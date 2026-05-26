import 'dart:async';

import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/features/home_module/provider/home_provider.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/services/reward_ad_service.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:spin_craze/widgets/ad_disclaimer_text.dart';
import 'package:spin_craze/widgets/coin_chip.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Local light-theme palette for the home screen (the rest of the app is still
// dark themed — see CLAUDE.md "UI revamp pass").
const _kPageBg = Color(0xFFF4F7FE);
const _kCardBg = Colors.white;
const _kCardBorder = Color(0xFFE5EBF5);
const _kBlue = Color(0xFF2563EB);
const _kBlueDeep = Color(0xFF1E3FE0);
const _kBlueSoft = Color(0xFFE6EEFF);
const _kTextDark = Color(0xFF111827);
const _kTextMuted = Color(0xFF6B7280);

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
          backgroundColor: _kPageBg,
          appBar: _HomeAppBar(
            coins: coins,
            streak: streak,
            onCoinsTap: () {
              AnalyticsManager.instance.logEvent(name: 'home_coin_chip_tap');
              context.pushNamed(AppRoutes.walletScreen);
            },
            onStreakTap: () {
              AnalyticsManager.instance.logEvent(name: 'home_streak_chip_tap');
              context.pushNamed(AppRoutes.dailyCheckin);
            },
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
                const _EarnModulesCarousel(),
                SizedBox(height: AppSize.h24),
                _HeroCarousel(
                  dailyRewardCoins: provider.dailyRewardCoins,
                  isRewardClaimed: provider.isRewardClaimed,
                  onClaim: () {
                    AnalyticsManager.instance.logEvent(
                      name: 'daily_reward_claim_tap',
                      parameters: {'coins': provider.dailyRewardCoins},
                    );
                    provider.claimReward(context);
                  },
                  balance:
                      r'$'
                      '${(coins / RemoteConfigService.instance.coinToDollarDivider).toStringAsFixed(2)}',
                  coins: coins,
                  xp: xp,
                ),
                SizedBox(height: AppSize.h20),
                _StatTilesRow(level: level, xp: xp),
                SizedBox(height: AppSize.h20),
                //TODO: HOME PAGE AD
                // NativeAdsWidget(nativeAd: _homeNativeAd),
                // SizedBox(height: AppSize.h16),
                const _HowItWorksBanner(),
                SizedBox(height: AppSize.h20),
                const _Leaderboard(),
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
// Home app bar (light variant — replaces CommonAppBar on this screen only)
// ─────────────────────────────────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar({
    required this.coins,
    required this.streak,
    required this.onCoinsTap,
    required this.onStreakTap,
  });

  final int coins;
  final int streak;
  final VoidCallback onCoinsTap;
  final VoidCallback onStreakTap;

  @override
  Size get preferredSize => Size.fromHeight(AppSize.h100);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSize.w16),
            child: Row(
              children: [
                CoinChip(
                  amount: '$coins',
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD84D).withValues(alpha: 0.7),
                      const Color(0xFFFFD84D).withValues(alpha: 0.5),
                      const Color(0xFFFFD84D).withValues(alpha: 0.0),
                    ],
                  ),
                  borderColor: Colors.transparent,
                  onTap: onCoinsTap,
                ),
                Expanded(
                  child: Center(
                    child: Assets.images.smallAppLogo.image(
                      height: AppSize.sp50,
                      width: AppSize.sp50,
                    ),
                  ),
                ),
                _StreakChip(days: streak, onTap: onStreakTap),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            child: CustomPaint(
              size: const Size(double.infinity, 2),
              painter: PremiumDividerPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Streak chip (top bar trailing)
// ─────────────────────────────────────────────────────────────────────────────

class PremiumDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x00C9CBD3),
          Color(0xFFC9CBD3),
          Color(0xFFC9CBD3),
          Color(0x00C9CBD3),
        ],
        stops: [0.0, 0.08, 0.92, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // main divider
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // top soft highlight
    final highlight = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.45)
      ..strokeWidth = 0.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, (size.height / 2) - 0.6),
      Offset(size.width, (size.height / 2) - 0.6),
      highlight,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days, this.onTap});

  final int days;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      bottomRight: Radius.circular(AppSize.r100),
      topRight: Radius.circular(AppSize.r100),
    );
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
            '$days Days',
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
      child: InkWell(borderRadius: radius, onTap: onTap, child: chip),
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
    final radius = BorderRadius.circular(AppSize.r20);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSize.w22,
          AppSize.h22,
          AppSize.w22,
          AppSize.h22,
        ),
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A6BFF), _kBlueDeep],
          ),
          boxShadow: [
            BoxShadow(
              color: _kBlue.withValues(alpha: 0.30),
              blurRadius: AppSize.r24,
              offset: Offset(0, AppSize.h10),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Treasure chest, positioned to overflow the right edge.
            Positioned(
              right: -AppSize.w8,
              top: -AppSize.h4,
              child: Assets.images.dailyRewardTrophy.image(
                height: AppSize.h120,
                width: AppSize.h120,
                fit: BoxFit.contain,
              ),
            ),
            // Text + CTA
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Reward',
                  style: context.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: AppSize.sp24,
                  ),
                ),
                SizedBox(height: AppSize.h6),
                SizedBox(
                  width: AppSize.w170,
                  child: Text(
                    'Collect more coins\neach day',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.25,
                    ),
                  ),
                ),
                SizedBox(height: AppSize.h20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Assets.images.gift.image(
                      height: AppSize.sp28,
                      width: AppSize.sp28,
                    ),
                    SizedBox(width: AppSize.w10),
                    Text(
                      '+$coins',
                      style: context.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: AppSize.sp24,
                      ),
                    ),
                    SizedBox(width: AppSize.w6),
                    Padding(
                      padding: EdgeInsets.only(top: AppSize.h4),
                      child: Text(
                        '/Coins',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
                AdDisclaimerText(show: RewardAdService.isDailyCheckinAdEnabled),
                SizedBox(height: AppSize.h18),
                _PaleCyanButton(
                  label: isClaimed ? 'Claimed' : 'Claim Now',
                  onPressed: isClaimed ? () {} : (onClaim ?? () {}),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// White pill button used on the Daily Reward and Total Balance cards.
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
            color: const Color(0xFFDDDDD7),
            border: Border.all(
              color: const Color(0xFFA38E72),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1F4D).withValues(alpha: 0.14),
                blurRadius: AppSize.r12,
                offset: Offset(0, AppSize.h4),
              ),
            ],
          ),
          child: Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF0B1726),
              fontWeight: FontWeight.w800,
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
    final radius = BorderRadius.circular(AppSize.r20);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSize.w22,
          AppSize.h22,
          AppSize.w16,
          AppSize.h22,
        ),
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A6BFF), _kBlueDeep],
          ),
          boxShadow: [
            BoxShadow(
              color: _kBlue.withValues(alpha: 0.30),
              blurRadius: AppSize.r24,
              offset: Offset(0, AppSize.h10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Total Balance',
                    style: context.textTheme.titleSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: AppSize.h6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      balance,
                      style: context.textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: AppSize.sp36,
                        height: 1.0,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSize.h14),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Assets.icons.coins.svg(
                          height: AppSize.sp18,
                          width: AppSize.sp18,
                        ),
                        SizedBox(width: AppSize.w6),
                        Text(
                          '$coins Coins',
                          style: context.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: AppSize.w12),
                        Assets.icons.thunder.svg(
                          height: AppSize.sp18,
                          width: AppSize.sp18,
                        ),
                        SizedBox(width: AppSize.w6),
                        Text(
                          '$xp XP',
                          style: context.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSize.w10),
            SizedBox(
              width: AppSize.w140,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PaleCyanButton(
                    label: 'Withdraw',
                    onPressed: () {
                      AnalyticsManager.instance.logEvent(
                        name: 'home_withdraw_tap',
                      );
                      context.pushNamed(AppRoutes.walletScreen);
                    },
                  ),
                  SizedBox(height: AppSize.h12),
                  _OutlineWhiteButton(
                    label: 'Rewards',
                    onPressed: () {
                      AnalyticsManager.instance.logEvent(
                        name: 'home_rewards_tap',
                      );
                      context.go('/${AppRoutes.rewards}');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White-outline pill used as a secondary CTA on the blue Total Balance card.
class _OutlineWhiteButton extends StatelessWidget {
  const _OutlineWhiteButton({required this.label, required this.onPressed});

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
            color: Colors.transparent,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.95),
              width: 1.8,
            ),
          ),
          child: Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: AppSize.sp16,
            ),
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
  const _StatTilesRow({required this.level, required this.xp});

  final int level;
  final int xp;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatTile(
          label: 'Level',
          value: '$level',
          icon: Assets.icons.user,
          accent: const Color(0xFFB1232E),
        ),
        _StatTile(
          label: 'Today',
          value: '0',
          icon: Assets.icons.flame,
          accent: const Color(0xFFFF7A24),
        ),
        _StatTile(
          label: 'XP',
          value: '$xp',
          icon: Assets.icons.thunder,
          accent: _kBlue,
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
    final radius = BorderRadius.circular(AppSize.r16);

    return Container(
      height: AppSize.h72,
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w18,
        vertical: AppSize.h8,
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE6EEFF), Color(0xFFD3DEFA)],
        ),
        border: Border.all(color: const Color(0xFFBFCDEE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1F4D).withValues(alpha: 0.05),
            blurRadius: AppSize.r10,
            offset: Offset(0, AppSize.h4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: context.textTheme.titleSmall?.copyWith(
              color: _kTextDark,
              fontSize: AppSize.sp13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSize.h6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon.svg(
                height: AppSize.sp22,
                width: AppSize.sp22,
                colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
              ),
              SizedBox(width: AppSize.w8),
              Text(
                value,
                style: context.textTheme.titleMedium?.copyWith(
                  color: _kTextDark,
                  fontSize: AppSize.sp18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Earn Money carousel (top icons + featured card + page indicator)
// ─────────────────────────────────────────────────────────────────────────────

class _EarnModulesCarousel extends StatefulWidget {
  const _EarnModulesCarousel();

  @override
  State<_EarnModulesCarousel> createState() => _EarnModulesCarouselState();
}

class _EarnModulesCarouselState extends State<_EarnModulesCarousel> {
  static const int _itemsCount = 6;

  // Quiz Master sits at index 2 in the items list — centered at first paint.
  static const int _initialIconIndex = 2;

  // Cards use a builder with no itemCount (infinite forward); a large multiple
  // of [_itemsCount] is chosen so the modulo lands on Quiz Master initially
  // and there is effectively unlimited room to scroll forward (and back).
  static const int _cardInitialPage = _itemsCount * 1000 + _initialIconIndex;

  final PageController _iconController = PageController(
    viewportFraction: 0.24,
    initialPage: _initialIconIndex,
  );
  final PageController _cardController = PageController(
    initialPage: _cardInitialPage,
  );
  Timer? _autoScrollTimer;
  int _iconIndex = _initialIconIndex;
  int _cardIndex = _initialIconIndex;

  @override
  void initState() {
    super.initState();
    // Cards auto-advance forward forever — never animate backward, so the
    // user never sees the carousel "rewind" to the first card.
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_cardController.hasClients) return;
      _cardController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _iconController.dispose();
    _cardController.dispose();
    super.dispose();
  }

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
        'Refer & Earn',
        'Invite Friends',
        Assets.images.referAndEarn,
        Assets.icons.icReferAndEarn,
        onTap: () {
          logEarnTap('refer_and_earn');
          nav.navigateWithAdCheck(
            context,
            () => context.go('/${AppRoutes.rewards}'),
          );
        },
      ),
      _EarnItemData(
        'Spin Wheel',
        'Spin and Win',
        Assets.images.spinWheel,
        Assets.icons.icSpinWheel,
        onTap: () {
          logEarnTap('spin_wheel');
          nav.navigateWithAdCheck(
            context,
            () => context.pushNamed(AppRoutes.spinWheelScreen),
          );
        },
      ),
      _EarnItemData(
        'Quiz Master',
        'Answer & Earn',
        Assets.images.quizMaster,
        Assets.icons.icQuizMaster,
        onTap: () {
          logEarnTap('quiz_master');
          nav.navigateWithAdCheck(
            context,
            () => context.pushNamed(AppRoutes.quizScreen),
          );
        },
      ),
      _EarnItemData(
        'Scratch Card',
        'Scratch & Reveal',
        Assets.images.scratchCard,
        Assets.icons.icScratch,
        onTap: () {
          logEarnTap('scratch_card');
          nav.navigateWithAdCheck(
            context,
            () => context.pushNamed(AppRoutes.scratchCard),
          );
        },
      ),
      _EarnItemData(
        'Web Visits',
        'Visit & Earn',
        Assets.images.webVisits,
        Assets.icons.icWebVisits,
        onTap: () {
          logEarnTap('web_visits');
          nav.navigateWithAdCheck(
            context,
            () => context.pushNamed(AppRoutes.webVisitsScreen),
          );
        },
      ),
      _EarnItemData(
        'Game Zone',
        'Play Games',
        Assets.images.gameZone,
        Assets.icons.icGameZone,
        onTap: () {
          logEarnTap('game_zone');
          nav.navigateWithAdCheck(
            context,
            () => context.pushNamed(AppRoutes.gameZoneScreen),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top circular icons — user-swipeable, NOT auto-scrolling, NOT synced
        // with the cards below. Tapping an icon navigates straight to that
        // module rather than scrubbing the carousel.
        SizedBox(
          height: AppSize.h78,
          child: PageView.builder(
            controller: _iconController,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _iconIndex = i),
            itemBuilder: (_, i) {
              return AnimatedBuilder(
                animation: _iconController,
                builder: (_, child) {
                  double scale;
                  if (_iconController.hasClients &&
                      _iconController.position.haveDimensions) {
                    final page = _iconController.page ?? 0.0;
                    scale = (1 - (page - i).abs() * 0.25).clamp(0.72, 1.0);
                  } else {
                    scale = i == _iconIndex ? 1.0 : 0.78;
                  }
                  return Transform.scale(scale: scale, child: child!);
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: items[i].onTap,
                  child: _EarnIconAvatar(
                    icon: items[i].icon,
                    isActive: i == _iconIndex,
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: AppSize.h8),
        // Label below the currently-centered icon.
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              items[_iconIndex].title,
              key: ValueKey<int>(_iconIndex),
              textAlign: TextAlign.center,
              style: context.textTheme.titleSmall?.copyWith(
                color: _kTextDark,
                fontWeight: FontWeight.w700,
                fontSize: AppSize.sp14,
              ),
            ),
          ),
        ),
        SizedBox(height: AppSize.h24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSize.w4),
          child: Text(
            'Earn Money',
            style: context.textTheme.titleLarge?.copyWith(
              color: _kTextDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: AppSize.h12),
        // Featured cards — infinite forward auto-scroll (itemCount null).
        SizedBox(
          height: AppSize.h82,
          child: PageView.builder(
            controller: _cardController,
            onPageChanged: (i) => setState(() => _cardIndex = i % items.length),
            itemBuilder: (_, i) =>
                _EarnFeatureCard(data: items[i % items.length]),
          ),
        ),
        SizedBox(height: AppSize.h14),
        Align(
          alignment: Alignment.center,
          child: _PageIndicator(count: items.length, currentIndex: _cardIndex),
        ),
      ],
    );
  }
}

class _EarnItemData {
  const _EarnItemData(
    this.title,
    this.subtitle,
    this.image,
    this.icon, {
    this.onTap,
  });

  final String title;
  final String subtitle;
  final AssetGenImage image;
  final SvgGenImage icon;
  final VoidCallback? onTap;
}

class _EarnIconAvatar extends StatelessWidget {
  const _EarnIconAvatar({required this.icon, required this.isActive});

  final SvgGenImage icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: AppSize.sp60,
        height: AppSize.sp60,
        padding: EdgeInsets.all(AppSize.sp14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isActive
              ? null
              : Border.all(width: 2, color: context.themeColors.border),
          gradient: isActive
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF5577FF), _kBlueDeep],
                )
              : null,
          color: isActive ? null : Colors.white,
        ),
        child: icon.svg(
          colorFilter: ColorFilter.mode(
            isActive ? Colors.white : _kBlue,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class _EarnFeatureCard extends StatelessWidget {
  const _EarnFeatureCard({required this.data});

  final _EarnItemData data;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSize.r16);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.w4),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: data.onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSize.w20,
              vertical: AppSize.h12,
            ),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEDF2FF), Color(0xFFDDE6FB)],
              ),
                border: Border.all(color: Color(0xFF8CB4FF),width: 1.5)
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        data.title,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: _kTextDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: AppSize.h2),
                      Text(
                        data.subtitle,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: _kTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSize.w12),
                data.image.image(
                  height: AppSize.h60,
                  width: AppSize.w60,
                  fit: BoxFit.contain,
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
// Hero carousel (Daily Reward + Total Balance, auto-scrolling)
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel({
    required this.dailyRewardCoins,
    required this.isRewardClaimed,
    required this.onClaim,
    required this.balance,
    required this.coins,
    required this.xp,
  });

  final int dailyRewardCoins;
  final bool isRewardClaimed;
  final VoidCallback onClaim;
  final String balance;
  final int coins;
  final int xp;

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  // Large even initialPage so we start on Daily Reward (index 0 mod 2) and
  // can scroll forward effectively forever — never animate "rewind" back.
  static const int _initialPage = 2000;

  // Each card fills the screen — viewportFraction = 1.0 avoids the narrow
  // viewport that was clipping Total Balance content. The gap between Daily
  // Reward and Total Balance during the swap is produced by horizontal padding
  // inside each itemBuilder entry, not by a peek.
  final PageController _controller = PageController(
    initialPage: _initialPage,
  );
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.nextPage(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: AppSize.h270,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (idx) => setState(() => _index = idx % 2),
            itemBuilder: (_, i) {
              final card = i.isEven
                  ? _DailyRewardCard(
                      coins: widget.dailyRewardCoins,
                      isClaimed: widget.isRewardClaimed,
                      onClaim: widget.onClaim,
                    )
                  : _TotalBalanceCard(
                      balance: widget.balance,
                      coins: widget.coins,
                      xp: widget.xp,
                    );
              // Inner gutter on every page so neighbouring cards never touch.
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSize.w4),
                child: card,
              );
            },
          ),
        ),
        SizedBox(height: AppSize.h14),
        _PageIndicator(count: 2, currentIndex: _index),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page indicator (stepper dots)
// ─────────────────────────────────────────────────────────────────────────────

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: isActive ? AppSize.w24 : AppSize.w8,
          height: AppSize.h8,
          margin: EdgeInsets.symmetric(horizontal: AppSize.w3),
          decoration: BoxDecoration(
            color: isActive ? _kBlue : const Color(0xFFCBD5F0),
            borderRadius: BorderRadius.circular(AppSize.r4),
          ),
        );
      }),
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
    final radius = BorderRadius.circular(AppSize.r16);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w16,
        vertical: AppSize.h14,
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        color: _kCardBg,
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1F4D).withValues(alpha: 0.04),
            blurRadius: AppSize.r10,
            offset: Offset(0, AppSize.h4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Assets.icons.question.svg(
            height: AppSize.sp24,
            width: AppSize.sp24,
            colorFilter: const ColorFilter.mode(
              Color(0xFF334155),
              BlendMode.srcIn,
            ),
          ),
          SizedBox(width: AppSize.w12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How It Works',
                  style: context.textTheme.titleSmall?.copyWith(
                    color: _kTextDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSize.h2),
                Text(
                  'Learn Step-by-Step how to earn money',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: _kTextMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSize.w8),
          _PaleCyanLearnButton(
            onPressed: () {
              AnalyticsManager.instance.logEvent(name: 'home_how_it_works_tap');
              context.pushNamed(AppRoutes.howItWorks);
            },
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
            border: Border.all(
                width: 1.5,
                color: Color(0xFFDDDDDD)),
            borderRadius: radius,
            color: const Color(0xFFE0DEDE),
          ),
          child: Text(
            'Learn',
            style: context.textTheme.labelMedium?.copyWith(
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
    return Row(
      children: [
        Expanded(
          child: _IconStatTile(
            caption: 'See top earner',
            label: 'Leader board',
            icon: Assets.icons.chartBar,
            accent: _kBlue,
            onTap: () {
              AnalyticsManager.instance.logEvent(name: 'home_leaderboard_tap');
              NavigationHelper().navigateWithAdCheck(
                context,
                () => context.go('/${AppRoutes.rank}'),
              );
            },
          ),
        ),
        SizedBox(width: AppSize.w12),
        Expanded(
          child: _IconStatTile(
            caption: 'Unlock your Badges',
            label: 'Achievements',
            icon: Assets.icons.trophy,
            accent: _kBlue,
          ),
        ),
      ],
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
    final radius = BorderRadius.circular(AppSize.r16);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.w14,
            vertical: AppSize.h12,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: _kCardBg,
            border: Border.all(color: _kCardBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1F4D).withValues(alpha: 0.04),
                blurRadius: AppSize.r10,
                offset: Offset(0, AppSize.h4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                caption,
                style: context.textTheme.bodySmall?.copyWith(
                  color: _kTextMuted,
                  fontSize: AppSize.sp11,
                ),
              ),
              SizedBox(height: AppSize.h6),
              Row(
                children: [
                  icon.svg(
                    height: AppSize.sp20,
                    width: AppSize.sp20,
                    colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                  ),
                  SizedBox(width: AppSize.w8),
                  Flexible(
                    child: Text(
                      label,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: _kTextDark,
                        fontWeight: FontWeight.w700,
                        fontSize: AppSize.sp14,
                      ),
                    ),
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
