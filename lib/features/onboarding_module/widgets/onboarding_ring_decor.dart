import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Concentric rings backdrop that sits behind the onboarding illustration.
///
/// - Four soft-blue layers (lightest on the outside, most saturated in the
///   middle) breathe gently with out-of-phase alpha pulses.
/// - Two outlined ripples continuously expand outward and fade — the
///   "wave-like" motion radiating from the illustration centre.
///
/// The widget fills its parent, so when the scaffold's `Expanded` area
/// shrinks (e.g. when a native ad is shown), the rings shrink with it.
class OnboardingRingDecor extends StatefulWidget {
  const OnboardingRingDecor({super.key});

  @override
  State<OnboardingRingDecor> createState() => _OnboardingRingDecorState();
}

class _OnboardingRingDecorState extends State<OnboardingRingDecor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _RingPainter(phase: _ctrl.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.phase});

  final double phase;

  static const _baseColor = Color(0xFFB4C9F0);
  static const _pulseAmount = 0.18;

  // Drawn largest-and-lightest first; smaller and more saturated on top.
  static const _rings = <_RingLayer>[
    _RingLayer(radiusFactor: 1.30, baseAlpha: 0.18, phaseShift: 0.00),
    _RingLayer(radiusFactor: 1.02, baseAlpha: 0.28, phaseShift: 0.20),
    _RingLayer(radiusFactor: 0.78, baseAlpha: 0.40, phaseShift: 0.40),
    _RingLayer(radiusFactor: 0.55, baseAlpha: 0.55, phaseShift: 0.60),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;

    // Static concentric fills with subtle breathing pulse.
    for (final ring in _rings) {
      final t = (phase + ring.phaseShift) * 2 * math.pi;
      final pulse = 1.0 + _pulseAmount * math.sin(t);
      final alpha = (ring.baseAlpha * pulse).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        baseRadius * ring.radiusFactor,
        Paint()..color = _baseColor.withValues(alpha: alpha),
      );
    }

    // Continuous outward ripples — two rings, phase-offset so as one fades
    // out the next is just emerging from the centre.
    for (var i = 0; i < 2; i++) {
      final p = (phase + i * 0.5) % 1.0;
      final radius = baseRadius * (0.50 + p * 0.95);
      final alpha = (0.40 * (1.0 - p)).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = _baseColor.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class _RingLayer {
  const _RingLayer({
    required this.radiusFactor,
    required this.baseAlpha,
    required this.phaseShift,
  });

  final double radiusFactor;
  final double baseAlpha;
  final double phaseShift;
}
