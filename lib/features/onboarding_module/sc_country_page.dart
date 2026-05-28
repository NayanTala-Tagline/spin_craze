import 'package:flutter/material.dart';

import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/extension/ext_string_alert.dart';
import 'package:spin_craze/features/onboarding_module/data/sc_onboarding_options.dart';
import 'package:spin_craze/features/onboarding_module/provider/sc_selection_ad_provider.dart';
import 'package:spin_craze/features/onboarding_module/widgets/sc_selection_scaffold.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/remote_config.dart';

const _titleColor = Color(0xFF0A1A33);
const _bodyColor = Color(0xFF55617A);
const _accentBlue = Color(0xFF1B4FF5);
const _pillBorder = Color(0xFFB2D3FF);
const _fieldFill = Color(0xFFFFFFFF);

/// Onboarding step 1/3 — pick your country (single-select, searchable).
class ScCountryPage extends StatefulWidget {
  const ScCountryPage({super.key, required this.onContinue, this.preloaded});

  /// Called on "Next"; receives the pre-loaded ads for the next screen.
  final void Function(ScSelectionAds? next) onContinue;

  /// Ads pre-loaded by the previous screen (language).
  final ScSelectionAds? preloaded;

  @override
  State<ScCountryPage> createState() => _ScCountryPageState();
}

class _ScCountryPageState extends State<ScCountryPage> {
  final _db = Injector.instance<AppDB>();
  late final ScSelectionAdProvider _ads;
  final _searchCtrl = TextEditingController();

  String _query = '';
  String? _selected;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logScreenView(
      screenName: 'onboarding_country',
      screenClass: 'ScCountryPage',
    );
    // Onboarding flow: always start unselected, even if a value was saved on a
    // previous visit (we still persist the new pick on Next).
    _ads = ScSelectionAdProvider(
      preloaded: widget.preloaded,
      nativeData: RemoteConfigService.instance.countryNative,
      interData: RemoteConfigService.instance.countryInter,
      // Pre-load the next screen (currency) while this one is shown.
      nextNativeData: RemoteConfigService.instance.currencyNative,
      nextInterData: RemoteConfigService.instance.currencyInter,
    )..addListener(_onAdsChanged);
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  void _onAdsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ads.removeListener(_onAdsChanged);
    _ads.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ScCountryOption> get _filtered {
    if (_query.isEmpty) return kCountries;
    return kCountries
        .where((c) => c.name.toLowerCase().contains(_query))
        .toList();
  }

  Future<void> _onNext() async {
    if (_selected == null) {
      context.l10n.pleaseSelectCountry.showInfoAlert();
      return;
    }
    _db.selectedCountry = _selected;
    AnalyticsManager.instance.logEvent(
      name: 'onboarding_country_selected',
      parameters: {'country': _selected ?? 'unknown'},
    );
    await _ads.wait();
    await _ads.showInterstitial();
    if (mounted) widget.onContinue(_ads.takeNext());
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return ScSelectionScaffold(
      stepIndex: 4,
      title: context.l10n.selectYourCountry,
      subtitle: context.l10n.selectCountrySubtitle,
      nativeAd: _ads.nativeAd,
      isLoading: _ads.isLoading,
      nextLabel: context.l10n.next,
      onNext: _onNext,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSize.w24),
            child: _ScSearchField(controller: _searchCtrl),
          ),
          SizedBox(height: AppSize.h12),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      context.l10n.noCountriesFound,
                      style: TextStyle(
                        color: _bodyColor,
                        fontSize: AppSize.sp14,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      AppSize.w24,
                      0,
                      AppSize.w24,
                      AppSize.h8,
                    ),
                    itemCount: list.length,
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (_, _) => SizedBox(height: AppSize.h10),
                    itemBuilder: (context, i) {
                      final c = list[i];
                      return _ScCountryTile(
                        country: c,
                        selected: c.code == _selected,
                        onTap: () => setState(() => _selected = c.code),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ScSearchField extends StatelessWidget {
  const _ScSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: AppSize.sp15, color: _titleColor),
      decoration: InputDecoration(
        hintText: context.l10n.searchCountry,
        hintStyle: TextStyle(color: _bodyColor, fontSize: AppSize.sp14),
        prefixIcon: Icon(Icons.search, color: _bodyColor, size: AppSize.sp22),
        filled: true,
        fillColor: _fieldFill,
        contentPadding: EdgeInsets.symmetric(vertical: AppSize.h12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.r40),
          borderSide: const BorderSide(color: _pillBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.r40),
          borderSide: const BorderSide(color: _accentBlue, width: 1.8),
        ),
      ),
    );
  }
}

class _ScCountryTile extends StatelessWidget {
  const _ScCountryTile({
    required this.country,
    required this.selected,
    required this.onTap,
  });

  final ScCountryOption country;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSize.r40);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: AppSize.h52,
          padding: EdgeInsets.symmetric(horizontal: AppSize.w18),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: selected ? _accentBlue : Colors.white,
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
                : null,
          ),
          child: Row(
            children: [
              Text(country.flag, style: TextStyle(fontSize: AppSize.sp22)),
              SizedBox(width: AppSize.w14),
              Expanded(
                child: Text(
                  country.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: AppSize.sp15,
                    color: selected ? Colors.white : _titleColor,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: Colors.white, size: AppSize.sp22),
            ],
          ),
        ),
      ),
    );
  }
}
