import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nox_iptv/models/playlist_profile.dart';
import 'package:nox_iptv/models/xtream_category.dart';
import 'package:nox_iptv/models/xtream_series.dart';
import 'package:nox_iptv/services/catalog_database.dart';
import 'package:nox_iptv/services/playlist_session.dart';
import 'package:nox_iptv/services/storage_service.dart';
import 'package:nox_iptv/services/xtream_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late StorageService storage;
  late Directory temp;
  CatalogDatabase? catalog;
  setUp(() async {
    HttpOverrides.global = null; // the test binding fakes HTTP otherwise
    databaseFactory = databaseFactoryFfi;
    temp = await Directory.systemTemp.createTemp('vesper-warmup-');
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.init();
  });
  tearDown(() async {
    await catalog?.close();
    await temp.delete(recursive: true);
  });

  Future<PlaylistSession> session(int port) async {
    final s = PlaylistSession(
        profile: PlaylistProfile(
            id: 'p',
            name: 'p',
            mode: 'xtream',
            sortOrder: 0,
            createdAt: DateTime(2026)),
        storage: storage,
        catalogDb: catalog =
            CatalogDatabase(databasePath: '${temp.path}/catalog.db'),
        favoriteIds: () => {},
        favoriteSeriesIds: () => {},
        isRestrictedViewer: () => false,
        onNotify: () {});
    s.xtreamApi = XtreamApiService(
        server: 'http://127.0.0.1:$port',
        username: 'u',
        password: 'p',
        playlistId: 'p');
    s.vodCategories = [
      for (var i = 0; i < 20; i++) XtreamCategory(id: '$i', name: 'Movies $i')
    ];
    s.seriesCategories = [
      for (var i = 0; i < 20; i++) XtreamCategory(id: '$i', name: 'Shows $i')
    ];
    return s;
  }

  test('an unreachable server stops the warm-up after one retry', () async {
    var requests = 0;
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((socket) {
      requests++;
      socket.destroy(); // no reply at all, like a dead host
    });
    final s = await session(server.port);
    await s.warmAllCategories();
    await server.close();

    expect(requests, lessThan(12), reason: '40 categories, server down');
    expect(s.isWarmingCatalog, isFalse);
    expect(storage.getLastFullSyncAt('p'), isNull,
        reason: 'a stopped warm-up is not a full sync');
  });

  test('browse rows stop asking an unreachable server (LOG-6LYY3R)', () async {
    var requests = 0;
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((socket) {
      requests++;
      socket.destroy();
    });
    final s = await session(server.port);
    s.vodCategoryIdByName
        .addAll({for (final c in s.vodCategories) c.name: c.id});
    await s.ensureCategoriesLoaded(s.vodCategories.map((c) => c.name), 'vod');
    await server.close();

    expect(s.serverDown, isTrue);
    expect(requests, lessThan(6), reason: '20 rows, server down');
  });

  test('HTTP 429 pauses catalog requests (LOG-MP44ZB)', () async {
    var requests = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      requests++;
      request.response
        ..statusCode = 429
        ..close();
    });
    final s = await session(server.port);
    await s.warmAllCategories();
    await server.close(force: true);

    expect(s.serverDown, isTrue);
    expect(requests, lessThan(12), reason: '40 categories, rate limited');
  });

  test('a server that answers again lifts the pause', () async {
    final dead = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    dead.listen((socket) => socket.destroy());
    final s = await session(dead.port);
    await s.warmAllCategories();
    await dead.close();
    expect(s.serverDown, isTrue);

    final live = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    live.listen((request) => request.response
      ..headers.contentType = ContentType.json
      ..write('{}')
      ..close());
    s.xtreamApi = XtreamApiService(
        server: 'http://127.0.0.1:${live.port}',
        username: 'u',
        password: 'p',
        playlistId: 'p');
    await s.loadSeriesEpisodes(XtreamSeries(
        seriesId: 1, playlistId: 'p', name: 'Show', categoryId: '0'));
    await live.close(force: true);
    expect(s.serverDown, isFalse);
  });

  test('HTTP errors from a live server do not stop the warm-up', () async {
    var requests = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      requests++;
      request.response
        ..statusCode = 500
        ..close();
    });
    final s = await session(server.port);
    await s.warmAllCategories();
    await server.close(force: true);

    expect(requests, 40);
    expect(storage.getLastFullSyncAt('p'), isNotNull);
  });
}
