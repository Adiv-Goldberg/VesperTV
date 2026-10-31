# VesperTV — working notes for Claude Code

Read this first in any fresh session. It is the project's memory: what it is, how to build/ship it,
the rules that were learned the hard way, and every bug that has already been fixed (so it doesn't
get re-introduced or re-investigated).

## 1. What this is
Flutter **universal media player** for **Android phones, Android TV boxes (Formuler), Fire
Sticks, and Windows 10/11 PCs**: live IPTV (M3U + Xtream Codes, XMLTV EPG), the **Media Hub**
(user-added REST add-ons + the user's own **Jellyfin / Emby** server) and **Trakt / Simkl** watch
tracking. GPL-3.0, open source, always free, no ads, no tracking, bring-your-own sources (the app
ships no content).

- **Name:** VesperTV (formerly **NoXPlayer**; "NoX TV Player" in some UI text). Renamed in Oct 2026
  because "NoXPlayer" collided with a well-known Android emulator that had a malware scandal.
  "Vesper" = evening star; brand is **black + gold**, logo is a gold "V" with a four-point star.
- **Repo:** https://github.com/NoXqc/VesperTV (renamed from `NoXqc/NoXPlayer`; GitHub auto-redirects
  web/API/git/download URLs from the old name — **never create a new repo called `NoXPlayer`**, it
  would break those redirects for every old install and link).
- **Site:** https://vespertv.app (GitHub Pages from `docs/`, HTTPS enforced). DNS is at Cloudflare,
  4 `A` records (185.199.108-111.153) on the apex + `www` CNAME → `noxqc.github.io`, all
  **DNS only / grey cloud** (an orange proxy cloud breaks Pages' certificate issuance). `docs/CNAME`
  = `vespertv.app`. The old `noxplayertv.com` *marketing site* is gone, but **keep that domain registered** - it is still used by other infrastructure (details are in a private notes file on the owner's PC, outside the repo).
- **Community:** Discord https://discord.gg/VPQ849NPV, Reddit r/VesperTV. **Downloader (AFTVnews) code: `1760256`**.
- **Package / identifiers deliberately NOT renamed** (renaming would orphan every install's data and
  break in-place updates): Android `applicationId` `com.nox.nox_iptv`, Dart package `nox_iptv`,
  Windows exe `VesperTV.exe` (was `nox_iptv.exe` until the post-3.53.1 build; CMake `BINARY_NAME`; `ProductName`/`CompanyName` in Runner.rc stay `nox_iptv`/`com.nox` because they name the user-data folder), signing alias `noxplayer`, SharedPreferences keys, cache names like
  `noxplayer_posters`. Only user-visible strings, icons, URLs and docs were renamed.

**The owner** tests on real devices and sends phone photos/screenshots of the TV. Most bugs only show
up on real boxes (weak CPUs, D-pad remotes, Fire OS quirks) — emulators/tests are not a substitute.
Keep replies short; make routine calls yourself; **confirm before anything destructive or
outward-facing** (deleting releases, force-pushes, posting). Only commit/release when asked.

## 2. Start-here checklist for a clean session
1. `git pull`, then `git status` (ignore the untracked `*-windows-x64.zip` and
   `third_party/video_player_android/pubspec.lock` — local artifacts).
2. Machine facts (Windows PC): repo `C:\Users\aarse\NoXPlayer`; Flutter `C:\src\flutter`; JDK 17;
   Android SDK `C:\Android\Sdk`; apksigner `C:\Android\Sdk\build-tools\36.0.0\apksigner.bat`;
   keystore `C:\Users\aarse\keystores\noxplayer-release.jks` via git-ignored `android\key.properties`
   (originals also on drive `E:\`). Files are CRLF here (autocrlf) — "LF will be replaced by CRLF"
   warnings are normal. `flutter pub get` dirties generated plugin files under linux/macos/windows —
   `git checkout` them before committing.
   **VPS** (NOX-VPS; login + details in the owner's private `C:\Users\aarse\VPS.md`, key auth from
   `~/.ssh/id_ed25519`, works from the Bash tool): runs the pairing relay + transfer vault (`tools/pair_relay/`, `pair.vespertv.app`)
   **and the owner's streams (Tuliprox) behind the same nginx** — back up first, `nginx -t`, then
   `systemctl reload nginx` (never restart). Deploy steps: `tools/pair_relay/README.md`.
3. Use Bash (Git Bash) or PowerShell. In Git Bash, **prefix adb commands that take `/sdcard`-style
   paths with `MSYS_NO_PATHCONV=1`** (it mangles them). Big multi-line heredocs sometimes break the
   Bash tool — write a script file with the Write tool and run that instead.
4. `flutter analyze` must report the baseline **16** info-level issues (no errors). Don't add new ones.
5. Check the current state of releases: `gh release list` (latest should be `1.0.39` unless noted
   in §13).

## 3. Layout (what matters)
- `lib/main.dart` — bootstrap + splash, layout choice (TV vs phone), welcome/add-playlist prompt for
  new users, Windows `window_manager` init, post-splash auto-resume of the last channel.
- `lib/screens/tv_home_screen.dart` — the whole TV UI (tabs, groups, live list, Timeline guide,
  Movies/TV Shows browse + hero, Windows Minimize/Close rows). Huge file, full of load-bearing
  comments. Read them.
- `lib/screens/player_screen.dart` + `lib/widgets/player_controls.dart` — Android/TV fullscreen
  player (primary row, chevron-revealed secondary row, quality/FPS/audio-channel badges).
- `lib/screens/multiview_screen.dart` — Multiview, 2 stacked or 4 (2x2) screens (remembered),
  connection-tip popup with "Don't show again", channel picker with group+search+EPG-now subtitle. Windows has its own `desktop_multiview_screen.dart`.
- `lib/screens/desktop_player_screen.dart`, `lib/services/desktop_mini_player.dart`,
  `lib/widgets/desktop_live_resume_hint.dart` — the **entirely separate Windows playback stack**
  (`media_kit`). Android uses `video_player_hdr` + `PlaybackService`/`PlayerScreen`. Changes to one do
  not affect the other; features must be built twice.
- `lib/services/playlist_manager.dart` / `playlist_session.dart` — per-playlist state, catalog
  loading, hidden groups/channels, backup-server failover. `playback_service.dart`,
  `epg_service.dart` + `epg_database.dart` (guide in sqflite), `catalog_database.dart` (sqflite), `storage_service.dart` (prefs/cache),
  `app_update_service.dart` (GitHub release updater). Transfer to another device:
  `cloud_transfer.dart` (internet, encrypted upload to the relay's vault — the main Send path) +
  `device_transfer.dart` (same Wi-Fi), UI `screens/settings/transfer_screen.dart`. Backup &
  restore: `services/backup_service.dart` + `android/.../BackupStore.kt` (Download/VesperTV via
  MediaStore; Windows Documents\VesperTV), UI `screens/settings/backup_screen.dart`; Transfer and
  Restore share `screens/settings/replace_setup.dart` (clear caches, import, exit).
- `lib/screens/settings/*` — Settings screens (Add Playlist is a 3-pane LokTV-style layout).
- **Media Hub** (code name Archive — files/classes/keys stay `archive_*`): `screens/archive_screen.dart`
  (tab), `archive_detail_screen.dart` / `archive_playback.dart` (play, series via
  `SeriesDetailScreen`), `services/archive_service.dart` (sources, rows, routing per source kind),
  `archive_api_service.dart` (add-on REST schema), `media_server_api.dart` (Jellyfin/Emby),
  `tracker_api.dart` + `tracker_sync.dart` + `watch_tracker.dart` (Trakt/Simkl: rows, read-back,
  scrobbling), `screens/settings/{archive_sources,media_server,trackers}_screen.dart`. Details in
  §10 "REST/JSON Add-on Architecture" and §13.
- Multiview extras: `services/multiview_sports.dart` (picker Live now / Sports),
  `widgets/game_channel_chooser.dart`, `widgets/auto_hide_overlay.dart` (tile name bar).
- `lib/screens/welcome_add_playlist_screen.dart` — first-launch "Hey beautiful Human" prompt.
- `lib/widgets/`: `poster_card`, `hold_to_activate`, `live_resume_hint`, `tv_menu_tile`,
  `mode_button`, `pin_pad`, `sidebar`, `epg_guide`, `roll_down_menu` (the black/gold menu that
  unrolls under a button: Media Hub row hold menu, groups column Playlists menu).
- Palettes: `lib/utils/constants.dart` (`cyberpunkPalettes`, `AppConstants.appName`),
  `lib/models/cyberpunk_palette.dart`, `lib/utils/tv_theme.dart`.
- `third_party/video_player_android` — **vendored, patched** ExoPlayer plugin (see §9).
- `assets/icon/` — logo sources; `gen_icon.py` regenerates all icons + the TV banner (§8).
- `docs/index.html` — the entire marketing site (single file) + `docs/assets/` screenshots (§8).
- `windows/runner/main.cpp`, `Runner.rc` — Windows runner (window title "VesperTV").

## 4. Build / check
- Native Robolectric tests default to compile SDK 36 and need Java 21. Use a temporary
  Gradle -Dorg.gradle.java.home path; do not change signing/build secrets. On release +449,
  the extra native run completed 187 tests: 175 passed, 12 fixture failures across listener/
  texture tests (all with the same unstubbed track return):
  mocked getCurrentTracks() returns null (real ExoPlayer returns Tracks). Owner instructed
  publish/announce; Flutter analyze 17 and all 515 Flutter tests passed. Native suite is NOT green.
- `flutter analyze` — baseline **16** info issues, none errors. `flutter test` — `test/device_transfer_test.dart` (real LAN sockets).
- Android: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk` (~68 MB).
- Windows: **kill the running app first** (`Get-Process VesperTV | Stop-Process -Force`) or the link
  step fails with `LNK1104: cannot open VesperTV.exe`. Then `flutter build windows --release`
  (output `build\windows\x64\runner\Release\VesperTV.exe`) and zip the **whole Release folder** as
  `VesperTV-windows-x64.zip` (the exe needs the DLLs/`data` folder beside it — a bare .exe will
  not run, which is why the site links the zip, not the exe).
- Windows build needs **`nuget`** on PATH since the in-app trailers (flutter_inappwebview_windows
  downloads WebView2 with it; `NUGET-NOTFOUND` = missing). Installed via
  `winget install Microsoft.NuGet` (2026-10-23). Android: the plugin is vendored (§9-style,
  `third_party/flutter_inappwebview_android`, proguard file fix).
- Only run `dart format` on files you edited (`dart format lib` reformats unrelated files).
- Don't launch the Windows exe from an automated PowerShell session to test it — it can show a blank
  white window there (proven unrelated to `window_manager`); the owner launching it normally works.

## 5. Signing (READ BEFORE BUILDING A RELEASE)
- `android/key.properties` + the `.jks` keystore are **git-ignored secrets**. Alias `noxplayer`.
  `storeFile` is an absolute path for that machine (Windows: forward slashes).
- If key.properties is missing/wrong the build **silently signs with the debug key** — that APK
  cannot install over a real install. Always verify:
  `apksigner verify --print-certs app-release.apk` → SHA-256 must be
  `c92a346ac5b6191a373b3572fa0fbd72abdd5f64db497bd321617b8cc4562431`.
- Never commit the keystore/passwords. Losing the key = existing installs can never update.
- Android requires `versionCode` (the `+N` in `pubspec.yaml`) to never go
  down, even if the visible version resets. Always bump N on every build you intend to install.
  (Stable **+422**, 1.0.39; native-surface beta **+425**.)

## 6. Release workflow (details in `dev-notes/release.md` — read it before releasing)
Only release when the owner asks ("update the latest", "cut it", "fully release"). Outline: bump `pubspec.yaml` (versionCode `+N` must always rise) → `flutter analyze` → build APK + verify signature (§5) → build Windows + zip → **commit & push first** → `gh release upload <tag> app-release.apk VesperTV-windows-x64.zip --clobber` → `gh release edit <tag> --tag <new> --notes-file …` → make sure the tag equals HEAD → verify downloads/hashes, the OLD `NoXqc/NoXPlayer` redirect links and AFTVnews code `1760256`. The updater offers any *different* tag (`_isDifferent`), never leave two `.zip`/`.apk` assets on the latest release.

## 7. Test devices (details in `dev-notes/devices.md`)
Formuler Z11 Pro MAX `10.0.0.46:5555` (IP changes; was `192.168.1.46`), Fire Stick 4K Max (AFTKM) `10.0.0.26:5555` (2026-10-27; was `192.168.1.33`, USB `G072JN0733471CJ6`). Install with `adb install -r` after verifying the signature. Not rooted: no run-as on the Formuler, but `adb logcat` works (Flutter `print` shows as tag `flutter` even in release). **Don't drive the owner's Formuler over adb to debug** (owner, 2026-10-15) — add temporary on-screen debug output and ask for a photo, or use the Fire Stick when he hooks it up. Never press Select on "Disable and exit" (was "Exit App": it disables every playlist). Hold-Select via adb needs `input swipe X Y X Y 1800`, not `--longpress`. The owner keeps the Formuler on **Dark / Gold**.

## 8. Branding & website (details in `dev-notes/branding-and-site.md`)
Brand = black + gold, gold "V" + star logo. Regenerate icons with `python assets/icon/gen_icon.py` then `dart run flutter_launcher_icons`. Default Platinum theme accent = gold. Site is the single file `docs/index.html` (carousel, hero sky). Fire OS keeps old launcher icons after updates — known, unfixable in-app.

## 9. Vendored ExoPlayer plugin
`third_party/video_player_android` is a patched copy of `video_player_android` **2.12.2** (matches
what `video_player_hdr ^1.2.0` resolves to), wired in through `dependency_overrides`. Patch adds
`org.jellyfin.media3:media3-ffmpeg-decoder` with `EXTENSION_RENDERER_MODE_ON` (was PREFER until
`dbc88fc` — PREFER software-decoded plain AAC) plus a context-less `AudioSink` (so `setVolume`
works, no HDMI passthrough) in `PlatformViewVideoPlayer.java` **and** `TextureVideoPlayer.java`,
fixing silent **AC3/E-AC3 5.1** audio on boxes without a licensed Dolby decoder. Also patched:
Multiview-only buffer sizes + 4 s stuck-playing detection (`TextureVideoPlayer`), in-place
error/ENDED/frozen-video recovery (`ExoPlayerEventListener`, delayed + frozen-video watchdog only for
texture players), and **`VideoPlayerPlugin.createForTextureView` forces the SurfaceTexture-backed
producer** (`FlutterRenderer.debugForceSurfaceProducerGlTextures`) — the ImageReader producer
ignores the decoder's crop rect, which showed 720p Multiview tiles with a green area on a Fire Stick
(MTK). Only safe while Impeller stays off (Skia/GL). Also added (1.0.18): **`SubtitleBridge.java`**
(MethodChannel `vespertv/subtitles` + EventChannel `vespertv/subtitles/cues`, attached in
`VideoPlayerPlugin.registerPlayerInstance`) — lists/selects embedded text tracks and streams cue text;
every player starts with text tracks disabled. Added in 1.0.24: **live closed captions**
(`HttpVideoAsset.liveCaptionExtractors`: `DefaultExtractorsFactory.setTsSubtitleFormats(CEA-608)`,
so every .ts stream lists a "CC" track, empty when the channel has none; `SubtitleBridge` flags it
`cc`), **decoder fallback** (`setEnableDecoderFallback(true)` in both players), and
`VideoPlayer.dispose` **removes its listener before `release()`**: a 4K release on the Fire
Stick passes ExoPlayer's 500 ms timeout, and the error recovery then re-prepared the released
player on the main thread (an ANR was seen once). **If `video_player_hdr` or its constraint
is ever bumped**, re-sync the vendored copy to the new version and re-apply all of these patches
plus the gradle dependency line. Migrating to `media_kit` on Android was researched and
rejected (HDR + Android-TV hardware-decode risk). Also patched (1.0.27):
`ExoPlayerEventListener.describeCause` appends `[HTTP 404 Not Found] [ERROR_CODE_…] cause: …` to
the error string; Dart reads it (`httpStatusFromPlaybackError`) and the player's error screen
always shows the details (owner: show any error so user photos can be diagnosed).
Added in 1.0.31 (**Data pool**): `StreamStats.java` (a `TransferListener` counting network bytes,
set by `HttpVideoAsset`), `StatsBridge.java` (MethodChannel `vespertv/stats` → nowMs / bytes /
rendered / dropped frames), `VideoAsset.streamStats()`, `VideoPlayer.streamStats`, and
`videoPlayer.streamStats = videoAsset.streamStats()` in both `VideoPlayerPlugin` create methods.
Uses `android.util.LongSparseArray`; new classes need `@OptIn(markerClass = UnstableApi.class)`.
Next release: **`ExoPlayerEventListener`** gives up on HTTP 404/410 at once (`isGoneError`) and after
3 failures in a row without reaching READY (`consecutiveErrors`); the 10 s window alone never fired
when each attempt took ~6.5 s to fail (endless spinner on a dead Media Hub link).
Unreleased (`+397`): **restart-loop cap** (`restartLooping`, main platform-view player only via
`capRestartLoops`; Multiview tiles keep recovering): more than 6 in-place restarts in 60 s of any
kind (errors, BEHIND_LIVE_WINDOW — never counted before — live ENDED, frozen video) even with READY
in between → `stop()` + error `[RESTART_LOOP n in 60 s: reason xN]`. Dart
`PlaybackService._watchRestartLoop` logs it (native restarts never reach Send log otherwise), shows
Reconnecting..., waits 3 s and runs `reloadCurrentChannel` once per channel per 2 min; else the
error screen. User video: guide preview flashing after Back from full screen until a channel change.
Added in 1.0.34: **`BufferBudget.java`** — on devices under 2.5 GB RAM (or `isLowRamDevice`),
`setTargetBufferBytes` 64 MB in `PlatformViewVideoPlayer` and 32 MB in `TextureVideoPlayer` (the
time limits alone let a 4K remux fill ~140 MB of Java heap; the Fire Stick ran out of memory).
Test +476 (cdx, 2026-10-27): **`OnDemandLoadControl.java`** wraps the main
player's existing load control. Dart explicitly enables it for non-transient
movies/episodes (`VodBuffering`, `Channel.isLive`); post-seek reserve5s,
depletion/rebuffer reserve10s, unchanged byte-budget escape/min/max/back buffer.
Live and texture policies are unchanged. **`VodPlaybackTrace.java`** adds bounded
credential-free state/buffer/audio-underrun telemetry for5min after configure/seek.
The owner's +475 stutter recovered without a restart; buffer starvation versus
audio stalls remains unconfirmed. See `dev-notes/vod-seek-buffering.md`.
Unreleased: **`AudioPassthrough.java`** (MethodChannel `vespertv/audio`, `setPassthrough`) — opt-in
HDMI passthrough: `PlatformViewVideoPlayer.buildAudioSink` gives `DefaultAudioSink.Builder(context)`
when on (AC3/E-AC3 Atmos/DTS to the receiver, app volume no longer applies); otherwise the
context-less sink above. Texture players (Multiview, Compatibility video) never pass through.
**Recording (1.0.32) is NOT in this plugin** — it is app-side Kotlin (`RecorderService.kt`,
`RecorderScheduler.kt` in `android/app/.../nox_iptv/`), so a plugin re-sync doesn't touch it.

## 10. Hard-won rules (don't re-learn these)
- **cdx, 2026-10-29: Moving a focused widget between containers can skip scope
  focus callbacks.** Sports Mode league reorder crosses between the top row and
  sidebar using the same FocusNode. Derive sidebar visibility from focused-entry
  membership and reconcile parent Back/last-entry state after layout; cached
  scope focus alone left the selected league hidden (or the rail stuck open).
- **Release-safe focus keys (cdx, 2026-10-27):** `FocusNode.debugLabel` is always
  null in release builds. Never derive widget keys, IDs or behavior from it.
  Media Hub +473 used `ValueKey(node.debugLabel!)`: controls became ErrorWidgets
  and D-pad could not enter cards, despite passing debug widget tests. +474 uses
  explicit stable control IDs; regressions clear diagnostic labels before rebuild
  and enter the grid through the wrapped TV connector row.
- **M3U playback type (cdx, 2026-10-26):** use `channel.isLive`, not
  `Channel.isLiveId(channel.rawId)`, whenever the Channel exists. M3U Movies/TV Shows
  use group-title classification but ordinary tvg-id/ch_N identifiers: those IDs alone
  look live. `onDemand` stores catalog type without renaming IDs; parser, legacy M3U
  cache restore and recent-history restore apply the same group rule. Xtream live groups
  are never reclassified by their names. Never infer VOD from controller duration.
- **Cold-start splash is deliberately slow (~20-25s with a big second playlist).** Entering the UI
  early lets remote input crash weak boxes. Do not cap/shorten it (`_bootstrap` in main.dart).
  The time is the catalog pre-load + `_waitForCategoriesToSettle`, not a timer (floor 2.6 s).
  Re-asked after the SQLite EPG (2026-10-18): owner chose to **leave it as is**. Since 1.0.31
  there is an **opt-in, device-only Fast startup** (Settings > General > Startup,
  `AppPreferences.fastStartup`): the splash loads Movies/TV Shows for at most 3.5 s, then the UI
  opens and the rest loads behind it (owner timed Formuler 30 s → 4 s, Fire Stick 4K 14 s → 5 s,
  stable). **On by default since 1.0.51+541 (owner, 2026-10-31: tested on several devices, they handle it);** an explicit user choice is kept. Never transfer it. The
  Android last-channel auto-resume after the splash was once removed (decoder start + the old ~25 s
  EPG decode made cold start sluggish); since the SQLite EPG it's back, **on by default** behind
  Settings > General > Startup: "Resume last channel in full screen" or "…with the guide open"
  (plays in the preview box / Windows mini player); at most one on, both off = nothing plays
  (Android shows the "Hold > to resume" pill). Both platforms honor it (Windows used to always
  resume full screen). Settings > General > Tabs can hide Movies/TV Shows (`AppPreferences
  .hideMoviesShows`: tabs column and search).
- **D-pad focus:** default directional traversal is unreliable across differently shaped columns/
  rows — use explicit dispatch (`_moveColumnFocus`, the Timeline guide's own Up/Down/Left/Right,
  one `FocusScopeNode` per zone + `CallbackShortcuts`). No per-row `FocusScope`. Any programmatic
  scroll uses `jumpTo`, never `animateTo` (caused an ANR-length freeze on a big list). Pause periodic
  timers when covered (`RouteAware`). Remote "hold Select" = `HoldToActivate`; `InkWell.onLongPress`
  is touch-only.
- **Fire OS's on-screen keyboard swallows the physical Back button — known, unfixable limitation.**
  Confirmed via a raw `getevent` capture (clean `KEY_BACK`) plus Flutter-side logging of
  `logicalKey.keyId`: pressing Back on a Fire TV remote while the on-screen keyboard has D-pad
  focus never reaches the app as Back/Escape/browserBack at all. Fire OS's own keyboard overlay
  intercepts it first and resynthesizes it as ordinary keyboard-internal D-pad navigation
  (arrowRight/arrowDown moving the on-screen selector) immediately followed by a synthetic
  `numpadEnter` — indistinguishable, by the time Flutter sees it, from the user genuinely
  navigating the keyboard and pressing Enter on purpose. That synthetic Enter is what fires
  `TextField.onSubmitted`/`TextInputAction.next`, advancing focus to the next field instead of
  closing the keyboard. No app-level fix exists. A Formuler box does not have this problem (Back
  closes its keyboard normally).
- **Text fields on a TV box go through `TvTextFieldGate` (`widgets/tv_text_field_gate.dart`,
  1.0.24):** the field stays `readOnly` (no keyboard) until OK, so the D-pad can pass over it.
  A plain `TextField` raises the keyboard as soon as it's focused: on Fire OS that took the
  remote, and Back then cleared all focus. Never reopen the keyboard on Enter/numpadEnter,
  because Fire OS sends a numpadEnter when Back closes its keyboard (Add Playlist and the Sports
  picker did that, so Back reopened the keyboard forever). The keyboard also never follows Next
  into the next field: Fire OS reports Back as that same Next action, so it can't be told apart
  (tried, 2026-10-19: Back walked field to field). A new field on TV: wrap it, and give
  its `onSubmitted` a focus target. **Every** field is gated since 1.0.26 (EPG matching, channel
  linking, TMDB key, profiles, backup-server dialog were the last — Fire TV user report);
  dialogs/pickers without a node use `FocusNodeOwner`. `test/tv_text_field_gate_guard_test.dart`
  fails the build on any ungated `TextField`; a deliberate exception needs a
  `// tv-text-field-gate: exempt — why` comment (Timeline filter, Windows Multiview picker).
  **Arrows on a gated field move focus on TV (1.0.35):** once a field has a cursor (typed in once),
  EditableText's arrow actions moved the cursor and consumed the key even read-only with the
  keyboard closed (Flutter's text-field fallback for arrows is "stay") — the long-standing "stuck in
  the search field". The gate overrides `ExtendSelectionVerticallyToAdjacentLineIntent` /
  `ExtendSelectionByCharacterIntent` with `focusInDirection`, deferred a microtask and skipped if
  focus already moved: Flutter delivers the key to the field even after a `HardwareKeyboard`
  handler handled it (Add Playlist's `_handleFieldEscapeKey`), and that handler must win.
  `test/tv_text_field_gate_test.dart`.
- **Sports Trak, Settings and Search keep a background live channel playing** (owner reverted the
  1.0.24 parking on all three, 2026-10-20). Movies/TV Shows/Media Hub still park it
  (`_parkLiveChannel`). The parking was added because the video stayed on screen over those pages
  on some Fire TV sticks (newer sticks on an older Fire OS build; not on the owner's updated 4K
  Max). Fix = opt-in **Settings > General > Background video** (`AppPreferences
  .hideVideoOnSports`, device-only): `_pushOverLiveVideo` removes the picture's platform view
  while the page is open, stream + sound keep going. Don't re-add the parking.
- **A `Focus(onKeyEvent: …)` wrapper around focusable children must be `canRequestFocus: false,
  skipTraversal: true`.** A plain one is itself a focus target: D-pad traversal landed on
  Multiview's invisible grid-sized wrapper instead of the next tile and the remote looked stuck
  (Fire Stick, 1.0.26 header overlay).
- **A plain focusable widget (not a text field) competes with Flutter's own default directional
  traversal — `HardwareKeyboard.instance.addHandler` loses that race.** `add_playlist_screen.dart`'s
  `_handleFieldEscapeKey` reliably overrides arrow keys while a *text field* has focus only because
  `EditableText` swallows arrow keys internally. For a non-text-field widget (e.g. `ModeButton`,
  `TvMenuTile`), default traversal still runs and overrides a raw handler's `requestFocus()`. Use
  `CallbackShortcuts` for that case — it intercepts before default traversal.
- **EPG lives in `EpgDatabase`, never fully in memory.** `EpgService` getters stay synchronous:
  now/next from a preloaded ~4 h slice, `getPrograms` loads Timeline rows on demand and signals via
  `guideRowsLoaded` (not `notifyListeners` — `TvHomeScreen` watches the whole service, so that would
  rebuild the entire TV screen per scrolled row). Don't reintroduce a whole-guide load or save.
- **`requestFocus` on an item a lazy `ListView` hasn't built does nothing** (off-screen chip/tile
  has no context). Jumping focus to "the selected one" needs a non-lazy row
  (`SingleChildScrollView`) + `Scrollable.ensureVisible`, or a target that is on screen.
- **Never call `notifyListeners()` mid-build.** `PlaylistManager.notifyListeners` defers anything
  fired during the build phase (fixed Group Management checkmarks not repainting).
- Composite `Channel.id` (`playlistId::rawId`) vs raw `Channel.rawId`: EPG lookups and
  `Channel.isLiveId` need **rawId**. EPG lookups go through `Channel.epgId` (override → `epgKey` →
  rawId). Channel ids come from the provider's EPG id, which copies share (ESPN 4K/HD/FHD), so
  every live-list load path runs `Channel.withUniqueIds` — add it to any new load path.
- Back button: walks content → groups → tabs, exits the app only from the tabs column (`PopScope`
  in TvHomeScreen).
- The "live island" pill / mini player share **one controller** across preview/fullscreen/pill; see
  the comments before touching `PlaybackService`.
- **Multiview audio swap = `setVolume` only (confirmed on Formuler + Fire Stick).** Never toggle
  audio *tracks* in place (`setAudioTrackTypeDisabled`) — tried twice, worse both times (frozen
  frame + looping audio, stalls). The "recreate both controllers on every swap" workaround
  reconnected two streams per Select press and fought the provider's connection limit; it's gone.
- **Multiview needs one provider connection per screen — that was the real cause of the old
  "freezes every ~40-60 s".** Most accounts behind the owner's Tuliprox really allow **1**
  connection (provider `user_info`), whatever Tuliprox's `max_connections` says. Two tiles on one
  such account kick each other; Tuliprox reconnects and splices the new upstream into the same
  socket (TS sync lost, timestamps jump back 15-26 s) → ExoPlayer audio discontinuity → freeze.
  No player can fix that; don't chase it again. One tile per account, or a 2+-connection provider,
  ran clean 25+ min. The popup on entering Multiview explains this to users.
- **"Open in Multiview" from the player must `await _playback.stop()` before pushing**, otherwise
  the fullscreen stream and its audio keep playing underneath.
- **Windows** is a separate world: `DesktopWindow` (`services/desktop_window.dart`) creates the
  window **full screen** by default (`WindowOptions(fullScreen: true, titleBarStyle: hidden)`) or
  **windowed** (sidebar toggle, remembered); leaving full screen needs `windowManager.show()`
  after `setFullScreen(false)` or the window vanishes (§13, 1.0.23). It cannot minimize while
  fullscreen → `_minimizeWindow()` exits fullscreen first and `onWindowRestore` re-enters it
  (not when windowed);
  `SystemNavigator.pop()` does nothing on Windows → use `windowManager.close()`; mouse "hold" needs
  the pointer `LongPressGestureRecognizer` inside `HoldToActivate` (keyboard Enter-hold alone did not
  work for mouse users); the last live channel is saved in `DesktopPlayerScreen`
  (`setLastChannelId`) because nothing else writes it on Windows.
- **Every user-visible string goes through `tr()` with a French entry in `lib/l10n/fr.dart`**
  (same `{placeholders}`). Never `tr()` a string that is also an id in logic (tab ids, 'All'/
  'Favorites' group entries, standings column labels) — translate at the display site. Details in
  `dev-notes/features.md` (Languages).
- **A screen that swaps its focused widget for another (keypad → summary) must give the new view
  a focus target** (`autofocus` + key handling); otherwise the remote has nothing focused and
  looks frozen (Transfer "Ready to copy", 2026-10-16).
- **`CallbackShortcuts` must be an ancestor of the focused node.** If it wraps only the body, it
  misses an AppBar `TextField`, so wrap the whole Scaffold (Search screen).
- Open-source principle: **no embedded API keys.** Anything needing a key (TMDB, a future
  OpenSubtitles) is bring-your-own-key in Settings.
- **REST/JSON Add-on Architecture (Media Hub, code name Archive):**
  The player plays HTTP(S) URLs (it has no torrent client: `infoHash`/`ytId`/`externalUrl` entries
  are skipped). Debrid-backed add-ons (Torrentio + Real-Debrid/TorBox etc.) are fine and supported —
  owner, 2026-10-21: users are worldwide, don't judge their sources. Their uncached streams
  (`[TB download]`, `[RD download]`…) 302 to a ~0.1 MB "being downloaded" clip; see
  `ArchiveReadyWatch` (Ready tag) and `DebridApi` (Settings > Media Hub > Debrid accounts).
  Two kinds of add-on source: a **stream-only** add-on on IMDb ids gets its grids/metas from
  Cinemeta (`ArchiveCatalogProvider`) and only `/stream/` goes to the add-on; an add-on with **its
  own catalogs** (any type, any id scheme — since 1.0.24) is browsed and played entirely from its
  own `/catalog/`, `/meta/`, `/stream/`. Custom types (not movie/series) keep their type string
  (`ArchiveCatalog.wireType` / `ArchiveMeta.wireType`) for requests and are browsed under Movies
  behind the genre picker's **Other** entry only (`ArchiveService.otherGenre`; kept out of the
  normal rows, search and Recently watched — adult add-ons, owner 2026-10-19).
  **Jellyfin / Emby** (1.0.24, `services/media_server_api.dart`, `screens/settings/
  media_server_screen.dart`): a server is an `ArchiveSource` with `server` (`MediaServerLogin`:
  kind, userId, token, deviceId), libraries = catalogs, direct `/Videos/{id}/stream?static=true`
  (no transcoding; key `ApiKey` Jellyfin / `api_key` Emby; auth header `Authorization` vs
  `X-Emby-Authorization`+`X-Emby-Token`; Emby tried under `/emby`). Owner added a real Emby server
  successfully on 1.0.24 (2026-10-19); Jellyfin still only mock-tested. Not done: watched-state sync, server subtitles, Quick Connect.

## 11. Known bugs & fixes (full table in `dev-notes/bugs-and-fixes.md`)
Look there before debugging. Still-open items: the **Fire OS stale launcher icon** (not fixable). The
old ~50 s EPG delay is **fixed** by the SQLite EPG store (0.5 s on the Formuler) — Windows check pending.

## 12. Features (details in `dev-notes/features.md`)
Timeline/Live guide, player secondary row + badges, Multiview, welcome prompt, hide channels, Expand catalog, backup servers, palettes, **viewer profiles** (never rewrite Main's storage keys), **languages** (EN/FR/ES/IT/EL), **Transfer to another device** (Wi-Fi + internet vault, built to grow into cloud sync). Read the file before changing any of these.

## 13. Status & open items (as of 2026-10-24)
- **Claude, 2026-10-31 - release 1.0.51 (beta), +541 (latest):** owner tested +540 on the Formuler and asked for the
  release and announcement. Android only; Windows stays 1.0.45. German (lib/l10n/de.dart, machine-translated), expanded
  catalog spotlight design + opt-in "Open groups as expanded catalog", Interface > Guide page (+ Compact guide, custom
  EPG URL in EPG > General), transparent popups (+ test popup), Support and Discord entries, Fast startup now ON by
  default, resume pill off by default, Sports Mode Right/OK key changes. Notes: dev-notes/releases/1.0.51.md.
- **cdx, 2026-10-30 - release 1.0.50 (beta), +534:** owner requested push and a new
  release after +533 acceptance. Android only; Windows stays at1.0.45 with its
  existing website links. Includes Plex/server streams from tracker lists,
  IPTV cast portraits, title-page row order, Android skip intro/credits and
  phone touch lock, updater storage/download guards, Sports preferences/odds,
  My Teams preferred channel and compact league header/quality setting move.
  Analyze16 baseline,1090 Flutter and15 guide tests pass;87 guide entries
  verified. Signed package/version checked. No queued Home mini player or
  Plex Live TV work added. Notes: dev-notes/releases/1.0.50.md; final push,
  publication and download verification state: root HANDOFF.md.
- **Claude, 2026-10-30 — test builds +532/+533 on main (owner-tested, all OK; Codex releases next):**
  - **Skip intro / credits (Android):** IntroDB (`api.introdb.app/segments?imdb_id&season&episode`,
    keyless, Nuvio's source) via `services/skip_segments.dart`; ids from `WatchTracker.itemFor`
    (Media Hub IMDb; IPTV TMDB -> IMDb with the user's key). Many providers send **no** series ids
    (LOG-UPRJ8M): `SeriesDetailScreen._syncTrackers` then uses the single exact title/year TMDB match
    (`ArchiveDiscoveryService.tmdbIdFor`, shared with the cast photos). `widgets/skip_segment_button.dart`:
    white pill, auto-hides after 10 s, back with the bar; OK skips while no bar button has focus, Up
    from the bottom bar focuses the pill (`_skipFocus`, ▲ hint), credits + queued episode = Next
    episode. Settings > Playback > Skip intro (on by default; owner never answered on default-off).
    Send log: `SeriesIds:` / `SkipIntro:`. Windows not done. Episodes only.
  - **Betting odds** (Settings > Sports Trak > Betting odds, off, per viewer): ESPN scoreboard
    `competitions[0].odds` -> `SportsOdds` (`sportsOddsOf`), game card line, matchup middle slot when
    no injury, `_OddsTable` in the stats pop-up. Display only: never bet links / in-app betting
    (sportsbooks have no third-party bet API; licensing risk). Sports Mode setting moved to Sports Trak.
  - `cleanDisplayTitle` drops "4K: " / "4KDV: " colon prefixes (only quality tags before the colon), so
    IPTV 4K categories get cast. Merged Codex phone touch lock + Plex streams for tracker/list titles.
  - Parked ideas: `dev-notes/plex-live-tv.md`; Home live mini player (HANDOFF.md).
- **cdx, 2026-10-30 — IPTV cast portraits** (`codex/iptv-cast-portraits`):
  IPTV movie/show pages reuse Media Hub portraits/actor credits with a saved
  TMDB key. Cast jumps to the row; selected credits open matching IPTV details.
  Positive provider TMDB id or unique exact title/year lookup; no key retains
  provider-name bubbles. Analyze16/1046Flutter and15Node pass; guide84 verified.
  See dev-notes/iptv-cast-portraits.md. No package/upload; hosted APK530 predates
  this and updater storage guard. Actual TMDB/provider/device QA pending.
- **cdx, 2026-10-30 — updater storage/download guards**
  (`codex/updater-storage-check`, stacked on hosted test530): Android StatFs
  cache free-space check requires3x GitHub APK size before HTTP. Plain localized
  shortfall errors; invalid/partial/oversized downloads removed before Install.
  Old update APK deleted at next cold launch, guarded against activity recreation.
  See dev-notes/app-updater-storage.md. Analyze16/1025Flutter pass and Kotlin
  debug compilation succeeds. Hosted APK530 predates this change; no version
  bump/installable APK/install/upload. Cold-launch/low-space device QA pending.
- **cdx, 2026-10-30 — signed test APK1.0.49+530** (`codex/test-apk-530`):
  includes Plex, title-page row order, My Teams preferred channel, country
  preference, preferred playlist and hide-empty-leagues. Analyze16/1005Flutter
  pass; package/version and release certificate verified. Owner approved VPS
  upload; test APK is live on pair.vespertv.app/dl/ under its versioned filename.
  Public HTTP200/full-download SHA256 verified. No device installation, server
  configuration/service change, public release or push. Next newly built APK
  must exceed530. Exact download URL/hash and state: root HANDOFF.md.
- **cdx, 2026-10-30 — Hide empty Sports leagues**
  (`codex/hide-empty-sports-leagues`, stacked on preferred playlist): new
  off-by-default, per-viewer Sports Trak setting follows the selected day.
  Navigation hides confirmed empty leagues; unavailable schedules remain.
  Saved membership/order/favourite and Edit leagues are preserved; quiet
  selected league falls back to All. See dev-notes/sports-league-visibility.md.
  Analyze16/1005Flutter and15Node tests pass; guide83 verified. APK529 predates
  this and preferred playlist. Formuler install still on hold; no build.
- **cdx, 2026-10-30 — Sports preferred playlist**
  (`codex/sports-preferred-playlist`, stacked on test APK529 sources): new
  per-viewer Settings > Sports Trak > Preferred playlist. Comparable matches
  rank playlist before country/quality; saved picks, added sources and
  game evidence retain precedence. Both capped fallback paths prioritize
  eligible preferred-playlist copies. See sports-country-preferences.md.
  Analyze16/977Flutter and15Node tests pass. APK529 predates this change;
  Formuler installation still on hold. No build/version bump/publication.
- **cdx, 2026-10-29 — local test APK1.0.49+529** (`codex/test-apk-529`):
  all four completed changes (Plex, title-page order, My Teams preferred channel,
  Sports country preferences) built in release mode. Analyze16/965Flutter pass;
  release certificate and package/version verified. Owner explicitly asked to
  wait before Formuler installation: **not installed; wait for owner instruction**.
  Artifact/hash in root HANDOFF.md. No push/release; next new build >529.
- **cdx, 2026-10-29 — Sports country preferences**
  (`codex/sports-country-preferences`, stacked on prior three features): new
  Settings > Sports Trak > Preferred channel countries, per viewer. Final
  ranking only; explicit picks and game evidence precede generic suggestions,
  other countries remain fallbacks, unset preserves previous ranking. See
  `dev-notes/sports-country-preferences.md`; no package or publication.
  Analyze16,965Flutter and15Node tests pass; physical-box/provider QA pending.
- **cdx, 2026-10-29 — My Teams preferred channel**
  (`codex/my-teams-preferred-channel`, stacked on title-page/Plex): hold team >
  Set preferred channel works without a current game; visible live channels,
  search/groups, Automatic reset, per-viewer storage. Existing game overrides win.
  Remote guide/help index updated locally; no bot/VPS deployment.
  Analyze16,951Flutter and15Node tests pass. No build/install; box QA pending.
- **cdx, 2026-10-29 — title-page row order** (`codex/title-page-row-order`,
  stacked on Plex): Customize title page beside Explore more saves per-viewer
  collection/related/cast order; actors can be first. Shared Hub movie/series
  panel, explicit remote navigation, FR/ES/IT/EL. See media-hub-experience.md.
- **cdx, 2026-10-29 — Plex connector** (`codex/plex-media-server`): shared
  Jellyfin/Emby/Plex connector adds Plex phone/QR sign-in and owned/shared server
  selection. Libraries/search/metadata/episodes/direct versions/subtitles use the
  existing Hub and Android/Windows playback paths. No transcoding or multipart
  stitching. Analyze16 and945Flutter tests pass; real Plex sign-in/playback pending.
  See `dev-notes/plex-media-server.md`; no package/publication.
- **Claude, 2026-10-29 — Android hotfix release 1.0.49+528 (latest):** global search
  speed (Media Hub replies throttled 350 ms + rows capped at 100, cached `TitleSearch.fold`
  with ASCII fast path, memoized local matches, stable row keys/nodes, indexed
  `ArchiveService.isFavorite` — it decoded the whole favourites JSON per poster per build);
  **From phone** for TMDB key + Custom posters (`screens/settings/phone_link_screen.dart`,
  `PairingKind.apiKey`/`poster`, Wi-Fi only); Sports Mode: Back from full screen opened from
  the Live TV guide refocuses the guide (`_refocusAfterFeed` checks `_liveOpen`; Shield report).
  Owner-tested +525/+527. APK only, Windows stays 1.0.45. Next build > 528.
- **Claude, 2026-10-29 — Android hotfix release 1.0.48+524:** discovery rows scroll
  steadily (`archive_discovery_panel.dart`: minimal row jumpTo; page reveals the row's keyed
  Column, NOT a card — ensureVisible measures against the nearest viewport; Explore more minimal
  scroll; D-pad test asserts focus on screen + Up never scrolls down). New Settings > Media Hub >
  **Custom posters** (`ArchivePosters`, `vesper_archive_poster_pattern`, device-only):
  `{imdb_id}`/`{tmdb_id}`/`{type}` pattern; `ArchiveMeta.posterUrl` is now a getter over
  `originalPosterUrl` (what toJson saves). APK only, Windows stays 1.0.45. Known flaky test:
  `sports_schedule_test` "calendar: D-pad selects days" can fail in the full suite
  (path_provider MissingPluginException after completion), passes alone. Next build > 524.
- **Claude, 2026-10-29 — Android release 1.0.47+520:** Codex's Media Hub experience
  (all 6 Nuvio-plan priorities, dev-notes/media-hub-experience.md + Claude follow-ups: Windows
  headers/subtitles, 41 translations, movie page scroll-to-top), live player Right = last channel,
  TV boxes ignore audio-focus loss (`streamController` mixWithOthers on TV), main player
  reconnects a live stream the server closed (`PlatformViewExoPlayerEventListener
  .reconnectWhenLiveEnds`; Xiaomi MIBOX4 freeze, LOG-RY6KT6/FF6ZV5: provider drops every ~60 s,
  now a hiccup), cache-folder recreate. APK only; Windows stays 1.0.45 (same exception as 1.0.46).
  Debrid torrent resolution parked on `claude/debrid-resolve` (owner: not doing it).
  Notes: dev-notes/releases/1.0.47.md. Next build must be > 520.
- **Codex, 2026-10-29 — Android release1.0.46+514:** includes local main through
  0f296e5 (owner-tested +513), all league/preview/stats fixes and Multiview Swap.
  Remote tips and79-entry help index now cover Guide/EPG, the Sports Mode Live TV
  panel, Back chain, big/small player flow, Swap mode and profile-root Back.
  Analyze16 baseline,915Flutter tests and15Node guide tests pass. Owner deferred
  Windows build/testing: keep release1.0.45 and pin website Windows links there;
  release1.0.46 has only an APK, so Windows' updater offers no new zip. See
  dev-notes/releases/1.0.46.md and root HANDOFF.md for publication status.
- **Claude, 2026-10-29 — merged to local `main` for release, test +503 (Formuler):**
  - **Multiview 1 + 3 Swap mode** (Android): hold OK > Swap mode or the header button;
    arrows rotate the playing screens through the big one (controllers move, nothing
    reconnects), sound only from the big screen, blinking SWAP pill in the black band
    under it + gold flash per swap; OK/Back ends. Hold menu = taller scrollable sheet.
  - **Sports Mode player flow** (owner-worded): first game = big player beside the feed;
    Down to the cards = small player; OK on a card there plays in the small player
    (`_setPreview` keeps `_modeBrowsing`); Up from the first row = big player again
    (`_backToFeed` before the See all chip step).
  - **Back with Launch with profiles selector on** (`services/profile_gate.dart`): Back
    at the TV / Sports Mode root stops playback and returns to Who's watching
    (`main.dart _returnToProfiles`); Back there = Exit prompt (Stay focused). Off = unchanged.
  - Includes Codex's `codex/sports-league-fixes` (1e0dd53, tests 500/501). Analyze 16,
    906 tests pass. Owner approved +503 and asked Codex to release/announce.
  - **Remote Guide/EPG key** (`services/guide_key.dart`, +504..+508): opens the live guide
    from anywhere (TV home: pop to it, TV tab, playing channel). Formuler EPG = Linux
    KEY_PROGRAM (scan 362) mapped by its locked keylayout to Android keycode 228 (found
    with an on-screen key probe; its logcat is empty) — `GuideKey.isGuide` accepts
    KEYCODE_GUIDE, scan 362 and keycode 228. Sports Mode root: the in-page Live TV panel.
  - **Sports Mode Live TV panel** (+510..+513): OK on a channel plays it in the Sports
    Mode player itself (channel-only preview: feed layout's big video; no games = shared
    `_HeroVideo` alone), OK again = full screen on the same session; Right on a group (no
    guide open) = into the page; Left from the page = back to the open panel. Sports Mode
    Back: page -> rail (player alive) -> rail Back stops it -> Back quits. Regular Sports
    Trak (mode off) unchanged. Owner tested through +513; 915 tests, analyze 16.
- **cdx, 2026-10-29 — Sports Mode league navigation** (`codex/sports-league-fixes`,
  unreleased): vertical sidebar move uses Up/Down; horizontal rows use Left/Right.
  Rail visibility and Back state survive focused-league reparenting across the
  fifth slot. All is a visible one-press dropdown of every enabled league, with
  All leagues first; normal Sports Trak tap/hold behavior retained. No enable
  cap reproduced or settings rewritten. Investigation + implementation notes:
  `dev-notes/sports-league-investigation.md`; device acceptance pending.
- **cdx, 2026-10-28 — release preparation 1.0.45 (beta), +496:** owner asked
  to follow the merge/release handoff. Real branches claude/sports-mode-rail
  (863da01, Menu/Live TV/provider-failure) and codex/startup-profile-selector
  (bbb9733, owner-approved +494) merged; test494 snapshot stashed, excluded
  experiments unchanged. Matching Android/Windows release packages; guide and
  help index updated. Exact validation/publication state: root HANDOFF.md;
  user-facing notes: dev-notes/release-1.0.45.md. Analyze16, all872 Flutter
  tests,15 guide tests and6 deployment-script tests pass.

- **Claude, 2026-10-28 — Sports Mode Live TV panel, test +495** (`claude/sports-mode-rail`,
  committed with the +493 Sports Menu/provider-failure work): rail Live TV opens groups + a
  see-through guide inside Sports Mode; OK = full screen, Back returns to the guide, Back x3
  closes. "Open full Live TV" row = TV home. Installed on the Formuler (version 495 verified);
  owner approved, asked Codex to merge and release. Analyze 16, 860 tests pass.
  Details: `dev-notes/sports-mode.md` (Live TV panel). Next build must be > 495.
- **cdx, 2026-10-28 — startup profile selector** (`codex/startup-profile-selector`):
  Settings > General > Startup > Launch with profiles selector (off by default,
  device-only). After the existing splash, a bounded frosted panel lists all
  viewers with photos and explicit remote arrows. Existing switchTo/PIN gate
  applies before the short selection animation; only then are startup routes
  and automatic playback created for the chosen viewer. No Home flash or
  previous-viewer playback. See `dev-notes/startup-profile-selector.md`;
  owner tested +494 on Formuler and approved; included in release +496.

- **cdx, 2026-10-28 — release preparation 1.0.44 (beta), +492**
  (`codex/release-1-0-44`): owner requested publication and Discord announcement
  after accepted +491. Matching Android/Windows packages, Sports Mode explicitly
  labelled a beta feature in release notes and remote guide. Includes every main
  change since public +472; excluded branches unchanged. Analyze baseline16,
  all852 Flutter tests and15 guide tests pass; both signed Android package and
  full Windows ZIP built/version-checked (492). Exact artifacts/publication in
  HANDOFF.md; notes in dev-notes/release-1.0.44.md.

- **2026-10-28 — merged to local `main` (not pushed), ready for Codex to release: +491.**
  Contains +484 programme reminders/recording, +485 compact live info, +486 Red/Blue
  palettes, +487 Codex **Sports Mode** (opt-in sports-first home, per viewer) and Claude's
  +488..+491 Sports Mode layout: TV rail hidden until Left (`SportsModeShell.collapse`,
  `Offstage` keeps nodes focusable), day strip -> `day:menu` roll-down chip, and while a
  game plays a **feed** of the day's games beside a big video (`_buildFeed`, one focus node;
  OK watch, Right full screen, hold OK stats, Down past end = card rows under a small hero,
  Up back). Owner-tested on the Formuler +491 ("we have a winner"); Windows not rebuilt, no
  widget test for the feed (needs a matched playing channel). Details:
  `dev-notes/sports-mode.md`. Next build must be > 491. Excluded branches unchanged
  (native-surface-prepare, network-cards, tunneling-test).
- **cdx, 2026-10-28 — Sports Mode** (`codex/sports-mode`): opt-in per-viewer
  sports home, five ordered leagues in the left rail and remaining leagues/All/
  Edit leagues in a floating bar. Shared SportsScreen engine, day/tools and
  My Teams/live/upcoming/final rows; explicit rail/control/row focus and scroll.
  Toggle in Sports Trak and Interface settings. Single root route on startup,
  preview stays fixed on TV, Live TV Back returns to sports. Test +487 installed
  on Formuler (version/hash verified); analyze baseline 16, all851 tests and15
  guide tests pass. Physical acceptance pending; exact details in HANDOFF.md.
  See dev-notes/sports-mode.md.

- **cdx, 2026-10-28 — Red / Blue palettes** (`codex/red-blue-palettes`):
  standalone vivid vermilion Red; Habs replaced by vivid royal Blue. Existing
  `habs` / `green_orange` preferences resolve to Blue without rewriting storage.
  Localised EN/FR/ES/IT/EL labels; same Aqua-style accent treatment and Refined
  finish behavior. Test +486 installed on Formuler (version/hash verified);
  analyze baseline 16 and all 832 tests pass. Owner palette acceptance pending;
  exact checks/artifact details in HANDOFF.md.

- **cdx, 2026-10-28 — compact live info** (`codex/compact-live-info`):
  Channel schedule is inside the live/catch-up info card header. Narrower card,
  smaller logo/padding, one-line description, lower placement; same Up/OK/Down/Back
  handlers/node. Narrow/large-text screens keep the action inside on its own row.
  Test +485 includes +484 reminders/recording; analyze baseline 16 and 831 tests
  pass. Signed APK installed on Formuler (version/hash verified); owner acceptance
  pending. Exact checks/artifact details in HANDOFF.md.

- **cdx, 2026-10-28 — programme schedule actions** (`codex/programme-reminders-recording`):
  upcoming Channel schedule shows Remind me / Record, with cancellation and stable
  remote focus. Viewer/device-local reminders notify5min before and at start while
  open; exact EPG-window recordings use the existing Android alarm/boot scheduler
  and Recordings tab. Storage/overlap checks and guarded same-channel tap handoff.
  Production-signed+484 (all +483 features) installed over+482 on Formuler,
  version/hash verified; analyze16,825Flutter/15help tests pass. Device acceptance
  pending; exact artifact state in HANDOFF.md.
  See `dev-notes/programme-schedule-actions.md`. No publication/native-player edits.

- **Claude, 2026-10-27 (main, unbuilt): Team Schedule + Media Hub fixes.** Hold OK on a team in
  Standings / My Teams = menu Schedule / Follow-Unfollow (`showSportsTeamMenu`). Schedule =
  `screens/sports_schedule_screen.dart`, month calendar (one focus node, own arrows, CH+/CH- month),
  data `SportsService.teamSeason`: soccer reads ESPN `soccer/all/teams/{id}/schedule` (+`fixture=true`)
  so cups come along; `_eventLeague` gives each event its competition (bank entry, else built from the
  event's `league.slug`/`alternateId` logo). My Teams unchanged (league path). Media Hub: the Refresh
  button re-reads every add-on manifest (`refresh(manifests: true)`; a stream-only AIOStreams that gained
  TMDB catalogs never upgraded); own-catalog `tmdb:` titles retry with the details' `imdb_id` and ask
  stream-only add-ons too (`_imdbVideoId`); shared Cinemeta search rows/hero chip name every add-on.
- **cdx 2026-10-27 — broader title search:** `codex/broader-title-search`
  shares Unicode/accent/separator matching across global M3U/live, Xtream's full
  SQLite cache (schema9, bounded backfill) and Media Hub. Hub preserves provider
  aliases, merges bounded spelling queries and supports search-only catalogs;
  old saved manifests upgrade without re-adding. Production-signed test+477 is
  installed on Formuler (version/hash verified); analyze16,774Flutter tests pass.
  Device search acceptance pending. See `dev-notes/broader-title-search.md`.

- **cdx 2026-10-27 — post-seek stutter candidate:** `codex/vod-seek-buffering`
  adds explicit shared IPTV/Media Hub VOD buffering reserves and bounded native
  diagnostics after comparing LOG-EW8Q8X with recovered LOG-QHP444. No decoder,
  audio-track selection or live timing changes. Production-signed test +476 is
  installed on Formuler (version/hash verified); actual seek improvement pending
  owner testing. Analyze16,760Flutter/87targeted native tests passed.
  See `dev-notes/vod-seek-buffering.md` and HANDOFF.md.

- **cdx 2026-10-27 — Media Hub source cards:** `codex/mediahub-source-grid`
  redesigns the shared Settings/Hub Sources page with add/connectors at the top,
  playback-source and catalog/list grids, role labels and per-card controls.
  Explicit responsive D-pad rows, stable toggle/dialog focus and immediate scroll;
  no player/storage changes. +473 release diagnostic-key failure was fixed in
  +474 (see section10); owner confirmed improved navigation, requested smaller
  cards. Production-signed +475 is installed on Formuler: roughly one-third card
  area,3 columns at960px/4 at1280px, same direct controls/dark glass. Analyze16,
  755 tests; owner accepted compact size on Formuler (2026-10-27). See `dev-notes/mediahub-source-grid.md`
  and root HANDOFF.md. No publication.

- **cdx 2026-10-27 — release 1.0.43 (beta), +472:** owner requested release and
  Discord announcement after Claude merged all branches. Timeline is the fresh-install
  guide default; saved choices remain. Includes +464–471 cast/source-size/guide fixes,
  Android 1+3 Multiview, per-match score alerts and configurable reminder timing.
  APK + Windows built; analyze16,740Flutter/15Node/6deployment tests pass.
  Publication/download/announcement results: root HANDOFF.md.

- **cdx 2026-10-27 — match score alerts:** `codex/match-score-alerts` adds the game
  hold-menu Set/Remove goals alert for this match, using the existing top-left popup.
  Both teams, independent of My Teams opt-in; per-viewer/device persistence, Hide
  scores respected, duplicates suppressed. Existing cached polling/baselines reused.
- **cdx 2026-10-27 — reminder timing:** `codex/reminder-timing` adds a right-side
  game reminder picker (15min/1h/1day/1week + kickoff, or kickoff only). Existing
  reminders migrate to15min; per-game timing survives rescheduling and can be edited.
  Passed choices disabled, stale notices discarded; team defaults remain15min.
  See dev-notes/sports-tab.md and root HANDOFF.md for verification/integration state.

- **cdx, 2026-10-27: Playing source marker** (`codex/current-source-tag`): shared
  Media Hub source drawer uses a persistent gold Current stream tag and thin outline
  independent of cursor focus. Matches refreshed links by unique same-provider file
  identity; ambiguous/missing matches retain the known playing entry. No probes,
  saved-choice changes, new strings or playback restart on selecting Current.
- **cdx, 2026-10-27: IPTV file size** (`codex/iptv-file-size`): Data pool shows
  file totals from existing progressive-player HTTP headers, with Media Hub metadata
  fallback; never a manifest/chunk size or downloaded-byte estimate. Owner authorised
  the stats-only native exception; no additional requests or decoder/surface changes.
  See `dev-notes/iptv-file-size.md` and root HANDOFF.md for checks.

- **Codex 2026-10-27 — catch-up help:** `codex/catchup-help` adds Android catch-up
  controls and provider limits to the remote guide, site FAQ/features and README.
  Bot index has 66 entries; plain catchup/catch-up/catch up questions are supported.
  Guide Back/Now is distinguished from full-screen LIVE/Fast-forward. Deploy status:
  root HANDOFF.md. No app/player changes; Windows catch-up remains pending.
- **Released 1.0.42 (beta), +463, 2026-10-27** (previous release; tag on `1651df1`, Discord announced).
  Includes catch-up (Android), Refined finish + translucent columns, Aqua, reminders on all game
  cards, decoder HDR reporting and audio track labels. The notes ask users to run Update Content +
  Update EPG Now once. Next build must be > 463.
- **cdx, 2026-10-27: Aqua palette** (`codex/aqua-theme`, from committed test459):
  cyan/teal vivid pair in the existing palette registry, localised label in all
  four dictionaries. Existing picker/profile persistence/refined/translucent paths
  unchanged. Added Aqua to the existing finish geometry/focus test matrix.

- **Claude, 2026-10-27: Catch-up (Android) done, owner-tested (+461 Formuler, +462 Fire Stick
  with Codex's Aqua)** on `claude/catchup`; local `main` fast-forwarded to it, not pushed. Plan,
  Blcktv probe and task split: `dev-notes/catchup-plan.md`.
  - **Playback:**
    - Each catch-up request plays a transient `cu_` channel (never live, own id); its live channel
      is `PlaybackService.liveChannel`. Use liveChannel for anything matching groups/rows/history.
    - `playCatchup` / `backToLive` / `togglePlayPause` (pause > 90 s = timeshift).
    - Native `setFiniteMode`: no live recovery for finite archive streams.
    - `_playGen`: overlapping plays used to leak a player and its connection.
  - **Guide:**
    - Left into the past remounts on an anchored window (`onShiftWindow`); Back = back to now.
    - `_guideHoldFocus` keeps focus through block rebuilds and remounts. Without it the focus
      recovery opened the columns, and fast presses flicked to the search button.
  - **EPG:**
    - Catch-up ids keep up to 7 days of past.
    - The catch-up list is re-read lazily (live lists load after launch).
    - A refresh awaits `ensureLiveChannelsLoaded`.
  - **Left to do:** Windows (C4) and the docs/remote page (C5, Codex). See HANDOFF.md.
- **cdx, 2026-10-27: C2 catch-up URL builder** (`codex/catchup-url`, from dd16643):
  standalone CatchupKind plus catchupUrl/catchupPhpUrl/catchupUrlForLog; no Channel
  dependency or callers. Fixed server-offset minute URLs, UTC templates and
  credential-free diagnostics. See `test/catchup_url_test.dart` and root HANDOFF.md.

- **cdx, 2026-10-27: Refined translucent columns** (`codex/refined-translucent`,
  from installed glass test458): full-video guide scrims now scope see-through
  refined fills for tabs/groups/guide while retaining rounded bevels/reflections.
  Ordinary settings/panels keep the solid finish; no focus/video/config changes.
  See `dev-notes/refined-finish.md` and root HANDOFF.md for checks.

- **Claude, 2026-10-26: Live audio tracks (+457 on the Formuler; labels after it, not installed).**
  `_AudioTrackButton`/`_SubtitleButton` are keyed by controller + channel id: the full-screen bar
  stays mounted across zaps (and native live zap keeps the controller), so the track lists were
  read once per player screen and later channels never showed their tracks. They now re-read 5x
  over 15 s (not stopping at 2+, the old stream's tracks linger right after a native zap). Picker
  labels: name, else language (placeholders `mis`/`mul`/`und`/`zxx`/`qaa` skipped), else
  "Audio n", plus codec + layout (`DataPoolCard.codecName`/`channelsName`). Send log line
  `AudioTracks: <channel> n=… m3u8=… ts=… [lang|label|codec|ch]` once per stream (temporary
  diagnostic; keep until the CBC case below is closed). Owner: TSN2 shows 4 tracks (MIS/MUL).
  **CBC Montreal (Samiam23, "commentary", TiviMate switches it):** a raw PMT probe of the stream on
  Trex (2 copies, .ts + .m3u8) and Blcktv showed ONE AAC `eng` track (audio_type normal) on
  2026-10-26 ~21:30 ET; our log agreed (n=1). Likely a programme-time described-video track. Next:
  when Sam sees it, TiviMate screenshot + our Send log + a re-probe at the same moment. Unrelated
  fact verified in media3 1.9.2 source: HLS TS segments key tracks by stream type
  (`TsExtractor` MODE_HLS), so a second same-codec audio PID inside HLS segments is dropped;
  plain .ts (our Xtream default) keys by PID and keeps all of them.
  Analyze baseline is now **16** (the rewritten label code removed one info). Also cleaned
  `C:\Users\aarse`: all 13 worktrees + 21 old build/snapshot folders + 199 loose
  `VesperTV-*` logs deleted (every branch verified merged; unmerged branches kept, no folders).
- **cdx, 2026-10-26: Release 1.0.41 (beta), +455 authorised.** Includes all completed
  Codex work through Goals alert plus previously integrated Claude profiles/trailers/zap freeze.
  All worktrees audited: Claude's dirty zap-freeze source is already present (native file identical;
  guide patch reverse-applies). Old native-surface-prepare is superseded; network-cards-only notes
  are historical; tunneling-test remains deliberately excluded per dev-notes/merge-all-20261025.md.
  Android + Windows, latest release with beta in title; retain previous releases. Exact final
  build/publication checks in HANDOFF.md. See dev-notes/release-1.0.41.md for user-facing changes.


- **cdx, 2026-10-26: Compact source drawer / Back correction (+454).** On wide screens drawer width is30% capped320logicalpx (was500), compact124px rows scaled for larger text; provider/current marker, advertised formats, description summary and file size retained. Portrait layout remains full. Both Android and Windows player routes block Back while drawer opens/closes and for700ms after dismissal; Left/Back close once, late source selection cannot pop the player. Shared PlaybackModalBackGuard. Owner confirmed Windows Resume works on+452.

- **cdx, 2026-10-26: Home Back regression correction (+453).** Owner reported Back returns Home to TV then opens Exit in +452. Duplicate key/platform Back reproduces this in tests. TV root ignores exit requests for700ms after returning from Home/Hub/Sports; normal later Back still confirms Exit. Covered root cannot handle Back, Home ignores Back repeats. Tested profiles visible/hidden and initial Home/sidebar Home with system/key/duplicate paths. No native player changes.

- **cdx, 2026-10-26: Local test build +452 (owner requested merge/build/install).** All Codex work including Windows movie/episode resume and saved source URL retrieval merged locally. Production-signed VesperTV-1.0.40-test.452.apk installed in place on Formuler Z11 Pro MAX; installed version452 and SHA256 match verified. Windows ZIP VesperTV-1.0.40-test.452-windows-x64.zip built (exe version1.0.40+452), full release folder/CRC checked. Analyze17, all552tests passed. No Windows launch or box UI navigation. No push, GitHub release, VPS deploy or Discord announcement; published release unchanged. See HANDOFF.md for hashes/artifacts.

- **cdx, 2026-10-26: Retrieve saved source URL** on `codex/view-source-url` (merged locally in +452): Media Hub source settings add View source URL for add-ons and media servers. Opens full selectable/scrollable URL with Copy URL; add-ons copy exact saved manifest URL, media servers copy base URL without internal user fragment. Tracker rows omitted. URLs remain hidden until requested and are never logged by this action. No source state changes.

- **cdx, 2026-10-26: Windows VOD resume** (merged locally in +452) on `codex/windows-vod-resume`: desktop player now saves per-viewer movie/episode position and duration every5s and before exit/source changes, records Continue Watching history, and opens files at saved positions through media_kit Media.start. Applies to IPTV and Media Hub, including M3U VOD. Tracker fraction resume waits for known duration; source-file changes keep explicit current position. Live/transient/download-placeholder playback excluded; no native player edits; Windows binary built in +452, runtime testing pending.

- **cdx, 2026-10-26: All Codex branches merged into main locally (owner requested).** Includes M3U movie controls/cache migration, per-profile audio/subtitle resume, Playback settings, live playlist tag, Boxing/WWE/AEW, Media Hub Right source drawer and phone PiP. Discord bot source and historical research/audit also merged; generated help index refreshed from current guide. Old proposals archived under `dev-notes/legacy-*-proposal*.md` so the owner's root PROPOSAL.md remains untouched. No new APK/version, deployment, push, release or announcement. Merge verification is in HANDOFF.md.

- **cdx, 2026-10-26: Boxing / WWE / AEW events** on `codex/boxing-wrestling-events` (merged locally). Optional Fighting bank entries use verified TheSportsDB schedules (4445/4444/4563), existing UFC workflow. Named boxing bouts show fighters; wrestling/unpaired cards show event title/time/venue, same themed cards and channel controls. SportsGame.isEventOnly guards absent opponents in menus, side panel and recordings. No invented live scores/winners, standings or announced matches. Free feed schedule/result completeness limited; official website importers not used. See dev-notes/sports-tab.md.

- **cdx, 2026-10-26: Live playlist gold tag** on `codex/live-playlist-tag` (based on Playback settings). Android live OK/zap info card shows current channel's playlist name beside the channel title, even without EPG; Windows live player bar shows the same label. Resolves via channel.playlistId; unknown/blank names omitted, long labels ellipsised. GoldTag extracted from Real4kTag so both use the existing amber outline pattern. No behavior/default/native changes; merged locally, not in a new APK.

- **cdx, 2026-10-26: Playback settings category** on `codex/playback-settings`, based on track-resume f8e49ce. Moves Background video, Audio (including new language defaults), Frame rate & resolution (formerly Display), Data pool, Trailers, Multiview tips, Resume reminder and Media Hub largest-file playback into Playback. Interface retains theme/tabs/favourites; General retains Startup. Same preference keys/defaults/platform gates. Largest-file option moved from source management without changing its behavior. Merged locally, not in a new APK; see HANDOFF.md.

- **cdx, 2026-10-26: Audio/subtitle Resume** on `codex/mediahub-track-resume` (merged locally). Android Playback > Audio adds per-viewer preferred audio/subtitle languages (source default/off initially). Manual VOD audio is remembered by language+label, not transient track IDs; applies on initial/reconnect/backup controller creation. Subtitle memory now includes Media Hub series and individual movies, explicitly remembers Off and is per viewer; main legacy keys retained. Android waits for player initialization, guards stale requests; Windows subtitle restoration uses the same memory. Audio preferences are Android only (Windows has no audio-track picker). Does not prove the separate 47GB-to-7GB source report: same file can reopen with different default tracks. No vendored-player changes.
- **cdx, 2026-10-26: Phone picture-in-picture** on `codex/phone-picture-in-picture` (source only, not in test APK+451). Android 8+ phones/tablets enter PiP from playing fullscreen video via Home; Android12+ auto-entry, older versions onUserLeaveHint. PhonePictureInPicture native bridge and route-aware Flutter wrapper hide overlays while retaining the video pane; playback pause/covered routes disarm entry, stopped Activity pauses video. TV hardware excluded natively and in Dart. Native Kotlin compilation and Flutter tests required; real-phone PiP rendering not yet verified. No vendored-player changes.

- **cdx, 2026-10-26: Test APK +451** (owner requested): Hide profiles and Media Hub resume/size branches merged into main locally. Adds stable hashed file identity plus resume/size diagnostics for the reported 47GB-to-7GB episode case, whose exact cause remains unconfirmed from LOG-T8WJEC (+449). Test by selecting the desired file once, exiting and resuming the same episode from Media Hub, pressing OK for size, then sending a fresh log. Legacy records cannot reconstruct missing file identity when both old link and description change. No GitHub publication or Discord announcement requested.

- **cdx, 2026-10-26: Hide profiles** under Settings > Interface > Tabs on `codex/hide-home-profiles` (not released). Off by default, stored per viewer with Home settings; removes only Home profile cards, keeps clock/Windows Back and safe D-pad focus including empty Home. Home profile-copy includes the setting. See HANDOFF.md for verification.
- **cdx, 2026-10-26: Media Hub resume/size investigation** on `codex/mediahub-resume-file` (not released). Size parsing now includes stream names; preserve supplied filename/videoHash for hashed resume identity when links/descriptions change, reject structured byte conflicts, retain legacy matching. Safe `ArchiveResume` and `MediaFileInfo` byte diagnostics distinguish selection/fallback from popup metadata. User-specific 47GB->7GB cause needs reproduction log; do not claim confirmed. The separate drawer has since been merged locally from `codex/mediahub-stream-drawer`.
- **cdx, 2026-10-25: Media Hub source drawer** prepared on `codex/mediahub-stream-drawer` (not released): Right with player controls unfocused opens alternative stream files, provider/format labels and sizes; OK changes source at the current position. Shared drawer/session feeds Android and Windows; choices remain scoped to title/episode/viewer. See HANDOFF.md for verification and commit.
- **cdx, 2026-10-25: Discord help prepared locally.** `tools/discord_help_bot/README.md` documents a no-AI `/howto` app indexed from `docs/remote.html`; regenerate `guide.json` when the guide changes. Node HTTP and Worker adapters included. Not registered/deployed: hosting and Discord application setup pending. Release-announcement webhook is not a bot credential.

- **Prepared release: VesperTV 1.0.40 (beta), +449 (2026-10-25).** Owner requested
  the current integrated tree and Live now grid, APK + Windows, GitHub publication with
  (beta) in title and Downloader pointing to it. Publish as latest (not GitHub prerelease,
  otherwise Downloader/updater skip it). Source/provider outages remain separate known issues;
  no claim that TorBox service errors or every custom-source title are fixed.

- **Codex Live now grid (2026-10-25, codex/live-games-grid, unreleased):** Sports Trak
  Live now > See all uses the same _GameCard, width and Wrap spacing as Later today.
  SportsLiveListScreen retains polling, final-game retention, stats on OK, menu on hold and
  watch on Play/Pause; optional card builder replaces dense rows for the hub. Explicit D-pad
  moves by actual grid columns; partial last row remains reachable without horizontal wrapping.

- **Codex diagnostic follow-up +448 (2026-10-25):** LOG-9XBM8M finally captures the custom
  source with type AdultVideo, playable=0. Rendering has not started for this failure.
  Genre menu deliberately excludes genres of sources grouped under Other; Other alone does
  not prove a catalog/type mismatch (or a native-video problem). Source checks from desktop
  still succeed; device playback root cause remains unresolved. Log raw vs accepted catalog/stream
  counts, manifest counts even when unchanged, and short public lookup references (URLs and long
  opaque ids hashed). Refresh now includes mixed standard/custom catalogs, previously skipped.

- **Codex, 2026-10-25: custom Media Hub source investigation** (`codex/custom-source-refresh`).
  +446 owner log shows custom rows empty; exact playback failure remains unconfirmed.
  Owner clarified adult source says "No playable stream", distinct from Torrentio upstream
  TorBox-unavailable response reproduced outside the app. Same ArchiveApiService live test
  successfully fetched custom catalogs, full metadata and playable links; native surface untouched.
  Fix: custom-only source manifests update on open/explicit Refresh (previously only accepted
  transitions to stream-only). Preserve latest enable/Other choices, retain saved data on failure,
  do not resurrect removed sources; queued force refresh retains force. Hashed ArchiveStreams
  diagnostics distinguish empty options from HTTP failures without URLs/credentials.

- **Codex, 2026-10-25: Native video surface defaults ON** (`codex/native-surface-default`, +446).
  Missing device preference defaults to true in BOTH StorageService and MainActivity startup
  (transparent Flutter window must match Dart on the first launch). Explicit saved on/off choices
  remain unchanged. Owner requested hiding the Green flicker fix and Compatibility video
  switches from Settings; their stored preferences/device fallback logic remain intact.
  Playlist enabled D-pad fix is a1e8c38 (`codex/playlist-enable-focus`), included in this build.
- **Codex focus/history/storage batch** (2026-10-25, based on Claude +444):
  theme colour work explicitly on HOLD. Focus recovery uses concrete tab nodes;
  Home/Hub/Sports return to TV rail with guide closed. Empty/lazy movie entry
  retains a selector. Distant group/poster jumps defer focus until layout, with
  bounded retries invalidated by Back/tab/route changes. Return also clears the
  Timeline filter/keyboard. Playlist Manager Right enters details, Left/Back returns
  to selected playlist. Media Hub history hold asks Cancel/Remove in glass menu.
  Backup & restore imports M3U files and included Media Hub manifest sources
  from USB/external storage; owner clarified this scope instead of local-video
  collection import. Private M3U snapshots accompany backup/transfer and clean up
  with their playlist. See `dev-notes/external-storage-import.md`. Owner requested
  build/install on Formuler when complete; no GitHub/Discord publication.

- **Claude, 2026-10-25: Fire TV trailers + Trailers setting** (`claude/firestick-trailer`, on +442;
  test build **+444** installed on Formuler + Fire Stick): Fire OS's WebView draws `<video>` on its
  own native overlay (`SurfaceViewOverlayCore$NoPunchingSurfaceView`, seen in `dumpsys activity top`).
  Hybrid composition = black with audio (background and Trailer button, beta on or off); texture
  composition shows it but **above all Flutter UI**, so Fire TV plays trailers full screen. Texture
  mode only for manufacturer Amazon (`youtube_platform_view.dart`, getprop once); other devices keep
  hybrid. Toggle moved Theme -> Settings > Interface > **Trailers** with the note "On Fire TV sticks,
  the trailer plays full screen." (4 languages). Analyze 17, 481 tests. Formuler re-check pending.
- **Claude, 2026-10-25: Formuler zap frozen frame** (in Codex's +442 integration): Formuler 4K/HDR
  video is on a hardware plane that PixelCopy/screencap read as solid (0,150,0) green, so capture can't
  work. `NativeVideoSurface` keeps two SurfaceViews on the Z11 Pro MAX: a zap moves the decoder to the
  offscreen one, the old one stays on screen with its last real frame + spinner, swap 120 ms after the
  new first frame. Owner: "works well". Also guide `_ensureRowVisible` viewport guard (Back crash).
- **Known, not bugs (2026-10-25):** Multiview tiles can't show HDR (texture path): Formuler 4K tile is
  green, Shield tile washed out; full screen fine. Proposed: tiles prefer the channel's HD copy; owner
  is asking Sam to compare TiviMate Multiview first. Fire Stick 4K freezing = weak Wi-Fi (resolved).

- **Codex large custom Media Hub catalogs** (codex/mediahub-large-catalog,
  2026-10-25): owner confirms slow main horizontal rows under Other after refresh.
  Vertical browse used an eager Column: every catalog's poster strip stayed
  mounted/loaded, and focus rebuilt all rows. Use fixed-extent lazy vertical rows
  with one-row cache; row jumps materialize destination before card focus. Keep
  remembered horizontal positions and custom IDs/Other filtering. Sparse focus
  nodes avoid allocating every preceding card on distant jumps. Row headings are
  one line; Windows rail title is constrained to avoid overflow. Synthetic
  100,000-item/100-row regressions cover bounded posters, D-pad and distant jumps.
  This addresses a concrete scaling cost; the reported unexpected exit has no
  crash/OOM log yet, so its cause remains unconfirmed. Owner requests +442 build
  and Formuler install including preceding manager/popup changes. No publication.

- **Codex compact source popup** (codex/compact-source-popup, 2026-10-25):
  owner requests smaller Media Hub source/size cue, roughly three rows. Width
  320 -> 240 logical pixels, padding 16/12 -> 10/8, source/size text 15/14 ->
  12/11. Source wraps up to two lines above file size; same shared Android,
  Windows and in-app YouTube overlay, 5-second timeout and focus unchanged.
  No new strings, version bump, APK or install. Includes prior combined manager
  commit f5baae0 as its parent; local main still 6d05ae4.

- **Codex combined Playlist Manager** (codex/playlist-manager-panes, 2026-10-25):
  persistent playlist list and inline details on one route. D-pad highlighting
  selects details without enabling an account or changing playback; OK/click
  enters the details pane. Wide screens use a sidebar, phones a list above details;
  detail quadrants stack in narrow panes. Existing edit/delete, backup servers,
  groups, hidden channels and sync controls retained. Delete stays on this route
  and falls back to another playlist or the empty Add Playlist state. No new
  settings, strings, version bump or APK. Device acceptance pending.

- **Codex IPTV trailer shading/startup** (codex/iptv-trailer-shading, 2026-10-25):
  owner confirms Hub movie looks correct; IPTV has a rectangular brightness boundary.
  Wide movie/series retained backdrop gradients were bounded to a partial art panel;
  use full-viewport bounds to match the trailer. Keep same-title, same-URL preview
  alive when late metadata resolves rather than restarting its iframe. No deliberate
  startup delay; lookup/provider buffering remains. Local +441 test; hardware
  confirmation pending. See `dev-notes/automatic-detail-trailers.md`.

- **Codex trailer playback follow-up** (codex/trailer-playback-performance, 2026-10-25):
  owner reports +439 stuttering and no sound. Remove Opacity around the platform
  video (always painted, including preload); fade an ordinary Flutter cover and
  artwork instead. Enable audible automatic trailers; update all four languages.
  Local +440 test. Composition is a suspected cause, not a proved hardware fix;
  device acceptance pending. No native player or WebView composition-mode edits.

- **Codex trailer backdrop follow-up** (codex/trailer-backdrop-fade, 2026-10-25):
  owner tested +438 and requested full-page video behind poster/details instead of
  split preview. Retain original detail layout, 650ms artwork/video fade on playing,
  fade back at end/error, readable gradients; automatic iframe controls off and
  cannot steal focus. Manual Trailer player unchanged. Local test +439 follows;
  see dev-notes/automatic-detail-trailers.md for behavior and provider limitation.

- **Owner-requested Formuler test package (Codex, 2026-10-25):** build 1.0.39+438
  from the combined main integration. Analyzer baseline 17; all 472 Flutter tests
  pass; integrated native suite 134 pass. Signing/install result and artifact
  recorded in the main-checkout HANDOFF.md. No GitHub/Discord publication.
- **Owner-authorised local integration (Codex, 2026-10-25):** completed Codex stack plus
  Claude's device-defaults branch and source snapshot from claude/zap-freeze-surface
  integrated for main. Claude's snapshot retains version 1.0.39+437; no new package
  built, installed, pushed or released here. Formuler dual SurfaceViews retain the
  outgoing hardware frame instead of PixelCopy, plus guide viewport-dimension guard.
  Details and excluded historical experiments: dev-notes/merge-all-20261025.md.
- **Codex automatic detail trailers** (codex/automatic-detail-trailers, unbuilt, 2026-10-25):
  Settings > Theme > Automatic trailers, off by default, IPTV and Media Hub movies/shows.
  Muted direct-video backdrop; official YouTube preview beside/above details (uncovered).
  Cancel lookup/dispose on leave, background, error/end; await stop before Play/Trailer.
  No history/queue/native changes. dev-notes/automatic-detail-trailers.md; device test pending.
- **Codex Home game timezone fix** (`codex/home-game-local-time`, unbuilt, 2026-10-25):
  Home's game cards/backdrop and hero status formatted SportsGame.start as UTC;
  Sports Trak already converts to device-local time. Add toLocal at both Home
  format sites. Keep model/feed times UTC and existing 12/24-hour preference.
  No feed/cache change, hardcoded timezone or offset. No build/install/release.
- **Codex Media Hub selected-file cue** (`codex/mediahub-file-info`, unbuilt, 2026-10-25):
  OK on movies/episodes shows source label + reported file size in the top-right for
  5 seconds, independently of Data pool. Main-player taps and in-app YouTube controls
  show it too. Selected option metadata follows resume and resolved next episodes;
  redirect copies retain it in memory, never in channel JSON. Unknown sizes say so.
  Android/Windows players and Media Hub's in-app YouTube path included; external
  YouTube app cannot show our overlay. French/Spanish/Italian/Greek strings added.
  No build/install/release; Formuler remains +435 pending owner frozen-frame test.
- **Codex Expand Timeline guide** (`codex/expand-timeline-guide`, unbuilt):
  Android Theme > Live TV guide > Timeline > Full-screen video now has Expand.
  Off by default, saved on device like other guide layout preferences. On fills
  the guide area with rows and hides the floating programme card; filtering keeps
  its keyboard space. Grid state and Back preserved. No player changes; +435
  frozen-frame capture still awaiting owner test. No build/install/release yet.
- **Codex frozen-frame + spinner follow-up** (`codex/frozen-zap-spinner`, local test +435):
  owner confirms +434 covers green but dislikes logo on every zap. Prepare one recent
  720px-max frame on a worker while the Formuler channel plays, never wait during zap;
  display cached frame + small spinner until first frame. Reject dark/bright uniform
  green and blank captures; invalidate late results on source change/hide/dispose.
  Logo + spinner remains if capture unavailable. See dev-notes/frozen-zap-spinner.md.
  Actual 4K capture validity still needs the owner's box test; no GitHub publication.
- **Codex Formuler transition follow-up** (`codex/formuler-green-cover`, local test +434):
  +433 green-capture heuristic did not help. LOG-A44B6U shows no green rejection,
  capture callbacks after 180-224 ms on several zaps, and some source loads around
  4-5 seconds. Removed heuristic and skip PixelCopy entirely on this exact Formuler
  model: immediate existing opaque logo cover until first frame, no capture wait.
  Other devices retain last-frame capture. Decoder/HDR/reuse behavior unchanged;
  green origin still unproven, owner test required. GitHub publication still held.
- **Owner release preference (2026-10-24):** wait for an explicit request before
  publishing future updates to GitHub. Sports +432 stays local; public beta stays +431.
- **Codex Sports 4K default correction** (`codex/sports-default-4k`, local test build +432, unpublished):
  highest-quality preference now defaults on. Saved picks first, then matched 4K
  sources across broadcasters (not only copies of one channel); game cards and
  menus keep the same ordering after merging added sources. Explicit opt-out stays
  respected. Media Hub largest-file setting and episode resume remain unchanged.
- **Codex handoff batch +431** (`codex/handoff-fixes`, owner authorised all handoff tasks):
  merged Claude diagnostics/thread/guide fixes and subtitle-link routing, retaining Cinemeta toggle.
  Bounded indexed Sports title slices with shared caches/background literal matching; atomic
  matcher snapshots fix concurrent-index RangeErrors; saved picks persist; optional quality copies.
  Media Hub episodes remember their stream like movies; optional largest-file start per viewer.
  Home history hold removal; Sports frame uses actual constraints; private image/row diagnostics.
  Native Formuler-only Realtek-first renderer, equivalent-HDR metadata reuse, transient last-frame
  cover for decoder swaps; explicit new-playback surface handoff and Android 9 paused output fix.
  Hardware acceptance remains pending. See `dev-notes/handoff-fixes-431.md`.
- **Codex Cinemeta catalog switch** (`codex/cinemeta-catalog-toggle`, unreleased):
  Settings > Media Hub sources > Show Cinemeta catalog (default on). Off hides
  automatic browse/search rows; custom catalogs, stream add-ons and metadata
  remain available. Details: `dev-notes/features.md` (Cinemeta catalog visibility).
- **Combined native beta +428** (`codex/native-live-zap`): owner requested GitHub
  beta including Claude's `d87c688` prepare diagnostics, layered on the existing
  early-bind fix and newer live reuse. All pending theme/reminder/browse/episode
  work included. Analyze17, Flutter428/native104 tests pass; device results pending.
  Keep the existing beta tag/asset URL and prerelease status; stable unchanged.
- **Codex native live zap** (`codex/native-live-zap`, owner test +427):
  reuse the native live player's session/output across channel zaps; reset stats,
  recovery and metadata state, guard rapid A->B->A, fall back on failure.
  +426 preview log showed stable rect yet blackouts; actual improvement needs
  owner testing. Details: `dev-notes/native-video-surface.md` (Native live zap).
- **Codex native channel handoff** (`codex/native-channel-handoff`, owner test APK +426):
  bind native output before prepare, skip clear-before-release, retain rectangle
  while replacing a player; texture/beta-off unchanged. Includes pending browse,
  per-profile colours, compact reminders and Coming soon branches. Analyze17,
  Flutter426 and native96 tests pass; whole-TV blackout still needs box validation.
  See `dev-notes/native-video-surface.md` (Native channel handoff follow-up).
- **Codex episode Coming soon tag** (`codex/episode-coming-soon`, not packaged):
  future-dated IPTV/Media Hub episodes show a translated badge on shared series
  thumbnails (wide cards and phone list). Uses validated `EpisodeAiring` dates;
  unknown/invalid dates and date-only today stay unlabelled; playback unchanged.
- **Codex Movies/TV Shows native return** (`codex/browse-video-transition`, unbuilt):
  retain the playing native beta controller across browse tabs instead of disposing
  it; audio continues like Settings. Legacy parking and Home/Media Hub unchanged.
  See `dev-notes/native-video-surface.md` (Movies / TV Shows return follow-up).
- **Codex native beta follow-ups** (`codex/native-surface-fixes` 6222f16, included in beta +425, from
  `f1ceb95`): retain last surface rect beneath covering routes/transitions, seed
  decoder/format diagnostics from player creation/current format, and guard
  guide scroll resets/mirroring until dimensions exist. Details and device checks:
  `dev-notes/native-video-surface.md` (Codex fixes after Formuler +424 feedback).
- **Native video surface (beta)** (`claude/native-surface`, test builds `+423`/`+424`/`+425`;
  Codex follow-ups above included in +425): opt-in, restart-applied; main Android player in a plain SurfaceView behind a transparent
  Flutter view instead of the platform view. For AMD's Fire TV Cube (4K HDR10 decoded as 1080p SDR,
  LOG-CFN2FE) and Sam's NVIDIA Shield (green flicker; Compatibility video loses HDR). Tunneling test
  `+420` is not the fix. Full Send-log diagnostics (`NativeSurface:` / `VesperNativeSurface`).
  Design, risks, test checklist: `dev-notes/native-video-surface.md`. Codex takes diagnostics.
- **Codex, unreleased: independent profile theme colours** — `codex/profile-theme-colours`:
  viewer-scoped palette keys, one-time preservation of existing shared colours, and
  immediate theme reload on profile switch. Main key stays unchanged. Details:
  `dev-notes/features.md` (Per-profile theme colours).
- **Codex, unreleased: reminder card styling** — `codex/reminder-card-style`: prominent
  64px team crest, stronger faded background logo, accent border and time badge.
  Reminder timing/focus behavior unchanged. Owner confirmed 1.0.39 reminders work.
- **Release 1.0.39 (`+422`, 2026-10-23):** integrates the five completed Codex branches
  below: Windows Home Back arrow, player clock, all Open on startup destinations,
  per-game/automatic team reminders with faded-logo popup, and Media Hub movie
  resume from the selected stream. Tunneling test +420 is excluded. Native-device
  checks remain pending except the owner-confirmed Windows Home arrow.
- **Codex lower player bar clock** (`codex/player-bar-clock`, included in 1.0.39): current local time
  beside the channel/stream title on Android/TV and Windows (`widgets/player_bar_title.dart`),
  using the existing 12/24-hour setting. No player changes; native device check pending.
- **Codex Open on startup flash fix** (`codex/start-on-home`, included in 1.0.39): all destinations
  resolve before the first frame. Home/Media Hub/Sports use the initial route stack; Movies/TV
  Shows initialize the keyed TV root on the chosen tab. Keeps Back navigation, selected-tab
  focus, hidden-tab/crash fallback and Sports background-video workaround. Routing is in
  `utils/startup_routes.dart`; Fast startup/splash budgets unchanged. Native checks pending.

- **Codex, included in 1.0.39: game reminders** — `codex/game-reminders`: hold an upcoming
  My Teams/followed-team game > Remind me / Cancel reminder, or automatic reminders
  for every game from either followed team (30-minute foreground schedule refresh).
  Faded selected-team logo behind the popup text. Global non-focus-stealing
  popups 15 minutes before and at scheduled start while foregrounded, per viewer/device.
  Details and limits: `dev-notes/sports-tab.md` (Per-game reminders).
- **Codex, included in 1.0.39: Media Hub movie resume source** — `codex/media-hub-resume-source`
  saves the selected provider/file as viewer-scoped fingerprints, re-matches fresh
  stream links on resume, and falls back to alternatives if absent/unreachable.
  Details/limits: `dev-notes/features.md` (Media Hub movie resume source).
- **Shipped: 1.0.38 (`+419`, 2026-10-23, latest; test builds `+414`/`+416`/`+417` = pre-releases
  `1.0.37-test.*`, not deleted yet — owner OK needed):** Home page (profile cards that shrink
  while browsing rows, hero, Today's games: My Teams → starred league → rest, finals gone 60 min
  after ending, matchup backdrop), profile photos/editor/copy-from-Main and per-profile Media
  Hub + Recent channels, Networks remembered picks, EFL1/EFL2, Match frame rate/resolution +
  Stream HDR, Green flicker fix (test), in-app YouTube trailers (Cinemeta built in, never the
  title from a stream add-on), season mark-watched, next-episode air date, remote scrub bar,
  Extra small subtitles, Data pool Dolby Vision profile + fallback. Every bullet below marked
  Unreleased/Codex down to 1.0.37 is in it. **Open:** HDR10 on AMD's Cube; frozen frame while
  zapping (next).
- **Profile proposal (Codex, 2026-10-23):** portrait cards/hold-to-edit, LAN QR/local
  photos, new create/edit pages and opt-in independent copies from Main; season-wide
  watched/unwatched with one tracker batch per account. See `dev-notes/profile-cards-photos.md`.
  Includes the Hub-key/empty-recent-history isolation fixes also pending in Claude's
  checkout; review overlap when integrating. switchTo/applyActiveViewer unchanged.
  Native device acceptance pending; no build/push/release.
- **In-app trailers (Codex, 2026-10-23):** official YouTube IFrame on Android/Windows;
  user-installed add-ons only, Xtream supplied trailers first, strict IMDb identity. Direct
  trailers use transient normal-player channels (no history/tracking). See
  `dev-notes/external-trailers.md` for origin/Referer, WebView prerequisites and controls.
  Native playback/remote checks pending; no build/push/release.
- **Codex next episode air date** (`codex/next-episode-air-date`, unreleased): shared series
  header shows the next known airing from supplied episode dates, or exact-id TMDB (user key) /
  Cinemeta metadata. Hidden when unknown; no playback/watch-state changes. Details and limitations:
  `dev-notes/features.md` → Next episode air date. Not built or device-tested.
- **Unreleased (Claude, `claude/match-frame-rate`, 2026-10-23): Match frame rate / resolution**
  (TiviMate-style, AMD's Fire TV Cube request). Settings > Interface > **Display** (Android,
  device-only, off by default): Match frame rate (+ "Only switch between 50 and 60 Hz") and
  Match resolution. `services/display_match.dart`: as soon as frames arrive, declared fps
  (StatsBridge `frameRate`) else the first 16 frames' timestamps (vendored `FrameRateProbe`, a
  `VideoFrameMetadataListener`, median gap, StatsBridge `ptsFps`; ~0.3 s; was 2 s + 2 s of frame
  counting = "clunky" on AMD's Cube, LOG-HR6JNB) → `vespertv/display` `match` in app-side
  `DisplayModes.kt` (`DisplayModePicker`: snaps to 23.976/24/25/29.97/30/50/59.94/60; 25/30 →
  50/60 Hz, 24p kept unless 50/60-only; resolution = smallest mode holding the video) →
  window `preferredDisplayModeId`. Zapping keeps the mode; `PlaybackService.stop()` resets;
  Android restores it when the app leaves the screen. Send log: `DisplayMatch:` lines. Data pool
  got a **Stream HDR** row (StatsBridge `hdrKind`: DV / HDR10 / HLG / SDR — "Device HDR" is only
  what the box supports). Mode text logs as `3840x2160 50.00 Hz` (an `@` was redacted as an e-mail).
  Formuler: 1080p60 → 1080p50 confirmed. AMD's Cube: rate + resolution switch work; **HDR10 doesn't
  trigger** there (open: is the stream HDR? does HDR trigger with matching off?).
- **Codex unfolded Back tap fix** (`codex/unfolded-back-tap`, unreleased): owner reports
  visible header arrow does nothing on an unfolded Google Pixel 10 Pro Fold. Reproduced
  focus-dependent navigation in a widget regression: when the destination column cannot
  accept focus, `requestFocus` emits no column-change callback and the groups stay hidden.
  Header arrow/system Back now share `_handleBack`; non-TV Back explicitly updates visible
  depth as well as requesting focus. TV remote handling stays on its existing focus path.
  Full-video layout uses Flutter's target platform so Android tests on Windows exercise its
  fully hidden columns (the old dart:io Windows guard silently skipped that layout in tests).
  Coverage includes Android/Windows sizes, blocked focus for tap/system Back, folding and
  unfolding, compact portrait and TV. Actual Pixel device check pending; no build/install.
- **Unreleased (Claude, `claude/device-defaults`, 2026-10-23): automatic per-device defaults**
  (`services/device_defaults.dart`). Rules match getprop manufacturer/model/hardware/socModel/sdk
  and turn `hideVideoOnSports` / `compatVideo` on by default; a user's own switch always wins
  (storage getters return null = never set). Bundled list + `docs/device-defaults.json`
  (vespertv.app, fetched once per launch, cached in `vesper_device_defaults`; same id replaces a
  bundled rule, empty `set` disables). Settings shows "Automatic: on for this device."; Send log
  prints `Device defaults: …` + fingerprint. First entry: **Fire TV Cube 3rd gen `AFTGAZL`** →
  Background video (user report). **Keep the bundled list and the JSON in sync** (a test checks).
  Shield → compatVideo deliberately not added yet (Samiam23's Media Hub stall, HANDOFF).
- **Shipped: 1.0.37 (`+413`, 2026-10-22, latest; test build `+412` = pre-release `1.0.36-test.412`,
  deleted):** every bullet below marked Unreleased down to 1.0.36 (Codex batch: Data pool bottom
  panel, live group sort, 1/3/6 h content updates, favourite networks kept, live CC fit; Claude:
  Media Hub/Add-ons pages reach Add, Multiview Up hint). Notes in the release body.
- **Shipped: 1.0.36 (`+411`, 2026-10-22; test builds `+402`..`+410` = pre-releases
  `1.0.36-test.*`, deleted):** every bullet below marked Unreleased (Codex + Claude) down to 1.0.35.
  Notes in the release body. Fire Stick-tested by the owner at work (Networks crash fixed in +405).
- **Unreleased (Claude, 2026-10-22, `+412`):** the five Codex commits below are merged into main
  (fast-forward) + review fixes `15bfb57`. **Media Hub sources** and **subtitle Add-ons** pages
  are a non-lazy `SingleChildScrollView` + `Column`: with 11 sources the lazy ListView never built
  the Add field, so the remote couldn't reach it (user: "is there a limit?" — there isn't).
  **Multiview** (TV): a small Up-arrow tab at the top centre while the header is hidden, so users
  find the header (2/4-screen layout); touch keeps its tap handle.
- **Codex reverse-order fixes (unreleased, 2026-10-22):** four stacked branches above
  `551b5ed`: `codex/data-pool-bottom` → `codex/live-group-sort` →
  `codex/hourly-content-sync` → `codex/persist-favorite-networks` (tip contains all four;
  no main merge/push/build). **Data pool**: bottom panel, two side-by-side stats tables,
  bounded/scrollable on short screens; captions stack above its actual height. Existing OK,
  10 s timeout and setting preserved. **Live groups**: filter icon above Favourites (Up then
  OK), Provider order / Name A–Z / Name Z–A, device-only `vesper_live_group_sort`.
  Each playlist stays together, own groups sort separately; manual moves restore stored order;
  favourite channel order untouched. Remote tips updated; D-pad/persistence regression coverage.
  **Update content every**: adds 1/3/6 hours to existing day choices. Optional
  `PlaylistProfile.syncFrequencyHours` overrides legacy days; due check uses `syncInterval`.
  Absent field keeps old cadence; backup/transfer, unrelated profile edits, launch prompt and
  automatic-update decision tested. Playlist editor preserves interval and autoSync.
  **Favourite networks**: reproduced an older picker saving over newer favourites.
  `SportsChannelLists.save` preserves unedited sections and merges favourite additions/removals;
  captured viewer prevents a delayed save writing to another viewer. Existing JSON keys/ids
  retained; known/unknown cards, reopen, source picker, transfer and removal regressions.
  Networks hold menu uses Material for its translucent background (ListTile ink/debug warning).
  Real device checks remain for these four changes.
- **Codex caption follow-up** (`codex/live-caption-fit-timing`, stacked above the batch;
  owner approved starting it): embedded CC preserves explicit broadcast rows and scales down
  only when needed to fit the actual available width. Regression fixtures include 32-column
  Small captions, narrow parents, phones and accessibility scaling. Movie/file subtitles keep
  word wrapping. Incoming cue snapshots already replace text immediately: no Dart queue,
  debounce or roll-up accumulation found. Tests now assert replacement without advancing time
  and rapid roll-up snapshots without a backlog. The 1 s blank-only grace remains (new text
  cancels it immediately), as do Off/track/source/controller clears. Vendored player unchanged.
  Reported TSN1 speech lag is **not reproduced or confirmed fixed**: needs owner live-stream
  comparison of arriving cues and speech. No build/install/device test.
- **Codex unreleased sports ranking follow-up** (`codex/sports-ranking-measurement`):
  offline remeasurement in `dev-notes/sports-ranking-measurement/results.md` (current code vs flat
  cutoff, plus historical baseline). Found stale event feeds bypassing event-date checks through
  the team fallback: same date guard now applies there, and dates accept `8th Nov` / `Nov 8th`.
  Keeps undated team feeds and current dated events; no guide/user-pick change. Two regressions.
  No observed copy-identity collision in 104 reviewed groups. CFL November-event false suggestions
  removed; real TSN/RDS coverage still needs a fresh guide reaching Oct 23 23:00 UTC. No streams,
  account configuration, device operation, build or release involved.
- **Codex external trailers** (`codex/external-trailers`, unreleased): IPTV/Hub movies and
  shows share a handler-aware Trailer action. Supplied metadata -> user-key TMDB -> strict
  Cinemeta identity; no guessed first result. External YouTube app/browser only, no movie
  history/queue/tracking calls. `dev-notes/external-trailers.md`; device return checks pending.
- **Codex Sports Channels phase 2** (`codex/sports-channel-rules`, dependent on phase 1):
  filters including Unknown, user tag corrections, updating lists with manual overrides,
  game/team/league user sources and lazy More sources. Composite IDs and viewer visibility
  remain mandatory; see `dev-notes/sports-channels.md`. No stream probing or game-rights claims.
- **Codex Sports Channels phase 1** (`codex/sports-channels`, unreleased): Games/Channels
  within Sports Trak, conservative network categories, manual/group multi-select lists,
  viewer-scoped composite references, Backup/Transfer and viewer deletion. Shared Sports
  preview/fullscreen path; hold adds to list/versions. `dev-notes/sports-channels.md`.
- **Unreleased fix (Codex, `codex/fix-vod-favorites`, 2026-10-22):** Movie/series favourites now
  toggle from saved ids and synchronize browse copies. Saved favourites are resolved from the
  catalog independently of the 300/category browse cap (400-id query batches, per viewer), with
  hidden/allowed-group and enabled-playlist filtering. Search/Expand/detail stars read saved state.
  Ten regressions in `test/vod_favorites_test.dart`; investigation and fix notes in
  `dev-notes/vod-favorites-investigation.md`. Sony-specific user reproduction still unconfirmed.
- **Unreleased (Codex, `codex/favorites-channel-order`):** TV Favourites supports the existing
  hold OK → Move Up / Down mode in the live list and Timeline guide (unfiltered). Independent
  per-viewer order across playlists (`vesper_favorite_live_order`, composite channel ids), including
  favourited-group channels; manual order wins over playlist/A-Z defaults, new entries append.
  Provider/own-group order stays separate. Backup/Transfer carry the order. Remote tips updated.
- **Unreleased (Codex, `codex/wide-guide-back`):** Wide non-TV layouts (unfolded phones/tablets)
  show a header Back button when inside groups/content, using the existing PopScope handling.
  Full-video guide mode hid the side columns while only compact portrait had a touch Back arrow.
  Reopening columns now keeps their child layout wide enough during the animation (no row overflow).
  Six widget regressions cover wide sizes, portrait, fold/unfold and TV; real foldable check pending.
- **Unreleased (Claude, 2026-10-22, `+410`, on the Formuler; all Codex branches above merged into main):**
  **Restart-loop cap** (§9). **Live HLS host learning verified** (`learnHlsHost` sniffs first: one
  dead `.ts` answering with an error page marked its whole server as HLS, every other channel then
  failed "does not start with the #EXTM3U header" until restart — Romanian channels, Discord photo;
  `unlearnHlsUrl` retries a wrongly-HLS `.ts` once as TS; MANIFEST_MALFORMED gets the source-reply
  sniff; `test/hls_host_test.dart`). **Sports audit item 5** (`distinctCopiesFirst`,
  `channelCopyKey` keeps the region tag, drops 4K/FHD/HD…: 8 distinct channels, then their quality
  copies; `test/sports_channel_copies_test.dart`; not re-run through the audit harness).
  **`vespertv.app/apk`** (`docs/apk/index.html`): backup to Downloader code 1760256 when a network
  blocks go.aftvnews.com.
  **Movies / TV Shows rows follow the Expand catalog sort** (`utils/catalog_sort.dart`
  `CatalogSort`, shared with `GroupCatalogScreen`): `PlaylistSession._rowSort` reads
  `vesper_catalog_sort_vod|series`; cached loads pass `CatalogSort.orderBy` to
  `getVodCategory`/`getSeriesCategory` (ORDER BY before the 300 cap, so "Date added/updated" really
  puts the newest in the row), provider loads sort the full list before `take(300)`; a new sort in
  Expand calls `PlaylistManager.applyCatalogSort` (drops that tab's loaded rows, they reload).
  User request (Discord). `test/catalog_sort_test.dart` checks SQL order == Dart order.
  **Surround passthrough (Dolby Atmos)** — Settings › Interface › Audio (Android,
  `AppPreferences.audioPassthrough`, device-only, off by default; §9). Atmos had been impossible
  since 2026-10-07 (passthrough off for Multiview audio bleed); Discord user missed it. Multiview
  entry points stop the main player first, so Multiview never needs the switch turned off.
  **Sports banners** (`SportsBackdrop` in `widgets/sports_widgets.dart`): the picked league's logo
  (Sports Trak, not on "All") / the selected team's (My Teams) large and dimmed behind the page,
  sport icon without a logo; ≤512 px decode, static. No player photos (no source).
  **Subtitle size** (Small 0.8 / Normal / Large 1.25 / Extra large 1.5; last row of the Subtitles
  menu on Android + Windows; `AppPreferences.subtitleScale`, device-only): scales
  `SubtitleOverlay` and the Windows `SubtitleViewConfiguration.textScaler`.
  **Update automatically** (per playlist, `PlaylistProfile.autoSync`, Playlist Manager > Full
  Catalog Sync): `PlaylistManager.dueSyncIsAutomatic` skips the launch "Update content now?" when
  every due playlist has it on. **Open on** (Settings > General > Startup,
  `AppPreferences.startSection` tv/movies/series/hub/sports, device-only; `effectiveStartSection`
  falls back to TV when hidden): `TvHomeScreen._openStartSection` once per launch; with full-screen
  resume on and another section chosen, `_autoResumeLastChannel` plays in the background instead.
  **Sports rows**: still Live now / Later / Final (owner: keeps live first, D-pad friendly — the
  user asked for a row per league / a wrapping grid); `_byLeague` groups each row by the user's
  league order (My Teams games first), `_LeagueDivider` between leagues on "All"; rows of 5+ get a
  **See all** chip (`_headerChipStep` generalises Live now's chip; `_SectionGridScreen`, non-lazy
  Wrap, OK returns to the card in the row).
  **Sports Trak › Channels redesigned** (owner: "boring, looks like Settings"; hockey filter missed
  TSN/ESPN/Sportsnet/TVA/RDS): `services/sports_networks.dart` `kSportsNetworks` (league / sports /
  regional; most specific first — ESPN+ before ESPN, US SportsNet before Sportsnet; `sports` null =
  every sport) drives `SportsChannelLibrary` tags (a network adds the sports it carries),
  `category` and `groups` (one card per network: TSN 1–5 + copies, `compareNetworkChannels` order;
  an unknown sports channel gets its own card). Screen: hero (preview video or logo, now/next),
  rows My lists / League / Sports / Regional of `_NetworkCard`s with explicit arrows; OK previews
  the card's first (or held-picked) channel, OK again full screen, hold = pick a channel / add to
  list / Edit list. `test/sports_networks_test.dart`.
  **+404 Fire Stick crash fix** (opening Sports Trak froze/killed the app): the Channels page sat
  in Sports' `IndexedStack`, so it was built on every Games rebuild and took the focus; now built
  only while shown. Network/category/sort keys cached per `Channel` (Expando); rows rebuilt only on
  playlist/filter/list changes (`_dirty`). 20k channels: ~250 ms per rebuild -> ~30 ms once.
  **Start-section crash guard**: `vesper_start_section_pending` set while opening, cleared after
  15 s; still set at launch = open on TV that once.
  **+405**: +404 still crashed on opening Channels (log LOG-T9PWPS: no Dart error, the process was
  killed — memory). Card rows are now lazy `ListView.builder`s (`_cardStride`, `_focusCard`
  scrolls an unbuilt card into existence), and sports channels of no known network go to a last
  row **Other sports channels** (a big "Sports" group gave hundreds of one-channel cards). Renamed
  **Networks**, a chip beside Standings / My Teams (zone 2), not the league-bar text button.
  Separate, not fixed: that log shows repeated "database has been locked for 10 s" at startup.
  **+406 Search**: a Movies result (and an M3U show item) opens `MovieDetailScreen` (Play, Trailer,
  description) instead of playing; hold OK = favourite on every result row (live, movies, TV shows,
  Media Hub via `ArchiveService.toggleFavorite`) with the Added/Removed snackbar. Live channels still
  play on OK. User report: hold played the title.
  **+407 Networks**: Back = stop preview, else back to Games — the Games `PopScope` allowed popping
  while Networks showed, so Back left Sports Trak and the hero preview moved to the main player;
  Networks' `PopScope` never pops, the Games chip stops a preview first (`_leave`). The Games hero's
  preview carries into Networks (`initialPreview`). Hold menu = `_GlassMenu` (blurred, black 0.74)
  + **Favourite this network** (`SportsChannelLists.favoriteNetworks`, row "Favourite networks" on
  top). Patterns tightened: Tennis/Golf/MLS need the channel's own name ("TSN+ 01: ATP 250 Tennis…"
  was in Tennis Channel), TSN+ and Tennis+ are their own cards.
  **+408**: one Back from Networks returns to Games with the mini player still playing (it used to
  stop it, a second Back left). `SportsScreen._openNetworks` remembers the previewing game,
  `_closeNetworks` relinks the same stream to it, restores it if another channel was picked, and
  stops a Networks-only preview (the hero needs a game).
  **+409**: hold OK on the **All** league chip = roll-down (`_openLeagueMenu`, `showRollDownMenu`)
  of every league in the bar (owner, +410: ECHL/AHL were missing on a quiet day), "N games · N live"
  or No games, plus All
  leagues; with a filter on it fetches the day for every league. Remote tips updated (Networks).
- **Codex branch, unreleased: live caption readability** (`codex/live-caption-readability`).
  `SubtitleBridge` sends selected MIME/CC state, explicit resets on Off/track change and cue row
  coordinates; format-only diagnostics use logcat tag `VesperSubtitles` (no URLs/caption text).
  `SubtitleOverlay` allows CEA-608/708 captions 90% screen width (was 80%) and bridges empty
  updates for at most 1 second; repeated blanks do not extend the hold. Off, controller changes and
  downloaded subtitles clear the hold immediately. Timed non-CEA/add-on captions keep exact clears;
  per-series selection remains unchanged. Each CueGroup is a complete snapshot, not history to append:
  preserve its multiline text and order positioned CC boxes by row when coordinates are comparable.
  Widget coverage includes TV/phone sizes, blanks, source/track changes and downloaded captions.
  Owner's actual track MIME and improvement on a real live stream are still unverified; this does
  not add the separate subtitle font-size setting mentioned below. No build/install/release.

## 13. Status & open items (as of 2026-10-22)
- **Historical trailer research (Codex, 2026-10-22; superseded by shipped trailer work):** `dev-notes/trailers-research.md` covers IPTV + Media
  Hub movies/shows. Four public Cinemeta samples supply YouTube trailer IDs without a key;
  external Trailer buttons are the recommended first cut, optional TMDB fallback. No feature
  implemented; earlier external-only/on-hold decision remains. Embedded YouTube needs a separate
  platform spike/product decision; direct server trailer files are another playback kind.
- **Shipped: 1.0.35 (`+396`, 2026-10-22, latest; `+395` owner-tested on the Formuler; test build `+389` = pre-release `1.0.35-test.389`):** **Hide Recordings** (Settings › Tabs, `hideRecordings`, Codex `codex/hide-recording-tab`). Media Hub show page shows its source chip (`SeriesDetailScreen
  .sourceLabel`) and an hourglass on the tapped episode + Play while streams load (`_startingId`,
  extra presses ignored). **Add-on links resolved once before playing** (`services/stream_resolver.dart`
  `resolveRedirects`, `archive_playback._playUrl`; media servers skipped; `_track` keeps the original
  link for `ArchiveReadyWatch`): a 4K DV episode took 6.5 s to start on a Shield (user log) because
  every range request re-walked add-on → debrid API → CDN; measured on a TorBox remux 2.3 s → 0.65 s
  for 3 requests. **No endless retry on dead links** (§9). Shield user's 47 GB Carrie link was an
  HTTP 404 retried 18x. **Unplayable video no longer crashes the app**: a DV profile 5 episode
  (`dvhe.05.06`) on the Formuler (no DV decoder) went READY on audio alone and the platform view's
  `sendInitialized` NPE'd on the null video format (also seen on 1.0.30). `ExoPlayerEventListener
  .sendInitializedOrReportUnplayable` now pauses and errors with `[UNSUPPORTED_VIDEO: mime codecs
  size]`; `_friendlyPlaybackError` has a Dolby Vision message (owner-confirmed). DV profile 8 (and 4)
  already plays as HDR10 via media3's HEVC fallback; profile 5 can't; profile 7 could (not done).
  **CFL** in Sports Trak (Codex, merged). **Sports matching, audit items 1+2**
  (`dev-notes/sports-matcher-audit*`, harness on branch `codex/sports-matcher-audit`):
  `_usNetworkNames` (CBSSN, NFL Net, NHL Net, NBC Sports Phil, USA Net: US-tagged exact network
  only); `prepare` signature hashes every id/name/epgId (was count+first+last: stale index after a
  rename); `MatchReason.teamChannel` + labels say "no guide listing" for team-channel/broadcaster
  suggestions; `whyNoMatch`/`NoMatch` explain an empty game (only on a hidden channel — named;
  upcoming game's kickoff has under half the channels listed as now — `EpgService.guideCoverageAt`,
  not MAX(stop): a few week-long listings hid a 2-day guide; nothing names it), shown on the
  hero, game menu, live list and side panel. `prepare(hidden: playlist.hiddenLiveChannels())` at
  **every** call site (the signature includes it; mixing would re-index each time). Restricted
  viewers get no hidden list. Phone-installed `+395`; not box-tested.
- **Shipped: 1.0.34 (`+388`, 2026-10-21, latest; test builds `+386`/`+387` = pre-releases
  `1.0.34-test.386`/`.387`, `+388` owner-tested on the Fire Stick):** **list-only add-ons** (`ArchiveSource.listOnly`,
  stored `listOnly`): a manifest with movie/series catalogs on IMDb ids (or no idPrefixes) and no
  `stream` resource is accepted instead of "This source offers no streams" — rows from its own
  `/catalog/`, metas from Cinemeta, Play asks every stream-only source (same path as tracker lists).
  User's case: Streaming Catalogs (`catalog.ers.pw`, Netflix/Disney+/Prime/Apple TV+/HBO Max),
  verified live (10 rows, Cinemeta metas). `test/archive_list_only_test.dart`.
  **Global Search › Media Hub**: after the playlists' rows, a gold "Media Hub" heading, then its
  Movies / TV Shows (`ArchiveService.searchRows(underOther: false)` — no Other/adult content, doesn't
  touch the tab's own search state; 500 ms debounce; hidden with Hide Media Hub).
  **Unreadable-stream sniff** (Android, `PlaybackService._sniffUnreadable` + `sniffStream`): on
  ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED for a link the `.ts` rule doesn't cover, the first KB is
  read once per link: `#EXTM3U` = retried as HLS (`_hlsUrls`); JSON/HTML/text = the reply goes on the
  error as `[SOURCE_REPLY:kind HTTP n] text` and `_friendlyPlaybackError` shows it in plain words;
  a no-URL line goes to Send log. User case: Media Hub TV show via TorBox add-ons — couldn't reproduce
  with Torrentio+TorBox (10 episode/pack links all MKV). No stream picker = one stream, so likely a
  Jellyfin/Emby `.strm` library: a body that is only an http(s) link = `link`, played instead (address
  never shown/logged). Pre-release `1.0.34-test.386` has it. Windows: not done.
  **Add-on import** (`services/addon_import.dart`): the Media Hub sources link field takes many
  `manifest.json` links at once (`AddonImporter.linksIn`, even run together) — each checked, Media Hub
  sources saved in one go (`ArchiveService.checkSource`/`addCheckedSources`), subtitle-only ones go to
  Settings > Add-ons; summary dialog. **Import from Stremio** (`screens/settings/stremio_import_screen.dart`,
  `StremioAccount`): QR + 4-letter code from `link.stremio.com/api/v2/create`, poll `/read` every 3 s
  (error 101 = not signed in yet), `api.strem.io/api/addonCollectionGet`, checklist, then `logout`.
  Built-ins (protected, Cinemeta, 127.0.0.1) skipped. Undocumented Stremio API; the signed-in `/read`
  shape (`result.authKey`) — **owner-verified on the Fire Stick (2026-10-21)**: real sign-in, list, Streaming Catalogs added. Nuvio: needs
  Nuvio's Supabase anon key (`api.nuvio.tv`) — owner chose not to ship it (2026-10-21); paste links instead.
  **Expand catalog remembers its sort** per category (`vesper_catalog_sort_vod|series`, shown beside
  the Sort icon; a saved TMDB sort re-runs its lookups). **Data pool on VOD** (Android): OK on a
  movie/episode (provider or Media Hub) opens the Data pool card alone when the setting is on.
  **Quality badge uses width too** (`qualityLabelForTrack`): 3840x1600 films were "HD", 1920x800 had
  none. `test/video_quality_test.dart`. Not done: subtitle size setting (asked by the same user).
  **Player buffer budget** (§9 `BufferBudget.java`): a 4K remux ANR'd the 1.7 GB Fire Stick (whole
  device out of memory, kswapd 82 %, VesperTV killed as not responding). Under 2.5 GB RAM the main
  player caps its buffer at 64 MB, texture players at 32 MB. Owner: a 4K Spider-Man remux then
  played well (tiny lag at start); memory log: app ~320 MB PSS, device free RAM low point 55 MB.
  **`AGENTS.md`** added: Codex (or any agent) reads it first; it points here.
- **Shipped: 1.0.33 (`+385`, 2026-10-21; Formuler-tested):**
  - **Media Hub Ready tag** (`services/archive_ready_watch.dart`): a Media Hub stream under 90 s is a
    source's "being downloaded" clip — no resume point, no Trakt/Simkl scrobble, no auto-advance;
    on leaving the player the title is queued (persisted, device-only `vesper_hub_ready_watch`),
    checked every minute for 24 h; poster shows outlined **Fetching…**, then gold **Ready**
    (cleared on the next play). Ready = the user's debrid account lists the URL's 40-hex torrent
    hash as finished (`services/debrid_api.dart`, Real-Debrid `/torrents` + TorBox `/torrents/mylist`,
    keys in Settings > Media Hub > **Debrid accounts**), else the same URL now serves ≥50 MB and ≥4×
    the clip (Torrentio: clip `videos/downloading_v3.mp4` 0.1 MB vs TorBox CDN file). Owner saw
    Fetching… on the Formuler; the Ready flip itself not yet seen on a box.
  - **Big Sky Football / Basketball** (League bank › **College**): `SportsLeague.espnGroup` adds
    `groups=` (scoreboards) / `group=` (standings) to ESPN's whole-sport feeds (20 = Big Sky football,
    5 = men's basketball; verified live). Any other conference = one entry.
  - **AHL + ECHL** (Hockey bank, TheSportsDB 4738 / 4916, no tables). AHL matched on the Fire Stick.
  - **Remote tips**: site page `docs/remote.html` (tabs per screen, search, print = PDF), linked
    from the site nav + How to use it; Settings > General > Remote tips = QR to it. Update the page
    whenever a hold menu or remote move changes.
- **Shipped: 1.0.32 (`+384`, 2026-10-21; test build `+383` on the Formuler + Fire Stick):**
  - **Recording (Android only)** — Sports Trak games (game menu `_recordTiles`: "Record until the
    show ends" / "Record until I stop it", 4 h max) and live channels (hold menu), margins 5 min
    before / 30 after, **auto-record ONE team** (all its leagues). Native `RecorderService.kt`
    (foreground service, wake + Wi-Fi lock, HLS loop, `LiveTee`: watching the recorded channel
    plays `127.0.0.1` so both share one provider connection) + `RecorderScheduler.kt` (exact
    alarms `USE_EXACT_ALARM`, `BootReceiver`, channel `vespertv/recorder`). Dart
    `services/recording_service.dart` (device-only `recordings.json`), Recordings tab row
    (`screens/recordings_screen.dart`: game cards = both teams, **never the score**; channel
    card = logo + program at start), Settings > Recording (app storage or USB/SD), conflict popup
    when the account's connections are used. 20 GB cap, stops at 1 GB free (start needs 1.25 GB).
    **Red REC cue** (`widgets/rec_cue.dart`): dot by a recording channel on the live list +
    Timeline guide corner, "● REC" pill before the player badges, on Sports game cards (outlined
    dot = scheduled) and beside the hero's status. Fire Stick-verified: record, tee, stop,
    playback with seek. **Unverified:** scheduled start with the app closed / standby,
    HLS-behind-.ts, USB/SD, conflict popup, auto-team over days, the REC cue on a box.
    Notification text is English only. Windows: no recording.
  - **Send log** (Settings, `services/app_log.dart` capture zone + `redact`,
    `send_log_screen.dart`) → `POST pair.vespertv.app/api/log` → owner's private Discord channel
    (relay `_log_post`, webhook only in root-only `/etc/pair-relay.env` `PAIR_LOG_WEBHOOK`).
  - **NBA channel matching** (`_networkAliases`, `_callSign`, team channels step 2b): 11/11 on the
    Fire Stick. **Menus:** `widgets/tv_dialog_option.dart` replaces every `SimpleDialogOption`
    (gold focus row, `SwallowHeldActivate` — a held OK on a focused first row activated it), TV
    forces the focus highlight (`alwaysTraditional`); Formuler + Sony CEC remote recheck pending.
- **Shipped: 1.0.31 (`+382`, 2026-10-21; test builds `+374`..`+381` on the Formuler and
  the Fire Stick, all owner-tested):**
  - **Own live groups** (`services/user_groups.dart`, `UserGroups` owned by `PlaylistManager`,
    key `nox_my_groups` **per viewer, across playlists**; moves keyed by `Channel.id`, own channel
    order across playlists). Hold OK on a channel → **Move to group…** (own groups, New group…,
    Back to <provider group>) / **Remove from {group}**; hold on any live group → **New group…**;
    hold on an own group → Move Up/Down, Move to Top, New group…, Delete. Own groups are rows
    under Favourites/History (`_myGroupsId` sentinel) and are never hidden with a playlist (a
    first per-playlist version was — owner test). Sessions only know `myGroupOf` → `liveGroupOf`;
    the loaded `Channel.group` stays the provider's. TV group selection is **by title**, so own
    group names are made unique against provider titles. Not done (owner: fine as is): hiding an
    own group, Search by own group, kid-profile allowlist.
  - **Settings = left panel + right pane** (`settings_menu_screen.dart`): Playlists & guide /
    Media Hub (sources, Add-ons, Trakt & Simkl, TMDB) / Interface (Theme, Tabs, Background video,
    Data pool, Favourites, Multiview, Resume reminder) / General (Language, Startup, History) /
    Device & data (Transfer, Backup, Updates). The focused category's description + rows show on
    the right; Right/OK enters, Left/Back returns (each column its own `FocusScope`, plain default
    Up/Down inside); phone = list → category page. `GeneralSettingsScreen(sections:, title:)`
    shows one section without its header.
  - **Fast startup** (opt-in, §10).
  - **Data pool** (Settings > Interface > Data pool, off by default): OK on a live channel opens a
    second card with resolution, fps, codecs, declared + measured bitrate, variants, audio tracks,
    buffer, HDR, dropped frames, playing-for timer (`widgets/data_pool_card.dart`, native §9).
    Never shows the server host; no channel probing.
  - **Black-flash fix** on channel change (`PlaybackService.switching` + `VideoPlayerPane`
    spinner; `switching` is set before `_teardown()`, `currentChannel` is not).
  - **Greek football club names** (`greekBroadcastNames`, 197 clubs) — confirmed by Black1914.
  - **Media Hub**: the floating bar starts with **Search** (+ Clear); rows no longer lose the
    selector after ~15 Rights (`_cardExtent` missed PosterCard's own 6 px padding → 12 px short per
    step; now exact + `itemExtent`).
  - **Transfer** already carried all Sports Trak data (test proves it); its text now says so.
    Settings row subtitle: "Copy all of your data to another device".
  - **Faster channel changes: not done.** The main player already starts at
    `bufferForPlaybackMs` 500; time each step on the Fire Stick before changing anything (reusing
    one ExoPlayer would be the big win — ask first).
  - Site: dedicated Sports Trak / Media Hub sections (`#sports`, `#media-hub`) + new screenshots.
    Never show a piracy add-on's name in a site screenshot (the Media Hub shot's source chip was
    painted out).
- **Shipped: 1.0.30 (`+373`, 2026-10-20, latest; test `+372` = pre-release `1.0.29-test.372`,
  confirmed by the Greek user — Nova Sports found):**
  - **Greek-only guide titles:** Strong8K's Nova guide says `Live: Μπάσκετ: Χάποελ Τελ Αβίβ -
    Βίρτους Μπολόνια` (EuroLeague only in the description, which isn't searched).
    `greekForeignTeamNames` (greek_sports_names.dart): 19 EuroLeague clubs' Greek spellings from
    Nova's listings, same shape as the Greek clubs; `greekTeamFor` searches both lists.
  - `_foldAccents`: č ć š ž đ ş ğ ı ł ą ę ń ś ź ż ő ű ř ě ů ț ș ă ("Beşiktaş" split words).
  - **App language Greek → GR channels rank first** for every league (`_languageTags`, +20 like
    `homeTags`). Only Greek: the other languages' viewers mostly watch North American feeds.
  - Strong8K test account for guide checks: the disabled "dom OG" playlist in the Windows app.
- **Shipped: 1.0.29 (`+371`, 2026-10-20, latest; test builds `+369`/`+370`, pre-release
  `1.0.28-test.370` for a Greek Discord user) — released before that user finished testing
  (owner: best we can do for now):**
  - **Greek:** UI language `lib/l10n/el.dart` (machine-authored, not native-reviewed); leagues
    Super League 2 (`gre.2`), EuroLeague, Greek Basket League (TheSportsDB; basketball has no
    free tables → `hasStandings: false`); `SportsLeague.homeTags` ranks a league's own-country
    channels first; `greek_sports_names.dart` transliterates Greek guide titles and maps 23 clubs.
  - **TheSportsDB day cap:** the free `eventsday` returns at most **3 games per league/day**
    (SL2 user: games missing). A capped day now loads its whole round(s) from `eventsround`
    (uncapped) and keeps that UTC day. `eventsseason` caps at 15 and `eventsnextleague` at 1.
  - **Matching:** `sportsDbShortName` strips BC/SK/FC/Basket/Baloncesto/Pallacanestro… (feed
    names never matched guides); EuroLeague `seriesPhrases` incl. raw Greek spellings — team
    leagues accept a series-only guide title unless it names another game. Unconfirmed on a
    real Greek guide (Nova Sports).
  - **Box score** (`_BoxTable`): trailing columns that don't fit are dropped, names keep 96 px
    (NBA's 7 columns overlapped the other team on the Formuler). Owner-checked.
  - **Windows:** Media Hub detail had no back arrow at wide widths — arrow at every width + Esc.
    Owner-confirmed.
- **Shipped: 1.0.28 (`+368`, 2026-10-20, latest; test builds `+361`..`+367`, pre-release
  `1.0.28-test.362` for a Fire OS 6 user):**
  - **Sports Trak:** Romanian Liga I/II, Croatian HNL, Serbian SuperLiga, Bulgarian First League
    from **TheSportsDB** (`SportsLeague.sportsDbId`, `services/sports_db_source.dart`; ESPN has
    none of them, its `rou.1` is frozen in 2025). Free public key `123` (shared, not a secret).
    Free tier: day's games + scores, next game, **top 5** of the table, no live minute/box
    score. Rate limit ~10 quick requests then 429 with a growing `Retry-After`, so one day per
    league (not 3), a token bucket in `SportsDbSource.get`, live refresh 2 min.
  - **HLS behind a `.ts` URL** (Strong8K via `live.flixnest.app`): `.ts` 302s to an `.m3u8`, and
    ExoPlayer picks its reader from the URL → ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED.
    `learnHlsHost` retries once with `formatHint: hls` and `streamController` opens that host's
    live `.ts` as HLS for the session (player + Multiview). Owner-confirmed on the Formuler.
  - **Compatibility video** (Settings > General > Background video, `AppPreferences.compatVideo`,
    device-only): main player as a **texture** instead of the platform view. Default on for
    Android 7 and older (`DeviceTypeService.sdkInt`): a 1st-gen Fire TV Stick 4K (Fire OS 6.7)
    showed the picture twice, stripes, and the guide stuck on screen after Back. Unconfirmed
    (the user hasn't tested yet). Texture players use Multiview's buffer policy (§9).
  - **Media Hub:** Favourites row per category (hold OK on any poster toggles; Recently watched
    keeps hold = remove), `keyArchiveFavorites`; **stream-only regression fix**: an IMDb stream
    add-on with only custom-type catalogs was read as "own catalogs" since 1.0.24 (only its row
    under Other) — it's stream-only again (Cinemeta grids), stored sources re-checked once per
    launch (`_recheckCustomOnlySources`); custom-only add-ons without IMDb streams stay in Other
    (owner-checked with an adult add-on). **Whole source under Other**: an own-catalog add-on
    with any custom-type catalog (`ArchiveSource.autoOther`) goes entirely under Other — its
    plain "series" shows too (adult add-on report), TV Shows gets an Other filter — and every
    add-on source has a **"Show under Other"** switch (Settings > Media Hub sources,
    `otherChoice`, stored as `other`) so either direction can be undone; Refresh after changing.
    Floating bar under Other starts with **Back to main**. PosterCard's InkWell focus highlight
    is off (it showed as a stray box under the zoomed card). Owner-confirmed.
  - **Real 4K tag** (`services/real_4k_channels.dart`, `widgets/real_4k_tag.dart`): a live
    channel that decoded at 2160p (Android at 4 s / 12 s, Multiview at 6 s, Windows from mpv's
    height) gets a gold 4K tag on the live list and the Timeline guide (corner badge); lower
    playback removes it. Never from the name. Not in search / side panel yet.
  - **Windows:** volume slider + mute in the player bar (M key too), remembered per PC
    (`keyDesktopVolume`/`keyDesktopMuted`). Owner-confirmed.
  - Playlists menu eye icon on non-TV devices (owner-confirmed on the phone); `/pickup` command.
  - **Trailers: on hold** (owner). Only safe way = open the YouTube link in the YouTube app /
    browser, button hidden when nothing can open it; never extract YouTube streams in-app.
- **Shipped: 1.0.27 (`+360`, 2026-10-20, latest; test builds `+351`..`+359` were on the Formuler and
  the Fire Stick):** playback error codes on screen (§9); hold OK on a live channel
  (guide or list) = menu with **Move Up / Down** inside its group (`PlaylistSession.moveChannel`,
  `nox_channel_order`; the plain list's hold now opens that menu instead of favouriting);
  Settings > General **collapsible sections** (`_section`), **Mix playlists in Favourites**
  (A-Z across playlists), **Background video** opt-in (§10); **Backup & restore** (§3; Android
  11+ can't list another install's files, Fire TV has no file picker — only Fire OS 7 sticks see
  old backups after a reinstall); Media Hub sources show "Use the Other filter…" under sources
  with custom-type catalogs; Jellyfin/Emby **From phone** (`PairingKind.mediaServer`; it and the
  link kind are **Wi-Fi only** — the relay's deployed pair.html predates them, redeploy only if
  the owner asks); Media Hub **hold a row button = roll-down menu** (Expand catalog =
  `screens/archive_catalog_screen.dart` grid, Go to row); groups column **Playlists ▾** row under
  History (What's New/Favourites/All in Movies/Shows): jump to a playlist, Right = **Hide/Show
  that playlist's groups in this tab only** (`keyHiddenPlaylistGroups`, per viewer, channels stay
  in Search/Favourites); Multiview stuck-focus fix (§10). Owner said "very good" to the menus,
  From phone and the jump; owner confirmed the Multiview fix and Backup save + restore on the Formuler (2026-10-20). Unconfirmed: restore after a full uninstall, error screen, move, Windows.
- **Open (2026-10-19 evening):** no real Trakt/Simkl account has signed in yet (all mock-tested +
  live endpoint/client-id checks) — first user reports are the real test. Jellyfin only
  mock-tested (owner confirmed a real Emby server). Windows Multiview has no header-overlay /
  full-screen fade (hover controls instead) — do it only if asked.
- **Shipped: 1.0.26 (`+350`, 2026-10-19, latest, commit `e3c3f51`):** every text field gated + guard test (see §10, Fire TV report).
  **Multiview header = overlay** (user report: it squashed the 2x2): grid fills the screen; header
  slides down on Up from the top row (`_onGridKey` → `_revealHeader(focus: true)`, `_headerFirst`),
  Down returns to tile 0, hides 1.5 s after focus leaves (`_headerScope` listener), shown 4 s on
  entry; touch/mouse get a top-centre handle. Multiview **full screen**: name + back arrow fade
  after 4 s, any key/tap reveals; while hidden the first OK only reveals (Back always works).
  **Trakt/Simkl read-back** (`services/tracker_sync.dart`): history (watched episodes per show,
  watched movies, paused items; Trakt `/sync/watched/*` + `/sync/playback`, Simkl
  `/sync/all-items/... extended=full` + `/sync/playback`) cached 5 min, merged across accounts,
  matched by IMDb (Media Hub) or provider TMDB id (IPTV `Channel.tmdbId` / `XtreamSeries.tmdbId`)
  and written into the saved positions (only fills in: never clears a mark or overwrites a local
  resume). Unknown length → `StorageService.setResumeFraction` (1e6 scale + flag; `PlaybackService`
  converts on start). Applied on opening a series/movie page and to the whole VOD catalog 20 s
  after startup / on connect (`syncCatalog`). "Continue watching on Trakt/Simkl" rows (`*.playback`,
  re-derived for old accounts in `ArchiveService.sources`). IPTV plays now scrobble too (TMDB),
  hold-OK episode toggle pushes to `/sync/history(/remove)`. IPTV *shows* don't join the TV tab's
  Continue Watching until opened once (episode ids need `get_series_info`). Mock-tested + live
  401 path checks; no real account yet.
- **Shipped: 1.0.25 (`+349`, 2026-10-19)** — everything in the next bullet (was the
  "unreleased" list). Owner trusted the mock tests; real Trakt/Simkl sign-in still unconfirmed.
- **1.0.25 contents:** Multiview quad tiles **fill** their quarter
  (`_MaybeAspect`, no aspect lock — owner: black side bands on a landscape phone); **portrait
  phone = always 2 screens** (`_portraitDual`: toggle hidden, screens 3-4 paused, audio moved).
  Picker **Live now** = one row per game, OK opens every matched channel
  (`widgets/game_channel_chooser.dart`), the choice saved as the game's pick
  (`MultiviewSports.rememberPick` → Sports Trak uses it too). **Tennis** (`SportsKind.tennis`,
  `_parseTennis`: main-draw singles only, score = sets won, matched like fights) — ATP + WTA,
  and **NCAA men's/women's soccer** in the league bank. README rewritten for the universal player.
  Game stats **Goals** section now lists every hockey goal (from ESPN `plays`, type `goal`:
  period, clock, scorer, assists, running score) — the box score keeps only the top 3 per position,
  so a 4-0 showed two scorers (owner photo, 2026-10-19).
  **Trakt & Simkl** (Settings > Trakt & Simkl, `screens/settings/trackers_screen.dart`,
  `services/tracker_api.dart`, `services/watch_tracker.dart`): device-code sign-in (code + QR on
  the TV); an account is an `ArchiveSource` with `tracker` (`TrackerLogin`) whose catalogs are its
  lists (Trakt watchlist/trending, Simkl watching/plan-to-watch) by IMDb id, metas from Cinemeta,
  Play via stream-only add-ons. Scrobbling: `playArchiveTitle` registers the channel →
  `PlaybackService.play`/`_teardown` and `DesktopPlayerScreen` report start / stop (≥80 % = watched,
  else pause). Jellyfin/Emby items carry `ProviderIds` IMDb (`ArchiveMeta.imdbId`). **No secret,
  no relay:** the Trakt app (developer.trakt.tv, owner's GitHub-linked account, Production,
  redirect `https://vespertv.app/trakt`) is a public client — device token + refresh take only
  `kTraktClientId` (verified against the live API 2026-10-19). Simkl = **AUTH V2** app of type "TV,
  devices & command line" (V1 /oauth/pin retired ~2027; V2 = `POST /oauth2/device` + `/oauth2/token`
  device grant, 7-day tokens refreshed with the client id, QR opens `verification_uri_complete`); both client ids set (verified live). Credits: Settings footer + Trakt & Simkl screen +
  README "Credits". Mock-tested plus a live Trakt device-code check; no real sign-in yet.
- **Shipped: 1.0.24 (`+348`, 2026-10-19).** Archive/Extras tab renamed **Media Hub**
  (user-facing only; code/files/keys still `archive_*`); site repositioned as a "universal media
  player"; add-ons with their own catalogs of any type/ids (Other filter); **Jellyfin / Emby**
  sources (see §10 REST/JSON); Multiview name bar auto-hides after 4 s (`widgets/auto_hide_overlay.dart`,
  it covered the NHL score bug; speaker dot bottom-right meanwhile) and the Multiview picker got
  **Live now** (Sports Trak games playing now + matched channel) and **Sports** shortcuts
  (`services/multiview_sports.dart`; Windows: chips). Also live CC captions, decoder fallback,
  ANR fix on 4K release, `TvTextFieldGate`, Fit/Fill screen, parking live on Sports/Settings/Search.
- Donations will go through GitHub Sponsors (pending approval). After approval: `FUNDING.yml`,
  site/README links and an About row. Relay `X-VesperTV-App` enforcement (`PAIR_REQUIRE_APP=1`) is
  ON since 2026-10-17 (service file backed up on the VPS as `pair-relay.service.bak-*`).
- **Shipped: 1.0.23 (`+346`, 2026-10-18).** +340 (owner: "perfect"):
  Extras rail is now only Movies / TV Shows / Refresh / Extras sources; the row jumps (Popular /
  New / Featured / Recently watched, not search results) moved into the floating bar before
  Search + Genre (`_barRows`, `_barRowNodes`; bar scrolls sideways, `_focusBarNode` keeps the
  focused button visible; Up from a row lands on that row's button). The "big library" crash
  reporter says his library now loads fine (not reproduced by us; the lazy-rows idea stays a
  fallback if it comes back).
  **+342:** picker sheets scroll (Audio Track was a plain Column, ran off screen with ~12 tracks;
  subtitle sheets not lazy so the autofocused language exists; `TvMenuTile` reveals itself on
  focus, `test/menu_sheet_scroll_test.dart`). **Channel-change flash fixed** (owner-confirmed on the
  Formuler): `PlaybackService.play` now notifies + waits a frame and 250 ms *before* `play()`, so
  the platform view's surface exists first — playing surface-less then attaching mid-stream made
  the box's decoder restart (one frame, black until the next keyframe, picture).
  **+343:** the old phone `HomeScreen` is **gone** (+ its orphans `sidebar`, `channel_list_tile`,
  `mini_player_bar`); `TvHomeScreen` is the only home, Settings > Theme > Layout = Auto / TV
  (a saved 'phone' reads as 'auto'). Portrait phone bottom bar always has **Extras** (after the tabs,
  before Sports Trak; Hide Extras removes it) and the More page no longer lists it.
  **+345 (phone, owner: "very good"):** fullscreen player on touch: a left-edge tab (with the bars) and
  swipe right open `PlayerSidePanel` (live only), swipe left / tap the video closes it, panel max
  88% wide. Landscape touch Pull stats = full height right against the panel, 64 px tap-out strip
  on the right, `useSafeArea: false` (TV unchanged). **Taps on a video:** a `GestureDetector`
  *around* the platform view never fired on a phone — use `widgets/video_tap_layer.dart` (invisible
  layer *over* it): TV-tab preview (off while the pane shows an error) and the Sports hero
  (tap = `_play` full screen, also Windows click).
  **Windows (+346):** sidebar **Windowed / Full screen** row (`services/desktop_window.dart`, live
  switch, remembered with the window bounds, both keys skip Transfer). **window_manager gotcha:** an
  app *started* full screen saved its style before the first show (no `WS_VISIBLE`), so
  `setFullScreen(false)` hid the window (frozen ghost frame, window-less process, style
  `0x04CF0000`) — `show()` right after fixes it. Fullscreen player: `PlayerSidePanel` (tab on the
  left edge, Left key when the bar isn't focused, Esc / click closes, `onPlay: _switchTo`); Pull
  stats on Windows = its own card (≤980 wide, 88% high) beside the panel, not the phone layout.
- **1.0.22 (`+339`, 2026-10-18):** Extras **genre filter**
  (Search + Genre in a floating pill at the top centre, per category — owner didn't want them in the
  rail with Movies/TV Shows; Up from the first row reaches it; genre picker + search are `_FloatingPanel` dialogs in the same style; **Recently watched** row per category from `ArchiveService.recordWatched` (on play, `vesper_archive_history`, hold OK = remove) and per-category **recent searches** (`vesper_archive_recent_searches`), both Extras transfer keys. Open: a user's "big library" source sent the app to the launcher — not reproduced; suspect memory: every row is built at once and each catalog fetches 2 pages: `ArchiveCatalog.genres` from the manifest's `genre` options, Cinemeta's
  list for provider rows, `withGenre`; "New" hides while a genre is picked; genre labels translated
  under `genre.` keys — "History" alone is watch history). **Favourite league** (League manager: hold
  OK on any of your leagues = menu: favourite on/off, send back; per viewer
  `vesper_sports_favorite_league`, `favoriteSportsLeague()`): Sports Trak opens filtered to it, its
  live games lead the side panel's Live now. **Pull stats**: hold OK on a game in the fullscreen side
  panel = `SportsGameDetailsDialog(overStream:)` see-through, right of the panel (hold = key repeat,
  like `HoldToActivate`). Phone tab bar labels scale down (FittedBox) instead of "Sports T…". Portrait
  phone: the resume pill hides while the TV preview shows (`_syncPreviewHint`, released when a
  screen is pushed). **Windows parity:** one-row player bar (`DesktopPlayerScreen._buildBar`),
  subtitles (`widgets/desktop_subtitles.dart`: file tracks + add-ons + per-series memory, media_kit
  draws them; Settings > Add-ons now shown on Windows), Sports hero mini player via
  `DesktopMiniPlayer` (second click/Enter = hero, again = full screen on the same session, Back
  returns to the hero). Owner tested the Android side on the Formuler; Windows untested.
- **1.0.21 (`+335`, 2026-10-18)** — **Extras tab** (code name
  Archive: `archive_*` files, `ArchiveService`, storage keys unchanged): user-added Stremio-schema
  add-on sources; a stream-only source on IMDb ids gets Popular / New (this year) / Featured rows,
  search and metas from Cinemeta (`ArchiveCatalogProvider`), Play asks every stream-only source's
  `/stream/` and shows "Choose a stream" when there are several (direct http(s) only). Shows open
  the regular `SeriesDetailScreen` (its `loadEpisodes`/`playEpisode`/`showFavorite` hooks, see
  `archive_playback.dart`); episode queue = URL-less placeholders resolved when due
  (`PlaybackService.setUpNextQueue(resolve:)`, `DesktopPlayerScreen.resolveQueued`), keeping the
  picked source + stream name. Search = server + loaded rows, word-prefix ranked
  (`ArchiveService.rankSearch`). Rows page in as focus nears the end (own scroll controller per
  row — focusing an unbuilt lazy card does nothing). Back from the rail fixed (PopScope canPop was
  stale). Extras sits under TV Shows in the tabs column; Settings > General > Tabs: Hide Extras,
  **Hide Multiview** (row + player button). Transfer: "Include Extras tab data" (off = payload
  marker, receiver keeps its own Archive keys). Phone "send a link" (`pair.html` `#…link`) is
  **Wi-Fi only on purpose** (owner, 2026-10-18): the VPS relay's `pair.html` is deliberately
  left without link mode — don't redeploy it unless the owner asks (revisit if users request it).
- 1.0.20 (`+330`, 2026-10-17) — the Sports tab is renamed
  **Sports Trak** (`AppConstants.sportsTabName`, a brand: never translated, `{tab}` placeholder in
  sentences); **live games list** ("See all · stats" beside Live now with 2+ live games: dense rows
  with situation + top players, OK = stats pop-up with box score / injuries / team stats /
  standings from ESPN `summary`, ▶❚❚ or hold > Play = full screen, Back = list, league logo
  backdrop); channel search much faster (guide scan: one team's names per game, superstring terms
  dropped, 15 min cache keyed by `EpgService.lastUpdated`, one app-wide
  `SportsChannelMatcher.shared`, hub shows last visit's channels at once); explicit Left/Right on
  the game rows (fast scrolling jumped rows). Details: `dev-notes/sports-tab.md` (Live games list).
- 1.0.19 (`+320`, 2026-10-17) — relay app check ON (Transfer over
  the internet / From phone need 1.0.16+, announced as a privacy change); hold OK on an episode =
  mark watched/unwatched (watched episodes restart from 0); **Neon Green** palette (`vivid` flag,
  `#2FD414`); portrait phone: bottom tab bar (TV/Movies/TV Shows/Sports/More, page 0 = "More"),
  live preview drawn once above the phone pages (shown on groups too), full-width Multiview picker;
  Sports: OK on another card while the hero plays = its details beside the same video (`_heroPick`),
  "WATCHING" pill on the playing card; Multiview 4 screens touch (tiles aligned to centre, 1.08
  boost). Formuler-only green 4K HDR Multiview tile = won't fix (bugs-and-fixes.md).
- 1.0.18 (`+309`, 2026-10-18) — **subtitles**: embedded MKV/MP4
  text tracks (Subtitles button, native `SubtitleBridge`, Flutter `SubtitleOverlay`) and **online
  subtitles from Stremio-protocol add-ons** (Settings > Add-ons, official OpenSubtitles v3 listed off,
  recent online languages one press away;
  a choice made on an episode carries to the rest of that series (movies manual). Player bar = one row
  (title | buttons | badges + time; slim seek bar above for VOD), Down focuses Play/Pause, pickers use
  `TvMenuTile`, OK in fullscreen live = info card, Sports game menu "Play here", coloured Live-now
  scores, Audio-track button retries, What's New skips disabled playlists + rebuilds a stale TMDB list,
  Search keeps the keyboard closed after picking a recent search. Details: `dev-notes/features.md`
  (Subtitles & add-ons). Windows: none of the player/subtitle work (separate player).
- 1.0.17 (`+294`, 2026-10-18) — Sports hero controls reworked
  (owner-tested Fire Stick/Formuler/phone): OK on a card only selects it, ▶❚❚ plays it in the hero,
  OK on the playing game = fullscreen at once; phone = tap focuses / tap plays in hero / tap
  fullscreen; phone Sports page scrolls as one + portrait hero; white play/pause icons in hints
  (`_KeyHintText`); `HoldToActivate` needs a key repeat to count a hold (first OK on the Fire Stick's
  Favourites opened "Clear favourites?"). Details: `dev-notes/sports-tab.md` (Hero mini player).
- 1.0.16 (`+289`, 2026-10-17) — **Sports hero mini player** (Android: Play/Pause on a game card plays its channel in the hero, video left + small VS layout right; OK = fullscreen on the same stream, Back stops it; see `dev-notes/sports-tab.md` "Hero mini player"); **unique channel ids** for channels sharing an EPG id (`Channel.withUniqueIds`, `epgKey`; fixed favourites/hide hitting every ESPN copy); hold OK on a tab's Favourites row = clear that tab's favourites (`PlaylistManager.clearFavorites`); What's New full-screen backdrop + default view; launch update prompt; Search/EPG-overlap/Transfer-focus fixes; relay app header; `TRADEMARKS.md`. Windows: no Sports preview yet.
- 1.0.15 (`+284`, 2026-10-16) — Favorites tab removed: favourites live behind one **Favourites** entry per tab (Movies/TV Shows: starred rows per playlist + favourited groups; TV: starred + favourited groups' channels); playlist labels with 2+ playlists (Search cards, TV Favourites list + Timeline guide); 12/24 h clock (Settings > General); splash greeting bank of compliments (one per cold start); phone: header search icon, tap shows both player bars, rotate button in the top bar, browse posters tap = preview / tap again = open. Details: `dev-notes/features.md` (1.0.15).
- 1.0.14 (`+271`, 2026-10-16) — **Transfer over the internet**: Send = encrypted upload to the relay's vault for 1 h / 24 h / 7 days, 16-digit code, works any number of times until expiry or Delete now; the Wi-Fi transfer is the "Both devices on the same Wi-Fi?" tile on that screen; Receive takes 9 or 16 digits. Relay deployed on the VPS (`tools/pair_relay`, vault on disk in `/var/lib/pair-relay`). Built to grow into cloud sync later. Also the +268 provider-duration + browse-banner title fix. Details: `dev-notes/features.md` (Transfer over the internet). Owner tested Fire Stick ↔ phone: "flawless and superfast".
- 1.0.13 (`+267`, 2026-10-15) — redesigned TV Show + movie detail pages (`series_detail_screen.dart`, `movie_detail_screen.dart`, shared `widgets/detail_header.dart`, `utils/display_title.dart` title cleanup; per-episode progress from existing saved positions, watched = >=95%); HD images (`utils/image_urls.dart` keyless TMDB size upgrade, `widgets/hd_network_image.dart` decode caps, provider backdrops via `get_vod_info`/`get_series_info`, `CatalogDatabase` v8); hero/carousel go dark -> backdrop (no poster flash, `_focusedArtPending`); hold the Sports RedZone pill to pick its channel; Back-from-guide focus safety net. Next keyless artwork option if wanted: TVmaze (series/episodes, CC BY-SA, no key).
- 1.0.12 (`+261`, 2026-10-15) — Android player CH+/CH- (and PgUp/PgDn) zap through the list the channel was picked from (`PlaybackService.zapList`, skips same-id duplicates) with a 3 s info card; hold OK on History = delete watched history; Add Playlist button black until focused; site shows the translucent guide. Windows: no CH zapping.
- 1.0.11 (`+259`, 2026-10-15) — Settings > General: hide Movies/TV Shows tabs, Startup = full screen / guide-preview / nothing (Android + Windows); Sports: watching another listed channel becomes that game's pick, glowing NFL RedZone pill, opens on the league row; Movies/TV Shows hero backdrop fades behind the first row, focused poster title no longer clipped.
- 1.0.10 (`+254`, 2026-10-14, 4 Formuler screenshots attached) —
  **full-screen video behind the Timeline guide** (Theme toggle, 3-row translucent guide, side
  columns hidden in the guide, corner description card), **fullscreen side panel** on Left (Last
  channels / My Teams / Live now; Left no longer exits the player — Back only), and Movies/TV Shows
  stopping a background live channel but keeping it resumable. All Android only — Windows parity
  not done. Details: `dev-notes/features.md`. **Next:** ask the owner.
- 1.0.9 (`+246`, 2026-10-14) — **Select = preview, Select again =
  fullscreen** on the Timeline guide + Live list (Android and Windows, `_previewOrOpenChannel`,
  `DesktopMiniPlayer.play`; see `dev-notes/features.md`), **event sports** in the League bank
  (golf PGA/LPGA/DP World/LIV, UFC/PFL, F1/NASCAR/IndyCar — leaderboard cards, F1 per session,
  fight cards = main event) and **racing championship standings** (drivers + F1 constructors).
  Details: `dev-notes/sports-tab.md` (Event sports). Not done: UFC rankings / golf points race
  (no usable free data), wrestling / horse racing (only an EPG-based idea). **Next:** ask the owner.
- 1.0.8 (`+240`, 2026-10-14) — **Spanish + Italian** (es.dart/it.dart,
  same 614 keys as fr.dart), **Transfer to another device** (Settings, last row: copies the
  whole setup over the home network, `services/device_transfer.dart` +
  `screens/settings/transfer_screen.dart`, see `dev-notes/features.md` → Transfer), Settings menu
  lost its Add Playlist row (it's in Playlist Manager). Owner prefers **batched releases** (a few
  features per cut). **Next:** ask the owner.
- 1.0.7 (`+235`, 2026-10-14) — Sports **League manager**
  (replaces the Edit leagues dialog): 13 base leagues + a bank of 63 ESPN leagues
  (`kSportsLeagueBank`, add / hold-to-send-back, per viewer), cups without a table kept out of
  Standings, and an empty single-league day offers "Next game: <date>". Details:
  `dev-notes/sports-tab.md` (League manager).
- 1.0.6 (`+232`, 2026-10-14) — **phone mode**: `TvHomeScreen`
  adapts to portrait phones (one column at a time, `_compact`/`_phonePage`; "auto" layout now
  uses it on phones — the old `HomeScreen` was deleted in +343), touch/mouse group pick collapses the side columns, Add Playlist / My Teams stack
  in portrait, Standings scrolls sideways on touch. Details: `dev-notes/features.md` (Phone mode).
- 1.0.5 (`+230`, 2026-10-14) — Sports on Windows: back arrow + Esc
  on the Sports screens, the whole Sports UI scales up on big displays (`SportsScreenFrame`,
  design width 1440, never shrinks — owner checked on a 4K monitor), and mouse ‹ › arrows on the
  game-card rows (`SportsRowArrows`). All Windows-only / no-ops on TV boxes.
- 1.0.4 (`+229`, 2026-10-14) — French + language picker (Settings > General > Language,
  `lib/l10n/`, see `dev-notes/features.md`) and the "Hey beautiful Human" splash greeting.
  Releases are announced on Discord (gold embed, `.github/workflows/discord-release.yml`, run by
  hand after an in-place release — `dev-notes/release.md` step 8).
- 1.0.3 (`+226`, 2026-10-14, tag on `d02200e`) — the Sports tab:
  scores, channel matching, Standings, **My Teams** (see `dev-notes/sports-tab.md`), plus Add
  Playlist "From phone" and the resume-pill fixes/switch (details below). Site + README advertise it
  with Formuler screenshots (`docs/assets/shot-sports.jpg`, `shot-my-teams.jpg`,
  `shot-standings.png`, `shot-follow.png`). Sports on Windows checked + fixed in
  1.0.5. **Later:** the "Not yet" list in `dev-notes/sports-tab.md` (Sports
  Multiview, phone layout, BYOK providers) — ask the owner which first.
- 1.0.2 (`+207`, 2026-10-13) — TV tab focused at launch, Settings >
  General History clearing (also on Windows). 1.0.1 (`+206`) added Settings > General (resume last
  channel at startup, Multiview tip toggle). The 1.0.0 release was retagged in place each time; tag `1.0.0`
  (`+204`) remains. 1.0.0 restarted the version numbers and included
  the SQLite EPG store, visible playlist password and the Multiview fixes (volume-only audio swap,
  auto-recovery, SurfaceTexture green fix, wakelock, connection-tip popup, 2/4-screen layout; see
  §9-§10). Releases/tags older than 3.52 were deleted; their history is in `previousreleases.md`.
  Tags 3.52.0-3.53.3 and the 3.53.3 release remain. Apps on ≤3.52.3 can't see 1.0.0 (old updater
  wants a higher number) — they reinstall from vespertv.app / Downloader `1760256`.
  Still to check: SQLite EPG on Windows. (Fire Stick "Update EPG Now" confirmed fixed by the owner,
  2026-10-13.)
- **What went into 1.0.3:** Sports v1 + Standings + **My Teams** (follow from Standings,
  starred/first games, team details screen; owner happy with it 2026-10-14). Site: carousel slides
  2-4, features cluster 04 / SPORTS, a Sports how-to group. Also fixed the "Hold > to resume" pill rendering with
  Flutter's yellow-underline debug text (no Material ancestor; Android + Windows), and the pill is
  now **hidden while Sports is open** (`LiveResumeHint.hideWhileMounted()` — a counter both pills
  watch; hold-Right still resumes), plus a Settings > General switch to turn the pill off. Also
  **Add Playlist > "From phone"** (QR → phone form; Wi-Fi path tested on the Formuler, VPS relay
  live at `https://pair.vespertv.app`, both paths verified with the real TV) — see `dev-notes/features.md`.
  Owner tested Sports on 2026-10-14 and the feedback round is in (OK plays / hold = menu, league
  reorder by hold, gold focus look).
- **Test builds** for the owner's Fire Stick go to a GitHub **pre-release** (skipped by the updater
  and `/latest`), sideloaded via Downloader with the direct asset URL; delete it once shipped.
- **Roadmap (owner, 2026-10-12):** ~~fix Multiview~~ (done 2026-10-13). **Next:** a **Sports tab** (design draft: `dev-notes/sports-tab.md`)
  with live scores, BYOK supporting **two** sports APIs (user picks/pastes a key in Settings; hard
  part is matching games to channels).
- **Ideas discussed, not started:** OpenSubtitles integration (BYO key); Windows player-controls
  secondary-row parity; widen `epgPastRetention` for catch-up later (owner wants it, after basics/
  stability); (done) EPG speed rework; (done) rename of `nox_iptv.exe`→`VesperTV.exe`
  (CMake `BINARY_NAME`; user data location is unaffected).
- Competitor reference: **LokTV** (paid) — cached EPG, sports tab, multiview, simple add-playlist.

## 14. Git
- Commit only when asked; end commit messages with the attribution trailer Claude Code provides.
- Never `--no-verify`, never force-push `main` (force-moving a **tag** to HEAD is the one sanctioned
  exception, §6.4).
- Local junk is git-ignored/untracked on purpose (`nox_*.png` screenshots, `*.apk`, `*-windows-x64.zip`).

## 15. Session hygiene (token efficiency)
- **User logs:** the owner saves users' Send-log files in `Logs/` (repo root, git-ignored) for the agents
  to read, e.g. `Logs/LOG-F28YBG.txt`. Read them from there; never commit or quote secrets from them.
- **Two agents:** Claude and Codex share this repo. `AGENTS.md` is the entry point for Codex (and its
  hard rules, branch etiquette, task split and handoff/pickup steps); `CLAUDE.md` stays the single
  rulebook. Only one agent works at a time; commit before switching; Codex works on `codex/*` branches.
- **One task per session.** Long sessions get lossy compaction and re-read the whole history after the
  1-hour prompt-cache expires. Finish a task, commit, then start fresh (`/clear` or a new session).
- **Hand off, don't drag.** Before a session ends or compacts, run `/handoff` (project command in
  `.claude/commands/handoff.md`): it writes `HANDOFF.md` (git-ignored). **If `HANDOFF.md` exists, read it
  first**, then delete or overwrite it once its contents are done/obsolete.
- Don't read giant files whole (`tv_home_screen.dart` is huge): `Grep` for the symbol, then `Read` only
  the needed line range. Use the `dev-notes/` files on demand, not all at once.
- Keep CLAUDE.md lean: put details in `dev-notes/`, put in-progress state in `HANDOFF.md`, and
  record only lessons that prevent a repeat mistake.

### Codex 2026-10-26: My Teams Goals alert (included in 1.0.41)

`codex/my-teams-goals-alert` adds an off-by-default, per-viewer Interface toggle.
Root `GoalsAlertOverlay` polls the existing scoreboard cache while foregrounded,
shows score increases for followed teams at top-left without touching playback/focus,
and stacks below reminders on phones. Hide scores suppresses alerts immediately.
Not instant push: 30s polling plus existing feed cache. First observation after launch,
profile change or backgrounding is silent. See `dev-notes/sports-tab.md` for details.

### Codex 2026-10-26: Refined finish (unreleased branch)

`codex/refined-finish` initially added Settings > Interface > Theme > Refined finish,
 off by default and per viewer. Owner requested a much stronger finish and explicitly
 accepted extra graphics cost (2026-10-26): `codex/refined-glass-finish` adds glossy
 reflections, painted bevels, deeper shadows, artwork edge rims and bounded blur in
 existing focused-control wrappers. Keep child/FocusNode slots and all geometry stable.
 The off state remains original. Never filter/reconfigure the native video surface.
 See `dev-notes/refined-finish.md`; real-device performance/appearance needs QA.
 Test package 1.0.41+458 includes ae5cb7f audio labels; analyze16 and600Flutter
 tests passed, guide59entries/12Node tests passed. Install result: root HANDOFF.md.

### Codex 2026-10-26: decoder HDR reporting (unreleased branch)

`codex/decoder-hdr-reporting` corrects unknown colour metadata being labelled SDR
and adds decoder-output fallback via existing FrameRateProbe callbacks. StatsBridge
retains both input and output evidence; Data pool labels stream/decoder and shows
known disagreement separately. No codec/display/surface configuration changes.
See `dev-notes/decoder-hdr-reporting.md`; a real Shield retest is still required.

### Codex 2026-10-26: reminders on every upcoming Sports Trak card (unreleased)

`codex/game-card-reminders` removes the game-menu My Teams restriction. The existing
reminder widget/scheduler already supports manual reminders without following teams.
Live score popups are Settings > Interface > Goals alert (off by default, My Teams).
Separate completed decoder HDR work remains on codex/decoder-hdr-reporting b0b0889.

### Codex 2026-10-26: combined Formuler test +456

Owner requested installation after Refined finish. codex/formuler-test-456 combines
Refined finish d5874ff, decoder HDR reporting b0b0889 and all-game reminders173d08d.
Version1.0.41+456; analyze17,598Flutter tests and62targeted native tests passed.
This is a local test package only; main/published1.0.41+455 remain unchanged.
Exact package/signature/installation results are in root HANDOFF.md.

### Codex 2026-10-29: sports first-press preview and key stats (unreleased)

`codex/sports-league-fixes` also contains the owner's follow-up: focus updates
matchup information, first OK/tap/click previews a matched game, second opens
full screen using the same opening/playing session. Hold behavior is retained;
no match opens the channel menu. The big matchup adds available key stats via
SportsMatchupStats and the existing gameSummary cache; Hide scores suppresses
live/final details. New strings have FR/ES/IT/EL. Regular cards grow for large
text too. See dev-notes/sports-mode.md and root HANDOFF.md for validation.

### Codex 2026-10-29: combined Formuler test +500

Owner requested merge/build/install/commit. codex/sports-league-fixes combines
all pending league and matchup changes above with claude/multiview-swap-mode
through5853b55 (swap, slower/lower pill, scrollable hold menu). Version1.0.45+500;
analyze16 baseline infos,902Flutter tests passed. Release certificate verified;
installed in place on Formuler Z11 Pro MAX and launched. No public release/push.
Next installed build must exceed500. Artifact and final commit: root HANDOFF.md.

### Codex 2026-10-29: Formuler follow-up +501

Owner reported +500 preview jumping into the rail and getting stuck, and asked
for injuries between the team stats. sports_screen now hands focus to the feed
when that feed mounts after playback opens, not only on the first OK frame;
Right from the rail goes to an active feed and full-screen Back restores it.
Pregame stats reserve left team / centered injuries / right team slots.
Regression reproduces the delayed-start jump before the fix;54targeted and904
full Flutter tests pass, analyze16. See dev-notes/sports-mode.md / root HANDOFF.

Signed +501 installed on Formuler. Actual-device D-pad check passed: first OK
keeps the feed focused/rail collapsed, Left then Down/Right exits the rail,
second OK opens full screen and Back restores the playing feed. Injuries
alignment checked on screen. Next installed build must exceed501.
