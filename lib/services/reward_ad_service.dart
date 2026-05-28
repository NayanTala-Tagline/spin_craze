import 'package:ad_manager/ad_manager.dart';
import 'package:ad_manager/models/ad_data.dart';
import 'package:flutter/material.dart';
import '../utils/anaytics_manager.dart';
import '../utils/remote_config.dart';
import '../utils/rewarded_ad_helper.dart';
import '../widgets/loading_overlay/loading_overlay.dart';

/// Central service for showing rewarded ads before coin claims.
/// Returns the coins to grant, or null if the user cancelled.
/// Coins are dynamically computed from ad revenue:
///   max(defaultCoins, floor((valueMicros / 1_000_000) * 30))
class RewardAdService {
  RewardAdService._();

  /// Shows a rewarded ad using [adData].
  static Future<void> show(BuildContext context, AdData adData) async {
    try {
      LoadingOverlay.instance().show(context: context);

      final ad = FullScreenAdManager(
        adData: adData,
        rewardedCallback: FullScreenContentCallback<RewardedAd>(
          onAdDismissedFullScreenContent: (_) {},
          onAdFailedToShowFullScreenContent: (_, _) {},
        ),
      );

      await ad.load();
      await ad.future();
      if (context.mounted && ad.isLoaded) {
        await ad.show(
          context: context,
          onUserEarnedReward: (_, _) {},
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await ad.dispose();
    } catch (_) {
      // Ad failed — proceed without blocking the reward
    } finally {
      LoadingOverlay.instance().hide();
    }
  }

  // ── Ad-enabled checks (used by UI to show/hide disclaimer) ──────────

  static bool get isDailyCheckinAdEnabled =>
      RemoteConfigService.instance.dailyClaimReward.enabled;

  static bool get isMathQuizAdEnabled =>
      RemoteConfigService.instance.mathQuizClaimReward.enabled;

  static bool get isScratchCardAdEnabled =>
      RemoteConfigService.instance.scratchCardClaimReward.enabled;

  static bool get isSpinWheelAdEnabled =>
      RemoteConfigService.instance.spinWheelClaimReward.enabled;

  static bool get isWebsiteRewardAdEnabled =>
      RemoteConfigService.instance.websiteReward.enabled;

  static bool get isPlayGameRewardAdEnabled =>
      RemoteConfigService.instance.playGameReward.enabled;

  // ── Show methods — return null if cancelled, coins to grant if watched ─

  static Future<int?> showDailyCheckin(BuildContext context, {required int defaultCoins}) async {
    int? earned;
    await RewardAdHelper.showRewardAdWithBottomSheet(
      context: context,
      adData: RemoteConfigService.instance.dailyClaimReward,
      defaultCoins: defaultCoins,
      onAdCompleted: (coins) { earned = coins; },
      onAdCancelled: () {
        AnalyticsManager.instance.logEvent(name: 'cancel_daily_claim');
      },
      isHomepage: false,
    );
    return earned;
  }

  static Future<int?> showMathQuiz(BuildContext context, {required int defaultCoins}) async {
    int? earned;
    await RewardAdHelper.showRewardAdWithBottomSheet(
      context: context,
      adData: RemoteConfigService.instance.mathQuizClaimReward,
      defaultCoins: defaultCoins,
      onAdCompleted: (coins) { earned = coins; },
      onAdCancelled: () {
        AnalyticsManager.instance.logEvent(name: 'cancel_math_quiz_claim');
      },
    );
    return earned;
  }

  static Future<int?> showScratchCard(BuildContext context, {required int defaultCoins}) async {
    int? earned;
    await RewardAdHelper.showRewardAdWithBottomSheet(
      context: context,
      adData: RemoteConfigService.instance.scratchCardClaimReward,
      defaultCoins: defaultCoins,
      onAdCompleted: (coins) { earned = coins; },
      onAdCancelled: () {
        AnalyticsManager.instance.logEvent(name: 'cancel_scratch_card_claim');
      },
    );
    return earned;
  }

  static Future<int?> showSpinWheel(BuildContext context, {required int defaultCoins}) async {
    int? earned;
    await RewardAdHelper.showRewardAdWithBottomSheet(
      context: context,
      adData: RemoteConfigService.instance.spinWheelClaimReward,
      defaultCoins: defaultCoins,
      onAdCompleted: (coins) { earned = coins; },
      onAdCancelled: () {
        AnalyticsManager.instance.logEvent(name: 'cancel_spin_wheel_claim');
      },
    );
    return earned;
  }

  static Future<int?> showWebsiteReward(BuildContext context, {required int defaultCoins}) async {
    int? earned;
    await RewardAdHelper.showRewardAdWithBottomSheet(
      context: context,
      adData: RemoteConfigService.instance.websiteReward,
      defaultCoins: defaultCoins,
      onAdCompleted: (coins) { earned = coins; },
      onAdCancelled: () {
        AnalyticsManager.instance.logEvent(name: 'cancel_website_reward');
      },
    );
    return earned;
  }

  static Future<int?> showPlayGameReward(BuildContext context, {required int defaultCoins}) async {
    int? earned;
    await RewardAdHelper.showRewardAdWithBottomSheet(
      context: context,
      adData: RemoteConfigService.instance.playGameReward,
      defaultCoins: defaultCoins,
      onAdCompleted: (coins) { earned = coins; },
      onAdCancelled: () {
        AnalyticsManager.instance.logEvent(name: 'cancel_play_game_reward');
      },
    );
    return earned;
  }
}
