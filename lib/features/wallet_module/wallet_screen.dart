import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/features/wallet_module/provider/wallet_provider.dart';
import 'package:spin_craze/features/wallet_module/widgets/wallet_bottom_sheet.dart';
import 'package:spin_craze/features/wallet_module/widgets/wallet_tab_card.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:spin_craze/utils/navigation_helper.dart';
import 'package:spin_craze/widgets/common_appbar.dart';
import 'package:spin_craze/widgets/back_btn.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spin_craze/extension/ext_localization.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsManager.instance.logScreenView(
      screenName: 'wallet',
      screenClass: 'WalletScreen',
    );
    return ChangeNotifierProvider(
      create: (context) => WalletProvider(),
      child: Consumer<WalletProvider>(
        builder: (context, provider, _) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              NavigationHelper().handleBackPress(context);
            },
            child: Scaffold(
              backgroundColor: context.themeColors.background,
              appBar: CommonAppBar(
                title: context.l10n.wallet,
                showBack: true,
                trailing: AppBackButton(
                  icon: Icons.history_rounded,
                  iconSize: AppSize.sp30,
                  onTap: () {
                    AnalyticsManager.instance.logEvent(
                      name: 'wallet_history_tap',
                    );
                    context.pushNamed(AppRoutes.walletHistory);
                  },
                ),
              ),
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  // -- Balance card --
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSize.w20,
                        vertical: AppSize.h16,
                      ),
                      child: const _BalanceCard(),
                    ),
                  ),

                  // -- Pending withdrawal banner --
                  SliverToBoxAdapter(
                    child: _PendingWithdrawBanner(provider: provider),
                  ),

                  // -- Tabs --
                  SliverPersistentHeader(
                    pinned: true,
                    floating: true,
                    delegate: _WalletTabsDelegate(),
                  ),
                ],

                body: PageView.builder(
                  controller: provider.pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    provider.setSelectedIndex(index);
                    provider.setWithdrawType(
                      provider.getWalletCategories(context)[index].title,
                    );
                  },
                  itemCount: provider.getWalletCategories(context).length,
                  itemBuilder: (context, pageIndex) {
                    final items = provider
                        .getWalletCategories(context)[pageIndex]
                        .items;

                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSize.w20,
                        vertical: AppSize.h12,
                      ),
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: AppSize.w12,
                        mainAxisSpacing: AppSize.h12,
                        childAspectRatio: 0.85,
                      ),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            provider.setWithdrawSubType(items[index].title);
                            AnalyticsManager.instance.logEvent(
                              name: 'wallet_method_tap',
                              parameters: {
                                'category': provider
                                    .getWalletCategories(context)[pageIndex]
                                    .title,
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
                                  child: WalletBottomSheet(item: items[index]),
                                );
                              },
                            ).then((_) {
                              provider.resetWithdrawForm();
                            });
                          },
                          child: WalletTabCard(item: items[index]),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Balance card ────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

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
        vertical: AppSize.h24,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.r20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B52D9), Color(0xFF5539B0), Color(0xFF3B2888)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B52D9).withValues(alpha: 0.35),
            blurRadius: AppSize.r24,
            offset: Offset(0, AppSize.h8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            context.l10n.availableBalance,
            style: context.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: AppSize.sp14,
            ),
          ),
          SizedBox(height: AppSize.h8),
          Text(
            '\$${dollarValue.toStringAsFixed(5)}',
            style: context.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: AppSize.sp32,
            ),
          ),
          SizedBox(height: AppSize.h6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Assets.icons.coins.svg(height: AppSize.sp16, width: AppSize.sp16),
              SizedBox(width: AppSize.w4),
              Text(
                '${coins.toInt()} Coins',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSize.h10),
          RichText(
            text: TextSpan(
              style: context.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: AppSize.sp13,
              ),
              children: [
                const TextSpan(text: 'Min. Withdrawal: '),
                TextSpan(
                  text: '\$${minWithdraw.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: const Color(0xFF4ADE80),
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

// ── Tab bar (underline style) ───────────────────────────────────────────────

class _WalletTabsDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: context.themeColors.background,
      width: context.width,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w20,
        vertical: AppSize.h6,
      ),
      child: const _WalletUnderlineTabs(),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class _WalletUnderlineTabs extends StatelessWidget {
  const _WalletUnderlineTabs();

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          height: AppSize.h36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: provider.getWalletCategories(context).length,
            itemBuilder: (context, index) {
              final isSelected = provider.selectedIndex == index;
              final title = provider.getWalletCategories(context)[index].title;

              return GestureDetector(
                onTap: () {
                  provider.setSelectedIndex(index);
                  provider.setWithdrawType(
                    provider.getWalletCategories(context)[index].title,
                  );
                  provider.pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Padding(
                  padding: EdgeInsets.only(right: AppSize.w24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.labelLarge?.copyWith(
                          color: isSelected
                              ? context.themeColors.primary
                              : context.themeTextColors.secondary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: AppSize.sp15,
                        ),
                      ),
                      SizedBox(height: AppSize.h4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 2.5,
                        width: isSelected ? AppSize.w32 : 0,
                        decoration: BoxDecoration(
                          color: context.themeColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Pending withdrawal banner ───────────────────────────────────────────────

class _PendingWithdrawBanner extends StatelessWidget {
  final WalletProvider provider;
  const _PendingWithdrawBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: provider.pendingWithdrawStream(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSize.w20,
            0,
            AppSize.w20,
            AppSize.h12,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: AppSize.w16,
              vertical: AppSize.h12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE6A817).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSize.r12),
              border: Border.all(
                color: const Color(0xFFE6A817).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  color: const Color(0xFFE6A817),
                  size: AppSize.sp20,
                ),
                SizedBox(width: AppSize.w10),
                Expanded(
                  child: Text(
                    'You have a pending withdrawal. New requests are disabled until it is approved.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.themeTextColors.primary,
                      fontSize: AppSize.sp13,
                      height: 1.35,
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
