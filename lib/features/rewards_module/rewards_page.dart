import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/features/rewards_module/provider/rewards_provider.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_share_helper.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/widgets/common_appbar.dart';
import 'package:spin_craze/widgets/glow_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// Rewards & Bonuses tab — referral code, promo-code input, and invite stats.
/// Guest users see a prompt to link their account instead of a referral code.
class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsManager.instance.logScreenView(
      screenName: 'rewards',
      screenClass: 'RewardsPage',
    );
    return ChangeNotifierProvider(
      create: (_) => RewardsProvider(),
      child: const _RewardsBody(),
    );
  }
}

class _RewardsBody extends StatelessWidget {
  const _RewardsBody();

  @override
  Widget build(BuildContext context) {
    final db = Injector.instance<AppDB>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CommonAppBar(title: context.l10n.rewardsAndBonuses),
      body: StreamBuilder(
        stream: db.userListenable(),
        builder: (context, _) {
          final user = db.userModel;
          final isGuest = user?.isGuest ?? true;
          final referralCode = user?.userId ?? '';

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSize.w16,
              AppSize.h16,
              AppSize.w16,
              AppSize.h120,
            ),
            child: Column(
              children: [
                if (isGuest)
                  _LinkAccountCard()
                else
                  _ReferralCodeCard(code: referralCode),
                SizedBox(height: AppSize.h16),
                _EnterReferralCard(isGuest: isGuest),
                SizedBox(height: AppSize.h16),
                Consumer<RewardsProvider>(
                  builder: (context, provider, _) => _InviteStatsRow(
                    friendsInvited: provider.friendsInvited,
                    coinsEarned: provider.coinsEarned,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Link Account prompt (for guest users)
// ─────────────────────────────────────────────────────────────────────────────

class _LinkAccountCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final textColors = context.themeTextColors;

    return InkWell(
      onTap: () {
        AnalyticsManager.instance.logEvent(name: 'rewards_link_account_tap');
        context.go('/${AppRoutes.profile}');
      },
      child: GlowContainer(
        accent: colors.secondary,
        borderRadius: AppSize.r16,
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.w20,
          vertical: AppSize.h24,
        ),
        child: Column(
          spacing: AppSize.h4,
          children: [
            Icon(
              Icons.link_rounded,
              color: colors.secondary,
              size: AppSize.sp40,
            ),
            Text(
              context.l10n.linkYourAccount,
              style: context.textTheme.titleSmall?.copyWith(
                color: textColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              context.l10n.linkAccountMessage,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: textColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Your Referral Code card (for logged-in users)
// ─────────────────────────────────────────────────────────────────────────────

class _ReferralCodeCard extends StatelessWidget {
  const _ReferralCodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final textColors = context.themeTextColors;

    return GlowContainer(
      accent: context.themeColors.primary,
      borderRadius: AppSize.r16,
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w20,
        vertical: AppSize.h24,
      ),
      child: Column(
        children: [
          Text(
            context.l10n.yourReferralCode,
            style: context.textTheme.titleSmall?.copyWith(
              color: textColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSize.h20),
          // Code box
          GestureDetector(
            onTap: () {
              AnalyticsManager.instance.logEvent(name: 'referral_code_copied');
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.codeCopied),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSize.w24,
                vertical: AppSize.h14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSize.r12),
                color: const Color(0xFF1C3A48),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      code,
                      style: context.textTheme.titleLarge?.copyWith(
                        color: textColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        fontSize: AppSize.sp16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: AppSize.w16),
                  Icon(
                    Icons.copy_rounded,
                    color: textColors.secondary,
                    size: AppSize.sp22,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSize.h20),
          _PaleCyanPill(
            label: context.l10n.shareLink,
            onPressed: () async {
              AnalyticsManager.instance.logEvent(name: 'referral_code_shared');
              final appUrl = await getPlayStoreUrl();
              await SharePlus.instance.share(
                ShareParams(
                  text:
                      'Join me on Earn Money and earn coins! Use my referral code: $code\n\n'
                      'Download the app: $appUrl',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Enter Referral Code card
// ─────────────────────────────────────────────────────────────────────────────

class _EnterReferralCard extends StatelessWidget {
  const _EnterReferralCard({this.isGuest = false});

  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final textColors = context.themeTextColors;
    final provider = context.watch<RewardsProvider>();

    return GlowContainer(
      accent: colors.primary,
      borderRadius: AppSize.r16,
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w20,
        vertical: AppSize.h24,
      ),
      child: Column(
        children: [
          Text(
            context.l10n.enterReferralCode,
            style: context.textTheme.titleSmall?.copyWith(
              color: textColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSize.h20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: provider.referralController,
                  enabled: !isGuest && !provider.isApplyingReferral,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: textColors.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l10n.havePromoCode,
                    hintStyle: context.textTheme.bodyMedium?.copyWith(
                      color: textColors.secondary,
                    ),
                    errorText: provider.errorText,
                    filled: true,
                    fillColor: const Color(0xFF1C3A48),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSize.w16,
                      vertical: AppSize.h14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSize.r12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSize.r12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSize.r12),
                      borderSide: const BorderSide(
                        color: Color(0xFF29B0E6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSize.w12),
              _PaleCyanPill(
                label: provider.isApplyingReferral ? '...' : context.l10n.apply,
                expand: false,
                onPressed: () {
                  if (isGuest) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.pleaseLinkAccountFirst),
                      ),
                    );
                    return;
                  }
                  if (provider.isApplyingReferral) return;
                  AnalyticsManager.instance.logEvent(
                    name: 'referral_code_apply',
                  );
                  provider.validateReferralCode(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invite stats row
// ─────────────────────────────────────────────────────────────────────────────

class _InviteStatsRow extends StatelessWidget {
  const _InviteStatsRow({
    required this.friendsInvited,
    required this.coinsEarned,
  });

  final int friendsInvited;
  final int coinsEarned;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InviteStatTile(
            label: context.l10n.friendsInvited,
            value: '$friendsInvited',
            icon: Assets.icons.user,
            accent: const Color(0xFFA86CFF),
          ),
        ),
        SizedBox(width: AppSize.w12),
        Expanded(
          child: _InviteStatTile(
            label: context.l10n.coinsEarned,
            value: '$coinsEarned',
            icon: Assets.icons.coins,
            accent: const Color(0xFFFF8C24),
          ),
        ),
      ],
    );
  }
}

class _InviteStatTile extends StatelessWidget {
  const _InviteStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final SvgGenImage icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textColors = context.themeTextColors;

    return GlowContainer(
      accent: accent,
      borderRadius: AppSize.r16,
      child: Container(
        height: AppSize.h96,
        padding: EdgeInsets.all(AppSize.sp14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: textColors.secondary,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                icon.svg(
                  height: AppSize.sp22,
                  width: AppSize.sp22,
                  colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                ),
                SizedBox(width: AppSize.w10),
                Flexible(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: textColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared pale-cyan pill button
// ─────────────────────────────────────────────────────────────────────────────

class _PaleCyanPill extends StatelessWidget {
  const _PaleCyanPill({
    required this.label,
    required this.onPressed,
    this.expand = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool expand;

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
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: AppSize.w24),
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
