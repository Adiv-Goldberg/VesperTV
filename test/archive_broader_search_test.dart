import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nox_iptv/models/archive_models.dart';
import 'package:nox_iptv/services/archive_api_service.dart';
import 'package:nox_iptv/services/archive_cache.dart';
import 'package:nox_iptv/services/archive_service.dart';
import 'package:nox_iptv/services/storage_service.dart';
import 'package:nox_iptv/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

ArchiveMeta _m(String id, String name) =>
    ArchiveMeta(id: id, type: ArchiveType.movie, name: name);
http.Response _metas(List<ArchiveMeta> items) => http.Response(
    jsonEncode({
      'metas': [for (final m in items) m.toJson()]
    }),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'});

class _Cache extends ArchiveCache {
  _Cache([this.items = const []]);
  final List<ArchiveMeta> items;
  @override
  Future<List<ArchiveMeta>> read(
          String sourceKey, ArchiveCatalog catalog) async =>
      items;
  @override
  Future<DateTime?> fetchedAt(String sourceKey, ArchiveCatalog catalog) async =>
      null;
  @override
  Future<void> write(String sourceKey, ArchiveCatalog catalog,
      List<ArchiveMeta> items) async {}
}

const _source = ArchiveSource(
    manifestUrl: 'https://source.example/manifest.json',
    name: 'Source',
    catalogs: [
      ArchiveCatalog(
          type: ArchiveType.movie, id: 'all', name: 'All', searchable: true)
    ]);

Future<StorageService> _storage(List<Map<String, dynamic>> sources) async {
  SharedPreferences.setMockInitialValues(
      {AppConstants.keyArchiveSources: jsonEncode(sources)});
  final storage = StorageService();
  await storage.init();
  return storage;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('custom search-only sources remain reachable through Other', () async {
    const source = ArchiveSource(
        manifestUrl: 'https://custom.example/manifest.json',
        name: 'Custom',
        // Under Other only when the user says so (2026-11-02).
        otherChoice: true,
        catalogs: [
          ArchiveCatalog(
              type: ArchiveType.movie,
              wireType: 'CustomVideo',
              id: 'search',
              name: 'Search',
              searchable: true,
              searchOnly: true)
        ]);
    final storage = await _storage([source.toJson()]);
    final service = ArchiveService(storage, cache: _Cache());
    addTearDown(service.dispose);
    expect(service.genres(ArchiveType.movie), [ArchiveService.otherGenre]);
    expect(service.canSearch(ArchiveType.movie), isFalse);
    await service.setGenre(ArchiveType.movie, ArchiveService.otherGenre);
    expect(service.canSearch(ArchiveType.movie), isTrue);
  });
  test(
      'global and Hub search combine spelling variants, aliases and cold cache; respect source split',
      () async {
    final storage = await _storage([
      _source.toJson(),
      _source.copyWith(enabled: false).toJson()
        ..['url'] = 'https://disabled.example/manifest.json',
      _source.copyWith(otherChoice: true).toJson()
        ..['url'] = 'https://other.example/manifest.json'
    ]);
    final requests = <Uri>[];
    final service = ArchiveService(storage,
        cache: _Cache([_m('cache', 'The Amazing Spider Man')]),
        api: ArchiveApiService(client: MockClient((r) async {
      requests.add(r.url);
      if (r.url.path.contains('search=spiderman')) {
        return _metas(
            [_m('one', 'Spider-Man'), _m('alias', 'L’Homme-araignée')]);
      }
      if (r.url.path.contains('search=spid')) {
        return _metas([
          _m('one', 'Spider-Man'),
          _m('two', 'Spider-Man 2'),
          _m('noise', 'Spiderwick')
        ]);
      }
      return _metas([]);
    })));
    addTearDown(service.dispose);
    final global = await service.searchRows(ArchiveType.movie, 'spiderman',
        underOther: false);
    expect(
        global.single.items.map((m) => m.id), ['one', 'two', 'cache', 'alias']);
    expect(requests.length, 2);
    expect(requests.every((u) => u.host == 'source.example'), isTrue);
    expect(service.searchQuery(ArchiveType.movie), isNull);
    await service.search(ArchiveType.movie, 'spiderman');
    expect(service.rows(ArchiveType.movie).first.items.map((m) => m.id),
        global.single.items.map((m) => m.id));
  });

  test('required-search catalogs are queried but never fetched for browsing',
      () async {
    final requests = <Uri>[];
    final api = ArchiveApiService(client: MockClient((r) async {
      requests.add(r.url);
      if (r.url.path.endsWith('/manifest.json')) {
        return http.Response(
            jsonEncode({
              'name': 'Search only',
              'resources': ['catalog', 'stream'],
              'types': ['movie'],
              'catalogs': [
                {
                  'type': 'movie',
                  'id': 'modern',
                  'extra': [
                    {'name': 'search', 'isRequired': true}
                  ]
                },
                {
                  'type': 'movie',
                  'id': 'legacy',
                  'extraSupported': ['search'],
                  'extraRequired': ['search']
                },
                {
                  'type': 'movie',
                  'id': 'unsupported',
                  'extra': [
                    {'name': 'genre', 'isRequired': true}
                  ]
                }
              ]
            }),
            200);
      }
      return _metas([_m('one', 'Spider-Man')]);
    }));
    final source =
        await api.fetchManifest('https://source.example/manifest.json');
    expect(source.catalogs.map((c) => c.id), ['modern', 'legacy']);
    expect(source.catalogs.every((c) => c.searchOnly && c.searchable), isTrue);
    final storage = await _storage([source.toJson()]);
    final service = ArchiveService(storage, api: api, cache: _Cache());
    addTearDown(service.dispose);
    requests.clear();
    await service.refresh(force: true);
    expect(requests, isEmpty);
    expect(service.rows(ArchiveType.movie), isEmpty);
    expect(service.canSearch(ArchiveType.movie), isTrue);
    final rows = await service.searchRows(ArchiveType.movie, 'spiderman');
    expect(rows.single.items.single.id, 'one');
    expect(requests.length, 4);
    expect(requests.every((u) => u.path.contains('/search=')), isTrue);
  });

  test(
      'old saved manifests upgrade once for concurrent global movie/show searches',
      () async {
    final old = _source.toJson()..remove('searchCatalogsChecked');
    final storage = await _storage([old]);
    var manifests = 0;
    final service = ArchiveService(storage, cache: _Cache(),
        api: ArchiveApiService(client: MockClient((r) async {
      if (r.url.path.endsWith('/manifest.json')) {
        manifests++;
        return http.Response(
            jsonEncode({
              'name': 'Source',
              'resources': ['catalog', 'stream'],
              'types': ['movie'],
              'catalogs': [
                {
                  'type': 'movie',
                  'id': 'search',
                  'extra': [
                    {'name': 'search', 'isRequired': true}
                  ]
                }
              ]
            }),
            200);
      }
      return _metas([_m('one', 'Spider-Man')]);
    })));
    addTearDown(service.dispose);
    final results = await Future.wait([
      service.searchRows(ArchiveType.movie, 'spiderman', underOther: false),
      service.searchRows(ArchiveType.series, 'spiderman', underOther: false)
    ]);
    expect(manifests, 1);
    expect(results.first.single.items.single.id, 'one');
    expect(service.sources.single.searchCatalogsChecked, isTrue);
    expect(service.sources.single.catalogs.single.searchOnly, isTrue);
    await service.searchRows(ArchiveType.movie, 'spiderman');
    expect(manifests, 1);
  });

  test('failed manifest upgrade preserves existing search and cached matches',
      () async {
    final storage =
        await _storage([_source.toJson()..remove('searchCatalogsChecked')]);
    var manifests = 0;
    final service =
        ArchiveService(storage, cache: _Cache([_m('cache', 'Spider-Man')]),
            api: ArchiveApiService(client: MockClient((r) async {
      if (r.url.path.endsWith('/manifest.json')) {
        manifests++;
        return http.Response('{}', 503);
      }
      return _metas([]);
    })));
    addTearDown(service.dispose);
    for (var i = 0; i < 2; i++) {
      expect(
          (await service.searchRows(ArchiveType.movie, 'spiderman'))
              .single
              .items
              .single
              .id,
          'cache');
    }
    expect(manifests, 1);
    expect(service.sources.single.catalogs.single.id, 'all');
  });
}
