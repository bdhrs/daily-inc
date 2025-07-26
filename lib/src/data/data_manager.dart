import 'dart:convert';
import 'dart:io';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/services/notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

class DataManager {
  static const String _dataFileName = 'daily_inc_data.json';
  final NotificationService _notificationService =
      NotificationService(); // Use the singleton instance
  final _log = Logger('DataManager');

  int _getNotificationId(String dailyThingId) {
    _log.info('_getNotificationId called with id: $dailyThingId');
    // Generate a consistent integer ID from the DailyThing's UUID string
    // by summing its code units and taking modulo to ensure it fits in an int.
    final id = dailyThingId.codeUnits.reduce((a, b) => a + b) % 2147483647;
    _log.info('_getNotificationId returning: $id');
    return id;
  }

  Future<List<DailyThing>> loadFromFile() async {
    _log.info('loadFromFile called');
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        _log.info('File picked: ${result.files.single.path}');
        final file = File(result.files.single.path!);
        final contents = await file.readAsString();
        final jsonData = jsonDecode(contents) as Map<String, dynamic>;
        final thingsList = jsonData['dailyThings'] as List<dynamic>;
        final loadedThings = thingsList
            .map((json) => DailyThing.fromJson(json as Map<String, dynamic>))
            .toList();
        _log.info('Loaded ${loadedThings.length} items from file.');

        // Cancel all existing notifications before importing new ones
        await _notificationService.cancelAllNotifications();

        // Schedule notifications for imported items with nagTime
        for (final thing in loadedThings) {
          if (thing.nagTime != null && thing.nagMessage != null) {
            await _notificationService.scheduleNagNotification(
              _getNotificationId(thing.id),
              thing.name,
              thing.nagMessage!,
              thing.nagTime!,
            );
          }
        }

        return loadedThings;
      }
      _log.warning('No file picked.');
      return [];
    } catch (e, s) {
      _log.severe('Error loading from file', e, s);
      return [];
    }
  }

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_dataFileName';
  }

  Future<List<DailyThing>> loadData() async {
    _log.info('loadData called');
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      if (!file.existsSync()) {
        _log.warning('Data file not found at $filePath');
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> dataList = jsonDecode(contents);
      final loadedThings = dataList
          .map((json) => DailyThing.fromJson(json as Map<String, dynamic>))
          .toList();
      _log.info('Loaded ${loadedThings.length} items from file-based storage.');
      return loadedThings;
    } catch (e, s) {
      _log.severe('Error loading data from file', e, s);
      return [];
    }
  }

  Future<void> saveData(List<DailyThing> items) async {
    _log.info('saveData called with ${items.length} items.');
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      final dataList = items.map((item) => item.toJson()).toList();
      final dataString = jsonEncode(dataList);
      await file.writeAsString(dataString);
      _log.info('Saved data to file-based storage at $filePath.');
    } catch (e, s) {
      _log.severe('Error saving data to file', e, s);
    }
  }

  Future<void> addDailyThing(DailyThing newItem) async {
    _log.info('addDailyThing called for item: ${newItem.name}');
    final items = await loadData();
    items.add(newItem);
    await saveData(items);
    _log.info('Item added and data saved.');

    // Schedule notification if nag time and message are provided
    if (newItem.nagTime != null && newItem.nagMessage != null) {
      // Ensure nag time is in the future
      DateTime scheduledTime = newItem.nagTime!;
      final now = DateTime.now();

      // If the scheduled time is in the past, schedule for tomorrow at the same time
      if (scheduledTime.isBefore(now)) {
        scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          newItem.nagTime!.hour,
          newItem.nagTime!.minute,
        ).add(const Duration(days: 1));
      }

      await _notificationService.scheduleNagNotification(
        _getNotificationId(newItem.id),
        newItem.name,
        newItem.nagMessage!,
        scheduledTime,
      );
      _log.info(
          'Scheduled notification for new item: ${newItem.name} at $scheduledTime');
    }
  }

  Future<void> deleteDailyThing(DailyThing itemToDelete) async {
    _log.info('deleteDailyThing called for item: ${itemToDelete.name}');
    final items = await loadData();
    items.removeWhere((item) => item.id == itemToDelete.id);
    await saveData(items);
    _log.info('Item deleted and data saved.');
    _notificationService
        .cancelNotification(_getNotificationId(itemToDelete.id));
    _log.info('Cancelled notification for ${itemToDelete.name}');
  }

  Future<void> updateDailyThing(DailyThing updatedItem) async {
    _log.info('updateDailyThing called for item: ${updatedItem.name}');
    final items = await loadData();
    final index = items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _log.info('Item found at index $index, updating.');
      final oldItem = items[index];
      items[index] = updatedItem;
      await saveData(items);
      _log.info('Item updated and data saved.');

      // Only update notification if nag time or message has changed
      if (updatedItem.nagTime != oldItem.nagTime ||
          updatedItem.nagMessage != oldItem.nagMessage) {
        _notificationService
            .cancelNotification(_getNotificationId(updatedItem.id));
        _log.info('Cancelled existing notification for ${updatedItem.name}');
      }

      // Schedule new notification if nag time and message are provided
      if (updatedItem.nagTime != null && updatedItem.nagMessage != null) {
        // Ensure nag time is in the future
        DateTime scheduledTime = updatedItem.nagTime!;
        final now = DateTime.now();

        // If the scheduled time is in the past, schedule for tomorrow at the same time
        if (scheduledTime.isBefore(now)) {
          scheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            updatedItem.nagTime!.hour,
            updatedItem.nagTime!.minute,
          ).add(const Duration(days: 1));
        }

        await _notificationService.scheduleNagNotification(
          _getNotificationId(updatedItem.id),
          updatedItem.name,
          updatedItem.nagMessage!,
          scheduledTime,
        );
        _log.info(
            'Rescheduled notification for updated item: ${updatedItem.name} at $scheduledTime');
      }
    } else {
      _log.warning('Item with id ${updatedItem.id} not found for update.');
    }
  }

  Future<void> resetData() async {
    _log.info('resetData called to clear all data.');
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
        _log.info('Data file deleted successfully from $filePath');
      } else {
        _log.info('Data file did not exist, nothing to delete.');
      }
    } catch (e, s) {
      _log.severe('Error deleting data file', e, s);
    }
  }

  /// Schedules notifications for all items that have nagTime and nagMessage
  Future<void> scheduleAllNotifications() async {
    _log.info('scheduleAllNotifications called');
    try {
      final items = await loadData();
      int scheduledCount = 0;

      // Cancel all existing notifications first
      await _notificationService.cancelAllNotifications();
      _log.info('Cancelled all existing notifications');

      // Schedule notifications for items with nag time and message
      for (final thing in items) {
        if (thing.nagTime != null && thing.nagMessage != null) {
          // Ensure nag time is in the future
          DateTime scheduledTime = thing.nagTime!;
          final now = DateTime.now();

          // If the scheduled time is in the past, schedule for tomorrow at the same time
          if (scheduledTime.isBefore(now)) {
            scheduledTime = DateTime(
              now.year,
              now.month,
              now.day,
              thing.nagTime!.hour,
              thing.nagTime!.minute,
            ).add(const Duration(days: 1));
          }

          await _notificationService.scheduleNagNotification(
            _getNotificationId(thing.id),
            thing.name,
            thing.nagMessage!,
            scheduledTime,
          );
          scheduledCount++;
          _log.info(
              'Scheduled notification for: ${thing.name} at $scheduledTime');
        }
      }

      _log.info('Successfully scheduled $scheduledCount notifications');
    } catch (e, s) {
      _log.severe('Error scheduling notifications', e, s);
    }
  }

  Future<bool> saveHistoryToFile() async {
    _log.info('saveHistoryToFile called to save history data to a file.');
    try {
      final items = await loadData();
      final jsonData = {
        'dailyThings': items.map((thing) => thing.toJson()).toList(),
        'savedAt': DateTime.now().toIso8601String(),
      };
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
      final bytes = utf8.encode(jsonString);

      _log.info('Opening file picker to save file.');
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save History Data',
        fileName: 'daily_inc_history.json',
        allowedExtensions: ['json'],
        type: FileType.custom,
        bytes: bytes,
      );

      if (outputFile != null) {
        _log.info('History saved successfully to $outputFile.');
        return true;
      } else {
        _log.info('Save file operation cancelled.');
        return false;
      }
    } catch (e, s) {
      _log.severe('Failed to save history', e, s);
      return false;
    }
  }
}
