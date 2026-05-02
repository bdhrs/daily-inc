import 'dart:io' show Platform;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void _noOpCallback() {}

class ForegroundDownloadService {
  static bool get _isAndroid => Platform.isAndroid;

  static void initialize() {
    if (!_isAndroid) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'daily_inc_update',
        channelName: 'App update',
        channelDescription: 'Shown while downloading an app update',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> startAppDownload() async {
    if (!_isAndroid) return;
    await FlutterForegroundTask.requestNotificationPermission();
    await FlutterForegroundTask.startService(
      serviceId: 1002,
      notificationTitle: 'Downloading update…',
      notificationText: 'Preparing download',
      serviceTypes: [ForegroundServiceTypes.dataSync],
      callback: _noOpCallback,
    );
  }

  static Future<void> updateProgress(double progress) async {
    if (!_isAndroid) return;
    final pct = (progress * 100).toStringAsFixed(0);
    await FlutterForegroundTask.updateService(
      notificationText: 'Downloading update… $pct%',
    );
  }

  static Future<void> stop() async {
    if (!_isAndroid) return;
    await FlutterForegroundTask.stopService();
  }
}
