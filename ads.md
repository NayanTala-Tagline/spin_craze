# Ads — migration & integration guide

A drop-in playbook for upgrading an older app from an outdated `ad_manager` package to the version shipped in this project. Hand this file to any old codebase and follow it top-to-bottom — at the end you'll have the same Remote-Config-driven, hot-swappable ad pipeline that `btc_mining_7` uses.

The golden rule: in app code use **only the two switchable wrappers** — `InlineAdManager` for inline slots (banner/native/custom) and `FullScreenAdManager` for full-screen slots (interstitial/openApp/rewarded/custom). Never instantiate `BannerAdManager`, `NativeAdManager`, `InterstitialAdManager`, `OpenAppAdManager`, or `RewardedAdManager` directly — the wrappers route to the right one based on `AdData.adType`, so a slot can be flipped between types from the Firebase console with **zero code changes**.

---

## Table of contents

1. [What changed vs. the old package](#1-what-changed-vs-the-old-package)
2. [Dependencies & platform setup](#2-dependencies--platform-setup)
3. [`main.dart` boot sequence](#3-maindart-boot-sequence)
4. [Remote Config — JSON shape & service](#4-remote-config--json-shape--service)
5. [Inline ads — `AdSlot` widget](#5-inline-ads--adslot-widget)
6. [Full-screen ads on resume — `OpenAdProvider`](#6-full-screen-ads-on-resume--openadprovider)
7. [Full-screen ads on navigation — `NavigationHelper`](#7-full-screen-ads-on-navigation--navigationhelper)
8. [Rewarded ads — `RewardAdHelper`](#8-rewarded-ads--rewardadhelper)
9. [Custom (image / URL) ads](#9-custom-image--url-ads)
10. [Migration checklist — old → new](#10-migration-checklist--old--new)
11. [Gotchas & debug checklist](#11-gotchas--debug-checklist)

---

## 1. What changed vs. the old package

| Concern | Old package (typical) | New `ad_manager` (this project) |
|---|---|---|
| One class per ad type | `BannerAd`, `InterstitialAd`, `RewardedAd` instantiated everywhere | Two wrappers: `InlineAdManager` + `FullScreenAdManager` |
| Type switch | Code change & app release | Flip `ad_type` in Firebase Remote Config — no release |
| Custom (image/URL) ads | Not supported | First-class `AdType.custom` for inline and full-screen |
| Lifecycle | Manual listener wiring | `load()` → `await future()` → `show()` / `adWidget()` → `dispose()` |
| Analytics | Manual events | Built-in Firebase Analytics + `ad_impression` paid-revenue event |
| Consent (rewarded) | Custom dialog per call site | Built-in dialog, overridable via `RewardedConsent.setConsentDialogBuilder` |
| Mediation | Manual adapter setup | Unity / AppLovin / Meta / IronSource / InMobi / Pangle pre-bundled |
| Config source | Hard-coded ad IDs in code | All slots driven by a single JSON in Remote Config |

The migration story is mostly **delete code**: rip out per-ad classes, listener glue, and hard-coded IDs; replace each call site with an `InlineAdManager` or `FullScreenAdManager` reading from `RemoteConfigService`.

---

## 2. Dependencies & platform setup

### `pubspec.yaml`

Copy the `ad_manager` folder from this repo (or reference your own fork) and wire it in via `path:`:

```yaml
dependencies:
  ad_manager:
    path: ad_manager
  firebase_core: ^4.x
  firebase_remote_config: ^6.x
  google_mobile_ads: ^6.x      # re-exported via ad_manager
  shimmer: ^3.x                # for inline shimmer placeholder
  url_launcher: ^6.x           # for AdType.custom links
  provider: ^6.x               # OpenAdProvider lives in a MultiProvider
```

Then `flutter pub get` in **both** the app root **and** inside `ad_manager/` if you change its deps.

### Android — `android/app/src/main/AndroidManifest.xml`

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"/>
```

Use `ca-app-pub-3940256099942544~3347511713` for local debug.

### iOS — `ios/Runner/Info.plist`

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
```

### Native ad factory (only if any slot can render as `native`)

Register `"default_native_factory"` on the platform side per the [google_mobile_ads native ads guide](https://pub.dev/packages/google_mobile_ads). Without it, every native request fails before fill.

---

## 3. `main.dart` boot sequence

Order matters. Remote Config **must finish before any ad manager is constructed** because every `AdData` is read from it. Mirror the sequence in [lib/main.dart](lib/main.dart):

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = (d) => CrashlyticsManager.instance.logFlutterError(d);
  PlatformDispatcher.instance.onError = (e, s) {
    CrashlyticsManager.instance.logHandledDartError(error: e, stackTrace: s);
    return true;
  };

  await Hive.initFlutter();
  Injector.initModules();
  await Injector.instance.isReady<AppDB>();
  await GoogleSignIn.instance.initialize();

  await RemoteConfigService.instance.init();   // 1. fetch ad config first
  await MobileAds.instance.initialize();       // 2. then init GMA SDK

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => RewardProvider()),
      ChangeNotifierProvider(create: (_) => AdsProvider()),
    ],
    child: const MyApp(),
  ));
}
```

If your app already calls `MobileAds.instance.initialize()` before Remote Config, **swap them**. Otherwise the first ad request runs against `_emptyAd()` defaults (everything disabled) and you'll spend an hour wondering why nothing shows.

---

## 4. Remote Config — JSON shape & service

The project uses **two** JSON-string parameters in Firebase Remote Config:

| Parameter | Purpose |
|---|---|
| `android` | All ad slots + a few app-level toggles (read on both platforms — see note below) |
| `btc_cloud_manager` | Game economy / booster tuning (mining duration, rewards table, withdraw thresholds, …) |

Note — despite the parameter being named `android`, this codebase reads the **same key** on both platforms (the upstream `ad_manager` README describes a per-platform `android`/`ios` split that this app does not implement). If you need iOS-specific ad IDs, add an `ios` parameter and switch on `Platform.isIOS` in `init()`.

### 4.1 `AdData` JSON shape

Each ad slot is a map with these fields. Spelling matters.

| Field | Type | Required | Notes |
|---|---|---|---|
| `ad_id` | string | yes | AdMob unit ID. Empty string for `custom`. |
| `enabled` | bool | yes | `false` → manager resolves to `AdStatus.disabled`, renders nothing. |
| `ad_type` | string | yes | One of `banner`, `native`, `interstatial` (note the typo — that **is** the enum), `rewarded`, `openApp`, `custom`. |
| `template_type` | string | native only | `small` or `medium`. |
| `height` | number | no | Logical pixels. `0` = intrinsic height. |
| `custom_ad_view_url` | string | custom inline | Image URL for the inline creative. |
| `custom_ad_url` | string | custom | Landing URL opened on tap (inline) or on show (full-screen). |

**Gotchas:**
- `ad_type` enum is `AdType.interstatial` (missing an `i`). Any other spelling silently falls back to `AdType.native` → `FullScreenAdManager` skips creating an underlying manager and nothing shows.
- When `ad_type` is absent, `RemoteConfigService._getAdData` defaults it to `"native"`. Always set it explicitly.

### 4.2 Example `android` payload (slots used in this project)

```json
{
  "app_click_counter": 15,
  "privacy_policy_url": "https://example.com/privacy",
  "terms_and_conditions": "https://example.com/terms",
  "show_multiple_onboarding": false,

  "Application_appOpen":    {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "openApp"},

  "app_inter":              {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "interstatial"},
  "start_inter":            {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "interstatial"},
  "fortune_games_inter":    {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "interstatial"},

  "app_native":             {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "native", "template_type": "medium", "height": 320},
  "start_native":           {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "native", "template_type": "medium", "height": 320},
  "accounts_native":        {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "native", "template_type": "small",  "height": 120},
  "congratulation_screen":  {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "native", "template_type": "medium", "height": 320},

  "onboarding_screen1":     {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "native", "template_type": "medium", "height": 320},
  "onboarding_screen2":     {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "native", "template_type": "medium", "height": 320},
  "onboarding_screen3":     {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "native", "template_type": "medium", "height": 320},

  "onboarding_inter1":      {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "interstatial"},
  "onboarding_inter2":      {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "interstatial"},
  "onboarding_inter3":      {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "interstatial"},

  "language_native_1":      {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "native", "template_type": "medium", "height": 320},
  "language_native_2":      {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "native", "template_type": "small",  "height": 120},

  "bottom_nav_banner_1":    {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "banner"},
  "bottom_nav_banner_2":    {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "banner"},
  "bottom_nav_banner_3":    {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "banner"},
  "bottom_nav_banner_4":    {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "banner"},

  "daily_reward_1":         {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "rewarded"},
  "daily_reward_2":         {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "rewarded"},
  "start_mining_reward":    {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "rewarded"},
  "node_efficiency_reward": {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "rewarded"},
  "session_duration_reward":{"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "rewarded"},
  "combined_session_reward":{"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "rewarded"},
  "spin_reward":            {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "rewarded"},
  "scratch_reward":         {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "rewarded"},
  "reward_speed_boost":     {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "rewarded"},
  "reward_time_boost":      {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "rewarded"},
  "play_game_reward":       {"ad_id": "ca-app-pub-…/…", "enabled": true, "ad_type": "rewarded"}
}
```

> Replace the IDs with your live AdMob unit IDs before release. For local debug use Google's test unit IDs from the [ad_manager README](ad_manager/README.md#json-format).

### 4.3 `RemoteConfigService`

Singleton with one typed getter per slot. See [lib/utils/remote_config.dart](lib/utils/remote_config.dart) for the full file — the shape you need is:

```dart
class RemoteConfigService {
  static final RemoteConfigService instance = RemoteConfigService._internal();
  RemoteConfigService._internal();

  final _rc = FirebaseRemoteConfig.instance;
  Map<String, dynamic> _appData = {};
  Map<String, dynamic> _btcCloudManager = {};

  Future<void> init() async {
    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(minutes: 1),
    ));
    try {
      await _rc.fetchAndActivate();
    } catch (e) { '⚠️ RC fetch failed: $e'.logD; return; }

    _appData         = _decode(_rc.getString('android'));
    _btcCloudManager = _decode(_rc.getString('btc_cloud_manager'));
  }

  Map<String, dynamic> _decode(String s) =>
      s.isEmpty ? {} : jsonDecode(s) as Map<String, dynamic>;

  // Normalised AdData read — defaults safely on missing/invalid keys.
  AdData _getAdData(String key) {
    final raw = _appData[key];
    if (raw is! Map) return AdData.fromJson(_emptyAd());
    return AdData.fromJson({
      'ad_id':             raw['ad_id']             ?? '',
      'enabled':           raw['enabled']           ?? false,
      'ad_type':           raw['ad_type']           ?? 'native',
      'template_type':     raw['template_type']     ?? 'small',
      'height':            (raw['height'] is num) ? (raw['height'] as num).toDouble() : 0.0,
      'custom_ad_view_url':raw['custom_ad_view_url']?? '',
      'custom_ad_url':     raw['custom_ad_url']     ?? '',
    });
  }

  Map<String, dynamic> _emptyAd() => {
    'ad_id': '', 'enabled': false, 'ad_type': 'native',
    'template_type': 'small', 'height': 0.0,
    'custom_ad_view_url': '', 'custom_ad_url': '',
  };

  // One getter per slot — examples:
  AdData get applicationAppOpen => _getAdData('Application_appOpen');
  AdData get appInter           => _getAdData('app_inter');
  AdData get appNative          => _getAdData('app_native');
  AdData get spinReward         => _getAdData('spin_reward');
  // … (see remote_config.dart for the full list)

  int    get appClickCounter    => (_appData['app_click_counter'] ?? 15) as int;
  String get privacyPolicyUrl   => (_appData['privacy_policy_url'] ?? '') as String;
}
```

**Never call `FirebaseRemoteConfig.instance` directly outside this file.** Add a typed getter and read it from the feature. This is the single point where new tunables live.

---

## 5. Inline ads — `AdSlot` widget

`InlineAdManager.adWidget()` handles its own rendering, but during load it can be blank (native) or default-shimmer (banner). We wrap it in [lib/features/onboarding_module/widgets/ad_slot.dart](lib/features/onboarding_module/widgets/ad_slot.dart) — a themed shimmer placeholder until `future()` resolves, then it either renders the ad or collapses if the slot is disabled / failed.

```dart
class AdSlot extends StatefulWidget {
  const AdSlot({
    super.key,
    this.ad,
    this.height,
    this.safeAreaTop,
    this.safeAreaBottom,
  });

  final InlineAdManager? ad;
  final double? height;
  final bool? safeAreaTop;
  final bool? safeAreaBottom;

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
    if (ad.adData.enabled == false) return const SizedBox.shrink();
    if (ad.isFailed) return const SizedBox.shrink();

    final placeholderHeight = widget.ad?.adData.height ?? AppSize.h120;

    if (!ad.isLoaded) {
      return _ShimmerPlaceholder(
        height: placeholderHeight,
        safeAreaTop: widget.safeAreaTop ?? false,
        safeAreaBottom: widget.safeAreaBottom ?? true,
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: AppSize.h10),
      child: SafeArea(
        top: widget.safeAreaTop ?? false,
        bottom: widget.safeAreaBottom ?? true,
        child: ad.adWidget(),
      ),
    );
  }
}
```

### How to use it in any screen

```dart
class _MyScreenState extends State<MyScreen> {
  late final InlineAdManager _ad;

  @override
  void initState() {
    super.initState();
    _ad = InlineAdManager(
      adData: RemoteConfigService.instance.appNative,
      bannerSize: AdSize.banner,
      nativeFactoryId: 'default_native_factory',
    );
    _ad.load();   // AdSlot listens to future() — no need to await here
  }

  @override
  void dispose() {
    _ad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        bottomNavigationBar: AdSlot(ad: _ad),
        body: /* … */,
      );
}
```

**Ownership rule:** whichever `State` builds the `InlineAdManager` is the one that disposes it. If a screen forwards the manager to its next screen via `extra`, the **receiving** screen disposes — see the onboarding hand-off pattern in [ads_onboarding.md](ads_onboarding.md).

---

## 6. Full-screen ads on resume — `OpenAdProvider`

The "show an app-open ad every time the app is resumed from background" pattern lives in [lib/features/provider/open_ad_provider.dart](lib/features/provider/open_ad_provider.dart). It's registered as a top-level provider in `main.dart` and started once after the first frame.

Key behaviors:
1. **First resume after cold start is suppressed** (`ignoreNextEvent = true`) — the splash already handled that slot.
2. The ad is **reloaded after every show** via callbacks on both `openAppCallback` and `interstitialCallback`, so Remote Config can flip the slot type without breaking the cycle.
3. For `AdType.custom`, the URL is launched via `url_launcher` and the next resume is suppressed (since launching the URL backgrounds the app).

```dart
class OpenAdProvider extends ChangeNotifier {
  FullScreenAdManager? _openAdManager;
  AppLifecycleListener? _listener;

  void startOpenAdListener() {
    ignoreNextEvent = true;       // skip the cold-start resume
    _loadOpenAd();
    _startStateListener();
  }

  Future<void> _loadOpenAd() async {
    final data = RemoteConfigService.instance.applicationAppOpen;

    _openAdManager?.dispose();
    _openAdManager = FullScreenAdManager(
      adData: data,
      openAppCallback: FullScreenContentCallback<AppOpenAd>(
        onAdWillDismissFullScreenContent: (_) => _loadOpenAd(),
        onAdFailedToShowFullScreenContent: (_, _) => _loadOpenAd(),
      ),
      interstitialCallback: FullScreenContentCallback<InterstitialAd>(
        onAdWillDismissFullScreenContent: (_) => _loadOpenAd(),
        onAdFailedToShowFullScreenContent: (_, _) => _loadOpenAd(),
      ),
    );
    await _openAdManager?.load();
  }

  Future<void> _startStateListener() async {
    _listener = AppLifecycleListener(
      onResume: () async {
        if (!RemoteConfigService.instance.applicationAppOpen.enabled) return;
        if (ignoreNextEvent) { ignoreNextEvent = false; return; }

        final context = rootNavKey.currentContext;
        if (context == null || !context.mounted) return;

        final data = RemoteConfigService.instance.applicationAppOpen;
        final overlay = LoadingOverlay.instance()..show(context: context);

        try {
          if (data.adType == AdType.custom && data.enabled) {
            ignoreNextEvent = true;
            unawaited(launchUrlString(data.customAdUrl));
            await Future<void>.delayed(const Duration(milliseconds: 500));
            return;
          }

          final ad = _openAdManager;
          if (ad == null) return;
          await ad.future();
          if (ad.isLoaded) await ad.show();
        } finally {
          overlay.hide();
        }
      },
    );
  }

  @override
  void dispose() {
    _openAdManager?.dispose();
    _listener?.dispose();
    super.dispose();
  }
}
```

### Wiring it up

```dart
// main.dart
runApp(MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => OpenAdProvider()),
    // …
  ],
  child: const MyApp(),
));

// after first frame, e.g. in the root widget's initState:
WidgetsBinding.instance.addPostFrameCallback((_) {
  context.read<OpenAdProvider>().startOpenAdListener();
});
```

`ignoreNextEvent` is a top-level mutable flag (lives in `app_router.dart` in this project) — used by both `OpenAdProvider` and `NavigationHelper` to coordinate: when **either** of them backgrounds the app via `launchUrlString`, it sets the flag so the next resume doesn't re-show an app-open ad on top of the user's browser return.

---

## 7. Full-screen ads on navigation — `NavigationHelper`

Show a full-screen ad every N taps of nav buttons (back arrow, bottom-nav, etc.). The threshold comes from Remote Config (`app_click_counter`). Implementation: [lib/utils/navigation_helper.dart](lib/utils/navigation_helper.dart).

Key design choices:
1. **Singleton** — the tap counter is process-wide, not per-screen.
2. **Threshold read every tap** — Remote Config changes apply immediately without rebuilding the singleton.
3. **`enabled == false` → straight-through navigation**, no counting.
4. The `_fullScreenAd` is **rebuilt on every fire** so the latest Remote Config values are used (cheap; the prior instance is disposed).
5. For `AdType.custom`, the URL is launched in `LaunchMode.inAppBrowserView` so the app stays foregrounded; we set `ignoreNextEvent = true` to keep the app-open ad from also firing on return.
6. **`onNavigate` always runs in the `finally`** — even on errors — so the user is never stranded.

```dart
class NavigationHelper {
  static final NavigationHelper _instance = NavigationHelper._internal();
  factory NavigationHelper() => _instance;
  NavigationHelper._internal();

  int _tapCount = 0;
  int get _tapThreshold => RemoteConfigService.instance.appClickCounter;

  FullScreenAdManager? _fullScreenAd;

  void handleBackPress(BuildContext context) =>
      navigateWithAdCheck(context, () => context.pop());

  void addBackTap(BuildContext context) =>
      navigateWithAdCheck(context, () {});

  void navigateWithAdCheck(BuildContext context, VoidCallback onNavigate) {
    if (_fullScreenAd?.adData.enabled == false) { onNavigate(); return; }

    _tapCount++;
    if (_tapCount >= _tapThreshold) {
      _tapCount = 0;
      _handleAdSequence(context, onNavigate);
    } else {
      onNavigate();
    }
  }

  Future<void> _handleAdSequence(BuildContext context, VoidCallback onNavigate) async {
    final overlayContext = context.mounted ? context : rootNavKey.currentContext;
    if (overlayContext == null) { onNavigate(); return; }

    final data = RemoteConfigService.instance.appInter;
    final overlay = LoadingOverlay.instance();
    bool overlayShown = false;

    try {
      if (data.adType == AdType.custom) {
        ignoreNextEvent = true;
        unawaited(launchUrlString(data.customAdUrl,
            mode: LaunchMode.inAppBrowserView));
        await Future<void>.delayed(const Duration(milliseconds: 800));
        return;
      }

      if (data.enabled) {
        ignoreNextEvent = true;
        overlay.show(context: overlayContext);
        overlayShown = true;

        _fullScreenAd?.dispose();
        _fullScreenAd = FullScreenAdManager(
          adData: data,
          interstitialCallback: FullScreenContentCallback<InterstitialAd>(
            onAdShowedFullScreenContent:    (_) => 'Ad Shown'.logI,
            onAdDismissedFullScreenContent: (_) => 'Ad Dismissed'.logI,
            onAdFailedToShowFullScreenContent: (_, _) => 'Ad Failed Show'.logI,
          ),
          openAppCallback: FullScreenContentCallback<AppOpenAd>(
            onAdShowedFullScreenContent:    (_) => 'Ad Shown'.logI,
            onAdDismissedFullScreenContent: (_) => 'Ad Dismissed'.logI,
            onAdFailedToShowFullScreenContent: (_, _) => 'Ad Failed Show'.logI,
          ),
        );

        await _fullScreenAd!.load();
        await _fullScreenAd!.future();
        if (_fullScreenAd!.isLoaded) await _fullScreenAd!.show();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    } catch (e) {
      debugPrint('Ad Logic Exception: $e');
    } finally {
      if (overlayShown) overlay.hide();
      onNavigate();   // always navigate, even on failure
    }
  }

  void resetCounter() { _tapCount = 0; }
}
```

### How to use it

Replace direct navigation calls in your buttons:

```dart
// Before
IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back));

// After
IconButton(
  onPressed: () => NavigationHelper().handleBackPress(context),
  icon: const Icon(Icons.arrow_back),
);
```

For a "tap counter only, no navigation" (e.g. a button that just opens a dialog), use `addBackTap(context)` before opening the dialog.

---

## 8. Rewarded ads — `RewardAdHelper`

For reward-zone style flows (Spin / Scratch / Daily / Booster), the project wraps the standard reward-ad lifecycle in [lib/utils/reward_ad_helper.dart](lib/utils/reward_ad_helper.dart). The shape is the same every time:

```dart
final ad = FullScreenAdManager(
  adData: RemoteConfigService.instance.spinReward,
  rewardedCallback: FullScreenContentCallback<RewardedAd>(
    onAdDismissedFullScreenContent: (_) => onDismissed(),
    onAdFailedToShowFullScreenContent: (_, _) => onFailed(),
  ),
);

await ad.load();
await ad.future();

if (ad.isLoaded) {
  await ad.show(
    context: context,
    onUserEarnedReward: (ad, reward) {
      // grant the reward here
    },
  );
}

ad.dispose();
```

Notes:
- The consent dialog (the "Watch a short ad to earn your reward" prompt) is **built into the package**. Override it once at startup with `RewardedConsent.setConsentDialogBuilder` if you want your own design.
- `FullScreenAdManager.show()` returns `false` if the user declined consent, the ad wasn't ready, etc. For granular reasons (`consentDeclined` vs. `notReady` vs. `failed`), use `RewardedAdManager.show()` directly — but for 95% of call sites the wrapper is enough.

---

## 9. Custom (image / URL) ads

Set `adType: "custom"` on any slot to ship a creative without going through AdMob. Both inline and full-screen managers handle it transparently — no branching needed at the call site.

| Field | Inline (banner/native slot) | Full-screen |
|---|---|---|
| `custom_ad_view_url` | Image URL rendered in place of the ad | unused |
| `custom_ad_url` | Tap target | URL opened on `show()` via `url_launcher` |
| `height` | Pixel height of the image | unused |

Flip an inline `banner` slot to `custom` mid-campaign:

```json
"app_native": {
  "ad_id": "",
  "enabled": true,
  "ad_type": "custom",
  "height": 100,
  "custom_ad_view_url": "https://cdn.example.com/promo.png",
  "custom_ad_url": "https://example.com/promo"
}
```

No app release needed.

---

## 10. Migration checklist — old → new

For each ad call site in the old codebase, follow this in order. Stop at any step that doesn't apply.

1. **Remove direct GMA usage.** Delete every `import 'package:google_mobile_ads/google_mobile_ads.dart'` and replace with `import 'package:ad_manager/ad_manager.dart'` — `ad_manager` re-exports everything you need.
2. **Pull all ad IDs out of code.** For each hard-coded `'ca-app-pub-…/…'` string, add a slot entry to the Remote Config `android` JSON and a typed getter in `RemoteConfigService`.
3. **Replace inline ads with `InlineAdManager`.**
   - Old: `BannerAd(adUnitId: ..., size: ..., listener: ...)` / `NativeAd(...)`
   - New: `InlineAdManager(adData: rc.someBanner, bannerSize: AdSize.banner, nativeFactoryId: 'default_native_factory')`
   - In the widget tree, wrap with `AdSlot(ad: _ad)` instead of conditional shimmer/`SizedBox` glue.
4. **Replace full-screen ads with `FullScreenAdManager`.**
   - Old: `InterstitialAd.load(...)` + global completer / `AppOpenAd.load(...)` + `AppStateEventNotifier` / `RewardedAd.load(...)` + manual reward listener.
   - New: a single `FullScreenAdManager(adData: rc.someFullScreen, interstitialCallback: ..., openAppCallback: ..., rewardedCallback: ...)`. Wire callbacks for **every** ad type that the slot might flip to — `FullScreenAdManager` picks the right one based on `adData.adType`.
5. **Migrate app-open-on-resume to `OpenAdProvider`** ([section 6](#6-full-screen-ads-on-resume--openadprovider)). Delete the old `AppStateEventNotifier`-based listener.
6. **Migrate "ad every N taps" to `NavigationHelper`** ([section 7](#7-full-screen-ads-on-navigation--navigationhelper)). Delete any `if (--counter == 0) { showAd(); }` blocks scattered through screens.
7. **Reload after dismiss.** If the old code didn't reload its interstitials after a show, the new pattern does — every full-screen callback wires `onAdWillDismissFullScreenContent` (or equivalent) to `_load…()`. Don't skip this; otherwise the **second** tap of a nav button hits a disposed ad.
8. **Lifecycle.** `load()` → `await future()` → `show()` / `adWidget()` → `dispose()`. The old pattern of "fire and forget" doesn't apply — `future()` is the load-completed signal you wait on before showing.
9. **Audit `dispose()`.** Every State that builds an `InlineAdManager` or `FullScreenAdManager` must dispose it. The ad-manager package leaks platform views if you skip this; the symptom is "AdWidget already has a parent".
10. **Toggle test mode.** During development, set all `ad_id`s to Google's test units (see [ad_manager/README.md](ad_manager/README.md#json-format)). Swap to your live IDs in Remote Config — **no release needed**.

---

## 11. Gotchas & debug checklist

When ads don't show, walk this in order:

1. **Is Remote Config loading?** Look for `✅ Remote config loaded successfully` from `RemoteConfigService.init()`. If you see `⚠️ android key is empty in Remote Config` or `⚠️ Remote config fetch failed`, every downstream slot is disabled — fix Firebase / network first.
2. **Per-slot logs.** Every load logs `id=… enabled=… type=…` and the eventual `loaded` / `FAILED` / `disabled` / `idle`. If `enabled=false` appears on every slot, Remote Config is empty and you're seeing `_emptyAd()` defaults.
3. **`ad_type` spelling.** `interstatial`, not `interstitial`. Any other spelling falls back to `AdType.native` → `FullScreenAdManager` silently creates no manager → nothing shows.
4. **Missing `ad_type` field.** Defaults to `"native"`. Silently wrong for banner / interstitial / app-open / rewarded slots — always set it explicitly.
5. **Native factory.** If any native slot logs a missing-factory error, you forgot to register `"default_native_factory"` on the platform side.
6. **"no fill" + 403 with test IDs.** Platform-level, not code:
   - Device system date/time correct.
   - Emulator uses a Play Store image (not "Google APIs" only).
   - No VPN.
   - Wipe emulator data if previously spammed as a test device.
7. **Banner shows shimmer forever.** Drive `setState` from `future()`, not `load().then()` — `BannerAd.load()` resolves before the actual load completes. `AdSlot` already does this correctly.
8. **Interstitial "loads but doesn't show" / shows for a frame.** You're navigating immediately after `show()`. Wait for the dismiss callback (e.g. via a `Completer<void>`) before navigating. `NavigationHelper` handles this by running `onNavigate` in the `finally` block after the show-and-wait sequence.
9. **"AdWidget already has a parent."** The wrapper is a reference — decide who owns disposal. For hand-offs via `extra`, the receiving screen disposes.
10. **`context` across async gaps.** Guard every navigation after `await` with `if (!context.mounted) return;`.
11. **`ignoreNextEvent` desync.** Whenever you `launchUrlString` (custom ads, in-app browser), set `ignoreNextEvent = true` before launching. Otherwise the user returns to your app and gets an app-open ad on top of the page they just opened — confusing UX.
12. **Ad reloads.** Every full-screen manager must wire `onAdWillDismissFullScreenContent` / `onAdFailedToShowFullScreenContent` to a `_loadOpenAd()` (or equivalent) so the *next* show has a fresh ad ready. Without this, only the first show works.

### Reference files in this repo

- [lib/utils/remote_config.dart](lib/utils/remote_config.dart) — Remote Config service
- [lib/features/onboarding_module/widgets/ad_slot.dart](lib/features/onboarding_module/widgets/ad_slot.dart) — inline shimmer wrapper
- [lib/features/provider/open_ad_provider.dart](lib/features/provider/open_ad_provider.dart) — app-open on resume
- [lib/utils/navigation_helper.dart](lib/utils/navigation_helper.dart) — interstitial every N taps
- [lib/utils/reward_ad_helper.dart](lib/utils/reward_ad_helper.dart) — rewarded-ad helper with pre-roll sheet
- [lib/main.dart](lib/main.dart) — boot sequence
- [ad_manager/README.md](ad_manager/README.md) — full package spec (authoritative)
- [ads_onboarding.md](ads_onboarding.md) — splash + onboarding preload pattern

That's the whole migration.
