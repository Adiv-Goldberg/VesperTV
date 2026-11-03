import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' show canLaunchUrl;
import '../l10n/l10n.dart';
import '../services/desktop_mini_player.dart';
import '../services/playback_service.dart';
import '../services/trailer_service.dart';
import '../services/archive_service.dart';
import '../models/trailer.dart';
import '../screens/youtube_playback.dart';
import '../screens/desktop_player_screen.dart';
import '../screens/player_screen.dart';
import '../models/channel.dart';
import 'detail_header.dart';

class TrailerButton extends StatefulWidget {
  const TrailerButton(
      {super.key,
      required this.request,
      required this.focusNode,
      this.scale = 1,
      this.onFocused,
      this.beforeOpen,
      this.service,
      this.available,
      this.open});
  final TrailerRequest request;
  final FocusNode focusNode;
  final double scale;
  final VoidCallback? onFocused;
  final Future<void> Function()? beforeOpen;
  final TrailerService? service;
  final Future<bool> Function(Uri)? available;
  final Future<bool> Function(Uri)? open;
  @override
  State<TrailerButton> createState() => _TrailerButtonState();
}

class _TrailerButtonState extends State<TrailerButton> {
  Uri? _url;
  int _generation = 0;
  bool _launching = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.watch<ArchiveService?>();
    _resolve();
  }

  @override
  void didUpdateWidget(TrailerButton old) {
    super.didUpdateWidget(old);
    if (old.request.cacheKey != widget.request.cacheKey) {
      _url = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final generation = ++_generation;
    try {
      final url = await (widget.service ?? TrailerService.instance).resolve(
          widget.request,
          addons: context.read<ArchiveService?>()?.enabledSources ?? const []);
      final canOpen = url != null &&
          (widget.available != null
              ? await widget.available!(url)
              : (Platform.isAndroid || Platform.isWindows) ||
                  await canLaunchUrl(url));
      if (mounted && generation == _generation) {
        setState(() => _url = canOpen ? url : null);
      }
    } catch (_) {/* Hidden without an external handler. */}
  }

  Future<void> _launch() async {
    final url = _url;
    if (url == null || _launching) return;
    _launching = true;
    try {
      await widget.beforeOpen?.call();
      if (!mounted) return;
      if (Platform.isWindows) {
        await DesktopMiniPlayer.instance.controller?.player.pause();
      } else {
        await context.read<PlaybackService>().controller?.pause();
      }
      bool opened;
      if (widget.open != null) {
        opened = await widget.open!(url);
      } else if (TrailerLinks.videoId(url.toString()) case final video?) {
        if (!mounted) return;
        await playYouTubeVideo(context, video, widget.request.title);
        opened = true;
      } else if (Platform.isWindows) {
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DesktopPlayerScreen(
                  channel: Channel.trailer(
                      title: widget.request.title, url: url.toString()),
                )));
        opened = true;
      } else {
        if (!mounted) return;
        final playback = context.read<PlaybackService>();
        playback.setUpNextQueue(null);
        final channel =
            Channel.trailer(title: widget.request.title, url: url.toString());
        await playback.play(channel);
        if (!mounted) return;
        await Navigator.of(context).push(
            PlayerPageRoute(builder: (_) => PlayerScreen(channel: channel)));
        opened = true;
      }
      if (!opened) throw StateError('No handler');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(tr('Unable to open trailer'))));
        widget.focusNode.requestFocus();
      }
    } finally {
      _launching = false;
      if (mounted) widget.focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) => _url == null
      ? const SizedBox.shrink()
      : DetailPillButton(
          focusNode: widget.focusNode,
          icon: Icons.movie_outlined,
          label: tr('Trailer'),
          scale: widget.scale,
          onFocused: widget.onFocused,
          onPressed: _launch,
        );
}
