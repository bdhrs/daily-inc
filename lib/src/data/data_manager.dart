import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/services/notification_service.dart';

class DataManager {
  static const String _dataKey = 'inc_timer_data';
  final NotificationService _notificationService = NotificationService();

  int _getNotificationId(String dailyThingId) {
    // Generate a consistent integer ID from the DailyThing's UUID string
    // by summing its code units and taking modulo to ensure it fits in an int.
    return dailyThingId.codeUnits.reduce((a, b) => a + b) % 2147483647;
  }

  Future<List<DailyThing>> loadFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final contents = await file.readAsString();
        final jsonData = jsonDecode(contents) as Map<String, dynamic>;
        final thingsList = jsonData['dailyThings'] as List<dynamic>;
        return thingsList
            .map((json) => DailyThing.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<DailyThing>> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      // First try to read as single string
      final dataString = prefs.getString(_dataKey);
      if (dataString != null) {
        final List<dynamic> dataList = jsonDecode(dataString);
        return dataList
            .map((json) => DailyThing.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Fall back to string list for backward compatibility
      final dataChunks = prefs.getStringList(_dataKey);
      if (dataChunks == null || dataChunks.isEmpty) {
        return [];
      }
      final combinedString = dataChunks.join();
      final List<dynamic> dataList = jsonDecode(combinedString);
      return dataList
          .map((json) => DailyThing.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveData(List<DailyThing> items) async {
    final prefs = await SharedPreferences.getInstance();
    final dataList = items.map((item) => item.toJson()).toList();
    final dataString = jsonEncode(dataList);

    // Handle Android's byte requirements by splitting large data
    if (dataString.length > 10000) {
      final chunks = <String>[];
      for (var i = 0; i < dataString.length; i += 10000) {
        final end =
            (i + 10000 < dataString.length) ? i + 10000 : dataString.length;
        chunks.add(dataString.substring(i, end));
      }
      await prefs.setStringList(_dataKey, chunks);
    } else {
      await prefs.setString(_dataKey, dataString);
    }
  }

  Future<void> addDailyThing(DailyThing newItem) async {
    final items = await loadData();
    items.add(newItem);
    await saveData(items);
    if (newItem.nagTime != null && newItem.nagMessage != null) {
      _notificationService.scheduleNagNotification(
        _getNotificationId(newItem.id), // Use a unique ID for the notification
        'Daily Inc Reminder',
        newItem.nagMessage!,
        newItem.nagTime!,
      );
    }
  }

  Future<void> deleteDailyThing(DailyThing itemToDelete) async {
    final items = await loadData();
    items.removeWhere((item) => item.id == itemToDelete.id);
    await saveData(items);
    _notificationService
        .cancelNotification(_getNotificationId(itemToDelete.id));
  }

  Future<void> updateDailyThing(DailyThing updatedItem) async {
    final items = await loadData();
    final index = items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      // Cancel existing notification before updating
      _notificationService
          .cancelNotification(_getNotificationId(updatedItem.id));
      items[index] = updatedItem;
      await saveData(items);
      if (updatedItem.nagTime != null && updatedItem.nagMessage != null) {
        _notificationService.scheduleNagNotification(
          _getNotificationId(updatedItem.id),
          'Daily Inc Reminder',
          updatedItem.nagMessage!,
          updatedItem.nagTime!,
        );
      }
    }
  }
}
