import 'package:ad_manager/ad_manager.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/features/onboarding_module/provider/onboarding_provider.dart';
import 'package:spin_craze/features/onboarding_module/widgets/onboarding_scaffold.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/services/ad_repository_service.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class OnboardingPage1 extends StatefulWidget {
  const OnboardingPage1({super.key, this.preloadedNativeAd});

  /// Native ad preloaded by the splash screen and handed off via the router's
  /// `extra`. When present it's used instead of loading a fresh one. May be
  /// `null` (e.g. navigated to directly / ad disabled in Remote Config).
  final InlineAdManager? preloadedNativeAd;

  @override
  State<OnboardingPage1> createState() => _OnboardingPage1State();
}

class _OnboardingPage1State extends State<OnboardingPage1> {
  @override
  void initState() {
    AdRepository.showConsentUMP();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AnalyticsManager.instance.logScreenView(
      screenName: 'onboarding_1',
      screenClass: 'OnboardingPage1',
    );
    return ChangeNotifierProvider(
      create: (_) => OnboardingProvider(
        onboardingIndex: 1,
        preloadedNative1: widget.preloadedNativeAd,
      ),
      child: Consumer<OnboardingProvider>(
        builder: (context, prov, _) {
          return OnboardingScaffold(
            currentIndex: 0,
            image: Assets.images.scDailyRewardTrophy.image(),
            title: context.l10n.onboardingDailyRewardsTitle,
            description: context.l10n.onboardingDailyRewardsDesc,
            nextLabel: context.l10n.next,
            nativeAd: prov.nativeAd,
            isLoading: prov.isLoading,
            onNext: () async {
              AnalyticsManager.instance.logEvent(
                name: 'onboarding_next',
                parameters: {'page': 1},
              );
              await prov.wait(prov.nativeAd1!, prov.interAd1!);
              await prov.interAd1?.show();
              if (context.mounted) {
                context.goNamed(AppRoutes.onboarding2);
              }
            },
          );
        },
      ),
    );
  }
}
