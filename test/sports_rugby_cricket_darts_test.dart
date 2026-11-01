import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox_iptv/models/sports.dart';
import 'package:nox_iptv/screens/sports_standings_screen.dart';
import 'package:nox_iptv/services/sports_db_source.dart';
import 'package:nox_iptv/widgets/sports_widgets.dart';

void main() {
  test('rugby, cricket and darts are in the league bank', () {
    for (final id in [
      'rugby.six-nations',
      'rugby.prem',
      'rugby.urc',
      'rugby.top14',
      'rugby-league.nrl',
      'cricket.ipl',
      'cricket.bbl',
      'darts.pdc',
    ]) {
      final league = sportsLeagueById(id);
      expect(league, isNotNull, reason: id);
      expect(kSportsLeagueRegions, contains(league!.region), reason: id);
    }
    final ids = [for (final l in kSportsLeagueBank) l.id];
    expect(ids.toSet().length, ids.length, reason: 'duplicate league ids');
  });

  test('rugby and cricket read home side first', () {
    expect(sportsLeagueById('rugby.prem')!.homeFirst, isTrue);
    expect(sportsLeagueById('cricket.ipl')!.homeFirst, isTrue);
    expect(sportsLeagueById('nhl')!.homeFirst, isFalse);
  });

  test('rugby tables use the rugby stat names', () {
    final stats = [
      for (final c in sportsStandingColumns(sportsLeagueById('rugby.urc')!))
        c.stat
    ];
    expect(stats, containsAll(['gamesWon', 'gamesDrawn', 'bonusPoints']));
  });

  test('sport icons', () {
    expect(SportsBackdrop.sportIcon(sportsLeagueById('rugby.prem')),
        Icons.sports_rugby);
    expect(SportsBackdrop.sportIcon(sportsLeagueById('cricket.ipl')),
        Icons.sports_cricket);
    expect(SportsBackdrop.sportIcon(sportsLeagueById('darts.pdc')),
        Icons.track_changes);
  });

  test('cricket events keep both teams and their runs', () {
    final league = sportsLeagueById('cricket.ipl')!;
    final body = jsonEncode({
      'events': [
        {
          'idEvent': '1',
          'strEvent': 'Gujarat Titans vs Royal Challengers Bangalore',
          'strHomeTeam': 'Gujarat Titans',
          'strAwayTeam': 'Royal Challengers Bangalore',
          'intHomeScore': '156',
          'intAwayScore': '161',
          'strTimestamp': '2026-05-31T14:00:00',
          'strStatus': 'FT',
        }
      ]
    });
    final game = parseSportsDbEvents((body, league)).single;
    expect(game.state, GameState.post);
    expect(game.first.name, 'Gujarat Titans');
    expect(game.first.score, '156');
    expect(game.second.score, '161');
  });

  test('a PDC day without a time is a date-only event card', () {
    final league = sportsLeagueById('darts.pdc')!;
    final body = jsonEncode({
      'events': [
        {
          'idEvent': '2',
          'strEvent': 'Players Championship 33',
          'dateEvent': '2026-11-04',
          'strTime': '00:00:00',
          'strTimestamp': '2026-11-04T00:00:00',
          'strStatus': '',
        }
      ]
    });
    final game = parseSportsDbEvents((body, league)).single;
    expect(game.isEventOnly, isTrue);
    expect(game.title, 'Players Championship 33');
    expect(game.end, isNotNull);
    // Still Nov 4 in the Americas (was 8 pm on Nov 3 in New York).
    expect(game.start, DateTime.utc(2026, 11, 4, 4));
  });
}
