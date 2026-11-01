import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nox_iptv/l10n/l10n.dart';
import 'package:nox_iptv/models/profile_copy.dart';
import 'package:nox_iptv/models/sports.dart';
import 'package:nox_iptv/screens/settings/settings_menu_screen.dart';
import 'package:nox_iptv/screens/settings/sports_league_visibility_settings_screen.dart';
import 'package:nox_iptv/services/app_preferences.dart';
import 'package:nox_iptv/services/sports_service.dart';
import 'package:nox_iptv/services/storage_service.dart';
import 'package:nox_iptv/widgets/tv_menu_tile.dart';
import 'package:nox_iptv/widgets/tv_switch_list_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final nhl = sportsLeagueById('nhl')!, nfl = sportsLeagueById('nfl')!;
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day);
  late StorageService storage;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.init();
  });

  test(
      'empty schedules are reliable only after all neighboring dates succeed; cache is reused',
      () async {
    final requests = <Uri>[];
    final client = MockClient((r) async {
      requests.add(r.url);
      return http.Response('{"events":[]}', 200);
    });
    addTearDown(client.close);
    final service = SportsService.forTesting(client);
    expect(service.hasReliableSchedule(nhl, day), false);
    expect(await service.gamesForDay([nhl], day), isEmpty);
    expect(requests.length, 3);
    expect(service.hasReliableSchedule(nhl, day), true);
    expect(service.hasReliableSchedule(nfl, day), false);
    await service.gamesForDay([nhl], day);
    expect(requests.length, 3);
  });

  // Clocks went back on 2026-11-01 in North America: midnight + 24 h was
  // 23:00 the same day, so the next day's games were never fetched (and
  // the day strip's "tomorrow" showed today). Calendar days, not hours.
  test('the day after a clock change is still fetched', () async {
    final requests = <String>[];
    final client = MockClient((r) async {
      requests.add(r.url.queryParameters['dates'] ?? '');
      return http.Response('{"events":[]}', 200);
    });
    addTearDown(client.close);
    final service = SportsService.forTesting(client);
    await service.gamesForDay([nhl], DateTime(2026, 11, 1));
    expect(requests.toSet(), {'20261031', '20261101', '20261102'});
    requests.clear();
    await service.gamesForDay([nhl], DateTime(2026, 3, 8));
    expect(requests.toSet(), {'20260307', '20260308', '20260309'});
  });

  test(
      'one failed neighboring date stays unknown independently of other leagues and recovers',
      () async {
    var failed = true;
    final target =
        '${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';
    final client = MockClient((r) async => r.url.path.contains('nhl') &&
            r.url.queryParameters['dates'] == target &&
            failed
        ? http.Response('Unavailable', 503)
        : http.Response('{"events":[]}', 200));
    addTearDown(client.close);
    final service = SportsService.forTesting(client);
    await service.gamesForDay([nhl, nfl], day);
    expect(service.hasReliableSchedule(nhl, day), false);
    expect(service.hasReliableSchedule(nfl, day), true);
    failed = false;
    await service.gamesForDay([nhl], day);
    expect(service.hasReliableSchedule(nhl, day), true);
  });

  for (final body in [
    '{}',
    '{"events":{}}',
    '{"events":[{}]}',
    'invalid json'
  ]) {
    test(
        'malformed schedule is unknown rather than a confirmed empty league: $body',
        () async {
      final client = MockClient((_) async => http.Response(body, 200));
      addTearDown(client.close);
      final service = SportsService.forTesting(client);
      expect(await service.gamesForDay([nhl], day), isEmpty);
      expect(service.hasReliableSchedule(nhl, day), false);
    });
  }

  test(
      'SportsDB explicit null events means empty, missing events means unknown',
      () async {
    final league = sportsLeagueById('boxing')!;
    for (final (body, known) in [('{"events":null}', true), ('{}', false)]) {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response(body, 200);
      });
      addTearDown(client.close);
      final service = SportsService.forTesting(client);
      expect(await service.gamesForDay([league], day), isEmpty);
      expect(service.hasReliableSchedule(league, day), known);
      expect(requests, 1);
    }
  });

  test('live games carried past midnight still count on Today', () async {
    final start = day.subtract(const Duration(hours: 1));
    final body = jsonEncode({
      'events': [
        {
          'id': 'overnight',
          'date': start.toUtc().toIso8601String(),
          'competitions': [
            {
              'competitors': [
                for (final side in ['home', 'away'])
                  {
                    'homeAway': side,
                    'team': {
                      'id': side,
                      'displayName': side,
                      'abbreviation': side
                    },
                  }
              ],
              'status': {
                'type': {'state': 'in', 'shortDetail': 'Live'}
              },
            }
          ],
        }
      ]
    });
    final client = MockClient((_) async => http.Response(body, 200));
    addTearDown(client.close);
    final service = SportsService.forTesting(client);
    final games = await service.gamesForDay([nhl], day);
    expect(games.single.id, 'overnight');
    expect(service.hasReliableSchedule(nhl, day), true);
  });

  test(
      'off by default; profile scope, Main sports copy, Backup and Transfer preserve setting',
      () async {
    expect(storage.getSportsHideEmptyLeagues(), false);
    await storage.setSportsHideEmptyLeagues(true);
    final payload = storage.exportForTransfer();
    expect(
        storage
            .exportForBackup()
            .keys
            .any((k) => k.contains('sports_hide_empty_leagues')),
        true);
    await storage.copyMainToViewer('copy', {ProfileCopy.sports},
        restricted: false);
    await storage.setActiveViewerId('other');
    expect(storage.getSportsHideEmptyLeagues(), false);
    await storage.setActiveViewerId('copy');
    expect(storage.getSportsHideEmptyLeagues(), true);
    await storage.setActiveViewerId('main');
    await storage.setSportsHideEmptyLeagues(false);
    await storage.importForTransfer(payload);
    expect(storage.getSportsHideEmptyLeagues(), true);
  });

  for (final size in [const Size(1280, 720), const Size(390, 760)]) {
    testWidgets('Sports settings opens league visibility at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final prefs = AppPreferences(storage);
      await prefs.init();
      await tester.pumpWidget(MultiProvider(
          providers: [
            Provider.value(value: storage),
            ChangeNotifierProvider.value(value: prefs)
          ],
          child: MaterialApp(
              theme: ThemeData.dark(), home: const SettingsMenuScreen())));
      await tester.pumpAndSettle();
      final category = find.widgetWithText(TvMenuTile, 'Sports Trak');
      await tester.ensureVisible(category);
      await tester.tap(category);
      await tester.pumpAndSettle();
      final entry =
          find.widgetWithText(TvMenuTile, 'Hide leagues with no games');
      // This destination is below the new quality preference on phones.
      await tester.scrollUntilVisible(entry, 120,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(find.byType(SportsLeagueVisibilitySettingsScreen), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(storage.getSportsHideEmptyLeagues(), true);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(SportsLeagueVisibilitySettingsScreen), findsNothing);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      prefs.dispose();
    });
  }

  for (final language in ['en', 'fr', 'es', 'it', 'el']) {
    testWidgets(
        'league visibility toggle supports large text and stale viewer guard in $language',
        (tester) async {
      L10n.code = language;
      addTearDown(() => L10n.code = 'en');
      tester.view.physicalSize = const Size(390, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(Provider.value(
          value: storage,
          child: MaterialApp(
              theme: ThemeData.dark(),
              home: const MediaQuery(
                  data: MediaQueryData(
                      size: Size(390, 760), textScaler: TextScaler.linear(1.4)),
                  child: SportsLeagueVisibilitySettingsScreen()))));
      await tester.pumpAndSettle();
      final toggle = find.byType(TvSwitchListTile);
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(storage.getSportsHideEmptyLeagues(), true);
      await storage.setActiveViewerId('other');
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(storage.getSportsHideEmptyLeagues(), false);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
