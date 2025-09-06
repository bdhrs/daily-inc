import 'dart:convert';
import 'dart:io';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/services/backup_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

class DataManager {
  static const String _dataFileName = 'daily_inc_data.json';
  final _log = Logger('DataManager');

  Future<List<DailyThing>> loadFromFile() async {
    _log.info('loadFromFile called');
    try {
      FilePickerResult? result;

      // Use different file picker configuration based on platform
      if (Platform.isLinux) {
        // On Linux, use ANY file type to avoid the "custom" issue
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          dialogTitle: 'Select JSON File',
        );
      } else {
        // On other platforms, use custom type with JSON extension
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
          dialogTitle: 'Select JSON File',
        );
      }

      if (result != null) {
        _log.info('File picked: ${result.files.single.path}');
        final file = File(result.files.single.path!);
        final contents = await file.readAsString();
        final jsonData = jsonDecode(contents) as Map<String, dynamic>;
        final thingsList = jsonData['dailyThings'] as List<dynamic>;
        final loadedThings = thingsList
            .map((json) => DailyThing.fromJson(json as Map<String, dynamic>))
            .toList();

        // Fix missing actual_value for minutes items where done_today is true
        final fixedThings = <DailyThing>[];
        for (final thing in loadedThings) {
          if (thing.itemType == ItemType.minutes) {
            final fixedHistory = <HistoryEntry>[];
            for (final entry in thing.history) {
              if (entry.doneToday && entry.actualValue == null) {
                _log.info(
                    'Fixing missing actual_value for ${thing.name} on ${entry.date}');
                fixedHistory.add(HistoryEntry(
                  date: entry.date,
                  targetValue: entry.targetValue,
                  doneToday: entry.doneToday,
                  actualValue: entry.targetValue,
                  comment: entry.comment,
                ));
              } else {
                fixedHistory.add(entry);
              }
            }
            fixedThings.add(DailyThing(
              id: thing.id,
              icon: thing.icon,
              name: thing.name,
              itemType: thing.itemType,
              startDate: thing.startDate,
              startValue: thing.startValue,
              duration: thing.duration,
              endValue: thing.endValue,
              history: fixedHistory,
              nagTime: thing.nagTime,
              nagMessage: thing.nagMessage,
              category: thing.category,
              isPaused: thing.isPaused,
              intervalType: thing.intervalType,
              intervalValue: thing.intervalValue,
              intervalWeekdays: thing.intervalWeekdays,
              bellSoundPath: thing.bellSoundPath,
              subdivisions: thing.subdivisions,
              subdivisionBellSoundPath: thing.subdivisionBellSoundPath,
            ));
          } else {
            fixedThings.add(thing);
          }
        }

        _log.info('Loaded ${fixedThings.length} items from file.');
        return fixedThings;
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

  Future<Map<String, dynamic>> _readRawStore() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      if (!file.existsSync()) {
        return {};
      }
      final contents = await file.readAsString();
      final decoded = jsonDecode(contents);
      if (decoded is List) {
        return {'dailyThings': decoded, 'meta': {}};
      }
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (e, s) {
      _log.severe('Error reading raw store', e, s);
      return {};
    }
  }

  Future<void> _writeRawStore(Map<String, dynamic> data) async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      await file.writeAsString(jsonEncode(data));
    } catch (e, s) {
      _log.severe('Error writing raw store', e, s);
    }
  }

  Future<List<DailyThing>> loadData() async {
    _log.fine('loadData called');
    try {
      final raw = await _readRawStore();
      final list = (raw['dailyThings'] as List<dynamic>? ?? []);
      final loadedThings = list
          .map((json) => DailyThing.fromJson(json as Map<String, dynamic>))
          .toList();
      _log.fine('Loaded ${loadedThings.length} items from file-based storage');
      return loadedThings;
    } catch (e, s) {
      _log.severe('Error loading data from file', e, s);
      return [];
    }
  }

  Future<void> saveData(List<DailyThing> items, {BuildContext? context}) async {
    _log.info('saveData called with ${items.length} items.');
    try {
      final raw = await _readRawStore();
      raw['dailyThings'] = items.map((item) => item.toJson()).toList();
      raw['meta'] = (raw['meta'] as Map<String, dynamic>? ?? {});
      await _writeRawStore(raw);
      _log.info('Saved data to file-based storage.');

      // Trigger automatic backup with context for notifications
      await _triggerAutomaticBackup(items, context: context);
    } catch (e, s) {
      _log.severe('Error saving data to file', e, s);
    }
  }

  Future<void> addDailyThing(DailyThing newItem) async {
    _log.info('addDailyThing called for item: ${newItem.name}');
    final items = await loadData();
    items.add(newItem);
    await saveData(items, context: null);
    _log.info('Item added and data saved.');
  }

  Future<void> deleteDailyThing(DailyThing itemToDelete) async {
    _log.info('deleteDailyThing called for item: ${itemToDelete.name}');
    final items = await loadData();
    items.removeWhere((item) => item.id == itemToDelete.id);
    await saveData(items, context: null);
    _log.info('Item deleted and data saved.');
  }

  Future<void> updateDailyThing(DailyThing updatedItem) async {
    _log.info('updateDailyThing called for item: ${updatedItem.name}');
    final items = await loadData();
    final index = items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _log.info('Item found at index $index, updating.');
      items[index] = updatedItem;
      await saveData(items, context: null);
      _log.info('Item updated and data saved.');
    } else {
      _log.warning('Item with id ${updatedItem.id} not found for update.');
    }
  }

  Future<void> archiveDailyThing(DailyThing item) async {
    _log.info('archiveDailyThing called for item: ${item.name}');
    final archivedItem = item.copyWith(isArchived: true);
    await updateDailyThing(archivedItem);
    _log.info('Item archived and data saved.');
  }

  Future<void> unarchiveDailyThing(DailyThing item) async {
    _log.info('unarchiveDailyThing called for item: ${item.name}');
    final unarchivedItem = item.copyWith(isArchived: false);
    await updateDailyThing(unarchivedItem);
    _log.info('Item unarchived and data saved.');
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

      String? outputFile;

      if (Platform.isLinux) {
        // On Linux, use ANY file type
        outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save History Data',
          fileName: 'daily_inc_history.json',
          type: FileType.any,
          bytes: bytes,
        );
      } else {
        // On other platforms, use custom type with JSON extension
        outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save History Data',
          fileName: 'daily_inc_history.json',
          allowedExtensions: ['json'],
          type: FileType.custom,
          bytes: bytes,
        );
      }

      if (outputFile != null) {
        _log.fine('History saved successfully to $outputFile.');
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

  Future<bool> saveTemplateToFile() async {
    _log.info('saveTemplateToFile called to save template data to a file.');
    try {
      final items = await loadData();
      // Create template items without history
      final templateItems = items.map((thing) {
        return thing.copyWith(history: []);
      }).toList();

      final jsonData = {
        'dailyThings': templateItems.map((thing) => thing.toJson()).toList(),
        'savedAt': DateTime.now().toIso8601String(),
        'isTemplate': true,
      };
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
      final bytes = utf8.encode(jsonString);

      String? outputFile;

      if (Platform.isLinux) {
        // On Linux, use ANY file type
        outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Template Data',
          fileName: 'daily_inc_template.json',
          type: FileType.any,
          bytes: bytes,
        );
      } else {
        // On other platforms, use custom type with JSON extension
        outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Template Data',
          fileName: 'daily_inc_template.json',
          allowedExtensions: ['json'],
          type: FileType.custom,
          bytes: bytes,
        );
      }

      if (outputFile != null) {
        _log.fine('Template saved successfully to $outputFile.');
        return true;
      } else {
        _log.info('Save template operation cancelled.');
        return false;
      }
    } catch (e, s) {
      _log.severe('Failed to save template', e, s);
      return false;
    }
  }

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

  Future<List<String>> getUniqueCategoriesForType(ItemType type) async {
    _log.info('getUniqueCategoriesForType called for type: $type');
    try {
      final items = await loadData();
      final categories = items
          .where((item) => item.itemType == type)
          .map((item) => item.category.trim())
          .where((category) => category.isNotEmpty && category != 'None')
          .toSet()
          .toList();
      _log.info('Found ${categories.length} unique categories for type $type');
      return categories;
    } catch (e, s) {
      _log.severe('Error getting unique categories for type', e, s);
      return [];
    }
  }

  Future<String?> getLastMotivationShownDate() async {
    final raw = await _readRawStore();
    final dynamicMeta = raw['meta'];
    if (dynamicMeta is Map) {
      final m = Map<String, dynamic>.from(dynamicMeta);
      return m['lastMotivationShownDate'] as String?;
    }
    return null;
  }

  Future<void> setLastMotivationShownDate(String yyyymmdd) async {
    final raw = await _readRawStore();
    final dynamicMeta = raw['meta'];
    final meta = (dynamicMeta is Map)
        ? Map<String, dynamic>.from(dynamicMeta)
        : <String, dynamic>{};
    meta['lastMotivationShownDate'] = yyyymmdd;
    raw['meta'] = meta;
    await _writeRawStore(raw);
  }

  Future<String?> getLastCompletionShownDate() async {
    final raw = await _readRawStore();
    final dynamicMeta = raw['meta'];
    if (dynamicMeta is Map) {
      final m = Map<String, dynamic>.from(dynamicMeta);
      return m['lastCompletionShownDate'] as String?;
    }
    return null;
  }

  Future<void> setLastCompletionShownDate(String yyyymmdd) async {
    final raw = await _readRawStore();
    final dynamicMeta = raw['meta'];
    final meta = (dynamicMeta is Map)
        ? Map<String, dynamic>.from(dynamicMeta)
        : <String, dynamic>{};
    meta['lastCompletionShownDate'] = yyyymmdd;
    raw['meta'] = meta;
    await _writeRawStore(raw);
  }

  /// Trigger automatic backup after data is saved with optional context for notifications
  Future<void> _triggerAutomaticBackup(List<DailyThing> items,
      {BuildContext? context}) async {
    try {
      final backupService = BackupService();
      final success = await backupService.createBackup(items);

      // Show notification if context is provided and backup failed
      if (context != null && !success) {
        final errorMessage = await backupService.getLastBackupError();
        final failureCount = await backupService.getBackupFailureCount();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                failureCount >= 3
                    ? 'Backups consistently failing: ${errorMessage ?? 'Unknown error'}'
                    : 'Backup failed: ${errorMessage ?? 'Unknown error'}',
              ),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, s) {
      _log.warning('Automatic backup failed', e, s);
      // Don't rethrow - backup failure shouldn't prevent data saving
    }
  }

  /// Save template data to backup location automatically (without file picker)
  Future<void> saveTemplateToBackupLocation() async {
    _log.info(
        'saveTemplateToBackupLocation called to save template data automatically');
    try {
      final items = await loadData();
      // Create template items without history
      final templateItems = items.map((thing) {
        return thing.copyWith(history: []);
      }).toList();

      final jsonData = {
        'dailyThings': templateItems.map((thing) => thing.toJson()).toList(),
        'savedAt': DateTime.now().toIso8601String(),
        'isTemplate': true,
      };
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

      // Get backup location from backup service
      final backupService = BackupService();
      final backupLocation = await backupService.getBackupLocation();
      if (backupLocation == null || backupLocation.isEmpty) {
        _log.warning('Backup location not configured, skipping template save');
        return;
      }

      final backupDir = Directory(backupLocation);
      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
        _log.info('Created backup directory: $backupLocation');
      }

      // Save template file with correct name
      final templateFile =
          File('${backupDir.path}/daily_inc_latest_template.json');
      await templateFile.writeAsString(jsonString);

      _log.fine('Template saved successfully to: ${templateFile.path}');
    } catch (e, s) {
      _log.warning('Failed to save template to backup location', e, s);
      // Don't rethrow - template save failure shouldn't prevent normal operations
    }
  }
}
