// import 'package:ad_manager/interstitial_ad_manager.dart';
// import 'package:btc_cloud_mining/utils/anaytics_manager.dart';
// import 'package:btc_cloud_mining/utils/logger.dart';
// import 'package:btc_cloud_mining/utils/revenue_handler.dart';
// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

// import 'interstitial_ad_manager.dart';


// class RewardAdManager {
//   final String adUnitId;

//   RewardedAd? _rewardedAd;
//   bool _isAdLoaded = false;
//   bool _isAdShowing = false;

//   bool get isLoaded => _isAdLoaded;
//   bool get isAdShowing => _isAdShowing;

//   /// Callbacks
//   VoidCallback? onAdLoaded;
//   Function(LoadAdError)? onAdFailedToLoad;
//   VoidCallback? onAdShown;
//   VoidCallback? onAdDismissed;
//   Function(AdError)? onAdFailedToShow;
//   Function(RewardItem)? onUserEarnedReward;

//   RewardAdManager({
//     required this.adUnitId,
//     this.onAdLoaded,
//     this.onAdFailedToLoad,
//     this.onAdShown,
//     this.onAdDismissed,
//     this.onAdFailedToShow,
//     this.onUserEarnedReward,
//   });

//   /// Load the rewarded ad
//   Future<void> loadAd() async {
//     await RewardedAd.load(
//       adUnitId: adUnitId,
//       request: const AdRequest(),
//       rewardedAdLoadCallback: RewardedAdLoadCallback(
//         onAdLoaded: (ad) {
//           AnalyticsManager.instance.logEvent(name: 'rewarded_ad_loaded');
//           _rewardedAd = ad;
//           _isAdLoaded = true;

//           // Track paid event for revenue analytics
//           ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
//             RevenueHelper.sendAdImpressionRevenueToFirebase(
//               valueMicros: valueMicros,
//               currencyCode: currencyCode,
//               precision: precision,
//               adUnitId: adUnitId,
//             );
//           };

//           ad.fullScreenContentCallback = FullScreenContentCallback(
//             onAdShowedFullScreenContent: (ad) {
//               AnalyticsManager.instance.logEvent(name: 'rewarded_ad_show_in_full_screen');
//               ignoreNextEvent = true;
//               'RewardedAd is showing'.logD;
//               _isAdShowing = true;
//               onAdShown?.call();
//             },
//             onAdDismissedFullScreenContent: (ad) {
//               AnalyticsManager.instance.logEvent(name: 'rewarded_ad_dismissed_full_screen');
//               'RewardedAd dismissed'.logD;
//               _isAdShowing = false;
//               _isAdLoaded = false;
//               onAdDismissed?.call();
//               ad.dispose();
//               _rewardedAd = null;
//             },
//             onAdFailedToShowFullScreenContent: (ad, error) {
//               AnalyticsManager.instance.logEvent(
//                 name: 'failed_to_show_rewarded_ad',
//                 parameters: {'message': error.message},
//               );
//               'RewardedAd failed to show: $error'.logD;
//               _isAdShowing = false;
//               _isAdLoaded = false;
//               onAdFailedToShow?.call(error);
//               ad.dispose();
//               _rewardedAd = null;
//             },
//             onAdImpression: (ad) {
//               AnalyticsManager.instance.logEvent(name: 'rewarded_ad_impression');
//               'RewardedAd impression recorded'.logD;
//             },
//             onAdClicked: (ad) {
//               AnalyticsManager.instance.logEvent(name: 'rewarded_ad_clicked');
//               'RewardedAd clicked'.logD;
//             },
//           );

//           onAdLoaded?.call();
//           'RewardedAd loaded successfully'.logD;
//         },
//         onAdFailedToLoad: (error) {
//           'RewardedAd failed to load: $error'.logD;
//           AnalyticsManager.instance.logEvent(
//             name: 'failed_to_load_rewarded_ad',
//             parameters: {'message': error.message},
//           );
//           _isAdLoaded = false;
//           onAdFailedToLoad?.call(error);
//         },
//       ),
//     );
//   }

//   /// Show the ad if available and loaded
//   bool showAdIfAvailable() {
//     if (!_isAdLoaded || _rewardedAd == null) {
//       'RewardedAd not ready yet'.logD;
//       return false;
//     }

//     _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
//       'User earned reward: ${reward.amount} ${reward.type}'.logD;
//       AnalyticsManager.instance.logEvent(
//         name: 'user_earned_reward',
//         parameters: {'amount': reward.amount, 'type': reward.type},
//       );
//       onUserEarnedReward?.call(reward);
//     });

//     _isAdLoaded = false;
//     return true;
//   }

//   /// Dispose ad manually if needed
//   void dispose() {
//     _rewardedAd?.dispose();
//     _rewardedAd = null;
//     _isAdLoaded = false;
//   }
// }
