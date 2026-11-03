/// Playlist Manager > Stream format ([PlaylistProfile.liveHls]): Xtream
/// live channels of an HLS playlist open as `…/live/user/pass/id.m3u8`.
/// Channel URLs stay `.ts` in the catalog; the link is swapped only when a
/// player opens it, so switching needs no content update.
class LiveStreamFormat {
  /// `/live/user/pass/` of every Xtream playlist set to HLS. Set by
  /// PlaylistManager.
  static Iterable<String> Function() hlsAccounts = () => const [];

  static String urlFor(String url) {
    if (!url.endsWith('.ts')) return url;
    for (final account in hlsAccounts()) {
      if (url.contains(account)) {
        return '${url.substring(0, url.length - 3)}.m3u8';
      }
    }
    return url;
  }
}
