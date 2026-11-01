import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player_hdr/video_player_hdr.dart';

import '../models/channel.dart';
import '../services/archive_playback_sources.dart';
import '../widgets/archive_source_drawer.dart';
import '../utils/playback_modal_back_guard.dart';
import '../services/app_preferences.dart';
import '../services/playback_service.dart';
import '../services/watch_game_offer.dart';
import '../services/playlist_manager.dart';
import '../services/skip_segments.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/tv_theme.dart';
import '../widgets/channel_schedule_panel.dart';
import '../widgets/live_channel_info_card.dart';
import '../widgets/data_pool_card.dart';
import '../widgets/epg_guide.dart';
import '../widgets/player_controls.dart';
import '../widgets/skip_segment_button.dart';
import '../widgets/watch_game_button.dart';
import '../widgets/subtitle_overlay.dart';
import '../widgets/player_side_panel.dart';
import 'multiview_screen.dart';
import 'search_screen.dart';
import '../l10n/l10n.dart';
import '../widgets/media_file_info_overlay.dart';
import '../widgets/phone_picture_in_picture.dart';
import '../widgets/player_touch_lock.dart';

/// Fullscreen playback screen. Pushed when a channel is tapped on a phone,
/// or when the mini-player bar is tapped to expand back into fullscreen —
/// either way it attaches to the same shared [PlaybackService] controller,
/// so it never restarts playback that's already running.
///
/// Also owns the actual "fullscreen" behavior other apps mean by that word:
/// landscape orientation + hidden system bars ([_toggleImmersive]) — but
/// only the "hidden system bars" half of that on a TV-sized screen. A TV
/// never physically rotates, so forcing an orientation there does nothing
/// useful and can actively backfire: [AppPreferences.layoutMode] "auto"
/// (see main.dart) picks the TV UI vs. phone UI based on
/// `MediaQuery.size.width`, and forcing `portraitUp` on restore was
/// observed to shrink that reported width enough to flip the *entire app*
/// into the phone layout after leaving fullscreen on a TV box. Orientation
/// is now only ever touched when [_isTvLayout] is false.
///
/// D-pad navigation is a small explicit state machine rather than default
/// focus traversal, mirroring the fix applied to [TvHomeScreen]'s columns:
/// - **Left** (live only, no bar focused) opens [PlayerSidePanel] — Last
///   channels / My Teams / Live now. It used to exit back to the list; the
///   owner moved that to Back only (2026-10-14).
/// - **Up** first reveals the top bar (back/search/fullscreen + the
///   current/next EPG line for live channels); pressed again, it moves
///   focus onto the back button so Left/Right can reach Search too.
/// - **Down** does the same for the bottom bar (title/seek bar/play-pause);
///   once focus is inside it with nowhere further to move, a further Down
///   reveals `PlayerControls`'s own secondary action row (Recall/Reload/
///   audio track/linked-channel) — see [_moreVisible].
/// Both bars auto-hide after inactivity so they can't permanently trap the
/// D-pad the way the seek bar used to.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.channel, this.sources});

  final Channel channel;
  final ArchivePlaybackSources? sources;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _immersive = false;
  bool _topVisible = false;
  bool _bottomVisible = false;
  bool _touchLocked = false;

  void _setTouchLocked(bool locked) {
    _hideTimer?.cancel();
    _zapInfoTimer?.cancel();
    _dataPoolTimer?.cancel();
    _skipCommit?.cancel();
    setState(() {
      _touchLocked = locked;
      _topVisible = !locked;
      _bottomVisible = !locked;
      _moreVisible = false;
      _panelOpen = false;
      _scheduleOpen = false;
      _zapInfoVisible = false;
      _dataPoolVisible = false;
      _skipTarget = null;
      _skipSteps = 0;
    });
    if (!locked) {
      _resetHideTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_touchLocked) _rootFocus.requestFocus();
      });
    }
  }

  /// Whether `PlayerControls`'s secondary ("more") action row — Recall,
  /// Reload, audio track, linked-channel failover — is expanded. A second
  /// Down press once focus is already inside the bottom bar with nowhere
  /// further to move reveals it (see [_handleDown]) — found this exact
  /// "press Down again" pattern on a competitor's player by accident, with
  /// no visual cue it existed; [PlayerControls.onToggleMore]'s chevron
  /// hint is what keeps that from being true here too. Reset alongside
  /// [_topVisible]/[_bottomVisible] on auto-hide so the bar always starts
  /// collapsed again next time it's revealed.
  bool _moreVisible = false;
  Timer? _hideTimer;

  /// Request counter for the independent Media Hub selected-file cue.
  final _fileInfoRequests = ValueNotifier<int>(0);

  /// CH+/CH- info card ([LiveChannelInfoCard]) — separate from the top bar so a
  /// zap shows what's on without moving focus or the bars.
  bool _zapInfoVisible = false;
  Timer? _zapInfoTimer;

  /// Data pool card ([DataPoolCard]) under the info card — OK only, when
  /// Settings > General > Data pool display is on. Stays 10 s (more to
  /// read than the info card's 4 s); OK again hides both.
  bool _dataPoolVisible = false;
  Timer? _dataPoolTimer;

  /// Skip intro / recap / credits on episodes (IntroDB, Settings >
  /// Playback > Skip intro). OK skips while its button shows.
  final _skip = SkipSegmentWatcher();

  /// The pill, focused by Up from the player bar (OK there reaches the
  /// focused bar button, not the pill). Focus returns to the screen when
  /// the pill goes away under it.
  final FocusNode _skipFocus = FocusNode(debugLabel: 'player-skip');

  bool get _skipShowing => _skip.visibleWith(_bottomVisible) != null;

  void _onSkipChanged() {
    if (_skipFocus.hasFocus && !_skipShowing) _rootFocus.requestFocus();
  }

  /// Watch game pill (Settings > Sports Trak > Watch game button): a
  /// reminded game started. Up from the bar (or from the skip pill) reaches
  /// it, OK switches; it never switches by itself (owner, 1.0.51).
  final FocusNode _watchFocus = FocusNode(debugLabel: 'player-watch-game');

  /// Like the skip pill: 10 s when it arrives (once per game), then
  /// only while the player bar shows or the pill has focus (owner, +544:
  /// it stayed forever).
  WatchGameOffer? get _watchOffer {
    final offer = WatchGameOffer.current.value;
    if (offer == null || offer.expired) return null;
    final playing = _playback.currentChannel ?? widget.channel;
    if (offer.channel.id == playing.id) return null;
    final fresh =
        _watchShownUntil != null && DateTime.now().isBefore(_watchShownUntil!);
    return fresh || _bottomVisible || _watchFocus.hasFocus ? offer : null;
  }

  DateTime? _watchShownUntil;
  Timer? _watchTimer;

  /// The bottom bar's measured height: the Watch game pill hugs its top
  /// edge (owner, +546), and the bar is taller with a seek bar (VOD).
  final _bottomBarKey = GlobalKey();
  double _bottomBarHeight = 96;

  void _measureBottomBar() {
    final box = _bottomBarKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final h = box.size.height;
    if ((h - _bottomBarHeight).abs() > 1 && mounted) {
      setState(() => _bottomBarHeight = h);
    }
  }

  void _armWatchTimer() {
    _watchTimer?.cancel();
    final offer = WatchGameOffer.current.value;
    if (offer == null || offer.announced) return;
    offer.announced = true;
    const shown = Duration(seconds: 10);
    _watchShownUntil = DateTime.now().add(shown);
    _watchTimer = Timer(shown, () {
      if (mounted) setState(() {});
    });
  }

  void _onWatchOfferChanged() {
    if (!mounted) return;
    _armWatchTimer();
    if (_watchFocus.hasFocus && _watchOffer == null) _rootFocus.requestFocus();
    setState(() {});
  }

  void _watchGame(WatchGameOffer offer) {
    if (_watchFocus.hasFocus) _rootFocus.requestFocus();
    WatchGameOffer.current.value = null;
    _zapTo(offer.channel);
  }

  void _onOk() {
    final segment = _skip.visibleWith(_bottomVisible);
    if (segment != null && !_panelOpen && !_scheduleOpen) {
      _skipSegment(segment);
      return;
    }
    _toggleInfoCard();
  }

  void _skipSegment(SkipSegment segment) {
    if (_skipFocus.hasFocus) _rootFocus.requestFocus();
    final next = _playback.nextUpChannel;
    _skip.skip(segment,
        playNext: next == null ? null : () => _playback.play(next));
  }

  /// [PlayerSidePanel] showing (Left on a live channel). Back closes it
  /// instead of leaving the player (see the PopScope in [build]).
  bool _panelOpen = false;

  /// The screen's own key-catching Focus — focus goes back here when the
  /// panel closes, so Up/Down/Left work again straight away.
  final FocusNode _rootFocus = FocusNode(debugLabel: 'player-root');

  void _openPanel() {
    _hideTimer?.cancel();
    setState(() {
      _panelOpen = true;
      _topVisible = false;
      _bottomVisible = false;
      _moreVisible = false;
    });
  }

  void _closePanel() {
    if (!_panelOpen) return;
    setState(() => _panelOpen = false);
    _rootFocus.requestFocus();
  }

  /// "Channel schedule" control inside the info card: Up from the card
  /// focuses it, OK opens [ChannelSchedulePanel] (owner, 2026-10-28).
  final FocusNode _scheduleChipFocus =
      FocusNode(debugLabel: 'player-schedule-chip');

  /// [ChannelSchedulePanel] showing. Back closes it (PopScope).
  bool _scheduleOpen = false;

  void _focusScheduleChip() {
    _zapInfoTimer?.cancel();
    _scheduleChipFocus.requestFocus();
  }

  /// Down/Back on the chip: back to the video, the card hides as usual.
  void _leaveScheduleChip() {
    _rootFocus.requestFocus();
    _zapInfoTimer?.cancel();
    _zapInfoTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _zapInfoVisible = false);
    });
  }

  void _openSchedule() {
    _hideTimer?.cancel();
    _zapInfoTimer?.cancel();
    _dataPoolTimer?.cancel();
    setState(() {
      _scheduleOpen = true;
      _zapInfoVisible = false;
      _dataPoolVisible = false;
      _topVisible = false;
      _bottomVisible = false;
      _moreVisible = false;
    });
  }

  void _closeSchedule() {
    if (!_scheduleOpen) return;
    setState(() => _scheduleOpen = false);
    _rootFocus.requestFocus();
  }

  KeyEventResult _onScheduleChipKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (event is KeyDownEvent) _openSchedule();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      if (event is KeyDownEvent) _leaveScheduleChip();
      return KeyEventResult.handled;
    }
    // Up/Left/Right stay on the chip (the root would open the bars or the
    // side panel under it).
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  late final _sourceBackGuard = PlaybackModalBackGuard(onChanged: () {
    if (mounted) setState(() {});
  });
  bool get _sourceDrawerOpen => _sourceBackGuard.isOpen;

  Future<void> _openSources() async {
    final sources = widget.sources;
    final channel = _playback.currentChannel;
    if (sources == null || channel == null || _sourceDrawerOpen) return;
    _sourceBackGuard.opened();
    _hideTimer?.cancel();
    setState(() {
      _topVisible = false;
      _bottomVisible = false;
      _moreVisible = false;
    });
    try {
      final selection = await showArchiveSourceDrawer(context,
          sources: sources, channelId: channel.id);
      if (!mounted ||
          selection == null ||
          _playback.currentChannel?.id != channel.id) {
        return;
      }
      await sources.remember(channel.id, selection.option);
      if (!mounted || _playback.currentChannel?.id != channel.id) return;
      final wasPlaying = _playback.controller?.value.isPlaying ?? true;
      // Same title/episode ID, new URL: teardown saves its exact position
      // before the replacement controller reads the normal resume point.
      await _playback.play(selection.channel);
      final replacement = _playback.controller;
      await _playback.initFuture;
      if (!wasPlaying && mounted && _playback.controller == replacement) {
        await replacement?.pause();
      }
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

  /// Refreshed on every build (see [build]) and read from [_toggleImmersive]
  /// / [_restoreChrome] / [dispose] — those don't call [build] themselves,
  /// so this caches the last-known answer rather than doing a fresh
  /// `context.watch`/`MediaQuery.of` lookup from places where that's
  /// unsafe (dispose) or unnecessary (a plain button handler).
  bool _isTvLayout = false;

  /// A touch device (phone/tablet), refreshed on every build like
  /// [_isTvLayout] — unlike that one it stays true for a phone held
  /// sideways, whose width can pass the TV-layout threshold.
  bool _touch = false;

  /// The rotate button forced an orientation (released on leaving).
  bool _rotated = false;

  /// Touch devices: the orientation the system bars were last set for —
  /// hidden in landscape (they sat over the video and the player bar,
  /// Pixel 10 Pro XL, Discord 2026-10-28), shown in portrait unless Fill.
  Orientation? _barsFor;
  bool _barsHidden = false;

  void _syncSystemBars(Orientation orientation) {
    if (_barsFor == orientation) return;
    _barsFor = orientation;
    final hide = _immersive || orientation == Orientation.landscape;
    if (hide == _barsHidden) return;
    _barsHidden = hide;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SystemChrome.setEnabledSystemUIMode(
          hide ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
    });
  }

  final FocusScopeNode _topScope = FocusScopeNode(debugLabel: 'player-top');
  final FocusNode _playFocus = FocusNode(debugLabel: 'player-play');
  final FocusScopeNode _bottomScope =
      FocusScopeNode(debugLabel: 'player-bottom');

  /// The "Switch to linked channel" button VideoPlayerPane shows on a
  /// playback error — owned here (not by that button itself) so Up/Down can
  /// treat it as a third explicit zone. See
  /// [VideoPlayerPane.switchButtonFocusNode]'s doc comment for why.
  final FocusNode _switchButtonFocus =
      FocusNode(debugLabel: 'player-switch-button');

  /// Refreshed on every build, same pattern as [_isTvLayout] — read from
  /// [_handleUp]/[_handleDown], which don't run during a build themselves.
  bool _hasSwitchButton = false;

  bool get _focusInBar => _topScope.hasFocus || _bottomScope.hasFocus;

  /// Search from the player should land on the tab that matches what's
  /// playing — inferred from the Xtream id prefix (see
  /// XtreamApiService.getVodStreams/getSeriesEpisodes/getLiveStreams).
  String get _searchScope {
    final id = widget.channel.id;
    if (id.startsWith('xt_vod_')) return 'Movies';
    if (id.startsWith('xt_ep_')) return 'TV Shows';
    return 'TV';
  }

  late final PlaybackService _playback;

  @override
  void initState() {
    super.initState();
    _playback = context.read<PlaybackService>();
    _playback.play(widget.channel);
    // Read by LiveResumeHint — stops its hold-Right gesture from firing
    // again on top of an already-showing fullscreen view, and hides its
    // reminder text while this is showing. Deferred a frame: this is
    // called from `initState`, itself running mid-build for the frame
    // that's mounting this freshly-pushed route — `setFullscreenActive`'s
    // `notifyListeners()` reaching another, already-mounted widget's
    // `setState()` at that exact moment isn't a safe time to do it.
    // Confirmed on real hardware as the cause of the reminder text
    // sometimes not hiding when it should: a release build has no
    // assertion for this (unlike debug), so the resulting rebuild just
    // silently got lost instead of throwing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playback.setFullscreenActive(true);
    });
    _topScope.addListener(_onBarFocusChange);
    _bottomScope.addListener(_onBarFocusChange);
    _skip.addListener(_onSkipChanged);
    WatchGameOffer.current.addListener(_onWatchOfferChanged);
    _armWatchTimer();
    _switchButtonFocus.addListener(_onBarFocusChange);
    _scheduleChipFocus.addListener(_onBarFocusChange);
    _resetHideTimer();
    // Fill remembered from last time: hide the system bars again (no
    // orientation lock — that only comes with pressing ⛶).
    if (context.read<AppPreferences>().videoFill &&
        !context.read<AppPreferences>().isTelevision) {
      _immersive = true;
      _barsHidden = true;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _onBarFocusChange() {
    if (mounted) setState(() {});
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _topVisible = false;
          _bottomVisible = false;
          _moreVisible = false;
        });
        // An auto-hidden pill goes with the bar.
        _onSkipChanged();
      }
    });
  }

  /// Once inside a bar (e.g. focus on the new favorite-star button next to
  /// the seek bar), Up/Down always jumping straight to "reveal/focus the
  /// scope" — instead of first trying to move to the *next* thing in that
  /// bar (star → play/pause) — left nothing reachable past the star: the
  /// exact "trapped, can't do anything else" bug the seek bar itself used
  /// to have. Try the normal move first, same fallback pattern used
  /// elsewhere this session; only fall back to the reveal/jump behavior
  /// once there's nowhere further to go.
  ///
  /// [FocusNode.focusInDirection]'s geometric search isn't bounded to "the
  /// bar you started in" the way that comment assumes, though — confirmed
  /// directly, once the switch-to-linked-channel button existed as a third
  /// focusable thing sitting between the two bars, as it jumping straight
  /// from the bottom bar to the (differently-shaped, full-width) top bar
  /// and skipping the button entirely. [_tryIntraBarMove] below keeps the
  /// legitimate star→play/pause case working while rejecting exactly that:
  /// a move is only accepted if it lands back inside the same bar it
  /// started in, so escaping to somewhere else on screen is never mistaken
  /// for "nothing further to move to in this bar".
  bool _tryIntraBarMove(FocusScopeNode scope, TraversalDirection direction) {
    final previous = FocusManager.instance.primaryFocus;
    final moved = previous?.focusInDirection(direction) ?? false;
    if (moved && scope.hasFocus) return true;
    if (moved) previous?.requestFocus();
    return false;
  }

  void _handleUp() {
    // Info card up: Up reaches its "Channel schedule" chip first.
    if (_zapInfoVisible &&
        !_focusInBar &&
        !_switchButtonFocus.hasFocus &&
        !_scheduleOpen) {
      _focusScheduleChip();
      return;
    }
    _resetHideTimer();
    if (_switchButtonFocus.hasFocus) {
      if (!_topVisible) {
        setState(() => _topVisible = true);
        return;
      }
      _topScope.requestFocus();
      return;
    }
    if (_bottomScope.hasFocus) {
      if (_tryIntraBarMove(_bottomScope, TraversalDirection.up)) return;
      if (_skipShowing) {
        _skipFocus.requestFocus();
        return;
      }
      if (_watchOffer != null) {
        _watchFocus.requestFocus();
        return;
      }
      if (_hasSwitchButton) {
        _switchButtonFocus.requestFocus();
        return;
      }
      if (!_topVisible) {
        setState(() => _topVisible = true);
        return;
      }
      _topScope.requestFocus();
      return;
    }
    if (_topScope.hasFocus) {
      _tryIntraBarMove(_topScope, TraversalDirection.up);
      return;
    }
    if (!_topVisible) {
      setState(() => _topVisible = true);
      return;
    }
    _topScope.requestFocus();
  }

  /// Shows the bottom bar with Play/Pause focused in one press. Showing it
  /// alone, then focusing the bar's scope (no child), left nothing
  /// highlighted: it took a second Down plus Left/Right to see where the
  /// remote was (owner, 2026-10-18).
  void _focusBottomBar() {
    if (!_bottomVisible) setState(() => _bottomVisible = true);
    // Next frame: the bar is ExcludeFocus'd until it's visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_playFocus.context != null) {
        _playFocus.requestFocus();
      } else {
        _bottomScope.requestFocus();
      }
    });
  }

  void _handleDown() {
    _resetHideTimer();
    if (_switchButtonFocus.hasFocus) {
      _focusBottomBar();
      return;
    }
    if (_topScope.hasFocus) {
      if (_tryIntraBarMove(_topScope, TraversalDirection.down)) return;
      if (_hasSwitchButton) {
        _switchButtonFocus.requestFocus();
        return;
      }
      _focusBottomBar();
      return;
    }
    if (_bottomScope.hasFocus) {
      // All the buttons are on one line now (no second row to reveal).
      _tryIntraBarMove(_bottomScope, TraversalDirection.down);
      return;
    }
    _focusBottomBar();
  }

  /// `PlaybackService`'s own controller is deliberately kept alive in the
  /// background for the normal "back out of fullscreen" case (the mobile
  /// "island"/resume hint) — but here, the same channel is about to start
  /// playing again from scratch as Multiview's own first cell, an entirely
  /// separate decode session. Leaving the old one running underneath
  /// doesn't serve that "resume where I left off" purpose at all in this
  /// case, it just duplicates the stream — reported directly as its audio
  /// bleeding through on top of whichever Multiview cell has focus, and on
  /// hardware already close to its concurrent-decoder ceiling, an extra
  /// background session is a real stability cost too. Same fix already
  /// established for `TvHomeScreen`'s own "Multiview" sidebar entry —
  /// this just applies it to this second entry point, which missed it.
  Future<void> _openMultiview(Channel channel) async {
    await _playback.stop();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MultiviewScreen(initialChannel: channel)));
  }

  void _revealBottomOnTap() {
    // Touch: a tap on the video beside the open side panel closes it.
    if (_panelOpen) {
      _closePanel();
      return;
    }
    if (_scheduleOpen) {
      _closeSchedule();
      return;
    }
    if ((_playback.currentChannel ?? widget.channel).mediaFileInfo != null) {
      _fileInfoRequests.value++;
    }
    // Phone/tablet: a tap shows both bars (the top one holds the
    // fullscreen button, which turns the phone landscape without the
    // system rotation lock), and a second tap hides them again.
    if (_touch) {
      final show = !(_topVisible && _bottomVisible);
      if (show) {
        _resetHideTimer();
      } else {
        _hideTimer?.cancel();
      }
      setState(() {
        _topVisible = show;
        _bottomVisible = show;
        if (!show) _moreVisible = false;
      });
      return;
    }
    _resetHideTimer();
    setState(() => _bottomVisible = true);
  }

  /// A remote's dedicated hardware Play/Pause button (or separate Play/
  /// Pause keys, on remotes that split them) should just work regardless
  /// of where D-pad focus currently is — requiring the user to navigate to
  /// the on-screen button first defeats the entire point of a physical
  /// media key existing. Bound alongside Up/Down below rather than gated
  /// by `!_focusInBar` the way Left/Right are: this should fire no matter
  /// which bar (if any) currently has focus, not just when none does. A
  /// remote with no such key simply never sends this event — the on-screen
  /// button (and D-pad navigation to it) keeps working exactly as before.
  void _handlePlayPause() {
    if (_playback.controller == null) return;
    _resetHideTimer();
    // Through the service: pausing a live channel with catch-up is a
    // timeshift (Play resumes from the pause).
    _playback.togglePlayPause();
  }

  /// The remote's Fast-forward / Rewind skip like the bar's +10 / -10
  /// (owner, 2026-10-28): on a movie, episode or catch-up each press (or
  /// key repeat while held) moves a target that grows 10 s → 30 s → 1 → 2
  /// → 5 min, one seek lands 700 ms after the last press ([_ScrubBar]'s
  /// rule: each seek re-buffers). Fast-forward to a catch-up's end = live.
  /// On a live channel with catch-up, Rewind goes back in minutes (a
  /// timeshift through catch-up); Fast-forward does nothing there.
  void _handleFastForward() => _skipKey(1);

  void _handleRewind() => _skipKey(-1);

  /// Seekable target ([_skipLive] false) or minutes back from now (true).
  Duration? _skipTarget;
  bool _skipLive = false;
  int _skipSteps = 0;
  Timer? _skipCommit;

  static int _skipStepSeconds(int steps) => steps < 3
      ? 10
      : steps < 6
          ? 30
          : steps < 10
              ? 60
              : steps < 15
                  ? 120
                  : 300;

  /// Live rewind: past catch-up's 90 s live edge from the first press.
  static int _liveStepMinutes(int steps) => steps == 0
      ? 2
      : steps < 4
          ? 1
          : steps < 8
              ? 5
              : 15;

  void _skipKey(int sign) {
    if (_panelOpen || _scheduleOpen) return;
    final controller = _playback.controller;
    if (controller == null) return;
    final channel = _playback.currentChannel ?? widget.channel;
    final duration = controller.value.duration;
    final seekable = !channel.isLive && duration > Duration.zero;
    if (seekable) {
      if (_skipLive) _skipTarget = null;
      _skipLive = false;
      final from = _skipTarget ?? controller.value.position;
      final next =
          from + Duration(seconds: sign * _skipStepSeconds(_skipSteps++));
      _skipTarget = next < Duration.zero
          ? Duration.zero
          : next > duration
              ? duration
              : next;
    } else {
      final live = _playback.liveChannel ?? channel;
      if (sign > 0 || !live.isLive || !live.hasCatchup) return;
      if (!_skipLive) _skipTarget = null;
      _skipLive = true;
      final back = (_skipTarget ?? Duration.zero) +
          Duration(minutes: _liveStepMinutes(_skipSteps++));
      final most = Duration(days: live.catchupDays);
      _skipTarget = back > most ? most : back;
    }
    _resetHideTimer();
    setState(() {});
    _skipCommit?.cancel();
    _skipCommit = Timer(const Duration(milliseconds: 700), _commitSkip);
  }

  void _commitSkip() {
    _skipCommit?.cancel();
    final target = _skipTarget;
    final live = _skipLive;
    _skipTarget = null;
    _skipSteps = 0;
    if (mounted) setState(() {});
    final controller = _playback.controller;
    if (target == null || controller == null) return;
    if (live) {
      final channel = _playback.liveChannel ?? widget.channel;
      _playback.playCatchup(channel, DateTime.now().subtract(target),
          toProgrammeEnd: false);
      return;
    }
    // Fast-forward to the end of a catch-up: that's now, so live.
    if (_playback.catchup != null &&
        controller.value.duration - target < const Duration(seconds: 5)) {
      _playback.backToLive();
      return;
    }
    controller.seekTo(target);
  }

  /// A remote's CH+/CH- (or Page Up/Down) keys: CH- = next channel (the
  /// one below in the list), CH+ = previous (above) — matches the guide,
  /// owner's call. Steps through the list the channel was picked from
  /// ([PlaybackService.zapList], e.g. Favourites), else the channel's own
  /// group; wraps at either end. Live only; a remote without these keys
  /// (Fire Stick) never sends them. Reveals the top bar so the new
  /// channel's name + now/next show.
  void _zapChannel(int step) {
    if (_panelOpen || _scheduleOpen) return;
    // From catch-up, zapping steps from its live channel (and leaves it).
    final current = _playback.liveChannel ?? widget.channel;
    if (!current.isLive) return;
    // A playlist can list the same channel twice (same id, e.g. a tvg-id
    // used as the id): find the exact entry playing, and step past any
    // copy with the same id — play() no-ops on it, which used to leave
    // CH+/- stuck on a duplicate (owner, Favourites).
    int indexIn(List<Channel> l) {
      final exact = l.indexWhere((c) => identical(c, current));
      return exact >= 0 ? exact : l.indexWhere((c) => c.id == current.id);
    }

    var list = _playback.zapList ?? const <Channel>[];
    var i = indexIn(list);
    if (i < 0) {
      list = context.read<PlaylistManager>().visibleChannels(
          playlistId: current.playlistId,
          groupTitle: current.group,
          category: 'tv');
      i = indexIn(list);
    }
    if (i < 0) return;
    Channel? next;
    for (var n = 1; n < list.length; n++) {
      final c = list[(i + step * n) % list.length];
      if (c.id != current.id) {
        next = c;
        break;
      }
    }
    final target = next;
    if (target == null) return;
    _zapTo(target);
  }

  /// Right on a live channel: back to the channel watched before this one
  /// (the side panel's Last channels list), so Right again flips back.
  void _lastChannel() {
    if (_panelOpen || _scheduleOpen) return;
    final current = _playback.liveChannel ?? widget.channel;
    if (!current.isLive) return;
    final target = _playback.recentlyPlayed
        .where((c) => c.isLive && c.id != current.id)
        .firstOrNull;
    if (target != null) _zapTo(target);
  }

  void _zapTo(Channel target) {
    // Info overlay stays up while the new stream connects, then for 3 s
    // once it's started (owner's call) — counted from the start, not the
    // key press, so a slow stream doesn't eat the whole window.
    _zapInfoTimer?.cancel();
    setState(() => _zapInfoVisible = true);
    _playback.play(target).whenComplete(() {
      if (!mounted || _playback.currentChannel?.id != target.id) return;
      _zapInfoTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _zapInfoVisible = false);
      });
    });
  }

  /// OK with no bar focused on a live channel: the CH+/CH- info card for
  /// 4 s (owner, 2026-10-18); OK again hides it. With Data pool on, its
  /// card too — and on movies/episodes (provider or Media Hub) the Data
  /// pool card alone (owner, 2026-10-21: a user missed VOD stream specs).
  void _toggleInfoCard() {
    if (_panelOpen || _scheduleOpen) return;
    final current = _playback.currentChannel ?? widget.channel;
    if (current.mediaFileInfo != null) _fileInfoRequests.value++;
    // Catch-up gets the same card, for the programme at the playhead.
    final live = current.isLive || _playback.catchup != null;
    final dataPool = context.read<AppPreferences>().dataPool;
    if (!live && !dataPool) return;
    _zapInfoTimer?.cancel();
    _dataPoolTimer?.cancel();
    if (_zapInfoVisible || _dataPoolVisible) {
      setState(() {
        _zapInfoVisible = false;
        _dataPoolVisible = false;
      });
      return;
    }
    setState(() {
      _zapInfoVisible = live;
      _dataPoolVisible = dataPool;
    });
    if (live) {
      _zapInfoTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _zapInfoVisible = false);
      });
    }
    if (dataPool) {
      _dataPoolTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) setState(() => _dataPoolVisible = false);
      });
    }
  }

  /// ⛶: the picture fills the whole screen (zoomed, edges cropped, no black
  /// bars; remembered) and the system bars hide; again = fit + bars back.
  /// Owner: on his phone this button used to look like it did nothing — it
  /// only toggled the system bars.
  Future<void> _toggleImmersive() async {
    final prefs = context.read<AppPreferences>();
    final next = !prefs.videoFill;
    prefs.setVideoFill(next);
    _resetHideTimer();
    setState(() => _immersive = next);
    _barsHidden = next;
    _barsFor = null;
    if (next) {
      if (!_isTvLayout) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await _restoreChrome();
    }
  }

  /// Phone: flips between landscape and portrait without the system's
  /// rotation lock (top bar's rotate button).
  Future<void> _toggleRotation() async {
    final toLandscape =
        MediaQuery.of(context).orientation == Orientation.portrait;
    _rotated = true;
    _resetHideTimer();
    await SystemChrome.setPreferredOrientations(toLandscape
        ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
        : [DeviceOrientation.portraitUp]);
  }

  Future<void> _restoreChrome() async {
    if (!_isTvLayout) {
      // Release the lock instead of forcing portraitUp specifically — a
      // phone/tablet held sideways (or a tablet used in landscape as its
      // normal orientation) shouldn't get snapped to portrait just because
      // it watched a video fullscreen; letting go of the restriction lets
      // the sensor/app defaults decide instead.
      await SystemChrome.setPreferredOrientations([]);
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _sourceBackGuard.dispose();
    // Deferred a frame for the same reason `initState` defers the
    // opposite call — this runs mid-build for the frame that's tearing
    // down this route, not a safe time for another widget's `setState`
    // to land. `_playback` is a long-lived singleton, safe to touch
    // after this widget's own disposal.
    //
    //
    // Live TV deliberately keeps playing in the background (see
    // LiveResumeHint) — channel-surfing while keeping a live stream "on
    // standby" is a real pattern a live stream's own lack of a fixed
    // endpoint supports. A movie/episode has a clear stop, and backing
    // out was reported directly as leaving it audibly still playing with
    // no way back short of manually finding and reselecting it — no
    // resume prompt exists for VOD at all, unlike live. Stopping it here
    // instead, with the exact position saved (see
    // PlaybackService._teardown), means Continue Watching is the one,
    // deliberate way back in, instead of a confusing background audio
    // leak with no discoverable resume path. Bundled into the same
    // deferred callback as setFullscreenActive below — stop() also calls
    // notifyListeners(), the exact same "not safe mid-teardown" case that
    // callback already exists for.
    final ch = _playback.currentChannel;
    // Catch-up keeps playing behind the guide, like live.
    final shouldStopVod = ch != null && !ch.isLive && _playback.catchup == null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shouldStopVod) unawaited(_playback.stop());
      _playback.setFullscreenActive(false);
    });
    _hideTimer?.cancel();
    _zapInfoTimer?.cancel();
    _dataPoolTimer?.cancel();
    _skipCommit?.cancel();
    _skip.removeListener(_onSkipChanged);
    _skip.dispose();
    _skipFocus.dispose();
    WatchGameOffer.current.removeListener(_onWatchOfferChanged);
    _watchTimer?.cancel();
    _watchFocus.dispose();
    _fileInfoRequests.dispose();
    _topScope.removeListener(_onBarFocusChange);
    _bottomScope.removeListener(_onBarFocusChange);
    _switchButtonFocus.removeListener(_onBarFocusChange);
    _scheduleChipFocus.removeListener(_onBarFocusChange);
    _scheduleChipFocus.dispose();
    _topScope.dispose();
    _bottomScope.dispose();
    _playFocus.dispose();
    _switchButtonFocus.dispose();
    _rootFocus.dispose();
    // Defensive: never leave the whole app stuck in landscape/immersive
    // mode if this screen is popped while _immersive was still on.
    if (_immersive || _rotated || _barsHidden) _restoreChrome();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PhonePictureInPicture(
        controller: context.watch<PlaybackService>().controller,
        isTelevision: context.watch<AppPreferences>().isTelevision,
        builder: _buildPlayer,
      );

  Widget _buildPlayer(BuildContext context, bool inPip) {
    if (WatchGameOffer.current.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureBottomBar());
    }
    final playback = context.watch<PlaybackService>();
    final controller = playback.controller;
    final prefs = context.watch<AppPreferences>();
    // Just to rebuild (and so the star reflects the current state) when
    // toggled from this screen — widget.channel is the same object
    // instance PlaylistManager.toggleFavorite mutates, not a copy.
    final playlist = context.watch<PlaylistManager>();
    // Auto-advancing into the next episode (see PlaybackService's up-next
    // queue) swaps `playback.currentChannel` without this screen being
    // popped/re-pushed — everything below reflects whatever's *actually*
    // playing, not just the episode this screen was originally opened for.
    final channel = playback.currentChannel ?? widget.channel;
    final storage = context.read<StorageService>();
    _skip.attach(controller, channel.id,
        enabled: storage.getSkipSegments(),
        episodeCandidate: !channel.isLive &&
            !channel.transientPlayback &&
            playback.catchup == null,
        tmdbKey: storage.getTmdbApiKey());
    // Catch-up: the guide line and the OK card follow the playhead.
    final session = playback.catchup;
    final catchupAt = session == null || controller == null
        ? null
        : session.playhead(controller.value.position);
    // See PlayerControls.linkedChannel's doc comment. Resolved fresh on
    // every build (not cached) — a link the user just set in Settings, or
    // a channel that's disappeared from a refreshed catalog, should show
    // up/go away here without needing to reopen this screen.
    final channelLink = playlist.channelLinkFor(channel);
    final linkedChannel =
        channelLink == null ? null : playlist.resolveChannelLink(channelLink);
    // Read by [_handleUp]/[_handleDown] — kept in sync with whatever
    // VideoPlayerPane below actually decides to show (playback.error != null
    // && a linkedChannel to offer), same caching pattern as [_isTvLayout].
    _hasSwitchButton = playback.error != null && linkedChannel != null;
    _touch = !prefs.isTelevision;
    final phoneTouch =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android && _touch;
    final touchLocked = phoneTouch && _touchLocked && !inPip;
    if (_touch && !inPip) _syncSystemBars(MediaQuery.orientationOf(context));
    _isTvLayout = prefs.layoutMode == 'tv' ||
        (prefs.layoutMode == 'auto' &&
            (prefs.isTelevision ||
                MediaQuery.of(context).size.width >=
                    AppConstants.tvLayoutWidthThreshold));

    final player = withTvThemeIfNeeded(
        context,
        (context) => PopScope(
            // Back with the side panel / schedule open just closes it;
            // on the schedule chip, it returns to the video.
            canPop: !_panelOpen &&
                !_scheduleOpen &&
                !_scheduleChipFocus.hasFocus &&
                !_sourceBackGuard.blocksBack,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop || touchLocked || _sourceBackGuard.blocksBack) return;
              if (_scheduleOpen) {
                _closeSchedule();
              } else if (_scheduleChipFocus.hasFocus) {
                _leaveScheduleChip();
              } else {
                _closePanel();
              }
            },
            child: Scaffold(
              backgroundColor: Colors.black,
              body: CallbackShortcuts(
                bindings: <ShortcutActivator, VoidCallback>{
                  const SingleActivator(LogicalKeyboardKey.arrowUp): _handleUp,
                  const SingleActivator(LogicalKeyboardKey.arrowDown):
                      _handleDown,
                  // Some remotes send a single combined key, others send separate
                  // Play and Pause keys (e.g. a dedicated Pause button) — bound to
                  // the same toggle handler either way, since it already checks
                  // the actual current state rather than assuming.
                  const SingleActivator(LogicalKeyboardKey.mediaPlayPause):
                      _handlePlayPause,
                  const SingleActivator(LogicalKeyboardKey.mediaPlay):
                      _handlePlayPause,
                  const SingleActivator(LogicalKeyboardKey.mediaPause):
                      _handlePlayPause,
                  const SingleActivator(LogicalKeyboardKey.mediaFastForward):
                      _handleFastForward,
                  const SingleActivator(LogicalKeyboardKey.mediaRewind):
                      _handleRewind,
                  const SingleActivator(LogicalKeyboardKey.channelUp): () =>
                      _zapChannel(-1),
                  const SingleActivator(LogicalKeyboardKey.channelDown): () =>
                      _zapChannel(1),
                  const SingleActivator(LogicalKeyboardKey.pageUp): () =>
                      _zapChannel(-1),
                  const SingleActivator(LogicalKeyboardKey.pageDown): () =>
                      _zapChannel(1),
                  if (!_focusInBar) ...{
                    // Back is the only way out now; Left opens the side
                    // panel on a live channel (a no-op on movies/episodes).
                    const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
                      if (channel.isLive || playback.catchup != null) {
                        _openPanel();
                      }
                    },
                    // Right never had any established purpose here — it simply had
                    // no handler at all, so with no bar focused (nothing else on
                    // this screen to move to) it fell through to Flutter's
                    // *default* directional focus search across every focusable
                    // widget currently attached, including whatever's still
                    // mounted (just covered, never torn down) on the route
                    // underneath. If that was a big Movies/TV Shows catalog with
                    // hundreds of poster cards, that geometric search over a huge
                    // focus graph is expensive enough to hang weaker hardware —
                    // confirmed on real hardware as a genuine ANR ("Input
                    // dispatching timed out... Waited 5004ms for KeyEvent", CPU at
                    // 186%), not a clean exception: the video kept playing (it's
                    // driven independently of the Dart UI thread) while the UI
                    // froze solid until Android force-killed the app. Consume
                    // it even when no Media Hub sources exist;
                    // Media Hub playback uses it to open its source drawer.
                    // Live: Right = last channel (owner, 2026-10-29). No
                    // repeats: the Right held to resume this player (the
                    // "Hold > to resume" pill) recalled the last channel on
                    // arrival (owner, +545).
                    const SingleActivator(LogicalKeyboardKey.arrowRight,
                        includeRepeats: false): () {
                      if (channel.isLive || playback.catchup != null) {
                        _lastChannel();
                      } else {
                        _openSources();
                      }
                    },
                    // No repeats: the OK held to open this player must not
                    // pop the card on arrival.
                    const SingleActivator(LogicalKeyboardKey.select,
                        includeRepeats: false): _onOk,
                    const SingleActivator(LogicalKeyboardKey.enter,
                        includeRepeats: false): _onOk,
                    const SingleActivator(LogicalKeyboardKey.numpadEnter,
                        includeRepeats: false): _onOk,
                  },
                },
                child: Focus(
                  focusNode: _rootFocus,
                  autofocus: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _revealBottomOnTap,
                    // Touch has no Left key: swipe right opens the side
                    // panel on a live channel, swipe left closes it.
                    onHorizontalDragEnd: _touch
                        ? (d) {
                            final v = d.primaryVelocity ?? 0;
                            if (v > 300 &&
                                !_panelOpen &&
                                !_scheduleOpen &&
                                channel.isLive) {
                              _openPanel();
                            } else if (v < -300 && _panelOpen) {
                              _closePanel();
                            }
                          }
                        : null,
                    // No outer SafeArea here (deliberately — it was tried and
                    // wasn't the fix; left off anyway since it's unneeded once the
                    // real bug below is fixed). The top/bottom bars keep their own
                    // narrow `SafeArea(bottom: false)` for their own content.
                    //
                    // Every entry in this Stack's children list must resolve to a
                    // `Positioned` widget, with no exceptions — see [_UpNextBubble]
                    // for why: Stack only sizes itself to fill the available space
                    // (`constraints.biggest`) when *every* child is `Positioned`;
                    // a single non-positioned child (even a zero-size
                    // `SizedBox.shrink()`) makes Stack size itself to fit that
                    // child instead, which was collapsing this entire Stack —
                    // video included — to 0x0 whenever `_UpNextBubble` had nothing
                    // to show (i.e. essentially always). That was the actual cause
                    // of the black fullscreen screen.
                    child: Stack(
                      children: [
                        Positioned.fill(
                          // See HomeScreen's identical fix for why this is
                          // keyed to the channel rather than const.
                          child: VideoPlayerPane(
                            key: ValueKey(channel.id),
                            showControls: false,
                            showEpgBar: false,
                            fillScreen: prefs.videoFill,
                            switchButtonFocusNode: _switchButtonFocus,
                          ),
                        ),
                        if (!inPip) ...[
                          // Top bar: back, current/next EPG line (live only), search,
                          // fullscreen toggle. Positioned has to be the outermost
                          // widget of this Stack entry — burying it under
                          // ExcludeFocus/AnimatedOpacity (as an earlier draft of
                          // this did) breaks Stack's "nearest RenderObjectWidget
                          // ancestor" resolution for Positioned's parent data.
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            // Hidden = not tappable either (an invisible back
                            // button used to still catch taps up there).
                            child: IgnorePointer(
                              ignoring: !_topVisible,
                              child: ExcludeFocus(
                                excluding: !_topVisible,
                                child: AnimatedOpacity(
                                  opacity: _topVisible ? 1 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: FocusTraversalGroup(
                                    child: FocusScope(
                                      node: _topScope,
                                      child: Container(
                                        color: Colors.black54,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 4),
                                        child: SafeArea(
                                          bottom: false,
                                          child: Row(
                                            children: [
                                              _TopBarIconButton(
                                                icon: Icons.arrow_back,
                                                tooltip: tr('Back'),
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                              ),
                                              Expanded(
                                                child: _searchScope == 'TV'
                                                    ? EpgGuide(
                                                        // epgId (rawId, or a
                                                        // manual override), not
                                                        // the composite `id` —
                                                        // see PlaylistManager
                                                        // .knownChannelIdsFor's
                                                        // doc comment.
                                                        channelId:
                                                            channel.epgId,
                                                        at: catchupAt)
                                                    : Text(
                                                        channel.name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                              ),
                                              _TopBarIconButton(
                                                icon: Icons.search,
                                                tooltip: tr('Search'),
                                                onPressed: () =>
                                                    Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        SearchScreen(
                                                            initialScope:
                                                                _searchScope),
                                                  ),
                                                ),
                                              ),
                                              if (_touch)
                                                _TopBarIconButton(
                                                  icon: Icons.screen_rotation,
                                                  tooltip: tr('Rotate'),
                                                  onPressed: _toggleRotation,
                                                ),
                                              if (phoneTouch)
                                                _TopBarIconButton(
                                                  icon: Icons.lock_open,
                                                  tooltip:
                                                      tr('Lock touch controls'),
                                                  onPressed: () =>
                                                      _setTouchLocked(true),
                                                ),
                                              _TopBarIconButton(
                                                icon: prefs.videoFill
                                                    ? Icons.fullscreen_exit
                                                    : Icons.fullscreen,
                                                tooltip: prefs.videoFill
                                                    ? tr('Fit to screen')
                                                    : tr('Fill screen'),
                                                onPressed: _toggleImmersive,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          if (channel.mediaFileInfo case final info?)
                            MediaFileInfoOverlay(
                              key: ValueKey('file-info-${channel.id}'),
                              top: _touch ? 72 : 16,
                              info: info,
                              requests: _fileInfoRequests,
                            ),
                          // The schedule control stays inside the compact info card.
                          Positioned(
                            top: MediaQuery.paddingOf(context).top + 48,
                            left: 0,
                            right: 0,
                            child: AnimatedOpacity(
                              opacity: _zapInfoVisible ? 1 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: IgnorePointer(
                                ignoring: !_zapInfoVisible,
                                child: ExcludeFocus(
                                  excluding: !_zapInfoVisible,
                                  child: Center(
                                      child: LiveChannelInfoCard(
                                    channel: channel,
                                    at: catchupAt,
                                    touch: _touch,
                                    scheduleFocus: _scheduleChipFocus,
                                    onScheduleKey: _onScheduleChipKey,
                                    onSchedule: _openSchedule,
                                  )),
                                ),
                              ),
                            ),
                          ),

                          // One bottom layout keeps captions above the actual panel
                          // height, including on phones and with larger text. Only
                          // build the Data pool while visible (it polls the player).
                          if (controller != null)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 48,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IgnorePointer(
                                    child:
                                        SubtitleOverlay(controller: controller),
                                  ),
                                  if (_dataPoolVisible)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 8, 16, 0),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight: MediaQuery.sizeOf(context)
                                                  .height *
                                              0.45,
                                        ),
                                        child: SingleChildScrollView(
                                          child: DataPoolCard(
                                            controller: controller,
                                            since: playback.playingSince,
                                            showFileSize: !channel.isLive &&
                                                !channel.transientPlayback,
                                            fileSizeBytes: channel
                                                .mediaFileInfo?.sizeBytes,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                          // Bottom bar: title, seek bar, play/pause.
                          if (controller != null)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: ExcludeFocus(
                                key: _bottomBarKey,
                                excluding: !_bottomVisible,
                                child: AnimatedOpacity(
                                  opacity: _bottomVisible ? 1 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: FocusTraversalGroup(
                                    child: FocusScope(
                                      node: _bottomScope,
                                      child: PlayerControls(
                                        insetForSystemBars: true,
                                        controller: controller,
                                        title: channel.name,
                                        // epgId (rawId, or a manual override), not the composite `id` —
                                        // see PlaylistManager
                                        // .knownChannelIdsFor's doc comment;
                                        // Channel.isLiveId also documents
                                        // that it expects rawId, not id.
                                        channelId: channel.epgId,
                                        isLive: channel.isLive,
                                        isFavorite: channel.isFavorite,
                                        onToggleFavorite: () =>
                                            playlist.toggleFavorite(channel),
                                        onPrevious:
                                            playback.previousUpChannel != null
                                                ? () => playback.play(
                                                    playback.previousUpChannel!)
                                                : null,
                                        onNext: playback.nextUpChannel != null
                                            ? () => playback
                                                .play(playback.nextUpChannel!)
                                            : null,
                                        onActivity: _resetHideTimer,
                                        linkedChannel: linkedChannel,
                                        channel: channel,
                                        showMore: _moreVisible,
                                        onToggleMore: () => setState(
                                            () => _moreVisible = !_moreVisible),
                                        playFocusNode: _playFocus,
                                        onOpenMultiview: channel.isLive &&
                                                !prefs.hideMultiview
                                            ? () => _openMultiview(channel)
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Fast-forward / Rewind target until it lands.
                          if (_skipTarget case final target?
                              when controller != null)
                            Positioned(
                              top: 0,
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: IgnorePointer(
                                child: Center(
                                  child: _SkipCue(
                                    target: target,
                                    live: _skipLive,
                                    position: controller.value.position,
                                    duration: controller.value.duration,
                                  ),
                                ),
                              ),
                            ),

                          if (!touchLocked)
                            SkipSegmentButton(
                              watcher: _skip,
                              controlsVisible: _bottomVisible,
                              hasNext: playback.nextUpChannel != null,
                              hint: _touch
                                  ? SkipHint.none
                                  : _bottomScope.hasFocus
                                      ? SkipHint.up
                                      : _focusInBar
                                          ? SkipHint.none
                                          : SkipHint.ok,
                              onSkip: _skipSegment,
                              focusNode: _skipFocus,
                              onDown: _focusBottomBar,
                              onUp: _watchOffer == null
                                  ? null
                                  : _watchFocus.requestFocus,
                            ),

                          if (!touchLocked)
                            WatchGameButton(
                              offer: _watchOffer,
                              // Hugs the player bar (bottom corner while the
                              // bar is hidden); above the skip pill when
                              // both show.
                              bottom: _skipShowing
                                  ? 262
                                  : _bottomVisible
                                      ? _bottomBarHeight + 8
                                      : 28,
                              showUpHint: !_touch &&
                                  _bottomScope.hasFocus &&
                                  !_skipShowing,
                              onWatch: _watchGame,
                              focusNode: _watchFocus,
                              onDown: _skipShowing
                                  ? _skipFocus.requestFocus
                                  : _focusBottomBar,
                            ),

                          if (controller != null && !touchLocked)
                            _UpNextBubble(
                              mode: context
                                  .read<StorageService>()
                                  .getUpNextMode(),
                              controller: controller,
                              nextChannel: playback.nextUpChannel,
                              onPlayNow: () {
                                final next = playback.nextUpChannel;
                                if (next != null) playback.play(next);
                              },
                              onDismiss: playback.dismissAutoAdvance,
                            ),

                          // Touch: a tab on the left edge while the bars show
                          // opens the side panel (a remote uses Left).
                          if (_touch && channel.isLive)
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: IgnorePointer(
                                ignoring: !_topVisible || _panelOpen,
                                child: AnimatedOpacity(
                                  opacity: _topVisible && !_panelOpen ? 1 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: SafeArea(
                                    right: false,
                                    child: Center(
                                      child:
                                          PlayerSidePanelTab(onTap: _openPanel),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Always Positioned (see the Stack comment above).
                          // Narrower than 400 on a portrait phone.
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: _panelOpen
                                ? math.min(PlayerSidePanel.width,
                                    MediaQuery.sizeOf(context).width * 0.88)
                                : 0,
                            child: _panelOpen
                                ? GestureDetector(
                                    // Taps on the panel's empty space mustn't
                                    // reach the video's tap-to-close.
                                    onTap: () {},
                                    child: PlayerSidePanel(
                                        current: channel, onClose: _closePanel),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          if (_scheduleOpen)
                            Positioned.fill(
                              child: ChannelSchedulePanel(
                                channel: playback.liveChannel ?? channel,
                                at: catchupAt,
                                onClose: _closeSchedule,
                                onCatchup: (start) => _playback.playCatchup(
                                    playback.liveChannel ?? channel, start),
                                onLive: () {
                                  if (_playback.catchup != null) {
                                    _playback.backToLive();
                                  }
                                },
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            )));
    // The same wrapper stays mounted through lock, rotation and PiP changes;
    // locking must never recreate the video/controller or intercept PiP's UI.
    return PlayerTouchLock(
      locked: touchLocked,
      onUnlock: () => _setTouchLocked(false),
      child: player,
    );
  }
}

/// A Netflix-style "Up Next" card in the corner of the screen once an
/// episode is close to ending — [PlaybackService] already auto-advances
/// at 30 seconds remaining; this surfaces that instead of letting it
/// happen silently, and lets the user jump immediately or cancel it for
/// this episode. Reacts to the controller directly (not `PlaybackService`,
/// which only notifies on channel/controller changes) since it needs to
/// know the position every tick, the same way the seek bar does.
class _UpNextBubble extends StatelessWidget {
  const _UpNextBubble({
    required this.mode,
    required this.controller,
    required this.nextChannel,
    required this.onPlayNow,
    required this.onDismiss,
  });

  /// [StorageService.getUpNextMode]: early / end / off (no bubble).
  final String mode;
  final VideoPlayerHdrController controller;
  final Channel? nextChannel;
  final VoidCallback onPlayNow;
  final VoidCallback onDismiss;

  static const _showAt = Duration(seconds: 45);
  static const _autoAdvanceAt = Duration(seconds: 30);

  // Every branch below returns a `Positioned`, never a bare widget — this
  // sits directly in PlayerScreen's Stack (not wrapped in Positioned at
  // the call site), and Stack's sizing rule is "size to fill the available
  // space only if EVERY child is Positioned; otherwise size to fit the
  // non-positioned children instead". A single bare `SizedBox.shrink()`
  // here (the "nothing to show" case, which is most of the time) used to
  // demote the whole Stack to a non-positioned-children layout, and since
  // that shrink box's natural size is zero, the entire Stack — video
  // included — collapsed to 0x0 and painted nothing. This was the actual
  // cause of the black fullscreen screen; confirmed via a LayoutBuilder +
  // RenderBox size dump (NOX_DIAG) showing bounded incoming constraints
  // but a 0x0 resulting Stack size.
  static const _hidden = Positioned(
      right: 24, bottom: 110, width: 0, height: 0, child: SizedBox.shrink());

  @override
  Widget build(BuildContext context) {
    final next = nextChannel;
    if (next == null || mode == 'off') return _hidden;
    final atEnd = mode == 'end';
    return ValueListenableBuilder<VideoPlayerHdrValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final duration = value.duration;
        if (duration <= Duration.zero) return _hidden;
        final remaining = duration - value.position;
        // When the episode ends: the last 15 s count down to the end.
        if (remaining > (atEnd ? const Duration(seconds: 15) : _showAt) ||
            remaining < Duration.zero) {
          return _hidden;
        }

        final countdown = (remaining - (atEnd ? Duration.zero : _autoAdvanceAt))
            .inSeconds
            .clamp(0, 999);
        final hasLogo = next.logoUrl != null && next.logoUrl!.isNotEmpty;

        return Positioned(
          right: 24,
          bottom: 110,
          width: 320,
          child: Material(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: hasLogo
                          ? CachedNetworkImage(
                              imageUrl: next.logoUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  const _UpNextFallbackIcon(),
                            )
                          : const _UpNextFallbackIcon(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(tr('Up Next'),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        Text(
                          next.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          countdown > 0
                              ? tr('Playing in {countdown}s',
                                  {'countdown': countdown})
                              : tr('Playing now...'),
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_circle_fill,
                            color: Colors.white, size: 30),
                        tooltip: tr('Play now'),
                        onPressed: onPlayNow,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white54, size: 18),
                        tooltip: tr('Dismiss'),
                        onPressed: onDismiss,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UpNextFallbackIcon extends StatelessWidget {
  const _UpNextFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade800,
      alignment: Alignment.center,
      child: const Icon(Icons.movie, color: Colors.white38, size: 28),
    );
  }
}

/// Plain [IconButton]s gave no visible cue for which of the top bar's three
/// buttons the D-pad cursor was actually on — Material's default focus
/// highlight is too subtle to read at 10-foot distance, especially over a
/// busy video background. Same highlight pattern as the rest of the TV UI
/// (Material+InkWell+onFocusChange, e.g. TvHomeScreen's _SelectableRow): a
/// solid filled circle behind the icon while focused.
class _TopBarIconButton extends StatefulWidget {
  const _TopBarIconButton(
      {required this.icon, required this.onPressed, this.tooltip});

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  State<_TopBarIconButton> createState() => _TopBarIconButtonState();
}

class _TopBarIconButtonState extends State<_TopBarIconButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Every palette now gets the same contour + gradient-sheen treatment
    // — see `TvHomeScreen._SelectableRow`'s doc comment for the full
    // story.
    final button = Padding(
      padding: const EdgeInsets.all(4),
      child: Container(
        // Always present (even with an empty shadow list) — see
        // MinimalGlassFocus's doc comment elsewhere for why a focus
        // widget's ancestor shape must stay stable across builds.
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // A flat `black87` fill here photographed as more "filled" than
          // the real diagonal sheen `_SelectableRow`/`_GroupRow` use for
          // the exact same focus state — see their doc comment.
          gradient: _focused
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black,
                    Color.lerp(Colors.black, scheme.primaryContainer, 0.4)!,
                    Colors.black,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                )
              : null,
          boxShadow: _focused
              ? [
                  BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.45),
                      blurRadius: 12)
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          shape: _focused
              ? CircleBorder(side: BorderSide(color: scheme.primary, width: 2))
              : const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onPressed,
            onFocusChange: (f) => setState(() => _focused = f),
            child: Padding(
              padding: const EdgeInsets.all(10),
              // `scheme.tertiary` — a dedicated icon/symbol-glyph accent,
              // separate from the border/gradient accent
              // (`focusForeground`) — see `buildPaletteColorScheme`'s own
              // doc comment for why (Habs: white contour, blue icons).
              child: Icon(widget.icon,
                  color: _focused ? scheme.tertiary : Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
    return widget.tooltip != null
        ? Tooltip(message: widget.tooltip!, child: button)
        : button;
  }
}

/// Where the remote's Fast-forward / Rewind will land: the target time
/// and the jump (movies, episodes, catch-up), or how far back from now
/// (live rewind).
class _SkipCue extends StatelessWidget {
  const _SkipCue(
      {required this.target,
      required this.live,
      required this.position,
      required this.duration});

  final Duration target;
  final bool live;
  final Duration position;
  final Duration duration;

  static String _clock(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final forward = !live && target >= position;
    final text = live
        ? tr('{m} min back', {'m': target.inMinutes})
        : '${_clock(target)} / ${_clock(duration)}   '
            '(${forward ? '+' : '−'}${_clock((target - position).abs())})';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(forward ? Icons.fast_forward : Icons.fast_rewind,
              color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(width: 10),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
