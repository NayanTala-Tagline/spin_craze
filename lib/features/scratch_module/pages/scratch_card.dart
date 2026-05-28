import 'dart:math';

import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/features/scratch_module/provider/scratch_card_provider.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/services/coin_service.dart';
import 'package:spin_craze/services/reward_ad_service.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/widgets/ad_disclaimer_text.dart';
import 'package:spin_craze/widgets/common_appbar.dart';
import 'package:spin_craze/utils/navigation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scratcher/widgets.dart';
class ScratchCardScreen extends StatefulWidget {
  const ScratchCardScreen({super.key});

  @override
  State<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends State<ScratchCardScreen>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logScreenView(
      screenName: 'scratch_card',
      screenClass: 'ScratchCardScreen',
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScratchCardProvider(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          NavigationHelper().handleBackPress(context);
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F7FE),
          appBar: CommonAppBar(
            title: context.l10n.earnModuleScratchTitle,
            showBack: true,
          ),
          body: SafeArea(
            top: false,
            child: Consumer<ScratchCardProvider>(
              builder: (context, prov, _) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSize.w24),
                  child: Column(
                    children: [
                      SizedBox(height: AppSize.h32),
                      _ScratchArea(
                        provider: prov,
                        shakeController: _shakeController,
                        shakeAnimation: _shakeAnimation,
                      ),
                      const Spacer(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scratch card area
// ─────────────────────────────────────────────────────────────────────────────

class _ScratchArea extends StatelessWidget {
  const _ScratchArea({
    required this.provider,
    required this.shakeController,
    required this.shakeAnimation,
  });

  final ScratchCardProvider provider;
  final AnimationController shakeController;
  final Animation<double> shakeAnimation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.r20),
        border: Border.all(
          color: const Color(0xFF29B0E6).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B52D9).withValues(alpha: 0.3),
            blurRadius: AppSize.r24,
            offset: Offset(0, AppSize.h8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSize.r20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Listener(
              onPointerUp: (_) async {
                if (provider.isThresholdReached &&
                    !provider.isGiftBoxRevealed) {
                  provider.scratchKey.currentState?.reveal();
                  provider.revealGiftBox();
                  await shakeController.repeat(reverse: true);
                }
              },
              child: Scratcher(
                key: provider.scratchKey,
                brushSize: 70,
                threshold: 40,
                image: Assets.images.scrarch.scScratch.image(fit: BoxFit.cover),
                onChange: (_) {},
                onThreshold: () {
                  provider.isThresholdReached = true;
                },
                child: Container(
                  height: AppSize.sp260,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D2B3E), Color(0xFF112D3E)],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!provider.isGiftBoxOpened)
                        GestureDetector(
                          onTap: () => _onGiftTap(context),
                          child: provider.isGiftBoxRevealed
                              ? AnimatedBuilder(
                                  animation: shakeAnimation,
                                  builder: (_, child) {
                                    return Transform.translate(
                                      offset: Offset(
                                        sin(shakeAnimation.value) * 5,
                                        0,
                                      ),
                                      child: Transform.rotate(
                                        angle: sin(shakeAnimation.value) * 0.1,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Icon(
                                    Icons.card_giftcard,
                                    size: AppSize.sp100,
                                    color: const Color(0xFFFFD84D),
                                  ),
                                )
                              : Icon(
                                  Icons.card_giftcard,
                                  size: AppSize.sp100,
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                        )
                      else
                        _RevealedReward(reward: provider.reward ?? 0),
                    ],
                  ),
                ),
              ),
            ),
            // "Scratch it to Win" overlay — sits on top of the scratch image
            if (!provider.isThresholdReached)
              IgnorePointer(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSize.w24,
                    vertical: AppSize.h12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2B3E).withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(AppSize.r100),
                  ),
                  child: Text(
                    context.l10n.scratchToWin,
                    textAlign: TextAlign.center,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                      fontSize: AppSize.sp20,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onGiftTap(BuildContext context) {
    if (!provider.isGiftBoxRevealed) return;

    shakeController
      ..stop()
      ..reset();
    provider.openGiftBox();

    final reward = provider.reward ?? 0;

    if (reward != 0) {
      provider.controller.play();
    }

    _showResultSheet(reward);
  }

  void _showResultSheet(int reward) {
    final isLoss = reward == 0;
    final navCtx = rootNavKey.currentContext;
    if (navCtx == null || !navCtx.mounted) return;

    AnalyticsManager.instance.logEvent(
      name: 'scratch_card_revealed',
      parameters: {'coins_won': reward, 'is_loss': isLoss ? 1 : 0},
    );

    showModalBottomSheet<void>(
      context: navCtx,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetCtx) => _CongratsSheet(
        coins: reward,
        isLoss: isLoss,
        onClaim: () async {
          sheetCtx.pop();
          if (!isLoss) {
            AnalyticsManager.instance.logEvent(
              name: 'scratch_card_reward_claim_tap',
              parameters: {'coins': reward},
            );
            final ctx = rootNavKey.currentContext!;
            final earned = await RewardAdService.showScratchCard(
              ctx,
              defaultCoins: reward,
            );
            if (earned == null) return;
            AnalyticsManager.instance.logEvent(
              name: 'scratch_card_reward_claimed',
              parameters: {'coins': earned},
            );
            await CoinService.addCoins(earned);
          }
          final ctx = rootNavKey.currentContext;
          if (ctx != null && ctx.mounted) ctx.pop();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Revealed reward display
// ─────────────────────────────────────────────────────────────────────────────

class _RevealedReward extends StatelessWidget {
  const _RevealedReward({required this.reward});

  final int reward;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    if (reward == 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_dissatisfied,
            size: AppSize.sp55,
            color: colors.error,
          ),
          SizedBox(height: AppSize.h8),
          Text(
            context.l10n.scratchBetterLuck,
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge?.copyWith(
              color: colors.error,
              fontWeight: FontWeight.w700,
              fontSize: AppSize.sp22,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (bounds) =>
              colors.coinGradient.createShader(bounds),
          child: Assets.icons.scCoins.svg(
            height: AppSize.sp48,
            width: AppSize.sp48,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
        SizedBox(height: AppSize.h14),
        ShaderMask(
          shaderCallback: (bounds) =>
              colors.coinGradient.createShader(bounds),
          child: Text(
            '+$reward',
            style: context.textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: AppSize.sp40,
              height: 1,
            ),
          ),
        ),
        SizedBox(height: AppSize.h6),
        Text(
          context.l10n.coinsLabel,
          style: context.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Congratulations bottom sheet (same style as spin module)
// ─────────────────────────────────────────────────────────────────────────────

class _CongratsSheet extends StatelessWidget {
  const _CongratsSheet({
    required this.coins,
    required this.isLoss,
    required this.onClaim,
  });

  final int coins;
  final bool isLoss;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSize.w24,
        AppSize.h20,
        AppSize.w24,
        AppSize.h32,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.r24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1F4D).withValues(alpha: 0.14),
            blurRadius: AppSize.r32,
            offset: Offset(0, -AppSize.h4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: AppSize.w40,
            height: AppSize.h4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSize.r100),
              color: const Color(0xFFE5EBF5),
            ),
          ),
          SizedBox(height: AppSize.h20),
          Assets.images.scDailyRewardTrophy.image(
            height: AppSize.sp100,
            width: AppSize.sp100,
            fit: BoxFit.contain,
          ),
          SizedBox(height: AppSize.h20),
          Text(
            isLoss ? context.l10n.spinOops : context.l10n.spinCongrats,
            style: context.textTheme.titleLarge?.copyWith(
              color: isLoss
                  ? const Color(0xFFFF5183)
                  : const Color(0xFF111827),
              fontWeight: FontWeight.w800,
              fontSize: AppSize.sp24,
            ),
          ),
          SizedBox(height: AppSize.h8),
          Text(
            isLoss ? context.l10n.spinBetterLuck : context.l10n.spinWonCoins(coins),
            style: context.textTheme.bodyLarge?.copyWith(
              color: isLoss
                  ? const Color(0xFFFF5183)
                  : const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppSize.h28),
          if (!isLoss)
            AdDisclaimerText(show: RewardAdService.isScratchCardAdEnabled),
          _PaleCyanPill(
            label: isLoss ? context.l10n.tryAgain : context.l10n.claimCoins,
            onPressed: onClaim,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable pale-cyan pill (same as spin module)
// ─────────────────────────────────────────────────────────────────────────────

class _PaleCyanPill extends StatelessWidget {
  const _PaleCyanPill({required this.label, required this.onPressed});

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
          height: AppSize.h48,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3A6BFF), Color(0xFF1E3FE0)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                blurRadius: AppSize.r16,
                offset: Offset(0, AppSize.h4),
              ),
            ],
          ),
          child: Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
