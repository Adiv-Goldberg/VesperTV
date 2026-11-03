import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'perf_diagnostics.dart';

/// One programme row as stored in [EpgDatabase] — times are epoch
/// milliseconds (UTC), so reading a row back never goes through
/// `DateTime.parse` (the old JSON cache paid ~430k of those per cold start).
typedef EpgRow = ({
  String channelId,
  int startMs,
  int stopMs,
  String title,
  String? description,
});

/// On-disk EPG store — replaces the single big JSON cache file that
/// `EpgService.init()` used to fully decode on every cold start (measured
/// ~58 s on a Formuler before the guide appeared). The guide is now only
/// ever *queried* for the channels actually on screen, the same way the
/// VOD/series catalog moved into [CatalogDatabase].
///
/// Only a rolling window is kept (see `AppConstants.epgPastRetention` /
/// `epgFutureWindow`) — the past side is a constant on purpose so a later
/// catch-up feature can simply widen it.
///
/// Fully re-derivable from the EPG URLs, so a database that won't open is
/// deleted and recreated rather than surfaced as an error.
class EpgDatabase {
  EpgDatabase({@visibleForTesting Database? database}) : _db = database;
  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;
    // Application *support* dir, not the temporary/cache dir the old JSON
    // file lived in: Android may purge the cache dir at any time, which
    // left the guide empty until the next refresh.
    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, 'vesper_epg.db');
    try {
      _db = await _open(path);
    } catch (e) {
      debugPrint('EpgDatabase: reopening from scratch after $e');
      await deleteDatabase(path);
      _db = await _open(path);
    }
    return _db!;
  }

  Future<Database> _open(String path) => openDatabase(
        path,
        version: 2,
        // The sports index is built lazily, outside cold-start guide loading.
        onUpgrade: (db, oldVersion, newVersion) async {},
        onCreate: (db, version) => createSchema(db),
      );

  @visibleForTesting
  static Future<void> createSchema(Database db) async {
    // (channel_id, start) is the natural key and also exactly the
    // lookup every read does — WITHOUT ROWID stores rows in that
    // order, so "programmes for these channels" is an index range
    // scan with no extra table lookup.
    await db.execute('''
            CREATE TABLE programme (
              channel_id TEXT NOT NULL,
              start INTEGER NOT NULL,
              stop INTEGER NOT NULL,
              title TEXT NOT NULL,
              descr TEXT,
              source_url TEXT NOT NULL,
              gen INTEGER NOT NULL,
              PRIMARY KEY (channel_id, start)
            ) WITHOUT ROWID
          ''');
    await db.execute('CREATE INDEX idx_programme_stop ON programme(stop)');
    await db.execute(
        'CREATE INDEX idx_programme_source ON programme(source_url, gen)');
  }

  Future<void> open() async => _database;

  /// Every programme for [channelIds] that hasn't ended before [minStopMs],
  /// ordered by channel then start. Chunked to stay under SQLite's bound
  /// parameter limit.
  Future<Map<String, List<EpgRow>>> programmesFor(
      List<String> channelIds, int minStopMs) async {
    final db = await _database;
    final result = <String, List<EpgRow>>{};
    const chunk = 500;
    for (var i = 0; i < channelIds.length; i += chunk) {
      final ids = channelIds.sublist(
          i, i + chunk > channelIds.length ? channelIds.length : i + chunk);
      final placeholders = List.filled(ids.length, '?').join(',');
      final rows = await db.rawQuery(
        'SELECT channel_id, start, stop, title, descr FROM programme '
        'WHERE channel_id IN ($placeholders) AND stop > ? '
        'ORDER BY channel_id, start',
        [...ids, minStopMs],
      );
      for (final r in rows) {
        final id = r['channel_id'] as String;
        (result[id] ??= []).add((
          channelId: id,
          startMs: r['start'] as int,
          stopMs: r['stop'] as int,
          title: r['title'] as String,
          description: r['descr'] as String?,
        ));
      }
    }
    return result;
  }

  /// Every channel's programmes overlapping [fromMs, toMs) — the small
  /// "now / next" slice `EpgService` preloads for *all* channels at startup
  /// (a few rows per channel instead of the whole window).
  Future<Map<String, List<EpgRow>>> programmesBetween(
      int fromMs, int toMs) async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT channel_id, start, stop, title, descr FROM programme '
      'WHERE stop > ? AND start < ? ORDER BY channel_id, start',
      [fromMs, toMs],
    );
    final result = <String, List<EpgRow>>{};
    for (final r in rows) {
      final id = r['channel_id'] as String;
      (result[id] ??= []).add((
        channelId: id,
        startMs: r['start'] as int,
        stopMs: r['stop'] as int,
        title: r['title'] as String,
        description: r['descr'] as String?,
      ));
    }
    return result;
  }

  /// Programmes starting in [fromMs, toMs) whose title contains any of
  /// [terms] (case-insensitive) — the Sports tab's "find this game in the
  /// guide" lookup, one scan for a whole day of games rather than one per
  /// game. Chunked to stay under SQLite's bound parameter limit.
  Future<List<EpgRow>> programmesStartingWithTitle(
      int fromMs, int toMs, List<String> terms) async {
    if (terms.isEmpty || toMs <= fromMs) return const [];
    final watch = Stopwatch()..start();
    final result = <EpgRow>[];
    const sliceMs = 6 * Duration.millisecondsPerHour;
    var scans = 0;
    for (var slice = fromMs ~/ sliceMs * sliceMs;
        slice < toMs;
        slice += sliceMs) {
      final rows = await _sportsSlice(slice);
      // Literal terms, not SQL wildcards. Expensive title matching runs away
      // from both the UI isolate and sqflite's guide connection.
      result.addAll(
          await compute(filterSportsTitles, (rows, terms, fromMs, toMs)));
      scans++;
      await Future<void>.delayed(Duration.zero);
    }
    debugPrint('EpgDatabase: title scan ${terms.length} terms '
        '($scans slices) -> ${result.length} rows '
        'in ${watch.elapsedMilliseconds} ms');
    return result;
  }

  Future<void>? _sportsIndex;
  final Map<int, (Future<List<EpgRow>>, DateTime)> _sportsSlices = {};

  void _invalidateSports() => _sportsSlices.clear();

  Future<List<EpgRow>> _sportsSlice(int from) {
    final now = DateTime.now();
    _sportsSlices.removeWhere(
        (_, entry) => now.difference(entry.$2) > const Duration(minutes: 15));
    final hit = _sportsSlices[from];
    if (hit != null) return hit.$1;
    // Bound title-only cache memory. Pending readers retain their own future.
    while (_sportsSlices.length >= 6) {
      _sportsSlices.remove(_sportsSlices.keys.first);
    }
    final future = _readSportsSlice(from);
    _sportsSlices[from] = (future, now);
    return future;
  }

  Future<List<EpgRow>> _readSportsSlice(int from) async {
    try {
      final db = await _database;
      await (_sportsIndex ??= db.execute(
          'CREATE INDEX IF NOT EXISTS idx_programme_start ON programme(start)'));
      final rows = <EpgRow>[];
      final to = from + 6 * Duration.millisecondsPerHour;
      var start = from;
      String? channel;
      // Keyset pagination keeps each DB turn small and avoids OFFSET rescans.
      while (true) {
        final batch = await db.rawQuery(
          'SELECT channel_id, start, stop, title FROM programme '
          'INDEXED BY idx_programme_start WHERE start >= ? AND start < ? '
          '${channel == null ? '' : 'AND (start > ? OR (start = ? AND channel_id > ?)) '}'
          'ORDER BY start, channel_id LIMIT 1000',
          [
            start,
            to,
            if (channel != null) ...[start, start, channel]
          ],
        );
        for (final r in batch) {
          rows.add((
            channelId: r['channel_id'] as String,
            startMs: r['start'] as int,
            stopMs: r['stop'] as int,
            title: r['title'] as String,
            description: null
          ));
        }
        if (batch.length < 1000) break;
        start = batch.last['start'] as int;
        channel = batch.last['channel_id'] as String;
        await Future<void>.delayed(Duration.zero);
      }
      return rows;
    } catch (_) {
      _sportsIndex = null;
      _sportsSlices.remove(from);
      rethrow;
    }
  }

  /// One line for Send log: how big the guide is (programmes, channels, the
  /// time span) and how long counting it took. Run once, a while after
  /// startup, so it never competes with the splash.
  Future<void> logStats() async {
    try {
      final db = await _database;
      final watch = Stopwatch()..start();
      final r = (await db.rawQuery('SELECT COUNT(*) AS n, '
              'COUNT(DISTINCT channel_id) AS c, MIN(start) AS a, '
              'MAX(stop) AS b FROM programme'))
          .first;
      String day(Object? ms) => ms is int
          ? DateTime.fromMillisecondsSinceEpoch(ms)
              .toIso8601String()
              .substring(0, 16)
          : '-';
      debugPrint('EpgDatabase: guide ${r['n']} programmes, ${r['c']} '
          'channels, ${day(r['a'])} to ${day(r['b'])} '
          '(counted in ${watch.elapsedMilliseconds} ms)');
    } catch (e) {
      debugPrint('EpgDatabase: stats failed: $e');
    }
  }

  /// Distinct channel ids that still have any programme ending after
  /// [minStopMs] — the "does this channel have EPG at all" answer for
  /// callers that need it for every channel at once (auto-pair).
  Future<Set<String>> channelIdsWithData(int minStopMs) async {
    final db = await _database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT channel_id FROM programme WHERE stop > ?',
        [minStopMs]);
    return {for (final r in rows) r['channel_id'] as String};
  }

  /// How many programmes are on at [atMs] — one per channel with guide
  /// data then.
  Future<int> countAiringAt(int atMs) async {
    final db = await _database;
    final rows = await db.rawQuery(
        'SELECT COUNT(*) AS n FROM programme WHERE stop > ? AND start <= ?',
        [atMs, atMs]);
    return rows.first['n'] as int? ?? 0;
  }

  Future<bool> isEmpty() async {
    final db = await _database;
    final rows = await db.rawQuery('SELECT 1 FROM programme LIMIT 1');
    return rows.isEmpty;
  }

  /// Writes one batch of parsed rows in a single transaction. A re-sent
  /// programme (same channel + start) replaces the old row and takes the
  /// new [gen], which is what [deleteStaleFromSource] keys off.
  ///
  /// Two *different* sources covering the same channel + start overwrite
  /// each other's row ("last refresh wins") — harmless for display, and
  /// either source's next refresh puts its own version back.
  ///
  /// Keep batches small (~1000 rows): sqflite has one connection, so a
  /// long commit would stall the guide's reads behind it.
  Future<void> insertBatch(List<EpgRow> rows, String sourceUrl, int gen) =>
      PerfDiagnostics.timed('epg insert n=${rows.length}',
          () => _insertBatch(rows, sourceUrl, gen));

  Future<void> _insertBatch(
      List<EpgRow> rows, String sourceUrl, int gen) async {
    if (rows.isEmpty) return;
    final db = await _database;
    final batch = db.batch();
    for (final r in rows) {
      batch.rawInsert(
        'INSERT OR REPLACE INTO programme '
        '(channel_id, start, stop, title, descr, source_url, gen) '
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          r.channelId,
          r.startMs,
          r.stopMs,
          r.title,
          r.description,
          sourceUrl,
          gen
        ],
      );
    }
    await batch.commit(noResult: true);
    _invalidateSports();
  }

  /// After a *successful* refresh of [sourceUrl]: drops every row that
  /// source wrote in an earlier refresh but didn't re-send this time
  /// (channel removed from the feed, programme rescheduled). Never touches
  /// another source's rows. A failed/aborted refresh skips this, so the
  /// previous data survives a network error.
  Future<void> deleteStaleFromSource(String sourceUrl, int gen) async {
    final db = await _database;
    _invalidateSports();
    await db.delete('programme',
        where: 'source_url = ? AND gen <> ?', whereArgs: [sourceUrl, gen]);
  }

  /// Rolling-window trim: drops programmes that ended before [minStopMs].
  /// Deletes programmes that ended before [minStopMs], except channels in
  /// [keep] (normalized id -> their own oldest kept end), which only lose
  /// rows older than that — catch-up channels keep days of past.
  Future<void> deleteEndedBefore(int minStopMs,
          {Map<String, int> keep = const {}}) =>
      PerfDiagnostics.timed('epg trim keep=${keep.length}',
          () => _deleteEndedBefore(minStopMs, keep: keep));

  /// A trivial query: how long it waits = the guide database's queue.
  Future<void> ping() async => (await _database).rawQuery('SELECT 1');

  Future<void> _deleteEndedBefore(int minStopMs,
      {Map<String, int> keep = const {}}) async {
    final db = await _database;
    _invalidateSports();
    if (keep.isEmpty) {
      await db.delete('programme', where: 'stop < ?', whereArgs: [minStopMs]);
      return;
    }
    await db.transaction((txn) async {
      await txn.execute('CREATE TEMP TABLE IF NOT EXISTS catchup_keep '
          '(channel_id TEXT PRIMARY KEY, min_stop INTEGER) WITHOUT ROWID');
      await txn.delete('catchup_keep');
      final batch = txn.batch();
      for (final e in keep.entries) {
        batch
            .insert('catchup_keep', {'channel_id': e.key, 'min_stop': e.value});
      }
      await batch.commit(noResult: true);
      await txn.rawDelete(
          'DELETE FROM programme WHERE stop < ? AND '
          'stop < COALESCE((SELECT min_stop FROM catchup_keep k '
          'WHERE k.channel_id = programme.channel_id), ?)',
          [minStopMs, minStopMs]);
      await txn.delete('catchup_keep');
    });
  }

  Future<void> clearAll() async {
    final db = await _database;
    _invalidateSports();
    await db.delete('programme');
  }
}

/// Isolate entry point; preserve literal case-insensitive substring semantics.
List<EpgRow> filterSportsTitles((List<EpgRow>, List<String>, int, int) input) {
  final (rows, terms, from, to) = input;
  final needles =
      terms.map((s) => s.toLowerCase()).where((s) => s.isNotEmpty).toList();
  return [
    for (final r in rows)
      if (r.startMs >= from &&
          r.startMs < to &&
          r.stopMs > from &&
          needles.any(r.title.toLowerCase().contains))
        r
  ];
}
