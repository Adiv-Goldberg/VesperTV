import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml_events.dart';

import '../models/epg_program.dart';
import '../utils/constants.dart';
import 'epg_database.dart';
import 'storage_service.dart';
import '../l10n/l10n.dart';

/// One playlist's EPG URL plus the channel ids it's allowed to populate
/// programmes for — see [EpgService.refresh]'s doc comment.
typedef EpgSource = ({String url, Set<String> knownChannelIds});

/// Every EPG channel id this service touches — a feed's own `<channel id>`,
/// a provider's `epg_channel_id`, a manual override, an M3U `tvg-id` — is
/// normalized through this before it's ever used as a map key or compared.
/// Two real providers were confirmed to disagree on casing for the exact
/// same channel (`espn.us` vs `ESPN.us`) despite XMLTV ids conventionally
/// being case-insensitive identifiers in practice; a plain exact-string
/// map lookup silently failed on that alone, with no error to show for
/// it — indistinguishable from "the feed just doesn't have this channel".
String normalizeEpgId(String id) => id.trim().toLowerCase();

EpgProgram _toProgram(EpgRow r) => EpgProgram(
      channelId: r.channelId,
      title: r.title,
      description: r.description,
      start: DateTime.fromMillisecondsSinceEpoch(r.startMs),
      stop: DateTime.fromMillisecondsSinceEpoch(r.stopMs),
    );

Map<String, List<EpgProgram>> _toPrograms(Map<String, List<EpgRow>> rows) =>
    rows.map((id, list) => MapEntry(id, _untangle(list)));

/// One channel's rows as a clean timeline. Some providers' XMLTV lists two
/// programmes for the same time slot (owner, 2026-10-16: RDS showed two
/// titles drawn on top of each other in the Timeline guide). By start
/// time, the earlier programme keeps its slot; a later one that starts
/// inside it is trimmed to begin when it ends, or dropped if it ends
/// inside it too.
List<EpgProgram> _untangle(List<EpgRow> rows) {
  final sorted = [...rows]..sort((a, b) => a.startMs.compareTo(b.startMs));
  final out = <EpgProgram>[];
  var lastStop = -1;
  for (final r in sorted) {
    if (r.stopMs <= lastStop) continue;
    final p = _toProgram(r);
    out.add(r.startMs < lastStop
        ? EpgProgram(
            channelId: p.channelId,
            title: p.title,
            description: p.description,
            start: DateTime.fromMillisecondsSinceEpoch(lastStop),
            stop: p.stop,
          )
        : p);
    lastStop = r.stopMs;
  }
  return out;
}

/// Fetches and parses XMLTV EPG data into [EpgDatabase], and serves it.
///
/// Programmes live on disk in [EpgDatabase] and are only ever *queried* —
/// the old design decoded one big JSON cache of every programme into memory
/// on each cold start (measured on a Formuler: 24.8 s for 167k programmes,
/// after the splash) and rewrote the whole file after every refresh (20 s,
/// and the step that ran Fire Sticks out of memory).
///
/// The getters stay synchronous so no caller had to change:
/// - [getCurrentProgram]/[getNextProgram] read [_soon] — every channel's
///   programmes for the next few hours, preloaded at startup in one query.
/// - [getPrograms] (the Timeline guide) returns a cached full window for a
///   channel, or queues a batched load for the channels being built and
///   returns the [_soon] slice meanwhile; [guideRowsLoaded] ticks when the
///   rows arrive.
/// - [hasPrograms] reads [_withData].
class EpgService extends ChangeNotifier {
  EpgService(this._storage, {@visibleForTesting EpgDatabase? database})
      : _db = database ?? EpgDatabase();

  final StorageService _storage;
  final EpgDatabase _db;

  /// The guide database's queue wait ([PerfDiagnostics]).
  Future<void> pingDatabase() => _db.ping();

  /// How far ahead [_soon] reaches — comfortably past "next" for any
  /// channel, and reloaded every [_soonReloadEvery] so it never runs dry.
  static const _soonAhead = Duration(hours: 4);
  static const _soonReloadEvery = Duration(minutes: 15);

  /// Cap on [_full] — the Timeline only ever shows a screenful of rows, so
  /// this is just a bound on memory while scrolling a big channel list.
  static const _fullCacheLimit = 400;

  static const _minFirstRefreshDelay = Duration(seconds: 30);

  /// Normalized EPG id -> days of past programmes to keep, for channels
  /// with catch-up (`PlaylistManager.catchupDaysByEpgId`). Every other
  /// channel keeps [AppConstants.epgPastRetention]. Read again on every
  /// refresh and cache reload, so a playlist update is picked up.
  Map<String, int> Function()? catchupDaysProvider;
  Map<String, int> _catchupDays = const {};
  DateTime? _catchupDaysReadAt;

  /// Awaited before a refresh parses anything: the live channel lists
  /// (PlaylistManager.ensureLiveChannelsLoaded). At launch they load after
  /// this service, so the catch-up list read too early was empty: rows kept
  /// only 2 h of past, and a refresh then dropped the catch-up past
  /// (owner, +460: only Update EPG brought it back).
  Future<void> Function()? beforeRefresh;

  /// Re-reads the catch-up list; true when it changed.
  bool _readCatchupDays() {
    try {
      final next = catchupDaysProvider?.call() ?? const <String, int>{};
      _catchupDaysReadAt = DateTime.now();
      if (mapEquals(next, _catchupDays)) return false;
      _catchupDays = next;
      return true;
    } catch (e) {
      debugPrint('EpgService: catch-up channels unavailable: $e');
      return false;
    }
  }

  @visibleForTesting
  static Duration catchupRecheckEvery = const Duration(seconds: 20);

  /// [_readCatchupDays] at most every 20 s, for row loads: channels that
  /// load after launch then get their catch-up past without a refresh.
  bool _readCatchupDaysIfStale() {
    final at = _catchupDaysReadAt;
    if (at != null && DateTime.now().difference(at) < catchupRecheckEvery) {
      return false;
    }
    return _readCatchupDays();
  }

  /// Oldest programme end kept for [normalizedId] (ms since epoch).
  int _minStopMsFor(String normalizedId, DateTime now) {
    final days = _catchupDays[normalizedId];
    return now
        .subtract(
            days == null ? AppConstants.epgPastRetention : Duration(days: days))
        .millisecondsSinceEpoch;
  }

  Map<String, List<EpgProgram>> _soon = {};
  final Map<String, List<EpgProgram>> _full = {};
  Set<String> _withData = {};

  final Set<String> _pendingLoads = {};
  final Set<String> _inFlightLoads = {};
  bool _loadScheduled = false;

  /// Bumped whenever the database changes under the caches, so a load that
  /// was in flight across a refresh doesn't put old rows back into [_full].
  int _cacheEpoch = 0;

  Timer? _soonTimer;
  Future<void>? _initFuture;

  /// Ticks when [getPrograms] rows finish loading — see [_loadPending].
  final ValueNotifier<int> guideRowsLoaded = ValueNotifier(0);

  /// Every `<channel id>` -> its first `<display-name>` this session has
  /// seen, across every source refreshed so far — *not* scoped to any one
  /// playlist's [EpgSource.knownChannelIds] the way stored programmes are
  /// (see [refresh]'s doc comment): the whole point is letting "Assign
  /// EPG channel" browse the *feed's* full channel directory to search
  /// for a match, independent of which ids a given playlist happens to
  /// already own. Small either way (a few thousand short strings, not
  /// full programme data) so keeping every source's entries around at
  /// once costs nothing worth guarding. Rebuilt fresh each app launch
  /// (not stored in [EpgDatabase]) — "Update EPG Now" is right there in
  /// the same settings screen that would use this.
  final Map<String, String> _channelCatalog = {};
  Map<String, String> get channelCatalog => Map.unmodifiable(_channelCatalog);

  /// Every `<channel id>`'s own currently-airing programme, as of
  /// whenever it was last refreshed — lets "Assign EPG channel" show what
  /// a *candidate* id is airing right now (e.g. telling `espn.us` apart
  /// from `espn2.us`/`espnu.us` by matching it against what the real
  /// channel is actually showing), not just its display name. Reported
  /// directly: several plausible-looking candidates for the same channel,
  /// no way to tell which one is actually right without trial and error.
  /// Same unfiltered-by-[EpgSource.knownChannelIds] reasoning as
  /// [_channelCatalog] — see [_parseXmltvStream]'s doc comment.
  final Map<String, EpgProgram> _nowPlayingCatalog = {};
  EpgProgram? currentProgramInCatalog(String id) =>
      _nowPlayingCatalog[normalizeEpgId(id)];

  DateTime? lastUpdated;
  bool isLoading = false;
  String? error;

  Timer? _refreshTimer;

  /// Evaluated fresh on every auto-refresh tick (not a frozen snapshot
  /// taken once at `startAutoRefresh` time) — playlists can be
  /// added/removed/enabled/disabled while the timer is running, and the
  /// next tick should reflect whichever playlists are enabled *then*, not
  /// whatever was true when the timer was first started.
  List<EpgSource> Function()? _sourcesProvider;

  /// Opens the database and preloads the small always-in-memory slices.
  /// Idempotent: `main.dart` starts it during the splash (cheap — a few
  /// thousand rows, and SQLite does the work on its own thread) and awaits
  /// the same future after the splash.
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    lastUpdated = _storage.getEpgLastUpdated();
    // Leftover from the pre-database JSON cache — tens of MB on a big feed.
    unawaited(_storage
        .deleteCacheFile(AppConstants.cacheFileEpgPrograms)
        .catchError((_) {}));
    try {
      await _db.open();
      await _reloadCaches();
      unawaited(
          Future<void>.delayed(const Duration(seconds: 25), _db.logStats));
    } catch (e) {
      debugPrint('EpgService.init: $e');
    }
    _soonTimer = Timer.periodic(_soonReloadEvery, (_) async {
      await _reloadCaches();
      notifyListeners();
    });
    notifyListeners();
  }

  /// Reloads [_soon]/[_withData] from the database and drops [_full], so
  /// every guide row re-queries on its next build.
  Future<void> _reloadCaches() async {
    _readCatchupDays();
    final now = DateTime.now();
    final soon = await _db.programmesBetween(
        now.millisecondsSinceEpoch, now.add(_soonAhead).millisecondsSinceEpoch);
    final withData = await _db.channelIdsWithData(now.millisecondsSinceEpoch);
    _soon = _toPrograms(soon);
    _withData = withData;
    _full.clear();
    _cacheEpoch++;
  }

  /// (Re)starts auto-refresh every [minutes], refreshing every source
  /// [sourcesProvider] returns (one per enabled playlist with a non-empty
  /// EPG URL — see [EpgSource]). The first tick is due when the stored data
  /// reaches [minutes] old — immediately if it already is, or if the
  /// database is empty (first launch after upgrading from the JSON cache) —
  /// so a box that was off for a day refreshes at launch instead of waiting
  /// a full interval. Call again whenever the interval changes.
  ///
  /// Never sooner than [_minFirstRefreshDelay]: a refresh parses on the UI
  /// isolate for ~30 s on a Formuler, and the first seconds after the
  /// splash are when weak boxes used to crash under load (see main.dart's
  /// splash comments). The stored guide is already on screen meanwhile.
  void startAutoRefresh(
      int minutes, List<EpgSource> Function() sourcesProvider) {
    _refreshTimer?.cancel();
    _sourcesProvider = sourcesProvider;
    final interval = Duration(minutes: minutes);
    final age = lastUpdated == null
        ? interval
        : DateTime.now().difference(lastUpdated!);
    var firstDelay = _withData.isEmpty ? Duration.zero : interval - age;
    if (firstDelay < _minFirstRefreshDelay) {
      firstDelay = _minFirstRefreshDelay;
    }
    _refreshTimer = Timer(firstDelay, () {
      refreshAll();
      _refreshTimer = Timer.periodic(interval, (_) => refreshAll());
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Refreshes every source [_sourcesProvider] currently returns, one at a
  /// time — each source only ever replaces its own rows (see
  /// [EpgDatabase.deleteStaleFromSource]), and running them sequentially
  /// keeps `isLoading`/`error` meaningful for whichever one is in flight.
  /// Skipped while another refresh is already running.
  Future<void> refreshAll() async {
    if (isLoading) return;
    final sources = _sourcesProvider?.call() ?? const [];
    if (sources.isEmpty) return;
    await _runRefresh(sources);
  }

  /// Refreshes one EPG source — the entry point for every *single*-playlist
  /// caller (adding a playlist).
  Future<void> refresh(String url,
      {required Set<String> knownChannelIds}) async {
    await _runRefresh([(url: url, knownChannelIds: knownChannelIds)]);
  }

  Future<void> _runRefresh(List<EpgSource> sources) async {
    isLoading = true;
    notifyListeners();
    try {
      await init();
      var anySucceeded = false;
      try {
        await beforeRefresh?.call();
      } catch (e) {
        debugPrint('EpgService: channels not ready for refresh: $e');
      }
      _readCatchupDays();
      for (final source in sources) {
        final count = await _refreshOne(source.url,
            knownChannelIds: source.knownChannelIds);
        if (count != null) anySucceeded = true;
      }
      if (anySucceeded) {
        final now = DateTime.now();
        await _db.deleteEndedBefore(
            now.subtract(AppConstants.epgPastRetention).millisecondsSinceEpoch,
            keep: {
              for (final id in _catchupDays.keys) id: _minStopMsFor(id, now)
            });
        lastUpdated = DateTime.now();
        await _storage.setEpgLastUpdated(lastUpdated!);
      }
      await _reloadCaches();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Wipes every stored programme ("Clear Cache" in EPG settings).
  Future<void> clearAll() async {
    await _db.clearAll();
    lastUpdated = null;
    _soon = {};
    _withData = {};
    _full.clear();
    _cacheEpoch++;
    notifyListeners();
  }

  /// Downloads and parses one EPG source, writing its programmes into
  /// [EpgDatabase] in small batches *while* parsing — the full feed is
  /// never held in memory. Returns how many programmes were stored, or null
  /// on failure. A failed/aborted refresh leaves that source's previous
  /// rows alone (stale-removal only runs after a complete parse), so a
  /// network error never empties the guide.
  ///
  /// [knownChannelIds] scopes the stored programmes — a shared
  /// multi-provider EPG source can cover vastly more channels than one
  /// playlist actually has. Empty [knownChannelIds] disables filtering
  /// entirely rather than risking an empty guide if this ever races ahead
  /// of the playlist's own channels finishing their load.
  Future<int?> _refreshOne(String url,
      {required Set<String> knownChannelIds}) async {
    if (url.isEmpty) return null;
    error = null;
    notifyListeners();

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final streamedResponse =
          await client.send(request).timeout(const Duration(seconds: 30));
      if (streamedResponse.statusCode != 200) {
        throw Exception(tr('Failed to load EPG (HTTP {code})',
            {'code': streamedResponse.statusCode}));
      }

      // Normalized the same way the parser normalizes the feed's own ids
      // (see [normalizeEpgId]) — these are Channel.epgId values (rawId or
      // a manual override), compared against the feed's <channel>/
      // <programme channel="..."> ids below, and a caller's casing
      // convention won't generally match the feed's own.
      final effectiveFilter = knownChannelIds.isEmpty
          ? null
          : knownChannelIds.map(normalizeEpgId).toSet();
      // Unique per refresh across app restarts — see
      // [EpgDatabase.deleteStaleFromSource].
      final gen = DateTime.now().millisecondsSinceEpoch;
      final result = await _parseXmltvStream(
        await _autoGunzip(streamedResponse.stream),
        knownChannelIds: effectiveFilter,
        onRows: (rows) => _db.insertBatch(rows, url, gen),
      ).timeout(const Duration(minutes: 10));
      // First-seen wins on a duplicate id across sources — an arbitrary
      // but harmless tie-break; these are just display labels for a
      // picker, not something correctness depends on.
      for (final entry in result.channelNames.entries) {
        _channelCatalog.putIfAbsent(entry.key, () => entry.value);
      }
      // Overwrite (not putIfAbsent) — unlike a channel's name, "what's on
      // right now" for a given id goes stale, so a fresh refresh's answer
      // should replace whatever an earlier one found.
      _nowPlayingCatalog.addAll(result.nowPlaying);

      // Only this URL's own rows from earlier refreshes that it didn't
      // re-send (channel dropped, programme rescheduled) — never another
      // source's, which used to wrongly wipe a manual override pointing at
      // a different playlist's feed.
      await _db.deleteStaleFromSource(url, gen);
      return result.stored;
    } catch (e) {
      error = e.toString();
      debugPrint('EpgService error: $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// Transparently decompresses gzip — plenty of third-party XMLTV sources
  /// (large ones especially) are served as `.xml.gz` to save bandwidth,
  /// and a plain file host (unlike a real web server) commonly serves that
  /// as its literal bytes with no `Content-Encoding: gzip` header, so
  /// there's nothing for the HTTP client to auto-decompress — confirmed
  /// directly against a real feed advertised for this app. Detected by
  /// sniffing the gzip magic number on the stream's first chunk rather
  /// than trusting the URL's extension (a redirect, or a server not
  /// bothering to name it `.gz`, would defeat that). Still fully
  /// streaming either way — `gzip.decoder` decompresses incrementally, so
  /// this never buffers the whole (routinely much larger, decompressed)
  /// file in memory, matching [_parseXmltvStream]'s own reason for
  /// avoiding a full DOM parse.
  Future<Stream<List<int>>> _autoGunzip(Stream<List<int>> input) async {
    final it = StreamIterator(input);
    if (!await it.moveNext()) return const Stream.empty();
    final first = it.current;
    Stream<List<int>> rebuilt() async* {
      yield first;
      while (await it.moveNext()) {
        yield it.current;
      }
    }

    final isGzip = first.length >= 2 && first[0] == 0x1F && first[1] == 0x8B;
    return isGzip ? rebuilt().transform(gzip.decoder) : rebuilt();
  }

  /// Parses XMLTV as a stream of events rather than building a full DOM —
  /// full program guides (many channels x many days) are routinely well
  /// over 100MB of XML, and loading that into one String plus a full
  /// [XmlDocument] tree is exactly the kind of allocation that triggers an
  /// OutOfMemoryError on a phone's capped per-app heap.
  ///
  /// Programmes are handed to [onRows] in batches as they're parsed, never
  /// accumulated — only those inside the stored window
  /// ([AppConstants.epgPastRetention]/[AppConstants.epgFutureWindow]) and,
  /// when [knownChannelIds] is non-null, only for channels in it (a shared
  /// multi-provider source routinely covers far more channels than any
  /// one playlist actually has).
  Future<
      ({
        int stored,
        Map<String, String> channelNames,
        Map<String, EpgProgram> nowPlaying
      })> _parseXmltvStream(
    Stream<List<int>> byteStream, {
    Set<String>? knownChannelIds,
    required Future<void> Function(List<EpgRow> rows) onRows,
  }) async {
    const batchSize = 1000;
    var pending = <EpgRow>[];
    var stored = 0;
    // Every <channel id>'s first <display-name> — never filtered by
    // [knownChannelIds]: see [EpgService._channelCatalog]'s doc comment for
    // why the *whole* feed's directory matters here, not just whatever one
    // playlist already owns.
    final channelNames = <String, String>{};
    // Every <channel id>'s own currently-airing programme, same
    // unfiltered-by-design reasoning as [channelNames] — "Assign EPG
    // channel" needs to show what's actually on right now for each
    // *candidate* id, most of which aren't in [knownChannelIds] at all
    // (that's the whole point of searching for one). Bounded the same
    // way [channelNames] is (one entry per channel, not per programme),
    // so keeping it unfiltered costs nothing worth guarding against.
    final nowPlaying = <String, EpgProgram>{};
    final now = DateTime.now();
    final minStopMs =
        now.subtract(AppConstants.epgPastRetention).millisecondsSinceEpoch;
    final catchupDays = _catchupDays;
    final maxStartMs =
        now.add(AppConstants.epgFutureWindow).millisecondsSinceEpoch;

    String? channelId;
    String? startRaw;
    String? stopRaw;
    // 'title'/'desc' while inside a <programme>, or 'display-name' while
    // inside a <channel> — safe to share one flag either way since XMLTV
    // never nests one inside the other.
    String? currentTextTag;
    String? title;
    String? desc;
    String? catalogChannelId;
    String? catalogDisplayName;

    void finalizeProgramme() {
      if (channelId == null || startRaw == null || stopRaw == null) return;
      try {
        final start = _parseXmltvTime(startRaw);
        final stop = _parseXmltvTime(stopRaw);
        final cleanTitle =
            title?.trim().isNotEmpty == true ? title!.trim() : tr('No Title');
        final cleanDesc =
            (desc?.trim().isNotEmpty ?? false) ? desc!.trim() : null;
        if (!now.isBefore(start) && now.isBefore(stop)) {
          nowPlaying[channelId] = EpgProgram(
            channelId: channelId,
            title: cleanTitle,
            description: cleanDesc,
            start: start,
            stop: stop,
          );
        }
        if (knownChannelIds != null && !knownChannelIds.contains(channelId)) {
          return;
        }
        final startMs = start.millisecondsSinceEpoch;
        final stopMs = stop.millisecondsSinceEpoch;
        if (startMs >= maxStartMs) return;
        if (stopMs <= minStopMs &&
            (catchupDays[channelId] == null ||
                stopMs <= _minStopMsFor(channelId, now))) {
          return;
        }
        pending.add((
          channelId: channelId,
          startMs: startMs,
          stopMs: stopMs,
          title: cleanTitle,
          description: cleanDesc,
        ));
      } catch (_) {
        // Unparseable timestamp — skip this one programme, keep going.
      }
    }

    Future<void> flush() async {
      if (pending.isEmpty) return;
      final rows = pending;
      pending = <EpgRow>[];
      stored += rows.length;
      await onRows(rows);
    }

    final events = byteStream
        .transform(const Utf8Decoder(allowMalformed: true))
        .toXmlEvents()
        .normalizeEvents()
        .flatten();

    // A full-catalog EPG can be hundreds of thousands of XML events. Stream
    // delivery yields between them at the microtask level, but that's not
    // the same as yielding to the Flutter engine's frame scheduler — on
    // weak hardware, long enough runs of back-to-back microtask work can
    // still stall UI responsiveness badly enough to look frozen. Force a
    // real yield periodically so a frame always gets a chance to run.
    var eventsSinceYield = 0;
    await for (final event in events) {
      if (++eventsSinceYield >= 500) {
        eventsSinceYield = 0;
        await Future<void>.delayed(Duration.zero);
      }
      if (event is XmlStartElementEvent) {
        if (event.name == 'programme') {
          channelId = null;
          startRaw = null;
          stopRaw = null;
          title = null;
          desc = null;
          currentTextTag = null;
          for (final attr in event.attributes) {
            switch (attr.name) {
              case 'channel':
                channelId = normalizeEpgId(attr.value);
              case 'start':
                startRaw = attr.value;
              case 'stop':
                stopRaw = attr.value;
            }
          }
          // A self-closing <programme/> has no title/desc children and no
          // matching end event, so it must be recorded right here.
          if (event.isSelfClosing) finalizeProgramme();
        } else if (event.name == 'channel') {
          catalogChannelId = null;
          catalogDisplayName = null;
          currentTextTag = null;
          for (final attr in event.attributes) {
            if (attr.name == 'id') {
              catalogChannelId = normalizeEpgId(attr.value);
            }
          }
        } else if ((event.name == 'title' ||
                event.name == 'desc' ||
                event.name == 'display-name') &&
            !event.isSelfClosing) {
          // Self-closing versions of these carry no text — leave
          // currentTextTag unset so we don't wait on an end event that
          // will never arrive for them.
          currentTextTag = event.name;
        }
      } else if (event is XmlTextEvent) {
        if (currentTextTag == 'title') {
          title = (title ?? '') + event.value;
        } else if (currentTextTag == 'desc') {
          desc = (desc ?? '') + event.value;
        } else if (currentTextTag == 'display-name' &&
            catalogDisplayName == null) {
          // First <display-name> only — a channel can list several
          // (language variants, abbreviations); the first is XMLTV's own
          // convention for "the" name.
          catalogDisplayName = event.value;
        }
      } else if (event is XmlEndElementEvent) {
        if (event.name == 'title' || event.name == 'desc') {
          currentTextTag = null;
        } else if (event.name == 'display-name') {
          currentTextTag = null;
        } else if (event.name == 'programme') {
          finalizeProgramme();
        } else if (event.name == 'channel') {
          final id = catalogChannelId;
          if (id != null && catalogDisplayName != null) {
            channelNames.putIfAbsent(id, () => catalogDisplayName!.trim());
          }
        }
      }
      if (pending.length >= batchSize) await flush();
    }
    await flush();

    return (stored: stored, channelNames: channelNames, nowPlaying: nowPlaying);
  }

  /// Parses XMLTV timestamps such as `20240101120000 +0000`.
  DateTime _parseXmltvTime(String raw) {
    final cleaned = raw.trim();
    final datePart = cleaned.substring(0, 14);
    final year = int.parse(datePart.substring(0, 4));
    final month = int.parse(datePart.substring(4, 6));
    final day = int.parse(datePart.substring(6, 8));
    final hour = int.parse(datePart.substring(8, 10));
    final minute = int.parse(datePart.substring(10, 12));
    final second = int.parse(datePart.substring(12, 14));

    var offsetHours = 0;
    var offsetMinutes = 0;
    if (cleaned.length > 15) {
      final offsetPart = cleaned.substring(15).trim();
      final sign = offsetPart.startsWith('-') ? -1 : 1;
      final digits = offsetPart.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 4) {
        offsetHours = sign * int.parse(digits.substring(0, 2));
        offsetMinutes = sign * int.parse(digits.substring(2, 4));
      }
    }

    return DateTime.utc(year, month, day, hour, minute, second)
        .subtract(Duration(hours: offsetHours, minutes: offsetMinutes))
        .toLocal();
  }

  List<EpgProgram>? _cached(String id) => _full[id] ?? _soon[id];

  EpgProgram? getCurrentProgram(String channelId) {
    final list = _cached(normalizeEpgId(channelId));
    if (list == null) return null;
    final now = DateTime.now();
    for (final p in list) {
      if (p.isNowPlaying(now)) return p;
    }
    return null;
  }

  EpgProgram? getNextProgram(String channelId) {
    final list = _cached(normalizeEpgId(channelId));
    if (list == null) return null;
    final now = DateTime.now();
    for (final p in list) {
      if (p.start.isAfter(now)) return p;
    }
    return null;
  }

  /// Programmes starting between [from] and [to] whose title contains any
  /// of [terms] — see [EpgDatabase.programmesStartingWithTitle]. Channel ids
  /// come back normalized (see [normalizeEpgId]).
  Future<List<EpgProgram>> findProgrammesByTitle(
      DateTime from, DateTime to, List<String> terms) async {
    try {
      final rows = await _db.programmesStartingWithTitle(
          from.millisecondsSinceEpoch, to.millisecondsSinceEpoch, terms);
      return rows.map(_toProgram).toList();
    } catch (e) {
      debugPrint('EpgService: title search failed: $e');
      return const [];
    }
  }

  DateTime? _coverageStamp;
  final Map<int, Future<int>> _airingCounts = {};

  /// How much of the guide reaches [at]: channels with a programme on then,
  /// over channels with one on now (0 = none, about 1 = as well covered as
  /// today), or null without a guide. Sports Trak uses it to tell "your
  /// guide doesn't reach this game yet" apart from "nothing names this
  /// game". Not the guide's latest end: a few channels listed a week ahead
  /// made a provider's 2-day guide look like it reached Friday (owner,
  /// 2026-10-21). Counts are per hour and kept until the next refresh.
  Future<double?> guideCoverageAt(DateTime at) async {
    if (_coverageStamp != lastUpdated) {
      _coverageStamp = lastUpdated;
      _airingCounts.clear();
    }
    Future<int> airing(DateTime t) {
      final hour = t.millisecondsSinceEpoch ~/ Duration.millisecondsPerHour;
      return _airingCounts[hour] ??=
          _db.countAiringAt(hour * Duration.millisecondsPerHour);
    }

    try {
      final now = await airing(DateTime.now());
      if (now == 0) return null;
      return await airing(at) / now;
    } catch (e) {
      debugPrint('EpgService: guide coverage failed: $e');
      _airingCounts.clear();
      return null;
    }
  }

  /// [getPrograms] limited to programmes overlapping [from]..[to] — the
  /// catch-up guide's view of the past. Same lazy loading.
  List<EpgProgram> programsBetween(
          String channelId, DateTime from, DateTime to) =>
      [
        for (final p in getPrograms(channelId))
          if (p.stop.isAfter(from) && p.start.isBefore(to)) p
      ];

  /// Whether [channelId] has any programme that hasn't ended — without
  /// loading its rows.
  bool hasPrograms(String channelId) =>
      _withData.contains(normalizeEpgId(channelId));

  /// Every stored programme for [channelId], ordered by start. Served from
  /// memory when loaded; otherwise queues a batched database load (every
  /// channel requested in the same frame shares one query) and returns the
  /// preloaded next-few-hours slice meanwhile — [guideRowsLoaded] ticks when
  /// the full rows arrive. Safe to call from `build`: the load and its
  /// notification always happen after the current frame.
  List<EpgProgram> getPrograms(String channelId) {
    // Catch-up channels known now (live lists load after launch): rows in
    // memory were cut at 2 h of past, so they all load again.
    if (_readCatchupDaysIfStale()) {
      _full.clear();
      debugPrint('EpgService: catch-up channels: ${_catchupDays.length}');
    }
    final id = normalizeEpgId(channelId);
    final full = _full[id];
    if (full != null) return full;
    if (!_withData.contains(id) && !_catchupDays.containsKey(id)) {
      return _soon[id] ?? const [];
    }
    if (!_inFlightLoads.contains(id)) {
      _pendingLoads.add(id);
      if (!_loadScheduled) {
        _loadScheduled = true;
        Timer.run(_loadPending);
      }
    }
    return _soon[id] ?? const [];
  }

  Future<void> _loadPending() async {
    _loadScheduled = false;
    if (_pendingLoads.isEmpty) return;
    final ids = _pendingLoads.toList();
    _pendingLoads.clear();
    _inFlightLoads.addAll(ids);
    final epoch = _cacheEpoch;
    try {
      final now = DateTime.now();
      var since = now.subtract(AppConstants.epgPastRetention);
      for (final id in ids) {
        final days = _catchupDays[id];
        if (days == null) continue;
        final own = now.subtract(Duration(days: days));
        if (own.isBefore(since)) since = own;
      }
      final rows = await _db.programmesFor(ids, since.millisecondsSinceEpoch);
      if (epoch != _cacheEpoch) return;
      if (_full.length + ids.length > _fullCacheLimit) _full.clear();
      for (final id in ids) {
        // One query for the batch reaches the oldest catch-up horizon;
        // channels without catch-up still only show their usual past.
        final minStop = _minStopMsFor(id, now);
        _full[id] = _untangle([
          for (final r in rows[id] ?? const <EpgRow>[])
            if (r.stopMs > minStop) r
        ]);
      }
      // Not notifyListeners(): TvHomeScreen watches this whole service, and
      // rebuilding all of it for every guide row scrolled into view would
      // jank a weak box. Only the Timeline listens to this.
      guideRowsLoaded.value++;
    } catch (e) {
      debugPrint('EpgService: guide load failed: $e');
    } finally {
      _inFlightLoads.removeAll(ids);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _soonTimer?.cancel();
    guideRowsLoaded.dispose();
    super.dispose();
  }
}
