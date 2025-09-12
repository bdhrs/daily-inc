import 'package:audioplayers/audioplayers.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:logging/logging.dart';

/// Helper class for handling audio playback functionality
class AudioHelper {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _subdivisionAudioPlayer = AudioPlayer();
  final Logger _log = Logger('AudioHelper');

  /// Plays the timer completion notification sound
  Future<void> playTimerCompleteNotification(DailyThing currentItem) async {
    _log.info('Playing timer complete notification');

    try {
      final bellPath = (currentItem.bellSoundPath ?? 'assets/bells/bell1.mp3')
          .replaceFirst('assets/', '');
      // Don't await the play operation - let it run in background
      _audioPlayer.play(AssetSource(bellPath));
    } catch (e) {
      _log.warning('Failed to play bell sound: $e');
    }
  }

  /// Plays the subdivision bell sound
  Future<void> playSubdivisionBell(DailyThing currentItem) async {
    _log.info('Playing subdivision bell');

    try {
      final bellPath =
          (currentItem.subdivisionBellSoundPath ?? 'assets/bells/bell1.mp3')
              .replaceFirst('assets/', '');
      // Stop any currently playing subdivision bell to ensure the new one plays
      await _subdivisionAudioPlayer.stop();
      // Don't await the play operation - let it run in background
      _subdivisionAudioPlayer.play(AssetSource(bellPath));
    } catch (e) {
      _log.warning('Failed to play subdivision bell sound: $e');
    }
  }

  /// Disposes of the audio players to free up resources
  void dispose() {
    _audioPlayer.dispose();
    _subdivisionAudioPlayer.dispose();
  }
}
