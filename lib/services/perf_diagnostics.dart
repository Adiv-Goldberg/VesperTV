import 'dart:async';

import 'package:flutter/foundation.dart';

/// Send-log diagnostics for very large playlists (a 300k-channel user's
/// phone and Onn box froze for 1-6 s per press, LOG-ARF5AW / LOG-A2BGZA,
/// 2026-11-03). Logs only when something is slow:
/// - `MainStall:` every 10 s while the UI thread stalled (a 200 ms timer
///   firing late), with PlaylistManager notifies and TV home rebuilds in
///   that window and how long a `SELECT 1` waited on each database;
/// - `SlowDb:` a timed catalog / guide query over 500 ms ([timed]);
/// - `CatalogSize:` once, live channels and categories per playlist and
///   the catalog rows the database holds.
class PerfDiagnostics {
  PerfDiagnostics._();

  static int notifies = 0;
  static int homeBuilds = 0;

  static Timer? _tick;
  static final Stopwatch _clock = Stopwatch();
  static int _lastTickMs = 0;
  static int _stalls = 0;
  static int _maxStallMs = 0;
  static int _stallTotalMs = 0;

  static const _tickMs = 200;
  static const _stallMs = 700;

  /// Starts the probes. [pings]: label -> a trivial query on that
  /// database (its wait = how long the database queue is).
  static void start(Map<String, Future<void> Function()> pings) {
    if (_tick != null) return;
    _clock.start();
    _lastTickMs = _clock.elapsedMilliseconds;
    _tick = Timer.periodic(const Duration(milliseconds: _tickMs), (_) {
      final now = _clock.elapsedMilliseconds;
      final late = now - _lastTickMs - _tickMs;
      _lastTickMs = now;
      if (late >= _stallMs) {
        _stalls++;
        _stallTotalMs += late;
        if (late > _maxStallMs) _maxStallMs = late;
      }
    });
    Timer.periodic(const Duration(seconds: 10), (_) async {
      final stalls = _stalls, max = _maxStallMs, total = _stallTotalMs;
      final n = notifies, builds = homeBuilds;
      _stalls = _maxStallMs = _stallTotalMs = notifies = homeBuilds = 0;
      final waits = <String>[];
      for (final e in pings.entries) {
        final sw = Stopwatch()..start();
        try {
          await e.value().timeout(const Duration(seconds: 30));
          waits.add('${e.key}=${sw.elapsedMilliseconds}ms');
        } catch (_) {
          waits.add('${e.key}=>30s');
        }
      }
      final dbSlow = waits.any((w) {
        final ms = int.tryParse(w.split('=').last.replaceAll('ms', ''));
        return ms == null || ms >= 1000;
      });
      if (stalls == 0 && !dbSlow) return;
      debugPrint('MainStall: n=$stalls max=${max}ms total=${total}ms '
          'notifies=$n homeBuilds=$builds dbWait ${waits.join(' ')}');
    });
  }

  /// Runs [body] and logs `SlowDb: label N ms` when it took over 500 ms.
  static Future<T> timed<T>(String label, Future<T> Function() body) async {
    final sw = Stopwatch()..start();
    try {
      return await body();
    } finally {
      final ms = sw.elapsedMilliseconds;
      if (ms >= 500) debugPrint('SlowDb: $label ${ms}ms');
    }
  }
}
