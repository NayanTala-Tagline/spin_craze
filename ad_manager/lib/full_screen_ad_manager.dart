import 'dart:async';

import 'package:ad_manager/enum/ad_status.dart';
import 'package:ad_manager/enum/ad_type.dart';
import 'package:ad_manager/enum/rewarded_show_result.dart';
import 'package:ad_manager/interstitial_ad_manager.dart';
import 'package:ad_manager/models/ad_data.dart';
import 'package:ad_manager/open_app_ad_manager.dart';
import 'package:ad_manager/rewarded_ad_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manages a full-screen ad that can switch between interstitial, app open,
/// and rewarded based on [AdData.adType].
///
/// - [AdType.interstatial] → InterstitialAdManager
/// - [AdType.openApp]      → OpenAppAdManager
/// - [AdType.rewarded]     → RewardedAdManager
class FullScreenAdManager {
  final AdData adData;

  InterstitialAdManager? _interstitialManager;
  OpenAppAdManager? _openAppManager;
  RewardedAdManager? _rewardedManager;

  FullScreenAdManager({
    required this.adData,
    FullScreenContentCallback<InterstitialAd>? interstitialCallback,
    FullScreenContentCallback<AppOpenAd>? openAppCallback,
    FullScreenContentCallback<RewardedAd>? rewardedCallback,
  }) {
    switch (adData.adType) {
      case AdType.interstatial:
      case AdType.custom:
        _interstitialManager = InterstitialAdManager(
          adData: adData,
          fullScreenContentCallback: interstitialCallback,
        );
      case AdType.openApp:
        _openAppManager = OpenAppAdManager(
          adData: adData,
          fullScreenContentCallback: openAppCallback,
        );
      case AdType.rewarded:
        _rewardedManager = RewardedAdManager(
          adData: adData,
          fullScreenContentCallback: rewardedCallback,
        );
      default:
        break;
    }
  }

  AdStatus get adStatus =>
      _interstitialManager?.adStatus ??
      _openAppManager?.adStatus ??
      _rewardedManager?.adStatus ??
      AdStatus.idle;

  bool get isLoaded => adStatus == AdStatus.loaded;
  bool get isLoading => adStatus == AdStatus.loading;
  bool get isFailed => adStatus == AdStatus.failed;

  Future<void> load() async {
    if (_interstitialManager != null) return _interstitialManager!.load();
    if (_openAppManager != null) return _openAppManager!.load();
    if (_rewardedManager != null) return _rewardedManager!.load();
  }

  Future<void> reload() async {
    if (_interstitialManager != null) return _interstitialManager!.reload();
    if (_openAppManager != null) return _openAppManager!.reload();
    if (_rewardedManager != null) return _rewardedManager!.reload();
  }

  Future<AdStatus> future() {
    return _interstitialManager?.future() ??
        _openAppManager?.future() ??
        _rewardedManager?.future() ??
        Future.value(AdStatus.idle);
  }

  /// Show the full-screen ad.
  ///
  /// For interstitial / app-open ads returns `true` on success, `false`
  /// otherwise.
  ///
  /// For rewarded ads [context] and [onUserEarnedReward] are required.
  /// Returns a [RewardedShowResult] mapped to `bool` (`success` → `true`,
  /// everything else → `false`). Inspect [showRewardedAd] directly on
  /// [RewardedAdManager] when you need the granular result (e.g. to
  /// distinguish [RewardedShowResult.consentDeclined]).
  Future<bool> show({
    BuildContext? context,
    void Function(AdWithoutView, RewardItem)? onUserEarnedReward,
  }) async {
    if (_interstitialManager != null) return _interstitialManager!.show();
    if (_openAppManager != null) return _openAppManager!.show();
    if (_rewardedManager != null) {
      if (onUserEarnedReward == null || context == null) return false;
      final result = await _rewardedManager!.show(
        context: context,
        onUserEarnedReward: onUserEarnedReward,
      );
      return result == RewardedShowResult.success;
    }
    return false;
  }

  Future<void> dispose() async {
    await _interstitialManager?.dispose();
    await _openAppManager?.dispose();
    await _rewardedManager?.dispose();
  }
}
