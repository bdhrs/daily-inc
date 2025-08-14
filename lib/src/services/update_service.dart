import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';

class UpdateService {
  final _log = Logger('UpdateService');
  final _dio = Dio();

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

      _log.info(
          'Latest version: $latestVersionStr, Current version: $currentVersionStr');

      final latestVersion = Version.parse(latestVersionStr);
      final currentVersion = Version.parse(currentVersionStr);

      final isUpdateAvailable = latestVersion > currentVersion;
      _log.info('Update available: $isUpdateAvailable');
      return isUpdateAvailable;
    } catch (e, st) {
      _log.severe('Error checking for update', e, st);
      return false;
    }
  }

  Future<String?> getDownloadUrl() async {
    final release = await getLatestRelease();
    if (release == null) {
      return null;
    }

    final assets = release['assets'] as List<dynamic>?;
    if (assets == null || assets.isEmpty) {
      return null;
    }

    try {
      final androidAsset = assets.firstWhere(
        (asset) {
          final name = asset['name'] as String?;
          return name != null && name.toLowerCase().endsWith('.apk');
        },
      );
      return androidAsset['browser_download_url'] as String?;
    } catch (e) {
      _log.info('No Android .apk asset found in the latest release.');
      return null;
    }
  }

  Future<void> installUpdate(String filePath) async {
    _log.info('Attempting to install update from $filePath');
    try {
      final result = await OpenFile.open(filePath);
      if (result.type == ResultType.done) {
        _log.info('Installation started successfully.');
      } else {
        _log.warning(
            'Failed to start installation: ${result.type} - ${result.message}');
        throw Exception('Failed to start installation: ${result.message}');
      }
    } catch (e, st) {
      _log.severe('Error installing update', e, st);
      rethrow;
    }
  }

  Future<String?> downloadUpdate(String url) async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        _log.severe('Could not get downloads directory.');
        return null;
      }
      final filePath = '${downloadsDir.path}/${url.split('/').last}';

      _log.info('Downloading update from $url to $filePath');

      await _dio.download(url, filePath);

      _log.info('Download complete.');
      return filePath;
    } on DioException catch (e, st) {
      _log.severe('Failed to download update', e, st);
      return null;
    } catch (e, st) {
      _log.severe('An unexpected error occurred during download', e, st);
      return null;
    }
  }
}
