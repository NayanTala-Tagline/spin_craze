import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../extension/ext_context.dart';
import 'loading_overlay_controller.dart';

/// Loading overlay is a singleton class that can be used to show loading indicator on top of the screen.
class LoadingOverlay {
  /// Returns the singleton instance of [LoadingOverlay]
  factory LoadingOverlay.instance() => _instance;

  LoadingOverlay._();

  static final LoadingOverlay _instance = LoadingOverlay._();

  LoadingOverlayController? _controller;

  /// flag to check if loader is on tree or not
  bool isShowing = false;

  /// Shows loading indicator on top of the screen.
  void show({required BuildContext context, String text = 'Ad loading..'}) {
    if (_controller?.update(text) ?? false) {
      return;
    } else {
      _controller = _showOverlay(context: context, text: text);
    }
  }

  /// updates progress on overlay loading
  void progress(double? val) {
    _controller?.progress(val);
  }

  /// updates text shown on overlay loading
  void updateTitle(String text) {
    _controller?.update(text);
  }

  /// Hides loading indicator.
  void hide() {
    _controller?.close();
    _controller = null;
  }

  LoadingOverlayController? _showOverlay({
    required BuildContext context,
    required String text,
  }) {
    final textController = StreamController<String>()
      ..add(text); // default string in stream
    final progressController = StreamController<double?>()
      ..add(null); // default string in stream

    // final renderBox = context.findRenderObject()! as RenderBox;
    // final screenSize = renderBox.size;

    showDialog<AlertDialog>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      useSafeArea: false,
      builder: (BuildContext context) {
        isShowing = true;
        return PopScope(
          canPop: false,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  constraints: const BoxConstraints(minWidth: 180),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0.08),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFF5CCBF7).withValues(alpha: 0.45),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00B7FF).withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StreamBuilder<double?>(
                        stream: progressController.stream,
                        builder: (context, snapshot) {
                          return _GlowSpinner(progress: snapshot.data);
                        },
                      ),
                      const SizedBox(height: 18),
                      StreamBuilder(
                        stream: textController.stream,
                        builder: (context, snapshot) {
                          final label = snapshot.hasData
                              ? snapshot.requireData
                              : '';
                          if (label.isEmpty) return const SizedBox.shrink();
                          return Text(
                            label,
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              shadows: [
                                Shadow(
                                  color: const Color(
                                    0xFF00B7FF,
                                  ).withValues(alpha: 0.6),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    return LoadingOverlayController(
      close: () {
        if (context.mounted && context.canPop()) {
          // Changing context.pop() to Navigator.of(context).pop()
          // Issue : Loading overlay pop issue [community feed-> Community feed list -> hide]
          context.pop();
          isShowing = false;
        }
        textController.close();
        progressController.close();
        return true;
      },
      update: (text) {
        textController.add(text);
        return true;
      },
      progress: (progress) {
        progressController.add(progress);
        return true;
      },
    );
  }
}

class _GlowSpinner extends StatefulWidget {
  const _GlowSpinner({this.progress});

  final double? progress;

  @override
  State<_GlowSpinner> createState() => _GlowSpinnerState();
}

class _GlowSpinnerState extends State<_GlowSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF5CCBF7).withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          if (widget.progress != null)
            SizedBox.square(
              dimension: 48,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                value: widget.progress,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF9AE0FA),
                ),
                backgroundColor: Colors.white.withValues(alpha: 0.15),
              ),
            )
          else
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) {
                return Transform.rotate(
                  angle: _ctrl.value * 6.2831853,
                  child: CustomPaint(
                    size: const Size.square(48),
                    painter: _ArcPainter(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shader = SweepGradient(
      colors: const [
        Color(0x009AE0FA),
        Color(0xFF9AE0FA),
        Color(0xFF5CCBF7),
        Color(0xFF00B7FF),
      ],
      stops: const [0.0, 0.55, 0.85, 1.0],
    ).createShader(rect);

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2 - 2,
      ),
      0,
      4.7, // ~270°
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
