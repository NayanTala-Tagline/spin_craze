/*
import 'dart:async';
import 'package:btc_mining_tracker/utils/logger.dart';
import 'package:btc_mining_tracker/utils/remote_config.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ad_manager/interstitial_ad_manager.dart';

// Assuming rootNavKey is defined here or imported from main/router
import '../routes/app_router.dart';
import '../widgets/loading_overlay/loading_overlay.dart';

class AdTapManager {
  static final AdTapManager _instance = AdTapManager._internal();

  factory AdTapManager() => _instance;

  AdTapManager._internal();

  // --- 1. The Switch ---
  bool isAdReady = false;

  int tapCount = 0;

  // Using the threshold from RemoteConfig as per your logic
  final int tapThreshold = 4;

  InterstitialAdManager? interstitialAdManager;

  /// Main method to call on button taps
  /// [onNavigate] contains the logic to move to the next screen (e.g., context.pushNamed(...))
  void registerTap(BuildContext context, VoidCallback onNavigate) {
    // 1. If Switch is OFF, navigate immediately
    if (!isAdReady) {
      onNavigate();
      return;
    }
    tapCount++;
    '/// tapCount: $tapCount / $tapThreshold'.logD;

    if (tapCount >= tapThreshold) {
      "go to load".logD;
      tapCount = 0; // Reset immediately

      // 2. Load Ad, THEN Navigate
      _loadAndShowAd(context, onNavigate);
    } else {
      // 3. Threshold not reached, navigate immediately
      onNavigate();
    }
  }

  Future<void> _loadAndShowAd(
      BuildContext context,
      VoidCallback onNavigate,
      ) async {
    // Use the passed context, but fallback to rootNavKey if needed (GoRouter style)
    final overlayContext = context.mounted
        ? context
        : rootNavKey.currentContext;

    if (overlayContext == null) {
      onNavigate(); // Fallback if no context
      return;
    }

    // 1. Show Loading Overlay
    'Show Overlay'.logD;
    final overlay = LoadingOverlay.instance();

    try {
       if (RemoteConfigService.instance.appShowInter) {
        overlay.show(context: context);
        'try cache'.logD;
        interstitialAdManager?.dispose();

        interstitialAdManager = InterstitialAdManager(
          isEnabled: RemoteConfigService.instance.appShowInter,
          // Updated to use your Remote Config
          adUnitId: RemoteConfigService.instance.appInter,

          listener: InterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              'Ad Loaded'.logI;
            },
            onAdFailedToLoad: (error) {
              'Ad Failed: $error'.logI;
            },
          ),

          fullScreenContentCallback: FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              'Ad Shown'.logI;
            },
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

        // 2. Load Ad
        await interstitialAdManager?.load();
        // Wait for the ad to be fully ready (calls the future in your manager)
        await interstitialAdManager?.future();

        // 3. Show Ad
        // This awaits until the user closes the ad
        await interstitialAdManager?.show();
      } else {}
    } catch (e) {
      debugPrint('Ad Load Exception: $e');
    } finally {
      // 4. Always Hide Overlay
      overlay.hide();

      // 5. RUN NAVIGATION NOW
      // This ensures navigation happens only after Ad logic is done.
      onNavigate();
    }
  }

  void dispose() {
    interstitialAdManager?.dispose();
    interstitialAdManager = null;
  }
}
*/
