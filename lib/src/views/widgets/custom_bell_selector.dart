import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:daily_inc/src/core/asset_utils.dart';
import 'package:logging/logging.dart';

class CustomBellSelectorDialog extends StatefulWidget {
  final String? initialBellSoundPath;

  const CustomBellSelectorDialog({super.key, this.initialBellSoundPath});

  @override
  State<CustomBellSelectorDialog> createState() => _CustomBellSelectorDialogState();
}

class _CustomBellSelectorDialogState extends State<CustomBellSelectorDialog> {
  final _log = Logger('CustomBellSelectorDialog');
  List<String> _bellSoundPaths = [];
  String? _selectedBellSoundPath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingPath;

  @override
  void initState() {
    super.initState();
    _selectedBellSoundPath = widget.initialBellSoundPath;
    _loadBellSounds();

    _audioPlayer.onPlayerComplete.listen((event) {
      _log.info('Player complete: $_currentlyPlayingPath');
      setState(() {
        _currentlyPlayingPath = null;
      });
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _log.info('Player state changed: $state for $_currentlyPlayingPath');
    });
  }

  Future<void> _loadBellSounds() async {
    try {
      final paths = await AssetUtils.getBellSoundPaths();
      _log.info('Loaded bell sound paths: $paths');
      setState(() {
        _bellSoundPaths = paths;
      });
    } catch (e, s) {
      _log.severe('Error loading bell sounds', e, s);
    }
  }

  Future<void> _playBellSound(String path) async {
    try {
      final assetPath = path.replaceFirst('assets/', ''); // Remove leading 'assets/'
      if (_currentlyPlayingPath == path) {
        _log.info('Stopping currently playing sound: $path');
        await _audioPlayer.stop();
        setState(() {
          _currentlyPlayingPath = null;
        });
      } else {
        _log.info('Playing new sound: $path (AssetSource: $assetPath)');
        await _audioPlayer.stop(); // Stop any currently playing sound
        await _audioPlayer.play(AssetSource(assetPath));
        setState(() {
          _currentlyPlayingPath = path;
        });
      }
    } catch (e, s) {
      _log.severe('Error playing bell sound: $path', e, s);
    }
  }

  void _selectBellSound(String path) {
    setState(() {
      _selectedBellSoundPath = path;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Bell Sound'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _bellSoundPaths.map((path) {
          final fileName = path.split('/').last;
          final isSelected = _selectedBellSoundPath == path;
          final isPlaying = _currentlyPlayingPath == path;

          return ListTile(
            title: Text(fileName),
            leading: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Colors.white : null,
            ),
            trailing: IconButton(
              icon: Icon(
                isPlaying ? Icons.stop : Icons.play_arrow,
              ),
              onPressed: () => _playBellSound(path),
            ),
            onTap: () => _selectBellSound(path),
            selected: isSelected,
            selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedBellSoundPath);
          },
          child: const Text('Select'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null); // User cancelled
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}