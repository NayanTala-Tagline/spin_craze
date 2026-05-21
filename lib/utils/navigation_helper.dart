import 'package:spin_craze/utils/remote_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:ad_manager/ad_manager.dart';
import '../routes/app_router.dart';
import '../widgets/loading_overlay/loading_overlay.dart';
import 'logger.dart';

class NavigationHelper {
  // Singleton instance
  static final NavigationHelper _instance = NavigationHelper._internal();
  factory NavigationHelper() => _instance;
  NavigationHelper._internal();

  int _tapCount = 0;
  final int _tapThreshold = RemoteConfigService.instance.appClickCounter;

  // Instance of your Ad Manager
  InterstitialAdManager? interstitialAdManager;

  // Helper to check if either ad mode is enabled
  bool get _isAdReady =>
      RemoteConfigService.instance.appInter.isCustomAd ||
          RemoteConfigService.instance.appInter.enabled;

  void handleBackPress(BuildContext context) {
    navigateWithAdCheck(context, () {
      context.pop();
    });
  }

  void addBackTap(BuildContext context) {
    navigateWithAdCheck(context, () {
    });
  }

  /// Main entry point for navigation
  void navigateWithAdCheck(BuildContext context, VoidCallback onNavigate) {
    '/// taped...$_tapCount'.logV;
    // 1. If Switch is OFF, navigate immediately
    if (!_isAdReady) {
      onNavigate();
      return;
    }

    _tapCount++;
    '/// tapCount: $_tapCount / $_tapThreshold'.logD;

    if (_tapCount >= _tapThreshold) {
      "go to load".logD;
      _tapCount = 0; // Reset immediately

      // 2. Load Ad logic, THEN Navigate
      _handleAdSequence(context, onNavigate);
    } else {
      // 3. Threshold not reached, navigate immediately
      onNavigate();
    }
  }

  Future<void> _handleAdSequence(BuildContext context, VoidCallback onNavigate) async {
    // Fallback to rootNavKey if current context is invalid/unmounted
    final overlayContext = context.mounted ? context : rootNavKey.currentContext;

    if (overlayContext == null) {
      onNavigate(); // Safety fallback
      return;
    }

    final overlay = LoadingOverlay.instance();
    bool overlayShown = false;

    try {
      // --- LOGIC A: Custom URL Redirect ---
      if (RemoteConfigService.instance.appInter.isCustomAd) {
        ignoreNextEvent = true; // Global var from ad_manager
        '/// launchURL'.logD;

        // Launch the Browser
        // We do NOT await this. We fire it and immediately start the delay timer.
        // This ensures the intent is sent to the OS instantly.
        launchUrlString(
          RemoteConfigService.instance.appInter.customAdUrl,
          mode: LaunchMode.inAppBrowserView,
        );

        // Wait 300ms to allow the browser to take focus before navigating
        await Future.delayed(const Duration(milliseconds: 800));
      }
      // --- LOGIC B: Interstitial Ad ---
      else if (RemoteConfigService.instance.appInter.enabled) {
        ignoreNextEvent = true;
        'Show Overlay'.logD;
        overlay.show(context: overlayContext);
        overlayShown = true;

        'try cache'.logD;
        interstitialAdManager?.dispose();

        // Initialize Ad Manager
        interstitialAdManager = InterstitialAdManager(
          adData: RemoteConfigService.instance.appInter,
          listener: InterstitialAdLoadCallback(
            onAdLoaded: (ad) => 'Ad Loaded'.logI,
            onAdFailedToLoad: (error) => 'Ad Failed: $error'.logI,
          ),
          fullScreenContentCallback: FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) => 'Ad Shown'.logI,
            onAdDismissedFullScreenContent: (ad) {
              'Ad Dismissed'.logI;
              interstitialAdManager?.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              'Ad Failed Show'.logI;
              interstitialAdManager?.dispose();
            },
          ),
        );

        // Load Ad
        await interstitialAdManager?.load();

        // Wait for Ad to be ready
        await interstitialAdManager?.future();

        // Show Ad (Awaits until user closes the ad)
        await interstitialAdManager?.show();

        // Wait 300ms to allow the browser to take focus before navigating
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } catch (e) {
      debugPrint('Ad Logic Exception: $e');
    } finally {
      // 4. Cleanup
      if (overlayShown) {
        overlay.hide();
      }

      // 5. RUN NAVIGATION NOW
      // If Interstitial: Runs after user closes ad.
      // If URL: Runs after browser launches (navigates behind browser).
      onNavigate();
    }
  }

  /// Call this to reset counter if needed
  void resetCounter() {
    _tapCount = 0;
  }
}