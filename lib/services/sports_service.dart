import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/sports.dart';
import '../l10n/l10n.dart';
import 'cfl_source.dart';
import 'sports_db_source.dart';
import 'storage_service.dart';

/// The viewer's active leagues, in their order: base leagues plus the ones
/// added from the League bank (defaults when nothing usable is saved).
/// Shared by the Sports tab and the player's side panel.
List<SportsLeague> savedSportsLeagues(StorageService storage) {
  final added = storage.getSportsAddedLeagues();
  final leagues = [
    for (final id in storage.getSportsLeagues() ?? kDefaultSportsLeagueIds)
      if (sportsLeagueById(id) case final l?)
        if (l.isBase || added.contains(id)) l,
  ];
  return leagues.isNotEmpty
      ? leagues
      : [for (final id in kDefaultSportsLeagueIds) sportsLeagueById(id)!];
}

/// The favourite league, when it's still one of [savedSportsLeagues] (a
/// hidden or sent-back league doesn't count).
SportsLeague? favoriteSportsLeague(StorageService storage) {
  final id = storage.getSportsFavoriteLeague();
  if (id == null) return null;
  return savedSportsLeagues(storage).where((l) => l.id == id).firstOrNull;
}

/// Scores and schedules from ESPN's public site API — key-less, so the
/// Sports tab works for everyone without signing up anywhere (see
/// dev-notes/sports-tab.md for why ESPN is the default layer). Unofficial
/// and undocumented: if it changes shape, this file is the only adapter to
/// fix.
///
/// One request returns every game of one league for one ESPN date, so the
/// cost is leagues x days, never per game. Results are cached in memory for
/// the whole app session with a freshness window that depends on what the
/// day holds (live games refresh every minute, finished days rarely).
class SportsService {
  SportsService._() : _client = http.Client();
  @visibleForTesting
  SportsService.forTesting(this._client);
  static final SportsService instance = SportsService._();

  static const _base = 'https://site.api.espn.com/apis/site/v2/sports';

  final http.Client _client;
  late final CflSource _cfl = CflSource(_client);
  final Map<String, _CacheEntry> _cache = {};
  final Map<String, Future<List<SportsGame>>> _inFlight = {};
  final Set<String> _failedScheduleKeys = {};
  bool _cflScheduleKnown = false;

  /// Empty is safe to hide only after every date needed for the local day
  /// loaded successfully. Failed refreshes keep cached games for display,
  /// but cannot establish that a league has no games. Unfetched is unknown.
  bool hasReliableSchedule(SportsLeague league, DateTime day) {
    if (league.isCfl) return _cflScheduleKnown;
    final local = DateTime(day.year, day.month, day.day);
    final dates = league.sportsDbId != null ? [local] : _aroundDay(local);
    return dates.every((date) {
      final key = '${league.id}|${_espnDate(date)}';
      return !_failedScheduleKeys.contains(key) &&
          (_cache[key]?.reliable ?? false);
    });
  }

  /// Every game of [leagues] that starts on the local calendar day [day],
  /// plus — when [day] is today — games from the day before that are still
  /// live past midnight. ESPN buckets games by US Eastern date, so the days
  /// either side are fetched too (cached) and filtered locally; otherwise a
  /// European viewer would lose every evening NHL game, which falls on the
  /// next local day.
  ///
  /// Never throws: a league that fails keeps its last cached games (or
  /// none), and [lastError] says so.
  /// The local day before [day], [day] and the day after, by calendar.
  /// Not +/- 24 h: on the day clocks go back, midnight + 24 h is 23:00 the
  /// same day, so the next day's schedule was never fetched (and spring
  /// forward skipped back two days).
  static List<DateTime> _aroundDay(DateTime day) => [
        DateTime(day.year, day.month, day.day - 1),
        DateTime(day.year, day.month, day.day),
        DateTime(day.year, day.month, day.day + 1),
      ];

  Future<List<SportsGame>> gamesForDay(
      List<SportsLeague> leagues, DateTime day) async {
    final local = DateTime(day.year, day.month, day.day);
    final today = _today();
    final dates = _aroundDay(local);
    final results = await Future.wait([
      for (final league in leagues)
        if (league.isCfl)
          _cflGames()
        else
          // TheSportsDB: the local date only (its rate limit). It buckets by
          // UTC date, which is the local one for European kick-offs here and
          // in the Americas; a viewer far east loses the evening games.
          for (final d in league.sportsDbId != null ? [local] : dates)
            _fetch(league, d),
    ]);
    final seen = <String>{};
    final games = <SportsGame>[];
    for (final list in results) {
      for (final g in list) {
        if (!seen.add('${g.league.id}:${g.id}')) continue;
        final start = g.start.toLocal();
        final sameDay = g.end == null &&
            start.year == local.year &&
            start.month == local.month &&
            start.day == local.day;
        final carriedOver = local == today &&
            g.state == GameState.live &&
            start.isBefore(local);
        if (sameDay || carriedOver || _tournamentDay(g, local)) games.add(g);
      }
    }
    games.sort((a, b) {
      final byStart = a.start.compareTo(b.start);
      return byStart != 0 ? byStart : a.league.id.compareTo(b.league.id);
    });
    return games;
  }

  Future<List<SportsGame>> _cflGames() async {
    try {
      final games = await _cfl.games();
      _cflScheduleKnown = true;
      lastError = null;
      return games;
    } catch (e) {
      debugPrint('SportsService: CFL scores failed: $e');
      _cflScheduleKnown = false;
      lastError = tr('Some scores could not be loaded. Check the connection.');
      return _cfl.cachedGames;
    }
  }

  /// A golf tournament runs Thursday to Sunday but ESPN dates it once, at
  /// US-Eastern midnight of day one (`04:00Z`/`05:00Z`), with `endDate` the
  /// last day's midnight. Shown on each of its days: those are Eastern
  /// calendar dates, so read them 4 h back from UTC rather than in the
  /// viewer's zone (midnight Eastern is the evening before in California).
  static bool _tournamentDay(SportsGame g, DateTime localDay) {
    final end = g.end;
    if (end == null) return false;
    DateTime easternDate(DateTime utc) {
      final t = utc.subtract(const Duration(hours: 4));
      return DateTime(t.year, t.month, t.day);
    }

    final first = easternDate(g.start);
    final last = easternDate(end);
    return !localDay.isBefore(first) && !localDay.isAfter(last);
  }

  /// TheSportsDB leagues go through its rate-limit bucket.
  Future<http.Response> _get(SportsLeague league, Uri url) =>
      league.sportsDbId != null
          ? SportsDbSource.get(_client, url)
          : _client.get(url).timeout(const Duration(seconds: 15));

  /// Set when the most recent load had at least one failed request.
  String? lastError;

  static const _standingsBase = 'https://site.api.espn.com/apis/v2/sports';

  /// A conference league's scoreboard filter ([SportsLeague.espnGroup]),
  /// after [sep] (`?` or `&`); empty for every other league.
  static String _groupQuery(SportsLeague league, String sep) =>
      league.espnGroup == null ? '' : '${sep}groups=${league.espnGroup}';
  final Map<String, (SportsStandings, DateTime)> _standingsCache = {};
  final Map<String, Future<SportsStandings?>> _standingsInFlight = {};

  /// Conference/league tables for [league]. Null when ESPN can't be reached
  /// and nothing is cached. Standings only move when a game ends, so a
  /// 15-minute cache is plenty.
  Future<SportsStandings?> standings(SportsLeague league) {
    final cached = _standingsCache[league.id];
    if (cached != null &&
        DateTime.now().difference(cached.$2) < const Duration(minutes: 15)) {
      return Future.value(cached.$1);
    }
    return _standingsInFlight[league.id] ??=
        _downloadStandings(league).whenComplete(() {
      _standingsInFlight.remove(league.id);
    });
  }

  Future<SportsStandings?> _downloadStandings(SportsLeague league) async {
    final db = league.sportsDbId != null;
    final url = db
        ? SportsDbSource.tableUrl(league)
        : Uri.parse('$_standingsBase/${league.espnPath}/standings'
            '${league.espnGroup == null ? '' : '?group=${league.espnGroup}'}');
    try {
      if (league.isCfl) {
        final table = await _cfl.standings();
        _standingsCache[league.id] = (table, DateTime.now());
        return table;
      }
      final response = await _get(league, url);
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final standings = await compute(
          db ? parseSportsDbTable : parseEspnStandings,
          (response.body, league));
      _standingsCache[league.id] = (standings, DateTime.now());
      return standings;
    } catch (e) {
      debugPrint('SportsService: ${league.id} standings failed: $e');
      return _standingsCache[league.id]?.$1;
    }
  }

  final Map<String, (SportsTeamSchedule, DateTime)> _scheduleCache = {};
  final Map<String, Future<SportsTeamSchedule?>> _scheduleInFlight = {};

  /// [teamId]'s whole season (My Teams): record, standing line and every
  /// game. Null when ESPN can't be reached and nothing is cached. One call
  /// per team (two for soccer: ESPN only returns played games unless asked
  /// for `fixture=true`, which returns only the upcoming ones).
  Future<SportsTeamSchedule?> teamSchedule(SportsLeague league, String teamId) {
    final key = '${league.id}|$teamId';
    final cached = _scheduleCache[key];
    if (cached != null) {
      final live = cached.$1.games.any((g) => g.state == GameState.live);
      final nearCflGame = league.isCfl &&
          cached.$1.games.any((g) =>
              g.state == GameState.pre &&
              g.start.difference(DateTime.now()).abs() <
                  const Duration(minutes: 30));
      final age = DateTime.now().difference(cached.$2);
      if (age <
          (live || nearCflGame
              ? const Duration(seconds: 50)
              : const Duration(minutes: 10))) {
        return Future.value(cached.$1);
      }
    }
    return _scheduleInFlight[key] ??=
        _downloadSchedule(league, teamId, key).whenComplete(() {
      _scheduleInFlight.remove(key);
    });
  }

  Future<SportsTeamSchedule?> _downloadSchedule(
      SportsLeague league, String teamId, String key) async {
    if (league.isCfl) {
      try {
        final schedule = await _cfl.teamSchedule(teamId);
        if (schedule != null) {
          _scheduleCache[key] = (schedule, DateTime.now());
        }
        return schedule;
      } catch (e) {
        debugPrint('SportsService: CFL team $teamId schedule failed: $e');
        return _scheduleCache[key]?.$1;
      }
    }
    if (league.sportsDbId != null) {
      return _downloadDbSchedule(league, teamId, key);
    }
    final base = '$_base/${league.espnPath}/teams/$teamId/schedule';
    try {
      final responses = await Future.wait([
        _client.get(Uri.parse(base)).timeout(const Duration(seconds: 15)),
        if (league.soccer)
          _client
              .get(Uri.parse('$base?fixture=true'))
              .timeout(const Duration(seconds: 15)),
      ]);
      for (final r in responses) {
        if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      }
      // A hockey season is ~1 MB of JSON — parsed off the UI isolate.
      final schedule = await compute(
          parseEspnTeamSchedule, ([for (final r in responses) r.body], league));
      if (schedule == null) throw Exception('no team in response');
      _scheduleCache[key] = (schedule, DateTime.now());
      return schedule;
    } catch (e) {
      debugPrint(
          'SportsService: ${league.id} team $teamId schedule failed: $e');
      return _scheduleCache[key]?.$1;
    }
  }

  final Map<String, (SportsTeamSchedule, DateTime)> _seasonCache = {};

  /// [teamId]'s whole season in every competition (the Schedule calendar).
  /// Soccer reads ESPN's `soccer/all` team schedule, so cups (FA Cup,
  /// Carabao Cup, Champions League…) come with the league games, each
  /// [SportsGame.league] being its own competition. Other sports and the
  /// non-ESPN sources are [teamSchedule].
  Future<SportsTeamSchedule?> teamSeason(
      SportsLeague league, String teamId) async {
    if (!league.soccer || league.isCfl || league.sportsDbId != null) {
      return teamSchedule(league, teamId);
    }
    final key = '${league.id}|$teamId';
    final cached = _seasonCache[key];
    if (cached != null &&
        DateTime.now().difference(cached.$2) < const Duration(minutes: 10)) {
      return cached.$1;
    }
    final base = '$_base/soccer/all/teams/$teamId/schedule';
    try {
      final responses = await Future.wait([
        for (final url in [base, '$base?fixture=true'])
          _client.get(Uri.parse(url)).timeout(const Duration(seconds: 15)),
      ]);
      for (final r in responses) {
        if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      }
      final schedule = await compute(
          parseEspnTeamSchedule, ([for (final r in responses) r.body], league));
      if (schedule == null) throw Exception('no team in response');
      _seasonCache[key] = (schedule, DateTime.now());
      return schedule;
    } catch (e) {
      debugPrint('SportsService: ${league.id} team $teamId season failed: $e');
      return _seasonCache[key]?.$1 ?? await teamSchedule(league, teamId);
    }
  }

  /// [teamSchedule] for a TheSportsDB league: the free key gives only the
  /// last and the next game; the table line when the team is in its top 5.
  Future<SportsTeamSchedule?> _downloadDbSchedule(
      SportsLeague league, String teamId, String key) async {
    try {
      final responses = await Future.wait([
        for (final url in SportsDbSource.teamUrls(teamId)) _get(league, url),
      ]);
      final games = <SportsGame>[];
      for (final r in responses) {
        if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
        games.addAll(await compute(parseSportsDbEvents, (r.body, league)));
      }
      games.sort((a, b) => a.start.compareTo(b.start));
      final rows = [
        for (final g in (await standings(league))?.groups ?? const [])
          ...g.rows,
      ];
      final row = rows.where((r) => r.team.id == teamId).firstOrNull;
      final team = row?.team ??
          [
            for (final g in games) ...[g.home, g.away]
          ].where((t) => t.id == teamId).firstOrNull;
      if (team == null) throw Exception('no team in response');
      final schedule = SportsTeamSchedule(
        league: league,
        team: team,
        games: games,
        standingSummary:
            row == null ? null : '${_ordinal(row.position)} in ${league.name}',
      );
      _scheduleCache[key] = (schedule, DateTime.now());
      return schedule;
    } catch (e) {
      debugPrint(
          'SportsService: ${league.id} team $teamId schedule failed: $e');
      return _scheduleCache[key]?.$1;
    }
  }

  static String _ordinal(int n) {
    final suffix = n % 100 >= 11 && n % 100 <= 13
        ? 'th'
        : switch (n % 10) { 1 => 'st', 2 => 'nd', 3 => 'rd', _ => 'th' };
    return '$n$suffix';
  }

  /// Sources without a box score show the teams' available standings.
  Future<SportsGameSummary?> _tableSummary(SportsGame game) async {
    final table = await standings(game.league);
    final ids = {game.home.id, game.away.id};
    final keys = game.league.isCfl
        ? const ['gamesPlayed', 'wins', 'losses', 'ties', 'points']
        : const ['gamesPlayed', 'wins', 'ties', 'losses', 'points'];
    return SportsGameSummary(tables: [
      for (final g in table?.groups ?? const <SportsStandingGroup>[])
        if (g.rows.any((r) => ids.contains(r.team.id)))
          SportsSummaryTable(
            title: tr(g.name),
            labels: game.league.isCfl
                ? const ['GP', 'W', 'L', 'T', 'PTS']
                : const ['GP', 'W', 'D', 'L', 'PTS'],
            rows: [
              for (final r in g.rows)
                (
                  r.team.id,
                  r.team.name,
                  [
                    for (final k in keys) r.stat(k),
                  ],
                ),
            ],
          ),
    ]);
  }

  final Map<String, (SportsGameSummary, DateTime)> _summaryCache = {};
  final Map<String, Future<SportsGameSummary?>> _summaryInFlight = {};

  /// One game's box score, leaders, injuries and its teams' standings (the
  /// live list's detail pop-up). One call per opened game, cached 30 s
  /// while it's live. Null when ESPN can't be reached and nothing is cached.
  /// [fresh]: skip the cache (a goal alert needs the goal just scored).
  Future<SportsGameSummary?> gameSummary(SportsGame game,
      {bool fresh = false}) {
    if (game.league.sportsDbId != null ||
        (game.league.isCfl && game.statusText == 'Score unavailable')) {
      return _tableSummary(game);
    }
    final key = '${game.league.id}|${game.id}';
    final cached = _summaryCache[key];
    if (!fresh &&
        cached != null &&
        DateTime.now().difference(cached.$2) <
            (game.state == GameState.live
                ? const Duration(seconds: 30)
                : const Duration(minutes: 10))) {
      return Future.value(cached.$1);
    }
    return _summaryInFlight[key] ??= () async {
      if (game.league.isCfl) {
        try {
          final results = await Future.wait([
            _cfl.gameSummary(game),
            _tableSummary(game),
          ]);
          final details = results[0]!;
          final previous = _summaryCache[key]?.$1;
          // One feed can fail while the other updates. Keep the last
          // available box score instead of blanking it on a transient error.
          final summary = SportsGameSummary(
            teamStats: details.teamStats.isNotEmpty
                ? details.teamStats
                : previous?.teamStats ?? const [],
            players: details.players.isNotEmpty
                ? details.players
                : previous?.players ?? const {},
            tables: results[1]?.tables ?? previous?.tables ?? const [],
          );
          _summaryCache[key] = (summary, DateTime.now());
          return summary;
        } catch (e) {
          debugPrint('SportsService: CFL summary ${game.id} failed: $e');
          return _summaryCache[key]?.$1 ?? await _tableSummary(game);
        }
      }
      final url =
          Uri.parse('$_base/${game.league.espnPath}/summary?event=${game.id}');
      // It's ~40 KB gzipped and answers in well under a second, so a slow
      // try is a stuck connection, not a big download: give up after 6 s
      // and retry once (the owner's Formuler took ~30 s to fill the
      // pop-up with one 15 s try).
      for (var attempt = 1; attempt <= 2; attempt++) {
        final watch = Stopwatch()..start();
        try {
          final response =
              await _client.get(url).timeout(const Duration(seconds: 6));
          if (response.statusCode != 200) {
            throw Exception('HTTP ${response.statusCode}');
          }
          final httpMs = watch.elapsedMilliseconds;
          // ~400 KB of JSON: parsed off the UI isolate.
          final summary = await compute(
              parseEspnSummary, (response.body, game.home.id, game.away.id));
          debugPrint('SportsService: summary ${game.id} try $attempt: '
              'http ${httpMs}ms ${response.bodyBytes.length}B, '
              'parse ${watch.elapsedMilliseconds - httpMs}ms');
          _summaryCache[key] = (summary, DateTime.now());
          return summary;
        } catch (e) {
          debugPrint('SportsService: ${game.league.id} summary ${game.id} '
              'try $attempt after ${watch.elapsedMilliseconds}ms: $e');
        }
      }
      return _summaryCache[key]?.$1;
    }()
        .whenComplete(() {
      // A block, not `=> remove(key)`: remove returns this very future, and
      // whenComplete waits for a returned future — so it waited on itself
      // forever and the pop-up only filled at its 30 s refresh.
      _summaryInFlight.remove(key);
    });
  }

  /// Starts [gameSummary] for a row the user is resting on, so OK opens the
  /// pop-up already filled. Cached/in-flight games cost nothing.
  void prefetchSummary(SportsGame game) => unawaited(gameSummary(game));

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static String _espnDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}'
      '${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';

  final Map<String, (List<DateTime>, DateTime)> _windowStarts = {};

  /// Start of [league]'s first game on or after the local day [from], from
  /// ESPN's dateless scoreboard (the league's current or next round). Lets
  /// an empty day offer "Next game: ..." — cups and off-season leagues can
  /// go weeks without a game. Null when ESPN lists nothing upcoming.
  Future<DateTime?> nextGameStart(SportsLeague league, DateTime from) async {
    final day = DateTime(from.year, from.month, from.day);
    if (league.isCfl) {
      final starts = [
        for (final game in await _cflGames())
          if (game.state != GameState.post &&
              !game.start.toLocal().isBefore(day))
            game.start.toLocal(),
      ]..sort();
      return starts.firstOrNull;
    }
    var hit = _windowStarts[league.id];
    if (hit == null ||
        DateTime.now().difference(hit.$2) > const Duration(minutes: 30)) {
      try {
        // Event sports' dateless scoreboard is the *last* event (UFC showed
        // last week's card, so "no upcoming games"); a 60-day range lists
        // what's next. Team leagues keep the dateless call — a range there
        // is hundreds of games (NHL's failed outright).
        final db = league.sportsDbId != null;
        final range = league.kind == SportsKind.team
            ? _groupQuery(league, '?')
            : '?dates=${_espnDate(day)}-${_espnDate(day.add(const Duration(days: 60)))}';
        final response = await _get(
            league,
            db
                ? SportsDbSource.nextUrl(league)
                : Uri.parse('$_base/${league.espnPath}/scoreboard$range'));
        if (response.statusCode != 200) return null;
        final games = await compute(
            db ? parseSportsDbEvents : parseEspnScoreboard,
            (response.body, league));
        hit = ([for (final g in games) g.start.toLocal()], DateTime.now());
        _windowStarts[league.id] = hit;
      } catch (e) {
        debugPrint('SportsService: ${league.id} next game failed: $e');
        return null;
      }
    }
    final upcoming = [
      for (final s in hit.$1)
        if (!s.isBefore(day)) s
    ]..sort();
    return upcoming.firstOrNull;
  }

  Future<List<SportsGame>> _fetch(SportsLeague league, DateTime date) {
    final key = '${league.id}|${_espnDate(date)}';
    final cached = _cache[key];
    if (cached != null && !cached.isStale(date, _today())) {
      return Future.value(cached.games);
    }
    return _inFlight[key] ??= _download(league, date, key).whenComplete(() {
      _inFlight.remove(key);
    });
  }

  /// TheSportsDB's day call stops at [SportsDbSource.dayCap] games: a day at
  /// the cap gets the rest from its whole round(s), cut to that UTC day.
  /// The day's own list stands if a round can't be loaded.
  Future<List<SportsGame>> _completeCappedDay(SportsLeague league,
      DateTime date, String body, List<SportsGame> games) async {
    final byId = {for (final g in games) g.id: g};
    for (final url in SportsDbSource.roundUrls(league, body)) {
      try {
        final round = await _roundBody(league, url);
        if (round == null) continue;
        for (final g in await compute(parseSportsDbEvents, (round, league))) {
          final s = g.start.toUtc();
          if (s.year == date.year &&
              s.month == date.month &&
              s.day == date.day) {
            byId.putIfAbsent(g.id, () => g);
          }
        }
      } catch (e) {
        debugPrint('SportsService: ${league.id} round failed: $e');
      }
    }
    return byId.values.toList()..sort((a, b) => a.start.compareTo(b.start));
  }

  /// A round is fetched for each capped day around the one shown (see
  /// [gamesForDay]) — the same URL, so it's shared for 2 minutes.
  final Map<Uri, (Future<String?>, DateTime)> _rounds = {};

  Future<String?> _roundBody(SportsLeague league, Uri url) {
    final hit = _rounds[url];
    if (hit != null &&
        DateTime.now().difference(hit.$2) < const Duration(minutes: 2)) {
      return hit.$1;
    }
    final body =
        _get(league, url).then((r) => r.statusCode == 200 ? r.body : null);
    _rounds[url] = (body, DateTime.now());
    body.catchError((_) {
      _rounds.remove(url);
      return null;
    });
    return body;
  }

  Future<List<SportsGame>> _download(
      SportsLeague league, DateTime date, String key) async {
    final db = league.sportsDbId != null;
    // TheSportsDB buckets by UTC date, ESPN by US Eastern; either way the
    // days either side are fetched too (see [gamesForDay]).
    final url = db
        ? SportsDbSource.dayUrl(league, date)
        : Uri.parse(
            '$_base/${league.espnPath}/scoreboard?dates=${_espnDate(date)}'
            '${_groupQuery(league, '&')}');
    try {
      final response = await _get(league, url);
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final body = response.body;
      // A busy NFL Sunday is a few hundred KB of JSON — decoded off the UI
      // isolate so the screen keeps responding on a weak box.
      final parsed = await compute(_parseDaySchedule, (body, league));
      var games = parsed.$1;
      if (db) games = await _completeCappedDay(league, date, body, games);
      _cache[key] =
          _CacheEntry(games, DateTime.now(), sportsDb: db, reliable: parsed.$2);
      _failedScheduleKeys.remove(key);
      lastError = null;
      return games;
    } catch (e) {
      debugPrint('SportsService: ${league.id} ${_espnDate(date)} failed: $e');
      _failedScheduleKeys.add(key);
      lastError = tr('Some scores could not be loaded. Check the connection.');
      return _cache[key]?.games ?? const [];
    }
  }
}

class _CacheEntry {
  _CacheEntry(this.games, this.fetchedAt,
      {this.sportsDb = false, this.reliable = false});
  final List<SportsGame> games;
  final DateTime fetchedAt;
  final bool reliable;

  /// TheSportsDB's free tier allows 30 requests a minute: live days
  /// refresh every 2 minutes instead of every 50 s.
  final bool sportsDb;

  bool isStale(DateTime espnDate, DateTime today) {
    final age = DateTime.now().difference(fetchedAt);
    final live = games.any((g) => g.state == GameState.live);
    final startsSoon = games.any((g) =>
        g.state == GameState.pre &&
        g.start.difference(DateTime.now().toUtc()).inMinutes < 30);
    if (live || startsSoon) {
      return age > Duration(seconds: sportsDb ? 120 : 50);
    }
    final d = DateTime(espnDate.year, espnDate.month, espnDate.day);
    if (d.isBefore(DateTime(today.year, today.month, today.day - 1))) {
      return age > const Duration(hours: 6);
    }
    return age > const Duration(minutes: 10);
  }
}

/// Decode/validate on the same worker as the existing parsers. An absent or
/// malformed events field must not be interpreted as a confirmed empty day.
(List<SportsGame>, bool) _parseDaySchedule((String, SportsLeague) args) {
  final (body, league) = args;
  final db = league.sportsDbId != null;
  final value = jsonDecode(body);
  final games =
      db ? parseSportsDbEvents(args) : _parseEspnEvents(value, league);
  final events = value is Map ? value['events'] : null;
  final known = events is List
      ? events.isEmpty || games.isNotEmpty
      : db && value is Map && value.containsKey('events') && events == null;
  return (games, known);
}

/// Top-level so [compute] can run it on a background isolate.
@visibleForTesting
List<SportsGame> parseEspnScoreboard((String, SportsLeague) args) {
  final (body, league) = args;
  return _parseEspnEvents(jsonDecode(body), league);
}

List<SportsGame> _parseEspnEvents(dynamic json, SportsLeague league) {
  if (json is! Map<String, dynamic>) return const [];
  final events = json['events'];
  if (events is! List) return const [];
  final games = <SportsGame>[];
  for (final e in events) {
    try {
      final m = e as Map<String, dynamic>;
      switch (league.kind) {
        case SportsKind.team:
          final game = _parseEvent(m, league);
          if (game != null) games.add(game);
        case SportsKind.golf:
          final game = _parseGolf(m, league);
          if (game != null) games.add(game);
        case SportsKind.racing:
          games.addAll(_parseRacing(m, league));
        case SportsKind.fight:
          final game = _parseFightCard(m, league);
          if (game != null) games.add(game);
        case SportsKind.tennis:
          games.addAll(_parseTennis(m, league));
      }
    } catch (_) {
      // One malformed event shouldn't drop the whole league.
    }
  }
  return games;
}

// ------------------------------------------------------------ event sports

GameState _stateOf(Map<String, dynamic>? status) =>
    switch ((status?['type'] as Map?)?['state']) {
      'in' => GameState.live,
      'post' => GameState.post,
      _ => GameState.pre,
    };

String _statusTextOf(Map<String, dynamic>? status) {
  final type = status?['type'] as Map?;
  return (type?['shortDetail'] ?? type?['detail'] ?? '').toString();
}

List<String> _broadcastsOf(Iterable<Map<String, dynamic>> comps) {
  final out = <String>{};
  for (final comp in comps) {
    for (final b in (comp['broadcasts'] as List?) ?? const []) {
      for (final n in ((b as Map)['names'] as List?) ?? const []) {
        out.add(n.toString());
      }
    }
    for (final g in (comp['geoBroadcasts'] as List?) ?? const []) {
      final name = ((g as Map)['media'] as Map?)?['shortName']?.toString();
      if (name != null && name.isNotEmpty) out.add(name);
    }
  }
  return out.toList();
}

String? _venueOf(Map<String, dynamic> e, Map<String, dynamic>? comp) {
  Object? v = e['circuit'] ?? comp?['venue'] ?? e['venues'];
  if (v is List) v = v.isEmpty ? null : v.first;
  if (v is! Map) return null;
  final name = v['fullName']?.toString();
  final city = (v['address'] as Map?)?['city']?.toString();
  if (name == null || name.isEmpty) return city;
  return city == null || city.isEmpty || name.contains(city)
      ? name
      : '$name, $city';
}

List<Map<String, dynamic>> _competitorsByOrder(Map<String, dynamic> comp) {
  final list = [
    for (final c in (comp['competitors'] as List?) ?? const [])
      (c as Map).cast<String, dynamic>()
  ];
  int order(Map<String, dynamic> c) => (c['order'] as num?)?.toInt() ?? 1 << 20;
  list.sort((a, b) => order(a).compareTo(order(b)));
  return list;
}

String? _flagOf(Map<String, dynamic> c) =>
    ((c['athlete'] as Map?)?['flag'] as Map?)?['href']?.toString();

String _athleteName(Map<String, dynamic> c, {bool short = false}) {
  final a = (c['athlete'] as Map?) ?? const {};
  return ((short ? a['shortName'] : null) ??
          a['displayName'] ??
          a['fullName'] ??
          '')
      .toString();
}

/// Golf and racing have no sides; the cards read the event instead, but the
/// rest of the tab (glow, picks, search) still expects two teams.
SportsTeam _placeholderSide(SportsLeague league, String title) => SportsTeam(
      id: '',
      name: title,
      shortName: title,
      abbreviation: league.shortName,
      logoUrl: league.logoUrl,
    );

SportsGame? _parseGolf(Map<String, dynamic> e, SportsLeague league) {
  final comp = ((e['competitions'] as List?)?.firstOrNull as Map?)
      ?.cast<String, dynamic>();
  if (comp == null) return null;
  final status = (comp['status'] ?? e['status']) as Map<String, dynamic>?;
  final state = _stateOf(status);
  final title = (e['name'] ?? '').toString();
  final players = _competitorsByOrder(comp);
  // Ties share a place ("T3"), the way every leaderboard shows them.
  final leaders = <SportsEventEntry>[];
  if (state != GameState.pre) {
    for (var i = 0; i < players.length && leaders.length < 5; i++) {
      final score = players[i]['score']?.toString();
      var first = i;
      while (first > 0 && players[first - 1]['score']?.toString() == score) {
        first--;
      }
      final tied = (i + 1 < players.length &&
              players[i + 1]['score']?.toString() == score) ||
          first != i;
      leaders.add(SportsEventEntry(
        position: '${tied ? 'T' : ''}${first + 1}',
        name: _athleteName(players[i], short: true),
        flagUrl: _flagOf(players[i]),
        value: score,
      ));
    }
  }
  final round = (status?['period'] as num?)?.toInt();
  final side = _placeholderSide(league, title);
  final endRaw = e['endDate']?.toString();
  return SportsGame(
    id: e['id'].toString(),
    league: league,
    start: DateTime.parse((e['date'] ?? comp['date']).toString()).toUtc(),
    end: endRaw == null ? null : DateTime.tryParse(endRaw)?.toUtc(),
    state: state,
    statusText: state == GameState.pre ? '' : _statusTextOf(status),
    home: side,
    away: side,
    broadcasts: _broadcastsOf([comp]),
    event: SportsEventInfo(
      title: title,
      session: state != GameState.pre && round != null && round > 0
          ? 'Round $round'
          : null,
      venue: _venueOf(e, comp),
      leaders: leaders,
    ),
  );
}

/// ESPN's session abbreviations. Practice sessions are left out: they'd
/// triple the cards of a race weekend for something few people tune in to.
const Map<String, String?> _racingSessions = {
  'FP1': null,
  'FP2': null,
  'FP3': null,
  'SS': 'Sprint Qualifying',
  'SR': 'Sprint',
  'Qual': 'Qualifying',
  'Race': 'Race',
};

List<SportsGame> _parseRacing(Map<String, dynamic> e, SportsLeague league) {
  final title = (e['name'] ?? '').toString();
  final side = _placeholderSide(league, title);
  final out = <SportsGame>[];
  for (final raw in (e['competitions'] as List?) ?? const []) {
    final comp = (raw as Map).cast<String, dynamic>();
    final abbr = (comp['type'] as Map?)?['abbreviation']?.toString();
    // NASCAR/IndyCar events are one untyped competition: the race.
    final session = abbr == null
        ? 'Race'
        : (_racingSessions.containsKey(abbr) ? _racingSessions[abbr] : abbr);
    if (session == null) continue;
    final status = (comp['status'] ?? e['status']) as Map<String, dynamic>?;
    final state = _stateOf(status);
    final drivers = _competitorsByOrder(comp);
    out.add(SportsGame(
      id: (comp['id'] ?? e['id']).toString(),
      league: league,
      start: DateTime.parse((comp['date'] ?? e['date']).toString()).toUtc(),
      state: state,
      statusText: _statusTextOf(status),
      home: side,
      away: side,
      broadcasts: _broadcastsOf([comp]),
      event: SportsEventInfo(
        title: title,
        session: session,
        venue: _venueOf(e, comp),
        // Before the start the order is just the entry list.
        leaders: state == GameState.pre
            ? const []
            : [
                for (var i = 0; i < drivers.length && i < 5; i++)
                  SportsEventEntry(
                    position: '${i + 1}',
                    name: _athleteName(drivers[i], short: true),
                    flagUrl: _flagOf(drivers[i]),
                  ),
              ],
      ),
    ));
  }
  return out;
}

/// A tennis tournament is one ESPN event with `groupings` (Men's Singles,
/// Women's Doubles…), each listing every match of the tournament. Each
/// main-draw singles match becomes a card ([gamesForDay] keeps the day's):
/// doubles (no athlete per side) and qualifying rounds are left out — a
/// tournament day would otherwise be 50+ cards. Score = sets won.
List<SportsGame> _parseTennis(Map<String, dynamic> e, SportsLeague league) {
  final tournament = (e['name'] ?? '').toString();
  final out = <SportsGame>[];
  for (final g in (e['groupings'] as List?) ?? const []) {
    final grouping =
        ((g as Map)['grouping'] as Map?)?['displayName']?.toString() ?? '';
    if (!grouping.toLowerCase().contains('singles')) continue;
    for (final c in (g['competitions'] as List?) ?? const []) {
      final comp = (c as Map).cast<String, dynamic>();
      final round = ((comp['round'] as Map?)?['displayName'] ?? '').toString();
      if (round.toLowerCase().contains('qualif')) continue;
      final players = _competitorsByOrder(comp);
      if (players.length != 2 || players.any((p) => p['athlete'] is! Map)) {
        continue;
      }
      final date = DateTime.tryParse((comp['date'] ?? '').toString());
      if (date == null) continue;
      final status = comp['status'] as Map<String, dynamic>?;
      final state = _stateOf(status);
      List<num> sets(Map<String, dynamic> p) => [
            for (final l in (p['linescores'] as List?) ?? const [])
              ((l as Map)['value'] as num?) ?? 0,
          ];
      final a = sets(players[0]), b = sets(players[1]);
      int won(List<num> mine, List<num> theirs) {
        var n = 0;
        for (var i = 0; i < mine.length && i < theirs.length; i++) {
          // A set still being played counts once it's over (6+ games, 2 up,
          // or 7 after a tie-break) — otherwise only finished matches.
          final done = state == GameState.post || i < mine.length - 1;
          if (done && mine[i] > theirs[i]) n++;
        }
        return n;
      }

      SportsTeam player(Map<String, dynamic> p, int setsWon) {
        final full = _athleteName(p);
        return SportsTeam(
          id: ((p['athlete'] as Map?)?['id'] ?? p['id'] ?? full).toString(),
          name: full,
          shortName: full,
          abbreviation: full
              .split(' ')
              .where((w) => w.isNotEmpty)
              .map((w) => w[0])
              .take(2)
              .join()
              .toUpperCase(),
          logoUrl: _flagOf(p),
          score: state == GameState.pre ? null : '$setsWon',
        );
      }

      out.add(SportsGame(
        id: comp['id'].toString(),
        league: league,
        start: date.toUtc(),
        state: state,
        statusText: _statusTextOf(status),
        home: player(players[0], won(a, b)),
        away: player(players[1], won(b, a)),
        broadcasts: _broadcastsOf([comp]),
        event: SportsEventInfo(
          title: tournament,
          session: round.isEmpty ? grouping : round,
          venue: _venueOf(e, comp),
        ),
      ));
    }
  }
  return out;
}

/// A fight card is one ESPN event with a competition per fight. The card
/// shows the main event: the fight whose two names are in the event's name
/// ("UFC Fight Night: Allen vs. Duncan"), else the last one listed.
SportsGame? _parseFightCard(Map<String, dynamic> e, SportsLeague league) {
  final comps = [
    for (final c in (e['competitions'] as List?) ?? const [])
      (c as Map).cast<String, dynamic>()
  ];
  if (comps.isEmpty) return null;
  final name = (e['name'] ?? '').toString();
  final lowerName = name.toLowerCase();
  bool billed(Map<String, dynamic> comp) {
    final fighters = (comp['competitors'] as List?) ?? const [];
    return fighters.length == 2 &&
        fighters.every((f) {
          final full = _athleteName((f as Map).cast<String, dynamic>());
          final parts = full.toLowerCase().split(' ');
          return parts.isNotEmpty && lowerName.contains(parts.last);
        });
  }

  final main = comps.where(billed).lastOrNull ?? comps.last;
  final fighters = _competitorsByOrder(main);
  if (fighters.length != 2) return null;
  final status = (e['status'] ?? main['status']) as Map<String, dynamic>?;
  final mainState = _stateOf(main['status'] as Map<String, dynamic>?);
  SportsTeam fighter(Map<String, dynamic> c) {
    final full = _athleteName(c);
    final records = c['records'] as List?;
    return SportsTeam(
      id: ((c['athlete'] as Map?)?['id'] ?? c['id'] ?? full).toString(),
      name: full,
      shortName: full,
      abbreviation: full
          .split(' ')
          .where((w) => w.isNotEmpty)
          .map((w) => w[0])
          .take(2)
          .join()
          .toUpperCase(),
      logoUrl: _flagOf(c),
      record: (records != null && records.isNotEmpty)
          ? (records.first as Map)['summary']?.toString()
          : null,
      // W / L once the main event is decided (no score in MMA). A draw or
      // no contest has no winner, so no letters.
      score: mainState == GameState.post &&
              fighters.any((f) => f['winner'] == true)
          ? (c['winner'] == true ? 'W' : 'L')
          : null,
    );
  }

  DateTime start =
      DateTime.parse((comps.first['date'] ?? e['date']).toString());
  for (final c in comps) {
    final d = DateTime.tryParse((c['date'] ?? '').toString());
    if (d != null && d.isBefore(start)) start = d;
  }
  final type = main['type'] as Map?;
  final weightClass = (type?['text'] ?? type?['abbreviation'])?.toString();
  return SportsGame(
    id: e['id'].toString(),
    league: league,
    start: start.toUtc(),
    state: _stateOf(status),
    statusText: _statusTextOf(status),
    home: fighter(fighters[0]),
    away: fighter(fighters[1]),
    broadcasts: _broadcastsOf(comps),
    event: SportsEventInfo(
      title: name,
      session: weightClass,
      venue: _venueOf(e, null),
    ),
  );
}

/// Top-level so [compute] can run it on a background isolate. [bodies] are
/// the team schedule responses (soccer: results + fixtures); events are
/// merged by id and sorted oldest first. Null when there's no team.
@visibleForTesting
SportsTeamSchedule? parseEspnTeamSchedule((List<String>, SportsLeague) args) {
  final (bodies, league) = args;
  Map<String, dynamic>? teamJson;
  final byId = <String, SportsGame>{};
  for (final body in bodies) {
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic>) continue;
    teamJson ??= (json['team'] as Map?)?.cast<String, dynamic>();
    for (final e in (json['events'] as List?) ?? const []) {
      try {
        final event = e as Map<String, dynamic>;
        final game = _parseEvent(event, _eventLeague(event, league));
        if (game != null) byId[game.id] = game;
      } catch (_) {
        // One malformed event shouldn't drop the season.
      }
    }
  }
  if (teamJson == null || teamJson['id'] == null) return null;
  final t = teamJson;
  final name = (t['displayName'] ?? t['name'] ?? '').toString();
  final team = SportsTeam(
    id: t['id'].toString(),
    name: name,
    shortName: (t['shortDisplayName'] ?? t['name'] ?? name).toString(),
    abbreviation: (t['abbreviation'] ?? '').toString(),
    logoUrl: t['logo']?.toString(),
    color: t['color']?.toString(),
    record: t['recordSummary']?.toString(),
  );
  // Schedule events leave out team colours; give the followed team its own
  // so the cards and glow match the rest of the tab.
  SportsTeam withColor(SportsTeam s) => s.id != team.id || s.color != null
      ? s
      : SportsTeam(
          id: s.id,
          name: s.name,
          shortName: s.shortName,
          abbreviation: s.abbreviation,
          logoUrl: s.logoUrl,
          color: team.color,
          record: s.record,
          score: s.score,
        );
  final games = [
    for (final g in byId.values)
      SportsGame(
        id: g.id,
        league: g.league,
        start: g.start,
        state: g.state,
        statusText: g.statusText,
        home: withColor(g.home),
        away: withColor(g.away),
        broadcasts: g.broadcasts,
      ),
  ]..sort((a, b) => a.start.compareTo(b.start));
  return SportsTeamSchedule(
    league: league,
    team: team,
    games: games,
    standingSummary: t['standingSummary']?.toString(),
  );
}

/// The competition of a soccer team-schedule event: `soccer/all` mixes the
/// league with cups, each event naming its own (`league.slug`). A known
/// league/cup keeps its entry (logo, channel terms, game details path);
/// another one gets a plain entry from the event.
SportsLeague _eventLeague(Map<String, dynamic> e, SportsLeague league) {
  final l = e['league'];
  if (!league.soccer || l is! Map) return league;
  final slug = l['slug']?.toString();
  if (slug == null || slug.isEmpty || slug == league.id) return league;
  final known = sportsLeagueById(slug);
  if (known != null) return known;
  final name = (l['name'] ?? l['abbreviation'] ?? slug).toString();
  final logoId = l['alternateId']?.toString();
  return SportsLeague(
    id: slug,
    espnPath: 'soccer/$slug',
    name: name,
    shortName: (l['abbreviation'] ?? name).toString(),
    logoUrl: logoId == null
        ? league.logoUrl
        : 'https://a.espncdn.com/i/leaguelogos/soccer/500/$logoId.png',
    soccer: true,
    hasStandings: false,
  );
}

SportsGame? _parseEvent(Map<String, dynamic> e, SportsLeague league) {
  final competitions = e['competitions'] as List?;
  if (competitions == null || competitions.isEmpty) return null;
  final comp = competitions.first as Map<String, dynamic>;
  final competitors = (comp['competitors'] as List?) ?? const [];
  SportsTeam? home;
  SportsTeam? away;
  for (final c in competitors) {
    final m = c as Map<String, dynamic>;
    final team = _parseTeam(m);
    if (m['homeAway'] == 'home') {
      home = team;
    } else {
      away = team;
    }
  }
  if (home == null || away == null) return null;

  final status = (comp['status'] ?? e['status']) as Map<String, dynamic>?;
  final type = status?['type'] as Map<String, dynamic>?;
  final state = switch (type?['state']) {
    'in' => GameState.live,
    'post' => GameState.post,
    _ => GameState.pre,
  };

  final broadcasts = <String>{};
  for (final b in (comp['broadcasts'] as List?) ?? const []) {
    final m = b as Map;
    for (final n in (m['names'] as List?) ?? const []) {
      broadcasts.add(n.toString());
    }
    // Team schedules list `{media: {shortName}}` instead of `names`.
    final media = (m['media'] as Map?)?['shortName']?.toString();
    if (media != null && media.isNotEmpty) broadcasts.add(media);
  }
  for (final g in (comp['geoBroadcasts'] as List?) ?? const []) {
    final name = ((g as Map)['media'] as Map?)?['shortName']?.toString();
    if (name != null && name.isNotEmpty) broadcasts.add(name);
  }

  return SportsGame(
    id: e['id'].toString(),
    league: league,
    start: DateTime.parse((comp['date'] ?? e['date']).toString()).toUtc(),
    state: state,
    statusText: (type?['shortDetail'] ?? type?['detail'] ?? '').toString(),
    home: home,
    away: away,
    broadcasts: broadcasts.toList(),
    leaders: _scoreboardLeaders(comp, competitors),
    situation: state == GameState.live
        ? _situationOf(comp['situation'], league)
        : null,
    odds: state == GameState.post ? null : sportsOddsOf(comp['odds']),
  );
}

/// ESPN's scoreboard `competitions[0].odds` (the first, highest-priority
/// sportsbook). Prefers the current ("close") lines of `moneyline` /
/// `pointSpread` / `total`, else the older flat `homeTeamOdds.moneyLine`.
/// The bet links in it are never kept.
SportsOdds? sportsOddsOf(Object? raw) {
  final o = raw is List && raw.isNotEmpty && raw.first is Map
      ? raw.first as Map
      : null;
  if (o == null) return null;
  String? text(Object? v) {
    if (v is num) {
      if (v == v.roundToDouble()) return v.toInt().toString();
      return v.toString();
    }
    final s = v?.toString().trim();
    return s == null || s.isEmpty ? null : s;
  }

  String? american(Object? v) {
    if (v is num) {
      final n = v.round();
      return n > 0 ? '+$n' : '$n';
    }
    return text(v);
  }

  Map? side(String market, String key) {
    final m = o[market];
    final s = m is Map ? m[key] : null;
    final current = s is Map ? (s['close'] ?? s['current'] ?? s['open']) : null;
    return current is Map ? current : null;
  }

  Map? team(String key) => o[key] is Map ? o[key] as Map : null;
  final provider = o['provider'] is Map
      ? text((o['provider'] as Map)['displayName'] ??
          (o['provider'] as Map)['name'])
      : null;
  final odds = SportsOdds(
    provider: provider,
    details: text(o['details']),
    total: text(o['overUnder']) ??
        side('total', 'over')?['line']?.toString().replaceFirst('o', ''),
    homeMoneyline: american(side('moneyline', 'home')?['odds'] ??
        team('homeTeamOdds')?['moneyLine']),
    awayMoneyline: american(side('moneyline', 'away')?['odds'] ??
        team('awayTeamOdds')?['moneyLine']),
    drawMoneyline: american(
        side('moneyline', 'draw')?['odds'] ?? team('drawOdds')?['moneyLine']),
    homeSpread: text(side('pointSpread', 'home')?['line']),
    awaySpread: text(side('pointSpread', 'away')?['line']),
    homeSpreadOdds: american(side('pointSpread', 'home')?['odds']),
    awaySpreadOdds: american(side('pointSpread', 'away')?['odds']),
    overOdds: american(side('total', 'over')?['odds']),
    underOdds: american(side('total', 'under')?['odds']),
  );
  return odds.isEmpty ? null : odds;
}

/// ESPN's "rating" leader repeats another line ("29 PTS").
const _skippedLeaderStats = {'RAT', 'MLB'};

SportsLeader? _leaderOf(Map category, {String? teamId}) {
  final first = (category['leaders'] as List?)?.firstOrNull as Map?;
  final athlete = first?['athlete'] as Map?;
  if (first == null || athlete == null) return null;
  final name = (athlete['shortName'] ?? athlete['displayName'])?.toString();
  final value = first['displayValue']?.toString();
  if (name == null || value == null || value.isEmpty) return null;
  return SportsLeader(
    stat: (category['shortDisplayName'] ??
            category['abbreviation'] ??
            category['displayName'] ??
            '')
        .toString(),
    name: name,
    value: value,
    teamId: ((first['team'] as Map?)?['id'] ??
            (athlete['team'] as Map?)?['id'] ??
            teamId)
        ?.toString(),
    position: (athlete['position'] as Map?)?['abbreviation']?.toString(),
  );
}

/// Football puts one leader per stat on the competition; hockey/basketball/
/// baseball give each team its own — merged here to the better of the two
/// per stat, in ESPN's order.
List<SportsLeader> _scoreboardLeaders(
    Map<String, dynamic> comp, List competitors) {
  final out = <SportsLeader>[];
  for (final c in (comp['leaders'] as List?) ?? const []) {
    final l = _leaderOf(c as Map);
    if (l != null && !_skippedLeaderStats.contains(l.stat)) out.add(l);
  }
  if (out.isNotEmpty) return out;
  final byStat = <String, (SportsLeader, double)>{};
  final order = <String>[];
  for (final t in competitors) {
    final teamId = (((t as Map)['team'] as Map?)?['id'] ?? t['id'])?.toString();
    for (final c in (t['leaders'] as List?) ?? const []) {
      final l = _leaderOf(c as Map, teamId: teamId);
      if (l == null || _skippedLeaderStats.contains(l.stat)) continue;
      final v =
          ((c['leaders'] as List).first['value'] as num?)?.toDouble() ?? 0;
      final had = byStat[l.stat];
      if (had == null) order.add(l.stat);
      if (had == null || v > had.$2) byStat[l.stat] = (l, v);
    }
  }
  return [for (final s in order) byStat[s]!.$1];
}

SportsSituation? _situationOf(Object? raw, SportsLeague league) {
  if (raw is! Map) return null;
  final lastPlay = (raw['lastPlay'] as Map?)?['text']?.toString();
  String? text = raw['downDistanceText']?.toString();
  if (text == null && raw['outs'] != null) {
    // Baseball: "1-2, 2 out · 1st, 3rd".
    bool on(String k) => raw[k] == true || raw[k] is Map;
    final bases = [
      if (on('onFirst')) '1st',
      if (on('onSecond')) '2nd',
      if (on('onThird')) '3rd',
    ];
    text = [
      if (raw['balls'] != null && raw['strikes'] != null)
        '${raw['balls']}-${raw['strikes']}',
      '${raw['outs']} out',
      if (bases.isNotEmpty) bases.join(', '),
    ].join(' · ');
  }
  final possession = raw['possession']?.toString();
  if (text == null && possession == null && lastPlay == null) return null;
  return SportsSituation(
    text: text,
    possessionTeamId: possession,
    redZone: raw['isRedZone'] == true,
    lastPlay: lastPlay,
  );
}

/// Box-score columns worth a glance, per category, in display order; a
/// category whose labels hit none of them is left out (returns, punting).
const List<List<String>> _boxColumns = [
  ['C/ATT', 'YDS', 'TD', 'INT'], // passing
  ['CAR', 'YDS', 'TD'], // rushing
  ['REC', 'TGTS', 'YDS', 'TD'], // receiving
  ['TOT', 'SACKS', 'TFL'], // defensive
  ['FG', 'XP', 'PTS'], // kicking
  ['MIN', 'PTS', 'REB', 'AST', '3PT', 'STL', 'BLK'], // basketball
  ['G', 'A', 'S', '+/-', 'TOI'], // hockey skaters (S = shots)
  ['SA', 'SV', 'SV%', 'GA'], // goalies
  ['H-AB', 'R', 'HR', 'RBI', 'BB', 'K'], // batting
  ['IP', 'H', 'ER', 'BB', 'K', 'PC'], // pitching
];

const _boxCategories = {
  'passing',
  'rushing',
  'receiving',
  'defensive',
  'kicking',
  'forwards',
  'defenses',
  'goalies',
};

/// Top-level so [compute] can run it on a background isolate.
@visibleForTesting
SportsGameSummary parseEspnSummary((String, String, String) args) {
  final (body, homeId, awayId) = args;
  final json = jsonDecode(body);
  if (json is! Map<String, dynamic>) return const SportsGameSummary();
  final box = json['boxscore'] as Map?;

  // Team stats, away | home.
  final teamStats = <(String, String, String)>[];
  final boxTeams = [
    for (final t in (box?['teams'] as List?) ?? const []) t as Map
  ];
  Map? statsOf(String id) => boxTeams
      .where((t) => (t['team'] as Map?)?['id']?.toString() == id)
      .firstOrNull;
  final away = statsOf(awayId);
  final home = statsOf(homeId);
  if (away != null && home != null) {
    final homeByName = {
      for (final s in (home['statistics'] as List?) ?? const [])
        (s as Map)['name']: s['displayValue']?.toString(),
    };
    for (final s in (away['statistics'] as List?) ?? const []) {
      final m = s as Map;
      final label = (m['label'] ?? m['abbreviation'])?.toString();
      final a = m['displayValue']?.toString();
      final h = homeByName[m['name']];
      if (label == null || a == null || h == null) continue;
      teamStats.add((label, a, h));
    }
  }

  // Box score: per team, a few columns of the top players per category.
  final players = <String, List<SportsPlayerGroup>>{};
  for (final t in (box?['players'] as List?) ?? const []) {
    final teamId = ((t as Map)['team'] as Map?)?['id']?.toString();
    if (teamId == null) continue;
    final groups = <SportsPlayerGroup>[];
    for (final c in (t['statistics'] as List?) ?? const []) {
      final cat = c as Map;
      final labels = [
        for (final l in (cat['labels'] as List?) ?? const []) '$l'
      ];
      final name = cat['name']?.toString();
      final title = name ??
          (labels.contains('IP')
              ? 'pitching'
              : labels.contains('AB')
                  ? 'batting'
                  : 'players');
      if (name != null && !_boxCategories.contains(name)) continue;
      // The column set this category matches best (rushing also has
      // passing's YDS/TD — the first set with two hits dropped CAR).
      List<String>? wanted;
      for (final cols in _boxColumns) {
        final hit = [
          for (final x in cols)
            if (labels.contains(x)) x
        ];
        if (hit.length >= 2 && hit.length > (wanted?.length ?? 0)) {
          wanted = hit;
        }
      }
      if (wanted == null) continue;
      final idx = [for (final x in wanted) labels.indexOf(x)];
      double num0(List s, String label) {
        final i = labels.indexOf(label);
        if (i < 0 || i >= s.length) return 0;
        final v = '${s[i]}'.split(RegExp(r'[-/]')).first;
        return double.tryParse(v) ?? 0;
      }

      double rank(List s) {
        if (labels.contains('G') && labels.contains('A')) {
          return num0(s, 'G') + num0(s, 'A') + num0(s, 'S') / 100;
        }
        for (final k in ['PTS', 'YDS', 'TOT']) {
          if (labels.contains(k)) return num0(s, k);
        }
        if (labels.contains('H-AB')) {
          return num0(s, 'H-AB') + num0(s, 'RBI') + num0(s, 'R') / 2;
        }
        return 0; // pitchers / goalies: ESPN's order (starter first)
      }

      final rows = <(String, List<String>, double)>[];
      for (final a in (cat['athletes'] as List?) ?? const []) {
        final m = a as Map;
        final stats = (m['stats'] as List?) ?? const [];
        if (stats.isEmpty) continue; // DNP
        final ath = m['athlete'] as Map? ?? const {};
        final n = (ath['shortName'] ?? ath['displayName'])?.toString();
        if (n == null) continue;
        rows.add((
          n,
          [for (final i in idx) i < stats.length ? '${stats[i]}' : ''],
          rank(stats)
        ));
      }
      if (rows.isEmpty) continue;
      // Stable: equal ranks keep ESPN's order.
      final indexed = rows.indexed.toList()
        ..sort((x, y) {
          final r = y.$2.$3.compareTo(x.$2.$3);
          return r != 0 ? r : x.$1.compareTo(y.$1);
        });
      final take = switch (title) {
        'players' => 5,
        'passing' || 'kicking' || 'goalies' || 'pitching' => 2,
        _ => 3,
      };
      groups.add(SportsPlayerGroup(
        title: title,
        labels: wanted,
        rows: [for (final r in indexed.take(take)) (r.$2.$1, r.$2.$2)],
      ));
    }
    if (groups.isNotEmpty) players[teamId] = groups;
  }

  // Leaders per team.
  final leaders = <String, List<SportsLeader>>{};
  for (final t in (json['leaders'] as List?) ?? const []) {
    final teamId = ((t as Map)['team'] as Map?)?['id']?.toString();
    if (teamId == null) continue;
    final list = <SportsLeader>[];
    for (final c in (t['leaders'] as List?) ?? const []) {
      final cat = c as Map;
      final l = _leaderOf(cat, teamId: teamId);
      if (l == null) continue;
      list.add(SportsLeader(
          stat: (cat['displayName'] ?? l.stat).toString(),
          name: l.name,
          value: l.value,
          teamId: teamId,
          position: l.position));
    }
    if (list.isNotEmpty) leaders[teamId] = list;
  }

  // Injuries per team (football/basketball list them before and during).
  final injuries = <String, List<SportsInjury>>{};
  for (final t in (json['injuries'] as List?) ?? const []) {
    final teamId = ((t as Map)['team'] as Map?)?['id']?.toString();
    if (teamId == null) continue;
    final list = <SportsInjury>[];
    for (final i in (t['injuries'] as List?) ?? const []) {
      final m = i as Map;
      final ath = m['athlete'] as Map? ?? const {};
      final n = (ath['shortName'] ?? ath['displayName'])?.toString();
      final status = m['status']?.toString();
      if (n == null || status == null) continue;
      list.add(SportsInjury(
        name: n,
        status: status,
        position: (ath['position'] as Map?)?['abbreviation']?.toString(),
        detail: (m['details'] as Map?)?['type']?.toString(),
      ));
    }
    if (list.isNotEmpty) injuries[teamId] = list;
  }

  // Soccer scorers.
  final goals = <SportsGoal>[];
  for (final k in (json['keyEvents'] as List?) ?? const []) {
    final m = k as Map;
    if (m['scoringPlay'] != true) continue;
    final who = (((m['participants'] as List?)?.firstOrNull as Map?)?['athlete']
            as Map?)?['displayName']
        ?.toString();
    if (who == null) continue;
    final type = ((m['type'] as Map?)?['text'] ?? '').toString().toLowerCase();
    goals.add(SportsGoal(
      minute: ((m['clock'] as Map?)?['displayValue'] ?? '').toString(),
      scorer: who,
      teamId: (m['team'] as Map?)?['id']?.toString(),
      penalty: type.contains('penalty'),
    ));
  }

  // Hockey goals: ESPN has no keyEvents there, but every play, goals flagged
  // (user report: 0-4 with only two scorers in the box score's top three).
  // Only plays typed "Goal": basketball's scoring plays are every basket.
  if (goals.isEmpty) {
    for (final p in (json['plays'] as List?) ?? const []) {
      final m = p as Map;
      if (m['scoringPlay'] != true) continue;
      final type = m['type'] as Map?;
      final kind = (type?['abbreviation'] ?? type?['text'] ?? '')
          .toString()
          .toLowerCase();
      if (kind != 'goal') continue;
      String? scorer;
      final assists = <String>[];
      for (final x in (m['participants'] as List?) ?? const []) {
        final part = x as Map;
        final ath = part['athlete'] as Map? ?? const {};
        final n = (ath['shortName'] ?? ath['displayName'])?.toString();
        if (n == null) continue;
        if (part['type'] == 'scorer') {
          scorer = n;
        } else if (part['type'] == 'assister') {
          assists.add(n);
        }
      }
      if (scorer == null) continue;
      final away = m['awayScore'], home = m['homeScore'];
      goals.add(SportsGoal(
        minute: ((m['clock'] as Map?)?['displayValue'] ?? '').toString(),
        scorer: scorer,
        teamId: (m['team'] as Map?)?['id']?.toString(),
        period: (m['period'] as Map?)?['displayValue']?.toString(),
        assists: assists,
        score: away is num && home is num ? '$away-$home' : null,
      ));
    }
  }

  // Standings groups that hold either team: a few columns, wins first.
  const preferred = [
    'overall', 'Total', 'W', 'D', 'L', 'T', 'OTL', 'P', 'PTS', 'PCT', 'GB', //
    'GD', 'CONF', 'STRK',
  ];
  final tables = <SportsSummaryTable>[];
  final groupsJson =
      ((json['standings'] as Map?)?['groups'] as List?) ?? const [];
  for (final g in groupsJson) {
    final gm = g as Map;
    final entries =
        ((gm['standings'] as Map?)?['entries'] as List?) ?? const [];
    final ids = [
      for (final e in entries) ((e as Map)['id'] ?? '').toString(),
    ];
    if (!ids.contains(homeId) && !ids.contains(awayId)) continue;
    final first = entries.isEmpty ? null : entries.first as Map;
    final stats = [
      for (final s in (first?['stats'] as List?) ?? const []) s as Map
    ];
    final cols = [
      for (final p in preferred)
        if (stats.any((s) => s['abbreviation'] == p)) p,
    ].take(5).toList();
    String header(String abbr) {
      final s = stats.firstWhere((s) => s['abbreviation'] == abbr);
      return (s['shortDisplayName'] ?? abbr).toString();
    }

    tables.add(SportsSummaryTable(
      title: (gm['header'] ?? '')
          .toString()
          .replaceFirst(RegExp(r'^\d{4}(-\d{2})?\s+'), '')
          .replaceFirst(RegExp(r'\s+Standings$'), ''),
      labels: [for (final c in cols) header(c)],
      rows: [
        for (final e in entries)
          (
            ((e as Map)['id'] ?? '').toString(),
            (e['team'] ?? '').toString(),
            [
              for (final c in cols)
                ((e['stats'] as List?)
                            ?.cast<Map>()
                            .where((s) => s['abbreviation'] == c)
                            .firstOrNull?['displayValue'] ??
                        '')
                    .toString(),
            ],
          ),
      ],
    ));
  }

  return SportsGameSummary(
    teamStats: teamStats,
    players: players,
    leaders: leaders,
    injuries: injuries,
    goals: goals,
    tables: tables,
  );
}

/// Top-level so [compute] can run it on a background isolate. ESPN nests
/// groups (college conferences hold divisions); every node that carries
/// `standings.entries` becomes one table, in ESPN's order.
@visibleForTesting
SportsStandings parseEspnStandings((String, SportsLeague) args) {
  final (body, league) = args;
  final json = jsonDecode(body);
  final groups = <SportsStandingGroup>[];
  var preseason = false;
  String? season;

  void walk(Map<String, dynamic> node) {
    final standings = node['standings'];
    if (standings is Map && standings['entries'] is List) {
      // Soccer tables always say seasonType 1; only the US leagues use it
      // for exhibition games.
      if (!league.soccer && standings['seasonType'] == 1) preseason = true;
      // The table's own season ("2026" for a finished MLB year — the
      // top-level `season` already says 2027); soccer appends the league
      // name ("2026-27 English Premier League"), keep just the years.
      season ??= RegExp(r'^\d{4}(-\d{2})?')
          .firstMatch(standings['seasonDisplayName']?.toString() ?? '')
          ?.group(0);
      final rows = <SportsStandingRow>[];
      for (final e in standings['entries'] as List) {
        try {
          rows.add(_parseStandingRow(e as Map<String, dynamic>));
        } catch (_) {
          // Skip a malformed team rather than the whole table.
        }
      }
      if (rows.isNotEmpty) {
        groups.add(SportsStandingGroup(
          // "2026-27 English Premier League" → "English Premier League";
          // the season is shown on its own.
          name: (node['name'] ?? league.name)
              .toString()
              .replaceFirst(RegExp(r'^\d{4}(-\d{2})?\s+'), ''),
          rows: _sortStandings(rows, league),
        ));
      }
    }
    for (final c in (node['children'] as List?) ?? const []) {
      if (c is Map<String, dynamic>) walk(c);
    }
  }

  if (json is Map<String, dynamic>) walk(json);
  return SportsStandings(
    league: league,
    groups: groups,
    season: season,
    preseason: preseason,
  );
}

SportsStandingRow _parseStandingRow(Map<String, dynamic> e) {
  // Racing's driver table lists athletes (with a flag) instead of teams.
  final t = ((e['team'] ?? e['athlete']) as Map).cast<String, dynamic>();
  final logos = t['logos'] as List? ??
      [if (t['flag'] is Map) t['flag']]; // href, same shape as a logo
  final name = (t['displayName'] ?? t['name'] ?? '').toString();
  final stats = <String, String>{};
  for (final s in (e['stats'] as List?) ?? const []) {
    final m = s as Map;
    final key = (m['name'] ?? m['type'])?.toString();
    if (key == null) continue;
    // College football repeats the whole set per split (overall, home,
    // away); the first one is the overall line.
    var value = (m['displayValue'] ?? m['summary'] ?? '').toString();
    // NHL's last-ten reads "6-1-1, 0" (a trailing shootout count).
    if (key == 'Last Ten Games') value = value.split(',').first.trim();
    stats.putIfAbsent(key, () => value);
  }
  // Racing: drivers have `championshipPts`, F1 constructors `points` — one
  // column reads both.
  if (stats['points'] != null) {
    stats.putIfAbsent('championshipPts', () => stats['points']!);
  }
  final note = e['note'] as Map?;
  return SportsStandingRow(
    team: SportsTeam(
      id: (t['id'] ?? name).toString(),
      name: name,
      shortName: (t['shortDisplayName'] ?? t['name'] ?? name).toString(),
      abbreviation: (t['abbreviation'] ?? '').toString(),
      logoUrl:
          logos.isNotEmpty ? (logos.first as Map)['href']?.toString() : null,
      color: t['color']?.toString(),
    ),
    position: 0,
    stats: stats,
    // replaceAll: ESPN has sent "##B5E7CE" (Europa League).
    noteColor: note?['color']?.toString().replaceAll('#', ''),
    note: note?['description']?.toString(),
  );
}

/// ESPN's entries are not in table order (NBA/MLB come alphabetical-ish).
/// Soccer has a `rank`; the others a `playoffSeed`, which is 0 for everyone
/// before a season starts — then wins/points decide.
List<SportsStandingRow> _sortStandings(
    List<SportsStandingRow> rows, SportsLeague league) {
  double num(SportsStandingRow r, String k) =>
      double.tryParse(r.stat(k).replaceAll('+', '')) ?? 0;
  final key = league.soccer || league.kind == SportsKind.racing
      ? 'rank'
      : 'playoffSeed';
  final ranked = rows.every((r) => num(r, key) > 0);
  final sorted = [...rows];
  sorted.sort((a, b) {
    if (ranked) return num(a, key).compareTo(num(b, key));
    final byPoints = num(b, 'points').compareTo(num(a, 'points'));
    if (league.espnPath.startsWith('hockey') && byPoints != 0) return byPoints;
    final byPct = num(b, 'winPercent').compareTo(num(a, 'winPercent'));
    return byPct != 0 ? byPct : num(b, 'wins').compareTo(num(a, 'wins'));
  });
  return [
    for (var i = 0; i < sorted.length; i++)
      SportsStandingRow(
        team: sorted[i].team,
        position: i + 1,
        stats: sorted[i].stats,
        noteColor: sorted[i].noteColor,
        note: sorted[i].note,
      ),
  ];
}

SportsTeam _parseTeam(Map<String, dynamic> c) {
  final t = (c['team'] as Map?)?.cast<String, dynamic>() ?? const {};
  String? record;
  final records = c['records'] as List?;
  if (records != null && records.isNotEmpty) {
    record = (records.first as Map)['summary']?.toString();
  }
  // Team schedules: `record: [{displayValue: "2-1-0, 4 PTS"}]`.
  final schedRecord = c['record'];
  if (record == null && schedRecord is List && schedRecord.isNotEmpty) {
    record = (schedRecord.first as Map)['displayValue']
        ?.toString()
        .split(',')
        .first
        .trim();
  }
  // Scoreboard: "3"; team schedules: {value: 3.0, displayValue: "3"}.
  final rawScore = c['score'];
  final score = rawScore is Map
      ? rawScore['displayValue']?.toString()
      : rawScore?.toString();
  String? logo = t['logo']?.toString();
  final logos = t['logos'];
  if (logo == null && logos is List && logos.isNotEmpty) {
    logo = (logos.first as Map)['href']?.toString();
  }
  final name = (t['displayName'] ?? t['name'] ?? '').toString();
  // 99 = unranked.
  final poll = (c['curatedRank'] as Map?)?['current'];
  final pollRank = poll is num && poll >= 1 && poll <= 25 ? poll.toInt() : null;
  return SportsTeam(
    id: (t['id'] ?? name).toString(),
    name: name,
    shortName: (t['shortDisplayName'] ?? t['name'] ?? name).toString(),
    abbreviation: (t['abbreviation'] ?? '').toString(),
    logoUrl: logo,
    color: t['color']?.toString(),
    record: record,
    score: score,
    pollRank: pollRank,
  );
}
