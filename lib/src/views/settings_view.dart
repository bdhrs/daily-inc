import 'package:daily_inc/src/core/increment_calculator.dart';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/services/backup_service.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:daily_inc/src/theme/color_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SettingsView extends StatefulWidget {
  final VoidCallback? onResetAllData;

  const SettingsView({super.key, this.onResetAllData});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _log = Logger('SettingsView');
  final DataManager _dataManager = DataManager();

  // Motivational message settings
  bool _showStartOfDayMessage = false;
  String _startOfDayMessageText = 'Finish all your things today!';
  bool _showCompletionMessage = false;
  String _completionMessageText = 'Well done! You did it!';

  // Grace period setting
  int _gracePeriodDays = 1; // Default to 1 day

  // Screen dimmer setting
  bool _dimScreenMode = false;
  
  // Minimalist mode setting
  bool _minimalistMode = false;

  // Backup settings
  bool _backupEnabled = false;
  String _backupLocation = '';
  int _backupRetentionDays = 30;
  DateTime? _lastBackupTime;

  late TextEditingController _startOfDayMessageController;
  late TextEditingController _completionMessageController;
  late TextEditingController _backupLocationController;

  @override
  void initState() {
    super.initState();
    _startOfDayMessageController = TextEditingController();
    _completionMessageController = TextEditingController();
    _backupLocationController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _startOfDayMessageController.dispose();
    _completionMessageController.dispose();
    _backupLocationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final backupService = BackupService();
    final defaultBackupPath = await backupService.getDefaultBackupDirectory();

    setState(() {
      _showStartOfDayMessage = prefs.getBool('showStartOfDayMessage') ?? false;
      _startOfDayMessageText = prefs.getString('startOfDayMessageText') ??
          'Finish all your things today!';
      _showCompletionMessage = prefs.getBool('showCompletionMessage') ?? false;
      _completionMessageText =
          prefs.getString('completionMessageText') ?? 'Well done! You did it!';
      _gracePeriodDays =
          prefs.getInt('gracePeriodDays') ?? 1; // Default to 1 day
      _dimScreenMode =
          prefs.getBool('dimScreenMode') ?? false; // Load dim screen mode
      _minimalistMode =
          prefs.getBool('minimalistMode') ?? false; // Load minimalist mode

      // Load backup settings
      _backupEnabled = prefs.getBool('backupEnabled') ?? false;
      // Always use the default backup location
      _backupLocation = defaultBackupPath;
      _backupRetentionDays = prefs.getInt('backupRetentionDays') ?? 30;

      final lastBackupTimestamp = prefs.getInt('lastBackupTime');
      _lastBackupTime = lastBackupTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(lastBackupTimestamp)
          : null;
    });
    // Update the static variable in IncrementCalculator
    IncrementCalculator.setGracePeriod(_gracePeriodDays);

    // Update controllers after loading settings
    _startOfDayMessageController.text = _startOfDayMessageText;
    _completionMessageController.text = _completionMessageText;
    _backupLocationController.text = _backupLocation;
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showStartOfDayMessage', _showStartOfDayMessage);
    await prefs.setString('startOfDayMessageText', _startOfDayMessageText);
    await prefs.setBool('showCompletionMessage', _showCompletionMessage);
    await prefs.setString('completionMessageText', _completionMessageText);
    await prefs.setInt('gracePeriodDays', _gracePeriodDays);
    await prefs.setBool(
        'dimScreenMode', _dimScreenMode); // Save dim screen mode
    await prefs.setBool(
        'minimalistMode', _minimalistMode); // Save minimalist mode

    // Save backup settings
    await prefs.setBool('backupEnabled', _backupEnabled);
    // No need to save backupLocation as it's always the default
    await prefs.setInt('backupRetentionDays', _backupRetentionDays);

    // Update the static variable in IncrementCalculator
    IncrementCalculator.setGracePeriod(_gracePeriodDays);
    _log.info('Settings saved');
  }

  Future<void> _createManualBackup() async {
    try {
      final backupService = BackupService();
      final dataManager = DataManager();
      final items = await dataManager.loadData();

      final success = await backupService.createBackup(items);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Backup created successfully!'
                : 'Backup failed. Check backup settings.'),
            duration: const Duration(seconds: 2),
          ),
        );

        if (success) {
          // Reload settings to update last backup time
          await _loadSettings();
        }
      }
    } catch (e, s) {
      _log.warning('Error creating manual backup', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _resetAllData() async {
    _log.info('Resetting all data...');
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
            'This will delete ALL your daily items and history. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Reset',
              style: TextStyle(color: ColorPalette.warningOrange),
            ),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      _log.info('User confirmed data reset');
      try {
        await _dataManager.resetAllData();
        if (mounted) {
          // Call the callback to reset data in the main view
          widget.onResetAllData?.call();
          // Pop back to the main screen
          navigator.popUntil((route) => route.isFirst);
          // Show snackbar after navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('All data has been reset'),
                duration: Duration(seconds: 2),
              ),
            );
          });
        }
      } catch (e) {
        _log.warning('Error resetting data: $e');
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
                content: Text('Error resetting data: $e'),
                duration: const Duration(seconds: 2)),
          );
        }
      }
    } else {
      _log.info('Reset operation cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Motivational Messages Section
          const Text(
            'Motivational Messages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Start of Day Message Settings
          SwitchListTile(
            title: const Text('Show start of day message'),
            value: _showStartOfDayMessage,
            onChanged: (value) {
              setState(() {
                _showStartOfDayMessage = value;
              });
              _saveSettings();
            },
          ),
          if (_showStartOfDayMessage)
            Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Start of day message',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: null,
                controller: _startOfDayMessageController,
                onChanged: (value) {
                  _startOfDayMessageText = value;
                  _saveSettings();
                },
              ),
            ),

          // Completion Message Settings
          SwitchListTile(
            title: const Text('Show completion message'),
            value: _showCompletionMessage,
            onChanged: (value) {
              setState(() {
                _showCompletionMessage = value;
              });
              _saveSettings();
            },
          ),
          if (_showCompletionMessage)
            Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Completion message',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: null,
                controller: _completionMessageController,
                onChanged: (value) {
                  _completionMessageText = value;
                  _saveSettings();
                },
              ),
            ),

          const Divider(),
          const SizedBox(height: 16),

          // Grace Period Section
          const Text(
            'Grace Period',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Number of days before penalties are applied for missed tasks:',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _gracePeriodDays.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: '$_gracePeriodDays days',
                  onChanged: (value) {
                    setState(() {
                      _gracePeriodDays = value.toInt();
                    });
                    _saveSettings();
                  },
                ),
              ),
              Text('$_gracePeriodDays days'),
            ],
          ),
          const SizedBox(height: 16),

          const Divider(),
          const SizedBox(height: 16),

          // Timer Options Section
          const Text(
            'Timer Options',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Dim screen during timer'),
            subtitle:
                const Text('Fade to black after 10 seconds to save battery'),
            value: _dimScreenMode,
            onChanged: (value) {
              setState(() {
                _dimScreenMode = value;
              });
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Minimalist mode'),
            subtitle: const Text('Show only timer and comment when finished'),
            value: _minimalistMode,
            onChanged: (value) {
              setState(() {
                _minimalistMode = value;
              });
              _saveSettings();
            },
          ),
          const SizedBox(height: 16),

          const Divider(),
          const SizedBox(height: 16),

          // Backup Settings Section
          const Text(
            'Automatic Backups',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Automatically save backups whenever your data changes:',
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text('Enable automatic backups'),
            value: _backupEnabled,
            onChanged: (value) {
              setState(() {
                _backupEnabled = value;
              });
              _saveSettings();
            },
          ),

          if (_backupEnabled) ...[
            const SizedBox(height: 8),
            const Text('Backup location:'),
            const SizedBox(height: 8),
            Text(
              _backupLocation,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('Keep backups for:'),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _backupRetentionDays.toDouble(),
                    min: 7,
                    max: 365,
                    divisions: 12,
                    label: '$_backupRetentionDays days',
                    onChanged: (value) {
                      setState(() {
                        _backupRetentionDays = value.toInt();
                      });
                      _saveSettings();
                    },
                  ),
                ),
                Text('$_backupRetentionDays days'),
              ],
            ),
            if (_lastBackupTime != null)
              Text(
                'Last backup: ${_lastBackupTime!.toString().split(' ')[0]} ${_lastBackupTime!.toString().split(' ')[1].substring(0, 5)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.backup),
              label: const Text('Create Backup Now'),
              onPressed: _createManualBackup,
            ),
          ],

          const Divider(),
          const SizedBox(height: 16),

          // Reset Data Section
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.warningOrange,
            ),
            onPressed: _resetAllData,
            icon: const Icon(Icons.warning, color: Colors.white),
            label: const Text('Reset All Data'),
          ),
        ],
      ),
    );
  }
}
