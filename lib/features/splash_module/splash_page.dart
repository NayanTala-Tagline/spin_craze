import 'dart:async';
import 'dart:ui' as ui;

import 'package:ad_manager/ad_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/res/theme_colors.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/services/ad_repository_service.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/logger.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:spin_craze/widgets/app_button.dart';

/// First screen the app shows. Plays a hand-built logo animation while it:
///   • checks connectivity (with a no-internet retry / auto-reconnect view),
///   • optionally shows the `splash_app_open` full-screen ad,
///   • preloads Onboarding screen 1's native ad and hands it off on navigation,
///   • then routes to home or onboarding.
///
/// All animations are built from raw [AnimationController]s — no animation
/// package is used.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// Floor on splash duration so the animation has room to play even when the
  /// ad resolves instantly (disabled / cached / failed).
  static const _minSplashDuration = Duration(milliseconds: 1800);

  /// Ad load timeout. After this we stop waiting on `future()` and move on.
  static const _adLoadTimeout = Duration(seconds: 6);

  /// Wall-clock ceiling. No matter what happens (RC stalls, a callback never
  /// fires, native code hangs), the user navigates away after this.
  static const _maxSplashDuration = Duration(seconds: 12);

  // ── Animation ──────────────────────────────────────────────────────────────
  late final AnimationController _introController;
  late final AnimationController _floatController;
  late final AnimationController _shimmerController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoBlur;
  late final Animation<double> _floatOffset;

  // ── Ads ──────────────────────────────────────────────────────────────────
  FullScreenAdManager? _fullScreen;

  /// Native ad for Onboarding screen 1, preloaded here so the next screen
  /// renders an ad instead of an empty slot. Ownership is handed off via
  /// `extra` on navigation — this screen does NOT dispose it after handoff.
  InlineAdManager? _onboardingNative1;

  // ── Flow state ─────────────────────────────────────────────────────────────
  Timer? _safetyTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _navigated = false;
  bool _showNoInternet = false;
  bool _retrying = false;
  DateTime _startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _setUpAnimations();
    AdRepository.showConsentUMP();
    unawaited(_bootstrap());
  }

  void _setUpAnimations() {
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    _logoScale = Tween<double>(begin: 0.55, end: 1).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );
    _logoOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    _logoBlur = Tween<double>(begin: 14, end: 0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _floatOffset = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Kick off the looping ambient motion only once the entrance has played,
    // so the intro reads cleanly.
    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _floatController.repeat(reverse: true);
        _shimmerController.repeat();
      }
    });
    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    _safetyTimer?.cancel();
    _connectivitySub?.cancel();
    unawaited(_fullScreen?.dispose());
    // Safety-dispose if we never handed off (e.g. torn down before nav).
    unawaited(_onboardingNative1?.dispose());
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FLOW
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _bootstrap() async {
    final hasNet = await _hasInternet();
    if (!mounted) return;

    if (!hasNet) {
      _watchForReconnect();
      setState(() => _showNoInternet = true);
      return;
    }
    _startAdFlow();
  }

  void _startAdFlow() {
    _startedAt = DateTime.now();
    _safetyTimer = Timer(_maxSplashDuration, () {
      '⚠️ splash safety timer fired — forcing navigate'.logD;
      unawaited(_goNext());
    });
    if (!_shouldGoHome()) {
      _preloadOnboarding1Native();
    }
    unawaited(_runFullScreenFlow());
  }

  /// Kicks off the load for Onboarding screen 1's native so it's ready (or in
  /// flight) by the time the user lands there. Handed off in [_goNext].
  void _preloadOnboarding1Native() {
    final data = RemoteConfigService.instance.onboardingNative1;
    if (!data.enabled && data.adType != AdType.custom) return;
    if (data.adId.isEmpty && data.adType != AdType.custom) return;
    _onboardingNative1 = InlineAdManager(adData: data);
    unawaited(_onboardingNative1!.load());
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.any((r) => r != ConnectivityResult.none);
    } catch (e) {
      '⚠️ connectivity check failed: $e'.logD;
      // If the check itself fails, assume connected and let ad timeouts handle it.
      return true;
    }
  }

  /// Auto-retry the moment the user toggles wifi/mobile back on so they don't
  /// have to mash the Retry button.
  void _watchForReconnect() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      final back = result.any((r) => r != ConnectivityResult.none);
      if (back && _showNoInternet && !_retrying) {
        unawaited(_onRetry());
      }
    });
  }

  Future<void> _onRetry() async {
    if (_retrying) return;
    setState(() => _retrying = true);

    final hasNet = await _hasInternet();
    if (!mounted) return;

    if (!hasNet) {
      setState(() => _retrying = false);
      return;
    }

    // Remote Config likely failed in main() if there was no internet —
    // refetch now that we're back online so ad slots populate.
    try {
      await RemoteConfigService.instance.init();
    } catch (e) {
      '⚠️ RC re-init failed: $e'.logD;
    }
    if (!mounted) return;

    _connectivitySub?.cancel();
    _connectivitySub = null;
    setState(() {
      _showNoInternet = false;
      _retrying = false;
    });
    _startAdFlow();
  }

  Future<void> _runFullScreenFlow() async {
    try {
      final data = RemoteConfigService.instance.splashAppOpen;

      // Remote Config says off (or wasn't fetched at all) — skip the ad.
      if (!data.enabled || data.adId.isEmpty) {
        await _waitForMinSplash();
        unawaited(_goNext());
        return;
      }

      _fullScreen = FullScreenAdManager(
        adData: data,
        openAppCallback: FullScreenContentCallback<AppOpenAd>(
          onAdDismissedFullScreenContent: (_) => unawaited(_goNext()),
          onAdFailedToShowFullScreenContent: (_, _) => unawaited(_goNext()),
        ),
        interstitialCallback: FullScreenContentCallback<InterstitialAd>(
          onAdDismissedFullScreenContent: (_) => unawaited(_goNext()),
          onAdFailedToShowFullScreenContent: (_, _) => unawaited(_goNext()),
        ),
      );

      unawaited(_fullScreen!.load());
      final status = await _fullScreen!.future().timeout(
        _adLoadTimeout,
        onTimeout: () => AdStatus.failed,
      );

      // Always let the splash breathe a moment so the logo animation plays.
      await _waitForMinSplash();
      if (!mounted) return;

      if (status == AdStatus.loaded && (_fullScreen?.isLoaded ?? false)) {
        final shown = await _fullScreen!.show();
        if (!shown) unawaited(_goNext());
        // shown == true → dismiss/fail callback drives navigation.
      } else {
        unawaited(_goNext());
      }
    } catch (e, s) {
      '❌ splash ad flow failed: $e'.logD;
      s.toString().logD;
      unawaited(_goNext());
    }
  }

  Future<void> _waitForMinSplash() async {
    final elapsed = DateTime.now().difference(_startedAt);
    final remaining = _minSplashDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  Future<void> _goNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    _safetyTimer?.cancel();

    if (_shouldGoHome()) {
      // Home doesn't accept the onboarding native — dispose it locally so it
      // doesn't leak waiting for the splash's dispose().
      unawaited(_onboardingNative1?.dispose());
      _onboardingNative1 = null;
      context.goNamed(AppRoutes.home);
      return;
    }

    // Ownership of the preloaded native transfers to Onboarding screen 1.
    final handoff = _onboardingNative1;
    _onboardingNative1 = null;
    context.goNamed(AppRoutes.onboarding1, extra: handoff);
  }

  /// Routing decision after the splash flow:
  ///   • `skip_onboarding` (RC)           → home (always, even on first launch).
  ///   • `show_multiple_onboarding` (RC)  → onboarding (ignore prior completion).
  ///   • otherwise → home if a user session exists, else onboarding.
  bool _shouldGoHome() {
    final rc = RemoteConfigService.instance;
    if (rc.skipOnBoarding) return true;
    if (rc.showMultipleOnboarding) return false;
    return Injector.instance<AppDB>().userModel != null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final logoSize = 190.w;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Assets.images.splashBg.image(fit: BoxFit.cover),
          if (_showNoInternet)
            _NoInternetView(onRetry: _onRetry, retrying: _retrying)
          else
            _buildSplashContent(colors, logoSize),
        ],
      ),
    );
  }

  Widget _buildSplashContent(ThemeColors colors, double logoSize) {
    return Stack(
      children: [
        Center(child: _animatedLogo(logoSize)),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: AppSize.h24),
              child: SizedBox(
                width: AppSize.w120,
                height: AppSize.h3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSize.r3),
                  child: LinearProgressIndicator(
                    minHeight: AppSize.h3,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _animatedLogo(double size) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _introController,
        _floatController,
        _shimmerController,
      ]),
      builder: (context, _) {
        Widget logo = Assets.images.logo.image(
          width: size,
          height: size,
          fit: BoxFit.contain,
        );

        // Moving highlight sweep across the logo.
        logo = ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _shimmerController.value;
            return LinearGradient(
              begin: Alignment(-1 + 2 * t - 0.35, -0.3),
              end: Alignment(-1 + 2 * t + 0.35, 0.3),
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.55),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0, 0.5, 1],
            ).createShader(bounds);
          },
          child: logo,
        );

        // Entrance blur (sigma 14 → 0). Skip the filter once it's ~0 to avoid
        // a needless blur pass for the rest of the screen's life.
        final blur = _logoBlur.value;
        if (blur > 0.05) {
          logo = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: logo,
          );
        }

        return Transform.translate(
          offset: Offset(0, _floatOffset.value),
          child: Opacity(
            opacity: _logoOpacity.value.clamp(0.0, 1.0),
            child: Transform.scale(scale: _logoScale.value, child: logo),
          ),
        );
      },
    );
  }
}

class _NoInternetView extends StatelessWidget {
  const _NoInternetView({required this.onRetry, required this.retrying});

  final VoidCallback onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final textColors = context.themeTextColors;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSize.w24),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSize.w24,
              vertical: AppSize.h28,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppSize.r24),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppSize.w72,
                  height: AppSize.w72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: colors.primaryGradient,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    color: textColors.onPrimary,
                    size: AppSize.sp36,
                  ),
                ),
                SizedBox(height: AppSize.h20),
                Text(
                  'No Internet Connection',
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: textColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: AppSize.sp18,
                  ),
                ),
                SizedBox(height: AppSize.h8),
                Text(
                  'Please check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: textColors.muted,
                    fontSize: AppSize.sp13,
                  ),
                ),
                SizedBox(height: AppSize.h24),
                AppButton(
                  label: retrying ? 'Checking...' : 'Retry',
                  isLoading: retrying,
                  variant: AppButtonVariant.gradient,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
