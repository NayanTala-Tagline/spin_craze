import 'package:ad_manager/ad_manager.dart';
import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:spin_craze/extension/ext_localization.dart';

class NativeAdsWidget extends StatelessWidget {
  const NativeAdsWidget({super.key, required this.nativeAd});

  final NativeAdManager? nativeAd;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: nativeAd?.adData.enabled ?? false,
      child: SafeArea(
        top: false,
        child: Container(
          width: context.width,
          margin: EdgeInsets.only(top: AppSize.h4),
          color: context.themeColors.background,
          height:
              (nativeAd?.isLoaded ?? false) ||
                  Injector.instance<AppDB>().isInternetConnected
              ? AppSize.h360
              : 0,
          child: Center(
            child: nativeAd?.isLoaded ?? false
                ? nativeAd?.adWidget()
                : nativeAd?.isLoading ?? false
                ? Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: AppSize.h360,
                      width: context.width,
                      color: Colors.white,
                    ),
                  )
                : const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
