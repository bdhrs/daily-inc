import 'package:flutter/material.dart';

class NextTaskArrow extends StatefulWidget {
  final VoidCallback onTap;
  final bool isVisible;

  const NextTaskArrow({
    super.key,
    required this.onTap,
    this.isVisible = true,
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
    return Visibility(
      visible: widget.isVisible,
      child: Positioned(
        right: 20,
        bottom: MediaQuery.of(context).size.height * 0.33, // About 1/3 from bottom
        child: ScaleTransition(
          scale: _animation,
          child: IconButton(
            onPressed: widget.onTap,
            icon: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}