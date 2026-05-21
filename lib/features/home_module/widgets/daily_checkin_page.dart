import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/features/home_module/provider/home_provider.dart';
import 'package:spin_craze/features/home_module/widgets/daily_checkin_dialog.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/services/reward_ad_service.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/widgets/ad_disclaimer_text.dart';
import 'package:spin_craze/widgets/app_button.dart';
import 'package:spin_craze/widgets/common_appbar.dart';
import 'package:spin_craze/widgets/glow_container.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Full-screen Daily Check-in page reachable from the AppBar streak chip.
///
/// Mirrors [DailyCheckinDialog] (same 1-7 progress + claim flow) but adds the
/// lifetime claim count and renders as a Scaffold.
class DailyCheckinPage extends StatelessWidget {
  const DailyCheckinPage({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsManager.instance.logScreenView(
      screenName: 'daily_checkin',
      screenClass: 'DailyCheckinPage',
    );

    final db = Injector.instance<AppDB>();

    // HomeProvider is created at the app root (see main.dart) so we just read
    // the shared instance here — creating a new one would re-trigger the
    // post-frame check-in dialog.
    return Consumer<HomeProvider>(
      builder: (context, provider, _) {
        return StreamBuilder(
          stream: db.userListenable(),
          builder: (context, _) {
            final colors = context.themeColors;
            return Scaffold(
                backgroundColor: colors.background,
                appBar: CommonAppBar(
                  title: 'Daily Check-in',
                  showBack: true,
                ),
                body: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSize.w16,
                    AppSize.h16,
                    AppSize.w16,
                    AppSize.h32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TotalStreakCard(totalDays: provider.totalClaimDays),
                      SizedBox(height: AppSize.h20),
                      _ProgressCard(
                        currentDay: provider.currentCheckInDay,
                        rewardCoins: provider.dailyRewardCoins,
                        isClaimed: provider.isRewardClaimed,
                        onClaim: provider.isRewardClaimed
                            ? null
                            : () {
                                AnalyticsManager.instance.logEvent(
                                  name: 'daily_checkin_page_claim_tap',
                                  parameters: {
                                    'coins': provider.dailyRewardCoins,
                                  },
                                );
                                provider.claimReward(context);
                              },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
      },
    );
  }
}

class _TotalStreakCard extends StatelessWidget {
  const _TotalStreakCard({required this.totalDays});

  final int totalDays;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final txt = context.themeTextColors;
    final radius = BorderRadius.circular(AppSize.r16);

    return GlowContainer(
      accent: const Color(0xFFFF8C24),
      borderRadius: AppSize.r16,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.w20,
          vertical: AppSize.h20,
        ),
        decoration: BoxDecoration(
          borderRadius: radius,
          color: colors.surface,
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: AppSize.sp52,
              height: AppSize.sp52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB347), Color(0xFFFF8C24)],
                ),
              ),
              child: Assets.icons.flame.svg(
                height: AppSize.sp28,
                width: AppSize.sp28,
              ),
            ),
            SizedBox(width: AppSize.w16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Days Claimed',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: txt.secondary,
                    ),
                  ),
                  SizedBox(height: AppSize.h4),
                  Text(
                    context.l10n.daysCount(totalDays),
                    style: context.textTheme.titleLarge?.copyWith(
                      color: txt.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: AppSize.sp22,
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

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.currentDay,
    required this.rewardCoins,
    required this.isClaimed,
    required this.onClaim,
  });

  final int currentDay;
  final int rewardCoins;
  final bool isClaimed;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final txt = context.themeTextColors;
    final radius = BorderRadius.circular(AppSize.r20);

    return GlowContainer(
      accent: colors.primary,
      borderRadius: AppSize.r20,
      child: Container(
        padding: EdgeInsets.all(AppSize.w20),
        decoration: BoxDecoration(
          borderRadius: radius,
          color: colors.card,
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Assets.images.dailyRewardTrophy.image(
              width: AppSize.w80,
              height: AppSize.h80,
              fit: BoxFit.contain,
            ),
            SizedBox(height: AppSize.h16),
            Text(
              'Daily Check-in Reward',
              style: context.textTheme.titleMedium?.copyWith(
                color: txt.primary,
                fontSize: AppSize.sp18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppSize.h8),
            Text(
              'Day $currentDay',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.secondary,
                fontSize: AppSize.sp16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSize.h8),
            Text(
              isClaimed
                  ? 'You have already claimed today\'s reward.'
                  : 'Claim your daily reward of +$rewardCoins Coins!',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: txt.secondary,
                fontSize: AppSize.sp14,
              ),
            ),
            SizedBox(height: AppSize.h16),
            DailyCheckinProgressBar(currentDay: currentDay),
            SizedBox(height: AppSize.h20),
            AdDisclaimerText(show: RewardAdService.isDailyCheckinAdEnabled),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: isClaimed
                    ? context.l10n.claimed
                    : context.l10n.claimReward,
                variant: AppButtonVariant.gradient,
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: AppSize.w20,
                ),
                onPressed: onClaim ?? () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
