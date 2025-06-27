import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:daily_inc_timer_flutter/src/models/daily_thing.dart';

class DataManager {
  static const String _dataKey = 'inc_timer_data';

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
  }

  Future<void> deleteDailyThing(DailyThing itemToDelete) async {
    final items = await loadData();
    items.removeWhere((item) => item.name == itemToDelete.name);
    await saveData(items);
  }

  Future<void> updateDailyThing(DailyThing updatedItem) async {
    final items = await loadData();
    final index = items.indexWhere((item) => item.name == updatedItem.name);
    if (index != -1) {
      items[index] = updatedItem;
      await saveData(items);
    } else {}
  }
}
