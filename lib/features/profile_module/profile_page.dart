import 'package:ad_manager/ad_manager.dart';
import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/extension/ext_string_alert.dart';
import 'package:spin_craze/features/auth_module/provider/auth_provider.dart';
import 'package:spin_craze/features/settings_module/language_page.dart'
    show LanguagePageArgs;
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_share_helper.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:spin_craze/widgets/glow_container.dart';
import 'package:spin_craze/widgets/loading_overlay/loading_overlay.dart';
import 'package:spin_craze/widgets/native_ads_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spin_craze/extension/ext_localization.dart';

/// Profile / settings screen.
///
/// The screen background and bottom navigation are owned by `BottomNavPage`,
/// so this is a transparent [Scaffold] that lays out the content.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _db = Injector.instance<AppDB>();
  NativeAdManager? _settingNativeAd;

  /// Pre-loaded so the language page can show its native ad immediately.
  /// Handed off to the language page on tap — we stop owning it after that.
  NativeAdManager? _languageNativeAd;
  bool _languageAdTransferred = false;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logScreenView(
      screenName: 'profile',
      screenClass: 'ProfilePage',
    );
    // TODO: Setting Ad
    // final adData = RemoteConfigService.instance.settingNative;
    // if (adData.enabled) {
    //   _settingNativeAd = NativeAdManager(adData: adData);
    //   _settingNativeAd!.load();
    //   _settingNativeAd!.future().then((_) {
    //     if (mounted) setState(() {});
    //   });
    // }

    // Pre-load the language page ad so it's ready on navigation.
    final langAdData = RemoteConfigService.instance.languageNative;
    if (langAdData.enabled || langAdData.isCustomAd) {
      _languageNativeAd = NativeAdManager(adData: langAdData);
      _languageNativeAd!.load();
    }
  }

  @override
  void dispose() {
    // TODO: Setting Ad
    // _settingNativeAd?.dispose();
    if (!_languageAdTransferred) {
      _languageNativeAd?.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    AnalyticsManager.instance.logEvent(name: 'profile_sign_out_tap');
    final auth = AuthProvider();
    await auth.signOut();
    if (mounted) {
      context.goNamed(AppRoutes.login);
    }
  }

  Future<void> _handleDeleteAccount() async {
    AnalyticsManager.instance.logEvent(name: 'profile_delete_account_tap');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteAccountDialog(),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    LoadingOverlay.instance().show(
      context: context,
      text: 'Deleting account...',
    );
    try {
      final db = Injector.instance<AppDB>();
      final userId = db.userModel?.userId;
      if (userId != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .delete();
        } catch (e) {
          debugPrint('Delete account: firestore delete failed: $e');
        }
      }
      final auth = AuthProvider();
      await auth.signOut();
      AnalyticsManager.instance.logEvent(
        name: 'profile_delete_account_success',
      );
    } finally {
      LoadingOverlay.instance().hide();
    }

    if (mounted) {
      context.goNamed(AppRoutes.login);
    }
  }

  Future<void> _handleRateUs() async {
    AnalyticsManager.instance.logEvent(name: 'profile_rate_us_tap');
    try {
      final url = await getPlayStoreUrl();
      await launchURL(url);
    } catch (e) {
      debugPrint('Rate Us: launch failed: $e');
    }
  }

  Future<void> _handleLinkGoogle() async {
    AnalyticsManager.instance.logEvent(name: 'profile_link_google_tap');
    final auth = AuthProvider();
    await auth.linkGoogleAccount();

    if (auth.linkSuccess) {
      AnalyticsManager.instance.logEvent(name: 'profile_link_google_success');
      context.l10n.googleAccountLinkedSuccess.showSuccessAlert();
    } else if (auth.linkErrorMessage != null) {
      AnalyticsManager.instance.logEvent(
        name: 'profile_link_google_failed',
        parameters: {'error': auth.linkErrorMessage ?? 'unknown'},
      );
      auth.linkErrorMessage!.showErrorAlert();
    }

    if (mounted) setState(() {});
  }

  Future<void> launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> privacyPolicy() async {
    try {
      final privacyUrl = RemoteConfigService.instance.privacyPolicyUrl;
      if (privacyUrl.isNotEmpty) {
        await launchURL(privacyUrl);
      } else {
        // Fallback to default URL if remote config is empty
        throw Exception('Privacy policy URL not configured');
      }
    } catch (e) {
      debugPrint('Error launching privacy policy: $e');
      rethrow;
    }
  }

  Future<void> termsOfService() async {
    try {
      final termsUrl = RemoteConfigService.instance.termsAndConditions;
      if (termsUrl.isNotEmpty) {
        await launchURL(termsUrl);
      } else {
        // Fallback to default URL if remote config is empty
        throw Exception('Terms of service URL not configured');
      }
    } catch (e) {
      debugPrint('Error launching terms of service: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _db.userListenable(),
      builder: (context, _) {
        final user = _db.userModel;
        final name = user?.name ?? 'Guest User';
        final email = user?.email ?? 'Not signed in';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';
        final level = user?.level.toInt() ?? 1;
        final xp = user?.xp.toInt() ?? 0;
        final coins = user?.coin.toInt() ?? 0;
        final isGuest = user?.isGuest ?? true;

        // Calculate level progress: XP needed per level is 200
        final xpInLevel = xp % 200;
        final percent = xpInLevel / 200;

        String tier;
        if (level >= 10) {
          tier = 'Expert';
        } else if (level >= 5) {
          tier = 'Intermediate';
        } else {
          tier = 'Beginner';
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSize.w16,
              AppSize.h24,
              AppSize.w16,
              AppSize.h120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: AppSize.h60),
                _ProfileAvatar(initial: initial, photoUrl: user?.photoUrl),
                SizedBox(height: AppSize.h16),
                Text(
                  name,
                  style: context.textTheme.titleLarge?.copyWith(
                    color: context.themeTextColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: AppSize.sp22,
                  ),
                ),
                SizedBox(height: AppSize.h6),
                Text(
                  email,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.themeTextColors.secondary,
                  ),
                ),
                SizedBox(height: AppSize.h6),
                _LevelLine(level: level, tier: tier),
                SizedBox(height: AppSize.h20),
                _StatsRow(
                  coins: coins,
                  xp: xp,
                  streak: user?.totalClaimDays ?? 0,
                ),
                SizedBox(height: AppSize.h16),
                _LevelProgressCard(percent: percent, nextTier: tier),
                SizedBox(height: AppSize.h20),
                if (isGuest)
                  _SettingNavRow(
                    icon: Assets.icons.settings.lock,
                    label: context.l10n.linkGoogleAccount,
                    onTap: _handleLinkGoogle,
                  ),
                _SettingNavRow(
                  icon: Assets.icons.settings.translate,
                  label: context.l10n.language,
                  onTap: () {
                    AnalyticsManager.instance.logEvent(
                      name: 'profile_language_tap',
                    );
                    _languageAdTransferred = true;
                    context.pushNamed(
                      AppRoutes.language,
                      extra: LanguagePageArgs(
                        isOnboarding: false,
                        languageNativeAd: _languageNativeAd,
                      ),
                    );
                  },
                ),
                _SettingNavRow(
                  icon: Assets.icons.settings.headset,
                  label: context.l10n.support,
                  onTap: () {
                    AnalyticsManager.instance.logEvent(
                      name: 'profile_support_tap',
                    );
                    context.pushNamed(AppRoutes.support);
                  },
                ),
                _SettingNavRow(
                  icon: Assets.icons.settings.lock,
                  label: context.l10n.privacyPolicyLabel,
                  onTap: () {
                    AnalyticsManager.instance.logEvent(
                      name: 'profile_privacy_policy_tap',
                    );
                    privacyPolicy();
                  },
                ),
                _SettingNavRow(
                  icon: Assets.icons.settings.note,
                  label: context.l10n.termsAndCondition,
                  onTap: () {
                    AnalyticsManager.instance.logEvent(
                      name: 'profile_terms_tap',
                    );
                    termsOfService();
                  },
                ),
                _RateUsRow(onTap: _handleRateUs),
                _DeleteAccountButton(onTap: _handleDeleteAccount),
                SizedBox(height: AppSize.h8),
                _SignOutButton(onTap: _handleSignOut),
                SizedBox(height: AppSize.h12),
                // TODO: Setting Ad
                // NativeAdsWidget(nativeAd: _settingNativeAd),
                SizedBox(height: AppSize.h12),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.initial, this.photoUrl});

  final String initial;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return GlowContainer(
      accent: Colors.white,
      borderRadius: AppSize.r32,
      child: Container(
        width: AppSize.sp160,
        height: AppSize.sp160,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSize.r32),
          // Purple → blue gradient stroke (top-left → bottom-right).
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFA86CFF), Color(0xFF29B0E6)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA86CFF).withValues(alpha: 0.25),
              blurRadius: AppSize.r24,
              offset: Offset(0, AppSize.h6),
            ),
          ],
        ),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSize.r30),
            color: const Color(0xFF12313D),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasPhoto
              ? Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, _, _) => _AvatarInitial(initial: initial),
                )
              : _AvatarInitial(initial: initial),
        ),
      ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: const Color(0xFFB8C4CC),
          fontWeight: FontWeight.w600,
          fontSize: AppSize.sp64,
          height: 1,
        ),
      ),
    );
  }
}

class _LevelLine extends StatelessWidget {
  const _LevelLine({required this.level, required this.tier});

  final int level;
  final String tier;

  @override
  Widget build(BuildContext context) {
    final textColors = context.themeTextColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Lv. $level',
          style: context.textTheme.bodySmall?.copyWith(
            color: textColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(width: AppSize.w8),
        Text(
          tier,
          style: context.textTheme.bodySmall?.copyWith(
            color: textColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row (Balance / XP / Days / Refs)
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({this.coins = 0, this.xp = 0, this.streak = 0});

  final int coins;
  final int xp;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final stats = <_StatTileData>[
      _StatTileData(
        'Balance',
        '\$${(coins / RemoteConfigService.instance.coinToDollarDivider).toStringAsFixed(3)}',
      ),
      _StatTileData('XP', '$xp'),
      _StatTileData('Days', '$streak'),
      _StatTileData('Refs', '0'),
    ];

    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          Expanded(child: _StatTile(data: stats[i])),
          if (i < stats.length - 1) SizedBox(width: AppSize.w10),
        ],
      ],
    );
  }
}

class _StatTileData {
  const _StatTileData(this.label, this.value);
  final String label;
  final String value;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.data});

  final _StatTileData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final textColors = context.themeTextColors;

    return GlowContainer(
      accent: colors.primary,
      borderRadius: AppSize.r12,
      child: Container(
        height: AppSize.h72,
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.w10,
          vertical: AppSize.h10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSize.r12),
          color: colors.surface,
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              data.label,
              style: context.textTheme.bodySmall?.copyWith(
                color: textColors.secondary,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                data.value,
                style: context.textTheme.titleMedium?.copyWith(
                  color: textColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Level progress
// ─────────────────────────────────────────────────────────────────────────────

class _LevelProgressCard extends StatelessWidget {
  const _LevelProgressCard({required this.percent, required this.nextTier});

  /// 0..1 progress.
  final double percent;
  final String nextTier;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final textColors = context.themeTextColors;

    return GlowContainer(
      accent: colors.primary,
      borderRadius: AppSize.r16,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Level Progress',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: textColors.secondary,
                    ),
                  ),
                ),
                Text(
                  '${(percent * 100).round()}%',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: textColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSize.h10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSize.r100),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: AppSize.h6,
                backgroundColor: const Color(0xFF143A48),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF29B0E6),
                ),
              ),
            ),
            SizedBox(height: AppSize.h10),
            Text(
              'Next: $nextTier',
              style: context.textTheme.bodySmall?.copyWith(
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
// Setting rows
// ─────────────────────────────────────────────────────────────────────────────

class _SettingToggleRow extends StatelessWidget {
  const _SettingToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final SvgGenImage icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingRowShell(
      icon: icon,
      label: label,
      trailing: SizedBox(
        height: AppSize.h30,
        child: Transform.scale(
          scale: 0.9,
          child: Switch(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.zero,
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF22C55E),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF2C4452),
            trackOutlineColor: const WidgetStatePropertyAll<Color>(
              Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingNavRow extends StatelessWidget {
  const _SettingNavRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final SvgGenImage icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SettingRowShell(
      icon: icon,
      label: label,
      onTap: onTap,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: context.themeTextColors.primary,
        size: AppSize.sp24,
      ),
    );
  }
}

class _SettingRowShell extends StatelessWidget {
  const _SettingRowShell({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  final SvgGenImage icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColors = context.themeTextColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.r12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.w4,
            vertical: AppSize.h12,
          ),
          child: Row(
            children: [
              icon.svg(
                height: AppSize.sp24,
                width: AppSize.sp24,
                colorFilter: ColorFilter.mode(
                  textColors.primary,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: AppSize.w14),
              Expanded(
                child: Text(
                  label,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: textColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign out
// ─────────────────────────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSize.r12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.w16,
          vertical: AppSize.h8,
        ),
        child: Text(
          context.l10n.signOut,
          style: context.textTheme.titleSmall?.copyWith(
            color: const Color(0xFFFF5183),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete account
// ─────────────────────────────────────────────────────────────────────────────

class _RateUsRow extends StatelessWidget {
  const _RateUsRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColors = context.themeTextColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.r12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.w4,
            vertical: AppSize.h12,
          ),
          child: Row(
            children: [
              Icon(
                Icons.star_outline,
                color: textColors.primary,
                size: AppSize.sp24,
              ),
              SizedBox(width: AppSize.w14),
              Expanded(
                child: Text(
                  'Rate Us',
                  style: context.textTheme.titleSmall?.copyWith(
                    color: textColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: textColors.primary,
                size: AppSize.sp24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSize.r12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.w4,
          vertical: AppSize.h10,
        ),
        child: Row(
          children: [
            Icon(
              Icons.delete_forever_outlined,
              color: const Color(0xFFFF5183),
              size: AppSize.w24,
            ),
            SizedBox(width: AppSize.w8),
            Text(
              context.l10n.deleteAccount,
              style: context.textTheme.titleSmall?.copyWith(
                color: const Color(0xFFFF5183),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final textColors = context.themeTextColors;
    return AlertDialog(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.r20),
      ),
      titlePadding: EdgeInsets.fromLTRB(
        AppSize.w24,
        AppSize.h28,
        AppSize.w24,
        0,
      ),
      contentPadding: EdgeInsets.fromLTRB(
        AppSize.w24,
        AppSize.h12,
        AppSize.w24,
        0,
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        AppSize.w16,
        AppSize.h16,
        AppSize.w16,
        AppSize.h20,
      ),
      title: Column(
        children: [
          Container(
            width: AppSize.w60,
            height: AppSize.w60,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5183).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.delete_forever_rounded,
              color: const Color(0xFFFF5183),
              size: AppSize.w32,
            ),
          ),
          SizedBox(height: AppSize.h14),
          Text(
            context.l10n.deleteAccountConfirmTitle,
            style: context.textTheme.titleLarge?.copyWith(
              color: const Color(0xFFFF5183),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Text(
        context.l10n.deleteAccountConfirmMessage,
        textAlign: TextAlign.center,
        style: context.textTheme.bodyMedium?.copyWith(
          color: textColors.secondary,
          height: 1.4,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSize.r10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: AppSize.h12),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  context.l10n.cancel,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: textColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSize.w12),
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5183),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSize.r10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: AppSize.h12),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  context.l10n.delete,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
