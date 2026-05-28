import 'dart:async';

import 'package:ad_manager/ad_manager.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/logger.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:spin_craze/widgets/loading_overlay/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// App-open ad on resume. Reloads after every show so Remote Config can flip
/// the slot's `ad_type` without breaking the cycle.
class OpenAdProvider extends ChangeNotifier {
  OpenAdProvider();

  FullScreenAdManager? _openAdManager;
  AppLifecycleListener? _listener;

  void startOpenAdListener() {
    'is start'.logD;
    ignoreNextEvent = true;
    _loadOpenAd();
    _startStateListener();
  }

  Future<void> _loadOpenAd() async {
    final data = RemoteConfigService.instance.applicationAppOpen;

    await _openAdManager?.dispose();
    _openAdManager = FullScreenAdManager(
      adData: data,
      openAppCallback: FullScreenContentCallback<AppOpenAd>(
        onAdWillDismissFullScreenContent: (_) => _loadOpenAd(),
        onAdFailedToShowFullScreenContent: (_, _) => _loadOpenAd(),
      ),
      interstitialCallback: FullScreenContentCallback<InterstitialAd>(
        onAdWillDismissFullScreenContent: (_) => _loadOpenAd(),
        onAdFailedToShowFullScreenContent: (_, _) => _loadOpenAd(),
      ),
    );
    await _openAdManager?.load();
  }

  Future<void> _startStateListener() async {
    _listener = AppLifecycleListener(
      onResume: () async {
        'on resume'.logD;
        final data = RemoteConfigService.instance.applicationAppOpen;
        if (!data.enabled) return;
        if (ignoreNextEvent) {
          ignoreNextEvent = false;
          return;
        }
        final context = rootNavKey.currentContext;
        if (context == null || !context.mounted) return;

        final overlay = LoadingOverlay.instance()..show(context: context);
        'overlay is show'.logD;
        try {
          if (data.adType == AdType.custom) {
            ignoreNextEvent = true;
            await Future<void>.delayed(const Duration(milliseconds: 500));
            unawaited(launchUrlString(data.customAdUrl));
            return;
          }

          final ad = _openAdManager;
          if (ad == null) return;
          await ad.future();
          if (ad.isLoaded) await ad.show();
        } finally {
          overlay.hide();
        }
      },
    );
  }

  @override
  void dispose() {
    _openAdManager?.dispose();
    _listener?.dispose();
    super.dispose();
  }
}
