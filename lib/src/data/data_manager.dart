import 'dart:convert';
import 'dart:io';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/services/notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataManager {
  static const String _dataKey = 'inc_timer_data';
  final NotificationService _notificationService = NotificationService();
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
        return loadedThings;
      }
      _log.warning('No file picked.');
      return [];
    } catch (e, s) {
      _log.severe('Error loading from file', e, s);
      return [];
    }
  }

  Future<List<DailyThing>> loadData() async {
    _log.info('loadData called');
    final prefs = await SharedPreferences.getInstance();
    try {
      // First try to read as single string
      final dataString = prefs.getString(_dataKey);
      if (dataString != null) {
        _log.info('Found data as a single string.');
        final List<dynamic> dataList = jsonDecode(dataString);
        final loadedThings = dataList
            .map((json) => DailyThing.fromJson(json as Map<String, dynamic>))
            .toList();
        _log.info('Loaded ${loadedThings.length} items from single string.');
        return loadedThings;
      }

      // Fall back to string list for backward compatibility
      _log.info('No single string data found, trying string list.');
      final dataChunks = prefs.getStringList(_dataKey);
      if (dataChunks == null || dataChunks.isEmpty) {
        _log.warning('No data found in shared preferences.');
        return [];
      }
      final combinedString = dataChunks.join();
      final List<dynamic> dataList = jsonDecode(combinedString);
      final loadedThings = dataList
          .map((json) => DailyThing.fromJson(json as Map<String, dynamic>))
          .toList();
      _log.info('Loaded ${loadedThings.length} items from string list.');
      return loadedThings;
    } catch (e, s) {
      _log.severe('Error loading data', e, s);
      return [];
    }
  }

  Future<void> saveData(List<DailyThing> items) async {
    _log.info('saveData called with ${items.length} items.');
    final prefs = await SharedPreferences.getInstance();
    final dataList = items.map((item) => item.toJson()).toList();
    final dataString = jsonEncode(dataList);

    // Handle Android's byte requirements by splitting large data
    if (dataString.length > 10000) {
      _log.info('Data string is large, splitting into chunks.');
      final chunks = <String>[];
      for (var i = 0; i < dataString.length; i += 10000) {
        final end =
            (i + 10000 < dataString.length) ? i + 10000 : dataString.length;
        chunks.add(dataString.substring(i, end));
      }
      await prefs.setStringList(_dataKey, chunks);
      _log.info('Saved data as ${chunks.length} chunks.');
    } else {
      await prefs.setString(_dataKey, dataString);
      _log.info('Saved data as a single string.');
    }
  }

  Future<void> addDailyThing(DailyThing newItem) async {
    _log.info('addDailyThing called for item: ${newItem.name}');
    final items = await loadData();
    items.add(newItem);
    await saveData(items);
    _log.info('Item added and data saved.');
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
    } else {
      _log.warning('Item with id ${updatedItem.id} not found for update.');
    }
  }
}
