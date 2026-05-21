import 'package:ad_manager/ad_manager.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/logger.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:spin_craze/widgets/loading_overlay/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class OpenAdProvider extends ChangeNotifier {
  OpenAdProvider();

  void startOpenAdListener() {
    'is start'.logD;
    ignoreNextEvent = true;
    loadOpenAppAd();
    startStateListener();
  }

  OpenAppAdManager? openAppAd;
  AppLifecycleListener? _listener;

  Future<void> loadOpenAppAd() async {
    openAppAd = OpenAppAdManager(
      adData: RemoteConfigService.instance.applicationAppOpen,
      fullScreenContentCallback: FullScreenContentCallback(
        onAdWillDismissFullScreenContent: (ad) {
          loadOpenAppAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          loadOpenAppAd();
        },
      ),
    );
    await openAppAd?.load();
  }

  Future<void> startStateListener() async {
    _listener = AppLifecycleListener(
      onResume: () async {
        'on resume'.logD;
        if (!RemoteConfigService.instance.applicationAppOpen.enabled &&
            !RemoteConfigService.instance.applicationAppOpen.isCustomAd) {
          return;
        }
        if (ignoreNextEvent) {
          ignoreNextEvent = false;
          return;
        }
        //  ignoreNextEvent = true;
        final context = rootNavKey.currentContext;
        if (context != null && context.mounted) {
          final overlay = LoadingOverlay.instance()..show(context: context);
          'overlay is show'.logD;
          if (RemoteConfigService.instance.applicationAppOpen.isCustomAd) {
            ignoreNextEvent = true;
            await Future.delayed(const Duration(milliseconds: 500));
            launchUrlString(
              RemoteConfigService.instance.applicationAppOpen.customAdUrl,
            );
          } else {
            await openAppAd?.future();
            await openAppAd?.show();
          }
          overlay.hide();
        }
      },
    );
  }

  @override
  void dispose() {
    openAppAd?.dispose();
    _listener?.dispose();
    super.dispose();
  }
}
