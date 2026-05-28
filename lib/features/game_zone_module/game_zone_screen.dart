import 'package:ad_manager/ad_manager.dart';
import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/features/game_zone_module/provider/game_zone_provider.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:spin_craze/widgets/common_appbar.dart';
import 'package:spin_craze/utils/navigation_helper.dart';
import 'package:spin_craze/widgets/common_background.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Palette ─────────────────────────────────────────────────────────────────

const _kBlueDark = Color(0xFF004CD9);
const _kBlue = Color(0xFF1164FF);
const _kCardBorder = Color(0xFFE5EAF2);
const _kInk = Color(0xFF111827);
const _kInkMuted = Color(0xFF6B7280);
const _kDanger = Color(0xFFEF4444);

const _kPageBg = Color(0xFFE8EFFB);

const _kPageGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [_kPageBg, _kPageBg],
);

const _kBlueGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [_kBlue, _kBlueDark],
);

// ── Data ────────────────────────────────────────────────────────────────────

class _GameItem {
  const _GameItem(this.title, this.url);
  final String title;
  final String url;
}

int get _coinsPerGame => RemoteConfigService.instance.gameVisitRewardCoins;
int get _gameDurationSecs => RemoteConfigService.instance.gameVisitTimeSeconds;
bool get _useInAppWebView => RemoteConfigService.instance.inAppWebView;

final _gameItems = <_GameItem>[
  _GameItem(
    RemoteConfigService.instance.gameVisit1Title,
    RemoteConfigService.instance.gameVisit1,
  ),
  _GameItem(
    RemoteConfigService.instance.gameVisit2Title,
    RemoteConfigService.instance.gameVisit2,
  ),
  _GameItem(
    RemoteConfigService.instance.gameVisit3Title,
    RemoteConfigService.instance.gameVisit3,
  ),
  _GameItem(
    RemoteConfigService.instance.gameVisit4Title,
    RemoteConfigService.instance.gameVisit4,
  ),
  _GameItem(
    RemoteConfigService.instance.gameVisit5Title,
    RemoteConfigService.instance.gameVisit5,
  ),
];

// ── Screen ──────────────────────────────────────────────────────────────────

class GameZoneScreen extends StatelessWidget {
  const GameZoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameZoneProvider(),
      child: const _GameZoneContent(),
    );
  }
}

class _GameZoneContent extends StatefulWidget {
  const _GameZoneContent();

  @override
  State<_GameZoneContent> createState() => _GameZoneContentState();
}

class _GameZoneContentState extends State<_GameZoneContent>
    with WidgetsBindingObserver {
  DateTime? _launchTime;
  bool _waitingForReturn = false;
  int? _activeItemIndex;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logScreenView(
      screenName: 'game_zone',
      screenClass: 'GameZoneScreen',
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForReturn) {
      _waitingForReturn = false;
      _onReturnedToApp();
    }
  }

  Future<void> _launchGame(_GameItem item) async {
    AnalyticsManager.instance.logEvent(
      name: 'game_launch_external',
      parameters: {'game_title': item.title},
    );
    final uri = Uri.parse(item.url);
    if (await canLaunchUrl(uri)) {
      _launchTime = DateTime.now();
      _waitingForReturn = true;
      // Skip the next App-Open ad on resume — the game-completion flow
      // owns the ad/reward UX for this round-trip.
      ignoreNextEvent = true;
      await launchUrl(uri);
    }
  }

  Future<void> _onReturnedToApp() async {
    if (!mounted || _launchTime == null) return;

    final elapsed = DateTime.now().difference(_launchTime!).inSeconds;
    _launchTime = null;

    if (elapsed >= _gameDurationSecs) {
      AnalyticsManager.instance.logEvent(
        name: 'game_completion_eligible',
        parameters: {'time_spent': elapsed, 'required': _gameDurationSecs},
      );
      _showCongratsDialog();
    } else {
      AnalyticsManager.instance.logEvent(
        name: 'game_completion_failed',
        parameters: {'time_spent': elapsed, 'required': _gameDurationSecs},
      );
      _showTimeFailDialog(elapsed);
    }
  }

  /// In-app webview flow (inAppWebView == true)
  void _launchGameInApp(_GameItem item) {
    AnalyticsManager.instance.logEvent(
      name: 'game_launch_inapp',
      parameters: {'game_title': item.title},
    );
    final index = _activeItemIndex;
    context.pushNamed(
      AppRoutes.inAppWebView,
      extra: {
        'url': item.url,
        'title': context.l10n.playGame,
        'durationSeconds': _gameDurationSecs,
        'coins': _coinsPerGame,
        'adData': RemoteConfigService.instance.websiteReward,
        'onRewardClaimed': () {
          if (index != null) {
            context.read<GameZoneProvider>().setLock(index);
          }
        },
      },
    );
  }

  void _showMissionBrief(int index, _GameItem item) {
    AnalyticsManager.instance.logEvent(
      name: 'game_mission_brief_shown',
      parameters: {'game_title': item.title},
    );
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogCtx) => _MissionBriefDialog(
        durationSeconds: _gameDurationSecs,
        onStart: () {
          AnalyticsManager.instance.logEvent(
            name: 'game_mission_start',
            parameters: {'game_title': item.title},
          );
          dialogCtx.pop();
          _activeItemIndex = index;
          if (_useInAppWebView) {
            _launchGameInApp(item);
          } else {
            _launchGame(item);
          }
        },
        onCancel: () => dialogCtx.pop(),
      ),
    );
  }

  void _showCongratsDialog() {
    final claimedIndex = _activeItemIndex;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: _CongratsDialog(
          coins: _coinsPerGame,
          onClaim: () async {
            AnalyticsManager.instance.logEvent(
              name: 'game_reward_claim_tap',
              parameters: {'coins': _coinsPerGame},
            );
            dialogCtx.pop();
            if (claimedIndex != null) {
              await context.read<GameZoneProvider>().claimReward(claimedIndex);
              AnalyticsManager.instance.logEvent(
                name: 'game_reward_claimed',
                parameters: {'coins': _coinsPerGame},
              );
            }
          },
        ),
      ),
    );
  }

  void _showTimeFailDialog(int elapsedSecs) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogCtx) => _TimeFailDialog(
        required: _gameDurationSecs,
        elapsed: elapsedSecs,
        onDismiss: () => dialogCtx.pop(),
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
        gradient: _kPageGradient,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CommonAppBar(title: context.l10n.earnModuleGameTitle, showBack: true),
          body: SafeArea(
            top: false,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                AppSize.w24,
                AppSize.h20,
                AppSize.w24,
                AppSize.h24,
              ),
              itemCount: _gameItems.length,
              separatorBuilder: (_, _) => SizedBox(height: AppSize.h14),
              itemBuilder: (context, index) {
                final item = _gameItems[index];
                final prov = context.watch<GameZoneProvider>();
                final locked = prov.isLocked(index);
                final countdown = locked ? prov.lockCountdown(index) : null;

                return _GameTile(
                  item: item,
                  isLocked: locked,
                  lockCountdown: countdown,
                  onTap: locked ? () {} : () => _showMissionBrief(index, item),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Game tile ───────────────────────────────────────────────────────────────

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.item,
    required this.onTap,
    this.isLocked = false,
    this.lockCountdown,
  });

  final _GameItem item;
  final VoidCallback onTap;
  final bool isLocked;
  final String? lockCountdown;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSize.r10);
    return _InsetShadowCard(
      radius: radius,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.w20,
          vertical: AppSize.h22,
        ),
        child: Row(
          children: [
            Assets.icons.icGameZone.svg(
              height: AppSize.sp32,
              width: AppSize.sp36,
            ),
            SizedBox(width: AppSize.w14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF083255),
                      fontWeight: FontWeight.w600,
                      fontSize: AppSize.sp14,
                    ),
                  ),
                  SizedBox(height: AppSize.h6),
                  Row(
                    children: [
                      Assets.icons.coins.svg(
                        height: AppSize.sp14,
                        width: AppSize.sp14,
                      ),
                      SizedBox(width: AppSize.w4),
                      Text(
                        context.l10n.gameZoneCoinsReward(_coinsPerGame),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF3D3E40),
                          fontWeight: FontWeight.w500,
                          fontSize: AppSize.sp12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isLocked &&
                lockCountdown != null &&
                lockCountdown!.isNotEmpty) ...[
              SizedBox(width: AppSize.w8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSize.w10,
                  vertical: AppSize.h4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSize.r10),
                  color: _kDanger.withValues(alpha: 0.1),
                  border: Border.all(
                    color: _kDanger.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: AppSize.sp14,
                      color: _kDanger,
                    ),
                    SizedBox(width: AppSize.w4),
                    Text(
                      lockCountdown!,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: _kDanger,
                        fontWeight: FontWeight.w700,
                        fontSize: AppSize.sp12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Inset-shadow card shell ─────────────────────────────────────────────────

class _InsetShadowCard extends StatelessWidget {
  const _InsetShadowCard({
    required this.radius,
    required this.onTap,
    required this.child,
  });

  final BorderRadius radius;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: const Color(0xFF7CB0FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7CB0FF).withValues(alpha: 0.20),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _InnerShadowPainter(
                    cornerRadius: radius.topLeft.x,
                  ),
                ),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: radius,
                onTap: onTap,
                splashColor: const Color(0xFF7CB0FF).withValues(alpha: 0.12),
                highlightColor: const Color(0xFF7CB0FF).withValues(alpha: 0.06),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InnerShadowPainter extends CustomPainter {
  const _InnerShadowPainter({required this.cornerRadius});
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(cornerRadius),
    );
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = const Color(0xFFB0C3F8).withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26,
    );
  }

  @override
  bool shouldRepaint(_InnerShadowPainter old) =>
      old.cornerRadius != cornerRadius;
}

// ── Mission Brief dialog ────────────────────────────────────────────────────

class _MissionBriefDialog extends StatefulWidget {
  const _MissionBriefDialog({
    required this.durationSeconds,
    required this.onStart,
    required this.onCancel,
  });

  final int durationSeconds;
  final VoidCallback onStart;
  final VoidCallback onCancel;

  @override
  State<_MissionBriefDialog> createState() => _MissionBriefDialogState();
}

class _MissionBriefDialogState extends State<_MissionBriefDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _imgScale;
  late final Animation<double> _imgSwing;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _imgScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _imgSwing = Tween<double>(begin: -0.06, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    _contentFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _imgScale,
            child: RotationTransition(
              turns: _imgSwing,
              child: Assets.images.missionBrief.image(
                height: AppSize.sp114,
                width: AppSize.sp114,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: AppSize.h16),
          FadeTransition(
            opacity: _contentFade,
            child: SlideTransition(
              position: _contentSlide,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.missionBriefTitle,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: _kInk,
                      fontWeight: FontWeight.w800,
                      fontSize: AppSize.sp22,
                    ),
                  ),
                  SizedBox(height: AppSize.h10),
                  Text.rich(
                    TextSpan(
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: _kInkMuted,
                        height: 1.45,
                        fontSize: AppSize.sp14,
                      ),
                      children: [
                        TextSpan(
                          text: context.l10n.missionBriefPart1(widget.durationSeconds),
                        ),
                        TextSpan(
                          text: context.l10n.missionBriefClaimAction,
                          style: const TextStyle(
                            color: _kBlueDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(text: context.l10n.missionBriefPart2),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSize.h20),
                  Row(
                    children: [
                      Expanded(
                        child: _GhostButton(
                          label: context.l10n.cancel,
                          onPressed: widget.onCancel,
                        ),
                      ),
                      SizedBox(width: AppSize.w12),
                      Expanded(
                        child: _PrimaryButton(
                          label: context.l10n.start,
                          onPressed: widget.onStart,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Congrats dialog ─────────────────────────────────────────────────────────

class _CongratsDialog extends StatefulWidget {
  const _CongratsDialog({required this.coins, required this.onClaim});

  final int coins;
  final VoidCallback onClaim;

  @override
  State<_CongratsDialog> createState() => _CongratsDialogState();
}

class _CongratsDialogState extends State<_CongratsDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _imgScale;
  late final Animation<double> _imgFloat;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _imgScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _imgFloat = Tween<double>(begin: -14.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.65, curve: Curves.bounceOut),
      ),
    );
    _contentFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.45, 1.0, curve: Curves.easeIn),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
      ),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _imgFloat,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _imgFloat.value),
              child: child,
            ),
            child: ScaleTransition(
              scale: _imgScale,
              child: Assets.images.gift.image(
                height: AppSize.sp114,
                width: AppSize.sp114,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: AppSize.h16),
          FadeTransition(
            opacity: _contentFade,
            child: SlideTransition(
              position: _contentSlide,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.spinCongrats,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: _kBlueDark,
                      fontWeight: FontWeight.w800,
                      fontSize: AppSize.sp24,
                    ),
                  ),
                  SizedBox(height: AppSize.h8),
                  Text(
                    context.l10n.spinWonCoins(widget.coins),
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: _kInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSize.h24),
                  _PrimaryButton(
                    label: context.l10n.claimCoins,
                    onPressed: widget.onClaim,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Time fail dialog ────────────────────────────────────────────────────────

class _TimeFailDialog extends StatelessWidget {
  const _TimeFailDialog({
    required this.required,
    required this.elapsed,
    required this.onDismiss,
  });

  final int required;
  final int elapsed;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: AppSize.sp82,
            width: AppSize.sp82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kDanger.withValues(alpha: 0.1),
              border: Border.all(color: _kDanger.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.timer_off_rounded,
              size: AppSize.sp42,
              color: _kDanger,
            ),
          ),
          SizedBox(height: AppSize.h20),
          Text(
            context.l10n.timeNotCompleted,
            style: context.textTheme.titleLarge?.copyWith(
              color: _kDanger,
              fontWeight: FontWeight.w800,
              fontSize: AppSize.sp22,
            ),
          ),
          SizedBox(height: AppSize.h10),
          Text(
            context.l10n.gameTimeFail(elapsed, required),
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: _kInkMuted,
              height: 1.5,
              fontSize: AppSize.sp14,
            ),
          ),
          SizedBox(height: AppSize.h24),
          _PrimaryButton(label: context.l10n.tryAgain, onPressed: onDismiss),
        ],
      ),
    );
  }
}

// ── Dialog shell ────────────────────────────────────────────────────────────

class _DialogShell extends StatelessWidget {
  const _DialogShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: AppSize.w28),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          AppSize.w22,
          AppSize.h24,
          AppSize.w22,
          AppSize.h22,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSize.r24),
          boxShadow: [
            BoxShadow(
              color: _kBlueDark.withValues(alpha: 0.18),
              blurRadius: AppSize.r28,
              offset: Offset(0, AppSize.h10),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ── Buttons ─────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

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
            gradient: _kBlueGradient,
            boxShadow: [
              BoxShadow(
                color: _kBlueDark.withValues(alpha: 0.35),
                blurRadius: AppSize.r16,
                offset: Offset(0, AppSize.h6),
              ),
            ],
          ),
          child: Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: AppSize.sp15,
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onPressed});

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
            color: Colors.white,
            borderRadius: radius,
            border: Border.all(color: _kCardBorder, width: 1.5),
          ),
          child: Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: _kInk,
              fontWeight: FontWeight.w700,
              fontSize: AppSize.sp15,
            ),
          ),
        ),
      ),
    );
  }
}
