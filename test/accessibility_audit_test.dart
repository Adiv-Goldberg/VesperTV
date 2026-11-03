import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox_iptv/screens/settings/add_playlist_screen.dart';
import 'package:nox_iptv/screens/settings/general_settings_screen.dart';
import 'package:nox_iptv/screens/settings/playlist_manager_screen.dart';
import 'package:nox_iptv/screens/search_screen.dart';
import 'package:nox_iptv/screens/settings/settings_menu_screen.dart';
import 'package:nox_iptv/screens/tv_home_screen.dart';
import 'package:nox_iptv/services/app_preferences.dart';
import 'package:nox_iptv/services/archive_service.dart';
import 'package:nox_iptv/services/epg_service.dart';
import 'package:nox_iptv/services/playback_service.dart';
import 'package:nox_iptv/services/playlist_manager.dart';
import 'package:nox_iptv/services/storage_service.dart';
import 'package:nox_iptv/services/viewer_profile_service.dart';
import 'package:nox_iptv/utils/constants.dart';
import 'package:nox_iptv/utils/route_observer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'wide_guide_back_test.dart' show GuidePlaylist, GuideEpg;

/// Big-text phone audit (vision-impaired user, 2026-11-02): the main phone
/// screens at ~320 dp wide with the largest font must lay out without
/// overflow, and every tap target must have a TalkBack label.
void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
            'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
            (_) async => const StandardMessageCodec().encodeMessage([null]));
  });

  Future<void> pumpScreen(WidgetTester tester, Widget screen,
      {required double scale}) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    SharedPreferences.setMockInitialValues({AppConstants.keyShowClock: false});
    final storage = StorageService();
    await storage.init();
    final prefs = AppPreferences(storage);
    await prefs.init();
    prefs.isTelevision = false;
    final playlist = GuidePlaylist(storage);
    final playback = PlaybackService(storage, playlist);
    final epg = GuideEpg(storage);
    final viewers = ViewerProfileService(storage, playlist, playback);
    await tester.pumpWidget(MultiProvider(
        providers: [
          Provider.value(value: storage),
          ChangeNotifierProvider.value(value: prefs),
          ChangeNotifierProvider<PlaylistManager>.value(value: playlist),
          ChangeNotifierProvider.value(value: playback),
          ChangeNotifierProvider<EpgService>.value(value: epg),
          ChangeNotifierProvider.value(value: viewers),
          ChangeNotifierProvider(create: (_) => ArchiveService(storage)),
        ],
        child: MaterialApp(
            navigatorObservers: [appRouteObserver], home: screen)));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 16));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      playback.dispose();
      viewers.dispose();
      playlist.dispose();
      prefs.dispose();
      epg.dispose();
      await tester.pump();
    });
  }

  final screens = <String, Widget Function()>{
    'home': () => const TvHomeScreen(),
    'settings': () => const SettingsMenuScreen(),
    'add playlist': () => const AddPlaylistScreen(),
    'playlist manager': () => const PlaylistManagerScreen(),
    'search': () => const SearchScreen(initialScope: 'TV'),
    'all general settings': () => const GeneralSettingsScreen(),
  };
  for (final scale in [1.3, 2.0]) {
    for (final e in screens.entries) {
      testWidgets('${e.key} fits a big-text phone ($scale)', (tester) async {
        final semantics = tester.ensureSemantics();
        final overflows = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          final text = details.toString();
          if (text.contains('overflowed')) {
            final at = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(text);
            overflows.add(at?.group(0) ?? text.split('\n').first);
          } else {
            previous?.call(details);
          }
        };
        try {
          await pumpScreen(tester, e.value(), scale: scale);
        } finally {
          FlutterError.onError = previous;
        }
        if (e.key == 'home') {
          // Phone: walk into the TV tab's group and its channel list.
          for (final label in ['TV', 'Test group']) {
            final f = find.text(label);
            if (f.evaluate().isEmpty) continue;
            FlutterError.onError = (details) {
              final text = details.toString();
              if (text.contains('overflowed')) {
                final at = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(text);
                overflows.add('$label: ${at?.group(0) ?? 'overflow'}');
              } else {
                previous?.call(details);
              }
            };
            try {
              await tester.tap(f.first, warnIfMissed: false);
              await tester.pumpAndSettle();
            } finally {
              FlutterError.onError = previous;
            }
            await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          }
          expect(find.text('Test channel'), findsWidgets);
        }
        expect(overflows.toSet(), isEmpty, reason: 'overflows');
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        semantics.dispose();
      });
    }
  }
}
