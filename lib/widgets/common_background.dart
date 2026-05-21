import 'package:spin_craze/extension/ext_context.dart';
import 'package:flutter/material.dart';
import 'package:spin_craze/extension/ext_localization.dart';

/// Full-screen gradient background pulled from [ThemeColors.backgroundGradient].
///
/// Use as the outermost widget on every screen so all screens share the same
/// vertical gradient and the rest of the layout can sit on a transparent
/// [Scaffold] / [CommonAppBar].
class CommonBackground extends StatelessWidget {
  const CommonBackground({
    required this.child,
    super.key,
    this.gradient,
  });

  final Widget child;

  /// Override the theme gradient (e.g. for the Spin / Quiz hero screens).
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient ?? context.themeColors.backgroundGradient,
      ),
      child: child,
    );
  }
}
