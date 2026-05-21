import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spin_craze/extension/ext_localization.dart';

/// Circular back button used by [CommonAppBar] and any screen that needs a
/// stand-alone back affordance. Pulls its colors from the active theme.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onTap,
    this.size,
    this.iconSize,
    this.icon = Icons.arrow_back_ios_new_rounded,
  });

  final VoidCallback? onTap;
  final double? size;
  final double? iconSize;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? AppSize.sp45;
    final colors = context.themeColors;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () => context.pop(),
        child: Container(
          width: dimension,
          height: dimension,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surface,
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: AppSize.r12,
                offset: Offset(0, AppSize.h4),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: iconSize ?? AppSize.sp18,
            color: context.themeTextColors.primary,
          ),
        ),
      ),
    );
  }
}
