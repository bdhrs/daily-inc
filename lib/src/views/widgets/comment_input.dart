import 'package:flutter/material.dart';

/// A widget that displays the comment input field with visibility logic based on timer state.
///
/// This widget handles the comment input field visibility and behavior based on:
/// - Minimalist mode settings
/// - Timer state (running/paused/overtime)
/// - Focus management
class CommentInputWidget extends StatelessWidget {
  final TextEditingController commentController;
  final FocusNode commentFocusNode;
  final bool minimalistMode;
  final bool isOvertime;
  final bool isPaused;
  final double remainingSeconds;
  final bool shouldFadeUI;
  final VoidCallback onTap;

  const CommentInputWidget({
    super.key,
    required this.commentController,
    required this.commentFocusNode,
    required this.minimalistMode,
    required this.isOvertime,
    required this.isPaused,
    required this.remainingSeconds,
    required this.shouldFadeUI,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // In minimalist mode:
    // - When timer is running in overtime, hide the comment field
    // - When timer is paused in overtime, show the comment field
    // - When timer is finished (at 0 seconds) but not in overtime, show the comment field
    final bool showCommentField = !minimalistMode ||
        (isOvertime ? isPaused : (remainingSeconds <= 0 && !isOvertime));

    // In minimalist mode when timer is running, fade out the comment field like other UI elements
    final bool shouldFadeOut = minimalistMode && !isPaused && showCommentField;

    return Opacity(
      opacity: showCommentField ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: !showCommentField,
        child: AnimatedOpacity(
          opacity: shouldFadeOut ? (shouldFadeUI ? 0.0 : 1.0) : 1.0,
          duration: const Duration(milliseconds: 500),
          child: GestureDetector(
            onTap: onTap,
            child: TextField(
              controller: commentController,
              focusNode: commentFocusNode,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'add a comment',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: commentFocusNode.hasFocus ||
                        commentController.text.isNotEmpty
                    ? const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      )
                    : InputBorder.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
