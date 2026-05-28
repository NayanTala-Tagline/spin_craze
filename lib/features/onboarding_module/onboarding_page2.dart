import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/features/onboarding_module/provider/onboarding_provider.dart';
import 'package:spin_craze/features/onboarding_module/widgets/onboarding_scaffold.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsManager.instance.logScreenView(
      screenName: 'onboarding_2',
      screenClass: 'OnboardingPage2',
    );
    return ChangeNotifierProvider(
      create: (_) => OnboardingProvider(onboardingIndex: 2),
      child: Consumer<OnboardingProvider>(
        builder: (context, prov, _) {
          return OnboardingScaffold(
            currentIndex: 1,
            image: Assets.images.gameZone.image(),
            title: context.l10n.onboardingUltimateGamesTitle,
            description: context.l10n.onboardingUltimateGamesDesc,
            nextLabel: context.l10n.next,
            nativeAd: prov.nativeAd,
            isLoading: prov.isLoading,
            onNext: () async {
              AnalyticsManager.instance.logEvent(
                name: 'onboarding_next',
                parameters: {'page': 2},
              );
              await prov.wait(prov.nativeAd2!, prov.interAd2!);
              await prov.interAd2?.show();
              if (context.mounted) {
                context.goNamed(AppRoutes.onboarding3);
              }
            },
          );
        },
      ),
    );
  }
}
