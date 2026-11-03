import 'media_subtitle.dart';
import 'catchup.dart';
import 'media_file_info.dart';

/// A manual cross-playlist link — see
/// `AppConstants.keyChannelLinks`'s doc comment. Identifies another
/// [Channel] by its own (playlistId, rawId), the same pair
/// `PlaylistManager.resolveChannelLink` looks a live [Channel] back up
/// from.
typedef ChannelLink = ({String playlistId, String rawId});

/// A single playable entry parsed from an M3U playlist (a live TV channel
/// or a VOD/movie item — the app treats both the same way at this level).
class Channel {
  Channel({
    required this.id,
    required this.rawId,
    required this.playlistId,
    required String name,
    required this.group,
    required this.url,
    String? logoUrl,
    this.subtitleUrl,
    this.subtitles = const [],
    this.httpHeaders = const {},
    this.isFavorite = false,
    this.rating,
    this.addedAt,
    this.seriesId,
    this.seriesName,
    this.seriesCoverUrl,
    this.epgIdOverride,
    this.epgKey,
    this.tmdbId,
    this.releaseDate,
    this.posterUrl,
    this.backdropUrl,
    this.providerPosterUrl,
    this.providerBackdropUrl,
    this.transientPlayback = false,
    this.mediaFileInfo,
    this.onDemand = false,
    this.catchupDays = 0,
    this.catchupKind,
    this.catchupSource,
    this.streamId,
    this.imdbId,
  })  : sourceName = name,
        sourceLogoUrl = logoUrl;

  /// Stable identifier: the M3U `tvg-id` when present (used to match EPG
  /// programmes), otherwise a generated fallback. Already prefixed with
  /// `playlistId` at construction time (see `XtreamApiService`/
  /// `M3uParser`) so ids stay globally unique once channels from more than
  /// one playlist are merged into the same lists — two different
  /// providers can easily reuse the same raw `stream_id`/`tvg-id`.
  final String id;

  /// The pre-multi-playlist-support id shape, unprefixed — e.g.
  /// `xt_vod_$streamId`, `xt_ep_$episodeId`, `xt_live_$streamId`/an
  /// `epg_channel_id`, or an M3U `tvg-id`. [id] is `'$playlistId::$rawId'`.
  /// Kept as its own field (not derived by string-stripping [id] at every
  /// call site — `playlistId` is variable-length, `::` splitting would be
  /// fragile) purely for the handful of places that pattern-match on the
  /// provider's own id shape: [isLiveId], the Movies/TV-Shows "Continue
  /// Watching" `xt_vod_`/`xt_ep_` prefix filters, and
  /// `PlaylistManager.getVodDescription`'s raw-stream-id extraction.
  final String rawId;

  /// Explicit M3U catalog type. IDs stay unchanged for favourites, EPG and
  /// history; an ordinary tvg-id alone cannot distinguish a movie from TV.
  final bool onDemand;

  /// Playback controls and lifecycle must agree about M3U movies too.
  /// Never infer this from duration: live HLS can expose a DVR window.
  bool get isLive => !onDemand && isLiveId(rawId);

  /// Days of past programmes the provider keeps for this live channel
  /// (Xtream `tv_archive_duration`, M3U `catchup-days`/`tvg-rec`). 0 = none.
  final int catchupDays;

  /// How past programmes are requested; null = no catch-up.
  final CatchupKind? catchupKind;

  /// M3U `catchup-source` template (placeholders like `{utc}`), if any.
  final String? catchupSource;

  /// The provider's own stream id (Xtream `stream_id`). Live channels with
  /// an EPG id don't carry it in [rawId]; catch-up links need it.
  final String? streamId;

  /// A Media Hub title's IMDb id (`tt…`, the series' id for an episode):
  /// what subtitle add-ons are asked with (AddonService).
  final String? imdbId;

  bool get hasCatchup => isLive && catchupDays > 0 && catchupKind != null;

  /// Which playlist this channel came from — the same id every group,
  /// hidden-groups entry, and cache-file name for this playlist share
  /// (see `PlaylistProfile.id`). Used to detect a playlist boundary when
  /// rendering merged group lists (a divider between Playlist A's and
  /// Playlist B's groups), and to scope Group Management/favorites-group
  /// lookups.
  final String playlistId;
  /// The provider's own name. Matching (Sports, quality copies, EPG by
  /// name) uses this; [name] is what the viewer sees.
  final String sourceName;

  /// Playlist editor rename (`PlaylistEdits`), stamped on every load like
  /// [epgIdOverride]. Never persisted with the channel.
  String? nameOverride;

  String get name => nameOverride ?? sourceName;
  final String group;
  final String url;

  /// One-off trailer playback: no library history, resume or watch tracking.
  /// In memory only; trailers are never persisted as catalog entries.
  final bool transientPlayback;

  /// Selected Media Hub file, in memory only; refreshed when streams resolve.
  final MediaFileInfo? mediaFileInfo;

  factory Channel.trailer({required String title, required String url}) {
    final raw = 'arc_vod_trailer_${DateTime.now().microsecondsSinceEpoch}';
    return Channel(
        id: 'trailer::$raw',
        rawId: raw,
        playlistId: 'trailer',
        name: title,
        group: '',
        url: url,
        transientPlayback: true);
  }
  final String? sourceLogoUrl;

  /// Playlist editor logo, see [nameOverride].
  String? logoOverride;

  String? get logoUrl => logoOverride ?? sourceLogoUrl;
  final String? subtitleUrl;

  /// Per-file add-on data; never persisted in channel history.
  final List<MediaSubtitle> subtitles;
  final Map<String, String> httpHeaders;
  bool isFavorite;

  /// Provider-supplied rating (e.g. Xtream's `rating` field on VOD items).
  /// Meaningless for live channels — null there.
  final String? rating;

  /// When the provider says this title showed up in its catalog (Xtream's
  /// `added` field on VOD items, epoch seconds). Null for live channels,
  /// for M3U playlists (no such concept exists there at all), and whenever
  /// the provider didn't report it — the "What's New" carousel simply has
  /// nothing to show in those cases rather than guessing an order.
  final DateTime? addedAt;

  /// Set on episode channels only (see PlaylistManager.loadSeriesEpisodes)
  /// — the series this episode belongs to, so "Continue Watching" can show
  /// and reopen the actual show instead of just this one episode. Mutable
  /// (like [isFavorite]) rather than requiring a full reconstruction each
  /// time a season screen is opened.
  int? seriesId;
  String? seriesName;
  String? seriesCoverUrl;

  /// A manually-assigned EPG channel id (see
  /// `PlaylistManager.setEpgIdOverride`), replacing [rawId] as the key an
  /// EPG lookup uses for this channel — set on the already-loaded
  /// `Channel` in place, the same "mutate in place, no full reload"
  /// pattern [isFavorite] already uses, and reapplied from
  /// [PlaylistSession.epgIdOverrides] every time this channel's list is
  /// (re)built (see the `favoriteIds()` stamping loops in
  /// `playlist_session.dart`, right next to where this is stamped
  /// alongside them). Exists because a provider's own `epg_channel_id`/
  /// `tvg-id` for a channel can be missing, wrong, or simply not covered
  /// by whatever third-party XMLTV source is configured — reported
  /// directly (Trex channels with no EPG match at all in a third-party
  /// feed that otherwise parses fine). Null means "use rawId", not "no
  /// EPG" — every existing channel keeps working exactly as before.
  String? epgIdOverride;

  /// The TMDB (The Movie Database) id this title is looked up by — the
  /// provider's own `get_vod_streams`/`get_series` bulk list call
  /// [addedAt] already comes from sends one for *some* items at zero extra
  /// network cost; when it doesn't (confirmed directly: entirely untagged
  /// on some providers, with no TMDB-sourced [releaseDate]/[posterUrl]
  /// ever appearing as a result — "What's New" looked like it was simply
  /// never using TMDB at all), [TmdbEnrichmentService] resolves one itself
  /// via a title search instead and stamps it in here. Mutable (not
  /// `final`) for exactly that reason — same pattern [releaseDate]/
  /// [posterUrl] already use. Exists purely as the lookup key those two
  /// are fetched with; nothing else in the app reads this directly.
  String? tmdbId;

  /// The title's actual real-world release date — deliberately *not* the
  /// same thing as [addedAt] (when the provider's own catalog first
  /// listed it), which is often months or years off from when something
  /// actually released. Reported directly: wanted to sort a category by
  /// genuine release recency ("just came out Oct 1 2026" at the top), not
  /// by provider ingestion date. Requires a separate TMDB API lookup per
  /// [tmdbId] (see `TmdbEnrichmentService`) — not available from the bulk
  /// catalog list the way [addedAt]/[rating] are, so this stays null until
  /// that lookup has actually run and cached a result for this item.
  /// Mutable (not `final`) — same "stamp it in place on the already-built
  /// object" pattern [epgIdOverride]/[seriesId] use, since enrichment runs
  /// *after* a category's [Channel] objects already exist in memory.
  DateTime? releaseDate;

  /// A TMDB poster image, fetched at zero extra request cost — the same
  /// per-[tmdbId] lookup `TmdbEnrichmentService` already makes for
  /// [releaseDate] returns a `poster_path` in that identical response.
  /// Consistently higher-resolution and more reliably present than a
  /// provider's own [logoUrl]/[seriesCoverUrl] (reported directly as this
  /// app's least-liked thing about the "What's New" row), so callers
  /// prefer this over those when it's set, falling back otherwise. Same
  /// mutable "stamp in place" reasoning as [releaseDate].
  String? posterUrl;

  /// A TMDB *backdrop* image — a landscape (16:9) scene still/key-art,
  /// a completely different asset from [posterUrl]'s portrait poster,
  /// fetched from the same per-[tmdbId] lookup at no extra request cost
  /// (`backdrop_path` rides along in that identical response). Requested
  /// directly after seeing TiviMate's full-bleed hero banner: stretching
  /// [posterUrl] (portrait) to fill a wide banner is the exact "hand and
  /// a desk" crop bug this app already hit once building its own hero —
  /// a real landscape backdrop is the actual fix, not a different crop of
  /// the same wrong image. Same mutable "stamp in place" pattern as
  /// [posterUrl]; null until enrichment has run for this item, same as
  /// every TMDB-sourced field here.
  String? backdropUrl;

  /// The provider's own bigger artwork from `get_vod_info` (`cover_big`,
  /// else `movie_image`) — keyless, unlike [posterUrl]. Only fetched when a
  /// movie's detail screen opens or the browse hero dwells on it (the same
  /// one request that brings its plot), then persisted. Null until then.
  String? providerPosterUrl;

  /// `get_vod_info`'s `backdrop_path` (first entry) — a landscape image for
  /// the hero/detail background when no TMDB [backdropUrl] exists. Same
  /// on-demand fetch and persistence as [providerPosterUrl].
  String? providerBackdropUrl;

  /// Hero/detail background order: TMDB backdrop, then the provider's.
  String? get anyBackdropUrl {
    for (final u in [backdropUrl, providerBackdropUrl]) {
      if (u != null && u.isNotEmpty) return u;
    }
    return null;
  }

  /// The id every EPG lookup call site uses — see [epgIdOverride]'s doc
  /// comment. Never [rawId] directly from an EPG-lookup call site; that
  /// would bypass a manual assignment.
  String get epgId => epgIdOverride ?? epgKey ?? rawId;

  /// The provider's own EPG id (`epg_channel_id`/`tvg-id`) when [rawId] is
  /// not it — set by [withUniqueIds] for channels that shared one. Null =
  /// [rawId] is the EPG id.
  final String? epgKey;

  /// Gives channels that share an id (the id is the provider's EPG id, and
  /// "ESPN 4K", "ESPN HD" and "ESPN FHD" often all carry the same one) ids
  /// of their own, so starring, hiding or picking one no longer hits all of
  /// them. Each one becomes `<epg id>#<last URL segment>` (the stream id —
  /// stable across reloads), with the EPG id kept in [epgKey] so the guide
  /// still finds them. Channels with a unique id are untouched, so nothing
  /// saved for them changes. Idempotent: an already-fixed list (from the
  /// cache) has nothing left to fix.
  static List<Channel> withUniqueIds(List<Channel> channels) {
    final counts = <String, int>{};
    for (final c in channels) {
      counts[c.id] = (counts[c.id] ?? 0) + 1;
    }
    if (!counts.values.any((n) => n > 1)) return channels;
    final used = {
      for (final e in counts.entries)
        if (e.value == 1) e.key
    };
    return [
      for (final c in channels)
        if (counts[c.id] == 1) c else c._withUniqueRawId(used)
    ];
  }

  Channel _withUniqueRawId(Set<String> used) {
    final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    var key = segments.isEmpty ? '' : segments.last;
    final dot = key.lastIndexOf('.');
    if (dot > 0) key = key.substring(0, dot);
    final base = key.isEmpty ? '$rawId#' : '$rawId#$key';
    var newRaw = base;
    for (var n = 2; used.contains('$playlistId::$newRaw'); n++) {
      newRaw = '$base~$n';
    }
    used.add('$playlistId::$newRaw');
    return copyWith(
        id: '$playlistId::$newRaw', rawId: newRaw, epgKey: epgKey ?? rawId);
  }

  Channel copyWith(
          {bool? isFavorite,
          String? id,
          String? rawId,
          String? epgKey,
          String? url,
          Map<String, String>? httpHeaders,
          MediaFileInfo? mediaFileInfo,
          bool? onDemand,
          int? catchupDays}) =>
      Channel(
        id: id ?? this.id,
        rawId: rawId ?? this.rawId,
        onDemand: onDemand ?? this.onDemand,
        epgKey: epgKey ?? this.epgKey,
        playlistId: playlistId,
        name: sourceName,
        group: group,
        url: url ?? this.url,
        logoUrl: sourceLogoUrl,
        subtitleUrl: subtitleUrl,
        subtitles: subtitles,
        httpHeaders: httpHeaders ?? this.httpHeaders,
        isFavorite: isFavorite ?? this.isFavorite,
        rating: rating,
        addedAt: addedAt,
        seriesId: seriesId,
        seriesName: seriesName,
        seriesCoverUrl: seriesCoverUrl,
        epgIdOverride: epgIdOverride,
        tmdbId: tmdbId,
        releaseDate: releaseDate,
        posterUrl: posterUrl,
        backdropUrl: backdropUrl,
        providerPosterUrl: providerPosterUrl,
        providerBackdropUrl: providerBackdropUrl,
        transientPlayback: transientPlayback,
        mediaFileInfo: mediaFileInfo ?? this.mediaFileInfo,
        catchupDays: catchupDays ?? this.catchupDays,
        catchupKind: catchupKind,
        catchupSource: catchupSource,
        streamId: streamId,
        imdbId: imdbId,
      )
        ..nameOverride = nameOverride
        ..logoOverride = logoOverride;

  Map<String, dynamic> toJson() => {
        'id': id,
        'rawId': rawId,
        if (onDemand) 'onDemand': true,
        if (epgKey != null) 'epgKey': epgKey,
        'playlistId': playlistId,
        'name': sourceName,
        'group': group,
        'url': url,
        'logoUrl': sourceLogoUrl,
        'subtitleUrl': subtitleUrl,
        'isFavorite': isFavorite,
        'rating': rating,
        'addedAt': addedAt?.millisecondsSinceEpoch,
        'seriesId': seriesId,
        'seriesName': seriesName,
        'seriesCoverUrl': seriesCoverUrl,
        'tmdbId': tmdbId,
        'releaseDate': releaseDate?.millisecondsSinceEpoch,
        'posterUrl': posterUrl,
        'backdropUrl': backdropUrl,
        'providerPosterUrl': providerPosterUrl,
        'providerBackdropUrl': providerBackdropUrl,
        if (catchupDays > 0) 'catchupDays': catchupDays,
        if (catchupKind != null) 'catchupKind': catchupKind!.name,
        if (catchupSource != null) 'catchupSource': catchupSource,
        if (streamId != null) 'streamId': streamId,
        if (imdbId != null) 'imdbId': imdbId,
      };

  /// `playlistId` defaults to `'migrated_default'` and `rawId` to [id]
  /// itself when absent from a decoded blob — belt-and-suspenders only:
  /// every on-disk cache file this reads gained a playlist-id-suffixed
  /// name in this same release (see `PlaylistManager`'s per-session cache
  /// naming), so a pre-multi-playlist cache file is simply never looked up
  /// again under its old unsuffixed name post-upgrade, not silently
  /// misread as if it had these fields.
  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        id: json['id'] as String,
        rawId: json['rawId'] as String? ?? json['id'] as String,
        epgKey: json['epgKey'] as String?,
        onDemand: json['onDemand'] as bool? ?? false,
        playlistId: json['playlistId'] as String? ?? 'migrated_default',
        name: json['name'] as String,
        group: json['group'] as String,
        url: json['url'] as String,
        logoUrl: json['logoUrl'] as String?,
        subtitleUrl: json['subtitleUrl'] as String?,
        isFavorite: json['isFavorite'] as bool? ?? false,
        rating: json['rating'] as String?,
        addedAt: json['addedAt'] is int
            ? DateTime.fromMillisecondsSinceEpoch(json['addedAt'] as int)
            : null,
        seriesId: json['seriesId'] as int?,
        seriesName: json['seriesName'] as String?,
        seriesCoverUrl: json['seriesCoverUrl'] as String?,
        tmdbId: json['tmdbId'] as String?,
        releaseDate: json['releaseDate'] is int
            ? DateTime.fromMillisecondsSinceEpoch(json['releaseDate'] as int)
            : null,
        posterUrl: json['posterUrl'] as String?,
        backdropUrl: json['backdropUrl'] as String?,
        providerPosterUrl: json['providerPosterUrl'] as String?,
        providerBackdropUrl: json['providerBackdropUrl'] as String?,
        catchupDays: json['catchupDays'] as int? ?? 0,
        catchupKind: _catchupKindByName[json['catchupKind']],
        catchupSource: json['catchupSource'] as String?,
        streamId: json['streamId'] as String?,
        imdbId: json['imdbId'] as String?,
      );

  static final Map<String, CatchupKind> _catchupKindByName = {
    for (final k in CatchupKind.values) k.name: k
  };

  /// Legacy raw-ID classification for Xtream, Media Hub and recordings.
  /// Use [isLive] when a Channel is available: M3U movie IDs have no prefix.
  /// Takes rawId, never the playlist-prefixed composite id.
  static bool isLiveId(String rawId) => !(rawId.startsWith('xt_vod_') ||
      rawId.startsWith('xt_ep_') ||
      isCatchupId(rawId) ||
      isArchiveId(rawId) ||
      isRecordingId(rawId));

  /// An Archive tab movie/episode (ArchiveService.resolve) — no playlist
  /// profile backs it.
  static bool isArchiveId(String rawId) =>
      rawId.startsWith('arc_vod_') || rawId.startsWith('arc_ep_');

  /// A Sports Trak recording (RecordingService.channelFor): a local file,
  /// seekable, no playlist profile backs it.
  static const recordingPrefix = 'rec_';
  static bool isRecordingId(String rawId) => rawId.startsWith(recordingPrefix);

  /// A past programme played from a live channel's catch-up
  /// (`PlaybackService.playCatchup`): finite, seekable, never live.
  static const catchupPrefix = 'cu_';
  static bool isCatchupId(String rawId) => rawId.startsWith(catchupPrefix);
}
