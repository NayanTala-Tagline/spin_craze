import 'dart:async';

import 'package:ad_manager/ad_manager.dart';
import 'package:ad_manager/enum/ad_status.dart';
import 'package:ad_manager/enum/ad_type.dart';
import 'package:ad_manager/enum/rewarded_show_result.dart';
import 'package:ad_manager/models/ad_data.dart';
import 'package:ad_manager/rewarded_consent.dart';
import 'package:ad_manager/utils/anaytics_manager.dart';
import 'package:ad_manager/utils/revenue_handler.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher_string.dart';

class RewardedAdManager {
  final AdData adData;
  final RewardedAdLoadCallback? listener;
  final FullScreenContentCallback<RewardedAd>? fullScreenContentCallback;

  RewardedAd? _ad;
  RewardedAd? get ad => _ad;

  AdStatus adStatus = AdStatus.idle;

  bool get isLoaded => adStatus == AdStatus.loaded;
  bool get isLoading => adStatus == AdStatus.loading;
  bool get isFailed => adStatus == AdStatus.failed;

  Completer<AdStatus> _completer = Completer<AdStatus>();

  RewardedAdManager({required this.adData, this.listener, this.fullScreenContentCallback});

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

    _ad?.dispose();
    _ad = null;
    _completer = Completer<AdStatus>();
    adStatus = AdStatus.idle;
    await load();
  }

  void _setupFullScreenListeners(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (ad) {
        fullScreenContentCallback?.onAdShowedFullScreenContent?.call(ad);
        AnalyticsManager.instance.logEvent(name: "rewarded_ad_opened");
      },
      onAdDismissedFullScreenContent: (ad) {
        fullScreenContentCallback?.onAdDismissedFullScreenContent?.call(ad);
        AnalyticsManager.instance.logEvent(name: "rewarded_ad_closed");
        ignoreNextEvent = true;
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

  /// Show with reward callback. Shows a consent dialog before the ad —
  /// either the one set via [RewardedConsent.setConsentDialogBuilder] or the
  /// built-in fallback.
  ///
  /// Returns [RewardedShowResult.consentDeclined] if the user opts out,
  /// [RewardedShowResult.disabled] / [RewardedShowResult.notReady] /
  /// [RewardedShowResult.failed] for other non-success cases, and
  /// [RewardedShowResult.success] when the ad is shown.
  Future<RewardedShowResult> show({
    required BuildContext context,
    required void Function(AdWithoutView, RewardItem) onUserEarnedReward,
  }) async {
    if (!adData.enabled) return RewardedShowResult.disabled;
    if (!isLoaded || _ad == null) return RewardedShowResult.notReady;

   //  final consented = await RewardedConsent.requestConsent(context);
   // if (!consented) return RewardedShowResult.consentDeclined;

    try {
      if (adData.adType == AdType.custom) {
        await launchUrlString(adData.customAdUrl);
      } else {
        await _ad!.show(onUserEarnedReward: onUserEarnedReward);
      }
      return RewardedShowResult.success;
    } catch (e) {
      debugPrint("Rewarded show error: $e");
      return RewardedShowResult.failed;
    }
  }

  Future<void> dispose() async {
    _ad?.dispose();
    _ad = null;
    adStatus = AdStatus.idle;
  }
}
