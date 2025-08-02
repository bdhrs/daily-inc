import 'package:flutter/material.dart';

class Pulse extends StatefulWidget {
  final Widget child;
  final Color pulseColor;
  final double borderWidth;
  final Duration duration;
  final bool enableShadow;

  const Pulse({
    super.key,
    required this.child,
    this.pulseColor = Colors.blue,
    this.borderWidth = 2.0,
    this.duration = const Duration(milliseconds: 1500),
    this.enableShadow = true,
  });

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _colorAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _colorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _shadowAnimation = Tween<double>(
      begin: 0.0,
      end: 0.15,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.pulseColor.withValues(alpha: _colorAnimation.value),
              width: widget.borderWidth,
            ),
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: widget.enableShadow
                ? [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: _shadowAnimation.value),
                      blurRadius: 8.0,
                      spreadRadius: 2.0,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
