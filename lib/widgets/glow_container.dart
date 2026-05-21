import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:spin_craze/extension/ext_localization.dart';

class GlowContainer extends StatefulWidget {
  final Widget child;
  final Color accent;
  final double borderRadius;
  final double strokeWith;
  final EdgeInsetsGeometry padding;

  const GlowContainer({
    super.key,
    required this.child,
    this.accent = Colors.white,
    this.borderRadius = 12,
    this.strokeWith = 2,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<GlowContainer> createState() => _GlowContainerState();
}

class _GlowContainerState extends State<GlowContainer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    value: math.Random().nextDouble(),
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => CustomPaint(
        painter: _GlowBorderPainter(
          strokeWidth: widget.strokeWith,
          progress: _ctrl.value,
          accent: widget.accent,
          radius: widget.borderRadius,
        ),
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius - 0.5),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(Colors.black, widget.accent, 0.09)!,
              const Color(0xFF05131B),
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius - 0.5),
          child: Stack(
            children: [
              // top-right radial glow
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.accent.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // bottom center line
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        widget.accent.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // content
              Padding(padding: widget.padding, child: widget.child),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowBorderPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final double radius;
  final double strokeWidth;

  _GlowBorderPainter({
    required this.progress,
    required this.accent,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // faint base border
    canvas.drawRRect(
      rRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = accent.withValues(alpha: 0.18),
    );

    // outer blur glow
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = accent.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8),
    );

    // spinning arc via PathMetrics (no seam glitch)
    final path = Path()..addRRect(rRect);
    final metric = path.computeMetrics().first;
    final totalLen = metric.length;

    const arcFraction = 0.22;
    final arcLen = totalLen * arcFraction;
    final startDist = progress * totalLen;

    const steps = 24;
    for (int i = 0; i < steps; i++) {
      final t0 = i / steps;
      final t1 = (i + 1) / steps;

      final d0 = (startDist + t0 * arcLen) % totalLen;
      final d1 = (startDist + t1 * arcLen) % totalLen;

      final tMid = (t0 + t1) / 2;
      final alpha = math.sin(tMid * math.pi);

      Path segment;
      if (d1 >= d0) {
        segment = metric.extractPath(d0, d1);
      } else {
        segment = metric.extractPath(d0, totalLen);
        segment.addPath(metric.extractPath(0, d1), Offset.zero);
      }

      canvas.drawPath(
        segment,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 2
          ..strokeCap = StrokeCap.round
          ..color = accent.withValues(alpha: alpha * 0.95),
      );
    }
  }

  @override
  bool shouldRepaint(_GlowBorderPainter o) => o.progress != progress;
}
