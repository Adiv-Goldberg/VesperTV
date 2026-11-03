import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nox_iptv/l10n/l10n.dart';
import 'package:nox_iptv/models/channel.dart';
import 'package:nox_iptv/models/series_details.dart';
import 'package:nox_iptv/models/xtream_series.dart';
import 'package:nox_iptv/screens/series_detail_screen.dart';
import 'package:nox_iptv/services/app_preferences.dart';
import 'package:nox_iptv/services/playback_service.dart';
import 'package:nox_iptv/services/playlist_manager.dart';
import 'package:nox_iptv/services/storage_service.dart';

import 'wide_guide_back_test.dart' show GuidePlaylist;

/// 38 seasons (The Young and the Restless, owner 2026-11-02): Right to the
/// end of the season row, then Left back: the row must scroll back too.
void main() {
  testWidgets('season row scrolls back with Left on a long show',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
            'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
            (_) async => const StandardMessageCodec().encodeMessage([null]));
    SharedPreferences.setMockInitialValues({});
    await L10n.apply('en');
    final storage = StorageService();
    await storage.init();
    final prefs = AppPreferences(storage);
    await prefs.init();
    prefs.isTelevision = true;
    final playlist = GuidePlaylist(storage);
    final playback = PlaybackService(storage, playlist);
    final bySeason = <int, List<Channel>>{};
    final details = <String, EpisodeDetails>{};
    for (var s = 1; s <= 38; s++) {
      final c = Channel(
          id: 'xt_ep_$s',
          rawId: 'xt_ep_$s',
          playlistId: 'p',
          name: 'Episode $s',
          group: 'Show',
          url: 'https://example.com/e/$s');
      bySeason[s] = [c];
      details[c.id] = EpisodeDetails(season: s, episodeNumber: 1);
    }
    await tester.pumpWidget(MultiProvider(
        providers: [
          Provider.value(value: storage),
          ChangeNotifierProvider.value(value: prefs),
          ChangeNotifierProvider<PlaylistManager>.value(value: playlist),
          ChangeNotifierProvider.value(value: playback),
        ],
        child: MaterialApp(
            home: SeriesDetailScreen(
          series: XtreamSeries(
              seriesId: 1, playlistId: 'p', name: 'Show', categoryId: '1'),
          showFavorite: false,
          loadEpisodes: () async => (
            episodes: bySeason,
            plot: null,
            details: SeriesDetails(episodes: details)
          ),
        ))));
    await tester.pumpAndSettle();

    bool onScreen(String label) {
      final box = tester.getRect(find.text(label).first);
      return box.left >= 0 && box.right <= 1920;
    }

    // Down from Play to the season row.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    for (var i = 0; i < 37; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(onScreen('Season 38'), isTrue);
    expect(onScreen('Season 1'), isFalse);
    for (var i = 0; i < 37; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(onScreen('Season 1'), isTrue);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    playback.dispose();
    playlist.dispose();
    prefs.dispose();
    await tester.pump();
  });
}
