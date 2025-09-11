import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  final _log = Logger('UpdateService');

  Future<Map<String, dynamic>?> getLatestRelease() async {
    final url = Uri.parse(
        'https://api.github.com/repos/bdhrs/daily-inc/releases/latest');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        _log.warning('Failed to get latest release: ${response.statusCode}');
        return null;
      }
    } catch (e, st) {
      _log.severe('Error getting latest release', e, st);
      return null;
    }
  }

  Future<String> getCurrentAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<bool> isUpdateAvailable() async {
    _log.info('Checking for updates...');
    try {
      final latestRelease = await getLatestRelease();
      if (latestRelease == null || latestRelease['tag_name'] == null) {
        _log.warning('Could not get latest release information.');
        return false;
      }

      final latestVersionStr =
          latestRelease['tag_name'].toString().replaceFirst('v', '');
      final currentVersionStr = await getCurrentAppVersion();

      _log.info('Current app version: $currentVersionStr');
      _log.info('Latest GitHub release version: $latestVersionStr');

      final latestVersion = Version.parse(latestVersionStr);
      final currentVersion = Version.parse(currentVersionStr);

      final isNewer = latestVersion > currentVersion;
      _log.info('Is newer version available? $isNewer');
      return isNewer;
    } catch (e, st) {
      _log.severe('Error checking for update', e, st);
      return false;
    }
  }

  Future<String?> getDownloadUrl() async {
    final release = await getLatestRelease();
    if (release == null || release['assets'] == null) {
      return null;
    }

    final assets = release['assets'] as List;
    for (var asset in assets) {
      final name = asset['name'] as String;
      if (name.endsWith('.apk')) {
        final url = asset['browser_download_url'] as String;
        _log.info('Found APK asset: $name at $url');
        return url;
      }
    }
    _log.warning('No APK asset found in release assets');
    return null;
  }

  Future<File> downloadUpdate() async {
    final url = await getDownloadUrl();
    if (url == null) {
      throw Exception('No APK URL found');
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to download APK: ${response.statusCode}');
    }

    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw Exception('External storage directory not found');
    }

    final apkFile = File('${dir.path}/DailyInc_update.apk');
    await apkFile.writeAsBytes(response.bodyBytes);
    _log.info('APK downloaded to ${apkFile.path}');
    return apkFile;
  }

  Future<void> installUpdate(File apkFile) async {
    if (Platform.isAndroid) {
      final uri = Uri.file(apkFile.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _log.warning('Could not launch APK file: ${apkFile.path}');
      }
    } else {
      _log.warning('InstallUpdate not implemented for this platform');
    }
  }
}
