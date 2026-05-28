# ad_manager

A Flutter package for managing Google Mobile Ads with built-in Firebase Analytics, ad revenue tracking, remote-config-driven ad switching, and a consent flow for rewarded ads.

---

## Table of contents

- [Features](#features)
- [Installation](#installation)
- [Platform setup](#platform-setup)
- [Core concepts](#core-concepts)
- [AdData model](#addata-model)
- [Inline ads](#inline-ads)
  - [BannerAdManager](#banneradmanager)
  - [NativeAdManager](#nativeadmanager)
  - [InlineAdManager — switchable inline wrapper](#inlineadmanager--switchable-inline-wrapper)
- [Full-screen ads](#full-screen-ads)
  - [InterstitialAdManager](#interstitialadmanager)
  - [OpenAppAdManager](#openappadmanager)
  - [RewardedAdManager](#rewardedadmanager)
  - [FullScreenAdManager — switchable full-screen wrapper](#fullscreenadmanager--switchable-full-screen-wrapper)
- [Rewarded consent dialog](#rewarded-consent-dialog)
- [Custom ads (no AdMob required)](#custom-ads-no-admob-required)
- [Remote Config integration](#remote-config-integration)
  - [JSON format](#json-format)
  - [Switching ad types at runtime](#switching-ad-types-at-runtime)
- [AdStatus reference](#adstatus-reference)
- [RewardedShowResult reference](#rewardedshowresult-reference)
- [Firebase Analytics events](#firebase-analytics-events)
- [Mediation adapters](#mediation-adapters)

---

## Features

- **5 ad types** — banner, native, interstitial, app open, rewarded
- **2 composable wrappers** — `InlineAdManager` and `FullScreenAdManager` let you switch ad types with zero code changes
- **Remote-config-driven** — swap ad types, IDs, and enable/disable ads without a release
- **Custom ads** — image + URL fallback for any slot; no AdMob account required
- **Rewarded consent** — built-in opt-in dialog with a custom dialog hook
- **Analytics** — lifecycle events and ad revenue forwarded to Firebase automatically
- **Mediation** — Unity, AppLovin, Meta, IronSource, InMobi, and Pangle adapters bundled

---

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  ad_manager:
    path: ../ad_manager   # or your pub.dev / git reference
```

Initialize the Google Mobile Ads SDK once, before any ad is loaded — typically in `main.dart`:

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const MyApp());
}
```

---

## Platform setup

### Android

Add your AdMob App ID to `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"/>
```

### iOS

Add your AdMob App ID to `ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
```

### Native ad factory (required for NativeAdManager)

Native ads require a platform-side factory registered under the id `"default_native_factory"` (or a custom id you pass via `nativeFactoryId`). Follow the [google_mobile_ads native ads guide](https://pub.dev/packages/google_mobile_ads) to create the factory on Android and iOS, then register it in your `MainActivity` / `AppDelegate` before `runApp`.

---

## Core concepts

Every manager follows the same three-step lifecycle:

```
load() → await future() → show() / adWidget()
```

| Step | What it does |
|---|---|
| `load()` | Requests the ad from the network (or marks it ready for custom ads) |
| `future()` | Returns a `Future<AdStatus>` that completes when loading finishes or fails |
| `adWidget()` | Returns the inline widget (banner / native only) |
| `show()` | Presents a full-screen ad (interstitial / rewarded / app open) |
| `reload()` | Disposes the current ad and calls `load()` again |
| `dispose()` | Releases resources — call from `State.dispose()` |

---

## AdData model

`AdData` is the single configuration object that every manager takes.

```dart
AdData({
  required String adId,           // AdMob unit ID  e.g. "ca-app-pub-…/…"
  required bool enabled,          // false → manager returns AdStatus.disabled immediately
  required AdType adType,         // which ad type to render
  TemplateType templateType,      // small | medium  (native ads only)
  double height,                  // explicit height in logical pixels (0 = use ad default)
  String customAdViewUrl,         // image URL shown for custom inline ads
  String customAdUrl,             // landing URL opened for custom ads
})
```

**AdType values**

| Value | Description |
|---|---|
| `AdType.banner` | Standard banner ad |
| `AdType.native` | Native template ad |
| `AdType.interstatial` | Full-screen interstitial |
| `AdType.rewarded` | Full-screen rewarded |
| `AdType.openApp` | App open ad |
| `AdType.custom` | Custom image / URL ad — no AdMob needed |

---

## Inline ads

Inline ads render as widgets inside your layout.

### BannerAdManager

```dart
final manager = BannerAdManager(
  adData: AdData(
    adId: 'ca-app-pub-xxx/yyy',
    enabled: true,
    adType: AdType.banner,
  ),
  size: AdSize.banner,   // any AdSize — default is 320×50
);

await manager.load();
await manager.future();  // wait for loaded or failed

// In your widget tree:
manager.adWidget()   // shows shimmer while loading, collapses on failure
```

While loading `adWidget()` renders a shimmer placeholder. On failure it returns `SizedBox.shrink()`.

### NativeAdManager

```dart
final manager = NativeAdManager(
  adData: AdData(
    adId: 'ca-app-pub-xxx/yyy',
    enabled: true,
    adType: AdType.native,
    templateType: TemplateType.medium,  // or TemplateType.small
    height: 320,                        // optional explicit height
  ),
  factoryId: 'default_native_factory',  // matches platform registration
);

await manager.load();
await manager.future();

manager.adWidget()
```

### InlineAdManager — switchable inline wrapper

`InlineAdManager` is the recommended class for inline placements. It routes to `BannerAdManager` or `NativeAdManager` based on `adData.adType`, so changing the type in Remote Config requires no code change.

**Switchable ad types for inline slots:**

| `adData.adType` | Renders as |
|---|---|
| `AdType.banner` | BannerAdManager |
| `AdType.native` | NativeAdManager |
| `AdType.custom` | Image loaded from `customAdViewUrl`, tapping opens `customAdUrl` |

```dart
class _MyWidgetState extends State<MyWidget> {
  late InlineAdManager _ad;

  @override
  void initState() {
    super.initState();
    _ad = InlineAdManager(
      adData: remoteConfig.banner,   // AdType can be banner, native, or custom
      bannerSize: AdSize.banner,
      nativeFactoryId: 'default_native_factory',
    );
    _loadAd();
  }

  Future<void> _loadAd() async {
    await _ad.load();
    final status = await _ad.future();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ad.isLoaded ? _ad.adWidget() : const SizedBox.shrink();
  }
}
```

---

## Full-screen ads

Full-screen ads are shown on demand and do not embed a widget.

### InterstitialAdManager

```dart
final manager = InterstitialAdManager(
  adData: AdData(
    adId: 'ca-app-pub-xxx/yyy',
    enabled: true,
    adType: AdType.interstatial,
  ),
);

await manager.load();
await manager.future();

final shown = await manager.show();   // returns bool
```

The interstitial disposes itself automatically after it is dismissed.

### OpenAppAdManager

```dart
final manager = OpenAppAdManager(
  adData: AdData(
    adId: 'ca-app-pub-xxx/yyy',
    enabled: true,
    adType: AdType.openApp,
  ),
);

await manager.load();
await manager.future();

await manager.show();
```

`show()` is a no-op if the ad is already on screen.

### RewardedAdManager

The rewarded manager requires a `BuildContext` on `show()` because a consent dialog is shown before the ad (see [Rewarded consent dialog](#rewarded-consent-dialog)).

```dart
final manager = RewardedAdManager(
  adData: AdData(
    adId: 'ca-app-pub-xxx/yyy',
    enabled: true,
    adType: AdType.rewarded,
  ),
);

await manager.load();
await manager.future();

final result = await manager.show(
  context: context,
  onUserEarnedReward: (ad, reward) {
    print('Earned ${reward.amount.toInt()} ${reward.type}');
  },
);
```

`show()` returns a `RewardedShowResult` — see the [reference table](#rewardedshowresult-reference).

### FullScreenAdManager — switchable full-screen wrapper

`FullScreenAdManager` is the recommended class for full-screen placements. It routes to the right underlying manager based on `adData.adType`, so you can switch between interstitial, rewarded, and app open ads from Remote Config with no code changes.

**Switchable ad types for full-screen slots:**

| `adData.adType` | Routes to |
|---|---|
| `AdType.interstatial` | InterstitialAdManager |
| `AdType.rewarded` | RewardedAdManager (consent dialog included) |
| `AdType.openApp` | OpenAppAdManager |
| `AdType.custom` | InterstitialAdManager (opens `customAdUrl` via url_launcher) |

```dart
final manager = FullScreenAdManager(adData: remoteConfig.interstitial);

await manager.load();
await manager.future();

// For interstitial / app open — context and onUserEarnedReward are optional:
await manager.show();

// For rewarded — both parameters are required:
final shown = await manager.show(
  context: context,
  onUserEarnedReward: (ad, reward) {
    // grant the reward
  },
);
// shown == false if user declined consent, ad wasn't ready, etc.
// For granular reason, use RewardedAdManager.show() directly.
```

---

## Rewarded consent dialog

Before a rewarded ad is shown the manager requests the user's consent. If the user declines, the ad is not shown and `show()` returns `RewardedShowResult.consentDeclined`.

### Default dialog

When no custom builder is set, a built-in `AlertDialog` is shown:

> **Watch a Rewarded Ad?**
> Watch a short ad to earn your reward. This helps keep the app free for everyone.
> \[No Thanks\] \[Opt In\]

### Custom consent dialog

Register your own dialog once at startup, before any ad is loaded:

```dart
// main.dart
RewardedConsent.setConsentDialogBuilder((BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('Earn your reward'),
      content: const Text('Watch a short ad to unlock premium content.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Watch'),
        ),
      ],
    ),
  ) ?? false;
});
```

The builder receives a `BuildContext` and must return `Future<bool>` — `true` to allow the ad, `false` to cancel.

### Handling the result

```dart
final result = await rewardedAdManager.show(
  context: context,
  onUserEarnedReward: (ad, reward) { /* grant reward */ },
);

switch (result) {
  case RewardedShowResult.success:
    // ad played, reward already delivered via onUserEarnedReward
  case RewardedShowResult.consentDeclined:
    // user tapped "No Thanks" — do not penalise them
  case RewardedShowResult.notReady:
    // ad not loaded yet — try again later
  case RewardedShowResult.disabled:
    // unit disabled via Remote Config
  case RewardedShowResult.failed:
    // SDK error during show
}
```

---

## Custom ads (no AdMob required)

Set `adType: AdType.custom` on any `AdData` to use your own creative instead of an AdMob ad. No AdMob unit ID is needed.

| Field | Used by |
|---|---|
| `customAdViewUrl` | URL of the image rendered in inline slots (banner / native position) |
| `customAdUrl` | URL opened when the user taps inline ads or when a full-screen custom ad is shown |
| `height` | Explicit pixel height of the inline image |

```dart
// Inline custom ad
AdData(
  adId: '',
  enabled: true,
  adType: AdType.custom,
  customAdViewUrl: 'https://example.com/promo.png',
  customAdUrl: 'https://example.com/promo',
  height: 100,
)

// Full-screen custom ad (opens URL instead of showing a video)
AdData(
  adId: '',
  enabled: true,
  adType: AdType.custom,
  customAdUrl: 'https://example.com/promo',
)
```

Custom ads go through the same `load()` / `show()` / `adWidget()` API — no branching required in your code.

---

## Remote Config integration

### JSON format

In Firebase Remote Config, create two parameters: `android` and `ios`. Each parameter's value is a **JSON string** (not a nested object) containing all ad configurations for that platform.

```json
{
  "click_counter": 4,

  "banner": {
    "ad_id": "ca-app-pub-3940256099942544/6300978111",
    "enabled": true,
    "ad_type": "banner",
    "height": 0
  },

  "native_small": {
    "ad_id": "ca-app-pub-3940256099942544/2247696110",
    "enabled": true,
    "ad_type": "native",
    "template_type": "small",
    "height": 120
  },

  "native_medium": {
    "ad_id": "ca-app-pub-3940256099942544/2247696110",
    "enabled": true,
    "ad_type": "native",
    "template_type": "medium",
    "height": 320
  },

  "custom_inline": {
    "ad_id": "",
    "enabled": true,
    "ad_type": "custom",
    "height": 100,
    "custom_ad_view_url": "https://example.com/promo.png",
    "custom_ad_url": "https://example.com"
  },

  "interstitial": {
    "ad_id": "ca-app-pub-3940256099942544/1033173712",
    "enabled": true,
    "ad_type": "interstatial"
  },

  "rewarded": {
    "ad_id": "ca-app-pub-3940256099942544/5224354917",
    "enabled": true,
    "ad_type": "rewarded"
  },

  "app_open": {
    "ad_id": "ca-app-pub-3940256099942544/9257395921",
    "enabled": true,
    "ad_type": "openApp"
  },

  "custom_fullscreen": {
    "ad_id": "",
    "enabled": true,
    "ad_type": "custom",
    "custom_ad_url": "https://example.com"
  }
}
```

> The IDs above are Google's official test unit IDs. Replace them with your live IDs before release.

**Field reference**

| Field | Type | Required | Description |
|---|---|---|---|
| `ad_id` | string | yes | AdMob unit ID. Empty string for `custom` type. |
| `enabled` | bool | yes | `false` disables the slot without removing the config. |
| `ad_type` | string | yes | `banner` · `native` · `interstatial` · `rewarded` · `openApp` · `custom` |
| `template_type` | string | native only | `small` or `medium` |
| `height` | number | no | Explicit height in logical pixels. `0` uses the ad's intrinsic height. |
| `custom_ad_view_url` | string | custom inline | Image URL for the inline creative. |
| `custom_ad_url` | string | custom | Landing URL opened on tap (inline) or on show (full-screen). |
| `click_counter` | number | no | App-level threshold for frequency capping logic (read via `RemoteConfigService.instance.clickCounter`). |

### Reading config in code

```dart
class RemoteConfigService {
  static final RemoteConfigService instance = RemoteConfigService._();
  RemoteConfigService._();

  final _rc = FirebaseRemoteConfig.instance;
  Map<String, dynamic> _data = {};

  Future<void> init() async {
    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(seconds: 10),
    ));
    await _rc.fetchAndActivate();
    final raw = _rc.getString(Platform.isAndroid ? 'android' : 'ios');
    _data = raw.isEmpty ? {} : jsonDecode(raw) as Map<String, dynamic>;
  }

  AdData _ad(String key) =>
      AdData.fromJson(Map<String, dynamic>.from(_data[key] as Map));

  AdData get banner           => _ad('banner');
  AdData get nativeSmall      => _ad('native_small');
  AdData get nativeMedium     => _ad('native_medium');
  AdData get customInline     => _ad('custom_inline');
  AdData get interstitial     => _ad('interstitial');
  AdData get rewarded         => _ad('rewarded');
  AdData get appOpen          => _ad('app_open');
  AdData get customFullscreen => _ad('custom_fullscreen');
  int    get clickCounter     => (_data['click_counter'] ?? 4) as int;
}
```

Call `RemoteConfigService.instance.init()` before `runApp`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await RemoteConfigService.instance.init();
  await MobileAds.instance.initialize();
  runApp(const MyApp());
}
```

### Switching ad types at runtime

The type switch is entirely driven by the `ad_type` field in Remote Config. Update the value in the Firebase console — no release needed.

**Inline slots** (`InlineAdManager`):

```
banner  ↔  native  ↔  custom
```

**Full-screen slots** (`FullScreenAdManager`):

```
interstatial  ↔  rewarded  ↔  openApp  ↔  custom
```

Example — turn the interstitial slot into a rewarded ad:

```json
"interstitial": {
  "ad_id": "ca-app-pub-xxx/your_rewarded_unit_id",
  "enabled": true,
  "ad_type": "rewarded"
}
```

Because your code already uses `FullScreenAdManager`, it automatically creates a `RewardedAdManager` internally. Pass `context` and `onUserEarnedReward` in `show()` so you're ready regardless of which type Remote Config picks.

To disable a slot entirely without removing its entry:

```json
"banner": {
  "ad_id": "ca-app-pub-xxx/yyy",
  "enabled": false,
  "ad_type": "banner"
}
```

The manager resolves to `AdStatus.disabled` on `load()` and renders nothing / returns `false` from `show()`.

---

## AdStatus reference

| Value | Meaning |
|---|---|
| `AdStatus.idle` | Not yet loaded |
| `AdStatus.loading` | Load in progress |
| `AdStatus.loaded` | Ready to show / render |
| `AdStatus.failed` | Load or show failed |
| `AdStatus.disabled` | `AdData.enabled` is `false` |

---

## RewardedShowResult reference

Returned only by `RewardedAdManager.show()`. `FullScreenAdManager.show()` maps this to a plain `bool`.

| Value | Meaning |
|---|---|
| `RewardedShowResult.success` | Ad was shown; reward delivered via `onUserEarnedReward` |
| `RewardedShowResult.consentDeclined` | User tapped "No Thanks" in the consent dialog |
| `RewardedShowResult.notReady` | Ad not loaded or already disposed |
| `RewardedShowResult.disabled` | Unit disabled via `AdData.enabled` |
| `RewardedShowResult.failed` | SDK threw an error during `show()` |

---

## Firebase Analytics events

The package logs the following events automatically in release mode.

| Event | Triggered by |
|---|---|
| `banner_ad_opened` | Banner clicked / opened |
| `banner_ad_close` | Banner dismissed |
| `banner_ad_impression` | Banner impression |
| `banner_ad_click` | Banner click |
| `native_ad_opened` | Native ad opened |
| `native_ad_closed` | Native ad dismissed |
| `native_ad_impression` | Native impression |
| `native_ad_click` | Native click |
| `native_fail_to_load` | Native load failure (includes error message) |
| `interstitial_ad_opened` | Interstitial shown |
| `interstitial_ad_closed` | Interstitial dismissed |
| `interstitial_ad_impression` | Interstitial impression |
| `interstitial_ad_click` | Interstitial click |
| `interstitial_ad_show_failed` | Interstitial show error |
| `rewarded_ad_opened` | Rewarded ad shown |
| `rewarded_ad_closed` | Rewarded ad dismissed |
| `rewarded_ad_impression` | Rewarded impression |
| `rewarded_ad_click` | Rewarded click |
| `rewarded_ad_show_failed` | Rewarded show error |
| `open_app_ad_opened` | App open ad shown |
| `open_app_ad_closed` | App open dismissed |
| `open_app_ad_impression` | App open impression |
| `open_app_ad_click` | App open click |
| `open_app_ad_failed_to_show` | App open show error |
| `ad_impression` | Paid impression revenue (all ad types — includes value, currency, precision) |

---

## Mediation adapters

The following adapters are bundled as dependencies. Configure mediation groups in the AdMob dashboard — no extra unit IDs are required in your Flutter code.

| Adapter | Package |
|---|---|
| Unity Ads | `gma_mediation_unity` |
| AppLovin | `gma_mediation_applovin` |
| Meta Audience Network | `gma_mediation_meta` |
| IronSource | `gma_mediation_ironsource` |
| InMobi | `gma_mediation_inmobi` |
| Pangle | `gma_mediation_pangle` |

Remove any adapter you don't use to keep the binary size down.
