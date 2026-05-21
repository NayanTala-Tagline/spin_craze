import 'dart:async';

import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flutter/material.dart';
import 'package:spin_craze/extension/ext_localization.dart';

/// Visual style for [AppButton].
enum AppButtonVariant {
  /// Solid cyan fill (default CTA).
  primary,

  /// Cyan-blue gradient fill — used for hero CTAs in Figma.
  gradient,

  /// Purple/pink gradient — used on Spin/Quiz screens.
  accentGradient,

  /// Outline only, transparent background.
  outline,

  /// No fill, no border — link-style.
  ghost,
}

/// Size variant for [AppButton].
enum AppButtonSize { small, medium, large }

/// The single button primitive used across the app.
///
/// Wraps a [Material] + [InkWell] so it gets correct ripple/press feedback,
/// debounces taps for 500 ms to prevent double-fires, and supports loading,
/// disabled, leading/trailing icons, and full/intrinsic width.
class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    super.key,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.leading,
    this.trailing,
    this.isLoading = false,
    this.isDisabled = false,
    this.expand = true,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? leading;
  final Widget? trailing;
  final bool isLoading;
  final bool isDisabled;

  /// When `true` the button stretches to fill its parent's width.
  final bool expand;

  /// Override the default radius for this size.
  final double? borderRadius;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  Timer? _debounce;
  bool _locked = false;

  void _handleTap() {
    if (_locked || widget.isLoading || widget.isDisabled) return;
    _locked = true;
    widget.onPressed?.call();
    _debounce = Timer(const Duration(milliseconds: 500), () => _locked = false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // ── Spec helpers ────────────────────────────────────────────────────────────

  double get _height => switch (widget.size) {
        AppButtonSize.small => AppSize.h36,
        AppButtonSize.medium => AppSize.h48,
        AppButtonSize.large => AppSize.h56,
      };

  EdgeInsets get _padding => switch (widget.size) {
        AppButtonSize.small => EdgeInsets.symmetric(horizontal: AppSize.w16),
        AppButtonSize.medium => EdgeInsets.symmetric(horizontal: AppSize.w20),
        AppButtonSize.large => EdgeInsets.symmetric(horizontal: AppSize.w24),
      };

  TextStyle? _labelStyle(BuildContext context) {
    final base = switch (widget.size) {
      AppButtonSize.small => context.textTheme.labelMedium,
      AppButtonSize.medium => context.textTheme.labelLarge,
      AppButtonSize.large => context.textTheme.labelLarge?.copyWith(fontSize: AppSize.sp18),
    };
    return base?.copyWith(color: _foreground(context));
  }

  Color _foreground(BuildContext context) {
    if (widget.isDisabled) return context.themeTextColors.disabled;
    return switch (widget.variant) {
      AppButtonVariant.primary ||
      AppButtonVariant.gradient ||
      AppButtonVariant.accentGradient =>
        context.themeTextColors.onPrimary,
      AppButtonVariant.outline => context.themeColors.primary,
      AppButtonVariant.ghost => context.themeTextColors.link,
    };
  }

  BoxDecoration _decoration(BuildContext context) {
    final colors = context.themeColors;
    final radius = BorderRadius.circular(widget.borderRadius ?? AppSize.r16);

    if (widget.isDisabled) {
      return BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: radius,
        border: Border.all(color: colors.border),
      );
    }

    return switch (widget.variant) {
      AppButtonVariant.primary => BoxDecoration(
          color: colors.primary,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.35),
              blurRadius: AppSize.r20,
              offset: Offset(0, AppSize.h6),
            ),
          ],
        ),
      AppButtonVariant.gradient => BoxDecoration(
          gradient: colors.primaryGradient,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.35),
              blurRadius: AppSize.r24,
              offset: Offset(0, AppSize.h8),
            ),
          ],
        ),
      AppButtonVariant.accentGradient => BoxDecoration(
          gradient: colors.purpleGradient,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: colors.secondary.withValues(alpha: 0.35),
              blurRadius: AppSize.r24,
              offset: Offset(0, AppSize.h8),
            ),
          ],
        ),
      AppButtonVariant.outline => BoxDecoration(
          color: Colors.transparent,
          borderRadius: radius,
          border: Border.all(color: colors.primary, width: 1.5),
        ),
      AppButtonVariant.ghost => BoxDecoration(
          color: Colors.transparent,
          borderRadius: radius,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius ?? AppSize.r16);

    final child = widget.isLoading
        ? SizedBox(
            height: AppSize.sp20,
            width: AppSize.sp20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_foreground(context)),
            ),
          )
        : Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                SizedBox(width: AppSize.w8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _labelStyle(context),
                ),
              ),
              if (widget.trailing != null) ...[
                SizedBox(width: AppSize.w8),
                widget.trailing!,
              ],
            ],
          );

    final container = Container(
      height: _height,
      width: widget.expand ? double.infinity : null,
      padding: _padding,
      alignment: Alignment.center,
      decoration: _decoration(context),
      child: child,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: (widget.isDisabled || widget.isLoading) ? null : _handleTap,
        child: container,
      ),
    );
  }
}
