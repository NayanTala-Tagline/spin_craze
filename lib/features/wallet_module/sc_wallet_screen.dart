import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/features/wallet_module/provider/sc_wallet_provider.dart';
import 'package:spin_craze/features/wallet_module/widgets/sc_wallet_bottom_sheet.dart';
import 'package:spin_craze/features/wallet_module/widgets/sc_wallet_tab_card.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/utils/navigation_helper.dart';
import 'package:spin_craze/widgets/common_appbar.dart';
import 'package:spin_craze/widgets/back_btn.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ScWalletScreen extends StatelessWidget {
  const ScWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsManager.instance.logScreenView(
      screenName: 'wallet',
      screenClass: 'ScWalletScreen',
    );
    return ChangeNotifierProvider(
      create: (context) => ScWalletProvider(),
      child: Consumer<ScWalletProvider>(
        builder: (context, provider, _) {
          final categories = provider.getWalletCategories(context);
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              NavigationHelper().handleBackPress(context);
            },
            child: Scaffold(
              backgroundColor: const Color(0xFFEEF2F9),
              appBar: CommonAppBar(
                title: context.l10n.walletTitle,
                showBack: true,
                trailing: AppBackButton(
                  icon: Icons.history_rounded,
                  iconSize: AppSize.sp28,
                  onTap: () {
                    AnalyticsManager.instance.logEvent(
                      name: 'wallet_history_tap',
                    );
                    context.pushNamed(AppRoutes.walletHistory);
                  },
                ),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: AppSize.h16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSize.w20),
                    child: const _ScBalanceCard(),
                  ),
                  _ScPendingWithdrawBanner(provider: provider),
                  SizedBox(height: AppSize.h22),
                  const _ScSectionDivider(),
                  SizedBox(height: AppSize.h16),
                  _ScCategoryIconTabs(
                    categories: categories,
                    selectedIndex: provider.selectedIndex,
                    onTap: (index) {
                      if (index == provider.selectedIndex) return;
                      provider.setSelectedIndex(index);
                      provider.setWithdrawType(categories[index].title);
                      // jumpToPage (not animateToPage) — animating across far
                      // pages fires onPageChanged for every intermediate
                      // integer, which made every circle flash selected.
                      provider.pageController.jumpToPage(index);
                    },
                  ),
                  SizedBox(height: AppSize.h14),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSize.w24),
                    child: Text(
                      categories[provider.selectedIndex].title,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'SFPro',
                        color: const Color(0xFF0E1A2B),
                        fontWeight: FontWeight.w700,
                        fontSize: AppSize.sp15,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSize.h14),
                  Expanded(
                    child: Container(
                      color: const Color(0xFFE2E8F2),
                      child: PageView.builder(
                        controller: provider.pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) {
                          provider.setSelectedIndex(index);
                          provider.setWithdrawType(categories[index].title);
                        },
                        itemCount: categories.length,
                        itemBuilder: (context, pageIndex) {
                          final items = categories[pageIndex].items;
                          return GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              AppSize.w20,
                              AppSize.h16,
                              AppSize.w20,
                              AppSize.h20,
                            ),
                            itemCount: items.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: AppSize.w12,
                                  mainAxisSpacing: AppSize.h12,
                                  childAspectRatio: 1.0,
                                ),
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  provider.setWithdrawSubType(
                                    items[index].title,
                                  );
                                  AnalyticsManager.instance.logEvent(
                                    name: 'wallet_method_tap',
                                    parameters: {
                                      'category': categories[pageIndex].title,
                                      'method': items[index].title,
                                    },
                                  );

                                  showModalBottomSheet(
                                    context: rootNavKey.currentContext!,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) {
                                      return ChangeNotifierProvider.value(
                                        value: provider,
                                        child: ScWalletBottomSheet(
                                          item: items[index],
                                        ),
                                      );
                                    },
                                  ).then((_) {
                                    provider.resetWithdrawForm();
                                  });
                                },
                                child: ScWalletTabCard(item: items[index]),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Balance card ────────────────────────────────────────────────────────────

class _ScBalanceCard extends StatelessWidget {
  const _ScBalanceCard();

  @override
  Widget build(BuildContext context) {
    final db = Injector.instance<AppDB>();
    return StreamBuilder(
      stream: db.userListenable(),
      builder: (context, _) {
        final coins = db.userModel?.coin ?? 0;
        final divider = RemoteConfigService.instance.coinToDollarDivider;
        final dollarValue = coins / divider;
        final minWithdraw =
            RemoteConfigService.instance.minWithdrawAmount / divider;
        return _buildBalanceCard(context, coins, dollarValue, minWithdraw);
      },
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    num coins,
    double dollarValue,
    double minWithdraw,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w24,
        vertical: AppSize.h22,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.r20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A66FF), Color(0xFF0040E0)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A66FF).withValues(alpha: 0.35),
            blurRadius: AppSize.r24,
            offset: Offset(0, AppSize.h8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            context.l10n.availableBalance,
            style: TextStyle(
              fontFamily: 'SFPro',
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: AppSize.sp14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppSize.h6),
          Text(
            '\$${dollarValue.toStringAsFixed(5)}',
            style: TextStyle(
              fontFamily: 'SFPro',
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: AppSize.sp32,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: AppSize.h6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Assets.icons.scCoins.svg(height: AppSize.sp16, width: AppSize.sp16),
              SizedBox(width: AppSize.w4),
              Text(
                context.l10n.homeCoinsCount(coins.toInt()),
                style: TextStyle(
                  fontFamily: 'SFPro',
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: AppSize.sp13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSize.h8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'SFPro',
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: AppSize.sp13,
              ),
              children: [
                TextSpan(text: context.l10n.minWithdrawal),
                TextSpan(
                  text: '\$${minWithdraw.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF8FE0FF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category icon tabs ──────────────────────────────────────────────────────

class _ScCategoryIconTabs extends StatelessWidget {
  const _ScCategoryIconTabs({
    required this.categories,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<dynamic> categories;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final icons = [
      Assets.icons.scIcCash,
      Assets.icons.scIcBitcoin,
      Assets.icons.scIcFiles,
      Assets.icons.scIcGameZone,
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.w20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(categories.length, (index) {
          final isSelected = selectedIndex == index;
          final iconAsset = index < icons.length ? icons[index] : icons.first;
          final iconColor = isSelected
              ? Colors.white
              : const Color(0xFF1164FF);
          return GestureDetector(
            onTap: () => onTap(index),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: AppSize.sp52,
              height: AppSize.sp52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF1164FF) : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1164FF)
                      : const Color(0xFFE2E8F2),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF1164FF,
                          ).withValues(alpha: 0.28),
                          blurRadius: AppSize.r12,
                          offset: Offset(0, AppSize.h4),
                        ),
                      ]
                    : null,
              ),
              child: iconAsset.svg(
                width: AppSize.sp22,
                height: AppSize.sp22,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Section divider ─────────────────────────────────────────────────────────

class _ScSectionDivider extends StatelessWidget {
  const _ScSectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(horizontal: AppSize.w20),
      color: const Color(0xFFD9E2F0),
    );
  }
}

// ── Pending withdrawal banner ───────────────────────────────────────────────

class _ScPendingWithdrawBanner extends StatelessWidget {
  final ScWalletProvider provider;
  const _ScPendingWithdrawBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: provider.pendingWithdrawStream(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSize.w20,
            AppSize.h12,
            AppSize.w20,
            0,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: AppSize.w14,
              vertical: AppSize.h12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E0),
              borderRadius: BorderRadius.circular(AppSize.r12),
              border: Border.all(color: const Color(0xFFF5C150)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  color: const Color(0xFFB97A0A),
                  size: AppSize.sp20,
                ),
                SizedBox(width: AppSize.w10),
                Expanded(
                  child: Text(
                    context.l10n.pendingWithdrawalMsg,
                    style: TextStyle(
                      fontFamily: 'SFPro',
                      color: const Color(0xFF6A4400),
                      fontSize: AppSize.sp12,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
