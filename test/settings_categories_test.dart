import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox_iptv/screens/settings/settings_menu_screen.dart';
import 'package:nox_iptv/services/app_preferences.dart';
import 'package:nox_iptv/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings' left panel (owner, 2026-10-21): the focused category's
/// description and rows show on the right; Right enters them, Left / Back
/// returns to the panel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final prefs = AppPreferences(storage);
    await prefs.init();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: prefs,
      child: const MaterialApp(home: SettingsMenuScreen()),
    ));
    await tester.pumpAndSettle();
  }

  String? focusedLabel() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return null;
    final texts = <String>[];
    ctx.visitChildElements(_collect(texts));
    return texts.isEmpty ? null : texts.first;
  }

  testWidgets('pane follows the panel; Right / Left move between them',
      (tester) async {
    await pump(tester);
    // First category focused, its rows on the right.
    expect(focusedLabel(), 'Playlists & guide');
    expect(find.text('Playlist Manager'), findsOneWidget);
    expect(find.text('Media Hub sources'), findsNothing);

    // Down: Media Hub — sources, Add-ons, Trakt and TMDB together.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusedLabel(), 'Media Hub');
    for (final row in [
      'Media Hub sources',
      'Add-ons',
      'Trakt & Simkl',
      'TMDB (Release Dates)'
    ]) {
      expect(find.text(row), findsOneWidget);
    }
    expect(find.text('Playlist Manager'), findsNothing);
    expect(find.text('Media Hub playback'), findsOneWidget);

    // Right: into the pane, first row.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(focusedLabel(), 'Media Hub sources');
    // Down stays in the pane.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusedLabel(), 'Add-ons');

    // Left: back on the same category.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(focusedLabel(), 'Media Hub');

    // Interface retains appearance settings; Playback owns player settings.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusedLabel(), 'Interface');
    expect(find.text('Tabs'), findsOneWidget);
    expect(find.text('Resume reminder'), findsNothing);
    expect(find.text('Trailers'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusedLabel(), 'Playback');
    expect(find.text('Resume reminder'), findsOneWidget);
    expect(find.text('Trailers'), findsOneWidget);
    expect(find.text('Media Hub playback'), findsNothing);
    expect(find.text('Tabs'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(
        focusedLabel(), Platform.isWindows ? 'Trailers' : 'Background video');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(focusedLabel(), 'Playback');
  });
}

ElementVisitor _collect(List<String> out) => (Element e) {
      final w = e.widget;
      if (w is Text && w.data != null) out.add(w.data!);
      e.visitChildElements(_collect(out));
    };
