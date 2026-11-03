import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/channel.dart';
import 'playlist_edits.dart';

/// Opt-in playlist-editor stream test: opens ONE stream for a few seconds
/// and reads what it really is (resolution, frame rate, codec) without a
/// decoder. HLS: the master playlist's `RESOLUTION`/`FRAME-RATE` (often no
/// video bytes at all), else the first segment. MPEG-TS: the video PID's
/// SPS (H.264 / HEVC) + PES timestamps for the frame rate.
///
/// Callers run it strictly one stream at a time (see
/// `PlaylistEditorServer._runProbe`); providers often allow 1 connection.
class StreamProbe {
  StreamProbe({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _readLimit = 600 * 1024;
  static const _readTime = Duration(seconds: 6);

  /// Statuses that mean "stop the whole test, the provider is refusing us".
  static bool isRefusal(ProbeResult r) =>
      !r.ok &&
      (r.error == 'HTTP 401' ||
          r.error == 'HTTP 403' ||
          r.error == 'HTTP 429' ||
          r.error == 'HTTP 458' ||
          r.error == 'connection limit');

  Future<ProbeResult> probe(Channel channel) async {
    final now = DateTime.now();
    try {
      final first = await _read(Uri.parse(channel.url), channel.httpHeaders);
      if (first.status >= 400) {
        return ProbeResult(ok: false, at: now, error: 'HTTP ${first.status}');
      }
      final bytes = first.bytes;
      if (_startsWith(bytes, '#EXTM3U')) {
        return await _hls(
            first.uri, String.fromCharCodes(bytes), channel.httpHeaders, now);
      }
      return parseTs(bytes, now) ??
          ProbeResult(
              ok: bytes.length > 4096,
              at: now,
              error: bytes.length > 4096 ? null : 'no video');
    } on TimeoutException {
      return ProbeResult(ok: false, at: now, error: 'timeout');
    } catch (e) {
      final text = e.toString().toLowerCase();
      return ProbeResult(
          ok: false,
          at: now,
          error: text.contains('max') && text.contains('connection')
              ? 'connection limit'
              : 'no reply');
    }
  }

  void close() => _client.close();

  Future<ProbeResult> _hls(
      Uri base, String text, Map<String, String> headers, DateTime now) async {
    final lines = text.split(RegExp(r'\r?\n'));
    int? bestH, bestW;
    double? fps;
    String? codec;
    String? bestVariant;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!line.startsWith('#EXT-X-STREAM-INF')) continue;
      final res = RegExp(r'RESOLUTION=(\d+)x(\d+)').firstMatch(line);
      final h = res == null ? null : int.parse(res.group(2)!);
      if (bestVariant == null || (h != null && h > (bestH ?? 0))) {
        bestH = h;
        bestW = res == null ? null : int.parse(res.group(1)!);
        final f = RegExp(r'FRAME-RATE=([\d.]+)').firstMatch(line);
        fps = f == null ? null : double.tryParse(f.group(1)!);
        final c = RegExp(r'CODECS="([^"]+)"').firstMatch(line)?.group(1);
        codec = c == null
            ? null
            : c.contains('hvc1') || c.contains('hev1')
                ? 'HEVC'
                : c.contains('avc1')
                    ? 'H.264'
                    : null;
        for (var j = i + 1; j < lines.length; j++) {
          final v = lines[j].trim();
          if (v.isNotEmpty && !v.startsWith('#')) {
            bestVariant = v;
            break;
          }
        }
      }
    }
    if (bestH != null) {
      return ProbeResult(
          ok: true,
          at: now,
          height: bestH,
          width: bestW,
          fps: fps,
          codec: codec);
    }
    // A media playlist (or a master without RESOLUTION): read a segment.
    var media = text;
    var mediaUri = base;
    if (bestVariant != null) {
      mediaUri = base.resolve(bestVariant);
      final r = await _read(mediaUri, headers, limit: 256 * 1024);
      if (r.status >= 400) {
        return ProbeResult(ok: false, at: now, error: 'HTTP ${r.status}');
      }
      media = String.fromCharCodes(r.bytes);
      mediaUri = r.uri;
    }
    final segment = media
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .lastOrNull;
    if (segment == null) return ProbeResult(ok: false, at: now, error: 'empty');
    final seg = await _read(mediaUri.resolve(segment), headers);
    if (seg.status >= 400) {
      return ProbeResult(ok: false, at: now, error: 'HTTP ${seg.status}');
    }
    return parseTs(seg.bytes, now) ?? ProbeResult(ok: true, at: now);
  }

  Future<({int status, Uint8List bytes, Uri uri})> _read(
      Uri uri, Map<String, String> headers,
      {int limit = _readLimit}) async {
    final req = http.Request('GET', uri)
      ..headers.addAll(headers)
      ..followRedirects = true;
    final res = await _client.send(req).timeout(const Duration(seconds: 8));
    final out = BytesBuilder(copy: false);
    if (res.statusCode < 400) {
      final done = Completer<void>();
      late StreamSubscription<List<int>> sub;
      final timer = Timer(_readTime, () {
        if (!done.isCompleted) done.complete();
      });
      sub = res.stream.listen((chunk) {
        out.add(chunk);
        if (out.length >= limit && !done.isCompleted) done.complete();
      }, onDone: () {
        if (!done.isCompleted) done.complete();
      }, onError: (Object _) {
        if (!done.isCompleted) done.complete();
      }, cancelOnError: true);
      await done.future;
      timer.cancel();
      // Closes the provider connection right away.
      await sub.cancel();
    } else {
      unawaited(res.stream.listen((_) {}).cancel());
    }
    return (
      status: res.statusCode,
      bytes: out.takeBytes(),
      uri: res.request?.url ?? uri
    );
  }

  static bool _startsWith(Uint8List b, String s) {
    var i = 0;
    if (b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) i = 3;
    if (b.length < i + s.length) return false;
    for (var k = 0; k < s.length; k++) {
      if (b[i + k] != s.codeUnitAt(k)) return false;
    }
    return true;
  }

  // ------------------------------------------------------------- MPEG-TS

  /// Null when [bytes] isn't MPEG-TS.
  @visibleForTesting
  static ProbeResult? parseTs(Uint8List bytes, DateTime at) {
    var start = -1;
    for (var i = 0; i + 376 < bytes.length && i < 188; i++) {
      if (bytes[i] == 0x47 && bytes[i + 188] == 0x47) {
        start = i;
        break;
      }
    }
    if (start < 0) return null;
    int? pmtPid;
    int? videoPid;
    var videoType = 0;
    final es = BytesBuilder(copy: false);
    final pts = <int>[];
    for (var p = start; p + 188 <= bytes.length; p += 188) {
      if (bytes[p] != 0x47) continue;
      final pusi = bytes[p + 1] & 0x40 != 0;
      final pid = ((bytes[p + 1] & 0x1F) << 8) | bytes[p + 2];
      final afc = (bytes[p + 3] >> 4) & 0x3;
      var off = p + 4;
      if (afc == 2 || afc == 0) continue;
      if (afc == 3) off += 1 + bytes[p + 4];
      if (off >= p + 188) continue;
      if (pid == 0 && pusi && pmtPid == null) {
        final t = off + 1 + bytes[off];
        // First program in the PAT.
        for (var k = t + 8; k + 4 <= t + 3 + _secLen(bytes, t) - 4; k += 4) {
          final prog = (bytes[k] << 8) | bytes[k + 1];
          if (prog != 0) {
            pmtPid = ((bytes[k + 2] & 0x1F) << 8) | bytes[k + 3];
            break;
          }
        }
      } else if (pid == pmtPid && pusi && videoPid == null) {
        final t = off + 1 + bytes[off];
        final end = t + 3 + _secLen(bytes, t) - 4;
        final infoLen = ((bytes[t + 10] & 0x0F) << 8) | bytes[t + 11];
        for (var k = t + 12 + infoLen; k + 5 <= end && k + 5 < bytes.length;) {
          final type = bytes[k];
          final epid = ((bytes[k + 1] & 0x1F) << 8) | bytes[k + 2];
          final esLen = ((bytes[k + 3] & 0x0F) << 8) | bytes[k + 4];
          if (type == 0x1B || type == 0x24) {
            videoPid = epid;
            videoType = type;
            break;
          }
          k += 5 + esLen;
        }
      } else if (videoPid != null && pid == videoPid) {
        if (pusi &&
            off + 9 < p + 188 &&
            bytes[off] == 0 &&
            bytes[off + 1] == 0 &&
            bytes[off + 2] == 1) {
          final flags = bytes[off + 7];
          if (flags & 0x80 != 0 && off + 14 <= p + 188) {
            final b = off + 9;
            pts.add(((bytes[b] >> 1) & 0x07) << 30 |
                bytes[b + 1] << 22 |
                (bytes[b + 2] >> 1) << 15 |
                bytes[b + 3] << 7 |
                bytes[b + 4] >> 1);
          }
          off += 9 + bytes[off + 8];
        }
        if (off < p + 188 && es.length < 400 * 1024) {
          es.add(Uint8List.sublistView(bytes, off, p + 188));
        }
      }
    }
    if (videoPid == null) {
      return ProbeResult(ok: true, at: at, codec: null);
    }
    final hevc = videoType == 0x24;
    final dims = _findSps(es.takeBytes(), hevc);
    return ProbeResult(
      ok: true,
      at: at,
      width: dims?.$1,
      height: dims?.$2,
      fps: _fpsFromPts(pts),
      codec: hevc ? 'HEVC' : 'H.264',
    );
  }

  static int _secLen(Uint8List b, int t) =>
      t + 2 < b.length ? ((b[t + 1] & 0x0F) << 8) | b[t + 2] : 0;

  static double? _fpsFromPts(List<int> pts) {
    if (pts.length < 4) return null;
    final sorted = [...pts]..sort();
    final gaps = <int>[
      for (var i = 1; i < sorted.length; i++)
        if (sorted[i] - sorted[i - 1] > 0) sorted[i] - sorted[i - 1]
    ]..sort();
    if (gaps.isEmpty) return null;
    final gap = gaps[gaps.length ~/ 2];
    final fps = 90000 / gap;
    if (fps < 10 || fps > 130) return null;
    // A field-coded 25i stream reports 50 PES per second, as viewers count it.
    return (fps * 100).roundToDouble() / 100;
  }

  static (int, int)? _findSps(Uint8List es, bool hevc) {
    for (var i = 0; i + 4 < es.length; i++) {
      if (es[i] != 0 || es[i + 1] != 0 || es[i + 2] != 1) continue;
      final h = es[i + 3];
      final type = hevc ? (h >> 1) & 0x3F : h & 0x1F;
      if (type != (hevc ? 33 : 7)) continue;
      var end = i + 3;
      while (end + 2 < es.length &&
          !(es[end] == 0 && es[end + 1] == 0 && es[end + 2] == 1)) {
        end++;
      }
      final rbsp =
          _unescape(Uint8List.sublistView(es, i + (hevc ? 5 : 4), end));
      try {
        return hevc ? _hevcSps(rbsp) : _avcSps(rbsp);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Uint8List _unescape(Uint8List b) {
    final out = BytesBuilder(copy: false);
    var zeros = 0;
    for (final x in b) {
      if (zeros >= 2 && x == 3) {
        zeros = 0;
        continue;
      }
      out.addByte(x);
      zeros = x == 0 ? zeros + 1 : 0;
    }
    return out.takeBytes();
  }

  static (int, int) _avcSps(Uint8List b) {
    final r = _Bits(b);
    final profile = r.u(8);
    r.u(16); // constraint flags + level
    r.ue();
    if (const {100, 110, 122, 244, 44, 83, 86, 118, 128, 138, 139, 134, 135}
        .contains(profile)) {
      final chroma = r.ue();
      if (chroma == 3) r.u(1);
      r.ue();
      r.ue();
      r.u(1);
      if (r.u(1) == 1) {
        for (var i = 0; i < (chroma != 3 ? 8 : 12); i++) {
          if (r.u(1) == 1) {
            var last = 8, next = 8;
            for (var j = 0; j < (i < 6 ? 16 : 64); j++) {
              if (next != 0) next = (last + r.se() + 256) % 256;
              last = next == 0 ? last : next;
            }
          }
        }
      }
    }
    r.ue();
    final poc = r.ue();
    if (poc == 0) {
      r.ue();
    } else if (poc == 1) {
      r.u(1);
      r.se();
      r.se();
      final n = r.ue();
      for (var i = 0; i < n; i++) {
        r.se();
      }
    }
    r.ue();
    r.u(1);
    final wMbs = r.ue() + 1;
    final hMaps = r.ue() + 1;
    final frameMbsOnly = r.u(1);
    if (frameMbsOnly == 0) r.u(1);
    r.u(1);
    var cl = 0, cr = 0, ct = 0, cb = 0;
    if (r.u(1) == 1) {
      cl = r.ue();
      cr = r.ue();
      ct = r.ue();
      cb = r.ue();
    }
    final w = wMbs * 16 - (cl + cr) * 2;
    final h =
        (2 - frameMbsOnly) * hMaps * 16 - (ct + cb) * 2 * (2 - frameMbsOnly);
    return (w, h);
  }

  static (int, int) _hevcSps(Uint8List b) {
    final r = _Bits(b);
    r.u(4);
    final subLayers = r.u(3);
    r.u(1);
    // profile_tier_level: general part = 88 bits + level 8.
    r.skip(88);
    r.u(8);
    final profilePresent = <bool>[];
    final levelPresent = <bool>[];
    for (var i = 0; i < subLayers; i++) {
      profilePresent.add(r.u(1) == 1);
      levelPresent.add(r.u(1) == 1);
    }
    if (subLayers > 0) {
      for (var i = subLayers; i < 8; i++) {
        r.u(2);
      }
    }
    for (var i = 0; i < subLayers; i++) {
      if (profilePresent[i]) r.skip(88);
      if (levelPresent[i]) r.u(8);
    }
    r.ue();
    final chroma = r.ue();
    if (chroma == 3) r.u(1);
    var w = r.ue();
    var h = r.ue();
    if (r.u(1) == 1) {
      final sub = chroma == 1 || chroma == 2 ? 2 : 1;
      final subH = chroma == 1 ? 2 : 1;
      final l = r.ue(), rr = r.ue(), t = r.ue(), bb = r.ue();
      w -= (l + rr) * sub;
      h -= (t + bb) * subH;
    }
    return (w, h);
  }
}

class _Bits {
  _Bits(this.b);
  final Uint8List b;
  int pos = 0;

  int u(int n) {
    var v = 0;
    for (var i = 0; i < n; i++) {
      if (pos >> 3 >= b.length) throw const FormatException('end');
      v = (v << 1) | ((b[pos >> 3] >> (7 - (pos & 7))) & 1);
      pos++;
    }
    return v;
  }

  void skip(int n) => pos += n;

  int ue() {
    var zeros = 0;
    while (u(1) == 0) {
      if (++zeros > 31) throw const FormatException('ue');
    }
    return (1 << zeros) - 1 + (zeros == 0 ? 0 : u(zeros));
  }

  int se() {
    final k = ue();
    return k.isOdd ? (k + 1) ~/ 2 : -(k ~/ 2);
  }
}

/// Safety checks before a stream test starts, shown in the warning.
typedef ProbeGate = ({int? maxConnections, int? activeConnections});

/// Where the probe can't run (a Windows desktop works too: plain HTTP).
bool get streamProbeSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isWindows);
