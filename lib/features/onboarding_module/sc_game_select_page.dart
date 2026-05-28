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
const _accentBlue = Color(0xFF1B4FF5);
const _pillBorder = Color(0xFFB2D3FF);

/// Onboarding step 3/3 — pick the games you like (multi-select chips).
class ScGameSelectPage extends StatefulWidget {
  const ScGameSelectPage({super.key, required this.onContinue, this.preloaded});

  final VoidCallback onContinue;

  /// Ads pre-loaded by the previous screen (currency).
  final ScSelectionAds? preloaded;

  @override
  State<ScGameSelectPage> createState() => _ScGameSelectPageState();
}

class _ScGameSelectPageState extends State<ScGameSelectPage> {
  final _db = Injector.instance<AppDB>();
  late final ScSelectionAdProvider _ads;

  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logScreenView(
      screenName: 'onboarding_games',
      screenClass: 'ScGameSelectPage',
    );
    // Onboarding flow: always start with nothing selected, even if games were
    // saved on a previous visit (we still persist the new picks on Next).
    _ads = ScSelectionAdProvider(
      preloaded: widget.preloaded,
      nativeData: RemoteConfigService.instance.gameSelectNative,
      interData: RemoteConfigService.instance.gameSelectInter,
      // Last selection screen — nothing to pre-load after this.
    )..addListener(_onAdsChanged);
  }

  void _onAdsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ads.removeListener(_onAdsChanged);
    _ads.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _onNext() async {
    if (_selected.isEmpty) {
      context.l10n.pleasePickGame.showInfoAlert();
      return;
    }
    _db.selectedGames = _selected.toList();
    _db.onboardingCompleted = true;
    AnalyticsManager.instance.logEvent(
      name: 'onboarding_games_selected',
      parameters: {'count': _selected.length},
    );
    await _ads.wait();
    await _ads.showInterstitial();
    if (mounted) widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return ScSelectionScaffold(
      stepIndex: 6,
      title: context.l10n.gamesYouLove,
      subtitle: context.l10n.gamesYouLoveSubtitle,
      nativeAd: _ads.nativeAd,
      isLoading: _ads.isLoading,
      nextLabel: context.l10n.finish,
      onNext: _onNext,
      headerAction: _ScCountBadge(count: _selected.length),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSize.w24,
          AppSize.h4,
          AppSize.w24,
          AppSize.h8,
        ),
        child: Wrap(
          spacing: AppSize.w10,
          runSpacing: AppSize.h12,
          children: [
            for (final g in kGames)
              _ScGameChip(
                game: g,
                selected: _selected.contains(g.id),
                onTap: () => _toggle(g.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScCountBadge extends StatelessWidget {
  const _ScCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w12,
        vertical: AppSize.h6,
      ),
      decoration: BoxDecoration(
        color: count == 0 ? Colors.white : _accentBlue,
        borderRadius: BorderRadius.circular(AppSize.r100),
        border: Border.all(color: _pillBorder, width: 1.5),
      ),
      child: Text(
        context.l10n.gamesSelected(count),
        style: TextStyle(
          fontSize: AppSize.sp12,
          fontWeight: FontWeight.w700,
          color: count == 0 ? _accentBlue : Colors.white,
        ),
      ),
    );
  }
}

class _ScGameChip extends StatelessWidget {
  const _ScGameChip({
    required this.game,
    required this.selected,
    required this.onTap,
  });

  final ScGameOption game;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSize.r100);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.w14,
            vertical: AppSize.h10,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: selected ? _accentBlue : Colors.white,
            border: Border.all(
              color: selected ? Colors.transparent : _pillBorder,
              width: 1.8,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _accentBlue.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(game.emoji, style: TextStyle(fontSize: AppSize.sp16)),
              SizedBox(width: AppSize.w8),
              Text(
                game.name,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: AppSize.sp14,
                  color: selected ? Colors.white : _titleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
