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
    final radius = BorderRadius.circular(AppSize.r16);

    return Container(
      margin: EdgeInsets.fromLTRB(AppSize.w30, 0, AppSize.w30, AppSize.h12),
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w6,
        vertical: AppSize.h8,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: radius,
        // Flat deep cyan-teal base matching the app bar and mockup.
        color: const Color(0xFF0B4E6A),
        border: Border.all(
          color: const Color(0xFF5CCBF7).withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B7FF).withValues(alpha: 0.25),
            blurRadius: AppSize.r24,
            offset: Offset(0, AppSize.h8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cyan glow anchored to the top-left corner.
          Positioned(
            left: -AppSize.w60,
            top: -AppSize.h60,
            child: IgnorePointer(
              child: Container(
                width: AppSize.sp120,
                height: AppSize.sp120,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xCC29B0E6), Color(0x0029B0E6)],
                  ),
                ),
              ),
            ),
          ),
          // Cyan glow anchored to the bottom-right corner.
          Positioned(
            right: -AppSize.w60,
            bottom: -AppSize.h60,
            child: IgnorePointer(
              child: Container(
                width: AppSize.sp120,
                height: AppSize.sp120,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xCC29B0E6), Color(0x0029B0E6)],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
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
        ],
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
    final radius = BorderRadius.circular(AppSize.r12);

    return Flexible(
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: AppSize.h58,
            height: AppSize.h58,
            // padding: EdgeInsets.symmetric(
            //   horizontal: AppSize.w4,
            //   vertical: AppSize.h4,
            // ),
            decoration: BoxDecoration(
              borderRadius: radius,
              // Pale-cyan gradient tile when selected, matching Claim Now /
              // Withdraw buttons.
              gradient: selected
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF9AE0FA), Color(0xFF5CCBF7)],
                    )
                  : null,
              border: selected
                  ? Border.all(color: const Color(0xFFB8ECFF))
                  : null,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF5CCBF7).withValues(alpha: 0.5),
                        blurRadius: AppSize.r20,
                        offset: Offset(0, AppSize.h6),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  data.icon.image(
                    height: AppSize.sp24,
                    width: AppSize.sp24,
                    color: Colors.white,
                  ),
                  SizedBox(height: AppSize.h4),
                  Text(
                    data.label,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontSize: AppSize.sp12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
