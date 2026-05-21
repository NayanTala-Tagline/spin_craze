import 'package:flutter/cupertino.dart';

import 'logger.dart';

mixin NativeAdMixin<T extends StatefulWidget> on State<T> {
  /// 1. Force the screen to provide the Ad (Getter)
  /// This connects the Mixin to your widget's ad variable.
  dynamic get screenNativeAd;

  @override
  void initState() {
    super.initState();
    // Automatically call your update logic when screen starts
    updateNative();
  }

  @override
  void dispose() {
    // Automatically dispose the ad when screen closes
    screenNativeAd?.dispose();
    'add Dispose'.logD;
    super.dispose();
  }

  /// The Common Update Function
  Future<void> updateNative() async {
    if (screenNativeAd != null) {
      // Assuming .future() is your custom extension or method
      await screenNativeAd?.future();

      // Check mounted before setState to avoid errors
      if (mounted) {
        setState(() {});
      }
    }
  }
}