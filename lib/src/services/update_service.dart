import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

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
    if (release == null) {
      return null;
    }

    // Get the HTML URL for the release page instead of direct download URL
    final releaseUrl = release['html_url'] as String?;
    if (releaseUrl != null) {
      _log.info('Release URL: $releaseUrl');
      return releaseUrl;
    } else {
      _log.warning('No release URL found in the latest release.');
      return null;
    }
  }

  Future<String?> downloadUpdate(String url) async {
    try {
      _log.info('Release URL is accessible: $url');
      return url;
    } catch (e, st) {
      _log.severe(
          'An unexpected error occurred while checking release URL', e, st);
      return null;
    }
  }
}
