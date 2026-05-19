import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'foreground_download_service.dart';
import 'update_service.dart';

enum AppUpdateStatus { idle, checking, downloading, readyToInstall }

class AppUpdateState {
  final AppUpdateStatus status;
  final double progress;
  final String? apkPath;
  final String? latestTag;

  const AppUpdateState({
    this.status = AppUpdateStatus.idle,
    this.progress = 0,
    this.apkPath,
    this.latestTag,
  });

  AppUpdateState copyWith({
    AppUpdateStatus? status,
    double? progress,
    String? apkPath,
    String? latestTag,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      apkPath: apkPath ?? this.apkPath,
      latestTag: latestTag ?? this.latestTag,
    );
  }
}

class AppUpdateController extends ChangeNotifier {
  static const _cachedVersionKey = 'cachedUpdateApkVersion';

  final _log = Logger('AppUpdateController');
  final _service = UpdateService();
  AppUpdateState state = const AppUpdateState();

  Future<void> checkAndMaybeDownload({required bool wifiOnly}) async {
    if (kDebugMode) return;
    if (state.status != AppUpdateStatus.idle) return;

    if (wifiOnly) {
      final connectivity = await Connectivity().checkConnectivity();
      if (!connectivity.contains(ConnectivityResult.wifi)) return;
    }

    _update(state.copyWith(status: AppUpdateStatus.checking));

    bool hasUpdate;
    String? latestTag;
    try {
      final release = await _service.getLatestRelease();
      if (release == null || release['tag_name'] == null) {
        _update(state.copyWith(status: AppUpdateStatus.idle));
        return;
      }
      latestTag = release['tag_name'].toString();
      hasUpdate = await _service.isUpdateAvailable();
    } catch (_) {
      _update(state.copyWith(status: AppUpdateStatus.idle));
      return;
    }

    if (!hasUpdate) {
      await _clearCachedApk();
      _update(state.copyWith(status: AppUpdateStatus.idle));
      return;
    }

    if (Platform.isAndroid) {
      final granted = await Permission.requestInstallPackages.isGranted;
      if (!granted) {
        final result = await Permission.requestInstallPackages.request();
        if (!result.isGranted) {
          _update(state.copyWith(status: AppUpdateStatus.idle));
          return;
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final cachedVersion = prefs.getString(_cachedVersionKey);
    final cachedFile = await _service.getCachedApkFile();
    if (cachedVersion == latestTag && await cachedFile.exists()) {
      _log.info('Reusing cached APK for $latestTag at ${cachedFile.path}');
      _update(state.copyWith(
        status: AppUpdateStatus.readyToInstall,
        apkPath: cachedFile.path,
        latestTag: latestTag,
        progress: 1,
      ));
      return;
    }

    if (cachedVersion != null && cachedVersion != latestTag) {
      _log.info(
          'Cached APK version $cachedVersion is stale (latest $latestTag); deleting.');
      await _clearCachedApk();
    } else if (await cachedFile.exists()) {
      await _clearCachedApk();
    }

    await _download(latestTag);
  }

  Future<void> _download(String? latestTag) async {
    _update(state.copyWith(
      status: AppUpdateStatus.downloading,
      latestTag: latestTag,
      progress: 0,
    ));

    await ForegroundDownloadService.startAppDownload();
    try {
      final file = await _service.downloadUpdate(
        onProgress: (count, total) {
          if (total > 0) {
            final progress = count / total;
            _update(state.copyWith(progress: progress));
            ForegroundDownloadService.updateProgress(progress);
          }
        },
      );
      if (latestTag != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cachedVersionKey, latestTag);
      }
      _update(state.copyWith(
        status: AppUpdateStatus.readyToInstall,
        apkPath: file.path,
      ));
    } catch (_) {
      _update(state.copyWith(status: AppUpdateStatus.idle));
    } finally {
      await ForegroundDownloadService.stop();
    }
  }

  Future<void> _clearCachedApk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedVersionKey);
      final file = await _service.getCachedApkFile();
      if (await file.exists()) {
        await file.delete();
        _log.info('Deleted cached APK at ${file.path}');
      }
    } catch (e) {
      _log.warning('Failed to clear cached APK: $e');
    }
  }

  void _update(AppUpdateState next) {
    state = next;
    notifyListeners();
  }
}
