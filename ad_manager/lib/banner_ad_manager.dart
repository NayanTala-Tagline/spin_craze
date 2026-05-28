import 'dart:async';

import 'package:ad_manager/enum/ad_status.dart';
import 'package:ad_manager/enum/ad_type.dart';
import 'package:ad_manager/models/ad_data.dart';
import 'package:ad_manager/utils/anaytics_manager.dart';
import 'package:ad_manager/utils/revenue_handler.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BannerAdManager {
  final AdData adData;
  final AdSize size;
  final BannerAdListener? listener;
  late final BannerAd _ad;
  bool get isLoaded => adStatus == AdStatus.loaded;
  bool get isLoading => adStatus == AdStatus.loading;
  bool get isFailed => adStatus == AdStatus.failed;
  AdStatus adStatus = AdStatus.idle;
  Completer<AdStatus> _completer = Completer<AdStatus>();

  double get _adHeight => adData.height > 0 ? adData.height : size.height.toDouble();

  BannerAdManager({required this.adData, required this.size, this.listener}) {
    _ad = BannerAd(
      adUnitId: adData.adId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          listener?.onAdLoaded?.call(ad);
          try {
            adStatus = AdStatus.loaded;
            if (!_completer.isCompleted) _completer.complete(AdStatus.loaded);
          } catch (e) {
            debugPrint(e.toString());
          }
        },
        onAdFailedToLoad: (ad, error) {
          listener?.onAdFailedToLoad?.call(ad, error);
          try {
            adStatus = AdStatus.failed;
            if (!_completer.isCompleted) _completer.complete(AdStatus.failed);
          } catch (e) {
            debugPrint(e.toString());
          }
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          listener?.onPaidEvent?.call(ad, valueMicros, precision, currencyCode);
          RevenueHelper.sendAdImpressionRevenueToFirebase(
            valueMicros: valueMicros,
            currencyCode: currencyCode,
            precision: precision,
            adUnitId: adData.adId,
          );
        },
        onAdOpened: (ad) {
          listener?.onAdOpened?.call(ad);
          AnalyticsManager.instance.logEvent(name: 'banner_ad_opened');
        },
        onAdClosed: (ad) {
          listener?.onAdClosed?.call(ad);
          AnalyticsManager.instance.logEvent(name: 'banner_ad_close');
        },
        onAdImpression: (ad) {
          listener?.onAdImpression?.call(ad);
          AnalyticsManager.instance.logEvent(name: 'banner_ad_impression');
        },
        onAdClicked: (ad) {
          AnalyticsManager.instance.logEvent(name: 'banner_ad_click');
        },
        onAdWillDismissScreen: listener?.onAdWillDismissScreen?.call,
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SizedBox(width: double.infinity, height: _adHeight),
    );
  }

  Widget adWidget() {
    if (adData.adType == AdType.custom) {
      return SizedBox(
        height: _adHeight,
        child: GestureDetector(
          onTap: () {
            launchUrlString(adData.customAdUrl);
          },
          behavior: HitTestBehavior.opaque,
          child: Image.network(
            height: _adHeight,
            width: double.maxFinite,
            adData.customAdViewUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: SizedBox(width: double.infinity, height: _adHeight),
              );
            },
          ),
        ),
      );
    }
    if (isFailed) return const SizedBox.shrink();

    return SizedBox(
      height: _adHeight,
      child: isLoaded ? AdWidget(ad: _ad) : _buildShimmer(),
    );
  }

  Future<void> load() async {
    if (!adData.enabled) {
      adStatus = AdStatus.disabled;
    }

    if (adData.adType == AdType.custom) {
      adStatus = AdStatus.loaded;
      return;
    }

    if (!isLoaded && !isLoading && !adData.enabled) return;
    adStatus = AdStatus.loading;
    await _ad.load();
  }

  Future<void> reload() async {
    if (!adData.enabled) {
      adStatus = AdStatus.disabled;
    }
    if (!isLoaded && !isLoading && !adData.enabled) return;
    adStatus = AdStatus.loading;
    _completer = Completer<AdStatus>();
    await _ad.load();
  }

  Future<AdStatus> future() => _completer.future;

  BannerAd get ad => _ad;

  Future<void> dispose() => _ad.dispose();
}
