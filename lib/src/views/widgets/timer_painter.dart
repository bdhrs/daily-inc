import 'dart:math';
import 'package:daily_inc/src/theme/color_palette.dart';
import 'package:flutter/material.dart';

class TimerPainter extends CustomPainter {
  final double totalTime;
  final double elapsedTime;
  final int subdivisions;

  TimerPainter({
    required this.totalTime,
    required this.elapsedTime,
    this.subdivisions = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 20;

    // Background circle
    final backgroundPaint = Paint()
      ..color = elapsedTime >= totalTime
          ? ColorPalette.cardBackground.withAlpha(100)
          : ColorPalette.cardBackground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    if (elapsedTime <= totalTime) {
      canvas.drawCircle(center, radius, backgroundPaint);
    }

    final progressPaint = Paint()
      ..color = elapsedTime >= totalTime
          ? ColorPalette.primaryBlue
          : ColorPalette.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.butt;

    if (elapsedTime >= totalTime) {
      // When timer is complete, draw a full circle for perfect closure
      canvas.drawCircle(center, radius, progressPaint);
    } else {
      // Draw progress arc for incomplete timer
      final progressAngle = 2 * pi * (elapsedTime / totalTime).clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        progressAngle,
        false,
        progressPaint,
      );
    }

    // Spokes
    if (subdivisions > 0 && elapsedTime < totalTime) {
      final spokePaint = Paint()
        ..color = ColorPalette.secondaryText.withAlpha((255 * 0.5).round())
        ..strokeWidth = 2;
      for (int i = 0; i < subdivisions; i++) {
        final angle = -pi / 2 + 2 * pi * i / subdivisions;
        final start = center + Offset(cos(angle), sin(angle)) * (radius - 8);
        final end = center + Offset(cos(angle), sin(angle)) * (radius + 8);
        canvas.drawLine(start, end, spokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
