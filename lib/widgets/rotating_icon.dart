import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:spin_craze/extension/ext_localization.dart';

/// Rotating icon widget in z axis used in the home page
class RotatingIcon extends StatefulWidget {
  /// Default constructor
  const RotatingIcon({
    required this.icon,
    super.key,
    this.isRotating = true, // 👈 Added flag to control rotation
  });

  final Widget icon;
  final bool isRotating;

  @override
  State<RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<RotatingIcon> with TickerProviderStateMixin {
  late AnimationController _controller;
  late CurvedAnimation _animation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_setupAnimation());
  }

  Future<void> _setupAnimation() async {
    _controller = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticInOut,
    );

    if (widget.isRotating) {
      await _startRotation();
    }
  }

  Future<void> _startRotation() async {
    await _controller.forward();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) async {
      await _controller.forward(from: 0);
    });
  }

  void _stopRotation() {
    _timer?.cancel();
    _controller.stop();
  }

  @override
  void didUpdateWidget(covariant RotatingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If rotation state changes dynamically
    if (oldWidget.isRotating != widget.isRotating) {
      if (widget.isRotating) {
        unawaited(_startRotation());
      } else {
        _stopRotation();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If rotation is disabled → show static icon
    if (!widget.isRotating) {
      return widget.icon;
    }

    return MatrixTransition(
      animation: _animation,
      child: widget.icon,
      onTransform: (value) {
        return Matrix4.identity()
          ..setEntry(3, 2, 0.004)
          ..rotateY(pi * 8.0 * value);
      },
    );
  }
}
