import 'dart:convert';
import 'dart:io';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

class DataManager {
  static const String _dataFileName = 'daily_inc_data.json';
  final _log = Logger('DataManager');

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
  }

  Future<void> deleteDailyThing(DailyThing itemToDelete) async {
    _log.info('deleteDailyThing called for item: ${itemToDelete.name}');
    final items = await loadData();
    items.removeWhere((item) => item.id == itemToDelete.id);
    await saveData(items);
    _log.info('Item deleted and data saved.');
  }

  Future<void> updateDailyThing(DailyThing updatedItem) async {
    _log.info('updateDailyThing called for item: ${updatedItem.name}');
    final items = await loadData();
    final index = items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _log.info('Item found at index $index, updating.');
      items[index] = updatedItem;
      await saveData(items);
      _log.info('Item updated and data saved.');
    } else {
      _log.warning('Item with id ${updatedItem.id} not found for update.');
    }
  }

  Future<void> resetAllData() async {
    _log.info('resetAllData called to clear all data.');
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

  /// Returns a list of unique categories from all daily things
  Future<List<String>> getUniqueCategories() async {
    _log.info('getUniqueCategories called');
    try {
      final items = await loadData();
      final categories = items
          .map((item) => item.category)
          .where((category) => category != 'None' && category.isNotEmpty)
          .toSet()
          .toList();
      _log.info('Found ${categories.length} unique categories');
      return categories;
    } catch (e, s) {
      _log.severe('Error getting unique categories', e, s);
      return [];
    }
  }
}
