import 'dart:math' as math;

import 'package:spin_craze/features/auth_module/provider/auth_provider.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/gen/fonts.gen.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
// Shared with the onboarding / language redesign. Kept local so the rest of
// the app (still on the dark theme) is untouched.
const _bgGradient = LinearGradient(
  colors: [Color(0xFFF3F7FF), Color(0xFFE2ECFF)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);
const _titleColor = Color(0xFF0A1A33);
const _bodyColor = Color(0xFF55617A);
const _accentBlue = Color(0xFF1B4FF5);
const _accentBlueDeep = Color(0xFF0034D9);
const _pillBorder = Color(0xFFB2D3FF);
const _pillTextColor = Color(0xFF3D3E40);
const _innerShadowColor = Color(0xD4B0C3F8);
const _statusBarStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsManager.instance.logScreenView(
      screenName: 'login',
      screenClass: 'LoginScreen',
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _statusBarStyle,
      child: ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const _LoginBody(),
      ),
    );
  }
}

class _LoginBody extends StatefulWidget {
  const _LoginBody();

  @override
  State<_LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<_LoginBody>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineFade;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _googleFade;
  late final Animation<Offset> _googleSlide;
  late final Animation<double> _guestFade;
  late final Animation<Offset> _guestSlide;
  late final Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoFade = _interval(0.00, 0.30, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.78, end: 1.0).animate(
      _interval(0.00, 0.35, curve: Curves.easeOutBack),
    );

    _titleFade = _interval(0.15, 0.45, curve: Curves.easeOut);
    _titleSlide = _slide(0.15, 0.45, dy: 0.30);

    _taglineFade = _interval(0.25, 0.55, curve: Curves.easeOut);

    _cardFade = _interval(0.35, 0.70, curve: Curves.easeOut);
    _cardSlide = _slide(0.35, 0.70, dy: 0.22);

    _googleFade = _interval(0.55, 0.85, curve: Curves.easeOut);
    _googleSlide = _slide(0.55, 0.85, dy: 0.30);

    _guestFade = _interval(0.65, 0.95, curve: Curves.easeOut);
    _guestSlide = _slide(0.65, 0.95, dy: 0.30);

    _footerFade = _interval(0.78, 1.00, curve: Curves.easeOut);

    _entranceCtrl.forward();
  }

  CurvedAnimation _interval(double begin, double end, {required Curve curve}) {
    return CurvedAnimation(
      parent: _entranceCtrl,
      curve: Interval(begin, end, curve: curve),
    );
  }

  Animation<Offset> _slide(double begin, double end, {required double dy}) {
    return Tween<Offset>(
      begin: Offset(0, dy),
      end: Offset.zero,
    ).animate(_interval(begin, end, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _bgGradient),
      child: Stack(
        children: [
          const Positioned.fill(child: _FloatingParticles()),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSize.w24),
                child: Column(
              children: [
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: const _AnimatedLogo(),
                  ),
                ),
                SizedBox(height: AppSize.h22),
                FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: Text(
                      'Spin Craze',
                      style: TextStyle(
                        fontFamily: FontFamily.sFPro,
                        fontWeight: FontWeight.w800,
                        fontSize: AppSize.sp32,
                        letterSpacing: 1.6,
                        color: _titleColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSize.h10),
                FadeTransition(
                  opacity: _taglineFade,
                  child: const _Tagline(
                    watch: 'WATCH',
                    earn: 'EARN',
                    play: 'PLAY',
                  ),
                ),
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _cardFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: _WelcomeCard(
                      title: 'Welcome',
                      subtitle: 'Sign in to access your wallet',
                      googleFade: _googleFade,
                      googleSlide: _googleSlide,
                      guestFade: _guestFade,
                      guestSlide: _guestSlide,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: _footerFade,
                  child: const _Footer(
                    leadingText: 'By continuing, you agree to our',
                    termsText: 'Terms',
                    privacyText: 'Privacy Policy',
                  ),
                ),
                    SizedBox(height: AppSize.h8),
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

// ── Logo ─────────────────────────────────────────────────────────────────────

class _AnimatedLogo extends StatefulWidget {
  const _AnimatedLogo();

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _haloCtrl;
  late final Animation<double> _floatY;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _floatY = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _haloCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _haloCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSize.w160,
      height: AppSize.w160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _haloCtrl,
            builder: (context, _) {
              return CustomPaint(
                size: Size(AppSize.w160, AppSize.w160),
                painter: _HaloPainter(phase: _haloCtrl.value),
              );
            },
          ),
          AnimatedBuilder(
            animation: _floatY,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatY.value),
                child: child,
              );
            },
            child: Container(
              width: AppSize.w110,
              height: AppSize.w110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSize.r28),
                border: Border.all(color: _pillBorder, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: _accentBlue.withValues(alpha: 0.22),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: const Offset(0, 14),
                  ),
                  const BoxShadow(
                    color: _innerShadowColor,
                    blurRadius: 10,
                    blurStyle: BlurStyle.inner,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(AppSize.w16),
                child: Assets.images.logo.image(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  _HaloPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    for (var i = 0; i < 2; i++) {
      final p = (phase + i * 0.5) % 1.0;
      final radius = maxR * (0.42 + p * 0.55);
      final alpha = (0.30 * (1.0 - p)).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = _accentBlue.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HaloPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

// ── Tagline (WATCH ◇ EARN ◇ PLAY) ───────────────────────────────────────────

class _Tagline extends StatelessWidget {
  const _Tagline({
    required this.watch,
    required this.earn,
    required this.play,
  });

  final String watch;
  final String earn;
  final String play;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chip(watch),
        const _Diamond(),
        _chip(earn),
        const _Diamond(),
        _chip(play),
      ],
    );
  }

  Widget _chip(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: FontFamily.sFPro,
        fontWeight: FontWeight.w600,
        fontSize: AppSize.sp12,
        letterSpacing: 2.4,
        color: _bodyColor,
      ),
    );
  }
}

class _Diamond extends StatelessWidget {
  const _Diamond();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.w8),
      child: Transform.rotate(
        angle: math.pi / 4,
        child: Container(
          width: AppSize.w6,
          height: AppSize.w6,
          decoration: BoxDecoration(
            color: _accentBlue,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ),
    );
  }
}

// ── Welcome card ────────────────────────────────────────────────────────────

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.title,
    required this.subtitle,
    required this.googleFade,
    required this.googleSlide,
    required this.guestFade,
    required this.guestSlide,
  });

  final String title;
  final String subtitle;
  final Animation<double> googleFade;
  final Animation<Offset> googleSlide;
  final Animation<double> guestFade;
  final Animation<Offset> guestSlide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSize.w22,
        AppSize.h24,
        AppSize.w22,
        AppSize.h20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSize.r24),
        border: Border.all(color: _pillBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: _innerShadowColor,
            blurRadius: 12,
            blurStyle: BlurStyle.inner,
          ),
          BoxShadow(
            color: Color(0x1A1B4FF5),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: FontFamily.sFPro,
              fontWeight: FontWeight.w800,
              fontSize: AppSize.sp22,
              color: _titleColor,
            ),
          ),
          SizedBox(height: AppSize.h6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontFamily.sFPro,
              fontWeight: FontWeight.w400,
              fontSize: AppSize.sp14,
              color: _bodyColor,
            ),
          ),
          SizedBox(height: AppSize.h22),
          FadeTransition(
            opacity: googleFade,
            child: SlideTransition(
              position: googleSlide,
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) => _PrimaryButton(
                  label: 'Continue with Google',
                  isLoading: auth.isGoogleLoading,
                  isDisabled: auth.isGuestLoading,
                  leading: Assets.images.googleLogo.image(
                    height: AppSize.sp18,
                    width: AppSize.sp18,
                  ),
                  onPressed: () => _handleGoogle(context, auth),
                ),
              ),
            ),
          ),
          SizedBox(height: AppSize.h12),
          FadeTransition(
            opacity: guestFade,
            child: SlideTransition(
              position: guestSlide,
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) => _SecondaryButton(
                  label: 'Continue as Guest',
                  isLoading: auth.isGuestLoading,
                  isDisabled: auth.isGoogleLoading,
                  leading: Icon(
                    Icons.person_outline_rounded,
                    size: AppSize.sp18,
                    color: _titleColor,
                  ),
                  onPressed: () => _handleGuest(context, auth),
                ),
              ),
            ),
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final message = auth.errorMessage;
              if (message == null) return const SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.only(top: AppSize.h12),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FontFamily.sFPro,
                    fontWeight: FontWeight.w500,
                    fontSize: AppSize.sp12,
                    color: const Color(0xFFD0334A),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogle(BuildContext context, AuthProvider auth) async {
    AnalyticsManager.instance.logEvent(
      name: 'login_attempt',
      parameters: {'method': 'google'},
    );
    final success = await auth.signInWithGoogle();
    if (success) {
      AnalyticsManager.instance.logEvent(
        name: 'login_success',
        parameters: {'method': 'google'},
      );
      if (context.mounted) context.goNamed(AppRoutes.home);
    } else {
      AnalyticsManager.instance.logEvent(
        name: 'login_failed',
        parameters: {
          'method': 'google',
          'error': auth.errorMessage ?? 'unknown',
        },
      );
    }
  }

  Future<void> _handleGuest(BuildContext context, AuthProvider auth) async {
    AnalyticsManager.instance.logEvent(
      name: 'login_attempt',
      parameters: {'method': 'guest'},
    );
    final success = await auth.continueAsGuest();
    if (success) {
      AnalyticsManager.instance.logEvent(
        name: 'login_success',
        parameters: {'method': 'guest'},
      );
      if (context.mounted) context.goNamed(AppRoutes.home);
    } else {
      AnalyticsManager.instance.logEvent(
        name: 'login_failed',
        parameters: {
          'method': 'guest',
          'error': auth.errorMessage ?? 'unknown',
        },
      );
    }
  }
}

// ── Buttons ─────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.leading,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
  });

  final String label;
  final Widget leading;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _shimmerCtrl;

  bool get _interactive => !widget.isDisabled && !widget.isLoading;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(30);
    return GestureDetector(
      onTapDown: _interactive ? (_) => setState(() => _pressed = true) : null,
      onTapUp: _interactive ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: _interactive ? () => setState(() => _pressed = false) : null,
      onTap: _interactive ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: widget.isDisabled ? 0.55 : 1.0,
          duration: const Duration(milliseconds: 180),
          child: Container(
            height: AppSize.h54,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_accentBlue, _accentBlueDeep],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: _accentBlue.withValues(alpha: 0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_interactive)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _shimmerCtrl,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _ShimmerPainter(
                              progress: _shimmerCtrl.value,
                            ),
                          );
                        },
                      ),
                    ),
                  widget.isLoading
                      ? SizedBox(
                          width: AppSize.sp20,
                          height: AppSize.sp20,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            widget.leading,
                            SizedBox(width: AppSize.w10),
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontFamily: FontFamily.sFPro,
                                fontWeight: FontWeight.w700,
                                fontSize: AppSize.sp16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatefulWidget {
  const _SecondaryButton({
    required this.label,
    required this.leading,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
  });

  final String label;
  final Widget leading;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _pressed = false;

  bool get _interactive => !widget.isDisabled && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _interactive ? (_) => setState(() => _pressed = true) : null,
      onTapUp: _interactive ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: _interactive ? () => setState(() => _pressed = false) : null,
      onTap: _interactive ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: widget.isDisabled ? 0.55 : 1.0,
          duration: const Duration(milliseconds: 180),
          child: Container(
            height: AppSize.h54,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _pillBorder, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: _innerShadowColor,
                  blurRadius: 7.5,
                  blurStyle: BlurStyle.inner,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: widget.isLoading
                ? SizedBox(
                    width: AppSize.sp20,
                    height: AppSize.sp20,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_accentBlue),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.leading,
                      SizedBox(width: AppSize.w10),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontFamily: FontFamily.sFPro,
                          fontWeight: FontWeight.w600,
                          fontSize: AppSize.sp16,
                          color: _pillTextColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Footer ──────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({
    required this.leadingText,
    required this.termsText,
    required this.privacyText,
  });

  final String leadingText;
  final String termsText;
  final String privacyText;

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(
      fontFamily: FontFamily.sFPro,
      fontWeight: FontWeight.w600,
      fontSize: AppSize.sp12,
      color: _accentBlue,
      decoration: TextDecoration.underline,
      decorationColor: _accentBlue,
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontFamily: FontFamily.sFPro,
          fontWeight: FontWeight.w400,
          fontSize: AppSize.sp12,
          color: _bodyColor,
        ),
        children: [
          TextSpan(text: '$leadingText '),
          TextSpan(
            text: termsText,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchUrl(
                    RemoteConfigService.instance.termsAndConditions,
                  ),
          ),
          const TextSpan(text: ' & '),
          TextSpan(
            text: privacyText,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchUrl(
                    RemoteConfigService.instance.privacyPolicyUrl,
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    AnalyticsManager.instance.logEvent(
      name: 'login_policy_link_tap',
      parameters: {'url': url},
    );
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// ── Floating background particles ────────────────────────────────────────────

class _FloatingParticles extends StatefulWidget {
  const _FloatingParticles();

  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    final rng = math.Random(42);
    _particles = List.generate(16, (_) => _Particle.random(rng));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _ParticlePainter(
              particles: _particles,
              phase: _ctrl.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.startY,
    required this.size,
    required this.driftSpeed,
    required this.alphaBase,
    required this.phaseOffset,
    required this.swayAmplitude,
  });

  factory _Particle.random(math.Random rng) {
    return _Particle(
      x: rng.nextDouble(),
      startY: rng.nextDouble(),
      size: 3.0 + rng.nextDouble() * 5.0,
      driftSpeed: 0.4 + rng.nextDouble() * 0.7,
      alphaBase: 0.25 + rng.nextDouble() * 0.30,
      phaseOffset: rng.nextDouble(),
      swayAmplitude: 6.0 + rng.nextDouble() * 14.0,
    );
  }

  final double x;
  final double startY;
  final double size;
  final double driftSpeed;
  final double alphaBase;
  final double phaseOffset;
  final double swayAmplitude;
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Soft white band sweeps left-to-right, then waits off-screen before
    // looping. The "wait" comes from the band travelling beyond the right
    // edge before it wraps.
    final bandWidth = size.width * 0.45;
    final travel = size.width + bandWidth * 2;
    final cx = -bandWidth + progress * travel;

    final shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0x00FFFFFF),
        Color(0x3DFFFFFF),
        Color(0x00FFFFFF),
      ],
      stops: [0.0, 0.5, 1.0],
    ).createShader(
      Rect.fromLTWH(cx - bandWidth / 2, 0, bandWidth, size.height),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.particles, required this.phase});

  final List<_Particle> particles;
  final double phase;

  static const _color = _accentBlue;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Vertical drift upward, wrapping seamlessly.
      final yT = (p.startY + 1.0 - phase * p.driftSpeed) % 1.0;
      final y = yT * size.height;

      // Subtle horizontal sway.
      final swayT = (phase + p.phaseOffset) * 2 * math.pi;
      final x = p.x * size.width + math.sin(swayT) * p.swayAmplitude;

      // Alpha pulse — particles fade in/out as they drift.
      final pulse = (0.6 + 0.4 * math.sin(swayT * 1.3));
      final alpha = (p.alphaBase * pulse).clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(x, y),
        p.size / 2,
        Paint()..color = _color.withValues(alpha: alpha * 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.phase != phase;
}
