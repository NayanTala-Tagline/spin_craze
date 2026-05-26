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
import 'package:spin_craze/widgets/loading_overlay/loading_overlay.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Profile / settings screen.
///
/// The screen background and bottom navigation are owned by `BottomNavPage`,
/// so this is a transparent [Scaffold] that lays out the content.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  final _db = Injector.instance<AppDB>();
  NativeAdManager? _settingNativeAd;

  /// Pre-loaded so the language page can show its native ad immediately.
  /// Handed off to the language page on tap — we stop owning it after that.
  NativeAdManager? _languageNativeAd;
  bool _languageAdTransferred = false;

  late final AnimationController _entrance;
  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logScreenView(
      screenName: 'profile',
      screenClass: 'ProfilePage',
    );

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _progress.forward();
    });

    // Pre-load the language page ad so it's ready on navigation.
    final langAdData = RemoteConfigService.instance.languageNative;
    if (langAdData.enabled || langAdData.isCustomAd) {
      _languageNativeAd = NativeAdManager(adData: langAdData);
      _languageNativeAd!.load();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _progress.dispose();
    if (!_languageAdTransferred) {
      _languageNativeAd?.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    AnalyticsManager.instance.logEvent(name: 'profile_sign_out_tap');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SignOutDialog(),
    );
    if (confirmed != true) return;
    if (!mounted) return;

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
      'Google account linked successfully!'.showSuccessAlert();
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
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSize.w20,
              AppSize.h24,
              AppSize.w20,
              AppSize.h120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSize.h32),
                _Staggered(
                  controller: _entrance,
                  start: 0.0,
                  end: 0.55,
                  curve: Curves.easeOutBack,
                  offsetY: 0,
                  scaleFrom: 0.6,
                  child: Center(
                    child: _ProfileAvatar(
                      initial: initial,
                      photoUrl: user?.photoUrl,
                    ),
                  ),
                ),
                SizedBox(height: AppSize.h16),
                _Staggered(
                  controller: _entrance,
                  start: 0.20,
                  end: 0.65,
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: context.themeTextColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: AppSize.sp22,
                    ),
                  ),
                ),
                SizedBox(height: AppSize.h4),
                _Staggered(
                  controller: _entrance,
                  start: 0.25,
                  end: 0.70,
                  child: Text(
                    email,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.themeTextColors.primary.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSize.h6),
                _Staggered(
                  controller: _entrance,
                  start: 0.30,
                  end: 0.75,
                  child: _LevelLine(level: level, tier: tier),
                ),
                SizedBox(height: AppSize.h24),
                _Staggered(
                  controller: _entrance,
                  start: 0.35,
                  end: 0.85,
                  child: _LevelProgressCard(
                    percent: percent,
                    animation: _progress,
                  ),
                ),
                SizedBox(height: AppSize.h16),
                _Staggered(
                  controller: _entrance,
                  start: 0.40,
                  end: 0.90,
                  child: _StatsRow(
                    coins: coins,
                    xp: xp,
                    streak: user?.totalClaimDays ?? 0,
                  ),
                ),
                SizedBox(height: AppSize.h16),
                if (isGuest)
                  _StaggeredRow(
                    controller: _entrance,
                    index: 0,
                    child: _SettingNavRow(
                      icon: Assets.icons.settings.lock,
                      label: 'Link Google Account',
                      onTap: _handleLinkGoogle,
                    ),
                  ),
                _StaggeredRow(
                  controller: _entrance,
                  index: 1,
                  child: _SettingNavRow(
                    icon: Assets.icons.settings.translate,
                    label: 'Language',
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
                ),
                _StaggeredRow(
                  controller: _entrance,
                  index: 2,
                  child: _SettingNavRow(
                    icon: Assets.icons.settings.headset,
                    label: 'Support',
                    onTap: () {
                      AnalyticsManager.instance.logEvent(
                        name: 'profile_support_tap',
                      );
                      context.pushNamed(AppRoutes.support);
                    },
                  ),
                ),
                _StaggeredRow(
                  controller: _entrance,
                  index: 3,
                  child: _SettingNavRow(
                    icon: Assets.icons.settings.lock,
                    label: 'Privacy Policy',
                    onTap: () {
                      AnalyticsManager.instance.logEvent(
                        name: 'profile_privacy_policy_tap',
                      );
                      privacyPolicy();
                    },
                  ),
                ),
                _StaggeredRow(
                  controller: _entrance,
                  index: 4,
                  child: _SettingNavRow(
                    icon: Assets.icons.settings.note,
                    label: 'Terms & Condition',
                    onTap: () {
                      AnalyticsManager.instance.logEvent(
                        name: 'profile_terms_tap',
                      );
                      termsOfService();
                    },
                  ),
                ),
                _StaggeredRow(
                  controller: _entrance,
                  index: 5,
                  child: _RateUsRow(onTap: _handleRateUs),
                ),
                _StaggeredRow(
                  controller: _entrance,
                  index: 6,
                  child: _DeleteAccountButton(onTap: _handleDeleteAccount),
                ),
                SizedBox(height: AppSize.h8),
                _StaggeredRow(
                  controller: _entrance,
                  index: 7,
                  child: _SignOutButton(onTap: _handleSignOut),
                ),
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
// Animation helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Staggered extends StatelessWidget {
  const _Staggered({
    required this.controller,
    required this.start,
    required this.end,
    required this.child,
    this.curve = Curves.easeOutCubic,
    this.offsetY = 16,
    this.scaleFrom = 1.0,
  });

  final AnimationController controller;
  final double start;
  final double end;
  final Widget child;
  final Curve curve;
  final double offsetY;
  final double scaleFrom;

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: curve),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, _) {
        final t = anim.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * offsetY),
            child: Transform.scale(
              scale: scaleFrom + (1 - scaleFrom) * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _StaggeredRow extends StatelessWidget {
  const _StaggeredRow({
    required this.controller,
    required this.index,
    required this.child,
  });

  final AnimationController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Rows animate in between 0.45–1.0, each offset by 0.05.
    final base = 0.45 + (index * 0.05);
    final start = base.clamp(0.0, 0.95);
    final end = (start + 0.40).clamp(0.0, 1.0);
    return _Staggered(
      controller: controller,
      start: start,
      end: end,
      offsetY: 14,
      child: child,
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
    final primary = context.themeColors.primary;
    return Container(
      width: AppSize.sp120,
      height: AppSize.sp120,
      decoration: BoxDecoration(
        color: const Color(0xFFE4ECFF),
        borderRadius: BorderRadius.circular(AppSize.r28),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
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
          color: const Color(0xFF0A2A6B),
          fontWeight: FontWeight.w700,
          fontSize: AppSize.sp56,
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
    final mutedColor = context.themeTextColors.primary.withValues(alpha: 0.55);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Lv. $level',
          style: context.textTheme.bodySmall?.copyWith(
            color: mutedColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: AppSize.w10),
        Text(
          tier,
          style: context.textTheme.bodySmall?.copyWith(
            color: mutedColor,
            fontWeight: FontWeight.w600,
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
          Expanded(child: _StatTile(data: stats[i], index: i)),
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
  const _StatTile({required this.data, required this.index});

  final _StatTileData data;
  final int index;

  @override
  Widget build(BuildContext context) {
    final textColors = context.themeTextColors;
    final borderColor = textColors.primary.withValues(alpha: 0.10);
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 80)),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (_, t, child) => Transform.translate(
        offset: Offset(0, (1 - t) * 12),
        child: Opacity(opacity: t, child: child),
      ),
      child: Container(
        height: AppSize.h70,
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.w10,
          vertical: AppSize.h10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSize.r12),
          color: Colors.white,
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              data.label,
              style: context.textTheme.bodySmall?.copyWith(
                color: textColors.primary.withValues(alpha: 0.55),
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
  const _LevelProgressCard({required this.percent, required this.animation});

  /// 0..1 progress.
  final double percent;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final textColors = context.themeTextColors;
    final colors = context.themeColors;

    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        final eased = Curves.easeOutCubic.transform(animation.value);
        final animatedPercent = (percent * eased).clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Level Progress',
                    style: context.textTheme.titleSmall?.copyWith(
                      color: textColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${(animatedPercent * 100).round()}%',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: textColors.primary.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSize.h12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSize.r100),
              child: LinearProgressIndicator(
                value: animatedPercent,
                minHeight: AppSize.h8,
                backgroundColor: textColors.primary.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Setting rows
// ─────────────────────────────────────────────────────────────────────────────

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
        color: context.themeTextColors.primary.withValues(alpha: 0.45),
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
            vertical: AppSize.h14,
          ),
          child: Row(
            children: [
              icon.svg(
                height: AppSize.sp22,
                width: AppSize.sp22,
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
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.r12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.w4,
            vertical: AppSize.h10,
          ),
          child: Text(
            'Sign Out',
            style: context.textTheme.titleMedium?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rate us / Delete account
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
            vertical: AppSize.h14,
          ),
          child: Row(
            children: [
              Icon(
                Icons.star_outline_rounded,
                color: textColors.primary,
                size: AppSize.sp22,
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
                color: textColors.primary.withValues(alpha: 0.45),
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
                Icons.delete_outline_rounded,
                color: const Color(0xFFFF5183),
                size: AppSize.sp22,
              ),
              SizedBox(width: AppSize.w14),
              Text(
                'Delete Account',
                style: context.textTheme.titleSmall?.copyWith(
                  color: const Color(0xFFFF5183),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
      backgroundColor: Colors.white,
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
            'Delete Account?',
            style: context.textTheme.titleLarge?.copyWith(
              color: const Color(0xFFFF5183),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Text(
        'This will permanently remove your account, coins, and progress. This action cannot be undone.',
        textAlign: TextAlign.center,
        style: context.textTheme.bodyMedium?.copyWith(
          color: textColors.primary.withValues(alpha: 0.65),
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
                  backgroundColor: textColors.primary.withValues(alpha: 0.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSize.r10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: AppSize.h12),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
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
                  'Delete',
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

class _SignOutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textColors = context.themeTextColors;
    const accent = Color(0xFF004CD9);
    return AlertDialog(
      backgroundColor: Colors.white,
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
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.logout_rounded,
              color: accent,
              size: AppSize.w32,
            ),
          ),
          SizedBox(height: AppSize.h14),
          Text(
            'Sign Out',
            style: context.textTheme.titleLarge?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to sign out of your account?',
        textAlign: TextAlign.center,
        style: context.textTheme.bodyMedium?.copyWith(
          color: textColors.primary.withValues(alpha: 0.65),
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
                  backgroundColor: textColors.primary.withValues(alpha: 0.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSize.r10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: AppSize.h12),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
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
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSize.r10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: AppSize.h12),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Sign Out',
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
