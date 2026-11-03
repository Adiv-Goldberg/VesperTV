import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:nox_iptv/models/archive_models.dart';
import 'package:nox_iptv/services/missing_episodes.dart';

const _imdb = 'tt32125269';

ArchiveMeta _show(List<(int, int, String)> eps) => ArchiveMeta.fromJson({
      'id': _imdb,
      'type': 'series',
      'name': 'Beyond the Gates',
      'videos': [
        for (final (s, e, date) in eps)
          {'id': '$_imdb:$s:$e', 'season': s, 'episode': e, 'released': date}
      ],
    })!;

void main() {
  final now = DateTime.utc(2026, 11, 3, 15);
  final meta = _show([
    (2, 200, '2026-10-29T00:00:00.000Z'),
    (2, 201, '2026-10-30T00:00:00.000Z'),
    (3, 1, '2026-12-29T00:00:00.000Z'), // upcoming: not the latest season
  ]);

  MockClient tmdb({required bool sameNumbering}) => MockClient((req) async {
        if (req.url.path == '/3/find/$_imdb') {
          return http.Response(
              jsonEncode({
                'tv_results': [
                  {'id': 99}
                ]
              }),
              200);
        }
        if (req.url.path == '/3/tv/99/season/2') {
          return http.Response(
              jsonEncode({
                'episodes': [
                  {
                    'episode_number': sameNumbering ? 201 : 150,
                    'air_date': '2026-10-30'
                  },
                  {
                    'episode_number': 202,
                    'name': 'Episode 202',
                    'air_date': '2026-11-02'
                  },
                  {'episode_number': 203, 'air_date': '2026-11-03'},
                  {'episode_number': 204, 'air_date': '2026-11-04'},
                ]
              }),
              200);
        }
        return http.Response('{}', 404);
      });

  test('TMDB fills in aired episodes Cinemeta does not list yet', () async {
    final found = await MissingEpisodes(
            client: tmdb(sameNumbering: true), now: () => now)
        .find(meta, tmdbKey: 'key');
    expect(found.map((v) => v.id), ['$_imdb:2:202', '$_imdb:2:203']);
    expect(found.first.title, 'Episode 202');
  });

  test('TMDB with other numbering falls back to the next episode', () async {
    final found = await MissingEpisodes(
            client: tmdb(sameNumbering: false), now: () => now)
        .find(meta, tmdbKey: 'key');
    expect(found.map((v) => v.id), ['$_imdb:2:202']);
    expect(found.single.released, isNull);
  });

  test('no key: the next episode after a recent one', () async {
    var calls = 0;
    final found = await MissingEpisodes(
            client: MockClient((_) async {
              calls++;
              return http.Response('{}', 200);
            }),
            now: () => now)
        .find(meta);
    expect(found.map((v) => v.id), ['$_imdb:2:202']);
    expect(calls, 0);
  });

  test('a season that ended long ago gets nothing', () async {
    final ended = _show([(1, 10, '2026-01-01T00:00:00.000Z')]);
    final found = await MissingEpisodes(now: () => now).find(ended);
    expect(found, isEmpty);
  });

  test('a listed next episode is not added twice', () async {
    final listed = _show([
      (2, 201, '2026-10-30T00:00:00.000Z'),
      (2, 202, '2026-11-04T00:00:00.000Z'),
    ]);
    final found = await MissingEpisodes(now: () => now).find(listed);
    expect(found, isEmpty);
  });
}
