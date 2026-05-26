import 'package:ad_manager/ad_manager.dart';
import 'package:spin_craze/features/onboarding_module/onboarding_card.dart';
import 'package:spin_craze/features/onboarding_module/widgets/onboarding_background.dart';
import 'package:spin_craze/features/onboarding_module/widgets/onboarding_step_indicator.dart';
import 'package:spin_craze/features/onboarding_module/widgets/onboarding_ring_decor.dart';
import 'package:spin_craze/gen/fonts.gen.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/widgets/bottom_ads_widget.dart';
import 'package:spin_craze/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared layout for the three onboarding pages.
///
/// Owns the light backdrop, top step indicator, the Next button and the
/// staggered entrance animations so each page only carries per-page data
/// and the ad / analytics / navigation logic.
class OnboardingScaffold extends StatefulWidget {
  const OnboardingScaffold({
    super.key,
    required this.currentIndex,
    required this.image,
    required this.title,
    required this.description,
    required this.nextLabel,
    required this.onNext,
    this.nativeAd,
  });

  final int currentIndex;
  final Widget image;
  final String title;
  final String description;
  final String nextLabel;
  final VoidCallback onNext;
  final NativeAdManager? nativeAd;

  @override
  State<OnboardingScaffold> createState() => _OnboardingScaffoldState();
}

class _OnboardingScaffoldState extends State<OnboardingScaffold>
    with TickerProviderStateMixin {
  static const _pageCount = 4;
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

  late final AnimationController _ctrl;
  late final AnimationController _floatCtrl;
  late final Animation<double> _indicatorFade;
  late final Animation<Offset> _indicatorSlide;
  late final Animation<double> _imageFade;
  late final Animation<double> _imageScale;
  late final Animation<double> _floatY;
  late final Animation<double> _bodyFade;
  late final Animation<Offset> _bodySlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _indicatorFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _indicatorSlide = Tween<Offset>(
      begin: const Offset(-0.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));

    _imageFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.10, 0.60, curve: Curves.easeOut),
    );
    _imageScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.10, 0.60, curve: Curves.easeOutBack),
      ),
    );

    _bodyFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.30, 0.80, curve: Curves.easeOut),
    );
    _bodySlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.30, 0.80, curve: Curves.easeOutCubic),
    ));

    _buttonFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.50, 1.0, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.30),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.50, 1.0, curve: Curves.easeOutCubic),
    ));

    _ctrl.forward();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _floatY = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _statusBarStyle,
      child: OnboardingBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(height: AppSize.h12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSize.w24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FadeTransition(
                      opacity: _indicatorFade,
                      child: SlideTransition(
                        position: _indicatorSlide,
                        child: OnboardingStepIndicator(
                          currentPage: widget.currentIndex,
                          pageCount: _pageCount,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSize.h16),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const OnboardingRingDecor(),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSize.w24,
                          vertical: AppSize.h12,
                        ),
                        child: Center(
                          child: FadeTransition(
                            opacity: _imageFade,
                            child: ScaleTransition(
                              scale: _imageScale,
                              child: AnimatedBuilder(
                                animation: _floatY,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, _floatY.value),
                                    child: child,
                                  );
                                },
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: widget.image,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSize.h16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSize.w24),
                  child: FadeTransition(
                    opacity: _bodyFade,
                    child: SlideTransition(
                      position: _bodySlide,
                      child: OnboardingCard(
                        title: widget.title,
                        description: widget.description,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSize.h28),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSize.w24),
                  child: FadeTransition(
                    opacity: _buttonFade,
                    child: SlideTransition(
                      position: _buttonSlide,
                      child: GradientButton(
                        text: widget.nextLabel,
                        onPressed: widget.onNext,
                        height: AppSize.h54,
                        borderRadius: 30,
                        gradient: _nextGradient,
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
                SizedBox(height: AppSize.h16),
              ],
            ),
          ),
          bottomNavigationBar: BottomAdsWidget(
            key: ValueKey(widget.currentIndex + 1),
            nativeAd: widget.nativeAd,
          ),
        ),
      ),
    );
  }
}
