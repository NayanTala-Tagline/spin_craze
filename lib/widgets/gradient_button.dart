import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flutter/material.dart';
import 'package:spin_craze/extension/ext_localization.dart';

/// Gradient button with top glow highlight effect.
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final Widget? trailingIcon;
  final double? height;
  final double? borderRadius;
  final Gradient? gradient;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.height,
    this.borderRadius,
    this.gradient,
    this.textStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? AppSize.h48;
    final primaryGradient = gradient ?? context.themeColors.primaryGradient;
    final double br = borderRadius ?? 10;

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: effectiveHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: primaryGradient,
          borderRadius: BorderRadius.circular(br),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GlowPainter(borderRadius: br),
              ),
            ),
            Center(
              child: Padding(
                padding: padding ?? EdgeInsets.symmetric(horizontal: AppSize.w16),
                child: isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.themeTextColors.primary,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            icon!,
                            SizedBox(width: AppSize.w8),
                          ],
                          Flexible(
                            child: Text(
                              text,
                              strutStyle: StrutStyle(
                                fontSize: AppSize.sp15,
                                height: 1.1,
                                forceStrutHeight: true,
                              ),
                              style: textStyle ??
                                  context.textTheme.bodyLarge?.copyWith(
                                    color: context.themeTextColors.primary,
                                    fontSize: AppSize.sp15,
                                  ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (trailingIcon != null) ...[
                            SizedBox(width: AppSize.w5),
                            trailingIcon!,
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double borderRadius;

  _GlowPainter({required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    const highlightHeight = 1.8;
    final highlightRect = Rect.fromCenter(
      center: Offset(size.width / 2, highlightHeight / 2 + 0.5),
      width: size.width * 0.85,
      height: highlightHeight,
    );

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(highlightRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);

    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, const Radius.circular(1)),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius;
  }
}
