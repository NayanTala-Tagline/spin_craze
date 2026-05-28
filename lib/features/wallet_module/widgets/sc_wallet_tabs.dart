import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/features/wallet_module/provider/sc_wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:provider/provider.dart';

class ScWalletTabs extends StatelessWidget {
  const ScWalletTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScWalletProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: [
                context.themeColors.primary,
                context.themeColors.secondary,
              ],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: context.themeColors.background,
              borderRadius: BorderRadius.circular(28),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                        provider.getWalletCategories(context).length,
                        (index) => GestureDetector(
                          onTap: () {
                            provider.setSelectedIndex(index);
                            provider.setWithdrawType(
                              provider
                                  .getWalletCategories(context)[index]
                                  .title,
                            );
                            provider.pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: _ScWalletTabitem(
                            title: provider
                                .getWalletCategories(context)[index]
                                .title,
                            isSelected: provider.selectedIndex == index,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ScWalletTabitem extends StatelessWidget {
  final String title;
  final bool isSelected;

  const _ScWalletTabitem({required this.title, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 36,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: AppSize.w14),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.blueAccent.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: isSelected
          ? ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  context.themeColors.primary,
                  context.themeColors.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: context.textTheme.displayLarge?.copyWith(
                    fontSize: AppSize.sp15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          : Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: context.textTheme.displayLarge?.copyWith(
                  fontSize: AppSize.sp14,
                  fontWeight: FontWeight.w700,
                  color: context.themeTextColors.primary,
                ),
              ),
            ),
    );
  }
}
