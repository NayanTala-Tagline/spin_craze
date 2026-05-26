import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spin_craze/extension/ext_localization.dart';

/// Plain white left-arrow used by [CommonAppBar] and any screen that needs a
/// stand-alone back affordance. Matches the Figma `Quiz` header — a bare
/// icon on the gradient panel, no chip / container.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onTap,
    this.size,
    this.iconSize,
    this.icon = Icons.arrow_back_rounded,
  });

  final VoidCallback? onTap;
  final double? size;
  final double? iconSize;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? AppSize.sp45;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () => context.pop(),
        child: SizedBox(
          width: dimension,
          height: dimension,
          child: Icon(
            icon,
            size: iconSize ?? AppSize.sp24,
            color: context.themeTextColors.onPrimary,
          ),
        ),
      ),
    );
  }
}
