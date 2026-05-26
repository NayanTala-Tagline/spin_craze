import 'package:flutter/material.dart';

/// Shared stepper used across the four onboarding steps (the three
/// onboarding pages + the language page).
///
/// Active step is a wider gradient pill, inactive steps are small dots.
class OnboardingStepIndicator extends StatelessWidget {
  const OnboardingStepIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
  });

  final int currentPage;
  final int pageCount;

  static const _activeGradient = LinearGradient(
    colors: [Color(0xFF1B4FF5), Color(0xFF0028AA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const _inactiveColor = Color(0xFFB7C2E8);
  static const _dotSize = 8.0;
  static const _activeWidth = 36.0;
  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return Padding(
          padding: EdgeInsets.only(right: index == pageCount - 1 ? 0 : _gap),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOut,
            width: isActive ? _activeWidth : _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              gradient: isActive ? _activeGradient : null,
              color: isActive ? null : _inactiveColor,
              borderRadius: BorderRadius.circular(_dotSize / 2),
            ),
          ),
        );
      }),
    );
  }
}
