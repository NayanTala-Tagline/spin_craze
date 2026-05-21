import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/widgets/back_btn.dart';
import 'package:flutter/material.dart';
import 'package:spin_craze/extension/ext_localization.dart';

/// Top bar matching the Figma `Home` frame.
///
/// Visual recipe (Figma node `20:1901`, 375×120):
///   - solid dark-teal panel
///   - corners flat on top, 24 px radius on the bottom-left and bottom-right
///
/// Lays out three optional slots inside the safe area: [leading] · [center] ·
/// [trailing]. When [title] is provided instead of [center], the bar shows a
/// back button + title + actions in a more conventional layout.
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    this.leading,
    this.center,
    this.trailing,
    this.title,
    this.subtitle,
    this.actions,
    this.showBack = false,
    this.onBack,
    this.height = 120,
    this.radius = 24,
  });

  /// Left slot. Defaults to [AppBackButton] when [showBack] is true.
  final Widget? leading;

  /// Center slot — full widget. Takes precedence over [title].
  final Widget? center;

  /// Right slot.
  final Widget? trailing;

  /// Optional title shown in the center when [center] is null.
  final String? title;
  final String? subtitle;

  /// Optional trailing widgets shown after [trailing].
  final List<Widget>? actions;

  final bool showBack;
  final VoidCallback? onBack;

  /// Total bar height including the area behind the status bar.
  final double height;

  /// Radius for the bottom corners.
  final double radius;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final leadingWidget =
        leading ?? (showBack ? AppBackButton(onTap: onBack) : null);
    final trailingWidgets = <Widget>[?trailing, ...?actions];

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── 1. Solid dark-teal panel ───────────────────────────────────────
          Positioned.fill(child: _Panel(radius: radius)),

          // ── 2. Content (inside safe area) ──────────────────────────────────
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSize.w16,
                  vertical: AppSize.h8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ?leadingWidget,
                    Expanded(
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            center ??
                                _TitleBlock(title: title, subtitle: subtitle),
                            (leadingWidget != null && trailingWidgets.isNotEmpty)
                                ? SizedBox.shrink()
                                : leadingWidget != null
                                ? SizedBox(width: AppSize.w36)
                                : SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ),
                    if (trailingWidgets.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: trailingWidgets,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Panel extends StatelessWidget {
  const _Panel({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.only(
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
    final glow = context.themeColors.primary;

    return ClipRRect(
      borderRadius: shape,
      child: Stack(
        children: [
          // Base fill — dark teal matching Figma `#00B7FF @ 16%` composited
          // over the app background.
          const Positioned.fill(child: ColoredBox(color: Color(0xFF0E3E4F))),
          // Bottom-left corner glow (Figma: cyan circle r=30, blur 30 at 13,102)
          Positioned(
            left: -AppSize.w30,
            bottom: -AppSize.h30,
            child: _CornerGlow(color: glow),
          ),
          // Bottom-right corner glow (Figma: cyan circle r=30, blur 30 at 361,102)
          Positioned(
            right: -AppSize.w30,
            bottom: -AppSize.h30,
            child: _CornerGlow(color: glow),
          ),
        ],
      ),
    );
  }
}

class _CornerGlow extends StatelessWidget {
  const _CornerGlow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    // Soft radial gradient — bright cyan at the centre fading to transparent
    // by the edge, mimicking the Figma feGaussianBlur(stdDeviation=30) on a
    // 60×60 cyan disc. Sized 120×120 so the falloff sits well inside the
    // panel after the corner offset.
    return IgnorePointer(
      child: Container(
        width: AppSize.sp120,
        height: AppSize.sp120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            radius: 0.5, // increase spread
            colors: [
              color.withValues(alpha: 0.5), // reduce opacity
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({this.title, this.subtitle});

  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    if (title == null && subtitle == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Text(
            title!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleLarge,
          ),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodySmall,
          ),
      ],
    );
  }
}
