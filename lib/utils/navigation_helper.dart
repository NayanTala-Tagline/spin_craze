import 'dart:async';

import 'package:ad_manager/ad_manager.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../routes/app_router.dart';
import '../widgets/loading_overlay/loading_overlay.dart';
import 'logger.dart';

/// Shows a full-screen ad every N taps of nav buttons. Threshold is read from
/// Remote Config (`app_click_counter`) on every tap, so config changes apply
/// without a rebuild.
class NavigationHelper {
  static final NavigationHelper _instance = NavigationHelper._internal();
  factory NavigationHelper() => _instance;
  NavigationHelper._internal();

  int _tapCount = 0;
  int get _tapThreshold => RemoteConfigService.instance.appClickCounter;

  FullScreenAdManager? _fullScreenAd;

  bool get _isAdReady {
    final data = RemoteConfigService.instance.appInter;
    return data.enabled || data.adType == AdType.custom;
  }

  void handleBackPress(BuildContext context) {
    navigateWithAdCheck(context, () {
      context.pop();
    });
  }

  void addBackTap(BuildContext context) {
    navigateWithAdCheck(context, () {});
  }

  /// Main entry point for navigation.
  void navigateWithAdCheck(BuildContext context, VoidCallback onNavigate) {
    '/// taped...$_tapCount'.logV;

    if (!_isAdReady) {
      onNavigate();
      return;
    }

    _tapCount++;
    '/// tapCount: $_tapCount / $_tapThreshold'.logD;

    if (_tapCount >= _tapThreshold) {
      'go to load'.logD;
      _tapCount = 0;
      _handleAdSequence(context, onNavigate);
    } else {
      onNavigate();
    }
  }

  Future<void> _handleAdSequence(
    BuildContext context,
    VoidCallback onNavigate,
  ) async {
    final overlayContext = context.mounted ? context : rootNavKey.currentContext;
    if (overlayContext == null) {
      onNavigate();
      return;
    }

    final data = RemoteConfigService.instance.appInter;
    final overlay = LoadingOverlay.instance();
    bool overlayShown = false;

    try {
      if (data.adType == AdType.custom) {
        ignoreNextEvent = true;
        '/// launchURL'.logD;
        unawaited(
          launchUrlString(
            data.customAdUrl,
            mode: LaunchMode.inAppBrowserView,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 800));
        return;
      }

      if (data.enabled) {
        ignoreNextEvent = true;
        'Show Overlay'.logD;
        overlay.show(context: overlayContext);
        overlayShown = true;

        await _fullScreenAd?.dispose();
        _fullScreenAd = FullScreenAdManager(
          adData: data,
          interstitialCallback: FullScreenContentCallback<InterstitialAd>(
            onAdShowedFullScreenContent: (_) => 'Ad Shown'.logI,
            onAdDismissedFullScreenContent: (_) => 'Ad Dismissed'.logI,
            onAdFailedToShowFullScreenContent: (_, _) => 'Ad Failed Show'.logI,
          ),
          openAppCallback: FullScreenContentCallback<AppOpenAd>(
            onAdShowedFullScreenContent: (_) => 'Ad Shown'.logI,
            onAdDismissedFullScreenContent: (_) => 'Ad Dismissed'.logI,
            onAdFailedToShowFullScreenContent: (_, _) => 'Ad Failed Show'.logI,
          ),
        );

        await _fullScreenAd!.load();
        await _fullScreenAd!.future();
        if (_fullScreenAd!.isLoaded) await _fullScreenAd!.show();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    } catch (e) {
      debugPrint('Ad Logic Exception: $e');
    } finally {
      if (overlayShown) overlay.hide();
      onNavigate();
    }
  }

  void resetCounter() {
    _tapCount = 0;
  }
}
