import 'dart:async';

import 'package:ad_manager/enum/ad_status.dart';
import 'package:ad_manager/models/ad_data.dart';
import 'package:ad_manager/utils/anaytics_manager.dart';
import 'package:ad_manager/utils/revenue_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'interstitial_ad_manager.dart';

class RewardedAdManager {
  final AdData adData;
  final RewardedAdLoadCallback? listener;
  final FullScreenContentCallback<RewardedAd>? fullScreenContentCallback;
  final void Function(double valueMicros)? onPaidEventReceived;

  RewardedAd? _ad;
  RewardedAd? get ad => _ad;

  AdStatus adStatus = AdStatus.idle;

  bool get isLoaded => adStatus == AdStatus.loaded;
  bool get isLoading => adStatus == AdStatus.loading;
  bool get isFailed => adStatus == AdStatus.failed;

  Completer<AdStatus> _completer = Completer<AdStatus>();

  RewardedAdManager({required this.adData, this.listener, this.fullScreenContentCallback, this.onPaidEventReceived});

  Future<void> load() async {
    if (!adData.enabled) {
      adStatus = AdStatus.disabled;
      _completer.complete(AdStatus.disabled);
      return;
    }

    if (adData.isCustomAd) {
      adStatus = AdStatus.loaded;
      _completer.complete(AdStatus.loaded);
      return;
    }

    if (isLoaded || isLoading) return;

    adStatus = AdStatus.loading;

    try {
      await RewardedAd.load(
        adUnitId: adData.adId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _ad = ad;

            // Paid event
            ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
              RevenueHelper.sendAdImpressionRevenueToFirebase(
                valueMicros: valueMicros,
                currencyCode: currencyCode,
                precision: precision,
                adUnitId: adData.adId,
              );
              onPaidEventReceived?.call(valueMicros);
            };

            adStatus = AdStatus.loaded;

            _setupFullScreenListeners(ad);

            listener?.onAdLoaded.call(ad); // forward load callback

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
      debugPrint("RewardedAd load error: $e");
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

    adStatus = AdStatus.loading;
    _completer = Completer<AdStatus>();
    await load();
  }

  void _setupFullScreenListeners(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (ad) {
        ignoreNextEvent =true;
        fullScreenContentCallback?.onAdShowedFullScreenContent?.call(ad);
        AnalyticsManager.instance.logEvent(name: "rewarded_ad_opened");
      },
      onAdDismissedFullScreenContent: (ad) {
        fullScreenContentCallback?.onAdDismissedFullScreenContent?.call(ad);
        AnalyticsManager.instance.logEvent(name: "rewarded_ad_closed");
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        fullScreenContentCallback?.onAdFailedToShowFullScreenContent?.call(ad, error);
        AnalyticsManager.instance.logEvent(name: "rewarded_ad_show_failed");
        adStatus = AdStatus.failed;
      },
      onAdImpression: (ad) {
        fullScreenContentCallback?.onAdImpression?.call(ad);
        AnalyticsManager.instance.logEvent(name: "rewarded_ad_impression");
      },
      onAdClicked: (ad) {
        fullScreenContentCallback?.onAdClicked?.call(ad);
        AnalyticsManager.instance.logEvent(name: "rewarded_ad_click");
      },
      onAdWillDismissFullScreenContent: fullScreenContentCallback?.onAdWillDismissFullScreenContent?.call,
    );
  }

  /// Future completes when load or fail happens.
  Future<AdStatus> future() => _completer.future;

  /// Show with reward callback
  Future<bool> show({required void Function(AdWithoutView, RewardItem) onUserEarnedReward}) async {
    if (!adData.enabled) return false;
    if (!isLoaded || _ad == null) return false;

    try {
      if (adData.isCustomAd) {
        await launchUrlString(adData.customAdUrl);
      } else {
        await _ad!.show(onUserEarnedReward: onUserEarnedReward);
      }
      return true;
    } catch (e) {
      debugPrint("Rewarded show error: $e");
      return false;
    }
  }

  Future<void> dispose() async {
    _ad?.dispose();
    _ad = null;
  }
}
