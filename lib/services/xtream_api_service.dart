import '../models/trailer.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/catchup.dart';
import '../models/channel.dart';
import '../models/series_details.dart';
import '../models/xtream_category.dart';
import '../models/xtream_series.dart';
import '../models/vod_details.dart';
import '../l10n/l10n.dart';

/// Talks to a real Xtream Codes ("XC API") panel via `player_api.php`.
///
/// Large providers can have tens of thousands of movies/series — pulling
/// the whole catalog at once (or via the `get.php` M3U export) is exactly
/// what caused an OutOfMemoryError on a 28k-live/158k-VOD/50k-series
/// account. Categories are cheap and fetched eagerly; VOD/series items are
/// fetched lazily, one category at a time, which keeps every response in
/// the hundreds-of-KB to low-MB range regardless of catalog size.
class XtreamApiService {
  XtreamApiService({
    required String server,
    required this.username,
    required this.password,
    required this.playlistId,
  }) : server = _normalizeServer(server);

  final String server;
  final String username;
  final String password;

  /// Which playlist this login belongs to — prefixed onto every id this
  /// instance generates (`Channel.id`/`XtreamSeries.id`) so two different
  /// Xtream logins' ids can never collide once merged into the same lists.
  /// See `Channel.playlistId`'s doc comment.
  final String playlistId;

  /// From the account's own `user_info.max_connections` (a string in the
  /// API response, `"0"` conventionally meaning unlimited) — null until
  /// [authenticate] runs, or if the field was missing/unparseable.
  /// PlaylistManager uses this to size how many categories it fetches
  /// concurrently: confirmed on real hardware that firing more concurrent
  /// requests than an account actually allows gets the extras rejected
  /// with HTTP 403 — and, a separate bug also fixed alongside this, that
  /// nothing gave up retrying those, so it hammered the server with
  /// rejected requests forever for the rest of the session.
  int? maxConnections;

  /// From the account's own `user_info.exp_date` (an epoch-seconds
  /// string) — null until [authenticate] runs, and also left null if the
  /// field is missing, unparseable, or "0" (some panels use that for a
  /// lifetime/reseller-unlimited account with no real expiry to report).
  DateTime? expiryDate;

  /// How far the provider's clock (`server_info.time_now`, the time zone
  /// Xtream catch-up links are written in) is ahead of UTC, rounded to
  /// 15 minutes. Null = the login answer didn't say. Set by [authenticate].
  Duration? serverTimeOffset;

  /// `server_info.timezone` as the provider reports it (log only).
  String? serverTimeZone;

  static String _normalizeServer(String server) {
    var s = server.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  Uri _apiUri(String action, [Map<String, String>? extra]) {
    return Uri.parse('$server/player_api.php').replace(queryParameters: {
      'username': username,
      'password': password,
      if (action.isNotEmpty) 'action': action,
      ...?extra,
    });
  }

  Future<dynamic> _getJson(String action, [Map<String, String>? extra]) async {
    final response = await http
        .get(_apiUri(action, extra))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception(tr(
          'Xtream request to {server} failed: {action} (HTTP {code})',
          {'server': server, 'action': action, 'code': response.statusCode}));
    }
    // Off the UI thread — this is the shared decode path for every single
    // API call, including the per-category VOD/series fetches that fire
    // every time scrolling opens a newly-visible category. Confirmed via a
    // live Dart VM pause during an actual freeze (stuck the whole time
    // inside one uninterruptible native call) that a synchronous jsonDecode
    // here is exactly what was blocking the UI thread for seconds on a
    // large provider's category response — this is the first-fetch
    // counterpart to the cache-side fix in PlaylistManager.
    return compute(_decodeJsonBody, response.body);
  }

  Future<List<Map<String, dynamic>>> _getList(String action,
      [Map<String, String>? extra]) async {
    final decoded = await _getJson(action, extra);
    if (decoded is! List) return [];
    return decoded.cast<Map<String, dynamic>>();
  }

  /// The account's connection limit and how many are in use right now
  /// (`user_info.max_connections` / `active_cons`; null when not reported,
  /// max 0 = unlimited). Read before a playlist-editor stream test.
  Future<({int? max, int? active})> connectionStatus() async {
    final decoded = await _getJson('');
    final info = decoded is Map ? decoded['user_info'] : null;
    if (info is! Map) return (max: null, active: null);
    return (
      max: int.tryParse(info['max_connections']?.toString() ?? ''),
      active: int.tryParse(info['active_cons']?.toString() ?? ''),
    );
  }

  /// Verifies the credentials and account status. Throws if invalid,
  /// expired, or disabled.
  Future<void> authenticate() async {
    final decoded = await _getJson('');
    if (decoded is! Map<String, dynamic>) {
      throw Exception(tr('Unexpected Xtream API response'));
    }
    final userInfo = decoded['user_info'] as Map<String, dynamic>?;
    if (userInfo == null || userInfo['auth'] != 1) {
      throw Exception(tr('Invalid Xtream username/password'));
    }
    final status = userInfo['status'] as String?;
    if (status != 'Active') {
      throw Exception(tr('Xtream account is not active (status: {status})',
          {'status': status}));
    }
    final rawMaxConnections =
        int.tryParse(userInfo['max_connections']?.toString() ?? '');
    // "0" conventionally means unlimited on Xtream panels — leave
    // maxConnections null in that case so callers fall back to their own
    // default cap rather than reading 0 as "allow zero connections".
    maxConnections = (rawMaxConnections != null && rawMaxConnections > 0)
        ? rawMaxConnections
        : null;
    final rawExpDate = int.tryParse(userInfo['exp_date']?.toString() ?? '');
    expiryDate = (rawExpDate != null && rawExpDate > 0)
        ? DateTime.fromMillisecondsSinceEpoch(rawExpDate * 1000)
        : null;
    final serverInfo = decoded['server_info'];
    if (serverInfo is Map) {
      serverTimeZone = serverInfo['timezone']?.toString();
      serverTimeOffset = serverTimeOffsetFrom(serverInfo);
      if (serverTimeOffset != null) {
        debugPrint('Catchup: server tz=$serverTimeZone '
            'offset=${formatServerOffset(serverTimeOffset!)}');
      }
    }
  }

  /// `time_now` (provider-local wall clock) minus `timestamp_now` (UTC
  /// epoch seconds), rounded to the nearest 15 minutes. Null when either is
  /// missing or unreadable.
  static Duration? serverTimeOffsetFrom(Map serverInfo) {
    final local = DateTime.tryParse(
        '${serverInfo['time_now'] ?? ''}'.trim().replaceFirst(' ', 'T'));
    final epoch = int.tryParse('${serverInfo['timestamp_now'] ?? ''}'.trim());
    if (local == null || epoch == null) return null;
    final asUtc = DateTime.utc(local.year, local.month, local.day, local.hour,
        local.minute, local.second);
    final diff = asUtc.difference(
        DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true));
    final quarters = (diff.inSeconds / 900).round();
    return Duration(minutes: quarters * 15);
  }

  static String formatServerOffset(Duration d) {
    final sign = d.isNegative ? '-' : '+';
    final m = d.inMinutes.abs();
    return '$sign${(m ~/ 60).toString().padLeft(2, '0')}:'
        '${(m % 60).toString().padLeft(2, '0')}';
  }

  List<XtreamCategory> _toCategories(List<Map<String, dynamic>> raw) => raw
      .map((c) => XtreamCategory(
            id: c['category_id']?.toString() ?? '',
            name: c['category_name']?.toString() ?? 'Uncategorized',
          ))
      .where((c) => c.id.isNotEmpty)
      .toList();

  Future<List<XtreamCategory>> getLiveCategories() =>
      _getList('get_live_categories').then(_toCategories);

  Future<List<XtreamCategory>> getVodCategories() =>
      _getList('get_vod_categories').then(_toCategories);

  Future<List<XtreamCategory>> getSeriesCategories() =>
      _getList('get_series_categories').then(_toCategories);

  /// All live channels — fetched whole (typically single-digit MB even for
  /// large providers), since users expect to search live TV without
  /// picking a category first. [categoryNames] maps category id -> display
  /// name (from [getLiveCategories]) so [Channel.group] holds the same
  /// display name used everywhere else, keeping the sidebar's group
  /// filtering ("channels where c.group == selected group title") working
  /// identically to M3U mode.
  Future<List<Channel>> getLiveStreams(
      {required Map<String, String> categoryNames}) async {
    final raw = await _getList('get_live_streams');
    // Building a Channel per item is cheap in isolation, but a provider with
    // hundreds of live categories can mean tens of thousands of channels —
    // enough synchronous Dart work on the main isolate (no `await` inside
    // the loop to yield control) to block input dispatch past Android's 5s
    // ANR watchdog, confirmed on real hardware after "Update Content" was
    // hit right after a cold launch. One batched `compute()` call (not one
    // per item — that itself caused a launch-time isolate-spawn-storm
    // regression earlier this session) moves it off the main isolate.
    return compute(
      _buildLiveChannels,
      _LiveStreamsArgs(
        raw: raw,
        categoryNames: categoryNames,
        server: server,
        username: username,
        password: password,
        playlistId: playlistId,
      ),
    );
  }

  /// Movies for a single VOD category — call once per category, on demand.
  /// [categoryName] is the display name of [categoryId], already known by
  /// the caller (it's what the user just tapped in the sidebar).
  Future<List<Channel>> getVodStreams(
      String categoryId, String categoryName) async {
    final raw = await _getList('get_vod_streams', {'category_id': categoryId});
    // Some providers bundle thousands of items into a single category (the
    // whole reason `PlaylistManager` caps what it keeps in memory) — the
    // full list is still built once here before that cap applies, so this
    // needs the same off-main-isolate treatment as getLiveStreams.
    return compute(
      _buildVodChannels,
      _VodStreamsArgs(
        raw: raw,
        categoryName: categoryName,
        server: server,
        username: username,
        password: password,
        playlistId: playlistId,
      ),
    );
  }

  /// Plot/description for one movie — a separate on-demand call
  /// (`get_vod_info`), not part of [getVodStreams]: the list endpoint used
  /// for the whole category doesn't carry it, and fetching it for every
  /// item in a 150k-title catalog just to populate a browse grid isn't
  /// worth the request — only called when a user actually opens one
  /// movie's detail screen.
  Future<String?> getVodDescription(String streamId) async =>
      (await getVodInfo(streamId)).plot;

  /// The same `get_vod_info` call as [getVodDescription], plus the
  /// provider's own bigger art it carries for free: `cover_big` (else
  /// `movie_image`) as the poster and `backdrop_path` (a list or a single
  /// string on different panels — first http(s) entry) as the backdrop.
  ///
  /// Also the movie detail screen's metadata (genre, cast, director,
  /// release date, duration, rating) — all from this one response.
  Future<VodDetails> getVodInfo(String streamId) async {
    final decoded = await _getJson('get_vod_info', {'vod_id': streamId});
    if (decoded is! Map<String, dynamic>) return VodDetails.empty;
    final info = decoded['info'];
    if (info is! Map) return VodDetails.empty;
    return VodDetails(
      trailers: TrailerLinks.fromMetadata(info),
      plot: _nonEmpty(info['plot']) ?? _nonEmpty(info['description']),
      posterUrl: _httpUrl(info['cover_big']) ?? _httpUrl(info['movie_image']),
      backdropUrls: backdropUrlsOf(info['backdrop_path']),
      genre: _nonEmpty(info['genre']),
      cast: _nonEmpty(info['cast']) ?? _nonEmpty(info['actors']),
      director: _nonEmpty(info['director']),
      releaseDate:
          _nonEmpty(info['releasedate']) ?? _nonEmpty(info['release_date']),
      durationSeconds: _durationSeconds(info),
      rating: _rating(info['rating']),
    );
  }

  static String? _httpUrl(Object? raw) {
    final s = _nonEmpty(raw);
    return (s != null && s.startsWith('http')) ? s : null;
  }

  /// `backdrop_path` comes as a list on most panels, a bare string on
  /// some — every http(s) entry, in order.
  static List<String> backdropUrlsOf(Object? raw) {
    final out = <String>[];
    if (raw is List) {
      for (final b in raw) {
        final url = _httpUrl(b);
        if (url != null) out.add(url);
      }
    } else {
      final url = _httpUrl(raw);
      if (url != null) out.add(url);
    }
    return out;
  }

  /// Series (not directly playable) for a single category — call once per
  /// category, on demand. Use [getSeriesEpisodes] to resolve a chosen
  /// series into its playable episodes.
  Future<List<XtreamSeries>> getSeriesForCategory(String categoryId) async {
    final raw = await _getList('get_series', {'category_id': categoryId});
    // Same rationale as getVodStreams above — a single category can hold
    // thousands of series.
    return compute(_buildSeriesItems,
        _SeriesArgs(raw: raw, categoryId: categoryId, playlistId: playlistId));
  }

  /// Episodes for one series, grouped by season number, plus the series'
  /// own plot/description — both come from the same `get_series_info`
  /// call, so this returns both rather than making SeriesDetailScreen pay
  /// for a second request just for the plot.
  ///
  /// `details` carries the rest of `info` (backdrop, genre, cast, rating,
  /// run time) and each episode's own plot/duration — display-only, for
  /// SeriesDetailScreen; null when [plotOnly] or the response is unusable.
  Future<SeriesEpisodesResult> getSeriesEpisodes(
    int seriesId,
    String seriesName, {
    // The browse hero only ever wants the plot (see PlaylistManager
    // .getHeroSeriesDescription) — skips the entire episode-map build
    // below, which it would just discard, without needing a second
    // endpoint (plot already comes from this same `get_series_info` call).
    bool plotOnly = false,
  }) async {
    final decoded =
        await _getJson('get_series_info', {'series_id': '$seriesId'});
    if (decoded is! Map<String, dynamic>)
      return (episodes: <int, List<Channel>>{}, plot: null, details: null);

    final info = decoded['info'];
    final rawPlot = info is Map ? info['plot']?.toString() : null;
    final plot = (rawPlot != null && rawPlot.isNotEmpty) ? rawPlot : null;
    if (plotOnly) {
      // The browse hero also wants the fanart (see PlaylistManager
      // .getHeroSeriesDescription) — it's in this same response.
      return (
        episodes: <int, List<Channel>>{},
        plot: plot,
        details: info is Map
            ? SeriesDetails(backdropUrls: backdropUrlsOf(info['backdrop_path']))
            : null,
      );
    }

    final episodeDetails = <String, EpisodeDetails>{};
    final result = <int, List<Channel>>{};
    final episodesByS = decoded['episodes'];
    if (episodesByS is Map) {
      episodesByS.forEach((seasonKey, episodeList) {
        final season = int.tryParse(seasonKey.toString()) ?? 0;
        if (episodeList is! List) return;
        final channels = <Channel>[];
        for (final raw in episodeList) {
          if (raw is! Map) continue;
          final episode = raw;
          final episodeId = episode['id'];
          final ext = episode['container_extension']?.toString() ?? 'mp4';
          final episodeNum = episode['episode_num']?.toString() ?? '?';
          final title = episode['title']?.toString() ?? 'Episode $episodeNum';
          // Most Xtream panels include a per-episode still under `info`
          // (commonly `movie_image`) — read it defensively, since not every
          // panel supplies it; the UI falls back to the series' own cover
          // art when this is null rather than showing a blank card.
          final info = episode['info'];
          final stillUrl = info is Map ? info['movie_image']?.toString() : null;
          final rawId = 'xt_ep_$episodeId';
          final id = '$playlistId::$rawId';
          channels.add(Channel(
            id: id,
            rawId: rawId,
            playlistId: playlistId,
            name: 'S${season}E$episodeNum — $title',
            group: seriesName,
            url: '$server/series/$username/$password/$episodeId.$ext',
            logoUrl:
                (stillUrl != null && stillUrl.isNotEmpty) ? stillUrl : null,
          ));
          episodeDetails[id] = EpisodeDetails(
            season: season,
            episodeNumber: int.tryParse(episodeNum),
            title: episode['title']?.toString(),
            plot: info is Map ? _nonEmpty(info['plot']) : null,
            durationSeconds: info is Map ? _durationSeconds(info) : null,
            airDate: info is Map
                ? (_nonEmpty(info['releasedate']) ??
                    _nonEmpty(info['air_date']))
                : null,
            rating: info is Map ? _rating(info['rating']) : null,
          );
        }
        result[season] = channels;
      });
    }

    final seasonNames = <int, String>{};
    final seasons = decoded['seasons'];
    if (seasons is List) {
      for (final s in seasons) {
        if (s is! Map) continue;
        final number = int.tryParse(s['season_number']?.toString() ?? '');
        final name = _nonEmpty(s['name']);
        if (number != null && name != null) seasonNames[number] = name;
      }
    }

    SeriesDetails? details;
    if (info is Map) {
      final backdrops = backdropUrlsOf(info['backdrop_path']);
      details = SeriesDetails(
        trailers: TrailerLinks.fromMetadata(info),
        backdropUrls: backdrops,
        coverUrl: _nonEmpty(info['cover']),
        genre: _nonEmpty(info['genre']),
        cast: _nonEmpty(info['cast']),
        director: _nonEmpty(info['director']),
        releaseDate:
            _nonEmpty(info['releaseDate']) ?? _nonEmpty(info['release_date']),
        rating: _rating(info['rating']),
        episodeRunTimeMinutes:
            int.tryParse(info['episode_run_time']?.toString() ?? ''),
        seasonNames: seasonNames,
        episodes: episodeDetails,
      );
    } else {
      details =
          SeriesDetails(seasonNames: seasonNames, episodes: episodeDetails);
    }

    return (episodes: result, plot: plot, details: details);
  }

  static String? _nonEmpty(Object? raw) {
    final s = raw?.toString().trim();
    return (s == null || s.isEmpty || s == 'null') ? null : s;
  }

  /// Panels send "0", "0.0" or "" for "no rating" — those are dropped.
  static String? _rating(Object? raw) {
    final s = _nonEmpty(raw);
    if (s == null) return null;
    final value = double.tryParse(s);
    if (value == null || value <= 0) return null;
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  /// `duration_secs` when present, otherwise parses `duration`. Panels send
  /// it as "01:58:10", "1:58" (h:mm) or a bare "118" (minutes) — reading
  /// the last two as seconds showed The King's Speech as "2 min" (owner's
  /// Formuler). A `duration_secs` under 5 minutes is taken as minutes too.
  static int? _durationSeconds(Map info) {
    final secs = int.tryParse(info['duration_secs']?.toString() ?? '');
    if (secs != null && secs > 0) return secs < 300 ? secs * 60 : secs;
    final raw = _nonEmpty(info['duration']);
    if (raw == null) return null;
    final parts = raw.trim().split(':').map(int.tryParse).toList();
    if (parts.isEmpty || parts.any((p) => p == null)) return null;
    final int total;
    if (parts.length == 1) {
      total = parts[0]! * 60;
    } else if (parts.length == 2) {
      // "1:58" = 1 h 58 min; "45:12" = 45 min 12 s.
      total = parts[0]! <= 4
          ? parts[0]! * 3600 + parts[1]! * 60
          : parts[0]! * 60 + parts[1]!;
    } else {
      total = parts.fold(0, (t, p) => t * 60 + p!);
    }
    return total > 0 ? total : null;
  }
}

// Top-level — required by `compute`, which runs this on a separate isolate
// with no access to instance state.
dynamic _decodeJsonBody(String body) => jsonDecode(body);

class _LiveStreamsArgs {
  const _LiveStreamsArgs({
    required this.raw,
    required this.categoryNames,
    required this.server,
    required this.username,
    required this.password,
    required this.playlistId,
  });
  final List<Map<String, dynamic>> raw;
  final Map<String, String> categoryNames;
  final String server;
  final String username;
  final String password;
  final String playlistId;
}

/// Catch-up days of one `get_live_streams` entry: `tv_archive_duration`
/// when `tv_archive` is 1 (either may come as an int or a string), clamped
/// to 0..30; anything unreadable is 0.
int xtreamCatchupDays(Map item) {
  if (int.tryParse('${item['tv_archive'] ?? ''}'.trim()) != 1) return 0;
  final days = int.tryParse('${item['tv_archive_duration'] ?? ''}'.trim());
  if (days == null) return 0;
  return days.clamp(0, 30);
}

List<Channel> _buildLiveChannels(_LiveStreamsArgs args) {
  return args.raw.map((item) {
    final streamId = item['stream_id'];
    final epgChannelId = item['epg_channel_id']?.toString();
    final rawId = (epgChannelId != null && epgChannelId.isNotEmpty)
        ? epgChannelId
        : 'xt_live_$streamId';
    final categoryId = item['category_id']?.toString() ?? '';
    final days = xtreamCatchupDays(item);
    final added = int.tryParse(item['added']?.toString() ?? '');
    return Channel(
      id: '${args.playlistId}::$rawId',
      rawId: rawId,
      playlistId: args.playlistId,
      name: item['name']?.toString() ?? 'Unnamed Channel',
      group: args.categoryNames[categoryId] ?? 'Uncategorized',
      // .ts, not .m3u8: HLS needs the player to keep re-fetching a
      // manifest file every few seconds for the whole time a channel is
      // playing, and a reverse-proxying relay (tuliprox) only retries a
      // failed fetch during that *first* connection — a follow-up
      // manifest refresh that fails mid-session just fails outright, with
      // nothing on either side reconnecting it (confirmed directly:
      // "back out and back in, plays fine for a while, stops again").
      // Plain TS is one continuous connection with no periodic refetch to
      // fail in the first place, and a dropped TS connection is treated
      // as a fresh stream open by the relay — which *does* get retried.
      url: '${args.server}/live/${args.username}/${args.password}/$streamId.ts',
      logoUrl: item['stream_icon']?.toString(),
      streamId: streamId?.toString(),
      catchupDays: days,
      catchupKind: days > 0 ? CatchupKind.xc : null,
      // "Recently added" group (opt in).
      addedAt: (added != null && added > 0)
          ? DateTime.fromMillisecondsSinceEpoch(added * 1000)
          : null,
    );
  }).toList();
}

class _VodStreamsArgs {
  const _VodStreamsArgs({
    required this.raw,
    required this.categoryName,
    required this.server,
    required this.username,
    required this.password,
    required this.playlistId,
  });
  final List<Map<String, dynamic>> raw;
  final String categoryName;
  final String server;
  final String username;
  final String password;
  final String playlistId;
}

List<Channel> _buildVodChannels(_VodStreamsArgs args) {
  return args.raw.map((item) {
    final streamId = item['stream_id'];
    final ext = item['container_extension']?.toString() ?? 'mp4';
    final rating = item['rating']?.toString();
    final added = int.tryParse(item['added']?.toString() ?? '');
    final tmdbId = item['tmdb']?.toString();
    // Rare in the list response, but free when a panel sends it.
    final backdrops = XtreamApiService.backdropUrlsOf(item['backdrop_path']);
    final rawId = 'xt_vod_$streamId';
    return Channel(
      id: '${args.playlistId}::$rawId',
      rawId: rawId,
      playlistId: args.playlistId,
      name: item['name']?.toString() ?? 'Unnamed Movie',
      group: args.categoryName,
      url:
          '${args.server}/movie/${args.username}/${args.password}/$streamId.$ext',
      logoUrl: item['stream_icon']?.toString(),
      rating: (rating != null && rating.isNotEmpty && rating != '0')
          ? rating
          : null,
      addedAt: (added != null && added > 0)
          ? DateTime.fromMillisecondsSinceEpoch(added * 1000)
          : null,
      tmdbId: (tmdbId != null && tmdbId.isNotEmpty && tmdbId != '0')
          ? tmdbId
          : null,
      providerBackdropUrl: backdrops.isEmpty ? null : backdrops.first,
    );
  }).toList();
}

class _SeriesArgs {
  const _SeriesArgs(
      {required this.raw, required this.categoryId, required this.playlistId});
  final List<Map<String, dynamic>> raw;
  final String categoryId;
  final String playlistId;
}

List<XtreamSeries> _buildSeriesItems(_SeriesArgs args) {
  return args.raw.map((item) {
    final rating = item['rating']?.toString();
    // `last_modified`, not `added` — see XtreamSeries.addedAt's doc comment.
    final lastModified = int.tryParse(item['last_modified']?.toString() ?? '');
    final tmdbId = item['tmdb']?.toString();
    // Many panels already put the fanart in the list response itself.
    final backdrops = XtreamApiService.backdropUrlsOf(item['backdrop_path']);
    return XtreamSeries(
      seriesId: int.parse(item['series_id'].toString()),
      playlistId: args.playlistId,
      name: item['name']?.toString() ?? 'Unnamed Series',
      categoryId: args.categoryId,
      coverUrl: item['cover']?.toString(),
      rating: (rating != null && rating.isNotEmpty && rating != '0')
          ? rating
          : null,
      addedAt: (lastModified != null && lastModified > 0)
          ? DateTime.fromMillisecondsSinceEpoch(lastModified * 1000)
          : null,
      tmdbId: (tmdbId != null && tmdbId.isNotEmpty && tmdbId != '0')
          ? tmdbId
          : null,
      providerBackdropUrl: backdrops.isEmpty ? null : backdrops.first,
    );
  }).toList();
}
