import 'package:ad_manager/ad_manager.dart';
import 'package:ad_manager/models/ad_data.dart';
import 'package:flutter/material.dart';
import '../extension/ext_string_alert.dart';
import '../widgets/loading_overlay/loading_overlay.dart';
import '../widgets/rewarded_ad_bottom_sheet.dart';

class RewardAdHelper {
  static Future<void> showRewardAdWithBottomSheet({
    required BuildContext context,
    required AdData adData,
    required int defaultCoins,
    void Function(int coins)? onAdCompleted,
    VoidCallback? onAdCancelled,
    bool isHomepage = false,
  }) async {
    // Skip the bottom sheet entirely if the ad is disabled
    if (!adData.enabled) {
      onAdCompleted?.call(defaultCoins);
      return;
    }

    bool shouldShowAd = false;

    await showRewardAdBottomSheet(
      context: context,
      onSupportUs: () {
        shouldShowAd = true;
      },
      onCancel: () {
        shouldShowAd = false;
        onAdCancelled?.call();
      },
      isHomepage: isHomepage,
    );

    if (shouldShowAd && context.mounted) {
      // Always grant reward — even if the ad fails to load/show, the user
      // agreed to support us, so we shouldn't punish them for an ad failure.
      int coins = defaultCoins;
      try {
        coins = await _showRewardAd(context, adData, defaultCoins);
      } catch (_) {
        // Swallow ad errors; reward is still granted with default coins.
      }
      onAdCompleted?.call(coins);
    }
  }

  /// Shows the rewarded ad and returns the coins to grant.
  /// Coins = max(defaultCoins, floor((valueMicros / 1_000_000) * 30)).
  /// Falls back to defaultCoins if the paid event never fires.
  static Future<int> _showRewardAd(BuildContext context, AdData adData, int defaultCoins) async {
    double? capturedMicros;

    try {
      LoadingOverlay.instance().show(context: context);

      final rewardAd = RewardedAdManager(
        adData: adData,
        listener: RewardedAdLoadCallback(
          onAdFailedToLoad: (_) {},
          onAdLoaded: (_) {},
        ),
        onPaidEventReceived: (valueMicros) {
          capturedMicros = valueMicros;
        },
      );

      rewardAd.load();
      await rewardAd.future();
      await rewardAd.show(onUserEarnedReward: (_, _) {});
      await Future.delayed(const Duration(milliseconds: 400));
    } finally {
      LoadingOverlay.instance().hide();
    }

    if (capturedMicros != null) {
      final computed = ((capturedMicros! / 1_000_000) * 30).floor();
      if (computed > defaultCoins) {
        final extra = computed - defaultCoins;
        'You earned $extra extra coins from the ad!'.showSuccessAlert();
        return computed;
      }
    }

    return defaultCoins;
  }
}
