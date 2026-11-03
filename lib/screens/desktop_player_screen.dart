import '../utils/refined_finish.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

import '../models/channel.dart';
import '../services/archive_playback_sources.dart';
import '../widgets/archive_source_drawer.dart';
import '../utils/playback_modal_back_guard.dart';
import '../services/app_preferences.dart';
import '../services/desktop_mini_player.dart';
import '../services/desktop_vod_progress.dart';
import '../services/epg_service.dart';
import '../services/playback_service.dart';
import '../services/playlist_manager.dart';
import '../services/real_4k_channels.dart';
import '../services/storage_service.dart';
import '../services/archive_ready_watch.dart';
import '../services/watch_tracker.dart';
import '../l10n/l10n.dart';
import '../widgets/media_file_info_overlay.dart';
import '../widgets/player_side_panel.dart';
import '../widgets/desktop_subtitles.dart';
import '../widgets/player_bar_title.dart';
import '../widgets/gold_tag.dart';
import '../services/desktop_stream_setup.dart';

/// A deliberately standalone, Windows-only playback screen — see
/// `pubspec.yaml`'s media_kit comment for why this exists at all:
/// `video_player_hdr` (every other platform's player, completely
/// untouched by this file) has no Windows implementation whatsoever, and
/// `PlaybackService`/`PlayerScreen`/`PlayerControls`/`mini_player_bar.dart`
/// are all built directly around that package's own controller/value
/// shape (buffering state, captions, backup-server retry, Up Next,
/// position-save timers, the shared-controller-across-presentation-widgets
/// architecture...). Threading a platform-agnostic abstraction through all
/// of that is a real, separate project of its own — this screen
/// deliberately does NOT attempt it. It's a self-contained player: its own
/// `Player`, its own controls (favorite, reload, recall, skip ±10s,
/// previous/next episode), no shared state with `PlaybackService` at all.
/// VOD progress is saved separately through DesktopVodProgress using the same
/// storage/history as Android. Recall's [_DesktopLiveHistory] remains a local
/// live-channel list. This screen never calls PlaybackService.play().
///
/// Leaving a *live* channel via the back button doesn't stop it — same
/// "keeps playing in the background" idea as `PlaybackService` already
/// has for mobile — it hands the running `Player`/`VideoController` off to
/// [DesktopMiniPlayer] instead of disposing them (see [_handleBack]), and
/// `DesktopLiveResumeHint` (mounted globally in main.dart) shows a small
/// clickable pill until it's resumed. A movie or episode has no such
/// handoff — same as mobile, those just stop on exit.
class DesktopPlayerScreen extends StatefulWidget {
  const DesktopPlayerScreen({
    super.key,
    required this.channel,
    this.queue,
    this.sources,
    this.resolveQueued,
    this.existingPlayer,
    this.existingController,
  });

  final Channel channel;
  final ArchivePlaybackSources? sources;

  /// Every episode of the series this channel belongs to, in order — only
  /// meaningful (and only ever passed) for a TV show episode, same concept
  /// as `PlaybackService.setUpNextQueue`. Drives the Previous/Next episode
  /// buttons; null/empty for a movie or live channel, which have no such
  /// queue.
  final List<Channel>? queue;

  /// Gives a [queue] episode that has no URL yet (Archive) its stream —
  /// same role as `PlaybackService.setUpNextQueue`'s `resolve`.
  final Future<Channel?> Function(Channel)? resolveQueued;

  /// Set together, only by `DesktopLiveResumeHint` when resuming a
  /// minimized live channel — reuses the session already playing in the
  /// background instead of this screen creating (and restarting the
  /// stream with) a new `Player`. Null for every other caller, which
  /// always starts a fresh session.
  final Player? existingPlayer;
  final VideoController? existingController;

  @override
  State<DesktopPlayerScreen> createState() => _DesktopPlayerScreenState();
}

/// Recall's backing history — see [DesktopPlayerScreen]'s doc comment for
/// why this is separate from `PlaybackService.recentlyPlayed` rather than
/// reusing it. A plain static list (not persisted): good enough for "go
/// back to the live channel I was just on" within one run of the app.
class _DesktopLiveHistory {
  static final List<Channel> _recent = [];

  static void record(Channel channel) {
    _recent.removeWhere((c) => c.id == channel.id);
    _recent.insert(0, channel);
    if (_recent.length > 6) _recent.removeRange(6, _recent.length);
  }

  static List<Channel> recentExcluding(String id) =>
      _recent.where((c) => c.id != id).take(4).toList();
}

class _DesktopPlayerScreenState extends State<DesktopPlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;
  late Channel _currentChannel;
  bool _controlsVisible = true;
  final _fileInfoRequests = ValueNotifier<int>(0);

  /// [PlayerSidePanel] (Last channels / My Teams / Live now) on a live
  /// channel: the left-edge tab or the Left key opens it, Esc / a click on
  /// the video closes it — Windows has no remote Left (owner, 2026-10-18).
  bool _panelOpen = false;
  final FocusNode _rootFocus = FocusNode(debugLabel: 'desktop-player-root');

  void _openPanel() {
    if (!_isLive) return;
    setState(() {
      _panelOpen = true;
      _controlsVisible = false;
    });
  }

  void _closePanel() {
    if (!_panelOpen) return;
    setState(() => _panelOpen = false);
    _rootFocus.requestFocus();
  }

  late final _sourceBackGuard = PlaybackModalBackGuard(onChanged: () {
    if (mounted) setState(() {});
  });
  bool get _sourceDrawerOpen => _sourceBackGuard.isOpen;

  Future<void> _openSources() async {
    final sources = widget.sources;
    if (sources == null || _sourceDrawerOpen) return;
    final channelId = _currentChannel.id;
    _sourceBackGuard.opened();
    setState(() => _controlsVisible = false);
    try {
      final selection = await showArchiveSourceDrawer(context,
          sources: sources, channelId: channelId);
      if (!mounted || selection == null || _currentChannel.id != channelId) {
        return;
      }
      final position = _player.state.position;
      final playing = _player.state.playing;
      await sources.remember(channelId, selection.option);
      if (!mounted || _currentChannel.id != channelId) return;
      await _switchTo(selection.channel, start: position, play: playing);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr('Could not switch stream. Try another source.'))));
      }
    } finally {
      if (mounted) {
        _sourceBackGuard.closed();
        _rootFocus.requestFocus();
      }
    }
  }

  /// False when this screen is reusing a session handed off by
  /// [DesktopMiniPlayer] (see [initState]) — [dispose] must never tear
  /// down a `Player` it didn't create itself.
  bool _ownsPlayer = true;

  /// True once [_handleBack] has handed the live session to
  /// [DesktopMiniPlayer] — [dispose] must not also dispose it in that
  /// case, even though this screen did create it.
  bool _handedOffToMiniPlayer = false;

  /// Forces a fresh re-open whenever a *live* channel's player reports
  /// `completed` on its own. mpv's native reconnect config (see the
  /// `demuxer-lavf-o` property set in [initState]) doesn't reliably catch
  /// every way a live stream can end up here — confirmed directly: a
  /// clean `lavf: EOF reached` with no reconnect attempt logged
  /// afterward at all, despite `reconnect_at_eof=1` being set. A live
  /// channel should never just "complete," so reacting to it here is a
  /// recovery path this app fully controls, regardless of the exact
  /// low-level ffmpeg cause.
  StreamSubscription<bool>? _completedSubscription;

  /// The live list's 4K tag ([Real4kChannels]): mpv reports the decoded
  /// size whenever it changes, channel switches included.
  StreamSubscription<int?>? _heightSubscription;

  late final DesktopVodProgress _progress;
  late final PlaybackService _history;
  Timer? _progressTimer;
  bool _progressReady = false;
  int _openGeneration = 0;

  bool get _isLive => _currentChannel.isLive;
  List<Channel> get _queue => widget.queue ?? const [];
  int get _currentIndex => _queue.indexWhere((c) => c.id == _currentChannel.id);
  Channel? get _previousEpisode =>
      !_isLive && _currentIndex > 0 ? _queue[_currentIndex - 1] : null;
  Channel? get _nextEpisode =>
      !_isLive && _currentIndex >= 0 && _currentIndex < _queue.length - 1
          ? _queue[_currentIndex + 1]
          : null;

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;
    _progress = DesktopVodProgress(context.read<StorageService>());
    _history = context.read<PlaybackService>();
    if (widget.existingPlayer != null && widget.existingController != null) {
      _player = widget.existingPlayer!;
      _videoController = widget.existingController!;
      _ownsPlayer = false;
    } else {
      _player = Player();
      // Best-effort mpv/ffmpeg-level reconnect tuning for a live,
      // non-seekable TS stream — reconnect_streamed=1 is necessary for
      // mpv to even attempt recovering a genuinely dropped/reset read
      // (confirmed via log as `ffmpeg: tcp: ffurl_read returned -138` on
      // one specific provider), and rw_timeout bounds any single blocked
      // read/write (including a Range-reconnect attempt hanging forever
      // on a server that doesn't support it — the *original* bug this
      // property set replaces a plain reconnect_streamed=0 workaround
      // for) to a fixed ceiling instead of hanging indefinitely.
      //
      // This alone isn't fully reliable, though — confirmed directly: a
      // clean `lavf: EOF reached` with no reconnect attempt logged
      // afterward at all, despite reconnect_at_eof=1 being set, meaning
      // mpv doesn't catch every way a live stream can end up here. The
      // real safety net is _completedSubscription below, which reacts at
      // the app level instead of depending on mpv's own reconnect logic.
      configureDesktopStreamPlayer(_player, 'player');
      _videoController = VideoController(_player);
      // The volume / mute set last time (a handed-over mini player
      // session already has it).
      final storage = context.read<StorageService>();
      unawaited(_player.setVolume(
          storage.getDesktopMuted() ? 0 : storage.getDesktopVolume()));
      unawaited(_openMedia(_currentChannel));
      _applySeriesSubtitles();
    }
    if (_isLive) _DesktopLiveHistory.record(_currentChannel);
    // Trakt/Simkl, for Media Hub titles (a no-op otherwise).
    if (!_currentChannel.transientPlayback) {
      unawaited(WatchTracker.instance.started(_currentChannel.id));
    }
    // DesktopPlayerScreen deliberately never calls PlaybackService.play()
    // (see this class's own doc comment) — meaning nothing on Windows
    // ever recorded a "last channel" at all, since StorageService
    // .setLastChannelId is otherwise only ever called from inside
    // PlaybackService. Confirmed directly: main.dart's own Windows
    // auto-resume-last-channel (added for exactly this) silently never
    // found anything to resume into, because this was always null. Only
    // live channels are recorded, matching main.dart's own "scoped to
    // live channels only" resume logic — a movie/episode has no "resume
    // where I left off on launch" concept to begin with.
    if (_isLive) {
      context.read<StorageService>().setLastChannelId(_currentChannel.id);
      // Feeds the TV home's "History" group (live channels only, so
      // Continue Watching is unaffected).
      context.read<PlaybackService>().recordWatched(_currentChannel);
    }
    _progressTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _saveProgress());
    _heightSubscription = _player.stream.height.listen((height) {
      if (!_isLive || height == null) return;
      Real4kChannels.record(
          _currentChannel.id, _player.state.width ?? 0, height);
    });
    if (_isLive) {
      _completedSubscription = _player.stream.completed.listen((completed) {
        if (completed && mounted) {
          debugPrint(
              '[auto-recover] live channel reported completed — reopening');
          _reload();
        }
      });
    }
  }

  /// Open at the saved time without briefly playing the beginning first.
  /// Explicit start is used when switching source files within one title.
  Future<void> _openMedia(Channel channel,
      {Duration? start, bool play = true}) async {
    final generation = ++_openGeneration;
    _progressReady = false;
    bool current() =>
        mounted &&
        generation == _openGeneration &&
        _currentChannel.id == channel.id;
    try {
      final resume = start ?? _progress.resumePosition(channel);
      await _player.open(
          Media(channel.url, start: resume, httpHeaders: _headersOf(channel)),
          play: play);
      if (!current()) return;
      if (resume == null) {
        // Trakt/Simkl may only know a fraction until the stream opens.
        final duration = _player.state.duration > Duration.zero
            ? _player.state.duration
            : await _player.stream.duration
                .firstWhere((d) => d > Duration.zero)
                .timeout(const Duration(seconds: 30));
        if (!current() || !_progress.accepts(channel)) return;
        final target = _progress.resumePosition(channel, duration: duration);
        if (target != null) await _player.seek(target);
        if (!current() || !_progress.accepts(channel)) return;
        await _progress.storage.clearResumeFraction(channel.id);
      }
      if (!current() || (!channel.isLive && !_progress.accepts(channel))) {
        return;
      }
      // Restart and explicit source-switch positions supersede a tracker fraction.
      if (_progress.isFraction(channel)) {
        await _progress.storage.clearResumeFraction(channel.id);
      }
      if (!current()) return;
      _progressReady = true;
      if (_progress.accepts(channel)) {
        unawaited(_history.recordWatched(channel));
      }
    } catch (e) {
      // Transport URLs can contain credentials; log only the failure type.
      debugPrint('Desktop playback open failed: ${e.runtimeType}');
    }
  }

  void _saveProgress() {
    if (!_progressReady) return;
    unawaited(_progress.save(
        _currentChannel, _player.state.position, _player.state.duration));
  }

  /// Trakt/Simkl: report mpv's exact position independently of saved progress.
  void _reportStopped() {
    if (_currentChannel.transientPlayback) return;
    final state = _player.state;
    // A Media Hub source's "being downloaded" clip isn't the title.
    if (ArchiveReadyWatch.instance.ended(_currentChannel.id, state.duration)) {
      return;
    }
    unawaited(WatchTracker.instance
        .stopped(_currentChannel.id, state.position, state.duration));
  }

  @override
  void dispose() {
    _sourceBackGuard.dispose();
    _fileInfoRequests.dispose();
    _progressTimer?.cancel();
    ++_openGeneration;
    if (!_handedOffToMiniPlayer) {
      _saveProgress();
      _reportStopped();
    }
    _completedSubscription?.cancel();
    _heightSubscription?.cancel();
    _rootFocus.dispose();
    if (_ownsPlayer && !_handedOffToMiniPlayer) _player.dispose();
    super.dispose();
  }

  /// A live channel keeps playing in the background instead of stopping —
  /// see the class doc comment. A movie or episode just pops normally;
  /// [dispose] tears its `Player` down the same way it always has.
  void _handleBack() {
    if (_sourceBackGuard.blocksBack) return;
    if (_isLive) {
      DesktopMiniPlayer.instance
          .minimize(_currentChannel, _player, _videoController);
      _handedOffToMiniPlayer = true;
    }
    Navigator.of(context).pop();
  }

  Future<void> _switchTo(Channel channel,
      {Duration? start, bool play = true}) async {
    if (channel.url.isEmpty) {
      final resolve = widget.resolveQueued;
      Channel? resolved;
      try {
        resolved = resolve == null ? null : await resolve(channel);
      } catch (_) {
        resolved = null;
      }
      if (!mounted) return;
      if (resolved == null || resolved.url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('No playable stream for this title.')),
          backgroundColor: Colors.red.shade900,
        ));
        return;
      }
      channel = resolved;
    }
    _saveProgress();
    _progressReady = false;
    _reportStopped();
    setState(() => _currentChannel = channel);
    await _openMedia(channel, start: start, play: play);
    if (!mounted) return;
    unawaited(WatchTracker.instance.started(channel.id));
    _applySeriesSubtitles();
    if (_isLive) _DesktopLiveHistory.record(channel);
    // See initState's identical call for why — keeps it current across a
    // channel switch too, not just the one this screen opened with.
    if (_isLive) {
      context.read<StorageService>().setLastChannelId(channel.id);
      context.read<PlaybackService>().recordWatched(channel);
    }
  }

  /// An episode gets the subtitles chosen earlier in its series (same
  /// memory as Android's, see DesktopSubtitles.applyForSeries).
  void _applySeriesSubtitles() {
    if (_isLive) return;
    final channel = _currentChannel;
    unawaited(DesktopSubtitles.applyForSeries(
            context.read<StorageService>(), channel, _player,
            isCurrent: () => mounted && _currentChannel == channel)
        .catchError((Object _) => false));
  }

  /// Manual reconnect for a stalled live stream — this screen has none of
  /// `PlaybackService`'s automatic backup-server retry, so a simple
  /// re-open is the only recovery available.
  void _reload() => _player.open(
      Media(_currentChannel.url, httpHeaders: _headersOf(_currentChannel)));

  /// Headers a Media Hub add-on asked for (null keeps media_kit's cache).
  static Map<String, String>? _headersOf(Channel channel) =>
      channel.httpHeaders.isEmpty ? null : channel.httpHeaders;

  void _skip(Duration amount) {
    final current = _player.state.position;
    var target = current + amount;
    if (target < Duration.zero) target = Duration.zero;
    final duration = _player.state.duration;
    if (duration > Duration.zero && target > duration) target = duration;
    _player.seek(target);
  }

  Future<void> _openRecallPicker() async {
    final history = _DesktopLiveHistory.recentExcluding(_currentChannel.id);
    final chosen = await showModalBottomSheet<Channel>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black38,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: RefinedFinish.decorate(
              context,
              BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
              )),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  tr('Recall — recently watched'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    tr('No other live channels watched yet this session.'),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                )
              else
                ...history.map((c) => ListTile(
                      dense: true,
                      leading:
                          const Icon(Icons.tv, color: Colors.white54, size: 20),
                      title: Text(c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                      onTap: () => Navigator.of(sheetContext).pop(c),
                    )),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) _switchTo(chosen);
  }

  String _formatDuration(Duration d) {
    if (d.isNegative || d == Duration.zero) return '--:--';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  /// The player bar, one row like the Android player's (1.0.18): title on
  /// the left, buttons centred (scaled down to fit, never more than 60 % of
  /// the width), time on the right; a slim seek bar above it for VOD. Live
  /// shows what's left of the programme instead of a seek bar — never from
  /// the stream's own duration (a DVR window looked like a ~30 s file).
  Widget _buildBar(PlaylistManager playlist) {
    return StreamBuilder<bool>(
      stream: _player.stream.playing,
      initialData: _player.state.playing,
      builder: (context, playingSnapshot) {
        final playing = playingSnapshot.data ?? false;
        final width = MediaQuery.sizeOf(context).width;
        final buttons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Recall goes furthest left: it means *backward*.
            if (_isLive)
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                tooltip: tr('Recall — go back to a recent channel'),
                onPressed: _openRecallPicker,
              ),
            IconButton(
              icon: Icon(
                _currentChannel.isFavorite ? Icons.star : Icons.star_border,
                color: _currentChannel.isFavorite ? Colors.amber : Colors.white,
              ),
              tooltip: _currentChannel.isFavorite
                  ? tr('Remove from favorites')
                  : tr('Add to favorites'),
              onPressed: () {
                playlist.toggleFavorite(_currentChannel);
                setState(() {});
              },
            ),
            if (_isLive)
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: tr('Reload channel'),
                onPressed: _reload,
              ),
            if (_previousEpisode != null)
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white),
                tooltip: tr('Previous episode'),
                onPressed: () => _switchTo(_previousEpisode!),
              ),
            if (!_isLive)
              IconButton(
                tooltip: tr('Back 10 seconds'),
                icon: const Icon(Icons.replay_10, color: Colors.white),
                onPressed: () => _skip(const Duration(seconds: -10)),
              ),
            IconButton(
              tooltip: playing ? tr('Pause') : tr('Play'),
              iconSize: 40,
              color: Colors.white,
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              onPressed: () => playing ? _player.pause() : _player.play(),
            ),
            if (!_isLive)
              IconButton(
                tooltip: tr('Forward 10 seconds'),
                icon: const Icon(Icons.forward_10, color: Colors.white),
                onPressed: () => _skip(const Duration(seconds: 10)),
              ),
            if (_nextEpisode != null)
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                tooltip: tr('Next episode'),
                onPressed: () => _switchTo(_nextEpisode!),
              ),
            if (!_isLive)
              DesktopSubtitleButton(
                  // A new episode is a new file: fresh track list.
                  key: ValueKey(_currentChannel.id),
                  player: _player,
                  channel: _currentChannel),
            _DesktopVolume(player: _player),
          ],
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isLive)
              StreamBuilder<Duration>(
                stream: _player.stream.position,
                initialData: _player.state.position,
                builder: (context, posSnapshot) {
                  final position = posSnapshot.data ?? Duration.zero;
                  final duration = _player.state.duration;
                  final sliderMax = duration.inMilliseconds > 0
                      ? duration.inMilliseconds.toDouble()
                      : 1.0;
                  return SizedBox(
                    height: 24,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 12),
                      ),
                      child: Slider(
                        value: position.inMilliseconds
                            .clamp(0, sliderMax.toInt())
                            .toDouble(),
                        max: sliderMax,
                        onChanged: duration.inMilliseconds > 0
                            ? (v) =>
                                _player.seek(Duration(milliseconds: v.round()))
                            : null,
                      ),
                    ),
                  );
                },
              ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PlayerBarTitle(
                        title: _currentChannel.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      if (_isLive &&
                          playlist
                              .playlistNameFor(_currentChannel.playlistId)
                              .trim()
                              .isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: GoldTag(
                              label: playlist
                                  .playlistNameFor(_currentChannel.playlistId)
                                  .trim()),
                        ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width * 0.6),
                  child: FittedBox(fit: BoxFit.scaleDown, child: buttons),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _isLive
                        ? _LiveRemainingLabel(channelId: _currentChannel.epgId)
                        : StreamBuilder<Duration>(
                            stream: _player.stream.position,
                            initialData: _player.state.position,
                            builder: (context, posSnapshot) => Text(
                              '${_formatDuration(posSnapshot.data ?? Duration.zero)}'
                              ' / ${_formatDuration(_player.state.duration)}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlist = context.watch<PlaylistManager>();
    final size = MediaQuery.sizeOf(context);
    return PopScope(
      // Back with the side panel open closes it first.
      canPop: !_panelOpen && !_sourceBackGuard.blocksBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_sourceBackGuard.blocksBack) _closePanel();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          focusNode: _rootFocus,
          autofocus: true,
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                _rootFocus.hasPrimaryFocus &&
                _currentChannel.mediaFileInfo != null &&
                [
                  LogicalKeyboardKey.select,
                  LogicalKeyboardKey.enter,
                  LogicalKeyboardKey.numpadEnter
                ].contains(event.logicalKey)) {
              _fileInfoRequests.value++;
              return KeyEventResult.handled;
            }
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.arrowRight &&
                _rootFocus.hasPrimaryFocus &&
                widget.sources != null) {
              _openSources();
              return KeyEventResult.handled;
            }
            // M = mute / unmute, like most desktop players.
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.keyM) {
              _DesktopVolume.toggleMute(context, _player);
              return KeyEventResult.handled;
            }
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.arrowLeft &&
                // Not while arrowing along the player bar's buttons.
                _rootFocus.hasPrimaryFocus &&
                _isLive &&
                !_panelOpen) {
              _openPanel();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            onTap: () {
              if (_panelOpen) {
                _closePanel();
                return;
              }
              if (_currentChannel.mediaFileInfo != null) {
                _fileInfoRequests.value++;
              }
              setState(() => _controlsVisible = !_controlsVisible);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // NoVideoControls — Video defaults to its own built-in
                // AdaptiveVideoControls overlay (play/pause, seek bar, and
                // its own fullscreen toggle). Left on, that showed up as a
                // second player bar stacked on top of this screen's own,
                // and its fullscreen button entered real native-window
                // fullscreen with no way back to this screen's back
                // button (which isn't part of that overlay at all) short of
                // closing the app. This screen's own overlay below is the
                // only controls surface.
                Center(
                    child: Video(
                        controller: _videoController,
                        controls: NoVideoControls,
                        // Settings: the player's Subtitles menu > size.
                        subtitleViewConfiguration: SubtitleViewConfiguration(
                            textScaler: TextScaler.linear(context
                                .watch<AppPreferences>()
                                .subtitleScale)))),
                if (_controlsVisible) ...[
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: tr('Back'),
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: _handleBack,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: _buildBar(playlist),
                    ),
                  ),
                  if (_isLive && !_panelOpen)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: PlayerSidePanelTab(onTap: _openPanel),
                      ),
                    ),
                ],
                if (_currentChannel.mediaFileInfo case final info?)
                  MediaFileInfoOverlay(
                      key: ValueKey('file-info-${_currentChannel.id}'),
                      info: info,
                      requests: _fileInfoRequests),
                if (_panelOpen)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: math.min(PlayerSidePanel.width, size.width * 0.88),
                    child: GestureDetector(
                      // Clicks on the panel's empty space mustn't reach the
                      // video's click-to-close.
                      onTap: () {},
                      child: PlayerSidePanel(
                        current: _currentChannel,
                        onClose: _closePanel,
                        onPlay: _switchTo,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The live-only replacement for the seek bar — same widget/logic as
/// `PlayerControls`' private `_LiveRemainingLabel` on mobile: how long is
/// left in whatever's currently airing, from EPG data, not the video
/// controller's own (untrustworthy, for a live stream) duration.
class _LiveRemainingLabel extends StatelessWidget {
  const _LiveRemainingLabel({required this.channelId});

  final String channelId;

  @override
  Widget build(BuildContext context) {
    final epg = context.watch<EpgService>();
    final programme = epg.getCurrentProgram(channelId);
    if (programme == null) return const SizedBox.shrink();
    final remaining = programme.stop.difference(DateTime.now());
    if (remaining.isNegative) return const SizedBox.shrink();
    final minutes = remaining.inMinutes;
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        minutes < 1
            ? tr('Ending now')
            : tr('{minutes} min left', {'minutes': minutes}),
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}

/// Mute button + volume slider at the end of the player bar (Windows user
/// request, 2026-10-20). Volume and mute are remembered on this PC; mute
/// is volume 0 on the player, so the slider shows 0 while muted and
/// unmuting goes back to the saved level.
class _DesktopVolume extends StatelessWidget {
  const _DesktopVolume({required this.player});

  final Player player;

  static void toggleMute(BuildContext context, Player player) {
    final storage = context.read<StorageService>();
    final muted = !storage.getDesktopMuted();
    storage.setDesktopMuted(muted);
    player.setVolume(muted ? 0 : storage.getDesktopVolume());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: player.stream.volume,
      initialData: player.state.volume,
      builder: (context, snapshot) {
        final volume = (snapshot.data ?? 100).clamp(0.0, 100.0);
        final storage = context.read<StorageService>();
        final muted = storage.getDesktopMuted() || volume == 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                  muted
                      ? Icons.volume_off
                      : volume < 50
                          ? Icons.volume_down
                          : Icons.volume_up,
                  color: Colors.white),
              tooltip: muted ? tr('Unmute') : tr('Mute'),
              onPressed: () {
                if (!storage.getDesktopMuted() && volume == 0) {
                  // Slid down to 0: the button brings the sound back.
                  storage.setDesktopVolume(50);
                  player.setVolume(50);
                  return;
                }
                toggleMute(context, player);
              },
            ),
            SizedBox(
              width: 110,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: Slider(
                  value: muted ? 0 : volume,
                  max: 100,
                  onChanged: (v) {
                    storage.setDesktopMuted(false);
                    storage.setDesktopVolume(v);
                    player.setVolume(v);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
