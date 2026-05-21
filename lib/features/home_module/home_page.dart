import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/features/home_module/provider/home_provider.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/services/reward_ad_service.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:spin_craze/widgets/ad_disclaimer_text.dart';
import 'package:spin_craze/widgets/app_button.dart';
import 'package:spin_craze/widgets/coin_chip.dart';
import 'package:spin_craze/widgets/glow_container.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/navigation_helper.dart';
import 'package:spin_craze/widgets/common_appbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// ClipEarn home screen.
///
/// The screen background and bottom navigation are owned by `BottomNavPage`,
/// so this widget is a transparent [Scaffold] that just lays out the content.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _db = Injector.instance<AppDB>();
  //TODO: HOME PAGE AD
  // NativeAdManager? _homeNativeAd;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logScreenView(
      screenName: 'home',
      screenClass: 'HomePage',
    );
    //TODO: HOME PAGE AD
    // final adData = RemoteConfigService.instance.homeNative;
    // if (adData.enabled) {
    //   _homeNativeAd = NativeAdManager(adData: adData);
    //   _homeNativeAd!.load();
    //   _homeNativeAd!.future().then((_) {
    //     if (mounted) setState(() {});
    //   });
    // }
  }

  @override
  void dispose() {
    //TODO: HOME PAGE AD
    // _homeNativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _db.userListenable(),
      builder: (context, _) {
        final provider = context.read<HomeProvider>();
        final user = _db.userModel;
        final coins = user?.coin.toInt() ?? 0;
        final xp = user?.xp.toInt() ?? 0;
        final level = user?.level.toInt() ?? 1;
        final streak = user?.totalClaimDays ?? 0;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CommonAppBar(
            leading: CoinChip(
              amount: '$coins',
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD84D).withValues(alpha: 0.7),
                  const Color(0xFFFFD84D).withValues(alpha: 0.5),
                  const Color(0xFFFFD84D).withValues(alpha: 0.0),
                ],
              ),
              borderColor: Colors.transparent,
              onTap: () {
                AnalyticsManager.instance.logEvent(
                  name: 'home_coin_chip_tap',
                );
                context.pushNamed(AppRoutes.walletScreen);
              },
            ),
            center: Assets.images.smallAppLogo.image(
              height: AppSize.sp55,
              width: AppSize.sp55,
            ),
            trailing: _StreakChip(
              days: streak,
              onTap: () {
                AnalyticsManager.instance.logEvent(
                  name: 'home_streak_chip_tap',
                );
                context.pushNamed(AppRoutes.dailyCheckin);
              },
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSize.w16,
              AppSize.h16,
              AppSize.w16,
              AppSize.h120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DailyRewardCard(
                  coins: provider.dailyRewardCoins,
                  isClaimed: provider.isRewardClaimed,
                  onClaim: () {
                    AnalyticsManager.instance.logEvent(
                      name: 'daily_reward_claim_tap',
                      parameters: {'coins': provider.dailyRewardCoins},
                    );
                    provider.claimReward(context);
                  },
                ),
                SizedBox(height: AppSize.h20),
                _TotalBalanceCard(
                  balance:
                      r'$'
                      '${(coins / RemoteConfigService.instance.coinToDollarDivider).toStringAsFixed(2)}',
                  coins: coins,
                  xp: xp,
                ),
                SizedBox(height: AppSize.h16),
                _StatTilesRow(level: level, xp: xp),
                SizedBox(height: AppSize.h24),
                Text(
                  context.l10n.earnMoney,
                  style: context.textTheme.titleLarge,
                ),
                SizedBox(height: AppSize.h40),
                const _EarnMoneyGrid(),
                SizedBox(height: AppSize.h20),
                //TODO: HOME PAGE AD
                // NativeAdsWidget(nativeAd: _homeNativeAd),
                // SizedBox(height: AppSize.h16),
                const _Leaderboard(),
                SizedBox(height: AppSize.h20),
                const _HowItWorksBanner(),
                SizedBox(height: AppSize.h16),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Streak chip (top bar trailing)
// ─────────────────────────────────────────────────────────────────────────────

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days, this.onTap});

  final int days;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSize.r100);
    final chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w12,
        vertical: AppSize.h6,
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF8C24).withValues(alpha: 0.0),
            const Color(0xFFFF8C24).withValues(alpha: 0.5),
            const Color(0xFFFF8C24).withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.daysCount(days),
            style: context.textTheme.labelMedium?.copyWith(
              color: context.themeTextColors.primary,
              fontSize: AppSize.sp12,
            ),
          ),
          SizedBox(width: AppSize.w6),
          Assets.icons.flame.svg(height: AppSize.sp18, width: AppSize.sp18),
        ],
      ),
    );

    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: chip,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily reward card
// ─────────────────────────────────────────────────────────────────────────────

class _DailyRewardCard extends StatelessWidget {
  const _DailyRewardCard({
    required this.coins,
    this.isClaimed = false,
    this.onClaim,
  });

  final int coins;
  final bool isClaimed;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final textColors = context.themeTextColors;

    final radius = BorderRadius.circular(AppSize.r20);

    return GlowContainer(
      accent: context.themeColors.primary,
      borderRadius: radius.topLeft.x,
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            AppSize.w20,
            AppSize.h20,
            AppSize.w20,
            AppSize.h20,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            // Flat deep cyan-teal base matching the mockup.
            color: const Color(0xFF0B4E6A),
            border: Border.all(
              color: const Color(0xFF5CCBF7).withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00B7FF).withValues(alpha: 0.25),
                blurRadius: AppSize.r24,
                offset: Offset(0, AppSize.h8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Wide cyan bloom centered at the top, fading downward
              Positioned(
                left: 0,
                right: 0,
                top: -AppSize.h100,
                child: IgnorePointer(
                  child: Container(
                    height: AppSize.sp200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.transparent),
                      gradient: RadialGradient(
                        center: Alignment.center,
                        // radius: 0.7,
                        colors: [
                          const Color(0xFF5CCBF7).withValues(alpha: 0.8),
                          const Color(0xFF29B0E6).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Trophy image, positioned to overflow the right edge
              Positioned(
                right: -AppSize.w4,
                top: -AppSize.h4,
                child: Assets.images.dailyRewardTrophy.image(
                  height: AppSize.h112,
                  width: AppSize.h112,
                  fit: BoxFit.contain,
                ),
              ),
              // Text + CTA
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.dailyReward,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: textColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: AppSize.sp22,
                    ),
                  ),
                  SizedBox(height: AppSize.h4),
                  SizedBox(
                    width: AppSize.w170,
                    child: Text(
                      context.l10n.collectMoreCoinsEachDay,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: textColors.primary.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSize.h16),
                  Row(
                    children: [
                      Assets.images.gift.image(
                        height: AppSize.sp28,
                        width: AppSize.sp28,
                      ),
                      SizedBox(width: AppSize.w8),
                      Text(
                        context.l10n.coinsPrefix(coins.toString()),
                        style: context.textTheme.titleLarge?.copyWith(
                          color: textColors.primary,
                          fontSize: AppSize.sp22,
                        ),
                      ),
                      SizedBox(width: AppSize.w4),
                      Text(
                        context.l10n.coinsSlash(coins.toString()),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: textColors.primary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  AdDisclaimerText(
                    show: RewardAdService.isDailyCheckinAdEnabled,
                  ),
                  SizedBox(height: AppSize.h8),
                  _PaleCyanButton(
                    label: isClaimed
                        ? context.l10n.claimed
                        : context.l10n.claimNow,
                    onPressed: isClaimed ? () {} : (onClaim ?? () {}),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pale-cyan pill button used on the Daily Reward and Total Balance cards.
class _PaleCyanButton extends StatelessWidget {
  const _PaleCyanButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSize.r100);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: Container(
          height: AppSize.h44,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF9AE0FA), Color(0xFF5CCBF7)],
            ),
            border: Border.all(color: const Color(0xFFB8ECFF)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5CCBF7).withValues(alpha: 0.45),
                blurRadius: AppSize.r16,
                offset: Offset(0, AppSize.h4),
              ),
            ],
          ),
          child: Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF003A52),
              fontSize: AppSize.sp16,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Total balance card
// ─────────────────────────────────────────────────────────────────────────────

class _TotalBalanceCard extends StatelessWidget {
  const _TotalBalanceCard({
    required this.balance,
    required this.coins,
    required this.xp,
  });

  final String balance;
  final int coins;
  final int xp;

  @override
  Widget build(BuildContext context) {
    final textColors = context.themeTextColors;

    final radius = BorderRadius.circular(AppSize.r20);

    return GlowContainer(
      accent: const Color(0xFFA86CFF),
      borderRadius: radius.topLeft.x,
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.all(AppSize.sp20),
          decoration: BoxDecoration(
            borderRadius: radius,
            // Flat deep purple base matching the mockup.
            color: const Color(0xFF2B0B5C),
            border: Border.all(
              color: const Color(0xFFC89AFF).withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA86CFF).withValues(alpha: 0.3),
                blurRadius: AppSize.r24,
                offset: Offset(0, AppSize.h8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Wide purple bloom centered at the top, fading downward
              Positioned(
                left: 0,
                right: 0,
                top: -AppSize.h100,
                child: IgnorePointer(
                  child: Container(
                    height: AppSize.sp200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.transparent),
                      gradient: RadialGradient(
                        center: Alignment.center,
                        // radius: 0.7,
                        colors: [
                          const Color(0xFFC37DFF).withValues(alpha: 0.85),
                          const Color(0xFFA95CF5).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.totalBalance,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: textColors.primary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: AppSize.h4),
                  Text(
                    balance,
                    style: context.textTheme.displayLarge?.copyWith(
                      color: textColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: AppSize.sp36,
                    ),
                  ),
                  SizedBox(height: AppSize.h10),
                  Row(
                    children: [
                      Assets.icons.coins.svg(
                        height: AppSize.sp18,
                        width: AppSize.sp18,
                      ),
                      SizedBox(width: AppSize.w6),
                      Text(
                        context.l10n.coinsAmount(coins.toString()),
                        style: context.textTheme.labelMedium?.copyWith(
                          color: textColors.primary,
                        ),
                      ),
                      SizedBox(width: AppSize.w16),
                      Assets.icons.thunder.svg(
                        height: AppSize.sp18,
                        width: AppSize.sp18,
                      ),
                      SizedBox(width: AppSize.w6),
                      Text(
                        context.l10n.xpAmount(xp.toString()),
                        style: context.textTheme.labelMedium?.copyWith(
                          color: textColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSize.h16),
                  Divider(
                    color: textColors.primary.withValues(alpha: 0.22),
                    height: 1,
                  ),
                  SizedBox(height: AppSize.h16),
                  Row(
                    children: [
                      Expanded(
                        child: _PaleCyanButton(
                          label: context.l10n.withdraw,
                          onPressed: () {
                            AnalyticsManager.instance.logEvent(
                              name: 'home_withdraw_tap',
                            );
                            context.pushNamed(AppRoutes.walletScreen);
                          },
                        ),
                      ),
                      SizedBox(width: AppSize.w12),
                      Expanded(
                        child: AppButton(
                          label: context.l10n.rewards,
                          variant: AppButtonVariant.outline,
                          borderRadius: AppSize.r100,
                          onPressed: () {
                            AnalyticsManager.instance.logEvent(
                              name: 'home_rewards_tap',
                            );
                            context.go('/${AppRoutes.rewards}');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat tiles (Level / Today / XP)
// ─────────────────────────────────────────────────────────────────────────────

class _StatTilesRow extends StatelessWidget {
  const _StatTilesRow({
    required this.level,
    // required this.today,
    required this.xp,
  });

  final int level;
  // final int today;
  final int xp;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSize.w12,
      children: [
        Expanded(
          child: _StatTile(
            label: context.l10n.level,
            value: '$level',
            icon: Assets.icons.user,
            accent: const Color(0xFFA86CFF),
          ),
        ),
        // Expanded(
        //   child: _StatTile(
        //     label: 'Today',
        //     value: '$today',
        //     icon: Assets.icons.flame,
        //     accent: const Color(0xFFFF8C24),
        //   ),
        // ),
        Expanded(
          child: _StatTile(
            label: context.l10n.xp,
            value: '$xp',
            icon: Assets.icons.thunder,
            accent: const Color(0xFFA2FF60),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final SvgGenImage icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final textColors = context.themeTextColors;

    return GlowContainer(
      accent: accent,
      borderRadius: AppSize.r16,
      child: Container(
        height: AppSize.h66,
        padding: EdgeInsets.all(AppSize.sp12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Bottom-right accent glow — center sits on the corner
            Positioned(
              right: -AppSize.w36,
              bottom: -AppSize.h36,
              child: IgnorePointer(
                child: Container(
                  width: AppSize.sp72,
                  height: AppSize.sp72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: 0.7),
                        accent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: textColors.secondary,
                    fontSize: AppSize.sp12,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    // Solid rounded-square badge behind the icon
                    Flexible(
                      child: icon.svg(
                        height: AppSize.sp20,
                        width: AppSize.sp20,
                        colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                      ),
                    ),
                    SizedBox(width: AppSize.w6),
                    Flexible(
                      child: FittedBox(
                        child: Text(
                          value,
                          style: context.textTheme.titleMedium?.copyWith(
                            color: textColors.primary,
                            fontSize: AppSize.sp14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Earn Money grid
// ─────────────────────────────────────────────────────────────────────────────

class _EarnMoneyGrid extends StatelessWidget {
  const _EarnMoneyGrid();

  @override
  Widget build(BuildContext context) {
    final nav = NavigationHelper();
    void logEarnTap(String module) {
      AnalyticsManager.instance.logEvent(
        name: 'home_earn_module_tap',
        parameters: {'module': module},
      );
    }

    final items = <_EarnItemData>[
      _EarnItemData(
        context.l10n.quizMaster,
        context.l10n.answerAndEarn,
        Assets.images.quizMaster,
        onTap: () {
          logEarnTap('quiz_master');
          nav.navigateWithAdCheck(
            context,
            () => context.pushNamed(AppRoutes.quizScreen),
          );
        },
      ),
      _EarnItemData(
        context.l10n.spinWheel,
        context.l10n.spinAndWin,
        Assets.images.spinWheel,
        onTap: () {
          logEarnTap('spin_wheel');
          nav.navigateWithAdCheck(
            context,
            () => context.pushNamed(AppRoutes.spinWheelScreen),
          );
        },
      ),
      _EarnItemData(
        context.l10n.scratchCard,
        context.l10n.scratchAndReveal,
        Assets.images.scratchCard,
        onTap: () {
          logEarnTap('scratch_card');
          nav.navigateWithAdCheck(
            context,
            () => context.pushNamed(AppRoutes.scratchCard),
          );
        },
      ),
      _EarnItemData(
        context.l10n.webVisits,
        context.l10n.visitAndEarn,
        Assets.images.webVisits,
        onTap: () {
          logEarnTap('web_visits');
          nav.navigateWithAdCheck(
            context,
            () => context.pushNamed(AppRoutes.webVisitsScreen),
          );
        },
      ),
      _EarnItemData(
        context.l10n.gameZone,
        context.l10n.playGames,
        Assets.images.gameZone,
        onTap: () {
          logEarnTap('game_zone');
          nav.navigateWithAdCheck(
            context,
            () => context.pushNamed(AppRoutes.gameZoneScreen),
          );
        },
      ),
      _EarnItemData(
        context.l10n.referAndEarn,
        context.l10n.inviteFriends,
        Assets.images.referAndEarn,
        onTap: () {
          logEarnTap('refer_and_earn');
          nav.navigateWithAdCheck(
            context,
            () => context.go('/${AppRoutes.rewards}'),
          );
        },
      ),
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSize.w12,
        // Extra vertical spacing so images overflowing the top of each tile
        // don't collide with the row above.
        mainAxisSpacing: AppSize.h36,
        childAspectRatio: 2,
      ),
      itemBuilder: (_, i) => _EarnItemCard(data: items[i]),
    );
  }
}

class _EarnItemData {
  const _EarnItemData(this.title, this.subtitle, this.image, {this.onTap});
  final String title;
  final String subtitle;
  final AssetGenImage image;
  final VoidCallback? onTap;
}

class _EarnItemCard extends StatelessWidget {
  const _EarnItemCard({required this.data});

  final _EarnItemData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final textColors = context.themeTextColors;
    final radius = BorderRadius.circular(AppSize.r16);

    // Outer stack with `clipBehavior: none` so the image can overflow the
    // top of the tile (wings sticking out, matching the Figma).
    return Stack(
      clipBehavior: Clip.none,
      children: [
        //Glow effect
        Positioned.fill(
          child: GlowContainer(
            accent: Color(0xffFFD92B),
            borderRadius: radius.bottomLeft.x,
            child: Container(
              height: AppSize.h78,
              padding: EdgeInsets.all(AppSize.sp14),
            ),
          ),
        ),
        // The tile itself — own ClipRRect so the gold corner glow is clipped
        // to the rounded shape, but the outer stack is still unclipped.
        Positioned.fill(
          child: InkWell(
            borderRadius: radius,
            onTap: data.onTap,
            child: ClipRRect(
              borderRadius: radius,
              child: Container(
                height: AppSize.h78,
                padding: EdgeInsets.all(AppSize.sp14),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  // color: colors.surface,
                  gradient: LinearGradient(
                    colors: [
                      colors.surface,
                      colors.surface,
                      Color(0xffFFD92B).withValues(alpha: 0.7),
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      data.title,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: textColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppSize.h2),
                    Text(
                      data.subtitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: textColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Image overflowing the top of the tile
        Positioned(
          left: AppSize.w8,
          top: -AppSize.h28,
          child: IgnorePointer(
            child: data.image.image(height: AppSize.h48, fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// How It Works
// ─────────────────────────────────────────────────────────────────────────────

class _HowItWorksBanner extends StatelessWidget {
  const _HowItWorksBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final textColors = context.themeTextColors;
    final radius = BorderRadius.circular(AppSize.r16);

    return GlowContainer(
      accent: colors.primary,
      borderRadius: AppSize.r16,
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w16,
        vertical: AppSize.h16,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cyan corner glow — center anchored to bottom-right corner
          Positioned(
            right: -AppSize.w60,
            bottom: -AppSize.h60,
            child: IgnorePointer(
              child: Container(
                width: AppSize.sp120,
                height: AppSize.sp120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.55),
                      colors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Assets.icons.question.svg(
                height: AppSize.sp20,
                width: AppSize.sp20,
                colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
              ),
              SizedBox(width: AppSize.w12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.howItWorks,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: textColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppSize.h2),
                    Text(
                      context.l10n.learnStepByStep,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: textColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSize.w8),
              _PaleCyanLearnButton(
                onPressed: () {
                  AnalyticsManager.instance.logEvent(
                    name: 'home_how_it_works_tap',
                  );
                  context.pushNamed(AppRoutes.howItWorks);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaleCyanLearnButton extends StatelessWidget {
  const _PaleCyanLearnButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSize.r100);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.w20,
            vertical: AppSize.h10,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF9AE0FA), Color(0xFF5CCBF7)],
            ),
          ),
          child: Text(
            context.l10n.learn,
            style: context.textTheme.labelMedium?.copyWith(
              color: const Color(0xFF003A52),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Leaderboard / Achievements
// ─────────────────────────────────────────────────────────────────────────────

class _Leaderboard extends StatelessWidget {
  const _Leaderboard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // height: AppSize.h66,
      child: Row(
        children: [
          Expanded(
            child: _IconStatTile(
              caption: context.l10n.seeTopEarner,
              label: context.l10n.leaderboard,
              icon: Assets.icons.chartBar,
              accent: const Color(0xFFFFD84D),
              onTap: () {
                AnalyticsManager.instance.logEvent(
                  name: 'home_leaderboard_tap',
                );
                NavigationHelper().navigateWithAdCheck(
                  context,
                  () => context.go('/${AppRoutes.rank}'),
                );
              },
            ),
          ),
          // SizedBox(width: AppSize.w12),
          // Expanded(
          //   child: _IconStatTile(
          //     caption: 'Unlock your Badges',
          //     label: 'Achievements',
          //     icon: Assets.icons.trophy,
          //     accent: const Color(0xFFFF5183),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _IconStatTile extends StatelessWidget {
  const _IconStatTile({
    required this.caption,
    required this.label,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  final String caption;
  final String label;
  final SvgGenImage icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColors = context.themeTextColors;
    final radius = BorderRadius.circular(AppSize.r16);

    return GlowContainer(
      accent: accent,
      borderRadius: AppSize.r16,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSize.sp14),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -AppSize.w50,
                  bottom: -AppSize.h50,
                  child: IgnorePointer(
                    child: Container(
                      width: AppSize.sp100,
                      height: AppSize.sp100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accent.withValues(alpha: 0.65),
                            accent.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caption,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: textColors.secondary,
                        fontSize: AppSize.sp12,
                      ),
                    ),
                    SizedBox(height: AppSize.h4),
                    FittedBox(
                      child: Row(
                        children: [
                          icon.svg(
                            height: AppSize.sp22,
                            width: AppSize.sp22,
                            colorFilter: ColorFilter.mode(
                              accent,
                              BlendMode.srcIn,
                            ),
                          ),
                          SizedBox(width: AppSize.w8),
                          Text(
                            label,
                            style: context.textTheme.titleSmall?.copyWith(
                              color: textColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: AppSize.sp14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
