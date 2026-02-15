import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:open_filex/open_filex.dart';

class UpdateService {
  final _log = Logger('UpdateService');
  final _dio = Dio();

  Future<bool> hasInstallPermission() async {
    if (!Platform.isAndroid) return true;
    return await Permission.requestInstallPackages.isGranted;
  }

  Future<bool> requestInstallPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.requestInstallPackages.request();
    return status.isGranted;
  }

  Future<Map<String, dynamic>?> getLatestRelease() async {
    final url = 'https://api.github.com/repos/bdhrs/daily-inc/releases/latest';
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
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

  Future<File> downloadUpdate({
    void Function(int count, int total)? onProgress,
    String? savePath,
  }) async {
    final url = await getDownloadUrl();
    if (url == null) {
      throw Exception('No APK URL found');
    }

    String finalPath;
    if (savePath != null) {
      finalPath = savePath;
    } else {
      final dir = await getTemporaryDirectory();
      finalPath = '${dir.path}/DailyInc_update.apk';
    }

    _log.info('Downloading APK to $finalPath');

    await _dio.download(
      url,
      finalPath,
      onReceiveProgress: onProgress,
    );

    _log.info('APK downloaded successfully');
    return File(finalPath);
  }

  Future<void> deleteDownloadedUpdate(File apkFile) async {
    try {
      if (await apkFile.exists()) {
        await apkFile.delete();
        _log.info('Temporary APK file deleted: ${apkFile.path}');
      }
    } catch (e) {
      _log.warning('Failed to delete temporary APK file: $e');
    }
  }

  Future<void> installUpdate(File apkFile) async {
    if (Platform.isAndroid) {
      final result = await OpenFilex.open(apkFile.path);
      if (result.type != ResultType.done) {
        _log.warning('Could not open APK file: ${result.message}');
        throw Exception('Failed to open APK: ${result.message}');
      }
    } else {
      _log.warning('InstallUpdate not implemented for this platform');
    }
  }
}
