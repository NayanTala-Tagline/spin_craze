/*
import 'package:flutter/material.dart';

import '../routes/app_router.dart';
import 'add_tap_manager.dart';

class AdNavigationObserver extends NavigatorObserver {
  bool _isPopup(Route route) => route is PopupRoute;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (_isPopup(route)) {
      debugPrint('Ignored popup route push: ${route.settings.name}');
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = rootNavKey.currentContext;
      if (context != null) {
        // We pass an EMPTY callback () {} because navigation already finished.
        // The Ad Manager will Load -> Show Ad -> Run Callback (Do nothing).
        AdTapManager().registerTap(context, () {
          // Navigation already happened, so we do nothing here.
        });
      }
    });// Call your ad tap register
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (_isPopup(route)) {
      debugPrint('Ignored popup route push: ${route.settings.name}');
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = rootNavKey.currentContext;

      if (context != null) {
        // We pass an EMPTY callback () {} because navigation already finished.
        // The Ad Manager will Load -> Show Ad -> Run Callback (Do nothing).
        AdTapManager().registerTap(context, () {
          // Navigation already happened, so we do nothing here.
        });
      }
    });// Optional: also trigger on pop if you want
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (_isPopup(newRoute!)) {
      debugPrint('Ignored popup route push: ${newRoute.settings.name}');
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = rootNavKey.currentContext;

      if (context != null) {
        // We pass an EMPTY callback () {} because navigation already finished.
        // The Ad Manager will Load -> Show Ad -> Run Callback (Do nothing).
        AdTapManager().registerTap(context, () {
          // Navigation already happened, so we do nothing here.
        });
      }
    });
  }
}
*/
