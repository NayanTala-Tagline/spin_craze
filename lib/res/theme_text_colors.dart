// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

/// Theme extension for text colors.
///
/// Kept intentionally small — most surface/onSurface text uses [primary],
/// [secondary], [muted]; status colors mirror [ThemeColors].
@immutable
class ThemeTextColors extends ThemeExtension<ThemeTextColors> {
  const ThemeTextColors({
    required this.primary,
    required this.secondary,
    required this.muted,
    required this.disabled,
    required this.inverse,
    required this.onPrimary,
    required this.onAccent,
    required this.link,
    required this.success,
    required this.warning,
    required this.error,
  });

  /// Highest-contrast body / heading text.
  final Color primary;

  /// 70 % contrast — secondary copy.
  final Color secondary;

  /// 50 % contrast — captions, hints, helper text.
  final Color muted;

  /// Disabled state.
  final Color disabled;

  /// Text on light backgrounds in a dark theme (or vice-versa).
  final Color inverse;

  /// Text on top of [ThemeColors.primary] fills.
  final Color onPrimary;

  /// Text on top of [ThemeColors.accent] fills.
  final Color onAccent;

  /// Hyperlinks / accent labels.
  final Color link;

  final Color success;
  final Color warning;
  final Color error;

  @override
  ThemeTextColors copyWith({
    Color? primary,
    Color? secondary,
    Color? muted,
    Color? disabled,
    Color? inverse,
    Color? onPrimary,
    Color? onAccent,
    Color? link,
    Color? success,
    Color? warning,
    Color? error,
  }) {
    return ThemeTextColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      muted: muted ?? this.muted,
      disabled: disabled ?? this.disabled,
      inverse: inverse ?? this.inverse,
      onPrimary: onPrimary ?? this.onPrimary,
      onAccent: onAccent ?? this.onAccent,
      link: link ?? this.link,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  @override
  ThemeTextColors lerp(covariant ThemeTextColors? other, double t) {
    if (other == null) return this;
    return ThemeTextColors(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      inverse: Color.lerp(inverse, other.inverse, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      link: Color.lerp(link, other.link, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}
