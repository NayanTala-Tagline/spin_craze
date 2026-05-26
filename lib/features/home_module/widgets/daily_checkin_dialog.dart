import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/services/reward_ad_service.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/widgets/ad_disclaimer_text.dart';
import 'package:flutter/material.dart';

// Local light-theme palette — mirrors the home screen redesign so the dialog
// reads as part of the same surface family.
const _kCardBg = Colors.white;
const _kBlue = Color(0xFF2563EB);
const _kBlueDeep = Color(0xFF1E3FE0);
const _kBlueSoft = Color(0xFFE6EEFF);
const _kBlueBorder = Color(0xFFB8C8F0);
const _kTextDark = Color(0xFF111827);
const _kTextMuted = Color(0xFF6B7280);
const _kProgressIncomplete = Color(0xFFE3E9FB);
const _kProgressBorder = Color(0xFFC7D2FE);

class DailyCheckinDialog extends StatefulWidget {
  final int currentDay;
  final int rewardCoins;
  final VoidCallback onClaim;

  const DailyCheckinDialog({
    super.key,
    required this.currentDay,
    required this.rewardCoins,
    required this.onClaim,
  });

  @override
  State<DailyCheckinDialog> createState() => _DailyCheckinDialogState();
}

class _DailyCheckinDialogState extends State<DailyCheckinDialog>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _trophyController;
  late final AnimationController _progressController;
  late final AnimationController _coinController;
  late final AnimationController _glowController;

  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _progressAnim;
  late final Animation<int> _coinAnim;

  @override
  void initState() {
    super.initState();

    // Dialog entry — scale + fade, with a touch of overshoot.
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    // Trophy — slow continuous breathe (scale + glow alpha).
    _trophyController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);

    // Progress bars — staggered fill across the 7 segments.
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _progressAnim = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );

    // Coin count-up.
    _coinController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _coinAnim = IntTween(begin: 0, end: widget.rewardCoins).animate(
      CurvedAnimation(parent: _coinController, curve: Curves.easeOut),
    );

    // Claim button — pulsing glow.
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);

    _entryController.forward();
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      _progressController.forward();
      _coinController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _trophyController.dispose();
    _progressController.dispose();
    _coinController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: AppSize.w28),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              AppSize.w24,
              AppSize.h28,
              AppSize.w24,
              AppSize.h24,
            ),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(AppSize.r24),
              border: Border.all(color: const Color(0xFFE5EBF5)),
              boxShadow: [
                BoxShadow(
                  color: _kBlue.withValues(alpha: 0.22),
                  blurRadius: AppSize.r30,
                  offset: Offset(0, AppSize.h14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AnimatedTrophy(controller: _trophyController),
                SizedBox(height: AppSize.h14),
                Text(
                  'Daily Check-in Reward',
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: _kTextDark,
                    fontSize: AppSize.sp20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: AppSize.h10),
                _DayBadge(day: widget.currentDay),
                SizedBox(height: AppSize.h18),
                _CoinCounter(animation: _coinAnim),
                SizedBox(height: AppSize.h6),
                Text(
                  'Keep your streak going!',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: _kTextMuted,
                    fontSize: AppSize.sp13,
                  ),
                ),
                SizedBox(height: AppSize.h20),
                _AnimatedProgressBar(
                  currentDay: widget.currentDay,
                  progressAnim: _progressAnim,
                ),
                SizedBox(height: AppSize.h20),
                AdDisclaimerText(
                  show: RewardAdService.isDailyCheckinAdEnabled,
                ),
                _ClaimButton(
                  onPressed: widget.onClaim,
                  glowController: _glowController,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trophy with breathing glow halo
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedTrophy extends StatelessWidget {
  const _AnimatedTrophy({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSize.w120,
      height: AppSize.h110,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, child) {
          final t = controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: AppSize.w120,
                height: AppSize.h110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _kBlue.withValues(alpha: 0.18 + 0.18 * t),
                      _kBlue.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -2 + (t * 4)),
                child: Transform.scale(
                  scale: 1 + (t * 0.06),
                  child: child,
                ),
              ),
            ],
          );
        },
        child: Assets.images.dailyRewardTrophy.image(
          width: AppSize.w90,
          height: AppSize.h90,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day pill ("Day N" with flame)
// ─────────────────────────────────────────────────────────────────────────────

class _DayBadge extends StatelessWidget {
  const _DayBadge({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w14,
        vertical: AppSize.h6,
      ),
      decoration: BoxDecoration(
        color: _kBlueSoft,
        borderRadius: BorderRadius.circular(AppSize.r100),
        border: Border.all(color: _kBlueBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Assets.icons.flame.svg(
            height: AppSize.sp14,
            width: AppSize.sp14,
            colorFilter: const ColorFilter.mode(
              Color(0xFFFF7A24),
              BlendMode.srcIn,
            ),
          ),
          SizedBox(width: AppSize.w6),
          Text(
            'Day $day',
            style: context.textTheme.bodyMedium?.copyWith(
              color: _kBlueDeep,
              fontSize: AppSize.sp13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated coin counter ("+N Coins")
// ─────────────────────────────────────────────────────────────────────────────

class _CoinCounter extends StatelessWidget {
  const _CoinCounter({required this.animation});

  final Animation<int> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: AppSize.h2),
              child: Assets.images.gift.image(
                height: AppSize.sp30,
                width: AppSize.sp30,
              ),
            ),
            SizedBox(width: AppSize.w8),
            Text(
              '+${animation.value}',
              style: context.textTheme.titleLarge?.copyWith(
                color: _kBlueDeep,
                fontWeight: FontWeight.w800,
                fontSize: AppSize.sp30,
                height: 1.0,
              ),
            ),
            SizedBox(width: AppSize.w4),
            Padding(
              padding: EdgeInsets.only(bottom: AppSize.h6),
              child: Text(
                'Coins',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: _kTextMuted,
                  fontSize: AppSize.sp14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7-day progress bar — staggered left-to-right fill
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedProgressBar extends StatelessWidget {
  const _AnimatedProgressBar({
    required this.currentDay,
    required this.progressAnim,
  });

  final int currentDay;
  final Animation<double> progressAnim;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progressAnim,
      builder: (_, _) {
        return Row(
          children: List.generate(7, (index) {
            final day = index + 1;
            final isCompleted = day < currentDay;
            final isCurrent = day == currentDay;
            final shouldFill = isCompleted || isCurrent;
            // Stagger the fill across all 7 segments — bar i fills as the
            // global progress crosses its slice [i/7 .. (i+1)/7].
            final fillProgress = shouldFill
                ? (progressAnim.value * 7 - index).clamp(0.0, 1.0)
                : 0.0;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSize.w2),
                child: Transform(
                  transform: Matrix4.skewX(-0.25),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSize.r4),
                    child: Container(
                      height: AppSize.h14,
                      decoration: BoxDecoration(
                        color: _kProgressIncomplete,
                        border: Border.all(
                          color: _kProgressBorder,
                          width: 0.8,
                        ),
                        borderRadius: BorderRadius.circular(AppSize.r4),
                      ),
                      child: shouldFill
                          ? Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: fillProgress,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF5577FF), _kBlueDeep],
                                  ),
                                  boxShadow: isCurrent && fillProgress > 0.5
                                      ? [
                                          BoxShadow(
                                            color: _kBlue.withValues(
                                              alpha: 0.55,
                                            ),
                                            blurRadius: AppSize.r6,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Claim button — blue gradient with pulsing glow
// ─────────────────────────────────────────────────────────────────────────────

class _ClaimButton extends StatelessWidget {
  const _ClaimButton({
    required this.onPressed,
    required this.glowController,
  });

  final VoidCallback onPressed;
  final AnimationController glowController;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSize.r100);

    return SizedBox(
      width: double.infinity,
      child: AnimatedBuilder(
        animation: glowController,
        builder: (_, child) {
          final t = glowController.value;
          return Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: _kBlue.withValues(alpha: 0.32 + 0.22 * t),
                  blurRadius: AppSize.r16 + (AppSize.r10 * t),
                  offset: Offset(0, AppSize.h6),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: Container(
              height: AppSize.h54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF5577FF), _kBlueDeep],
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Claim Reward',
                    style: context.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: AppSize.sp16,
                    ),
                  ),
                  SizedBox(width: AppSize.w8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: AppSize.w16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
