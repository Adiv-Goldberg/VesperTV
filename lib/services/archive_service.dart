import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../models/archive_models.dart';
import '../models/archive_library.dart';
import '../models/channel.dart';
import '../utils/title_search.dart';
import 'archive_api_service.dart';
import 'archive_cache.dart';
import 'archive_stream_session.dart';
import 'media_server_api.dart';
import 'plex_api.dart';
import 'storage_service.dart';
import 'tracker_api.dart';

/// One row of the Archive browse: a source's catalog and its titles, or
/// (with [searchQuery]) that catalog's results for a search.
class ArchiveRow {
  const ArchiveRow({
    required this.source,
    required this.catalog,
    required this.items,
    this.searchQuery,
    this.itemSources,
    this.isFavorites = false,
    this.sourceLabel,
    this.continuations,
    this.upcoming = false,
    this.customTitle,
  });

  final ArchiveSource source;
  final ArchiveCatalog catalog;
  final List<ArchiveMeta> items;
  final String? searchQuery;

  /// Set on the watched-history and Favourites rows, whose titles come
  /// from several sources: the source of each item (else every item is
  /// [source]'s).
  final List<ArchiveSource>? itemSources;

  /// The Favourites row (also carries [itemSources]).
  final bool isFavorites;

  /// Who the row's titles come from, when that isn't just [source]: a
  /// search row shared by stream-only add-ons on the same provider names
  /// every one of them ("Torrentio TB · NoxAIO").
  final String? sourceLabel;
  final List<ArchiveContinueItem>? continuations;
  final bool upcoming;
  final String? customTitle;

  /// The source name shown for item [i] (hero chip, search row header).
  String labelAt(int i) =>
      itemSources != null ? sourceAt(i).name : sourceLabel ?? source.name;

  ArchiveSource sourceAt(int i) => itemSources?[i] ?? source;

  bool get isSearch => searchQuery != null;
  bool get isHistory =>
      itemSources != null && !isFavorites && continuations == null;

  String get key => continuations != null
      ? '${upcoming ? 'upcoming' : 'continue'}|${catalog.type.wire}'
      : isFavorites
          ? 'favorites|${catalog.type.wire}'
          : isHistory
              ? 'history|${catalog.type.wire}'
              : isSearch
                  ? 'search|${ArchiveService._rowKey(source, catalog)}'
                  : ArchiveService._rowKey(source, catalog);

  /// The row header: the catalog's own name, or the source name when the
  /// catalog has none. Provider row names ("Popular") and search rows are
  /// translated by the screen.
  String get title =>
      customTitle ?? (catalog.name.isEmpty ? source.name : catalog.name);
}

/// One stream offered for a title, with the source that offered it.
class ArchiveStreamOption {
  const ArchiveStreamOption({required this.source, required this.stream});

  final ArchiveSource source;
  final ArchiveStream stream;
}

/// The Archive tab's state: the user's sources (Settings > Archive
/// sources), their catalog rows (cache first, then network), and turning
/// a picked title into a [Channel] the existing player can play.
///
/// Sources are any server that follows the Stremio add-on REST schema
/// (see [ArchiveApiService]) — the app ships none, so nothing is
/// contacted until the user adds one. Only direct http(s) streams are
/// used; torrent/debrid entries are ignored on purpose.
class ArchiveService extends ChangeNotifier {
  /// Settings > Media Hub > Custom posters changed: rows rebuild with the
  /// new poster addresses (`ArchiveMeta.posterUrl`).
  void postersChanged() => notifyListeners();

  ArchiveService(this._storage,
      {ArchiveApiService? api,
      ArchiveCache? cache,
      MediaServerApi? servers,
      TrackerApi? trackers})
      : _api = api ?? ArchiveApiService(diagnostics: debugPrint),
        _cache = cache ?? ArchiveCache(),
        _servers = servers ?? MediaServerApi(),
        _trackers = trackers ?? TrackerApi() {
    _viewerState = _storage.viewerGeneration;
  }

  final StorageService _storage;
  final ArchiveApiService _api;
  final ArchiveCache _cache;
  bool get autoPlayLargest => _storage.getArchiveAutoLargest();
  Future<void> setAutoPlayLargest(bool value) async {
    await _storage.setArchiveAutoLargest(value);
    _notify();
  }

  /// Jellyfin/Emby sources ([ArchiveSource.server]) go here instead of
  /// [_api]; everything else (rows, cache, search, history, Play) is the
  /// same for both kinds of source.
  final MediaServerApi _servers;

  /// Trakt/Simkl accounts ([ArchiveSource.tracker]): their lists are rows.
  final TrackerApi _trackers;

  Future<List<ArchiveMeta>> _page(ArchiveSource s, ArchiveCatalog c,
      {int skip = 0, String? search}) async {
    final watch = Stopwatch()..start();
    final kind = s.tracker != null
        ? 'tracker'
        : s.server != null
            ? 'server'
            : 'addon';
    try {
      final List<ArchiveMeta> items;
      if (s.tracker != null) {
        if (search != null) return const [];
        final login = await _freshTracker(s);
        items = await _trackers.fetchCatalog(login, c, skip: skip);
      } else {
        items = s.server != null
            ? await _servers.fetchCatalog(s, c, skip: skip, search: search)
            : await _api.fetchCatalog(s.catalogBaseUrl, c,
                skip: skip, search: search);
      }
      final art = items.where((m) => m.posterUrl?.isNotEmpty ?? false).length;
      debugPrint('ArchiveRow: source=${s.key} kind=$kind type=${c.wire} '
          'items=${items.length} posters=$art missing=${items.length - art} '
          'fetchMs=${watch.elapsedMilliseconds}');
      return items;
    } catch (error) {
      debugPrint(
          'ArchiveRow: source=${s.key} kind=$kind failed=${error.runtimeType} '
          'fetchMs=${watch.elapsedMilliseconds}');
      rethrow;
    }
  }

  // ---- Trakt / Simkl -------------------------------------------------------

  /// [s]'s login, refreshed (and saved) first when it's about to expire.
  Future<TrackerLogin> _freshTracker(ArchiveSource s) async {
    final login = s.tracker!;
    if (!login.needsRefresh) return login;
    final fresh = await _trackers.refresh(login);
    await _saveSources([
      for (final x in sources)
        x.manifestUrl == s.manifestUrl ? x.copyWith(tracker: fresh) : x,
    ]);
    return fresh;
  }

  /// The connected tracker account of [kind], if any.
  ArchiveSource? trackerSource(TrackerKind kind) =>
      sources.where((s) => s.tracker?.kind == kind).firstOrNull;

  /// Every enabled account's login, fresh — what `WatchTracker` reports to.
  Future<List<TrackerLogin>> trackerLogins() async {
    final out = <TrackerLogin>[];
    for (final s in enabledSources) {
      if (s.tracker == null) continue;
      try {
        out.add(await _freshTracker(s));
      } catch (e) {
        debugPrint('ArchiveService: ${s.name} token refresh failed: $e');
      }
    }
    return out;
  }

  /// Adds (or replaces: one account per tracker) a signed-in account.
  Future<ArchiveSource> addTracker(TrackerLogin login) async {
    final source = ArchiveSource(
      manifestUrl: '${login.kind.name}://account',
      name: login.kind.label,
      description: login.userName,
      catalogs: TrackerApi.catalogsFor(login.kind),
      tracker: login,
    );
    await _saveSources([
      for (final s in sources)
        if (s.tracker?.kind != login.kind) s,
      source,
    ]);
    unawaited(refresh(force: true));
    return source;
  }

  /// Every Archive [Channel] uses this playlist id; `PlaybackService.play`
  /// lets it through (no playlist profile backs it).
  static const playlistId = 'archive';

  /// A cached catalog younger than this isn't refetched on open.
  static const _staleAfter = Duration(hours: 12);

  /// Pages fetched per catalog (sources usually send 100 per page).
  static const _pagesPerCatalog = 2;

  final Map<String, List<ArchiveMeta>> _items = {};
  bool _loadedFromCache = false;
  bool _refreshing = false;
  bool _refreshAgain = false;
  bool _forceRefreshAgain = false;
  String? lastError;

  bool get refreshing => _refreshing;

  // ---- sources ------------------------------------------------------------

  int _viewerState = -1;
  void _ensureViewerState() {
    if (_viewerState == _storage.viewerGeneration) return;
    _viewerState = _storage.viewerGeneration;
    _search.clear();
    _searchingTypes.clear();
    _searchGeneration.clear();
    _focusedSearchRows.clear();
    _searchStates.clear();
    _searchNames.clear();
    _selectedSearchSource.clear();
    _genre.clear();
    _newest.clear();
  }

  List<ArchiveSource> get sources {
    _ensureViewerState();
    final raw = _storage.getArchiveSourcesJson();
    if (raw == null) return const [];
    try {
      return [
        for (final j in jsonDecode(raw) as List)
          if (ArchiveSource.fromJson(Map<String, dynamic>.from(j as Map))
              case final s)
            // A tracker's rows are always the current set (accounts added
            // before "Continue watching" existed get it too).
            s.tracker == null
                ? s
                : s.copyWith(catalogs: TrackerApi.catalogsFor(s.tracker!.kind)),
      ];
    } catch (_) {
      return const [];
    }
  }

  List<ArchiveSource> get enabledSources =>
      sources.where((s) => s.enabled).toList();

  bool get showCinemetaCatalog => _storage.getArchiveCinemetaCatalog();

  Future<void> setShowCinemetaCatalog(bool on) async {
    await _storage.setArchiveCinemetaCatalog(on);
    _search.clear();
    _genre.clear();
    _newest.clear();
    _notify();
    if (on) await refresh();
  }

  // Hide only the automatic browse/search catalogs. Stream resolution and
  // metadata still use these enabled sources, including saved titles.
  bool _showCatalogs(ArchiveSource source) =>
      showCinemetaCatalog ||
      !source.streamOnly ||
      source.catalogProviderUrl != ArchiveCatalogProvider.baseUrl;

  Future<void> _saveSources(List<ArchiveSource> list) async {
    await _storage
        .setArchiveSourcesJson(jsonEncode([for (final s in list) s.toJson()]));
    _notify();
  }

  /// Custom sources can replace their catalog ids without changing the
  /// manifest link. Re-read their definitions on open and explicit Refresh,
  /// keeping the saved definition if the source cannot answer. With [all]
  /// (explicit Refresh) every add-on is re-read: a stream-only add-on can
  /// gain catalogs of its own (an AIOStreams config adding TMDB) and was
  /// never updated before (owner, 2026-10-27).
  Future<void> _recheckCustomSources({bool all = false}) async {
    for (final s in sources) {
      if (!s.enabled || s.server != null || s.tracker != null) continue;
      if (!all &&
          (s.streamOnly ||
              s.catalogs.isEmpty ||
              !s.catalogs.any((c) => c.wireType != null))) {
        continue;
      }
      await _refreshManifest(s);
    }
  }

  Future<void> _refreshManifest(ArchiveSource s) async {
    try {
      final fresh = await _api
          .fetchManifest(s.manifestUrl)
          .timeout(const Duration(seconds: 10));
      // Settings may have changed while the network request was pending.
      // Never resurrect a removed source or overwrite its current choices.
      final current = sources;
      final index = current.indexWhere((p) => p.manifestUrl == s.manifestUrl);
      if (index < 0) return;
      final saved = current[index];
      current[index] = fresh.copyWith(
          enabled: saved.enabled, otherChoice: saved.otherChoice);
      if (jsonEncode(current[index].toJson()) != jsonEncode(saved.toJson())) {
        await _saveSources(current);
      }
      debugPrint('ArchiveManifest: source=${s.key} '
          'catalogs=${fresh.catalogs.length} '
          'custom=${fresh.catalogs.where((c) => c.wireType != null).length} '
          'genres=${fresh.catalogs.expand((c) => c.genres).toSet().length} checked');
    } catch (e) {
      debugPrint('ArchiveManifest: source=${s.key} '
          'failed=${e.runtimeType}; keeping saved catalogs');
    }
  }

  final Map<String, Future<void>> _searchManifestChecks = {};

  /// Upgrade old saved manifests without requiring removal/re-addition.
  /// Both global search types share the request; failed sources keep working.
  Future<void> _upgradeSearchCatalogs(bool other) async {
    final pending = enabledSources
        .where((s) =>
            !s.searchCatalogsChecked &&
            s.server == null &&
            s.tracker == null &&
            s.underOther == other &&
            _showCatalogs(s))
        .toList();
    Future<void> worker() async {
      while (pending.isNotEmpty && !_disposed) {
        final source = pending.removeAt(0);
        await _searchManifestChecks.putIfAbsent(
            source.key, () => _refreshManifest(source));
      }
    }

    await Future.wait([worker(), worker(), worker()]);
  }

  /// Checks [link]'s manifest without adding it (same errors as
  /// [addSource]) — an import checks every link first, then adds them in
  /// one save with [addCheckedSources].
  Future<ArchiveSource> checkSource(String link) => _api.fetchManifest(link);

  /// Adds sources from [checkSource] in one save and one refresh; a link
  /// already in the list is left out. Returns the ones added.
  Future<List<ArchiveSource>> addCheckedSources(
      List<ArchiveSource> found) async {
    final list = sources;
    final have = {for (final s in list) s.manifestUrl};
    final added = [
      for (final s in found)
        if (have.add(s.manifestUrl)) s,
    ];
    if (added.isEmpty) return added;
    await _saveSources([...list, ...added]);
    unawaited(refresh(force: true));
    return added;
  }

  /// True when [link] (normalized like a manifest URL) is already a source.
  bool hasSource(String link) {
    final url = ArchiveApiService.normalizeManifestUrl(link);
    return sources.any((s) => s.manifestUrl == url);
  }

  /// Checks [link]'s manifest and adds it. Throws [ArchiveApiException]
  /// (bad link, no streams/catalogs) or [StateError] (already added).
  Future<ArchiveSource> addSource(String link) async {
    final source = await _api.fetchManifest(link);
    final list = sources;
    if (list.any((s) => s.manifestUrl == source.manifestUrl)) {
      throw StateError('already added');
    }
    await _saveSources([...list, source]);
    unawaited(refresh(force: true));
    return source;
  }

  /// Signs in to a Jellyfin/Emby server and adds it (signing in again as
  /// the same user replaces the old login). Throws
  /// [MediaServerLoginException] (wrong user/password),
  /// [MediaServerNoLibraryException] or [ArchiveApiException] (no server
  /// there).
  Future<ArchiveSource> addMediaServer(
      String address, String userName, String password) async {
    final source = await _servers.connect(address, userName, password);
    return _addServerSource(source);
  }

  Future<ArchiveSource> addPlexServer(
      PlexServer server, String deviceId) async {
    final source = await _servers.connectPlex(server, deviceId);
    return _addServerSource(source);
  }

  Future<ArchiveSource> _addServerSource(ArchiveSource source) async {
    final list = sources;
    final at = list.indexWhere((s) => s.key == source.key);
    if (at >= 0) {
      source = source.copyWith(
          enabled: list[at].enabled, otherChoice: list[at].otherChoice);
    }
    await _saveSources(at < 0
        ? [...list, source]
        : [for (var i = 0; i < list.length; i++) i == at ? source : list[i]]);
    unawaited(refresh(force: true));
    return source;
  }

  /// The source's "Show under Other" switch (see [ArchiveSource.underOther]).
  Future<void> setUnderOther(ArchiveSource source, bool on) => _saveSources([
        for (final s in sources)
          s.manifestUrl == source.manifestUrl ? s.copyWith(otherChoice: on) : s,
      ]);

  Future<void> setEnabled(ArchiveSource source, bool on) => _saveSources([
        for (final s in sources)
          s.manifestUrl == source.manifestUrl ? s.copyWith(enabled: on) : s,
      ]);

  Future<void> removeSource(ArchiveSource source) async {
    await _saveSources(
        sources.where((s) => s.manifestUrl != source.manifestUrl).toList());
    _items.removeWhere((k, _) => k.startsWith('${source.key}|'));
    await _cache.deleteSource(source.key);
    _notify();
  }

  /// Removes every source and its cached rows (Clear archives).
  Future<void> clearAll() async {
    await _saveSources(const []);
    _items.clear();
    await _cache.clear();
    _notify();
  }

  // ---- catalog rows -------------------------------------------------------

  static String _rowKey(ArchiveSource s, ArchiveCatalog c) =>
      '${s.key}|${c.wire}|${c.slug}';

  /// Catalogs of [type] to read, one per distinct row: a provider catalog
  /// shared by several stream-only sources is listed once (Play still
  /// asks every stream-only source — see [streams]). While a genre is
  /// picked ([setGenre]) only the catalogs offering it are listed, narrowed
  /// to it; [filtered] false lists the plain ones (search ignores genre).
  ///
  /// A source [ArchiveSource.underOther] (custom-type catalogs by default,
  /// or the user's switch) has its catalogs listed only while the
  /// [otherGenre] filter is picked, and then alone — search follows the
  /// same split.
  List<(ArchiveSource, ArchiveCatalog)> _catalogs(ArchiveType type,
      {bool filtered = true,
      bool? underOther,
      bool includeSearchOnly = false}) {
    final other = underOther ?? _genre[type] == otherGenre;
    final newest = filtered && !other && _newest.contains(type);
    // Newest can't narrow server-side (a year catalog has no second filter):
    // [rows] applies a picked genre to its items instead.
    final genre = filtered && !other && !newest ? _genre[type] : null;
    final year = DateTime.now().year;
    final shown = <String>{};
    return [
      for (final s in enabledSources)
        if (_showCatalogs(s))
          for (final base in s.catalogs)
            if (base.type == type &&
                s.underOther == other &&
                (includeSearchOnly || !base.searchOnly))
              if ((newest
                      ? _newestOf(base, year)
                      : genre == null
                          ? base
                          : base.withGenre(genre))
                  case final c?)
                if (!s.streamOnly ||
                    shown.add('${s.catalogBaseUrl}|${c.wire}|${c.slug}'))
                  (s, c),
    ];
  }

  // ---- newest filter ------------------------------------------------------

  /// Types with the "Newest" filter on (floating bar), kept for the session.
  final Set<ArchiveType> _newest = {};

  bool newest(ArchiveType type) => _newest.contains(type);

  /// [base] as this year's releases: the provider's New row as it is, or a
  /// source's own year catalog (`year` in its id, the year among its genre
  /// options) narrowed to this year. Null for any other catalog.
  static ArchiveCatalog? _newestOf(ArchiveCatalog base, int year) {
    final y = '$year';
    if (base.id == 'year' && base.extra['genre'] == y) return base;
    if (base.searchOnly ||
        base.extra.containsKey('genre') ||
        !base.id.toLowerCase().contains('year') ||
        !base.years.contains(y)) {
      return null;
    }
    return ArchiveCatalog(
        type: base.type,
        id: base.id,
        name: 'New',
        extra: {...base.extra, 'genre': y},
        genres: base.genres,
        years: base.years,
        wireType: base.wireType);
  }

  /// Whether some source offers a release-year catalog for [type] (the
  /// Newest button is hidden otherwise).
  bool canNewest(ArchiveType type) {
    final year = DateTime.now().year;
    for (final s in enabledSources) {
      if (!_showCatalogs(s) || s.underOther) continue;
      for (final c in s.catalogs) {
        if (c.type == type && _newestOf(c, year) != null) return true;
      }
    }
    return false;
  }

  /// Shows only new releases of [type] (the year catalogs, narrowed by the
  /// picked genre when there is one), or the normal rows again.
  Future<void> setNewest(ArchiveType type, bool on) async {
    if (_newest.contains(type) == on) return;
    if (on) {
      _newest.add(type);
    } else {
      _newest.remove(type);
    }
    _notify();
    if (!on) return;
    for (final (s, c) in _catalogs(type)) {
      final key = _rowKey(s, c);
      if (_items.containsKey(key)) continue;
      try {
        _items[key] = await _cache.read(s.key, c);
      } catch (e) {
        debugPrint('ArchiveService: cache read failed: ${e.runtimeType}');
      }
    }
    _notify();
    await refresh();
  }

  /// [items] of a Newest row narrowed to the picked genre. Items that carry
  /// no genres can't be judged, so they're left out while a genre is picked.
  List<ArchiveMeta> _inGenre(ArchiveType type, List<ArchiveMeta> items) {
    final genre = _genre[type];
    if (genre == null || genre == otherGenre || !_newest.contains(type)) {
      return items;
    }
    final want = genre.toLowerCase();
    return [
      for (final m in items)
        if (m.genres.any((g) => g.toLowerCase() == want)) m,
    ];
  }

  // ---- genre filter -------------------------------------------------------

  /// The genre picked per type (rail "Genre"), kept for the session.
  final Map<ArchiveType, String> _genre = {};

  /// The "Other" pick in the genre filter: shows the catalogs of custom
  /// types (not movie/series) instead of the regular rows. Not a real
  /// genre name, so it can't collide with one.
  static const otherGenre = '\u0001other';

  String? genre(ArchiveType type) => _genre[type];

  /// Every genre a regular catalog of [type] can be narrowed to, in the
  /// order the sources list them, then [otherGenre] when an enabled source
  /// shown under Other has catalogs browsed under [type].
  List<String> genres(ArchiveType type) {
    final regular = <String>{};
    var other = false;
    for (final s in enabledSources) {
      if (!_showCatalogs(s)) continue;
      for (final c in s.catalogs) {
        if (c.type != type) continue;
        if (s.underOther) {
          other = true;
        } else if (!c.searchOnly) {
          regular.addAll(c.genres);
        }
      }
    }
    return [...regular, if (other) otherGenre];
  }

  /// Narrows [type]'s rows to [genre] (null = all): the rows offering it
  /// are shown from cache at once and fetched behind when stale.
  Future<void> setGenre(ArchiveType type, String? genre) async {
    if (_genre[type] == genre) return;
    if (genre == null) {
      _genre.remove(type);
    } else {
      _genre[type] = genre;
    }
    _notify();
    if (genre == null) return;
    for (final (s, c) in _catalogs(type)) {
      final key = _rowKey(s, c);
      if (_items.containsKey(key)) continue;
      try {
        _items[key] = await _cache.read(s.key, c);
      } catch (e) {
        debugPrint('ArchiveService: cache read failed: ${e.runtimeType}');
      }
    }
    _notify();
    await refresh();
  }

  /// The current search per type: its query and result rows.
  final Map<ArchiveType, (String, List<ArchiveRow>)> _search = {};
  final Map<ArchiveType, int> _searchGeneration = {};
  final Map<ArchiveType, Set<String>> _focusedSearchRows = {};
  void retainSearchFocus(ArchiveRow row) {
    if (row.isSearch) {
      (_focusedSearchRows[row.catalog.type] ??= {}).add(row.key);
    }
  }

  final Set<ArchiveType> _searchingTypes = {};
  final Map<ArchiveType, Map<String, ArchiveSourceStatus>> _searchStates = {};
  final Map<ArchiveType, Map<String, String>> _searchNames = {};
  final Map<ArchiveType, String> _selectedSearchSource = {};
  bool get searching => _searchingTypes.isNotEmpty;
  String? searchQuery(ArchiveType type) => _search[type]?.$1;
  Map<String, ArchiveSourceStatus> searchStates(ArchiveType type) =>
      _searchStates[type] ?? const {};
  Map<String, String> searchSourceNames(ArchiveType type) =>
      _searchNames[type] ?? const {};
  String? selectedSearchSource(ArchiveType type) => _selectedSearchSource[type];
  void selectSearchSource(ArchiveType type, String? key) {
    key == null
        ? _selectedSearchSource.remove(type)
        : _selectedSearchSource[type] = key;
    _notify();
  }

  Future<void> search(ArchiveType type, String query) async {
    _ensureViewerState();
    final q = query.trim();
    if (q.isEmpty) return clearSearch(type);
    final viewer = _storage.viewerGeneration;
    final generation = (_searchGeneration[type] ?? 0) + 1;
    _searchGeneration[type] = generation;
    _focusedSearchRows.remove(type);
    bool current() =>
        !_disposed &&
        viewer == _storage.viewerGeneration &&
        _searchGeneration[type] == generation;
    unawaited(_rememberSearch(type, q));
    _searchingTypes.add(type);
    _search[type] = (q, const []);
    _searchStates[type] = {};
    _searchNames[type] = {};
    _selectedSearchSource.remove(type);
    _notify();
    try {
      await searchRows(type, q, isCurrent: current,
          onStatus: (key, name, status) {
        if (!current()) return;
        _searchStates[type]![key] = status;
        _searchNames[type]![key] = name;
        _notify();
      }, onRows: (incoming) {
        if (!current()) return;
        // Append newly responding sources; later replies cannot move a row
        // already being browsed to another position in the result list.
        final existing = {for (final row in _search[type]!.$2) row.key: row};
        for (final row in incoming) {
          final previous = existing[row.key];
          if (previous == null ||
              !(_focusedSearchRows[type]?.contains(row.key) ?? false)) {
            existing[row.key] = row;
            continue;
          }
          final updated = {for (final meta in row.items) meta.id: meta};
          final stable = <ArchiveMeta>[
            for (final meta in previous.items) updated.remove(meta.id) ?? meta,
            ...updated.values,
          ];
          existing[row.key] = ArchiveRow(
              source: row.source,
              catalog: row.catalog,
              items: stable,
              searchQuery: row.searchQuery,
              sourceLabel: row.sourceLabel);
        }
        _search[type] = (q, existing.values.toList());
        _notify();
      });
    } finally {
      if (current()) {
        _searchingTypes.remove(type);
        _notify();
      }
    }
  }

  /// Incremental provider results, with bounded work and stale-request guards.
  /// The returned list remains in configured source order for non-UI callers.
  Future<List<ArchiveRow>> searchRows(ArchiveType type, String q,
      {bool? underOther,
      void Function(List<ArchiveRow>)? onRows,
      void Function(String, String, ArchiveSourceStatus)? onStatus,
      bool Function()? isCurrent}) async {
    final search = TitleSearch(q);
    final viewer = _storage.viewerGeneration;
    bool current() =>
        !_disposed &&
        viewer == _storage.viewerGeneration &&
        (isCurrent?.call() ?? true);
    if (search.isEmpty || !current()) return const [];
    await _upgradeSearchCatalogs(underOther ?? _genre[type] == otherGenre);
    if (!current()) return const [];
    final groups = <String, List<(ArchiveSource, ArchiveCatalog)>>{};
    for (final sc in _catalogs(type,
        filtered: false, underOther: underOther, includeSearchOnly: true)) {
      final s = sc.$1;
      groups
          .putIfAbsent(
              s.streamOnly ? s.catalogBaseUrl : s.manifestUrl, () => [])
          .add(sc);
    }
    final results = <String, ArchiveRow>{};
    final entries = groups.entries.toList();
    for (final entry in entries) {
      final source = entry.value.first.$1;
      onStatus?.call(source.key, source.name, ArchiveSourceStatus.loading);
    }
    Future<void> find(
        MapEntry<String, List<(ArchiveSource, ArchiveCatalog)>> entry) async {
      final group = entry.value;
      final found = <ArchiveMeta>[], providerMatches = <ArchiveMeta>[];
      var failed = false, succeeded = false;
      final (source, catalog) =
          group.firstWhere((sc) => sc.$2.searchable, orElse: () => group.first);
      final names = [
        if (source.streamOnly)
          for (final s in enabledSources)
            if (s.streamOnly && s.catalogBaseUrl == source.catalogBaseUrl)
              s.name
      ];
      void publish() {
        if (!current()) return;
        final items = rankSearch(q, found);
        final seen = {for (final m in items) m.id};
        items.addAll(providerMatches.where((m) => seen.add(m.id)));
        if (items.isNotEmpty) {
          results[entry.key] = ArchiveRow(
              source: source,
              catalog: catalog,
              items: items,
              searchQuery: q,
              sourceLabel: names.length > 1 ? names.join(' · ') : null);
          onRows?.call([
            for (final key in groups.keys)
              if (results[key] case final row?) row
          ]);
        }
      }

      // Make cached matches useful before the first network response.
      for (final (s, c) in group) {
        if (!current()) return;
        if (!c.searchOnly) {
          final key = _rowKey(s, c);
          try {
            _items[key] ??= await _cache.read(s.key, c);
          } catch (_) {}
          found.addAll(_items[key] ?? const []);
        }
      }
      publish();
      for (final (s, c) in group) {
        if (!current()) return;
        if (!c.searchable) continue;
        final variants = search.remoteQueries(q);
        final replies = await Future.wait([
          for (final variant in variants)
            (() async {
              if (!current()) return <ArchiveMeta>[];
              try {
                final items = await _page(s, c, search: variant.text);
                succeeded = true;
                return variant.broad
                    ? items.where((m) => search.matches(m.name)).toList()
                    : items;
              } catch (_) {
                failed = true;
                return <ArchiveMeta>[];
              }
            })()
        ]);
        if (!current()) return;
        for (var i = 0; i < replies.length; i++) {
          found.addAll(replies[i]);
          if (!variants[i].broad) providerMatches.addAll(replies[i]);
        }
        publish();
      }
      if (current()) {
        onStatus?.call(
            source.key,
            names.length > 1 ? names.join(' · ') : source.name,
            results.containsKey(entry.key)
                ? ArchiveSourceStatus.ready
                : failed && !succeeded
                    ? ArchiveSourceStatus.failed
                    : ArchiveSourceStatus.empty);
      }
    }

    Future<void> worker() async {
      while (entries.isNotEmpty && current()) {
        await find(entries.removeAt(0));
      }
    }

    await Future.wait([worker(), worker(), worker()]);
    return current()
        ? [
            for (final key in groups.keys)
              if (results[key] case final row?) row
          ]
        : const [];
  }

  void clearSearch(ArchiveType type) {
    _focusedSearchRows.remove(type);
    _searchGeneration[type] = (_searchGeneration[type] ?? 0) + 1;
    _searchingTypes.remove(type);
    _searchStates.remove(type);
    _searchNames.remove(type);
    _selectedSearchSource.remove(type);
    if (_search.remove(type) != null) _notify();
  }

  bool canSearch(ArchiveType type) =>
      _catalogs(type, includeSearchOnly: true).isNotEmpty;

  // ---- recent searches ----------------------------------------------------

  static const _recentSearchMax = 8;

  Map<String, dynamic> _recentSearchMap() {
    try {
      final raw = _storage.getArchiveRecentSearchesJson();
      return raw == null
          ? {}
          : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  /// The last searches of [type], newest first (each category its own).
  List<String> recentSearches(ArchiveType type) => [
        for (final q in (_recentSearchMap()[type.wire] as List? ?? const []))
          '$q',
      ];

  Future<void> _rememberSearch(ArchiveType type, String query) async {
    final lower = query.toLowerCase();
    final list = [
      query,
      ...recentSearches(type).where((q) => q.toLowerCase() != lower),
    ].take(_recentSearchMax).toList();
    await _storage.setArchiveRecentSearchesJson(
        jsonEncode({..._recentSearchMap(), type.wire: list}));
  }

  Future<void> forgetRecentSearches(ArchiveType type) async {
    await _storage.setArchiveRecentSearchesJson(
        jsonEncode({..._recentSearchMap()}..remove(type.wire)));
    _notify();
  }

  // ---- favourites ---------------------------------------------------------

  /// Titles kept in Favourites (both categories together).
  static const _favoritesMax = 200;

  List<Map<String, dynamic>> _favoriteEntries() =>
      _decodeEntries(_storage.getArchiveFavoritesJson());

  String _titleIdentity(ArchiveSource source, ArchiveMeta meta) =>
      _storage.archiveMappedIdentity(
          'archive::arc_title_identity_${archiveTitleIdentity(source, meta)}');

  bool _sameTitle(
      Map<String, dynamic> e, ArchiveSource source, ArchiveMeta meta) {
    final raw = e['meta'];
    final old = raw is Map
        ? ArchiveMeta.fromJson(Map<String, dynamic>.from(raw))
        : null;
    if (old == null) return false;
    final oldSource = ArchiveSource(manifestUrl: '${e['src']}', name: '');
    if (e['src'] == source.manifestUrl &&
        old.id == meta.id &&
        old.wire == meta.wire) {
      return true;
    }
    if (source.server != null && meta.imdb == null) return false;
    return _titleIdentity(oldSource, old) == _titleIdentity(source, meta);
  }

  // [isFavorite] runs for every poster on every build (global search with
  // hundreds of Media Hub results): decoding the saved list per call made
  // typing in Search crawl, so the decoded list is indexed once per change.
  String? _favIndexRaw;
  int _favIndexRevision = -1, _favIndexViewer = -1;
  Set<String> _favExact = const {}, _favIdentities = const {};

  static String _exactFavKey(String src, ArchiveMeta meta) =>
      '$src|${meta.id}|${meta.wire}';

  void _ensureFavoriteIndex() {
    final raw = _storage.getArchiveFavoritesJson();
    final revision = _storage.archiveIdentityRevision;
    final viewer = _storage.viewerGeneration;
    if (raw == _favIndexRaw &&
        revision == _favIndexRevision &&
        viewer == _favIndexViewer) {
      return;
    }
    final exact = <String>{}, identities = <String>{};
    for (final e in _decodeEntries(raw)) {
      final m = e['meta'];
      final old =
          m is Map ? ArchiveMeta.fromJson(Map<String, dynamic>.from(m)) : null;
      if (old == null) continue;
      final src = '${e['src']}';
      exact.add(_exactFavKey(src, old));
      identities
          .add(_titleIdentity(ArchiveSource(manifestUrl: src, name: ''), old));
    }
    _favIndexRaw = raw;
    _favIndexRevision = revision;
    _favIndexViewer = viewer;
    _favExact = exact;
    _favIdentities = identities;
  }

  /// Same answer as `_favoriteEntries().any(_sameTitle)`, from the index.
  bool isFavorite(ArchiveSource source, ArchiveMeta meta) {
    _ensureFavoriteIndex();
    if (_favExact.contains(_exactFavKey(source.manifestUrl, meta))) {
      return true;
    }
    if (source.server != null && meta.imdb == null) return false;
    return _favIdentities.contains(_titleIdentity(source, meta));
  }

  /// Hold OK on a title: into Favourites (front of the row), or out again.
  /// Returns true when it is now a favourite.
  Future<bool> toggleFavorite(ArchiveSource source, ArchiveMeta meta) async {
    registerIdentity(source, meta);
    final entries = _favoriteEntries();
    final had = entries.any((e) => _sameTitle(e, source, meta));
    final next = had
        ? entries.where((e) => !_sameTitle(e, source, meta)).toList()
        : [
            {'src': source.manifestUrl, 'meta': meta.toJson()},
            ...entries,
          ].take(_favoritesMax).toList();
    await _storage
        .setArchiveFavoritesJson(next.isEmpty ? null : jsonEncode(next));
    _notify();
    return !had;
  }

  // ---- watched history ----------------------------------------------------

  /// Titles kept in the history (both categories together).
  static const _historyMax = 40;

  String? _historyRaw;
  List<Map<String, dynamic>> _decodedHistory = [];
  final Expando<ArchiveMeta> _historyMetas = Expando();
  List<Map<String, dynamic>> _historyEntries() {
    final raw = _storage.getArchiveHistoryJson();
    if (raw != _historyRaw) {
      _historyRaw = raw;
      _decodedHistory = _decodeEntries(raw);
    }
    return List.of(_decodedHistory);
  }

  ArchiveMeta? _historyMeta(Map entry) {
    final raw = entry['meta'];
    if (raw is! Map) return null;
    return _historyMetas[raw] ??=
        ArchiveMeta.fromJson(Map<String, dynamic>.from(raw));
  }

  static List<Map<String, dynamic>> _decodeEntries(String? raw) {
    try {
      if (raw == null) return [];
      return [
        for (final e in jsonDecode(raw) as List)
          if (e is Map) Map<String, dynamic>.from(e),
      ];
    } catch (_) {
      return [];
    }
  }

  /// Called when a title (a movie, or a show's episode) starts playing: it
  /// moves to the front of its category's "Recently watched" row.
  Future<void> recordWatched(ArchiveSource source, ArchiveMeta meta,
      {ArchiveVideo? episode}) async {
    registerIdentity(source, meta, episode: episode);
    final entries = [
      {
        'src': source.manifestUrl,
        'meta': meta.toJson(includeVideos: true),
        'detailAt': DateTime.now().toIso8601String(),
        if (episode != null) 'lastVideo': episode.toJson()
      },
      ..._historyEntries().where((e) => !_sameTitle(e, source, meta)),
    ].take(_historyMax).toList();
    await _storage.setArchiveHistoryJson(jsonEncode(entries));
    _notify();
  }

  Future<void> removeFromHistory(ArchiveSource source, ArchiveMeta meta) async {
    final entries =
        _historyEntries().where((e) => !_sameTitle(e, source, meta)).toList();
    await _storage
        .setArchiveHistoryJson(entries.isEmpty ? null : jsonEncode(entries));
    _notify();
  }

  final Expando<Set<String>> _registeredMetas = Expando();
  void registerIdentity(ArchiveSource source, ArchiveMeta meta,
      {ArchiveVideo? episode}) {
    final identity = archiveTitleIdentity(source, meta);
    if (!identity.startsWith('${meta.type.wire}:')) return;
    // An episode the meta already lists is covered by the one whole-show
    // registration below: keyed per episode, opening a 418-episode show
    // rebuilt every alias 418 times (~175k ids) and froze the Formuler
    // (LOG-YV5NC3, 2026-11-02).
    final listed =
        episode == null || meta.videos.any((v) => v.id == episode.id);
    final scope = '${_storage.viewerGeneration}|${source.key}|'
        '${listed ? '' : episode.id}';
    final registered = _registeredMetas[meta] ??= <String>{};
    if (!registered.add(scope)) return;
    final tmdb = meta.wireType == null &&
            source.server == null &&
            meta.imdb != null &&
            RegExp(r'^tmdb:\d+$').hasMatch(meta.id)
        ? '${meta.type.wire}:${meta.id}'
        : null;
    final aliases = <String, String>{
      if (tmdb != null)
        '$playlistId::arc_title_identity_$tmdb':
            '$playlistId::arc_title_identity_$identity',
    };
    void alias(String id, bool episode, String suffix) {
      final canonical =
          '$playlistId::arc_${episode ? 'ep' : 'vod'}_identity_$identity$suffix';
      if (tmdb != null) {
        aliases['$playlistId::arc_${episode ? 'ep' : 'vod'}_identity_$tmdb$suffix'] =
            canonical;
      }
      aliases[channelId(source, id, episode: episode)] = canonical;
    }

    if (meta.type == ArchiveType.movie) {
      alias(meta.id, false, '');
    } else {
      for (final v in [...meta.videos, if (!listed) episode]) {
        alias(v.id, true, ':${v.season}:${v.episode}');
      }
    }
    unawaited(
        _storage.registerArchiveIdentities(aliases).catchError((Object error) {
      registered.remove(scope);
      debugPrint('ArchiveIdentity: failed=${error.runtimeType}');
    }));
  }

  List<ArchiveContinueItem> continueWatching(ArchiveType type,
      {bool upcoming = false, DateTime? now}) {
    final byUrl = {for (final s in enabledSources) s.manifestUrl: s};
    final seen = <String>{};
    final result = <ArchiveContinueItem>[];
    for (final entry in _historyEntries()) {
      final source = byUrl[entry['src']];
      final raw = entry['meta'];
      if (source == null || source.underOther || raw is! Map) continue;
      final meta = _historyMeta(entry);
      if (meta == null ||
          meta.type != type ||
          !seen.add(_titleIdentity(source, meta))) {
        continue;
      }
      registerIdentity(source, meta);
      if (type == ArchiveType.movie) {
        final id = channelId(source, meta.id, episode: false);
        if (!upcoming && !_storage.isFullyWatched(id)) {
          result.add(ArchiveContinueItem(
              source: source,
              meta: meta,
              resume: _storage.getLastPosition(id) > 0,
              progress: _storage.getWatchedFraction(id)));
        }
        continue;
      }
      final videos =
          meta.videos.where((v) => v.season > 0 && v.episode > 0).toList();
      if (videos.isEmpty) {
        if (!upcoming) {
          result.add(ArchiveContinueItem(source: source, meta: meta));
        }
        continue;
      }
      int position(ArchiveVideo v) =>
          _storage.getLastPosition(channelId(source, v.id, episode: true));
      bool finished(ArchiveVideo v) =>
          _storage.isFullyWatched(channelId(source, v.id, episode: true));
      final last = entry['lastVideo'] is Map
          ? ArchiveVideo.fromJson(Map<String, dynamic>.from(entry['lastVideo']))
          : null;
      ArchiveVideo? chosen;
      if (last != null) {
        chosen =
            videos.where((v) => v.id == last.id && !finished(v)).firstOrNull;
      }
      chosen ??=
          videos.where((v) => position(v) > 0 && !finished(v)).lastOrNull;
      final lastFinished = videos.lastIndexWhere(finished);
      chosen ??=
          videos.skip(lastFinished + 1).where((v) => !finished(v)).firstOrNull;
      if (chosen == null) continue;
      final date = DateTime.tryParse(chosen.released ?? '');
      final future = date != null && date.isAfter(now ?? DateTime.now());
      if (future != upcoming) continue;
      final id = channelId(source, chosen.id, episode: true);
      result.add(ArchiveContinueItem(
          source: source,
          meta: meta,
          episode: chosen,
          resume: position(chosen) > 0,
          progress: _storage.getWatchedFraction(id),
          upcoming: future));
    }
    return result;
  }

  final Set<String> _historyHydrated = {};
  Future<void> refreshHistoryDetails({VoidCallback? onProgress}) async {
    final generation = _storage.viewerGeneration;
    final byUrl = {for (final s in enabledSources) s.manifestUrl: s};
    final pending = _historyEntries()
        .where((e) =>
            e['meta'] is Map &&
            e['meta']['type'] == 'series' &&
            byUrl.containsKey(e['src']))
        .toList();
    Future<void> worker() async {
      while (pending.isNotEmpty &&
          generation == _storage.viewerGeneration &&
          !_disposed) {
        final entry = pending.removeAt(0);
        final source = byUrl[entry['src']]!;
        final preview =
            ArchiveMeta.fromJson(Map<String, dynamic>.from(entry['meta']));
        if (preview == null) continue;
        final key = '$generation|${source.key}|${preview.id}';
        if (!_historyHydrated.add(key)) continue;
        final at = DateTime.tryParse('${entry['detailAt'] ?? ''}');
        if (preview.videos.isNotEmpty &&
            at != null &&
            DateTime.now().difference(at) < const Duration(hours: 12)) {
          continue;
        }
        try {
          final full = await meta(source, preview);
          if (generation != _storage.viewerGeneration || _disposed) return;
          if (full == null || full.videos.isEmpty) continue;
          final current = _historyEntries();
          final index =
              current.indexWhere((e) => _sameTitle(e, source, preview));
          if (index < 0 || current[index]['src'] != source.manifestUrl) {
            continue;
          }
          current[index] = {
            ...current[index],
            'meta': full.toJson(includeVideos: true),
            'detailAt': DateTime.now().toIso8601String()
          };
          registerIdentity(source, full);
          await _storage.setArchiveHistoryJson(jsonEncode(current));
          _notify();
          onProgress?.call();
        } catch (_) {/* Existing local progress stays usable offline. */}
      }
    }

    await Future.wait([worker(), worker()]);
  }

  ArchiveRow? _continueRow(ArchiveType type, {bool upcoming = false}) {
    final items = continueWatching(type, upcoming: upcoming);
    if (items.isEmpty) return null;
    return ArchiveRow(
        source: items.first.source,
        catalog: ArchiveCatalog(
            type: type,
            id: upcoming ? 'upcoming' : 'continue',
            name: upcoming ? 'Upcoming episodes' : 'Continue watching'),
        items: [for (final item in items) item.meta],
        itemSources: [for (final item in items) item.source],
        continuations: items,
        upcoming: upcoming);
  }

  /// Every played title (movies and shows), newest first, whose source is
  /// still enabled and not under Other — the Home page's Continue watching.
  List<({ArchiveSource source, ArchiveMeta meta})> recentlyWatched() {
    final byUrl = {for (final s in enabledSources) s.manifestUrl: s};
    return [
      for (final e in _historyEntries())
        if (byUrl[e['src']] case final source? when !source.underOther)
          if (e['meta'] case final Map m)
            if (ArchiveMeta.fromJson(Map<String, dynamic>.from(m))
                case final meta?)
              (source: source, meta: meta),
    ];
  }

  /// "Recently watched" for [type]: played titles whose source is still
  /// enabled, newest first. Not narrowed by the genre filter.
  ArchiveRow? _historyRow(ArchiveType type) => _savedRow(
      type,
      _historyEntries(),
      ArchiveCatalog(type: type, id: 'history', name: 'Recently watched'));

  /// "Favourites" for [type], newest first — like [_historyRow].
  ArchiveRow? _favoritesRow(ArchiveType type) => _savedRow(
      type,
      _favoriteEntries(),
      ArchiveCatalog(type: type, id: 'favorites', name: 'Favourites'),
      favorites: true);

  ArchiveRow? _savedRow(ArchiveType type, List<Map<String, dynamic>> entries,
      ArchiveCatalog catalog,
      {bool favorites = false}) {
    final byUrl = {for (final s in enabledSources) s.manifestUrl: s};
    final items = <ArchiveMeta>[];
    final sources = <ArchiveSource>[];
    final seen = <String>{};
    for (final e in entries) {
      final source = byUrl[e['src']];
      final m = e['meta'];
      if (source == null || m is! Map) continue;
      final meta = ArchiveMeta.fromJson(Map<String, dynamic>.from(m));
      if (meta == null ||
          meta.type != type ||
          !seen.add(_titleIdentity(source, meta))) {
        continue;
      }
      // An Other source's titles only under the Other filter, like its rows.
      if (source.underOther != (_genre[type] == otherGenre)) continue;
      items.add(meta);
      sources.add(source);
    }
    if (items.isEmpty) return null;
    return ArchiveRow(
      source: sources.first,
      catalog: catalog,
      items: items,
      itemSources: sources,
      isFavorites: favorites,
    );
  }

  /// Direct title matches, ignoring separators/accents and allowing all
  /// query words in any order. Title prefixes first, then substrings, then
  /// separate word matches, retaining source relevance within each rank.
  static List<ArchiveMeta> rankSearch(
      String query, Iterable<ArchiveMeta> items) {
    final search = TitleSearch(query);
    if (search.isEmpty) return [];
    final ranked = <int, List<ArchiveMeta>>{};
    final seen = <String>{};
    for (final m in items) {
      final rank = search.rank(m.name);
      if (rank != null && seen.add(m.id)) {
        ranked.putIfAbsent(rank, () => []).add(m);
      }
    }
    return [for (var rank = 0; rank <= 3; rank++) ...?ranked[rank]];
  }

  /// Rows of [type] from every enabled source, in source then manifest
  /// order. Rows not loaded yet (or empty) are left out, and so is a
  /// provider row an earlier stream-only source already shows (Play still
  /// asks every stream-only source — see [resolve]).
  Map<String, dynamic> get rowPreferences {
    try {
      return Map<String, dynamic>.from(
          jsonDecode(_storage.getArchiveOptionsJson('rows') ?? '{}') as Map);
    } catch (_) {
      return {};
    }
  }

  bool rowHidden(String key) =>
      (rowPreferences['hidden'] as List? ?? const []).contains(key);
  bool rowPinned(String key) =>
      (rowPreferences['pinned'] as List? ?? const []).contains(key);
  Future<void> setRowFlag(String key, String flag, bool value) async {
    final prefs = rowPreferences;
    final values = Set<String>.from(prefs[flag] as List? ?? const []);
    value ? values.add(key) : values.remove(key);
    prefs[flag] = values.toList();
    await _storage.setArchiveOptionsJson('rows', jsonEncode(prefs));
    _notify();
  }

  Future<void> renameRow(String key, String title) async {
    final prefs = rowPreferences;
    final titles =
        Map<String, dynamic>.from(prefs['titles'] as Map? ?? const {});
    title.trim().isEmpty ? titles.remove(key) : titles[key] = title.trim();
    prefs['titles'] = titles;
    await _storage.setArchiveOptionsJson('rows', jsonEncode(prefs));
    _notify();
  }

  Future<void> moveRow(ArchiveType type, String key, int direction) async {
    final all = rows(type, includeHidden: true)
        .where((r) => !r.isSearch && r.continuations == null)
        .map((r) => r.key)
        .toList();
    final index = all.indexOf(key), target = all.indexOf(key) + direction;
    if (index < 0 || target < 0 || target >= all.length) return;
    all.insert(target, all.removeAt(index));
    final prefs = rowPreferences;
    final previous = List<String>.from(prefs['order'] as List? ?? const []);
    prefs['order'] = [...all, ...previous.where((k) => !all.contains(k))];
    await _storage.setArchiveOptionsJson('rows', jsonEncode(prefs));
    _notify();
  }

  List<ArchiveRow> rows(ArchiveType type, {bool includeHidden = false}) {
    _ensureViewerState();
    final prefs = rowPreferences;
    final titles = prefs['titles'] as Map? ?? const {};
    final hidden = prefs['hidden'] as List? ?? const [];
    final pinned = prefs['pinned'] as List? ?? const [];
    final order = prefs['order'] as List? ?? const [];
    final rawRows = <ArchiveRow>[
      for (final row in _search[type]?.$2 ?? const <ArchiveRow>[])
        if (_selectedSearchSource[type] == null ||
            row.source.key == _selectedSearchSource[type])
          row,
      if (_continueRow(type) case final resume?) resume,
      if (_continueRow(type, upcoming: true) case final upcoming?) upcoming,
      if (_favoritesRow(type) case final favorites?) favorites,
      if (_historyRow(type) case final history?) history,
      for (final (s, c) in _catalogs(type))
        if (_items[_rowKey(s, c)] case final raw? when raw.isNotEmpty)
          if (_inGenre(type, raw) case final items when items.isNotEmpty)
            ArchiveRow(source: s, catalog: c, items: items),
    ];
    final indexed = {
      for (var i = 0; i < rawRows.length; i++) rawRows[i].key: i
    };
    int group(ArchiveRow r) => r.isSearch
        ? 0
        : r.continuations != null
            ? 1
            : pinned.contains(r.key)
                ? 2
                : 3;
    int rank(ArchiveRow r) => order.contains(r.key)
        ? order.indexOf(r.key)
        : order.length + indexed[r.key]!;
    rawRows.sort((a, b) {
      final g = group(a).compareTo(group(b));
      return g != 0 ? g : rank(a).compareTo(rank(b));
    });
    return [
      for (final row in rawRows)
        if (includeHidden || !hidden.contains(row.key))
          ArchiveRow(
              source: row.source,
              catalog: row.catalog,
              items: row.items,
              searchQuery: row.searchQuery,
              itemSources: row.itemSources,
              isFavorites: row.isFavorites,
              sourceLabel: row.sourceLabel,
              continuations: row.continuations,
              upcoming: row.upcoming,
              customTitle:
                  titles[row.key] is String ? titles[row.key] : row.customTitle)
    ];
  }

  final Set<String> _loadingMore = {};
  final Set<String> _exhausted = {};

  /// Appends [row]'s next page (called as focus nears its end), so a row
  /// keeps scrolling past the pages [refresh] fetched. Not cached: a
  /// refresh starts the row over.
  Future<void> loadMore(ArchiveRow row) async {
    final key = row.key;
    if (row.isSearch ||
        row.itemSources != null ||
        _exhausted.contains(key) ||
        !_loadingMore.add(key)) {
      return;
    }
    try {
      final have = _items[key] ?? const <ArchiveMeta>[];
      final batch = await _page(row.source, row.catalog, skip: have.length);
      final seen = {for (final m in have) m.id};
      final fresh = batch.where((m) => seen.add(m.id)).toList();
      if (fresh.isEmpty) {
        _exhausted.add(key);
      } else {
        _items[key] = [...have, ...fresh];
        _notify();
      }
    } catch (e) {
      debugPrint('ArchiveService: more of $key failed: $e');
    } finally {
      _loadingMore.remove(key);
    }
  }

  bool hasAny(ArchiveType type) =>
      enabledSources.any(
          (s) => _showCatalogs(s) && s.catalogs.any((c) => c.type == type)) ||
      _favoritesRow(type) != null ||
      _historyRow(type) != null;

  /// Call when the Archive tab opens: draws the cached rows at once, then
  /// refreshes stale catalogs behind them.
  Future<void> open() async {
    unawaited(refreshHistoryDetails());
    if (!_loadedFromCache) {
      _loadedFromCache = true;
      await _recheckCustomSources();
      for (final type in ArchiveType.values) {
        for (final (s, c) in _catalogs(type)) {
          try {
            _items[_rowKey(s, c)] = await _cache.read(s.key, c);
          } catch (e) {
            debugPrint('ArchiveService: cache read failed: ${e.runtimeType}');
          }
        }
      }
      _notify();
    }
    unawaited(refresh());
  }

  /// Refetches catalogs older than [_staleAfter] (all of them with
  /// [force]). A failing source keeps its cached rows. [manifests] (the
  /// Refresh button) re-reads every add-on's manifest first.
  final List<String> _visibleRows = [];
  void prioritizeRow(ArchiveRow row) {
    _visibleRows.remove(row.key);
    _visibleRows.insert(0, row.key);
    if (_visibleRows.length > 4) _visibleRows.removeLast();
  }

  int _refreshGeneration = 0;
  Future<void> refresh({bool force = false, bool manifests = false}) async {
    if (_refreshing) {
      _refreshAgain = true;
      _forceRefreshAgain |= force;
      return;
    }
    _refreshing = true;
    final viewer = _storage.viewerGeneration;
    final generation = ++_refreshGeneration;
    bool current() =>
        !_disposed &&
        viewer == _storage.viewerGeneration &&
        generation == _refreshGeneration;
    lastError = null;
    _notify();
    try {
      if (force) await _recheckCustomSources(all: manifests);
      final config = _storage.getArchiveSourcesJson();
      final pending = [
        for (final type in ArchiveType.values) ..._catalogs(type)
      ];
      Future<void> worker() async {
        while (pending.isNotEmpty &&
            current() &&
            config == _storage.getArchiveSourcesJson()) {
          final priority = pending
              .indexWhere((sc) => _visibleRows.contains(_rowKey(sc.$1, sc.$2)));
          final (source, catalog) =
              pending.removeAt(priority < 0 ? 0 : priority);
          final key = _rowKey(source, catalog);
          if (!force) {
            final at = await _cache.fetchedAt(source.key, catalog);
            if (at != null &&
                DateTime.now().difference(at) < _staleAfter &&
                (_items[key]?.isNotEmpty ?? false)) {
              continue;
            }
          }
          try {
            final items = <ArchiveMeta>[];
            final seen = <String>{};
            for (var page = 0; page < _pagesPerCatalog && current(); page++) {
              final batch = await _page(source, catalog, skip: items.length);
              final fresh = batch.where((m) => seen.add(m.id)).toList();
              if (fresh.isEmpty) break;
              items.addAll(fresh);
              if (batch.length < 50) break;
            }
            if (!current() || config != _storage.getArchiveSourcesJson()) {
              return;
            }
            _items[key] = items;
            _exhausted.remove(key);
            await _cache.write(source.key, catalog, items);
            _notify();
          } catch (error) {
            if (current()) {
              lastError = '${source.name}: catalog unavailable';
              debugPrint(
                  'ArchiveRow: source=${source.key} failed=${error.runtimeType}');
            }
          }
        }
      }

      await Future.wait([worker(), worker(), worker()]);
    } finally {
      _refreshing = false;
      _notify();
    }
    if (_refreshAgain && !_disposed) {
      _refreshAgain = false;
      final forceAgain = _forceRefreshAgain;
      _forceRefreshAgain = false;
      await refresh(force: forceAgain);
    }
  }

  // ---- details + playback -------------------------------------------------

  static String _rawId(ArchiveSource source, String videoId,
          {required bool episode}) =>
      'arc_${episode ? 'ep' : 'vod'}_${source.key}_$videoId';

  /// The [Channel.id] [channelFor] gives a title — known before resolving, so
  /// detail pages can show saved progress (StorageService positions).
  static String channelId(ArchiveSource source, String videoId,
          {required bool episode}) =>
      '$playlistId::${_rawId(source, videoId, episode: episode)}';

  Future<ArchiveMeta?> meta(ArchiveSource source, ArchiveMeta preview) async {
    final viewer = _storage.viewerGeneration;
    ArchiveMeta? full;
    try {
      full = source.tracker != null || source.listOnly
          ? await _api.fetchMeta(
              ArchiveCatalogProvider.baseUrl, preview.type, preview.id)
          : source.server != null
              ? await _servers.fetchMeta(source, preview)
              : await _api.fetchMeta(
                  source.catalogBaseUrl, preview.type, preview.id,
                  wire: preview.wire);
    } catch (_) {
      if (source.server != null ||
          preview.wireType != null ||
          preview.imdb == null) {
        rethrow;
      }
    }
    if (full == null &&
        source.server == null &&
        preview.wireType == null &&
        preview.imdb != null) {
      full = await _api.fetchMeta(
          ArchiveCatalogProvider.baseUrl, preview.type, preview.imdb!);
    }
    if (_storage.viewerGeneration != viewer || _disposed) return null;
    if (full != null) {
      if (preview.wireType == null && full.imdb != null) {
        final mappedPreview = ArchiveMeta.fromJson(
            {...preview.toJson(includeVideos: true), 'imdb_id': full.imdb});
        if (mappedPreview != null) registerIdentity(source, mappedPreview);
      }
      registerIdentity(source, full);
    }
    return full;
  }

  /// Check the selected recommendation against server libraries, including
  /// titles beyond the already-loaded catalog pages. No background library scan.
  Future<({ArchiveSource source, ArchiveMeta meta})?> findServerTitle(
      ArchiveMeta target) async {
    final viewer = _storage.viewerGeneration;
    final pending = [
      for (final source in enabledSources)
        if (source.server != null && !source.underOther)
          for (final catalog in source.catalogs)
            if (catalog.type == target.type) (source, catalog)
    ];
    final matches = <({ArchiveSource source, ArchiveMeta meta})>[];
    Future<void> worker() async {
      while (pending.isNotEmpty &&
          viewer == _storage.viewerGeneration &&
          !_disposed) {
        final (source, catalog) = pending.removeAt(0);
        try {
          final items = await _page(source, catalog, search: target.name);
          if (viewer != _storage.viewerGeneration || _disposed) return;
          final found = _matchingServerTitle(target, items);
          if (found != null) matches.add((source: source, meta: found));
        } catch (_) {/* A disconnected server leaves other sources usable. */}
      }
    }

    await Future.wait([worker(), worker(), worker()]);
    return viewer == _storage.viewerGeneration ? matches.firstOrNull : null;
  }

  static ArchiveMeta? _matchingServerTitle(
      ArchiveMeta target, Iterable<ArchiveMeta> items) {
    final candidates = items.where((m) => m.type == target.type).toList();
    final exact = candidates
        .where((m) => target.imdb != null && m.imdb == target.imdb)
        .firstOrNull;
    if (exact != null) return exact;
    final named = candidates
        .where((m) =>
            // Never substitute another known film with the same title/year.
            (target.imdb == null || m.imdb == null) &&
            TitleSearch.key(m.name) == TitleSearch.key(target.name) &&
            target.year != null &&
            m.year == target.year)
        .toList();
    return named.length == 1 ? named.single : null;
  }

  /// Tracker/public catalog ids are not server item ids. Resolve only the
  /// selected title, independently of how far the viewer has browsed a row.
  /// These requests stay inside the stream session's three-worker budget.
  Future<List<ArchiveStream>> _serverTitleStreams(
      ArchiveSource source,
      ArchiveMeta target,
      ArchiveVideo? episode,
      bool Function() current) async {
    if (target.type == ArchiveType.series && episode == null) return const [];
    final candidates = <String, ArchiveMeta>{};
    for (final catalog in source.catalogs) {
      if (!current()) return const [];
      if (catalog.type != target.type) continue;
      var skip = 0;
      final seen = <String>{};
      while (current()) {
        final items =
            await _page(source, catalog, skip: skip, search: target.name);
        if (!current()) return const [];
        final fresh = items.where((m) => seen.add(m.id)).toList();
        if (fresh.isEmpty) break; // Also stops servers ignoring pagination.
        for (final item in fresh) {
          if (item.type == target.type) candidates[item.id] = item;
        }
        if (target.imdb != null &&
            fresh.any((m) => m.type == target.type && m.imdb == target.imdb)) {
          break;
        }
        if (items.length < MediaServerApi.catalogPageSize) break;
        skip += items.length;
      }
      // A known identity can finish as soon as its library responds. Legacy
      // title/year fallback waits for all libraries to rule out ambiguity.
      if (target.imdb != null &&
          candidates.values.any((m) => m.imdb == target.imdb)) {
        break;
      }
    }
    final match = _matchingServerTitle(target, candidates.values);
    if (match == null || !current()) return const [];
    var id = match.id;
    if (episode != null) {
      final full = await _servers.fetchMeta(source, match);
      if (!current()) return const [];
      final matches = full?.videos
              .where((v) =>
                  v.season == episode.season && v.episode == episode.episode)
              .toList() ??
          const <ArchiveVideo>[];
      if (matches.length != 1) return const [];
      id = matches.single.id;
    }
    if (!current()) return const [];
    return _servers.streams(source, id);
  }

  /// The sources asked for a title's streams: [source] itself, then — for
  /// a title from the public provider — every other enabled stream-only
  /// source on the same provider, since they share the same IMDB ids.
  List<ArchiveSource> _streamSources(ArchiveSource source) => [
        // A tracker list or list-only add-on has no streams: every
        // stream-only add-on is asked, like for the provider's own rows
        // (same IMDb ids).
        if (source.tracker != null || source.listOnly)
          for (final s in enabledSources)
            if (s.streamOnly) s,
        if (source.tracker == null && !source.listOnly) source,
        if (source.streamOnly)
          for (final s in enabledSources)
            if (s.streamOnly &&
                s.manifestUrl != source.manifestUrl &&
                s.catalogBaseUrl == source.catalogBaseUrl)
              s,
      ];

  /// Every direct http(s) stream for [meta] (a movie) or one of its
  /// [episode]s, in source then server order — the detail page plays a
  /// single one at once and lets the user pick when there are several
  /// (quality, language…). Each source is asked at its own `/stream/` with
  /// the title's id (`tt…`, or `tt…:{season}:{episode}` for a provider
  /// episode); a failing source is skipped, and its error rethrown only
  /// when no source answered with anything.
  final Map<String, ArchiveStreamSession> _streamSessions = {};
  bool _disposed = false;

  String _streamConfiguration() => jsonEncode([
        for (final source in enabledSources)
          if (source.tracker == null && !source.listOnly)
            [
              source.manifestUrl,
              source.name,
              source.streamOnly,
              source.catalogBaseUrl,
              source.imdbResources,
              source.server?.toJson(),
              if (source.server != null)
                [
                  for (final catalog in source.catalogs)
                    [catalog.id, catalog.wire]
                ],
            ],
      ]);

  /// Bounded parallel metadata requests, scoped to the viewer and configuration.
  ArchiveStreamSession searchStreams(ArchiveSource source, ArchiveMeta meta,
      {ArchiveVideo? episode, bool force = false}) {
    final viewer = _storage.viewerGeneration;
    final config = _streamConfiguration();
    final videoId = episode?.id ?? meta.id;
    final key = '$viewer|${source.key}|${meta.wire}|$videoId|$config';
    for (final entry in _streamSessions.entries.toList()) {
      final session = entry.value;
      if (!session.active ||
          (session.completedAt != null &&
              DateTime.now().difference(session.completedAt!) >
                  const Duration(minutes: 2))) {
        _streamSessions.remove(entry.key);
        session.dispose();
      }
    }
    final cached = _streamSessions[key];
    if (!force && cached != null) return cached;
    if (cached != null) {
      _streamSessions.remove(key);
      cached.dispose();
    }
    final session = ArchiveStreamSession(
        isCurrent: () =>
            !_disposed &&
            _storage.viewerGeneration == viewer &&
            _streamConfiguration() == config);
    _streamSessions[key] = session;
    while (_streamSessions.length > 12) {
      final oldest = _streamSessions.keys.first;
      _streamSessions.remove(oldest)?.dispose();
    }
    final imdbId = _imdbVideoId(source, meta, episode);
    final targets = <String, (ArchiveSource, String)>{
      for (final s in _streamSources(source)) s.key: (s, videoId),
    };
    final imdb = meta.wireType == null ? meta.imdb : null;
    if (imdb != null) {
      final id =
          episode == null ? imdb : '$imdb:${episode.season}:${episode.episode}';
      for (final s in enabledSources) {
        if (source.server == null &&
            s.server != null &&
            !s.underOther &&
            s.catalogs.any((c) => c.type == meta.type)) {
          targets[s.key] = (s, id);
        }
        if (!targets.containsKey(s.key) &&
            s.server == null &&
            s.tracker == null &&
            !s.listOnly &&
            (s.streamOnly || s.supportsImdb('stream', meta.type.wire))) {
          targets[s.key] = (s, id);
        }
      }
    }
    for (final entry in targets.entries) {
      session.addSource(entry.key, entry.value.$1.name);
    }
    Future<void> ask(String key) async {
      if (!session.active) return;
      final (s, id) = targets[key]!;
      final watch = Stopwatch()..start();
      try {
        Future<List<ArchiveStream>> fetch(String id) async => s.server != null
            ? source.server == null
                ? await _serverTitleStreams(
                    s, meta, episode, () => session.active)
                : await _servers.streams(s, id)
            : await _api.fetchStreams(s.baseUrl, meta.type, id,
                wire: meta.wire);
        var streams = await fetch(id);
        if (streams.isEmpty &&
            imdbId != null &&
            s.manifestUrl == source.manifestUrl &&
            id != imdbId) {
          streams = await fetch(imdbId);
        }
        if (s.server != null) {
          debugPrint(
              'ArchiveStreams: source=${s.key} kind=${s.server!.kind.name} '
              'ref=${ArchiveApiService.diagnosticReference(videoId)} '
              'items=${streams.length} fetchMs=${watch.elapsedMilliseconds}');
        }
        session.finish(key, [
          for (final stream in streams)
            ArchiveStreamOption(source: s, stream: stream)
        ]);
      } catch (e) {
        debugPrint('ArchiveStreams: source=${s.key} failed=${e.runtimeType}');
        session.finish(key, const [], failed: true);
      }
    }

    final pending = targets.keys.toList();
    // Reserve an initial worker for a connected server, so three slow addons
    // cannot hide a fast local Plex result behind their network timeouts.
    final serverIndex =
        pending.indexWhere((key) => targets[key]!.$1.server != null);
    if (serverIndex > 0) pending.insert(0, pending.removeAt(serverIndex));
    var running = 0;
    Future<void> worker() async {
      running++;
      try {
        while (pending.isNotEmpty && session.active) {
          await ask(pending.removeAt(0));
        }
      } finally {
        running--;
      }
    }

    session.retrySource = (key) async {
      if (!session.active ||
          !targets.containsKey(key) ||
          session.statuses[key] == ArchiveSourceStatus.loading) {
        return;
      }
      session.startRetry(key);
      pending.add(key);
      if (running < 3) unawaited(worker());
      await session.done;
    };
    if (pending.isEmpty) {
      session.finishEmpty();
    } else {
      for (var i = 0; i < 3 && pending.isNotEmpty; i++) {
        unawaited(worker());
      }
    }
    return session;
  }

  Future<List<ArchiveStreamOption>> streams(
      ArchiveSource source, ArchiveMeta meta,
      {ArchiveVideo? episode}) async {
    final session = searchStreams(source, meta, episode: episode);
    await session.done;
    return session.active ? session.options : const [];
  }

  static String? _imdbVideoId(
      ArchiveSource source, ArchiveMeta meta, ArchiveVideo? episode) {
    final imdb = meta.imdb;
    if (imdb == null ||
        meta.wireType != null ||
        source.streamOnly ||
        source.listOnly ||
        source.server != null ||
        source.tracker != null) {
      return null;
    }
    final id = episode?.id ?? meta.id;
    if (id.startsWith('tt')) return null;
    if (episode == null) return imdb;
    if (episode.season <= 0 && episode.episode <= 0) return null;
    return '$imdb:${episode.season}:${episode.episode}';
  }

  /// The [Channel] that plays [stream] for [meta] or its [episode]. Its id
  /// comes from [source] (the row the title was opened from), not from the
  /// stream picked, so progress is kept whichever stream plays.
  Channel channelFor(
    ArchiveSource source,
    ArchiveMeta meta,
    ArchiveStream stream, {
    ArchiveVideo? episode,
  }) {
    registerIdentity(source, meta, episode: episode);
    final videoId = episode?.id ?? meta.id;
    final rawId = _rawId(source, videoId, episode: episode != null);
    return Channel(
      id: '$playlistId::$rawId',
      rawId: rawId,
      playlistId: playlistId,
      name: episode == null
          ? meta.name
          : 'S${episode.season.toString().padLeft(2, '0')}'
              'E${episode.episode.toString().padLeft(2, '0')}'
              '${episode.title.isEmpty ? '' : ' - ${episode.title}'}',
      group: meta.name,
      url: stream.url,
      logoUrl: episode?.thumbnailUrl ?? meta.posterUrl,
      subtitleUrl: stream.subtitles.isEmpty ? stream.subtitleUrl : null,
      subtitles: stream.subtitles,
      httpHeaders: stream.requestHeaders,
      posterUrl: meta.posterUrl,
      backdropUrl: meta.backgroundUrl,
      seriesName: episode == null ? null : meta.name,
      seriesCoverUrl: episode == null ? null : meta.posterUrl,
      imdbId: meta.wireType == null ? meta.imdb : null,
    );
  }

  /// notifyListeners, deferred out of a build phase (see CLAUDE.md:
  /// never notify mid-build).
  @override
  void dispose() {
    _disposed = true;
    for (final session in _streamSessions.values) {
      session.dispose();
    }
    _streamSessions.clear();
    super.dispose();
  }

  void _notify() {
    if (_disposed) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }
}
