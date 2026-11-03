import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox_iptv/screens/welcome_add_playlist_screen.dart';
import 'package:nox_iptv/services/app_preferences.dart';
import 'package:nox_iptv/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A phone with the largest font and display size (vision-impaired user,
/// 2026-11-02): ~320 dp wide, font scale 2.0 (Android 14's maximum).
Future<void> bigPhone(WidgetTester tester, {double scale = 2.0}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  for (final scale in [1.3, 2.0]) {
    testWidgets('welcome screen fits a big-text phone ($scale)', (tester) async {
      await bigPhone(tester, scale: scale);
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();
      final prefs = AppPreferences(storage);
      await prefs.init();
      final semantics = tester.ensureSemantics();
      bool? answer;
      await tester.pumpWidget(ChangeNotifierProvider.value(
          value: prefs,
          child: WelcomeAddPlaylistScreen(onRespond: (v) => answer = v)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(find.text('Skip for now'), 100);
      await tester.tap(find.text('Add Playlist'));
      expect(answer, isTrue);

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      semantics.dispose();
      prefs.dispose();
    });
  }
}
