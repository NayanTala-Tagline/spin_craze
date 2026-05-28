# Ads onboarding guide

How to wire the `ad_manager` package into a Flutter app the same way this project does. Hand this doc to any new project and follow it top-to-bottom.

The golden rule: **use only the two switchable wrappers** — `InlineAdManager` for inline (banner/native/custom) and `FullScreenAdManager` for full-screen (interstitial/openApp/rewarded/custom). Never instantiate `BannerAdManager`, `NativeAdManager`, `OpenAppAdManager`, `InterstitialAdManager`, `RewardedAdManager` directly in app code. The wrappers route to the right underlying manager based on `AdData.adType`, which means you can flip an ad type from Firebase Remote Config with zero code changes.

---

## Table of contents

1. [Dependencies & platform setup](#1-dependencies--platform-setup)
2. [Remote Config JSON shape](#2-remote-config-json-shape)
3. [RemoteConfigService](#3-remoteconfigservice)
4. [AdSlot widget (shimmer loader for inline)](#4-adslot-widget-shimmer-loader-for-inline)
5. [Splash screen — internet check + preload + app-open](#5-splash-screen--internet-check--preload--app-open)
6. [Onboarding provider — preload + interstitial transition](#6-onboarding-provider--preload--interstitial-transition)
7. [Onboarding screens — Next button + bottom ad slot](#7-onboarding-screens--next-button--bottom-ad-slot)
8. [Routes — forwarding preloaded ads via `extra`](#8-routes--forwarding-preloaded-ads-via-extra)
9. [Language screen — dual ads, onboarding-only](#9-language-screen--dual-ads-onboarding-only)
10. [Gotchas & debug checklist](#10-gotchas--debug-checklist)

---

## 1. Dependencies & platform setup

### `pubspec.yaml`

```yaml
dependencies:
  ad_manager:
    path: ad_manager           # or your pub / git reference
  firebase_core: ^4.x
  firebase_remote_config: ^6.x
  internet_connection_checker_plus: ^2.x
  shimmer: ^3.x
  url_launcher: ^6.x
  provider: ^6.x
  go_router: ^17.x
```

### `main.dart`

Initialize Firebase → AppDB/DI → `MobileAds.instance.initialize()` before `runApp`. Remote Config init runs inside the splash screen so the loader can react to its result (see [section 5](#5-splash-screen--internet-check--preload--app-open)).

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  Injector.initModules();
  await Injector.instance.isReady<AppDB>();
  await MobileAds.instance.initialize();
  runApp(const MyApp());
}
```

### Android manifest

Add the AdMob App ID under `<application>`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"/>
```

For local debug builds use Google's test App ID: `ca-app-pub-3940256099942544~3347511713`.

### iOS `Info.plist`

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
```

### Native ad factory (required for native slots)

If any slot can render as `native`, register a platform-side factory with id `"default_native_factory"` on Android (MainActivity) and iOS (AppDelegate) per the [google_mobile_ads native ads guide](https://pub.dev/packages/google_mobile_ads). Without it, every native ad request errors out before reaching the fill stage.

---

## 2. Remote Config JSON shape

Store a single JSON string under a per-platform key (`android`, `ios`). Each ad slot is a map with the six fields below.

### Field reference

| Field | Type | Required | Notes |
|---|---|---|---|
| `ad_id` | string | yes | Unit ID. Empty for `custom`. |
| `enabled` | bool | yes | `false` → manager resolves to `AdStatus.disabled` and renders nothing. |
| `ad_type` | string | yes | **One of** `banner`, `native`, `openApp`, `interstatial` (note the typo — that is the enum), `rewarded`, `custom`. |
| `template_type` | string | native only | `small` or `medium`. |
| `height` | number | no | Logical pixels. 0 = intrinsic height. |
| `custom_ad_view_url` | string | custom inline | Image URL for the inline creative. |
| `custom_ad_url` | string | custom | Landing URL. |

### Gotcha — `ad_type`

- The enum is `AdType.interstatial`. Any other spelling falls back to `AdType.native`, which makes `FullScreenAdManager` skip creating an underlying manager → ad never shows.
- When `ad_type` is absent, `RemoteConfigService._getAdData` defaults it to `"native"`. Always set it explicitly.

### Example payload (all slots this project uses)

```json
{
  "splash_banner":       {"ad_id": "ca-app-pub-3940256099942544/6300978111", "enabled": true, "ad_type": "banner"},
  "splash_app_open":     {"ad_id": "ca-app-pub-3940256099942544/9257395921", "enabled": true, "ad_type": "openApp"},

  "onboarding_screen1":  {"ad_id": "ca-app-pub-3940256099942544/2247696110", "enabled": true, "ad_type": "native", "template_type": "medium", "height": 320},
  "onboarding_screen2":  {"ad_id": "ca-app-pub-3940256099942544/2247696110", "enabled": true, "ad_type": "native", "template_type": "medium", "height": 320},
  "onboarding_screen3":  {"ad_id": "ca-app-pub-3940256099942544/2247696110", "enabled": true, "ad_type": "native", "template_type": "medium", "height": 320},

  "onboarding_inter1":   {"ad_id": "ca-app-pub-3940256099942544/1033173712", "enabled": true, "ad_type": "interstatial"},
  "onboarding_inter2":   {"ad_id": "ca-app-pub-3940256099942544/1033173712", "enabled": true, "ad_type": "interstatial"},
  "onboarding_inter3":   {"ad_id": "ca-app-pub-3940256099942544/1033173712", "enabled": true, "ad_type": "interstatial"},

  "language_screen1":    {"ad_id": "ca-app-pub-3940256099942544/2247696110", "enabled": true, "ad_type": "native", "template_type": "medium", "height": 320},
  "language_screen2":    {"ad_id": "ca-app-pub-3940256099942544/2247696110", "enabled": true, "ad_type": "native", "template_type": "small",  "height": 120},

  "home_native":         {"ad_id": "ca-app-pub-3940256099942544/2247696110", "enabled": true, "ad_type": "native", "template_type": "medium", "height": 320},

  "show_multiple_onboarding": false,
  "skip_onboarding": false
}
```

---

## 3. RemoteConfigService

A single service that fetches the JSON once and exposes a typed getter per slot. Location: `lib/utils/remote_config.dart`.

Key choices:
- `fetchTimeout: 10s`, `minimumFetchInterval: 1min`.
- Reads the `android` key. Extend with `ios` if you support iOS.
- `_getAdData(key)` normalizes every field and returns a disabled `AdData` when the key is missing/invalid. Errors are logged, not thrown.
- Two behavior flags live next to the ads: `showMultipleOnboarding`, `skipOnboarding`.

Add one getter per slot:

```dart
AdData get splashBanner       => getAd('splash_banner');
AdData get splashAppOpen      => getAd('splash_app_open');

AdData get onboarding1        => getAd('onboarding_screen1');
AdData get onboarding2        => getAd('onboarding_screen2');
AdData get onboarding3        => getAd('onboarding_screen3');

AdData get onboardingInter1   => getAd('onboarding_inter1');
AdData get onboardingInter2   => getAd('onboarding_inter2');
AdData get onboardingInter3   => getAd('onboarding_inter3');

AdData get language1          => getAd('language_screen1');
AdData get language2          => getAd('language_screen2');

AdData get homeNative         => getAd('home_native');

bool get showMultipleOnboarding => getValue('show_multiple_onboarding', false);
bool get skipOnboarding         => getValue('skip_onboarding', false);
```

`init()` is called from the splash — never from `main.dart`, so the splash UI can show a loader while it runs.

---

## 4. AdSlot widget (shimmer loader for inline)

`InlineAdManager.adWidget()` handles its own rendering, but during load:
- Banner → built-in shimmer already.
- Native → `SizedBox.shrink()` (blank).

We wrap it in a widget that shows a themed shimmer placeholder until the ad's `future()` resolves, then either renders the ad or collapses if it failed.

Location: `lib/widgets/ad_slot.dart`.

```dart
class AdSlot extends StatefulWidget {
  const AdSlot({super.key, this.ad, this.height});
  final InlineAdManager? ad;
  final double? height;

  @override
  State<AdSlot> createState() => _AdSlotState();
}

class _AdSlotState extends State<AdSlot> {
  @override
  void initState() {
    super.initState();
    widget.ad?.future().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    if (ad == null) return const SizedBox.shrink();
    if (ad.isFailed) return const SizedBox.shrink();

    final placeholderHeight = widget.ad?.adData.height ?? AppSize.h120;
    if (!ad.isLoaded) return _ShimmerPlaceholder(height: placeholderHeight);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.w8, vertical: AppSize.h6),
      child: ad.adWidget(),
    );
  }
}
```

The shimmer is built with the `shimmer` package, colored off `context.themeColors`. Use `AdSlot` wherever you place an inline ad — it gives you a free loading skeleton.

---

## 5. Splash screen — internet check + preload + app-open

Location: `lib/features/splash_screen/splash_screen.dart`.

### Responsibilities

1. Check internet (show branded no-internet card with Retry on failure).
2. Initialize Remote Config.
3. Start loading the splash banner (non-blocking).
4. Preload the **next screen's** inline ad (home or onboarding1) — blocking so the user doesn't land on an empty slot.
5. Load the splash full-screen ad (app-open / interstitial / custom) — blocking.
6. Show the full-screen ad; navigate on its dismiss callback.

### State fields (wrappers only)

```dart
InlineAdManager?       _splashBanner;
FullScreenAdManager?   _splashFullScreen;
InlineAdManager?       _onboardingInline;
InlineAdManager?       _homeInline;
```

### Routing decision

```dart
bool _shouldGoHome() {
  final rc = RemoteConfigService.instance;
  if (rc.skipOnboarding) return true;
  if (rc.showMultipleOnboarding) return false;
  return _appDB.isOnboardingCompleted ?? false;
}
```

### Banner: `.future()` not `.load().then()`

`BannerAd.load()` resolves when the request is initiated, not when the ad actually loads. Always drive `setState` from `future()`:

```dart
unawaited(_splashBanner!.load());
unawaited(
  _splashBanner!.future().then((status) {
    if (mounted) setState(() {});
  }),
);
```

### Full-screen: dismiss callback drives navigation

```dart
_splashFullScreen = FullScreenAdManager(
  adData: openData,
  openAppCallback: FullScreenContentCallback<AppOpenAd>(
    onAdDismissedFullScreenContent: (_) => _navigateNext(),
    onAdFailedToShowFullScreenContent: (_, _) => _navigateNext(),
  ),
  interstitialCallback: FullScreenContentCallback<InterstitialAd>(
    onAdDismissedFullScreenContent: (_) => _navigateNext(),
    onAdFailedToShowFullScreenContent: (_, _) => _navigateNext(),
  ),
);
await _splashFullScreen!.load();
await _splashFullScreen!.future();
```

Wire callbacks for both `openApp` and `interstitial` so Remote Config can flip the slot without code changes.

### Custom creative on splash

```dart
if (ad.adData.adType == AdType.custom && ad.isLoaded) {
  await launchUrlString(ad.adData.customAdUrl, mode: LaunchMode.externalApplication);
  await Future<void>.delayed(const Duration(milliseconds: 400));
  _navigateNext();
  return;
}
```

### UI: logo + linear loader + banner

Keep the existing splash design. Add a thin `LinearProgressIndicator` and the banner pinned to the bottom:

```dart
Positioned(
  left: 0, right: 0, bottom: 0,
  child: SafeArea(
    top: false,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: AppSize.h3,
          child: LinearProgressIndicator(
            minHeight: AppSize.h3,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            valueColor: AlwaysStoppedAnimation<Color>(context.themeColors.primary),
          ),
        ),
        if (_splashBanner != null)
          SizedBox(
            height: AppSize.h50,
            width: double.infinity,
            child: _splashBanner!.adWidget(),
          ),
      ],
    ),
  ),
),
```

### Dispose ownership

Splash disposes banner + full-screen. The **next-screen inline** (home/onboarding1) is handed off via `extra` — don't dispose it here.

```dart
@override
void dispose() {
  _splashBanner?.dispose();
  _splashFullScreen?.dispose();
  super.dispose();
}
```

---

## 6. Onboarding provider — preload + interstitial transition

Location: `lib/features/onboarding_module/provider/onboarding_provider.dart`.

### State

```dart
InlineAdManager?     nextInline;        // native to pass to the next screen
InlineAdManager?     nextInline2;       // second native (only for language)
FullScreenAdManager? transitionInter;   // interstitial between this screen and the next
Completer<void>?     _interDismissCompleter;
bool                 _busy = false;     // drives Next-button spinner
```

### Preload helpers

One helper per preload target. Onboarding1 preloads onboarding2's native + inter1. Onboarding2 preloads onboarding3's native + inter2. Onboarding3 preloads the two language natives + inter3.

```dart
void preloadOnboarding2Native() {
  nextInline = InlineAdManager(adData: RemoteConfigService.instance.onboarding2);
  nextInline?.load();
}

void preloadLanguageNatives() {
  nextInline  = InlineAdManager(adData: RemoteConfigService.instance.language1);
  nextInline2 = InlineAdManager(adData: RemoteConfigService.instance.language2);
  nextInline?.load();
  nextInline2?.load();
}

void _preloadInter(String tag, AdData data) {
  transitionInter = FullScreenAdManager(
    adData: data,
    interstitialCallback: FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (_) => _completeInterDismiss(),
      onAdFailedToShowFullScreenContent: (_, __) => _completeInterDismiss(),
    ),
  );
  transitionInter?.load();
}

void _completeInterDismiss() {
  final c = _interDismissCompleter;
  if (c != null && !c.isCompleted) c.complete();
}
```

### Transition — critical rules

1. Set `_busy = true` first so the screen's Next button can show a spinner and ignore repeated taps.
2. For `AdType.custom` → launch URL, small delay, navigate.
3. For real full-screen → `await inter.future()` (wait for load result) → `await inter.show()` → **await the dismiss completer** before navigating. This is the fix for the "ad shows for a frame then disappears" bug — navigating immediately races the ad's overlay.
4. `finally` block clears `_busy` and notifies.

```dart
Future<void> _transition({
  required BuildContext context,
  required String routeName,
  Object? extra,
}) async {
  if (_busy) return;
  _busy = true;
  notifyListeners();

  final inter = transitionInter;
  final interData = inter?.adData;

  try {
    if (interData != null && interData.adType == AdType.custom) {
      try {
        await launchUrlString(interData.customAdUrl, mode: LaunchMode.inAppBrowserView);
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!context.mounted) return;
      _go(context, routeName, extra);
      return;
    }

    if (inter != null && (interData?.enabled ?? false)) {
      await inter.future();
      if (inter.isLoaded) {
        _interDismissCompleter = Completer<void>();
        final shown = await inter.show();
        if (shown) {
          await _interDismissCompleter!.future.timeout(
            const Duration(seconds: 30),
            onTimeout: () {},
          );
        }
        _interDismissCompleter = null;
      }
    }

    if (!context.mounted) return;
    _go(context, routeName, extra);
  } finally {
    _busy = false;
    if (hasListeners) notifyListeners();
  }
}
```

### Public transition methods

```dart
Future<void> nextTo2(BuildContext context) =>
    _transition(context: context, routeName: AppRoutes.onBoarding2);

Future<void> nextTo3(BuildContext context) =>
    _transition(context: context, routeName: AppRoutes.onBoarding3);

Future<void> nextToLanguage(BuildContext context) async {
  Injector.instance<AppDB>().isOnboardingCompleted = true;   // end-of-flow marker
  await _transition(
    context: context,
    routeName: AppRoutes.languageScreen,
    extra: {
      'isFromHome': false,
      'inlineAd1': nextInline,
      'inlineAd2': nextInline2,
    },
  );
}
```

`nextToLanguage` also sets `isOnboardingCompleted = true` — the splash reads this on next launch to decide home vs onboarding.

### Dispose

```dart
@override
void dispose() {
  nextInline?.dispose();
  nextInline2?.dispose();
  transitionInter?.dispose();
  super.dispose();
}
```

---

## 7. Onboarding screens — Next button + bottom ad slot

Pattern is identical for Onboarding1, 2, 3. Each screen:

1. Accepts an optional `inlineAd` (passed from the previous screen via `extra`).
2. Creates an `OnboardingProvider` inside `ChangeNotifierProvider`, calling the two preloads for its outgoing transition.
3. The Next button calls `provider.nextToN(context)` and shows a spinner while `provider.busy`.
4. The bottom nav bar is an `AdSlot` wrapping `widget.inlineAd`.

```dart
class Onboarding1 extends StatefulWidget {
  const Onboarding1({super.key, this.inlineAd});
  final InlineAdManager? inlineAd;
  @override
  State<Onboarding1> createState() => _Onboarding1State();
}

class _Onboarding1State extends State<Onboarding1> {
  @override
  void dispose() {
    widget.inlineAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingProvider()
        ..preloadOnboarding2Native()
        ..preloadInter1(),
      child: Consumer<OnboardingProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            bottomNavigationBar: SafeArea(
              top: false,
              child: Container(
                color: context.themeColors.backgroundColor,
                child: AdSlot(ad: widget.inlineAd),
              ),
            ),
            body: /* … Next button calls provider.nextTo2(context) */,
          );
        },
      ),
    );
  }
}
```

### Next button

```dart
TextButton(
  onPressed: provider.busy ? null : () => provider.nextTo2(context),
  child: provider.busy
      ? SizedBox(
          height: AppSize.h20, width: AppSize.h20,
          child: CircularProgressIndicator(strokeWidth: 2, color: context.themeColors.primary),
        )
      : Text('Next', /* … */),
),
```

### Ownership

The receiving screen disposes the inline ad it was handed. The provider's `nextInline` is passed to the **next** screen, and that next screen's State disposes it. The provider also disposes it on `dispose()` as a safety net for screens the user backs out of before navigating.

---

## 8. Routes — forwarding preloaded ads via `extra`

Two patterns:

### Single inline ad via `extra`

```dart
GoRoute(
  path: '/${AppRoutes.onBoarding2}',
  name: AppRoutes.onBoarding2,
  pageBuilder: (context, state) {
    final ad = state.extra is InlineAdManager ? state.extra as InlineAdManager : null;
    return MaterialPage(key: state.pageKey, child: Onboarding2(inlineAd: ad));
  },
),
```

Apply the same shape for `onBoarding1`, `onBoarding3`, `homeScreen`.

### Map of named extras (language screen gets two ads + a flag)

```dart
GoRoute(
  path: '/${AppRoutes.languageScreen}',
  name: AppRoutes.languageScreen,
  pageBuilder: (context, state) {
    final extras = state.extra is Map<String, dynamic>
        ? state.extra as Map<String, dynamic>
        : <String, dynamic>{};
    final isFromHome = extras['isFromHome'] as bool? ?? false;
    final inlineAd1  = extras['inlineAd1'] is InlineAdManager ? extras['inlineAd1'] as InlineAdManager : null;
    final inlineAd2  = extras['inlineAd2'] is InlineAdManager ? extras['inlineAd2'] as InlineAdManager : null;
    return MaterialPage(
      key: state.pageKey,
      child: LanguagePage(isFromHome: isFromHome, inlineAd1: inlineAd1, inlineAd2: inlineAd2),
    );
  },
),
```

---

## 9. Language screen — dual ads, onboarding-only

`LanguagePage` accepts `inlineAd1`, `inlineAd2`, and an existing `isFromHome` flag. Both ads render **only when `!isFromHome`** — because from Home the user is just changing language, not onboarding.

```dart
class LanguagePage extends StatefulWidget {
  const LanguagePage({
    super.key,
    this.isFromHome = false,
    this.inlineAd1,
    this.inlineAd2,
  });

  final bool isFromHome;
  final InlineAdManager? inlineAd1;
  final InlineAdManager? inlineAd2;
}
```

Kick a rebuild when either future resolves, dispose on unmount:

```dart
@override
void initState() {
  super.initState();
  widget.inlineAd1?.future().then((_) { if (mounted) setState(() {}); });
  widget.inlineAd2?.future().then((_) { if (mounted) setState(() {}); });
}

@override
void dispose() {
  widget.inlineAd1?.dispose();
  widget.inlineAd2?.dispose();
  super.dispose();
}
```

Place them around the language list:

```dart
if (!widget.isFromHome) ...[
  // … heading / subtitle …
  if (widget.inlineAd1 != null) ...[
    SizedBox(height: AppSize.h8),
    AdSlot(ad: widget.inlineAd1),
  ],
],
// … language ListView …
if (!widget.isFromHome && widget.inlineAd2 != null) ...[
  SizedBox(height: AppSize.h8),
  AdSlot(ad: widget.inlineAd2),
],
```

"Get Started" also sets `AppDB.isOnboardingCompleted = true` so the splash can skip onboarding next launch.

---

## 10. Gotchas & debug checklist

### When ads don't show, walk the checklist in order

1. **Logs — is Remote Config loading?** Look for `Remote config loaded successfully` from `RemoteConfigService.init()`. If you see `android key is empty in Remote Config` or `Remote config fetch failed`, everything downstream is disabled; fix Firebase / network first.
2. **Per-slot logs.** In this project every ad load logs `id=… enabled=… type=…` and the eventual `loaded`/`FAILED`/`disabled`/`idle`. If `enabled=false` appears on every slot, Remote Config is empty and you are seeing `_emptyAd()` defaults.
3. **`ad_type` spelling.** `interstatial`, not `interstitial`. Otherwise `FullScreenAdManager` silently creates no manager → nothing shows.
4. **Missing `ad_type` field.** `RemoteConfigService` defaults it to `"native"`. Silently wrong for banner / interstitial / app-open slots.
5. **Native factory.** If any native slot reports load errors about a missing factory, you forgot to register `"default_native_factory"` on the platform side.
6. **"no fill" with test IDs + 403 HTTP response.** This is platform-level, not code. Usual fixes, in order:
   - Device system date/time correct.
   - Emulator has a Play Store image (not "Google APIs" only).
   - No VPN.
   - Wipe emulator data if previously registered as a spammed test device.
7. **Banner shows shimmer forever.** Drive `setState` from `future()`, not `load().then()`. `BannerAd.load()` resolves before the actual load completes.
8. **Interstitial "loads but doesn't show" / "shows for a frame".** You're navigating immediately after `show()`. Wait for the dismiss callback via a `Completer<void>` (see section 6).
9. **Ad disposed twice / "AdWidget already has a parent".** The wrapper is a reference. Decide who owns disposal — the screen that finally renders it. Splash hands off to next screen via `extra`; next screen disposes in `State.dispose`. The provider also safety-disposes its own references on provider `dispose`.
10. **`context` across async gaps.** Guard every navigation after `await` with `if (!context.mounted) return;`. We do this in the provider's `_transition`.

### Reference file paths

- [lib/utils/remote_config.dart](lib/utils/remote_config.dart)
- [lib/widgets/ad_slot.dart](lib/widgets/ad_slot.dart)
- [lib/features/splash_screen/splash_screen.dart](lib/features/splash_screen/splash_screen.dart)
- [lib/features/onboarding_module/provider/onboarding_provider.dart](lib/features/onboarding_module/provider/onboarding_provider.dart)
- [lib/features/onboarding_module/onboarding1_screen.dart](lib/features/onboarding_module/onboarding1_screen.dart)
- [lib/features/onboarding_module/onboarding2_screen.dart](lib/features/onboarding_module/onboarding2_screen.dart)
- [lib/features/onboarding_module/onboarding3_screen.dart](lib/features/onboarding_module/onboarding3_screen.dart)
- [lib/features/onboarding_module/language_page/language_page.dart](lib/features/onboarding_module/language_page/language_page.dart)
- [lib/routes/app_router.dart](lib/routes/app_router.dart)

### Quick copy-paste for a new screen that needs one inline ad

1. Add a Remote Config key + matching getter in `RemoteConfigService`.
2. On the screen **before** it, preload via the provider:
   ```dart
   nextInline = InlineAdManager(adData: RemoteConfigService.instance.mySlot)..load();
   ```
3. Navigate with the manager in `extra`: `context.pushNamed(route, extra: nextInline);`
4. Update the route's `pageBuilder` to read `state.extra as InlineAdManager?`.
5. Accept `InlineAdManager? inlineAd` in the receiving screen's constructor.
6. Render `AdSlot(ad: widget.inlineAd)` at the bottom (inside `SafeArea`).
7. `dispose()` → `widget.inlineAd?.dispose();`

That's the whole pattern.
