import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/services/reward_ad_service.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/widgets/ad_disclaimer_text.dart';
import 'package:spin_craze/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:spin_craze/extension/ext_localization.dart';

class DailyCheckinDialog extends StatelessWidget {
  final int currentDay;
  final int rewardCoins;
  final VoidCallback onClaim;

  const DailyCheckinDialog({
    super.key,
    required this.currentDay,
    required this.rewardCoins,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final txt = context.themeTextColors;

    return AlertDialog(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.r20),
      ),
      contentPadding: EdgeInsets.all(AppSize.w24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Assets.images.dailyRewardTrophy.image(
            width: AppSize.w60,
            height: AppSize.h60,
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
            'Claim your daily reward of +$rewardCoins Coins!',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: txt.secondary,
              fontSize: AppSize.sp14,
            ),
          ),
          SizedBox(height: AppSize.h8),

          // Progress bar (7-day streak)
          DailyCheckinProgressBar(currentDay: currentDay),
          SizedBox(height: AppSize.h20),

          AdDisclaimerText(show: RewardAdService.isDailyCheckinAdEnabled),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: context.l10n.claimReward,
              variant: AppButtonVariant.gradient,
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: AppSize.w20,
              ),
              onPressed: onClaim,
            ),
          ),
        ],
      ),
    );
  }
}

class DailyCheckinProgressBar extends StatelessWidget {
  const DailyCheckinProgressBar({super.key, required this.currentDay});

  final int currentDay;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    return Row(
      children: List.generate(7, (index) {
        final day = index + 1;
        final isCompleted = day < currentDay;
        final isCurrent = day == currentDay;
        final isIncomplete = !isCompleted && !isCurrent;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSize.w2),
            child: Transform(
              transform: Matrix4.skewX(-0.25),
              child: Container(
                height: AppSize.h12,
                decoration: BoxDecoration(
                  color: isIncomplete
                      ? Colors.white.withValues(alpha: 0.05)
                      : null,
                  border: isIncomplete
                      ? Border.all(color: Colors.white12)
                      : null,
                  gradient: !isIncomplete
                      ? LinearGradient(
                          colors: [colors.primary, colors.secondary],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(AppSize.r2),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
