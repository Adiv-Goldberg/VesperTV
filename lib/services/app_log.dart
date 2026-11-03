import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/playlist_profile.dart';
import 'device_defaults.dart';
import 'phone_pairing_service.dart' show kPairRelayBase, kRelayAppHeaders;

/// Settings > Device & data > Send log. Keeps the app's own `print` /
/// `debugPrint` output and uncaught errors in memory and in a file, so a
/// user can send them (with Android's logcat for this process) to the
/// relay's `/api/log`, which posts them to the owner's private Discord
/// channel (`tools/pair_relay/relay.py`). The user gets a short code to
/// quote on Reddit/Discord.
///
/// The file survives a crash or freeze: the next launch keeps it as the
/// previous session's log and sends it too. Nothing leaves the device
/// until the user presses Send, and [redact] strips addresses, account
/// names, passwords and tokens first.
class AppLog {
  AppLog._();

  static const _maxLines = 3000;
  static const _maxFileBytes = 1024 * 1024;
  static const _sendPrevBytes = 96 * 1024;
  static const _logcatLines = 2500;
  static const _logcatMaxChars = 350 * 1024;

  static final _lines = ListQueue<String>();
  static IOSink? _sink;
  static int _fileBytes = 0;
  static File? _prev;

  /// Runs [body] (the whole of `main`) with print and uncaught errors
  /// captured. `ensureInitialized` must run inside [body] (same zone as
  /// `runApp`).
  static Future<void> capture(Future<void> Function() body) async {
    final done = Completer<void>();
    runZonedGuarded(
      () async {
        await _openFile();
        final flutterError = FlutterError.onError;
        FlutterError.onError = (details) {
          add('FLUTTER ERROR: ${details.exceptionAsString()}\n'
              '${details.stack ?? ''}');
          flutterError?.call(details);
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          add('UNCAUGHT: $error\n$stack');
          return true;
        };
        await body();
        if (!done.isCompleted) done.complete();
      },
      (error, stack) {
        add('UNCAUGHT (zone): $error\n$stack');
        if (!done.isCompleted) done.complete();
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          add(line);
          parent.print(zone, line);
        },
      ),
    );
    return done.future;
  }

  static Future<void> _openFile() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final current = File('${dir.path}/vespertv_log.txt');
      final prev = File('${dir.path}/vespertv_log_prev.txt');
      if (await current.exists()) {
        if (await prev.exists()) await prev.delete();
        await current.rename(prev.path);
      }
      _prev = prev;
      _sink = current.openWrite();
    } catch (_) {
      _sink = null;
    }
  }

  /// One log line (or several, newline-separated), timestamped.
  static void add(String line) {
    final now = DateTime.now();
    final stamp = '${_two(now.hour)}:${_two(now.minute)}:${_two(now.second)}'
        '.${now.millisecond.toString().padLeft(3, '0')}';
    final entry = '$stamp $line';
    _lines.addLast(entry);
    while (_lines.length > _maxLines) {
      _lines.removeFirst();
    }
    final sink = _sink;
    if (sink != null && _fileBytes < _maxFileBytes) {
      _fileBytes += entry.length + 1;
      try {
        sink.writeln(entry);
      } catch (_) {}
    }
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// Everything a send would contain, before redaction: device lines,
  /// this session, the previous session's tail, and (Android) logcat.
  static Future<String> collect() async {
    final out = StringBuffer();
    out.writeln('== Device');
    for (final line in await _deviceLines()) {
      out.writeln(line);
    }
    out.writeln();
    out.writeln('== This session (app)');
    _lines.forEach(out.writeln);
    try {
      await _sink?.flush();
    } catch (_) {}
    final prev = _prev;
    if (prev != null && await prev.exists()) {
      try {
        final bytes = await prev.readAsBytes();
        final from = max(0, bytes.length - _sendPrevBytes);
        out.writeln();
        out.writeln('== Previous session (app, last '
            '${((bytes.length - from) / 1024).round()} KB)');
        out.writeln(utf8.decode(bytes.sublist(from), allowMalformed: true));
      } catch (_) {}
    }
    if (Platform.isAndroid) {
      out.writeln();
      out.writeln('== Android logcat (this process)');
      out.writeln(await _logcat());
    }
    return out.toString();
  }

  static Future<List<String>> _deviceLines() async {
    final lines = <String>[];
    try {
      final info = await PackageInfo.fromPlatform();
      lines.add('App: VesperTV ${info.version}+${info.buildNumber}');
    } catch (_) {}
    if (Platform.isAndroid) {
      Future<String> prop(String name) async {
        try {
          final r = await Process.run('getprop', [name]);
          return '${r.stdout}'.trim();
        } catch (_) {
          return '';
        }
      }

      lines.add('Device: ${await prop('ro.product.manufacturer')} '
          '${await prop('ro.product.model')}');
      lines.add('Android: ${await prop('ro.build.version.release')} '
          '(SDK ${await prop('ro.build.version.sdk')}), '
          'build ${await prop('ro.build.display.id')}');
    } else {
      lines.add('OS: ${Platform.operatingSystem} '
          '${Platform.operatingSystemVersion}');
    }
    lines.add('CPUs: ${Platform.numberOfProcessors}');
    lines.add('Locale: ${Platform.localeName}');
    lines.add(DeviceDefaults.describe());
    return lines;
  }

  /// An app may read its own process's logcat without any permission.
  static Future<String> _logcat() async {
    try {
      // Codec2 decoders log every frame's metadata (a Xiaomi phone's HEVC
      // decoder: ~1,600 lines a second for a 4K channel with captions), which
      // left 6 s of logcat and pushed the app section past the size cap
      // (LOG-58LMP2). Silenced here.
      final r = await Process.run('logcat', [
        '-d', '-v', 'time', '-t', '$_logcatLines', '--pid', '$pid', //
        'CCodecBuffers:S', 'CCodecConfig:S', 'CCodecBufferChannel:S',
        'CCodec:S', 'InsetsSource:S', '*:V',
      ]);
      var text = '${r.stdout}';
      // The app's own lines come first and must survive the send cap.
      if (text.length > _logcatMaxChars) {
        text = text.substring(text.length - _logcatMaxChars);
      }
      return text.trim().isEmpty ? '(empty: ${r.stderr})'.trim() : text;
    } catch (e) {
      return '(logcat unavailable: $e)';
    }
  }

  /// Strips what could identify the user's providers or accounts: every
  /// URL (scheme kept), IP address, e-mail, `user=`/`password=`-style
  /// value, long token, and the playlists' own server names, user names
  /// and passwords wherever they appear.
  static String redact(String text, List<PlaylistProfile> profiles) {
    final secrets = <String>{};
    for (final p in profiles) {
      for (final s in [
        p.xtreamUsername,
        p.xtreamPassword,
        _host(p.xtreamServer),
        _host(p.m3uUrl),
        _host(p.epgUrl),
        ...p.backupServers.map(_host),
      ]) {
        if (s != null && s.trim().length >= 3) secrets.add(s.trim());
      }
    }
    // Longest first, so "user123" goes before "user".
    final sorted = secrets.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    // URLs first: a secret swapped out inside one would end the URL match
    // early and leave the rest of it behind.
    var out = text.replaceAllMapped(
        RegExp(r'\b(https?|rtmp|rtsp|udp)://[^\s"<>]+'),
        (m) => '${m[1]}://<url>');
    for (final s in sorted) {
      out = out.replaceAll(s, '<secret>');
    }
    out = out
        .replaceAll(RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'), '<email>')
        .replaceAll(RegExp(r'\b\d{1,3}(\.\d{1,3}){3}(:\d+)?\b'), '<ip>')
        .replaceAllMapped(
            RegExp(
                r'((?:user(?:name)?|pass(?:word)?|token|api_?key|key|auth\w*|secret)\s*[=:]\s*)[^\s&,;"]+',
                caseSensitive: false),
            (m) => '${m[1]}<redacted>')
        .replaceAll(RegExp(r'\b[A-Za-z0-9_\-]{32,}\b'), '<token>');
    return out;
  }

  static String? _host(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final uri = Uri.tryParse(
        url.trim().contains('://') ? url.trim() : 'http://${url.trim()}');
    final host = uri?.host ?? '';
    return host.isEmpty ? null : host;
  }

  /// A new code like `LOG-7K2QX9` (no 0/O/1/I).
  static String newCode() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final r = Random.secure();
    return 'LOG-${List.generate(6, (_) => chars[r.nextInt(chars.length)]).join()}';
  }

  /// Posts [text] (already redacted) under [code]. Throws on failure;
  /// [TooManyLogsException] when the relay's per-device limit is hit.
  static Future<void> send(String code, String text) async {
    final body = utf8.encode(text);
    // The relay takes at most 1 MB; keep the end (the newest lines).
    final trimmed = body.length > 900 * 1024
        ? body.sublist(body.length - 900 * 1024)
        : body;
    final res = await http
        .post(Uri.parse('$kPairRelayBase/api/log'),
            headers: {
              ...kRelayAppHeaders,
              'Content-Type': 'text/plain; charset=utf-8',
              'X-Log-Code': code,
            },
            body: trimmed)
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 429) throw const TooManyLogsException();
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw HttpException('HTTP ${res.statusCode}');
    }
  }
}

class TooManyLogsException implements Exception {
  const TooManyLogsException();
}
