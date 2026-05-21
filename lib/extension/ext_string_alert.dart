// import 'package:clipboard/clipboard.dart';

import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flash/flash.dart';
import 'package:flash/flash_helper.dart';
import 'package:flutter/material.dart';

/// extension for [String] to show alerts
extension StringX on String {
  /// to show error alert
  void showErrorAlert({
    Duration? duration,
  }) => rootNavKey.currentContext!.showFlash<void>(
    builder: (context, controller) {
      return FlashBar(
        controller: controller,
        behavior: FlashBehavior.floating,
        content: Text(
          this,
          style: rootNavKey.currentContext!.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: context.themeColors.surface,
        indicatorColor: const Color(0xFFE57373),
        icon: const Icon(Icons.error_outline, color: Color(0xFFE57373)),
        shouldIconPulse: false,
        margin: EdgeInsets.symmetric(
          horizontal: AppSize.h16,
          vertical: AppSize.h16,
        ),
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.h16)),
        forwardAnimationCurve: Curves.bounceOut,
        // reverseAnimationCurve: Curves.bounceOut,
      );
    },
    duration: duration ?? const Duration(seconds: 3),
  );

  /// to show success alert
  void showSuccessAlert({
    Duration? duration,
  }) => rootNavKey.currentContext!.showFlash<void>(
    builder: (context, controller) {
      return FlashBar(
        controller: controller,
        behavior: FlashBehavior.floating,
        content: Text(
          this,
          style: rootNavKey.currentContext!.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: context.themeColors.surface,
        indicatorColor: const Color(0xFF81C784),
        icon: const Icon(Icons.check_circle_outline, color: Color(0xFF81C784)),
        shouldIconPulse: false,
        margin: EdgeInsets.symmetric(
          horizontal: AppSize.h16,
          vertical: AppSize.h16,
        ),
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.h16)),
        forwardAnimationCurve: Curves.bounceOut,
        // reverseAnimationCurve: Curves.bounceOut,
      );
    },
    duration: duration ?? const Duration(seconds: 3),
  );

  /// to show info alert
  void showInfoAlert({
    Duration? duration,
  }) => rootNavKey.currentContext!.showFlash<void>(
    builder: (context, controller) {
      return FlashBar(
        controller: controller,
        behavior: FlashBehavior.floating,
        content: Text(
          this,
          style: rootNavKey.currentContext!.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: context.themeColors.surface,
        indicatorColor: const Color(0xFF64B5F6),
        icon: const Icon(Icons.info_outline, color: Colors.white),
        shouldIconPulse: false,
        margin: EdgeInsets.symmetric(
          horizontal: AppSize.h16,
          vertical: AppSize.h16,
        ),
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.h16)),
        forwardAnimationCurve: Curves.bounceOut,
        // reverseAnimationCurve: Curves.bounceOut,
      );
    },
    duration: duration ?? const Duration(seconds: 2),
  );

  /// function to copy string to clipboard
  // void copyToClipboard({String? alert}) {
  //   FlutterClipboard.copy(this);
  //   // As discussed with QA team : changing showInfoAlert to showSuccessAlert
  //   (alert ?? rootNavKey.currentContext?.l10n.copied)?.showSuccessAlert();
  //   HapticFeedback.mediumImpact();
  // }
}
