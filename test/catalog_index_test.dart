import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox_iptv/models/channel.dart';
import 'package:nox_iptv/services/catalog_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Rows are read and replaced by playlist + category: with many playlists
/// the category-only index scanned every playlist's copy (LOG-6LYY3R).
void main() {
  sqfliteFfiInit();
  late Directory temp;
  late CatalogDatabase catalog;
  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    temp = await Directory.systemTemp.createTemp('vesper-index-');
    catalog = CatalogDatabase(databasePath: '${temp.path}/catalog.db');
  });
  tearDown(() async {
    await catalog.close();
    await temp.delete(recursive: true);
  });

  test('simultaneous first reads share one open (LOG-2L5D3S)', () async {
    final logs = <String>[];
    final print = debugPrint;
    debugPrint = (m, {wrapWidth}) => logs.add('$m');
    try {
      final reads = await Future.wait(
          List.generate(50, (i) => catalog.getVodCategory('p', 'C$i')));
      expect(reads.every((r) => r.isEmpty), isTrue);
    } finally {
      debugPrint = print;
    }
    expect(logs.where((l) => l.contains('reopening from scratch')), isEmpty);
  });

  test('row reads and replaces use the playlist + category index', () async {
    await catalog.upsertVodCategory('p', 'Movies', [
      Channel(
          id: 'p::1',
          rawId: '1',
          playlistId: 'p',
          name: 'A film',
          group: 'Movies',
          url: 'https://example.test/1',
          onDemand: true),
    ]);
    expect((await catalog.getVodCategory('p', 'Movies')).single.name, 'A film');

    final db = await databaseFactoryFfi.openDatabase('${temp.path}/catalog.db');
    try {
      Future<String> plan(String sql) async =>
          (await db.rawQuery('EXPLAIN QUERY PLAN $sql', ['Movies', 'p']))
              .map((r) => r['detail'])
              .join(' ');
      for (final table in ['vod_channels', 'series_items']) {
        final index = table == 'vod_channels'
            ? 'idx_vod_playlist_cat'
            : 'idx_series_playlist_cat';
        expect(
            await plan(
                'SELECT * FROM $table WHERE category_name = ? AND playlist_id = ?'),
            contains(index));
        expect(
            await plan(
                'DELETE FROM $table WHERE category_name = ? AND playlist_id = ?'),
            contains(index));
      }
    } finally {
      await db.close();
    }
  });
}
