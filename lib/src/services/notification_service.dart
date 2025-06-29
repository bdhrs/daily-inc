import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final _log = Logger('NotificationService');

  Future<void> init() async {
    _log.info('Initializing NotificationService...');
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        _log.info(
            'onDidReceiveLocalNotification: id=$id, title=$title, body=$body, payload=$payload');
      },
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
          'daily_inc_timer_channel',
          'Daily Inc Timer',
          channelDescription: 'Channel for Daily Inc Timer notifications',
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
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_inc_timer_channel',
            'Daily Inc Timer',
            channelDescription: 'Channel for Daily Inc Timer notifications',
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
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      _log.info('Notification scheduled successfully.');
    } catch (e, s) {
      _log.severe(
          'Error scheduling notification, falling back to immediate.', e, s);
      // Fallback to immediate notification if scheduling fails
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_inc_timer_channel',
            'Daily Inc Timer',
            channelDescription: 'Channel for Daily Inc Timer notifications',
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
  }

  Future<void> cancelNotification(int id) async {
    _log.info('cancelNotification called for id: $id');
    await flutterLocalNotificationsPlugin.cancel(id);
    _log.info('Notification with id: $id cancelled.');
  }
}
