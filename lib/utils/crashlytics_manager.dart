import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show FlutterErrorDetails, immutable, kReleaseMode;

/// Crashlytics Manager to manage FirebaseCrashlytics SDK
@immutable
final class CrashlyticsManager {
  // ---- Singleton setup ----
  static final CrashlyticsManager _instance = CrashlyticsManager._internal();

  /// Factory constructor allows calling `CrashlyticsManager()` directly
  factory CrashlyticsManager() => _instance;

  /// Named instance getter for clarity if preferred
  static CrashlyticsManager get instance => _instance;

  /// Private constructor
  CrashlyticsManager._internal();

  // ---- FirebaseCrashlytics setup ----
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Get FirebaseCrashlytics instance
  FirebaseCrashlytics get crashlytics => _crashlytics;

  /// Set user id
  void setUserId(String userId) {
    if (kReleaseMode) {
      _crashlytics.setUserIdentifier(userId);
    }
  }

  /// Log FlutterErrorDetails
  Future<void> logFlutterError(FlutterErrorDetails details) async {
    if (kReleaseMode) {
      _crashlytics.recordFlutterError(details);
    }
  }

  /// Log handled Dart error
  Future<void> logHandledDartError({required Object error, StackTrace? stackTrace, String? message}) async {
    if (kReleaseMode) {
      if (message != null) logCustomError(message);
      _crashlytics.recordError(error, stackTrace ?? StackTrace.current);
    }
  }

  /// Log custom error message
  void logCustomError(String message) {
    if (kReleaseMode) {
      _crashlytics.log(message);
    }
  }
}
