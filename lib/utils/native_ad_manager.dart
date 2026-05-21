// import 'package:btc_cloud_mining/utils/anaytics_manager.dart';
// import 'package:btc_cloud_mining/utils/logger.dart';
// import 'package:btc_cloud_mining/utils/revenue_handler.dart';
// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

// class NativeAdManager {
//   final String adUnitId;
//   final TemplateType templateType;
//   final String? factoryId;
//   NativeAd? _nativeAd;
//   bool _isLoaded = false;

//   bool get isLoaded => _isLoaded;
//   NativeAd? get nativeAd => _nativeAd;

//   /// Callbacks
//   VoidCallback? onAdLoaded;
//   Function(LoadAdError)? onAdFailedToLoad;
//   VoidCallback? onAdDisplayed;
//   VoidCallback? onAdDismissed;
//   Function(AdError)? onAdFailedToShow;

//   NativeAdManager({
//     required this.adUnitId,
//     this.factoryId,
//     this.templateType = TemplateType.medium,
//     this.onAdLoaded,
//     this.onAdFailedToLoad,
//     this.onAdDisplayed,
//     this.onAdDismissed,
//     this.onAdFailedToShow,
//   });

//   /// Load the native ad
//   Future<void> loadAd() async {
//     _nativeAd = NativeAd(
//       adUnitId: adUnitId,
//       factoryId: factoryId ?? 'adFactoryExample11', // your native ad layout factory id
//       request: const AdRequest(),
//       listener: NativeAdListener(
//         onAdLoaded: (ad) {
//           debugPrint('NativeAd loaded $factoryId');
//           _isLoaded = true;
//           onAdLoaded?.call();
//         },
//         onAdFailedToLoad: (ad, error) {
//           debugPrint('NativeAd failed to load: $error');
//           AnalyticsManager.instance.logEvent(name: 'failed_to_load_native_ad', parameters: {'message': error.message});
//           onAdFailedToLoad?.call(error);
//           ad.dispose();
//         },
//         onAdOpened: (ad) {
//           AnalyticsManager.instance.logEvent(name: 'native_ad_opened');
//           onAdDisplayed?.call();
//         },
//         onAdClosed: (ad) {
//           AnalyticsManager.instance.logEvent(name: 'native_ad_close');
//           onAdDismissed?.call();
//         },
//         onAdImpression: (ad) {
//           AnalyticsManager.instance.logEvent(name: 'native_ad_impression');
//           debugPrint('NativeAd impression recorded');
//         },
//         onAdClicked: (ad) {
//           AnalyticsManager.instance.logEvent(name: 'native_ad_click');
//           debugPrint('NativeAd clicked');
//         },
//         onPaidEvent: (ad, valueMicros, precision, currencyCode) {
//           RevenueHelper.sendAdImpressionRevenueToFirebase(
//             valueMicros: valueMicros,
//             currencyCode: currencyCode,
//             precision: precision,
//             adUnitId: adUnitId,
//           );
//         },
//       ),
//       nativeTemplateStyle: NativeTemplateStyle(templateType: templateType),
//       // size is optional but recommended for adaptive layouts
//       nativeAdOptions: NativeAdOptions(),
//     );

//     await _nativeAd!.load();
//   }

//   /// Widget to display the ad
//   Widget getAdWidget() {
//     'sending ad'.logD;
//     if (!_isLoaded || _nativeAd == null) {
//       return const SizedBox.expand();
//     }

//     return SizedBox(
//       child: AdWidget(key: Key('$factoryId-$adUnitId'), ad: _nativeAd!),
//     );
//   }

//    /// Method to check if the ad is loaded and show it
//   bool showAdIfAvailable() {
//     if (!_isLoaded || _nativeAd == null) {
//       'NativeAd not ready yet'.logD;
//       return false; // Ad is not ready, so don't show it.
//     }

//     // Show the ad
//     'Displaying native ad'.logD;
//     // Returning the AdWidget to be used in UI
//     return true; // Ad is available and ready to be shown
//   }

//   /// Dispose the ad
//   void dispose() {
//     _nativeAd?.dispose();
//     _nativeAd = null;
//   }
// }
