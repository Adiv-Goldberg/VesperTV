import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nox_iptv/l10n/l10n.dart';
import 'package:nox_iptv/models/sports.dart';
import 'package:nox_iptv/services/sports_service.dart';
import 'package:nox_iptv/utils/route_observer.dart';
import 'package:nox_iptv/widgets/sports_matchup_stats.dart';

class _Feed extends SportsService {
  _Feed() : super.forTesting(MockClient((_) async => http.Response('{}', 200)));
  final requests = <String>[];
  final results = <String, Future<SportsGameSummary?> Function()>{};
  @override
  Future<SportsGameSummary?> gameSummary(SportsGame game,
      {bool fresh = false}) async {
    requests.add(game.id);
    return results[game.id]?.call();
  }
}

SportsGame game(
        {String id = 'a',
        GameState state = GameState.live,
        bool soccer = false,
        List<SportsLeader> leaders = const [],
        SportsSituation? situation}) =>
    SportsGame(
      id: id,
      league: SportsLeague(
          id: soccer ? 'eng.1' : 'nhl',
          espnPath: '',
          name: 'Test',
          shortName: 'TEST',
          logoUrl: '',
          soccer: soccer),
      start: DateTime(2026, 10, 29),
      state: state,
      statusText: 'Live',
      home: const SportsTeam(
          id: 'h', name: 'Home', shortName: 'Home', abbreviation: 'H'),
      away: const SportsTeam(
          id: 'a', name: 'Away', shortName: 'Away', abbreviation: 'A'),
      leaders: leaders,
      situation: situation,
    );

void main() {
  late _Feed feed;
  late ValueNotifier<SportsGame> selected;
  late ValueNotifier<bool> hidden;
  final nav = GlobalKey<NavigatorState>();
  setUp(() {
    L10n.code = 'en';
    feed = _Feed();
    selected = ValueNotifier(game());
    hidden = ValueNotifier(false);
  });
  tearDown(() {
    selected.dispose();
    hidden.dispose();
    L10n.code = 'en';
  });
  Future<void> open(WidgetTester tester,
      {double width = 900, double scale = 1, bool compact = false}) async {
    tester.view.physicalSize = Size(width, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        navigatorKey: nav,
        navigatorObservers: [appRouteObserver],
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: Scaffold(
            body: ValueListenableBuilder(
                valueListenable: selected,
                builder: (context, g, child) => ValueListenableBuilder(
                    valueListenable: hidden,
                    builder: (context, hide, child) => Align(
                        alignment: Alignment.topCenter,
                        child: SportsMatchupStats(
                            game: g,
                            service: feed,
                            hideScores: hide,
                            compact: compact)))))));
    await tester.pump(const Duration(milliseconds: 351));
    await tester.pump();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  for (final soccer in [false, true]) {
    testWidgets('team values follow display order (soccer=$soccer)',
        (tester) async {
      selected.value = game(soccer: soccer);
      feed.results['a'] = () async => const SportsGameSummary(
          teamStats: [('Shots', '18', '25'), ('Possession', '40%', '60%')]);
      await open(tester);
      expect(find.text(soccer ? 'H 25 · A 18' : 'A 18 · H 25'), findsOneWidget);
      expect(find.text(soccer ? 'H 60% · A 40%' : 'A 40% · H 60%'),
          findsOneWidget);
      expect(feed.requests, ['a']);
      expect(tester.takeException(), isNull);
      await close(tester);
    });
  }

  testWidgets('latest goal, game leader and team stat add context',
      (tester) async {
    selected.value = game(leaders: const [
      SportsLeader(stat: 'G', name: 'Test scorer', value: '2', teamId: 'a')
    ]);
    feed.results['a'] = () async => const SportsGameSummary(goals: [
          SportsGoal(minute: '12:30', scorer: 'First scorer'),
          SportsGoal(minute: '18:00', period: '2nd', scorer: 'Latest scorer')
        ], teamStats: [
          ('Shots', '20', '30')
        ]);
    await open(tester);
    expect(find.text('Latest scorer · 2nd 18:00'), findsOneWidget);
    expect(find.text('Test scorer · 2'), findsOneWidget);
    expect(find.text('A 20 · H 30'), findsOneWidget);
    expect(find.textContaining('First scorer'), findsNothing);
    await close(tester);
  });

  testWidgets('pregame shows standings and injuries, excludes in-game data',
      (tester) async {
    selected.value = game(state: GameState.pre);
    feed.results['a'] = () async => const SportsGameSummary(tables: [
          SportsSummaryTable(title: 'Division', labels: [
            'W',
            'L'
          ], rows: [
            ('a', 'Away', ['10', '2']),
            ('h', 'Home', ['9', '3'])
          ])
        ], injuries: {
          'h': [SportsInjury(name: 'Test player', status: 'Out')]
        }, teamStats: [
          ('Shots', '45', '51')
        ], goals: [
          SportsGoal(minute: '18:00', scorer: 'Spoiler')
        ]);
    hidden.value = true;
    await open(tester);
    expect(find.text('Division · W 10 · L 2'), findsOneWidget);
    expect(find.text('Division · W 9 · L 3'), findsOneWidget);
    expect(find.text('Test player · Out'), findsOneWidget);
    expect(find.textContaining('Spoiler'), findsNothing);
    expect(find.text('Shots'), findsNothing);
    await close(tester);
  });

  testWidgets('hidden scores suppress stats and ignore an in-flight result',
      (tester) async {
    final pending = Completer<SportsGameSummary?>();
    feed.results['a'] = () => pending.future;
    await open(tester);
    hidden.value = true;
    await tester.pump();
    pending.complete(const SportsGameSummary(teamStats: [('Shots', '5', '8')]));
    await tester.pump();
    expect(find.text('Scores hidden'), findsOneWidget);
    expect(find.text('Shots'), findsNothing);
    selected.value = game(id: 'b', state: GameState.post);
    await tester.pump();
    await tester.pump(const Duration(seconds: 31));
    expect(feed.requests, ['a']);
    await close(tester);
  });

  testWidgets(
      'focus changes debounce and late response cannot replace selected stats',
      (tester) async {
    final pending = Completer<SportsGameSummary?>();
    feed.results['a'] = () => pending.future;
    feed.results['c'] =
        () async => const SportsGameSummary(teamStats: [('Shots', '3', '4')]);
    await open(tester);
    selected.value = game(id: 'b');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    selected.value = game(id: 'c');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 351));
    await tester.pump();
    pending
        .complete(const SportsGameSummary(teamStats: [('Shots', '99', '99')]));
    await tester.pump();
    expect(feed.requests, ['a', 'c']);
    expect(find.text('A 3 · H 4'), findsOneWidget);
    expect(find.textContaining('99'), findsNothing);
    await close(tester);
  });

  testWidgets(
      'missing summary keeps known last play; failed feed has honest fallback',
      (tester) async {
    selected.value =
        game(situation: const SportsSituation(lastPlay: 'Touchdown by Smith'));
    await open(tester);
    expect(find.text('Touchdown by Smith'), findsOneWidget);
    feed.results['b'] = () => Future.error(StateError('offline'));
    selected.value = game(id: 'b');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 351));
    await tester.pump();
    expect(find.text('No stats for this game yet.'), findsOneWidget);
    expect(find.text('Touchdown by Smith'), findsNothing);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('live refresh pauses offscreen and in background',
      (tester) async {
    await open(tester);
    await tester.pump(const Duration(seconds: 31));
    expect(feed.requests, hasLength(2));
    unawaited(nav.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Another screen')))));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 61));
    expect(feed.requests, hasLength(2));
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 351));
    expect(feed.requests, hasLength(3));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 61));
    expect(feed.requests, hasLength(3));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 351));
    expect(feed.requests, hasLength(4));
    await close(tester);
  });

  for (final width in [320.0, 960.0]) {
    testWidgets('stats fit large text at width $width', (tester) async {
      feed.results['a'] = () async => const SportsGameSummary(teamStats: [
            ('A long provider stat label', '123456789', '123456789'),
            ('A second label', '123456789', '123456789'),
            ('Third label', '123456789', '123456789')
          ]);
      await open(tester, width: width, scale: 1.5);
      expect(tester.takeException(), isNull);
      await close(tester);
    });
  }
}
