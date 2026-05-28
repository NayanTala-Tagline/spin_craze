import 'package:ad_manager/ad_manager.dart';
import 'package:flutter/material.dart';
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
      try {
        await _showRewardAd(context, adData);
      } catch (_) {
        // Swallow ad errors; reward is still granted with default coins.
      }
      onAdCompleted?.call(defaultCoins);
    }
  }

  static Future<void> _showRewardAd(
    BuildContext context,
    AdData adData,
  ) async {
    try {
      LoadingOverlay.instance().show(context: context);

      final rewardAd = FullScreenAdManager(
        adData: adData,
        rewardedCallback: FullScreenContentCallback<RewardedAd>(
          onAdDismissedFullScreenContent: (_) {},
          onAdFailedToShowFullScreenContent: (_, _) {},
        ),
      );

      await rewardAd.load();
      await rewardAd.future();
      if (context.mounted && rewardAd.isLoaded) {
        await rewardAd.show(
          context: context,
          onUserEarnedReward: (_, _) {},
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await rewardAd.dispose();
    } finally {
      LoadingOverlay.instance().hide();
    }
  }
}
