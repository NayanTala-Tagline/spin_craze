import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/widgets/page_indicator.dart';
import 'package:flutter/material.dart';
import 'package:spin_craze/extension/ext_localization.dart';

class OnboardingCard extends StatelessWidget {
  const OnboardingCard({
    super.key,
    required this.title,
    this.description,
    required this.currentIndex,
    this.accentColor,
  });

  final String title;
  final String? description;
  final int currentIndex;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final txt = context.themeTextColors;
    final accent = accentColor ?? context.themeColors.primary;

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: AppSize.sp32,
            color: txt.primary,
          ),
        ),
        SizedBox(height: AppSize.h10),
        // Divider lines (like daily-cash)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: AppSize.w60,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            SizedBox(width: AppSize.w8),
            Container(
              width: AppSize.w24,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: accent,
              ),
            ),
            SizedBox(width: AppSize.w8),
            Container(
              width: AppSize.w60,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
        if (description != null) ...[
          SizedBox(height: AppSize.h12),
          Text(
            description!,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: txt.primary,
              fontSize: AppSize.sp16,
            ),
          ),
        ],
        SizedBox(height: AppSize.h16),
        // Animated page indicator
        PageIndicator(currentPage: currentIndex, pageCount: 3),
        SizedBox(height: AppSize.h10),
      ],
    );
  }
}
