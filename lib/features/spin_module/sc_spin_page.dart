import 'dart:math';

import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/features/spin_module/widgets/sc_wheel_painter.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/services/coin_service.dart';
import 'package:spin_craze/services/reward_ad_service.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:spin_craze/widgets/ad_disclaimer_text.dart';
import 'package:spin_craze/widgets/coin_chip.dart';
import 'package:spin_craze/widgets/common_appbar.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/navigation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:spin_craze/widgets/common_background.dart';
import 'package:flutter/material.dart';

// ── Segment definitions ─────────────────────────────────────────────────────
// Segments are built from Remote Config (`spin_board_reward_values`) so the
// wheel labels and the actual coin reward stay in sync.
// Style alternates between blue-purple gradient and dark-green solid.

const _darkBlue = Color(0xFF3340E8);
const _lightBlue = Color(0xFF6B86FF);

List<ScWheelSegment> _getWheelSegments(BuildContext context) {
  final values = RemoteConfigService.instance.spinBoardRewardValues;
  // Defensive: if RC ever returns an empty list, fall back to a single 0 slot
  // so the painter still has something to render.
  final safeValues = values.isEmpty ? <int>[0] : values;

  return List<ScWheelSegment>.generate(safeValues.length, (i) {
    final value = safeValues[i];
    return ScWheelSegment(
      value,
      displayText: '$value',
      solidColor: i.isEven ? _darkBlue : _lightBlue,
    );
  });
}

// ── ScSpinWheelScreen ─────────────────────────────────────────────────────────

class ScSpinWheelScreen extends StatefulWidget {
  const ScSpinWheelScreen({super.key});

  @override
  State<ScSpinWheelScreen> createState() => _ScSpinWheelScreenState();
}

class _ScSpinWheelScreenState extends State<ScSpinWheelScreen>
    with SingleTickerProviderStateMixin {
  bool _showWelcome = true;
  bool _isSpinning = false;

  late final AnimationController _ctrl;
  Animation<double>? _rotation;
  int _wonCoins = 0;
  final _random = Random();

  /// Accumulated angle so consecutive spins continue from where they ended.
  double _currentAngle = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logScreenView(
      screenName: 'spin_wheel',
      screenClass: 'ScSpinWheelScreen',
    );
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _currentAngle = _rotation?.value ?? _currentAngle;
        setState(() => _isSpinning = false);
        _showCongratsSheet();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    AnalyticsManager.instance.logEvent(name: 'spin_wheel_get_started');
    setState(() => _showWelcome = false);
  }

  void _onSpin() {
    if (_isSpinning) return;
    AnalyticsManager.instance.logEvent(name: 'spin_wheel_spin_tap');

    // Pick a random segment.
    final wheelSegments = _getWheelSegments(context);
    final segmentCount = wheelSegments.length;
    final index = _random.nextInt(segmentCount);
    _wonCoins = wheelSegments[index].label;

    final segAngle = 2 * pi / segmentCount;
    // The pointer is fixed at the top (12 o'clock). Segments are drawn
    // starting from -pi/2 (top) clockwise. To land segment [index] under
    // the pointer the total wheel rotation (mod 2π) must equal:
    //   2π - (index * segAngle + segAngle / 2)
    // Since `_currentAngle` may be non-zero from a previous spin, subtract
    // its modulo so the final resting angle matches the target absolutely.
    final targetAngle = 2 * pi - (segAngle * index + segAngle / 2);
    final currentMod = _currentAngle % (2 * pi);
    var delta = targetAngle - currentMod;
    if (delta < 0) delta += 2 * pi;

    // 5–7 full rotations + land on the target segment.
    final totalAngle = (5 + _random.nextInt(3)) * 2 * pi + delta;

    _rotation = Tween<double>(
      begin: _currentAngle,
      end: _currentAngle + totalAngle,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.reset();
    setState(() => _isSpinning = true);
    _ctrl.forward();
  }

  void _showCongratsSheet() {
    final isLoss = _wonCoins == 0;
    final wonCoins = _wonCoins;

    AnalyticsManager.instance.logEvent(
      name: 'spin_wheel_completed',
      parameters: {'coins_won': wonCoins, 'is_loss': isLoss ? 1 : 0},
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xFF0B1F4D).withValues(alpha: 0.55),
      builder: (sheetCtx) => _ScCongratsDialog(
        coins: wonCoins,
        isLoss: isLoss,
        onClaim: () async {
          sheetCtx.pop();
          if (!isLoss) {
            AnalyticsManager.instance.logEvent(
              name: 'spin_wheel_reward_claim_tap',
              parameters: {'coins': wonCoins},
            );
            final navCtx = rootNavKey.currentContext!;
            final earned = await RewardAdService.showSpinWheel(
              navCtx,
              defaultCoins: wonCoins,
            );
            if (earned == null) return;
            AnalyticsManager.instance.logEvent(
              name: 'spin_wheel_reward_claimed',
              parameters: {'coins': earned},
            );
            await CoinService.addCoins(earned);
          }
          if (context.mounted) context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        NavigationHelper().handleBackPress(context);
      },
      child: CommonBackground(
        gradient: const LinearGradient(
          colors: [Color(0xFFF7F9FC), Color(0xFFEEF2F8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CommonAppBar(
            title: context.l10n.spinAndWin,
            showBack: true,
          ),
          body: SafeArea(
            top: false,
            child: _showWelcome
                ? _ScWelcomeBody(
                    onGetStarted: _onGetStarted,
                    currentAngle: _currentAngle,
                  )
                : _ScSpinBody(
                    onSpin: _onSpin,
                    isSpinning: _isSpinning,
                    rotation: _rotation,
                    currentAngle: _currentAngle,
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State 1: Welcome
// ─────────────────────────────────────────────────────────────────────────────

class _ScWelcomeBody extends StatelessWidget {
  const _ScWelcomeBody({required this.onGetStarted, required this.currentAngle});

  final VoidCallback onGetStarted;
  final double currentAngle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.w24),
      child: Column(
        children: [
          SizedBox(height: AppSize.h24),
          Text(
            context.l10n.spinWelcomeTitle,
            style: context.textTheme.titleLarge?.copyWith(
              color: const Color(0xFF0B1F4D),
              fontWeight: FontWeight.w800,
              fontSize: AppSize.sp22,
            ),
          ),
          SizedBox(height: AppSize.h10),
          Text(
            context.l10n.spinWelcomeSubtitle,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
          const Spacer(),
          SizedBox(
            height: AppSize.sp250,
            width: AppSize.sp250,
            child: _ScWheelWithPointer(angle: currentAngle),
          ),
          const Spacer(),
          _ScPaleCyanPill(
            label: context.l10n.getStarted,
            onPressed: onGetStarted,
          ),
          SizedBox(height: AppSize.h24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State 2: Spin (ready + spinning)
// ─────────────────────────────────────────────────────────────────────────────

class _ScSpinBody extends StatelessWidget {
  const _ScSpinBody({
    required this.onSpin,
    required this.isSpinning,
    required this.currentAngle,
    this.rotation,
  });

  final VoidCallback onSpin;
  final bool isSpinning;
  final double currentAngle;
  final Animation<double>? rotation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.w24),
      child: Column(
        children: [
          SizedBox(height: AppSize.h12),
          // Live coin balance
          StreamBuilder<dynamic>(
            stream: Injector.instance<AppDB>().userListenable(),
            builder: (context, _) {
              final balance =
                  Injector.instance<AppDB>().userModel?.coin.toInt() ?? 0;
              return CoinChip(
                amount: '$balance',
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD84D).withValues(alpha: 0.7),
                    const Color(0xFFFFD84D).withValues(alpha: 0.5),
                    const Color(0xFFFFD84D).withValues(alpha: 0.0),
                  ],
                ),
                borderColor: Colors.transparent,
              );
            },
          ),
          const Spacer(),
          SizedBox(
            height: AppSize.sp300,
            width: AppSize.sp300,
            child: _buildWheel(),
          ),
          const Spacer(),
          _ScPaleCyanPill(
            label: isSpinning ? context.l10n.spinning : context.l10n.spinNow,
            onPressed: isSpinning ? () {} : onSpin,
          ),
          SizedBox(height: AppSize.h24),
        ],
      ),
    );
  }

  Widget _buildWheel() {
    final anim = rotation;
    if (isSpinning && anim != null) {
      return AnimatedBuilder(
        animation: anim,
        builder: (_, child) => _ScWheelWithPointer(angle: anim.value),
      );
    }
    return _ScWheelWithPointer(angle: currentAngle);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wheel composite: spin_circle.png rotates, spin_arrow.png stays fixed
// ─────────────────────────────────────────────────────────────────────────────

class _ScWheelWithPointer extends StatelessWidget {
  const _ScWheelWithPointer({this.angle = 0});

  final double angle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 1. Static background: golden ring + grey rim (spin_wheel_bg.png)
              Positioned(
                top: -3.5,
                child: Assets.images.spin.scSpinWheelBg.image(
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                ),
              ),

              // 2. Rotating painted segments (only this part spins)
              //    Sized slightly smaller to sit inside the golden ring.
              ScSpinWheelWidget(
                segments: _getWheelSegments(context),
                angle: angle,
                size: size * 0.85,
              ),

              // 3. Fixed gold pointer/cap at the top (spin_cap.png)
              Positioned(
                top: -2.5,
                child: Assets.images.spin.scSpinCap.image(
                  height: size * 0.12,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Congratulations dialog (animated)
// ─────────────────────────────────────────────────────────────────────────────

class _ScCongratsDialog extends StatefulWidget {
  const _ScCongratsDialog({
    required this.coins,
    required this.isLoss,
    required this.onClaim,
  });

  final int coins;
  final bool isLoss;
  final VoidCallback onClaim;

  @override
  State<_ScCongratsDialog> createState() => _ScCongratsDialogState();
}

class _ScCongratsDialogState extends State<_ScCongratsDialog>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryScale;
  late final Animation<double> _entryFade;

  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _entryScale = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.elasticOut,
    );
    _entryFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    );
    _entryCtrl.forward();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: AppSize.w32),
      child: FadeTransition(
        opacity: _entryFade,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.85,
            end: 1.0,
          ).animate(_entryScale),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              AppSize.w24,
              AppSize.h32,
              AppSize.w24,
              AppSize.h24,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEAF0FB), Color(0xFFFFFFFF)],
              ),
              borderRadius: BorderRadius.circular(AppSize.r24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B1F4D).withValues(alpha: 0.18),
                  blurRadius: AppSize.r32,
                  offset: Offset(0, AppSize.h8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _floatCtrl,
                  builder: (_, child) {
                    final t = Curves.easeInOut.transform(_floatCtrl.value);
                    return Transform.translate(
                      offset: Offset(0, -6 * t),
                      child: Transform.rotate(
                        angle: 0.04 * (t * 2 - 1),
                        child: child,
                      ),
                    );
                  },
                  child: Assets.images.scTrackAchievments.image(
                    height: AppSize.sp120,
                    width: AppSize.sp120,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: AppSize.h20),
                Text(
                  widget.isLoss ? context.l10n.spinOops : context.l10n.spinCongrats,
                  style: context.textTheme.titleLarge?.copyWith(
                    color: widget.isLoss
                        ? const Color(0xFFFF5183)
                        : const Color(0xFF0B1F4D),
                    fontWeight: FontWeight.w800,
                    fontSize: AppSize.sp22,
                  ),
                ),
                SizedBox(height: AppSize.h8),
                Text(
                  widget.isLoss
                      ? context.l10n.spinBetterLuck
                      : context.l10n.spinWonCoins(widget.coins),
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: widget.isLoss
                        ? const Color(0xFFFF5183)
                        : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppSize.h24),
                if (!widget.isLoss)
                  AdDisclaimerText(show: RewardAdService.isSpinWheelAdEnabled),
                _ScPaleCyanPill(
                  label: widget.isLoss ? context.l10n.tryAgain : context.l10n.claimCoins,
                  onPressed: widget.onClaim,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable pale-cyan pill
// ─────────────────────────────────────────────────────────────────────────────

class _ScPaleCyanPill extends StatelessWidget {
  const _ScPaleCyanPill({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSize.r100);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: Container(
          height: AppSize.h48,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3A6BFF), Color(0xFF1E3FE0)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                blurRadius: AppSize.r16,
                offset: Offset(0, AppSize.h4),
              ),
            ],
          ),
          child: Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
