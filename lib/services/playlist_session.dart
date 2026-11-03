import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' show ClientException;

import '../models/channel.dart';
import '../models/m3u_group.dart';
import '../models/playlist_profile.dart';
import '../models/series_details.dart';
import '../models/vod_details.dart';
import '../models/xtream_category.dart';
import '../models/xtream_series.dart';
import '../utils/catalog_sort.dart';
import '../utils/constants.dart';
import 'catalog_database.dart';
import 'm3u_parser.dart';
import 'storage_service.dart';
import 'xtream_api_service.dart';
import '../l10n/l10n.dart';
import 'perf_diagnostics.dart';
import 'playlist_edits.dart';

/// One playlist's own load/cache state — extracted from what used to be
/// `PlaylistManager`'s entire body, back when only one playlist could
/// exist. `PlaylistManager` now holds a `List<PlaylistSession>` (one per
/// `PlaylistProfile`) and is a thin merge/dispatch layer over these; every
/// doc comment on the methods below explaining a hard-won real-hardware
/// bug fix (worker-pool starvation, failure backoff, throttled warm-up
/// notifications, the debug-mode-assertion-caught notifyListeners-during-
/// build bug, ...) is unchanged from the original single-playlist code —
/// none of that logic changed, it just now runs once per playlist instead
/// of once globally.
class PlaylistSession {
  PlaylistSession({
    required this.profile,
    required this.storage,
    required this.catalogDb,
    required this.favoriteIds,
    required this.favoriteSeriesIds,
    required this.isRestrictedViewer,
    required this.onNotify,
    this.myGroupOf,
  });

  /// The viewer's own group a live channel was moved into (see
  /// `UserGroups`, owned by `PlaylistManager`), or null.
  final String? Function(Channel)? myGroupOf;

  PlaylistProfile profile;
  final StorageService storage;
  final CatalogDatabase catalogDb;

  /// Read-only access to `PlaylistManager`'s global favorite id sets —
  /// favorites stay shared across every playlist (unlike hidden/favorited
  /// *groups*, which are per-playlist), so this session only ever reads
  /// them (to stamp `isFavorite` while loading), never owns or writes them.
  final Set<String> Function() favoriteIds;
  final Set<String> Function() favoriteSeriesIds;

  /// Whether the *currently active* viewer is restricted — read live
  /// (called, never cached) the same way [favoriteIds]/[favoriteSeriesIds]
  /// are, so it always reflects whichever viewer is active right now
  /// without this session needing to be told explicitly every time a
  /// switch happens. See [_loadViewerScopedState]'s doc comment for what
  /// this actually changes.
  final bool Function() isRestrictedViewer;

  /// Forwards to the owning `PlaylistManager`'s own `notifyListeners()` —
  /// screens listen to that single `ChangeNotifier`, not to this session
  /// directly.
  final VoidCallback onNotify;

  bool isLoading = false;
  String? error;
  DateTime? lastLoaded;
  String? loadingPhase;
  Map<String, int>? lastLoadSummary;

  /// Background catalog warm-up progress (Xtream mode only) — walks every
  /// VOD/series category that hasn't been loaded yet so nothing requires
  /// manually opening every category to populate it. Tracked per content
  /// type (not just combined) so the UI can show "Movies: 45/159" and
  /// "TV Shows: 22/80" separately, matching how the user actually thinks
  /// about the three content types.
  bool isWarmingCatalog = false;
  int warmCatalogDone = 0;
  int warmCatalogTotal = 0;
  int vodCatalogDone = 0;
  int vodCatalogTotal = 0;
  int seriesCatalogDone = 0;
  int seriesCatalogTotal = 0;

  Set<String> hiddenGroups = {};
  Set<String> favoritedGroups = {};

  /// User-chosen group order per content type ('tv'/'vod'/'series') — see
  /// [moveGroup]. Missing/empty = provider order.
  Map<String, List<String>> groupOrder = {};

  /// User-chosen live channel order per group title (ordered rawIds) — see
  /// [moveChannel]. Missing = provider order.
  Map<String, List<String>> channelOrder = {};

  /// Live TV only — see [AppConstants.keyHiddenChannels]'s doc comment
  /// for why this exists alongside whole-group hiding. Keyed by
  /// [Channel.rawId].
  Set<String> hiddenChannels = {};

  /// Playlist editor layer (renames, logos, rules, Collapse copies), see
  /// [PlaylistEdits]. Per viewer, reloaded with [hiddenChannels].
  PlaylistEdits edits = PlaylistEdits();

  /// Live rawIds the editor hides, recomputed by [applyEdits] on every
  /// load. Kept apart from [hiddenChannels] (the TV's own Hide channel).
  Set<String> editHidden = {};

  /// Hidden by "Combine playlists" (a higher playlist shows the same
  /// channel), set by `PlaylistManager.recomputeMerge`.
  Set<String> mergeHidden = {};

  /// Groups left with nothing to show after [mergeHidden].
  Set<String> mergeHiddenGroups = {};

  /// After every [applyEdits]: lets the manager redo "Combine playlists".
  void Function()? onEditsApplied;

  /// Hidden by the TV's Hide channel or by the editor (not by merging).
  bool isOwnHidden(String rawId) =>
      hiddenChannels.contains(rawId) || editHidden.contains(rawId);

  /// Hidden by the TV's Hide channel, the editor or Combine playlists.
  bool isLiveHidden(String rawId) =>
      isOwnHidden(rawId) || mergeHidden.contains(rawId);

  /// Every live channel of this playlist, hidden ones included.
  Iterable<Channel> get allLiveChannels => isXtream
      ? liveChannels
      : channels.where((c) => _classifyGroup(c.group) == 'tv');

  /// Live rawId -> first time this device saw it (ms); 0 = it was already
  /// there when tracking started. See [AppConstants.cacheFileLiveFirstSeen].
  Map<String, int> _firstSeen = {};
  bool _firstSeenLoaded = false;

  /// When [c] was added: the provider's date, else the first time this
  /// device saw it; null when unknown (it was there from the start).
  DateTime? addedAtOf(Channel c) {
    if (c.addedAt != null) return c.addedAt;
    final ms = _firstSeen[c.rawId];
    return ms == null || ms == 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// After a live list load: remembers channels without a provider date
  /// the first time they show up. The very first run only takes a
  /// baseline (nothing counts as new).
  Future<void> _trackFirstSeen() async {
    final live = allLiveChannels.where((c) => c.addedAt == null).toList();
    if (live.isEmpty) return;
    final name = _cacheName(AppConstants.cacheFileLiveFirstSeen);
    if (!_firstSeenLoaded) {
      _firstSeenLoaded = true;
      try {
        final raw = await storage.readCacheFile(name);
        if (raw != null) {
          _firstSeen = {
            for (final e in (jsonDecode(raw) as Map).entries)
              if (e.value is int) e.key as String: e.value as int
          };
        }
      } catch (_) {
        _firstSeen = {};
      }
    }
    final baseline = _firstSeen.isEmpty;
    final now = DateTime.now().millisecondsSinceEpoch;
    var changed = false;
    for (final c in live) {
      if (_firstSeen.containsKey(c.rawId)) continue;
      _firstSeen[c.rawId] = baseline ? 0 : now;
      changed = true;
    }
    if (changed) {
      try {
        await storage.writeCacheFile(name, jsonEncode(_firstSeen));
      } catch (_) {}
    }
  }

  /// Re-stamps editor names/logos and recomputes [editHidden].
  /// Never lets a bad saved layer stop the playlist from loading (it runs
  /// inside every load path): on any error the channels show unedited.
  void applyEdits() {
    try {
      editHidden = edits.apply(allLiveChannels);
    } catch (e) {
      debugPrint('PlaylistSession[${profile.id}]: editor layer skipped: $e');
      editHidden = {};
    }
    onEditsApplied?.call();
    unawaited(_trackFirstSeen());
  }

  /// Playlist editor: the TV groups' order (shown titles) and which are
  /// hidden. Movies / TV Shows groups in the same hidden set are kept.
  Future<void> setTvGroupLayout(
      {List<String>? order, Set<String>? hidden}) async {
    if (order != null) {
      groupOrder['tv'] = order;
      await storage.setGroupOrder(profile.id, 'tv', order);
    }
    if (hidden != null && !isRestrictedViewer()) {
      final tvTitles = {for (final g in _providerTvGroups) g.title};
      hiddenGroups = {
        ...hiddenGroups.where((t) => !tvTitles.contains(t)),
        ...hidden.where(tvTitles.contains),
      };
      await storage.setHiddenGroups(profile.id, hiddenGroups);
    }
    onNotify();
  }

  Future<void> saveEdits(PlaylistEdits next) async {
    edits = next;
    applyEdits();
    await storage.setPlaylistEditsJson(profile.id, next.encode());
    onNotify();
  }

  /// See [AppConstants.keyEpgIdOverrides]'s doc comment. Keyed by
  /// [Channel.rawId] -> the assigned EPG id; stamped onto each matching
  /// `Channel.epgIdOverride` wherever this session (re)builds its channel
  /// lists (the same loops that stamp `isFavorite`).
  Map<String, String> epgIdOverrides = {};

  /// See [AppConstants.keyChannelLinks]'s doc comment. Keyed by
  /// [Channel.rawId] -> the linked channel elsewhere. Unlike
  /// [epgIdOverrides]/[hiddenChannels], not stamped onto the `Channel`
  /// objects themselves — nothing reads a link off a `Channel` directly,
  /// every lookup goes through `PlaylistManager.channelLinkFor` instead,
  /// so there's no per-channel field to keep in sync on every rebuild.
  Map<String, ChannelLink> channelLinks = {};

  /// See [AppConstants.keyAutoPairedChannelLinks]/
  /// [AppConstants.keyAutoPairedEpgOverrides]'s doc comment — which
  /// entries in [channelLinks]/[epgIdOverrides] were set by "Auto-Pair
  /// Channels" rather than picked by hand, so "Unpair Channels" knows
  /// exactly what it's allowed to undo.
  Set<String> autoPairedChannelLinks = {};
  Set<String> autoPairedEpgOverrides = {};

  // --- M3U-mode state ---------------------------------------------------
  List<Channel> channels = [];

  // --- Xtream-mode state --------------------------------------------------
  XtreamApiService? xtreamApi;
  List<Channel> liveChannels = [];
  List<XtreamCategory> liveCategories = [];
  List<XtreamCategory> vodCategories = [];
  List<XtreamCategory> seriesCategories = [];
  final Map<String, String> vodCategoryIdByName = {};
  final Map<String, String> seriesCategoryIdByName = {};
  final Map<String, List<Channel>> vodByCategoryName = {};
  final Map<String, List<XtreamSeries>> seriesByCategoryName = {};
  // A category's true item count, independent of _maxItemsPerCategory's
  // display cap — the full set is always fetched from the network and
  // saved to the database (see _persistVodCategory/_persistSeriesCategory)
  // regardless of the cap, but vodByCategoryName/seriesByCategoryName
  // themselves only ever hold up to the cap, so there was previously no
  // way for the UI to show a category's real size. See
  // vodCategoryTotalCount/seriesCategoryTotalCount.
  final Map<String, int> vodCategoryTotalCount = {};
  final Map<String, int> seriesCategoryTotalCount = {};
  final Set<String> loadingCategoryNames = {};
  // Which tab category ('vod'/'series') currently has a self-sustaining
  // ensureCategoriesLoaded worker pool running — see that method's doc
  // comment for the bug this exists to fix (a rebuild-dependent design
  // that could silently stall for minutes once the browse screen simply
  // stopped being rebuilt).
  final Set<String> categoriesLoadingActive = {};

  /// How many times each category (keyed the same way as
  /// [loadingCategoryNames]) has failed to load this session. Confirmed
  /// on real hardware as a genuine, previously-missing safety net: without
  /// this, a category that fails (e.g. HTTP 403 from exceeding the
  /// account's own connection limit — see [_categoryConcurrency]) got
  /// retried again on every single widget rebuild forever, hammering the
  /// server with rejected requests indefinitely for the rest of the
  /// session. [_maxCategoryFailures] failures and it's left alone until
  /// an explicit force refresh (manual "Update Content") clears this.
  final Map<String, int> categoryFailureCounts = {};
  static const int _maxCategoryFailures = 2;

  /// Caps how many items of a single category are held in memory/rendered
  /// at once — even with a real on-disk database, a single oversized
  /// category (some providers bundle thousands of items under one
  /// "24/7"-style category) can still be enough to strain a
  /// memory-constrained device by itself, since the whole category is
  /// still materialized into Dart objects the moment it's opened. This is
  /// a blunt cap (silently truncates), not real pagination (load-more-on-
  /// scroll) — a full pagination UI is a bigger follow-up; this at least
  /// puts a ceiling on the worst case. The *database* still stores the
  /// full category, so raising this cap later doesn't need a re-fetch
  /// from the network.
  static const int _maxItemsPerCategory = 300;

  bool get isXtream => profile.isXtream;

  /// How many categories to fetch concurrently — capped at the account's
  /// own `max_connections` (from [XtreamApiService.authenticate]) when
  /// known, since firing more concurrent requests than an account allows
  /// gets the extras rejected outright rather than queued. Falls back to
  /// 3 (the concurrency level already confirmed safe/fast on accounts
  /// without a tight limit) when the account didn't report one.
  int get _categoryConcurrency {
    final accountLimit = xtreamApi?.maxConnections;
    return accountLimit == null ? 3 : accountLimit.clamp(1, 3);
  }

  /// The in-flight (or completed) [ensureLiveChannelsLoaded] load, shared
  /// across every caller — see that method's doc comment for why this
  /// needs to be a shared Future rather than a plain boolean guard.
  Future<void>? liveChannelsFuture;

  bool isGroupFavorited(String title) => favoritedGroups.contains(title);

  /// Every cache file this playlist owns is namespaced by its profile id
  /// — the whole reason a second playlist's cache can't collide with the
  /// first's (or, on upgrade, why a pre-multi-playlist cache file is never
  /// looked up again under its new suffixed name — see
  /// `Channel.fromJson`'s doc comment).
  String _cacheName(String base) => '${base}_${profile.id}';

  List<Channel> get allCachedVod =>
      vodByCategoryName.values.expand((l) => l).toList();
  List<XtreamSeries> get allCachedSeries =>
      seriesByCategoryName.values.expand((l) => l).toList();

  int? vodCategoryTotalCountFor(String categoryName) =>
      vodCategoryTotalCount[categoryName];
  int? seriesCategoryTotalCountFor(String categoryName) =>
      seriesCategoryTotalCount[categoryName];

  // --- Viewer-scoped state (favorited/hidden groups, hidden channels) ------
  // See `ViewerProfile`'s doc comment for the feature. Everything else in
  // this file (visibleChannels/visibleSeries/_warmCategories/
  // knownChannelIds, etc.) keeps reading the plain [hiddenGroups] field
  // exactly as it always has — only *how that field gets populated* changes
  // here, so none of those call sites needed to change at all.

  /// (Re)loads [favoritedGroups]/[hiddenChannels]/[hiddenGroups] for
  /// whichever viewer is active right now — called from [restoreOrLoad] at
  /// first load, and again from [reloadViewerState] on every viewer switch.
  /// A restricted viewer's effective [hiddenGroups] is computed from the
  /// *opposite* stored set ([StorageService.getShownGroups], an allowlist)
  /// instead of read directly — see [ViewerProfile.isRestricted]'s doc
  /// comment for why a restricted viewer needs "hidden unless explicitly
  /// shown" rather than every other viewer's "shown unless explicitly
  /// hidden" (so a category the provider adds tomorrow, which can't
  /// possibly be in a stored allowlist yet, defaults to hidden for them).
  void _loadViewerScopedState() {
    favoritedGroups = storage.getFavoritedGroups(profile.id);
    groupOrder = {
      for (final type in const ['tv', 'vod', 'series'])
        type: storage.getGroupOrder(profile.id, type),
    };
    channelOrder = storage.getChannelOrder(profile.id);
    hiddenChannels = storage.getHiddenChannels(profile.id);
    edits = PlaylistEdits.decode(storage.getPlaylistEditsJson(profile.id));
    applyEdits();
    if (isRestrictedViewer()) {
      hiddenGroups =
          _allKnownGroupTitles().difference(storage.getShownGroups(profile.id));
    } else {
      hiddenGroups = storage.getHiddenGroups(profile.id);
    }
  }

  /// Every group title this session currently knows about, across whichever
  /// content types it has loaded so far — the universe a restricted
  /// viewer's shown-groups allowlist gets subtracted from in
  /// [_loadViewerScopedState]. Xtream mode's three category lists cover
  /// live/VOD/series; M3U mode has only [channels] to derive group titles
  /// from (no separate category list exists in that mode).
  Set<String> _allKnownGroupTitles() => isXtream
      ? {
          ...liveCategories.map((c) => c.name),
          ...vodCategories.map((c) => c.name),
          ...seriesCategories.map((c) => c.name),
        }
      : channels.map((c) => c.group).toSet();

  /// Called by `PlaylistManager.applyActiveViewer` whenever the active
  /// viewer changes — reloads this playlist's favorited/hidden-groups/
  /// hidden-channels state for whichever viewer is active now, without
  /// touching anything network-related (categories/channels already loaded
  /// stay loaded; only which of them count as hidden changes).
  void reloadViewerState() => _loadViewerScopedState();

  /// Re-stamps every already-loaded [Channel]/[XtreamSeries]' `isFavorite`
  /// flag against [favoriteIds]/[favoriteSeriesIds]' *current* value —
  /// called by `PlaylistManager.applyActiveViewer` right after a viewer
  /// switch, since those two callbacks just started returning the
  /// newly-active viewer's own favorites, but every object already sitting
  /// in memory still carries whichever viewer's favorite state was true
  /// when it was first loaded (or last restamped).
  void restampFavorites() {
    final favs = favoriteIds();
    final seriesFavs = favoriteSeriesIds();
    for (final c in channels) {
      c.isFavorite = favs.contains(c.id);
    }
    for (final c in liveChannels) {
      c.isFavorite = favs.contains(c.id);
    }
    for (final list in vodByCategoryName.values) {
      for (final c in list) {
        c.isFavorite = favs.contains(c.id);
      }
    }
    for (final list in seriesByCategoryName.values) {
      for (final s in list) {
        s.isFavorite = seriesFavs.contains(s.id);
      }
    }
  }

  /// Persists a hide/show change for [titles] to whichever stored set the
  /// active viewer actually uses (the blocklist for a normal viewer, the
  /// allowlist for a restricted one — see [_loadViewerScopedState]'s doc
  /// comment), then recomputes [hiddenGroups] so every caller sees the
  /// effect immediately. Shared by [toggleGroupHidden]/[setGroupHidden]/
  /// [setGroupsHidden] so the restricted-viewer branch only needs writing
  /// once.
  Future<void> _applyGroupHiddenChange(
      Iterable<String> titles, bool hidden) async {
    if (isRestrictedViewer()) {
      final shown = storage.getShownGroups(profile.id);
      for (final title in titles) {
        if (hidden) {
          shown.remove(title);
        } else {
          shown.add(title);
        }
      }
      await storage.setShownGroups(profile.id, shown);
      hiddenGroups = _allKnownGroupTitles().difference(shown);
    } else {
      for (final title in titles) {
        if (hidden) {
          hiddenGroups.add(title);
        } else {
          hiddenGroups.remove(title);
        }
      }
      await storage.setHiddenGroups(profile.id, hiddenGroups);
    }
  }

  // --- Startup: restore from cache, or do a fresh load ---------------------

  /// Restores this playlist from its on-disk cache, or does a fresh
  /// network load if there's no cache yet. Returns once *something* is
  /// showable (cache hit or fresh load finished/failed).
  Future<void> restoreOrLoad() async {
    epgIdOverrides = storage.getEpgIdOverrides(profile.id);
    channelLinks = storage.getChannelLinks(profile.id);
    autoPairedChannelLinks = storage.getAutoPairedChannelLinks(profile.id);
    autoPairedEpgOverrides = storage.getAutoPairedEpgOverrides(profile.id);

    // `_loadViewerScopedState()` runs in `finally`, AFTER whichever branch
    // below actually populates categories/channels — not before, the way
    // this used to unconditionally run first. A restricted viewer's
    // hiddenGroups is computed from `_allKnownGroupTitles()` (see that
    // method's doc comment), which is empty on a brand-new session before
    // anything's loaded; computing it too early was confirmed as a real
    // bug during this feature's own review: `_allKnownGroupTitles()` ==
    // {} makes `{}.difference(shown) == {}`, silently treating every
    // category as visible — for the rest of that session, on every cold
    // start (a routine occurrence on this app's target hardware, per this
    // file's own cold-start/low-memory-kill history), not just a brief
    // window. Running this after the branch below means the real category
    // list is always what a restricted viewer's hiddenGroups gets computed
    // against, cache hit or fresh load either way.
    try {
      if (isXtream) {
        final username = profile.xtreamUsername;
        final password = profile.xtreamPassword;
        // Whatever answered last time, not necessarily the configured
        // primary — a cache hit skips the authenticating connect below
        // entirely, so this is the server every on-demand category fetch
        // for the rest of the session would otherwise be pointed at.
        final server = profile.serverCandidates.firstOrNull;
        if (server == null ||
            server.isEmpty ||
            username == null ||
            password == null) return;
        xtreamApi = XtreamApiService(
            server: server,
            username: username,
            password: password,
            playlistId: profile.id);
        if (await _restoreXtreamCache()) return;
        await loadFromXtream();
        return;
      }

      final url = profile.m3uUrl;
      if (url == null || url.isEmpty) return;
      if (await _restoreM3uCache()) return;
      await loadFromUrl(url);
    } finally {
      _loadViewerScopedState();
    }
  }

  // --- M3U mode -----------------------------------------------------------

  Future<bool> _restoreM3uCache() async {
    // Read, decode and parse all on a background isolate — this used to do
    // the lot on the main thread, for a list that can run to tens of
    // thousands of channels. See StorageService.cacheFilePath.
    final path = await storage
        .cacheFilePath(_cacheName(AppConstants.cacheFileM3uChannels));
    if (path == null) return false;
    try {
      final loaded =
          Channel.withUniqueIds(await compute(_readM3uChannelsFile, path));
      for (final channel in loaded) {
        channel.isFavorite = favoriteIds().contains(channel.id);
        channel.epgIdOverride = epgIdOverrides[channel.rawId];
      }
      channels = loaded;
      applyEdits();
      return true;
    } catch (e) {
      debugPrint(
          'PlaylistSession[${profile.id}]: failed to restore M3U cache: $e');
      return false;
    }
  }

  Future<void> loadFromUrl(String url) async {
    isLoading = true;
    error = null;
    lastLoadSummary = null;
    loadingPhase = tr('Connecting to server...');
    onNotify();

    try {
      final parsed = Channel.withUniqueIds(
          await M3uParser.fetchAndParse(url, playlistId: profile.id));
      for (final channel in parsed) {
        channel.isFavorite = favoriteIds().contains(channel.id);
        channel.epgIdOverride = epgIdOverrides[channel.rawId];
      }

      final counts = <String, int>{'tv': 0, 'vod': 0, 'series': 0};
      for (final channel in parsed) {
        final category = _classifyGroup(channel.group);
        counts[category] = (counts[category] ?? 0) + 1;
      }

      // Brief staged reveal so the counts are readable, rather than flashing
      // by instantly — the parsing above is already done at this point.
      loadingPhase =
          tr('Finding live channels... ({p} found)', {'p': counts['tv']});
      onNotify();
      await Future.delayed(const Duration(milliseconds: 400));

      loadingPhase = tr('Finding movies... ({p} found)', {'p': counts['vod']});
      onNotify();
      await Future.delayed(const Duration(milliseconds: 400));

      loadingPhase =
          tr('Finding TV shows... ({p} found)', {'p': counts['series']});
      onNotify();
      await Future.delayed(const Duration(milliseconds: 400));

      channels = parsed;
      applyEdits();
      lastLoadSummary = counts;
      lastLoaded = DateTime.now();
      profile = profile.copyWith(m3uUrl: url);
      await storage.writeCacheFile(
        _cacheName(AppConstants.cacheFileM3uChannels),
        await compute(_encodeJsonList, parsed.map((c) => c.toJson()).toList()),
      );

      loadingPhase = tr('Playlist added');
      onNotify();
      await Future.delayed(const Duration(milliseconds: 600));
    } catch (e) {
      error = e.toString();
      debugPrint('PlaylistSession[${profile.id}] error: $e');
    } finally {
      isLoading = false;
      loadingPhase = null;
      onNotify();
    }
    // See the matching call/comment at the end of loadFromXtream.
    _loadViewerScopedState();
  }

  /// All groups, in first-seen order, including hidden ones (used by the
  /// Group Management screen). M3U mode only.
  List<M3uGroup> get allGroups {
    final order = <String>[];
    final byTitle = <String, List<Channel>>{};
    for (final channel in channels) {
      byTitle.putIfAbsent(channel.group, () => []).add(channel);
      if (!order.contains(channel.group)) order.add(channel.group);
    }
    return order
        .map((title) => M3uGroup(
              title: title,
              playlistId: profile.id,
              channels: byTitle[title]!,
              isHidden: hiddenGroups.contains(title),
            ))
        .toList();
  }

  /// Classifies an M3U group into one of the three content tabs based on
  /// its `group-title`. Series is checked before VOD/movie so "TV Series"
  /// style group names land in the Series tab rather than Movies. Xtream
  /// mode doesn't need this — it gets live/VOD/series as separate API
  /// categories directly.
  String _classifyGroup(String title) => M3uParser.groupCategory(title);

  // --- Xtream mode ----------------------------------------------------------

  Future<void> _persistVodCategory(String categoryName, List<Channel> items) =>
      catalogDb.upsertVodCategory(profile.id, categoryName, items);

  Future<void> _persistSeriesCategory(
          String categoryName, List<XtreamSeries> items) =>
      catalogDb.upsertSeriesCategory(profile.id, categoryName, items);

  Future<bool> _restoreXtreamCache() async {
    try {
      final liveCatRaw = await storage
          .readCacheFile(_cacheName(AppConstants.cacheFileLiveCategories));
      final vodCatRaw = await storage
          .readCacheFile(_cacheName(AppConstants.cacheFileVodCategories));
      final seriesCatRaw = await storage
          .readCacheFile(_cacheName(AppConstants.cacheFileSeriesCategories));
      if (liveCatRaw == null || vodCatRaw == null || seriesCatRaw == null) {
        return false;
      }

      final decoded = await compute(
        _decodeXtreamCategoriesBatch,
        _XtreamCategoriesRaw(
            liveCatRaw: liveCatRaw,
            vodCatRaw: vodCatRaw,
            seriesCatRaw: seriesCatRaw),
      );
      liveCategories = decoded.liveCategories;
      vodCategories = decoded.vodCategories;
      seriesCategories = decoded.seriesCategories;

      vodCategoryIdByName
        ..clear()
        ..addEntries(vodCategories.map((c) => MapEntry(c.name, c.id)));
      seriesCategoryIdByName
        ..clear()
        ..addEntries(seriesCategories.map((c) => MapEntry(c.name, c.id)));

      // Deliberately NOT restoring every cached category's items into
      // memory here — vodByCategoryName/seriesByCategoryName simply start
      // empty every launch, exactly like a fresh install;
      // ensureCategoryLoaded queries the local catalog database on demand
      // the moment a category is actually opened. See CatalogDatabase's
      // doc comment for the memory-capacity problem this avoids.

      lastLoadSummary = {
        'tv': liveChannels.length,
        'vod': vodCategories.length,
        'series': seriesCategories.length,
      };
      return true;
    } catch (e) {
      debugPrint(
          'PlaylistSession[${profile.id}]: failed to restore Xtream cache: $e');
      return false;
    }
  }

  /// Loads the live channel list on first need instead of eagerly on every
  /// launch. Callers: `TvHomeScreen`/`HomeScreen`'s Live TV and Favorites
  /// views, `SearchScreen`, and `main.dart`'s auto-resume-last-channel
  /// (which awaits this directly, since it needs the list before it can
  /// look anything up). No-ops once loaded — safe to call unconditionally
  /// from any of them on every build.
  ///
  /// Returns the *same in-flight Future* to every caller while a load is
  /// already running, rather than just checking a boolean and returning
  /// immediately — main.dart's auto-resume awaits this specifically to
  /// wait for the list to exist, and if it lost a race to start the load
  /// against one of the fire-and-forget UI callers, a plain "already
  /// requested, return now" guard would let it fall through to searching
  /// a still-empty list instead of actually waiting for that other
  /// caller's load to finish.
  Future<void> ensureLiveChannelsLoaded() {
    if (!isXtream || liveChannels.isNotEmpty) return Future<void>.value();
    // A refused account (401/403/429) is not asked again for a minute:
    // every build retried it, ~100 requests in 40 s (LOG-8VZE3G, Trex
    // outage), which can turn a provider's short block into a long one.
    final wait = _liveRetryAfter;
    if (liveChannelsFuture == null &&
        wait != null &&
        DateTime.now().isBefore(wait)) {
      return Future<void>.value();
    }
    return liveChannelsFuture ??= _loadLiveChannelsOnce();
  }

  DateTime? _liveRetryAfter;

  Future<void> _loadLiveChannelsOnce() async {
    // Deliberately doesn't touch the shared `isLoading` above (used to,
    // see git history — removed for a real, reported bug). This method
    // runs completely independently of `loadFromXtream`/`loadFromUrl` —
    // it's triggered by `ensureLiveChannelsLoaded`'s callers (TvHomeScreen/
    // HomeScreen/SearchScreen), which run on *every* enabled session any
    // time PlaylistManager notifies, not just whichever one is currently
    // the foreground add/edit/sync. Since AddPlaylistScreen is pushed *on
    // top of* TvHomeScreen (which stays mounted underneath, not disposed),
    // adding a playlist made `addPlaylist`'s own notifyListeners() trigger
    // TvHomeScreen's build-time `ensureLiveChannelsLoaded()` call for the
    // brand-new session too — racing this method against the real
    // `loadFromXtream()` on the very same session object. This method's
    // own early-return below (`xtreamApi` isn't set yet this early)
    // finished in milliseconds, and its `finally` stomped the shared
    // `isLoading` back to false while the real connect was still several
    // seconds from done — which is exactly what made the Add Playlist
    // status box "flash once, then show nothing" even though
    // `loadingPhase` (only ever written by the real load) kept updating
    // correctly the whole time underneath it.
    //
    // See TvHomeScreen._buildLiveRegion / PlaylistManager's original
    // single-playlist history: deferring a frame before the first
    // notifyListeners avoids firing one synchronously during a caller's
    // own build.
    await Future<void>.delayed(Duration.zero);
    onNotify();
    try {
      List<Channel> loaded;
      // Path, not contents — see StorageService.cacheFilePath.
      final path = await storage
          .cacheFilePath(_cacheName(AppConstants.cacheFileLiveChannels));
      if (path != null) {
        loaded = await compute(_readChannelsFile, path);
      } else {
        final api = xtreamApi;
        if (api == null) return;
        final categoryNames = {for (final c in liveCategories) c.id: c.name};
        loaded = await api.getLiveStreams(categoryNames: categoryNames);
        _noteFetch(null);
        await storage.writeCacheFile(
          _cacheName(AppConstants.cacheFileLiveChannels),
          await compute(
              _encodeJsonList, loaded.map((c) => c.toJson()).toList()),
        );
      }
      final fromFile = loaded;
      PerfDiagnostics.timedSync('liveLoad n=${fromFile.length}', () {
        final unique = Channel.withUniqueIds(fromFile);
        for (final channel in unique) {
          channel.isFavorite = favoriteIds().contains(channel.id);
          channel.epgIdOverride = epgIdOverrides[channel.rawId];
        }
        liveChannels = unique;
        applyEdits();
      });
      lastLoadSummary = {...?lastLoadSummary, 'tv': liveChannels.length};
    } catch (e) {
      debugPrint(
          'PlaylistSession[${profile.id}]: failed to load live channels: $e');
      liveChannelsFuture = null; // allow a retry on the next access
      if (RegExp(r'HTTP (401|403|429)').hasMatch('$e')) {
        _liveRetryAfter = DateTime.now().add(const Duration(minutes: 1));
      }
    } finally {
      onNotify();
    }
  }

  /// How long to wait before trying the next server in the list. Only
  /// ever waited *between* attempts, never before the first or after the
  /// last — the point is to not machine-gun a provider's whole set of
  /// hostnames in the same instant, not to add latency for its own sake.
  static const _backupServerDelay = Duration(seconds: 3);

  /// Authenticates against [PlaylistProfile.serverCandidates] in order,
  /// returning the first one that answers. With no backups configured
  /// this is exactly the old single-server behaviour, message for
  /// message; the per-attempt reporting only appears once there's
  /// actually more than one server to talk about.
  ///
  /// A server that answers and *rejects* the account (bad credentials,
  /// expired/disabled subscription) stops the walk immediately instead of
  /// cycling through every backup — that server was reachable, so the
  /// problem follows the account to every other hostname too, and
  /// burying "your subscription expired" under a minute of fallback
  /// attempts helps nobody.
  Future<XtreamApiService> _connectWithFallback() async {
    final candidates = profile.serverCandidates;
    final username = profile.xtreamUsername!;
    final password = profile.xtreamPassword!;
    Object? lastError;

    for (var i = 0; i < candidates.length; i++) {
      final server = candidates[i];
      final label = _hostLabel(server);
      if (candidates.length > 1) {
        loadingPhase = tr('Connecting to {label} ({p}/{candidates})...',
            {'label': label, 'p': i + 1, 'candidates': candidates.length});
        onNotify();
      }
      final api = XtreamApiService(
          server: server,
          username: username,
          password: password,
          playlistId: profile.id);
      try {
        await api.authenticate();
        _noteFetch(null);
        if (candidates.length > 1) {
          loadingPhase = tr('Connected to {label}', {'label': label});
          onNotify();
        }
        await _rememberWorkingServer(server);
        return api;
      } catch (e) {
        lastError = e;
        if (_isAccountRejection(e)) rethrow;
        if (candidates.length > 1) {
          loadingPhase = tr(
              'Connecting to {label} ({p}/{candidates})... failed',
              {'label': label, 'p': i + 1, 'candidates': candidates.length});
          onNotify();
        }
        final hasMore = i < candidates.length - 1;
        if (hasMore) await Future<void>.delayed(_backupServerDelay);
      }
    }
    throw lastError ?? Exception('No server configured for this playlist');
  }

  /// Persisted so the next launch starts from whatever actually answered
  /// rather than re-walking a primary that's been down for days. Direct
  /// field assignment for the same reason [PlaylistProfile.expiresAt] uses
  /// one — see that field's doc comment.
  Future<void> _rememberWorkingServer(String server) async {
    if (profile.lastWorkingServer == server) return;
    profile.lastWorkingServer = server;
    final updated = storage
        .getPlaylists()
        .map((p) => p.id == profile.id ? profile : p)
        .toList();
    await storage.setPlaylists(updated);
  }

  Future<void> loadFromXtream() async {
    isLoading = true;
    error = null;
    lastLoadSummary = null;
    loadingPhase = tr('Connecting to server...');
    onNotify();

    try {
      final api = await _connectWithFallback();
      xtreamApi = api;
      // Refreshed on every successful connect, not just once at add time —
      // a provider extending/changing an account's expiry should show
      // the current value on the next connect, not whatever it was when
      // this playlist was first added. See PlaylistProfile.expiresAt's
      // doc comment for why this can legitimately stay null.
      if (api.expiryDate != profile.expiresAt) {
        // Direct field assignment, not copyWith — expiresAt is mutable
        // for exactly this (like enabled/sortOrder elsewhere on this
        // class), and copyWith's `expiresAt ?? this.expiresAt` can't
        // distinguish "not specified" from "a provider stopped
        // reporting one," so it could never actually clear a stale value.
        profile.expiresAt = api.expiryDate;
        final updated = storage
            .getPlaylists()
            .map((p) => p.id == profile.id ? profile : p)
            .toList();
        await storage.setPlaylists(updated);
      }
      // Same reasoning/pattern as expiresAt just above — see
      // PlaylistProfile.maxConnections' own doc comment for why this is
      // worth persisting and surfacing to the user at all.
      if (api.maxConnections != profile.maxConnections) {
        profile.maxConnections = api.maxConnections;
        final updated = storage
            .getPlaylists()
            .map((p) => p.id == profile.id ? profile : p)
            .toList();
        await storage.setPlaylists(updated);
      }
      // Catch-up links are written in the server's clock; kept so they
      // work before the next login. Never cleared by a login that didn't
      // report it.
      final offset = api.serverTimeOffset?.inMinutes;
      if (offset != null && offset != profile.serverTimeOffsetMinutes) {
        profile.serverTimeOffsetMinutes = offset;
        final updated = storage
            .getPlaylists()
            .map((p) => p.id == profile.id ? profile : p)
            .toList();
        await storage.setPlaylists(updated);
      }

      liveCategories = await api.getLiveCategories();
      final liveCategoryNames = {for (final c in liveCategories) c.id: c.name};
      await storage.writeCacheFile(
        _cacheName(AppConstants.cacheFileLiveCategories),
        await compute(
            _encodeJsonList, liveCategories.map((c) => c.toJson()).toList()),
      );

      loadingPhase = tr('Finding live channels...');
      onNotify();
      final loadedLive = Channel.withUniqueIds(
          await api.getLiveStreams(categoryNames: liveCategoryNames));
      for (final channel in loadedLive) {
        channel.isFavorite = favoriteIds().contains(channel.id);
        channel.epgIdOverride = epgIdOverrides[channel.rawId];
      }
      liveChannels = loadedLive;
      applyEdits();
      await storage.writeCacheFile(
        _cacheName(AppConstants.cacheFileLiveChannels),
        await compute(
            _encodeJsonList, loadedLive.map((c) => c.toJson()).toList()),
      );
      loadingPhase = tr('Finding live channels... ({loadedLive} found)',
          {'loadedLive': loadedLive.length});
      onNotify();
      await Future.delayed(const Duration(milliseconds: 400));

      loadingPhase = tr('Finding movie categories...');
      onNotify();
      vodCategories = await api.getVodCategories();
      vodCategoryIdByName
        ..clear()
        ..addEntries(vodCategories.map((c) => MapEntry(c.name, c.id)));
      vodByCategoryName
          .removeWhere((name, _) => !vodCategoryIdByName.containsKey(name));
      await storage.writeCacheFile(
        _cacheName(AppConstants.cacheFileVodCategories),
        await compute(
            _encodeJsonList, vodCategories.map((c) => c.toJson()).toList()),
      );
      loadingPhase = tr('Finding movies... ({vodCategories} categories found)',
          {'vodCategories': vodCategories.length});
      onNotify();
      await Future.delayed(const Duration(milliseconds: 400));

      loadingPhase = tr('Finding TV show categories...');
      onNotify();
      seriesCategories = await api.getSeriesCategories();
      seriesCategoryIdByName
        ..clear()
        ..addEntries(seriesCategories.map((c) => MapEntry(c.name, c.id)));
      seriesByCategoryName
          .removeWhere((name, _) => !seriesCategoryIdByName.containsKey(name));
      await storage.writeCacheFile(
        _cacheName(AppConstants.cacheFileSeriesCategories),
        await compute(
            _encodeJsonList, seriesCategories.map((c) => c.toJson()).toList()),
      );
      loadingPhase = tr(
          'Finding TV shows... ({seriesCategories} categories found)',
          {'seriesCategories': seriesCategories.length});
      onNotify();
      await Future.delayed(const Duration(milliseconds: 400));

      lastLoadSummary = {
        'tv': loadedLive.length,
        'vod': vodCategories.length,
        'series': seriesCategories.length,
      };
      lastLoaded = DateTime.now();

      loadingPhase = tr('Playlist added');
      onNotify();
      await Future.delayed(const Duration(milliseconds: 600));
    } catch (e) {
      error = e.toString();
      debugPrint('PlaylistSession[${profile.id}] error: $e');
    } finally {
      isLoading = false;
      loadingPhase = null;
      onNotify();
    }

    // Re-run after a fresh category fetch, not just once at initial load
    // (restoreOrLoad's own call covers that) — this method also runs
    // again later for "Update Content"/full catalog sync
    // (runFullCatalogSync), which is exactly when a provider-added *new*
    // category would first appear. A restricted viewer's hiddenGroups is
    // computed against `_allKnownGroupTitles()` (see that method's doc
    // comment) — without recomputing here, a category discovered by this
    // call would simply be invisible to that computation (neither hidden
    // nor explicitly shown) and default to *visible*, exactly backwards
    // from the allowlist's whole point.
    _loadViewerScopedState();

    // Deliberately NOT auto-starting the catalog warm-up here — the caller
    // (AddPlaylistScreen) asks the user "download everything, or choose
    // groups first?" and starts it explicitly via [warmAllCategories] once
    // that's settled, so a "choose groups" pick actually takes effect
    // before any fetching begins rather than racing it.
  }

  /// Fetches a VOD or series category's items the first time it's opened,
  /// then caches them (in memory for the rest of the session, and to the
  /// local catalog database). No-ops for live (already loaded whole) and
  /// for categories already cached in memory this session.
  /// The Expand catalog sort saved for [tabCategory] (`vod`/`series`):
  /// the browse rows follow it too (see `CatalogSort`).
  CatalogSort _rowSort(String tabCategory) =>
      catalogSortFrom(storage.getCatalogSort(tabCategory));

  /// Drops [tabCategory]'s loaded rows so the next build reloads them in
  /// the newly saved sort ([PlaylistManager.applyCatalogSort]).
  void dropLoadedCategories(String tabCategory) {
    if (tabCategory == 'vod') vodByCategoryName.clear();
    if (tabCategory == 'series') seriesByCategoryName.clear();
  }

  Future<void> ensureCategoryLoaded(
      String categoryName, String tabCategory) async {
    if (tabCategory == 'tv') return;
    if (tabCategory == 'vod' && vodByCategoryName.containsKey(categoryName))
      return;
    if (tabCategory == 'series' &&
        seriesByCategoryName.containsKey(categoryName)) return;
    final key = _loadKey(tabCategory, categoryName);
    if (loadingCategoryNames.contains(key)) return;
    if ((categoryFailureCounts[key] ?? 0) >= _maxCategoryFailures) return;

    // Only the first load in flight changes what's on screen (the
    // spinner); each extra notify rebuilt the whole TV home, and a big
    // playlist opens hundreds of rows (300k-channel user, 2026-11-03).
    final first = loadingCategoryNames.isEmpty;
    loadingCategoryNames.add(key);
    isLoading = true;
    if (first) onNotify();

    try {
      if (tabCategory == 'vod') {
        final cached = await catalogDb.getVodCategory(profile.id, categoryName,
            limit: _maxItemsPerCategory, orderBy: _rowSort('vod').orderBy);
        if (cached.isNotEmpty) {
          vodByCategoryName[categoryName] = cached;
          vodCategoryTotalCount[categoryName] =
              await catalogDb.getVodCategoryCount(profile.id, categoryName);
          return;
        }
        final api = xtreamApi;
        final categoryId = vodCategoryIdByName[categoryName];
        if (!isXtream || api == null || categoryId == null || serverDown) {
          return;
        }
        final items = await api.getVodStreams(categoryId, categoryName);
        _noteFetch(null);
        for (final channel in items) {
          channel.isFavorite = favoriteIds().contains(channel.id);
          channel.epgIdOverride = epgIdOverrides[channel.rawId];
        }
        await _persistVodCategory(categoryName, items);
        vodByCategoryName[categoryName] =
            sortCatalogChannels(items, _rowSort('vod'))
                .take(_maxItemsPerCategory)
                .toList();
        vodCategoryTotalCount[categoryName] = items.length;
      } else {
        final cached = await catalogDb.getSeriesCategory(
            profile.id, categoryName,
            limit: _maxItemsPerCategory, orderBy: _rowSort('series').orderBy);
        if (cached.isNotEmpty) {
          seriesByCategoryName[categoryName] = cached;
          seriesCategoryTotalCount[categoryName] =
              await catalogDb.getSeriesCategoryCount(profile.id, categoryName);
          return;
        }
        final api = xtreamApi;
        final categoryId = seriesCategoryIdByName[categoryName];
        if (!isXtream || api == null || categoryId == null || serverDown) {
          return;
        }
        final items = await api.getSeriesForCategory(categoryId);
        _noteFetch(null);
        for (final series in items) {
          series.isFavorite = favoriteSeriesIds().contains(series.id);
        }
        await _persistSeriesCategory(categoryName, items);
        seriesByCategoryName[categoryName] =
            sortCatalogSeries(items, _rowSort('series'))
                .take(_maxItemsPerCategory)
                .toList();
        seriesCategoryTotalCount[categoryName] = items.length;
      }
    } catch (e) {
      error = e.toString();
      debugPrint(
          'PlaylistSession[${profile.id}] CatLoad[$tabCategory] "$categoryName" FAILED: $e');
      categoryFailureCounts[key] = (categoryFailureCounts[key] ?? 0) + 1;
      _noteFetch(e);
    } finally {
      loadingCategoryNames.remove(key);
      isLoading = loadingCategoryNames.isNotEmpty;
      _notifyCategoryLoaded();
    }
  }

  DateTime? _lastCategoryNotify;
  Timer? _categoryNotifyTimer;

  /// A loaded row at most every 400 ms; the last one always arrives (a
  /// trailing notify), so no row is left unshown.
  void _notifyCategoryLoaded() {
    if (_categoryNotifyTimer != null) return;
    final now = DateTime.now();
    final since = _lastCategoryNotify == null
        ? null
        : now.difference(_lastCategoryNotify!);
    const window = Duration(milliseconds: 400);
    if (since == null || since >= window) {
      _lastCategoryNotify = now;
      onNotify();
      return;
    }
    _categoryNotifyTimer = Timer(window - since, () {
      _categoryNotifyTimer = null;
      _lastCategoryNotify = DateTime.now();
      onNotify();
    });
  }

  String _loadKey(String tabCategory, String categoryName) =>
      '$tabCategory:$categoryName';

  /// Same first-load-on-demand behavior as [ensureCategoryLoaded], but for
  /// a whole browse screen's worth of categories at once, with a hard cap
  /// on how many load concurrently. A genuine self-sustaining worker pool
  /// ([categoriesLoadingActive] guards against starting a second one per
  /// tab while one's already running) — see the original single-playlist
  /// `PlaylistManager`'s history for why a rebuild-dependent "top up on
  /// each build" design isn't safe here (confirmed on real hardware: it
  /// could silently stall for 10+ seconds once nothing else happened to
  /// rebuild the screen).
  Future<void> ensureCategoriesLoaded(
      Iterable<String> categoryNames, String tabCategory) async {
    if (categoriesLoadingActive.contains(tabCategory)) return;
    final namesList = categoryNames.toList();
    if (namesList.isEmpty) return;

    categoriesLoadingActive.add(tabCategory);
    final maxConcurrent = _categoryConcurrency;
    try {
      final loadedMap =
          tabCategory == 'vod' ? vodByCategoryName : seriesByCategoryName;
      var index = 0;
      Future<void> worker() async {
        while (index < namesList.length) {
          final name = namesList[index++];
          final key = _loadKey(tabCategory, name);
          if (loadedMap.containsKey(name) ||
              (categoryFailureCounts[key] ?? 0) >= _maxCategoryFailures) {
            continue;
          }
          await ensureCategoryLoaded(name, tabCategory);
        }
      }

      await Future.wait(List.generate(
          maxConcurrent.clamp(1, namesList.length), (_) => worker()));
    } finally {
      categoriesLoadingActive.remove(tabCategory);
    }
  }

  Future<void> _loadOneVodCategory(XtreamApiService api, XtreamCategory cat,
      {bool force = false}) async {
    final key = _loadKey('vod', cat.name);
    if ((!force && vodByCategoryName.containsKey(cat.name)) ||
        loadingCategoryNames.contains(key) ||
        (categoryFailureCounts[key] ?? 0) >= _maxCategoryFailures ||
        serverDown) {
      return;
    }
    loadingCategoryNames.add(key);
    try {
      final items = await api.getVodStreams(cat.id, cat.name);
      _noteFetch(null);
      for (final channel in items) {
        channel.isFavorite = favoriteIds().contains(channel.id);
        channel.epgIdOverride = epgIdOverrides[channel.rawId];
      }
      await _persistVodCategory(cat.name, items);
      vodByCategoryName[cat.name] = sortCatalogChannels(items, _rowSort('vod'))
          .take(_maxItemsPerCategory)
          .toList();
      vodCategoryTotalCount[cat.name] = items.length;
    } catch (e) {
      debugPrint(
          'PlaylistSession[${profile.id}]: background load failed for movies "${cat.name}": $e');
      categoryFailureCounts[key] = (categoryFailureCounts[key] ?? 0) + 1;
      _noteFetch(e);
    } finally {
      loadingCategoryNames.remove(key);
    }
  }

  Future<void> _loadOneSeriesCategory(XtreamApiService api, XtreamCategory cat,
      {bool force = false}) async {
    final key = _loadKey('series', cat.name);
    if ((!force && seriesByCategoryName.containsKey(cat.name)) ||
        loadingCategoryNames.contains(key) ||
        (categoryFailureCounts[key] ?? 0) >= _maxCategoryFailures ||
        serverDown) {
      return;
    }
    loadingCategoryNames.add(key);
    try {
      final items = await api.getSeriesForCategory(cat.id);
      _noteFetch(null);
      for (final series in items) {
        series.isFavorite = favoriteSeriesIds().contains(series.id);
      }
      await _persistSeriesCategory(cat.name, items);
      seriesByCategoryName[cat.name] =
          sortCatalogSeries(items, _rowSort('series'))
              .take(_maxItemsPerCategory)
              .toList();
      seriesCategoryTotalCount[cat.name] = items.length;
    } catch (e) {
      debugPrint(
          'PlaylistSession[${profile.id}]: background load failed for TV shows "${cat.name}": $e');
      categoryFailureCounts[key] = (categoryFailureCounts[key] ?? 0) + 1;
      _noteFetch(e);
    } finally {
      loadingCategoryNames.remove(key);
    }
  }

  DateTime? _lastWarmupNotify;

  /// Notifying on every single category (up to 200+ times in a row) forces
  /// a full rebuild of whatever's on screen that many times in rapid
  /// succession — on weaker TV-box hardware that's enough rebuild pressure
  /// to make the UI thread choke badly enough to get killed. Progress at
  /// a few updates per second is visually indistinguishable from every
  /// single one, so throttle it; [force] still always notifies.
  void _notifyWarmupProgress({bool force = false}) {
    final now = DateTime.now();
    if (!force &&
        _lastWarmupNotify != null &&
        now.difference(_lastWarmupNotify!) <
            const Duration(milliseconds: 400)) {
      return;
    }
    _lastWarmupNotify = now;
    onNotify();
  }

  /// No answer from the server at all (DNS, refused, reset, TLS, timeout),
  /// as opposed to an HTTP error or a bad reply for one category.
  static bool _isHostUnreachable(Object e) =>
      e is SocketException ||
      e is ClientException ||
      e is TimeoutException ||
      e is HandshakeException;

  /// Retry once, then leave a server that doesn't answer alone for a while:
  /// a 13-playlist user whose provider domains didn't resolve made 2,471
  /// failed row requests in 2 minutes, each one also queueing on the
  /// catalog database (LOG-6LYY3R, 2026-11-03); another playlist answered
  /// 607 requests in 17 s with HTTP 429 (LOG-MP44ZB). Kept short and lifted
  /// as soon as the server answers anything else (sign-in, live list,
  /// episodes): a box that starts the app before its Wi-Fi is up must not
  /// lose its movie rows for long. Cached rows still show; "Update
  /// content" also lifts it.
  static const _pauseFor = Duration(minutes: 2);
  DateTime? _serverDownUntil;
  int _failedInARow = 0;

  bool get serverDown =>
      _serverDownUntil != null && DateTime.now().isBefore(_serverDownUntil!);

  static bool _isRefused(Object e) =>
      RegExp(r'HTTP (401|403|429)').hasMatch('$e');

  /// [error] null = the server answered (lifts a pause).
  void _noteFetch(Object? error) {
    if (error == null) {
      _failedInARow = 0;
      _serverDownUntil = null;
      return;
    }
    final unreachable = _isHostUnreachable(error);
    if (!unreachable && !_isRefused(error)) {
      _failedInARow = 0;
      return;
    }
    if (++_failedInARow < 2) return;
    _failedInARow = 0;
    _serverDownUntil = DateTime.now().add(_pauseFor);
    debugPrint('PlaylistSession[${profile.id}]: server '
        '${unreachable ? 'unreachable' : 'refused'}, '
        'catalog requests paused for ${_pauseFor.inMinutes} min');
  }

  /// Walks every VOD/series category that isn't cached yet and isn't
  /// hidden, one at a time, fetching its items in the background.
  Future<void> warmAllCategories() => _warmCategories(force: false);

  /// Re-fetches every non-hidden VOD/series category's items, including
  /// ones already cached — the "Update content" action.
  Future<void> refreshAllCategories() => _warmCategories(force: true);

  /// True when this playlist hasn't had a *full* sync (every non-hidden
  /// category's items, not just category names/live channels) recently
  /// enough.
  bool needsFullSync() {
    if (!isXtream) return false;
    final last = storage.getLastFullSyncAt(profile.id);
    if (last == null) return true;
    return DateTime.now().difference(last) >= profile.syncInterval;
  }

  /// The blocking "Updating..." pass established players like TiviMate and
  /// MyTVOnline3 do a few times a week rather than on every launch.
  Future<void> runFullCatalogSync() async {
    if (!isXtream) return;
    await loadFromXtream();
    await refreshAllCategories();
  }

  Future<void> _warmCategories({required bool force}) async {
    if (isWarmingCatalog) return;

    final api = xtreamApi;
    if (api == null) return;

    if (force) {
      categoryFailureCounts.clear();
      _serverDownUntil = null;
    }

    try {
      final vodTodo = vodCategories
          .where((c) =>
              (force || !vodByCategoryName.containsKey(c.name)) &&
              !hiddenGroups.contains(c.name))
          .toList();
      final seriesTodo = seriesCategories
          .where((c) =>
              (force || !seriesByCategoryName.containsKey(c.name)) &&
              !hiddenGroups.contains(c.name))
          .toList();
      final total = vodTodo.length + seriesTodo.length;
      if (total > 0) {
        isWarmingCatalog = true;
        warmCatalogDone = 0;
        warmCatalogTotal = total;
        vodCatalogDone = 0;
        vodCatalogTotal = vodTodo.length;
        seriesCatalogDone = 0;
        seriesCatalogTotal = seriesTodo.length;
        _notifyWarmupProgress(force: true);

        final maxConcurrent = _categoryConcurrency;
        var vodIndex = 0;
        Future<void> vodWorker() async {
          while (!serverDown && vodIndex < vodTodo.length) {
            final cat = vodTodo[vodIndex++];
            await _loadOneVodCategory(api, cat, force: force);
            vodCatalogDone++;
            warmCatalogDone++;
            _notifyWarmupProgress();
          }
        }

        var seriesIndex = 0;
        Future<void> seriesWorker() async {
          while (!serverDown && seriesIndex < seriesTodo.length) {
            final cat = seriesTodo[seriesIndex++];
            await _loadOneSeriesCategory(api, cat, force: force);
            seriesCatalogDone++;
            warmCatalogDone++;
            _notifyWarmupProgress();
          }
        }

        await Future.wait([
          ...List.generate(
              vodTodo.isEmpty ? 0 : maxConcurrent.clamp(1, vodTodo.length),
              (_) => vodWorker()),
          ...List.generate(
              seriesTodo.isEmpty
                  ? 0
                  : maxConcurrent.clamp(1, seriesTodo.length),
              (_) => seriesWorker()),
        ]);
      }
      // Not a full sync when the server was down: try again next launch.
      if (!serverDown) {
        await storage.setLastFullSyncAt(profile.id, DateTime.now());
      }
    } catch (e) {
      debugPrint('PlaylistSession[${profile.id}]: catalog warm-up failed: $e');
    } finally {
      isWarmingCatalog = false;
      _notifyWarmupProgress(force: true);
    }
  }

  /// Fetches episodes for one series, grouped by season number.
  Future<SeriesEpisodesResult> loadSeriesEpisodes(XtreamSeries series,
      {bool plotOnly = false}) async {
    final api = xtreamApi;
    if (api == null) {
      return (episodes: <int, List<Channel>>{}, plot: null, details: null);
    }
    final result = await api.getSeriesEpisodes(series.seriesId, series.name,
        plotOnly: plotOnly);
    _noteFetch(null);
    for (final list in result.episodes.values) {
      for (final channel in list) {
        channel.isFavorite = favoriteIds().contains(channel.id);
        channel.epgIdOverride = epgIdOverrides[channel.rawId];
        channel.seriesId = series.seriesId;
        channel.seriesName = series.name;
        channel.seriesCoverUrl = series.coverUrl;
      }
    }
    return result;
  }

  /// Movie plot/description — [rawStreamId] is `Channel.rawId` with its
  /// `xt_vod_` prefix already stripped by the caller (`PlaylistManager
  /// .getVodDescription`).
  Future<String?> getVodDescription(String rawStreamId) async {
    final api = xtreamApi;
    if (api == null) return null;
    return api.getVodDescription(rawStreamId);
  }

  /// [getVodDescription] plus the provider's HD poster/backdrop from the
  /// same `get_vod_info` response.
  Future<VodDetails> getVodInfo(String rawStreamId) async {
    final api = xtreamApi;
    if (api == null) return VodDetails.empty;
    return api.getVodInfo(rawStreamId);
  }

  /// Applies [groupOrder] for [type]: titles the user has ordered come
  /// first in that order, anything not in it yet (e.g. a category the
  /// provider added since) follows in provider order.
  List<M3uGroup> _ordered(String type, List<M3uGroup> groups) {
    final order = groupOrder[type];
    if (order == null || order.isEmpty) return groups;
    final byTitle = <String, List<M3uGroup>>{};
    for (final g in groups) {
      (byTitle[g.title] ??= []).add(g);
    }
    final result = <M3uGroup>[];
    for (final title in order) {
      final matches = byTitle.remove(title);
      if (matches != null) result.addAll(matches);
    }
    for (final g in groups) {
      if (byTitle.containsKey(g.title)) result.add(g);
    }
    return result;
  }

  /// Moves [title] by [delta] places among the *visible* (non-hidden)
  /// groups of [type] — a hidden neighbour in between would otherwise make
  /// a press look like it did nothing. Clamped to the ends, so a big
  /// negative delta means "move to top". Returns the new visible index, or
  /// null if [title] isn't a visible group of [type]. [shown], when given,
  /// is the exact list of titles on screen (the Movies/TV Shows rail also
  /// leaves out categories that haven't loaded anything yet) and is used
  /// as the "visible" list instead.
  Future<int?> moveGroup(String type, String title, int delta,
      {List<String>? shown}) async {
    final all = switch (type) {
      'tv' => tvGroups,
      'vod' => vodGroups,
      _ => seriesGroups,
    }
        .map((g) => g.title)
        .toSet()
        .toList();
    // Order always comes from [all] (the current saved order); [shown] only
    // decides membership, so a stale copy from a quick double-press is fine.
    final shownSet = shown?.toSet();
    final visible = all
        .where((t) =>
            shownSet != null ? shownSet.contains(t) : !hiddenGroups.contains(t))
        .toList();
    final from = visible.indexOf(title);
    if (from < 0) return null;
    final to = (from + delta).clamp(0, visible.length - 1);
    if (to == from) return from;
    final anchor = visible[to];
    all.remove(title);
    final anchorIndex = all.indexOf(anchor);
    all.insert(delta < 0 ? anchorIndex : anchorIndex + 1, title);
    groupOrder[type] = all;
    await storage.setGroupOrder(profile.id, type, all);
    onNotify();
    return to;
  }

  List<M3uGroup> get tvGroups {
    final groups = _ordered('tv', _providerTvGroups);
    if (mergeHiddenGroups.isEmpty) return groups;
    return [
      for (final g in groups)
        mergeHiddenGroups.contains(g.title) && !g.isHidden
            ? M3uGroup(
                title: g.title,
                playlistId: g.playlistId,
                channels: g.channels,
                isHidden: true)
            : g
    ];
  }

  /// Playlist editor group renames / merges ([PlaylistEdits.groupNames]):
  /// the provider's groups under their shown titles, merged groups at the
  /// first one's place.
  List<M3uGroup> get _providerTvGroups {
    final groups = _sourceTvGroups;
    if (edits.groupNames.isEmpty) return groups;
    final byTitle = <String, M3uGroup>{};
    for (final g in groups) {
      final title = edits.groupTitle(g.title);
      final prev = byTitle[title];
      byTitle[title] = M3uGroup(
        title: title,
        playlistId: profile.id,
        channels: prev == null ? g.channels : [...prev.channels, ...g.channels],
        isHidden: hiddenGroups.contains(title),
      );
    }
    return byTitle.values.toList();
  }

  /// The provider's live group titles, before editor renames.
  List<String> get sourceTvGroupTitles =>
      [for (final g in _sourceTvGroups) g.title];

  List<M3uGroup> get _sourceTvGroups {
    if (isXtream) {
      // No category list (not cached, and the provider refusing a fresh
      // one: Trex 403 on the owner's home IP, 2026-11-02) but channels
      // are there: build the groups from the channels' own group names,
      // in provider order, instead of an empty groups column.
      if (liveCategories.isEmpty && liveChannels.isNotEmpty) {
        final titles = <String>{for (final c in liveChannels) c.group};
        return [
          for (final t in titles)
            if (t.isNotEmpty)
              M3uGroup(
                title: t,
                playlistId: profile.id,
                channels: const [],
                isHidden: hiddenGroups.contains(t),
              )
        ];
      }
      return liveCategories
          .map((c) => M3uGroup(
                title: c.name,
                playlistId: profile.id,
                channels: const [],
                isHidden: hiddenGroups.contains(c.name),
              ))
          .toList();
    }
    return allGroups.where((g) => _classifyGroup(g.title) == 'tv').toList();
  }

  List<M3uGroup> get vodGroups => _ordered('vod', _providerVodGroups);

  List<M3uGroup> get _providerVodGroups {
    if (isXtream) {
      return vodCategories
          .map((c) => M3uGroup(
                title: c.name,
                playlistId: profile.id,
                channels: vodByCategoryName[c.name] ?? const [],
                isHidden: hiddenGroups.contains(c.name),
              ))
          .toList();
    }
    return allGroups.where((g) => _classifyGroup(g.title) == 'vod').toList();
  }

  List<M3uGroup> get seriesGroups => _ordered('series', _providerSeriesGroups);

  List<M3uGroup> get _providerSeriesGroups {
    if (isXtream) {
      return seriesCategories
          .map((c) => M3uGroup(
                title: c.name,
                playlistId: profile.id,
                channels: const [],
                isHidden: hiddenGroups.contains(c.name),
              ))
          .toList();
    }
    return allGroups.where((g) => _classifyGroup(g.title) == 'series').toList();
  }

  List<Channel> visibleChannels(
      {String? groupTitle, required String category}) {
    if (isXtream) {
      switch (category) {
        case 'tv':
          final list = groupTitle != null
              ? _orderedChannels(groupTitle,
                  liveChannels.where((c) => liveGroupOf(c) == groupTitle))
              : liveChannels
                  .where((c) => !hiddenGroups.contains(liveGroupOf(c)));
          // Applied even when a specific group was asked for (unlike
          // hiddenGroups above) — a hidden channel is usually a
          // duplicate *within* an otherwise-wanted group, so hiding the
          // whole group isn't the option the user actually wants.
          return list.where((c) => !isLiveHidden(c.rawId)).toList();
        case 'vod':
          return groupTitle != null
              ? (vodByCategoryName[groupTitle] ?? const [])
              : vodByCategoryName.entries
                  .where((e) => !hiddenGroups.contains(e.key))
                  .expand((e) => e.value)
                  .toList();
        default:
          return const [];
      }
    }

    if (groupTitle != null) {
      final inGroup = channels.where(
          (c) => (category == 'tv' ? liveGroupOf(c) : c.group) == groupTitle);
      final list =
          category == 'tv' ? _orderedChannels(groupTitle, inGroup) : inGroup;
      return (category == 'tv'
              ? list.where((c) => !isLiveHidden(c.rawId))
              : list)
          .toList();
    }
    return channels
        .where((c) =>
            _classifyGroup(c.group) == category &&
            !hiddenGroups
                .contains(category == 'tv' ? liveGroupOf(c) : c.group) &&
            (category != 'tv' || !isLiveHidden(c.rawId)))
        .toList();
  }

  /// The live channels [visibleChannels] leaves out (hidden groups and
  /// channels): Sports Trak says when a game is only on one of them.
  List<Channel> hiddenLiveChannels() {
    final live = isXtream
        ? liveChannels
        : channels.where((c) => _classifyGroup(c.group) == 'tv');
    return live
        .where((c) =>
            hiddenGroups.contains(liveGroupOf(c)) || isLiveHidden(c.rawId))
        .toList();
  }

  /// Applies [channelOrder] for [groupTitle] — same rule as [_ordered]:
  /// ordered rawIds first, channels the provider added since follow in
  /// provider order.
  Iterable<Channel> _orderedChannels(
      String groupTitle, Iterable<Channel> inGroup) {
    final order = channelOrder[groupTitle];
    if (order == null || order.isEmpty) return inGroup;
    final byRawId = {for (final c in inGroup) c.rawId: c};
    return [
      for (final rawId in order)
        if (byRawId.remove(rawId) case final c?) c,
      ...inGroup.where((c) => byRawId.containsKey(c.rawId)),
    ];
  }

  /// Moves the live channel [rawId] by [delta] places among [groupTitle]'s
  /// visible channels (a hidden one in between would make a press look
  /// like it did nothing), clamped to the ends. Returns the new visible
  /// index, or null if it isn't a visible channel of that group.
  Future<int?> moveChannel(String groupTitle, String rawId, int delta) async {
    final source = isXtream ? liveChannels : channels;
    final all = _orderedChannels(
            groupTitle, source.where((c) => liveGroupOf(c) == groupTitle))
        .map((c) => c.rawId)
        .toList();
    final visible = all.where((id) => !isLiveHidden(id)).toList();
    final from = visible.indexOf(rawId);
    if (from < 0) return null;
    final to = (from + delta).clamp(0, visible.length - 1);
    if (to == from) return from;
    final anchor = visible[to];
    all.remove(rawId);
    final anchorIndex = all.indexOf(anchor);
    all.insert(delta < 0 ? anchorIndex : anchorIndex + 1, rawId);
    channelOrder[groupTitle] = all;
    await storage.setChannelOrder(profile.id, channelOrder);
    onNotify();
    return to;
  }

  /// A live channel's group as shown: the viewer's own group it was moved
  /// into, else the provider's.
  String liveGroupOf(Channel c) =>
      myGroupOf?.call(c) ?? edits.groupTitle(c.group);

  Future<void> toggleChannelHidden(String rawId) async {
    if (hiddenChannels.contains(rawId)) {
      hiddenChannels.remove(rawId);
    } else {
      hiddenChannels.add(rawId);
    }
    await storage.setHiddenChannels(profile.id, hiddenChannels);
    onNotify();
  }

  /// [epgId] null clears the override (back to this channel's own rawId).
  /// Patches every already-loaded `Channel` with this [rawId] in place
  /// (both `channels` and `liveChannels` — one of them is always empty
  /// depending on mode, so this is safe to run unconditionally on both
  /// rather than needing to know which mode this session is in) rather
  /// than requiring a full reload for the change to show up anywhere.
  /// [isAuto] marks this as "Auto-Pair Channels"' own doing rather than a
  /// manual pick — see [autoPairedEpgOverrides]'s doc comment. A manual
  /// call (the ordinary picker screen's own default) always clears that
  /// mark, whether it's setting a fresh value or clearing one outright —
  /// either way this rawId is no longer "just an auto guess" once a
  /// person has looked at it.
  Future<void> setEpgIdOverride(String rawId, String? epgId,
      {bool isAuto = false}) async {
    if (epgId == null || epgId.isEmpty) {
      epgIdOverrides.remove(rawId);
    } else {
      epgIdOverrides[rawId] = epgId;
    }
    if (isAuto && epgId != null && epgId.isNotEmpty) {
      autoPairedEpgOverrides.add(rawId);
    } else {
      autoPairedEpgOverrides.remove(rawId);
    }
    await storage.setEpgIdOverrides(profile.id, epgIdOverrides);
    await storage.setAutoPairedEpgOverrides(profile.id, autoPairedEpgOverrides);
    for (final channel in channels) {
      if (channel.rawId == rawId) channel.epgIdOverride = epgIdOverrides[rawId];
    }
    for (final channel in liveChannels) {
      if (channel.rawId == rawId) channel.epgIdOverride = epgIdOverrides[rawId];
    }
    onNotify();
  }

  /// See [setChannelLinksBulk]'s doc comment — same fix, for EPG
  /// assignments instead of cross-playlist links. Also patches every
  /// affected `Channel.epgIdOverride` in one pass over each list (not
  /// once per entry in [newOverrides] — the same quadratic trap
  /// [setChannelLinksBulk] describes applies here just as much, since
  /// [setEpgIdOverride] above re-scans the *entire* channel list on
  /// every single call).
  Future<void> setEpgIdOverridesBulk(Map<String, String> newOverrides) async {
    if (newOverrides.isEmpty) return;
    epgIdOverrides.addAll(newOverrides);
    autoPairedEpgOverrides.addAll(newOverrides.keys);
    await storage.setEpgIdOverrides(profile.id, epgIdOverrides);
    await storage.setAutoPairedEpgOverrides(profile.id, autoPairedEpgOverrides);
    for (final channel in channels) {
      final id = newOverrides[channel.rawId];
      if (id != null) channel.epgIdOverride = id;
    }
    for (final channel in liveChannels) {
      final id = newOverrides[channel.rawId];
      if (id != null) channel.epgIdOverride = id;
    }
    onNotify();
  }

  /// [link] null clears it. No per-`Channel` field to patch afterward —
  /// see [channelLinks]'s own doc comment for why this is simpler than
  /// [setEpgIdOverride] just above it. [isAuto]: see that same method's
  /// own doc comment.
  Future<void> setChannelLink(String rawId, ChannelLink? link,
      {bool isAuto = false}) async {
    if (link == null) {
      channelLinks.remove(rawId);
    } else {
      channelLinks[rawId] = link;
    }
    if (isAuto && link != null) {
      autoPairedChannelLinks.add(rawId);
    } else {
      autoPairedChannelLinks.remove(rawId);
    }
    await storage.setChannelLinks(profile.id, channelLinks);
    await storage.setAutoPairedChannelLinks(profile.id, autoPairedChannelLinks);
    onNotify();
  }

  /// "Auto-Pair Channels"' own way of applying many links at once — see
  /// [PlaylistManager.autoPairChannelLinks]. [setChannelLink] above is
  /// exactly right for a single manual pick, but was also (wrongly) being
  /// called once per match from that bulk pass: each call there does a
  /// full disk write of the *entire* accumulated map, an O(size) cost
  /// that grows with every match added — reported directly as "still
  /// running after 5 minutes" against a catalog with a few thousand
  /// channels. This does the same update, but writes to disk and patches
  /// every affected `Channel` exactly once, regardless of how many
  /// [newLinks] there are.
  Future<void> setChannelLinksBulk(Map<String, ChannelLink> newLinks) async {
    if (newLinks.isEmpty) return;
    channelLinks.addAll(newLinks);
    autoPairedChannelLinks.addAll(newLinks.keys);
    await storage.setChannelLinks(profile.id, channelLinks);
    await storage.setAutoPairedChannelLinks(profile.id, autoPairedChannelLinks);
    onNotify();
  }

  List<XtreamSeries> visibleSeries(String? categoryName) {
    if (categoryName != null)
      return seriesByCategoryName[categoryName] ?? const [];
    return seriesByCategoryName.entries
        .where((e) => !hiddenGroups.contains(e.key))
        .expand((e) => e.value)
        .toList();
  }

  Future<void> setGroupFavorited(String title, bool favorited) async {
    if (favorited) {
      favoritedGroups.add(title);
    } else {
      favoritedGroups.remove(title);
    }
    await storage.setFavoritedGroups(profile.id, favoritedGroups);
    onNotify();
  }

  Future<void> toggleGroupHidden(String groupTitle) async {
    final hidden = !hiddenGroups.contains(groupTitle);
    await _applyGroupHiddenChange([groupTitle], hidden);
    onNotify();
  }

  Future<void> setGroupHidden(String groupTitle, bool hidden,
      {bool loadImmediately = true}) async {
    await _applyGroupHiddenChange([groupTitle], hidden);
    onNotify();
    if (!hidden && loadImmediately) unawaited(_loadIfNewlyShown(groupTitle));
  }

  Future<void> setGroupsHidden(Iterable<String> groupTitles, bool hidden,
      {bool loadImmediately = true}) async {
    await _applyGroupHiddenChange(groupTitles, hidden);
    onNotify();
    if (!hidden && loadImmediately) {
      for (final title in groupTitles) {
        unawaited(_loadIfNewlyShown(title));
      }
    }
  }

  Future<void> _loadIfNewlyShown(String groupTitle) async {
    if (!isXtream) return;
    if (vodCategoryIdByName.containsKey(groupTitle)) {
      await ensureCategoryLoaded(groupTitle, 'vod');
    } else if (seriesCategoryIdByName.containsKey(groupTitle)) {
      await ensureCategoryLoaded(groupTitle, 'series');
    }
  }
}

// Top-level — required by `compute`, which runs this on a separate isolate
// with no access to instance state.
class _XtreamCategoriesRaw {
  const _XtreamCategoriesRaw({
    required this.liveCatRaw,
    required this.vodCatRaw,
    required this.seriesCatRaw,
  });
  final String liveCatRaw;
  final String vodCatRaw;
  final String seriesCatRaw;
}

class _XtreamCategoriesDecoded {
  const _XtreamCategoriesDecoded({
    required this.liveCategories,
    required this.vodCategories,
    required this.seriesCategories,
  });
  final List<XtreamCategory> liveCategories;
  final List<XtreamCategory> vodCategories;
  final List<XtreamCategory> seriesCategories;
}

_XtreamCategoriesDecoded _decodeXtreamCategoriesBatch(
    _XtreamCategoriesRaw raw) {
  final liveCategories = (jsonDecode(raw.liveCatRaw) as List)
      .map((e) => XtreamCategory.fromJson(e as Map<String, dynamic>))
      .toList();
  final vodCategories = (jsonDecode(raw.vodCatRaw) as List)
      .map((e) => XtreamCategory.fromJson(e as Map<String, dynamic>))
      .toList();
  final seriesCategories = (jsonDecode(raw.seriesCatRaw) as List)
      .map((e) => XtreamCategory.fromJson(e as Map<String, dynamic>))
      .toList();
  return _XtreamCategoriesDecoded(
    liveCategories: liveCategories,
    vodCategories: vodCategories,
    seriesCategories: seriesCategories,
  );
}

/// Isolate entry point: reads a cached channel list straight from disk, so
/// the file read and its UTF-8 decode happen off the main thread as well as
/// the JSON parse. See StorageService.cacheFilePath for why that matters.
List<Channel> _readM3uChannelsFile(String path) =>
    _readChannelsFile(path).map(M3uParser.withCatalogType).toList();

List<Channel> _readChannelsFile(String path) =>
    _decodeLiveChannelsBatch(File(path).readAsStringSync());

List<Channel> _decodeLiveChannelsBatch(String raw) => (jsonDecode(raw) as List)
    .map((e) => Channel.fromJson(e as Map<String, dynamic>))
    .toList();

/// Off the main isolate, matching the read-side decode path above and
/// `XtreamApiService._getJson`'s own `compute(_decodeJsonBody, ...)`.
/// Reported directly, live: a large account's live-channel cache write
/// (confirmed on one real test account: 28,388 channels) froze the UI
/// thread long enough that the Add Playlist status box appeared to
/// "flash and go blank" for several real seconds — traced via timestamped
/// logging to a gap between `getLiveStreams()` returning (already
/// isolate-backgrounded) and the next status update, which is exactly
/// where the un-computed `jsonEncode(...)` for this cache write sat,
/// synchronously serializing the whole list on the UI isolate before the
/// file write itself could even start.
String _encodeJsonList(List<Map<String, dynamic>> maps) => jsonEncode(maps);

/// Just the hostname for status messages — a full `http://host:8080` in
/// "Connecting to ..." reads as noise on a TV across the room.
String _hostLabel(String server) {
  final host = Uri.tryParse(server)?.host ?? '';
  return host.isEmpty ? server : host;
}

/// True when a server answered and turned the *account* away, as opposed
/// to not answering at all. See `PlaylistSession._connectWithFallback`
/// for why those two cases can't be treated the same way: matched on
/// `XtreamApiService.authenticate`'s own thrown messages, which are the
/// only place these two states are distinguishable by the time they
/// reach here.
bool _isAccountRejection(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('invalid xtream username') ||
      text.contains('account is not active');
}
