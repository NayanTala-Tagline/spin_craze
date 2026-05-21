import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdData {
  AdData({
    required this.adId,
    required this.enabled,
    required this.templateType,
    required this.isCustomAd,
    required this.customAdHeight,
    required this.customAdViewUrl,
    required this.customAdUrl,
  });

  String adId;
  bool enabled;
  TemplateType templateType;
  bool isCustomAd;
  double customAdHeight;
  String customAdViewUrl;
  String customAdUrl;

  factory AdData.fromJson(Map<String, dynamic> data) => AdData(
    adId: data['ad_id'],
    enabled: data['enabled'],
    templateType: data['template_type'] == 'medium' ? TemplateType.medium : TemplateType.small,
    isCustomAd: data['is_custom_ad'],
    customAdHeight: data['custom_ad_height'],
    customAdViewUrl: data['custom_ad_view_url'],
    customAdUrl: data['custom_ad_url'],
  );

  Map<String, dynamic> toJson() {
    return {
      'ad_id': adId,
      'enabled': enabled,
      'template_type': templateType == TemplateType.medium ? 'medium' : 'small',
      'is_custom_ad': isCustomAd,
      'custom_ad_height': customAdHeight,
      'custom_ad_view_url': customAdViewUrl,
      'custom_ad_url': customAdUrl,
    };
  }
}
