import 'package:flutter/material.dart';

/// Plain light-blue gradient backdrop for the onboarding pages.
///
/// The animated decoration (waves) is drawn separately inside the
/// illustration area so it shrinks together with the image when the
/// scaffold's available height changes (e.g. when an ad is shown in
/// the bottom nav slot).
class OnboardingBackground extends StatelessWidget {
  const OnboardingBackground({super.key, required this.child});

  final Widget child;

  static const _gradient = LinearGradient(
    colors: [Color(0xFFF3F7FF), Color(0xFFE2ECFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _gradient),
      child: child,
    );
  }
}
