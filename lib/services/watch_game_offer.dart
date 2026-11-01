import 'package:flutter/foundation.dart';

import '../models/channel.dart';

/// A reminded game that just started, with the channel Sports Trak would
/// play it on (Settings > Sports Trak > Watch game button, owner 1.0.51).
class WatchGameOffer {
  WatchGameOffer(
      {required this.title, required this.channel, required this.until});

  /// "Canadiens vs Maple Leafs".
  final String title;
  final Channel channel;

  /// The pill goes away after this, switched to or not.
  final DateTime until;

  bool get expired => DateTime.now().isAfter(until);

  /// Its 10 s on its own (without the player bar) were used: once per game,
  /// not again on every return to full screen (owner, +547).
  bool announced = false;

  /// The current offer, shown as the player's Watch game pill (Up from the
  /// player bar, OK switches). Never switches by itself.
  static final current = ValueNotifier<WatchGameOffer?>(null);

  static const lifetime = Duration(minutes: 10);
}
