import 'package:flutter/material.dart';
import 'package:daily_inc/src/theme/color_palette.dart';

class TimerAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final bool minimalistMode;
  final bool isPaused;
  final bool dimScreenMode;
  final bool shouldFadeUI;
  final String? nextTaskName;
  final bool showNextTaskName;
  final String currentItemName;
  final bool hasNotes;
  final VoidCallback toggleDimScreenMode;
  final VoidCallback toggleMinimalistMode;
  final VoidCallback editItem;
  final VoidCallback toggleNoteViewMode;
  final VoidCallback onBackButtonPressed;

  const TimerAppBarWidget({
    super.key,
    required this.minimalistMode,
    required this.isPaused,
    required this.dimScreenMode,
    required this.shouldFadeUI,
    required this.nextTaskName,
    required this.showNextTaskName,
    required this.currentItemName,
    required this.hasNotes,
    required this.toggleDimScreenMode,
    required this.toggleMinimalistMode,
    required this.editItem,
    required this.toggleNoteViewMode,
    required this.onBackButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ColorPalette.darkBackground,
      automaticallyImplyLeading: !(minimalistMode && !isPaused),
      leading: (minimalistMode && !isPaused)
          ? AnimatedOpacity(
              opacity: shouldFadeUI ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 500),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBackButtonPressed,
              ),
            )
          : null,
      actions: [
        if (!(minimalistMode && !isPaused))
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String result) {
              if (result == 'toggle') {
                toggleDimScreenMode();
              } else if (result == 'minimalist') {
                toggleMinimalistMode();
              } else if (result == 'edit') {
                editItem();
              } else if (result == 'show_note_view') {
                toggleNoteViewMode();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(dimScreenMode
                        ? Icons.brightness_high
                        : Icons.brightness_low),
                    const SizedBox(width: 8),
                    Text(dimScreenMode
                        ? 'Turn Dim Screen Off'
                        : 'Turn Dim Screen On'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'minimalist',
                child: Row(
                  children: [
                    Icon(
                        minimalistMode ? Icons.fullscreen : Icons.aspect_ratio),
                    const SizedBox(width: 8),
                    Text(minimalistMode
                        ? 'Turn Minimalist Mode Off'
                        : 'Turn Minimalist Mode On'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit),
                    const SizedBox(width: 8),
                    const Text('Edit Item'),
                  ],
                ),
              ),
              if (hasNotes)
                PopupMenuItem<String>(
                  value: 'show_note_view',
                  child: Row(
                    children: [
                      const Icon(Icons.note),
                      const SizedBox(width: 8),
                      const Text('Show Note View'),
                    ],
                  ),
                ),
            ],
          )
        else
          AnimatedOpacity(
            opacity: shouldFadeUI ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 500),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String result) {
                if (result == 'toggle') {
                  toggleDimScreenMode();
                } else if (result == 'minimalist') {
                  toggleMinimalistMode();
                } else if (result == 'edit') {
                  editItem();
                } else if (result == 'show_note_view') {
                  toggleNoteViewMode();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(dimScreenMode
                          ? Icons.brightness_high
                          : Icons.brightness_low),
                      const SizedBox(width: 8),
                      Text(dimScreenMode
                          ? 'Turn Dim Screen Off'
                          : 'Turn Dim Screen On'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'minimalist',
                  child: Row(
                    children: [
                      Icon(minimalistMode
                          ? Icons.fullscreen
                          : Icons.aspect_ratio),
                      const SizedBox(width: 8),
                      Text(minimalistMode
                          ? 'Turn Minimalist Mode Off'
                          : 'Turn Minimalist Mode On'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit),
                      const SizedBox(width: 8),
                      const Text('Edit Item'),
                    ],
                  ),
                ),
                if (hasNotes)
                  PopupMenuItem<String>(
                    value: 'show_note_view',
                    child: Row(
                      children: [
                        const Icon(Icons.note),
                        const SizedBox(width: 8),
                        const Text('Show Note View'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
      title: AnimatedOpacity(
        opacity: minimalistMode && !isPaused ? (shouldFadeUI ? 0.0 : 1.0) : 1.0,
        duration: const Duration(milliseconds: 500),
        child: (nextTaskName != null && showNextTaskName
            ? Text(
                nextTaskName!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : Text(
                currentItemName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )),
      ),
      centerTitle: true,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
