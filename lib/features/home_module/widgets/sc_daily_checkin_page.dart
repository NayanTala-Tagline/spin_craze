import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/features/home_module/provider/sc_home_provider.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/services/reward_ad_service.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/widgets/ad_disclaimer_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Local light-theme palette — mirrors the home screen + check-in dialog so the
// whole daily-reward flow reads as one surface family.
const _kPageBg = Color(0xFFF4F7FE);
const _kCardBg = Colors.white;
const _kCardBorder = Color(0xFFE5EBF5);
const _kBlue = Color(0xFF2563EB);
const _kBlueDeep = Color(0xFF1E3FE0);
const _kBlueSoft = Color(0xFFE6EEFF);
const _kBlueBorder = Color(0xFFB8C8F0);
const _kOrange = Color(0xFFFF7A24);
const _kTextDark = Color(0xFF111827);
const _kTextMuted = Color(0xFF6B7280);
const _kProgressIncomplete = Color(0xFFE3E9FB);
const _kProgressBorder = Color(0xFFC7D2FE);

/// Full-screen Daily Check-in page reachable from the AppBar streak chip.
///
/// Mirrors [ScDailyCheckinDialog] (same 1-7 progress + claim flow) but adds the
/// lifetime claim count and renders as a Scaffold.
class ScDailyCheckinPage extends StatelessWidget {
  const ScDailyCheckinPage({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsManager.instance.logScreenView(
      screenName: 'daily_checkin',
      screenClass: 'ScDailyCheckinPage',
    );

    final db = Injector.instance<AppDB>();

    // ScHomeProvider is created at the app root (see main.dart) so we just read
    // the shared instance here — creating a new one would re-trigger the
    // post-frame check-in dialog.
    return Consumer<ScHomeProvider>(
      builder: (context, provider, _) {
        return StreamBuilder(
          stream: db.userListenable(),
          builder: (context, _) {
            return Scaffold(
              backgroundColor: _kPageBg,
              appBar: AppBar(
                backgroundColor: _kPageBg,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                iconTheme: const IconThemeData(color: _kTextDark),
                title: Text(
                  context.l10n.dailyCheckinTitle,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: _kTextDark,
                    fontSize: AppSize.sp18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: _kCardBorder,
                  ),
                ),
              ),
              body: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSize.w16,
                  AppSize.h20,
                  AppSize.w16,
                  AppSize.h32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ScTotalStreakCard(totalDays: provider.totalClaimDays),
                    SizedBox(height: AppSize.h20),
                    _ScProgressCard(
                      currentDay: provider.currentCheckInDay,
                      rewardCoins: provider.dailyRewardCoins,
                      isClaimed: provider.isRewardClaimed,
                      onClaim: provider.isRewardClaimed
                          ? null
                          : () {
                              AnalyticsManager.instance.logEvent(
                                name: 'daily_checkin_page_claim_tap',
                                parameters: {
                                  'coins': provider.dailyRewardCoins,
                                },
                              );
                              provider.claimReward(context);
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Total streak card — orange flame badge + lifetime claim count
// ─────────────────────────────────────────────────────────────────────────────

class _ScTotalStreakCard extends StatelessWidget {
  const _ScTotalStreakCard({required this.totalDays});

  final int totalDays;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSize.r20);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w20,
        vertical: AppSize.h18,
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        color: _kCardBg,
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
            blurRadius: AppSize.r14,
            offset: Offset(0, AppSize.h6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: AppSize.sp54,
            height: AppSize.sp54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFB347), _kOrange],
              ),
              boxShadow: [
                BoxShadow(
                  color: _kOrange.withValues(alpha: 0.35),
                  blurRadius: AppSize.r10,
                  offset: Offset(0, AppSize.h4),
                ),
              ],
            ),
            child: Assets.icons.scFlame.svg(
              height: AppSize.sp26,
              width: AppSize.sp26,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
          SizedBox(width: AppSize.w16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.totalDaysClaimed,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: _kTextMuted,
                    fontSize: AppSize.sp13,
                  ),
                ),
                SizedBox(height: AppSize.h4),
                Text(
                  context.l10n.homeStreakDays(totalDays),
                  style: context.textTheme.titleLarge?.copyWith(
                    color: _kTextDark,
                    fontWeight: FontWeight.w800,
                    fontSize: AppSize.sp22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress card — trophy, day badge, animated count + bar, claim CTA
// ─────────────────────────────────────────────────────────────────────────────

class _ScProgressCard extends StatefulWidget {
  const _ScProgressCard({
    required this.currentDay,
    required this.rewardCoins,
    required this.isClaimed,
    required this.onClaim,
  });

  final int currentDay;
  final int rewardCoins;
  final bool isClaimed;
  final VoidCallback? onClaim;

  @override
  State<_ScProgressCard> createState() => _ScProgressCardState();
}

class _ScProgressCardState extends State<_ScProgressCard>
    with TickerProviderStateMixin {
  late final AnimationController _trophyController;
  late final AnimationController _progressController;
  late final AnimationController _coinController;
  late final AnimationController _glowController;
  late final Animation<double> _progressAnim;
  late final Animation<int> _coinAnim;

  @override
  void initState() {
    super.initState();

    _trophyController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _progressAnim = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );

    _coinController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _coinAnim = IntTween(begin: 0, end: widget.rewardCoins).animate(
      CurvedAnimation(parent: _coinController, curve: Curves.easeOut),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      _progressController.forward();
      _coinController.forward();
    });
  }

  @override
  void dispose() {
    _trophyController.dispose();
    _progressController.dispose();
    _coinController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSize.r24);

    return Container(
      padding: EdgeInsets.all(AppSize.sp22),
      decoration: BoxDecoration(
        borderRadius: radius,
        color: _kCardBg,
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.12),
            blurRadius: AppSize.r20,
            offset: Offset(0, AppSize.h10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ScAnimatedTrophy(controller: _trophyController),
          SizedBox(height: AppSize.h14),
          Text(
            context.l10n.dailyCheckinReward,
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium?.copyWith(
              color: _kTextDark,
              fontSize: AppSize.sp20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppSize.h10),
          _ScDayBadge(day: widget.currentDay),
          SizedBox(height: AppSize.h18),
          if (widget.isClaimed)
            Text(
              context.l10n.alreadyClaimedToday,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: _kTextMuted,
                fontSize: AppSize.sp14,
              ),
            )
          else ...[
            _ScCoinCounter(animation: _coinAnim),
            SizedBox(height: AppSize.h6),
            Text(
              context.l10n.keepStreakGoing,
              style: context.textTheme.bodySmall?.copyWith(
                color: _kTextMuted,
                fontSize: AppSize.sp13,
              ),
            ),
          ],
          SizedBox(height: AppSize.h20),
          _ScAnimatedProgressBar(
            currentDay: widget.currentDay,
            progressAnim: _progressAnim,
          ),
          SizedBox(height: AppSize.h20),
          AdDisclaimerText(show: RewardAdService.isDailyCheckinAdEnabled),
          _ScClaimButton(
            label: widget.isClaimed ? context.l10n.claimed : context.l10n.claimReward,
            onPressed: widget.onClaim,
            glowController: _glowController,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trophy with breathing glow halo
// ─────────────────────────────────────────────────────────────────────────────

class _ScAnimatedTrophy extends StatelessWidget {
  const _ScAnimatedTrophy({required this.controller});

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
        child: Assets.images.scDailyRewardTrophy.image(
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

class _ScDayBadge extends StatelessWidget {
  const _ScDayBadge({required this.day});

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
          Assets.icons.scFlame.svg(
            height: AppSize.sp14,
            width: AppSize.sp14,
            colorFilter: const ColorFilter.mode(_kOrange, BlendMode.srcIn),
          ),
          SizedBox(width: AppSize.w6),
          Text(
            context.l10n.dayBadge(day),
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

class _ScCoinCounter extends StatelessWidget {
  const _ScCoinCounter({required this.animation});

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
              child: Assets.images.scGift.image(
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
                context.l10n.coinsLabel,
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

class _ScAnimatedProgressBar extends StatelessWidget {
  const _ScAnimatedProgressBar({
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
// Claim button — blue gradient with pulsing glow, disabled state when claimed
// ─────────────────────────────────────────────────────────────────────────────

class _ScClaimButton extends StatelessWidget {
  const _ScClaimButton({
    required this.label,
    required this.onPressed,
    required this.glowController,
  });

  final String label;
  final VoidCallback? onPressed;
  final AnimationController glowController;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final radius = BorderRadius.circular(AppSize.r100);

    return SizedBox(
      width: double.infinity,
      child: AnimatedBuilder(
        animation: glowController,
        builder: (_, child) {
          if (isDisabled) return child!;
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
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDisabled
                      ? const [Color(0xFFC7CFE2), Color(0xFFA8B3CC)]
                      : const [Color(0xFF5577FF), _kBlueDeep],
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: AppSize.sp16,
                    ),
                  ),
                  if (!isDisabled) ...[
                    SizedBox(width: AppSize.w8),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: AppSize.w16,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
