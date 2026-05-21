import 'dart:async';

import 'package:ad_manager/ad_manager.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:spin_craze/widgets/loading_overlay/loading_overlay.dart';
import 'package:flutter/cupertino.dart';

/// Onboarding provider — matches daily-cash ad loading pattern.
///
/// Each page creates its own provider instance with the correct index.
/// The provider loads this page's native + interstitial ads, waits for them,
/// and notifies listeners when ready.
///
/// Also pre-loads the language page native ads (`languageNative` and
/// `languageNative2`) so they're ready the instant the user lands on the
/// language screen — ownership is transferred via [takeLanguageAds].
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider({required int onboardingIndex}) {
    switch (onboardingIndex) {
      case 1:
        _loadOnboarding1Ads();
      case 2:
        _loadOnboarding2Ads();
      case 3:
        _loadOnboarding3Ads();
    }
    _loadLanguageAds();
  }

  bool isLoading = false;

  NativeAdManager? nativeAd1;
  NativeAdManager? nativeAd2;
  NativeAdManager? nativeAd3;

  InterstitialAdManager? interAd1;
  InterstitialAdManager? interAd2;
  InterstitialAdManager? interAd3;

  /// Convenience getter — returns the native ad for whichever page was loaded.
  NativeAdManager? get nativeAd => nativeAd1 ?? nativeAd2 ?? nativeAd3;

  // Pre-loaded ads for the language page.
  NativeAdManager? _languageNativeAd1;
  NativeAdManager? _languageNativeAd2;
  bool _languageAdsTransferred = false;

  // ── Per-page ad loading (same as daily-cash) ────────────────────────────

  Future<void> _loadOnboarding1Ads() async {
    nativeAd1 = NativeAdManager(
      adData: RemoteConfigService.instance.onboardingNative1,
    );
    interAd1 = InterstitialAdManager(
      adData: RemoteConfigService.instance.onboardingInter1,
    );
    await Future.wait([nativeAd1!.load(), interAd1!.load()]);
    await Future.wait([nativeAd1!.future(), interAd1!.future()]);
    notifyListeners();
  }

  Future<void> _loadOnboarding2Ads() async {
    nativeAd2 = NativeAdManager(
      adData: RemoteConfigService.instance.onboardingNative2,
    );
    interAd2 = InterstitialAdManager(
      adData: RemoteConfigService.instance.onboardingInter2,
    );
    await Future.wait([nativeAd2!.load(), interAd2!.load()]);
    await Future.wait([nativeAd2!.future(), interAd2!.future()]);
    notifyListeners();
  }

  Future<void> _loadOnboarding3Ads() async {
    nativeAd3 = NativeAdManager(
      adData: RemoteConfigService.instance.onboardingNative3,
    );
    interAd3 = InterstitialAdManager(
      adData: RemoteConfigService.instance.onboardingInter3,
    );
    await Future.wait([nativeAd3!.load(), interAd3!.load()]);
    await Future.wait([nativeAd3!.future(), interAd3!.future()]);
    notifyListeners();
  }

  /// Waits for the given native + interstitial to finish loading.
  /// Shows a full-screen loading overlay so the user knows ads are loading.
  Future<void> wait(
    NativeAdManager nativeAd,
    InterstitialAdManager interAd,
    BuildContext context,
  ) async {
    isLoading = true;
    notifyListeners();

    final overlay = LoadingOverlay.instance();
    overlay.show(context: context);

    await Future.wait([nativeAd.future(), interAd.future()]);

    overlay.hide();
    isLoading = false;
    notifyListeners();
  }

  // ── Language page ads ───────────────────────────────────────────────────

  Future<void> _loadLanguageAds() async {
    final ad1Data = RemoteConfigService.instance.languageNative;
    if (ad1Data.enabled || ad1Data.isCustomAd) {
      _languageNativeAd1 = NativeAdManager(adData: ad1Data);
      unawaited(_languageNativeAd1!.load());
    }

    final ad2Data = RemoteConfigService.instance.languageNative2;
    if (ad2Data.enabled || ad2Data.isCustomAd) {
      _languageNativeAd2 = NativeAdManager(adData: ad2Data);
      unawaited(_languageNativeAd2!.load());
    }
  }

  /// Hand the pre-loaded language ads off to the language page.
  ({NativeAdManager? ad1, NativeAdManager? ad2}) takeLanguageAds() {
    _languageAdsTransferred = true;
    return (ad1: _languageNativeAd1, ad2: _languageNativeAd2);
  }

  @override
  void dispose() {
    // dispose the native and interstitial ads
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
