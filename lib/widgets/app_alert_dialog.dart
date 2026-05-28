import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spin_craze/extension/ext_localization.dart';

/// Standard confirm/cancel dialog styled with the ClipEarn dark palette.
///
/// Returns the user's choice via the future: `true` if confirmed, `false`
/// (or `null`) if dismissed.
Future<bool?> showAppConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmText,
  String? cancelText,
  bool destructive = false,
}) {
  final effectiveConfirm = confirmText ?? context.l10n.confirm;
  final effectiveCancel = cancelText ?? context.l10n.cancel;
  return showDialog<bool>(
    context: context,
    barrierColor: context.themeColors.scrim,
    builder: (ctx) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: AppSize.w24),
        backgroundColor: ctx.themeColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSize.r20),
          side: BorderSide(color: ctx.themeColors.border),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSize.sp20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: ctx.textTheme.titleLarge,
              ),
              SizedBox(height: AppSize.h12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: ctx.textTheme.bodyMedium,
              ),
              SizedBox(height: AppSize.h24),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: effectiveCancel,
                      variant: AppButtonVariant.outline,
                      onPressed: () => ctx.pop(false),
                    ),
                  ),
                  SizedBox(width: AppSize.w12),
                  Expanded(
                    child: AppButton(
                      label: effectiveConfirm,
                      variant: destructive
                          ? AppButtonVariant.accentGradient
                          : AppButtonVariant.gradient,
                      onPressed: () => ctx.pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
