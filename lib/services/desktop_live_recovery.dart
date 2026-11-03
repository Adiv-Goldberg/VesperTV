import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import '../l10n/l10n.dart';
import '../models/channel.dart';
import 'channel_copy_fallback.dart';
import 'desktop_stream_setup.dart';

/// Windows live TV recovery, one per mpv [Player] ([of]), so it follows the
/// stream when full screen hands it to the mini player and back.
///
/// Before (1.0.45): a live stream the provider closed was reopened at once,
/// with no wait, no retry and no logging. A provider still closing the old
/// connection refused the new one, and the picture stayed black (LOG-FZXE2W,
/// 2026-11-03: two "completed" reopens, no video after). A stream handed to
/// the mini player had no recovery at all. Android has had waits, retries and
/// copy failover since 1.0.47 / 1.0.54.
///
/// Now: ended / error / stuck buffering -> "Reconnecting..." -> wait
/// (2, 4, 8, 15, 30 s) -> reopen; from the third try the channel's other
/// copies (4K -> FHD -> HD, Settings' automatic failover) when there are any.
/// Success = playback moving again; after 8 tries the message says so and a
/// retry still runs every 30 s while the channel stays on screen.
class DesktopLiveRecovery {
  DesktopLiveRecovery._(this.player) {
    _subs = [
      player.stream.completed.listen((done) {
        if (done) _trouble('ended');
      }),
      player.stream.error.listen((_) => _trouble('error')),
      player.stream.buffering.listen(_onBuffering),
      player.stream.position.listen(_onPosition),
    ];
  }

  static final _byPlayer = Expando<DesktopLiveRecovery>();

  /// The recovery of [player] (created on first use).
  static DesktopLiveRecovery of(Player player) =>
      _byPlayer[player] ??= DesktopLiveRecovery._(player);

  /// Disposes [player] and its recovery (use instead of `player.dispose()`).
  static void disposePlayer(Player? player) {
    if (player == null) return;
    _byPlayer[player]?.dispose();
    _byPlayer[player] = null;
    player.dispose();
  }

  /// Set by main.dart on Windows: a live channel's other copies, best
  /// first, or empty when automatic failover is off.
  static List<Channel> Function(Channel channel) copiesOf = (_) => const [];

  final Player player;
  late final List<StreamSubscription<Object?>> _subs;

  /// "Reconnecting…" while a reconnect is pending or running; null = fine.
  final status = ValueNotifier<String?>(null);

  /// The channel on screen (the copy playing may differ), null = not live.
  Channel? _channel;
  Channel? _playing;
  final _fallback = ChannelCopyFallback();
  int _attempt = 0;
  Timer? _retry;
  Timer? _bufferingTimer;
  DateTime? _reopenedAt;
  bool _recovering = false;

  static const _waits = [2, 4, 8, 15, 30];
  static const _giveUpAfter = 8;

  /// Call after opening [channel] (live) on [player]; null for a movie,
  /// an episode or nothing.
  void watch(Channel? channel) {
    _retry?.cancel();
    _bufferingTimer?.cancel();
    _attempt = 0;
    _recovering = false;
    _channel = channel != null && channel.isLive && !channel.transientPlayback
        ? channel
        : null;
    _playing = _channel;
    status.value = null;
  }

  void stop() => watch(null);

  void _onBuffering(bool buffering) {
    _bufferingTimer?.cancel();
    if (!buffering || _channel == null || _recovering) return;
    // Stuck for 25 s: mpv's own reconnect gave up without saying so.
    _bufferingTimer = Timer(const Duration(seconds: 25), () {
      if (player.state.buffering) _trouble('stalled');
    });
  }

  void _onPosition(Duration position) {
    if (!_recovering || _reopenedAt == null) return;
    if (position < const Duration(seconds: 1)) return;
    // Playing again.
    final took = DateTime.now().difference(_reopenedAt!).inMilliseconds;
    debugPrint('DesktopLive: playing again after try $_attempt '
        '(${(took / 1000).toStringAsFixed(1)} s)');
    _recovering = false;
    _attempt = 0;
    _retry?.cancel();
    status.value = null;
  }

  void _trouble(String reason) {
    final channel = _channel;
    if (channel == null || (_retry?.isActive ?? false)) return;
    _attempt++;
    _recovering = true;
    final wait = _waits[(_attempt - 1).clamp(0, _waits.length - 1)];
    debugPrint('DesktopLive: $reason, reconnect $_attempt in $wait s');
    status.value = _attempt > _giveUpAfter
        ? tr('The channel stopped. Still trying to reconnect...')
        : tr('Reconnecting...');
    _retry = Timer(Duration(seconds: wait), () => _reopen(channel));
  }

  Future<void> _reopen(Channel channel) async {
    if (_channel?.id != channel.id) return;
    var target = _playing ?? channel;
    if (_attempt >= 3) {
      final copy = _fallback.next(target, copiesOf(channel));
      if (copy != null) {
        debugPrint('DesktopLive: trying another copy (${copy.name})');
        target = channel.copyWith(url: copy.url, httpHeaders: copy.httpHeaders);
        status.value = tr('Trying another copy: {name}', {'name': copy.name});
      }
    }
    _playing = target;
    _reopenedAt = null;
    try {
      await openDesktopStream(player, target);
    } catch (e) {
      debugPrint('DesktopLive: reopen failed (${e.runtimeType})');
    }
    // Positions from before this open don't count as playing again.
    _reopenedAt = DateTime.now();
    // No movement within 15 s = another try.
    _retry = Timer(const Duration(seconds: 15), () {
      if (_recovering && _channel?.id == channel.id) _trouble('no video');
    });
  }

  void dispose() {
    _retry?.cancel();
    _bufferingTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    status.dispose();
  }
}
