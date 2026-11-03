import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/channel.dart';
import '../models/playlist_profile.dart';
import '../models/viewer_profile.dart';
import '../models/profile_copy.dart';
import 'profile_photos.dart';
import 'local_playlist_files.dart';
import '../utils/constants.dart';

/// Wraps [SharedPreferences] for small settings values, and the OS temp
/// directory for larger cached payloads (parsed playlist/catalog JSON) —
/// multi-MB strings don't belong in SharedPreferences' XML-backed store,
/// and living under the temp dir means the OS can reclaim them under
/// storage pressure with no worse outcome than "re-fetch from network".
class StorageService {
  StorageService({ProfilePhotos? photos, LocalPlaylistFiles? localPlaylists})
      : profilePhotos = photos ?? ProfilePhotos(),
        localPlaylists = localPlaylists ?? LocalPlaylistFiles();
  late SharedPreferences _prefs;
  Directory? _cacheDir;
  final ProfilePhotos profilePhotos;
  final LocalPlaylistFiles localPlaylists;

  /// Include associated private files alongside the preference payload.
  Future<Map<String, Object>> withProfilePhotos(
      Map<String, Object> values) async {
    final snapshots = await localPlaylists.export(getPlaylists());
    return {
      ...values,
      'vesper_profile_photos': await profilePhotos.export(getViewerProfiles()
          .where((p) => p.photoVersion > 0)
          .map((p) => p.id)),
      if (snapshots.isNotEmpty) 'vesper_imported_playlists': snapshots,
    };
  }

  /// Only a newly created viewer is a valid destination. Main is read-only.
  Future<void> copyMainToViewer(String id, Set<ProfileCopy> options,
      {required bool restricted}) async {
    if (id == AppConstants.mainViewerId ||
        !ProfilePhotos.validId(id) ||
        getViewerProfiles().any((p) => p.id == id)) {
      throw ArgumentError('Invalid destination');
    }
    final selected = {...options};
    if (restricted) selected.remove(ProfileCopy.visibility);
    for (final key
        in _prefs.getKeys().where((k) => copyMainKey(k, selected)).toList()) {
      final target = _vk(key, viewerId: id);
      final value = _prefs.get(key);
      switch (value) {
        case String s:
          await _prefs.setString(target, s);
        case bool b:
          await _prefs.setBool(target, b);
        case int n:
          await _prefs.setInt(target, n);
        case double n:
          await _prefs.setDouble(target, n);
        case List<String> l:
          await _prefs.setStringList(target, [...l]);
      }
    }
    if (selected.contains(ProfileCopy.history)) {
      final history = await readCacheFile('recently_played');
      if (history != null) {
        await writeCacheFile('recently_played_vp_$id', history);
      }
    }
  }

  int viewerGroupCount(String playlistId, String viewerId,
          {bool allowed = false}) =>
      (_prefs.getStringList(_vk(
                  '${allowed ? AppConstants.keyShownGroups : AppConstants.keyHiddenGroups}_$playlistId',
                  viewerId: viewerId)) ??
              [])
          .length;
  int viewerHiddenChannelCount(String playlistId, String viewerId) =>
      (_prefs.getStringList(_vk('${AppConstants.keyHiddenChannels}_$playlistId',
                  viewerId: viewerId)) ??
              [])
          .length;

  /// See the "Viewer-profile scoping" section below for what this drives.
  /// Loaded once at [init] and kept in memory rather than read from
  /// [_prefs] on every single per-viewer getter/setter — `ViewerProfileService
  /// .switchTo` updates this (via [setActiveViewerId]) and the persisted
  /// value together, in that order, before anything else reads a
  /// per-viewer key again, so there's never a window where the two disagree.
  int viewerGeneration = 0;
  String _activeViewerId = AppConstants.mainViewerId;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _activeViewerId = _prefs.getString(AppConstants.keyActiveViewerId) ??
        AppConstants.mainViewerId;
    await _migrateViewerPalettes();
  }

  /// Snapshot the old shared colour for existing viewers once. Main's
  /// original key is read only; future profiles start with the default.
  Future<void> _migrateViewerPalettes() async {
    if (_prefs.getBool(AppConstants.keyViewerPalettesMigrated) == true) return;
    final legacy = _prefs.getString(AppConstants.keyPaletteId);
    if (legacy != null) {
      for (final viewer in getViewerProfiles()) {
        if (viewer.id == AppConstants.mainViewerId) continue;
        final key = _vk(AppConstants.keyPaletteId, viewerId: viewer.id);
        if (!_prefs.containsKey(key)) await _prefs.setString(key, legacy);
      }
    }
    await _prefs.setBool(AppConstants.keyViewerPalettesMigrated, true);
  }

  Future<Directory> _ensureCacheDir() async {
    final existing = _cacheDir;
    if (existing != null) return existing;
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}/nox_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  // --- Generic on-disk JSON cache -----------------------------------------

  Future<void> writeCacheFile(String name, String content) async {
    final dir = await _ensureCacheDir();
    final file = File('${dir.path}/$name.json');
    try {
      await file.writeAsString(content);
    } on PathNotFoundException {
      // Android can clear the cache folder while the app runs (MIBOX4,
      // LOG-V5ET8S: every recently_played write failed until restart).
      await dir.create(recursive: true);
      await file.writeAsString(content);
    }
  }

  /// Path of a cache file if it exists, for callers that read *and*
  /// decode it on a background isolate. [readCacheFile] reads on the
  /// calling isolate, and `File.readAsString` does its whole UTF-8 decode
  /// there as one uninterrupted task — measured on real hardware as ~43%
  /// of the main thread's time across a cold start, because the big cache
  /// files (live channels, EPG) are tens of MB and channel names full of
  /// non-ASCII (superscript "ᴴᴰ", "ᴿᴬᵂ"...) force the slow two-byte decode
  /// path. With Dart now sharing Android's main thread, a remote key press
  /// that lands during one of those decodes can wait past Android's 5s
  /// input timeout and get the app killed as not responding. Handing the
  /// isolate a path instead also avoids copying the whole decoded string
  /// into it, which `compute(decode, rawString)` did on the main thread too.
  Future<String?> cacheFilePath(String name) async {
    final dir = await _ensureCacheDir();
    final file = File('${dir.path}/$name.json');
    return await file.exists() ? file.path : null;
  }

  Future<String?> readCacheFile(String name) async {
    final dir = await _ensureCacheDir();
    final file = File('${dir.path}/$name.json');
    if (!await file.exists()) return null;
    try {
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteCacheFile(String name) async {
    final dir = await _ensureCacheDir();
    final file = File('${dir.path}/$name.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  // --- Multi-playlist list --------------------------------------------------

  List<PlaylistProfile> getPlaylists() {
    final raw = _prefs.getString(AppConstants.keyPlaylists);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => PlaylistProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setPlaylists(List<PlaylistProfile> playlists) =>
      _prefs.setString(AppConstants.keyPlaylists,
          jsonEncode(playlists.map((p) => p.toJson()).toList()));

  bool getMigratedToMultiPlaylist() =>
      _prefs.getBool(AppConstants.keyMigratedToMultiPlaylist) ?? false;
  Future<void> setMigratedToMultiPlaylist(bool value) =>
      _prefs.setBool(AppConstants.keyMigratedToMultiPlaylist, value);

  // --- Legacy single-playlist scalars — read-only, migration use only ------
  // See AppConstants' doc comment on these keys: nothing writes any of these
  // anymore, they only feed PlaylistManager._migrateLegacySinglePlaylist.

  String? getLegacyM3uUrl() => _prefs.getString(AppConstants.keyM3uUrl);
  String? getLegacyEpgUrl() => _prefs.getString(AppConstants.keyEpgUrl);
  String getLegacyPlaylistMode() =>
      _prefs.getString(AppConstants.keyPlaylistMode) ?? 'm3u';
  String? getLegacyXtreamServer() =>
      _prefs.getString(AppConstants.keyXtreamServer);
  String? getLegacyXtreamUsername() =>
      _prefs.getString(AppConstants.keyXtreamUsername);
  String? getLegacyXtreamPassword() =>
      _prefs.getString(AppConstants.keyXtreamPassword);
  bool getLegacyPlaylistEnabled() =>
      _prefs.getBool(AppConstants.keyPlaylistEnabled) ?? true;
  Set<String> getLegacyHiddenGroups() =>
      (_prefs.getStringList(AppConstants.keyHiddenGroups) ?? []).toSet();
  Set<String> getLegacyFavoritedGroups() =>
      (_prefs.getStringList(AppConstants.keyFavoritedGroups) ?? []).toSet();
  int getLegacySyncFrequencyDays() =>
      _prefs.getInt(AppConstants.keySyncFrequencyDays) ??
      AppConstants.defaultSyncFrequencyDays;
  DateTime? getLegacyLastFullSyncAt() {
    final raw = _prefs.getString(AppConstants.keyLastFullSyncAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  int getRefreshInterval() {
    final stored = _prefs.getInt(AppConstants.keyRefreshInterval);
    // A pre-database install stored 15-120 min — not an option any more.
    return AppConstants.refreshIntervalOptions.contains(stored)
        ? stored!
        : AppConstants.defaultRefreshIntervalMinutes;
  }

  Future<void> setRefreshInterval(int minutes) =>
      _prefs.setInt(AppConstants.keyRefreshInterval, minutes);

  /// Null/empty means "release-date sorting is off" — `TmdbEnrichmentService`
  /// treats a missing key as a no-op rather than erroring, so a user who
  /// never sets one just never sees that sort option do anything, instead
  /// of a hard failure.
  String? getTmdbApiKey() => _prefs.getString(AppConstants.keyTmdbApiKey);
  Future<void> setTmdbApiKey(String key) =>
      _prefs.setString(AppConstants.keyTmdbApiKey, key);

  /// Settings > Media Hub > Custom posters — see `ArchivePosters`.
  String getArchivePosterPattern() =>
      _prefs.getString(AppConstants.keyArchivePosterPattern) ?? '';
  Future<void> setArchivePosterPattern(String pattern) =>
      _prefs.setString(AppConstants.keyArchivePosterPattern, pattern);

  /// Settings > Media Hub > Debrid accounts — see `DebridApi`.
  String? getRealDebridToken() =>
      _prefs.getString(AppConstants.keyRealDebridToken);
  Future<void> setRealDebridToken(String token) =>
      _prefs.setString(AppConstants.keyRealDebridToken, token);
  String? getTorBoxKey() => _prefs.getString(AppConstants.keyTorBoxKey);
  Future<void> setTorBoxKey(String key) =>
      _prefs.setString(AppConstants.keyTorBoxKey, key);

  /// Subtitle add-ons, see AddonService. Null = never saved (defaults).
  String? getAddonsJson() => _prefs.getString(AppConstants.keyAddons);
  Future<void> setAddonsJson(String json) =>
      _prefs.setString(AppConstants.keyAddons, json);

  /// Archive tab sources (ArchiveService). Null = never saved (none).
  double getDesktopVolume() =>
      _prefs.getDouble(AppConstants.keyDesktopVolume) ?? 100;
  Future<void> setDesktopVolume(double value) =>
      _prefs.setDouble(AppConstants.keyDesktopVolume, value);
  /// Windows: draw video without the GPU path (Settings > Playback >
  /// Software video). Device-only.
  bool getDesktopSoftwareVideo() =>
      _prefs.getBool('vesper_desktop_software_video') ?? false;
  Future<void> setDesktopSoftwareVideo(bool value) =>
      _prefs.setBool('vesper_desktop_software_video', value);

  bool getDesktopMuted() =>
      _prefs.getBool(AppConstants.keyDesktopMuted) ?? false;
  Future<void> setDesktopMuted(bool value) =>
      _prefs.setBool(AppConstants.keyDesktopMuted, value);

  String? getArchiveFavoritesJson() =>
      _prefs.getString(_vk(AppConstants.keyArchiveFavorites));
  Future<void> setArchiveFavoritesJson(String? json) => json == null
      ? _prefs.remove(_vk(AppConstants.keyArchiveFavorites))
      : _prefs.setString(_vk(AppConstants.keyArchiveFavorites), json);

  String? getArchiveHistoryJson() =>
      _prefs.getString(_vk(AppConstants.keyArchiveHistory));
  Future<void> setArchiveHistoryJson(String? json) => json == null
      ? _prefs.remove(_vk(AppConstants.keyArchiveHistory))
      : _prefs.setString(_vk(AppConstants.keyArchiveHistory), json);

  /// Profile-scoped Media Hub presentation and playback preferences.
  String? getArchiveOptionsJson(String section) =>
      _prefs.getString(_vk('vesper_archive_$section'));
  Future<void> setArchiveOptionsJson(String section, String json) =>
      _prefs.setString(_vk('vesper_archive_$section'), json);

  String? getArchiveRecentSearchesJson() =>
      _prefs.getString(_vk(AppConstants.keyArchiveRecentSearches));
  Future<void> setArchiveRecentSearchesJson(String json) =>
      _prefs.setString(_vk(AppConstants.keyArchiveRecentSearches), json);

  String? getArchiveSourcesJson() =>
      _prefs.getString(AppConstants.keyArchiveSources);
  bool getArchiveCinemetaCatalog() =>
      _prefs.getBool(AppConstants.keyArchiveCinemetaCatalog) ?? true;
  Future<void> setArchiveCinemetaCatalog(bool on) =>
      _prefs.setBool(AppConstants.keyArchiveCinemetaCatalog, on);
  Future<void> setArchiveSourcesJson(String json) =>
      _prefs.setString(AppConstants.keyArchiveSources, json);

  /// Languages picked from online subtitles (add-on codes like "fre"),
  /// most recent first — the player's Subtitles list offers them directly.
  String? getSeriesSubtitlesJson() =>
      _prefs.getString(_vk(AppConstants.keySeriesSubtitles));
  Future<void> setSeriesSubtitlesJson(String json) =>
      _prefs.setString(_vk(AppConstants.keySeriesSubtitles), json);

  String getPreferredAudioLanguage() =>
      _prefs.getString(_vk(AppConstants.keyPreferredAudioLanguage)) ?? '';
  Future<void> setPreferredAudioLanguage(String value) =>
      _prefs.setString(_vk(AppConstants.keyPreferredAudioLanguage), value);
  String getPreferredSubtitleLanguage() =>
      _prefs.getString(_vk(AppConstants.keyPreferredSubtitleLanguage)) ?? 'off';
  Future<void> setPreferredSubtitleLanguage(String value) =>
      _prefs.setString(_vk(AppConstants.keyPreferredSubtitleLanguage), value);
  String? getAudioTrackChoicesJson() =>
      _prefs.getString(_vk(AppConstants.keyAudioTrackChoices));
  Future<void> setAudioTrackChoicesJson(String value) =>
      _prefs.setString(_vk(AppConstants.keyAudioTrackChoices), value);

  List<String> getOnlineSubtitleLangs() =>
      _prefs.getStringList(AppConstants.keyOnlineSubtitleLangs) ?? const [];
  Future<void> addOnlineSubtitleLang(String lang) {
    final list = [lang, ...getOnlineSubtitleLangs().where((l) => l != lang)];
    return _prefs.setStringList(
        AppConstants.keyOnlineSubtitleLangs, list.take(3).toList());
  }

  /// When "What's New" was last TMDB-enriched — see
  /// `PlaylistManager.refreshWhatsNewTmdbIfDue`'s doc comment. Null means
  /// never (a freshly-added key, or TMDB sorting never used at all).
  DateTime? getWhatsNewTmdbLastRefreshed() {
    final raw = _prefs.getString(AppConstants.keyWhatsNewTmdbLastRefreshed);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setWhatsNewTmdbLastRefreshed(DateTime time) => _prefs.setString(
      AppConstants.keyWhatsNewTmdbLastRefreshed, time.toIso8601String());

  /// See `AppConstants.keyWhatsNewVodIds`'s doc comment. Empty (not null)
  /// when never refreshed yet — callers treat that as "nothing curated
  /// yet", same as any other empty list.
  List<String> getWhatsNewVodIds() =>
      _prefs.getStringList(AppConstants.keyWhatsNewVodIds) ?? [];
  Future<void> setWhatsNewVodIds(List<String> ids) =>
      _prefs.setStringList(AppConstants.keyWhatsNewVodIds, ids);

  List<String> getWhatsNewSeriesIds() =>
      _prefs.getStringList(AppConstants.keyWhatsNewSeriesIds) ?? [];
  Future<void> setWhatsNewSeriesIds(List<String> ids) =>
      _prefs.setStringList(AppConstants.keyWhatsNewSeriesIds, ids);

  bool getTime24h() => _prefs.getBool(AppConstants.keyTime24h) ?? true;
  Future<void> setTime24h(bool value) =>
      _prefs.setBool(AppConstants.keyTime24h, value);

  String? getSkippedUpdateVersion() =>
      _prefs.getString(AppConstants.keySkippedUpdateVersion);
  Future<void> setSkippedUpdateVersion(String version) =>
      _prefs.setString(AppConstants.keySkippedUpdateVersion, version);

  bool getShowClock() => _prefs.getBool(AppConstants.keyShowClock) ?? true;
  Future<void> setShowClock(bool value) =>
      _prefs.setBool(AppConstants.keyShowClock, value);

  /// "Don't show this again" on the Multiview connections tip.
  bool getMultiviewHideTips() =>
      _prefs.getBool(AppConstants.keyMultiviewHideTips) ?? false;
  Future<void> setMultiviewHideTips(bool value) =>
      _prefs.setBool(AppConstants.keyMultiviewHideTips, value);

  /// Settings > General: open the last live channel fullscreen right after
  /// the splash (Android; Windows always does). Off = the "Hold > to resume"
  /// pill only.
  bool getResumeLastChannelAtStartup() =>
      _prefs.getBool(AppConstants.keyResumeLastChannelAtStartup) ?? true;
  Future<void> setResumeLastChannelAtStartup(bool value) =>
      _prefs.setBool(AppConstants.keyResumeLastChannelAtStartup, value);
  bool getResumeLastChannelInGuide() =>
      _prefs.getBool(AppConstants.keyResumeLastChannelInGuide) ?? false;
  Future<void> setResumeLastChannelInGuide(bool value) =>
      _prefs.setBool(AppConstants.keyResumeLastChannelInGuide, value);
  bool getHideMoviesShows() =>
      _prefs.getBool(AppConstants.keyHideMoviesShows) ?? false;
  Future<void> setHideMoviesShows(bool value) =>
      _prefs.setBool(AppConstants.keyHideMoviesShows, value);

  /// Separate Movies / TV Shows switches; unset = the old combined one.
  bool getHideMovies() =>
      _prefs.getBool(AppConstants.keyHideMovies) ?? getHideMoviesShows();
  Future<void> setHideMovies(bool value) =>
      _prefs.setBool(AppConstants.keyHideMovies, value);
  bool getHideShows() =>
      _prefs.getBool(AppConstants.keyHideShows) ?? getHideMoviesShows();
  Future<void> setHideShows(bool value) =>
      _prefs.setBool(AppConstants.keyHideShows, value);
  bool getVideoFill() => _prefs.getBool(AppConstants.keyVideoFill) ?? false;
  Future<void> setVideoFill(bool value) =>
      _prefs.setBool(AppConstants.keyVideoFill, value);

  /// Null = never set by the user (AppPreferences uses the device default).
  bool? getHideVideoOnSports() =>
      _prefs.getBool(AppConstants.keyHideVideoOnSports);
  Future<void> setHideVideoOnSports(bool value) =>
      _prefs.setBool(AppConstants.keyHideVideoOnSports, value);

  Set<String> getReal4kChannels() =>
      (_prefs.getStringList(AppConstants.keyReal4kChannels) ?? const [])
          .toSet();
  Future<void> setReal4kChannels(Set<String> ids) =>
      _prefs.setStringList(AppConstants.keyReal4kChannels, ids.toList());

  /// Expand catalog's last sort for [category] ('vod'/'series'), by name.
  String? getCatalogSort(String category) =>
      _prefs.getString('${AppConstants.keyCatalogSortPrefix}$category');
  Future<void> setCatalogSort(String category, String sort) =>
      _prefs.setString('${AppConstants.keyCatalogSortPrefix}$category', sort);

  String? getArchiveReadyWatch() =>
      _prefs.getString(AppConstants.keyArchiveReadyWatch);
  Future<void> setArchiveReadyWatch(String json) =>
      _prefs.setString(AppConstants.keyArchiveReadyWatch, json);

  bool getLaunchWithProfiles() =>
      _prefs.getBool(AppConstants.keyLaunchWithProfiles) ?? false;
  Future<void> setLaunchWithProfiles(bool value) =>
      _prefs.setBool(AppConstants.keyLaunchWithProfiles, value);

  bool getFastStartup() => _prefs.getBool(AppConstants.keyFastStartup) ?? true;
  Future<void> setFastStartup(bool value) =>
      _prefs.setBool(AppConstants.keyFastStartup, value);

  String? getLiveGroupSort() => _prefs.getString(AppConstants.keyLiveGroupSort);
  Future<void> setLiveGroupSort(String value) =>
      _prefs.setString(AppConstants.keyLiveGroupSort, value);

  String? getStartSection() => _prefs.getString(AppConstants.keyStartSection);
  bool getStartSectionPending() =>
      _prefs.getBool(AppConstants.keyStartSectionPending) ?? false;
  Future<void> setStartSectionPending(bool value) =>
      _prefs.setBool(AppConstants.keyStartSectionPending, value);
  Future<void> setStartSection(String value) =>
      _prefs.setString(AppConstants.keyStartSection, value);

  double getSubtitleScale() =>
      _prefs.getDouble(AppConstants.keySubtitleScale) ?? 1.0;
  Future<void> setSubtitleScale(double value) =>
      _prefs.setDouble(AppConstants.keySubtitleScale, value);

  bool getAudioPassthrough() =>
      _prefs.getBool(AppConstants.keyAudioPassthrough) ?? false;
  Future<void> setAudioPassthrough(bool value) =>
      _prefs.setBool(AppConstants.keyAudioPassthrough, value);

  bool getVideoMediaOverlay() =>
      _prefs.getBool(AppConstants.keyVideoMediaOverlay) ?? false;
  Future<void> setVideoMediaOverlay(bool value) =>
      _prefs.setBool(AppConstants.keyVideoMediaOverlay, value);

  bool getNativeVideoSurface() =>
      _prefs.getBool(AppConstants.keyNativeVideoSurface) ?? true;
  Future<void> setNativeVideoSurface(bool value) =>
      _prefs.setBool(AppConstants.keyNativeVideoSurface, value);

  bool getMatchFrameRate() =>
      _prefs.getBool(AppConstants.keyMatchFrameRate) ?? false;
  Future<void> setMatchFrameRate(bool value) =>
      _prefs.setBool(AppConstants.keyMatchFrameRate, value);
  bool getMatch5060Only() =>
      _prefs.getBool(AppConstants.keyMatch5060Only) ?? false;
  Future<void> setMatch5060Only(bool value) =>
      _prefs.setBool(AppConstants.keyMatch5060Only, value);
  bool getMatchResolution() =>
      _prefs.getBool(AppConstants.keyMatchResolution) ?? false;
  Future<void> setMatchResolution(bool value) =>
      _prefs.setBool(AppConstants.keyMatchResolution, value);

  /// Null = never chosen (auto, see AppPreferences.compatVideo).
  bool? getCompatVideo() => _prefs.getBool(AppConstants.keyCompatVideo);

  String? getDeviceDefaults() =>
      _prefs.getString(AppConstants.keyDeviceDefaults);
  Future<void> setDeviceDefaults(String json) =>
      _prefs.setString(AppConstants.keyDeviceDefaults, json);
  Future<void> setCompatVideo(bool value) =>
      _prefs.setBool(AppConstants.keyCompatVideo, value);

  /// Settings > General > Data pool display (off by default).
  bool getDataPool() => _prefs.getBool(AppConstants.keyDataPool) ?? false;
  Future<void> setDataPool(bool value) =>
      _prefs.setBool(AppConstants.keyDataPool, value);

  /// Settings > Playback > Catch-up: keep playing past the programme it was
  /// started on (off by default: it stops at the programme's end).
  bool getCatchupKeepPlaying() =>
      _prefs.getBool(AppConstants.keyCatchupKeepPlaying) ?? false;
  Future<void> setCatchupKeepPlaying(bool value) =>
      _prefs.setBool(AppConstants.keyCatchupKeepPlaying, value);

  bool getSkipSegments() =>
      _prefs.getBool(AppConstants.keySkipSegments) ?? true;
  Future<void> setSkipSegments(bool value) =>
      _prefs.setBool(AppConstants.keySkipSegments, value);

  /// Settings > Playback > Up Next: when the next episode starts by itself.
  /// `early` = 30 s before the end (default, the original behaviour),
  /// `end` = when the episode ends, `off` = never (no countdown either).
  String getUpNextMode() {
    final v = _prefs.getString(AppConstants.keyUpNextMode);
    return v == 'end' || v == 'off' ? v! : 'early';
  }

  Future<void> setUpNextMode(String mode) =>
      _prefs.setString(AppConstants.keyUpNextMode, mode);

  bool getMixFavoritePlaylists() =>
      _prefs.getBool(AppConstants.keyMixFavoritePlaylists) ?? false;
  Future<void> setMixFavoritePlaylists(bool value) =>
      _prefs.setBool(AppConstants.keyMixFavoritePlaylists, value);

  bool getShowGroupCounts() =>
      _prefs.getBool(AppConstants.keyShowGroupCounts) ?? false;
  Future<void> setShowGroupCounts(bool value) =>
      _prefs.setBool(AppConstants.keyShowGroupCounts, value);
  bool getHideArchive() => _prefs.getBool(AppConstants.keyHideArchive) ?? false;
  Future<void> setHideArchive(bool value) =>
      _prefs.setBool(AppConstants.keyHideArchive, value);
  bool getHideRecordings() =>
      _prefs.getBool(AppConstants.keyHideRecordings) ?? false;
  Future<void> setHideRecordings(bool value) =>
      _prefs.setBool(AppConstants.keyHideRecordings, value);
  bool getHideCatchupGroup() =>
      _prefs.getBool(AppConstants.keyHideCatchupGroup) ?? false;
  Future<void> setHideCatchupGroup(bool value) =>
      _prefs.setBool(AppConstants.keyHideCatchupGroup, value);
  bool getHideMultiview() =>
      _prefs.getBool(AppConstants.keyHideMultiview) ?? false;
  Future<void> setHideMultiview(bool value) =>
      _prefs.setBool(AppConstants.keyHideMultiview, value);

  /// Settings > General: the "Hold > to resume" reminder pill (Android and
  /// Windows). Off hides only the pill; hold-Right still resumes.
  bool getShowResumePill() =>
      _prefs.getBool(AppConstants.keyShowResumePill) ?? false;
  Future<void> setShowResumePill(bool value) =>
      _prefs.setBool(AppConstants.keyShowResumePill, value);

  /// Hide only the active viewer's Home profiles strip.
  bool getHideProfiles() =>
      _prefs.getBool(_vk(AppConstants.keyHideProfiles)) ?? false;
  Future<void> setHideProfiles(bool value) =>
      _prefs.setBool(_vk(AppConstants.keyHideProfiles), value);

  /// Home page rows for the active viewer (see `HomeRows`).
  List<String>? getHomeRows() =>
      _prefs.getStringList(_vk(AppConstants.keyHomeRows));
  Future<void> setHomeRows(List<String> ids) =>
      _prefs.setStringList(_vk(AppConstants.keyHomeRows), ids);

  /// Sports tab league ids in display order; null = never chosen (the
  /// screen falls back to its own default set).
  List<String>? getSportsLeagues() =>
      _prefs.getStringList(_vk(AppConstants.keySportsLeagues));
  Future<void> setSportsLeagues(List<String> ids) =>
      _prefs.setStringList(_vk(AppConstants.keySportsLeagues), ids);

  /// Leagues the user added from the bank (League manager), in the order
  /// added. Removing one sends it back to the bank.
  List<String> getSportsAddedLeagues() =>
      _prefs.getStringList(_vk(AppConstants.keySportsAddedLeagues)) ?? const [];
  Future<void> setSportsAddedLeagues(List<String> ids) =>
      _prefs.setStringList(_vk(AppConstants.keySportsAddedLeagues), ids);

  /// The favourite league id (null = none). See
  /// [AppConstants.keySportsFavoriteLeague].
  String? getSportsFavoriteLeague() =>
      _prefs.getString(_vk(AppConstants.keySportsFavoriteLeague));
  Future<void> setSportsFavoriteLeague(String? id) => id == null
      ? _prefs.remove(_vk(AppConstants.keySportsFavoriteLeague))
      : _prefs.setString(_vk(AppConstants.keySportsFavoriteLeague), id);

  bool getSportsPreferQuality() =>
      _prefs.getBool(_vk('vesper_sports_prefer_quality')) ?? true;
  Future<void> setSportsPreferQuality(bool value) =>
      _prefs.setBool(_vk('vesper_sports_prefer_quality'), value);

  /// Empty preserves the existing ranking. Per viewer; Backup/Transfer included.
  List<String> getSportsPreferredCountries() =>
      _prefs.getStringList(_vk(AppConstants.keySportsPreferredCountries)) ??
      const [];
  Future<void> setSportsPreferredCountries(List<String> countries) => _prefs
      .setStringList(_vk(AppConstants.keySportsPreferredCountries), countries);
  String? getSportsPreferredPlaylist() =>
      _prefs.getString(_vk(AppConstants.keySportsPreferredPlaylist));
  bool getSportsHideEmptyLeagues() =>
      _prefs.getBool(_vk(AppConstants.keySportsHideEmptyLeagues)) ?? false;
  Future<void> setSportsHideEmptyLeagues(bool value) =>
      _prefs.setBool(_vk(AppConstants.keySportsHideEmptyLeagues), value);

  /// Betting odds on Sports Trak game cards and stats (off by default, per
  /// viewer).
  bool getSportsShowOdds() =>
      _prefs.getBool(_vk(AppConstants.keySportsShowOdds)) ?? false;
  Future<void> setSportsShowOdds(bool value) =>
      _prefs.setBool(_vk(AppConstants.keySportsShowOdds), value);

  /// Play a reminded game on its channel when it starts (per viewer, off).
  bool getSportsAutoPlay() =>
      _prefs.getBool(_vk(AppConstants.keySportsAutoPlay)) ?? false;
  Future<void> setSportsAutoPlay(bool value) =>
      _prefs.setBool(_vk(AppConstants.keySportsAutoPlay), value);
  Future<void> setSportsPreferredPlaylist(String? playlistId) async {
    final key = _vk(AppConstants.keySportsPreferredPlaylist);
    if (playlistId == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, playlistId);
    }
  }

  bool getArchiveAutoLargest() =>
      _prefs.getBool(_vk('vesper_archive_auto_largest')) ?? false;
  Future<void> setArchiveAutoLargest(bool value) =>
      _prefs.setBool(_vk('vesper_archive_auto_largest'), value);

  /// Sports Trak's league rail shows the names (device-only).
  bool getSportsRailExpanded() =>
      _prefs.getBool('vesper_sports_rail_expanded') ?? false;
  Future<void> setSportsRailExpanded(bool value) =>
      _prefs.setBool('vesper_sports_rail_expanded', value);

  bool getSportsHideScores() =>
      _prefs.getBool(_vk(AppConstants.keySportsHideScores)) ?? false;
  bool getSportsMode() =>
      _prefs.getBool(_vk(AppConstants.keySportsMode)) ?? false;
  Future<void> setSportsMode(bool value) =>
      _prefs.setBool(_vk(AppConstants.keySportsMode), value);
  Future<void> setSportsHideScores(bool value) =>
      _prefs.setBool(_vk(AppConstants.keySportsHideScores), value);

  /// Raw JSON of the user's game/team -> channel picks; parsed by
  /// `SportsChannelPicks` (null = none yet).
  String? getSportsChannelPicks() =>
      _prefs.getString(_vk(AppConstants.keySportsChannelPicks));
  Future<void> setSportsChannelPicks(String json) =>
      _prefs.setString(_vk(AppConstants.keySportsChannelPicks), json);

  /// Opt-in, per viewer; never persisted with transient score snapshots.
  bool getGoalsAlert() =>
      _prefs.getBool(_vk(AppConstants.keyGoalsAlert)) ?? false;
  Future<void> setGoalsAlert(bool value) =>
      _prefs.setBool(_vk(AppConstants.keyGoalsAlert), value);

  /// Reminder and goal-alert popups without their fill (outline only).
  bool getTransparentPopups() =>
      _prefs.getBool(AppConstants.keyTransparentPopups) ?? false;
  Future<void> setTransparentPopups(bool value) =>
      _prefs.setBool(AppConstants.keyTransparentPopups, value);

  /// My Teams, in follow order, as `leagueId|teamId`.
  List<String> getSportsFollowedTeams() =>
      _prefs.getStringList(_vk(AppConstants.keySportsFollowedTeams)) ??
      const [];
  Future<void> setSportsFollowedTeams(List<String> teams) =>
      _prefs.setStringList(_vk(AppConstants.keySportsFollowedTeams), teams);

  /// Last Multiview layout: true = 4 screens (2x2), false = 2 stacked.
  bool getMultiviewQuad() =>
      _prefs.getBool(AppConstants.keyMultiviewQuad) ?? false;
  Future<void> setMultiviewQuad(bool value) =>
      _prefs.setBool(AppConstants.keyMultiviewQuad, value);

  /// Multiview's "1 + 3" layout (one big screen, three small); wins over
  /// [getMultiviewQuad] when on.
  bool getMultiviewMain() =>
      _prefs.getBool(AppConstants.keyMultiviewMain) ?? false;
  Future<void> setMultiviewMain(bool value) =>
      _prefs.setBool(AppConstants.keyMultiviewMain, value);

  /// Falls back to the first entry (Minimalist) when unset or when the
  /// stored id doesn't match a known palette — no migration attempted from
  /// the old single-seed-color storage, a fresh sensible default is simpler
  /// than trying to map an arbitrary old color onto the closest palette.
  bool getRefinedFinish() =>
      _prefs.getBool(_vk(AppConstants.keyRefinedFinish)) ?? false;
  Future<void> setRefinedFinish(bool value) =>
      _prefs.setBool(_vk(AppConstants.keyRefinedFinish), value);

  String getPaletteId() =>
      _prefs.getString(_vk(AppConstants.keyPaletteId)) ??
      AppConstants.cyberpunkPalettes.first.id;
  Future<void> setPaletteId(String id) =>
      _prefs.setString(_vk(AppConstants.keyPaletteId), id);

  /// 'auto' or 'tv'. A saved 'phone' (the old phone-only home screen,
  /// removed) reads as 'auto'.
  String getLayoutMode() {
    final mode = _prefs.getString(AppConstants.keyLayoutMode) ??
        AppConstants.defaultLayoutMode;
    return mode == 'phone' ? 'auto' : mode;
  }

  Future<void> setLayoutMode(String mode) =>
      _prefs.setString(AppConstants.keyLayoutMode, mode);

  /// 'auto' or a language code ('en', 'fr', 'es', 'it', 'el'). main.dart reads the key directly before `runApp`
  /// (the splash text is already translated), this only writes it.
  Future<void> setLanguage(String value) =>
      _prefs.setString(AppConstants.keyLanguage, value);

  /// 'live' or 'timeline'.
  String getGuideViewMode() =>
      _prefs.getString(AppConstants.keyGuideViewMode) ??
      AppConstants.defaultGuideViewMode;
  Future<void> setGuideViewMode(String mode) =>
      _prefs.setString(AppConstants.keyGuideViewMode, mode);

  bool getGuideFullVideo() =>
      _prefs.getBool(AppConstants.keyGuideFullVideo) ?? false;
  Future<void> setGuideFullVideo(bool value) =>
      _prefs.setBool(AppConstants.keyGuideFullVideo, value);

  bool getAutoTrailers() =>
      _prefs.getBool(AppConstants.keyAutoTrailers) ?? false;
  Future<void> setAutoTrailers(bool value) =>
      _prefs.setBool(AppConstants.keyAutoTrailers, value);

  bool getGuideExpanded() =>
      _prefs.getBool(AppConstants.keyGuideExpanded) ?? false;
  Future<void> setGuideExpanded(bool value) =>
      _prefs.setBool(AppConstants.keyGuideExpanded, value);
  bool getExpandedBrowse() =>
      _prefs.getBool(AppConstants.keyExpandedBrowse) ?? false;
  Future<void> setExpandedBrowse(bool value) =>
      _prefs.setBool(AppConstants.keyExpandedBrowse, value);
  bool getGuideCompact() =>
      _prefs.getBool(AppConstants.keyGuideCompact) ?? false;
  Future<void> setGuideCompact(bool value) =>
      _prefs.setBool(AppConstants.keyGuideCompact, value);

  // --- Favorites (per viewer, shared across every playlist) -----------------
  // Favorites aren't namespaced by playlist (a favorited channel is just a
  // composite playlistId::rawId already, so there's no collision risk the
  // way group *names* have) but ARE namespaced per viewer — see
  // "Viewer-profile scoping" below.

  Set<String> getFavorites() =>
      (_prefs.getStringList(_vk(AppConstants.keyFavorites)) ?? []).toSet();
  Future<void> setFavorites(Set<String> ids) =>
      _prefs.setStringList(_vk(AppConstants.keyFavorites), ids.toList());

  Set<String> getFavoriteSeries() =>
      (_prefs.getStringList(_vk(AppConstants.keyFavoriteSeries)) ?? []).toSet();
  Future<void> setFavoriteSeries(Set<String> ids) =>
      _prefs.setStringList(_vk(AppConstants.keyFavoriteSeries), ids.toList());

  // --- Hidden / favorited groups (per playlist, per viewer) -----------------
  // Group identity is (playlistId, title), not just title — two different
  // providers can easily have a same-named category. Each playlist gets its
  // own namespaced key rather than one shared Set, so there's no collision;
  // each viewer gets its own copy of that on top, so a restricted viewer's
  // hidden groups are independent of what any other viewer hides.

  Set<String> getHiddenGroups(String playlistId) =>
      (_prefs.getStringList(_vkp(AppConstants.keyHiddenGroups, playlistId)) ??
              [])
          .toSet();
  Future<void> setHiddenGroups(String playlistId, Set<String> groups) =>
      _prefs.setStringList(
          _vkp(AppConstants.keyHiddenGroups, playlistId), groups.toList());

  /// Keyed by `Channel.rawId` (not the composite `id`) — this is already
  /// namespaced per playlist and per viewer via the key suffixes, same as
  /// [getHiddenGroups].
  Set<String> getHiddenChannels(String playlistId) =>
      (_prefs.getStringList(_vkp(AppConstants.keyHiddenChannels, playlistId)) ??
              [])
          .toSet();
  Future<void> setHiddenChannels(String playlistId, Set<String> rawIds) =>
      _prefs.setStringList(
          _vkp(AppConstants.keyHiddenChannels, playlistId), rawIds.toList());

  /// See [AppConstants.keyPlaylistEdits].
  String? getPlaylistEditsJson(String playlistId) =>
      _prefs.getString(_vkp(AppConstants.keyPlaylistEdits, playlistId));
  Future<void> setPlaylistEditsJson(String playlistId, String json) =>
      _prefs.setString(_vkp(AppConstants.keyPlaylistEdits, playlistId), json);

  /// See [AppConstants.keyCopyFallback]. On unless turned off.
  bool getCopyFallback() =>
      _prefs.getBool(AppConstants.keyCopyFallback) ?? true;
  Future<void> setCopyFallback(bool value) =>
      _prefs.setBool(AppConstants.keyCopyFallback, value);

  bool getCrossPlaylistFallback() =>
      _prefs.getBool(AppConstants.keyCrossPlaylistFallback) ?? true;
  Future<void> setCrossPlaylistFallback(bool value) =>
      _prefs.setBool(AppConstants.keyCrossPlaylistFallback, value);

  bool getRecentChannelsGroup() =>
      _prefs.getBool(AppConstants.keyRecentChannelsGroup) ?? false;
  Future<void> setRecentChannelsGroup(bool value) =>
      _prefs.setBool(AppConstants.keyRecentChannelsGroup, value);

  int getLiveBufferMs() => _prefs.getInt(AppConstants.keyLiveBufferMs) ?? 0;
  Future<void> setLiveBufferMs(int ms) =>
      _prefs.setInt(AppConstants.keyLiveBufferMs, ms);

  bool getMergePlaylists() =>
      _prefs.getBool(AppConstants.keyMergePlaylists) ?? false;
  Future<void> setMergePlaylists(bool value) =>
      _prefs.setBool(AppConstants.keyMergePlaylists, value);

  /// Keyed by `Channel.rawId` -> the assigned EPG feed's own channel id —
  /// see [AppConstants.keyEpgIdOverrides]'s doc comment. A malformed/
  /// pre-Map value (there isn't one pre-existing, but a corrupt prefs
  /// entry isn't unheard of elsewhere in this file) reads back as empty
  /// rather than throwing.
  Map<String, String> getEpgIdOverrides(String playlistId) {
    final raw =
        _prefs.getString('${AppConstants.keyEpgIdOverrides}_$playlistId');
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  Future<void> setEpgIdOverrides(
          String playlistId, Map<String, String> overrides) =>
      _prefs.setString('${AppConstants.keyEpgIdOverrides}_$playlistId',
          jsonEncode(overrides));

  /// Keyed by `Channel.rawId` -> the linked channel's own (playlistId,
  /// rawId) — see [AppConstants.keyChannelLinks]'s doc comment. Same
  /// "corrupt/missing reads back empty" tolerance as [getEpgIdOverrides].
  Map<String, ChannelLink> getChannelLinks(String playlistId) {
    final raw = _prefs.getString('${AppConstants.keyChannelLinks}_$playlistId');
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) {
        final m = v as Map<String, dynamic>;
        return MapEntry(k, (
          playlistId: m['playlistId'] as String,
          rawId: m['rawId'] as String
        ));
      });
    } catch (_) {
      return {};
    }
  }

  Future<void> setChannelLinks(
          String playlistId, Map<String, ChannelLink> links) =>
      _prefs.setString(
          '${AppConstants.keyChannelLinks}_$playlistId',
          jsonEncode(links.map((k, v) =>
              MapEntry(k, {'playlistId': v.playlistId, 'rawId': v.rawId}))));

  /// See [AppConstants.keyAutoPairedChannelLinks]'s doc comment.
  Set<String> getAutoPairedChannelLinks(String playlistId) =>
      (_prefs.getStringList(
                  '${AppConstants.keyAutoPairedChannelLinks}_$playlistId') ??
              [])
          .toSet();
  Future<void> setAutoPairedChannelLinks(
          String playlistId, Set<String> rawIds) =>
      _prefs.setStringList(
          '${AppConstants.keyAutoPairedChannelLinks}_$playlistId',
          rawIds.toList());

  /// See [AppConstants.keyAutoPairedEpgOverrides]'s doc comment.
  Set<String> getAutoPairedEpgOverrides(String playlistId) =>
      (_prefs.getStringList(
                  '${AppConstants.keyAutoPairedEpgOverrides}_$playlistId') ??
              [])
          .toSet();
  Future<void> setAutoPairedEpgOverrides(
          String playlistId, Set<String> rawIds) =>
      _prefs.setStringList(
          '${AppConstants.keyAutoPairedEpgOverrides}_$playlistId',
          rawIds.toList());

  Set<String> getFavoritedGroups(String playlistId) => (_prefs.getStringList(
              _vkp(AppConstants.keyFavoritedGroups, playlistId)) ??
          [])
      .toSet();
  Future<void> setFavoritedGroups(String playlistId, Set<String> groups) =>
      _prefs.setStringList(
          _vkp(AppConstants.keyFavoritedGroups, playlistId), groups.toList());

  /// [type] is 'tv'/'vod'/'series' — see [AppConstants.keyGroupOrder].
  /// Empty = provider order (nothing moved yet).
  List<String> getGroupOrder(String playlistId, String type) =>
      _prefs.getStringList(
          _vkp('${AppConstants.keyGroupOrder}_$type', playlistId)) ??
      [];
  Future<void> setGroupOrder(
          String playlistId, String type, List<String> titles) =>
      _prefs.setStringList(
          _vkp('${AppConstants.keyGroupOrder}_$type', playlistId), titles);

  /// See [AppConstants.keyHiddenPlaylistGroups]; [category] is
  /// 'tv'/'vod'/'series'.
  Set<String> getHiddenPlaylistGroups(String category) => (_prefs.getStringList(
              _vk('${AppConstants.keyHiddenPlaylistGroups}_$category')) ??
          const <String>[])
      .toSet();
  Future<void> setHiddenPlaylistGroups(String category, Set<String> ids) =>
      _prefs.setStringList(
          _vk('${AppConstants.keyHiddenPlaylistGroups}_$category'),
          ids.toList());

  /// Group title → ordered live channel rawIds — see
  /// [AppConstants.keyChannelOrder]. Empty = provider order everywhere.
  Map<String, List<String>> getChannelOrder(String playlistId) {
    final raw =
        _prefs.getString(_vkp(AppConstants.keyChannelOrder, playlistId));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in decoded.entries)
          e.key: (e.value as List).map((v) => v as String).toList(),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> setChannelOrder(
          String playlistId, Map<String, List<String>> order) =>
      _prefs.setString(
          _vkp(AppConstants.keyChannelOrder, playlistId), jsonEncode(order));

  /// [AppConstants.keyMyGroups]'s raw JSON (parsed by `UserGroups`).
  String? getMyGroups() => _prefs.getString(_vk(AppConstants.keyMyGroups));

  /// Pending game reminders stay on this device and belong to one viewer.
  String? getGameReminders({String? viewerId}) =>
      _prefs.getString(_vk(AppConstants.keyGameReminders, viewerId: viewerId));
  Future<void> setGameReminders(String json, {String? viewerId}) => _prefs
      .setString(_vk(AppConstants.keyGameReminders, viewerId: viewerId), json);

  /// Programme reminders belong to this viewer and stay on this device.
  String? getProgrammeReminders({String? viewerId}) => _prefs
      .getString(_vk(AppConstants.keyProgrammeReminders, viewerId: viewerId));
  Future<void> setProgrammeReminders(String json, {String? viewerId}) =>
      _prefs.setString(
          _vk(AppConstants.keyProgrammeReminders, viewerId: viewerId), json);

  /// Match score subscriptions belong to this viewer and device, like reminders.
  String? getMatchScoreAlerts({String? viewerId}) => _prefs
      .getString(_vk(AppConstants.keyMatchScoreAlerts, viewerId: viewerId));
  Future<void> setMatchScoreAlerts(String json, {String? viewerId}) =>
      _prefs.setString(
          _vk(AppConstants.keyMatchScoreAlerts, viewerId: viewerId), json);

  /// Leagues whose every goal alerts this viewer (league ids).
  List<String> getLeagueGoalAlerts({String? viewerId}) =>
      _prefs.getStringList(
          _vk(AppConstants.keyLeagueGoalAlerts, viewerId: viewerId)) ??
      const [];
  Future<void> setLeagueGoalAlerts(List<String> ids, {String? viewerId}) =>
      _prefs.setStringList(
          _vk(AppConstants.keyLeagueGoalAlerts, viewerId: viewerId), ids);

  String? getSportsChannelLists({String? viewerId}) => _prefs
      .getString(_vk(AppConstants.keySportsChannelLists, viewerId: viewerId));
  Future<void> setSportsChannelLists(String json, {String? viewerId}) =>
      _prefs.setString(
          _vk(AppConstants.keySportsChannelLists, viewerId: viewerId), json);
  Future<void> setMyGroups(String json) =>
      _prefs.setString(_vk(AppConstants.keyMyGroups), json);

  /// Live Favourites order across playlists (per viewer).
  List<String> getFavoriteLiveOrder() =>
      _prefs.getStringList(_vk(AppConstants.keyFavoriteLiveOrder)) ?? [];
  Future<void> setFavoriteLiveOrder(List<String> ids) async =>
      _prefs.setStringList(_vk(AppConstants.keyFavoriteLiveOrder), ids);

  // --- Search history (per viewer) ------------------------------------------

  static const _maxRecentSearches = 10;

  /// Most-recent-first. Shared across Live TV/Movies/TV Shows scopes rather
  /// than kept separate per scope — simpler, and a remembered search is
  /// useful regardless of which scope tab happens to be selected right now.
  List<String> getRecentSearches() =>
      _prefs.getStringList(_vk(AppConstants.keyRecentSearches)) ?? [];

  Future<void> addRecentSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Future.value();
    final list = getRecentSearches()
        .where((s) => s.toLowerCase() != trimmed.toLowerCase())
        .toList();
    list.insert(0, trimmed);
    if (list.length > _maxRecentSearches)
      list.removeRange(_maxRecentSearches, list.length);
    return _prefs.setStringList(_vk(AppConstants.keyRecentSearches), list);
  }

  Future<void> clearRecentSearches() =>
      _prefs.remove(_vk(AppConstants.keyRecentSearches));

  // --- EPG cache -------------------------------------------------------------
  // The programme data itself lives in `EpgDatabase`. Only the last-updated
  // timestamp stays here.

  DateTime? getEpgLastUpdated() {
    final raw = _prefs.getString(AppConstants.keyEpgLastUpdated);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setEpgLastUpdated(DateTime time) =>
      _prefs.setString(AppConstants.keyEpgLastUpdated, time.toIso8601String());

  // --- Full catalog sync (per playlist) -----------------------------------
  // Sync frequency itself lives directly on PlaylistProfile.syncFrequencyDays
  // now (see StorageService.setPlaylists) — only the "when did it last
  // actually run" timestamp needs its own namespaced key here.

  DateTime? getLastFullSyncAt(String playlistId) {
    final raw =
        _prefs.getString('${AppConstants.keyLastFullSyncAt}_$playlistId');
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setLastFullSyncAt(String playlistId, DateTime time) =>
      _prefs.setString('${AppConstants.keyLastFullSyncAt}_$playlistId',
          time.toIso8601String());

  // --- Resume playback (per viewer) ---------------------------------------

  String? getLastChannelId() =>
      _prefs.getString(_vk(AppConstants.keyLastChannelId));
  Future<void> setLastChannelId(String id) =>
      _prefs.setString(_vk(AppConstants.keyLastChannelId), id);

  /// The viewer suffix goes at the *end*, after [channelId] — not
  /// immediately after the prefix — so every viewer's position/duration key
  /// still starts with [AppConstants.keyLastPositionPrefix]/
  /// [keyLastDurationPrefix] and [clearCache]'s existing `startsWith` sweep
  /// below keeps catching all of them, not just Main's.
  final Map<String, Map<String, String>> _archiveAliases = {};

  /// Bumped whenever an identity alias is added, so callers can cache
  /// mapped identities (Media Hub favourites) until it changes.
  int archiveIdentityRevision = 0;
  Map<String, String> _aliasesFor(String viewer) =>
      _archiveAliases.putIfAbsent(viewer, () {
        try {
          return Map<String, String>.from(jsonDecode(_prefs.getString(
                  _vk('vesper_archive_identities', viewerId: viewer)) ??
              '{}') as Map);
        } catch (_) {
          return <String, String>{};
        }
      });
  String _progressId(String id, {String? viewer}) {
    if (!id.startsWith('archive::')) return id;
    final aliases = _aliasesFor(viewer ?? _activeViewerId);
    final seen = <String>{};
    var current = id;
    while (
        aliases.containsKey(current) && seen.add(current) && seen.length < 8) {
      current = aliases[current]!;
    }
    return current;
  }

  String archiveMappedIdentity(String id) => _progressId(id);

  /// Install the alias synchronously so the next build reads the migrated value.
  /// Existing canonical progress wins; every asynchronous write keeps its viewer.
  Future<void> registerArchiveIdentity(String legacy, String canonical) =>
      registerArchiveIdentities({legacy: canonical});

  Future<void> registerArchiveIdentities(Map<String, String> identities) async {
    final viewer = _activeViewerId;
    final aliases = _aliasesFor(viewer);
    final writes = <Future<bool>>[];
    var changed = false;
    String key(String prefix, String id) => _vk('$prefix$id', viewerId: viewer);
    for (final entry in identities.entries) {
      final legacy = entry.key, canonical = entry.value;
      if (aliases[legacy] == canonical || legacy == canonical) continue;
      final previous = _progressId(legacy, viewer: viewer);
      final position =
          _prefs.getInt(key(AppConstants.keyLastPositionPrefix, previous));
      final duration =
          _prefs.getInt(key(AppConstants.keyLastDurationPrefix, previous));
      final fraction = _prefs
          .getBool(key(AppConstants.keyLastPositionPrefix, 'frac:$previous'));
      aliases[legacy] = canonical;
      archiveIdentityRevision++;
      changed = true;
      if (position != null &&
          !_prefs.containsKey(
              key(AppConstants.keyLastPositionPrefix, canonical))) {
        writes.add(_prefs.setInt(
            key(AppConstants.keyLastPositionPrefix, canonical), position));
        if (duration != null) {
          writes.add(_prefs.setInt(
              key(AppConstants.keyLastDurationPrefix, canonical), duration));
        }
        if (fraction == true) {
          writes.add(_prefs.setBool(
              key(AppConstants.keyLastPositionPrefix, 'frac:$canonical'),
              true));
        }
      }
      final resumeKey =
          _vk('vesper_archive_resume_source_$canonical', viewerId: viewer);
      final choice = _prefs.getString(
          _vk('vesper_archive_resume_source_$previous', viewerId: viewer));
      if (choice != null && !_prefs.containsKey(resumeKey)) {
        writes.add(_prefs.setString(resumeKey, choice));
      }
    }
    if (changed) {
      writes.add(_prefs.setString(
          _vk('vesper_archive_identities', viewerId: viewer),
          jsonEncode(aliases)));
    }
    await Future.wait(writes);
  }

  String _positionKey(String channelId) =>
      _vk('${AppConstants.keyLastPositionPrefix}${_progressId(channelId)}');
  String _durationKey(String channelId) =>
      _vk('${AppConstants.keyLastDurationPrefix}${_progressId(channelId)}');

  /// Fingerprints only: never persist expiring add-on/CDN links here.
  String? getArchiveResumeSource(String channelId, {String? viewerId}) =>
      _prefs.getString(_vk(
          'vesper_archive_resume_source_${_progressId(channelId, viewer: viewerId)}',
          viewerId: viewerId));
  Future<void> setArchiveResumeSource(String channelId, String json,
          {String? viewerId}) =>
      _prefs.setString(
          _vk('vesper_archive_resume_source_${_progressId(channelId, viewer: viewerId)}',
              viewerId: viewerId),
          json);

  int getLastPosition(String channelId) =>
      _prefs.getInt(_positionKey(channelId)) ?? 0;
  Future<void> setLastPosition(String channelId, int milliseconds) =>
      _prefs.setInt(_positionKey(channelId), milliseconds);

  int getLastDuration(String channelId) =>
      _prefs.getInt(_durationKey(channelId)) ?? 0;

  /// A resume point known only as a fraction (Trakt/Simkl paused at 42 %,
  /// the title never played here so its length is unknown): saved as
  /// position/duration on a 1,000,000 scale, so progress bars and "resume"
  /// read it as is, plus a flag so the player converts it to a real time
  /// once the duration is known ([PlaybackService.play]). Its key starts
  /// with the position prefix, so clearing history sweeps it too.
  static const resumeFractionScale = 1000000;
  String _fractionKey(String channelId) => _vk(
      '${AppConstants.keyLastPositionPrefix}frac:${_progressId(channelId)}');

  Future<void> setResumeFraction(String channelId, double fraction) async {
    await _prefs.setBool(_fractionKey(channelId), true);
    await setLastDuration(channelId, resumeFractionScale);
    await setLastPosition(
        channelId, (fraction.clamp(0.0, 1.0) * resumeFractionScale).round());
  }

  bool isResumeFraction(String channelId) =>
      _prefs.getBool(_fractionKey(channelId)) ?? false;

  Future<void> clearResumeFraction(String channelId) =>
      _prefs.remove(_fractionKey(channelId));
  Future<void> setLastDuration(String channelId, int milliseconds) =>
      _prefs.setInt(_durationKey(channelId), milliseconds);

  /// Fraction watched (0.0-1.0), or null when there's nothing to compute
  /// one from — no saved position, or duration was never recorded (e.g.
  /// playback never got far enough to report one).
  double? getWatchedFraction(String channelId) {
    final duration = getLastDuration(channelId);
    final position = getLastPosition(channelId);
    if (duration <= 0 || position <= 0) return null;
    return (position / duration).clamp(0.0, 1.0);
  }

  /// True once far enough into playback to call it done — not exactly 100%,
  /// since end credits/a few trailing seconds are routinely never watched.
  bool isFullyWatched(String channelId) {
    final fraction = getWatchedFraction(channelId);
    return fraction != null && fraction >= 0.95;
  }

  /// The active viewer's saved positions/durations — the movie/episode
  /// progress bars and Continue Watching resume points (Settings > General
  /// "Clear Movies & TV Shows history"). Other viewers' keys are untouched:
  /// Main's are the bare keys (no viewer suffix), everyone else's end with
  /// their own suffix (see [_vk]).
  Future<void> clearPlaybackPositions() async {
    final ownSuffix = '${AppConstants.viewerKeySuffix}$_activeViewerId';
    final isMain = _activeViewerId == AppConstants.mainViewerId;
    final keys = _prefs
        .getKeys()
        .where((k) =>
            (k.startsWith(AppConstants.keyLastPositionPrefix) ||
                k.startsWith(AppConstants.keyLastDurationPrefix)) &&
            (isMain
                ? !k.contains(AppConstants.viewerKeySuffix)
                : k.endsWith(ownSuffix)))
        .toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  /// Clears EPG cache, the entire on-disk playlist/catalog cache (including
  /// the per-category files — there's one per VOD/series category, named
  /// dynamically by category id, so wiping the whole directory is simpler
  /// and more thorough than trying to enumerate them), and saved playback
  /// positions. Playlist/EPG source settings, favorites, and hidden-group
  /// choices are left untouched.
  // --- Device transfer (Settings > Transfer to another device) -----------

  /// The pending internet transfer's raw JSON (`AppConstants.keyCloudTransfer`).
  String? getCloudTransfer() => _prefs.getString(AppConstants.keyCloudTransfer);
  Future<void> setCloudTransfer(String? json) => json == null
      ? _prefs.remove(AppConstants.keyCloudTransfer)
      : _prefs.setString(AppConstants.keyCloudTransfer, json);

  /// Keys that describe *this device* or a cache, never the user's setup:
  /// left out of a transfer and kept as-is on the receiving device.
  static const _transferSkipExact = {
    AppConstants.keyEpgCache,
    AppConstants.keyEpgLastUpdated,
    AppConstants.keyLayoutMode,
    AppConstants.keyWindowsWindowed,
    AppConstants.keyWindowsBounds,
    AppConstants.keyDesktopVolume,
    AppConstants.keyDesktopMuted,
    AppConstants.keyVideoFill,
    AppConstants.keyAutoTrailers,
    AppConstants.keyHideVideoOnSports,
    AppConstants.keyCompatVideo,
    AppConstants.keyDeviceDefaults,
    AppConstants.keyAudioPassthrough,
    AppConstants.keyVideoMediaOverlay,
    AppConstants.keyNativeVideoSurface,
    AppConstants.keyMatchFrameRate,
    AppConstants.keyMatch5060Only,
    AppConstants.keyMatchResolution,
    AppConstants.keySubtitleScale,
    AppConstants.keyLiveGroupSort,
    AppConstants.keyStartSection,
    AppConstants.keyStartSectionPending,
    AppConstants.keyFastStartup,
    AppConstants.keyLaunchWithProfiles,
    AppConstants.keyPlaylistEnabled,
    AppConstants.keyPinFailCount,
    AppConstants.keyPinLockedUntil,
    AppConstants.keyFavoritesDbReconciled,
    AppConstants.keyWhatsNewTmdbLastRefreshed,
    AppConstants.keyWhatsNewVodIds,
    AppConstants.keyWhatsNewSeriesIds,
    AppConstants.keyCloudTransfer,
    AppConstants.keySplashGreeting,
    AppConstants.keySkippedUpdateVersion,
    AppConstants.keyArchiveReadyWatch,
  };

  /// Prefix-matched skips: the per-playlist full-sync timestamps (a copied
  /// one would tell the new, empty device its catalog is fresh), and transient
  /// device-local game reminders (restoring them could replay old alerts).
  static const _transferSkipPrefixes = [
    AppConstants.keyLastFullSyncAt,
    AppConstants.keyGameReminders,
    AppConstants.keyProgrammeReminders,
    AppConstants.keyMatchScoreAlerts,
  ];

  static bool _transferable(String key) =>
      !_transferSkipExact.contains(key) &&
      !_transferSkipPrefixes.any(key.startsWith);

  /// A backup goes back onto the same device, so unlike a transfer it keeps
  /// the device settings (layout, picture fit, enabled playlists, window
  /// size) — only caches and lock/sync state stay out.
  static const _backupSkipExact = {
    AppConstants.keyEpgCache,
    AppConstants.keyEpgLastUpdated,
    AppConstants.keyPinFailCount,
    AppConstants.keyPinLockedUntil,
    AppConstants.keyWhatsNewTmdbLastRefreshed,
    AppConstants.keyWhatsNewVodIds,
    AppConstants.keyWhatsNewSeriesIds,
    AppConstants.keyCloudTransfer,
    AppConstants.keyLastAutoBackup,
  };

  static bool _backupable(String key) =>
      !_backupSkipExact.contains(key) &&
      !_transferSkipPrefixes.any(key.startsWith);

  /// Everything [_backupable] in the same type-tagged form as
  /// [exportForTransfer] — see `BackupService`.
  Map<String, Object> exportForBackup() => _exportWhere(_backupable);

  /// Replaces the setup with a backup from [exportForBackup] (or an older
  /// one); the app must restart afterwards, as after a transfer.
  Future<void> importForBackup(Map<String, Object?> values) =>
      _importWhere(values, _backupable);

  Map<String, Object> _exportWhere(bool Function(String key) include,
      {bool Function(String key)? skip}) {
    final out = <String, Object>{};
    for (final key in _prefs.getKeys()) {
      if (!include(key) || (skip?.call(key) ?? false)) continue;
      final v = _prefs.get(key);
      final tagged = switch (v) {
        String s => {'t': 's', 'v': s},
        bool b => {'t': 'b', 'v': b},
        int i => {'t': 'i', 'v': i},
        double x => {'t': 'd', 'v': x},
        List<String> l => {'t': 'l', 'v': l},
        _ => null,
      };
      if (tagged != null) out[key] = tagged;
    }
    return out;
  }

  /// Removes every [include] key not [keep]-protected, then writes
  /// [values]' [include] keys back with their tagged types.
  Future<void> _importWhere(
      Map<String, Object?> values, bool Function(String key) include,
      {bool Function(String key)? keep}) async {
    final previous = getViewerProfiles();
    for (final key in _prefs.getKeys().toList()) {
      if (keep?.call(key) ?? false) continue;
      if (include(key)) await _prefs.remove(key);
    }
    for (final entry in values.entries) {
      if (entry.key == 'vesper_profile_photos' ||
          entry.key == 'vesper_imported_playlists') {
        continue;
      }
      if (!include(entry.key)) continue;
      if (entry.key == _transferArchiveExcluded) continue;
      if (keep?.call(entry.key) ?? false) continue;
      final tagged = entry.value;
      if (tagged is! Map) continue;
      final v = tagged['v'];
      switch (tagged['t']) {
        case 's' when v is String:
          await _prefs.setString(entry.key, v);
        case 'b' when v is bool:
          await _prefs.setBool(entry.key, v);
        case 'i' when v is int:
          await _prefs.setInt(entry.key, v);
        case 'd' when v is num:
          await _prefs.setDouble(entry.key, v.toDouble());
        case 'l' when v is List:
          await _prefs.setStringList(entry.key, [
            for (final s in v)
              if (s is String) s
          ]);
      }
    }
    final snapshots = values['vesper_imported_playlists'];
    if (snapshots is Map && snapshots.isNotEmpty) {
      await setPlaylists(
          await localPlaylists.restore(getPlaylists(), snapshots));
    }
    final photoIds = {
      ...previous.where((p) => p.photoVersion > 0).map((p) => p.id),
      ...getViewerProfiles().where((p) => p.photoVersion > 0).map((p) => p.id)
    };
    if (photoIds.isNotEmpty) {
      final photos = values['vesper_profile_photos'];
      await profilePhotos.restore(
          photos is Map ? photos : {}, photoIds.where(ProfilePhotos.validId));
    }
  }

  /// Settings > Backup & restore: automatic weekly backup (off by default)
  /// and when the last one ran (device-only, never in a backup).
  bool getAutoBackup() => _prefs.getBool(AppConstants.keyAutoBackup) ?? false;
  Future<void> setAutoBackup(bool value) =>
      _prefs.setBool(AppConstants.keyAutoBackup, value);
  DateTime? getLastAutoBackup() {
    final ms = _prefs.getInt(AppConstants.keyLastAutoBackup);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastAutoBackup(DateTime when) => _prefs.setInt(
      AppConstants.keyLastAutoBackup, when.millisecondsSinceEpoch);

  /// The Archive tab's data: its sources, plus the watch progress of its
  /// titles (position/duration keys of `archive::arc_…` channel ids — see
  /// `ArchiveService.channelId`). Its catalog cache is a separate database
  /// and never transfers.
  static bool _isArchiveKey(String key) =>
      key == AppConstants.keyArchiveCinemetaCatalog ||
      key == AppConstants.keyArchiveSources ||
      key.startsWith('vesper_archive_') ||
      key.startsWith(AppConstants.keyArchiveHistory) ||
      key.startsWith(AppConstants.keyArchiveFavorites) ||
      key.startsWith(AppConstants.keyArchiveRecentSearches) ||
      key.contains('archive::arc_');

  /// Present in a payload sent without the Archive tab's data: the
  /// receiving device then keeps its own instead of losing it.
  static const _transferArchiveExcluded = 'vesper_transfer_archive_excluded';

  /// Everything the user set up — playlists, every viewer's favorites,
  /// hidden groups, progress, history, Sports, settings — as a
  /// type-tagged map (`{"t": "s"|"b"|"i"|"d"|"l", "v": ...}` per key) that
  /// [importForTransfer] restores exactly. Catalog/EPG caches aren't in
  /// here: the receiving device downloads them from the provider.
  ///
  /// [includeArchive] false (Transfer > "Include Archive tab data" off)
  /// leaves out [_isArchiveKey] keys and marks the payload so the receiver
  /// keeps its own Archive data.
  Map<String, Object> exportForTransfer({bool includeArchive = true}) => {
        if (!includeArchive) _transferArchiveExcluded: {'t': 'b', 'v': true},
        ..._exportWhere(_transferable,
            skip: includeArchive ? null : _isArchiveKey),
      };

  /// Replaces this device's setup with [values] from [exportForTransfer].
  /// Device-only keys ([_transferable] = false) are kept; everything else
  /// is removed first so nothing from the old setup lingers. The app must
  /// restart afterwards — services hold the old state in memory.
  Future<void> importForTransfer(Map<String, Object?> values) => _importWhere(
      values, _transferable,
      keep:
          values.containsKey(_transferArchiveExcluded) ? _isArchiveKey : null);

  Future<void> clearCache() async {
    await _prefs.remove(AppConstants.keyEpgCache);
    await _prefs.remove(AppConstants.keyEpgLastUpdated);
    await _prefs.remove(AppConstants.keyLastFullSyncAt);
    final positionKeys = _prefs
        .getKeys()
        .where((k) =>
            k.startsWith(AppConstants.keyLastPositionPrefix) ||
            k.startsWith(AppConstants.keyLastDurationPrefix) ||
            k.startsWith('${AppConstants.keyLastFullSyncAt}_'))
        .toList();
    for (final key in positionKeys) {
      await _prefs.remove(key);
    }

    final dir = await _ensureCacheDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
  }

  // --- Viewer-profile scoping ----------------------------------------------
  // See `AppConstants`' "Viewer profiles" section and `ViewerProfile`'s doc
  // comment for the feature. Every getter/setter above this point that's
  // marked "(per viewer)" below resolves its key through `_vk`/`_vkp`
  // instead of the bare constant — a no-op for `mainViewerId`, so an
  // upgrading install with no other viewer keeps reading/writing exactly
  // the key it always has.

  /// Appends the active viewer's suffix to [base] — a no-op for
  /// [AppConstants.mainViewerId]. Every per-viewer getter/setter is built
  /// from this (or [_vkp] for a key that's also namespaced per playlist).
  String _vk(String base, {String? viewerId}) {
    final id = viewerId ?? _activeViewerId;
    return id == AppConstants.mainViewerId
        ? base
        : '$base${AppConstants.viewerKeySuffix}$id';
  }

  /// Same as [_vk], for a key namespaced per playlist *and* per viewer —
  /// the playlist suffix always comes first, viewer suffix last, so
  /// `deleteViewerData`'s single "ends with the viewer suffix" sweep still
  /// finds it regardless of which playlist it belongs to.
  String _vkp(String base, String playlistId) => _vk('${base}_$playlistId');

  String getActiveViewerId() => _activeViewerId;

  Future<void> setActiveViewerId(String id) async {
    viewerGeneration++;
    _activeViewerId = id;
    await _prefs.setString(AppConstants.keyActiveViewerId, id);
  }

  /// Always at least one entry (Main) — an install that's never configured
  /// any other viewer simply hasn't written this key yet.
  List<ViewerProfile> getViewerProfiles() {
    final raw = _prefs.getString(AppConstants.keyViewerProfiles);
    if (raw == null || raw.isEmpty) return [ViewerProfile.main()];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final profiles = decoded
          .map((e) => ViewerProfile.fromJson(e as Map<String, dynamic>))
          .toList();
      return profiles.isEmpty ? [ViewerProfile.main()] : profiles;
    } catch (_) {
      return [ViewerProfile.main()];
    }
  }

  Future<void> setViewerProfiles(List<ViewerProfile> profiles) =>
      _prefs.setString(AppConstants.keyViewerProfiles,
          jsonEncode(profiles.map((p) => p.toJson()).toList()));

  /// `{v, salt, hash}` — see `ParentalPin` for how this is produced/checked.
  /// Null means no PIN has ever been set (no restricted profile exists yet).
  Map<String, dynamic>? getParentalPin() {
    final raw = _prefs.getString(AppConstants.keyParentalPin);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> setParentalPin(Map<String, dynamic> record) =>
      _prefs.setString(AppConstants.keyParentalPin, jsonEncode(record));

  Future<void> clearParentalPin() => _prefs.remove(AppConstants.keyParentalPin);

  /// Consecutive wrong-PIN attempts — persisted (not just in memory) so
  /// restarting the app doesn't reset a lockout a kid could otherwise use
  /// to get unlimited guesses.
  int getPinFailCount() => _prefs.getInt(AppConstants.keyPinFailCount) ?? 0;
  Future<void> setPinFailCount(int count) =>
      _prefs.setInt(AppConstants.keyPinFailCount, count);

  DateTime? getPinLockedUntil() {
    final raw = _prefs.getString(AppConstants.keyPinLockedUntil);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setPinLockedUntil(DateTime? time) => time == null
      ? _prefs.remove(AppConstants.keyPinLockedUntil)
      : _prefs.setString(
          AppConstants.keyPinLockedUntil, time.toIso8601String());

  bool getFavoritesDbReconciled() =>
      _prefs.getBool(AppConstants.keyFavoritesDbReconciled) ?? false;
  Future<void> setFavoritesDbReconciled(bool value) =>
      _prefs.setBool(AppConstants.keyFavoritesDbReconciled, value);

  /// A restricted viewer's shown-groups allowlist — see
  /// [AppConstants.keyShownGroups]'s doc comment. (Per playlist, per viewer.)
  Set<String> getShownGroups(String playlistId) =>
      (_prefs.getStringList(_vkp(AppConstants.keyShownGroups, playlistId)) ??
              [])
          .toSet();
  Future<void> setShownGroups(String playlistId, Set<String> groups) =>
      _prefs.setStringList(
          _vkp(AppConstants.keyShownGroups, playlistId), groups.toList());

  /// Removes every one of [viewerId]'s own keys — favorites, hidden/shown/
  /// favorited groups and hidden channels for every playlist, positions/
  /// durations, recent searches, and its last-channel id — in one sweep,
  /// since every per-viewer key (see [_vk]/[_vkp]) ends with the same
  /// `__vp_<id>` suffix regardless of which feature or playlist it belongs
  /// to. Refuses [AppConstants.mainViewerId] outright: that id's data lives
  /// under the bare, unsuffixed keys every pre-profiles install already
  /// depends on, which this must never touch. The per-viewer
  /// recently-played cache *file* is a separate concern, deleted by
  /// whoever owns that file (`PlaybackService`), not here.
  Future<void> deleteViewerData(String viewerId) async {
    if (viewerId == AppConstants.mainViewerId) return;
    final suffix = '${AppConstants.viewerKeySuffix}$viewerId';
    final keys = _prefs.getKeys().where((k) => k.endsWith(suffix)).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
