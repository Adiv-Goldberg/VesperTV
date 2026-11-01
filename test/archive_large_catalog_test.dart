import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox_iptv/models/archive_models.dart';
import 'package:nox_iptv/screens/archive_screen.dart';
import 'package:nox_iptv/services/archive_service.dart';
import 'package:nox_iptv/services/storage_service.dart';
import 'package:nox_iptv/widgets/poster_card.dart';
import 'package:provider/provider.dart';

const _source = ArchiveSource(
  manifestUrl: 'https://example.com/manifest.json',
  name: 'Synthetic custom source',
  catalogs: [
    ArchiveCatalog(
        type: ArchiveType.movie,
        id: 'custom',
        name: 'Custom',
        wireType: 'custom')
  ],
);

class _Catalogs extends ArchiveService {
  _Catalogs() : super(StorageService());
  final entries = [
    for (var r = 0; r < 100; r++)
      ArchiveRow(
          source: _source,
          catalog: ArchiveCatalog(
              type: ArchiveType.movie,
              id: 'catalog$r',
              name: 'Catalog $r',
              wireType: 'custom'),
          items: [
            for (var i = 0; i < 1000; i++)
              ArchiveMeta(
                  id: '$r-$i',
                  type: ArchiveType.movie,
                  wireType: 'custom',
                  name: 'Title $r-$i')
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
  List<String> genres(ArchiveType type) => [ArchiveService.otherGenre];
  @override
  String? genre(ArchiveType type) => ArchiveService.otherGenre;
  @override
  bool canSearch(ArchiveType type) => false;
  @override
  bool isFavorite(ArchiveSource source, ArchiveMeta meta) => false;
}

Future<_Catalogs> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final service = _Catalogs();
  await tester.pumpWidget(ChangeNotifierProvider<ArchiveService>.value(
      value: service,
      child:
          MaterialApp(theme: ThemeData.dark(), home: const ArchiveScreen())));
  await tester.pumpAndSettle();
  return service;
}

int get _mountedPosters => find.byType(PosterCard).evaluate().length;

void main() {
  testWidgets('large custom catalogs build posters only near the viewport',
      (tester) async {
    final service = await _open(tester);
    // 100,000 items across 100 catalogs must not build 100 rows of posters.
    expect(_mountedPosters, greaterThan(0));
    expect(_mountedPosters, lessThan(100));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    for (var r = 0; r < 20; r++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'archive-card');
    expect(find.text('Title 20-0'), findsWidgets);
    expect(_mountedPosters, lessThan(120));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    // Returning to a row keeps the remembered horizontal position.
    final focused = tester.widget<PosterCard>(find.byWidgetPredicate(
        (w) => w is PosterCard && (w.focusNode?.hasFocus ?? false)));
    expect(focused.title, 'Title 20-1');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });

  testWidgets('catalog button jumps to an unbuilt row before focusing',
      (tester) async {
    final service = await _open(tester);
    // Out of the rail first: open, it lies over the bar's left end.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    final button = find.text('Catalog 80');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'archive-card');
    expect(find.text('Title 80-0'), findsWidgets);
    expect(_mountedPosters, lessThan(120));
    service.entries.removeRange(0, 80);
    service.notifyListeners();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });
}
