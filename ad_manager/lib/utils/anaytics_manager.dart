import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show immutable, kReleaseMode;

/// Analytics Manager to manage FirebaseAnalytics SDK
@immutable
final class AnalyticsManager {
  // ---- Singleton setup ----
  static final AnalyticsManager _instance = AnalyticsManager._internal();

  /// Factory constructor for direct access: `AnalyticsManager()`
  factory AnalyticsManager() => _instance;

  /// Named getter for explicit singleton access: `AnalyticsManager.instance`
  static AnalyticsManager get instance => _instance;

  /// Private internal constructor
  AnalyticsManager._internal();

  // ---- FirebaseAnalytics instance ----
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Get FirebaseAnalytics instance
  FirebaseAnalytics get analytics => _analytics;

  /// Set user ID for analytics tracking
  Future<void> setUserId(String userId) async {
    // if (kReleaseMode) {
      await _analytics.setUserId(id: userId);
    // }
  }

  /// Set user property (e.g., user type, plan, region)
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    // if (kReleaseMode) {
      await _analytics.setUserProperty(name: name, value: value);
    // }
  }

  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (kReleaseMode) {
      await _analytics.logEvent(name: name, parameters: parameters);
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    // if (kReleaseMode) {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    // }
  }

  /// Enable or disable analytics collection
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  /// Reset analytics data (e.g., for user logout)
  Future<void> resetAnalyticsData() async {
    await _analytics.resetAnalyticsData();
  }
}
