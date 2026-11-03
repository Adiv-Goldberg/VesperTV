import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_player_hdr/video_player_hdr.dart';

import '../models/channel.dart';
import 'subtitle_tracks.dart';

/// Explicit content type for the shared Android movie/episode player.
/// Never infer VOD from the container, URL, track format or reported duration.
class VodBuffering {
  static const _stats = MethodChannel('vespertv/stats');

  static bool appliesTo(Channel channel) =>
      !channel.isLive && !channel.transientPlayback;

  /// Settings > Playback > Live buffer, in ms (0 = off). Set from
  /// [StorageService.getLiveBufferMs] at startup and on change.
  static int liveBufferMs = 0;

  /// Sends [ms] to the native player as the live buffer every new player
  /// starts with (startup and on change).
  static Future<void> setLiveBufferDefault(int ms) async {
    liveBufferMs = ms;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _stats.invokeMethod<void>('setLiveBufferDefault', {'ms': ms});
    } on MissingPluginException {
      // Older platform implementations keep the 500 ms start.
    } on PlatformException catch (e) {
      debugPrint('LiveBuffer: configuration failed (${e.code})');
    }
  }

  static Future<void> configure(
      VideoPlayerHdrController controller, Channel channel) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final playerId = SubtitleTracks.playerIdOf(controller);
      await _stats.invokeMethod<void>('setOnDemandBuffering', {
        'playerId': playerId,
        'on': appliesTo(channel),
      });
      // Live only: catch-up and other finite streams keep the normal start.
      final live = channel.isLive && !channel.transientPlayback;
      await _stats.invokeMethod<void>('setLiveBuffer', {
        'playerId': playerId,
        'ms': live ? liveBufferMs : 0,
      });
    } on MissingPluginException {
      // Older platform implementations retain their existing buffering policy.
    } on PlatformException catch (e) {
      debugPrint('VodBuffer: configuration failed (${e.code})');
    }
  }
}
