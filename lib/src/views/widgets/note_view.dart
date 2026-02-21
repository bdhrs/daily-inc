import 'package:flutter/material.dart';
import 'package:daily_inc/src/theme/color_palette.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:daily_inc/src/core/time_converter.dart';

class NoteViewWidget extends StatelessWidget {
  final DailyThing currentItem;
  final bool isOvertime;
  final bool isPaused;
  final double todaysTargetMinutes;
  final double overtimeSeconds;
  final double currentElapsedTimeInMinutes;
  final int completedSubdivisions;
  final int? subdivisions;
  final String Function() getButtonText;
  final VoidCallback toggleTimer;
  final VoidCallback toggleNoteViewMode;
  final VoidCallback showNoteDialogInEditMode;

  const NoteViewWidget({
    super.key,
    required this.currentItem,
    required this.isOvertime,
    required this.isPaused,
    required this.todaysTargetMinutes,
    required this.overtimeSeconds,
    required this.currentElapsedTimeInMinutes,
    required this.completedSubdivisions,
    required this.subdivisions,
    required this.getButtonText,
    required this.toggleTimer,
    required this.toggleNoteViewMode,
    required this.showNoteDialogInEditMode,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        // When back button is pressed in note view mode, just toggle back to normal mode
        toggleNoteViewMode();
      },
      child: Scaffold(
        backgroundColor: ColorPalette.darkBackground,
        appBar: AppBar(
          backgroundColor: ColorPalette.darkBackground,
          toolbarHeight: 48, // Reduced from default ~56 to save vertical space
          title: Text(
            currentItem.name,
            style: const TextStyle(
              fontSize: 16, // Reduced from 18 to save space
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
          elevation: 0,
          // Add a close button to the app bar
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: toggleNoteViewMode,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0), // Reduced from 16.0
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Information Bar
                _buildNoteViewTopBar(),
                const SizedBox(height: 12), // Reduced from 16
                // Main Notes Display
                Expanded(
                  child: _buildNoteViewNotesDisplay(),
                ),
                const SizedBox(height: 12), // Reduced from 16
                // Bottom Action Buttons
                _buildNoteViewBottomButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the Top Information Bar for Note View mode
  Widget _buildNoteViewTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 8), // Reduced padding
      decoration: BoxDecoration(
        color: ColorPalette.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Left Side: Timer Control Button (fixed width to prevent layout shifts)
          SizedBox(
            width: 100, // Reduced width to save space
            child: ElevatedButton(
              onPressed: toggleTimer,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 6), // Reduced padding
                minimumSize: const Size(0, 32), // Smaller minimum height
              ),
              child: Text(
                getButtonText(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12), // Smaller font size
              ),
            ),
          ),
          const SizedBox(width: 12), // Reduced spacing
          // Center: Time Display
          Expanded(
            child: Text(
              isOvertime
                  ? '${_formatMinutesToMmSs(todaysTargetMinutes)} + ${_formatMinutesToMmSs(overtimeSeconds / 60.0)}'
                  : (todaysTargetMinutes == 0
                      ? _formatMinutesToMmSs(currentElapsedTimeInMinutes)
                      : '${_formatMinutesToMmSs(currentElapsedTimeInMinutes)} / ${_formatMinutesToMmSs(todaysTargetMinutes)}'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14, // Reduced from 16 to save space
                color: ColorPalette.lightText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12), // Reduced spacing
          // Right Side: Subdivision Display (only if subdivisions are enabled)
          if (subdivisions != null &&
              subdivisions! >= (todaysTargetMinutes == 0 ? 1 : 2))
            SizedBox(
              width: 70, // Reduced width
              child: Text(
                todaysTargetMinutes == 0
                    ? '${completedSubdivisions + 1}'
                    : '${completedSubdivisions + 1} / $subdivisions',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14, // Reduced from 16 to save space
                  color: ColorPalette.lightText,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the Main Notes Display for Note View mode
  Widget _buildNoteViewNotesDisplay() {
    final notes = currentItem.notes ?? '';

    if (notes.isEmpty) {
      return Center(
        child: Text(
          'No notes for this item.',
          style: TextStyle(
            fontSize: 20,
            color: ColorPalette.lightText.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12), // Reduced from 16
      decoration: BoxDecoration(
        color: ColorPalette.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: MarkdownBody(
          data: notes,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              fontSize: 25,
              color: ColorPalette.lightText,
              height: 1.5,
            ),
            h1: TextStyle(
              fontSize: 40,
              color: ColorPalette.lightText,
              fontWeight: FontWeight.bold,
            ),
            h2: TextStyle(
              fontSize: 35,
              color: ColorPalette.lightText,
              fontWeight: FontWeight.bold,
            ),
            h3: TextStyle(
              fontSize: 30,
              color: ColorPalette.lightText,
              fontWeight: FontWeight.bold,
            ),
            strong: const TextStyle(fontWeight: FontWeight.bold),
            em: const TextStyle(fontStyle: FontStyle.italic),
            // Add more styles as needed for lists, etc.
          ),
        ),
      ),
    );
  }

  /// Builds the Bottom Action Buttons for Note View mode
  Widget _buildNoteViewBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: showNoteDialogInEditMode, // Use the new edit mode dialog
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: 8), // Reduced padding
              minimumSize: const Size(0, 40), // Set minimum height
            ),
            child: const Text(
              'Edit Note',
              style: TextStyle(fontSize: 14), // Smaller font size
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: toggleNoteViewMode, // Close note view mode
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: 8), // Reduced padding
              minimumSize: const Size(0, 40), // Set minimum height
            ),
            child: const Text(
              'Close',
              style: TextStyle(fontSize: 14), // Smaller font size
            ),
          ),
        ),
      ],
    );
  }

  String _formatMinutesToMmSs(double minutesValue) {
    return TimeConverter.toMmSsString(minutesValue, padZeroes: true);
  }
}
