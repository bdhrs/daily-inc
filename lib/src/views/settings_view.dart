import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/views/daily_things_view.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:daily_inc/src/theme/color_palette.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _log = Logger('SettingsView');
  bool _stickyNotifications = false;
  final DataManager _dataManager = DataManager();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _log.info('Loading settings...');
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _stickyNotifications = prefs.getBool('stickyNotifications') ?? false;
    });
    _log.info('Settings loaded: stickyNotifications=$_stickyNotifications');
  }

  Future<void> _updateStickyNotifications(bool value) async {
    _log.info('Updating sticky notifications to: $value');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('stickyNotifications', value);
    setState(() {
      _stickyNotifications = value;
    });
    _log.info('Sticky notifications updated successfully.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Sticky Notifications'),
            value: _stickyNotifications,
            onChanged: _updateStickyNotifications,
          ),
          const Divider(
            height: 32,
            thickness: 2,
            indent: 16,
            endIndent: 16,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
            child: ListTile(
              title: const Text('Hard Reset'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.warningOrange,
                  foregroundColor: ColorPalette.lightText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirm Reset'),
                        content: const Text(
                            'Are you sure you want to reset? You will lose all data! Do you want to save first?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              _log.info('Save and Reset pressed');
                              final navigator = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              final theme = Theme.of(context);
                              _handleSaveAndReset(navigator, messenger, theme);
                            },
                            child: const Text('Save and Reset'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: ColorPalette.warningOrange,
                            ),
                            onPressed: () {
                              _log.info('Reset pressed');
                              final navigator = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              final theme = Theme.of(context);
                              _handleReset(navigator, messenger, theme);
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded),
                    SizedBox(width: 8),
                    Text('Reset'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveAndReset(NavigatorState navigator,
      ScaffoldMessengerState messenger, ThemeData theme) async {
    bool saved = await _dataManager.saveHistoryToFile();
    if (saved) {
      await _dataManager.resetData();
      if (mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DailyThingsView()),
          (route) => false,
        );
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Data saved and reset successfully.'),
            duration: const Duration(seconds: 2),
            backgroundColor: theme.snackBarTheme.backgroundColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      _log.info('Save operation cancelled or failed.');
      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: const Text(
                'Save operation cancelled or failed. Data not reset.'),
            duration: const Duration(seconds: 2),
            backgroundColor: theme.snackBarTheme.backgroundColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleReset(NavigatorState navigator,
      ScaffoldMessengerState messenger, ThemeData theme) async {
    await _dataManager.resetData();
    if (mounted) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DailyThingsView()),
        (route) => false,
      );
      messenger.showSnackBar(
        SnackBar(
          content: const Text('All data has been reset.'),
          duration: const Duration(seconds: 2),
          backgroundColor: theme.snackBarTheme.backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
