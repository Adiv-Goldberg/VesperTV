import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_player_hdr/video_player_hdr.dart';

import 'subtitle_tracks.dart';

/// Puts the main player's silent live reconnects in Send log.
///
/// The vendored `LiveReconnectDataSource` reopens a live stream the provider
/// closed without the player noticing (no blip, buffer kept). It happens on a
/// loader thread and never reaches the app log, so this polls the player's
/// stats every 10 s while a live channel plays and prints each new one.
class LiveReconnectLog {
  LiveReconnectLog(this._current);

  static const _stats = MethodChannel('vespertv/stats');

  /// The playing controller when it is a live channel, else null.
  final VideoPlayerHdrController? Function() _current;
  Timer? _timer;
  int? _playerId;
  int _seen = 0;
  String? _lastNote;

  void start() {
    // The real OS, not defaultTargetPlatform: widget tests run as Android.
    if (kIsWeb || !Platform.isAndroid) return;
    _timer ??= Timer.periodic(const Duration(seconds: 10), (_) => _poll());
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    final c = _current();
    if (c == null || !c.value.isInitialized) return;
    final id = SubtitleTracks.playerIdOf(c);
    try {
      final m = await _stats
          .invokeMapMethod<Object?, Object?>('getStats', {'playerId': id});
      final count = (m?['reconnects'] as num?)?.toInt();
      if (count == null) return;
      if (id != _playerId || count < _seen) {
        _playerId = id;
        _seen = 0;
      }
      // A failed attempt doesn't count, but changes the note.
      final note = m?['lastReconnect'] as String?;
      if (count > _seen || (note != null && note != _lastNote)) {
        debugPrint('LiveReconnect: $count on this stream, last $note');
        _seen = count;
        _lastNote = note;
      }
    } on MissingPluginException {
      dispose();
    } on PlatformException {
      // Player gone between the check and the call.
    }
  }
}
