import 'package:flutter/material.dart';

import '../models/cyberpunk_palette.dart';

/// App-wide constants: display strings, theme seed, and the SharedPreferences
/// keys used by [StorageService]. Centralized here so key names never drift
/// between the services that read and write them.
class AppConstants {
  static const String keyAutoTrailers = 'vesper_auto_trailers';

  static const String appName = 'VesperTV';

  /// The Sports tab's name (owner, 2026-10-17). A brand: not translated.
  static const String sportsTabName = 'Sports Trak';
  static const Color seedColor = Colors.deepPurple;

  /// Screen width above which "auto" layout mode switches to the TV UI.
  /// Real TVs/boxes routinely report >=1200 logical px in landscape;
  /// phones and even large tablets stay below it. Also used to decide
  /// whether the fullscreen player should touch orientation at all — see
  /// PlayerScreen's doc comment on why forcing portrait on a TV-sized
  /// screen is actively harmful, not just pointless.
  static const double tvLayoutWidthThreshold = 1200;

  /// Fresh-install default for [AppPreferences.layoutMode] — a user can
  /// always override it in Settings > Theme regardless. Baked in at build
  /// time (`--dart-define=DEFAULT_LAYOUT_MODE=tv`) rather than a runtime
  /// check, so the universal APK (built for TV boxes/Firesticks, where
  /// "auto" detection isn't reliable on non-certified hardware) can default
  /// straight to the TV layout, while the phone/arm64 build keeps "auto".
  static const String defaultLayoutMode =
      String.fromEnvironment('DEFAULT_LAYOUT_MODE', defaultValue: 'auto');

  /// Fresh-install default for [AppPreferences.guideViewMode] — 'live'
  /// (the original single-channel now/next view) or 'timeline' (the
  /// cable-guide grid). Always overridable in Settings > Theme.
  static const String defaultGuideViewMode = 'timeline';

  // SharedPreferences keys.
  //
  // keyM3uUrl/keyEpgUrl/keyXtreamServer.../keyPlaylistMode/
  // keyPlaylistEnabled/the global keyHiddenGroups/keyFavoritedGroups/
  // keySyncFrequencyDays/keyLastFullSyncAt below are LEGACY —
  // pre-multi-playlist, single global scalars. Nothing writes them
  // anymore; they're read exactly once, by
  // PlaylistManager._migrateLegacySinglePlaylist, to build the one
  // PlaylistProfile an upgrading install starts with. Kept (not deleted)
  // as a cheap fallback during early rollout of that migration.
  static const String keyM3uUrl = 'nox_m3u_url';
  static const String keyEpgUrl = 'nox_epg_url';
  static const String keyRefreshInterval = 'nox_refresh_interval_minutes';
  static const String keyTmdbApiKey = 'nox_tmdb_api_key';
  // Media Hub custom poster URL pattern (ArchivePosters), device-only.
  static const String keyArchivePosterPattern = 'vesper_archive_poster_pattern';
  // Stremio-style subtitle add-ons (AddonService), JSON list.
  static const String keyAddons = 'vesper_addons';
  // Archive tab sources (Stremio-schema catalogs + streams), JSON list.
  static const String keyArchiveSources = 'vesper_archive_sources';
  static const String keyArchiveCinemetaCatalog =
      'vesper_archive_cinemeta_catalog';

  /// Extras: titles played (newest first, JSON) and recent searches per
  /// category (JSON `{movie: [...], series: [...]}`). Sent with "Include
  /// Extras tab data" like the sources.
  static const String keyArchiveHistory = 'vesper_archive_history';

  /// Media Hub favourites (newest first, same `{src, meta}` JSON entries as
  /// the history), both categories together.
  static const String keyArchiveFavorites = 'vesper_archive_favorites';
  static const String keyArchiveRecentSearches =
      'vesper_archive_recent_searches';
  // Online subtitle languages picked before, most recent first.
  static const String keyOnlineSubtitleLangs = 'vesper_online_sub_langs';
  // Subtitle choice per series (SubtitleTracks.rememberForSeries), JSON.
  static const String keySeriesSubtitles = 'vesper_series_subs';
  static const String keyPreferredAudioLanguage = 'vesper_audio_language';
  static const String keyPreferredSubtitleLanguage = 'vesper_subtitle_language';
  static const String keyAudioTrackChoices = 'vesper_audio_choices';
  static const String keyWhatsNewTmdbLastRefreshed =
      'nox_whats_new_tmdb_last_refreshed';

  /// The curated "What's New" selection itself — see
  /// `PlaylistManager.refreshWhatsNewTmdbIfDue`'s doc comment for why
  /// this exists as a separately-persisted, ordered id list rather than
  /// just re-deriving "newest" from the provider catalog on every read:
  /// the actual selection now comes from matching TMDB's own trending/
  /// popular titles against the catalog, which is too expensive (a TMDB
  /// fetch plus a DB search per candidate) to redo on every carousel
  /// render. `Channel.id`s and `XtreamSeries.id`s respectively, in
  /// display order.
  static const String keyWhatsNewVodIds = 'nox_whats_new_vod_ids';
  static const String keyWhatsNewSeriesIds = 'nox_whats_new_series_ids';
  static const String keyFavorites = 'nox_favorites';
  static const String keyFavoriteSeries = 'nox_favorite_series';
  static const String keyHiddenGroups = 'nox_hidden_groups';

  /// A restricted ("kid") viewer's *shown*-groups allowlist — the inverse
  /// of [keyHiddenGroups]'s blocklist. See `ViewerProfile.isRestricted`'s
  /// doc comment for why a restricted viewer needs the opposite default
  /// (a newly-added category should start hidden for them, not visible).
  /// Namespaced per playlist exactly like [keyHiddenGroups].
  static const String keyShownGroups = 'nox_shown_groups';

  /// Per-channel hide, scoped to live TV only — for duplicate feeds a
  /// provider lists within an otherwise-wanted group (e.g. the same
  /// channel in both HD and HEVC), where hiding the whole group isn't
  /// an option. Namespaced per playlist exactly like [keyHiddenGroups].
  static const String keyHiddenChannels = 'nox_hidden_channels';

  /// Manual EPG channel-id assignment (see `Channel.epgIdOverride`) —
  /// `Channel.rawId` -> the EPG feed's own `<channel id>`, JSON-encoded
  /// since a `Map`, unlike the `Set`s above, needs more than
  /// `getStringList`/`setStringList`. Namespaced per playlist exactly
  /// like [keyHiddenChannels].
  static const String keyEpgIdOverrides = 'nox_epg_id_overrides';

  /// Manual cross-playlist "same real-world channel" link (see
  /// `PlaylistManager.channelLinkFor`) — lets a live channel on one
  /// playlist name its equivalent on another, for manual failover when
  /// this playlist's own server (and its own backup servers) are down.
  /// One-to-one only: a channel links to at most one other channel, not
  /// a chain across three+ playlists. `Channel.rawId` -> the target
  /// channel's own (playlistId, rawId) — JSON-encoded for the same reason
  /// as [keyEpgIdOverrides]. Namespaced per playlist like every other key
  /// here.
  static const String keyChannelLinks = 'nox_channel_links';

  /// Which `Channel.rawId`s' current [keyChannelLinks]/[keyEpgIdOverrides]
  /// entry was set by "Auto-Pair Channels" rather than picked by hand —
  /// lets "Unpair Channels" undo exactly what auto-pairing did, and
  /// nothing a manual pick has since confirmed (requested directly:
  /// an opt-out for anyone who finds auto-pairing gets something wrong).
  /// A rawId is removed from here the moment its link/override is set
  /// through the ordinary manual picker, or cleared outright — either
  /// one means it's no longer "just an auto guess". Namespaced per
  /// playlist and per feature (two separate keys, `_links`/`_epg`
  /// suffixed) like everything else here.
  static const String keyAutoPairedChannelLinks = 'nox_auto_paired_links';
  static const String keyAutoPairedEpgOverrides = 'nox_auto_paired_epg';
  static const String keyFavoritedGroups = 'nox_favorited_groups';

  /// User-chosen group order (long-press a group → Move), per playlist and
  /// per viewer, one list per content type ('tv'/'vod'/'series'): the key
  /// gets a `_<type>` suffix before the usual playlist/viewer suffixes.
  static const String keyGroupOrder = 'nox_group_order';

  /// User-chosen live channel order inside a group (hold OK on a channel →
  /// Move Up / Down), per playlist and per viewer: one JSON map of group
  /// title → ordered `Channel.rawId`s.
  static const String keyChannelOrder = 'nox_channel_order';

  /// Live Favourites order across playlists, per viewer; composite channel ids.
  static const String keyFavoriteLiveOrder = 'vesper_favorite_live_order';

  /// The viewer's own live groups, across every playlist (see
  /// `UserGroups` for the JSON). Per viewer, not per playlist.
  static const String keyMyGroups = 'nox_my_groups';

  /// Playlists whose groups are hidden from one category's groups column
  /// and browse rows (groups column > Playlists > Right > Hide), per viewer;
  /// the key gets a `_<category>` suffix ('tv'/'vod'/'series'). Their
  /// channels stay in Search and Favourites and keep playing.
  static const String keyHiddenPlaylistGroups = 'vesper_hidden_playlist_groups';
  static const String keyRecentSearches = 'nox_recent_searches';

  /// The JSON-encoded `List<PlaylistProfile>` — the whole multi-playlist
  /// list lives in one SharedPreferences string, same "small scalar" shape
  /// as everything else in this section (unlike the EPG cache, which is
  /// genuinely large and lives in a disk cache file instead — see
  /// cacheFileEpgPrograms below). Deliberately NOT a cache file: this has
  /// to survive `StorageService.clearCache()`, which wipes the whole
  /// OS-reclaimable cache directory on purpose.
  static const String keyPlaylists = 'nox_playlists';

  /// One-time guard so `PlaylistManager._migrateLegacySinglePlaylist` only
  /// ever runs once per install, even across many future launches.
  static const String keyMigratedToMultiPlaylist =
      'nox_migrated_multi_playlist';
  static const String keyEpgCache = 'nox_epg_cache';
  static const String keyEpgLastUpdated = 'nox_epg_last_updated';
  static const String keyLastChannelId = 'nox_last_channel_id';
  static const String keyLastPositionPrefix = 'nox_last_position_';
  static const String keyLastDurationPrefix = 'nox_last_duration_';

  // --- Viewer profiles -----------------------------------------------------
  // See `ViewerProfile`'s doc comment for the feature this supports: several
  // viewers sharing one device/playlist set, each with their own favorites/
  // hidden-groups/watch-history. `mainViewerId`'s data lives under every
  // *existing* unsuffixed key above completely unchanged — an upgrading
  // install with no viewer profiles yet is simply "Main", reading exactly
  // what it already had, with no migration/data-movement step at all. Only
  // a second-or-later viewer's data gets the `__vp_<id>` suffix added by
  // `StorageService`'s viewer-scoping helpers.
  static const String mainViewerId = 'main';
  static const String keyViewerProfiles = 'nox_viewer_profiles';
  static const String keyActiveViewerId = 'nox_active_viewer';
  static const String keyParentalPin = 'nox_parental_pin';
  static const String keyPinFailCount = 'nox_pin_fail_count';
  static const String keyPinLockedUntil = 'nox_pin_locked_until';

  /// One-time guard — see `PlaylistManager`'s favorites-reconciliation step
  /// in its `init()`, which only ever needs to run once per install.
  static const String keyFavoritesDbReconciled = 'nox_fav_db_reconciled';

  /// Suffix appended to a per-viewer-scoped key for every viewer except
  /// [mainViewerId] — see `StorageService._vk`.
  static const String viewerKeySuffix = '__vp_';

  /// LEGACY global scalar — when the last full catalog sync completed.
  /// Per-playlist now (`'${keyLastFullSyncAt}_$playlistId'`, read/written
  /// via `StorageService.getLastFullSyncAt(playlistId)`/
  /// `setLastFullSyncAt`); this bare key is only read once, during
  /// migration. See PlaylistManager.needsFullSync/runFullCatalogSync.
  static const String keyLastFullSyncAt = 'nox_last_full_sync_at';

  /// LEGACY global scalar — "how often" for the above. Per-playlist now,
  /// as `PlaylistProfile.syncFrequencyDays`; this bare key is only read
  /// once, during migration. The default remains days for old profiles;
  /// the detail-panel choices below use hours (24 hours = one day).
  static const String keySyncFrequencyDays = 'nox_sync_frequency_days';
  static const int defaultSyncFrequencyDays = 3;
  static const List<int> syncFrequencyHoursOptions = [
    1,
    3,
    6,
    24,
    72,
    168,
    240,
    336
  ];

  // LEGACY global scalars — one playlist's mode/login, superseded by
  // PlaylistProfile. Only read once, during migration.
  static const String keyPlaylistMode = 'nox_playlist_mode';
  static const String keyXtreamServer = 'nox_xtream_server';
  static const String keyXtreamUsername = 'nox_xtream_username';
  static const String keyXtreamPassword = 'nox_xtream_password';

  static const String keyShowClock = 'nox_show_clock';
  static const String keyMultiviewHideTips = 'vesper_multiview_hide_tips';
  static const String keyMultiviewQuad = 'vesper_multiview_quad';
  static const String keyMultiviewMain = 'vesper_multiview_main';
  static const String keyResumeLastChannelAtStartup =
      'vesper_resume_last_channel_at_startup';

  /// Startup alternative to the full-screen resume above: the last channel
  /// plays in the guide's preview box. At most one of the two is on.
  static const String keyResumeLastChannelInGuide =
      'vesper_resume_last_channel_in_guide';
  static const String keyShowResumePill = 'vesper_show_resume_pill';

  /// Hides the Movies and TV Shows tabs (and their search results) — for
  /// people who get movies/shows elsewhere (debrid etc.).
  static const String keyHideMoviesShows = 'vesper_hide_movies_shows';
  // Split from keyHideMoviesShows (which now only seeds these two).
  static const String keyHideMovies = 'vesper_hide_movies';
  static const String keyHideShows = 'vesper_hide_shows';
  static const String keyHideArchive = 'vesper_hide_archive';
  static const String keyHideRecordings = 'vesper_hide_recordings';
  static const String keyHideCatchupGroup = 'vesper_hide_catchup_group';
  static const String keyHideMultiview = 'vesper_hide_multiview';

  /// Favourites (TV, Movies, TV Shows) as one list across playlists,
  /// A-Z, instead of one block per playlist.
  static const String keyMixFavoritePlaylists = 'vesper_mix_favorite_playlists';
  static const String keyShowGroupCounts = 'vesper_show_group_counts';

  /// Settings > Backup & restore: weekly automatic backup on/off (off by
  /// default) and the last one's time (ms since epoch; never backed up).
  static const String keyAutoBackup = 'vesper_auto_backup';

  /// Settings > General > Background video: hide the live picture (not
  /// the stream) while Sports Trak, Settings or Search is open — opt-in
  /// workaround for Fire TV sticks that keep drawing it on top.
  /// Device-only (not transferred). Key name predates Settings/Search.
  static const String keyHideVideoOnSports = 'vesper_hide_video_on_sports';
  static const String keyCompatVideo = 'vesper_compat_video';

  /// Last downloaded automatic per-device defaults list (DeviceDefaults).
  static const String keyDeviceDefaults = 'vesper_device_defaults';

  /// Settings > Playback > Audio: HDMI passthrough on the main player
  /// (device-only; AppPreferences.audioPassthrough).
  static const String keyAudioPassthrough = 'vesper_audio_passthrough';

  /// Settings > Playback > Background video: Shield green-flicker fix
  /// (device-only; AppPreferences.videoMediaOverlay).
  static const String keyVideoMediaOverlay = 'vesper_video_media_overlay';

  /// Settings > Playback > Background video: Native video surface (beta,
  /// device-only; AppPreferences.nativeVideoSurface). MainActivity reads it
  /// as `flutter.vesper_native_video_surface` — keep the two in step.
  static const String keyNativeVideoSurface = 'vesper_native_video_surface';

  /// Settings > Playback > Frame rate & resolution (device-only; DisplayMatch).
  static const String keyMatchFrameRate = 'vesper_match_frame_rate';
  static const String keyMatch5060Only = 'vesper_match_5060_only';
  static const String keyMatchResolution = 'vesper_match_resolution';

  /// Subtitle size picked in the player's Subtitles menu (device-only;
  /// AppPreferences.subtitleScale).
  static const String keyLiveGroupSort = 'vesper_live_group_sort';

  static const String keySubtitleScale = 'vesper_subtitle_scale';

  /// Settings > General > Startup > Open on (device-only;
  /// AppPreferences.startSection).
  static const String keyStartSection = 'vesper_start_section';

  /// Set while the start section opens, cleared 15 s later: still set at
  /// the next launch = it crashed there, so that launch opens on TV.
  static const String keyStartSectionPending = 'vesper_start_section_pending';

  /// Settings > General > Startup: Fast startup (opt-in, owner
  /// 2026-10-21) — the UI opens without waiting for Movies/TV Shows to
  /// pre-load. Device-only: the slow splash protects weak boxes (§10).
  static const String keyFastStartup = 'vesper_fast_startup';

  /// Device-wide opt-in: choose a viewer after the splash, before startup routes
  /// or automatic playback. Backups retain it; transfers keep the target choice.
  static const String keyLaunchWithProfiles = 'vesper_launch_with_profiles';
  static const String keyDataPool = 'vesper_data_pool';
  // Settings > Playback > Catch-up: carry on past the programme (off =
  // stop at its end).
  static const String keyCatchupKeepPlaying = 'vesper_catchup_keep_playing';
  // Settings > Playback > Skip intro: the IntroDB skip button on episodes
  // (on by default; services/skip_segments.dart).
  static const String keySkipSegments = 'vesper_skip_segments';
  static const String keyUpNextMode = 'vesper_up_next_mode';
  // Live channel ids seen playing at real 4K (Real4kChannels), list.
  static const String keyReal4kChannels = 'vesper_real_4k_channels';
  // Media Hub placeholder clips re-asked + titles tagged Ready
  // (ArchiveReadyWatch), JSON. Device-only.
  static const String keyArchiveReadyWatch = 'vesper_hub_ready_watch';
  // Expand catalog: the last sort picked, per category (+ 'vod'/'series').
  static const String keyCatalogSortPrefix = 'vesper_catalog_sort_';
  // Settings > Media Hub > Debrid accounts (DebridApi): the user's own
  // Real-Debrid API token / TorBox API key.
  static const String keyRealDebridToken = 'vesper_real_debrid_token';
  static const String keyTorBoxKey = 'vesper_torbox_key';
  static const String keyLastAutoBackup = 'vesper_last_auto_backup';

  /// Sports tab, per viewer: leagues shown (ordered ids), spoiler mode, and
  /// the user's own game -> channel picks (JSON, see `SportsChannelPicks`).
  static const String keySportsLeagues = 'vesper_sports_leagues';
  static const String keySportsChannelLists = 'vesper_sports_channel_lists';
  static const String keySportsPreferredCountries =
      'vesper_sports_preferred_countries';
  static const String keySportsPreferredPlaylist =
      'vesper_sports_preferred_playlist';
  static const String keySportsHideEmptyLeagues =
      'vesper_sports_hide_empty_leagues';
  static const String keySportsShowOdds = 'vesper_sports_show_odds';
  static const String keySportsAutoPlay = 'vesper_sports_auto_play';

  /// Home page rows, per viewer: ordered row ids, a hidden row as `-id`
  /// (`HomeRows`). Null = never edited (the default order).
  static const String keyHomeRows = 'vesper_home_rows';
  static const String keyHideProfiles = 'vesper_hide_profiles';
  static const String keySportsAddedLeagues = 'vesper_sports_added_leagues';
  static const String keySportsHideScores = 'vesper_sports_hide_scores';
  static const String keySportsMode = 'vesper_sports_mode';
  static const String keySportsChannelPicks = 'vesper_sports_channel_picks';
  static const String keyGoalsAlert = 'vesper_goals_alert';
  static const String keyTransparentPopups = 'vesper_transparent_popups';
  static const String keyMatchScoreAlerts = 'vesper_match_score_alerts';
  static const String keyLeagueGoalAlerts = 'vesper_league_goal_alerts';
  static const String keySportsFollowedTeams = 'vesper_sports_followed_teams';
  static const String keyGameReminders = 'vesper_game_reminders';
  static const String keyProgrammeReminders = 'vesper_programme_reminders';

  /// Per viewer: the favourite league (League manager, hold OK): Sports Trak
  /// opens on it and its games lead the player side panel's Live now.
  static const String keySportsFavoriteLeague = 'vesper_sports_favorite_league';

  /// Per viewer; Main retains its original unsuffixed key.
  static const String keyPaletteId = 'nox_palette_id';
  static const String keyRefinedFinish = 'vesper_refined_finish';
  static const String keyViewerPalettesMigrated =
      'vesper_viewer_palettes_migrated';

  /// UI layout: 'auto' picks phone vs TV by screen size, 'phone'/'tv' force
  /// one regardless — needed because plenty of real Android boxes (this
  /// one included) aren't officially certified Android TV devices, so
  /// there's no fully reliable automatic signal for "this is a TV".
  static const String keyLayoutMode = 'nox_layout_mode';

  /// This device's pending internet transfer (`cloud_transfer.dart`), JSON
  /// `{"code": "...", "expires": <ms>}` — so Send can show it again and
  /// delete it. Device-only: never part of a transfer.
  static const String keyCloudTransfer = 'vesper_cloud_transfer';

  /// UI language for the whole device (not per viewer): 'auto' follows the
  /// system language, or a language code ('en', 'fr', 'es', 'it'). See lib/l10n/l10n.dart.
  static const String keyLanguage = 'vesper_language';

  /// Windows: windowed instead of full screen, and the window's last
  /// bounds ("x,y,w,h") — see DesktopWindow. This PC only.
  static const String keyWindowsWindowed = 'vesper_windows_windowed';
  static const String keyWindowsBounds = 'vesper_windows_bounds';
  // Windows player volume 0-100 and mute (device-only, like the bounds).
  static const String keyDesktopVolume = 'vesper_desktop_volume';
  static const String keyDesktopMuted = 'vesper_desktop_muted';

  /// Fullscreen player: zoom the picture to fill the screen (crops the
  /// edges) instead of fitting it with black bars — the player's ⛶ button.
  /// This device only (a phone and a TV want different things).
  static const String keyVideoFill = 'vesper_video_fill';

  /// 24-hour (default) vs 12-hour times everywhere — `utils/time_format.dart`.
  static const String keyTime24h = 'vesper_time_24h';

  /// Release tag the launch update popup was told to skip
  /// (`widgets/update_prompt.dart`); a newer tag is offered again.
  static const String keySkippedUpdateVersion = 'vesper_skipped_update';

  /// Next splash greeting to show (index into SplashGreeting.bank).
  static const String keySplashGreeting = 'vesper_splash_greeting';

  /// Live TV presentation: 'live' (single-channel now/next) or 'timeline'
  /// (cable-guide grid, all visible channels at once).
  static const String keyGuideViewMode = 'nox_guide_view_mode';

  /// Timeline guide only: the live video fills the whole screen behind a
  /// translucent guide (and a 3-row grid) instead of the small corner box.
  static const String keyGuideFullVideo = 'vesper_guide_full_video';

  static const String keyGuideExpanded = 'vesper_guide_expanded';
  static const String keyGuideCompact = 'vesper_guide_compact';
  static const String keyExpandedBrowse = 'vesper_expanded_browse';

  /// LEGACY global scalar — "enable/disable playlist" (freeing a
  /// provider's connection slot for another device without touching
  /// cached catalog/credentials). Per-playlist now, as
  /// `PlaylistProfile.enabled`; this bare key is only read once, during
  /// migration.
  static const String keyPlaylistEnabled = 'nox_playlist_enabled';

  /// Duo-tone accent palettes offered in Settings > Theme — replaced the
  /// old flat single-color presets, which couldn't represent a deliberate
  /// two-hue "cyberpunk" accent (Material's `ColorScheme.fromSeed` only
  /// derives one hue's tonal ramp). "Dark/Gold" is deliberately the most
  /// restrained of the four — muted rather than neon — so there's a safe
  /// option for a shared device an older user might also use.
  static const List<CyberpunkPalette> cyberpunkPalettes = [
    // First entry is the fresh-install default — see
    // StorageService.getPaletteId's fallback and AppPreferences._paletteById's
    // orElse, both of which fall back to cyberpunkPalettes.first.
    //
    // primary/secondary here are VesperTV's brand gold/amber (this used to
    // be the Neon Purple pair, from before the rename) — not shown as a
    // colored gradient/fill anywhere (see CyberpunkPalette.isMinimal), just
    // kept as the wordmark's own accent (and the small section-header
    // accent bars) so the default theme reads as the brand rather than
    // plain white.
    CyberpunkPalette(
      id: 'minimal',
      label: 'Platinum',
      primary: Color(0xFFF0C75E),
      secondary: Color(0xFFC9781A),
      isMinimal: true,
    ),
    CyberpunkPalette(
      id: 'red_blue',
      label: 'Rosé',
      primary: Color(0xFFE5393F),
      secondary: Color(0xFF2979FF),
    ),
    CyberpunkPalette(
      id: 'purple_magenta',
      label: 'Neon Purple',
      primary: Color(0xFF7C3AED),
      secondary: Color(0xFFE91E8C),
    ),
    // Owner, 2026-10-17: "same as the others, just green". `vivid` keeps the
    // neon (seeding it gave a pale mint). New id, not the retired
    // 'green_orange' (that one maps to Blue).
    CyberpunkPalette(
      id: 'neon_green',
      label: 'Neon Green',
      // Toned down from 39FF14 (owner: "nice but can be too much").
      primary: Color(0xFF2FD414),
      secondary: Color(0xFF00B86B),
      vivid: true,
    ),
    CyberpunkPalette(
      id: 'aqua',
      label: 'Aqua',
      primary: Color(0xFF22D3EE),
      secondary: Color(0xFF14B8A6),
      vivid: true,
    ),
    // Owner, 2026-10-28: standalone Red and Blue, using the same vivid
    // treatment as Aqua. Legacy Habs/Green-Orange choices resolve to Blue.
    CyberpunkPalette(
      id: 'red',
      label: 'Red',
      primary: Color(0xFFF45145),
      secondary: Color(0xFFC52C42),
      vivid: true,
    ),
    CyberpunkPalette(
      id: 'blue',
      label: 'Blue',
      primary: Color(0xFF4C8DFF),
      secondary: Color(0xFF2563EB),
      vivid: true,
    ),
    // "Antique Shine" — a hand-built scheme (see CyberpunkPalette.trueBlack),
    // not a seeded one: D4AF37 run through ColorScheme.fromSeed in dark mode
    // muted toward olive/brown, reported directly as looking "yellow-brown"
    // against a background that was a heavy gold-to-black wash rather than
    // true OLED black. `highlight` stays out of the interactive ColorScheme
    // entirely (see CyberpunkPalette.highlight's doc comment):
    // a pale champagne tint painted as a wide solid fill read as a washed
    // "Game Boy" look on real hardware, not gold. It's purely the
    // wordmark's gradient shine; `primary` (the base gold) drives every
    // focus/selected/badge surface.
    CyberpunkPalette(
      id: 'dark_gold',
      label: 'Dark / Gold',
      primary: Color(0xFFC9A355),
      secondary: Color(0xFF7A5A22),
      highlight: Color(0xFFF6E2A8),
      trueBlack: true,
    ),
  ];

  // On-disk cache file names (under the OS temp/cache directory — safe to
  // lose; the app just re-fetches from the network if they're missing).
  static const String cacheFileM3uChannels = 'm3u_channels';
  static const String cacheFileLiveChannels = 'xtream_live_channels';
  static const String cacheFileLiveCategories = 'xtream_live_categories';
  static const String cacheFileVodCategories = 'xtream_vod_categories';
  static const String cacheFileSeriesCategories = 'xtream_series_categories';
  // Per-category VOD/series *items* (not just the category list above) live
  // in CatalogDatabase (a real local database) now, not a JSON file per
  // category — see that class's doc comment for why.

  /// EPG programme cache. Was a SharedPreferences string (`keyEpgCache`,
  /// kept below only so `clearCache` can sweep away any leftover value
  /// from before this changed) — SharedPreferences backs onto a single XML
  /// file the OS loads whole, which is a bad fit for a full-catalog EPG
  /// blob that can be many MB; moved to the same disk-file cache the
  /// playlist/catalog data already uses.
  /// Superseded by `EpgDatabase` — kept only so `EpgService.init` can
  /// delete the leftover file on upgrading installs.
  static const String cacheFileEpgPrograms = 'epg_programs';

  /// Rolling window `EpgDatabase` keeps. Past: the Timeline guide shows 1 h
  /// back, so 2 h covers it; channels with catch-up keep their own longer
  /// past ([catchupEpgMaxDays], `EpgService.catchupDaysProvider`). Future: anything *starting* within 36 h — with the
  /// 12 h default refresh that leaves ~24 h of guide if refreshes fail or
  /// the box stays off.
  static const Duration epgPastRetention = Duration(hours: 2);
  static const Duration epgFutureWindow = Duration(hours: 36);

  /// Most days of past programmes kept for a catch-up channel, whatever
  /// the provider's archive length (DB size; providers' guides rarely
  /// reach back more than a day anyway — Blcktv's reaches 12 h).
  static const int catchupEpgMaxDays = 7;

  /// EPG auto-refresh. Was 15-120 min — each refresh is ~45 s of heavy
  /// work on a Formuler (measured), so every 30 min cost a quarter of the
  /// box's time. A stored legacy value falls back to the default (see
  /// `StorageService.getRefreshInterval`).
  static const int defaultRefreshIntervalMinutes = 720;
  static const List<int> refreshIntervalOptions = [360, 720, 1440];
}
