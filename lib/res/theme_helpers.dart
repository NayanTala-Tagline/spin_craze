import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flutter/material.dart';

/// Reusable visual primitives derived from the active [ThemeColors].
///
/// Prefer `context.themeColors` directly when you only need raw tokens —
/// this class exists for slightly higher-level shapes (shadows, borders,
/// gradient backgrounds) that show up in many widgets.
class ThemeHelpers {
  const ThemeHelpers._();

  /// Subtle elevation used by cards / sheets.
  static List<BoxShadow> cardShadow(BuildContext context) {
    return [
      BoxShadow(
        color: context.themeColors.shadow,
        blurRadius: AppSize.r16,
        offset: Offset(0, AppSize.h6),
      ),
    ];
  }

  /// Glow used behind primary CTAs in the Figma.
  static List<BoxShadow> primaryGlow(BuildContext context) {
    return [
      BoxShadow(
        color: context.themeColors.primary.withValues(alpha: 0.35),
        blurRadius: AppSize.r24,
        spreadRadius: 0,
      ),
    ];
  }

  /// Standard rounded outline border for inputs / selectable cards.
  static OutlineInputBorder inputBorder({
    required Color color,
    double radius = 12,
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
