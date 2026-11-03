import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/cyberpunk_palette.dart';
import '../utils/constants.dart';
import '../utils/live_group_sort.dart';
import '../utils/time_format.dart';
import 'display_match.dart';
import 'device_defaults.dart';
import 'playback_service.dart';
import 'storage_service.dart';

/// App-wide UI/behavior preferences (theme, clock, layout mode, whether
/// this device is allowed to play anything right now).
///
/// Replaces manually threading 8 separate value/callback constructor
/// params through every screen that touches a setting — with the growing
/// number of settings screens, that had become the classic "prop drilling"
/// problem Provider exists to solve. Screens just `watch<AppPreferences>()`
/// and call a setter; everything persists itself.
class AppPreferences extends ChangeNotifier {
  AppPreferences(this._storage);

  final StorageService _storage;

  late bool showClock;
  late CyberpunkPalette palette;
  late String layoutMode; // 'auto', 'tv'
  late String guideViewMode; // 'live', 'timeline'

  /// Timeline guide: video full screen behind a translucent guide.
  late bool guideFullVideo;

  /// Fill the full-video Timeline area instead of limiting it to three rows.
  late bool guideExpanded;
  late bool guideCompact;
  late bool expandedBrowse;

  /// Movies / TV Shows tabs (and their search results) hidden, each on its
  /// own switch (Settings > General > Tabs).
  late bool hideMovies;
  late bool hideShows;

  /// The Extras row (the Archive tab; tabs column / phone "More" page)
  /// hidden.
  late bool hideArchive;

  /// The Recordings row hidden.
  late bool hideRecordings;

  /// The TV tab's Catch-up row (every channel with catch-up).
  late bool hideCatchupGroup;

  /// The TV tab's "Recently added" channels group (opt in).
  late bool recentChannelsGroup;

  /// The Multiview row and the player's "Open in Multiview" hidden.
  late bool hideMultiview;

  /// Home's profiles strip is optional, like that viewer's other Home rows.
  bool get hideProfiles => _storage.getHideProfiles();

  void setHideProfiles(bool value) {
    _storage.setHideProfiles(value);
    notifyListeners();
  }

  /// Fullscreen player zooms the picture to fill the screen (no black bars).
  late bool videoFill;

  /// Favourites (TV, Movies, TV Shows) mixed across playlists, A-Z,
  /// instead of one block per playlist (Settings > General > Favourites).
  late bool mixFavoritePlaylists;

  /// Settings > Interface > Tabs > Show group counts: how many channels,
  /// movies or shows each group holds, beside its name (off by default).
  late bool showGroupCounts;

  /// OK on a live channel also opens the Data pool card (stream details,
  /// `widgets/data_pool_card.dart`). Settings > General, off by default.
  late bool dataPool;

  /// Sports Trak / Settings / Search hide the background live channel's
  /// picture while open (stream and sound keep going) — see
  /// `TvHomeScreen._pushOverLiveVideo`. Off unless the user turned it on
  /// or this device is on the DeviceDefaults list.
  bool get hideVideoOnSports =>
      _storage.getHideVideoOnSports() ??
      DeviceDefaults.values[DeviceDefaults.hideVideoOnSports] ??
      false;

  /// True when [setting] (a DeviceDefaults name) is on only because this
  /// device is on the list — Settings says "Automatic" under it.
  bool isAutomaticOn(String setting) {
    if (DeviceDefaults.values[setting] != true) return false;
    return switch (setting) {
          DeviceDefaults.hideVideoOnSports => _storage.getHideVideoOnSports(),
          DeviceDefaults.compatVideo => _storage.getCompatVideo(),
          _ => true,
        } ==
        null;
  }

  /// Downloads the current device list in the background; a change applies
  /// at once (compatVideo from the next channel).
  Future<void> refreshDeviceDefaults() async {
    final json = await DeviceDefaults.fetch();
    if (json == null || json == _storage.getDeviceDefaults()) return;
    await _storage.setDeviceDefaults(json);
    DeviceDefaults.apply(json);
    PlaybackService.textureVideo = compatVideo;
    notifyListeners();
  }

  /// Both Movies and TV Shows hidden.
  bool get hideMoviesShows => hideMovies && hideShows;

  /// Whether the tab id 'Movies' / 'TV Shows' is hidden.
  bool isTabHidden(String tab) => switch (tab) {
        'Movies' => hideMovies,
        'TV Shows' => hideShows,
        _ => false,
      };

  /// Set once at startup from Android's own UI mode (see
  /// DeviceTypeService) — what 'auto' actually keys off now. Not
  /// persisted: it's a property of the device, re-detected every launch,
  /// and a stale stored value would be worse than asking again.
  bool isTelevision = false;

  /// Android API level, set at startup like [isTelevision] (0 = unknown).
  int androidSdk = 0;

  /// Compatibility video: the main player draws into a texture instead of
  /// a native view (see PlaybackService.textureVideo). Default on for
  /// Android 7 and older: a 1st-gen Fire TV Stick 4K (Fire OS 6.7) showed
  /// the picture twice (a small copy top-left over the full one) and
  /// striped garbage with the native view (user photos, 2026-10-20).
  bool get compatVideo =>
      _storage.getCompatVideo() ??
      DeviceDefaults.values[DeviceDefaults.compatVideo] ??
      (androidSdk > 0 && androidSdk < 26);

  void setCompatVideo(bool value) {
    _storage.setCompatVideo(value);
    PlaybackService.textureVideo = value;
    notifyListeners();
  }

  /// HDMI audio passthrough on the main player (Android, off by default):
  /// Dolby Digital / Atmos / DTS go to the soundbar or receiver undecoded
  /// (vendored `AudioPassthrough`). Off since 2026-10-07 for every player
  /// because passthrough audio ignores the app's volume, which let muted
  /// Multiview screens keep playing; Multiview stays decoded either way.
  /// Opt-in after a user missed Atmos (Discord, 2026-10-22). Device-only.
  bool get audioPassthrough => _storage.getAudioPassthrough();

  /// Green-flicker fix (Android, off by default, device-only): the main
  /// player's video surface as a media overlay (vendored `VideoLayering`),
  /// for NVIDIA Shield green frames under the translucent guide without
  /// losing HDR the way Compatibility video does (Shield user, 2026-10-23).
  bool get videoMediaOverlay => _storage.getVideoMediaOverlay();

  /// Native video surface (beta, Android, on by default, device-only): the
  /// main player in a plain SurfaceView behind a transparent Flutter view
  /// (`widgets/native_video_hole.dart`). Read at launch: applies after a
  /// restart. For HDR / green flicker through the platform view (Fire TV
  /// Cube, NVIDIA Shield, 2026-10-24).
  bool get nativeVideoSurface => _storage.getNativeVideoSurface();

  void setNativeVideoSurface(bool value) {
    _storage.setNativeVideoSurface(value);
    debugPrint('NativeSurface: setting turned ${value ? 'on' : 'off'} '
        '(applies after a restart)');
    notifyListeners();
  }

  void setVideoMediaOverlay(bool value) {
    _storage.setVideoMediaOverlay(value);
    unawaited(PlaybackService.setVideoMediaOverlay(value));
    notifyListeners();
  }

  void setAudioPassthrough(bool value) {
    _storage.setAudioPassthrough(value);
    unawaited(PlaybackService.setAudioPassthrough(value));
    notifyListeners();
  }

  /// Settings > Playback > Frame rate & resolution (Android, device-only, off by default):
  /// switch the TV to the video's frame rate / resolution ([DisplayMatch]).
  bool get matchFrameRate => _storage.getMatchFrameRate();
  bool get match5060Only => _storage.getMatch5060Only();
  bool get matchResolution => _storage.getMatchResolution();

  void setMatchFrameRate(bool value) {
    _storage.setMatchFrameRate(value);
    if (!DisplayMatch.enabled(_storage)) unawaited(DisplayMatch.reset());
    notifyListeners();
  }

  void setMatch5060Only(bool value) {
    _storage.setMatch5060Only(value);
    notifyListeners();
  }

  void setMatchResolution(bool value) {
    _storage.setMatchResolution(value);
    if (!DisplayMatch.enabled(_storage)) unawaited(DisplayMatch.reset());
    notifyListeners();
  }

  /// Live TV groups column order (filter icon above Favourites): display-only,
  /// device-only. Moving a group switches back to provider order.
  LiveGroupSort get liveGroupSort =>
      LiveGroupSort.values
          .where((s) => s.name == _storage.getLiveGroupSort())
          .firstOrNull ??
      LiveGroupSort.provider;

  void setLiveGroupSort(LiveGroupSort value) {
    _storage.setLiveGroupSort(value.name);
    notifyListeners();
  }

  /// Where the app opens after the splash (user request: "load on Sports
  /// Trak"): `tv` (default), `movies`, `series`, `hub` (Media Hub) or
  /// `sports`. A hidden tab falls back to TV. With "Resume last channel in
  /// full screen" on and another section chosen, the channel resumes in
  /// the background instead (main.dart `_autoResumeLastChannel`): the
  /// chosen section wins. Device-only.
  String get startSection => _storage.getStartSection() ?? 'tv';

  void setStartSection(String value) {
    _storage.setStartSection(value);
    notifyListeners();
  }

  /// The choices and their (untranslated) names.
  static const startSections = [
    ('home', 'Home'),
    ('tv', 'TV'),
    ('movies', 'Movies'),
    ('series', 'TV Shows'),
    ('hub', 'Media Hub'),
    ('sports', AppConstants.sportsTabName),
  ];

  /// [startSection] unless what it names is hidden (then `tv`).
  String get effectiveStartSection => switch (startSection) {
        'movies' when hideMovies => 'tv',
        'series' when hideShows => 'tv',
        'hub' when hideArchive => 'tv',
        final s => s,
      };

  /// Subtitle text size, a factor on the player's own size (two users asked
  /// for bigger/smaller subtitles). Picked in the player's Subtitles menu;
  /// read by `SubtitleOverlay` (Android) and the Windows player's
  /// `SubtitleViewConfiguration`. Device-only: a TV and a phone differ.
  double get subtitleScale => _storage.getSubtitleScale();

  void setSubtitleScale(double value) {
    _storage.setSubtitleScale(value);
    notifyListeners();
  }

  /// The choices, smallest first, and their (untranslated) names.
  static const subtitleSizes = [
    (0.6, 'Extra small'),
    (0.8, 'Small'),
    (1.0, 'Normal'),
    (1.25, 'Large'),
    (1.5, 'Extra large'),
  ];

  /// The name of [scale] (nearest choice).
  static String subtitleSizeName(double scale) => subtitleSizes
      .reduce((a, b) => (a.$1 - scale).abs() <= (b.$1 - scale).abs() ? a : b)
      .$2;

  bool get sportsMode => _storage.getSportsMode();
  Future<void> setSportsMode(bool value) async {
    await _storage.setSportsMode(value);
    notifyListeners();
  }

  bool get sportsHideScores => _storage.getSportsHideScores();
  Future<void> setSportsHideScores(bool value) async {
    await _storage.setSportsHideScores(value);
    notifyListeners();
  }

  bool get transparentPopups => _storage.getTransparentPopups();
  void setTransparentPopups(bool value) {
    _storage.setTransparentPopups(value);
    notifyListeners();
  }

  bool get goalsAlert => _storage.getGoalsAlert();
  void setGoalsAlert(bool value) {
    _storage.setGoalsAlert(value);
    notifyListeners();
  }

  /// Fast startup: see [AppConstants.keyFastStartup]. Read once by the
  /// splash, so a change applies from the next launch.
  bool get fastStartup => _storage.getFastStartup();

  void setFastStartup(bool value) {
    _storage.setFastStartup(value);
    notifyListeners();
  }

  /// Read once after the splash; changing it applies on the next launch.
  bool get launchWithProfiles => _storage.getLaunchWithProfiles();

  void setLaunchWithProfiles(bool value) {
    _storage.setLaunchWithProfiles(value);
    notifyListeners();
  }

  bool refinedFinish = false;

  void setRefinedFinish(bool value) {
    refinedFinish = value;
    _storage.setRefinedFinish(value);
    notifyListeners();
  }

  Future<void> init() async {
    refinedFinish = _storage.getRefinedFinish();
    showClock = _storage.getShowClock();
    palette = _paletteById(_storage.getPaletteId());
    layoutMode = _storage.getLayoutMode();
    guideViewMode = _storage.getGuideViewMode();
    guideFullVideo = _storage.getGuideFullVideo();
    guideExpanded = _storage.getGuideExpanded();
    guideCompact = _storage.getGuideCompact();
    expandedBrowse = _storage.getExpandedBrowse();
    hideMovies = _storage.getHideMovies();
    hideShows = _storage.getHideShows();
    hideArchive = _storage.getHideArchive();
    hideRecordings = _storage.getHideRecordings();
    hideCatchupGroup = _storage.getHideCatchupGroup();
    recentChannelsGroup = _storage.getRecentChannelsGroup();
    hideMultiview = _storage.getHideMultiview();
    videoFill = _storage.getVideoFill();
    mixFavoritePlaylists = _storage.getMixFavoritePlaylists();
    showGroupCounts = _storage.getShowGroupCounts();
    dataPool = _storage.getDataPool();
    TimeFormat.use24h = _storage.getTime24h();
  }

  /// 24-hour vs 12-hour times (see TimeFormat).
  bool get use24h => TimeFormat.use24h;

  void setUse24h(bool value) {
    TimeFormat.use24h = value;
    _storage.setTime24h(value);
    notifyListeners();
  }

  CyberpunkPalette _paletteById(String id) {
    // Blue replaces Habs and its older Green / Orange alias. Resolve on
    // read so existing viewer-scoped keys and backups stay untouched.
    final resolved = id == 'green_orange' || id == 'habs' ? 'blue' : id;
    return AppConstants.cyberpunkPalettes.firstWhere((p) => p.id == resolved,
        orElse: () => AppConstants.cyberpunkPalettes.first);
  }

  void setShowClock(bool value) {
    showClock = value;
    _storage.setShowClock(value);
    notifyListeners();
  }

  /// A profile switch only reloads viewer-specific appearance. Device
  /// settings (layout, video compatibility, clock, etc.) stay as they are.
  void reloadPaletteForViewer() {
    final next = _paletteById(_storage.getPaletteId());
    final finish = _storage.getRefinedFinish();
    if (palette.id == next.id && refinedFinish == finish) return;
    palette = next;
    refinedFinish = finish;
    notifyListeners();
  }

  void setPalette(CyberpunkPalette newPalette) {
    palette = newPalette;
    _storage.setPaletteId(newPalette.id);
    notifyListeners();
  }

  void setLayoutMode(String mode) {
    layoutMode = mode;
    _storage.setLayoutMode(mode);
    notifyListeners();
  }

  /// 'auto' or a language code ('en', 'fr', 'es', 'it', 'el') (see L10n). Applied before `runApp` in main.dart;
  /// changing it here re-resolves the language and notifies, and main.dart
  /// remounts the home screen so every string is rebuilt.
  String get language => L10n.setting;

  Future<void> setLanguage(String value) async {
    await L10n.apply(value);
    await _storage.setLanguage(value);
    notifyListeners();
  }

  void setGuideViewMode(String mode) {
    guideViewMode = mode;
    _storage.setGuideViewMode(mode);
    notifyListeners();
  }

  void setGuideFullVideo(bool value) {
    guideFullVideo = value;
    _storage.setGuideFullVideo(value);
    notifyListeners();
  }

  /// Device-only: trailer playback while browsing movie/show details, opt-in.
  bool get autoTrailers => _storage.getAutoTrailers();

  void setAutoTrailers(bool value) {
    _storage.setAutoTrailers(value);
    notifyListeners();
  }

  void setExpandedBrowse(bool value) {
    expandedBrowse = value;
    _storage.setExpandedBrowse(value);
    notifyListeners();
  }

  void setGuideCompact(bool value) {
    guideCompact = value;
    _storage.setGuideCompact(value);
    notifyListeners();
  }

  void setGuideExpanded(bool value) {
    guideExpanded = value;
    _storage.setGuideExpanded(value);
    notifyListeners();
  }

  void setHideMovies(bool value) {
    hideMovies = value;
    _storage.setHideMovies(value);
    notifyListeners();
  }

  void setHideShows(bool value) {
    hideShows = value;
    _storage.setHideShows(value);
    notifyListeners();
  }

  void setVideoFill(bool value) {
    videoFill = value;
    _storage.setVideoFill(value);
    notifyListeners();
  }

  void setHideVideoOnSports(bool value) {
    _storage.setHideVideoOnSports(value);
    notifyListeners();
  }

  void setDataPool(bool value) {
    dataPool = value;
    _storage.setDataPool(value);
    notifyListeners();
  }

  void setMixFavoritePlaylists(bool value) {
    mixFavoritePlaylists = value;
    _storage.setMixFavoritePlaylists(value);
    notifyListeners();
  }

  void setShowGroupCounts(bool value) {
    showGroupCounts = value;
    _storage.setShowGroupCounts(value);
    notifyListeners();
  }

  void setHideArchive(bool value) {
    hideArchive = value;
    _storage.setHideArchive(value);
    notifyListeners();
  }

  void setHideRecordings(bool value) {
    hideRecordings = value;
    _storage.setHideRecordings(value);
    notifyListeners();
  }

  void setRecentChannelsGroup(bool value) {
    recentChannelsGroup = value;
    _storage.setRecentChannelsGroup(value);
    notifyListeners();
  }

  void setHideCatchupGroup(bool value) {
    hideCatchupGroup = value;
    _storage.setHideCatchupGroup(value);
    notifyListeners();
  }

  void setHideMultiview(bool value) {
    hideMultiview = value;
    _storage.setHideMultiview(value);
    notifyListeners();
  }
}
