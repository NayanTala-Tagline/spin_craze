import 'dart:async';

import 'package:ad_manager/enum/ad_status.dart';
import 'package:ad_manager/enum/ad_type.dart';
import 'package:ad_manager/models/ad_data.dart';
import 'package:ad_manager/utils/anaytics_manager.dart';
import 'package:ad_manager/utils/revenue_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher_string.dart';
bool ignoreNextEvent = false;


class InterstitialAdManager {
  final AdData adData;
  final InterstitialAdLoadCallback? listener;
  final FullScreenContentCallback<InterstitialAd>? fullScreenContentCallback;

  InterstitialAd? _ad;
  InterstitialAd? get ad => _ad;

  AdStatus adStatus = AdStatus.idle;

  bool get isLoaded => adStatus == AdStatus.loaded;
  bool get isLoading => adStatus == AdStatus.loading;
  bool get isFailed => adStatus == AdStatus.failed;

  Completer<AdStatus> _completer = Completer<AdStatus>();

  InterstitialAdManager({required this.adData, this.listener, this.fullScreenContentCallback});

  Future<void> load() async {
    if (!adData.enabled) {
      adStatus = AdStatus.disabled;
      _completer.complete(AdStatus.disabled);
      return;
    }

    if (adData.adType == AdType.custom) {
      adStatus = AdStatus.loaded;
      _completer.complete(AdStatus.loaded);
      return;
    }

    if (isLoaded || isLoading) return;

    adStatus = AdStatus.loading;

    if (_ad != null) {
      _ad!.dispose();
      _ad = null;
    }

    try {
      await InterstitialAd.load(
        adUnitId: adData.adId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _ad = ad;

            // Paid event
            ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
              RevenueHelper.sendAdImpressionRevenueToFirebase(
                valueMicros: valueMicros,
                currencyCode: currencyCode,
                precision: precision,
                adUnitId: adData.adId,
              );
            };

            adStatus = AdStatus.loaded;

            _setupFullScreenListeners(ad);

            listener?.onAdLoaded.call(ad);

            if (!_completer.isCompleted) {
              _completer.complete(AdStatus.loaded);
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            adStatus = AdStatus.failed;
            listener?.onAdFailedToLoad.call(error);

            if (!_completer.isCompleted) {
              _completer.complete(AdStatus.failed);
            }
          },
        ),
      );
    } catch (e) {
      debugPrint("Interstitial load error: $e");
      adStatus = AdStatus.failed;

      if (!_completer.isCompleted) {
        _completer.complete(AdStatus.failed);
      }
    }
  }

  Future<void> reload() async {
    if (!adData.enabled) {
      adStatus = AdStatus.disabled;
      return;
    }

    _ad?.dispose();
    _ad = null;
    _completer = Completer<AdStatus>();
    adStatus = AdStatus.idle;
    await load();
  }

  void _setupFullScreenListeners(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (ad) {
        ignoreNextEvent =true;
        fullScreenContentCallback?.onAdShowedFullScreenContent?.call(ad);
        AnalyticsManager.instance.logEvent(name: "interstitial_ad_opened");
      },
      onAdDismissedFullScreenContent: (ad) {
        fullScreenContentCallback?.onAdDismissedFullScreenContent?.call(ad);
        AnalyticsManager.instance.logEvent(name: "interstitial_ad_closed");
        dispose();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        fullScreenContentCallback?.onAdFailedToShowFullScreenContent?.call(ad, error);
        AnalyticsManager.instance.logEvent(name: "interstitial_ad_show_failed");
        adStatus = AdStatus.failed;
      },
      onAdImpression: (ad) {
        fullScreenContentCallback?.onAdImpression?.call(ad);
        AnalyticsManager.instance.logEvent(name: "interstitial_ad_impression");
      },
      onAdClicked: (ad) {
        fullScreenContentCallback?.onAdClicked?.call(ad);
        AnalyticsManager.instance.logEvent(name: "interstitial_ad_click");
      },
      onAdWillDismissFullScreenContent: fullScreenContentCallback?.onAdWillDismissFullScreenContent?.call,
    );
  }

  /// Future completes when load or fail happens.
  Future<AdStatus> future() => _completer.future;

  /// Show the interstitial ad
  Future<bool> show() async {
    if (!adData.enabled) return false;
    if (!isLoaded) return false;
    if (_ad == null && adData.adType != AdType.custom) return false;

    try {
      if (adData.adType == AdType.custom) {
        await launchUrlString(adData.customAdUrl);
      } else {
        await _ad!.show();
      }
      return true;
    } catch (e) {
      debugPrint("Interstitial show error: $e");
      return false;
    }
  }

  Future<void> dispose() async {
    _ad?.dispose();
    _ad = null;
    adStatus = AdStatus.idle;
  }
}
