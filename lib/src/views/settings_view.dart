import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _log = Logger('SettingsView');
  bool _stickyNotifications = false;

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
        ],
      ),
    );
  }
}
