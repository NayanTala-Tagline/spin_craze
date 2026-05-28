import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../utils/app_size.dart';
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
    final textController = StreamController<String>()..add(text);
    final progressController = StreamController<double?>()..add(null);

    showDialog<AlertDialog>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      useSafeArea: false,
      builder: (BuildContext context) {
        isShowing = true;
        return PopScope(
          canPop: false,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSize.w28,
                    vertical: AppSize.h28,
                  ),
                  constraints: BoxConstraints(minWidth: AppSize.w200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSize.r24),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFFFFF), Color(0xFFF4F7FF)],
                    ),
                    border: Border.all(
                      color: const Color(0xFFA86CFF).withValues(alpha: 0.35),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFF004CD9).withValues(alpha: 0.18),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StreamBuilder<double?>(
                        stream: progressController.stream,
                        builder: (context, snapshot) {
                          return _BrandSpinner(progress: snapshot.data);
                        },
                      ),
                      SizedBox(height: AppSize.h20),
                      StreamBuilder<String>(
                        stream: textController.stream,
                        builder: (context, snapshot) {
                          final label = snapshot.hasData
                              ? snapshot.requireData
                              : '';
                          if (label.isEmpty) return const SizedBox.shrink();
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.15),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: child,
                              ),
                            ),
                            child: Text(
                              label,
                              key: ValueKey<String>(label),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppSize.sp14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0E2B33),
                                letterSpacing: 0.3,
                                height: 1.3,
                              ),
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

class _BrandSpinner extends StatefulWidget {
  const _BrandSpinner({this.progress});

  final double? progress;

  @override
  State<_BrandSpinner> createState() => _BrandSpinnerState();
}

class _BrandSpinnerState extends State<_BrandSpinner>
    with TickerProviderStateMixin {
  late final AnimationController _rotate = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  late final AnimationController _counterRotate = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _rotate.dispose();
    _counterRotate.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showProgress = widget.progress != null;
    return SizedBox.square(
      dimension: AppSize.w72,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotate, _counterRotate, _pulse]),
        builder: (context, _) {
          final pulseT = _pulse.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing halo
              Container(
                width: AppSize.w64 + (AppSize.w16 * pulseT),
                height: AppSize.w64 + (AppSize.w16 * pulseT),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFD84D)
                          .withValues(alpha: 0.30 + pulseT * 0.20),
                      const Color(0xFFA86CFF)
                          .withValues(alpha: 0.18 + pulseT * 0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
              // Track ring (faint)
              Container(
                width: AppSize.w56,
                height: AppSize.w56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFA86CFF).withValues(alpha: 0.18),
                    width: 2,
                  ),
                ),
              ),
              // Sweep arc OR determinate progress
              if (!showProgress)
                Transform.rotate(
                  angle: _rotate.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size.square(AppSize.w56),
                    painter: _SweepArcPainter(),
                  ),
                )
              else
                SizedBox.square(
                  dimension: AppSize.w56,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    value: widget.progress,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF004CD9),
                    ),
                    backgroundColor:
                        const Color(0xFFA86CFF).withValues(alpha: 0.18),
                  ),
                ),
              // Counter-rotating orbiting dot on the outer ring
              if (!showProgress)
                Transform.rotate(
                  angle: -_counterRotate.value * 2 * math.pi,
                  child: SizedBox.square(
                    dimension: AppSize.w56,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: AppSize.w8,
                        height: AppSize.w8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFA86CFF),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFA86CFF)
                                  .withValues(alpha: 0.55),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // Center coin badge with subtle pulse
              Transform.scale(
                scale: 1 + (pulseT * 0.08),
                child: Container(
                  width: AppSize.w28,
                  height: AppSize.w28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFD84D), Color(0xFFFF8C24)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8C24)
                            .withValues(alpha: 0.55),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: showProgress
                      ? Center(
                          child: Text(
                            '${(widget.progress! * 100).round()}',
                            style: TextStyle(
                              fontSize: AppSize.sp10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SweepArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shader = const SweepGradient(
      colors: [
        Color(0x00004CD9),
        Color(0xFF1164FF),
        Color(0xFF004CD9),
      ],
      stops: [0.0, 0.6, 1.0],
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
