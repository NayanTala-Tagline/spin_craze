import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../extension/ext_context.dart';
import '../gen/assets.gen.dart';
import '../utils/app_size.dart';
import 'app_button.dart';

class RewardAdBottomSheet extends StatefulWidget {
  final VoidCallback onSupportUs;
  final VoidCallback onCancel;
  final int timerSeconds;
  final bool isHomepage;

  const RewardAdBottomSheet({
    super.key,
    required this.onSupportUs,
    required this.onCancel,
    this.timerSeconds = 3,
    this.isHomepage = false,
  });

  @override
  State<RewardAdBottomSheet> createState() => _RewardAdBottomSheetState();
}

class _RewardAdBottomSheetState extends State<RewardAdBottomSheet>
    with TickerProviderStateMixin {
  // Local color tokens — picked to read well on the app's light scaffold
  // (#F0F5FF). The Theme's text tokens are tuned for the dark surfaces, so we
  // pin explicit values here instead of pulling `txt.primary` (which is black
  // and was invisible on the old dark sheet, and unreadable on white either).
  static const _surfaceTop = Color(0xFFFFFFFF);
  static const _surfaceBottom = Color(0xFFF4F7FF);
  static const _textPrimary = Color(0xFF0E2B33);
  static const _textSecondary = Color(0xFF4A5A66);
  static const _handleColor = Color(0xFFD6DEEA);
  static const _chipBorder = Color(0x29A86CFF);

  late int _remainingSeconds;
  Timer? _timer;

  late final AnimationController _entryController;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _heroScale;

  late final AnimationController _floatController;
  late final AnimationController _glowController;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timerSeconds;

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _contentFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));
    _heroScale = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.15, 1.0, curve: Curves.elasticOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _entryController.forward();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        context.pop();
        widget.onSupportUs();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entryController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_surfaceTop, _surfaceBottom],
        ),
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSize.r28)),
        border: Border(
          top: BorderSide(
            color: tc.secondary.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x33081821),
            blurRadius: AppSize.r24,
            offset: Offset(0, -AppSize.h6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSize.w20,
        AppSize.h12,
        AppSize.w20,
        AppSize.h20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: AppSize.w44,
            height: AppSize.h5,
            decoration: BoxDecoration(
              color: _handleColor,
              borderRadius: BorderRadius.circular(AppSize.r4),
            ),
          ),
          SizedBox(height: AppSize.h20),

          // Animated hero — trackAchievements image
          SizedBox(
            height: AppSize.h180,
            width: AppSize.w200,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _glowController,
                _floatController,
                _rotationController,
              ]),
              builder: (context, _) {
                final glow = 0.28 + (_glowController.value * 0.32);
                final floatY = -AppSize.h10 * _floatController.value;
                final tilt = (math.sin(_rotationController.value * math.pi) *
                        0.04) -
                    0.02;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: AppSize.w160 + (20 * _glowController.value),
                      height: AppSize.w160 + (20 * _glowController.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            tc.coin.withValues(alpha: glow),
                            tc.secondary.withValues(alpha: glow * 0.55),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, floatY),
                      child: Transform.rotate(
                        angle: tilt,
                        child: ScaleTransition(
                          scale: _heroScale,
                          child: Assets.images.trackAchievments.image(
                            height: AppSize.h160,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: AppSize.h12),

          // Title + body
          FadeTransition(
            opacity: _contentFade,
            child: SlideTransition(
              position: _contentSlide,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Support Our App',
                    style: TextStyle(
                      fontSize: AppSize.sp20,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: AppSize.h8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSize.w12),
                    child: Text(
                      'Watch a short ad to support us and keep the app free for everyone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppSize.sp14,
                        fontWeight: FontWeight.w400,
                        color: _textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSize.h20),

          // Timer chip
          if (_remainingSeconds > 0)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Container(
                key: ValueKey<int>(_remainingSeconds),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSize.w16,
                  vertical: AppSize.h10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tc.primary.withValues(alpha: 0.10),
                      tc.secondary.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSize.r24),
                  border: Border.all(color: _chipBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: tc.coinDeep,
                      size: AppSize.sp16,
                    ),
                    SizedBox(width: AppSize.w8),
                    Text(
                      'Auto-starting in $_remainingSeconds s',
                      style: TextStyle(
                        fontSize: AppSize.sp12,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SizedBox(height: AppSize.h24),

          // Buttons
          FadeTransition(
            opacity: _contentFade,
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.outline,
                    onPressed: () {
                      _timer?.cancel();
                      context.pop();
                      widget.onCancel();
                    },
                  ),
                ),
                SizedBox(width: AppSize.w12),
                Expanded(
                  child: AppButton(
                    label: 'Watch Ads',
                    variant: AppButtonVariant.gradient,
                    leading: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: AppSize.sp20,
                    ),
                    onPressed: () {
                      _timer?.cancel();
                      context.pop();
                      widget.onSupportUs();
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: widget.isHomepage ? AppSize.h100 : AppSize.h10,
          ),
        ],
      ),
    );
  }
}

/// Helper function to show the reward ad bottom sheet
Future<void> showRewardAdBottomSheet({
  required BuildContext context,
  required VoidCallback onSupportUs,
  required VoidCallback onCancel,
  int timerSeconds = 3,
  bool isHomepage = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (context) => RewardAdBottomSheet(
      onSupportUs: onSupportUs,
      onCancel: onCancel,
      timerSeconds: timerSeconds,
      isHomepage: isHomepage,
    ),
  );
}
