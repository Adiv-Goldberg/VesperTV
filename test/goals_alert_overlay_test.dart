import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nox_iptv/services/app_preferences.dart';
import 'package:nox_iptv/models/sports.dart';
import 'package:nox_iptv/services/catalog_database.dart';
import 'package:nox_iptv/services/game_reminders.dart';
import 'package:nox_iptv/services/goals_alerts.dart';
import 'package:nox_iptv/services/playback_service.dart';
import 'package:nox_iptv/services/playlist_manager.dart';
import 'package:nox_iptv/services/storage_service.dart';
import 'package:nox_iptv/services/viewer_profile_service.dart';
import 'package:nox_iptv/screens/settings/general_settings_screen.dart';
import 'package:nox_iptv/widgets/game_reminder_overlay.dart';
import 'package:nox_iptv/widgets/goals_alert_overlay.dart';
import 'package:nox_iptv/widgets/game_score_alert_menu_tile.dart';
import 'game_reminders_test.dart' show reminderGame;
import 'game_reminder_overlay_test.dart' show ReminderViewers;
import 'goals_alerts_test.dart' show scoreGame;

void main() {
  late StorageService storage;
  late AppPreferences prefs;
  late PlaylistManager playlist;
  late PlaybackService playback;
  late ReminderViewers viewers;
  late GameReminders reminders;
  late GoalsAlerts goals;
  late DateTime time;
  late String score;
  late int calls;
  late FocusNode focus;
  late GlobalKey<NavigatorState> navigator;

  Future<void> setup() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.init();
    await storage.setGoalsAlert(true);
    await storage.setSportsFollowedTeams(['nhl|mtl']);
    prefs = AppPreferences(storage);
    await prefs.init();
    playlist = PlaylistManager(storage, CatalogDatabase());
    playback = PlaybackService(storage, playlist);
    viewers = ReminderViewers(storage, playlist, playback);
    time = DateTime.utc(2026, 10, 26, 20);
    score = '0';
    calls = 0;
    goals = GoalsAlerts(storage,
        now: () => time,
        loadGames: (_, __) async {
          calls++;
          return [scoreGame(time, home: score)];
        });
    reminders = GameReminders(storage, now: () => time);
    focus = FocusNode();
    navigator = GlobalKey<NavigatorState>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
            'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
            (_) async => const StandardMessageCodec().encodeMessage([null]));
  }

  tearDown(() {
    goals.dispose();
    reminders.dispose();
    viewers.dispose();
    playback.dispose();
    playlist.dispose();
    prefs.dispose();
    focus.dispose();
  });
  Future<void> mount(WidgetTester tester, {Widget? page}) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          ChangeNotifierProvider<GoalsAlerts>.value(value: goals),
          ChangeNotifierProvider<AppPreferences>.value(value: prefs),
          ChangeNotifierProvider<ViewerProfileService>.value(value: viewers),
          ChangeNotifierProvider<GameReminders>.value(value: reminders),
        ],
        child: MaterialApp(
          navigatorKey: navigator,
          home: page ??
              Scaffold(
                  body: TextButton(
                      focusNode: focus,
                      autofocus: true,
                      onPressed: () {},
                      child: const Text('Watching another stream'))),
          builder: (context, child) => Stack(children: [
            child!,
            const GameReminderOverlay(),
            const GoalsAlertOverlay()
          ]),
        )));
    await tester.pump();
    await tester.pump();
  }

  Future<void> tick(WidgetTester tester, int seconds) async {
    time = time.add(Duration(seconds: seconds));
    await tester.pump(Duration(seconds: seconds));
    await tester.pump();
    await tester.pump();
  }

  for (final width in [960.0, 360.0]) {
    testWidgets(
        'score popup and reminder do not overlap at width=$width, keep stream focus',
        (tester) async {
      await setup();
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await reminders.toggle(reminderGame(
          time.add(const Duration(minutes: 15, seconds: 30)),
          id: 'next-game'));
      await mount(tester);
      expect(find.byKey(const ValueKey('goal-alert')), findsNothing);
      expect(focus.hasFocus, isTrue);
      score = '1';
      await tick(tester, 30);
      expect(find.text('Canadiens scored!'), findsOneWidget);
      expect(find.text('Starts in 15 minutes'), findsOneWidget);
      expect(find.byKey(const ValueKey('goal-team-logo')), findsOneWidget);
      expect(find.byKey(const ValueKey('goal-league-logo')), findsOneWidget);
      final goal = tester.getRect(find.byKey(const ValueKey('goal-alert')));
      final reminder = tester.getRect(find
          .ancestor(
              of: find.text('Starts in 15 minutes'),
              matching: find.byType(Material))
          .first);
      expect(goal.overlaps(reminder), isFalse);
      if (width >= 800) {
        expect(goal.left, 20);
      } else {
        expect(goal.top, greaterThan(reminder.bottom));
      }
      expect(focus.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
      await tick(tester, 8);
      expect(find.byKey(const ValueKey('goal-alert')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }

  testWidgets('popup appears over dialogs and menus too', (tester) async {
    await setup();
    await mount(tester);
    unawaited(showDialog<void>(
        context: navigator.currentContext!,
        builder: (_) => const AlertDialog(content: Text('Open dialog'))));
    await tester.pumpAndSettle();
    score = '1';
    await tick(tester, 30);
    expect(find.text('Open dialog'), findsOneWidget);
    expect(find.text('Canadiens scored!'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      'popup appears over another route; opt-out and profile switch remove it',
      (tester) async {
    await setup();
    await mount(tester);
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => Scaffold(
            body: TextButton(
                autofocus: true,
                onPressed: () {},
                child: const Text('Different page')))));
    await tester.pumpAndSettle();
    final before = FocusManager.instance.primaryFocus;
    score = '1';
    await tick(tester, 30);
    expect(find.text('Different page'), findsOneWidget);
    expect(find.text('Canadiens scored!'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus, same(before));
    prefs.setGoalsAlert(false);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('goal-alert')), findsNothing);
    final savedCalls = calls;
    score = '2';
    await tick(tester, 30);
    expect(calls, savedCalls);
    prefs.setGoalsAlert(true);
    await tester.pump();
    await tester.pump();
    score = '3';
    await tick(tester, 30);
    expect(find.text('Canadiens scored!'), findsOneWidget);
    await prefs.setSportsHideScores(true);
    await tester.pump();
    expect(find.byKey(const ValueKey('goal-alert')), findsNothing);
    score = '4';
    await tick(tester, 30);
    await prefs.setSportsHideScores(false);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('goal-alert')), findsNothing);
    score = '5';
    await tick(tester, 30);
    expect(find.text('Canadiens scored!'), findsOneWidget);
    await viewers.change('other');
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('goal-alert')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      'background pauses checks; resume baselines without replaying missed scores',
      (tester) async {
    await setup();
    await mount(tester);
    score = '1';
    await tick(tester, 30);
    expect(find.text('Canadiens scored!'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.byKey(const ValueKey('goal-alert')), findsNothing);
    final savedCalls = calls;
    score = '3';
    await tick(tester, 30);
    expect(calls, savedCalls);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('goal-alert')), findsNothing);
    score = '4';
    await tick(tester, 30);
    expect(find.text('Canadiens scored!'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      'Interface Goals alert toggle is off by default and persists opt-in',
      (tester) async {
    await setup();
    await storage.setGoalsAlert(false);
    await mount(tester,
        page: const GeneralSettingsScreen(
            sections: {'goals'}, title: 'Goals alert'));
    expect(storage.getGoalsAlert(), isFalse);
    expect(find.byType(Switch), findsNWidgets(2));
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(storage.getGoalsAlert(), isTrue);
    final reopened = StorageService();
    await reopened.init();
    expect(reopened.getGoalsAlert(), isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets(
      'game menu enables both-side alerts with My Teams off and can cancel',
      (tester) async {
    await setup();
    await storage.setGoalsAlert(false);
    await storage.setSportsFollowedTeams([]);
    await mount(tester,
        page: Scaffold(body: GameScoreAlertMenuTile(game: scoreGame(time))));
    expect(find.text('Set goals alert for this match'), findsOneWidget);
    final before = calls;
    await tester.tap(find.text('Set goals alert for this match'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(goals.isSet(scoreGame(time)), isTrue);
    expect(storage.getGoalsAlert(), isFalse);
    expect(find.text('Remove goals alert for this match'), findsOneWidget);
    expect(calls, greaterThan(before));
    score = '1';
    await tick(tester, 30);
    expect(find.text('Canadiens scored!'), findsOneWidget);
    expect(find.byKey(const ValueKey('goal-team-logo')), findsOneWidget);
    await tester.tap(find.text('Remove goals alert for this match'));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('goal-alert')), findsNothing);
    expect(goals.isSet(scoreGame(time)), isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      'selected match popup retains playback focus and clears on profile change',
      (tester) async {
    await setup();
    await storage.setGoalsAlert(false);
    await storage.setSportsFollowedTeams([]);
    await goals.setGame(scoreGame(time), true);
    await mount(tester);
    expect(focus.hasFocus, isTrue);
    score = '1';
    await tick(tester, 30);
    expect(find.text('Canadiens scored!'), findsOneWidget);
    expect(focus.hasFocus, isTrue);
    await viewers.change('other');
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('goal-alert')), findsNothing);
    expect(goals.isSet(scoreGame(time)), isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('ended games hide the new opt-in action', (tester) async {
    await setup();
    await mount(tester,
        page: Scaffold(
            body: GameScoreAlertMenuTile(
                game: scoreGame(time, state: GameState.post))));
    expect(find.text('Set goals alert for this match'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
