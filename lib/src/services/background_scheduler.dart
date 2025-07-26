import 'dart:async';
import 'package:logging/logging.dart';
import '../data/data_manager.dart';

/// Manages background tasks for daily notification rescheduling
class BackgroundScheduler {
  static final Logger _log = Logger('BackgroundScheduler');
  static Timer? _dailyTimer;
  static bool _isInitialized = false;

  /// Initializes the background scheduler
  static Future<void> initialize() async {
    if (_isInitialized) {
      _log.info('Background scheduler already initialized');
      return;
    }

    _log.info('Initializing background scheduler');
    _isInitialized = true;

    // Schedule the first daily check
    _scheduleDailyCheck();
  }

  /// Schedules a daily check for rescheduling notifications
  static void _scheduleDailyCheck() {
    _log.info('Scheduling daily notification check');

    // Cancel any existing timer
    _dailyTimer?.cancel();

    // Calculate time until next midnight
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = tomorrow.difference(now);

    _log.info(
        'Next daily check scheduled in ${durationUntilMidnight.inHours} hours');

    // Schedule the timer
    _dailyTimer = Timer(durationUntilMidnight, () async {
      await _performDailyReschedule();

      // Schedule the next daily check
      _scheduleDailyCheck();
    });
  }

  /// Performs the daily notification rescheduling
  static Future<void> _performDailyReschedule() async {
    _log.info('Performing daily notification reschedule');

    try {
      final dataManager = DataManager();

      // Reschedule all notifications for the new day
      await dataManager.scheduleAllNotifications();

      _log.info('Daily notification reschedule completed successfully');
    } catch (e) {
      _log.severe('Error during daily notification reschedule', e);
    }
  }

  /// Manually triggers a reschedule (for testing)
  static Future<void> triggerReschedule() async {
    _log.info('Manually triggering notification reschedule');
    await _performDailyReschedule();
  }

  /// Disposes the background scheduler
  static void dispose() {
    _log.info('Disposing background scheduler');
    _dailyTimer?.cancel();
    _isInitialized = false;
  }
}
