# PlayHub

A Flutter (Material 3) Android app for browsing and playing HTML5 games from a bundled catalog: search, categories, favorites, recently played, autoplaying gameplay previews, a full-screen WebView player and AdMob monetization.

## Folder tree

```
playhub/
├── pubspec.yaml
├── analysis_options.yaml
├── assets/
│   └── games.json                     (replace with your full catalog)
├── android_overrides/                 (copy over the generated android/ folder)
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       └── res/drawable(-v21)/launch_background.xml
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── config/
│   │   ├── app_config.dart            (name, page size, privacy URL, age)
│   │   └── ad_config.dart             (every AdMob ID in one place)
│   ├── data/
│   │   ├── catalog_parser.dart        (runs in a background isolate)
│   │   ├── catalog_repository.dart
│   │   └── video_url_resolver.dart    (resolveVideoUrl + base URL TODO)
│   ├── models/
│   │   ├── game.dart
│   │   ├── catalog.dart
│   │   └── app_settings.dart
│   ├── providers/
│   │   ├── core_providers.dart
│   │   ├── catalog_providers.dart
│   │   ├── library_providers.dart     (favorites, recently played)
│   │   ├── settings_provider.dart
│   │   ├── network_provider.dart
│   │   ├── navigation_provider.dart
│   │   └── preview_video_provider.dart
│   ├── services/
│   │   ├── preview_video_manager.dart (max 2 video controllers)
│   │   ├── ad_service.dart            (consent, banners, interstitial cooldown)
│   │   └── game_navigation.dart       (open detail, play game)
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── shell_screen.dart
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   ├── featured_carousel.dart
│   │   │   └── continue_playing_row.dart
│   │   ├── categories_screen.dart
│   │   ├── category_games_screen.dart
│   │   ├── game_detail_screen.dart
│   │   ├── player_screen.dart
│   │   ├── favorites_screen.dart
│   │   └── settings_screen.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   ├── utils/
│   │   ├── genre_style.dart
│   │   └── text_utils.dart
│   └── widgets/
│       ├── app_logo.dart
│       ├── banner_ad_slot.dart
│       ├── chips.dart
│       ├── common.dart                (section header, empty state, offline banner)
│       ├── content_notice.dart
│       ├── favorite_heart.dart
│       ├── floating_nav_bar.dart
│       ├── game_card.dart
│       ├── game_image.dart
│       ├── game_mini_tile.dart
│       ├── glass_container.dart
│       ├── gradient_background.dart
│       ├── gradient_button.dart
│       ├── paged_game_grid.dart
│       ├── preview_media.dart
│       └── shimmer_box.dart
└── test/
    └── catalog_parser_test.dart
```

## Setup

1. **Create the Android shell.** From inside the `playhub` folder (the one with `pubspec.yaml`):

   ```bash
   flutter create --org com.yourcompany --project-name playhub --platforms android .
   ```

   This adds the `android/` folder and leaves `lib/`, `pubspec.yaml` and `assets/` untouched. Choose your real organization ID here, since it becomes the Play Store package name (`com.yourcompany.playhub`).

2. **Apply the Android overrides.**

   ```bash
   cp -r android_overrides/app/src/main/* android/app/src/main/
   ```

   Then open `android/app/build.gradle.kts` (or `build.gradle`) and set, inside `defaultConfig`:

   ```kotlin
   minSdk = 23
   ```

   The manifest adds `INTERNET`, `ACCESS_NETWORK_STATE` and `WAKE_LOCK`, turns cleartext traffic off, keeps orientation changes inside the activity (so the player can switch to landscape without restarting it), declares the AdMob app ID and adds the `queries` entries `url_launcher` needs on Android 11+.

3. **Add the catalog.** Replace `assets/games.json` with your full file (same `{ "segments": [ { "hits": [...] } ] }` structure). The app keeps only games whose `mobileReady` contains `For Android` and that have a `gameURL`. Nothing in the app edits `gameURL`; it is loaded in the WebView exactly as stored, so your `clid` stays intact.

4. **Run.**

   ```bash
   flutter pub get
   flutter test
   flutter run
   ```

5. **Turn on gameplay previews.** The catalog only has `videos[].playgama_id`, so open `lib/data/video_url_resolver.dart` and set `kPreviewVideoUrlPattern` to the real clip URL pattern, using `{id}` where the id goes. Until then, any clip whose `external_url` is a direct https `.mp4`/`.webm` still plays, and every other card shows its image.

## Replace the AdMob IDs

All IDs are Google's official test IDs today.

1. `lib/config/ad_config.dart`: set `homeBannerId`, `detailBannerId`, `interstitialId` and `androidAppId`.
2. `android/app/src/main/AndroidManifest.xml`: set the `com.google.android.gms.ads.APPLICATION_ID` value to the same app ID.
3. In AdMob, create a GDPR consent message under Privacy & messaging. The app already runs Google's consent flow (UMP) before it requests ads, and shows an "Ad privacy choices" item in Settings when the user's region requires it.
4. Publish an `app-ads.txt` on your developer website.

Ad placement: a banner above the bottom bar on Home, a banner inside the Game Detail content (kept away from the Play button), and an interstitial after returning from a game, at most once every 3 minutes. The Player screen never shows ads.

## Build the release AAB

1. Create an upload key (once):

   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties`:

   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/absolute/path/to/upload-keystore.jks
   ```

3. Wire it into `android/app/build.gradle.kts` as described in Flutter's "Build and release an Android app" guide (a `signingConfigs { create("release") { ... } }` block, and `signingConfig = signingConfigs.getByName("release")` on the release build type).

4. Build:

   ```bash
   flutter build appbundle --release
   ```

   Output: `build/app/outputs/bundle/release/app-release.aab`.

Before publishing: set `AppConfig.privacyPolicyUrl` to your real privacy policy, replace the launcher icon (for example with `flutter_launcher_icons`), and fill in the Play Console Data safety form (the app uses AdMob, which collects the advertising ID).

## Assumptions

- Riverpod 3 is used for state; only `Provider`, `FutureProvider`, `StreamProvider` and `Notifier` APIs are used, so the code also runs on Riverpod 2.6 if you pin that instead.
- Flutter 3.27 or newer (uses `Color.withValues` and `PopScope.onPopInvokedWithResult`).
- `id` may be a number or a string in the JSON; it is stored as a string and falls back to `slug`.
- If `screenOrientation` is missing, or both flags are false, the game is treated as playable in any orientation.
- The catalog order is treated as a popularity order: Featured takes the first games that have clips, and the genre chips use the 12 most common genres.
- Search matches the game title only, as specified.
- "Pages of 30" is applied to rendering: the whole catalog is parsed once in an isolate, and the grid builds 30 more cards as the user nears the end.
- Card glassmorphism uses translucent fills and borders. Real backdrop blur is used only on the bottom bar, the Home top bar and dialogs, because a blur on every grid card causes scroll jank on mid-range phones.
- A preview plays only when its card is at least 60% visible, after scrolling settles for 300 ms; clips that fail or take longer than 8 seconds fall back to the image for the rest of the session.
- The content notice recommends ages 13 and over (`AppConfig.minimumAge`). If you target children, AdMob and Play Families rules change and the ad setup must be adjusted.
- Links a game opens with a non-web scheme (for example `market://`) are handed to the system; web navigation stays inside the player.
- Poppins is loaded through `google_fonts` at first launch and cached. To work fully offline from the first launch, bundle the font files and set `GoogleFonts.config.allowRuntimeFetching = false`.
- Version number and build come from `pubspec.yaml` (`version: 1.0.0+1`).
#   p l a y h u b  
 