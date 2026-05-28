import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flutter/material.dart';
import 'package:spin_craze/extension/ext_localization.dart';

/// Pill-shaped coin balance chip used across the Figma (header, withdraw,
/// quiz reward). Renders the coin icon (or any leading widget) on the left
/// and a formatted balance on the right.
class CoinChip extends StatelessWidget {
  const CoinChip({
    required this.amount,
    super.key,
    this.leading,
    this.onTap,
    this.dense = false,
    this.gradient,
    this.borderColor,
  });

  /// Pre-formatted balance string (e.g. `"1,250"`).
  final String amount;

  /// Coin icon. Defaults to a small filled circle in [ThemeColors.coin] —
  /// callers should pass an SVG / image asset for the production look.
  final Widget? leading;

  final VoidCallback? onTap;
  final bool dense;
  final Gradient? gradient;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final textColors = context.themeTextColors;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(AppSize.r100),
      bottomLeft: Radius.circular(AppSize.r100),
    );

    final coinDot = leading ?? Assets.icons.scCoins.svg();

    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSize.w10 : AppSize.w14,
        vertical: dense ? AppSize.h4 : AppSize.h6,
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        color: colors.surface,
        gradient: gradient,
        border: Border.all(color: borderColor ?? colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          coinDot,
          SizedBox(width: AppSize.w8),
          Text(
            amount,
            style:
                (dense
                        ? context.textTheme.labelMedium
                        : context.textTheme.labelLarge)
                    ?.copyWith(
                      color: textColors.primary,
                      fontSize: AppSize.sp12,
                    ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(borderRadius: radius, onTap: onTap, child: content),
    );
  }
}
