import 'package:flutter/material.dart';
import 'package:daily_inc/src/theme/color_palette.dart';

class Pulse extends StatefulWidget {
  final Widget child;
  final Color pulseColor;
  final double borderWidth;
  final Duration duration;
  final bool enableShadow;
  final BorderRadiusGeometry? borderRadius;

  const Pulse({
    super.key,
    required this.child,
    this.pulseColor = ColorPalette.warningOrange,
    this.borderWidth = 2.0,
    this.duration = const Duration(milliseconds: 1000),
    this.enableShadow = true,
    this.borderRadius,
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
        // Use ShapeDecoration with a RoundedRectangleBorder to mirror Material/Card rendering precisely.
        final shape = RoundedRectangleBorder(
          borderRadius: widget.borderRadius ??
              const BorderRadius.all(Radius.circular(8.0)),
          side: BorderSide(
            color: widget.pulseColor.withValues(alpha: _colorAnimation.value),
            width: widget.borderWidth,
          ),
        );

        return Material(
          // Transparent material to ensure shape painting fidelity with Material widgets
          type: MaterialType.transparency,
          shape: shape,
          child: Ink(
            decoration: ShapeDecoration(
              shape: shape.copyWith(), // ensure same shape for fill clipping
              shadows: widget.enableShadow
                  ? [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: _shadowAnimation.value),
                        blurRadius: 8.0,
                        spreadRadius: 2.0,
                      ),
                    ]
                  : const [],
            ),
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
