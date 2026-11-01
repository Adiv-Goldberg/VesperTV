import '../models/sports.dart';
import 'sports_service.dart';

/// Each team's place in its standings table (conference / division /
/// league, as the Standings page groups it), shown beside team names on
/// Sports Trak's game cards: "Blackhawks (15)" (owner, 1.0.51). Read from
/// [SportsService.standings] (cached 15 min), never a new endpoint.
class SportsRanks {
  SportsRanks._();

  static final Map<String, int> _ranks = {};
  static final Map<String, DateTime> _loaded = {};

  /// The team's place, or null (no table, not loaded yet, event sports).
  /// College: the scoreboard's poll rank only (a conference table read
  /// "Notre Dame (1)" for the AP #5 independent, owner photo 1.0.51).
  static int? of(SportsLeague league, SportsTeam team) =>
      _college(league) ? team.pollRank : _ranks['${league.id}|${team.id}'];

  static bool _college(SportsLeague league) =>
      league.espnPath.contains('college') || league.id.contains('ncaa');

  /// "Blackhawks (15)", or the plain short name.
  static String name(SportsLeague league, SportsTeam team) {
    final rank = of(league, team);
    return rank == null ? team.shortName : '${team.shortName} ($rank)';
  }

  /// Loads the tables of [leagues] not loaded in the last 15 minutes.
  /// True when a rank was added or changed (the caller repaints).
  static Future<bool> ensure(Iterable<SportsLeague> leagues) async {
    final now = DateTime.now();
    final todo = {
      for (final l in leagues)
        if (l.kind == SportsKind.team &&
            l.hasStandings &&
            !_college(l) &&
            now.difference(_loaded[l.id] ?? DateTime(2000)) >
                const Duration(minutes: 15))
          l.id: l,
    }.values.toList();
    if (todo.isEmpty) return false;
    for (final l in todo) {
      _loaded[l.id] = now;
    }
    var changed = false;
    await Future.wait([
      for (final l in todo)
        SportsService.instance.standings(l).then((table) {
          for (final group in table?.groups ?? const <SportsStandingGroup>[]) {
            for (final row in group.rows) {
              final key = '${l.id}|${row.team.id}';
              if (_ranks[key] != row.position) {
                _ranks[key] = row.position;
                changed = true;
              }
            }
          }
        }).catchError((_) {}),
    ]);
    return changed;
  }
}
