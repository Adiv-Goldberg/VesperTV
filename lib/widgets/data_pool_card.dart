import '../utils/refined_finish.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:video_player_hdr/video_player_hdr.dart';

import '../l10n/l10n.dart';
import '../models/media_file_info.dart';
import '../utils/video_hdr_report.dart';
import '../services/subtitle_tracks.dart';

/// "Data pool" (Settings > General > Data pool display, off by default): a
/// bottom panel with two tables beside each other, containing the
/// nerdy details the player reports about the stream — resolution, frame
/// rate, codecs, bitrate, quality variants, audio tracks, buffer, HDR
/// (owner, 2026-10-20). Read from the playing stream only, never by probing
/// other channels — same rule as the Real 4K tag (a bulk checker would trip
/// providers' connection limits). Polls every 2 s while shown; anything the
/// stream doesn't report says so instead of guessing (live MPEG-TS usually
/// declares no bitrate or frame rate, owner's photo 2026-10-20), so those are
/// also **measured**: the vendored plugin's `StatsBridge` (Android) reports
/// downloaded bytes and the decoder's rendered/dropped frames, and the card
/// averages them since it opened. The server address is left out on
/// purpose: users post photos of the screen.
class DataPoolCard extends StatefulWidget {
  const DataPoolCard(
      {super.key,
      required this.controller,
      this.since,
      this.showFileSize = false,
      this.fileSizeBytes});

  /// Only on-demand movies/episodes, never live TV, catch-up or trailers.
  final bool showFileSize;
  final int? fileSizeBytes;

  final VideoPlayerHdrController controller;

  /// When the channel was tuned ([PlaybackService.playingSince]) — the
  /// player's position stays put on live streams, so "Playing for" counts
  /// from this.
  final DateTime? since;

  /// Same short names as the card, for the player's audio track picker.
  static String? codecName(String? raw) => _DataPoolCardState._codec(raw);
  static String? channelsName(int? n) => _DataPoolCardState._channels(n);

  @override
  State<DataPoolCard> createState() => _DataPoolCardState();
}

class _DataPoolCardState extends State<DataPoolCard> {
  List<VideoTrack> _videoTracks = const [];
  List<VideoAudioTrack> _audioTracks = const [];
  Duration? _buffered;
  bool _read = false;
  Timer? _timer;

  /// First and latest StatsBridge samples; the measured rows average
  /// between them (steadier than one 2 s window — HLS loads in bursts).
  Map<Object?, Object?>? _first;
  Map<Object?, Object?>? _last;

  static const _stats = MethodChannel('vespertv/stats');

  /// The device's HDR answer, asked once per app run.
  static Future<String?>? _hdr;

  @override
  void initState() {
    super.initState();
    _hdr ??= _deviceHdr(widget.controller);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void didUpdateWidget(DataPoolCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _videoTracks = const [];
      _audioTracks = const [];
      _buffered = null;
      _read = false;
      _first = null;
      _last = null;
      _refresh();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static Future<String?> _deviceHdr(VideoPlayerHdrController c) async {
    try {
      if (!await c.isHdrSupported()) return tr('No');
      final formats = await c.getSupportedHdrFormats();
      return formats.isEmpty ? tr('Yes') : formats.join(', ');
    } catch (_) {
      return null;
    }
  }

  Future<void> _refresh() async {
    final c = widget.controller;
    var videoTracks = const <VideoTrack>[];
    var audioTracks = const <VideoAudioTrack>[];
    try {
      if (c.isVideoTrackSupportAvailable()) {
        videoTracks = await c.getVideoTracks();
      }
      if (c.isAudioTrackSupportAvailable()) {
        audioTracks = await c.getAudioTracks();
      }
    } catch (_) {
      // Not every stream reports tracks: the rows say "not reported".
    }
    Map<Object?, Object?>? sample;
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        sample = await _stats.invokeMapMethod<Object?, Object?>(
            'getStats', {'playerId': SubtitleTracks.playerIdOf(c)});
      } catch (_) {
        // Player gone (channel changed) or an old plugin: rows fall back.
      }
    }
    final value = c.value;
    Duration? buffered;
    // The player's own reserve ahead of the playhead. The ranges below read
    // ~400 s on live .ts, where the Dart position doesn't follow (+582).
    final nativeMs = (sample?['bufferedMs'] as num?)?.toInt();
    if (nativeMs != null) {
      buffered = Duration(milliseconds: nativeMs);
    } else {
      for (final r in value.buffered) {
        if (r.start <= value.position && value.position <= r.end) {
          buffered = r.end - value.position;
        }
      }
    }
    if (!mounted || widget.controller != c) return;
    setState(() {
      _videoTracks = videoTracks;
      _audioTracks = audioTracks;
      _buffered = buffered;
      _read = true;
      if (sample != null) {
        _first ??= sample;
        _last = sample;
      }
    });
  }

  static String? _rate(int? bitsPerSecond) {
    if (bitsPerSecond == null || bitsPerSecond <= 0) return null;
    if (bitsPerSecond >= 1000000) {
      return '${(bitsPerSecond / 1000000).toStringAsFixed(1)} Mbps';
    }
    return '${(bitsPerSecond / 1000).round()} kbps';
  }

  /// "avc1.640028" -> "H.264"; unknown codecs pass through upper-cased.
  static String? _codec(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final c = raw.toLowerCase();
    if (c.startsWith('avc') || c.contains('h264')) return 'H.264';
    if (c.startsWith('hev') || c.startsWith('hvc') || c.contains('h265')) {
      return 'H.265';
    }
    if (c.startsWith('mp4a') || c.contains('aac')) return 'AAC';
    if (c.startsWith('ac-3') || c == 'ac3') return 'AC-3';
    if (c.startsWith('ec-3') || c == 'eac3') return 'E-AC-3';
    if (c.contains('mpeg') && c.contains('audio')) return 'MP2/MP3';
    if (c.contains('mpeg2') || c == 'mp2v') return 'MPEG-2';
    return raw.split('.').first.toUpperCase();
  }

  static String? _channels(int? n) => switch (n) {
        null || <= 0 => null,
        1 => tr('Mono'),
        2 => tr('Stereo'),
        6 => '5.1',
        8 => '7.1',
        _ => '$n ch',
      };

  /// 1920x1080 -> "16:9"; odd sizes as a decimal ratio.
  static String _aspect(Size s) {
    final r = s.width / s.height;
    for (final (label, value) in const [
      ('16:9', 16 / 9),
      ('4:3', 4 / 3),
      ('21:9', 21 / 9),
      ('1:1', 1.0),
    ]) {
      if ((r - value).abs() < 0.02) return label;
    }
    return '${r.toStringAsFixed(2)}:1';
  }

  /// HLS / DASH / MPEG-TS / MP4… from the format hint, else the URL.
  static String _container(VideoPlayerHdrController c) {
    switch (c.formatHint) {
      case VideoFormat.hls:
        return 'HLS';
      case VideoFormat.dash:
        return 'DASH';
      case VideoFormat.ss:
        return 'Smooth Streaming';
      case VideoFormat.other:
      case null:
        break;
    }
    final path = Uri.tryParse(c.dataSource)?.path.toLowerCase() ?? '';
    if (path.endsWith('.m3u8')) return 'HLS';
    if (path.endsWith('.mpd')) return 'DASH';
    if (path.endsWith('.ts')) return 'MPEG-TS';
    if (path.endsWith('.mp4') || path.endsWith('.m4v')) return 'MP4';
    if (path.endsWith('.mkv')) return 'MKV';
    return tr('Direct stream');
  }

  /// (difference of [key] between the first and latest sample, seconds).
  (num, double)? _delta(String key) {
    final a = _first, b = _last;
    if (a == null || b == null || identical(a, b)) return null;
    final x = a[key], y = b[key];
    final t0 = a['nowMs'], t1 = b['nowMs'];
    if (x is! num || y is! num || t0 is! num || t1 is! num) return null;
    final seconds = (t1 - t0) / 1000;
    if (seconds < 1) return null;
    return (y - x, seconds);
  }

  /// Bits per second actually downloaded since the card opened.
  int? get _measuredBitrate {
    final d = _delta('bytes');
    return d == null ? null : (d.$1 * 8 / d.$2).round();
  }

  /// Frames actually rendered per second since the card opened.
  double? get _measuredFps {
    final d = _delta('rendered');
    return d == null || d.$1 <= 0 ? null : d.$1 / d.$2;
  }

  static String _clock(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final value = c.value;
    VideoTrack? v;
    for (final t in _videoTracks) {
      if (t.isSelected) v = t;
    }
    VideoAudioTrack? a;
    for (final t in _audioTracks) {
      if (t.isSelected) a = t;
    }
    final notReported = tr('Not reported by the stream');
    final sampleRate = a?.sampleRate;
    final language = a?.language;
    final videoParts = [
      if (v?.width != null && v?.height != null) '${v!.width}×${v.height}',
      if (v?.frameRate != null)
        '${v!.frameRate!.toStringAsFixed(2)} fps'
      else if (_measuredFps != null)
        '${_measuredFps!.toStringAsFixed(2)} fps ${tr('(measured)')}',
      _codec(v?.codec),
    ].whereType<String>().toList();
    final audioParts = [
      _codec(a?.codec),
      _channels(a?.channelCount),
      if (sampleRate != null && sampleRate > 0)
        '${(sampleRate / 1000).toStringAsFixed(sampleRate % 1000 == 0 ? 0 : 1)} kHz',
      _rate(a?.bitrate),
      if (language != null && language.isNotEmpty && language != 'und')
        language.toUpperCase(),
    ].whereType<String>().toList();
    // Variants an adaptive (HLS) stream offers, best first.
    final heights = {
      for (final t in _videoTracks)
        if (t.height != null && t.height! > 0) t.height!
    }.toList()
      ..sort((x, y) => y.compareTo(x));
    final languages = {
      for (final t in _audioTracks)
        if (t.language != null && t.language!.isNotEmpty && t.language != 'und')
          t.language!.toUpperCase()
    };
    final size = value.size;
    final buffered = _buffered;
    final reportedBytes = _last?['fileSizeBytes'];
    final fileSize = MediaFileInfo.formatSize(
        reportedBytes is int && reportedBytes > 0
            ? reportedBytes
            : widget.fileSizeBytes);
    final https = c.dataSource.toLowerCase().startsWith('https');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: RefinedFinish.decorate(
          context,
          BoxDecoration(
            // Same see-through card as the OK info card.
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
          focused: false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(tr('Data pool'),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 6),
          if (!_read)
            Text(tr('Reading the stream…'),
                style: const TextStyle(color: Colors.white70, fontSize: 12))
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _row(
                      tr('Video'),
                      videoParts.isEmpty
                          ? notReported
                          : videoParts.join(' · ')),
                  _row(
                      tr('Stream bitrate'),
                      _measuredBitrate != null
                          ? '${_rate(_measuredBitrate)} ${tr('(measured)')}'
                          : _first == null || identical(_first, _last)
                              ? tr('Measuring…')
                              : notReported),
                  if (_rate(v?.bitrate) != null)
                    _row(tr('Declared bitrate'), _rate(v?.bitrate)!),
                  if (_last?['dropped'] is num)
                    _row(tr('Dropped frames'), '${_last!['dropped']}'),
                  if (size.width > 0 && size.height > 0)
                    _row(tr('Picture'),
                        '${size.width.round()}×${size.height.round()} · ${_aspect(size)}'),
                  // Source or decoder evidence, not the TV's active HDMI mode.
                  if (_last?['hdr'] is String)
                    _row(tr('Video HDR'), VideoHdrReport.label(_last!)),
                  if (_last != null &&
                      VideoHdrReport.decoderDifference(_last!) != null)
                    _row(tr('Decoder HDR'),
                        VideoHdrReport.decoderDifference(_last!)!),
                  _row(
                      tr('Quality variants'),
                      heights.length > 1
                          ? heights.map((h) => '${h}p').join(' · ')
                          : tr('One (not adaptive)')),
                ])),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _row(
                      tr('Audio'),
                      audioParts.isEmpty
                          ? notReported
                          : audioParts.join(' · ')),
                  if (_audioTracks.length > 1)
                    _row(
                        tr('Audio tracks'),
                        languages.isEmpty
                            ? '${_audioTracks.length}'
                            : '${_audioTracks.length} · ${languages.join(', ')}'),
                  if (widget.showFileSize)
                    _row(tr('File size'),
                        fileSize ?? tr('File size unavailable')),
                  _row(tr('Stream'),
                      '${_container(c)} · ${https ? 'HTTPS' : 'HTTP'}'),
                  _row(
                      tr('Buffered'),
                      buffered == null
                          ? notReported
                          : [
                              tr('{seconds} s', {
                                'seconds': (buffered.inMilliseconds / 1000)
                                    .toStringAsFixed(1)
                              }),
                              // Live buffer > Gradual (VideoPlayer.cushionTick).
                              if (_last?['cushionSlow'] == true)
                                tr('building at 96 % speed'),
                            ].join(' · ')),
                  _row(
                      tr('State'),
                      value.isBuffering
                          ? tr('Buffering…')
                          : value.isPlaying
                              ? tr('Playing for {time}', {
                                  'time': _clock(widget.since == null
                                      ? value.position
                                      : DateTime.now()
                                          .difference(widget.since!))
                                })
                              : tr('Paused')),
                  FutureBuilder<String?>(
                    future: _hdr,
                    builder: (context, snap) => snap.data == null
                        ? const SizedBox.shrink()
                        : _row(tr('Device HDR'), snap.data!),
                  ),
                ])),
              ],
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
            Expanded(
              flex: 3,
              child: Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      );
}
