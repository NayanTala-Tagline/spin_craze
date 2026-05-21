import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/features/onboarding_module/onboarding_card.dart';
import 'package:spin_craze/features/onboarding_module/provider/onboarding_provider.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/widgets/bottom_ads_widget.dart';
import 'package:spin_craze/widgets/common_background.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spin_craze/extension/ext_localization.dart';

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
          return CommonBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(Assets.images.onboardingBg.path),
                    fit: BoxFit.fill,
                  ),
                ),
                child: SafeArea(
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
                              parameters: {'page': 2},
                            );
                            await prov.wait(prov.nativeAd2!, prov.interAd2!, context);
                            await prov.interAd2?.show();
                            if (context.mounted) {
                              context.goNamed(AppRoutes.onboarding3);
                            }
                          },
                        ),

                        SizedBox(height: AppSize.h20),

                        // Image
                        Expanded(
                          child: Assets.images.gameZone.image(
                            height: AppSize.h280,
                          ),
                        ),

                        SizedBox(height: AppSize.h20),

                        // Card with title and dots
                        OnboardingCard(
                          title: context.l10n.ultimateGamesTitle,
                          description:
                              context.l10n.ultimateGamesDesc,
                          currentIndex: 1,
                        ),

                        SizedBox(height: AppSize.h20),

                        // Native Ad
                        // if (prov.nativeAd?.adStatus == AdStatus.loaded ||
                        //     prov.nativeAd?.adStatus == AdStatus.loading)
                        //   SizedBox(
                        //     height: prov.nativeAd?.adData.templateType ==
                        //             TemplateType.medium
                        //         ? AppSize.h330
                        //         : AppSize.h150,
                        //     child: prov.nativeAd!.adWidget(),
                        //   ),
                      ],
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: BottomAdsWidget(
                key: ValueKey(2),
                nativeAd: prov.nativeAd,
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
              style: context.textTheme.titleSmall?.copyWith(
                color: txt.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
