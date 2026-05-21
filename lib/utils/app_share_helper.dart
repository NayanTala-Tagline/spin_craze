import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _fallbackPlayStoreUrl = 'https://play.google.com/store/apps';

Future<String> getPlayStoreUrl() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    return 'https://play.google.com/store/apps/details?id=${packageInfo.packageName}';
  } catch (e) {
    debugPrint('getPlayStoreUrl: failed to read package info: $e');
    return _fallbackPlayStoreUrl;
  }
}
