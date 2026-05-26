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
            title: 'Ultimate Games',
            description:
                'Get Multiple options for Games to Play and Get More Points.',
            nextLabel: 'Next',
            nativeAd: prov.nativeAd,
            onNext: () async {
              AnalyticsManager.instance.logEvent(
                name: 'onboarding_next',
                parameters: {'page': 2},
              );
              await prov.wait(prov.nativeAd2!, prov.interAd2!, context);
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
