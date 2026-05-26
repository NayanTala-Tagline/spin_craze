import 'dart:convert';
import 'package:ad_manager/models/ad_data.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'logger.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();

  factory RemoteConfigService() => _instance;

  static RemoteConfigService get instance => _instance;

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  Map<String, dynamic> _appData = {};
  Map<String, dynamic> _visitWebsites = {};

  RemoteConfigService._internal();

  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------
  Future<void> init() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 1),
      ),
    );

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      '⚠️ Remote config fetch failed: $e'.logD;
      return;
    }

    final jsonString = _remoteConfig.getString('app_data');
    final jsonString1 = _remoteConfig.getString('visit_websites_games');

    if (jsonString.isEmpty) {
      '⚠️ app_data key is empty in Remote Config'.logD;
      return;
    }
    if (jsonString1.isEmpty) {
      '⚠️ visit_websites key is empty in Remote Config'.logD;
      return;
    }

    try {
      _appData = jsonDecode(jsonString) as Map<String, dynamic>;
      _visitWebsites = jsonDecode(jsonString1) as Map<String, dynamic>;
      '✅ Remote config loaded successfully'.logD;
    } catch (e) {
      _appData = {};
      _visitWebsites = {};
      '❌ Failed to decode remote config JSON: $e'.logD;
    }
  }

  // ---------------------------------------------------------------------------
  // INTERNAL HELPERS
  // ---------------------------------------------------------------------------

  AdData _getAdData(String key) {
    try {
      final raw = _appData[key];

      if (raw == null || raw is! Map<String, dynamic>) {
        '⚠️ $key missing or invalid'.logD;
        return AdData.fromJson(_emptyAd());
      }

      final Map<String, dynamic> data = {
        'ad_id': raw['ad_id'] ?? '',
        'enabled': raw['enabled'] ?? false,
        'template_type': raw['template_type'] ?? 'small',
        'is_custom_ad': raw['is_custom_ad'] ?? false,

        // 🔥 INT → DOUBLE FIX
        'custom_ad_height': (raw['custom_ad_height'] is num)
            ? (raw['custom_ad_height'] as num).toDouble()
            : 0.0,

        'custom_ad_view_url': raw['custom_ad_view_url'] ?? '',
        'custom_ad_url': raw['custom_ad_url'] ?? '',
      };

      return AdData.fromJson(data);
    } catch (e, s) {
      '❌ Failed to parse AdData for $key: $e'.logD;
      s.toString().logD;
      return AdData.fromJson(_emptyAd());
    }
  }

  Map<String, dynamic> _emptyAd() => {
    'ad_id': '',
    'enabled': false,
    'template_type': 'small',
    'is_custom_ad': false,
    'custom_ad_height': 0.0,
    'custom_ad_view_url': '',
    'custom_ad_url': '',
  };

  dynamic _get(String key, [dynamic defaultValue]) {
    return _appData[key] ?? defaultValue;
  }

  dynamic _getWebsites(String key, [dynamic defaultValue]) {
    return _visitWebsites[key] ?? defaultValue;
  }

  // ---------------------------------------------------------------------------
  // ADS
  // ---------------------------------------------------------------------------

  AdData get applicationAppOpen => _getAdData('application_app_open');

  AdData get languageNative => _getAdData('language_native');
  AdData get languageNative2 => _getAdData('language_native2');

  AdData get onboardingNative1 => _getAdData('onboarding_native_1');

  AdData get onboardingNative2 => _getAdData('onboarding_native_2');

  AdData get onboardingNative3 => _getAdData('onboarding_native_3');

  AdData get onboardingInter1 => _getAdData('onboarding_inter_1');

  AdData get onboardingInter2 => _getAdData('onboarding_inter_2');

  AdData get onboardingInter3 => _getAdData('onboarding_inter_3');

  AdData get appNative => _getAdData('app_native');

  AdData get appInter => _getAdData('app_inter');

  AdData get homeNative => _getAdData('home_native');

  // AdData get settingNative => _getAdData('setting_native');

  AdData get websiteReward => _getAdData('website_reward');

  AdData get dailyClaimReward => _getAdData('daily_claim_reward');

  AdData get mathQuizClaimReward => _getAdData('math_quiz_claim_reward');

  AdData get scratchCardClaimReward => _getAdData('scratch_card_claim_reward');

  AdData get spinWheelClaimReward => _getAdData('spin_wheel_claim_reward');

  AdData get playGameReward => _getAdData('play_game_reward');

  int get appClickCounter => _get('app_click_counter', 15);

  String get privacyPolicyUrl => _get('privacy_policy_url', '');

  String get termsAndConditions => _get('terms_and_conditions', '');

  // ---------------------------------------------------------------------------
  // OTHER CONFIG
  // ---------------------------------------------------------------------------
  /// ---------------- WEB VISITS ----------------

  String get webVisit1Title =>
      _getWebsites('web_visit_1_title', 'Tech News Daily');
  String get webVisit1 => _getWebsites('web_visit_1');

  String get webVisit2Title =>
      _getWebsites('web_visit_2_title', 'Viral Gadgets');
  String get webVisit2 => _getWebsites('web_visit_2');

  String get webVisit3Title =>
      _getWebsites('web_visit_3_title', 'Lifestyle Blog');
  String get webVisit3 => _getWebsites('web_visit_3');

  String get webVisit4Title =>
      _getWebsites('web_visit_4_title', 'Travel Diaries');
  String get webVisit4 => _getWebsites('web_visit_4');

  String get webVisit5Title =>
      _getWebsites('web_visit_5_title', 'Finance Tips');
  String get webVisit5 => _getWebsites('web_visit_5');

  int get webVisitTimeSeconds => _getWebsites('web_visit_time_seconds', 50);
  int get webVisitAgainLockTimeMinutes =>
      _getWebsites('web_visit_again_lock_time_minutes', 5);
  int get webVisitRewardCoins => _getWebsites('web_visit_reward_coins', 30);

  /// ---------------- GAME VISITS ----------------

  String get gameVisit1Title =>
      _getWebsites('game_visit_1_title', 'Bubble Shooter');
  String get gameVisit1 => _getWebsites('game_visit_1');

  String get gameVisit2Title =>
      _getWebsites('game_visit_2_title', 'Word Search');
  String get gameVisit2 => _getWebsites('game_visit_2');

  String get gameVisit3Title =>
      _getWebsites('game_visit_3_title', 'Puzzle Match');
  String get gameVisit3 => _getWebsites('game_visit_3');

  String get gameVisit4Title =>
      _getWebsites('game_visit_4_title', 'Memory Game');
  String get gameVisit4 => _getWebsites('game_visit_4');

  String get gameVisit5Title =>
      _getWebsites('game_visit_5_title', 'Speed Match');
  String get gameVisit5 => _getWebsites('game_visit_5');

  int get gameVisitTimeSeconds => _getWebsites('game_visit_time_seconds', 50);
  int get gameVisitAgainLockTimeMinutes =>
      _getWebsites('game_visit_again_lock_time_minutes', 5);
  int get gameVisitRewardCoins => _getWebsites('game_visit_reward_coins', 30);

  /// ---------------- WEB VIEW ----------------

  bool get inAppWebView => _getWebsites('in_app_web_view', true);
  int get minWithdrawAmount => _getWebsites('min_withdraw_amount', 10000);
  int get referralRewardAmount => _getWebsites('referral_reward_amount', 1000);

  int get coinToDollarDivider => _getWebsites('coin_to_dollar_divider', 1000);
  int get quizPerQuestionReward => _getWebsites('quiz_per_question_reward', 5);
  int get scrachMinReward => _getWebsites('scrach_min_reward', 20);
  int get scrachMaxReward => _getWebsites('scrach_max_reward', 30);
  List<int> get spinBoardRewardValues => List<int>.from(
    _getWebsites('spin_board_reward_values', [
      10,
      12,
      15,
      17,
      18,
      20,
      22,
      24,
      26,
      27,
      29,
      30,
    ]),
  );
}
