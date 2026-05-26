import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/features/rewards_module/provider/rewards_provider.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_share_helper.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

const Color _kPrimary = Color(0xFF004CD9);
const Color _kPrimaryLight = Color(0xFF1164FF);
const Color _kCardBorder = Color(0xFFB8D0FF);
const Color _kInputFill = Color(0xFFEEF1F6);
const Color _kCoin = Color(0xFFFFB429);
const Color _kMutedText = Color(0xFF7A8A9C);

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
      backgroundColor: const Color(0xFFF5F8FF),
      body: StreamBuilder(
        stream: db.userListenable(),
        builder: (context, _) {
          final user = db.userModel;
          final isGuest = user?.isGuest ?? true;
          final referralCode = user?.userId ?? '';

          return Column(
            children: [
              const _GradientHeader(title: 'Rewards & Bonuses'),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSize.w20,
                    AppSize.h20,
                    AppSize.w20,
                    AppSize.h120,
                  ),
                  child: Column(
                    children: [
                      Consumer<RewardsProvider>(
                        builder: (context, provider, _) => _InviteStatsRow(
                          friendsInvited: provider.friendsInvited,
                          coinsEarned: provider.coinsEarned,
                        ),
                      ),
                      SizedBox(height: AppSize.h16),
                      if (isGuest)
                        const _LinkAccountCard()
                      else ...[
                        _EnterReferralCard(isGuest: isGuest),
                        SizedBox(height: AppSize.h16),
                        _ReferralCodeCard(code: referralCode),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({required this.title});

  final String title;

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
            AppSize.w20,
            AppSize.h16,
            AppSize.w20,
            AppSize.h28,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: AppSize.sp20,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invite stats row (Friends Invited / Coins Earned)
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
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _InviteStatTile(
              label: 'Friends Invited',
              value: '$friendsInvited',
              icon: Assets.icons.user,
              iconColor: _kPrimary,
            ),
          ),
          SizedBox(width: AppSize.w12),
          Expanded(
            child: _InviteStatTile(
              label: 'Coins Earned',
              value: '$coinsEarned',
              icon: Assets.icons.coins,
              iconColor: _kCoin,
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteStatTile extends StatelessWidget {
  const _InviteStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final SvgGenImage icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        children: [
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSize.h8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon.svg(
                height: AppSize.sp20,
                width: AppSize.sp20,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
              SizedBox(width: AppSize.w8),
              Text(
                value,
                style: context.textTheme.titleMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Link Account prompt (for guest users)
// ─────────────────────────────────────────────────────────────────────────────

class _LinkAccountCard extends StatelessWidget {
  const _LinkAccountCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSize.r20),
      onTap: () {
        AnalyticsManager.instance.logEvent(name: 'rewards_link_account_tap');
        context.go('/${AppRoutes.profile}');
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.w20,
          vertical: AppSize.h24,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSize.r20),
          border: Border.all(color: _kCardBorder),
        ),
        child: Column(
          children: [
            Icon(
              Icons.link_rounded,
              color: _kPrimary,
              size: AppSize.sp40,
            ),
            SizedBox(height: AppSize.h8),
            Text(
              'Link Your Account',
              style: context.textTheme.titleSmall?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppSize.h6),
            Text(
              'Sign in with Google to get your referral code and invite friends, Go to Profile and link your account.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: _kMutedText,
                height: 1.4,
              ),
            ),
          ],
        ),
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
    final provider = context.watch<RewardsProvider>();

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSize.w20,
        AppSize.h20,
        AppSize.w20,
        AppSize.h20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSize.r20),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        children: [
          Text(
            'Enter Referral Code',
            style: context.textTheme.titleSmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSize.h16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: provider.referralController,
                  enabled: !isGuest && !provider.isApplyingReferral,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Have Promo Code',
                    hintStyle: context.textTheme.bodyMedium?.copyWith(
                      color: _kMutedText,
                    ),
                    errorText: provider.errorText,
                    filled: true,
                    fillColor: _kInputFill,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSize.w18,
                      vertical: AppSize.h14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSize.r100),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSize.r100),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSize.r100),
                      borderSide: const BorderSide(
                        color: _kPrimary,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSize.w10),
              _PrimaryPill(
                label: provider.isApplyingReferral ? '...' : 'Apply',
                expand: false,
                onPressed: () {
                  if (isGuest) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please link your account first'),
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
// Your Referral Code display card
// ─────────────────────────────────────────────────────────────────────────────

class _ReferralCodeCard extends StatelessWidget {
  const _ReferralCodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w20,
        vertical: AppSize.h22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSize.r20),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        children: [
          Text(
            'Your Referral Code',
            style: context.textTheme.titleSmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSize.h16),
          // Code chip
          GestureDetector(
            onTap: () {
              AnalyticsManager.instance.logEvent(name: 'referral_code_copied');
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Code copied!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSize.w24,
                vertical: AppSize.h14,
              ),
              decoration: BoxDecoration(
                color: _kInputFill,
                borderRadius: BorderRadius.circular(AppSize.r12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      code,
                      style: context.textTheme.titleLarge?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        fontSize: AppSize.sp22,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: AppSize.w10),
                  Icon(
                    Icons.copy_rounded,
                    color: Colors.black.withValues(alpha: 0.55),
                    size: AppSize.sp20,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSize.h20),
          _PrimaryPill(
            label: 'Share Link',
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
// Shared blue pill button
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryPill extends StatelessWidget {
  const _PrimaryPill({
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
          padding: EdgeInsets.symmetric(horizontal: AppSize.w28),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_kPrimaryLight, _kPrimary],
            ),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.30),
                blurRadius: AppSize.r12,
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
