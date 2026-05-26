# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Current working mode — UI redesign pass

The user is doing a **full UI revamp**, screen by screen. Rules for this pass:

- **Only update UI** — layout, colors, spacing, typography, widgets, animations, imagery. Do **not** change app behavior, navigation flow, provider/state logic, network calls, route names, DI wiring, or data models.
- **Work step by step, one screen/feature at a time.** Wait for the user to point at the next screen instead of refactoring adjacent files proactively.
- **Assets will be provided by the user.** When a new asset is needed, ask for it rather than reusing an unrelated existing asset or inventing a placeholder. After new files are dropped into `assets/`, remember to re-run `dart run build_runner build --delete-conflicting-outputs` so [lib/gen/assets.gen.dart](lib/gen/assets.gen.dart) picks them up.
- Keep using the existing sizing conventions ([`flutter_screenutil`](lib/utils/app_size.dart) `.w/.h/.sp` on the 375×843 design size) and the `SFPro` font family — don't introduce a new design system.
- Don't touch [lib/l10n/](lib/l10n/) ARB files for UI-only tweaks unless the user adds/changes a string.

## Project overview

Spin Craze (`name: spin_craze`, displayed as "Spin Craze" / `ClipEarnApp`) is a Flutter rewards/earn app targeting Dart SDK `^3.11.0`. Users earn coins via mini-games (spin wheel, scratch card, quiz, web visits, game zone, daily check-in) and withdraw via cash, crypto, gift, or game rewards. Firebase project: `spin-craze-aec36` (Android-only currently — see [firebase.json](firebase.json); no iOS configuration in `firebase_options.dart`).

## Common commands

```bash
# Initial setup
flutter pub get

# Run on a connected device / emulator
flutter run

# Static analysis (uses flutter_lints; ad_manager package also uses very_good_analysis)
flutter analyze

# Tests
flutter test                                # all tests
flutter test test/widget_test.dart          # single file

# Localization codegen — runs automatically on `flutter pub get` / `flutter run`
# because pubspec.yaml has `flutter.generate: true` and l10n.yaml is present.
# Force a regen with:
flutter gen-l10n

# Assets/fonts codegen (flutter_gen, configured in pubspec.yaml -> flutter_gen)
dart run build_runner build --delete-conflicting-outputs

# Rename Android application id (uses change_app_package_name dev dep)
dart run change_app_package_name:main com.new.package.name
```

There is no iOS project committed; only Android is wired up. Do not try `flutter build ios`.

## Architecture

### Entry point and bootstrap order ([lib/main.dart](lib/main.dart))

`main()` runs a strict initialization sequence before `runApp`:
1. `Firebase.initializeApp` (with `DefaultFirebaseOptions.currentPlatform`)
2. Wire `FlutterError.onError` and `PlatformDispatcher.instance.onError` into `CrashlyticsManager`
3. `NotificationHelper.initializeNotification()` (FCM + flutter_local_notifications)
4. `Hive.initFlutter()` then `Injector.initModules()`
5. **`await Injector.instance.isReady<AppDB>()`** — `AppDB` is registered as `registerSingletonAsync`, so anything that touches it (including `_initialLocation()` in the router) must run after this line
6. `GoogleSignIn.instance.initialize()`, `RemoteConfigService.instance.init()`, `MobileAds.instance.initialize()`, GMA Unity mediation consent
7. Lock orientation to portrait

If you add new singletons that depend on Hive/Firebase, register them in [lib/di/inject_services.dart](lib/di/inject_services.dart) and (if async) await them here before `runApp`.

### Dependency injection ([lib/di/](lib/di/))

`get_it` only — no `injectable` / codegen. `Injector` is a thin static facade around `GetIt.instance`. The `inject_repositories.dart` file exists but is not currently invoked from `Injector.initModules()`; only `ServicesInjector` runs. `AppDB` is the sole registered singleton today.

### Local storage: `AppDB` ([lib/db/app_db.dart](lib/db/app_db.dart))

Single Hive box (`_appDbBox`) acting as a key-value store for the entire app: `userModel`, `selectedLanguage`, `internetStatus`, plus arbitrary `getValue<T>` / `setValue<T>` calls. Exposes per-key `Stream<BoxEvent>` listenables (e.g. `languageListenable()`, `userListenable()`) that the app uses to reactively rebuild — this is how `ClipEarnApp` swaps `MaterialApp.router`'s `locale` when the user changes language. On open failure the constructor nukes the app documents directory and retries.

### Routing ([lib/routes/app_router.dart](lib/routes/app_router.dart) + [app_routes.dart](lib/routes/app_routes.dart))

`go_router` with a single global `appRouter`. Structure:
- A `StatefulShellRoute.indexedStack` hosts the four bottom-nav tabs (home, rank, rewards, profile) inside `BottomNavPage`.
- All other feature screens (spin, scratch, quiz, wallet, game zone, web visits, language, support, in-app webview, etc.) are top-level `GoRoute`s using `rootNavKey` as `parentNavigatorKey` so they push **above** the shell and hide the bottom nav.
- Route names are string constants on `AppRoutes` — always reference them via `AppRoutes.foo`, never hardcode paths.
- `_initialLocation()` reads `AppDB.userModel` to decide between `home` and `onboarding1`. Because this runs at router construction (top-level `final`), `AppDB` must already be ready — that's the reason for the `await Injector.instance.isReady<AppDB>()` in `main()`.
- Feature screens use the shared `_fadeTransitionPage` helper for a 300ms fade. The `inAppWebView` route reads its arguments out of `state.extra` as a `Map<String, dynamic>`.

### Feature modules ([lib/features/](lib/features/))

Each feature lives in its own `_module/` folder with a roughly consistent shape: `*_page.dart` (or `*_screen.dart`), `provider/`, `widgets/`, sometimes `model/` and `inner_screens/`. State management is **`provider` (`ChangeNotifierProvider`)**, not Riverpod/Bloc. Currently only `HomeProvider` is registered globally in `MultiProvider`; other providers are scoped where they're used.

### Ads ([ad_manager/](ad_manager/) local package + [lib/services/](lib/services/) + [lib/utils/](lib/utils/))

`ad_manager` is a path-dep local Flutter package (`ad_manager: path: ad_manager` in pubspec) that wraps `google_mobile_ads` and re-exports it. It provides `BannerAdManager`, `InterstitialAdManager`, `NativeAdManager`, `RewardedAdManager`, `OpenAppAdManager`. The app layer adds:
- `lib/services/ad_repository_service.dart`, `reward_ad_service.dart`
- `lib/utils/` ad helpers: `interstitial_ad_manager.dart`, `native_ad_manager.dart`, `native_ad_mixin.dart`, `reward_ad_manager.dart`, `rewarded_ad_helper.dart`, `add_tap_manager.dart`, `ad_navigation_observer.dart`, `revenue_handler.dart`
- `lib/provider/open_ad_provider.dart` for app-open ads

Unity mediation is wired via `gma_mediation_unity` with CCPA + GDPR consent set to true at startup. Ad unit IDs and configuration come from Firebase Remote Config — see below.

### Remote Config ([lib/utils/remote_config.dart](lib/utils/remote_config.dart))

Singleton `RemoteConfigService` fetches two JSON keys at startup: `app_data` (ad config + general app data) and `visit_websites_games` (web visits / game zone targets). Fetch timeout 10s, minimum interval 1m. Failures are logged but non-fatal — the rest of the app continues with empty config.

### Localization ([lib/l10n/](lib/l10n/))

Standard Flutter intl with ARB files for 11 locales: `en, es, de, fr, ar, hi, pt, nl, sw, fil, ms`. `app_en.arb` is the template (see [l10n.yaml](l10n.yaml)). Generated code goes to `app_localizations*.dart` in the same folder and is committed. The active locale is driven by `AppDB.selectedLanguage`; changes to that key trigger a `MaterialApp.router` rebuild via the Hive listenable in `_ClipEarnAppState`.

### Theming and sizing ([lib/res/](lib/res/), [lib/utils/app_size.dart](lib/utils/app_size.dart))

Dark theme is the default (`theme: darkTheme` — `theme_light.dart` exists but is not currently wired). Font family is `SFPro` (bundled in `assets/fonts/`). The app uses `flutter_screenutil` with `designSize: Size(375, 843)` — use `.w`, `.h`, `.sp` for sizing rather than raw pixel values to stay consistent with existing screens.

### Assets ([lib/gen/](lib/gen/))

`assets.gen.dart` and `fonts.gen.dart` are generated by `flutter_gen_runner` (configured under `flutter_gen:` in pubspec.yaml). After adding/removing files under `assets/` or fonts in pubspec, re-run `dart run build_runner build --delete-conflicting-outputs`. Asset folders listed in pubspec include `assets/images/`, `assets/icons/`, `assets/images/spin/`, plus per-withdrawal-type icon folders (`assets/cash_withdraw_icons/`, `crypto_withdraw_icons/`, `gift_withdraw_icons/`, `game_withdraw_icons/`).

### Crashlytics / logging

- `CrashlyticsManager` ([lib/utils/crashlytics_manager.dart](lib/utils/crashlytics_manager.dart)) is hooked to both `FlutterError.onError` and `PlatformDispatcher.instance.onError`.
- App-wide logging uses the `logger` package via the `.logD` string extension in [lib/utils/logger.dart](lib/utils/logger.dart) (e.g. `'message'.logD`). Prefer this over `print`.

### Lints

Root `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`. The `ad_manager` sub-package uses `very_good_analysis` — code there is held to a stricter bar (single quotes, public-member docs, etc.); match the existing style when editing files under [ad_manager/lib/](ad_manager/lib/).
