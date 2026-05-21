import 'package:spin_craze/res/theme_colors.dart';
import 'package:spin_craze/res/theme_dark.dart' show buildTextTheme;
import 'package:spin_craze/res/theme_text_colors.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flutter/material.dart';

// ClipEarn is dark-first; the light theme inverts surfaces while keeping
// brand cyan/purple/coin tokens identical so screens stay on-brand.

const _colors = ThemeColors(
  background: Color(0xFFF2F9FF),
  surface: Color(0xFFFFFFFF),
  surfaceMuted: Color(0xFFE6F3FB),
  card: Color(0xFFFFFFFF),
  cardElevated: Color(0xFFF7FBFE),
  primary: Color(0xFF00B7FF),
  primaryDeep: Color(0xFF005B80),
  primaryLight: Color(0xFF65D3FF),
  secondary: Color(0xFFA86CFF),
  accent: Color(0xFFFF5183),
  coin: Color(0xFFFFD84D),
  coinDeep: Color(0xFFFF8C24),
  success: Color(0xFF2BB673),
  warning: Color(0xFFFF8C24),
  error: Color(0xFFFF5183),
  info: Color(0xFF00B7FF),
  border: Color(0xFFDEF1FF),
  divider: Color(0xFFE6F3FB),
  shadow: Color(0x14081821),
  scrim: Color(0x99000000),
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
    colors: [Color(0xFFF2F9FF), Color(0xFFE3F2FD)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
);

const _text = ThemeTextColors(
  primary: Color(0xFF05131B),
  secondary: Color(0xB305131B),
  muted: Color(0x8005131B),
  disabled: Color(0x4D05131B),
  inverse: Color(0xFFFFFFFF),
  onPrimary: Color(0xFFFFFFFF),
  onAccent: Color(0xFFFFFFFF),
  link: Color(0xFF005B80),
  success: Color(0xFF2BB673),
  warning: Color(0xFFFF8C24),
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
