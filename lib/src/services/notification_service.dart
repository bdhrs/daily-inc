import 'dart:io';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/interval_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _log = Logger('NotificationService');
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  static const String _channelId = 'daily_nag_channel';
  static const String _channelName = 'Daily Nags';
  static const String _channelDescription = 'Reminders for your daily tasks';

  Future<void> _zonedScheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        _log.info('Exact alarms not permitted, falling back to inexact mode');
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: matchDateTimeComponents,
          payload: payload,
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_initialized) return;

    _navigatorKey = navigatorKey;

    try {
      _log.info('Initializing NotificationService');

      tz_data.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      _log.info('Device timezone: $timeZoneName');
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const androidSettings = AndroidInitializationSettings(
        'ic_notification',
      );
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      _initialized = true;
      _log.info('NotificationService initialized successfully');
    } catch (e, s) {
      _log.severe('Error initializing NotificationService', e, s);
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final notificationGranted =
            await androidImpl?.requestNotificationsPermission() ?? false;
        _log.info('Notification permission granted: $notificationGranted');

        if (await Permission.scheduleExactAlarm.isDenied) {
          _log.info('Schedule exact alarm permission denied');
        }

        return notificationGranted;
      } else if (Platform.isIOS) {
        final iosImpl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return true;
    } catch (e, s) {
      _log.severe('Error requesting permissions', e, s);
      return false;
    }
  }

  Future<bool> hasRequiredPermissions() async {
    try {
      if (Platform.isAndroid) {
        final notificationStatus = await Permission.notification.status;
        if (!notificationStatus.isGranted) return false;

        return await checkExactAlarmPermission();
      }
      return true;
    } catch (e) {
      _log.warning('Error checking permissions: $e');
      return false;
    }
  }

  Future<bool> checkExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.scheduleExactAlarm.status;
      return status.isGranted;
    } catch (e) {
      _log.warning('Error checking exact alarm permission: $e');
      return false;
    }
  }

  Future<void> openExactAlarmSettings() async {
    try {
      if (Platform.isAndroid) {
        await openAppSettings();
      }
    } catch (e, s) {
      _log.severe('Error opening exact alarm settings', e, s);
    }
  }

  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      final granted =
          await androidImpl?.requestExactAlarmsPermission() ?? false;
      _log.info('Exact alarm permission granted: $granted');
      return granted;
    } catch (e, s) {
      _log.severe('Error requesting exact alarm permission', e, s);
      return false;
    }
  }

  Future<void> scheduleNotification(DailyThing item) async {
    if (!item.notificationEnabled || item.nagTime == null) {
      await cancelNotification(item.id);
      return;
    }

    try {
      final nagHour = item.nagTime!.hour;
      final nagMinute = item.nagTime!.minute;
      final notificationId = item.id.hashCode;

      await _plugin.cancel(notificationId);

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );
      final notificationDetails = NotificationDetails(android: androidDetails);

      final body = item.nagMessage?.isNotEmpty == true
          ? item.nagMessage!
          : 'Time to complete your task!';

      if (item.intervalType == IntervalType.byWeekdays &&
          item.intervalWeekdays.isNotEmpty) {
        final scheduledDate = _nextWeekdayWithTime(
          item.intervalWeekdays,
          nagHour,
          nagMinute,
        );

        await _zonedScheduleWithFallback(
          id: notificationId,
          title: item.name,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: item.id,
        );
        _log.info(
          'Scheduled weekday notification for ${item.name} at $scheduledDate',
        );
      } else {
        final nextDue = await _calculateNextDueDate(item);
        if (nextDue == null) {
          _log.warning('Could not calculate next due date for ${item.name}');
          return;
        }

        final scheduledDate = tz.TZDateTime(
          tz.local,
          nextDue.year,
          nextDue.month,
          nextDue.day,
          nagHour,
          nagMinute,
        );

        if (scheduledDate.isAfter(DateTime.now())) {
          await _zonedScheduleWithFallback(
            id: notificationId,
            title: item.name,
            body: body,
            scheduledDate: scheduledDate,
            notificationDetails: notificationDetails,
            payload: item.id,
          );
          _log.info(
            'Scheduled one-time notification for ${item.name} at $scheduledDate',
          );
        }
      }
    } catch (e, s) {
      _log.severe('Error scheduling notification for ${item.name}', e, s);
    }
  }

  tz.TZDateTime _nextWeekdayWithTime(
    List<int> weekdays,
    int hour,
    int minute,
  ) {
    var scheduledDate = tz.TZDateTime.now(tz.local);
    scheduledDate = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    while (!weekdays.contains(scheduledDate.weekday)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<DateTime?> _calculateNextDueDate(DailyThing item) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (item.nagTime != null) {
      final nagToday = DateTime(
        today.year,
        today.month,
        today.day,
        item.nagTime!.hour,
        item.nagTime!.minute,
      );
      if (_isDueOnDate(item, today) && nagToday.isAfter(now)) {
        return today;
      }
    } else if (_isDueOnDate(item, today)) {
      return today;
    }

    for (int i = 1; i <= 365; i++) {
      final checkDate = today.add(Duration(days: i));
      if (_isDueOnDate(item, checkDate)) {
        return checkDate;
      }
    }

    return null;
  }

  bool _isDueOnDate(DailyThing item, DateTime date) {
    if (item.isPaused) return false;

    if (item.intervalType == IntervalType.byWeekdays) {
      return item.intervalWeekdays.contains(date.weekday);
    }

    final lastCompleted = item.lastCompletedDate;
    if (lastCompleted == null) {
      return !date.isBefore(item.startDate);
    }

    final lastCompletedDate = DateTime(
      lastCompleted.year,
      lastCompleted.month,
      lastCompleted.day,
    );
    final daysSinceLastCompleted = date.difference(lastCompletedDate).inDays;
    return daysSinceLastCompleted >= item.intervalValue;
  }

  Future<void> cancelNotification(String itemId) async {
    try {
      await _plugin.cancel(itemId.hashCode);
      _log.info('Cancelled notification for item $itemId');
    } catch (e, s) {
      _log.severe('Error cancelling notification', e, s);
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
      _log.info('Cancelled all notifications');
    } catch (e, s) {
      _log.severe('Error cancelling all notifications', e, s);
    }
  }

  Future<void> rescheduleAllNotifications(List<DailyThing> items) async {
    try {
      _log.info('Rescheduling all notifications');
      await cancelAllNotifications();

      for (final item in items) {
        if (item.notificationEnabled && !item.isArchived) {
          await scheduleNotification(item);
        }
      }

      _log.info('Finished rescheduling notifications');
    } catch (e, s) {
      _log.severe('Error rescheduling notifications', e, s);
    }
  }

  Future<void> onItemCompleted(DailyThing item) async {
    try {
      await cancelNotification(item.id);

      if (item.notificationEnabled) {
        await scheduleNotification(item);
      }

      _log.info('Handled completion for ${item.name}');
    } catch (e, s) {
      _log.severe('Error handling item completion', e, s);
    }
  }

  Future<void> testNotification(DailyThing item) async {
    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final androidDetails = AndroidNotificationDetails(
        '$_channelId-test',
        '$_channelName (Test)',
        channelDescription: 'Test notifications',
        importance: Importance.high,
        priority: Priority.high,
      );
      final notificationDetails = NotificationDetails(android: androidDetails);

      final body = item.nagMessage?.isNotEmpty == true
          ? item.nagMessage!
          : 'This is a test notification';

      final scheduledDate = tz.TZDateTime.now(tz.local).add(
        const Duration(seconds: 3),
      );

      await _zonedScheduleWithFallback(
        id: notificationId,
        title: item.name,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        payload: item.id,
      );

      _log.info('Scheduled test notification for ${item.name}');
    } catch (e, s) {
      _log.severe('Error sending test notification', e, s);
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    _log.info('Notification tapped: ${response.payload}');
    _navigatorKey?.currentState?.popUntil((route) => route.isFirst);
  }
}
