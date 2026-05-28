import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RevenueHelper {
  /// Sends ad impression revenue data to Firebase
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
  }

  static double microsToCurrency(double micros) => micros / 1_000_000.0;
}
