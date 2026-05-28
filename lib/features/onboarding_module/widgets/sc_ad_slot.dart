import 'package:ad_manager/ad_manager.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../utils/app_size.dart';

/// Renders an [InlineAdManager]'s widget with a shimmer placeholder while the
/// ad is loading, and collapses to nothing on failure or when disabled.
class ScAdSlot extends StatefulWidget {
  const ScAdSlot({
    super.key,
    this.ad,
    this.height,
    this.safeAreaTop,
    this.safeAreaBottom,
  });

  final InlineAdManager? ad;
  final bool? safeAreaTop;
  final bool? safeAreaBottom;

  /// Placeholder height used while the ad is loading. When null we fall back
  /// to a reasonable native-template height.
  final double? height;

  @override
  State<ScAdSlot> createState() => _ScAdSlotState();
}

class _ScAdSlotState extends State<ScAdSlot> {
  @override
  void initState() {
    super.initState();
    widget.ad?.future().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    if (ad?.adData.enabled == false) return const SizedBox.shrink();
    if (ad == null) return const SizedBox.shrink();

    if (ad.isFailed) return const SizedBox.shrink();

    final placeholderHeight = widget.ad?.adData.height ?? AppSize.h120;

    if (!ad.isLoaded) {
      return _ScShimmerPlaceholder(
        height: placeholderHeight,
        safeAreaTop: widget.safeAreaTop ?? false,
        safeAreaBottom: widget.safeAreaBottom ?? true,
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: AppSize.h10),
      child: SafeArea(
        top: widget.safeAreaTop ?? false,
        bottom: widget.safeAreaBottom ?? true,
        child: ad.adWidget(),
      ),
    );
  }
}

class _ScShimmerPlaceholder extends StatelessWidget {
  const _ScShimmerPlaceholder({
    required this.height,
    required this.safeAreaTop,
    required this.safeAreaBottom,
  });

  final double height;
  final bool safeAreaTop;
  final bool safeAreaBottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: AppSize.h10),
      child: SafeArea(
        top: safeAreaTop,
        bottom: safeAreaBottom,
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSize.r12),
            ),
          ),
        ),
      ),
    );
  }
}
