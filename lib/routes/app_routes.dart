// ignore_for_file: public_member_api_docs

part of 'app_router.dart';

/// This class contains all the routes used within the app
class AppRoutes {
  const AppRoutes._();

  // bottom navigation routes
  static const String home = 'home';
  static const String rank = 'rank';
  static const String rewards = 'rewards';
  static const String profile = 'profile';

  // settings sub-routes (pushed above the shell)
  static const String language = 'language';
  static const String support = 'support';

  /// auth routes
  static const String login = 'login';

  /// intro routes
  static const String splash = 'splash';
  static const String onboarding1 = 'onboarding1';
  static const String onboarding2 = 'onboarding2';
  static const String onboarding3 = 'onboarding3';

  static const String skinTool = 'skinTool';
  static const String diamondsGuidePreviewScreen = 'diamondsGuidePreviewScreen';
  static const String diamondsGuideScreen = 'diamondsGuideScreen';

  static const String spinWheelScreen = 'SpinWheelScreen';
  static const String quizScreen = 'QuizScreen';
  static const String scratchCard = 'ScratchCard';
  static const String webVisitsScreen = 'WebVisitsScreen';
  static const String gameZoneScreen = 'GameZoneScreen';
  static const String commonToolScreen = 'CommonToolScreen';
  static const String weaponToolScreen = 'WeaponToolScreen';
  static const String parachuteToolScreen = 'parachuteToolScreen';
  static const String mapToolScreen = 'mapToolScreen';
  static const String calculatorScreen = 'calculatorScreen';
  static const String selectPlayerLevelScreen = 'selectPlayerLevelScreen';
  static const String rankBadgeConceptsScreen = 'rankBadgeConceptsScreen';
  static const String claimtItemScreen = 'claimtItemScreen';
  static const String applyScreen = 'applyScreen';

  static const String settingScreen = 'settingScreen';

  /// wallet routes
  static const String walletScreen = 'walletScreen';
  static const String walletHistory = 'walletHistory';

  /// how it works
  static const String howItWorks = 'howItWorks';

  /// daily check-in
  static const String dailyCheckin = 'dailyCheckin';

  /// in-app webview
  static const String inAppWebView = 'inAppWebView';

  /// celebration overlay
  static const String celebrationOverlay = 'celebrationOverlay';
}
