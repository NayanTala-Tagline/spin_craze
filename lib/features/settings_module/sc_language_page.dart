import 'package:ad_manager/ad_manager.dart';
import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/extension/ext_string_alert.dart';
import 'package:spin_craze/features/onboarding_module/provider/sc_selection_ad_provider.dart';
import 'package:spin_craze/features/onboarding_module/widgets/sc_onboarding_step_indicator.dart';
import 'package:spin_craze/gen/fonts.gen.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/navigation_helper.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:spin_craze/features/onboarding_module/widgets/sc_ad_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Arguments passed via GoRouter `extra` to preload the language page ads
/// on the previous screen (onboarding pages or profile page).
///
/// When any ad is passed in, [ScLanguagePage] uses it directly and is
/// responsible for disposing it. When a slot is null, [ScLanguagePage] falls
/// back to loading that ad itself.
class ScLanguagePageArgs {
  const ScLanguagePageArgs({
    required this.isOnboarding,
    this.languageNativeAd,
    this.languageNative2Ad,
  });

  final bool isOnboarding;
  final InlineAdManager? languageNativeAd;
  final InlineAdManager? languageNative2Ad;
}

// ── Palette ──────────────────────────────────────────────────────────────────
// Shared with the onboarding redesign. Local to this file so the rest of the
// app (still on the dark theme) is untouched.
const _bgGradient = LinearGradient(
  colors: [Color(0xFFF3F7FF), Color(0xFFE7EFFF)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);
const _titleColor = Color(0xFF0A1A33);
const _bodyColor = Color(0xFF55617A);
const _accentBlue = Color(0xFF1B4FF5);
const _pillBorder = Color(0xFFB2D3FF);
const _pillUnselected = Color(0xFFFFFFFF);
const _pillTextColor = Color(0xFF3D3E40);
const _statusBarStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);

/// Language picker page.
///
/// Two flows:
///
/// 1. **Onboarding** ([isOnboarding] = `true`):
///    - No language is selected by default.
///    - Shows `languageNative` in the [ScAdSlot] until the user taps a
///      language; then swaps to `languageNative2`.
///    - "Get Started" is disabled until a language is picked; tapping it calls
///      [onContinue] which routes to login.
///
/// 2. **Settings** ([isOnboarding] = `false`):
///    - Defaults to the language the user chose during onboarding (read from
///      [AppDB]). Falls back to English if none was saved.
///    - Always shows the `languageNative` ad in the [ScAdSlot].
///
/// Ad managers are normally pre-loaded by the previous screen and passed in
/// via [preloadedAd1] / [preloadedAd2]. When those are null (e.g. deep-link
/// or other direct navigation), this page loads the ads itself.
class ScLanguagePage extends StatefulWidget {
  const ScLanguagePage({
    super.key,
    this.isOnboarding = false,
    this.onContinue,
    this.preloadedAd1,
    this.preloadedAd2,
  });

  final bool isOnboarding;

  /// Called on "Get Started" (onboarding only); receives the country screen's
  /// pre-loaded ads to hand off.
  final void Function(ScSelectionAds? countryAds)? onContinue;

  /// `languageNative` ad manager pre-loaded by the previous screen.
  final InlineAdManager? preloadedAd1;

  /// `languageNative2` ad manager pre-loaded by the previous screen (onboarding only).
  final InlineAdManager? preloadedAd2;

  @override
  State<ScLanguagePage> createState() => _ScLanguagePageState();
}

class _ScLanguagePageState extends State<ScLanguagePage> {
  InlineAdManager? _nativeAd1;
  InlineAdManager? _nativeAd2;
  bool _showSecondAd = false;

  /// Country screen ads pre-loaded while this screen is shown (onboarding only),
  /// handed off to [ScCountryPage] on "Get Started".
  ScSelectionAds? _countryAds;
  bool _countryAdsTransferred = false;

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
      screenClass: 'ScLanguagePage',
    );
    _initSelectedLanguage();
    _initAds();
    _preloadCountryAds();
  }

  /// Pre-load the next screen's (country) native + interstitial so they're
  /// ready the moment the user taps "Get Started".
  void _preloadCountryAds() {
    if (!widget.isOnboarding) return;
    final native = InlineAdManager(
      adData: RemoteConfigService.instance.countryNative,
    )..load();
    final inter = FullScreenAdManager(
      adData: RemoteConfigService.instance.countryInter,
    )..load();
    _countryAds = ScSelectionAds(native: native, inter: inter);
  }

  void _initSelectedLanguage() {
    if (widget.isOnboarding) {
      _selected = null;
      return;
    }
    final saved = Injector.instance<AppDB>().selectedLanguage;
    _selected = (saved != null && _languages.any((l) => l['code'] == saved))
        ? saved
        : _languages.first['code']!;
  }

  void _initAds() {
    if (widget.preloadedAd1 != null) {
      _nativeAd1 = widget.preloadedAd1;
      _nativeAd1!.future().then((_) {
        if (mounted) setState(() {});
      });
    } else {
      final ad1Data = RemoteConfigService.instance.languageNative;
      if (ad1Data.enabled || ad1Data.adType == AdType.custom) {
        _nativeAd1 = InlineAdManager(adData: ad1Data);
        _nativeAd1!.load();
        _nativeAd1!.future().then((_) {
          if (mounted) setState(() {});
        });
      }
    }

    if (!widget.isOnboarding) return;

    if (widget.preloadedAd2 != null) {
      _nativeAd2 = widget.preloadedAd2;
      _nativeAd2!.future().then((_) {
        if (mounted) setState(() {});
      });
    } else {
      final ad2Data = RemoteConfigService.instance.languageNative2;
      if (ad2Data.enabled || ad2Data.adType == AdType.custom) {
        _nativeAd2 = InlineAdManager(adData: ad2Data);
        _nativeAd2!.load();
        _nativeAd2!.future().then((_) {
          if (mounted) setState(() {});
        });
      }
    }
  }

  @override
  void dispose() {
    _nativeAd1?.dispose();
    _nativeAd2?.dispose();
    if (!_countryAdsTransferred) _countryAds?.dispose();
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
      if (widget.isOnboarding && !_showSecondAd) {
        _showSecondAd = true;
      }
    });
  }

  void _saveLanguage() {
    if (_selected != null) {
      Injector.instance<AppDB>().selectedLanguage = _selected;
    }
  }

  InlineAdManager? get _activeAd {
    if (widget.isOnboarding && _showSecondAd) return _nativeAd2;
    return _nativeAd1;
  }

  void _onGetStarted() {
    if (widget.isOnboarding && _selected == null) {
      context.l10n.pleaseSelectLanguage.showInfoAlert();
      return;
    }
    _saveLanguage();
    AnalyticsManager.instance.logEvent(
      name: 'language_get_started',
      parameters: {'language': _selected ?? 'unknown'},
    );
    _countryAdsTransferred = true;
    widget.onContinue?.call(_countryAds);
  }

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _statusBarStyle,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          NavigationHelper().handleBackPress(context);
        },
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: _bgGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isOnboarding)
                  _ScOnboardingTopBar(
                    getStartedLabel: context.l10n.getStarted,
                    onGetStarted: _onGetStarted,
                  )
                else
                  _ScSettingsTopBar(
                    title: context.l10n.language,
                    confirmLabel: context.l10n.confirm,
                    onBack: () => NavigationHelper().handleBackPress(context),
                    onConfirm: _onSave,
                  ),

                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSize.w24,
                    widget.isOnboarding ? AppSize.h12 : AppSize.h4,
                    AppSize.w24,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.setDefaultLanguage,
                        style: TextStyle(
                          fontFamily: FontFamily.sFPro,
                          fontWeight: FontWeight.w800,
                          fontSize: AppSize.sp24,
                          color: _titleColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                      SizedBox(height: AppSize.h10),
                      Text(
                        context.l10n.setDefaultLanguageDesc,
                        style: TextStyle(
                          fontFamily: FontFamily.sFPro,
                          fontWeight: FontWeight.w400,
                          fontSize: AppSize.sp14,
                          height: 1.5,
                          color: _bodyColor,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppSize.h20),

                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      AppSize.w24,
                      0,
                      AppSize.w24,
                      AppSize.h16,
                    ),
                    itemCount: _languages.length,
                    separatorBuilder: (_, _) => SizedBox(height: AppSize.h12),
                    itemBuilder: (context, i) {
                      final language = _languages[i];
                      final languageCode = language['code']!;
                      final languageName = language['name']!;
                      return _ScLanguageRow(
                        label: languageName,
                        selected: languageCode == _selected,
                        onTap: () => _onLanguageTap(languageCode),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

            bottomNavigationBar: ScAdSlot(
              key: ValueKey(_showSecondAd ? 'ad2' : 'ad1'),
              ad: _activeAd,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ScOnboardingTopBar extends StatelessWidget {
  const _ScOnboardingTopBar({
    required this.getStartedLabel,
    required this.onGetStarted,
  });

  final String getStartedLabel;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSize.w24,
        AppSize.h12,
        AppSize.w20,
        AppSize.h4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const ScOnboardingStepIndicator(currentPage: 3, pageCount: 7),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onGetStarted,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSize.w4,
                vertical: AppSize.h6,
              ),
              child: Text(
                getStartedLabel,
                style: TextStyle(
                  fontFamily: FontFamily.sFPro,
                  fontWeight: FontWeight.w700,
                  fontSize: AppSize.sp15,
                  color: _titleColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScSettingsTopBar extends StatelessWidget {
  const _ScSettingsTopBar({
    required this.title,
    required this.confirmLabel,
    required this.onBack,
    required this.onConfirm,
  });

  final String title;
  final String confirmLabel;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSize.w4,
        AppSize.h6,
        AppSize.w12,
        AppSize.h4,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: _titleColor,
              size: AppSize.sp22,
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(right: AppSize.w36),
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: FontFamily.sFPro,
                    fontWeight: FontWeight.w700,
                    fontSize: AppSize.sp18,
                    color: _titleColor,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onConfirm,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSize.w8,
                vertical: AppSize.h6,
              ),
              child: Text(
                confirmLabel,
                style: TextStyle(
                  fontFamily: FontFamily.sFPro,
                  fontWeight: FontWeight.w700,
                  fontSize: AppSize.sp14,
                  color: _accentBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScLanguageRow extends StatelessWidget {
  const _ScLanguageRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(40);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: AppSize.h52,
          padding: EdgeInsets.symmetric(horizontal: AppSize.w22),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: selected ? _accentBlue : _pillUnselected,
            border: Border.all(
              color: selected ? Colors.transparent : _pillBorder,
              width: 2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _accentBlue.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0xD4B0C3F8),
                      blurRadius: 7.5,
                      blurStyle: BlurStyle.inner,
                    ),
                  ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: FontFamily.sFPro,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: AppSize.sp15,
                    color: selected ? Colors.white : _pillTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _ScRadio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScRadio extends StatelessWidget {
  const _ScRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final size = AppSize.sp22;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? Colors.white : _pillTextColor,
          width: 1.4,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: size * 0.42,
                height: size * 0.42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }
}
