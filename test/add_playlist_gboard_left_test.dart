import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox_iptv/screens/settings/add_playlist_screen.dart';
import 'package:nox_iptv/services/app_preferences.dart';
import 'package:nox_iptv/services/epg_service.dart';
import 'package:nox_iptv/services/playback_service.dart';
import 'package:nox_iptv/services/playlist_manager.dart';
import 'package:nox_iptv/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'wide_guide_back_test.dart' show GuidePlaylist, GuideEpg;

/// Google TV + Gboard (owner, 2026-11-02): typing in a field, Left went to
/// the "Playlist source" pane and the remote then seemed stuck there.
void main() {
  testWidgets('Left out of a field being typed in, then Right comes back',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final prefs = AppPreferences(storage);
    await prefs.init();
    prefs.isTelevision = true;
    final playlist = GuidePlaylist(storage);
    final playback = PlaybackService(storage, playlist);
    final epg = GuideEpg(storage);
    await tester.pumpWidget(MultiProvider(providers: [
      Provider.value(value: storage),
      ChangeNotifierProvider.value(value: prefs),
      ChangeNotifierProvider<PlaylistManager>.value(value: playlist),
      ChangeNotifierProvider.value(value: playback),
      ChangeNotifierProvider<EpgService>.value(value: epg),
    ], child: const MaterialApp(home: AddPlaylistScreen())));
    await tester.pumpAndSettle();

    String focused() =>
        FocusManager.instance.primaryFocus?.context?.widget.toStringShort() ??
        'none';
    bool inField() =>
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<TextField>() !=
        null ||
        FocusManager.instance.primaryFocus?.context?.widget is EditableText;

    // Pick Xtream Codes in the left pane (Down, OK).
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    // Right into the form (Name), Down to Password.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(inField(), isTrue, reason: focused());
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    // OK = typing (keyboard up), type something.
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    tester.testTextInput.enterText('secret');
    await tester.pumpAndSettle();
    // Left: out of the field to the source pane.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(inField(), isFalse, reason: 'Left should leave the field');
    // Right: back into the form.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(inField(), isTrue, reason: 'Right should return: ${focused()}');
    // And Right again reaches Add Playlist.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(inField(), isFalse, reason: focused());

    await tester.pumpWidget(const SizedBox());
    playback.dispose();
    playlist.dispose();
    prefs.dispose();
    epg.dispose();
  });
}
