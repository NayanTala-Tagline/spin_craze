import 'package:ad_manager/ad_manager.dart';
import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/extension/ext_string_alert.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/navigation_helper.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:spin_craze/widgets/bottom_ads_widget.dart';
import 'package:spin_craze/widgets/common_appbar.dart';
import 'package:spin_craze/widgets/common_background.dart';
import 'package:flutter/material.dart';
import 'package:spin_craze/extension/ext_localization.dart';

/// Arguments passed via GoRouter `extra` to preload the language page ads
/// on the previous screen (onboarding pages or profile page).
///
/// When any ad is passed in, [LanguagePage] uses it directly and is
/// responsible for disposing it. When a slot is null, [LanguagePage] falls
/// back to loading that ad itself.
class LanguagePageArgs {
  const LanguagePageArgs({
    required this.isOnboarding,
    this.languageNativeAd,
    this.languageNative2Ad,
  });

  final bool isOnboarding;
  final NativeAdManager? languageNativeAd;
  final NativeAdManager? languageNative2Ad;
}

/// Language picker page.
///
/// Two flows:
///
/// 1. **Onboarding** ([isOnboarding] = `true`):
///    - No language is selected by default.
///    - Shows `languageNative` in the [BottomAdsWidget] until the user taps a
///      language; then swaps to `languageNative2`.
///    - "Get Started" is disabled until a language is picked; tapping it calls
///      [onContinue] which routes to login.
///
/// 2. **Settings** ([isOnboarding] = `false`):
///    - Defaults to the language the user chose during onboarding (read from
///      [AppDB]). Falls back to English if none was saved.
///    - Always shows the `languageNative` ad in the [BottomAdsWidget].
///
/// Ad managers are normally pre-loaded by the previous screen and passed in
/// via [preloadedAd1] / [preloadedAd2]. When those are null (e.g. deep-link
/// or other direct navigation), this page loads the ads itself.
class LanguagePage extends StatefulWidget {
  const LanguagePage({
    super.key,
    this.isOnboarding = false,
    this.onContinue,
    this.preloadedAd1,
    this.preloadedAd2,
  });

  final bool isOnboarding;
  final VoidCallback? onContinue;

  /// `languageNative` ad manager pre-loaded by the previous screen.
  final NativeAdManager? preloadedAd1;

  /// `languageNative2` ad manager pre-loaded by the previous screen (onboarding only).
  final NativeAdManager? preloadedAd2;

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  NativeAdManager? _nativeAd1;
  NativeAdManager? _nativeAd2;
  bool _showSecondAd = false;

  static const _languages = <Map<String, String>>[
    {'name': 'English', 'code': 'en', 'flag': '🇺🇸'},
    {'name': 'Español', 'code': 'es', 'flag': '🇪🇸'},
    {'name': 'Deutsch', 'code': 'de', 'flag': '🇩🇪'},
    {'name': 'Français', 'code': 'fr', 'flag': '🇫🇷'},
    {'name': 'العربية', 'code': 'ar', 'flag': '🇸🇦'},
    {'name': 'हिन्दी', 'code': 'hi', 'flag': '🇮🇳'},
    {'name': 'Português', 'code': 'pt', 'flag': '🇧🇷'},
    {'name': 'Nederlands', 'code': 'nl', 'flag': '🇳🇱'},
    {'name': 'Kiswahili', 'code': 'sw', 'flag': '🇰🇪'},
    {'name': 'Filipino', 'code': 'fil', 'flag': '🇵🇭'},
    {'name': 'Bahasa Melayu', 'code': 'ms', 'flag': '🇲🇾'},
  ];

  /// Null during onboarding until the user makes a choice.
  String? _selected;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logScreenView(
      screenName: widget.isOnboarding
          ? 'onboarding_language'
          : 'language_settings',
      screenClass: 'LanguagePage',
    );
    _initSelectedLanguage();
    _initAds();
  }

  void _initSelectedLanguage() {
    if (widget.isOnboarding) {
      // No default selection during onboarding.
      _selected = null;
      return;
    }
    // Settings flow — pre-select the language chosen during onboarding.
    final saved = Injector.instance<AppDB>().selectedLanguage;
    _selected = (saved != null && _languages.any((l) => l['code'] == saved))
        ? saved
        : _languages.first['code']!;
  }

  void _initAds() {
    // Ad 1 — languageNative, used in both flows.
    if (widget.preloadedAd1 != null) {
      _nativeAd1 = widget.preloadedAd1;
      // Attach a listener so the UI rebuilds once the ad finishes loading.
      _nativeAd1!.future().then((_) {
        if (mounted) setState(() {});
      });
    } else {
      final ad1Data = RemoteConfigService.instance.languageNative;
      if (ad1Data.enabled || ad1Data.isCustomAd) {
        _nativeAd1 = NativeAdManager(adData: ad1Data);
        _nativeAd1!.load();
        _nativeAd1!.future().then((_) {
          if (mounted) setState(() {});
        });
      }
    }

    // Ad 2 — languageNative2, onboarding only (shown after first tap).
    if (!widget.isOnboarding) return;

    if (widget.preloadedAd2 != null) {
      _nativeAd2 = widget.preloadedAd2;
      _nativeAd2!.future().then((_) {
        if (mounted) setState(() {});
      });
    } else {
      final ad2Data = RemoteConfigService.instance.languageNative2;
      if (ad2Data.enabled || ad2Data.isCustomAd) {
        _nativeAd2 = NativeAdManager(adData: ad2Data);
        _nativeAd2!.load();
        _nativeAd2!.future().then((_) {
          if (mounted) setState(() {});
        });
      }
    }
  }

  @override
  void dispose() {
    // We own whatever ad managers we hold, regardless of where they came
    // from — the previous page transferred ownership to us.
    _nativeAd1?.dispose();
    _nativeAd2?.dispose();
    super.dispose();
  }

  void _onLanguageTap(String languageCode) {
    AnalyticsManager.instance.logEvent(
      name: 'language_selected',
      parameters: {
        'language': languageCode,
        'is_onboarding': widget.isOnboarding ? 1 : 0,
      },
    );
    setState(() {
      _selected = languageCode;
      // Swap to second ad on first language tap (onboarding only).
      if (widget.isOnboarding && !_showSecondAd) {
        _showSecondAd = true;
      }
    });
  }

  /// Persists the selected language to the database.
  void _saveLanguage() {
    if (_selected != null) {
      Injector.instance<AppDB>().selectedLanguage = _selected;
    }
  }

  /// Which native ad should drive the BottomAdsWidget right now.
  NativeAdManager? get _activeAd {
    if (widget.isOnboarding && _showSecondAd) return _nativeAd2;
    return _nativeAd1;
  }

  void _onGetStarted() {
    if (widget.isOnboarding && _selected == null) {
      'Please select a language first'.showInfoAlert();
      return;
    }
    _saveLanguage();
    AnalyticsManager.instance.logEvent(
      name: 'language_get_started',
      parameters: {'language': _selected ?? 'unknown'},
    );
    widget.onContinue?.call();
  }

  /// Settings flow: persist and pop back.
  void _onSave() {
    _saveLanguage();
    AnalyticsManager.instance.logEvent(
      name: 'language_saved',
      parameters: {'language': _selected ?? 'unknown'},
    );
    Navigator.of(context).pop();
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
          appBar: widget.isOnboarding
              ? null
              : CommonAppBar(
                  title: context.l10n.language,
                  showBack: true,
                  trailing: GestureDetector(
                    onTap: _onSave,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSize.w8),
                      child: Text(
                        context.l10n.confirm,
                        style: context.textTheme.titleSmall?.copyWith(
                          color: context.themeTextColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top button (onboarding only) ──────────────────────
                if (widget.isOnboarding) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSize.w20,
                      vertical: AppSize.h8,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _onGetStarted,
                        child: Text(
                          context.l10n.getStarted,
                          style: context.textTheme.titleSmall?.copyWith(
                            color: context.themeTextColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // ── Header text ───────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSize.w20,
                    AppSize.h10,
                    AppSize.w20,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.setDefaultLanguage,
                        style: context.textTheme.titleLarge?.copyWith(
                          color: context.themeTextColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: AppSize.sp22,
                        ),
                      ),
                      SizedBox(height: AppSize.h10),
                      Text(
                        '${context.l10n.languageSelectionMessage.split(
                              ' which',
                            )[0]} app which you can change later if you want to.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.themeTextColors.secondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppSize.h24),

                // ── Language list (scrollable) ─────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      AppSize.w20,
                      0,
                      AppSize.w20,
                      AppSize.h16,
                    ),
                    itemCount: _languages.length,
                    separatorBuilder: (_, _) => SizedBox(height: AppSize.h12),
                    itemBuilder: (context, i) {
                      final language = _languages[i];
                      final languageCode = language['code']!;
                      final languageName = language['name']!;
                      final languageFlag = language['flag']!;
                      return _LanguageRow(
                        label: languageName,
                        flag: languageFlag,
                        selected: languageCode == _selected,
                        onTap: () => _onLanguageTap(languageCode),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Native ad in the bottom nav slot — swaps between languageNative
          // and languageNative2 on first language tap during onboarding.
          bottomNavigationBar: BottomAdsWidget(
            key: ValueKey(_showSecondAd ? 'ad2' : 'ad1'),
            nativeAd: _activeAd,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final textColors = context.themeTextColors;
    final radius = BorderRadius.circular(AppSize.r12);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          height: AppSize.h58,
          padding: EdgeInsets.symmetric(horizontal: AppSize.w20),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF29B0E6), Color(0xFFA86CFF)],
                  )
                : null,
            color: selected ? null : colors.surface,
            border: Border.all(
              color: selected ? Colors.transparent : colors.border,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF29B0E6).withValues(alpha: 0.35),
                      blurRadius: AppSize.r20,
                      offset: Offset(0, AppSize.h6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Text(flag, style: TextStyle(fontSize: AppSize.sp24)),
              SizedBox(width: AppSize.w12),
              Expanded(
                child: Text(
                  label,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: textColors.primary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              _Radio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Container(
        width: AppSize.sp22,
        height: AppSize.sp22,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
      );
    }
    return Container(
      width: AppSize.sp22,
      height: AppSize.sp22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: context.themeTextColors.secondary,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Container(
          width: AppSize.sp10,
          height: AppSize.sp10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.themeTextColors.secondary.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
