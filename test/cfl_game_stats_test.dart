import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nox_iptv/l10n/el.dart';
import 'package:nox_iptv/l10n/es.dart';
import 'package:nox_iptv/l10n/fr.dart';
import 'package:nox_iptv/l10n/it.dart';
import 'package:nox_iptv/l10n/l10n.dart';
import 'package:nox_iptv/models/sports.dart';
import 'package:nox_iptv/screens/sports_live_list_screen.dart';
import 'package:nox_iptv/services/cfl_game_stats.dart';
import 'package:nox_iptv/services/sports_service.dart';

String envelope(Map<String, dynamic> details) => jsonEncode({
      'data': {
        'status': {'status': 'AVAILABLE'},
        'details': details,
      }
    });

// Actual CFL gametracker schema and values from Calgary–BC, Oct 17, 2026.
String teamFeed() => envelope({
      'stats': [
        {
          'id': 'passing_detailed',
          'away': [262, 25, 10.5],
          'home': [324, 43, 7.5]
        },
        {
          'id': 'first_down_detailed',
          'away': [10, 3, 1],
          'home': [17, 9, 3]
        },
        {
          'id': 'second_down_detailed',
          'away': [15, 4, 26.7],
          'home': [23, 13, 56.5]
        },
        {
          'id': 'giveaways_detailed',
          'away': [0, 1, 1],
          'home': [0, 1, 0]
        },
        {
          'id': 'penalties_detailed',
          'away': [4, 44],
          'home': [6, 50]
        },
        {
          'id': 'field_goals_detailed',
          'away': [3, 2, 48],
          'home': [5, 4, 32]
        },
        {'id': 'time_possession', 'away': '23:33', 'home': '36:27'},
      ]
    });

Map<String, dynamic> player(String name, Map<String, Object> stats) => {
      'abbreviationName': name,
      'type': 'ActiveNotPlayed', // The real feed can mislabel active players.
      'stats': [
        for (final entry in stats.entries)
          {'name': entry.key, 'statValue': entry.value}
      ],
    };

String playerFeed() => envelope({
      'homeTeam': {
        'passing': [
          player('V. Adams Jr.', {
            'YARDS': '324',
            'COMPLETIONS_ATTEMPTS': '30/43',
            'TOUCHDOWNS': '1',
            'INTERCEPTIONS': '1'
          })
        ],
        'rushing': [
          player('D. McMahon', {
            'YARDS': '105',
            'CARRIES': '10',
            'AVERAGE_YARDS': '10.5',
            'TOUCHDOWNS': '0'
          })
        ],
      },
      'awayTeam': {
        'passing': [
          player('N. Rourke', {
            'YARDS': '149',
            'COMPLETIONS_ATTEMPTS': '8/11',
            'TOUCHDOWNS': '1',
            'INTERCEPTIONS': '0'
          }),
          player('K. Salter', {
            'YARDS': '113',
            'COMPLETIONS_ATTEMPTS': '6/14',
            'TOUCHDOWNS': '0',
            'INTERCEPTIONS': '1'
          }),
        ],
      },
    });

SportsGameSummary summary() =>
    parseCflGameStats((teamFeed(), playerFeed(), 'CGY', 'BC'));

class _SummaryService extends SportsService {
  _SummaryService(this.result)
      : super.forTesting(MockClient((_) async => http.Response('', 404)));
  final SportsGameSummary result;

  @override
  Future<SportsGameSummary?> gameSummary(SportsGame game,
          {bool fresh = false}) async =>
      result;
}

void main() {
  test('team totals preserve away/home ordering and CFL conversion fields', () {
    final rows = {for (final r in summary().teamStats) r.$1: (r.$2, r.$3)};
    expect(rows['Passing yards'], ('262', '324'));
    expect(rows['First downs'], ('14', '29'));
    expect(rows['2nd down conversions'], ('4/15', '13/23'));
    expect(rows['Turnovers'], ('2', '1'));
    expect(rows['Penalties (yards)'], ('4-44', '6-50'));
    expect(rows['Field goals'], ('2/3', '4/5'));
    expect(rows['Time of possession'], ('23:33', '36:27'));
  });

  test(
      'players use canonical team ids, retain zeros and ignore bad participation flags',
      () {
    final s = summary();
    expect(s.players.keys, ['CGY', 'BC']);
    expect(s.players['CGY']!.first.rows.single.$1, 'V. Adams Jr.');
    expect(s.players['CGY']!.first.rows.single.$2, ['324', '30/43', '1', '1']);
    expect(s.players['CGY']!.last.rows.single.$1, 'D. McMahon');
    expect(s.players['CGY']!.last.rows.single.$2, ['105', '10', '10.5', '0']);
    expect(s.players['BC']!.single.rows.first.$1, 'N. Rourke');
    expect(s.players['BC']!.single.rows.last.$1, 'K. Salter');
    expect(
        s.players['BC']!.single.rows
            .map((r) => int.parse(r.$2.first))
            .reduce((a, b) => a + b),
        262);
  });

  test('performers sort by production before limiting to eight', () {
    final feed = envelope({
      'homeTeam': {
        'receiving': [
          for (var i = 0; i < 12; i++) player('Player $i', {'YARDS': '$i'}),
          {'name': 'No stats', 'stats': []},
          null,
        ]
      }
    });
    final rows = parseCflGameStats((null, feed, 'CGY', 'BC'))
        .players['CGY']!
        .single
        .rows;
    expect(rows, hasLength(8));
    expect(rows.first.$1, 'Player 11');
    expect(rows.last.$1, 'Player 4');
  });

  test('unavailable and malformed optional feeds allow partial summaries', () {
    for (final body in [
      null,
      'not JSON',
      '[]',
      '{"data":[]}',
      '{"data":{"status":{"status":"UNAVAILABLE"}}}'
    ]) {
      expect(parseCflGameStats((body, body, 'CGY', 'BC')).isEmpty, isTrue);
      final partial = parseCflGameStats((teamFeed(), body, 'CGY', 'BC'));
      expect(partial.teamStats, isNotEmpty);
      expect(partial.players, isEmpty);
      expect(parseCflGameStats((body, playerFeed(), 'CGY', 'BC')).players,
          isNotEmpty);
    }
  });

  test('all new CFL stats labels exist in every supported dictionary', () {
    for (final dictionary in [kFr, kEs, kIt, kEl]) {
      for (final label in [
        'Passing yards',
        'Rushing yards',
        'Net offence',
        'First downs',
        'Sacks',
        '2nd down conversions',
        'Turnovers',
        'Penalties (yards)',
        'Field goals',
        'Time of possession',
        'Punting',
        'Kickoffs',
        'Kickoff returns',
        'Punt returns',
      ]) {
        expect(dictionary[label], isNotEmpty, reason: label);
      }
    }
  });

  for (final overStream in [false, true]) {
    testWidgets(
        'shared stats popup renders CFL box scores, overStream=$overStream',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final previous = L10n.setting;
      await L10n.apply('en');
      addTearDown(() => L10n.apply(previous));
      final game = SportsGame(
        id: '13419750',
        league: sportsLeagueById('cfl')!,
        start: DateTime.utc(2026, 10, 17),
        state: GameState.post,
        statusText: 'Final',
        home: const SportsTeam(
            id: 'CGY',
            name: 'Calgary Stampeders',
            shortName: 'Stampeders',
            abbreviation: 'CGY',
            score: '32'),
        away: const SportsTeam(
            id: 'BC',
            name: 'BC Lions',
            shortName: 'Lions',
            abbreviation: 'BC',
            score: '13'),
      );
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SportsGameDetailsDialog(
        game: game,
        matches: const [],
        hideScores: false,
        overStream: overStream,
        service: _SummaryService(summary()),
      ))));
      await tester.pumpAndSettle();
      expect(find.text('V. Adams Jr.'), findsOneWidget);
      expect(find.text('N. Rourke'), findsOneWidget);
      expect(find.text('Passing yards'), findsOneWidget);
      expect(find.text('324'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
