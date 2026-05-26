import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/provider/open_ad_provider.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/navigation_helper.dart';
import 'package:spin_craze/widgets/common_background.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Root scaffold for the four bottom-nav branches.
///
/// Wired into [appRouter] via [StatefulShellRoute.indexedStack] so each branch
/// keeps its own navigator stack and state across switches.
class BottomNavPage extends StatelessWidget {
  const BottomNavPage({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => OpenAdProvider()..startOpenAdListener(),
      lazy: false,
      child: CommonBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: navigationShell,
          bottomNavigationBar: Builder(
            builder: (context) => _BottomNavBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) {
                NavigationHelper().navigateWithAdCheck(context, () {
                  navigationShell.goBranch(
                    index,
                    // Pop to first route on the branch when re-tapping its tab.
                    initialLocation: index == navigationShell.currentIndex,
                  );
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static final _items = <_NavItemData>[
    _NavItemData('Home', Assets.images.navIcons.home),
    _NavItemData('Rank', Assets.images.navIcons.rank),
    _NavItemData('Rewards', Assets.images.navIcons.rewards),
    _NavItemData('Profile', Assets.images.navIcons.user),
  ];

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSize.r32);

    return Container(
      margin: EdgeInsets.fromLTRB(AppSize.w14, 0, AppSize.w14, AppSize.h14),
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w8,
        vertical: AppSize.h8,
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        // Soft lavender-white pill matching the mockup.
        color: const Color(0xFFEEF1F8),
        border: Border.all(
          color: const Color(0xFFDDE3EF),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1F4D).withValues(alpha: 0.06),
            blurRadius: AppSize.r24,
            offset: Offset(0, AppSize.h8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            return _NavItem(
              data: _items[i],
              selected: i == currentIndex,
              onTap: () => onTap(i),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData(this.label, this.icon);
  final String label;
  final AssetGenImage icon;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSize.r22);
    const unselectedColor = Color(0xFF1E2233);
    final iconColor = selected ? Colors.white : unselectedColor;
    final textColor = selected ? Colors.white : unselectedColor;

    return Flexible(
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: AppSize.h70,
            height: AppSize.h70,
            decoration: BoxDecoration(
              borderRadius: radius,
              // Vertical blue gradient on the selected tile — brighter at the
              // top, deeper indigo at the bottom — matching the mockup.
              gradient: selected
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF5577FF), Color(0xFF1E3FE0)],
                    )
                  : null,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2D5BFF).withValues(alpha: 0.35),
                        blurRadius: AppSize.r18,
                        offset: Offset(0, AppSize.h8),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  data.icon.image(
                    height: AppSize.sp26,
                    width: AppSize.sp26,
                    color: iconColor,
                  ),
                  SizedBox(height: AppSize.h6),
                  Text(
                    data.label,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: textColor,
                      fontSize: AppSize.sp13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
