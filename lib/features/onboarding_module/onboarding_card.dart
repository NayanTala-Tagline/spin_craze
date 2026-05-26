import 'package:spin_craze/gen/fonts.gen.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flutter/material.dart';

/// Centred title + description block for the onboarding pages.
///
/// The page indicator was moved to the top of [OnboardingScaffold] in the
/// redesign, so this widget no longer carries an index.
class OnboardingCard extends StatelessWidget {
  const OnboardingCard({
    super.key,
    required this.title,
    this.description,
  });

  final String title;
  final String? description;

  static const _titleColor = Color(0xFF0A1A33);
  static const _descriptionColor = Color(0xFF3B4A66);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: FontFamily.sFPro,
            fontWeight: FontWeight.w800,
            fontSize: AppSize.sp28,
            letterSpacing: 0.2,
            color: _titleColor,
          ),
        ),
        if (description != null) ...[
          SizedBox(height: AppSize.h12),
          Text(
            description!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontFamily.sFPro,
              fontWeight: FontWeight.w500,
              fontSize: AppSize.sp16,
              height: 1.4,
              color: _descriptionColor,
            ),
          ),
        ],
      ],
    );
  }
}
