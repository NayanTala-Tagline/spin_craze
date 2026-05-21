import 'package:spin_craze/gen/fonts.gen.dart';
import 'package:spin_craze/res/theme_colors.dart';
import 'package:spin_craze/res/theme_text_colors.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flutter/material.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
// Source: Figma `ClipEarn (Copy)` — Home (20:1180) and Withdraw (36:695) frames.

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
  primary: Color(0xFFFFFFFF),
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

final ThemeData darkTheme = _buildTheme(
  base: ThemeData.dark(useMaterial3: true),
  colors: _colors,
  textColors: _text,
);

// ── Builder ───────────────────────────────────────────────────────────────────

ThemeData _buildTheme({
  required ThemeData base,
  required ThemeColors colors,
  required ThemeTextColors textColors,
}) {
  final textTheme = buildTextTheme(textColors);

  return base.copyWith(
    colorScheme: ColorScheme.dark(
      primary: colors.primary,
      onPrimary: textColors.onPrimary,
      secondary: colors.secondary,
      onSecondary: textColors.onPrimary,
      surface: colors.surface,
      onSurface: textColors.primary,
      error: colors.error,
      onError: textColors.onPrimary,
    ),
    scaffoldBackgroundColor: colors.background,
    cardColor: colors.card,
    dividerColor: colors.divider,
    shadowColor: colors.shadow,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: textColors.primary),
      titleTextStyle: textTheme.titleLarge,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: textColors.onPrimary,
        disabledBackgroundColor: colors.surfaceMuted,
        disabledForegroundColor: textColors.disabled,
        minimumSize: Size(AppSize.w64, AppSize.h48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.r16)),
        textStyle: textTheme.labelLarge,
        padding: EdgeInsets.symmetric(horizontal: AppSize.w20),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primary,
        disabledForegroundColor: textColors.disabled,
        minimumSize: Size(AppSize.w64, AppSize.h48),
        side: BorderSide(color: colors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.r16)),
        textStyle: textTheme.labelLarge,
        padding: EdgeInsets.symmetric(horizontal: AppSize.w20),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: textColors.link,
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.r12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      hintStyle: textTheme.bodyMedium?.copyWith(color: textColors.muted),
      contentPadding: EdgeInsets.symmetric(horizontal: AppSize.w16, vertical: AppSize.h14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSize.r12),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSize.r12),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSize.r12),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSize.r12),
        borderSide: BorderSide(color: colors.error),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: textColors.primary,
      unselectedLabelColor: textColors.muted,
      labelStyle: textTheme.titleSmall,
      unselectedLabelStyle: textTheme.titleSmall,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: colors.primary, width: 2),
        insets: EdgeInsets.symmetric(horizontal: AppSize.w12),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSize.r16)),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.r20)),
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[colors, textColors],
  );
}

// ── Type scale ────────────────────────────────────────────────────────────────
// Sizes & weights mirror Figma (SF Pro 12 / 14 / 16 / 20 / 36, weights 400/510/590/700).

TextTheme buildTextTheme(ThemeTextColors colors) {
  TextStyle s({required double size, required FontWeight weight, double? height, Color? color}) {
    return TextStyle(
      fontFamily: FontFamily.sFPro,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color ?? colors.primary,
    );
  }

  return TextTheme(
    // Display — coin balance, big counters
    displayLarge: s(size: AppSize.sp36, weight: FontWeight.w700, height: 1.2),
    displayMedium: s(size: AppSize.sp28, weight: FontWeight.w700, height: 1.2),
    // Titles — section headings
    titleLarge: s(size: AppSize.sp20, weight: FontWeight.w700, height: 1.2),
    titleMedium: s(size: AppSize.sp18, weight: FontWeight.w600, height: 1.25),
    titleSmall: s(size: AppSize.sp16, weight: FontWeight.w600, height: 1.2),
    // Body
    bodyLarge: s(size: AppSize.sp16, weight: FontWeight.w400, height: 1.4, color: colors.secondary),
    bodyMedium: s(size: AppSize.sp14, weight: FontWeight.w400, height: 1.4, color: colors.secondary),
    bodySmall: s(size: AppSize.sp12, weight: FontWeight.w400, height: 1.4, color: colors.muted),
    // Labels — buttons, chips, badges
    labelLarge: s(size: AppSize.sp16, weight: FontWeight.w700, height: 1.2),
    labelMedium: s(size: AppSize.sp14, weight: FontWeight.w600, height: 1.2),
    labelSmall: s(size: AppSize.sp12, weight: FontWeight.w600, height: 1.2),
  );
}
