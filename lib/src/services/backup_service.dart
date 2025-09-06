import 'dart:convert';
import 'dart:io';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BackupType { full, template }

class BackupService {
  static const String _prefsKeyBackupEnabled = 'backupEnabled';
  static const String _prefsKeyBackupLocation = 'backupLocation';
  static const String _prefsKeyLastBackupTime = 'lastBackupTime';

  static const bool _defaultBackupEnabled = true;

  final _log = Logger('BackupService');

  /// Returns the platform-specific root directory for all backups.
  /// On desktop, it's 'Documents/DailyIncBackups'.
  /// On mobile, it's the standard app documents directory.
  Future<Directory> _getPlatformSpecificBackupDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      final desktopBackupsDir = Directory('${docsDir.path}/DailyIncBackups');
      if (!await desktopBackupsDir.exists()) {
        await desktopBackupsDir.create(recursive: true);
      }
      return desktopBackupsDir;
    }
    // For mobile platforms, use the root of the documents directory
    return docsDir;
  }

  /// Returns the path to the internal directory for storing backups.
  Future<Directory> getBackupsDir() async {
    final baseDir = await _getPlatformSpecificBackupDir();
    final backupsDir = Directory('${baseDir.path}/backups');
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }
    return backupsDir;
  }

  /// Returns the path to the internal directory for storing templates.
  Future<Directory> getTemplatesDir() async {
    final baseDir = await _getPlatformSpecificBackupDir();
    final templatesDir = Directory('${baseDir.path}/templates');
    if (!await templatesDir.exists()) {
      await templatesDir.create(recursive: true);
    }
    return templatesDir;
  }

  /// Creates a backup file with the given data.
  /// The filename will include a timestamp.
  Future<File> writeBackup(String data) async {
    final dir = await getBackupsDir();
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final file = File('${dir.path}/backup_$timestamp.json');
    _log.info('Writing backup to ${file.path}');
    return file.writeAsString(data);
  }

  /// Creates a template backup file with the given data.
  Future<File> writeTemplate(String data) async {
    final dir = await getTemplatesDir();
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final file = File('${dir.path}/template_$timestamp.json');
    _log.info('Writing template to ${file.path}');
    return file.writeAsString(data);
  }

  /// Reads the content of a specific backup file.
  Future<String> readBackup(File file) async {
    try {
      final contents = await file.readAsString();
      return contents;
    } catch (e) {
      _log.severe('Error reading backup: $e');
      return 'Error reading backup: $e';
    }
  }

  /// Gets a list of all backup files, sorted by newest first.
  Future<List<File>> getBackupFiles() async {
    final dir = await getBackupsDir();
    final files = dir
        .listSync()
        .where((entity) => entity.path.endsWith('.json'))
        .whereType<File>()
        .toList();
    // Sort by filename descending, which corresponds to newest first
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  /// Gets a list of all template files, sorted by newest first.
  Future<List<File>> getTemplateFiles() async {
    final dir = await getTemplatesDir();
    final files = dir
        .listSync()
        .where((entity) => entity.path.endsWith('.json'))
        .whereType<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  /// Restore from a specific backup file
  Future<List<DailyThing>> restoreFromBackup(File backupFile) async {
    try {
      final contents = await backupFile.readAsString();
      final jsonData = jsonDecode(contents) as Map<String, dynamic>;

      // Handle both old and new backup formats
      final List<dynamic> thingsList = jsonData.containsKey('dailyThings')
          ? jsonData['dailyThings'] as List<dynamic>
          : jsonData as List<dynamic>;

      final restoredThings = thingsList
          .map((json) => DailyThing.fromJson(json as Map<String, dynamic>))
          .toList();

      _log.info(
          'Restored ${restoredThings.length} items from backup: ${backupFile.path}');
      return restoredThings;
    } catch (e, s) {
      _log.severe('Error restoring from backup: ${backupFile.path}', e, s);
      rethrow;
    }
  }

  /// Restore from a specific template file
  Future<List<DailyThing>> restoreFromTemplate(File templateFile) async {
    try {
      final contents = await templateFile.readAsString();
      final jsonData = jsonDecode(contents) as Map<String, dynamic>;

      final List<dynamic> thingsList = jsonData.containsKey('dailyThings')
          ? jsonData['dailyThings'] as List<dynamic>
          : jsonData as List<dynamic>;

      final restoredThings = thingsList.map((json) {
        final item = DailyThing.fromJson(json as Map<String, dynamic>);
        // Crucially, clear the history when restoring from a template
        return item.copyWith(history: []);
      }).toList();

      _log.info(
          'Restored ${restoredThings.length} items from template: ${templateFile.path}');
      return restoredThings;
    } catch (e, s) {
      _log.severe('Error restoring from template: ${templateFile.path}', e, s);
      rethrow;
    }
  }

  /// Check if automatic backups are enabled
  Future<bool> isBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKeyBackupEnabled) ?? _defaultBackupEnabled;
  }

  /// Enable or disable automatic backups
  Future<void> setBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyBackupEnabled, enabled);
    _log.info('Backup ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Set the backup directory path
  Future<void> setBackupLocation(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyBackupLocation, path);
    _log.info('Backup location set to: $path');
  }

  /// Create a backup with timestamped filename
  Future<bool> createBackup(List<DailyThing> items, BackupType type) async {
    try {
      final backupEnabled = await isBackupEnabled();
      if (!backupEnabled) {
        _log.fine('Backup skipped - backups are disabled');
        return false;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final versionText = '${packageInfo.version}+${packageInfo.buildNumber}';

      final Map<String, dynamic> backupData;

      if (type == BackupType.template) {
        // For templates, serialize without history
        backupData = {
          'dailyThings': items
              .map((thing) => thing.toJson(includeHistory: false))
              .toList(),
          'backupCreatedAt': DateTime.now().toIso8601String(),
          'appVersion': versionText,
        };
        final jsonString =
            const JsonEncoder.withIndent('  ').convert(backupData);
        await writeTemplate(jsonString);
      } else {
        // For full backups, serialize with history
        backupData = {
          'dailyThings': items.map((thing) => thing.toJson()).toList(),
          'backupCreatedAt': DateTime.now().toIso8601String(),
          'appVersion': versionText,
        };
        final jsonString =
            const JsonEncoder.withIndent('  ').convert(backupData);
        await writeBackup(jsonString);
      }

      _log.fine('Backup of type $type created successfully.');

      await _setLastBackupTime(DateTime.now());

      // Clean up old backups (excluding the latest file)
      if (type == BackupType.full) {
        await _cleanupOldBackups();
      }

      return true;
    } catch (e, s) {
      _log.severe('Error creating backup', e, s);
      return false;
    }
  }

  /// Set the last backup time
  Future<void> _setLastBackupTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyLastBackupTime, time.millisecondsSinceEpoch);
  }

  /// Cleans up old backups using a tiered retention policy.
  ///
  /// This policy keeps:
  /// - All backups from the last 7 days.
  /// - The first backup of each week for the last month.
  /// - The first backup of each month for the last year.
  /// - The first backup of each year indefinitely.
  Future<void> _cleanupOldBackups() async {
    try {
      final backupDir = await getBackupsDir();
      final files = backupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json') && f.path.contains('backup_'))
          .toList();

      // Sort newest to oldest
      files.sort((a, b) => b.path.compareTo(a.path));

      final now = DateTime.now();
      final Set<File> toKeep = {};
      final Set<String> weeklyMarkers = {};
      final Set<String> monthlyMarkers = {};
      final Set<String> yearlyMarkers = {};

      for (final file in files) {
        final fileName = file.path.split('/').last;
        final dateString = fileName.substring(7, 17); // yyyy-MM-dd
        final fileDate = DateFormat('yyyy-MM-dd').parse(dateString);

        // 1. Keep all backups within the last 7 days
        if (now.difference(fileDate).inDays <= 7) {
          toKeep.add(file);
          continue;
        }

        // 2. Keep one backup per week for the last month
        if (now.difference(fileDate).inDays <= 30) {
          final weekMarker =
              '${fileDate.year}-${fileDate.weekday}'; // Week of year
          if (!weeklyMarkers.contains(weekMarker)) {
            toKeep.add(file);
            weeklyMarkers.add(weekMarker);
          }
          continue;
        }

        // 3. Keep one backup per month for the last year
        if (now.difference(fileDate).inDays <= 365) {
          final monthMarker = '${fileDate.year}-${fileDate.month}';
          if (!monthlyMarkers.contains(monthMarker)) {
            toKeep.add(file);
            monthlyMarkers.add(monthMarker);
          }
          continue;
        }

        // 4. Keep one backup per year indefinitely
        final yearMarker = '${fileDate.year}';
        if (!yearlyMarkers.contains(yearMarker)) {
          toKeep.add(file);
          yearlyMarkers.add(yearMarker);
        }
      }

      int deletedCount = 0;
      for (final file in files) {
        if (!toKeep.contains(file)) {
          file.deleteSync();
          deletedCount++;
          _log.fine('Deleted old backup: ${file.path}');
        }
      }

      if (deletedCount > 0) {
        _log.info('Cleaned up $deletedCount old backup(s)');
      }
    } catch (e, s) {
      _log.warning('Error cleaning up old backups', e, s);
    }
  }
}
