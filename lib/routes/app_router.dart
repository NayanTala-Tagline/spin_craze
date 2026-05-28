import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/features/auth_module/login_screen.dart';
import 'package:spin_craze/features/scratch_module/celebration_overlay.dart';
import 'package:spin_craze/features/bottom_nav/bottom_nav_page.dart';
import 'package:spin_craze/features/home_module/home_page.dart';
import 'package:spin_craze/features/home_module/widgets/daily_checkin_page.dart';
import 'package:ad_manager/ad_manager.dart';
import 'package:spin_craze/features/splash_module/splash_page.dart';
import 'package:spin_craze/features/onboarding_module/onboarding_page1.dart';
import 'package:spin_craze/features/onboarding_module/onboarding_page2.dart';
import 'package:spin_craze/features/onboarding_module/onboarding_page3.dart';
import 'package:spin_craze/features/onboarding_module/country_page.dart';
import 'package:spin_craze/features/onboarding_module/currency_page.dart';
import 'package:spin_craze/features/onboarding_module/game_select_page.dart';
import 'package:spin_craze/features/onboarding_module/provider/selection_ad_provider.dart'
    show SelectionAds;
import 'package:spin_craze/features/profile_module/profile_page.dart';
import 'package:spin_craze/features/rank_module/rank_page.dart';
import 'package:spin_craze/features/rewards_module/rewards_page.dart';
import 'package:spin_craze/features/settings_module/language_page.dart'
    show LanguagePage, LanguagePageArgs;
import 'package:spin_craze/features/settings_module/support_page.dart';
import 'package:spin_craze/features/game_zone_module/game_zone_screen.dart';
import 'package:spin_craze/features/quiz_module/quiz_screen.dart';
import 'package:spin_craze/features/scratch_module/pages/scratch_card.dart';
import 'package:spin_craze/features/spin_module/spin_page.dart';
import 'package:spin_craze/features/how_it_works_module/how_it_works_screen.dart';
import 'package:spin_craze/features/wallet_module/inner_screens/wallet_history/wallet_history_screen.dart';
import 'package:spin_craze/features/wallet_module/wallet_screen.dart';
import 'package:spin_craze/features/web_visits_module/web_visits_screen.dart';
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
  // onboarding (see [SplashScreen]).
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
          child: const SplashScreen(),
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
          child: OnboardingPage1(preloadedNativeAd: preloadedAd),
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
          child: const OnboardingPage2(),
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
          child: const OnboardingPage3(),
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
          child: const LoginScreen(),
        );
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return BottomNavPage(
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
        // Accept either the new LanguagePageArgs or the legacy `bool`
        // (`extra: true` means "onboarding") to avoid breaking existing
        // call sites that haven't been migrated yet.
        final extra = state.extra;
        LanguagePageArgs? args;
        if (extra is LanguagePageArgs) {
          args = extra;
        } else if (extra == true) {
          args = const LanguagePageArgs(isOnboarding: true);
        }
        final isOnboarding = args?.isOnboarding ?? false;

        return MaterialPage(
          key: state.pageKey,
          name: AppRoutes.language,
          child: LanguagePage(
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
        CountryPage(
          preloaded: state.extra as SelectionAds?,
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
        CurrencyPage(
          preloaded: state.extra as SelectionAds?,
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
        GameSelectPage(
          preloaded: state.extra as SelectionAds?,
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
          child: const SupportPage(),
        );
      },
    ),
    GoRoute(
      path: '/${AppRoutes.walletScreen}',
      name: AppRoutes.walletScreen,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(state, const WalletScreen()),
    ),
    GoRoute(
      path: '/${AppRoutes.walletHistory}',
      name: AppRoutes.walletHistory,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(state, const WalletHistoryScreen()),
    ),
    GoRoute(
      path: '/${AppRoutes.howItWorks}',
      name: AppRoutes.howItWorks,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(state, const HowItWorksScreen()),
    ),
    GoRoute(
      path: '/${AppRoutes.dailyCheckin}',
      name: AppRoutes.dailyCheckin,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(state, const DailyCheckinPage()),
    ),
    GoRoute(
      path: '/${AppRoutes.quizScreen}',
      name: AppRoutes.quizScreen,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(state, const QuizScreen()),
    ),
    GoRoute(
      path: '/${AppRoutes.scratchCard}',
      name: AppRoutes.scratchCard,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(state, const ScratchCardScreen()),
    ),
    GoRoute(
      path: '/${AppRoutes.webVisitsScreen}',
      name: AppRoutes.webVisitsScreen,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(state, const WebVisitsScreen()),
    ),
    GoRoute(
      path: '/${AppRoutes.gameZoneScreen}',
      name: AppRoutes.gameZoneScreen,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(state, const GameZoneScreen()),
    ),
    GoRoute(
      path: '/${AppRoutes.spinWheelScreen}',
      name: AppRoutes.spinWheelScreen,
      parentNavigatorKey: rootNavKey,
      pageBuilder: (context, state) => _fadeTransitionPage(state, const SpinWheelScreen()),
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
          return MaterialPage(key: state.pageKey, name: AppRoutes.home, child: const HomePage());
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
          return MaterialPage(key: state.pageKey, name: AppRoutes.rank, child: const RankPage());
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
          return MaterialPage(key: state.pageKey, name: AppRoutes.rewards, child: const RewardsPage());
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
          return MaterialPage(key: state.pageKey, name: AppRoutes.profile, child: const ProfilePage());
        },
      ),
    ],
  ),
];
