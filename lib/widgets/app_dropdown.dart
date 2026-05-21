import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flutter/material.dart';
import 'package:spin_craze/extension/ext_localization.dart';

/// Themed dropdown matching ClipEarn's dark surface + cyan focus.
class AppDropDown<T> extends StatelessWidget {
  const AppDropDown({
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
    this.title,
    this.hint,
    this.icon,
  });

  final String? title;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final textColors = context.themeTextColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.isNotEmpty) ...[
          Text(title!, style: context.textTheme.labelMedium),
          SizedBox(height: AppSize.h8),
        ],
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppSize.w16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppSize.r12),
            border: Border.all(color: colors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
              hint: hint != null
                  ? Text(
                      hint!,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: textColors.muted,
                      ),
                    )
                  : null,
              icon: icon ??
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: textColors.secondary,
                  ),
              style: context.textTheme.bodyMedium?.copyWith(
                color: textColors.primary,
              ),
              dropdownColor: colors.cardElevated,
              borderRadius: BorderRadius.circular(AppSize.r12),
            ),
          ),
        ),
      ],
    );
  }
}
