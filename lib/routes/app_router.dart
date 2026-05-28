import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/features/auth_module/sc_login_screen.dart';
import 'package:spin_craze/features/scratch_module/sc_celebration_overlay.dart';
import 'package:spin_craze/features/bottom_nav/sc_bottom_nav_page.dart';
import 'package:spin_craze/features/home_module/sc_home_page.dart';
import 'package:spin_craze/features/home_module/widgets/sc_daily_checkin_page.dart';
import 'package:ad_manager/ad_manager.dart';
import 'package:spin_craze/features/splash_module/sc_splash_page.dart';
import 'package:spin_craze/features/onboarding_module/sc_onboarding_page1.dart';
import 'package:spin_craze/features/onboarding_module/sc_onboarding_page2.dart';
import 'package:spin_craze/features/onboarding_module/sc_onboarding_page3.dart';
import 'package:spin_craze/features/onboarding_module/sc_country_page.dart';
import 'package:spin_craze/features/onboarding_module/sc_currency_page.dart';
import 'package:spin_craze/features/onboarding_module/sc_game_select_page.dart';
import 'package:spin_craze/features/onboarding_module/provider/sc_selection_ad_provider.dart'
    show ScSelectionAds;
import 'package:spin_craze/features/profile_module/sc_profile_page.dart';
import 'package:spin_craze/features/rank_module/sc_rank_page.dart';
import 'package:spin_craze/features/rewards_module/sc_rewards_page.dart';
import 'package:spin_craze/features/settings_module/sc_language_page.dart'
    show ScLanguagePage, ScLanguagePageArgs;
import 'package:spin_craze/features/settings_module/sc_support_page.dart';
import 'package:spin_craze/features/game_zone_module/sc_game_zone_screen.dart';
import 'package:spin_craze/features/quiz_module/sc_quiz_screen.dart';
import 'package:spin_craze/features/scratch_module/pages/sc_scratch_card.dart';
import 'package:spin_craze/features/spin_module/sc_spin_page.dart';
import 'package:spin_craze/features/how_it_works_module/sc_how_it_works_screen.dart';
import 'package:spin_craze/features/wallet_module/inner_screens/wallet_history/sc_wallet_history_screen.dart';
import 'package:spin_craze/features/wallet_module/sc_wallet_screen.dart';
import 'package:spin_craze/features/web_visits_module/sc_web_visits_screen.dart';
import 'package:spin_craze/widgets/in_app_webview_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'app_routes.dart';

/// root navigation key
final GlobalKey<NavigatorState> rootNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Scaffold navigation key
final GlobalKey<ScaffoldMessengerState> sfMessengerKey =
    GlobalKey<ScaffoldMessengerState>(debugLabel: 'appScaffold');

/// current route
String? currentRoute;

/// Fade transition for feature screens (300ms).
CustomTransitionPage<void> _fadeTransitionPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

String _initialLocation() {
  // Always start on the splash screen. It plays the intro animation, handles
  // connectivity, shows the splash app-open ad, then routes to home or
  // onboarding (see [ScSplashScreen]).
  return '/${AppRoutes.splash}';
}

/// global GoRouter instance which has all page routes
final appRouter = GoRouter(
  navigatorKey: rootNavKey,
  debugLogDiagnostics: kDebugMode,
  initialLocation: _initialLocation(),
  redirect: (context, state) {
    switch (state.fullPath) {
      case '/':
        return '/${AppRoutes.home}';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/${AppRoutes.splash}',
      name: AppRoutes.splash,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) {
        return MaterialPage(
          key: state.pageKey,
          name: AppRoutes.splash,
          child: const ScSplashScreen(),
        );
      },
    ),
    GoRoute(
      path: '/${AppRoutes.onboarding1}',
      name: AppRoutes.onboarding1,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) {
        // The splash screen hands off a preloaded native ad via `extra`.
        final preloadedAd = state.extra as InlineAdManager?;
        return MaterialPage(
          key: state.pageKey,
          name: AppRoutes.onboarding1,
          child: ScOnboardingPage1(preloadedNativeAd: preloadedAd),
        );
      },
    ),
    GoRoute(
      path: '/${AppRoutes.onboarding2}',
      name: AppRoutes.onboarding2,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) {
        return MaterialPage(
          key: state.pageKey,
          name: AppRoutes.onboarding2,
          child: const ScOnboardingPage2(),
        );
      },
    ),
    GoRoute(
      path: '/${AppRoutes.onboarding3}',
      name: AppRoutes.onboarding3,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) {
        return MaterialPage(
          key: state.pageKey,
          name: AppRoutes.onboarding3,
          child: const ScOnboardingPage3(),
        );
      },
    ),
    GoRoute(
      path: '/${AppRoutes.login}',
      name: AppRoutes.login,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) {
        return MaterialPage(
          key: state.pageKey,
          name: AppRoutes.login,
          child: const ScLoginScreen(),
        );
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScBottomNavPage(
          key: state.pageKey,
          navigationShell: navigationShell,
        );
      },
      branches: _bottomNavBranches,
    ),
    // Settings sub-pages — pushed above the shell so the bottom nav is hidden
    // and a back arrow returns to the Profile tab.
    GoRoute(
      path: '/${AppRoutes.language}',
      name: AppRoutes.language,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) {
        // Accept either the new ScLanguagePageArgs or the legacy `bool`
        // (`extra: true` means "onboarding") to avoid breaking existing
        // call sites that haven't been migrated yet.
        final extra = state.extra;
        ScLanguagePageArgs? args;
        if (extra is ScLanguagePageArgs) {
          args = extra;
        } else if (extra == true) {
          args = const ScLanguagePageArgs(isOnboarding: true);
        }
        final isOnboarding = args?.isOnboarding ?? false;

        return MaterialPage(
          key: state.pageKey,
          name: AppRoutes.language,
          child: ScLanguagePage(
            isOnboarding: isOnboarding,
            preloadedAd1: args?.languageNativeAd,
            preloadedAd2: args?.languageNative2Ad,
            onContinue: isOnboarding
                ? (countryAds) => GoRouter.of(context).goNamed(
                    AppRoutes.country,
                    extra: countryAds,
                  )
                : null,
          ),
        );
      },
    ),
    // ── Onboarding selection sub-flow: country → currency → games → login ──
    // Each screen pre-loads the next screen's ads and hands them off via
    // `extra` so the next screen's native + interstitial are ready instantly.
    GoRoute(
      path: '/${AppRoutes.country}',
      name: AppRoutes.country,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(
        state,
        ScCountryPage(
          preloaded: state.extra as ScSelectionAds?,
          onContinue: (next) => GoRouter.of(context).goNamed(
            AppRoutes.currency,
            extra: next,
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/${AppRoutes.currency}',
      name: AppRoutes.currency,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(
        state,
        ScCurrencyPage(
          preloaded: state.extra as ScSelectionAds?,
          onContinue: (next) => GoRouter.of(context).goNamed(
            AppRoutes.gameSelect,
            extra: next,
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/${AppRoutes.gameSelect}',
      name: AppRoutes.gameSelect,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(
        state,
        ScGameSelectPage(
          preloaded: state.extra as ScSelectionAds?,
          onContinue: () {
            // End of onboarding: if the user already has a session (e.g. a
            // returning user replaying onboarding via show_multiple_onboarding),
            // skip login and go straight home; otherwise send them to login.
            final loggedIn = Injector.instance<AppDB>().userModel != null;
            GoRouter.of(context).goNamed(
              loggedIn ? AppRoutes.home : AppRoutes.login,
            );
          },
        ),
      ),
    ),
    GoRoute(
      path: '/${AppRoutes.support}',
      name: AppRoutes.support,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) {
        return MaterialPage(
          key: state.pageKey,
          name: AppRoutes.support,
          child: const ScSupportPage(),
        );
      },
    ),
    GoRoute(
      path: '/${AppRoutes.walletScreen}',
      name: AppRoutes.walletScreen,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(state, const ScWalletScreen()),
    ),
    GoRoute(
      path: '/${AppRoutes.walletHistory}',
      name: AppRoutes.walletHistory,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(state, const ScWalletHistoryScreen()),
    ),
    GoRoute(
      path: '/${AppRoutes.howItWorks}',
      name: AppRoutes.howItWorks,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(state, const ScHowItWorksScreen()),
    ),
    GoRoute(
      path: '/${AppRoutes.dailyCheckin}',
      name: AppRoutes.dailyCheckin,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(state, const ScDailyCheckinPage()),
    ),
    GoRoute(
      path: '/${AppRoutes.quizScreen}',
      name: AppRoutes.quizScreen,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(state, const ScQuizScreen()),
    ),
    GoRoute(
      path: '/${AppRoutes.scratchCard}',
      name: AppRoutes.scratchCard,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(state, const ScScratchCardScreen()),
    ),
    GoRoute(
      path: '/${AppRoutes.webVisitsScreen}',
      name: AppRoutes.webVisitsScreen,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(state, const ScWebVisitsScreen()),
    ),
    GoRoute(
      path: '/${AppRoutes.gameZoneScreen}',
      name: AppRoutes.gameZoneScreen,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(state, const ScGameZoneScreen()),
    ),
    GoRoute(
      path: '/${AppRoutes.spinWheelScreen}',
      name: AppRoutes.spinWheelScreen,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(state, const ScSpinWheelScreen()),
    ),
    GoRoute(
      path: '/${AppRoutes.inAppWebView}',
      name: AppRoutes.inAppWebView,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) {
        final args = state.extra! as Map<String, dynamic>;
        return _fadeTransitionPage(
          state,
          InAppWebViewPage(
            url: args['url'] as String,
            title: args['title'] as String,
            durationSeconds: args['durationSeconds'] as int,
            coins: args['coins'] as int,
            adData: args['adData'],
            onRewardClaimed: args['onRewardClaimed'] as VoidCallback?,
          ),
        );
      },
    ),
  ],
);

final _bottomNavBranches = <StatefulShellBranch>[
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/${AppRoutes.home}',
        name: AppRoutes.home,
        pageBuilder: (context, state) {
          return MaterialPage(key: state.pageKey, name: AppRoutes.home, child: const ScHomePage());
        },
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/${AppRoutes.rank}',
        name: AppRoutes.rank,
        pageBuilder: (context, state) {
          return MaterialPage(key: state.pageKey, name: AppRoutes.rank, child: const ScRankPage());
        },
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/${AppRoutes.rewards}',
        name: AppRoutes.rewards,
        pageBuilder: (context, state) {
          return MaterialPage(key: state.pageKey, name: AppRoutes.rewards, child: const ScRewardsPage());
        },
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/${AppRoutes.profile}',
        name: AppRoutes.profile,
        pageBuilder: (context, state) {
          return MaterialPage(key: state.pageKey, name: AppRoutes.profile, child: const ScProfilePage());
        },
      ),
    ],
  ),
];
