import 'package:spin_craze/res/theme_colors.dart';
import 'package:spin_craze/res/theme_dark.dart' show buildTextTheme;
import 'package:spin_craze/res/theme_text_colors.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flutter/material.dart';

// ClipEarn is dark-first; the light theme inverts surfaces while keeping
// brand cyan/purple/coin tokens identical so screens stay on-brand.

const _colors = ThemeColors(
  // Surfaces
  background: Color(0xFFF0F5FF),
  surface: Color(0xFF0E2B33),
  surfaceMuted: Color(0xFF081821),
  card: Color(0xFF0E2B33),
  cardElevated: Color(0xFF14323D),
  // Brand
  primary: Color(0xFF004CD9),
  primaryDeep: Color(0xFF004CD9),
  primaryLight: Color(0xFF1164FF),
  secondary: Color(0xFFA86CFF),
  accent: Color(0xFFFF5183),
  coin: Color(0xFFFFD84D),
  coinDeep: Color(0xFFFF8C24),
  // Status
  success: Color(0xFFA2FF60),
  warning: Color(0xFFFFD84D),
  error: Color(0xFFFF5183),
  info: Color(0xFF65D3FF),
  // Lines / shadows
  border: Color(0x29A86CFF), // #A86CFF @ 16 %
  divider: Color(0xFF14323D),
  shadow: Color(0x66081821), // #081821 @ 40 %
  scrim: Color(0xCC000000),
  // Gradients (extracted from Figma fills)
  primaryGradient: LinearGradient(
    colors: [Color(0xFF47AED7), Color(0xFF62D2FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  purpleGradient: LinearGradient(
    colors: [Color(0xFF7529E6), Color(0xFFA95CF5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  coinGradient: LinearGradient(
    colors: [Color(0xFFFFD84D), Color(0xFFFF8C24)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
  backgroundGradient: LinearGradient(
    colors: [Color(0xFF0E2B33), Color(0xFF05131B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
);

const _text = ThemeTextColors(
  primary: Color(0xFF000000),
  secondary: Color(0xB3FFFFFF), // 70 %
  muted: Color(0x80FFFFFF), // 50 %
  disabled: Color(0x4DFFFFFF), // 30 %
  inverse: Color(0xFF05131B),
  onPrimary: Color(0xFFFFFFFF),
  onAccent: Color(0xFFFFFFFF),
  link: Color(0xFF65D3FF),
  success: Color(0xFFA2FF60),
  warning: Color(0xFFFFD84D),
  error: Color(0xFFFF5183),
);

final ThemeData lightTheme = () {
  final base = ThemeData.light(useMaterial3: true);
  final textTheme = buildTextTheme(_text);
  return base.copyWith(
    colorScheme: ColorScheme.light(
      primary: _colors.primary,
      onPrimary: _text.onPrimary,
      secondary: _colors.secondary,
      onSecondary: _text.onPrimary,
      surface: _colors.surface,
      onSurface: _text.primary,
      error: _colors.error,
      onError: _text.onPrimary,
    ),
    scaffoldBackgroundColor: _colors.background,
    cardColor: _colors.card,
    dividerColor: _colors.divider,
    shadowColor: _colors.shadow,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: _text.primary),
      titleTextStyle: textTheme.titleLarge,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _colors.primary,
        foregroundColor: _text.onPrimary,
        minimumSize: Size(AppSize.w64, AppSize.h48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.r16)),
        textStyle: textTheme.labelLarge,
        padding: EdgeInsets.symmetric(horizontal: AppSize.w20),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _colors.primary,
        minimumSize: Size(AppSize.w64, AppSize.h48),
        side: BorderSide(color: _colors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.r16)),
        textStyle: textTheme.labelLarge,
        padding: EdgeInsets.symmetric(horizontal: AppSize.w20),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _text.link,
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.r12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _colors.surfaceMuted,
      hintStyle: textTheme.bodyMedium?.copyWith(color: _text.muted),
      contentPadding: EdgeInsets.symmetric(horizontal: AppSize.w16, vertical: AppSize.h14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSize.r12),
        borderSide: BorderSide(color: _colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSize.r12),
        borderSide: BorderSide(color: _colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSize.r12),
        borderSide: BorderSide(color: _colors.primary, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.r16)),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    extensions: <ThemeExtension<dynamic>>[_colors, _text],
  );
}();
