import 'package:spin_craze/features/wallet_module/model/sc_wallet_models.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flutter/material.dart';

class ScWalletTabCard extends StatelessWidget {
  final ScWalletItem item;
  const ScWalletTabCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w8,
        vertical: AppSize.h10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.r12),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD9E2F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
            height: AppSize.sp34,
            width: AppSize.sp34,
            child: FittedBox(
              fit: BoxFit.contain,
              child: item.icon,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSize.w4),
            child: Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'SFPro',
                fontSize: AppSize.sp12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0E1A2B),
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
