import 'dart:async';

import 'package:ad_manager/enum/ad_status.dart';
import 'package:ad_manager/enum/ad_type.dart';
import 'package:ad_manager/models/ad_data.dart';
import 'package:ad_manager/utils/anaytics_manager.dart';
import 'package:ad_manager/utils/revenue_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher_string.dart';

class OpenAppAdManager {
  final AdData adData;
  final AppOpenAdLoadCallback? listener;
  final FullScreenContentCallback<AppOpenAd>? fullScreenContentCallback;

  AppOpenAd? _ad;
  AppOpenAd? get ad => _ad;

  AdStatus adStatus = AdStatus.idle;

  bool _isShowingAd = false;

  bool get isLoaded => adStatus == AdStatus.loaded;
  bool get isLoading => adStatus == AdStatus.loading;
  bool get isFailed => adStatus == AdStatus.failed;

  Completer<AdStatus> _completer = Completer<AdStatus>();

  OpenAppAdManager({required this.adData, this.listener, this.fullScreenContentCallback});

  /// Load ad
  Future<void> load() async {
    if (!adData.enabled) {
      adStatus = AdStatus.disabled;
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
      await AppOpenAd.load(
        adUnitId: adData.adId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (AppOpenAd ad) {
            _ad = ad;

            /// Paid event
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
      debugPrint("OpenAppAd load error: $e");
      adStatus = AdStatus.failed;

      if (!_completer.isCompleted) {
        _completer.complete(AdStatus.failed);
      }
    }
  }

  /// Reload and reset completer
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

  void _setupFullScreenListeners(AppOpenAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        fullScreenContentCallback?.onAdShowedFullScreenContent?.call(ad);
        AnalyticsManager.instance.logEvent(name: "open_app_ad_opened");
      },
      onAdDismissedFullScreenContent: (ad) {
        fullScreenContentCallback?.onAdDismissedFullScreenContent?.call(ad);
        AnalyticsManager.instance.logEvent(name: "open_app_ad_closed");
        _isShowingAd = false;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        fullScreenContentCallback?.onAdFailedToShowFullScreenContent?.call(ad, error);
        AnalyticsManager.instance.logEvent(name: "open_app_ad_failed_to_show");

        adStatus = AdStatus.failed;
        _isShowingAd = false;
      },
      onAdImpression: (ad) {
        fullScreenContentCallback?.onAdImpression?.call(ad);
        AnalyticsManager.instance.logEvent(name: "open_app_ad_impression");
      },
      onAdClicked: (ad) {
        fullScreenContentCallback?.onAdClicked?.call(ad);
        AnalyticsManager.instance.logEvent(name: "open_app_ad_click");
      },
      onAdWillDismissFullScreenContent: fullScreenContentCallback?.onAdWillDismissFullScreenContent?.call,
    );
  }

  /// Future completes when loaded or failed
  Future<AdStatus> future() => _completer.future;

  /// Show
  Future<bool> show() async {
    if (!adData.enabled) return false;
    if (!isLoaded || _ad == null) return false;
    if (_isShowingAd) return false;

    try {
      if (adData.adType == AdType.custom) {
        await launchUrlString(adData.customAdUrl);
      } else {
        await _ad!.show();
      }
      return true;
    } catch (e) {
      debugPrint("OpenAppAd show error: $e");
      return false;
    }
  }

  Future<void> dispose() async {
    _ad?.dispose();
    _ad = null;
    adStatus = AdStatus.idle;
  }
}
