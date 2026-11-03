import 'dart:convert';

import 'package:http/http.dart' as http;

import '../l10n/l10n.dart';
import '../models/archive_models.dart';

/// Episodes Cinemeta doesn't list yet (Media Hub shows from stream-only
/// add-ons): a daily soap's newest episode can be missing for days while
/// the add-ons already stream it (Beyond the Gates S02E202, 2026-11-03).
/// - With the viewer's TMDB key: TMDB's aired episodes of the latest season
///   past Cinemeta's last one, only when TMDB numbers that season the same
///   way (it has Cinemeta's last episode).
/// - Otherwise (or TMDB had nothing new): the next episode number, when the
///   last listed one aired in the past 14 days. Its sources are asked when
///   it's played; none = the usual "no stream" message.
/// Ids follow Cinemeta's `tt…:season:episode`, so the add-ons' `/stream/`
/// takes them as is. Failures never block the show page.
class MissingEpisodes {
  MissingEpisodes({http.Client? client, DateTime Function()? now})
      : _client = client ?? http.Client(),
        _now = now ?? DateTime.now;

  static final instance = MissingEpisodes();
  final http.Client _client;
  final DateTime Function() _now;
  final _cache = <String, ({DateTime until, List<ArchiveVideo> videos})>{};

  static const _recent = Duration(days: 14);
  static const _maxAdded = 30;

  Future<List<ArchiveVideo>> find(ArchiveMeta meta,
      {String tmdbKey = ''}) async {
    final imdb = meta.imdb;
    if (meta.type != ArchiveType.series || imdb == null) return const [];
    final videos = meta.videos.where((v) => v.season > 0 && v.episode > 0);
    // Only Cinemeta-style ids (what the add-ons' /stream/ expects).
    if (!videos.any((v) => v.id == '$imdb:${v.season}:${v.episode}')) {
      return const [];
    }
    final now = _now();
    DateTime? aired(ArchiveVideo v) {
      final d = DateTime.tryParse(v.released ?? '');
      return d != null && !d.isAfter(now) ? d : null;
    }

    final airedVideos = [
      for (final v in videos)
        if (aired(v) != null) v
    ];
    if (airedVideos.isEmpty) return const [];
    final season =
        airedVideos.map((v) => v.season).reduce((a, b) => a > b ? a : b);
    final inSeason = airedVideos.where((v) => v.season == season).toList()
      ..sort((a, b) => a.episode.compareTo(b.episode));
    final last = inSeason.last;
    final listed = {
      for (final v in videos)
        if (v.season == season) v.episode
    };

    final key = jsonEncode([imdb, season, last.episode, tmdbKey.hashCode]);
    final cached = _cache[key];
    if (cached != null && cached.until.isAfter(now)) return cached.videos;

    var found = const <ArchiveVideo>[];
    if (tmdbKey.trim().isNotEmpty) {
      found = await _fromTmdb(imdb, season, last.episode, listed, tmdbKey);
    }
    if (found.isEmpty &&
        now.difference(aired(last)!) <= _recent &&
        !listed.contains(last.episode + 1)) {
      found = [
        ArchiveVideo(
          id: '$imdb:$season:${last.episode + 1}',
          title: tr('Not listed yet'),
          season: season,
          episode: last.episode + 1,
          overview: tr(
              'The newest episode may not be in the catalog yet. Press Play to ask your sources.'),
        ),
      ];
    }
    if (_cache.length >= 64) _cache.remove(_cache.keys.first);
    _cache[key] = (until: now.add(const Duration(minutes: 30)), videos: found);
    return found;
  }

  Future<Map> _get(Uri uri) async {
    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return const {};
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data is Map ? data : const {};
    } catch (_) {
      return const {};
    }
  }

  Future<List<ArchiveVideo>> _fromTmdb(String imdb, int season, int lastEpisode,
      Set<int> listed, String key) async {
    final find = await _get(Uri.https('api.themoviedb.org', '/3/find/$imdb',
        {'api_key': key, 'external_source': 'imdb_id'}));
    final tv = find['tv_results'];
    final id = tv is List && tv.isNotEmpty && tv.first is Map
        ? (tv.first as Map)['id']
        : null;
    if (id == null) return const [];
    final data = await _get(Uri.https(
        'api.themoviedb.org', '/3/tv/$id/season/$season', {'api_key': key}));
    final episodes = data['episodes'];
    if (episodes is! List) return const [];
    final today = _now();
    final todayKey = '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final rows = episodes.whereType<Map>().toList();
    int? number(Map e) => int.tryParse('${e['episode_number']}');
    // Same numbering as Cinemeta, or nothing (a soap split differently
    // would add the wrong episodes).
    if (!rows.any((e) => number(e) == lastEpisode)) return const [];
    final out = <ArchiveVideo>[];
    for (final e in rows) {
      final n = number(e);
      final date = e['air_date']?.toString() ?? '';
      if (n == null || n <= lastEpisode || listed.contains(n)) continue;
      if (date.isEmpty || date.compareTo(todayKey) > 0) continue;
      final still = e['still_path']?.toString();
      final name = e['name']?.toString().trim() ?? '';
      final overview = e['overview']?.toString().trim() ?? '';
      out.add(ArchiveVideo(
        id: '$imdb:$season:$n',
        title: name,
        season: season,
        episode: n,
        released: date,
        overview: overview.isEmpty ? null : overview,
        thumbnailUrl: still == null || still.isEmpty
            ? null
            : 'https://image.tmdb.org/t/p/w300$still',
      ));
      if (out.length >= _maxAdded) break;
    }
    return out;
  }
}
