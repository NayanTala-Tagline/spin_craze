import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/navigation_helper.dart';
import 'package:spin_craze/widgets/app_button.dart';
import 'package:spin_craze/widgets/common_appbar.dart';
import 'package:spin_craze/widgets/common_background.dart';
import 'package:spin_craze/widgets/glow_container.dart';
import 'package:flutter/material.dart';
import 'package:spin_craze/extension/ext_localization.dart';

class _HowItWorksRule {
  final String title;
  final String desc;
  const _HowItWorksRule({required this.title, required this.desc});
}

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  List<_HowItWorksRule> _getRules(BuildContext context) => [
    _HowItWorksRule(
      title: 'What are Coins?',
      desc: 'Coins are the main currency in this app. You can earn coins by completing tasks and exchange them for real money.',
    ),
    _HowItWorksRule(
      title: 'Daily Missions',
      desc: 'Complete daily tasks like spinning the wheel, scratching cards, or answering quizzes. Each completed mission rewards you with coins.',
    ),
    _HowItWorksRule(
      title: 'Spin Wheel',
      desc: 'Spin the lucky wheel to win instant coin rewards! Each spin can reward you with 10-500 coins.',
    ),
    _HowItWorksRule(
      title: 'Scratch Cards',
      desc: 'Scratch virtual cards to reveal hidden coin rewards from 5 to 50 coins. Free cards daily!',
    ),
    _HowItWorksRule(
      title: 'Quiz Game',
      desc: 'Answer trivia questions correctly to earn 22 coins per question. Build your combo streak.',
    ),
    _HowItWorksRule(
      title: 'Watch Ads',
      desc: 'Watch short video ads to earn quick coins. Each ad rewards you instantly. Up to 10 ads per day.',
    ),
    _HowItWorksRule(
      title: 'Referral System',
      desc: 'Share your referral code with friends. When they sign up and earn, you get bonus coins!',
    ),
    _HowItWorksRule(
      title: 'Withdraw Money',
      desc: 'Once you reach the minimum threshold, convert your coins to real money via PayPal, bank transfer, or gift cards.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    AnalyticsManager.instance.logScreenView(
      screenName: 'how_it_works',
      screenClass: 'HowItWorksScreen',
    );
    final colors = context.themeColors;
    final txt = context.themeTextColors;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        NavigationHelper().handleBackPress(context);
      },
      child: CommonBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CommonAppBar(title: 'How It Works', showBack: true),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSize.w20),
              child: Column(
                children: [
                  SizedBox(height: AppSize.h16),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final rules = _getRules(context);
                        return ListView.separated(
                          itemCount: rules.length,
                          padding: EdgeInsets.symmetric(vertical: AppSize.h10),
                          separatorBuilder: (_, _) =>
                              SizedBox(height: AppSize.h12),
                          itemBuilder: (context, index) {
                            return _HowItWorkCard(
                              index: index + 1,
                              title: rules[index].title,
                              description: rules[index].desc,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: AppSize.h12),
                  // Bottom CTA
                  GlowContainer(
                    accent: colors.primary,
                    borderRadius: AppSize.r12,
                    padding: EdgeInsets.all(AppSize.w16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ready to start earning?',
                          style: context.textTheme.titleMedium?.copyWith(
                            color: txt.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: AppSize.sp16,
                          ),
                        ),
                        SizedBox(height: AppSize.h16),
                        AppButton(
                          label: 'Back to Home',
                          variant: AppButtonVariant.gradient,
                          onPressed: () =>
                              NavigationHelper().handleBackPress(context),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSize.h16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HowItWorkCard extends StatelessWidget {
  const _HowItWorkCard({
    required this.index,
    required this.title,
    required this.description,
  });

  final int index;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final txt = context.themeTextColors;

    return GlowContainer(
      accent: colors.primary,
      borderRadius: AppSize.r8,
      padding: EdgeInsets.all(AppSize.w16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSize.r8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlowContainer(
              accent: colors.primary,
              borderRadius: AppSize.r8,
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSize.w16,
                  vertical: AppSize.h5,
                ),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(AppSize.r8),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  '$index',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: txt.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: AppSize.sp20,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSize.w12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.labelLarge?.copyWith(
                      color: txt.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: AppSize.sp16,
                    ),
                  ),
                  SizedBox(height: AppSize.h5),
                  Text(
                    description,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: txt.secondary,
                      fontSize: AppSize.sp14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
