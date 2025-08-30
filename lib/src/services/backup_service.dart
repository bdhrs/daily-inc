import 'dart:convert';
import 'dart:io';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static const String _prefsKeyBackupEnabled = 'backupEnabled';
  static const String _prefsKeyBackupLocation = 'backupLocation';
  static const String _prefsKeyBackupRetentionDays = 'backupRetentionDays';
  static const String _prefsKeyLastBackupTime = 'lastBackupTime';
  static const String _prefsKeyFirstAppUseDate = 'firstAppUseDate';
  static const String _prefsKeyBackupPromptShown = 'backupPromptShown';

  static const bool _defaultBackupEnabled = false;
  static const int _defaultBackupRetentionDays = 30;

  final _log = Logger('BackupService');

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

  /// Get the backup directory path
  Future<String?> getBackupLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKeyBackupLocation);
  }

  /// Set the backup directory path
  Future<void> setBackupLocation(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyBackupLocation, path);
    _log.info('Backup location set to: $path');
  }

  /// Get backup retention days
  Future<int> getBackupRetentionDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsKeyBackupRetentionDays) ??
        _defaultBackupRetentionDays;
  }

  /// Set backup retention days
  Future<void> setBackupRetentionDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyBackupRetentionDays, days);
    _log.info('Backup retention set to $days days');
  }

  /// Get the last backup time
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_prefsKeyLastBackupTime);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Set the last backup time
  Future<void> _setLastBackupTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyLastBackupTime, time.millisecondsSinceEpoch);
  }

  /// Record first app use if not already recorded
  Future<void> recordFirstAppUse() async {
    final prefs = await SharedPreferences.getInstance();
    final firstUse = prefs.getString(_prefsKeyFirstAppUseDate);
    if (firstUse == null) {
      final now = DateTime.now().toIso8601String();
      await prefs.setString(_prefsKeyFirstAppUseDate, now);
      _log.info('Recorded first app use: $now');
    }
  }

  /// Check if backup prompt should be shown (after 1 day of first use)
  Future<bool> shouldShowBackupPrompt() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if prompt was already shown and declined
    if (prefs.getBool(_prefsKeyBackupPromptShown) == true) {
      return false;
    }

    // Check if backups are already enabled - if so, no need to prompt
    final backupEnabled =
        prefs.getBool(_prefsKeyBackupEnabled) ?? _defaultBackupEnabled;
    if (backupEnabled) {
      return false;
    }

    final firstUseString = prefs.getString(_prefsKeyFirstAppUseDate);
    if (firstUseString == null) {
      return false;
    }

    try {
      final firstUseDate = DateTime.parse(firstUseString);
      final oneDayLater = firstUseDate.add(const Duration(days: 1));
      final now = DateTime.now();

      return now.isAfter(oneDayLater);
    } catch (e) {
      _log.warning('Error parsing first use date', e);
      return false;
    }
  }

  /// Mark backup prompt as shown (user either configured or declined)
  Future<void> markBackupPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyBackupPromptShown, true);
    _log.info('Backup prompt marked as shown');
  }

  /// Show backup setup dialog with options to configure or decline
  Future<bool?> showBackupSetupDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Protect Your Data'),
          content: const Text(
            'You\'ve been using Daily Inc for a while now. Would you like to set up automatic backups to protect your progress?\n\n'
            'Backups will be created automatically whenever your data changes and saved to a location of your choice.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Decline
              },
              child: const Text('Not Now'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Configure
              },
              child: const Text('Set Up Backups'),
            ),
          ],
        );
      },
    );
  }

  /// Create a backup with timestamped filename and always keep a "latest" version
  Future<bool> createBackup(List<DailyThing> items) async {
    try {
      final backupEnabled = await isBackupEnabled();
      if (!backupEnabled) {
        _log.fine('Backup skipped - backups are disabled');
        return false;
      }

      // Always use the default backup directory to avoid permission issues on Android
      final backupLocation = await getDefaultBackupDirectory();
      await setBackupLocation(backupLocation); // Ensure setting is updated

      final backupDir = Directory(backupLocation);
      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
        _log.info('Created backup directory: $backupLocation');
      }

      return await _createBackupInDirectory(backupDir, items);
    } catch (e, s) {
      _log.severe('Error creating backup', e, s);
      return false;
    }
  }

  /// Create a backup in the specified directory
  Future<bool> _createBackupInDirectory(Directory backupDir, List<DailyThing> items) async {
    try {
      // Generate backup filenames
      final timestamp = DateTime.now();
      final timestampedFilename =
          'daily_inc_backup_${timestamp.toIso8601String().replaceAll(':', '-')}.json';
      final latestFilename = 'daily_inc_backup_latest.json';

      final timestampedBackupFile =
          File('${backupDir.path}/$timestampedFilename');
      final latestBackupFile = File('${backupDir.path}/$latestFilename');

      // Prepare backup data with actual app version
      final packageInfo = await PackageInfo.fromPlatform();
      final versionText = '${packageInfo.version}+${packageInfo.buildNumber}';

      final backupData = {
        'dailyThings': items.map((thing) => thing.toJson()).toList(),
        'backupCreatedAt': timestamp.toIso8601String(),
        'appVersion': versionText,
      };

      // Write backup files
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Write timestamped backup
      await timestampedBackupFile.writeAsString(jsonString);

      // Always write/overwrite the latest backup
      await latestBackupFile.writeAsString(jsonString);

      _log.fine('Backup created successfully: ${timestampedBackupFile.path}');
      _log.fine('Latest backup updated: ${latestBackupFile.path}');

      await _setLastBackupTime(timestamp);

      // Clean up old backups (excluding the latest file)
      await _cleanupOldBackups(backupDir);

      return true;
    } catch (e, s) {
      _log.severe('Error creating backup in directory: ${backupDir.path}', e, s);
      return false;
    }
  }

  /// Clean up backups older than retention period (excluding the latest backup)
  Future<void> _cleanupOldBackups(Directory backupDir) async {
    try {
      final retentionDays = await getBackupRetentionDays();
      final cutoffTime = DateTime.now().subtract(Duration(days: retentionDays));

      final backupFiles = backupDir.listSync().whereType<File>().where((file) {
        return file.path.endsWith('.json') &&
            file.path.contains('daily_inc_backup_') &&
            !file.path.endsWith('daily_inc_backup_latest.json');
      }).toList();

      int deletedCount = 0;
      for (final file in backupFiles) {
        final stat = file.statSync();
        if (stat.modified.isBefore(cutoffTime)) {
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

  /// Get list of available backups
  Future<List<FileSystemEntity>> getAvailableBackups() async {
    final backupLocation = await getBackupLocation();
    if (backupLocation == null || backupLocation.isEmpty) {
      return [];
    }

    final backupDir = Directory(backupLocation);
    if (!backupDir.existsSync()) {
      return [];
    }

    return backupDir.listSync().whereType<File>().where((file) {
      return file.path.endsWith('.json') &&
          file.path.contains('daily_inc_backup_');
    }).toList();
  }

  /// Restore from a specific backup file
  Future<List<DailyThing>> restoreFromBackup(File backupFile) async {
    try {
      final contents = await backupFile.readAsString();
      final jsonData = jsonDecode(contents) as Map<String, dynamic>;
      final thingsList = jsonData['dailyThings'] as List<dynamic>;

      final restoredThings = thingsList
          .map((json) => DailyThing.fromJson(json as Map<String, dynamic>))
          .toList();

      _log.info(
          'Restored ${restoredThings.length} items from backup: ${backupFile.path}');
      return restoredThings;
    } catch (e, s) {
      _log.severe('Error restoring from backup', e, s);
      rethrow;
    }
  }

  /// Get default backup directory (Documents/DailyIncBackups)
  Future<String> getDefaultBackupDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return '${documentsDir.path}/DailyIncBackups';
  }
}
