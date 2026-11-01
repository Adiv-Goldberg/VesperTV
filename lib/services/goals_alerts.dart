import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/sports.dart';
import 'sports_service.dart';
import 'storage_service.dart';

class GoalAlertNotice {
  const GoalAlertNotice(
      {required this.viewerId,
      required this.game,
      required this.team,
      required this.observedAt});
  final String viewerId;
  final SportsGame game;
  final SportsTeam team;
  final DateTime observedAt;
}

class _ScoreSample {
  _ScoreSample(
      this.score, this.state, this.at, this.owner, this.start, this.gameKey);
  final int score;
  final GameState state;
  final DateTime at;
  final String owner;
  final DateTime start;
  final String gameKey;
}

class _MatchScoreWatch {
  const _MatchScoreWatch(this.league, this.id, this.start);
  final SportsLeague league;
  final String id;
  final DateTime start;
  String get key => '${league.id}:$id';
  Map<String, String> toJson() =>
      {'league': league.id, 'id': id, 'start': start.toUtc().toIso8601String()};
}

/// Foreground, opt-in scoring changes for My Teams and selected matches. Reuses the existing
/// cached scoreboard client; no new endpoint or per-team network request.
class GoalsAlerts extends ChangeNotifier {
  GoalsAlerts(this.storage,
      {DateTime Function()? now,
      Future<List<SportsGame>> Function(List<SportsLeague>, DateTime)?
          loadGames})
      : now = now ?? DateTime.now,
        _loadGames = loadGames ?? SportsService.instance.gamesForDay;
  final StorageService storage;
  final DateTime Function() now;
  final Future<List<SportsGame>> Function(List<SportsLeague>, DateTime)
      _loadGames;
  final Map<String, _ScoreSample> _scores = {};
  String _viewer = '';
  int _epoch = 0;
  int? _busyEpoch;
  bool _disposed = false;
  static final _notPlaying = RegExp(
      r'postpon|cancel|abandon|suspend|forfeit|\btbd\b',
      caseSensitive: false);

  bool get enabled =>
      !storage.getSportsHideScores() &&
      (storage.getGoalsAlert() ||
          _matches().isNotEmpty ||
          _leagueIds.isNotEmpty);
  Set<String> get _followed => storage.getGoalsAlert()
      ? storage.getSportsFollowedTeams().toSet()
      : <String>{};

  static String gameKey(SportsGame game) => '${game.league.id}:${game.id}';

  /// Leagues whose every game alerts (game hold menu / League manager).
  Set<String> get _leagueIds => storage.getLeagueGoalAlerts().toSet();

  bool isLeagueSet(SportsLeague league) => _leagueIds.contains(league.id);

  bool canSetLeague(SportsLeague league) => league.kind == SportsKind.team;

  Future<void> setLeague(SportsLeague league, bool value) async {
    if (_disposed || (value && !canSetLeague(league))) return;
    final viewer = storage.getActiveViewerId();
    final ids = storage.getLeagueGoalAlerts(viewerId: viewer).toList()
      ..remove(league.id);
    if (value) ids.add(league.id);
    await storage.setLeagueGoalAlerts(ids, viewerId: viewer);
    if (_disposed) return;
    // A new subscription starts with a silent baseline, as for a match.
    _epoch++;
    if (viewer == storage.getActiveViewerId()) {
      _scores
          .removeWhere((_, sample) => sample.owner.startsWith('${league.id}|'));
    }
    notifyListeners();
  }

  Map<String, _MatchScoreWatch> _matches({String? viewerId}) {
    final result = <String, _MatchScoreWatch>{};
    try {
      final raw =
          jsonDecode(storage.getMatchScoreAlerts(viewerId: viewerId) ?? '[]');
      if (raw is! List) return result;
      for (final item in raw.take(64)) {
        if (item is! Map ||
            item['league'] is! String ||
            item['id'] is! String ||
            item['start'] is! String) {
          continue;
        }
        final league = sportsLeagueById(item['league'] as String);
        final id = item['id'] as String;
        final start = DateTime.tryParse(item['start'] as String);
        if (league == null ||
            league.kind != SportsKind.team ||
            id.isEmpty ||
            id.length > 128 ||
            start == null ||
            !now().isBefore(start.add(const Duration(days: 2)))) {
          continue;
        }
        final watch = _MatchScoreWatch(league, id, start);
        result[watch.key] = watch;
      }
    } catch (_) {/* Ignore malformed/expired device-local subscriptions. */}
    return result;
  }

  bool isSet(SportsGame game) => _matches().containsKey(gameKey(game));

  bool canSet(SportsGame game) =>
      game.league.kind == SportsKind.team &&
      !game.isEventOnly &&
      game.id.isNotEmpty &&
      game.id.length <= 128 &&
      game.state != GameState.post &&
      !_notPlaying.hasMatch(game.statusText) &&
      now().isBefore(game.start.add(const Duration(days: 2)));

  Future<void> setGame(SportsGame game, bool value) async {
    if (_disposed || (value && !canSet(game))) return;
    final viewer = storage.getActiveViewerId();
    final matches = _matches(viewerId: viewer);
    final key = gameKey(game);
    if (value) {
      if (matches.length >= 64 && !matches.containsKey(key)) {
        throw StateError('Too many match score subscriptions');
      }
      matches[key] = _MatchScoreWatch(game.league, game.id, game.start);
    } else {
      matches.remove(key);
    }
    await storage.setMatchScoreAlerts(
        jsonEncode(matches.values.map((watch) => watch.toJson()).toList()),
        viewerId: viewer);
    if (_disposed) return;
    // Discard a response begun under the old subscription, without resetting
    // unrelated games. A new subscription starts with a silent baseline.
    _epoch++;
    if (viewer == storage.getActiveViewerId()) {
      _scores.removeWhere((_, sample) => sample.gameKey == key);
    }
    notifyListeners();
  }

  void reset() {
    _epoch++;
    _viewer = '';
    _scores.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    reset();
    super.dispose();
  }

  bool isCurrent(GoalAlertNotice notice) =>
      !_disposed &&
      enabled &&
      _viewer == notice.viewerId &&
      storage.getActiveViewerId() == notice.viewerId &&
      (_followed.contains('${notice.game.league.id}|${notice.team.id}') ||
          isSet(notice.game) ||
          isLeagueSet(notice.game.league)) &&
      now().difference(notice.observedAt) <= const Duration(seconds: 90);

  Future<List<GoalAlertNotice>> poll() async {
    if (_disposed) return const [];
    final viewer = storage.getActiveViewerId();
    if (!enabled) {
      reset();
      return const [];
    }
    if (_viewer != viewer) {
      reset();
      _viewer = viewer;
    }
    final followed = _followed;
    final matches = _matches();
    final leagueIds = _leagueIds;
    _scores.removeWhere((_, s) =>
        (!followed.contains(s.owner) &&
            !matches.containsKey(s.gameKey) &&
            !leagueIds.contains(s.owner.split('|').first)) ||
        now().difference(s.at) > const Duration(hours: 6));
    final leagues = <String, SportsLeague>{};
    for (final raw in followed) {
      final team = FollowedTeam.parse(raw);
      final league = team == null ? null : sportsLeagueById(team.leagueId);
      if (league != null && league.kind == SportsKind.team) {
        leagues[league.id] = league;
      }
    }
    for (final watch in matches.values) {
      leagues[watch.league.id] = watch.league;
    }
    for (final id in leagueIds) {
      final league = sportsLeagueById(id);
      if (league != null && league.kind == SportsKind.team) {
        leagues[league.id] = league;
      }
    }
    if (leagues.isEmpty || _busyEpoch == _epoch) return const [];
    final epoch = _epoch;
    _busyEpoch = epoch;
    try {
      final all = <SportsGame>[];
      final todo = leagues.values.toList();
      var index = 0;
      Future<void> worker() async {
        while (index < todo.length) {
          final league = todo[index++];
          final current = now().toLocal();
          final today = DateTime(current.year, current.month, current.day);
          final dates = <DateTime>{today};
          // Keep an overnight live game's start day through its final update;
          // the normal day helper otherwise carries over live games only.
          // A saved match can cross midnight even before the first poll after
          // reopening the app. Fetch its original day as well as today's feed.
          for (final watch in matches.values) {
            if (watch.league.id != league.id) continue;
            final start = watch.start.toLocal();
            final day = DateTime(start.year, start.month, start.day);
            if (day.isBefore(today) &&
                today.difference(day) <= const Duration(days: 2)) {
              dates.add(day);
            }
          }
          for (final sample in _scores.values) {
            if (sample.state != GameState.live ||
                !sample.owner.startsWith('${league.id}|')) {
              continue;
            }
            final start = sample.start.toLocal();
            final day = DateTime(start.year, start.month, start.day);
            if (day.isBefore(today) &&
                today.difference(day) <= const Duration(days: 2)) {
              dates.add(day);
            }
          }
          for (final day in dates) {
            try {
              all.addAll(await _loadGames([league], day));
            } catch (_) {
              /* Preserve samples through a temporary feed failure. */
            }
            if (_disposed || epoch != _epoch) return;
          }
        }
      }

      await Future.wait(
          List.generate(math.min(2, todo.length), (_) => worker()));
      if (_disposed ||
          epoch != _epoch ||
          viewer != storage.getActiveViewerId() ||
          !enabled) {
        return const [];
      }
      final at = now();
      final owners = _followed;
      final selected = _matches();
      final wholeLeagues = _leagueIds;
      final seen = <String>{};
      final notices = <GoalAlertNotice>[];
      for (final game in all) {
        if (game.league.kind != SportsKind.team ||
            !seen.add('${game.league.id}:${game.id}')) {
          continue;
        }
        if (_notPlaying.hasMatch(game.statusText)) continue;
        // An incomplete scoreboard must never manufacture a goal or scoreline.
        final home = int.tryParse(game.home.score ?? '');
        final away = int.tryParse(game.away.score ?? '');
        if (home == null || away == null || home < 0 || away < 0) continue;
        for (final team in [game.home, game.away]) {
          final owner = '${game.league.id}|${team.id}';
          if (!owners.contains(owner) &&
              !selected.containsKey(gameKey(game)) &&
              !wholeLeagues.contains(game.league.id)) {
            continue;
          }
          final key = '${game.league.id}:${game.id}|${team.id}';
          final score = team.id == game.home.id ? home : away;
          final previous = _scores[key];
          _scores[key] = _ScoreSample(
              score, game.state, at, owner, game.start, gameKey(game));
          final eligible = game.state == GameState.live ||
              (game.state == GameState.post &&
                  previous?.state == GameState.live &&
                  at.difference(previous!.at) <= const Duration(minutes: 3));
          // First observation (including first launch, new team or resume) is
          // only a baseline. Corrections downward are also silent.
          if (previous != null &&
              eligible &&
              previous.state != GameState.post &&
              score > previous.score) {
            notices.add(GoalAlertNotice(
                viewerId: viewer, game: game, team: team, observedAt: at));
          }
        }
      }
      while (_scores.length > 512) {
        _scores.remove(_scores.keys.first);
      }
      return notices;
    } finally {
      if (_busyEpoch == epoch) _busyEpoch = null;
    }
  }
}
