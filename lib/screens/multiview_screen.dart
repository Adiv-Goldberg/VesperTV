import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player_hdr/video_player_hdr.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/channel.dart';
import '../services/app_preferences.dart';
import '../services/epg_service.dart';
import '../services/multiview_sports.dart';
import '../services/playback_service.dart'
    show learnHlsHost, streamController, unlearnHlsUrl;
import '../services/playlist_manager.dart';
import '../services/real_4k_channels.dart';
import '../services/storage_service.dart';
import '../services/subtitle_tracks.dart';
import '../widgets/auto_hide_overlay.dart';
import '../widgets/game_channel_chooser.dart';
import '../widgets/hold_to_activate.dart';
import '../widgets/tv_menu_tile.dart';
import '../widgets/tv_text_field_gate.dart';
import '../l10n/l10n.dart';

/// TV-remote-first multiview grid — several live channels playing at
/// once, one with audio focus at a time. Same idea/UX as
/// `DesktopMultiviewScreen` (Windows), independently implemented here
/// against `video_player_hdr` instead of `media_kit` — there is no
/// cross-platform video engine in this app (see `pubspec.yaml`'s
/// media_kit comment), so each platform needs its own.
///
/// Worth naming plainly: `video_player_hdr` can render via a platform view
/// (adopted elsewhere in this app, see `playback_service.dart`'s own doc
/// comment, specifically to dodge an Android GPU-texture rendering bug on
/// a *single* fullscreen stream) or a plain texture. This screen uses
/// [VideoViewType.textureView], not platform views — confirmed directly on
/// real hardware (a Formuler) via a live CPU/thread dump during a glitch:
/// with 3-4 simultaneous platform views, the app alone was pegging ~94%
/// of a CPU core concentrated in the main thread/RenderThread/GC, not any
/// audio or video codec thread — the signature of Android's hybrid-
/// composition overhead for multiple concurrent platform views, not an
/// actual decode bottleneck. A plain texture is a cheap GPU blit per
/// instance instead, which is exactly the "many simultaneous small tiles"
/// shape this screen has (the opposite of the single large fullscreen
/// view platform-view rendering was adopted for elsewhere).
///
/// This re-opens a different, already-fixed bug's risk, though: this
/// app has documented history of a *shared-decode-session* texture bug on
/// real Fire Stick hardware (see `LiveResumeHint`'s doc comment — the
/// scrapped "Live Island" pill: one decode session rendered in two places
/// at once corrupted both). [_MultiviewFullscreenView] reuses a cell's
/// already-playing controller rather than starting a second decode
/// session, but the grid's own cell tile stays mounted underneath while
/// that route is pushed on top (`Navigator.push` doesn't unmount the
/// previous route) — the same two-simultaneous-consumers shape. Needs
/// real-hardware verification specifically on that promote-to-fullscreen
/// flow, the same as everything else in this app.
class MultiviewScreen extends StatefulWidget {
  const MultiviewScreen({super.key, this.initialChannel});

  /// Pre-loads cell 0 with this channel on open — set when reached from
  /// `PlayerScreen`'s own "Open in Multiview" action (see
  /// `PlayerControls.onOpenMultiview`), so a channel already being
  /// watched fullscreen becomes the first multiview cell instead of
  /// landing on an empty grid. Null for the normal entry point (the
  /// sidebar's own "Multiview" row), which still starts empty as before.
  final Channel? initialChannel;

  @override
  State<MultiviewScreen> createState() => _MultiviewScreenState();
}

// Audio swap history (don't re-learn): switching the audio *track* off/on
// in place (`setAudioTrackTypeDisabled`) was tried twice and destabilized
// the cell both times — re-enabling audio mid-play re-runs track selection,
// the audio renderer takes over the playback clock (frozen frame + looping
// audio) and on a progressive live .ts stream it can force a reload. The
// workaround that replaced it — recreating *both* cells on every swap —
// cost two disconnects + two reconnects per Select press, colliding with
// the provider's connection limit. Swapping now only changes *volume*
// (TiviMate-style): both cells keep their audio track and their connection.
// The old reasons volume couldn't be used are gone: AC3 passthrough
// ignoring setVolume was fixed by the context-less AudioSink (24f7bcd), and
// the audio-mixer overload was seen with 3-4 cells + PREFER mode, both
// removed since (dbc88fc).

class _MultiviewCell {
  Channel? channel;
  VideoPlayerHdrController? controller;
  final FocusNode focusNode = FocusNode(debugLabel: 'multiview-cell');
}

/// 2 stacked screens (default) or a 2x2 grid of 4. The 4-screen grid was
/// removed once because cells kept freezing; that was traced (2026-10) to
/// provider accounts with fewer connections than open screens (they kick
/// each other off) plus plugin bugs since fixed — with enough connections
/// 2 screens ran clean for 25+ min on a Fire Stick. So it's back as an
/// option, with the connection rule explained in [_showTips]. All 4 cells
/// stay allocated; switching to 2 disposes cells 2-3 to free their
/// connections and decoders rather than just hiding them.
/// [main] ("1 + 3"): one big screen (cell 0) on the left, cells 1-3
/// stacked on the right — each a third of the height at half the big
/// one's width, so all four stay 16:9 on a 16:9 TV (owner request,
/// 2026-10-27).
enum _MultiviewLayout { dual, quad, main }

class _MultiviewScreenState extends State<MultiviewScreen> {
  static const _cellCount = 4;
  final List<_MultiviewCell> _cells =
      List.generate(_cellCount, (_) => _MultiviewCell());
  int _activeCell = 0;
  _MultiviewLayout _layout = _MultiviewLayout.dual;

  /// The header (back, 2/4 screens, the audio hint) is an overlay, not a
  /// row: it took height from the grid and squashed the 2x2 tiles (user
  /// report, 2026-10-19). It slides down on Up from the top row (or a tap
  /// on the handle, touch/mouse), shows for a few seconds on entering so
  /// it's discoverable, and slides away once focus leaves it.
  bool _headerShown = true;
  Timer? _headerTimer;
  final _headerScope = FocusScopeNode(debugLabel: 'multiview-header');
  final _headerFirst = FocusNode(debugLabel: 'multiview-header-first');

  void _revealHeader({bool focus = false}) {
    _headerTimer?.cancel();
    if (!_headerShown) setState(() => _headerShown = true);
    if (focus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _headerFirst.requestFocus();
      });
    } else {
      _hideHeaderSoon(const Duration(seconds: 4));
    }
  }

  void _hideHeaderSoon([Duration after = const Duration(milliseconds: 1500)]) {
    _headerTimer?.cancel();
    _headerTimer = Timer(after, () {
      if (mounted && !_headerScope.hasFocus && _headerShown) {
        setState(() => _headerShown = false);
      }
    });
  }

  void _onHeaderFocus() {
    if (_headerScope.hasFocus) {
      _headerTimer?.cancel();
    } else {
      _hideHeaderSoon();
    }
  }

  /// Up from a top-row screen opens the header (nothing is above it now).
  KeyEventResult _onGridKey(FocusNode node, KeyEvent e, int topRow) {
    if (_swapMode) return _onSwapKey(e);
    if (e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.arrowUp) {
      return KeyEventResult.ignored;
    }
    final i = _cells.indexWhere((c) => c.focusNode.hasFocus);
    if (i < 0 || i >= topRow) return KeyEventResult.ignored;
    _revealHeader(focus: true);
    return KeyEventResult.handled;
  }

  /// Portrait phone: always the 2 stacked screens (owner, 2026-10-19 — a
  /// 2x2 grid of tiny tiles on a narrow screen). The saved 4-screen choice
  /// stays; screens 3-4 are paused (not dropped) until it's rotated back.
  bool _portraitDual = false;

  Future<void> _setPortraitDual(bool on) async {
    if (on == _portraitDual || !mounted) return;
    setState(() {
      _portraitDual = on;
      if (on) _swapMode = false;
    });
    if (on && _activeCell >= 2) {
      final i = _cells[0].channel != null ? 0 : 1;
      if (_cells[i].channel != null) await _setActive(i);
    }
    for (var i = 2; i < _cellCount; i++) {
      final c = _cells[i].controller;
      if (c == null) continue;
      await (on ? c.pause() : c.play());
    }
  }

  /// 2 screens -> 4 -> 1 + 3 -> 2 (remembered).
  void _toggleLayout() {
    final next = switch (_layout) {
      _MultiviewLayout.dual => _MultiviewLayout.quad,
      _MultiviewLayout.quad => _MultiviewLayout.main,
      _MultiviewLayout.main => _MultiviewLayout.dual,
    };
    if (next == _MultiviewLayout.dual) {
      for (var i = 2; i < _cellCount; i++) {
        final cell = _cells[i];
        final old = cell.controller;
        cell.channel = null;
        cell.controller = null;
        unawaited(old?.dispose());
      }
      if (_activeCell >= 2) {
        _activeCell = 0;
        unawaited(_cells[0].controller?.setVolume(1.0));
      }
    }
    setState(() {
      _layout = next;
      _swapMode = false;
    });
    final storage = context.read<StorageService>();
    unawaited(storage.setMultiviewQuad(next == _MultiviewLayout.quad));
    unawaited(storage.setMultiviewMain(next == _MultiviewLayout.main));
  }

  /// 1 + 3: swaps a small screen with the big one (streams, sound and all;
  /// nothing reconnects).
  void _moveToMain(int index) {
    if (index == 0) return;
    final a = _cells[0], b = _cells[index];
    final channel = a.channel, controller = a.controller;
    a
      ..channel = b.channel
      ..controller = b.controller;
    b
      ..channel = channel
      ..controller = controller;
    if (_activeCell == index) {
      _activeCell = 0;
    } else if (_activeCell == 0) {
      _activeCell = index;
    }
    setState(() {});
    a.focusNode.requestFocus();
  }

  /// 1 + 3 Swap mode (TiviMate-style, owner 2026-10-29): the D-pad rotates
  /// the playing screens through the big one (Down/Right = next, Up/Left =
  /// previous), the sound always on the big screen. Same controller moves
  /// as [_moveToMain], so nothing reconnects. OK or Back ends it.
  bool _swapMode = false;

  /// Bumped on every swap: the big tile flashes once.
  int _swapCount = 0;

  bool get _canSwap =>
      _layout == _MultiviewLayout.main &&
      !_portraitDual &&
      _cells.where((c) => c.channel != null && c.controller != null).length >=
          2;

  void _enterSwapMode() {
    if (!_canSwap) return;
    // A playing screen on the big one first.
    if (_cells[0].channel == null || _cells[0].controller == null) {
      _moveToMain(
          _cells.indexWhere((c) => c.channel != null && c.controller != null));
    }
    setState(() => _swapMode = true);
    _setSwapAudio();
    _cells[0].focusNode.requestFocus();
    _hideHeaderSoon(Duration.zero);
  }

  void _exitSwapMode() {
    if (_swapMode) setState(() => _swapMode = false);
  }

  /// Moves every playing screen [step] places through the big one; empty or
  /// still-loading slots stay put (a loading [_assign] writes back by index).
  void _rotateSwap(int step) {
    final slots = [
      for (var i = 0; i < _cellCount; i++)
        if (_cells[i].channel != null && _cells[i].controller != null) i
    ];
    if (slots.length < 2) return;
    final order = swapRotation(slots, step);
    final moved = [
      for (final from in order) (_cells[from].channel, _cells[from].controller)
    ];
    for (var k = 0; k < slots.length; k++) {
      _cells[slots[k]]
        ..channel = moved[k].$1
        ..controller = moved[k].$2;
    }
    setState(() => _swapCount++);
    if (_swapMode) _setSwapAudio();
  }

  /// Swap mode: only the big screen plays sound.
  void _setSwapAudio() {
    _activeCell = 0;
    for (var i = 0; i < _cellCount; i++) {
      unawaited(_cells[i].controller?.setVolume(i == 0 ? 1.0 : 0.0));
    }
  }

  KeyEventResult _onSwapKey(KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final key = e.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowRight) {
      _rotateSwap(1);
    } else if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowLeft) {
      _rotateSwap(-1);
    } else {
      return KeyEventResult.ignored;
    }
    _cells[0].focusNode.requestFocus();
    return KeyEventResult.handled;
  }

  /// Shown on entering Multiview until the user ticks "Don't show this
  /// again" — replaced the old always-on sidebar caveats (requested
  /// directly), which cost the grid width.
  Future<void> _showTips() async {
    final storage = context.read<StorageService>();
    if (storage.getMultiviewHideTips()) return;
    var dontShow = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.amber),
              const SizedBox(width: 8),
              Text(tr('Before you start'),
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Every screen in Multiview is its own connection to your provider. Your playlist must allow at least as many connections as screens you open (see Max connections in Playlist Manager).\n\nIf two screens share an account that allows only one connection, they keep kicking each other off and will freeze or buffer. Tip: use channels from different playlists, one per account.\n\nA screen that freezes restarts on its own. If it doesn\'t, hold Select on it and choose Reload.'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: dontShow,
                  onChanged: (v) => setDialogState(() => dontShow = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('Don\'t show this again'),
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(tr('OK')),
            ),
          ],
        ),
      ),
    );
    if (dontShow) await storage.setMultiviewHideTips(true);
  }

  /// The cell index currently promoted to [_MultiviewFullscreenView], if
  /// any — see [_openFullscreen]'s own doc comment for why its grid tile
  /// needs to stop rendering its own video widget for as long as that's
  /// true.
  int? _promotedCell;

  @override
  void initState() {
    super.initState();
    // Keep the screen awake for the whole Multiview session. PlaybackService
    // only does this for the main player, and "Open in Multiview" stops that
    // player first (which releases its wakelock) — a Fire Stick fell into
    // its screensaver mid-test.
    unawaited(WakelockPlus.enable());
    _statsTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _logTiles());
    _headerScope.addListener(_onHeaderFocus);
    _hideHeaderSoon(const Duration(seconds: 4));
    final storage = context.read<StorageService>();
    if (storage.getMultiviewMain()) {
      _layout = _MultiviewLayout.main;
    } else if (storage.getMultiviewQuad()) {
      _layout = _MultiviewLayout.quad;
    }
    final initial = widget.initialChannel;
    if (initial != null) unawaited(_assign(0, initial));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _cells[0].focusNode.requestFocus();
      await _showTips();
      if (mounted) _cells[0].focusNode.requestFocus();
    });
  }

  /// Send log: one line per playing screen every 10 s (buffer, freezes,
  /// frames shown per second, dropped frames), to tell a provider that
  /// runs dry from a box that can't decode/draw every screen.
  Timer? _statsTimer;
  static const _stats = MethodChannel('vespertv/stats');
  final _lastRendered = <VideoPlayerHdrController, int>{};
  final _lastDropped = <VideoPlayerHdrController, int>{};

  Future<void> _logTiles() async {
    for (var i = 0; i < _cells.length; i++) {
      final c = _cells[i].controller;
      if (c == null || !c.value.isInitialized) continue;
      try {
        final m = await _stats.invokeMapMethod<Object?, Object?>(
            'getStats', {'playerId': SubtitleTracks.playerIdOf(c)});
        if (m == null || !mounted) return;
        int n(String k) => (m[k] as num?)?.toInt() ?? 0;
        final rendered = n('rendered'), dropped = n('dropped');
        final fps = (rendered - (_lastRendered[c] ?? rendered)) / 10;
        final newDrops = dropped - (_lastDropped[c] ?? dropped);
        _lastRendered[c] = rendered;
        _lastDropped[c] = dropped;
        debugPrint('Multiview: screen ${i + 1} ${_cells[i].channel?.name}: '
            'buffer ${(n('bufferedMs') / 1000).toStringAsFixed(1)} s, '
            'freezes ${n('stalls')} (last ${(n('lastStallMs') / 1000).toStringAsFixed(1)} s), '
            '${fps.toStringAsFixed(1)} fps, dropped +$newDrops, '
            '${n('height')}p${c.value.isBuffering ? ', buffering now' : ''}');
      } on MissingPluginException {
        _statsTimer?.cancel();
        return;
      } on PlatformException {
        // Screen changed between the check and the call.
      }
    }
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _headerTimer?.cancel();
    _headerScope.removeListener(_onHeaderFocus);
    _headerScope.dispose();
    _headerFirst.dispose();
    for (final cell in _cells) {
      cell.controller?.dispose();
      cell.focusNode.dispose();
    }
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  /// Deliberately the *opposite* order from `PlaybackService
  /// .reloadCurrentChannel`'s own "build the replacement fully before
  /// touching the old one" technique — that avoids a black flash when
  /// there's only ever one stream playing, but here several cells are
  /// already decoding at once, close to this hardware's own concurrent-
  /// decoder-session ceiling. Keeping the old controller alive while the
  /// new one initializes briefly needs N+1 simultaneous sessions instead
  /// of N — reported directly as tipping a completely different,
  /// already-stable cell into freezing as a result of reloading or
  /// swapping an unrelated one. Disposing the old controller first here
  /// instead, accepting a brief black flash on the cell actually being
  /// touched, is the safer trade-off once multiview is already this
  /// close to the hardware's real limit.
  Future<void> _assign(int index, Channel channel) async {
    final cell = _cells[index];
    if (cell.controller != null) {
      final old = cell.controller;
      setState(() => cell.controller = null);
      await old!.dispose();
    }
    // mixWithOthers: true — defaults to false, which lets this new
    // controller's own initialize()/play() request *exclusive* Android
    // audio focus even though it's about to be muted for every cell but
    // the active one. That exclusive request is itself enough to make
    // the system silently pause whichever controller actually held
    // focus — reported directly as exactly this: reloading one (muted
    // or not) cell froze the *other*, audio-focused one specifically,
    // not a random sibling, which pointed at audio focus rather than
    // the video decode/rendering path itself.
    final newController = streamController(
      channel.url,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await newController.initialize(viewType: VideoViewType.textureView);
      if (!mounted) {
        unawaited(newController.dispose());
        return;
      }
      // The live list's 4K tag, from what this tile really decodes.
      unawaited(Future<void>.delayed(const Duration(seconds: 6), () {
        if (cell.controller != newController) return;
        final size = newController.value.size;
        Real4kChannels.record(
            channel.id, size.width.round(), size.height.round());
      }));
      await newController.setVolume(index == _activeCell ? 1.0 : 0.0);
      await newController.play();
      setState(() {
        cell.channel = channel;
        cell.controller = newController;
      });
    } catch (e) {
      unawaited(newController.dispose());
      // A `.ts` that was really HLS (see learnHlsHost): once more as HLS;
      // or one wrongly opened as HLS (unlearnHlsUrl): once more as TS.
      if ((await learnHlsHost(channel.url, e) ||
              unlearnHlsUrl(channel.url, e)) &&
          mounted) {
        return _assign(index, channel);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('Couldn\'t start that channel'))));
      }
    }
  }

  /// The "Reload" action — see `PlayerControls`' own Reload button /
  /// `PlaybackService.reloadCurrentChannel`'s doc comment for why a
  /// manual relaunch (not an automatic watchdog) is this app's
  /// established fix for a channel that's silently stalled (frozen
  /// frame, no spinner, no error). Requested directly for every
  /// multiview cell for the same reason.
  Future<void> _reload(int index) async {
    final channel = _cells[index].channel;
    if (channel != null) await _assign(index, channel);
  }

  void _clear(int index) {
    final cell = _cells[index];
    final old = cell.controller;
    setState(() {
      cell.channel = null;
      cell.controller = null;
      _swapMode = false;
    });
    unawaited(old?.dispose());
  }

  /// Moves audio to [index] by volume alone — no reconnect, no track
  /// change (see the "Audio swap history" note at the top of this file).
  /// A no-op if [index] is already the active cell.
  Future<void> _setActive(int index) async {
    if (_cells[index].channel == null) return;
    final previousActive = _activeCell;
    if (previousActive == index) return;
    setState(() => _activeCell = index);
    await Future.wait([
      if (_cells[previousActive].controller != null)
        _cells[previousActive].controller!.setVolume(0.0),
      if (_cells[index].controller != null)
        _cells[index].controller!.setVolume(1.0),
    ]);
  }

  /// True while a picker push is already in flight — [HoldToActivate]'s
  /// own doc comment documents a real, confirmed-on-hardware class of bug
  /// this guards against: a single remote Select press occasionally
  /// reaching both its own synthesized `onTap` *and* the wrapped
  /// `InkWell`'s ambient keyboard-Activate handling, firing the callback
  /// twice. Reported directly here as exactly that shape of symptom — a
  /// flash, then the picker list still showing instead of the grid — a
  /// second `Navigator.push` stacking a second copy of the picker on top
  /// of the first, so popping one just reveals the other underneath. This
  /// makes a second call a no-op instead of a second push, regardless of
  /// what actually triggered it.
  bool _openingPicker = false;

  Future<void> _openPicker(int index) async {
    if (_openingPicker) return;
    _openingPicker = true;
    try {
      final playlist = context.read<PlaylistManager>();
      final channels = playlist.visibleChannels(category: 'tv');
      final chosen = await Navigator.of(context).push<Channel>(
        MaterialPageRoute(
            builder: (_) => _ChannelPickerScreen(channels: channels)),
      );
      if (chosen != null) await _assign(index, chosen);
    } finally {
      _openingPicker = false;
    }
  }

  /// Remote hardware has no separate "swap"/"remove" buttons to aim a
  /// D-pad at the way the Windows screen's mouse-driven icons do — a
  /// held Select (see [HoldToActivate]) opens this instead, the same
  /// "hold for more options" convention the live channel list and the
  /// Timeline guide's program blocks already use elsewhere in this app.
  Future<void> _showCellActions(int index) async {
    if (_cells[index].channel == null) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      // Six rows didn't fit the default sheet height on a TV (Remove was cut
      // off, owner photo 2026-10-29): taller allowed, compact rows, scrolls
      // (D-pad focus scrolls the row into view).
      isScrollControlled: true,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: ListTileTheme(
            dense: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.fullscreen, color: Colors.white),
                  title: Text(tr('Full screen'),
                      style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.of(sheetContext).pop('fullscreen'),
                ),
                if (_layout == _MultiviewLayout.main &&
                    !_portraitDual &&
                    index != 0)
                  ListTile(
                    leading:
                        const Icon(Icons.open_in_full, color: Colors.white),
                    title: Text(tr('Move to the big screen'),
                        style: const TextStyle(color: Colors.white)),
                    onTap: () => Navigator.of(sheetContext).pop('main'),
                  ),
                if (_canSwap && !_swapMode)
                  ListTile(
                    leading: const Icon(Icons.swap_vert, color: Colors.white),
                    title: Text(tr('Swap mode'),
                        style: const TextStyle(color: Colors.white)),
                    onTap: () => Navigator.of(sheetContext).pop('swapMode'),
                  ),
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.white),
                  title: Text(tr('Reload'),
                      style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.of(sheetContext).pop('reload'),
                ),
                ListTile(
                  leading: const Icon(Icons.swap_horiz, color: Colors.white),
                  title: Text(tr('Change channel'),
                      style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.of(sheetContext).pop('swap'),
                ),
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.white),
                  title: Text(tr('Remove'),
                      style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.of(sheetContext).pop('remove'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    switch (action) {
      case 'fullscreen':
        await _openFullscreen(index);
      case 'main':
        _moveToMain(index);
      case 'swapMode':
        _enterSwapMode();
      case 'reload':
        await _reload(index);
      case 'swap':
        await _openPicker(index);
      case 'remove':
        _clear(index);
    }
  }

  /// Reuses the cell's already-playing controller rather than starting a
  /// second decode session for the same stream — this box is already
  /// close to its real concurrent-decoder ceiling (see `_assign`'s doc
  /// comment), so a fullscreen view is just a bigger window onto the same
  /// session, not a new one. A plain `Navigator.push` (no `PopScope`
  /// override here) means Back simply pops this route, landing back on
  /// the multiview grid underneath with that same controller still
  /// playing — requested directly ("back should bring us to the multi
  /// view").
  Future<void> _openFullscreen(int index) async {
    final cell = _cells[index];
    final channel = cell.channel;
    if (channel == null) return;
    // Fullscreen carries the audio — a volume swap, the stream itself keeps
    // playing (see _setActive).
    await _setActive(index);
    final controller = cell.controller;
    if (!mounted || controller == null) return;
    // Now that this screen uses textureView (see this file's own top doc
    // comment), the grid tile staying mounted underneath while
    // [_MultiviewFullscreenView] renders the exact same controller on top
    // is the known shared-decode-session bug's shape — two simultaneous
    // consumers of the same texture. Suppressing the grid tile's own
    // video widget for the promoted index (it falls back to the existing
    // "no controller" placeholder) avoids that outright, regardless of
    // view type.
    setState(() => _promotedCell = index);
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          _MultiviewFullscreenView(channel: channel, controller: controller),
    ));
    if (mounted) setState(() => _promotedCell = null);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back ends Swap mode first.
      canPop: !_swapMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitSwapMode();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    final size = MediaQuery.sizeOf(context);
    final portrait = size.height > size.width;
    if (portrait != _portraitDual) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _setPortraitDual(portrait));
    }
    final quad = _layout == _MultiviewLayout.quad && !portrait;
    final main = _layout == _MultiviewLayout.main && !portrait;
    // Quad / 1 + 3: a 2 px seam between the tiles, nearly edge to edge.
    // In 1 + 3 the small tiles fill their slot; the big one keeps the
    // video's shape (centred, bars above and below).
    Widget cell(int i) => Padding(
        padding: EdgeInsets.all(quad || main ? 1 : 3),
        child: _buildCell(i, quad || (main && i != 0),
            widthBoost: main && i == 0 ? 1.0 : 1.15));
    // Below a phone's status bar (the back arrow sat under the clock,
    // owner 2026-11-02); the gradient still reaches the top edge.
    final inset = MediaQuery.paddingOf(context);
    final header = Container(
      padding: EdgeInsets.fromLTRB(
          4 + inset.left, 4 + inset.top, 12 + inset.right, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.92),
            Colors.black.withValues(alpha: 0.75),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: Focus(
        // Listen-only (see the grid's Focus below).
        canRequestFocus: false,
        skipTraversal: true,
        // Down from the header: back to the top row.
        onKeyEvent: (_, e) {
          if (e is KeyDownEvent &&
              e.logicalKey == LogicalKeyboardKey.arrowDown) {
            _cells[0].focusNode.requestFocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Row(
          children: [
            IconButton(
              tooltip: tr('Back'),
              focusNode: portrait ? _headerFirst : null,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Text(tr('Multiview'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            // Toggles 2 <-> 4 screens (remembered). Reached with Up from
            // the top row of screens. Not in portrait (always 2 there).
            if (!portrait)
              TextButton.icon(
                focusNode: _headerFirst,
                onPressed: _toggleLayout,
                icon: Icon(
                    quad
                        ? Icons.grid_view
                        : main
                            ? Icons.view_quilt
                            : Icons.view_agenda,
                    color: Colors.white,
                    size: 18),
                label: Text(
                    quad
                        ? tr('4 screens')
                        : main
                            ? tr('1 + 3 screens')
                            : tr('2 screens'),
                    style: const TextStyle(color: Colors.white)),
              ),
            if (main && _canSwap)
              TextButton.icon(
                onPressed: _enterSwapMode,
                icon:
                    const Icon(Icons.swap_vert, color: Colors.white, size: 18),
                label: Text(tr('Swap mode'),
                    style: const TextStyle(color: Colors.white)),
              ),
            const Spacer(),
            const Icon(Icons.volume_up, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                  tr('= audio — Select to switch, hold Select for options'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
    final isTv = context.read<AppPreferences>().isTelevision;
    return Stack(
      children: [
        // A fixed Row/Column+Expanded layout, not GridView — GridView is a
        // Scrollable, and its `childAspectRatio: 16/9` didn't exactly match
        // every real TV's available height, making it scrollable by a few
        // pixels; D-pad focus moving to the bottom row then scrolled the top
        // row partly off-screen. Row/Column+Expanded always exactly fills
        // the space, with nothing left to scroll.
        Positioned.fill(
          child: Focus(
            // Listen-only: it only hears keys bubbling up from the focused
            // tile. Focusable (the default), D-pad traversal could land on
            // this invisible grid-sized node instead of the next tile, and
            // the remote looked stuck (Fire Stick, 2026-10-20).
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: (node, e) => _onGridKey(node, e, quad || main ? 2 : 1),
            child: Padding(
              padding: EdgeInsets.all(quad || main ? 2 : 6),
              child: main
                  ? Row(
                      children: [
                        Expanded(flex: 2, child: cell(0)),
                        Expanded(
                          child: Column(children: [
                            Expanded(child: cell(1)),
                            Expanded(child: cell(2)),
                            Expanded(child: cell(3)),
                          ]),
                        ),
                      ],
                    )
                  : quad
                      ? Column(
                          children: [
                            Expanded(
                                child: Row(children: [
                              Expanded(child: cell(0)),
                              Expanded(child: cell(1)),
                            ])),
                            Expanded(
                                child: Row(children: [
                              Expanded(child: cell(2)),
                              Expanded(child: cell(3)),
                            ])),
                          ],
                        )
                      // 2 screens are stacked (Column), not side-by-side —
                      // requested directly: left/right halves squeeze each cell
                      // into a tall near-square, distorting widescreen video.
                      // Flex 13:7 when only one cell has a channel gives the
                      // occupied row 65% of the height (1.3x an even split,
                      // requested as "bigger by 30%"); both filled = even split.
                      : Column(
                          children: [
                            Expanded(
                                flex: _cells[0].channel != null ? 13 : 7,
                                child: cell(0)),
                            Expanded(
                                flex: _cells[1].channel != null ? 13 : 7,
                                child: cell(1)),
                          ],
                        ),
            ),
          ),
        ),
        if (_swapMode && main)
          Positioned(
            left: 0,
            width: size.width * 2 / 3,
            // Centred in the band under the big (16:9) screen.
            bottom: math.max(8.0,
                ((size.height - size.width * 2 / 3 * 9 / 16) / 2 - 36) / 2),
            child: const Center(child: _SwapModePill()),
          ),
        // Touch / mouse: a small handle opens the header (no Up key there).
        if (!isTv && !_headerShown)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _revealHeader,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: const Icon(Icons.expand_more,
                      color: Colors.white70, size: 20),
                ),
              ),
            ),
          ),
        // TV: the header is hidden on purpose, so a small Up arrow hints
        // it's there (users didn't know about the 4-screen layout). Up from
        // a top-row screen opens it (_onGridKey).
        if (isTv && !_headerShown)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: const Icon(Icons.keyboard_arrow_up,
                      color: Colors.white70, size: 20),
                ),
              ),
            ),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: !_headerShown,
            child: AnimatedSlide(
              offset: _headerShown ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 220),
              child: ExcludeFocus(
                excluding: !_headerShown,
                child: FocusScope(node: _headerScope, child: header),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCell(int index, bool fill, {double widthBoost = 1.15}) {
    final cell = _cells[index];
    final active = index == _activeCell && cell.channel != null;
    void onTap() {
      if (_swapMode) {
        // OK on the big one ends Swap mode; a tap on a small one moves it up.
        if (index == 0) {
          _exitSwapMode();
        } else if (cell.channel != null && cell.controller != null) {
          _moveToMain(index);
          _setSwapAudio();
          setState(() => _swapCount++);
        }
        return;
      }
      cell.channel == null ? _openPicker(index) : _setActive(index);
    }

    return HoldToActivate(
      onTap: onTap,
      onHold: cell.channel == null ? null : () => _showCellActions(index),
      child: _MultiviewCellTile(
        focusNode: cell.focusNode,
        channel: cell.channel,
        // null (not cell.controller) while this exact cell is promoted to
        // fullscreen — see _openFullscreen's own doc comment.
        controller: index == _promotedCell ? null : cell.controller,
        active: active,
        onTap: onTap,
        onLongPress:
            cell.channel == null ? null : () => _showCellActions(index),
        // Stacked 2-screen rows are much wider than 16:9: a 1.15 boost.
        // Quad: each tile fills its whole quarter (owner, 2026-10-19: on a
        // wide phone the 16:9-ish tiles left black bars at the sides; on a
        // TV the quarters are close to 16:9 anyway).
        widthBoost: widthBoost,
        fill: fill,
        alignment: Alignment.center,
        badge:
            _swapMode && index == 0 ? _SwapModeBadge(swaps: _swapCount) : null,
      ),
    );
  }
}

/// The order Swap mode moves the playing [slots] (cell indices, big one
/// first) into: slot k gets the screen from the returned k-th index.
@visibleForTesting
List<int> swapRotation(List<int> slots, int step) {
  final n = slots.length;
  return [for (var k = 0; k < n; k++) slots[((k + step) % n + n) % n]];
}

/// Swap mode on the big screen: a gold flash over the tile on every swap.
class _SwapModeBadge extends StatefulWidget {
  const _SwapModeBadge({required this.swaps});

  final int swaps;

  @override
  State<_SwapModeBadge> createState() => _SwapModeBadgeState();
}

class _SwapModeBadgeState extends State<_SwapModeBadge>
    with SingleTickerProviderStateMixin {
  late final _flash = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void didUpdateWidget(_SwapModeBadge old) {
    super.didUpdateWidget(old);
    if (widget.swaps != old.swaps) _flash.forward(from: 0);
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _flash,
            builder: (_, __) => _flash.isAnimating
                ? ColoredBox(
                    color: Colors.amber
                        .withValues(alpha: 0.35 * (1 - _flash.value)))
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Swap mode's blinking "SWAP" pill, in the black band under the big screen
/// (owner, 2026-10-29: inside the picture it covered the score bar; the
/// first blink rate was too fast).
class _SwapModePill extends StatefulWidget {
  const _SwapModePill();

  @override
  State<_SwapModePill> createState() => _SwapModePillState();
}

class _SwapModePillState extends State<_SwapModePill>
    with SingleTickerProviderStateMixin {
  late final _blink = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: Tween(begin: 0.35, end: 1.0).animate(_blink),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            border: Border.all(color: Colors.amber, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_vert, color: Colors.amber, size: 20),
              const SizedBox(width: 6),
              Text(tr('SWAP'),
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
              const SizedBox(width: 10),
              Text(tr('Arrows swap · OK or Back to finish'),
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MultiviewCellTile extends StatefulWidget {
  const _MultiviewCellTile({
    required this.focusNode,
    required this.channel,
    required this.controller,
    required this.active,
    required this.onTap,
    required this.onLongPress,
    required this.widthBoost,
    this.alignment = Alignment.center,
    this.fill = false,
    this.badge,
  });

  /// Drawn over the video (Swap mode's pill on the big screen).
  final Widget? badge;

  /// Fill the whole slot instead of an aspect-locked frame (quad).
  final bool fill;

  /// Where the ratio-locked frame sits in its slot (quad: toward the centre).
  final Alignment alignment;
  final FocusNode focusNode;
  final Channel? channel;
  final VideoPlayerHdrController? controller;
  final bool active;

  /// How far past the video's true aspect ratio the frame is stretched — see
  /// [_MultiviewCellTileState.build]. Small in the 2x2 layout, whose quarter
  /// cells are only a little wider than 16:9.
  final double widthBoost;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<_MultiviewCellTile> createState() => _MultiviewCellTileState();
}

class _MultiviewCellTileState extends State<_MultiviewCellTile> {
  bool _focused = false;

  Widget _withBadge(Widget tile) => widget.badge == null
      ? tile
      : Stack(fit: StackFit.expand, children: [tile, widget.badge!]);

  @override
  Widget build(BuildContext context) {
    // The frame (border included) is aspect-constrained to the video's own
    // ratio, not just the video inside it — requested directly. (An earlier
    // version was reverted for looking "noticeably smaller" next to the
    // quad grid; quad was then removed, and is back as an option with no
    // width boost — its quarter cells are already about 16:9.)
    // (A wider-than-native frame with a BoxFit.cover crop was tried first
    // to also widen the picture itself, but VideoPlayerHdr has no
    // intrinsic size for FittedBox to scale from — it rendered blank.)
    //
    // Stacked top/bottom means each cell's available box is much wider
    // than 16:9 (roughly screen-width by half-screen-height) — a strict
    // native-ratio frame leaves real unused width on both sides, visibly
    // marked up directly on a real screenshot and confirmed as worth
    // reclaiming even at the cost of some stretch, explicitly *not* full
    // edge-to-edge ("probably not as much but enough"). `widthBoost`
    // widens the locked ratio beyond the video's true shape — since this
    // widget's own `Stack(fit: StackFit.expand, ...)` below has no
    // internal letterboxing (the frame IS the video's rendered shape),
    // this genuinely stretches the picture by that same factor rather
    // than just growing empty frame around it. 1.15 was picked as a
    // first, modest value to judge on real hardware, not a measured
    // "right" number — tune directly if it reads as too stretched or not
    // enough once seen on the actual screen.
    final ratio =
        (widget.controller != null && widget.controller!.value.aspectRatio != 0
                ? widget.controller!.value.aspectRatio
                : 16 / 9) *
            widget.widthBoost;
    return Align(
      alignment: widget.alignment,
      child: _MaybeAspect(
        ratio: widget.fill ? null : ratio,
        child: InkWell(
          focusNode: widget.focusNode,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onFocusChange: (f) => setState(() => _focused = f),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.active
                    ? Colors.amber
                    : (_focused ? Colors.white : Colors.white24),
                width: widget.active || _focused ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            // The name bar fades after a few seconds (it covered the
            // score bug): shown again on a new channel, when the sound
            // moves here, and when focus lands on the tile.
            child: _withBadge(AutoHideOverlay(
              flashKey: (widget.channel?.id, widget.active, _focused),
              hidden: widget.active ? const MultiviewAudioBadge() : null,
              video: widget.controller != null &&
                      widget.controller!.value.isInitialized
                  ? VideoPlayerHdr(widget.controller!,
                      key: ObjectKey(widget.controller))
                  : ColoredBox(
                      color: const Color(0xFF1A1A1A),
                      child: Center(
                        child: Icon(
                            widget.channel == null
                                ? Icons.add_circle_outline
                                : Icons.hourglass_empty,
                            color: Colors.white38,
                            size: 36),
                      ),
                    ),
              overlay: widget.channel == null
                  ? const SizedBox.shrink()
                  : Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        // Was a 2-stop gradient fading to transparent almost
                        // immediately — reported directly as barely visible
                        // against a bright/busy video frame. A mid-bar stop
                        // keeps the whole header solidly dark (not just its
                        // very top edge) before fading out underneath it, and
                        // the text itself now carries its own shadow as a
                        // second, independent line of contrast — the same
                        // "readable over anything behind it" fix already used
                        // elsewhere in this app (e.g. PosterCard's progress
                        // label) rather than relying on the backdrop alone.
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.6, 1.0],
                            colors: [
                              Colors.black.withValues(alpha: 0.92),
                              Colors.black.withValues(alpha: 0.92),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            if (widget.active) ...[
                              const Icon(Icons.volume_up,
                                  color: Colors.amber,
                                  size: 15,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 4)
                                  ]),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                widget.channel!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(color: Colors.black, blurRadius: 4)
                                    ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            )),
          ),
        ),
      ),
    );
  }
}

/// An [AspectRatio] frame, or the whole slot when [ratio] is null (quad
/// tiles fill their quarter).
class _MaybeAspect extends StatelessWidget {
  const _MaybeAspect({required this.ratio, required this.child});

  final double? ratio;
  final Widget child;

  @override
  Widget build(BuildContext context) => ratio == null
      ? SizedBox.expand(child: child)
      : AspectRatio(aspectRatio: ratio!, child: child);
}

/// Pushed from a cell's hold-Select menu ("Full screen") — reuses that
/// cell's already-playing `VideoPlayerHdrController` instead of starting a
/// second decode session for the same stream. Popping (Back) just returns
/// to the multiview grid underneath, where the same controller is still
/// playing, unaffected.
class _MultiviewFullscreenView extends StatefulWidget {
  const _MultiviewFullscreenView(
      {required this.channel, required this.controller});

  final Channel channel;
  final VideoPlayerHdrController controller;

  @override
  State<_MultiviewFullscreenView> createState() =>
      _MultiviewFullscreenViewState();
}

class _MultiviewFullscreenViewState extends State<_MultiviewFullscreenView> {
  final _backFocus = FocusNode();

  /// The channel name and back arrow fade after a few seconds (they sat
  /// over the game — user report, 2026-10-19); any key or tap brings them
  /// back. While hidden, the first OK only reveals (it must not press the
  /// hidden back arrow); Back itself always works.
  bool _overlay = true;
  Timer? _overlayTimer;

  void _showOverlay() {
    _overlayTimer?.cancel();
    if (!_overlay) setState(() => _overlay = true);
    _overlayTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _overlay = false);
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final back = k == LogicalKeyboardKey.goBack ||
        k == LogicalKeyboardKey.escape ||
        k == LogicalKeyboardKey.browserBack;
    final wasHidden = !_overlay;
    _showOverlay();
    return wasHidden && !back ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  @override
  void initState() {
    super.initState();
    widget.controller.setVolume(1.0);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _backFocus.requestFocus());
    _showOverlay();
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _backFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const fade = Duration(milliseconds: 300);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        onKeyEvent: _onKey,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _showOverlay,
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: widget.controller.value.aspectRatio == 0
                        ? 16 / 9
                        : widget.controller.value.aspectRatio,
                    child: VideoPlayerHdr(widget.controller,
                        key: ObjectKey(widget.controller)),
                  ),
                ),
                Positioned(
                  left: 4 + MediaQuery.paddingOf(context).left,
                  top: 4 + MediaQuery.paddingOf(context).top,
                  child: AnimatedOpacity(
                    opacity: _overlay ? 1 : 0,
                    duration: fade,
                    child: IconButton(
                      tooltip: tr('Back'),
                      focusNode: _backFocus,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _overlay ? 1 : 0,
                      duration: fade,
                      child: Center(
                        child: Text(
                          widget.channel.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 4)
                              ]),
                        ),
                      ),
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

/// Group-filtered channel browser for assigning a cell — a left pane lists
/// groups (All/Favorites/every real group, same "Favorites sits alongside
/// the real provider groups, not inside one" convention `TvHomeScreen`'s
/// own sidebar already uses) and a right pane is a search field plus the
/// filtered channel list. Previously a single flat text-search list with
/// no group filtering at all — found genuinely lacking next to a
/// competitor's own add-channel screen, which splits exactly this way.
///
/// Left/Right switches between the two panes as independent focus zones
/// (mirroring `PlayerScreen`'s own top/bottom-bar `FocusScopeNode`
/// pattern) rather than trusting default directional traversal between
/// two differently-shaped side-by-side lists — same reasoning
/// `AddPlaylistScreen`'s mode-button row has for not trusting default
/// traversal for that shape of layout. The text-field escape fix
/// (`_handleSearchFieldEscapeKey`) is unchanged from before: `EditableText`
/// claims arrow keys for itself whenever a text field has focus, so plain
/// default Down traversal never actually escapes a focused search field on
/// real remote hardware, regardless of what's focusable below it.
class _ChannelPickerScreen extends StatefulWidget {
  const _ChannelPickerScreen({required this.channels});

  final List<Channel> channels;

  @override
  State<_ChannelPickerScreen> createState() => _ChannelPickerScreenState();
}

class _ChannelPickerScreenState extends State<_ChannelPickerScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _firstResultFocus = FocusNode();
  final _resultsScroll = ScrollController();

  final _groupScope = FocusScopeNode(debugLabel: 'picker-groups');
  final _contentScope = FocusScopeNode(debugLabel: 'picker-content');

  /// 'All', 'Favorites' (only when at least one favorite exists among
  /// [widget.channels]), then every real group name in first-seen order.
  /// Fixed for this screen's lifetime — [widget.channels] is a snapshot
  /// handed in once by [_MultiviewScreenState._openPicker], not something
  /// that changes while this is open.
  late final List<String> _groupEntries;
  late final List<FocusNode> _groupFocusNodes;
  int _selectedGroupIndex = 0;

  /// The two sports shortcuts ([MultiviewSports]) right after All /
  /// Favorites. Not real group names, so a provider group called "Sports"
  /// can't collide with them.
  static const _liveEntry = '\u0001live';
  static const _sportsEntry = '\u0001sports';

  /// Live now: loaded the first time the entry is picked (it fetches
  /// scores and runs the channel matcher), null until then.
  List<LiveGameChannel>? _live;
  bool _liveLoading = false;

  Future<void> _loadLive() async {
    if (_live != null || _liveLoading) return;
    setState(() => _liveLoading = true);
    List<LiveGameChannel> live;
    try {
      live = await MultiviewSports.liveGames(
        storage: context.read<StorageService>(),
        playlist: context.read<PlaylistManager>(),
        epg: context.read<EpgService>(),
      );
    } catch (_) {
      live = const [];
    }
    if (!mounted) return;
    setState(() {
      _live = live;
      _liveLoading = false;
    });
  }

  List<LiveGameChannel> get _liveRows =>
      MultiviewSports.search(_live ?? const [], _query);

  static String _entryTitle(String entry) => switch (entry) {
        'All' || 'Favorites' => tr(entry),
        _liveEntry => tr('Live now'),
        _sportsEntry => tr('Sports'),
        _ => entry,
      };

  static IconData _entryIcon(String entry) => switch (entry) {
        'All' => Icons.apps,
        'Favorites' => Icons.star,
        _liveEntry => Icons.sports_score,
        _sportsEntry => Icons.sports,
        _ => Icons.live_tv,
      };

  String _query = '';

  /// Portrait phone: a group was picked, its channels show (see build).
  bool _narrowShowChannels = false;

  @override
  void initState() {
    super.initState();
    final seen = <String>{};
    final groups = <String>[];
    for (final c in widget.channels) {
      if (c.group.isNotEmpty && seen.add(c.group)) groups.add(c.group);
    }
    final hasFavorites = widget.channels.any((c) => c.isFavorite);
    final hasSports = widget.channels.any(MultiviewSports.isSports);
    _groupEntries = [
      'All',
      if (hasFavorites) 'Favorites',
      _liveEntry,
      if (hasSports) _sportsEntry,
      ...groups,
    ];
    _groupFocusNodes = List.generate(_groupEntries.length, (_) => FocusNode());
    HardwareKeyboard.instance.addHandler(_handleSearchFieldEscapeKey);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _groupFocusNodes.first.requestFocus());
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleSearchFieldEscapeKey);
    _searchController.dispose();
    _searchFocus.dispose();
    _firstResultFocus.dispose();
    _resultsScroll.dispose();
    _groupScope.dispose();
    _contentScope.dispose();
    for (final node in _groupFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool _handleSearchFieldEscapeKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    if (event.logicalKey != LogicalKeyboardKey.arrowDown) return false;
    if (FocusManager.instance.primaryFocus != _searchFocus) return false;
    _firstResultFocus.requestFocus();
    return true;
  }

  List<Channel> get _filteredChannels {
    Iterable<Channel> base = widget.channels;
    final entry = _groupEntries[_selectedGroupIndex];
    if (entry == 'Favorites') {
      base = base.where((c) => c.isFavorite);
    } else if (entry == _liveEntry) {
      // One row per game (see build); search matches the game too.
      return [for (final l in _liveRows) l.channel];
    } else if (entry == _sportsEntry) {
      base = base.where(MultiviewSports.isSports);
    } else if (entry != 'All') {
      base = base.where((c) => c.group == entry);
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      base = base.where((c) => c.name.toLowerCase().contains(q));
    }
    return base.toList();
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filteredChannels;
    // What's airing now under each channel, same lookup the player's own
    // remaining-time label uses — epgId (rawId or a manual override), not
    // the composite `id`.
    final epg = context.watch<EpgService>();
    // Portrait phone: the two panes don't fit side by side (the channel
    // pane was one letter wide) — groups first, then that group's channels
    // full width; Back returns to the groups.
    final size = MediaQuery.sizeOf(context);
    final narrow = size.width < 600 && size.height > size.width;
    final showChannels = narrow && _narrowShowChannels;
    final entry = _groupEntries[_selectedGroupIndex];
    return PopScope(
      canPop: !showChannels,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _narrowShowChannels = false);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(showChannels ? _entryTitle(entry) : tr('Pick a channel')),
        ),
        body: CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
              // No-op when already there — EditableText claims Left/Right
              // for caret movement whenever the search field has focus, so
              // this only ever actually fires while focus is on a group or
              // channel row, never mid-typing.
              if (!_groupScope.hasFocus) {
                _groupFocusNodes[_selectedGroupIndex].requestFocus();
              }
            },
            const SingleActivator(LogicalKeyboardKey.arrowRight): () {
              // Into the channel list, not the search field: focusing the
              // field pops the on-screen keyboard, and on Fire OS that
              // keyboard swallows Back and then traps D-pad focus (CLAUDE.md
              // §10). Search stays one Up press away.
              if (_contentScope.hasFocus) return;
              if (_filteredChannels.isNotEmpty &&
                  _firstResultFocus.context != null) {
                _firstResultFocus.requestFocus();
              } else {
                _searchFocus.requestFocus();
              }
            },
          },
          child: _panes(
            narrow: narrow,
            showChannels: showChannels,
            groups: FocusScope(
              node: _groupScope,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _groupEntries.length,
                itemBuilder: (context, i) {
                  final entry = _groupEntries[i];
                  final selected = i == _selectedGroupIndex;
                  return TvMenuTile(
                    focusNode: _groupFocusNodes[i],
                    icon: _entryIcon(entry),
                    title: _entryTitle(entry),
                    trailing: selected
                        ? Icon(Icons.check, color: scheme.primary)
                        : const SizedBox.shrink(),
                    // Deliberately doesn't move focus into the content
                    // pane on its own — matches the competitor screen
                    // this is modeled on, where picking a group only
                    // updates the list on the right; "change pane" stays
                    // a separate, deliberate Right press.
                    onTap: () {
                      setState(() {
                        _selectedGroupIndex = i;
                        if (narrow) _narrowShowChannels = true;
                      });
                      if (entry == _liveEntry) _loadLive();
                      // Back to the top so Right lands on the new
                      // group's first channel (row 0 must be built).
                      if (_resultsScroll.hasClients) {
                        _resultsScroll.jumpTo(0);
                      }
                    },
                  );
                },
              ),
            ),
            channels: FocusScope(
              node: _contentScope,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TvTextFieldGate(
                      focusNode: _searchFocus,
                      builder: (context, readOnly) => TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        readOnly: readOnly,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: tr('Search channels...'),
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white54),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: entry == _liveEntry && _live == null
                                ? const CircularProgressIndicator()
                                : Text(
                                    entry == _liveEntry
                                        ? tr(
                                            'No live games on your channels right now')
                                        : tr('No channels found'),
                                    textAlign: TextAlign.center,
                                    style:
                                        const TextStyle(color: Colors.white54)),
                          )
                        : ListView.builder(
                            controller: _resultsScroll,
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final c = filtered[i];
                              final now = epg.getCurrentProgram(c.epgId);
                              // Live now: one row per game (title = the
                              // game, best channel + count below); OK opens
                              // every channel found for it.
                              final rows =
                                  entry == _liveEntry ? _liveRows : null;
                              final live = rows != null && i < rows.length
                                  ? rows[i]
                                  : null;
                              if (live != null) {
                                final n = live.matches.length;
                                return TvMenuTile(
                                  focusNode: i == 0 ? _firstResultFocus : null,
                                  icon: Icons.sports_score,
                                  title: MultiviewSports.label(live.game),
                                  subtitle: n > 1
                                      ? '${c.name} · ${tr('{n} channels', {
                                              'n': n
                                            })}'
                                      : c.name,
                                  trailing: n > 1
                                      ? const Icon(Icons.chevron_right,
                                          color: Colors.white54)
                                      : const SizedBox.shrink(),
                                  onTap: () async {
                                    final navigator = Navigator.of(context);
                                    final picked =
                                        await chooseGameChannel(context, live);
                                    if (picked != null && mounted) {
                                      navigator.pop(picked);
                                    }
                                  },
                                );
                              }
                              return TvMenuTile(
                                subtitle: now == null
                                    ? null
                                    : '${_hhmm(now.start)}–${_hhmm(now.stop)}  ${now.title}',
                                focusNode: i == 0 ? _firstResultFocus : null,
                                leading:
                                    (c.logoUrl != null && c.logoUrl!.isNotEmpty)
                                        ? Image.network(c.logoUrl!,
                                            width: 32,
                                            height: 32,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.tv,
                                                    color: Colors.white54))
                                        : const Icon(Icons.tv,
                                            color: Colors.white54),
                                title: c.name,
                                trailing: const SizedBox.shrink(),
                                onTap: () => Navigator.of(context).pop(c),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Groups | channels side by side, or one of them on a portrait phone.
  Widget _panes({
    required bool narrow,
    required bool showChannels,
    required Widget groups,
    required Widget channels,
  }) {
    if (narrow) return showChannels ? channels : groups;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 260, child: groups),
        const VerticalDivider(color: Colors.white24, width: 1),
        Expanded(child: channels),
      ],
    );
  }
}
