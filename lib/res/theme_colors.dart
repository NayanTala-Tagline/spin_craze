// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

/// Theme extension exposing the ClipEarn color palette.
///
/// Tokens are derived from the Figma source of truth (Home + Withdraw frames).
@immutable
class ThemeColors extends ThemeExtension<ThemeColors> {
  const ThemeColors({
    // Surfaces
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.card,
    required this.cardElevated,
    // Brand
    required this.primary,
    required this.primaryDeep,
    required this.primaryLight,
    required this.secondary,
    required this.accent,
    required this.coin,
    required this.coinDeep,
    // Status
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    // Lines / shadows
    required this.border,
    required this.divider,
    required this.shadow,
    required this.scrim,
    // Gradients
    required this.primaryGradient,
    required this.purpleGradient,
    required this.coinGradient,
    required this.backgroundGradient,
  });

  // ── Surfaces ──────────────────────────────────────────────────────────────
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color card;
  final Color cardElevated;

  // ── Brand ─────────────────────────────────────────────────────────────────
  /// Primary cyan (Figma `#00B7FF`).
  final Color primary;

  /// Deep teal used for chips/labels (Figma `#005B80`).
  final Color primaryDeep;

  /// Light cyan accent (Figma `#65D3FF`).
  final Color primaryLight;

  /// Violet/purple accent (Figma `#A86CFF`).
  final Color secondary;

  /// Pink CTA accent (Figma `#FF5183`).
  final Color accent;

  /// Coin yellow (Figma `#FFD84D`).
  final Color coin;

  /// Coin orange (Figma `#FF8C24`).
  final Color coinDeep;

  // ── Status ────────────────────────────────────────────────────────────────
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  // ── Lines / shadows ───────────────────────────────────────────────────────
  final Color border;
  final Color divider;
  final Color shadow;
  final Color scrim;

  // ── Gradients ─────────────────────────────────────────────────────────────
  /// Cyan → blue, used for primary CTAs.
  final LinearGradient primaryGradient;

  /// Violet → magenta, used for spin / quiz highlights.
  final LinearGradient purpleGradient;

  /// Gold gradient used behind coin pills.
  final LinearGradient coinGradient;

  /// Top→bottom dark gradient for screen backgrounds.
  final LinearGradient backgroundGradient;

  @override
  ThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? card,
    Color? cardElevated,
    Color? primary,
    Color? primaryDeep,
    Color? primaryLight,
    Color? secondary,
    Color? accent,
    Color? coin,
    Color? coinDeep,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? border,
    Color? divider,
    Color? shadow,
    Color? scrim,
    LinearGradient? primaryGradient,
    LinearGradient? purpleGradient,
    LinearGradient? coinGradient,
    LinearGradient? backgroundGradient,
  }) {
    return ThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      card: card ?? this.card,
      cardElevated: cardElevated ?? this.cardElevated,
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      primaryLight: primaryLight ?? this.primaryLight,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      coin: coin ?? this.coin,
      coinDeep: coinDeep ?? this.coinDeep,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      purpleGradient: purpleGradient ?? this.purpleGradient,
      coinGradient: coinGradient ?? this.coinGradient,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    );
  }

  @override
  ThemeColors lerp(covariant ThemeColors? other, double t) {
    if (other == null) return this;
    return ThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardElevated: Color.lerp(cardElevated, other.cardElevated, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      coin: Color.lerp(coin, other.coin, t)!,
      coinDeep: Color.lerp(coinDeep, other.coinDeep, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      purpleGradient: LinearGradient.lerp(purpleGradient, other.purpleGradient, t)!,
      coinGradient: LinearGradient.lerp(coinGradient, other.coinGradient, t)!,
      backgroundGradient: LinearGradient.lerp(backgroundGradient, other.backgroundGradient, t)!,
    );
  }
}
