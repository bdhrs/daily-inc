import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

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

  void _update(AppUpdateState next) {
    state = next;
    notifyListeners();
  }
}
