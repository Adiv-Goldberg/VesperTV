import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nox_iptv/l10n/l10n.dart';
import 'package:nox_iptv/models/channel.dart';
import 'package:nox_iptv/models/epg_program.dart';
import 'package:nox_iptv/models/sports.dart';
import 'package:nox_iptv/screens/sports_screen.dart';
import 'package:nox_iptv/screens/multiview_screen.dart';
import 'package:nox_iptv/services/guide_key.dart';
import 'package:nox_iptv/screens/player_screen.dart';
import 'package:nox_iptv/screens/sports_live_list_screen.dart';
import 'package:nox_iptv/screens/sports_my_teams_screen.dart';
import 'package:nox_iptv/screens/sports_league_manager_screen.dart';
import 'package:nox_iptv/screens/sports_channels_screen.dart';
import 'package:nox_iptv/screens/settings/sports_quality_settings_screen.dart';
import 'package:nox_iptv/screens/tv_home_screen.dart';
import 'package:nox_iptv/widgets/sports_widgets.dart';
import 'package:nox_iptv/services/app_preferences.dart';
import 'package:nox_iptv/services/catalog_database.dart';
import 'package:nox_iptv/services/epg_service.dart';
import 'package:nox_iptv/services/playback_service.dart';
import 'package:nox_iptv/services/playlist_manager.dart';
import 'package:nox_iptv/services/sports_service.dart';
import 'package:nox_iptv/services/sports_channel_matcher.dart';
import 'package:nox_iptv/services/goals_alerts.dart';
import 'package:nox_iptv/services/game_reminders.dart';
import 'package:nox_iptv/services/storage_service.dart';
import 'package:nox_iptv/services/viewer_profile_service.dart';
import 'package:nox_iptv/models/m3u_group.dart';
import 'package:nox_iptv/utils/constants.dart';
import 'package:nox_iptv/utils/refined_finish.dart';
import 'package:nox_iptv/utils/route_observer.dart';
import 'package:nox_iptv/utils/tv_theme.dart';
import 'package:nox_iptv/widgets/sports_mode_toggle.dart';
import 'package:nox_iptv/widgets/sports_mode_shell.dart';
import 'package:nox_iptv/widgets/sports_league_rail.dart';
import 'package:nox_iptv/widgets/sports_mode_live_panel.dart';

class _Storage extends StorageService {
  @override
  Future<void> writeCacheFile(String name, String content) async {}
}

class _Playlist extends PlaylistManager {
  _Playlist(StorageService storage) : super(storage, CatalogDatabase());

  /// Live TV panel fixture: one provider group with these channels.
  List<Channel> live = const [];
  @override
  List<M3uGroup> get tvGroups => live.isEmpty
      ? const []
      : [M3uGroup(title: 'Sports', playlistId: 'p1', channels: live)];
  @override
  List<Channel> visibleChannels(
          {String? playlistId, String? groupTitle, required String category}) =>
      groupTitle == null || groupTitle == 'Sports' ? live : [];
}

class _Epg extends EpgService {
  _Epg(super.storage);
  @override
  Future<double?> guideCoverageAt(DateTime at) async => null;
  @override
  Future<List<EpgProgram>> findProgrammesByTitle(
          DateTime from, DateTime to, List<String> terms) async =>
      [];
}

class _Playback extends PlaybackService {
  _Playback(super.storage, super.playlist);
  int stops = 0;
  final List<Channel> plays = [];
  Completer<void>? opening;
  @override
  Future<void> play(Channel channel) async {
    plays.add(channel);
    await opening?.future;
    currentChannel = channel;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    stops++;
    currentChannel = null;
    notifyListeners();
  }
}

/// Record the real full-screen destination without mounting its native video
/// surface in a widget test. The preview and navigation paths still run.
class _PlayerRoutes extends NavigatorObserver {
  final List<Channel> channels = [];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute == null || route is! MaterialPageRoute) return;
    final page = route.builder(navigator!.context);
    if (page is! PlayerScreen) return;
    channels.add(page.channel);
    scheduleMicrotask(() => navigator!.removeRoute(route));
  }
}

const _league = SportsLeague(
    id: 'nhl',
    espnPath: 'hockey/nhl',
    name: 'Hockey',
    shortName: 'NHL',
    logoUrl: '');
SportsGame _game(int index, GameState state) => SportsGame(
      id: 'game$index',
      league: _league,
      start: DateTime.now().add(Duration(minutes: index)),
      state: state,
      statusText: state == GameState.live ? 'Live' : 'Scheduled',
      home: SportsTeam(
          id: 'home$index',
          name: 'Home $index',
          shortName: 'Home $index',
          abbreviation: 'H$index'),
      away: SportsTeam(
          id: 'away$index',
          name: 'Away $index',
          shortName: 'Away $index',
          abbreviation: 'A$index'),
    );

class _Feed extends SportsService {
  _Feed(this.games,
      {this.gate, this.summary, this.days, this.unavailable = const {}})
      : super.forTesting(MockClient((_) async => http.Response('{}', 200)));
  final List<SportsGame> games;
  final List<List<String>> requests = [];
  final Completer<void>? gate;
  final SportsGameSummary? summary;
  final Map<int, List<SportsGame>>? days;
  final Set<String> unavailable;
  @override
  bool hasReliableSchedule(SportsLeague league, DateTime day) =>
      !unavailable.contains(league.id);
  @override
  Future<List<SportsGame>> gamesForDay(
      List<SportsLeague> leagues, DateTime day) async {
    requests.add([for (final league in leagues) league.id]);
    await gate?.future;
    final now = DateTime.now();
    if (days case final byDay?) {
      final offset =
          day.difference(DateTime(now.year, now.month, now.day)).inDays;
      final ids = leagues.map((league) => league.id).toSet();
      return (byDay[offset] ?? [])
          .where((game) => ids.contains(game.league.id))
          .toList();
    }
    return day.day == now.day ? games : [];
  }

  @override
  Future<SportsGameSummary?> gameSummary(SportsGame game,
          {bool fresh = false}) async =>
      summary;

  @override
  Future<DateTime?> nextGameStart(SportsLeague league, DateTime day) async =>
      null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Storage storage;
  late AppPreferences prefs;
  late _Playlist playlist;
  late _Playback playback;
  final boundary = GlobalKey();

  setUpAll(() async {
    for (final entry in {
      'Roboto': Platform.environment['SPORTS_MODE_PREVIEW_FONT'],
      'MaterialIcons': Platform.environment['SPORTS_MODE_PREVIEW_ICONS'],
    }.entries) {
      if (entry.value == null) continue;
      final loader = FontLoader(entry.key)
        ..addFont(Future.value(
            ByteData.sublistView(await File(entry.value!).readAsBytes())));
      await loader.load();
    }
  });

  setUp(() async {
    L10n.code = 'en';
    SharedPreferences.setMockInitialValues({
      AppConstants.keySportsMode: true,
      AppConstants.keySportsLeagues: [
        'nhl',
        'nfl',
        'nba',
        'mlb',
        'eng.1',
        'uefa.champions',
        'esp.1'
      ],
    });
    storage = _Storage();
    await storage.init();
    prefs = AppPreferences(storage);
    await prefs.init();
    prefs.isTelevision = true;
    playlist = _Playlist(storage);
    playback = _Playback(storage, playlist);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
            'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
            (_) async => const StandardMessageCodec().encodeMessage([null]));
    // Sports logos are decorative. Give the cache a real temporary location
    // while Flutter's test HTTP client supplies its normal failed-image reply.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => Directory.systemTemp.path);
  });

  tearDown(() {
    playback.dispose();
    playlist.dispose();
    prefs.dispose();
    L10n.code = 'en';
  });

  Future<void> open(WidgetTester tester,
      {List<SportsGame>? games,
      Size size = const Size(960, 540),
      double scale = 1,
      NavigatorObserver? observer,
      _Feed? feed}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          ChangeNotifierProvider<AppPreferences>.value(value: prefs),
          ChangeNotifierProvider<PlaylistManager>.value(value: playlist),
          ChangeNotifierProvider<EpgService>(create: (_) => _Epg(storage)),
          ChangeNotifierProvider<PlaybackService>.value(value: playback),
          ChangeNotifierProvider<GoalsAlerts>(
              create: (_) => GoalsAlerts(storage)),
          ChangeNotifierProvider<GameReminders>(
              create: (_) => GameReminders(storage)),
          ChangeNotifierProvider<ViewerProfileService>(
              create: (_) => ViewerProfileService(storage, playlist, playback)),
        ],
        child: MaterialApp(
          navigatorObservers: [
            appRouteObserver,
            if (observer != null) observer
          ],
          theme: RefinedFinish.apply(
              ThemeData(
                  colorScheme:
                      buildPaletteColorScheme(prefs.palette, Brightness.dark)),
              prefs.refinedFinish),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: RepaintBoundary(
              key: boundary,
              child: SportsScreen(
                  home: true,
                  service: feed ??
                      _Feed(games ??
                          [
                            _game(100, GameState.live),
                            for (var i = 0; i < 18; i++)
                              _game(i, GameState.pre),
                            _game(200, GameState.post),
                          ]))),
        )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  String? getFocus() => FocusManager.instance.primaryFocus?.debugLabel;
  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  Future<void> disposePage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(seconds: 31));
  }

  Future<List<SportsGame>> matchedGames() async {
    final games = [_game(100, GameState.live), _game(101, GameState.live)];
    playlist.live = [
      for (var i = 0; i < 2; i++)
        Channel(
            id: 'p1::$i',
            rawId: '$i',
            playlistId: 'p1',
            name: 'Test Sports $i',
            group: 'Sports',
            url: 'https://test/$i'),
    ];
    final picks = SportsChannelPicks.load(storage);
    for (var i = 0; i < games.length; i++) {
      await picks.pickForGame(games[i], playlist.live[i].id);
    }
    return games;
  }

  for (final mode in [false, true]) {
    testWidgets(
        'first OK previews, next uses same stream full screen (mode=$mode)',
        (tester) async {
      await prefs.setSportsMode(mode);
      final games = await matchedGames();
      final routes = _PlayerRoutes();
      await open(tester, games: games, observer: routes);
      final card = find.byWidgetPredicate((w) =>
          w is InkWell && w.focusNode?.debugLabel == 'sports-card-nhl:game100');
      tester.widget<InkWell>(card).focusNode!.requestFocus();
      await tester.pump();
      expect(playback.plays, isEmpty); // focus only changes the matchup
      await press(tester, LogicalKeyboardKey.select);
      expect(playback.plays.map((c) => c.id), ['p1::0']);
      expect(routes.channels, isEmpty);
      await press(tester, LogicalKeyboardKey.select);
      expect(routes.channels.map((c) => c.id), ['p1::0']);
      expect(playback.plays, hasLength(1));
      if (mode) {
        expect(getFocus(), 'sports-mode-feed');
        expect(find.byKey(const ValueKey('sports-mode-rail')), findsNothing);
      }
      expect(tester.takeException(), isNull);
      await disposePage(tester);
    });
  }

  testWidgets('quick second and third OK wait for one opening session',
      (tester) async {
    final games = await matchedGames();
    final routes = _PlayerRoutes();
    playback.opening = Completer<void>();
    await open(tester, games: games, observer: routes);
    await press(tester, LogicalKeyboardKey.arrowRight);
    await press(tester, LogicalKeyboardKey.select);
    await press(tester, LogicalKeyboardKey.select);
    await press(tester, LogicalKeyboardKey.select);
    expect(playback.plays, hasLength(1));
    expect(routes.channels, isEmpty);
    playback.opening!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(routes.channels.map((c) => c.id), ['p1::0']);
    expect(playback.plays, hasLength(1));
    expect(getFocus(), 'sports-mode-feed');
    expect(find.byKey(const ValueKey('sports-mode-rail')), findsNothing);
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('delayed preview keeps focus on the game with the rail collapsed',
      (tester) async {
    final games = await matchedGames();
    final routes = _PlayerRoutes();
    playback.opening = Completer<void>();
    await open(tester, games: games, observer: routes);
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(getFocus(), 'sports-card-nhl:game100');
    await press(tester, LogicalKeyboardKey.select);
    await tester.pump(const Duration(seconds: 1));
    playback.opening!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(getFocus(), 'sports-mode-feed');
    expect(find.byKey(const ValueKey('sports-mode-rail')), findsNothing);
    expect(find.byKey(const ValueKey('sports-mode-rail-tab')), findsOneWidget);
    expect(playback.plays, hasLength(1));
    // A second OK reaches that same game, not a league in the sidebar.
    await press(tester, LogicalKeyboardKey.select);
    expect(routes.channels.map((c) => c.id), ['p1::0']);
    expect(playback.plays, hasLength(1));
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('Right leaves the league rail after a delayed preview opens',
      (tester) async {
    final games = await matchedGames();
    playback.opening = Completer<void>();
    await open(tester, games: games);
    await press(tester, LogicalKeyboardKey.arrowRight);
    await press(tester, LogicalKeyboardKey.select);
    await tester.pump(const Duration(seconds: 1));
    playback.opening!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Exercise every rail league: returning should always reach the feed.
    for (var i = 0; i < 5; i++) {
      if (getFocus() == 'sports-mode-feed') {
        await press(tester, LogicalKeyboardKey.arrowLeft);
      }
      await press(tester, LogicalKeyboardKey.arrowDown);
      final feedElement =
          tester.element(find.byKey(const ValueKey('sports-mode-feed')));
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(getFocus(), 'sports-mode-feed');
      expect(find.byKey(const ValueKey('sports-mode-rail')), findsNothing);
      expect(tester.element(find.byKey(const ValueKey('sports-mode-feed'))),
          same(feedElement));
    }
    // A remembered header zone must not send Right to an absent game card.
    await press(tester, LogicalKeyboardKey.arrowUp);
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(getFocus(), 'sports-chip-league:all');
    await press(tester, LogicalKeyboardKey.arrowLeft);
    expect(find.byKey(const ValueKey('sports-mode-rail')), findsOneWidget);
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(getFocus(), 'sports-mode-feed');
    expect(find.byKey(const ValueKey('sports-mode-rail')), findsNothing);
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets(
      'cards under the small player: OK plays there, Up returns to the feed',
      (tester) async {
    final games = await matchedGames();
    final routes = _PlayerRoutes();
    await open(tester, games: games, observer: routes);
    await press(tester, LogicalKeyboardKey.arrowRight);
    await press(tester, LogicalKeyboardKey.select); // first game: big player
    expect(getFocus(), 'sports-mode-feed');
    // Down past the feed's games: the cards under the small player.
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(find.byKey(const ValueKey('sports-mode-feed')), findsNothing);
    final second = find.byWidgetPredicate((w) =>
        w is InkWell && w.focusNode?.debugLabel == 'sports-card-nhl:game101');
    tester.widget<InkWell>(second).focusNode!.requestFocus();
    await tester.pump();
    await press(tester, LogicalKeyboardKey.select);
    // Plays in the small player; the cards stay.
    expect(playback.plays.map((c) => c.id), ['p1::0', 'p1::1']);
    expect(routes.channels, isEmpty);
    expect(getFocus(), 'sports-card-nhl:game101');
    expect(find.byKey(const ValueKey('sports-mode-feed')), findsNothing);
    // Up from the first row: the big player with the feed again.
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(getFocus(), 'sports-mode-feed');
    expect(playback.plays, hasLength(2));
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('another feed game previews before going full screen',
      (tester) async {
    final games = await matchedGames();
    final routes = _PlayerRoutes();
    await open(tester, games: games, observer: routes);
    await press(tester, LogicalKeyboardKey.arrowRight);
    await press(tester, LogicalKeyboardKey.select);
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.select);
    expect(playback.plays.map((c) => c.id), ['p1::0', 'p1::1']);
    expect(routes.channels, isEmpty);
    await press(tester, LogicalKeyboardKey.select);
    expect(routes.channels.map((c) => c.id), ['p1::1']);
    expect(playback.plays, hasLength(2));
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('phone first tap previews without a focus-only extra tap',
      (tester) async {
    await prefs.setSportsMode(false);
    prefs.isTelevision = false;
    final games = await matchedGames();
    final routes = _PlayerRoutes();
    await open(tester,
        games: games, observer: routes, size: const Size(390, 844));
    var card = find.byWidgetPredicate((w) =>
        w is InkWell && w.focusNode?.debugLabel == 'sports-card-nhl:game100');
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pump();
    expect(playback.plays.map((c) => c.id), ['p1::0']);
    expect(routes.channels, isEmpty);
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pump();
    expect(routes.channels.map((c) => c.id), ['p1::0']);
    expect(playback.plays, hasLength(1));
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('holding a matched game keeps the channel menu and does not play',
      (tester) async {
    final games = await matchedGames();
    await open(tester, games: games);
    final card = find.byWidgetPredicate((w) =>
        w is InkWell && w.focusNode?.debugLabel == 'sports-card-nhl:game100');
    await tester.longPress(card);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('On 1 channel'), findsOneWidget);
    expect(playback.plays, isEmpty);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('first OK without a match offers the existing game menu',
      (tester) async {
    await open(tester, games: [_game(100, GameState.live)]);
    await press(tester, LogicalKeyboardKey.arrowRight);
    await press(tester, LogicalKeyboardKey.select);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Pick a channel'), findsWidgets);
    expect(playback.plays, isEmpty);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('My Teams watch opens a visible player from its own page',
      (tester) async {
    final games = await matchedGames();
    final routes = _PlayerRoutes();
    await open(tester, games: games, observer: routes);
    await tester.tap(find.text('My Teams'));
    await tester.pumpAndSettle();
    final page =
        tester.widget<SportsMyTeamsScreen>(find.byType(SportsMyTeamsScreen));
    unawaited(page.onActivate(games.first,
        [ChannelMatch(playlist.live.first, MatchReason.pick, 1000)]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(routes.channels.map((c) => c.id), ['p1::0']);
    expect(playback.plays, hasLength(1));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('See all live list retains its full-screen watch action',
      (tester) async {
    final games = await matchedGames();
    final routes = _PlayerRoutes();
    await open(tester, games: games, observer: routes);
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();
    final page =
        tester.widget<SportsLiveListScreen>(find.byType(SportsLiveListScreen));
    unawaited(page.onWatch(playlist.live.first));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(routes.channels.map((c) => c.id), ['p1::0']);
    expect(playback.plays, hasLength(1));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  for (final mode in [false, true]) {
    testWidgets('populated matchup stats fit TV large text (mode=$mode)',
        (tester) async {
      await prefs.setSportsMode(mode);
      final games = await matchedGames();
      final feed = _Feed(games,
          summary: const SportsGameSummary(teamStats: [
            ('Shots on goal', '18', '25'),
            ('Hits', '16', '21'),
            ('Power play percentage', '50%', '33%')
          ]));
      await open(tester, games: games, feed: feed, scale: 1.3);
      final card = find.byWidgetPredicate((w) =>
          w is InkWell && w.focusNode?.debugLabel == 'sports-card-nhl:game100');
      tester.widget<InkWell>(card).focusNode!.requestFocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 351));
      await tester.pump();
      expect(find.text('A100 18 · H100 25'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (Platform.environment['SPORTS_MODE_PREVIEW'] == '1') {
        await tester.runAsync(() async {
          final view =
              tester.renderObject<RenderRepaintBoundary>(find.byKey(boundary));
          final image = await view.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('build/sports-matchup-$mode.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await press(tester, LogicalKeyboardKey.select);
      expect(tester.takeException(), isNull);
      await disposePage(tester);
    });
  }

  test('Sports Mode is opt-in per viewer and survives reopening', () async {
    expect(prefs.sportsMode, isTrue);
    await storage.setActiveViewerId('other');
    expect(prefs.sportsMode, isFalse);
    await prefs.setSportsMode(true);
    final reopened = StorageService();
    await reopened.init();
    expect(reopened.getSportsMode(), isTrue);
    await reopened.setActiveViewerId('main');
    expect(reopened.getSportsMode(), isTrue);
    await storage.setActiveViewerId('main');
    await prefs.setSportsMode(false);
    await storage.setActiveViewerId('other');
    expect(prefs.sportsMode, isTrue);
  });

  for (final backup in [true, false]) {
    test(
        '${backup ? 'backup' : 'transfer'} retains Sports Mode for each viewer',
        () async {
      await storage.setActiveViewerId('other');
      await storage.setSportsMode(false);
      final payload =
          backup ? storage.exportForBackup() : storage.exportForTransfer();
      SharedPreferences.setMockInitialValues({});
      final restored = StorageService();
      await restored.init();
      if (backup) {
        await restored.importForBackup(payload);
      } else {
        await restored.importForTransfer(payload);
      }
      await restored.setActiveViewerId('main');
      expect(restored.getSportsMode(), isTrue);
      await restored.setActiveViewerId('other');
      expect(restored.getSportsMode(), isFalse);
    });
  }

  testWidgets(
      'league move crosses between rail and floating bar without losing focus',
      (tester) async {
    await open(tester, games: []);
    for (var i = 0; i < 4; i++) {
      await press(tester, LogicalKeyboardKey.arrowDown);
    }
    expect(getFocus(), 'sports-chip-league:eng.1');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(seconds: 1));
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pump();
    await press(tester, LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sports-mode-rail')), findsNothing);
    expect(find.byKey(const ValueKey('league:eng.1')).hitTestable(),
        findsOneWidget);
    expect(storage.getSportsLeagues()![5], 'eng.1');
    expect(getFocus(), 'sports-chip-league:eng.1');
    await press(tester, LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sports-mode-rail')), findsOneWidget);
    expect(find.byKey(const ValueKey('sports-mode-league:eng.1')).hitTestable(),
        findsOneWidget);
    expect(storage.getSportsLeagues()![4], 'eng.1');
    expect(getFocus(), 'sports-chip-league:eng.1');
    await press(tester, LogicalKeyboardKey.select);
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(getFocus(), 'sports-chip-league:mlb');
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  const college = 'basketball.mens-college-basketball';
  const collegeLabel = "NCAA Men's Basketball";

  Future<void> holdSelect(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 650));
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
  }

  /// A league / tool control: a chip, or a row of regular Sports Trak's
  /// league rail ('All' = its All leagues row).
  ({FocusNode focusNode, String label, bool selected}) chip(
      WidgetTester tester, String label) {
    for (final c in tester.widgetList<SportsChip>(find.byType(SportsChip))) {
      if (c.label == label) {
        return (focusNode: c.focusNode, label: c.label, selected: c.selected);
      }
    }
    for (final rail
        in tester.widgetList<SportsLeagueRail>(find.byType(SportsLeagueRail))) {
      for (final item in rail.items) {
        if (item.label == label ||
            (label == 'All' && item.id == 'league:all')) {
          return (
            focusNode: item.focusNode,
            label: label,
            selected: item.selected
          );
        }
      }
    }
    throw StateError('No control "$label"');
  }

  Future<void> manyLeagues() async {
    await storage.setSportsAddedLeagues([college]);
    await storage.setSportsLeagues([
      for (final league in kSportsLeagues) league.id,
      college,
    ]);
  }

  testWidgets(
      'vertical league reorder follows Up/Down and consumes horizontal keys',
      (tester) async {
    await open(tester, games: []);
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(getFocus(), 'sports-chip-league:nfl');
    await holdSelect(tester);
    expect(find.byIcon(Icons.swap_vert), findsOneWidget);
    final before = List<String>.of(storage.getSportsLeagues()!);
    await press(tester, LogicalKeyboardKey.arrowLeft);
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(storage.getSportsLeagues(), before);
    expect(getFocus(), 'sports-chip-league:nfl');
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(storage.getSportsLeagues()!.first, 'nfl');
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(storage.getSportsLeagues(), before);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(storage.getSportsLeagues()![3], 'nfl');
    expect(getFocus(), 'sports-chip-league:nfl');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.swap_vert), findsNothing);
    expect(find.text('Stay'), findsNothing);
    await disposePage(tester);
  });

  for (final size in [const Size(390, 844), const Size(700, 600)]) {
    testWidgets(
        'horizontal league strip uses Left/Right with matching indicator at $size',
        (tester) async {
      await open(tester, games: [], size: size);
      await holdSelect(tester);
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
      expect(find.byIcon(Icons.swap_vert), findsNothing);
      final before = List<String>.of(storage.getSportsLeagues()!);
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(storage.getSportsLeagues(), before);
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(storage.getSportsLeagues()![1], before.first);
      await press(tester, LogicalKeyboardKey.arrowLeft);
      expect(storage.getSportsLeagues(), before);
      await press(tester, LogicalKeyboardKey.select);
      expect(find.byIcon(Icons.swap_horiz), findsNothing);
      expect(tester.takeException(), isNull);
      await disposePage(tester);
    });
  }

  testWidgets('reorder adapts its axis when the layout changes orientation',
      (tester) async {
    await open(tester, games: []);
    await press(tester, LogicalKeyboardKey.arrowDown);
    await holdSelect(tester);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(storage.getSportsLeagues()![2], 'nfl');
    tester.view.physicalSize = const Size(960, 540);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.swap_vert), findsOneWidget);
    expect(find.byKey(const ValueKey('sports-mode-rail')), findsOneWidget);
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(storage.getSportsLeagues()![1], 'nfl');
    await press(tester, LogicalKeyboardKey.select);
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets(
      'promoted college league stays visible and Back remembers its new rail position',
      (tester) async {
    await storage.setSportsAddedLeagues([college]);
    await storage
        .setSportsLeagues(['nhl', 'nfl', 'nba', 'eng.1', 'mlb', college]);
    await open(tester, games: []);
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(getFocus(), 'sports-chip-league:all');
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(getFocus(), 'sports-chip-league:$college');
    await holdSelect(tester);
    await press(tester, LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(storage.getSportsLeagues()![4], college);
    expect(storage.getSportsLeagues()![5], 'mlb');
    expect(find.byKey(const ValueKey('sports-mode-rail')), findsOneWidget);
    expect(
        find
            .byKey(const ValueKey(
                'sports-mode-league:basketball.mens-college-basketball'))
            .hitTestable(),
        findsOneWidget);
    expect(getFocus(), 'sports-chip-league:$college');
    // Finish with Back, leave the rail, then return with Back: parent focus
    // state and the remembered rail entry must match the reparented node.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Stay'), findsNothing);
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(find.byKey(const ValueKey('sports-mode-rail')), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(getFocus(), 'sports-chip-league:$college');
    expect(find.byKey(const ValueKey('sports-mode-rail')), findsOneWidget);
    expect(find.text('Stay'), findsNothing);
    expect(storage.getSportsLeagues(), containsAll(['mlb', college]));
    await disposePage(tester);
  });

  testWidgets(
      'Sports Mode All dropdown exposes quiet and offscreen leagues and restores focus',
      (tester) async {
    await manyLeagues();
    await storage.setSportsFavoriteLeague('mlb');
    final feed = _Feed([]);
    await open(tester, feed: feed);
    final target =
        find.byKey(const ValueKey('league:basketball.mens-college-basketball'));
    expect(tester.getRect(target).left, greaterThan(960));
    final all = tester
        .widgetList<SportsChip>(find.byType(SportsChip))
        .firstWhere((c) => c.label == 'All');
    expect(
        find.descendant(
            of: find.byWidget(all), matching: find.byIcon(Icons.expand_more)),
        findsOneWidget);
    all.focusNode.requestFocus();
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Your leagues'), findsOneWidget);
    expect(find.text('All leagues'), findsOneWidget);
    expect(find.text('No games'), findsWidgets);
    final pick = find.text(collegeLabel).last;
    await tester.ensureVisible(pick);
    await tester.pumpAndSettle();
    await tester.tap(pick);
    await tester.pumpAndSettle();
    expect(feed.requests.last, [college]);
    expect(chip(tester, sportsLeagueById(college)!.shortName).selected, isTrue);
    expect(getFocus(), 'sports-chip-league:all');
    expect(storage.getSportsLeagues(), containsAll(['mlb', college]));
    // Hold remains an alternate way to open the same menu; cancellation
    // must not clear the selected league or strand focus in the dialog.
    await holdSelect(tester);
    expect(find.text('Your leagues'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(chip(tester, sportsLeagueById(college)!.shortName).selected, isTrue);
    expect(getFocus(), 'sports-chip-league:all');
    await press(tester, LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    final clear = find.text('All leagues');
    await tester.ensureVisible(clear);
    await tester.pumpAndSettle();
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(feed.requests.last, containsAll(['mlb', college]));
    expect(chip(tester, 'All').selected, isTrue);
    expect(getFocus(), 'sports-chip-league:all');
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets(
      'league manager can add college without hiding MLB and dropdown can select it',
      (tester) async {
    await storage
        .setSportsLeagues([for (final league in kSportsLeagues) league.id]);
    await storage.setSportsFavoriteLeague('mlb');
    final feed = _Feed([]);
    await open(tester, feed: feed);
    chip(tester, 'Edit leagues').focusNode.requestFocus();
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.select);
    expect(find.byType(SportsLeagueManagerScreen), findsOneWidget);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('bank:basketball.mens-college-basketball')),
        400,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 150);
    await tester.tap(
        find.byKey(const ValueKey('bank:basketball.mens-college-basketball')));
    await tester.pumpAndSettle();
    expect(storage.getSportsLeagues(),
        containsAll([for (final l in kSportsLeagues) l.id, college]));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    chip(tester, 'All').focusNode.requestFocus();
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    final choice = find.text(collegeLabel).last;
    await tester.ensureVisible(choice);
    await tester.pumpAndSettle();
    await tester.tap(choice);
    await tester.pumpAndSettle();
    expect(feed.requests.last, [college]);
    expect(storage.getSportsLeagues(), containsAll(['mlb', college]));
    await disposePage(tester);
  });

  testWidgets('regular Sports Trak keeps All tap and rail league reorder',
      (tester) async {
    await prefs.setSportsMode(false);
    await storage.setSportsFavoriteLeague('mlb');
    final feed = _Feed([]);
    await open(tester, feed: feed);
    chip(tester, 'All').focusNode.requestFocus();
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Your leagues'), findsNothing);
    expect(chip(tester, 'All').selected, isTrue);
    expect(feed.requests.last, containsAll(['mlb', 'nhl']));
    await holdSelect(tester);
    expect(find.text('Your leagues'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    chip(tester, 'NFL').focusNode.requestFocus();
    await tester.pumpAndSettle();
    await holdSelect(tester);
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(storage.getSportsLeagues()!.first, 'nfl');
    await press(tester, LogicalKeyboardKey.select);
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  for (final mode in [false, true]) {
    testWidgets(
        'compact league strip keeps full names in Edit leagues: mode=$mode',
        (tester) async {
      await prefs.setSportsMode(mode);
      await storage.setSportsAddedLeagues(['hockey.ahl', 'racing.f1']);
      await storage.setSportsLeagues([
        'nhl',
        'nfl',
        'nba',
        'mlb',
        'eng.1',
        'uefa.champions',
        'hockey.ahl',
        'racing.f1',
      ]);
      await open(tester, games: []);
      expect(chip(tester, 'AHL').label, 'AHL');
      expect(chip(tester, 'UCL').label, 'UCL');
      expect(chip(tester, 'F1').label, 'F1');
      expect(find.byKey(const ValueKey('league:quality')), findsNothing);
      expect(find.text('Prefer highest quality'), findsNothing);
      chip(tester, 'Edit leagues').focusNode.requestFocus();
      await tester.pumpAndSettle();
      // Removing the quality chip must not leave a dead remote-focus slot.
      // Regular Sports Trak: the league rail runs top to bottom.
      await press(tester,
          mode ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowDown);
      expect(getFocus(), 'sports-chip-league:scores');
      chip(tester, 'Edit leagues').focusNode.requestFocus();
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.select);
      final ahl = find.byKey(const ValueKey('yours:hockey.ahl'));
      await tester.scrollUntilVisible(ahl, 300,
          scrollable: find
              .descendant(
                  of: find.byType(SportsLeagueManagerScreen),
                  matching: find.byType(Scrollable))
              .first,
          maxScrolls: 30);
      expect(
          find.descendant(
              of: ahl, matching: find.text('American Hockey League')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposePage(tester);
    });
  }

  testWidgets('returning from quality settings re-ranks existing game matches',
      (tester) async {
    final game = _game(0, GameState.pre);
    playlist.live = [
      for (final quality in ['HD', '4K'])
        Channel(
          id: 'p1::$quality',
          rawId: quality,
          playlistId: 'p1',
          name: 'Home 0 vs Away 0 $quality',
          group: 'Sports',
          url: 'https://test/$quality',
        ),
    ];
    await open(tester, games: [game]);
    await tester.pumpAndSettle();
    expect(find.text('Home 0 vs Away 0 4K'), findsWidgets);
    Navigator.of(tester.element(find.byType(SportsScreen))).push(
        MaterialPageRoute<void>(
            builder: (_) => const SportsQualitySettingsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(storage.getSportsPreferQuality(), isFalse);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Home 0 vs Away 0 HD'), findsWidgets);
    expect(find.text('Home 0 vs Away 0 4K'), findsNothing);
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('Networks Back returns to its action in the sports home',
      (tester) async {
    await open(tester, games: []);
    tester
        .widgetList<SportsChip>(find.byType(SportsChip))
        .firstWhere((chip) => chip.label == 'Networks')
        .focusNode
        .requestFocus();
    await tester.pump();
    await press(tester, LogicalKeyboardKey.select);
    expect(find.byType(SportsChannelsScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SportsChannelsScreen), findsNothing);
    expect(getFocus(), 'sports-chip-networks');
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  Future<void> openLivePanel(WidgetTester tester,
      {List<SportsGame>? games = const [],
      double scale = 1,
      NavigatorObserver? observer}) async {
    playlist.live = [
      for (var i = 0; i < 40; i++)
        Channel(
            id: 'p1::c$i',
            rawId: 'c$i',
            playlistId: 'p1',
            name: 'Channel $i',
            group: 'Sports',
            url: 'http://example.invalid/$i.ts'),
    ];
    addTearDown(() => playlist.live = const []);
    await open(tester, games: games, scale: scale, observer: observer);
    for (var i = 0; i < 5; i++) {
      await press(tester, LogicalKeyboardKey.arrowDown);
    }
    expect(getFocus(), 'sports-chip-mode:tv');
    await press(tester, LogicalKeyboardKey.select);
  }

  testWidgets('remote Guide opens the Live TV panel; the game keeps playing',
      (tester) async {
    final games = await matchedGames();
    await open(tester, games: games);
    await press(tester, LogicalKeyboardKey.arrowRight);
    await press(tester, LogicalKeyboardKey.select); // game in the big player
    expect(playback.plays.map((c) => c.id), ['p1::0']);
    final stops = playback.stops;
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(
        GuideKey.handle(
            const KeyDownEvent(
                physicalKey: PhysicalKeyboardKey(0x110000016a),
                logicalKey: LogicalKeyboardKey(0x11000000e4),
                timeStamp: Duration.zero),
            navigator: navigator),
        isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TvHomeScreen), findsNothing);
    expect(find.byKey(const ValueKey('sports-live-panel')), findsOneWidget);
    expect(getFocus(), 'sports-live-guide');
    expect(playback.stops, stops);
    expect(playback.plays, hasLength(1));
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets(
      'Live TV guide: OK plays in the Sports Mode player, again full screen',
      (tester) async {
    final routes = _PlayerRoutes();
    await openLivePanel(tester, observer: routes);
    for (var i = 0; i < 3; i++) {
      await press(tester, LogicalKeyboardKey.arrowDown);
    }
    await press(tester, LogicalKeyboardKey.select); // the group's guide
    expect(getFocus(), 'sports-live-guide');
    await press(tester, LogicalKeyboardKey.select);
    expect(playback.plays.map((c) => c.id), ['p1::c0']);
    expect(routes.channels, isEmpty);
    // The Sports Mode player (no games today: the same player alone).
    expect(find.byKey(const ValueKey('sports-mode-player')), findsOneWidget);
    expect(getFocus(), 'sports-live-guide');
    await press(tester, LogicalKeyboardKey.select);
    expect(routes.channels.map((c) => c.id), ['p1::c0']);
    expect(playback.plays, hasLength(1)); // same session, no reconnect
    final stops = playback.stops;
    // Back: guide, then the panel close; the stream stays in its player.
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('sports-live-panel')), findsNothing);
    expect(find.byKey(const ValueKey('sports-mode-player')), findsOneWidget);
    expect(playback.stops, stops);
    // Back on the page opens the rail, still playing; Back there stops it.
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('sports-mode-rail')), findsOneWidget);
    expect(playback.stops, stops);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(playback.stops, greaterThan(stops));
    expect(find.byKey(const ValueKey('sports-mode-player')), findsNothing);
    // Back again quits (the exit prompt; Who's watching when that's on).
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Stay'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets(
      'Live TV guide keeps focus when a channel starts beside game cards',
      (tester) async {
    // User report (Shield, 1.0.48): games today, none previewing; OK on a
    // guide channel left the selector on the page under the guide.
    final routes = _PlayerRoutes();
    await openLivePanel(tester, games: await matchedGames(), observer: routes);
    for (var i = 0; i < 3; i++) {
      await press(tester, LogicalKeyboardKey.arrowDown);
    }
    await press(tester, LogicalKeyboardKey.select); // the group's guide
    expect(getFocus(), 'sports-live-guide');
    await press(tester, LogicalKeyboardKey.select); // plays beside the cards
    await tester.pump(const Duration(milliseconds: 500));
    expect(getFocus(), 'sports-live-guide');
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(getFocus(), 'sports-live-guide');
    await press(tester, LogicalKeyboardKey.select); // another channel
    await tester.pump(const Duration(milliseconds: 500));
    expect(getFocus(), 'sports-live-guide');
    await press(tester, LogicalKeyboardKey.select); // full screen
    expect(routes.channels, hasLength(1));
    // The observer closes full screen at once: back beside the guide.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('sports-live-guide')), findsOneWidget);
    expect(getFocus(), 'sports-live-guide');
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('a guide channel takes the big game player beside the feed',
      (tester) async {
    final games = await matchedGames();
    await open(tester, games: games);
    await press(tester, LogicalKeyboardKey.arrowRight);
    await press(tester, LogicalKeyboardKey.select); // game: big player
    expect(find.byKey(const ValueKey('sports-mode-feed')), findsOneWidget);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(
        GuideKey.handle(
            const KeyDownEvent(
                physicalKey: PhysicalKeyboardKey(0x110000016a),
                logicalKey: LogicalKeyboardKey(0x11000000e4),
                timeStamp: Duration.zero),
            navigator: navigator),
        isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(getFocus(), 'sports-live-guide');
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.select); // the other channel
    expect(playback.plays.map((c) => c.id), ['p1::0', 'p1::1']);
    // Still the feed layout's big player, now with the guide channel.
    expect(find.byKey(const ValueKey('sports-mode-feed')), findsOneWidget);
    expect(getFocus(), 'sports-live-guide');
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('Live TV groups: Right moves into the sports page, OK opens',
      (tester) async {
    await openLivePanel(tester);
    expect(getFocus(), 'sports-live-groups');
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(find.byKey(const ValueKey('sports-live-guide')), findsNothing);
    expect(find.byKey(const ValueKey('sports-live-panel')), findsOneWidget);
    expect(getFocus(), isNot(startsWith('sports-live')));
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('Live TV groups: Left from the page returns to them',
      (tester) async {
    await openLivePanel(tester);
    await press(tester, LogicalKeyboardKey.arrowRight); // into the page
    expect(getFocus(), isNot(startsWith('sports-live')));
    await press(tester, LogicalKeyboardKey.arrowLeft);
    expect(getFocus(), 'sports-live-groups');
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('Live TV opens groups and guide inside Sports Mode; Back x3',
      (tester) async {
    await openLivePanel(tester);
    expect(find.byType(TvHomeScreen), findsNothing);
    expect(getFocus(), 'sports-live-groups');
    expect(find.byKey(const ValueKey('sports-live-guide')), findsNothing);
    // Open full Live TV, Favourites, then the provider group (the last row).
    for (var i = 0; i < 3; i++) {
      await press(tester, LogicalKeyboardKey.arrowDown);
    }
    await press(tester, LogicalKeyboardKey.select);
    expect(getFocus(), 'sports-live-guide');
    expect(find.text('Channel 0'), findsOneWidget);
    // Lazy, fixed-extent rows: the last channel is not built yet.
    expect(find.text('Channel 39'), findsNothing);
    for (var i = 0; i < 39; i++) {
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }
    await tester.pump();
    expect(find.text('Channel 39'), findsOneWidget);
    // Left = groups, the guide stays; Right = back into it.
    await press(tester, LogicalKeyboardKey.arrowLeft);
    expect(getFocus(), 'sports-live-groups');
    expect(find.byKey(const ValueKey('sports-live-guide')), findsOneWidget);
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(getFocus(), 'sports-live-guide');
    // Back: guide closes, then groups close, then the page (no exit prompt).
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const ValueKey('sports-live-guide')), findsNothing);
    expect(getFocus(), 'sports-live-groups');
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('sports-live-panel')), findsNothing);
    expect(getFocus(), isNot('sports-chip-mode:tv'));
    expect(find.text('Stay'), findsNothing);
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('Live TV panel beside game rows fits with large text',
      (tester) async {
    await openLivePanel(tester, games: null, scale: 1.3);
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.select);
    expect(getFocus(), 'sports-live-guide');
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('Live TV panel: Left = rail, Back there closes the panel',
      (tester) async {
    await openLivePanel(tester);
    await press(tester, LogicalKeyboardKey.arrowLeft);
    expect(getFocus(), 'sports-chip-mode:tv');
    expect(find.byKey(const ValueKey('sports-live-panel')), findsOneWidget);
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(getFocus(), 'sports-live-groups');
    await press(tester, LogicalKeyboardKey.arrowLeft);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('sports-live-panel')), findsNothing);
    expect(getFocus(), 'sports-chip-mode:tv');
    expect(find.text('Stay'), findsNothing);
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('Open full Live TV returns to sports instead of asking to exit',
      (tester) async {
    await openLivePanel(tester);
    // The panel reopens on the last group: go up to its first row.
    for (var i = 0; i < 3; i++) {
      await press(tester, LogicalKeyboardKey.arrowUp);
    }
    await press(tester, LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.byType(TvHomeScreen).hitTestable(), findsOneWidget);
    for (var i = 0;
        i < 3 && find.byType(TvHomeScreen).hitTestable().evaluate().isNotEmpty;
        i++) {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
    expect(find.byType(TvHomeScreen), findsNothing);
    expect(find.text('Stay'), findsNothing);
    expect(getFocus(), 'sports-chip-mode:tv');
    if (!Platform.isWindows) expect(playback.stops, greaterThan(0));
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('Home, Search and Multiview sit behind the rail Menu',
      (tester) async {
    await open(tester, games: []);
    final first = getFocus();
    expect(first, startsWith('sports-chip-league:'));
    await press(tester, LogicalKeyboardKey.arrowUp);
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'sports-mode-menu');
    await press(tester, LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    for (final label in ['Home', 'Search', 'Multiview']) {
      expect(find.text(label), findsWidgets);
    }
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(getFocus(), first);
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('phone: Back opens the Menu with every destination',
      (tester) async {
    await open(tester, games: [], size: const Size(390, 844));
    await press(tester, LogicalKeyboardKey.arrowRight);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    for (final label in ['Home', 'Search', 'Live TV', 'Movies', 'Settings']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('Stay'), findsNothing);
    await tester.binding.handlePopRoute(); // closes the menu
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute(); // then asks to exit
    await tester.pumpAndSettle();
    expect(find.text('Stay'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    await disposePage(tester);
  });

  testWidgets('five leagues on rail; explicit bar/day/tool arrows and Back',
      (tester) async {
    await open(tester);
    expect(find.byKey(const ValueKey('sports-mode-rail')), findsOneWidget);
    expect(getFocus(), 'sports-chip-league:nhl');
    final rail = tester.getRect(find.byKey(const ValueKey('sports-mode-rail')));
    expect(rail.width, lessThan(200));
    expect(
        find.byKey(const ValueKey('sports-mode-league:eng.1')), findsOneWidget);
    expect(find.byKey(const ValueKey('sports-mode-league:uefa.champions')),
        findsNothing);
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(getFocus(), 'sports-card-nhl:game100');
    // The rail hides while the content has focus; a tab marks the edge.
    expect(find.byKey(const ValueKey('sports-mode-rail')), findsNothing);
    expect(find.byKey(const ValueKey('sports-mode-rail-tab')), findsOneWidget);
    await press(tester, LogicalKeyboardKey.arrowUp); // tools, day menu first
    expect(getFocus(), 'sports-chip-day:menu');
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(getFocus(), 'sports-chip-standings');
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(getFocus(), 'sports-chip-myteams');
    await press(tester, LogicalKeyboardKey.arrowUp); // no day strip
    expect(getFocus(), 'sports-chip-league:all');
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(getFocus(), 'sports-chip-league:uefa.champions');
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(getFocus(), 'sports-chip-myteams');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(getFocus(), 'sports-chip-league:nhl');
    expect(find.byKey(const ValueKey('sports-mode-rail')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Stay'), findsOneWidget);
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(prefs.sportsMode, isTrue);
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets(
      'long game rows scroll horizontally and vertically and remember selection',
      (tester) async {
    await open(tester);
    await press(tester, LogicalKeyboardKey.arrowRight);
    await press(tester, LogicalKeyboardKey.arrowDown); // first card in next row
    expect(getFocus(), 'sports-card-nhl:game0');
    for (var i = 0; i < 17; i++) {
      await press(tester, LogicalKeyboardKey.arrowRight);
    }
    expect(getFocus(), 'sports-card-nhl:game17');
    final selected =
        tester.getRect(find.byKey(const ValueKey('card-nhl:game17')));
    expect(selected.right, lessThanOrEqualTo(970));
    expect(selected.left, greaterThan(170));
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(getFocus(), 'sports-card-nhl:game200');
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(getFocus(), 'sports-card-nhl:game17');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(getFocus(), 'sports-card-nhl:game17');
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('loading and empty days retain working rail and header controls',
      (tester) async {
    final gate = Completer<void>();
    await open(tester, feed: _Feed([], gate: gate));
    expect(getFocus(), 'sports-chip-league:nhl');
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(getFocus(), 'sports-chip-league:nfl');
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(getFocus(), 'sports-chip-league:all');
    gate.complete();
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(getFocus(), 'sports-chip-day:menu');
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(getFocus(), 'sports-chip-day:menu');
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(getFocus(), 'sports-chip-standings');
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets(
      'sidebar scroll reaches Sports Mode; switching off returns to root',
      (tester) async {
    await open(tester, games: []);
    for (var i = 0; i < 20; i++) {
      await press(tester, LogicalKeyboardKey.arrowDown);
    }
    expect(getFocus(), 'sports-chip-mode:toggle');
    await press(tester, LogicalKeyboardKey.select);
    expect(find.byType(SportsModeToggle), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(prefs.sportsMode, isFalse);
    expect(playback.stops, greaterThan(0));
    expect(Navigator.of(tester.element(find.byType(SportsScreen))).canPop(),
        isFalse);
    await disposePage(tester);
  });

  testWidgets('normal Sports Trak exposes the same Sports Mode switch',
      (tester) async {
    await prefs.setSportsMode(false);
    await open(tester, games: []);
    expect(find.byKey(const ValueKey('sports-mode-rail')), findsNothing);
    chip(tester, 'Sports Mode').focusNode.requestFocus();
    await tester.pump();
    await press(tester, LogicalKeyboardKey.select);
    expect(find.byType(SportsModeToggle), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(prefs.sportsMode, isTrue);
    expect(find.byKey(const ValueKey('sports-mode-rail'), skipOffstage: false),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('day menu replaces the day strip and changes the day',
      (tester) async {
    await open(tester, games: []);
    await press(tester, LogicalKeyboardKey.arrowRight); // league:all
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(getFocus(), 'sports-chip-day:menu');
    expect(find.text('Yesterday'), findsNothing);
    await press(tester, LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Yesterday'), findsOneWidget);
    await press(tester, LogicalKeyboardKey.arrowDown); // Today -> Tomorrow
    await press(tester, LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Yesterday'), findsNothing);
    expect(
        tester
            .widget<SportsChip>(find.byWidgetPredicate((w) =>
                w is SportsChip &&
                w.focusNode.debugLabel == 'sports-chip-day:menu'))
            .label,
        'Tomorrow');
    expect(getFocus(), 'sports-chip-day:menu');
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  for (final size in [const Size(390, 844), const Size(960, 540)]) {
    testWidgets('game content fits $size with large text', (tester) async {
      L10n.code = 'el';
      await open(tester, size: size, scale: 1.5);
      expect(tester.takeException(), isNull);
      await press(tester, LogicalKeyboardKey.arrowRight);
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(tester.takeException(), isNull);
      await disposePage(tester);
    });
  }

  for (final locale in ['en', 'fr', 'el']) {
    testWidgets('narrow $locale large text keeps all controls reachable',
        (tester) async {
      L10n.code = locale;
      await open(tester, games: [], size: const Size(390, 844), scale: 1.4);
      await press(tester, LogicalKeyboardKey.arrowRight);
      await press(tester, LogicalKeyboardKey.arrowDown); // day menu
      await press(tester, LogicalKeyboardKey.arrowRight);
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(getFocus(), 'sports-chip-myteams');
      expect(tester.takeException(), isNull);
      await disposePage(tester);
    });
  }

  SportsGame leagueGame(String id) {
    final base = _game(1, GameState.pre);
    return SportsGame(
        id: id,
        league: sportsLeagueById(id)!,
        start: base.start,
        state: base.state,
        statusText: base.statusText,
        home: base.home,
        away: base.away);
  }

  Finder leagueControl(String id) => find.byWidgetPredicate((widget) =>
      widget.key == ValueKey('league:$id') ||
      widget.key == ValueKey('rail-league:$id') ||
      widget.key == ValueKey('sports-mode-league:$id'));

  for (final mode in [false, true]) {
    for (final size in [const Size(960, 540), const Size(390, 844)]) {
      testWidgets(
          'empty leagues hide in navigation only; failed schedules remain (mode=$mode, $size)',
          (tester) async {
        await prefs.setSportsMode(mode);
        await storage.setSportsHideEmptyLeagues(true);
        final saved = List<String>.of(storage.getSportsLeagues()!);
        await open(tester,
            size: size,
            feed: _Feed([], days: {
              0: [leagueGame('nhl'), leagueGame('esp.1')]
            }, unavailable: {
              'nfl'
            }));
        for (final id in ['nhl', 'nfl', 'esp.1']) {
          expect(leagueControl(id), findsOneWidget);
        }
        for (final id in ['nba', 'mlb', 'eng.1', 'uefa.champions']) {
          expect(leagueControl(id), findsNothing);
        }
        expect(storage.getSportsLeagues(), saved);
        expect(tester.takeException(), isNull);
        await disposePage(tester);
      });
    }
  }

  testWidgets(
      'disabled hiding preserves favorite-only loading and every saved league',
      (tester) async {
    await storage.setSportsFavoriteLeague('nfl');
    final feed = _Feed([], days: {
      0: [leagueGame('nhl')]
    });
    await open(tester, feed: feed);
    expect(feed.requests.first, ['nfl']);
    for (final id in storage.getSportsLeagues()!) {
      expect(leagueControl(id), findsOneWidget);
    }
    expect(getFocus(), 'sports-chip-league:nfl');
    await disposePage(tester);
  });

  testWidgets(
      'empty favorite falls back to All without changing saved favorite or order',
      (tester) async {
    await storage.setSportsHideEmptyLeagues(true);
    await storage.setSportsFavoriteLeague('nfl');
    final saved = List<String>.of(storage.getSportsLeagues()!);
    final feed = _Feed([], days: const {});
    await open(tester, feed: feed);
    expect(feed.requests.first, saved);
    for (final id in saved) {
      expect(leagueControl(id), findsNothing);
    }
    expect(chip(tester, 'All').selected, true);
    expect(leagueControl('edit'), findsOneWidget);
    expect(storage.getSportsFavoriteLeague(), 'nfl');
    expect(storage.getSportsLeagues(), saved);
    expect(tester.takeException(), null);
    await disposePage(tester);
  });

  testWidgets(
      'hiding follows Tomorrow and loads all leagues even with a league selected',
      (tester) async {
    await prefs.setSportsMode(false);
    await storage.setSportsHideEmptyLeagues(true);
    final feed = _Feed([], days: {
      0: [leagueGame('nhl')],
      1: [leagueGame('esp.1')]
    });
    await open(tester, feed: feed);
    chip(tester, 'NHL').focusNode.requestFocus();
    await press(tester, LogicalKeyboardKey.select);
    expect(feed.requests.last, storage.getSportsLeagues());
    final tomorrow = chip(tester, 'Tomorrow');
    tomorrow.focusNode.requestFocus();
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(leagueControl('nhl'), findsNothing);
    expect(leagueControl('esp.1'), findsOneWidget);
    expect(chip(tester, 'All').selected, true);
    expect(getFocus(), 'sports-chip-day:1');
    expect(tester.takeException(), null);
    await disposePage(tester);
  });

  testWidgets(
      'refresh restores focus when a league vanishes or crosses the top-five boundary',
      (tester) async {
    await storage.setSportsHideEmptyLeagues(true);
    final days = {
      0: [for (final id in storage.getSportsLeagues()!) leagueGame(id)]
    };
    final feed = _Feed([], days: days);
    await open(tester, feed: feed);
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(getFocus(), 'sports-chip-league:nfl');
    days[0] = [leagueGame('esp.1')];
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(getFocus(), 'sports-chip-league:esp.1');
    expect(leagueControl('nfl'), findsNothing);
    days[0] = [for (final id in storage.getSportsLeagues()!) leagueGame(id)];
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(getFocus(), 'sports-chip-league:esp.1');
    expect(find.byKey(const ValueKey('league:esp.1')), findsOneWidget);
    expect(tester.takeException(), null);
    await disposePage(tester);
  });

  testWidgets(
      'disabling hiding restores full navigation and focus after returning from settings',
      (tester) async {
    await storage.setSportsHideEmptyLeagues(true);
    await open(tester,
        feed: _Feed([], days: {
          0: [leagueGame('esp.1')]
        }));
    expect(getFocus(), 'sports-chip-league:esp.1');
    await storage.setSportsHideEmptyLeagues(false);
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    // The rail collapses when the focused league moves into the floating
    // bar; all league destinations must still be present in its entries.
    expect(
        tester
            .widget<SportsModeShell>(find.byType(SportsModeShell))
            .entries
            .map((entry) => entry.id),
        containsAll(
            storage.getSportsLeagues()!.take(5).map((id) => 'league:$id')));
    for (final id in storage.getSportsLeagues()!.skip(5)) {
      expect(leagueControl(id), findsOneWidget);
    }
    expect(getFocus(), 'sports-chip-league:esp.1');
    expect(tester.takeException(), null);
    await disposePage(tester);
  });

  testWidgets(
      'previously empty leagues return when a refresh becomes unavailable',
      (tester) async {
    await storage.setSportsHideEmptyLeagues(true);
    final unavailable = <String>{};
    await open(tester,
        feed: _Feed([], days: const {}, unavailable: unavailable));
    expect(leagueControl('nfl'), findsNothing);
    unavailable.add('nfl');
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(leagueControl('nfl'), findsOneWidget);
    expect(leagueControl('nhl'), findsNothing);
    expect(tester.takeException(), null);
    await disposePage(tester);
  });

  testWidgets(
      'reordering skips hidden leagues and preserves full saved membership',
      (tester) async {
    await storage.setSportsHideEmptyLeagues(true);
    final days = {
      0: [leagueGame('nhl'), leagueGame('nba')]
    };
    await open(tester, feed: _Feed([], days: days));
    final saved = List<String>.of(storage.getSportsLeagues()!);
    await holdSelect(tester);
    await press(tester, LogicalKeyboardKey.arrowDown);
    final after = storage.getSportsLeagues()!;
    expect(after.indexOf('nba'), lessThan(after.indexOf('nhl')));
    expect(after.toSet(), saved.toSet());
    expect(leagueControl('nfl'), findsNothing);
    expect(getFocus(), 'sports-chip-league:nhl');
    days[0] = [leagueGame('nba')];
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(
        leagueControl('nhl'), findsOneWidget); // finish the move before hiding
    await press(tester, LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(leagueControl('nhl'), findsNothing);
    expect(getFocus(), 'sports-chip-league:nba');
    expect(tester.takeException(), null);
    await disposePage(tester);
  });

  testWidgets('loading does not hide leagues before schedule confirmation',
      (tester) async {
    await storage.setSportsHideEmptyLeagues(true);
    final gate = Completer<void>();
    await open(tester, feed: _Feed([], gate: gate, days: const {}));
    for (final id in storage.getSportsLeagues()!) {
      expect(leagueControl(id), findsOneWidget);
    }
    gate.complete();
    await tester.pumpAndSettle();
    for (final id in storage.getSportsLeagues()!) {
      expect(leagueControl(id), findsNothing);
    }
    expect(tester.takeException(), null);
    await disposePage(tester);
  });

  testWidgets('dedicated My Teams row has no duplicate card focus nodes',
      (tester) async {
    await storage.setSportsFollowedTeams(['nhl|home0']);
    prefs.setRefinedFinish(true);
    await open(tester, size: const Size(1280, 720));
    if (Platform.environment['SPORTS_MODE_PREVIEW'] == '1') {
      await tester.runAsync(() async {
        final view =
            tester.renderObject<RenderRepaintBoundary>(find.byKey(boundary));
        final image = await view.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('Logs/sports-mode-wide.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    expect(find.byKey(const ValueKey('card-nhl:game0')), findsOneWidget);
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(getFocus(), 'sports-card-nhl:game0');
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('regular Sports Trak: league rail expands and links to the page',
      (tester) async {
    await prefs.setSportsMode(false);
    await open(tester, games: []);
    await tester.pumpAndSettle();
    expect(find.byType(SportsLeagueRail), findsOneWidget);
    expect(getFocus(), 'sports-chip-league:all');
    expect(find.text('All leagues'), findsNothing);
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(getFocus(), 'sports-chip-rail:expand');
    await press(tester, LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(storage.getSportsRailExpanded(), isTrue);
    expect(find.text('All leagues'), findsOneWidget);
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(getFocus(), 'sports-chip-league:nhl');
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(getFocus(), startsWith('sports-chip-day:'));
    chip(tester, 'Yesterday').focusNode.requestFocus();
    await tester.pump();
    await press(tester, LogicalKeyboardKey.arrowLeft);
    expect(getFocus(), 'sports-chip-league:all');
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('hold OK > Play in Multiview opens the checked live games',
      (tester) async {
    await prefs.setSportsMode(false);
    final games = await matchedGames();
    final routes = _MultiviewRoutes();
    await open(tester, games: games, observer: routes);
    await tester.pumpAndSettle();
    InkWell card(String id) => tester.widget<InkWell>(find.byWidgetPredicate(
        (w) => w is InkWell && w.focusNode?.debugLabel == 'sports-card-$id'));
    card('nhl:game100').focusNode!.requestFocus();
    await tester.pump();
    await holdSelect(tester);
    final entry = find.text('Play in Multiview');
    await tester.scrollUntilVisible(entry, 120,
        scrollable: find
            .descendant(
                of: find.byType(Dialog), matching: find.byType(Scrollable))
            .first);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget);
    card('nhl:game101').focusNode!.requestFocus();
    await tester.pump();
    await press(tester, LogicalKeyboardKey.select);
    expect(find.byIcon(Icons.check), findsNWidgets(2));
    expect(playback.plays, isEmpty);
    await press(tester, LogicalKeyboardKey.mediaPlayPause);
    await tester.pumpAndSettle();
    expect(routes.channels.map((c) => c.id), ['p1::0', 'p1::1']);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('Live now group: one row per game, hold OK = its sources',
      (tester) async {
    Channel ch(String id) => Channel(
        id: 'p1::$id',
        rawId: id,
        playlistId: 'p1',
        name: 'Channel $id',
        group: 'Sports',
        url: 'https://test/$id');
    final played = <String>[];
    final panel = GlobalKey<SportsModeLivePanelState>();
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          ChangeNotifierProvider<AppPreferences>.value(value: prefs),
          ChangeNotifierProvider<PlaylistManager>.value(value: playlist),
          ChangeNotifierProvider<EpgService>(create: (_) => _Epg(storage)),
          ChangeNotifierProvider<PlaybackService>.value(value: playback),
        ],
        child: MaterialApp(
            home: Scaffold(
                body: Align(
          alignment: Alignment.centerLeft,
          child: SportsModeLivePanel(
            key: panel,
            onPlay: (c, _) async => played.add(c.id),
            liveGames: () async => [
              (
                id: 'g1',
                title: 'A vs B',
                note: "16'",
                channels: [ch('1'), ch('2')]
              ),
              (id: 'g2', title: 'C vs D', note: "18'", channels: [ch('3')]),
            ],
          ),
        )))));
    await tester.pumpAndSettle();
    final group = find.text('Live now');
    expect(group, findsOneWidget);
    await tester.tap(group);
    await tester.pumpAndSettle();
    expect(find.text('Channel 1'), findsOneWidget);
    expect(find.text('Channel 2'), findsNothing);
    expect(find.text('Channel 3'), findsOneWidget);
    expect(find.textContaining('2 sources'), findsOneWidget);
    // Hold OK on the first game: its sources.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(played, isEmpty);
    expect(find.text('Channel 2'), findsOneWidget);
    expect(find.text('Channel 3'), findsNothing);
    // Back: the games again; a short OK plays the best channel.
    expect(panel.currentState!.back(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Channel 3'), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(played, ['p1::1']);
    expect(tester.takeException(), isNull);
  });
}

/// Records Multiview pushes and removes them (no video in a widget test).
class _MultiviewRoutes extends NavigatorObserver {
  final List<Channel> channels = [];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute == null || route is! MaterialPageRoute) return;
    final page = route.builder(navigator!.context);
    if (page is! MultiviewScreen) return;
    channels.addAll(page.initialChannels);
    scheduleMicrotask(() => navigator!.removeRoute(route));
  }
}
