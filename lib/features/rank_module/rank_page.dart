import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/features/rank_module/model/leaderboard_user_model.dart';
import 'package:spin_craze/features/rank_module/provider/rank_provider.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/navigation_helper.dart';
import 'package:spin_craze/widgets/common_appbar.dart';
import 'package:spin_craze/widgets/glow_container.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spin_craze/extension/ext_localization.dart';

/// Leaderboard / Rank tab — wired to Firestore via RankProvider.
class RankPage extends StatelessWidget {
  const RankPage({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsManager.instance.logScreenView(
      screenName: 'leaderboard',
      screenClass: 'RankPage',
    );
    return ChangeNotifierProvider(
      create: (_) => RankProvider(),
      child: Consumer<RankProvider>(
        builder: (context, provider, _) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              NavigationHelper().handleBackPress(context);
            },
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: CommonAppBar(title: context.l10n.leaderboard),
              body: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                  ? Center(
                      child: Text(
                        provider.error!,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.themeTextColors.error,
                        ),
                      ),
                    )
                  : RefreshIndicator(
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
                          AppSize.w16,
                          AppSize.h16,
                          AppSize.w16,
                          AppSize.h120,
                        ),
                        child: Column(
                          children: [
                            _Podium(players: provider.top3),
                            SizedBox(height: AppSize.h16),
                            // Refresh timer
                            _RefreshTimerRow(
                              canRefresh: provider.canRefresh,
                              formattedTimer: provider.formattedTimer,
                            ),
                            SizedBox(height: AppSize.h16),
                            const _TableHeader(),
                            SizedBox(height: AppSize.h12),
                            for (
                              int i = 0;
                              i < provider.listUsers.length;
                              i++
                            ) ...[
                              _PlayerRow(
                                data: provider.listUsers[i],
                                rank: i + 4,
                              ),
                              SizedBox(height: AppSize.h12),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Refresh timer row
// ─────────────────────────────────────────────────────────────────────────────

class _RefreshTimerRow extends StatelessWidget {
  const _RefreshTimerRow({
    required this.canRefresh,
    required this.formattedTimer,
  });

  final bool canRefresh;
  final String formattedTimer;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final textColors = context.themeTextColors;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w16,
        vertical: AppSize.h12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.r12),
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            color: canRefresh ? colors.success : colors.coin,
            size: AppSize.sp20,
          ),
          SizedBox(width: AppSize.w8),
          Text(
            canRefresh ? 'Pull down to refresh' : 'Refresh in $formattedTimer',
            style: context.textTheme.bodyMedium?.copyWith(
              color: canRefresh ? colors.success : textColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Podium (top 3)
// ─────────────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  const _Podium({required this.players});

  final List<LeaderboardUser> players;

  @override
  Widget build(BuildContext context) {
    final second = players.length > 1 ? players[1] : null;
    final first = players.isNotEmpty ? players[0] : null;
    final third = players.length > 2 ? players[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: AppSize.w14,
      children: [
        if (second != null)
          Expanded(
            child: _PodiumColumn(
              user: second,
              rank: 2,
              pedestalHeight: AppSize.h130,
              accent: const Color(0xFFC0C0C0),
              gradientColors: const [Color(0xFF1A3A4A), Color(0xFF0B3040)],
              rankIcon: Icons.workspace_premium_rounded,
            ),
          )
        else
          const Expanded(child: SizedBox()),
        if (first != null)
          Expanded(
            child: _PodiumColumn(
              user: first,
              rank: 1,
              pedestalHeight: AppSize.h170,
              accent: const Color(0xFFFFD84D),
              gradientColors: const [Color(0xFF2A4535), Color(0xFF0B3040)],
              isFirst: true,
              rankIcon: Icons.emoji_events_rounded,
            ),
          )
        else
          const Expanded(child: SizedBox()),
        if (third != null)
          Expanded(
            child: _PodiumColumn(
              user: third,
              rank: 3,
              pedestalHeight: AppSize.h110,
              accent: const Color(0xFFCD7F32),
              gradientColors: const [Color(0xFF2A2520), Color(0xFF0B3040)],
              rankIcon: Icons.military_tech_rounded,
            ),
          )
        else
          const Expanded(child: SizedBox()),
      ],
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.user,
    required this.rank,
    required this.pedestalHeight,
    required this.accent,
    required this.gradientColors,
    this.isFirst = false,
    this.rankIcon,
  });

  final LeaderboardUser user;
  final int rank;
  final double pedestalHeight;
  final Color accent;
  final List<Color> gradientColors;
  final bool isFirst;
  final IconData? rankIcon;

  String get _initial =>
      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

  String get _tier {
    if (user.level >= 10) return 'Expert';
    if (user.level >= 5) return 'Intermediate';
    return 'Beginner';
  }

  @override
  Widget build(BuildContext context) {
    final textColors = context.themeTextColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFirst) ...[
          Icon(Icons.emoji_events_rounded, color: accent, size: AppSize.sp28),
          SizedBox(height: AppSize.h4),
        ],
        _PodiumAvatar(
          initial: _initial,
          accent: accent,
          size: isFirst ? AppSize.sp56 : AppSize.sp48,
        ),
        SizedBox(height: AppSize.h8),
        Text(
          user.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelMedium?.copyWith(
            color: textColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSize.h2),
        Text(
          '${user.coins} coins',
          style: context.textTheme.bodySmall?.copyWith(
            color: accent,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSize.h10),
        GlowContainer(
          accent: accent,
          borderRadius: AppSize.r12,
          child: Container(
            width: double.infinity,
            height: pedestalHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSize.r12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: -AppSize.h20,
                  child: IgnorePointer(
                    child: Container(
                      height: AppSize.sp80,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 0.8,
                          colors: [
                            accent.withValues(alpha: 0.3),
                            accent.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: AppSize.h14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (rankIcon != null)
                          Icon(
                            rankIcon,
                            color: accent.withValues(alpha: 0.5),
                            size: AppSize.sp32,
                          ),
                        SizedBox(height: AppSize.h6),
                        Container(
                          width: AppSize.sp40,
                          height: AppSize.sp40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppSize.r10),
                            color: accent.withValues(alpha: 0.15),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            '$rank',
                            style: context.textTheme.titleLarge?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PodiumAvatar extends StatelessWidget {
  const _PodiumAvatar({
    required this.initial,
    required this.accent,
    required this.size,
  });

  final String initial;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.r14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, accent.withValues(alpha: 0.4)],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.4),
            blurRadius: AppSize.r16,
            offset: Offset(0, AppSize.h4),
          ),
        ],
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSize.r12),
          color: const Color(0xFF12313D),
        ),
        child: Text(
          initial,
          style: context.textTheme.titleMedium?.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table header
// ─────────────────────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final textColors = context.themeTextColors;
    final borderColor = const Color(0xFF29B0E6).withValues(alpha: 0.5);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w16,
        vertical: AppSize.h14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.r12),
        color: context.themeColors.surface,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppSize.w30,
            child: Text(
              '#',
              style: context.textTheme.titleSmall?.copyWith(
                color: textColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Player',
              style: context.textTheme.titleSmall?.copyWith(
                color: textColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            'Coins',
            style: context.textTheme.titleSmall?.copyWith(
              color: textColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Player row
// ─────────────────────────────────────────────────────────────────────────────

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.data, required this.rank});

  final LeaderboardUser data;
  final int rank;

  String get _initial =>
      data.name.isNotEmpty ? data.name[0].toUpperCase() : '?';

  String get _tier {
    if (data.level >= 10) return 'Expert';
    if (data.level >= 5) return 'Intermediate';
    return 'Beginner';
  }

  @override
  Widget build(BuildContext context) {
    final textColors = context.themeTextColors;
    final borderColor = const Color(0xFF29B0E6).withValues(alpha: 0.5);

    return GlowContainer(
      accent: borderColor,
      borderRadius: AppSize.r12,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.w16,
          vertical: AppSize.h12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSize.r12),
          color: context.themeColors.surface,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            SizedBox(
              width: AppSize.w30,
              child: Text(
                '$rank',
                style: context.textTheme.titleSmall?.copyWith(
                  color: textColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _MiniAvatar(initial: _initial, size: AppSize.sp40),
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
                      color: textColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppSize.h2),
                  Text(
                    'Lv. ${data.level}  $_tier',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: textColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              data.coins,
              style: context.textTheme.titleSmall?.copyWith(
                color: textColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.initial, this.size});

  final String initial;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final s = size ?? AppSize.sp42;
    return Container(
      width: s,
      height: s,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.r10),
        color: const Color(0xFF1C3A48),
        border: Border.all(
          color: const Color(0xFF29B0E6).withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        initial,
        style: context.textTheme.labelLarge?.copyWith(
          color: context.themeTextColors.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
