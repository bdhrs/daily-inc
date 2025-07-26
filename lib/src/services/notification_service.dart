import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
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
    // Ensure initialization is only done once
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
      },
    );

    tz.initializeTimeZones();
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
    await flutterLocalNotificationsPlugin.show(
      id,
      "Test: $title",
      "This is a test notification. The scheduled one will appear at the set time.",
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
    _log.info(
        'scheduleNagNotification called: id=$id, title=$title, scheduledTime=$scheduledTime');
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool stickyNotifications =
          prefs.getBool('stickyNotifications') ?? false;

      if (Platform.isLinux) {
        _log.warning('Skipping notification scheduling on Linux.');
        return;
      }

      // For other platforms, use zonedSchedule
      _log.info('Scheduling zoned notification.');
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_inc_channel',
            'Daily Inc',
            channelDescription: 'Channel for Daily Inc notifications',
            importance: Importance.max,
            priority: Priority.high,
            ongoing: stickyNotifications,
            autoCancel: !stickyNotifications,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      _log.info('Notification scheduled successfully.');
    } catch (e, s) {
      _log.severe(
          'Error scheduling notification, falling back to immediate.', e, s);
      final prefs = await SharedPreferences.getInstance();
      final bool stickyNotifications =
          prefs.getBool('stickyNotifications') ?? false;
      // Fallback to immediate notification if scheduling fails
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
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          linux: const LinuxNotificationDetails(
            urgency: LinuxNotificationUrgency.critical,
            resident: true,
          ),
        ),
      );
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

  /// Checks if the app has the necessary permissions for scheduling notifications
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

      // For other platforms, assume permissions are granted
      return true;
    } catch (e) {
      _log.severe('Error checking permissions', e);
      return false;
    }
  }
}
