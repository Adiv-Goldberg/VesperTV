import 'utils/refined_finish.dart';
import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'screens/catalog_sync_prompt_screen.dart';
import 'screens/catalog_sync_screen.dart';
import 'screens/desktop_player_screen.dart';
import 'services/desktop_mini_player.dart';
import 'services/desktop_window.dart';
import 'screens/player_screen.dart';
import 'screens/settings/add_playlist_screen.dart';
import 'screens/tv_home_screen.dart';
import 'screens/home_screen.dart';
import 'screens/archive_screen.dart';
import 'screens/sports_screen.dart';
import 'screens/welcome_add_playlist_screen.dart';
import 'screens/startup_profile_screen.dart';
import 'services/app_log.dart';
import 'services/app_preferences.dart';
import 'services/archive_posters.dart';
import 'services/catalog_database.dart';
import 'services/device_defaults.dart';
import 'services/device_memory_service.dart';
import 'services/epg_service.dart';
import 'services/parental_pin.dart';
import 'services/persistent_image_cache.dart';
import 'models/sports.dart';
import 'services/playback_service.dart';
import 'services/guide_key.dart';
import 'services/profile_gate.dart';
import 'services/archive_ready_watch.dart';
import 'services/real_4k_channels.dart';
import 'services/recording_service.dart';
import 'services/sports_channel_library.dart';
import 'services/watch_game_offer.dart';
import 'services/sports_channel_matcher.dart';
import 'services/sports_service.dart';
import 'models/channel.dart';
import 'widgets/recording_conflict_dialog.dart';
import 'services/playlist_manager.dart';
import 'services/storage_service.dart';
import 'services/game_reminders.dart';
import 'services/programme_reminders.dart';
import 'widgets/programme_reminder_overlay.dart';
import 'services/goals_alerts.dart';
import 'widgets/game_reminder_overlay.dart';
import 'widgets/goals_alert_overlay.dart';
import 'widgets/native_video_hole.dart';
import 'services/viewer_profile_service.dart';
import 'utils/constants.dart';
import 'utils/startup_routes.dart';
import 'utils/route_observer.dart';
import 'utils/splash_greeting.dart';
import 'utils/tv_theme.dart';
import 'widgets/desktop_live_resume_hint.dart';
import 'widgets/live_resume_hint.dart';
import 'widgets/splash_stars.dart';
import 'l10n/l10n.dart';
import 'services/archive_service.dart';
import 'services/backup_service.dart';
import 'services/tracker_sync.dart';
import 'services/watch_tracker.dart';
import 'services/perf_diagnostics.dart';
import 'services/desktop_live_recovery.dart';
import 'services/desktop_stream_setup.dart';

// AppLog keeps print/errors for Settings > Send log; the binding must be
// initialized inside its zone (same zone as runApp).
Future<void> main() => AppLog.capture(_main);

Future<void> _main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // sqflite on Android runs EVERY database (guide, catalog, Media Hub cache and
  // the image cache's metadata) on ONE worker thread. A long query on a big
  // guide (Sports Trak's channel search) then froze all of them: blank logos,
  // posters and Home cards, 1,000+ "database locked for 10 s" warnings (Shield
  // user, LOG-K2RDQM). With several workers different databases run side by
  // side; one database's own queries stay in order (plugin contract). Must run
  // before the first database opens.
  if (Platform.isAndroid) {
    try {
      await const MethodChannel('com.tekartik.sqflite')
          .invokeMethod<void>('options', {'androidThreadCount': 4});
      debugPrint('Sqflite: 4 database worker threads');
    } catch (e) {
      debugPrint('Sqflite: thread count not set: $e');
    }
  }
  // Plain `sqflite` has no Windows/Linux implementation at all — confirmed
  // via .flutter-plugins-dependencies: sqflite_android/sqflite_darwin exist
  // for the platforms this app already shipped on, nothing for
  // windows/linux. sqflite_common_ffi's FFI-based factory is the standard
  // swap for those two desktop platforms; Android/iOS/macOS keep using
  // plain sqflite's own already-proven native implementation untouched.
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Only ever used by DesktopPlayerScreen — see its own doc comment and
    // pubspec.yaml's media_kit comment. Every other platform keeps using
    // video_player_hdr exclusively and never touches this at all.
    MediaKit.ensureInitialized();
  }
  if (Platform.isWindows) {
    // See pubspec.yaml's window_manager comment — maximizing a plain
    // window left the title bar and taskbar visible ("only like 98%"), so
    // the default is real full screen with no title bar, TV-style. Users
    // asked for a resizable window too (half screen): the sidebar's
    // Windowed row, remembered — DesktopWindow creates the window directly
    // in the saved mode, so there's no windowed-then-fullscreen flash.
    await DesktopWindow.init(await SharedPreferences.getInstance());
  }
  // Before runApp so the splash text is already in the right language.
  // Read straight from SharedPreferences: StorageService isn't up yet.
  try {
    final prefs = await SharedPreferences.getInstance();
    await L10n.apply(prefs.getString(AppConstants.keyLanguage) ?? 'auto');
    await SplashGreeting.pickNext(prefs);
  } catch (_) {
    await L10n.apply('auto');
  }
  await _configureImageCache();
  // See persistent_image_cache.dart's doc comment — the package default
  // stores cached poster/logo *files* in OS-reclaimable storage while its
  // own cache index lives somewhere persistent, so they can (and on a
  // real box, confirmed do) drift out of sync: every poster re-fetches
  // from scratch on a cold start, not just the first one ever.
  CachedNetworkImageProvider.defaultCacheManager = persistentImageCacheManager;
  runApp(const NoxIptvApp());
}

/// Flutter's default ImageCache holds up to 1000 decoded images / ~100MB —
/// fine on a phone, but on a memory-constrained box (some Firesticks have
/// as little as ~1.7GB total RAM) that alone can be enough to trigger a
/// device-wide low-memory kill cascade while browsing a large catalog, even
/// with cacheWidth/cacheHeight shrinking each individual decoded image (see
/// PosterCard/channel_list_tile).
///
/// This used to be one fixed number for every device — confirmed as the
/// wrong model: a Firestick with almost no memory headroom and a Formuler
/// box with plenty both got the exact same ceiling, when what they can
/// each actually spare is very different. Native Android image loaders
/// (Glide, the de facto standard) size their own cache off
/// `ActivityManager.isLowRamDevice()`/`getMemoryInfo()` for exactly this
/// reason — this queries the same real device info (via MainActivity.kt,
/// since Flutter has no built-in way to ask this) and scales the ceiling
/// to what *this* device can actually spare, instead of guessing one
/// number for all of them. Falls back to the old conservative constant
/// (100MB) if the query fails for any reason (non-Android platform,
/// unexpected native exception) — never guesses generous under
/// uncertainty.
Future<void> _configureImageCache() async {
  final info = await DeviceMemoryService.getMemoryInfo();
  final int maxBytes;
  if (info == null || info.isLowRamDevice || info.totalMemGB < 2.0) {
    maxBytes =
        100 << 20; // 100MB — the tier this session already validated as stable
  } else if (info.totalMemGB < 3.0) {
    maxBytes = 175 << 20;
  } else if (info.totalMemGB < 4.0) {
    maxBytes = 250 << 20;
  } else {
    // Was 350MB — bumped after confirming on real hardware that the
    // adaptive ceiling (introduced this same version) was noticeably
    // faster than the old fixed 100MB but still not quite instant on a
    // device with real headroom to spare.
    maxBytes = 500 << 20;
  }
  // The image *count* isn't the real lever — at ~300KB per decoded poster
  // (see PosterCard's cacheWidth/cacheHeight), maxBytes above is reached
  // long before any sane count limit would matter. Set high enough that
  // it's never the actual constraint, so maxBytes is the one true ceiling.
  PaintingBinding.instance.imageCache.maximumSize = 2000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = maxBytes;
}

/// Root widget. Bootstraps [StorageService], [PlaylistManager], and
/// [EpgService] before building the [MaterialApp] so every provider handed
/// down the tree already has its persisted settings/cache loaded — no
/// "waiting for provider" states inside the UI.
class NoxIptvApp extends StatefulWidget {
  const NoxIptvApp({super.key});

  @override
  State<NoxIptvApp> createState() => _NoxIptvAppState();
}

class _NoxIptvAppState extends State<NoxIptvApp>
    with SingleTickerProviderStateMixin, WindowListener {
  late final StorageService _storage;
  late final CatalogDatabase _catalogDb;
  late final AppPreferences _preferences;
  late final PlaylistManager _playlistManager;
  late final EpgService _epgService;
  late final PlaybackService _playbackService;
  late final ViewerProfileService _viewerProfileService;
  late final ParentalPin _parentalPin;
  late final ArchiveService _archiveService;
  bool _ready = false;
  Completer<void>? _profileSelection;

  Future<void> _finishProfileSelection() async {
    final selection = _profileSelection;
    setState(() => _profileSelection = null);
    // The application Navigator must exist before startup playback can push.
    await WidgetsBinding.instance.endOfFrame;
    if (selection != null && !selection.isCompleted) selection.complete();
  }

  /// The remote's Guide button, anywhere in the app ([GuideKey]).
  bool _onGuideKey(KeyEvent event) => GuideKey.handle(event,
      navigator: _ready && _profileSelection == null
          ? _navigatorKey.currentState
          : null);

  /// Back at the root with the startup selector on (see [ProfileGate]):
  /// the current viewer's playback stops and Who's watching replaces the
  /// app; picking a viewer rebuilds it on the TV root.
  Future<void> _returnToProfiles() async {
    if (!_ready || _profileSelection != null) return;
    if (Platform.isWindows) {
      DesktopMiniPlayer.instance.clear();
    } else {
      await _playbackService.stop();
    }
    if (!mounted) return;
    setState(() => _profileSelection = Completer<void>());
  }

  final _startupRoutes = StartupRoutes();
  GameReminders? _gameReminders;
  ProgrammeReminders? _programmeReminders;
  GoalsAlerts? _goalsAlerts;

  /// True while [PlaylistManager.runFullCatalogSync] is blocking the
  /// launch — see [CatalogSyncScreen] and [_bootstrap] for the whole
  /// "a few times a week, not every launch" reasoning.
  bool _syncing = false;

  /// True while waiting on [CatalogSyncPromptScreen]'s Yes/No answer — a
  /// full sync is a multi-minute, server-round-trip-per-category action
  /// triggered automatically (a stale timestamp), not a direct user tap,
  /// so it asks first rather than just barging into it.
  bool _syncPromptPending = false;
  Completer<bool>? _syncPromptCompleter;

  Future<bool> _confirmAutoSync() {
    final completer = Completer<bool>();
    _syncPromptCompleter = completer;
    if (mounted) setState(() => _syncPromptPending = true);
    return completer.future;
  }

  void _respondToSyncPrompt(bool confirmed) {
    if (mounted) setState(() => _syncPromptPending = false);
    _syncPromptCompleter?.complete(confirmed);
    _syncPromptCompleter = null;
  }

  /// True while waiting on [WelcomeAddPlaylistScreen]'s answer — shown once,
  /// right after [PlaylistManager.init] confirms a brand-new install has
  /// zero playlists configured, since nothing else in the app hints that
  /// content lives behind Settings > Playlist Manager rather than just
  /// showing up on its own.
  bool _newUserPromptPending = false;
  Completer<bool>? _newUserPromptCompleter;

  /// Set from [WelcomeAddPlaylistScreen]'s answer, consumed once `_ready`
  /// flips true (see `_buildReadyContent`'s `build` doc comment below) —
  /// can't just push [AddPlaylistScreen] directly from the prompt itself,
  /// since the real `MaterialApp`/`Navigator` this screen's bootstrap gate
  /// runs ahead of doesn't exist yet at that point.
  bool _pendingAutoOpenAddPlaylist = false;

  Future<bool> _confirmNewUserWantsPlaylist() {
    final completer = Completer<bool>();
    _newUserPromptCompleter = completer;
    if (mounted) setState(() => _newUserPromptPending = true);
    return completer.future;
  }

  void _respondToNewUserPrompt(bool wantsToAddPlaylist) {
    if (mounted) setState(() => _newUserPromptPending = false);
    _newUserPromptCompleter?.complete(wantsToAddPlaylist);
    _newUserPromptCompleter = null;
  }

  /// Lets background work (the initial playlist load finishing, "Update
  /// content" finishing) show a brief toast without needing a BuildContext
  /// tied to whatever screen happens to be on top — same trick other IPTV
  /// players use for their "refresh complete" notification.
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Lets [LiveResumeHint] push the fullscreen player back on top from
  /// its own position in the tree — it sits as a *sibling* of the
  /// Navigator (see `builder` below), deliberately, so its hold-Right
  /// gesture and reminder text work from any screen; `Navigator.of
  /// (context)` from there would find nothing, since siblings aren't
  /// ancestors.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  final String _splashStatus = tr('Starting...');
  String? _bootstrapError;

  /// Drives the cold-start splash's "firing up" pulse (logo breathing
  /// scale + glow) — purely cosmetic, tied to however long [_bootstrap]
  /// actually takes rather than padding out a fixed extra delay. Most
  /// launches only see this for a moment; it just looks intentional
  /// instead of a bare spinner for however long that moment is.
  late final AnimationController _splashController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onGuideKey);
    _bootstrap();
    // Windows only — a window can't be minimized while it's *in*
    // `fullScreen` mode at all (confirmed directly: the sidebar's
    // Minimize row did nothing with the single `windowManager.minimize()`
    // call this used to be), so the real sequence is exit fullscreen,
    // then minimize (see the sidebar's own onTap in tv_home_screen.dart),
    // then re-enter fullscreen here once the window actually comes back —
    // onWindowRestore is `window_manager`'s event for exactly that
    // (clicking the taskbar icon), not something tied to any specific
    // screen, so this lives at the app root rather than wherever the
    // Minimize button happens to be.
    if (Platform.isWindows) windowManager.addListener(this);
  }

  @override
  void dispose() {
    _splashController.dispose();
    _startupRoutes.dispose();
    final selection = _profileSelection;
    if (selection != null && !selection.isCompleted) selection.complete();
    ProfileGate.unregister();
    HardwareKeyboard.instance.removeHandler(_onGuideKey);
    _gameReminders?.dispose();
    _programmeReminders?.dispose();
    RecordingService.instance.prepareProgramme = null;
    _goalsAlerts?.dispose();
    if (Platform.isWindows) windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowRestore() {
    if (Platform.isWindows) DesktopWindow.onRestore();
  }

  @override
  void onWindowResized() => DesktopWindow.onBoundsChanged();

  @override
  void onWindowMoved() => DesktopWindow.onBoundsChanged();

  /// PlaybackService.confirmOpen: a running recording holds [channel]'s
  /// playlist's only connection — Stop recording / Cancel.
  Future<bool> _confirmOverRecording(Channel channel) async {
    final rec = RecordingService.instance
        .conflictFor(channel, _playlistManager.profiles);
    final context = _navigatorKey.currentContext;
    if (rec == null || context == null) return true;
    final stop = await showRecordingConflictDialog(context, rec);
    if (!stop) return false;
    await RecordingService.instance.stop(rec);
    // The provider needs a moment to free the connection.
    await Future<void>.delayed(const Duration(seconds: 2));
    return true;
  }

  Future<String?> _recordingTapUrl(Channel channel) async {
    final rec = RecordingService.instance.recordingOf(channel);
    return rec == null ? null : RecordingService.instance.teeUrl(rec);
  }

  Future<void> _prepareProgrammeRecording(RecordingEntry entry) async {
    if (!mounted ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    final channel = _playbackService.currentChannel;
    if (channel == null ||
        channel.id != entry.channelId ||
        channel.transientPlayback) {
      return;
    }
    final viewer = _storage.getActiveViewerId();
    await _playbackService.handOverScheduledRecording(channel, () async {
      await RecordingService.instance.waitStarted(entry);
      await RecordingService.instance.refreshStatus();
    },
        canResume: () =>
            mounted &&
            _storage.getActiveViewerId() == viewer &&
            WidgetsBinding.instance.lifecycleState ==
                AppLifecycleState.resumed);
  }

  /// Settings > Sports Trak > Watch game button: a reminded game is about
  /// to start, so the player shows a Watch game pill (Up from the player
  /// bar, OK switches; never by itself, owner 1.0.51) for the channel Sports
  /// Trak would pick first (saved pick / added source / best match). No
  /// match = no pill.
  Future<void> _offerStartingGame(GameReminder reminder) async {
    final split = reminder.key.indexOf(':');
    if (split <= 0) return;
    final league = sportsLeagueById(reminder.key.substring(0, split));
    final id = reminder.key.substring(split + 1);
    if (league == null) return;
    final viewer = _storage.getActiveViewerId();
    try {
      await _playlistManager.ensureLiveChannelsLoaded();
      final start = reminder.start.toLocal();
      final games = await SportsService.instance
          .gamesForDay([league], DateTime(start.year, start.month, start.day));
      final game = games.where((g) => g.id == id).firstOrNull;
      if (game == null) return;
      final live = _playlistManager.visibleChannels(category: 'tv');
      final matcher = SportsChannelMatcher.shared(_epgService);
      await matcher.prepare(live,
          hidden: _playlistManager.hiddenLiveChannels());
      final picks = SportsChannelPicks.load(_storage);
      final key = SportsChannelPicks.eventKey(game);
      final found = (await matcher.matchDay([game], picks))[key] ?? [];
      final saved = SportsChannelLists(_storage).sourcesFor(game, key);
      final channel = (picks.channelIdFor(game) == null
              ? live.where((c) => saved.contains(c.id)).firstOrNull
              : null) ??
          picks
              .orderMatches(found, countries: picks.countryPreferences)
              .firstOrNull
              ?.channel;
      if (channel == null ||
          !mounted ||
          _storage.getActiveViewerId() != viewer) {
        debugPrint('WatchGame: ${reminder.key} no channel');
        return;
      }
      debugPrint('WatchGame: ${reminder.key} -> ${channel.name}');
      final offer = WatchGameOffer(
          title: '${reminder.home} vs ${reminder.away}',
          channel: channel,
          until: DateTime.now().add(WatchGameOffer.lifetime));
      WatchGameOffer.current.value = offer;
      Timer(WatchGameOffer.lifetime, () {
        if (WatchGameOffer.current.value == offer) {
          WatchGameOffer.current.value = null;
        }
      });
    } catch (e) {
      debugPrint('WatchGame: ${reminder.key} failed: $e');
    }
  }

  Future<void> _refreshAutoRecordings() async {
    final service = RecordingService.instance;
    if (service.autoTeam == null) return;
    await _epgService.init();
    await _playlistManager.ensureLiveChannelsLoaded();
    await service.refreshAutoTeam(
      viewerLeagues: savedSportsLeagues(_storage),
      matcher: SportsChannelMatcher.shared(_epgService),
      picks: SportsChannelPicks.load(_storage),
      channels: _playlistManager.visibleChannels(category: 'tv'),
      hiddenChannels: _playlistManager.hiddenLiveChannels(),
    );
  }

  /// The splash is meant to be *seen*, not just theoretically present —
  /// a boot animation that only flashes for a fraction of a second reads
  /// as broken, not polished. On a normal day (no full sync due),
  /// bootstrap itself now finishes in well under a second, which isn't
  /// enough time to register the pulse at all. This is a deliberate,
  /// fixed minimum floor the splash stays up for regardless of how fast
  /// the real work finishes — same idea as a game console's boot
  /// animation playing out fully even though the actual boot is quick.
  static const _minSplashDuration = Duration(milliseconds: 2600);

  /// Fast startup's splash: loads for this long at most (owner: 3-4 s is
  /// fine if it buys stability), then the UI opens and the rest of the
  /// catalog fills in behind it.
  static const _fastSplashDuration = Duration(milliseconds: 3500);

  Future<void> _bootstrap() async {
    setState(() => _bootstrapError = null);
    final started = DateTime.now();
    try {
      _storage = StorageService();
      await _storage.init();
      _gameReminders = GameReminders(_storage);
      _programmeReminders = ProgrammeReminders(_storage);
      _goalsAlerts = GoalsAlerts(_storage);
      LiveResumeHint.pillEnabled.value = _storage.getShowResumePill();
      ArchivePosters.pattern = _storage.getArchivePosterPattern();

      Real4kChannels.init(_storage);
      ArchiveReadyWatch.instance.init(_storage);
      _preferences = AppPreferences(_storage);
      await _preferences.init();
      // Asked once per launch, before anything decides a layout — see
      // DeviceTypeService for why screen width couldn't answer this.
      _preferences.isTelevision = await DeviceTypeService.isTelevision();
      // A TV has no touch screen, so the focus highlight always shows.
      // Flutter's automatic mode hides it until it sees a "keyboard" event,
      // and a TV's own remote forwarded over HDMI-CEC (owner's Sony on the
      // Formuler, 2026-10-21) moved the selector without ever showing it.
      if (_preferences.isTelevision) {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
      }
      if (Platform.isAndroid) {
        _preferences.androidSdk = await DeviceTypeService.sdkInt();
      }
      await DeviceDefaults.load(_storage.getDeviceDefaults());
      unawaited(_preferences.refreshDeviceDefaults());
      PlaybackService.textureVideo = _preferences.compatVideo;
      NativeVideoSurface.active =
          Platform.isAndroid && _preferences.nativeVideoSurface;
      if (NativeVideoSurface.active) {
        await NativeVideoSurface.configure();
        debugPrint('NativeSurface: beta ON at launch (SDK '
            '${_preferences.androidSdk}, compatibility video '
            '${_preferences.compatVideo ? 'on: native surface unused' : 'off'})');
      }
      unawaited(
          PlaybackService.setAudioPassthrough(_preferences.audioPassthrough));
      unawaited(
          PlaybackService.setVideoMediaOverlay(_preferences.videoMediaOverlay));

      _catalogDb = CatalogDatabase();

      _playlistManager = PlaylistManager(_storage, _catalogDb);
      _epgService = EpgService(_storage)
        ..catchupDaysProvider = _playlistManager.catchupDaysByEpgId
        ..beforeRefresh = _playlistManager.ensureLiveChannelsLoaded;
      // Started during the splash, not after it: it only opens the EPG
      // database and preloads now/next for every channel (a few thousand
      // rows, SQLite on its own thread), so it doesn't compete with the
      // catalog for the CPU the way the old full JSON decode would have.
      // Not awaited — the splash never waits on it; the post-splash chain
      // below awaits the same future.
      unawaited(_epgService.init());
      // Send-log probes for very large playlists (stalls, database queue).
      // Windows live recovery: a channel's other copies (Settings'
      // automatic failover, same as Android's PlaybackService).
      desktopSoftwareVideo = _storage.getDesktopSoftwareVideo();
      DesktopLiveRecovery.copiesOf = (channel) => _storage.getCopyFallback()
          ? _playlistManager.failoverCandidatesFor(channel)
          : const [];
      PerfDiagnostics.start({
        'catalog': _playlistManager.pingCatalog,
        'epg': _epgService.pingDatabase,
      });
      unawaited(Future<void>.delayed(const Duration(seconds: 90), () {
        unawaited(_playlistManager.logCatalogSize().catchError((_) {}));
      }));
      _playbackService = PlaybackService(_storage, _playlistManager)
        ..catchupGuide = ((live) => _epgService.getPrograms(live.epgId));
      if (RecordingService.supported) {
        PlaybackService.confirmOpen = _confirmOverRecording;
        PlaybackService.openUrlFor = _recordingTapUrl;
        RecordingService.instance.prepareProgramme = _prepareProgrammeRecording;
      }
      _parentalPin = ParentalPin(_storage);
      _archiveService = ArchiveService(_storage);
      // Trakt/Simkl scrobbling reads the connected accounts from here.
      WatchTracker.instance.attach(_archiveService);
      TrackerSync.instance.attach(_archiveService);
      _viewerProfileService = ViewerProfileService(
          _storage, _playlistManager, _playbackService,
          onViewerChanged: _preferences.reloadPaletteForViewer);

      // Restores category lists (small, fast regardless of catalog size —
      // see that method's doc comment for why live channels/category
      // *items* are no longer touched here). Awaited, unlike before: the
      // freshness check right below needs isXtream/category state to
      // already be correct, so there's no way to let the UI go up first
      // this time.
      await _playlistManager.init();

      // Brand-new install, nothing configured yet — ask once up front
      // rather than leaving a new user to land on an empty TV/Movies/TV
      // Shows screen with no indication content has to be added via
      // Settings first. `needsFullSync()` below is always false with zero
      // playlists (nothing enabled to be stale), so this can't race or
      // double up with that prompt.
      if (_playlistManager.profiles.isEmpty) {
        _pendingAutoOpenAddPlaylist = await _confirmNewUserWantsPlaylist();
      }

      // TiviMate/MyTVOnline3-style: a full catalog sync (every non-hidden
      // category's items, not just category lists) happens a few times a
      // week, not on every launch — an ordinary day skips straight to the
      // main UI with an already-populated local catalog. Blocking behind
      // CatalogSyncScreen here (rather than showing the main UI and
      // syncing behind it, the old approach) is the actual point: the
      // user shouldn't reach a real, usable Movies/TV Shows screen until
      // the catalog is genuinely ready, matching how those apps behave on
      // a sync day. Hidden groups are unaffected either way — see
      // runFullCatalogSync's doc comment.
      //
      // This is triggered by a stale timestamp, not a direct tap, so it
      // asks first (CatalogSyncPromptScreen) rather than just barging into
      // a multi-minute blocking sync — declining leaves the timestamp
      // untouched, so it asks again next launch instead of postponing
      // forever.
      var didSync = false;
      if (_playlistManager.needsFullSync()) {
        // "Update automatically" on every due playlist: no question.
        final confirmed =
            _playlistManager.dueSyncIsAutomatic() || await _confirmAutoSync();
        if (confirmed) {
          didSync = true;
          if (mounted) setState(() => _syncing = true);
          await _playlistManager.runFullCatalogSync();
          if (mounted) setState(() => _syncing = false);
        }
      }

      // Only relevant on the plain "no sync due today" path — if a sync
      // ran, [runFullCatalogSync] already populated every category via
      // its own warm-up, so there's nothing left to pre-load here.
      //
      // This is the actual point of showing a splash at all: an ordinary
      // cold restart starts with every category's *items* wiped from
      // memory (by design — see _restoreXtreamCache's doc comment), even
      // though they're already sitting in the local database from a
      // previous session. Without this, that repopulation only starts
      // once the user taps into Movies/TV Shows, and they'd watch it
      // happen live, category by category. Driving it here instead means
      // the splash — which the user is already expecting to sit through
      // for a moment, the same as a game console's boot animation —
      // is what "pays for" that, so Movies/TV Shows are already fully
      // populated by the time the main UI appears. Uses the same
      // self-sustaining worker pool "Update Content" already relies on,
      // so this is a fast local-database read in the common case, not a
      // network fetch — no artificial delay, this is genuinely the same
      // work that would otherwise happen the moment you opened either tab.
      // Fast startup (opt-in, Settings > General > Startup): the UI opens
      // now and Movies/TV Shows fill in behind it. Off by default — on a
      // weak box early remote input during this load crashed the app
      // (CLAUDE.md §10), which is why the splash waits for it.
      final fast = _preferences.fastStartup;
      if (!didSync && _playlistManager.isXtream) {
        // One pre-load pass per enabled Xtream playlist — group names
        // alone aren't enough to route to the right playlist's session
        // once more than one can exist (two playlists could share a
        // category name), so this groups the merged vod/seriesGroups
        // lists by their own `playlistId` first.
        final futures = <Future<void>>[];
        for (final profile in _playlistManager.profiles
            .where((p) => p.enabled && p.isXtream)) {
          final vodNames = _playlistManager.vodGroups
              .where((g) => g.playlistId == profile.id && !g.isHidden)
              .map((g) => g.title);
          final seriesNames = _playlistManager.seriesGroups
              .where((g) => g.playlistId == profile.id && !g.isHidden)
              .map((g) => g.title);
          futures.add(_playlistManager.ensureCategoriesLoaded(
              profile.id, vodNames, 'vod'));
          futures.add(_playlistManager.ensureCategoriesLoaded(
              profile.id, seriesNames, 'series'));
        }
        final preload = Future.wait(futures);
        if (fast) {
          // Whatever loads within the fast splash is ready on arrival.
          final left = _fastSplashDuration - DateTime.now().difference(started);
          await Future.any([
            preload.then((_) {},
                onError: (Object e) => debugPrint('Fast startup preload: $e')),
            Future<void>.delayed(left.isNegative ? Duration.zero : left),
          ]);
        } else {
          await preload;
        }
      }

      // Anything the pre-load above kicked off but didn't itself await
      // (a warm-up someone else started, a category still in flight)
      // finishes behind the splash rather than behind the real UI.
      // Reported directly, and the reason this is worth waiting for: the
      // app's crashes clustered in the first ~20 seconds of a cold start,
      // which is exactly when the catalog fetches, a video decoder
      // opening for the resumed channel, and the EPG parse all used to
      // run at once. The splash is time the user already expects to
      // spend; a half-populated UI that then falls over is not.
      await _waitForCategoriesToSettle(
          fast ? started.add(_fastSplashDuration) : null);

      // A fixed floor on top of the real work above — on a very small
      // catalog (or M3U mode, which skips the pre-load entirely) that
      // work alone might finish in well under a second, too fast for the
      // splash's pulse animation to actually register at all.
      final floor = fast ? _fastSplashDuration : _minSplashDuration;
      final elapsed = DateTime.now().difference(started);
      if (elapsed < floor) {
        await Future.delayed(floor - elapsed);
      }
      if (!mounted) return;
      if (_preferences.launchWithProfiles) {
        _profileSelection = Completer<void>();
      }
      ProfileGate.register(
          enabled: () => _preferences.launchWithProfiles,
          show: _returnToProfiles);
      final selection = _profileSelection;
      setState(() => _ready = true);
      // Never mount a previous viewer's home, consume startup routes, or resume
      // playback until the selected viewer and their appearance are applied.
      if (selection != null) await selection.future;
      if (!mounted) return;
      if (didSync) {
        // The toast needs the real MaterialApp's ScaffoldMessengerKey,
        // which doesn't exist until the tree above actually builds.
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _showToast(tr('Content updated')));
      }
      if (_pendingAutoOpenAddPlaylist) {
        // Same reasoning as the toast above — the real Navigator this
        // pushes onto doesn't exist until this build lands.
        _pendingAutoOpenAddPlaylist = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => const AddPlaylistScreen()));
        });
      }
      // Profile selection waits for the application's first frame above. Any
      // callbacks just queued still need a new frame, even on an idle screen.
      if (selection != null) WidgetsBinding.instance.ensureVisualUpdate();
      // `_epgService.init()` was started during the splash (see above);
      // awaiting it here only makes sure startAutoRefresh sees whether the
      // database has data — which decides if a refresh is due right away.
      // Trakt/Simkl: movies watched or paused elsewhere get their mark /
      // resume point (a no-op without an account). Late, off the busy
      // first seconds after the splash.
      unawaited(Future<void>.delayed(const Duration(seconds: 20)).then(
          (_) => TrackerSync.instance.syncCatalog(_storage, _playlistManager)));
      // Weekly automatic backup when switched on (Settings > Backup &
      // restore); a no-op otherwise.
      unawaited(Future<void>.delayed(const Duration(seconds: 40))
          .then((_) => BackupService(_storage).maybeAutoBackup()));
      // Recordings: states of anything that ran while the app was closed,
      // then the auto-recorded team's next games (needs the guide).
      if (RecordingService.supported) {
        unawaited(RecordingService.instance.init());
        unawaited(Future<void>.delayed(const Duration(seconds: 60))
            .then((_) => _refreshAutoRecordings()));
      }
      unawaited(() async {
        await _playbackService.init();
        await Future.wait([
          _autoResumeLastChannel(),
          _epgService.init(),
        ]);
        _epgService.startAutoRefresh(
            _storage.getRefreshInterval(), _epgSources);
        // No-op for most launches (no key set, or already refreshed this
        // week) — see PlaylistManager.refreshWhatsNewTmdbIfDue's doc
        // comment for why this is a launch-time due-check rather than an
        // in-process weekly timer.
        await _playlistManager.refreshWhatsNewTmdbIfDue();
      }());
    } catch (e) {
      // Surfaces any unexpected startup failure as a retryable screen
      // instead of leaving the app stuck on the splash spinner forever.
      if (mounted) setState(() => _bootstrapError = e.toString());
    }
  }

  /// Upper bound on how long the splash will hold for the catalog. A
  /// provider slow or broken enough to still be fetching after this has
  /// to be allowed to finish behind the UI instead — a splash that never
  /// ends is worse than a catalog that fills in late.
  static const _categorySettleTimeout = Duration(seconds: 30);

  /// [until] (Fast startup) cuts the wait short; the load carries on.
  Future<void> _waitForCategoriesToSettle([DateTime? until]) async {
    final deadline = until ?? DateTime.now().add(_categorySettleTimeout);
    while (_playlistManager.isLoadingCategories &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  /// Starts playing straight into whatever live channel was last playing —
  /// the same "turn it on and it's on the last channel" behavior MyTvOnline
  /// has. On Android this was once scaled back to a pill only
  /// ([PlaybackService.setPendingResumeChannel] + `LiveResumeHint`, hold
  /// Right to start) because opening a decoder concurrently with the
  /// catalog/EPG load made the first 10-20 s of a cold start sluggish; with
  /// the EPG now in SQLite it's back, behind Settings > General > "Resume
  /// last channel at startup" (on by default). Off = the pill again. A
  /// second switch there, "...with the guide open", plays it in the guide's
  /// preview box (Windows: the mini player) instead; both off = nothing
  /// plays (Android still offers the pill).
  ///
  /// Windows, restored to the original direct-open behavior —
  /// requested directly: a PC doesn't pay the same cold-launch cost a weak
  /// Android TV box does opening a decoder concurrently with the catalog/
  /// EPG load, so there's no reason to hold it back there. Pushes straight
  /// into [DesktopPlayerScreen] (not [PlaybackService]/[PlayerScreen] at
  /// all — Windows' own, wholly separate player, see that screen's own doc
  /// comment) via [_navigatorKey] directly, not through a postFrame-
  /// callback the way [_pendingAutoOpenAddPlaylist] needs to: unlike that
  /// flag (checked synchronously in the same frame `_ready` flips true),
  /// this runs after a real awaited disk read below, well after the real
  /// Navigator already exists — same reasoning [DesktopLiveResumeHint]
  /// .resume] already pushes through [_navigatorKey] directly with no such
  /// wrapping.
  ///
  /// No-ops if something's already playing (a real user action on this
  /// launch beat the background load) or there's nothing to resume into.
  /// Scoped to live channels only (not movies/episodes): those are
  /// deliberate choices to open, a live channel is just "what's on".
  ///
  /// Awaits [ensureLiveChannelsLoaded] directly (unlike every other caller,
  /// which just kicks it off and lets the UI show a brief loading state) —
  /// this one has to actually search the list, so it can't run until the
  /// list exists. Live channels are no longer loaded eagerly during
  /// PlaylistManager.init() (see that method's doc comment), so without
  /// this, resume-last-channel would silently find an empty list and do
  /// nothing on every Xtream launch.
  Future<void> _autoResumeLastChannel() async {
    // The sports home starts with its dashboard, never an unrelated stream.
    if (_preferences.sportsMode) return;
    if (_playbackService.isPlayingSomething) return;
    final lastId = _storage.getLastChannelId();
    if (lastId == null) return;
    await _playlistManager.ensureLiveChannelsLoaded();
    // Settings > General > Startup (both platforms): full screen (default),
    // or playing in the guide's preview box, or neither.
    // Another start section (Startup > Open on) wins over full screen: the
    // channel then resumes in the background, like "with the guide open".
    final elsewhere = _preferences.effectiveStartSection != 'tv';
    final fullscreen = _storage.getResumeLastChannelAtStartup() && !elsewhere;
    final inGuide = !fullscreen &&
        (_storage.getResumeLastChannelInGuide() ||
            (elsewhere && _storage.getResumeLastChannelAtStartup()));
    // visibleChannels, not the raw `channels` getter — a restricted
    // viewer's last-played channel may have had its group hidden since
    // they last watched (by whoever set up their profile), and silently
    // offering it to resume into would bypass that the same way an
    // unfiltered search result would.
    for (final channel in _playlistManager.visibleChannels(category: 'tv')) {
      if (channel.id == lastId) {
        if (Platform.isWindows) {
          if (fullscreen) {
            _navigatorKey.currentState?.push(MaterialPageRoute(
                builder: (_) => DesktopPlayerScreen(channel: channel)));
          } else if (inGuide &&
              DesktopMiniPlayer.instance.channel.value == null) {
            DesktopMiniPlayer.instance.play(channel);
          }
        } else if (inGuide) {
          if (_playbackService.isPlayingSomething) return;
          await _playbackService.play(channel);
        } else if (fullscreen) {
          // Back on by default since 1.0.x: the heavy part of the old
          // cold-start load (decoding the whole EPG, ~25 s) is gone — the
          // guide now opens from SQLite in ~0.3 s during the splash, and the
          // first EPG refresh waits >= 30 s. Settings > General turns it off
          // (then only the pill below). Same push the pill's own resume
          // does; PlayerScreen.initState starts playback.
          if (_playbackService.isPlayingSomething) return;
          _navigatorKey.currentState?.push(
              PlayerPageRoute(builder: (_) => PlayerScreen(channel: channel)));
        } else {
          _playbackService.setPendingResumeChannel(channel);
        }
        return;
      }
    }
  }

  /// The oldest last-full-sync timestamp among enabled Xtream playlists —
  /// the most stale one is what actually drove [needsFullSync] to true,
  /// so it's the most representative "how out of date is this" answer to
  /// show on the confirm-before-syncing prompt. Null if none has ever
  /// synced at all.
  DateTime? _oldestLastFullSyncAt() {
    DateTime? oldest;
    for (final profile
        in _playlistManager.profiles.where((p) => p.enabled && p.isXtream)) {
      final at = _storage.getLastFullSyncAt(profile.id);
      if (at == null) return null;
      if (oldest == null || at.isBefore(oldest)) oldest = at;
    }
    return oldest;
  }

  /// Every enabled playlist's EPG source, evaluated fresh on each
  /// `EpgService.startAutoRefresh` tick — see `EpgService.refresh`'s doc
  /// comment for why each playlist's own channel ids matter here.
  List<EpgSource> _epgSources() => _playlistManager.profiles
      .where((p) => p.enabled && (p.epgUrl?.isNotEmpty ?? false))
      .map((p) => (
            url: p.epgUrl!,
            knownChannelIds: _playlistManager.knownChannelIdsFor(p.id)
          ))
      .toList();

  void _showToast(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_bootstrapError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white70, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    tr('Startup failed:\n{bootstrapError}',
                        {'bootstrapError': _bootstrapError}),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _bootstrap, child: Text(tr('Retry'))),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Reported directly, live, on *two* devices after the fix below was
    // first written: a solid white screen for several real seconds on
    // every cold launch — this fix's own regression, not the native-
    // launch-screen bug fixed separately (drawable/launch_background.xml).
    // `_ready`/`_syncPromptPending`/`_syncing` all start false, which is
    // exactly the state this method is in for Flutter's very *first*
    // build — called synchronously as part of the same initState() call
    // stack, before `_bootstrap()` (started, not awaited, from initState)
    // has run past its own first `await` and actually assigned
    // `_preferences`/`_catalogDb`/`_playlistManager`/`_epgService`/
    // `_playbackService`. The previous version of this method wrapped
    // *every* non-error branch in the MultiProvider below unconditionally
    // — including this exact "nothing has happened yet" initial state —
    // so that very first build referenced five still-uninitialized `late
    // final` fields and threw, repeatedly, on every rebuild attempt until
    // `_bootstrap()` finally caught up. This splash branch never actually
    // needed Provider access at all (pure local widget state throughout)
    // — kept outside the wrap below, same as the original structure
    // before that fix, for exactly the reason that structure had it there.
    if (!_ready && !_newUserPromptPending && !_syncPromptPending && !_syncing) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const SplashStars(),
              Center(
                child: AnimatedBuilder(
                  animation: _splashController,
                  builder: (context, child) {
                    // 0..1..0 over the controller's duration — eased so the
                    // pulse breathes rather than bouncing linearly.
                    final t =
                        Curves.easeInOut.transform(_splashController.value);
                    final scale = 0.94 + (t * 0.12); // 0.94 .. 1.06
                    final glow = 0.25 + (t * 0.45); // 0.25 .. 0.70
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF0C75E)
                                    .withValues(alpha: glow),
                                blurRadius: 40,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: Transform.scale(
                            scale: scale,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.asset(
                                'assets/icon/icon_flat.png',
                                width: 120,
                                height: 120,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFF0C75E), Color(0xFFC9781A)],
                          ).createShader(bounds),
                          child: const Text(
                            AppConstants.appName,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // A small kind word on every cold start (owner's
                        // wish), a different one each launch.
                        Text(SplashGreeting.text,
                            style: const TextStyle(
                                color: Color(0xFFF0C75E),
                                fontSize: 16,
                                fontStyle: FontStyle.italic)),
                        const SizedBox(height: 20),
                        Text(_splashStatus,
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Everything below only ever becomes reachable after
    // `_playlistManager.init()` (which itself runs after every `late
    // final` service field above is assigned) has already completed —
    // `_newUserPromptPending`/`_syncPromptPending`/`_syncing` are only ever
    // set true later in `_bootstrap()`, well past that point — so
    // referencing all of them in this MultiProvider is genuinely safe here,
    // unlike in the splash branch above.
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: _storage),
        ChangeNotifierProvider<GameReminders>.value(value: _gameReminders!),
        ChangeNotifierProvider<ProgrammeReminders>.value(
            value: _programmeReminders!),
        ChangeNotifierProvider<GoalsAlerts>.value(value: _goalsAlerts!),
        Provider<CatalogDatabase>.value(value: _catalogDb),
        ChangeNotifierProvider<AppPreferences>.value(value: _preferences),
        ChangeNotifierProvider<PlaylistManager>.value(value: _playlistManager),
        ChangeNotifierProvider<EpgService>.value(value: _epgService),
        ChangeNotifierProvider<PlaybackService>.value(value: _playbackService),
        Provider<ParentalPin>.value(value: _parentalPin),
        ChangeNotifierProvider<ArchiveService>.value(value: _archiveService),
        ChangeNotifierProvider<ViewerProfileService>.value(
            value: _viewerProfileService),
      ],
      child: _buildReadyContent(context),
    );
  }

  Widget _buildReadyContent(BuildContext context) {
    if (_newUserPromptPending) {
      return WelcomeAddPlaylistScreen(onRespond: _respondToNewUserPrompt);
    }

    if (_syncPromptPending) {
      return CatalogSyncPromptScreen(
        lastSyncedAt: _oldestLastFullSyncAt(),
        onRespond: _respondToSyncPrompt,
      );
    }

    if (_syncing) {
      return CatalogSyncScreen(playlist: _playlistManager);
    }

    return Consumer<AppPreferences>(
      builder: (context, prefs, _) {
        if (_profileSelection != null) {
          return MaterialApp(
            key: const ValueKey('startup-profile-selector'),
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            locale: L10n.locale,
            supportedLocales: L10n.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: ThemeData(
              brightness: Brightness.dark,
              colorScheme:
                  buildPaletteColorScheme(prefs.palette, Brightness.dark),
              useMaterial3: true,
            ),
            home: StartupProfileScreen(onSelected: _finishProfileSelection),
          );
        }
        return MaterialApp(
          key: const ValueKey('application'),
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: _scaffoldMessengerKey,
          navigatorKey: _navigatorKey,
          navigatorObservers: [appRouteObserver],
          onGenerateInitialRoutes: (_) => _startupRoutes.generate(
            preferences: prefs,
            storage: _storage,
            rootBuilder: _buildTvRoot,
            destinations: {
              'home': (_) => const HomeScreen(),
              'hub': (_) => const ArchiveScreen(),
              'sports': (_) => const SportsScreen(),
            },
          ),
          // Flutter's own widget strings (text-selection menu, tooltips)
          // follow the app language, not the device's (see L10n).
          locale: L10n.locale,
          supportedLocales: L10n.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          // Renders above the Navigator's own output rather than inside
          // it, so the hold-Right-to-resume gesture and reminder text
          // work from any screen instead of only the one route they
          // happened to be built into (see LiveResumeHint's doc
          // comment).
          builder: (context, child) => Stack(
            children: [
              if (child != null) child,
              LiveResumeHint(navigatorKey: _navigatorKey),
              // Windows-only equivalent — see DesktopPlayerScreen's own
              // doc comment for why it's a separate widget/holder rather
              // than reusing LiveResumeHint/PlaybackService.
              if (Platform.isWindows)
                DesktopLiveResumeHint(navigatorKey: _navigatorKey),
              GameReminderOverlay(onGameStarting: _offerStartingGame),
              const ProgrammeReminderOverlay(),
              const GoalsAlertOverlay(),
            ],
          ),
          // Always dark, regardless of the OS/system light-dark setting —
          // a deliberate streaming-app convention (Netflix/YouTube/Plex
          // all do this too), confirmed directly: "keep it always dark and
          // remove the toggle". No `darkTheme`/`themeMode` at all, so
          // there's nothing for a system-level light-mode change to flip.
          theme: RefinedFinish.apply(
              ThemeData(
                brightness: Brightness.dark,
                colorScheme:
                    buildPaletteColorScheme(prefs.palette, Brightness.dark),
                useMaterial3: true,
              ),
              prefs.refinedFinish),
          routes: {Navigator.defaultRouteName: _buildTvRoot},
        );
      },
    );
  }

  Widget _buildTvRoot(BuildContext context) {
    // TvHomeScreen is the regular home; Sports Mode selects the sports root.
    // The regular layout adapts to phones itself
    // (one column at a time in portrait, bottom tab bar). The old
    // phone HomeScreen was removed (owner, 2026-10-18).
    // `Consumer<ViewerProfileService>` plus a `ValueKey` on the
    // active viewer's id is what actually makes a profile switch
    // take effect on screen — nothing else in this ancestor
    // chain (just `Consumer<AppPreferences>` above) listens to
    // that service at all, so without this, `switchTo` would
    // update every service's own state correctly but the UI
    // would silently keep showing the OLD viewer's screen,
    // confirmed as a real gap during this feature's own review.
    // A full remount (not just a rebuild) is deliberate too —
    // see `ViewerProfileService.switchTo`'s doc comment: it's
    // what tears down `TvHomeScreen`'s own pending-hide timers
    // and resets its focus/selection state via a clean `dispose`
    // instead of needing dozens of fields manually reset.
    return Consumer2<ViewerProfileService, AppPreferences>(
      builder: (context, viewerService, prefs, _) {
        // The language is part of the key for the same reason:
        // a language change remounts home so every tr() string
        // is rebuilt (General settings pops back here first).
        final key = ValueKey('${viewerService.active.id}|${L10n.code}');
        final section = _startupRoutes.takeRootSection();
        if (prefs.sportsMode) {
          return SportsScreen(key: key, home: true);
        }
        return TvHomeScreen(
          key: key,
          initialTab: switch (section) {
            'movies' => 'Movies',
            'series' => 'TV Shows',
            _ => 'TV',
          },
          startupSportsCovered: section == 'sports',
          startupBrowseCovered: section == 'home' || section == 'hub',
        );
      },
    );
  }
}
