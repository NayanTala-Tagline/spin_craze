/*
import 'package:btc_cloud_mining/utils/anaytics_manager.dart';
import 'package:btc_cloud_mining/utils/logger.dart';
import 'package:btc_cloud_mining/utils/revenue_handler.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

bool ignoreNextEvent = false;

class InterstitialAdManager {
  final String adUnitId;

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _isAdShowing = false;

  bool get isLoaded => _isAdLoaded;
  bool get isAdShowing => _isAdShowing;

  /// Callbacks
  VoidCallback? onAdLoaded;
  Function(LoadAdError)? onAdFailedToLoad;
  VoidCallback? onAdShown;
  VoidCallback? onAdDismissed;
  Function(AdError)? onAdFailedToShow;
  VoidCallback? onAdReadyForUI;
  VoidCallback? onAdFailedForUI;

  InterstitialAdManager({
    required this.adUnitId,
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdShown,
    this.onAdDismissed,
    this.onAdFailedToShow, VoidCallback? onAdReadyForUI, VoidCallback? onAdFailedForUI,
  });

  /// Load the interstitial ad
  Future<void> loadAd() async {
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          AnalyticsManager.instance.logEvent(name: 'interstitial_ad_loaded');
          onAdReadyForUI?.call(); 
          _interstitialAd = ad;
          _isAdLoaded = true;

          // Handle paid event (revenue tracking)
          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            RevenueHelper.sendAdImpressionRevenueToFirebase(
              valueMicros: valueMicros,
              currencyCode: currencyCode,
              precision: precision,
              adUnitId: adUnitId,
            );
          };

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              AnalyticsManager.instance.logEvent(name: 'interstitial_ad_show_in_full_screen');
              ignoreNextEvent = true;
              'InterstitialAd is showing'.logD;
              _isAdShowing = true;
              onAdShown?.call();
            },
            onAdDismissedFullScreenContent: (ad) {
              AnalyticsManager.instance.logEvent(name: 'interstitial_ad_dismissed_full_screen');
              'InterstitialAd dismissed'.logD;
              _isAdShowing = false;
              _isAdLoaded = false;
              onAdDismissed?.call();
              ad.dispose();
              _interstitialAd = null;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              AnalyticsManager.instance.logEvent(
                name: 'failed_to_show_interstitial_ad',
                parameters: {'message': error.message},
              );
              'InterstitialAd failed to show: $error'.logD;
              _isAdShowing = false;
              _isAdLoaded = false;
              onAdFailedToShow?.call(error);
              ad.dispose();
              _interstitialAd = null;
            },
            onAdImpression: (ad) {
              AnalyticsManager.instance.logEvent(name: 'interstitial_ad_impression');
              'InterstitialAd impression recorded'.logD;
            },
            onAdClicked: (ad) {
              AnalyticsManager.instance.logEvent(name: 'interstitial_ad_clicked');
              'InterstitialAd clicked'.logD;
            },
          );

          onAdLoaded?.call();
          'InterstitialAd loaded successfully'.logD;
        },
        onAdFailedToLoad: (error) {
          'InterstitialAd failed to load: $error'.logD;
          AnalyticsManager.instance.logEvent(
            name: 'failed_to_load_interstitial_ad',
            parameters: {'message': error.message},
          );
          onAdFailedForUI?.call();
          _isAdLoaded = false;
          onAdFailedToLoad?.call(error);
        },
      ),
    );
  }

  /// Show the ad if it's available and loaded
  bool showAdIfAvailable() {
    if (!_isAdLoaded || _interstitialAd == null) {
      'InterstitialAd not ready yet'.logD;
      return false;
    }

    _interstitialAd!.show();
    _isAdLoaded = false; // Reset after showing
    return true;
  }

  /// Dispose the ad manually if needed
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
  }
}
*/
