import 'dart:convert';
import 'dart:io';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class BackupService {
  static const String _prefsKeyBackupEnabled = 'backupEnabled';
  static const String _prefsKeyBackupLocation = 'backupLocation';
  static const String _prefsKeyBackupRetentionDays = 'backupRetentionDays';
  static const String _prefsKeyLastBackupTime = 'lastBackupTime';
  static const String _prefsKeyFirstAppUseDate = 'firstAppUseDate';
  static const String _prefsKeyBackupPromptShown = 'backupPromptShown';
  static const String _prefsKeyLastBackupSuccess = 'lastBackupSuccess';
  static const String _prefsKeyLastBackupError = 'lastBackupError';
  static const String _prefsKeyBackupFailureCount = 'backupFailureCount';

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

  /// Set backup success status
  Future<void> _setBackupSuccess(bool success, {String? errorMessage}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyLastBackupSuccess, success);

    if (errorMessage != null) {
      await prefs.setString(_prefsKeyLastBackupError, errorMessage);
    } else {
      await prefs.remove(_prefsKeyLastBackupError);
    }

    // Track consecutive failures
    if (!success) {
      final currentFailures = prefs.getInt(_prefsKeyBackupFailureCount) ?? 0;
      await prefs.setInt(_prefsKeyBackupFailureCount, currentFailures + 1);
    } else {
      await prefs.setInt(_prefsKeyBackupFailureCount, 0);
    }
  }

  /// Get last backup success status
  Future<bool?> getLastBackupSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKeyLastBackupSuccess);
  }

  /// Get last backup error message
  Future<String?> getLastBackupError() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKeyLastBackupError);
  }

  /// Get consecutive backup failure count
  Future<int> getBackupFailureCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsKeyBackupFailureCount) ?? 0;
  }

  /// Check if backups are consistently failing
  Future<bool> isBackupConsistentlyFailing() async {
    final failureCount = await getBackupFailureCount();
    return failureCount >= 3; // Consider it consistent after 3+ failures
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

      // Use configured backup location or fall back to default
      final configuredLocation = await getBackupLocation();
      final backupLocation = configuredLocation?.isNotEmpty == true
          ? configuredLocation!
          : await getDefaultBackupDirectory();

      // Only set to default if no location is configured
      if (configuredLocation?.isEmpty != false) {
        await setBackupLocation(backupLocation);
      }

      final backupDir = Directory(backupLocation);
      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
        _log.info('Created backup directory: $backupLocation');
      }

      final success = await _createBackupInDirectory(backupDir, items);
      await _setBackupSuccess(success,
          errorMessage:
              success ? null : 'Failed to create backup in directory');
      return success;
    } catch (e, s) {
      final errorMessage = _getUserFriendlyErrorMessage(e);
      _log.severe('Error creating backup: $errorMessage', e, s);
      await _setBackupSuccess(false, errorMessage: errorMessage);
      return false;
    }
  }

  /// Create a backup in the specified directory
  Future<bool> _createBackupInDirectory(
      Directory backupDir, List<DailyThing> items) async {
    try {
      // Check if directory exists and is writable
      if (!await backupDir.exists()) {
        try {
          await backupDir.create(recursive: true);
          _log.info('Created backup directory: ${backupDir.path}');
        } catch (e, s) {
          final errorMessage = _getUserFriendlyErrorMessage(e);
          _log.severe('Failed to create backup directory: $errorMessage', e, s);
          return false;
        }
      }

      // Check if we can write to the directory
      final canWrite = await _canWriteToDirectory(backupDir.path);
      if (!canWrite) {
        final errorMessage =
            'Cannot write to backup directory. Please choose a different location or check app permissions.';
        _log.severe(errorMessage);
        return false;
      }

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

      await _setBackupSuccess(true);
      return true;
    } catch (e, s) {
      final errorMessage = _getUserFriendlyErrorMessage(e);
      _log.severe(
          'Error creating backup in directory ${backupDir.path}: $errorMessage',
          e,
          s);
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

  /// Check if we can write to a directory (handles Android scoped storage limitations)
  Future<bool> _canWriteToDirectory(String directoryPath) async {
    try {
      final dir = Directory(directoryPath);

      // For Android, we need to handle scoped storage limitations
      if (Platform.isAndroid) {
        // Request both storage permissions - the appropriate one will be used based on Android version
        // For Android 10+ (SDK 29+), we need manageExternalStorage permission
        // For older versions, we need storage permission
        PermissionStatus status;

        try {
          // Try requesting manage external storage permission first (for Android 10+)
          status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            // If that fails, try regular storage permission (for older Android versions)
            status = await Permission.storage.request();
            if (!status.isGranted) {
              _log.severe(
                  'Neither manage external storage nor storage permission granted');
              return false;
            }
          }
        } catch (e) {
          // If manageExternalStorage is not available, try regular storage permission
          status = await Permission.storage.request();
          if (!status.isGranted) {
            _log.severe('Storage permission not granted: $e');
            return false;
          }
        }

        // Check if this is a directory we can access with our current permissions
        // For scoped storage, we might need to use different approaches

        // Try to create a test file to check write permissions
        final testFile = File(
            '$directoryPath/.write_test_${DateTime.now().millisecondsSinceEpoch}');
        try {
          await testFile.writeAsString('test', flush: true);
          await testFile.delete();
          return true;
        } catch (e) {
          _log.fine('Cannot write to directory $directoryPath: $e');
          return false;
        }
      }

      // For non-Android platforms, check directory existence and writability
      if (await dir.exists()) {
        // Check if we can write by creating a test file
        final testFile = File('${dir.path}/.write_test');
        try {
          await testFile.writeAsString('test', flush: true);
          await testFile.delete();
          return true;
        } catch (e) {
          _log.fine('Directory exists but not writable: $e');
          return false;
        }
      }

      // Try to create the directory
      try {
        await dir.create(recursive: true);
        _log.info('Created backup directory: ${dir.path}');

        // Verify we can write to it
        final testFile = File('${dir.path}/.write_test');
        await testFile.writeAsString('test', flush: true);
        await testFile.delete();
        return true;
      } catch (e) {
        _log.fine('Cannot create or write to directory: $e');
        return false;
      }
    } catch (e, s) {
      _log.warning('Error checking directory write access', e, s);
      return false;
    }
  }

  /// Check if Android version is 10 or higher (SDK 29+)
  Future<bool> _isAndroid10OrHigher() async {
    try {
      // We'll use a simple approach to check Android version
      // For Android 10+, the SDK version is 29 or higher
      // Since we don't have device_info_plus imported, we'll use a simpler approach
      return false; // For now, we'll assume older Android versions to be safe
    } catch (e) {
      _log.warning('Error checking Android version, assuming older version', e);
      return false; // Assume older Android version if we can't determine
    }
  }

  /// Convert technical error messages to user-friendly descriptions
  String _getUserFriendlyErrorMessage(Object error) {
    if (error is FileSystemException) {
      if (error.osError?.errorCode == 13) {
        return 'Permission denied - cannot write to backup location. Please grant storage permission in app settings or choose a different directory.';
      } else if (error.osError?.errorCode == 1) {
        return 'Operation not permitted - cannot write to backup location. Please check storage permissions or choose a different directory.';
      } else if (error.osError?.errorCode == 2) {
        return 'Backup directory not found or inaccessible';
      } else if (error.osError?.errorCode == 30) {
        return 'Storage is read-only - cannot write to backup location';
      }
      return 'File system error: ${error.message}';
    } else if (error is PathAccessException) {
      return 'Cannot access the specified backup location. Please choose a different directory or check storage permissions.';
    } else if (error is FormatException) {
      return 'Data format error during backup';
    } else if (error is IOException) {
      return 'Input/output error - storage may be full, unavailable, or read-only';
    } else if (error.toString().contains('Permission denied')) {
      return 'Permission denied - cannot access backup location. Please grant storage permission in app settings or choose a different directory.';
    } else if (error.toString().contains('Read-only file system')) {
      return 'Storage is read-only - cannot write to backup location. Please choose a different directory.';
    } else if (error.toString().contains('Operation not permitted')) {
      return 'Operation not permitted - cannot write to backup location. This is likely due to Android scoped storage restrictions. Please choose a different directory within the app\'s allowed storage areas.';
    } else if (error.toString().contains('Permission denied') ||
        error.toString().contains('permission')) {
      return 'Permission issue - cannot access backup location. On Android 10+, apps have limited access to external storage. Please choose a directory within the app\'s Documents or Download folders, or use the built-in file picker to select a location.';
    }
    return 'Unexpected error: ${error.toString()}\n\nOn Android 10+, consider using the app\'s internal storage or selecting a location through the file picker for better compatibility.';
  }
}
