import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/features/wallet_module/model/wallet_models.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flutter/material.dart';
import 'package:spin_craze/extension/ext_localization.dart';

class WalletTabCard extends StatelessWidget {
  final WalletItem item;
  const WalletTabCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final textColors = context.themeTextColors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.r16),
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: AppSize.sp40,
            width: AppSize.sp40,
            child: FittedBox(
              fit: BoxFit.contain,
              child: item.icon,
            ),
          ),
          SizedBox(height: AppSize.h8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSize.w4),
            child: Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                fontSize: AppSize.sp12,
                fontWeight: FontWeight.w500,
                color: textColors.primary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
