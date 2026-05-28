import 'package:ad_manager/enum/ad_type.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdData {
  AdData({
    required this.adId,
    required this.enabled,
    required this.adType,
    this.templateType = TemplateType.medium,
    this.height = 0,
    this.customAdViewUrl = '',
    this.customAdUrl = '',
  });

  String adId;
  bool enabled;
  AdType adType;
  TemplateType templateType;
  double height;
  String customAdViewUrl;
  String customAdUrl;

  factory AdData.fromJson(Map<String, dynamic> data) => AdData(
    adId: data['ad_id'] ?? '',
    enabled: data['enabled'] ?? false,
    adType: _adTypeFromString(data['ad_type']),
    templateType: _templateTypeFromString(data['template_type']),
    height: (data['height'] ?? 0).toDouble(),
    customAdViewUrl: data['custom_ad_view_url'] ?? '',
    customAdUrl: data['custom_ad_url'] ?? '',
  );

  Map<String, dynamic> toJson() {
    return {
      'ad_id': adId,
      'enabled': enabled,
      'ad_type': adType.name,
      'template_type': templateType.name,
      'height': height,
      'custom_ad_view_url': customAdViewUrl,
      'custom_ad_url': customAdUrl,
    };
  }

  static TemplateType _templateTypeFromString(String? value) {
    return TemplateType.values.firstWhere((e) => e.name == value, orElse: () => TemplateType.small);
  }

  static AdType _adTypeFromString(String? value) {
    return AdType.values.firstWhere((e) => e.name == value, orElse: () => AdType.native);
  }
}
