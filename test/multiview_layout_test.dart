import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox_iptv/screens/multiview_screen.dart';
import 'package:nox_iptv/services/app_preferences.dart';
import 'package:nox_iptv/services/storage_service.dart';
import 'package:nox_iptv/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const tv = Size(1920, 1080);

  void expect16x9(Rect r) => expect(r.width / r.height, closeTo(16 / 9, 0.01));

  bool overlap(Rect a, Rect b) =>
      a.intersect(b).width > 0.5 && a.intersect(b).height > 0.5;

  test('1 screen: one centred 16:9 screen', () {
    final r = multiviewSlotRects(tv, 1);
    expect(r.whereType<Rect>(), hasLength(1));
    expect16x9(r[0]!);
    expect(r[0]!.center.dx, closeTo(tv.width / 2, 0.5));
  });

  test('2 screens: side by side, same size, centred, no overlap', () {
    final r = multiviewSlotRects(tv, 2);
    final a = r[0]!, b = r[1]!;
    expect16x9(a);
    expect(a.size, b.size);
    expect(a.top, b.top);
    expect(b.left, greaterThan(a.right));
    expect((a.left + b.right) / 2, closeTo(tv.width / 2, 0.5));
  });

  test('3 screens: two on top, the third centred under them', () {
    final r = multiviewSlotRects(tv, 3);
    expect(r[3], isNull);
    expect(r[2]!.top, greaterThan(r[0]!.bottom));
    expect(r[2]!.center.dx, closeTo(tv.width / 2, 0.5));
  });

  test('4 screens: a 2x2 grid inside the screen', () {
    final r = multiviewSlotRects(tv, 4).whereType<Rect>().toList();
    expect(r, hasLength(4));
    for (final a in r) {
      expect16x9(a);
      expect((Offset.zero & tv).intersect(a), a);
      for (final b in r) {
        if (!identical(a, b)) expect(overlap(a, b), isFalse);
      }
    }
  });

  test('enlarged: the chosen screen big on top, the others small under it', () {
    final r = multiviewSlotRects(tv, 3, enlarged: 1);
    final big = r[1]!;
    for (final i in [0, 2]) {
      expect(r[i]!.top, greaterThan(big.bottom));
      expect(r[i]!.width, lessThan(big.width / 2));
      expect(overlap(r[i]!, big), isFalse);
    }
    expect(r[0]!.left, lessThan(r[2]!.left));
    expect(big.bottom, lessThanOrEqualTo(tv.height));
    expect(r[0]!.bottom, lessThanOrEqualTo(tv.height));
  });

  test('full screen: only that screen, over the whole area', () {
    final r = multiviewSlotRects(tv, 4, fullscreen: 2, enlarged: 0);
    expect(r[2], Offset.zero & tv);
    expect([r[0], r[1], r[3]], everyElement(isNull));
  });

  test('portrait: at most 2 screens, stacked', () {
    const phone = Size(400, 860);
    final r = multiviewSlotRects(phone, 4, portrait: true);
    expect(r.whereType<Rect>(), hasLength(2));
    expect(r[1]!.top, greaterThan(r[0]!.bottom));
    expect(r[0]!.width, lessThanOrEqualTo(phone.width));
  });

  testWidgets('opens on one empty screen', (tester) async {
    tester.view.physicalSize = tv;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(
        {AppConstants.keyMultiviewHideTips: true});
    final storage = StorageService();
    await storage.init();
    final prefs = AppPreferences(storage);
    await prefs.init();
    prefs.isTelevision = true;
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider.value(value: storage),
        ChangeNotifierProvider.value(value: prefs),
      ],
      child: const MaterialApp(home: MultiviewScreen()),
    ));
    await tester.pump(const Duration(seconds: 5));
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
  });

  test('1 + 3: one big 16:9 screen, three small stacked on the right', () {
    final r = multiviewSlotRects(tv, 4, main: true);
    final big = r[0]!;
    expect16x9(big);
    for (var i = 1; i < 4; i++) {
      expect(r[i]!.left, greaterThan(big.right - 1));
      expect(overlap(r[i]!, big), isFalse);
    }
    expect(r[1]!.top, lessThan(r[2]!.top));
    expect(r[2]!.top, lessThan(r[3]!.top));
    expect(big.width / r[1]!.width, closeTo(2, 0.1));
  });

  test('Swap mode rotates playing screens through the big one', () {
    expect(swapRotation([0, 1, 2, 3], 1), [1, 2, 3, 0]);
    expect(swapRotation([0, 1, 2, 3], -1), [3, 0, 1, 2]);
    expect(swapRotation([0, 1, 3], 1), [1, 3, 0]);
    expect(swapRotation([0, 3], -1), [3, 0]);
  });
}
