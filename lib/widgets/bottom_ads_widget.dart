import 'package:ad_manager/ad_manager.dart';
import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/widgets/connectivity_service.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:spin_craze/extension/ext_localization.dart';

class BottomAdsWidget extends StatefulWidget {
  const BottomAdsWidget({
    super.key,
    this.nativeAd,
    this.isSetting = false,
    this.isPadding = true,
  });

  final bool isPadding;

  final NativeAdManager? nativeAd;
  final bool isSetting;

  @override
  State<BottomAdsWidget> createState() => _BottomAdsWidgetState();
}

class _BottomAdsWidgetState extends State<BottomAdsWidget> {
  bool hasInternet = false;

  @override
  void initState() {
    internet();
    super.initState();
  }

  Future<void> internet() async {
    hasInternet = await ConnectivityService.hasInternet();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible:
          (widget.nativeAd?.adData.isCustomAd ?? false) ||
          (widget.nativeAd?.adData.enabled ?? false),
      child: SafeArea(
        bottom: true,
        top: false,
        child: Padding(
          padding: EdgeInsets.only(top: AppSize.h5),
          child: Container(
            color: context.theme.cardColor,
            child: widget.nativeAd?.adData.isCustomAd ?? false
                ? widget.nativeAd?.adWidget()
                : widget.nativeAd != null && widget.nativeAd!.isLoaded
                ? SizedBox(
                    height:
                        widget.nativeAd?.adData.templateType ==
                            TemplateType.medium
                        ? AppSize.h360
                        : AppSize.h100,
                    child: widget.nativeAd?.adWidget(),
                  ) // 1. Ad is loaded, display it
                : hasInternet
                ? Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height:
                          widget.nativeAd?.adData.templateType ==
                              TemplateType.medium
                          ? AppSize.h360
                          : AppSize.h100,
                      // This child container defines the area where the shimmer effect appears
                      color: context.theme.cardColor,
                    ),
                  )
                : const SizedBox.shrink(), // 3. No internet, don't show ad or shimmer
          ),
        ),
      ),
    );
  }
}
