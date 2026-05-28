import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/features/rank_module/model/sc_leaderboard_user_model.dart';
import 'package:spin_craze/features/rank_module/provider/sc_rank_provider.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const Color _kPrimary = Color(0xFF004CD9);
const Color _kPrimaryLight = Color(0xFF1164FF);
const Color _kCardBorder = Color(0xFFB8D0FF);
const Color _kAvatarBg = Color(0xFFE4ECFF);
const Color _kAvatarText = Color(0xFF0A2A6B);
const Color _kMutedText = Color(0xFF7A8A9C);
const Color _kPageBg = Color(0xFFF5F8FF);

// Pedestal gradients (top → bottom)
const List<Color> _kRed = [Color(0xFFD33038), Color(0xFF8B141A)];
const List<Color> _kBlue = [Color(0xFF2A53E8), Color(0xFF11258F)];
const List<Color> _kGreen = [Color(0xFF3FA64A), Color(0xFF1E6428)];

/// Leaderboard / Rank tab — wired to Firestore via ScRankProvider.
class ScRankPage extends StatelessWidget {
  const ScRankPage({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsManager.instance.logScreenView(
      screenName: 'leaderboard',
      screenClass: 'ScRankPage',
    );
    return ChangeNotifierProvider(
      create: (_) => ScRankProvider(),
      child: const _ScRankBody(),
    );
  }
}

class _ScRankBody extends StatefulWidget {
  const _ScRankBody();

  @override
  State<_ScRankBody> createState() => _ScRankBodyState();
}

class _ScRankBodyState extends State<_ScRankBody>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _podium;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _podium = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _podium.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _podium.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScRankProvider>(
      builder: (context, provider, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            NavigationHelper().handleBackPress(context);
          },
          child: Scaffold(
            backgroundColor: _kPageBg,
            body: Column(
              children: [
                _ScGradientHeader(
                  title: context.l10n.leaderboard,
                  onBack: () =>
                      NavigationHelper().handleBackPress(context),
                ),
                Expanded(
                  child: provider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: _kPrimary,
                          ),
                        )
                      : provider.error != null
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSize.w24,
                            ),
                            child: Text(
                              provider.error!,
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: Colors.red.shade400,
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: _kPrimary,
                          onRefresh: () async {
                            AnalyticsManager.instance.logEvent(
                              name: 'leaderboard_refresh',
                            );
                            await provider.refresh();
                          },
                          notificationPredicate: (_) => provider.canRefresh,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              AppSize.w20,
                              AppSize.h24,
                              AppSize.w20,
                              AppSize.h120,
                            ),
                            child: Column(
                              children: [
                                _ScPodium(
                                  players: provider.top3,
                                  animation: _podium,
                                ),
                                SizedBox(height: AppSize.h20),
                                _ScRefreshTimerRow(
                                  canRefresh: provider.canRefresh,
                                  formattedTimer: provider.formattedTimer,
                                ),
                                SizedBox(height: AppSize.h16),
                                const _ScTableHeader(),
                                SizedBox(height: AppSize.h10),
                                for (
                                  int i = 0;
                                  i < provider.listUsers.length;
                                  i++
                                ) ...[
                                  _ScStaggered(
                                    controller: _entrance,
                                    index: i,
                                    child: _ScPlayerRow(
                                      data: provider.listUsers[i],
                                      rank: i + 4,
                                    ),
                                  ),
                                  if (i < provider.listUsers.length - 1)
                                    SizedBox(height: AppSize.h10),
                                ],
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _ScGradientHeader extends StatelessWidget {
  const _ScGradientHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kPrimaryLight, _kPrimary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33004CD9),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSize.w8,
            AppSize.h8,
            AppSize.w8,
            AppSize.h24,
          ),
          child: SizedBox(
            height: AppSize.h44,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: AppSize.sp24,
                    ),
                    onPressed: onBack,
                  ),
                ),
                Center(
                  child: Text(
                    title,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: AppSize.sp20,
                      letterSpacing: 0.2,
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Animation helper for list rows
// ─────────────────────────────────────────────────────────────────────────────

class _ScStaggered extends StatelessWidget {
  const _ScStaggered({
    required this.controller,
    required this.index,
    required this.child,
  });

  final AnimationController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = (0.20 + index * 0.04).clamp(0.0, 0.85);
    final end = (base + 0.35).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(base, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, _) {
        final t = anim.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 18),
            child: child,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Podium (top 3)
// ─────────────────────────────────────────────────────────────────────────────

class _ScPodium extends StatelessWidget {
  const _ScPodium({required this.players, required this.animation});

  final List<ScLeaderboardUser> players;
  final AnimationController animation;

  @override
  Widget build(BuildContext context) {
    final first = players.isNotEmpty ? players[0] : null;
    final second = players.length > 1 ? players[1] : null;
    final third = players.length > 2 ? players[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _ScPodiumColumn(
            user: second,
            rank: 2,
            pedestalHeight: AppSize.h130,
            gradientColors: _kRed,
            animation: animation,
            interval: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
          ),
        ),
        SizedBox(width: AppSize.w12),
        Expanded(
          child: _ScPodiumColumn(
            user: first,
            rank: 1,
            pedestalHeight: AppSize.h180,
            gradientColors: _kBlue,
            animation: animation,
            interval: const Interval(0.15, 0.95, curve: Curves.easeOutCubic),
          ),
        ),
        SizedBox(width: AppSize.w12),
        Expanded(
          child: _ScPodiumColumn(
            user: third,
            rank: 3,
            pedestalHeight: AppSize.h110,
            gradientColors: _kGreen,
            animation: animation,
            interval: const Interval(0.08, 0.78, curve: Curves.easeOutCubic),
          ),
        ),
      ],
    );
  }
}

class _ScPodiumColumn extends StatelessWidget {
  const _ScPodiumColumn({
    required this.user,
    required this.rank,
    required this.pedestalHeight,
    required this.gradientColors,
    required this.animation,
    required this.interval,
  });

  final ScLeaderboardUser? user;
  final int rank;
  final double pedestalHeight;
  final List<Color> gradientColors;
  final AnimationController animation;
  final Interval interval;

  String get _initial =>
      user != null && user!.name.isNotEmpty ? user!.name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return SizedBox(height: pedestalHeight);
    }

    final pedestalAnim = CurvedAnimation(
      parent: animation,
      curve: interval,
    );

    return AnimatedBuilder(
      animation: pedestalAnim,
      builder: (_, _) {
        final t = pedestalAnim.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ScAvatar(initial: _initial, size: AppSize.sp40),
                    SizedBox(height: AppSize.h6),
                    Text(
                      user!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppSize.h2),
                    Text(
                      user!.coins,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: _kMutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSize.h10),
            _ScPedestal(
              height: pedestalHeight,
              gradientColors: gradientColors,
              rank: rank,
              progress: t,
            ),
          ],
        );
      },
    );
  }
}

class _ScPedestal extends StatelessWidget {
  const _ScPedestal({
    required this.height,
    required this.gradientColors,
    required this.rank,
    required this.progress,
  });

  final double height;
  final List<Color> gradientColors;
  final int rank;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height * progress.clamp(0.0, 1.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.r14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.35),
            blurRadius: AppSize.r16,
            offset: Offset(0, AppSize.h6),
          ),
        ],
      ),
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: AppSize.h16),
        child: Opacity(
          opacity: ((progress - 0.5) * 2).clamp(0.0, 1.0),
          child: Text(
            '$rank',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: AppSize.sp36,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar
// ─────────────────────────────────────────────────────────────────────────────

class _ScAvatar extends StatelessWidget {
  const _ScAvatar({required this.initial, required this.size});

  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _kAvatarBg,
        borderRadius: BorderRadius.circular(AppSize.r10),
        border: Border.all(color: _kCardBorder),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: _kAvatarText,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
          height: 1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Player row (rank 4+)
// ─────────────────────────────────────────────────────────────────────────────

class _ScPlayerRow extends StatelessWidget {
  const _ScPlayerRow({required this.data, required this.rank});

  final ScLeaderboardUser data;
  final int rank;

  String get _initial =>
      data.name.isNotEmpty ? data.name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    final tier = data.level >= 10
        ? context.l10n.rankTierExpert
        : data.level >= 5
            ? context.l10n.rankTierIntermediate
            : context.l10n.rankTierBeginner;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w14,
        vertical: AppSize.h12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSize.r14),
        border: Border.all(color: _kCardBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppSize.w22,
            child: Text(
              '$rank',
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: AppSize.w4),
          _ScAvatar(initial: _initial, size: AppSize.sp36),
          SizedBox(width: AppSize.w12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSize.h2),
                Text(
                  context.l10n.rankLevelTier(data.level, tier),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: _kMutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            data.coins,
            style: context.textTheme.titleSmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Refresh timer row
// ─────────────────────────────────────────────────────────────────────────────

class _ScRefreshTimerRow extends StatelessWidget {
  const _ScRefreshTimerRow({
    required this.canRefresh,
    required this.formattedTimer,
  });

  final bool canRefresh;
  final String formattedTimer;

  @override
  Widget build(BuildContext context) {
    final accent = canRefresh ? const Color(0xFF22A050) : _kPrimary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w16,
        vertical: AppSize.h12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSize.r14),
        border: Border.all(color: _kCardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            color: accent,
            size: AppSize.sp20,
          ),
          SizedBox(width: AppSize.w8),
          Text(
            canRefresh ? context.l10n.pullDownRefresh : context.l10n.refreshIn(formattedTimer),
            style: context.textTheme.bodyMedium?.copyWith(
              color: canRefresh ? accent : _kMutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table header
// ─────────────────────────────────────────────────────────────────────────────

class _ScTableHeader extends StatelessWidget {
  const _ScTableHeader();

  @override
  Widget build(BuildContext context) {
    final headerStyle = context.textTheme.titleSmall?.copyWith(
      color: Colors.black,
      fontWeight: FontWeight.w700,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w14,
        vertical: AppSize.h12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSize.r14),
        border: Border.all(color: _kCardBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppSize.w22,
            child: Text('#', style: headerStyle),
          ),
          SizedBox(width: AppSize.w4 + AppSize.sp36 + AppSize.w12),
          Expanded(child: Text(context.l10n.rankPlayer, style: headerStyle)),
          Text(context.l10n.coinsLabel, style: headerStyle),
        ],
      ),
    );
  }
}
