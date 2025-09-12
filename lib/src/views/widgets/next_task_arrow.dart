import 'package:flutter/material.dart';
import 'package:daily_inc/src/theme/color_palette.dart';

class NextTaskArrow extends StatefulWidget {
  final VoidCallback onTap;
  final bool isVisible;
  final bool isOvertime;
  final bool isMinimalistMode;
  final bool isPaused;
  final bool shouldFadeUI;

  const NextTaskArrow({
    super.key,
    required this.onTap,
    this.isVisible = true,
    this.isOvertime = false,
    this.isMinimalistMode = false,
    this.isPaused = true,
    this.shouldFadeUI = false,
  });

  @override
  State<NextTaskArrow> createState() => _NextTaskArrowState();
}

class _NextTaskArrowState extends State<NextTaskArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.7,
      end: 1.3,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Repeat the animation
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we should show the arrow:
    // 1. Must be visible (isVisible == true)
    // 2. In minimalist mode during overtime:
    //    - Hide when timer is running (!isPaused)
    //    - Show when timer is paused (isPaused)
    // 3. In all other cases, show the arrow

    bool showArrow = widget.isVisible;

    if (widget.isMinimalistMode && widget.isOvertime) {
      // In minimalist mode during overtime, hide when timer is running
      showArrow = showArrow && widget.isPaused;
    }

    // In minimalist mode when timer is running, fade out the arrow like other UI elements
    final bool shouldFadeOut =
        widget.isMinimalistMode && !widget.isPaused && showArrow;

    return Visibility(
      visible: showArrow,
      child: Positioned(
        right: 20,
        bottom:
            MediaQuery.of(context).size.height * 0.33, // About 1/3 from bottom
        child: AnimatedOpacity(
          opacity: shouldFadeOut ? (widget.shouldFadeUI ? 0.0 : 1.0) : 1.0,
          duration: const Duration(milliseconds: 500),
          child: ScaleTransition(
            scale: _animation,
            child: IconButton(
              onPressed: widget.onTap,
              icon: const Icon(
                Icons.arrow_forward,
                color: ColorPalette.lightText,
                size: 36,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
