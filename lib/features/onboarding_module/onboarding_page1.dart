import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/features/onboarding_module/onboarding_card.dart';
import 'package:spin_craze/features/onboarding_module/provider/onboarding_provider.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/services/ad_repository_service.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/widgets/bottom_ads_widget.dart';
import 'package:spin_craze/widgets/common_background.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class OnboardingPage1 extends StatefulWidget {
  const OnboardingPage1({super.key});

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
      create: (_) => OnboardingProvider(onboardingIndex: 1),
      child: Consumer<OnboardingProvider>(
        builder: (context, prov, _) {
          return CommonBackground(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Assets.images.onboardingBg.path),
                  fit: BoxFit.fill,
                ),
              ),
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSize.w20),
                    child: Column(
                      children: [
                        // ── Top Next button ───────────────
                        _TopButtons(
                          nextLabel: context.l10n.next,
                          onNext: () async {
                            AnalyticsManager.instance.logEvent(
                              name: 'onboarding_next',
                              parameters: {'page': 1},
                            );
                            await prov.wait(
                              prov.nativeAd1!,
                              prov.interAd1!,
                              context,
                            );
                            await prov.interAd1?.show();
                            if (context.mounted) {
                              context.goNamed(AppRoutes.onboarding2);
                            }
                          },
                        ),

                        SizedBox(height: AppSize.h20),

                        // Image
                        Expanded(
                          child: Assets.images.dailyRewardTrophy.image(
                            height: AppSize.h280,
                          ),
                        ),

                        SizedBox(height: AppSize.h20),

                        // Card with title, description, dots
                        OnboardingCard(
                          title: context.l10n.dailyRewardsTitle,
                          description:
                              'You’ll Get a Daily Points Reward, Which you can claim and increase you Points.',
                          currentIndex: 0,
                        ),

                        SizedBox(height: AppSize.h20),

                        // Native Ad
                        // if (prov.nativeAd?.adStatus == AdStatus.loaded ||
                        //     prov.nativeAd?.adStatus == AdStatus.loading)
                        //   SizedBox(
                        //     height:
                        //         prov.nativeAd?.adData.templateType ==
                        //             TemplateType.medium
                        //         ? AppSize.h330
                        //         : AppSize.h150,
                        //     child: prov.nativeAd!.adWidget(),
                        //   ),
                      ],
                    ),
                  ),
                ),
                bottomNavigationBar: BottomAdsWidget(
                  key: ValueKey(1),
                  nativeAd: prov.nativeAd,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Top Skip / Next buttons ─────────────────────────────────────────────────

class _TopButtons extends StatelessWidget {
  const _TopButtons({
    required this.onNext,
    required this.nextLabel,
  });

  final VoidCallback onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final txt = context.themeTextColors;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSize.h12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: onNext,
            child: Text(
              nextLabel,
              style: context.textTheme.titleSmall?.copyWith(color: txt.primary),
            ),
          ),
        ],
      ),
    );
  }
}
