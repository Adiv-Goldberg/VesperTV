import '../models/channel.dart';
import '../utils/channel_name_matching.dart';

/// Automatic inline failover for a live channel (`TSN 1 4K` fails ->
/// `TSN 1 FHD` -> `TSN 1 HD`), see `dev-notes/iptv-editor-plan.md`.
/// Candidates come from `PlaylistManager.failoverCandidatesFor` (editor
/// fallbacks, the manual channel link, then quality copies found with
/// [channelCopyKey], the same identity Sports uses).
///
/// The requested channel keeps its id/name/EPG: only the URL is swapped
/// (`channel.copyWith(url: copy.url)`), so the guide, zapping, history and
/// favourites still see the channel the viewer picked.
class ChannelCopyFallback {
  String? _channelId;
  DateTime _startedAt = DateTime.fromMillisecondsSinceEpoch(0);
  final Set<String> _tried = {};

  /// Failures per stream URL this run of the app: a copy that keeps failing
  /// sinks below its working siblings (reliability counts, not only labels).
  static final Map<String, int> _failures = {};

  /// A failed attempt is forgotten after this, so a later press on the same
  /// channel tries the best copy again.
  static const _window = Duration(minutes: 2);

  static void recordFailure(String url) {
    if (url.isEmpty) return;
    _failures[url] = (_failures[url] ?? 0) + 1;
    if (_failures.length > 500) _failures.remove(_failures.keys.first);
  }

  static int failuresOf(String url) => _failures[url] ?? 0;

  /// Higher = better. Unlabelled sits between SD and HD: most providers'
  /// plain name is their HD feed.
  static int qualityRank(String name) {
    final words = name
        .toUpperCase()
        .replaceAll(RegExp(r'[^\w+]'), ' ')
        .split(RegExp(r'\s+'))
        .toSet();
    if (words.contains('8K')) return 6;
    if (words.contains('4K') || words.contains('UHD')) return 5;
    if (words.contains('FHD') || words.contains('1080P')) return 4;
    if (words.contains('HD') || words.contains('720P')) return 3;
    if (words.contains('SD')) return 1;
    return 2;
  }

  /// Copies of [channel] in [pool], best first, [channel] itself excluded.
  /// [rank] defaults to the name label ([qualityRank]); the editor passes
  /// one that prefers measured quality.
  static List<Channel> copiesOf(Channel channel, Iterable<Channel> pool,
      {int Function(Channel)? rank}) {
    final key = channelCopyKey(channel.sourceName);
    if (key.isEmpty) return const [];
    final score = rank ?? (Channel c) => qualityRank(c.sourceName);
    final copies = [
      for (final c in pool)
        if (c.id != channel.id &&
            c.url != channel.url &&
            c.url.isNotEmpty &&
            channelCopyKey(c.sourceName) == key)
          c
    ];
    int value(Channel c) => score(c) * 10 - failuresOf(c.url).clamp(0, 9);
    copies.sort((a, b) => value(b).compareTo(value(a)));
    return copies;
  }

  /// The next untried candidate after [channel] failed, or null when none
  /// is left (each one is tried once per window: no loops).
  Channel? next(Channel channel, List<Channel> candidates, {DateTime? now}) {
    if (!channel.isLive || channel.transientPlayback) return null;
    final at = now ?? DateTime.now();
    if (_channelId != channel.id || at.difference(_startedAt) > _window) {
      _channelId = channel.id;
      _startedAt = at;
      _tried.clear();
    }
    _tried.add(channel.url);
    recordFailure(channel.url);
    for (final c in candidates) {
      if (_tried.add(c.url)) return c;
    }
    return null;
  }
}
