import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RevenueHelper {
  static const String _paidEventCollection = 'paid_event';

  /// Sends ad impression revenue data to Firebase Analytics and stores
  /// the paid event in the `paid_event` Firestore collection.
  static Future<void> sendAdImpressionRevenueToFirebase({
    required double valueMicros,
    required String currencyCode,
    required PrecisionType precision,
    required String adUnitId,
  }) async {
    final analytics = FirebaseAnalytics.instance;
    final revenue = microsToCurrency(valueMicros);

    final params = {
      'currency': currencyCode,
      'value': revenue,
      'formatted_revenue': revenue.toStringAsFixed(6),
      'precision': precision.index,
      'ad_unit_id': adUnitId,
    };

    await analytics.logEvent(name: 'ad_impression', parameters: params);

    await _savePaidEventToFirestore(
      valueMicros: valueMicros,
      revenue: revenue,
      currencyCode: currencyCode,
      precision: precision,
      adUnitId: adUnitId,
    );
  }

  /// Persists a single paid event into the `paid_event` Firestore collection.
  static Future<void> _savePaidEventToFirestore({
    required double valueMicros,
    required double revenue,
    required String currencyCode,
    required PrecisionType precision,
    required String adUnitId,
  }) async {
    try {
      await FirebaseFirestore.instance.collection(_paidEventCollection).add({
        'ad_unit_id': adUnitId,
        'value_micros': valueMicros,
        'value': revenue,
        'currency': currencyCode,
        'precision': precision.index,
        'precision_name': precision.name,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to save paid_event to Firestore: $e');
    }
  }

  static double microsToCurrency(double micros) => micros / 1_000_000.0;
}
