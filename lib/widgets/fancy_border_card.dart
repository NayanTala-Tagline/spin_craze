import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flutter/material.dart';
import 'package:spin_craze/extension/ext_localization.dart';

/// Card with a soft gradient stroke and a deep card fill — the "glow card"
/// look used throughout the Figma (Spin tile, Quiz card, Withdraw row).
class GlowCard extends StatelessWidget {
  const GlowCard({
    required this.child,
    super.key,
    this.padding,
    this.borderRadius,
    this.borderGradient,
    this.fillColor,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Gradient? borderGradient;
  final Color? fillColor;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final radius = BorderRadius.circular(borderRadius ?? AppSize.r16);
    final gradient = borderGradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryLight.withValues(alpha: 0.6),
            colors.primary.withValues(alpha: 0.0),
            colors.secondary.withValues(alpha: 0.4),
          ],
        );

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: gradient,
      ),
      child: Container(
        padding: padding ?? EdgeInsets.all(AppSize.sp16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular((borderRadius ?? AppSize.r16) - 1),
          color: fillColor ?? colors.card,
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: AppSize.r16,
              offset: Offset(0, AppSize.h6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
