import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox_iptv/models/archive_models.dart';
import 'package:nox_iptv/screens/archive_screen.dart';
import 'package:nox_iptv/services/archive_service.dart';
import 'package:nox_iptv/services/storage_service.dart';
import 'package:nox_iptv/widgets/poster_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _source = ArchiveSource(
  manifestUrl: 'https://example.com/manifest.json',
  name: 'Wide cards',
  catalogs: [
    ArchiveCatalog(type: ArchiveType.movie, id: 'popular', name: 'Popular')
  ],
);

class _Rows extends ArchiveService {
  _Rows(super.storage);
  final entries = [
    for (var r = 0; r < 3; r++)
      ArchiveRow(
          source: _source,
          catalog: ArchiveCatalog(
              type: ArchiveType.movie, id: 'catalog$r', name: 'Catalog $r'),
          items: [
            for (var i = 0; i < 14; i++)
              ArchiveMeta(
                  id: 'm$r-$i',
                  type: ArchiveType.movie,
                  name: 'Title $r-$i',
                  // Every fifth title has no backdrop: it stays a poster.
                  backgroundUrl: i % 5 == 4 ? null : 'https://img.test/$r-$i',
                  rating: '7.6',
                  year: '2026',
                  genres: const ['Horror'])
          ]),
  ];
  @override
  List<ArchiveSource> get enabledSources => [_source];
  @override
  List<ArchiveSource> get sources => [_source];
  @override
  Future<void> open() async {}
  @override
  List<ArchiveRow> rows(ArchiveType type, {bool includeHidden = false}) =>
      entries;
  @override
  bool canSearch(ArchiveType type) => false;
  @override
  bool isFavorite(ArchiveSource source, ArchiveMeta meta) => false;
}

PosterCard _focusedCard(WidgetTester tester) =>
    tester.widget<PosterCard>(find.byWidgetPredicate(
        (w) => w is PosterCard && (w.focusNode?.hasFocus ?? false)));

Iterable<PosterCard> _wideCards(WidgetTester tester) => tester
    .widgetList<PosterCard>(find.byType(PosterCard))
    .where((c) => c.wideWidth != null);

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key,
    [int times = 1]) async {
  for (var i = 0; i < times; i++) {
    await tester.sendKeyEvent(key);
    await tester.pump();
    await tester.pump();
  }
}

void main() {
  testWidgets('the focused card goes wide, one at a time, and stays on screen',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final service = _Rows(storage);
    await tester.pumpWidget(ChangeNotifierProvider<ArchiveService>.value(
        value: service,
        child:
            MaterialApp(theme: ThemeData.dark(), home: const ArchiveScreen())));
    await tester.pump();
    await tester.pump();

    // The rail has focus: no wide card yet.
    expect(_wideCards(tester), isEmpty);

    await _press(tester, LogicalKeyboardKey.arrowRight);
    expect(_focusedCard(tester).title, 'Title 0-0');
    expect(_focusedCard(tester).wideWidth, PosterCard.wideCardWidth);
    expect(_wideCards(tester).length, 1);
    // Hero: info line with the type, genre and year, and the IMDb badge.
    expect(find.text('Movie  •  Horror  •  2026'), findsOneWidget);
    expect(find.text('IMDb'), findsOneWidget);

    await _press(tester, LogicalKeyboardKey.arrowRight, 3);
    expect(_focusedCard(tester).title, 'Title 0-3');
    expect(_wideCards(tester).map((c) => c.title), ['Title 0-3']);

    // A title without a backdrop stays a poster.
    await _press(tester, LogicalKeyboardKey.arrowRight);
    expect(_focusedCard(tester).title, 'Title 0-4');
    expect(_wideCards(tester), isEmpty);

    // To the end of the row: the wide last card is fully on screen.
    await _press(tester, LogicalKeyboardKey.arrowRight, 9);
    await tester.pump();
    expect(_focusedCard(tester).title, 'Title 0-13');
    final rect = tester.getRect(find.byWidgetPredicate(
        (w) => w is PosterCard && (w.focusNode?.hasFocus ?? false)));
    expect(rect.right, lessThanOrEqualTo(1280));
    expect(rect.left, greaterThanOrEqualTo(80));

    // Down: the next row's card goes wide, this row's card is a poster again.
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_focusedCard(tester).title, startsWith('Title 1-'));
    expect(_wideCards(tester).length, 1);
    expect(_wideCards(tester).single.title, startsWith('Title 1-'));

    // Back to the rail: nothing is wide.
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(_wideCards(tester), isEmpty);

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });
}
