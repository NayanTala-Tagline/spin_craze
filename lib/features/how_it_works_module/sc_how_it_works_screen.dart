import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/navigation_helper.dart';
import 'package:spin_craze/widgets/app_button.dart';
import 'package:spin_craze/widgets/common_appbar.dart';
import 'package:flutter/material.dart';

const _kPageBg = Color(0xFFF4F7FE);
const _kCardBg = Colors.white;
const _kCardBorder = Color(0xFFE5EBF5);
const _kTextDark = Color(0xFF111827);
const _kTextMuted = Color(0xFF6B7280);
const _kBadgeBg = Color(0xFFE6EEFF);
const _kBadgeBorder = Color(0xFFBFCDEE);

class _ScHowItWorksRule {
  final String title;
  final String desc;
  const _ScHowItWorksRule({required this.title, required this.desc});
}

class ScHowItWorksScreen extends StatelessWidget {
  const ScHowItWorksScreen({super.key});

  List<_ScHowItWorksRule> _getRules(BuildContext context) => [
    _ScHowItWorksRule(
      title: context.l10n.hiwWhatAreCoinsTitle,
      desc: context.l10n.hiwWhatAreCoinsDesc,
    ),
    _ScHowItWorksRule(
      title: context.l10n.hiwDailyMissionsTitle,
      desc: context.l10n.hiwDailyMissionsDesc,
    ),
    _ScHowItWorksRule(
      title: context.l10n.earnModuleSpinTitle,
      desc: context.l10n.hiwSpinWheelDesc,
    ),
    _ScHowItWorksRule(
      title: context.l10n.hiwScratchCardsTitle,
      desc: context.l10n.hiwScratchCardsDesc,
    ),
    _ScHowItWorksRule(
      title: context.l10n.hiwQuizGameTitle,
      desc: context.l10n.hiwQuizGameDesc,
    ),
    _ScHowItWorksRule(
      title: context.l10n.hiwWatchAdsTitle,
      desc: context.l10n.hiwWatchAdsDesc,
    ),
    _ScHowItWorksRule(
      title: context.l10n.hiwReferralTitle,
      desc: context.l10n.hiwReferralDesc,
    ),
    _ScHowItWorksRule(
      title: context.l10n.hiwWithdrawTitle,
      desc: context.l10n.hiwWithdrawDesc,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    AnalyticsManager.instance.logScreenView(
      screenName: 'how_it_works',
      screenClass: 'ScHowItWorksScreen',
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        NavigationHelper().handleBackPress(context);
      },
      child: Scaffold(
        backgroundColor: _kPageBg,
        appBar: CommonAppBar(title: context.l10n.howItWorks, showBack: true),
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
                          return _ScHowItWorkCard(
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
                Container(
                  padding: EdgeInsets.all(AppSize.w16),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(AppSize.r12),
                    border: Border.all(color: _kCardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B1F4D).withValues(alpha: 0.05),
                        blurRadius: AppSize.r12,
                        offset: Offset(0, AppSize.h4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.readyToStartEarning,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: _kTextDark,
                          fontWeight: FontWeight.w600,
                          fontSize: AppSize.sp16,
                        ),
                      ),
                      SizedBox(height: AppSize.h16),
                      AppButton(
                        label: context.l10n.backToHome,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ScHowItWorkCard extends StatelessWidget {
  const _ScHowItWorkCard({
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

    return Container(
      padding: EdgeInsets.all(AppSize.w16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(AppSize.r12),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1F4D).withValues(alpha: 0.05),
            blurRadius: AppSize.r10,
            offset: Offset(0, AppSize.h4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(
              horizontal: AppSize.w14,
              vertical: AppSize.h6,
            ),
            decoration: BoxDecoration(
              color: _kBadgeBg,
              borderRadius: BorderRadius.circular(AppSize.r8),
              border: Border.all(color: _kBadgeBorder),
            ),
            child: Text(
              '$index',
              style: context.textTheme.titleMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                fontSize: AppSize.sp18,
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
                    color: _kTextDark,
                    fontWeight: FontWeight.w700,
                    fontSize: AppSize.sp15,
                  ),
                ),
                SizedBox(height: AppSize.h5),
                Text(
                  description,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: _kTextMuted,
                    fontSize: AppSize.sp13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
