import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final _log = Logger('NotificationService');
  bool _isInitialized = false;

  Future<void> init() async {
    _log.info('Initializing NotificationService...');
    if (_isInitialized) {
      _log.info('NotificationService already initialized.');
      return;
    }
    _isInitialized = true;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      linux: initializationSettingsLinux,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        _log.info(
            'onDidReceiveNotificationResponse: payload=${details.payload}');
        if (const bool.fromEnvironment('TEST_NOTIFICATION')) {
          _log.info('TEST_NOTIFICATION: Received notification response');
        }
      },
    );
    _log.info('NotificationService initialized.');
  }

  Future<void> requestPermissions() async {
    _log.info('Requesting notification permissions...');
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      _log.info('Requesting Android permissions.');
      await androidImplementation.requestNotificationsPermission();
    }

    _log.info('Requesting iOS permissions.');
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    _log.info('Notification permissions requested.');
  }

  Future<void> showTestNotification(int id, String title) async {
    _log.info('showTestNotification called: id=$id, title=$title');
    if (const bool.fromEnvironment('TEST_NOTIFICATION')) {
      _log.info('TEST_NOTIFICATION: Showing test notification');
    }
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      "complete!",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_inc_channel',
          'Daily Inc',
          channelDescription: 'Channel for Daily Inc notifications',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: true,
          autoCancel: false,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        linux: LinuxNotificationDetails(
          urgency: LinuxNotificationUrgency.critical,
          resident: true,
        ),
      ),
    );
  }

  Future<void> scheduleNagNotification(
      int id, String title, String body, DateTime scheduledTime) async {
    final utcTime = scheduledTime.toUtc();
    _log.info(
        'scheduleNagNotification called: id=$id, title=$title, utcTime=$utcTime');

    if (const bool.fromEnvironment('TEST_NOTIFICATION')) {
      _log.info('TEST_NOTIFICATION: Scheduling notification for testing');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final bool stickyNotifications =
          prefs.getBool('stickyNotifications') ?? false;

      if (Platform.isLinux) {
        _log.warning('Skipping notification scheduling on Linux.');
        return;
      }

      _log.info('Creating scheduled notification', {
        'id': id,
        'title': title,
        'utcTime': utcTime.toString(),
        'timestamp': utcTime.millisecondsSinceEpoch,
        'currentUtcTime': DateTime.now().toUtc().toString()
      });

      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_inc_channel',
            'Daily Inc',
            channelDescription: 'Channel for Daily Inc notifications',
            importance: Importance.max,
            priority: Priority.high,
            ongoing: stickyNotifications,
            autoCancel: !stickyNotifications,
            when: utcTime.millisecondsSinceEpoch,
            showWhen: true,
            styleInformation: const BigTextStyleInformation(''),
            visibility: NotificationVisibility.public,
            fullScreenIntent: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );

      _log.info('Notification scheduled successfully.');
      if (const bool.fromEnvironment('TEST_NOTIFICATION')) {
        _log.info('TEST_NOTIFICATION: Notification scheduled successfully');
      }
    } catch (e, s) {
      _log.severe('Error scheduling notification', e, s);
      if (const bool.fromEnvironment('TEST_NOTIFICATION')) {
        _log.severe('TEST_NOTIFICATION: Failed to schedule notification', e, s);
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    _log.info('cancelNotification called for id: $id');
    await flutterLocalNotificationsPlugin.cancel(id);
    _log.info('Notification with id: $id cancelled.');
  }

  Future<void> cancelAllNotifications() async {
    _log.info('cancelAllNotifications called');
    await flutterLocalNotificationsPlugin.cancelAll();
    _log.info('All notifications cancelled');
  }

  Future<bool> checkPermissions() async {
    _log.info('Checking notification permissions');
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? granted =
            await androidImplementation.areNotificationsEnabled();
        _log.info('Android notifications enabled: $granted');
        return granted ?? false;
      }
      return true;
    } catch (e) {
      _log.severe('Error checking permissions', e);
      return false;
    }
  }
}
