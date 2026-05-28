import 'dart:async';

import 'package:ad_manager/ad_manager.dart';
import 'package:flutter/foundation.dart';

/// A loaded (or loading) inline + interstitial ad pair, handed between
/// onboarding selection screens so the next screen's ads are ready instantly.
class SelectionAds {
  SelectionAds({this.native, this.inter});

  final InlineAdManager? native;
  final FullScreenAdManager? inter;

  Future<void> dispose() async {
    await native?.dispose();
    await inter?.dispose();
  }
}

/// Owns the ad lifecycle for one onboarding selection screen
/// (country / currency / game) and pre-loads the *next* screen's ads.
///
/// - The inline ad is shown at the bottom via `AdSlot`.
/// - The interstitial is shown on the "Next" tap.
/// - [isLoading] drives the Next button spinner until both ads settle.
/// - [nextNativeData]/[nextInterData] are pre-loaded in the background and
///   handed to the next screen via [takeNext]; ownership transfers on handoff.
///
/// If [preloaded] is supplied (handed off by the previous screen) it is used
/// for this screen's ads instead of creating fresh managers.
class SelectionAdProvider extends ChangeNotifier {
  SelectionAdProvider({
    SelectionAds? preloaded,
    AdData? nativeData,
    AdData? interData,
    this.nextNativeData,
    this.nextInterData,
  }) {
    _init(preloaded, nativeData, interData);
  }

  final AdData? nextNativeData;
  final AdData? nextInterData;

  bool isLoading = false;

  InlineAdManager? nativeAd;
  FullScreenAdManager? interAd;

  SelectionAds? _next;
  bool _nextTransferred = false;

  Future<void> _init(
    SelectionAds? preloaded,
    AdData? nativeData,
    AdData? interData,
  ) async {
    if (preloaded != null) {
      // Ads were pre-loaded on the previous screen — reuse them. They may
      // still be loading, so rebuild once their futures settle.
      nativeAd = preloaded.native;
      interAd = preloaded.inter;
      nativeAd?.future().then((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      nativeAd = nativeData == null ? null : InlineAdManager(adData: nativeData);
      interAd =
          interData == null ? null : FullScreenAdManager(adData: interData);
      await Future.wait([
        nativeAd?.load() ?? Future<void>.value(),
        interAd?.load() ?? Future<void>.value(),
      ]);
    }

    _preloadNext();
    if (!_disposed) notifyListeners();
  }

  void _preloadNext() {
    final n = nextNativeData;
    final i = nextInterData;
    if (n == null || i == null) return;
    final native = InlineAdManager(adData: n);
    final inter = FullScreenAdManager(adData: i);
    // Fire-and-forget; the next screen awaits them via its own wait().
    unawaited(native.load());
    unawaited(inter.load());
    _next = SelectionAds(native: native, inter: inter);
  }

  /// Hand the pre-loaded next-screen ads to the next screen. After this the
  /// provider no longer disposes them.
  SelectionAds? takeNext() {
    _nextTransferred = true;
    return _next;
  }

  /// Awaits both ads finishing their load (success or failure) while flagging
  /// [isLoading] so the caller can show an inline spinner.
  Future<void> wait() async {
    isLoading = true;
    notifyListeners();

    await Future.wait([
      nativeAd?.future() ?? Future.value(AdStatus.idle),
      interAd?.future() ?? Future.value(AdStatus.idle),
    ]);

    isLoading = false;
    notifyListeners();
  }

  /// Shows the interstitial if it loaded; safe to call when disabled/failed.
  Future<void> showInterstitial() async {
    final ad = interAd;
    if (ad == null) return;
    if (ad.isLoaded) await ad.show();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    nativeAd?.dispose();
    interAd?.dispose();
    if (!_nextTransferred) _next?.dispose();
    super.dispose();
  }
}
