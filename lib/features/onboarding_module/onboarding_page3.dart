import 'package:spin_craze/features/onboarding_module/provider/onboarding_provider.dart';
import 'package:spin_craze/features/onboarding_module/widgets/onboarding_scaffold.dart';
import 'package:spin_craze/features/settings_module/language_page.dart'
    show LanguagePageArgs;
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsManager.instance.logScreenView(
      screenName: 'onboarding_3',
      screenClass: 'OnboardingPage3',
    );
    return ChangeNotifierProvider(
      create: (_) => OnboardingProvider(onboardingIndex: 3),
      child: Consumer<OnboardingProvider>(
        builder: (context, prov, _) {
          return OnboardingScaffold(
            currentIndex: 2,
            image: Assets.images.trackAchievments.image(),
            title: 'Track Achievements',
            description:
                'See your achievements and Track it with other user through Leatherboard',
            nextLabel: 'Next',
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
                  extra: LanguagePageArgs(
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
