import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/channel.dart';
import '../utils/channel_name_matching.dart';
import 'phone_pairing_service.dart' show privateLanIpv4;
import 'playback_service.dart';
import 'playlist_edits.dart';
import 'playlist_manager.dart';
import 'playlist_session.dart';
import 'storage_service.dart';
import 'stream_probe.dart';

/// The playlist editor's local web server (Settings > Playlist editor):
/// a phone (QR) or a PC (typed address + 6-digit code) on the same network
/// edits the TV's playlists. Everything stays on the device; nothing goes
/// through the relay. Only open while the editor screen is on screen.
class PlaylistEditorServer extends ChangeNotifier {
  PlaylistEditorServer(this._playlists, this._playback, this._storage);

  final PlaylistManager _playlists;
  final PlaybackService _playback;
  final StorageService _storage;

  HttpServer? _server;
  String? _address;
  String code = '';
  int _badCodes = 0;
  String? _html;

  /// `http://10.0.0.46:8790` (null until started / without a LAN address).
  String? get address => _address;

  /// QR target: the address with the code, so a phone signs in at once.
  String? get qrUrl => _address == null ? null : '$_address/#$code';

  /// Set when the last change came from the phone/PC (the TV shows it).
  String? lastChange;

  // Stream test state.
  bool probing = false;
  int probeDone = 0;
  int probeTotal = 0;
  String? probeCurrent;
  String? probeStopReason;
  bool _stopProbe = false;
  String? _probePlaylist;

  /// Streams per test run: 22 in a row from one IP preceded a provider
  /// block (Trex 403, 2026-11-02), cause unconfirmed.
  static const maxProbe = 60;

  Future<void> start() async {
    _html ??= await rootBundle.loadString('assets/editor/editor.html');
    code = _newCode();
    final ip = await privateLanIpv4();
    HttpServer? server;
    // A fixed port is easy to type on a PC; fall back to any free one.
    for (var port = 8790; port < 8800 && server == null; port++) {
      try {
        server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      } catch (_) {}
    }
    server ??= await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server = server;
    _address = 'http://${ip?.address ?? '127.0.0.1'}:${server.port}';
    server.listen(_handle, onError: (Object e) {
      debugPrint('PlaylistEditor: server error $e');
    });
    notifyListeners();
  }

  Future<void> stop() async {
    _stopProbe = true;
    final s = _server;
    _server = null;
    await s?.close(force: true);
  }

  static String _newCode() {
    final r = Random.secure();
    return List.generate(6, (_) => r.nextInt(10)).join();
  }

  // ------------------------------------------------------------- HTTP

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    res.headers
      ..set('Cache-Control', 'no-store')
      ..set('Referrer-Policy', 'no-referrer')
      ..set('X-Content-Type-Options', 'nosniff')
      ..set('X-Frame-Options', 'DENY');
    try {
      final path = req.uri.path;
      if (path == '/' && req.method == 'GET') {
        res.headers.contentType = ContentType.html;
        res.write(_html ?? '');
        return;
      }
      if (!path.startsWith('/api/')) {
        res.statusCode = HttpStatus.notFound;
        return;
      }
      if (req.headers.value('x-editor-code') != code) {
        // Ten wrong codes: a new code, shown on the TV only.
        if (++_badCodes >= 10) {
          _badCodes = 0;
          code = _newCode();
          notifyListeners();
        }
        res.statusCode = HttpStatus.unauthorized;
        return;
      }
      final body = req.method == 'POST' ? await _readBody(req) : null;
      final out = await _route(req.method, path, req.uri.queryParameters, body);
      if (out == null) {
        res.statusCode = HttpStatus.notFound;
        return;
      }
      res.headers.contentType = ContentType.json;
      res.write(jsonEncode(out));
    } catch (e) {
      debugPrint('PlaylistEditor: request failed: $e');
      res.statusCode = HttpStatus.badRequest;
    } finally {
      await res.close();
    }
  }

  static Future<Object?> _readBody(HttpRequest req) async {
    final bytes = <int>[];
    await for (final chunk in req.timeout(const Duration(seconds: 20))) {
      bytes.addAll(chunk);
      if (bytes.length > 4 * 1024 * 1024) throw StateError('too large');
    }
    return jsonDecode(utf8.decode(bytes, allowMalformed: true));
  }

  Future<Object?> _route(
      String method, String path, Map<String, String> q, Object? body) async {
    switch ((method, path)) {
      case ('GET', '/api/playlists'):
        return {
          'copyFallback': _storage.getCopyFallback(),
          'crossFallback': _storage.getCrossPlaylistFallback(),
          'merge': _storage.getMergePlaylists(),
          'probeMax': maxProbe,
          'playlists': [
            for (final p in _playlists.profiles)
              if (_playlists.editorSession(p.id) case final s?)
                {
                  'id': p.id,
                  'name': p.name,
                  'enabled': p.enabled,
                  'count': s.allLiveChannels.length,
                }
          ],
        };
      case ('GET', '/api/channels'):
        final s = _session(q['pl']);
        return s == null ? null : _channelsJson(s);
      case ('POST', '/api/preview'):
        final s = _session(q['pl']);
        if (s == null || body is! Map) return null;
        final draft = PlaylistEdits.fromJson(body['edits']);
        draft.probes.addAll(s.edits.probes);
        final hidden = draft.apply(s.allLiveChannels);
        final names = {
          for (final c in s.allLiveChannels)
            if (c.nameOverride != null) c.rawId: c.nameOverride
        };
        s.applyEdits(); // back to the saved layer
        return {'hidden': hidden.toList(), 'names': names};
      case ('POST', '/api/edits'):
        final s = _session(q['pl']);
        if (s == null || body is! Map) return null;
        final next = PlaylistEdits.fromJson(body['edits']);
        // The page never edits test results; keep the TV's.
        next.probes
          ..clear()
          ..addAll(s.edits.probes);
        await s.saveEdits(next);
        lastChange = s.profile.name;
        notifyListeners();
        return {'hidden': s.editHidden.length};
      case ('POST', '/api/settings'):
        if (body is! Map) return null;
        if (body['copyFallback'] is bool) {
          await _storage.setCopyFallback(body['copyFallback'] as bool);
        }
        if (body['crossFallback'] is bool) {
          await _storage
              .setCrossPlaylistFallback(body['crossFallback'] as bool);
        }
        if (body['merge'] is bool) {
          await _storage.setMergePlaylists(body['merge'] as bool);
          _playlists.recomputeMerge();
          _playlists.notifyListeners();
        }
        return {'ok': true};
      case ('GET', '/api/groups'):
        final s = _session(q['pl']);
        if (s == null) return null;
        // Xtream live lists load on first need.
        await s.ensureLiveChannelsLoaded();
        final counts = <String, int>{
          for (final t in s.sourceTvGroupTitles) t: 0,
        };
        for (final c in s.allLiveChannels) {
          counts[c.group] = (counts[c.group] ?? 0) + 1;
        }
        final shown = s.tvGroups.map((g) => g.title).toList();
        return {
          'restricted': s.isRestrictedViewer(),
          // Provider groups, each with the title it shows under.
          'groups': [
            for (final title in counts.keys)
              {
                't': title,
                'd': s.edits.groupTitle(title),
                'n': counts[title],
              }
          ],
          // Shown groups in their order, with hidden flags.
          'order': [
            for (final g in s.tvGroups)
              {'d': g.title, if (s.hiddenGroups.contains(g.title)) 'h': 1}
          ],
          'shown': shown,
        };
      case ('POST', '/api/groups'):
        final s = _session(q['pl']);
        if (s == null || body is! Map) return null;
        final names = <String, String>{};
        if (body['names'] is Map) {
          for (final e in (body['names'] as Map).entries) {
            final v = e.value;
            if (e.key is String && v is String && v.trim().isNotEmpty &&
                v.trim() != e.key) {
              names[e.key as String] =
                  v.trim().length > 120 ? v.trim().substring(0, 120) : v.trim();
            }
          }
        }
        s.edits.groupNames
          ..clear()
          ..addAll(names);
        await s.saveEdits(s.edits);
        await s.setTvGroupLayout(
          order: body['order'] is List
              ? [for (final x in body['order'] as List) if (x is String) x]
              : null,
          hidden: body['hidden'] is List
              ? {for (final x in body['hidden'] as List) if (x is String) x}
              : null,
        );
        lastChange = s.profile.name;
        notifyListeners();
        return {'ok': true};
      case ('GET', '/api/gate'):
        final s = _session(q['pl']);
        if (s == null) return null;
        final api = s.xtreamApi;
        ({int? max, int? active}) gate = (max: null, active: null);
        if (api != null) {
          try {
            gate = await api.connectionStatus();
          } catch (_) {}
        }
        return {
          'max': gate.max,
          'active': gate.active,
          'playing': _playback.currentChannel != null,
          'xtream': api != null,
        };
      case ('POST', '/api/probe'):
        final s = _session(q['pl']);
        if (s == null || body is! Map || body['accept'] != true) return null;
        final ids = {
          if (body['ids'] is List)
            for (final x in body['ids'] as List)
              if (x is String) x
        };
        final error = await _startProbe(s, ids);
        return {'started': error == null, 'error': error};
      case ('POST', '/api/probe/stop'):
        _stopProbe = true;
        return {'ok': true};
      case ('GET', '/api/probe'):
        return {
          'running': probing,
          'done': probeDone,
          'total': probeTotal,
          'current': probeCurrent,
          'stopped': probeStopReason,
          'pl': _probePlaylist,
        };
    }
    return null;
  }

  PlaylistSession? _session(String? id) =>
      id == null ? null : _playlists.editorSession(id);

  Map<String, Object?> _channelsJson(PlaylistSession s) {
    final e = s.edits;
    return {
      'edits': e.toJson(),
      'channels': [
        for (final c in s.allLiveChannels)
          {
            'r': c.rawId,
            'n': c.sourceName,
            if (c.nameOverride != null) 'd': c.nameOverride,
            'g': c.group,
            if (c.sourceLogoUrl != null) 'l': c.sourceLogoUrl,
            if (s.hiddenChannels.contains(c.rawId)) 'th': 1,
            if (s.editHidden.contains(c.rawId)) 'eh': 1,
            if (s.hiddenGroups.contains(s.liveGroupOf(c))) 'gh': 1,
            'k': channelCopyKey(c.sourceName),
            'q': e.copyRank(c),
            if (e.probes[c.rawId] case final p?) 'p': p.label,
            if (!s.isLiveHidden(c.rawId) && _epgMissing(c)) 'ne': 1,
          }
      ],
    };
  }

  /// Hook for "no guide data" (set by the TV screen from EpgService).
  bool Function(Channel)? hasNoGuide;
  bool _epgMissing(Channel c) => hasNoGuide?.call(c) ?? false;

  // ------------------------------------------------------------- test

  Future<String?> _startProbe(PlaylistSession s, Set<String> ids) async {
    if (probing) return 'A test is already running.';
    if (_playback.currentChannel != null) {
      return 'Stop the video on the TV first: the test needs the connection.';
    }
    final api = s.xtreamApi;
    if (api != null) {
      try {
        final gate = await api.connectionStatus();
        final max = gate.max ?? 0;
        final active = gate.active ?? 0;
        if (max > 0 && active >= max) {
          return 'All $max connection(s) of this account are in use right now. '
              'Try again when nobody is watching.';
        }
      } catch (_) {}
    }
    final targets = [
      for (final c in s.allLiveChannels)
        if (ids.contains(c.rawId) && c.url.isNotEmpty) c
    ];
    if (targets.isEmpty) return 'No channels selected.';
    if (targets.length > maxProbe) {
      return 'At most $maxProbe streams per test (you picked '
          '${targets.length}): many connections in a row can get an account '
          'blocked. Pick fewer, wait a few minutes between tests.';
    }
    _probePlaylist = s.profile.id;
    unawaited(_runProbe(s, targets));
    return null;
  }

  Future<void> _runProbe(PlaylistSession s, List<Channel> targets) async {
    probing = true;
    _stopProbe = false;
    probeDone = 0;
    probeTotal = targets.length;
    probeStopReason = null;
    notifyListeners();
    final probe = StreamProbe();
    var failuresInARow = 0;
    try {
      for (final c in targets) {
        if (_stopProbe) {
          probeStopReason = 'Stopped.';
          break;
        }
        if (_playback.currentChannel != null) {
          probeStopReason = 'Stopped: a video started on the TV.';
          break;
        }
        probeCurrent = c.sourceName;
        notifyListeners();
        final r = await probe.probe(c);
        s.edits.probes[c.rawId] = r;
        probeDone++;
        if (StreamProbe.isRefusal(r)) {
          probeStopReason =
              'Stopped: the provider refused the connection (${r.error}). '
              'Wait before testing again.';
          break;
        }
        failuresInARow = r.ok ? 0 : failuresInARow + 1;
        if (failuresInARow >= 5) {
          probeStopReason = 'Stopped: 5 streams in a row failed.';
          break;
        }
        if (probeDone % 10 == 0) await s.saveEdits(s.edits);
        // Let the provider see the connection close before the next one.
        await Future<void>.delayed(const Duration(milliseconds: 2500));
      }
    } finally {
      probe.close();
      await s.saveEdits(s.edits);
      probing = false;
      probeCurrent = null;
      probeStopReason ??= 'Done.';
      notifyListeners();
    }
  }
}
