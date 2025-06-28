import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {},
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
        // Handle notification tapped logic here
      },
    );

    tz.initializeTimeZones();
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> scheduleNagNotification(
      int id, String title, String body, DateTime scheduledTime) async {
    try {
      // For all platforms, first try to show an immediate notification
      // This ensures the user gets a notification even if scheduling fails
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

      // Skip scheduling on Linux as it's not supported
      if (Platform.isLinux) {
        return;
      }

      // For other platforms, use zonedSchedule
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
    } catch (e) {
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
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
