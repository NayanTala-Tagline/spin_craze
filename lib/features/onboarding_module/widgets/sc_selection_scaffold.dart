import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ad_manager/ad_manager.dart';
import 'package:spin_craze/features/onboarding_module/widgets/sc_ad_slot.dart';
import 'package:spin_craze/features/onboarding_module/widgets/sc_onboarding_background.dart';
import 'package:spin_craze/features/onboarding_module/widgets/sc_onboarding_step_indicator.dart';
import 'package:spin_craze/gen/fonts.gen.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/widgets/gradient_button.dart';

/// Shared animated layout for the post-language onboarding selection screens
/// (country / currency / favourite games).
///
/// Owns the light backdrop, a 3-step indicator, the staggered entrance
/// animations, the Next button (with inline loader) and the bottom [ScAdSlot].
/// Each screen supplies its [title], [subtitle] and the scrollable [child]
/// that holds the actual list / chips.
class ScSelectionScaffold extends StatefulWidget {
  const ScSelectionScaffold({
    super.key,
    required this.stepIndex,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.nextLabel,
    required this.onNext,
    this.headerAction,
    this.nativeAd,
    this.isLoading = false,
  });

  /// 0-based index within the 3-step selection sub-flow.
  final int stepIndex;
  final String title;
  final String subtitle;

  /// The screen body (typically an [Expanded] list or chip wrap).
  final Widget child;

  final String nextLabel;
  final VoidCallback onNext;

  /// Optional trailing widget in the header row (e.g. a "Skip" or counter).
  final Widget? headerAction;

  final InlineAdManager? nativeAd;

  /// When true the Next button shows a spinner and ignores taps.
  final bool isLoading;

  static const _titleColor = Color(0xFF0A1A33);
  static const _bodyColor = Color(0xFF55617A);
  static const _nextGradient = LinearGradient(
    colors: [Color(0xFF1B4FF5), Color(0xFF0034D9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const _statusBarStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  @override
  State<ScSelectionScaffold> createState() => _ScSelectionScaffoldState();
}

class _ScSelectionScaffoldState extends State<ScSelectionScaffold>
    with SingleTickerProviderStateMixin {
  static const _stepCount = 7;

  late final AnimationController _ctrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _bodyFade;
  late final Animation<Offset> _bodySlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _headerFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(-0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    ));

    _bodyFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 0.75, curve: Curves.easeOut),
    );
    _bodySlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic),
    ));

    _buttonFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.30),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    ));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ScSelectionScaffold._statusBarStyle,
      child: ScOnboardingBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSize.h12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSize.w24),
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: Row(
                        children: [
                          ScOnboardingStepIndicator(
                            currentPage: widget.stepIndex,
                            pageCount: _stepCount,
                          ),
                          const Spacer(),
                          if (widget.headerAction != null) widget.headerAction!,
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSize.h20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSize.w24),
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontFamily: FontFamily.sFPro,
                              fontWeight: FontWeight.w800,
                              fontSize: AppSize.sp24,
                              color: ScSelectionScaffold._titleColor,
                              letterSpacing: 0.1,
                            ),
                          ),
                          SizedBox(height: AppSize.h8),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontFamily: FontFamily.sFPro,
                              fontWeight: FontWeight.w400,
                              fontSize: AppSize.sp14,
                              height: 1.5,
                              color: ScSelectionScaffold._bodyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSize.h18),
                Expanded(
                  child: FadeTransition(
                    opacity: _bodyFade,
                    child: SlideTransition(
                      position: _bodySlide,
                      child: widget.child,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSize.w24,
                    AppSize.h12,
                    AppSize.w24,
                    0,
                  ),
                  child: FadeTransition(
                    opacity: _buttonFade,
                    child: SlideTransition(
                      position: _buttonSlide,
                      child: GradientButton(
                        text: widget.nextLabel,
                        onPressed: widget.onNext,
                        isLoading: widget.isLoading,
                        height: AppSize.h54,
                        borderRadius: 30,
                        gradient: ScSelectionScaffold._nextGradient,
                        textStyle: TextStyle(
                          fontFamily: FontFamily.sFPro,
                          fontWeight: FontWeight.w700,
                          fontSize: AppSize.sp17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                ScAdSlot(ad: widget.nativeAd),
                SizedBox(height: AppSize.h12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
