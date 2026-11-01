import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox_iptv/models/archive_models.dart';
import 'package:nox_iptv/screens/archive_screen.dart';
import 'package:nox_iptv/services/app_preferences.dart';
import 'package:nox_iptv/services/archive_service.dart';
import 'package:nox_iptv/services/storage_service.dart';
import 'package:nox_iptv/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _source = ArchiveSource(
  manifestUrl: 'https://example.com/manifest.json',
  name: 'Rail search',
  catalogs: [
    ArchiveCatalog(type: ArchiveType.movie, id: 'popular', name: 'Popular')
  ],
);

class _Service extends ArchiveService {
  _Service(super.storage);
  @override
  List<ArchiveSource> get enabledSources => [_source];
  @override
  List<ArchiveSource> get sources => [_source];
  @override
  Future<void> open() async {}
  @override
  List<ArchiveRow> rows(ArchiveType type, {bool includeHidden = false}) => [
        ArchiveRow(source: _source, catalog: _source.catalogs.first, items: [
          const ArchiveMeta(id: 'm1', type: ArchiveType.movie, name: 'Title 1')
        ])
      ];
  @override
  bool canSearch(ArchiveType type) => true;
  @override
  bool isFavorite(ArchiveSource source, ArchiveMeta meta) => false;
}

Future<_Service> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService();
  await storage.init();
  final service = _Service(storage);
  final prefs = AppPreferences(storage)
    ..layoutMode = 'auto'
    ..palette = AppConstants.cyberpunkPalettes.first;
  await tester.pumpWidget(MultiProvider(providers: [
    ChangeNotifierProvider<ArchiveService>.value(value: service),
    ChangeNotifierProvider<AppPreferences>.value(value: prefs),
  ], child: MaterialApp(theme: ThemeData.dark(), home: const ArchiveScreen())));
  await tester.pump();
  await tester.pump();
  return service;
}

void main() {
  testWidgets('Search sits in the rail and pulls out Movies / TV Shows',
      (tester) async {
    final service = await _pump(tester);
    // One Search entry, in the rail; the top bar no longer has one.
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Search movies'), findsNothing);
    final rail = tester.getRect(find.text('Search'));
    expect(rail.left, lessThan(250));

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    // The pull-out: its title plus the two categories (also in the rail).
    expect(find.text('Search'), findsNWidgets(2));
    expect(find.text('TV Shows'), findsNWidgets(2));
    final menuItem = tester.getRect(find.text('TV Shows').last);
    expect(menuItem.left, greaterThan(rail.right),
        reason: 'the menu opens beside the button');

    await tester.tap(find.text('TV Shows').last);
    await tester.pumpAndSettle();
    expect(find.text('Search TV shows'), findsOneWidget);

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });

  testWidgets('the rail is icons only while the rows have focus',
      (tester) async {
    final service = await _pump(tester);
    expect(find.text('TV Shows'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('TV Shows'), findsNothing);
    expect(find.text('Media Hub'), findsNothing);
    expect(find.byIcon(Icons.video_library), findsOneWidget);
    // Closed, the rows take the room back; open, the rail pushes them
    // aside instead of lying over the posters.
    final closed = tester.getRect(find.text('Title 1').first);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('TV Shows'), findsOneWidget);
    final open = tester.getRect(find.text('Title 1').first);
    expect(open.left, greaterThan(closed.left));
    final rail = tester.getRect(find.text('TV Shows'));
    expect(open.left, greaterThan(rail.right));

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });
}
