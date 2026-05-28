import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/features/onboarding_module/provider/sc_onboarding_provider.dart';
import 'package:spin_craze/features/onboarding_module/widgets/sc_onboarding_scaffold.dart';
import 'package:spin_craze/features/settings_module/sc_language_page.dart'
    show ScLanguagePageArgs;
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ScOnboardingPage3 extends StatelessWidget {
  const ScOnboardingPage3({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsManager.instance.logScreenView(
      screenName: 'onboarding_3',
      screenClass: 'ScOnboardingPage3',
    );
    return ChangeNotifierProvider(
      create: (_) => ScOnboardingProvider(onboardingIndex: 3),
      child: Consumer<ScOnboardingProvider>(
        builder: (context, prov, _) {
          return ScOnboardingScaffold(
            currentIndex: 2,
            image: Assets.images.scTrackAchievments.image(),
            title: context.l10n.onboardingTrackAchievementsTitle,
            description: context.l10n.onboardingTrackAchievementsDesc,
            nextLabel: context.l10n.next,
            nativeAd: prov.nativeAd,
            isLoading: prov.isLoading,
            onNext: () async {
              AnalyticsManager.instance.logEvent(
                name: 'onboarding_completed',
              );
              await prov.wait(prov.nativeAd3!, prov.interAd3!);
              await prov.interAd3?.show();
              if (context.mounted) {
                final ads = prov.takeLanguageAds();
                context.goNamed(
                  AppRoutes.language,
                  extra: ScLanguagePageArgs(
                    isOnboarding: true,
                    languageNativeAd: ads.ad1,
                    languageNative2Ad: ads.ad2,
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
