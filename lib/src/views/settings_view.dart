import 'package:daily_inc/src/data/data_manager.dart';
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
  bool _hideWhenDone = false;
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
      _hideWhenDone = prefs.getBool('hideWhenDone') ?? false;
    });
    _log.info('Settings loaded: hideWhenDone=$_hideWhenDone');
  }

  Future<void> _updateHideWhenDone(bool value) async {
    _log.info('Updating hideWhenDone to: $value');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hideWhenDone', value);
    setState(() {
      _hideWhenDone = value;
    });
    _log.info('hideWhenDone updated successfully.');
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
          navigator.pop();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('All data has been reset'),
              duration: Duration(seconds: 2),
            ),
          );
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
          SwitchListTile(
            title: const Text('Hide Completed Items'),
            value: _hideWhenDone,
            onChanged: _updateHideWhenDone,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.warningOrange,
            ),
            onPressed: _resetAllData,
            child: const Text('Reset All Data'),
          ),
        ],
      ),
    );
  }
}
