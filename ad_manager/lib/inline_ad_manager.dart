import 'dart:async';

import 'package:ad_manager/banner_ad_manager.dart';
import 'package:ad_manager/enum/ad_status.dart';
import 'package:ad_manager/enum/ad_type.dart';
import 'package:ad_manager/models/ad_data.dart';
import 'package:ad_manager/native_ad_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manages an inline sticker-style ad that can switch between banner,
/// native small, and native medium based on [AdData.adType] and
/// [AdData.templateType].
///
/// - [AdType.banner]  → BannerAdManager
/// - [AdType.native]  → NativeAdManager (TemplateType.small or .medium via adData)
class InlineAdManager {
  final AdData adData;

  /// Only used when [adData.adType] is [AdType.banner].
  final AdSize bannerSize;

  /// Only used when [adData.adType] is [AdType.native].
  final String? nativeFactoryId;

  final BannerAdListener? bannerListener;
  final NativeAdListener? nativeListener;

  BannerAdManager? _bannerManager;
  NativeAdManager? _nativeManager;

  InlineAdManager({
    required this.adData,
    this.bannerSize = AdSize.banner,
    this.nativeFactoryId,
    this.bannerListener,
    this.nativeListener,
  }) {
    switch (adData.adType) {
      case AdType.banner:
        _bannerManager = BannerAdManager(
          adData: adData,
          size: bannerSize,
          listener: bannerListener,
        );
      case AdType.native:
      case AdType.custom:
        _nativeManager = NativeAdManager(
          adData: adData,
          factoryId: nativeFactoryId,
          listener: nativeListener,
        );
      default:
        break;
    }
  }

  AdStatus get adStatus =>
      _bannerManager?.adStatus ?? _nativeManager?.adStatus ?? AdStatus.idle;

  bool get isLoaded => adStatus == AdStatus.loaded;
  bool get isLoading => adStatus == AdStatus.loading;
  bool get isFailed => adStatus == AdStatus.failed;

  Future<void> load() async {
    if (_bannerManager != null) return _bannerManager!.load();
    if (_nativeManager != null) return _nativeManager!.load();
  }

  Future<void> reload() async {
    if (_bannerManager != null) return _bannerManager!.reload();
    if (_nativeManager != null) return _nativeManager!.reload();
  }

  Future<AdStatus> future() {
    if (_bannerManager != null) return _bannerManager!.future();
    if (_nativeManager != null) return _nativeManager!.future();
    return Future.value(AdStatus.idle);
  }

  Widget adWidget() {
    if (_bannerManager != null) return _bannerManager!.adWidget();
    if (_nativeManager != null) return _nativeManager!.adWidget();
    return const SizedBox.shrink();
  }

  Future<void> dispose() async {
    await _bannerManager?.dispose();
    _nativeManager?.dispose();
  }
}
