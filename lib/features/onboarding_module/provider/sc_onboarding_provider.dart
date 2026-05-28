import 'dart:async';

import 'package:ad_manager/ad_manager.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:flutter/cupertino.dart';

/// Onboarding provider — loads this page's inline (native/banner) and
/// full-screen (interstitial) ads via the wrapper APIs so slots can be
/// flipped from Remote Config without code changes.
///
/// Also pre-loads the language page native ads (`languageNative` and
/// `languageNative2`) so they're ready the instant the user lands on the
/// language screen — ownership is transferred via [takeLanguageAds].
class ScOnboardingProvider extends ChangeNotifier {
  ScOnboardingProvider({
    required int onboardingIndex,
    InlineAdManager? preloadedNative1,
  }) {
    switch (onboardingIndex) {
      case 1:
        _loadOnboarding1Ads(preloadedNative1);
      case 2:
        _loadOnboarding2Ads();
      case 3:
        _loadOnboarding3Ads();
    }
    _loadLanguageAds();
  }

  bool isLoading = false;

  InlineAdManager? nativeAd1;
  InlineAdManager? nativeAd2;
  InlineAdManager? nativeAd3;

  FullScreenAdManager? interAd1;
  FullScreenAdManager? interAd2;
  FullScreenAdManager? interAd3;

  /// Convenience getter — returns the inline ad for whichever page was loaded.
  InlineAdManager? get nativeAd => nativeAd1 ?? nativeAd2 ?? nativeAd3;

  InlineAdManager? _languageNativeAd1;
  InlineAdManager? _languageNativeAd2;
  bool _languageAdsTransferred = false;

  Future<void> _loadOnboarding1Ads([InlineAdManager? preloadedNative1]) async {
    // Reuse the native ad the splash screen preloaded (and is handing off) when
    // available, so this page renders an ad immediately instead of starting a
    // fresh load. Falls back to loading our own when nothing was handed off.
    final reusedNative = preloadedNative1 != null;
    nativeAd1 = preloadedNative1 ??
        InlineAdManager(
          adData: RemoteConfigService.instance.onboardingNative1,
        );
    interAd1 = FullScreenAdManager(
      adData: RemoteConfigService.instance.onboardingInter1,
    );
    await Future.wait([
      if (!reusedNative) nativeAd1!.load(),
      interAd1!.load(),
    ]);
    await Future.wait([nativeAd1!.future(), interAd1!.future()]);
    notifyListeners();
  }

  Future<void> _loadOnboarding2Ads() async {
    nativeAd2 = InlineAdManager(
      adData: RemoteConfigService.instance.onboardingNative2,
    );
    interAd2 = FullScreenAdManager(
      adData: RemoteConfigService.instance.onboardingInter2,
    );
    await Future.wait([nativeAd2!.load(), interAd2!.load()]);
    await Future.wait([nativeAd2!.future(), interAd2!.future()]);
    notifyListeners();
  }

  Future<void> _loadOnboarding3Ads() async {
    nativeAd3 = InlineAdManager(
      adData: RemoteConfigService.instance.onboardingNative3,
    );
    interAd3 = FullScreenAdManager(
      adData: RemoteConfigService.instance.onboardingInter3,
    );
    await Future.wait([nativeAd3!.load(), interAd3!.load()]);
    await Future.wait([nativeAd3!.future(), interAd3!.future()]);
    notifyListeners();
  }

  /// Waits for the given inline + full-screen ad to finish loading.
  /// Drives [isLoading] so the caller can show an inline loader (e.g. a spinner
  /// on the Next button) until the ads are ready.
  Future<void> wait(
    InlineAdManager nativeAd,
    FullScreenAdManager interAd,
  ) async {
    isLoading = true;
    notifyListeners();

    await Future.wait([nativeAd.future(), interAd.future()]);

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadLanguageAds() async {
    final ad1Data = RemoteConfigService.instance.languageNative;
    if (ad1Data.enabled || ad1Data.adType == AdType.custom) {
      _languageNativeAd1 = InlineAdManager(adData: ad1Data);
      unawaited(_languageNativeAd1!.load());
    }

    final ad2Data = RemoteConfigService.instance.languageNative2;
    if (ad2Data.enabled || ad2Data.adType == AdType.custom) {
      _languageNativeAd2 = InlineAdManager(adData: ad2Data);
      unawaited(_languageNativeAd2!.load());
    }
  }

  /// Hand the pre-loaded language ads off to the language page.
  ({InlineAdManager? ad1, InlineAdManager? ad2}) takeLanguageAds() {
    _languageAdsTransferred = true;
    return (ad1: _languageNativeAd1, ad2: _languageNativeAd2);
  }

  @override
  void dispose() {
    nativeAd1?.dispose();
    interAd1?.dispose();
    nativeAd2?.dispose();
    interAd2?.dispose();
    nativeAd3?.dispose();
    interAd3?.dispose();

    if (!_languageAdsTransferred) {
      _languageNativeAd1?.dispose();
      _languageNativeAd2?.dispose();
    }
    super.dispose();
  }
}
