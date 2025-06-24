import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_inc_timer_flutter/src/models/daily_thing.dart';

class DataManager {
  static const String _dataKey = 'inc_timer_data';

  Future<List<DailyThing>> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_dataKey);
    if (dataString == null || dataString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> dataList = jsonDecode(dataString);
      return dataList
          .map((json) => DailyThing.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading data: $e');
      return [];
    }
  }

  Future<void> saveData(List<DailyThing> items) async {
    final prefs = await SharedPreferences.getInstance();
    final dataList = items.map((item) => item.toJson()).toList();
    final dataString = jsonEncode(dataList);
    await prefs.setString(_dataKey, dataString);
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
    } else {
      print('Item to update not found: ${updatedItem.name}');
    }
  }
}
