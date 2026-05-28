import 'dart:math';
import 'dart:ui' as ui;

import 'package:spin_craze/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

class WheelSegment {
  WheelSegment(
    this.label, {
    required this.displayText,
    this.colorStart,
    this.colorEnd,
    this.solidColor,
  });

  final int label;
  final String displayText;

  /// For gradient segments (blue-purple).
  final Color? colorStart;
  final Color? colorEnd;

  /// For solid-color segments (dark green).
  final Color? solidColor;

  bool get isGradient => colorStart != null && colorEnd != null;
}

class WheelPainter extends CustomPainter {
  WheelPainter(this.segments);
  final List<WheelSegment> segments;

  static const _darkGreen = Color(0xFF0B2B26);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = 2 * pi / segments.length;

    for (var i = 0; i < segments.length; i++) {
      final startAngle = i * sweepAngle - pi / 2;
      final midAngle = startAngle + sweepAngle / 2;
      final segment = segments[i];

      final rect = Rect.fromCircle(center: center, radius: radius);

      // ── Draw segment ──────────────────────────────────────
      final paint = Paint()..style = PaintingStyle.fill;

      if (segment.isGradient) {
        // Gradient from center outward along the segment's mid-angle.
        final endX = center.dx + radius * cos(midAngle);
        final endY = center.dy + radius * sin(midAngle);
        paint.shader = ui.Gradient.linear(center, Offset(endX, endY), [
          segment.colorStart!,
          segment.colorEnd!,
        ]);
      } else {
        paint.color = segment.solidColor ?? _darkGreen;
      }

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // ── Separator line ────────────────────────────────────
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * cos(startAngle),
          center.dy + radius * sin(startAngle),
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // ── Text label centered in segment ────────────────────
      _drawText(
        canvas: canvas,
        center: center,
        radius: radius,
        radiusFactor: 0.65,
        midAngle: midAngle,
        text: segment.displayText,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: FontFamily.sFPro,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      );
    }

    // ── Center hub ──────────────────────────────────────────
    canvas.drawCircle(
      center,
      radius * 0.06,
      Paint()..color = const Color(0xFF1E293B),
    );
    // ..drawCircle(
    //   center,
    //   radius * 0.06,
    //   Paint()
    //     ..color = Colors.white.withValues(alpha: 0.3)
    //     ..style = PaintingStyle.stroke
    //     ..strokeWidth = 2,
    // );
  }

  void _drawText({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double radiusFactor,
    required double midAngle,
    required String text,
    required TextStyle style,
  }) {
    final x = center.dx + radius * radiusFactor * cos(midAngle);
    final y = center.dy + radius * radiusFactor * sin(midAngle);

    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    canvas
      ..save()
      ..translate(x, y)
      ..rotate(midAngle);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SpinWheelWidget extends StatelessWidget {
  const SpinWheelWidget({
    required this.segments,
    required this.angle,
    super.key,
    this.size = 320,
  });
  final List<WheelSegment> segments;
  final double angle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: WheelPainter(segments)),
      ),
    );
  }
}
