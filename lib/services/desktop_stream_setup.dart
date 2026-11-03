import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

/// What the Windows player says it is. mpv's own "libmpv" is on many IPTV
/// panels' blocked list for live streams: a Windows user had black live TV
/// (no picture, no sound, no error) while VOD, Media Hub and the same
/// playlist on their phone all worked (LOG-HCLSJZ, 2026-11-02). Android's
/// player identifies as Dalvik, which panels accept.
const kDesktopStreamUserAgent =
    'Dalvik/2.1.0 (Linux; U; Android 11; VesperTV Windows)';

/// The shared mpv setup for every Windows stream player (full screen, mini
/// player, Multiview): reconnect tuning, the User-Agent above, and mpv
/// errors into Send log (a refused stream used to fail silently).
void configureDesktopStreamPlayer(Player player, String tag) {
  final native = player.platform as NativePlayer;
  // See DesktopPlayerScreen.initState for the reconnect story.
  native.setProperty('demuxer-lavf-o',
      'reconnect=1,reconnect_at_eof=1,reconnect_streamed=1,reconnect_delay_max=5,rw_timeout=15000000');
  native.setProperty('user-agent', kDesktopStreamUserAgent);
  player.stream.error.listen((e) => debugPrint('DesktopPlayer[$tag]: $e'));
  player.stream.log.listen((log) {
    if (log.level == 'error' || log.level == 'fatal') {
      debugPrint('DesktopPlayer[$tag] mpv ${log.prefix}: ${log.text.trim()}');
    }
  });
}
