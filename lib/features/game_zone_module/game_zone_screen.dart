import 'package:ad_manager/ad_manager.dart';
import 'package:spin_craze/extension/ext_context.dart';
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
import 'package:spin_craze/extension/ext_localization.dart';

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
      _showCongratsSheet();
    } else {
      AnalyticsManager.instance.logEvent(
        name: 'game_completion_failed',
        parameters: {'time_spent': elapsed, 'required': _gameDurationSecs},
      );
      _showTimeFailSheet(elapsed);
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _MissionBriefSheet(
        onStart: () {
          AnalyticsManager.instance.logEvent(
            name: 'game_mission_start',
            parameters: {'game_title': item.title},
          );
          sheetCtx.pop();
          _activeItemIndex = index;
          if (_useInAppWebView) {
            _launchGameInApp(item);
          } else {
            _launchGame(item);
          }
        },
        onCancel: () => sheetCtx.pop(),
      ),
    );
  }

  void _showCongratsSheet() {
    final claimedIndex = _activeItemIndex;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetCtx) => _CongratsSheet(
        coins: _coinsPerGame,
        onClaim: () async {
          AnalyticsManager.instance.logEvent(
            name: 'game_reward_claim_tap',
            parameters: {'coins': _coinsPerGame},
          );
          sheetCtx.pop();
          if (claimedIndex != null) {
            await context.read<GameZoneProvider>().claimReward(claimedIndex);
            AnalyticsManager.instance.logEvent(
              name: 'game_reward_claimed',
              parameters: {'coins': _coinsPerGame},
            );
          }
        },
      ),
    );
  }

  void _showTimeFailSheet(int elapsedSecs) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _TimeFailSheet(
        required: _gameDurationSecs,
        elapsed: elapsedSecs,
        onDismiss: () => sheetCtx.pop(),
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
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CommonAppBar(
            title: context.l10n.gameZoneTitle,
            showBack: true,
          ),
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
              separatorBuilder: (_, _) => SizedBox(height: AppSize.h12),
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
    final colors = context.themeColors;
    final textColors = context.themeTextColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSize.r16),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.w16,
            vertical: AppSize.h14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSize.r16),
            color: colors.surface,
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Assets.images.gameZone.image(
                height: AppSize.sp40,
                width: AppSize.sp40,
                fit: BoxFit.contain,
              ),
              SizedBox(width: AppSize.w12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: textColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSize.h4),
                    Row(
                      children: [
                        Assets.icons.coins.svg(
                          height: AppSize.sp14,
                          width: AppSize.sp14,
                        ),
                        SizedBox(width: AppSize.w4),
                        Text(
                          '+ $_coinsPerGame Coins',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFFFD84D),
                            fontWeight: FontWeight.w600,
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
                  lockCountdown!.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSize.w10,
                    vertical: AppSize.h4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSize.r8),
                    color: colors.error.withValues(alpha: 0.15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: AppSize.sp14,
                        color: colors.error,
                      ),
                      SizedBox(width: AppSize.w4),
                      Text(
                        lockCountdown!,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: AppSize.sp12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: AppSize.sp18,
                  color: textColors.muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mission Brief bottom sheet ──────────────────────────────────────────────

class _MissionBriefSheet extends StatelessWidget {
  const _MissionBriefSheet({required this.onStart, required this.onCancel});

  final VoidCallback onStart;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final textColors = context.themeTextColors;
    final colors = context.themeColors;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSize.w24,
        AppSize.h20,
        AppSize.w24,
        AppSize.h32,
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.r24)),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF29B0E6).withValues(alpha: 0.4),
          ),
          left: BorderSide(
            color: const Color(0xFF29B0E6).withValues(alpha: 0.4),
          ),
          right: BorderSide(
            color: const Color(0xFF29B0E6).withValues(alpha: 0.4),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B7FF).withValues(alpha: 0.2),
            blurRadius: AppSize.r24,
            offset: Offset(0, -AppSize.h6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSize.w40,
            height: AppSize.h4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSize.r100),
              color: textColors.muted,
            ),
          ),
          SizedBox(height: AppSize.h20),
          Assets.images.dailyRewardTrophy.image(
            height: AppSize.sp100,
            width: AppSize.sp100,
            fit: BoxFit.contain,
          ),
          SizedBox(height: AppSize.h20),
          Text(
            context.l10n.missionBrief,
            style: context.textTheme.titleLarge?.copyWith(
              color: textColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: AppSize.sp22,
            ),
          ),
          SizedBox(height: AppSize.h8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text:
                      'Stay on the page for $_gameDurationSecs Secs., A\ncountdown timer will appear.\nclick "',
                ),
                TextSpan(
                  text: context.l10n.claimCoin,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: textColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(text: '" when ready!'),
              ],
            ),
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: textColors.secondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: AppSize.h24),
          Row(
            children: [
              Expanded(
                child: _OutlinePill(
                  label: context.l10n.cancel,
                  onPressed: onCancel,
                ),
              ),
              SizedBox(width: AppSize.w12),
              Expanded(
                child: _PaleCyanPill(
                  label: context.l10n.start,
                  onPressed: onStart,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Congrats bottom sheet ───────────────────────────────────────────────────

class _CongratsSheet extends StatelessWidget {
  const _CongratsSheet({required this.coins, required this.onClaim});

  final int coins;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final textColors = context.themeTextColors;
    final colors = context.themeColors;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSize.w24,
        AppSize.h20,
        AppSize.w24,
        AppSize.h32,
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.r24)),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF29B0E6).withValues(alpha: 0.4),
          ),
          left: BorderSide(
            color: const Color(0xFF29B0E6).withValues(alpha: 0.4),
          ),
          right: BorderSide(
            color: const Color(0xFF29B0E6).withValues(alpha: 0.4),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B7FF).withValues(alpha: 0.2),
            blurRadius: AppSize.r24,
            offset: Offset(0, -AppSize.h6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSize.w40,
            height: AppSize.h4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSize.r100),
              color: textColors.muted,
            ),
          ),
          SizedBox(height: AppSize.h20),
          Assets.images.dailyRewardTrophy.image(
            height: AppSize.sp100,
            width: AppSize.sp100,
            fit: BoxFit.contain,
          ),
          SizedBox(height: AppSize.h20),
          Text(
            'Congratulations..!',
            style: context.textTheme.titleLarge?.copyWith(
              color: const Color(0xFFFFD84D),
              fontWeight: FontWeight.w800,
              fontSize: AppSize.sp24,
            ),
          ),
          SizedBox(height: AppSize.h8),
          Text(
            'You won $coins Coins',
            style: context.textTheme.bodyLarge?.copyWith(
              color: textColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppSize.h28),
          _PaleCyanPill(label: context.l10n.claimCoins, onPressed: onClaim),
        ],
      ),
    );
  }
}

// ── Time not completed sheet ────────────────────────────────────────────────

class _TimeFailSheet extends StatelessWidget {
  const _TimeFailSheet({
    required this.required,
    required this.elapsed,
    required this.onDismiss,
  });

  final int required;
  final int elapsed;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final textColors = context.themeTextColors;
    final colors = context.themeColors;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSize.w24,
        AppSize.h20,
        AppSize.w24,
        AppSize.h32,
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.r24)),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF29B0E6).withValues(alpha: 0.4),
          ),
          left: BorderSide(
            color: const Color(0xFF29B0E6).withValues(alpha: 0.4),
          ),
          right: BorderSide(
            color: const Color(0xFF29B0E6).withValues(alpha: 0.4),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B7FF).withValues(alpha: 0.2),
            blurRadius: AppSize.r24,
            offset: Offset(0, -AppSize.h6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSize.w40,
            height: AppSize.h4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSize.r100),
              color: textColors.muted,
            ),
          ),
          SizedBox(height: AppSize.h20),
          Icon(
            Icons.timer_off_rounded,
            size: AppSize.sp72,
            color: const Color(0xFFFF5183),
          ),
          SizedBox(height: AppSize.h20),
          Text(
            'Time Not Completed!',
            style: context.textTheme.titleLarge?.copyWith(
              color: const Color(0xFFFF5183),
              fontWeight: FontWeight.w800,
              fontSize: AppSize.sp22,
            ),
          ),
          SizedBox(height: AppSize.h8),
          Text(
            'You stayed for ${elapsed}s out of ${required}s.\nPlease stay on the page for the full duration.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: textColors.secondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: AppSize.h28),
          _PaleCyanPill(label: context.l10n.tryAgain, onPressed: onDismiss),
        ],
      ),
    );
  }
}

// ── Reusable buttons ────────────────────────────────────────────────────────

class _PaleCyanPill extends StatelessWidget {
  const _PaleCyanPill({required this.label, required this.onPressed});

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
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF9AE0FA), Color(0xFF5CCBF7)],
            ),
            border: Border.all(color: const Color(0xFFB8ECFF)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5CCBF7).withValues(alpha: 0.4),
                blurRadius: AppSize.r16,
                offset: Offset(0, AppSize.h4),
              ),
            ],
          ),
          child: Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF003A52),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlinePill extends StatelessWidget {
  const _OutlinePill({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
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
            border: Border.all(color: colors.border, width: 1.5),
          ),
          child: Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: context.themeTextColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
