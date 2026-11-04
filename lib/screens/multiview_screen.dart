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
import '../widgets/native_video_hole.dart';
import '../widgets/roll_down_menu.dart';
import '../widgets/sports_mode_live_panel.dart';
import '../widgets/tv_dialog_option.dart';
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
/// 2026-11-03: with the native video surface on (the default), each screen
/// is still a texture-view player but draws into its own SurfaceView behind
/// Flutter ([NativeMultiviewTiles], [multiviewVideo]) — the texture path
/// capped 3 screens at ~7 fps each (LOG-C47KFD). Off = textures as before.
/// The same LOG and TiviMate on the owner's Formuler showed the real limit
/// is the box's H.264 decoder (~120 frames/s of 1080p for all screens, one
/// 4K stream at a time).
///
/// Full screen and Enlarge are layouts, not routes: one tile, one
/// controller, one video view that slides to its new place
/// ([multiviewSlotRects]); nothing renders the same stream twice.
class MultiviewScreen extends StatefulWidget {
  const MultiviewScreen(
      {super.key, this.initialChannel, this.initialChannels = const []});

  /// Pre-loads cell 0 with this channel on open — set when reached from
  /// `PlayerScreen`'s own "Open in Multiview" action (see
  /// `PlayerControls.onOpenMultiview`), so a channel already being
  /// watched fullscreen becomes the first multiview cell instead of
  /// landing on an empty grid. Null for the normal entry point (the
  /// sidebar's own "Multiview" row), which still starts empty as before.
  final Channel? initialChannel;

  /// Sports Trak's "Play in Multiview": one screen per checked live game
  /// (up to 4), equal screens.
  final List<Channel> initialChannels;

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

/// Controllers whose player draws into a native tile (see
/// [NativeMultiviewTiles]) instead of a Flutter texture.
final _tileControllers = Expando<bool>();

/// A screen's video: the native tile's hole, or the texture.
Widget multiviewVideo(VideoPlayerHdrController controller) =>
    _tileControllers[controller] == true
        ? NativeTileHole(
            playerId: SubtitleTracks.playerIdOf(controller),
            key: ObjectKey(controller))
        : VideoPlayerHdr(controller, key: ObjectKey(controller));

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
/// Where each of the 4 cells goes in [area] (null = not on screen).
///
/// TiviMate-style (owner, 2026-11-03): the number of screens follows what's
/// been added. 1 = one 16:9 screen, 2 = side by side, 3-4 = 2x2 (a third
/// screen centred under the first two); [enlarged] = that screen big at the
/// top and the others small in a row underneath; [fullscreen] = that screen
/// alone over the whole area. Portrait (phones) stacks at most 2.
///
enum EnlargedPosition { top, bottom, left, right }

enum TwoScreenLayout { sideBySide, stacked }

EnlargedPosition enlargedPositionFromString(String? s) => switch (s) {
      'bottom' => EnlargedPosition.bottom,
      'left' => EnlargedPosition.left,
      'right' => EnlargedPosition.right,
      _ => EnlargedPosition.top,
    };

String enlargedPositionToString(EnlargedPosition p) => switch (p) {
      EnlargedPosition.bottom => 'bottom',
      EnlargedPosition.left => 'left',
      EnlargedPosition.right => 'right',
      EnlargedPosition.top => 'top',
    };

TwoScreenLayout twoScreenLayoutFromString(String? s) => switch (s) {
      'stacked' => TwoScreenLayout.stacked,
      _ => TwoScreenLayout.sideBySide,
    };

String twoScreenLayoutToString(TwoScreenLayout l) => switch (l) {
      TwoScreenLayout.stacked => 'stacked',
      TwoScreenLayout.sideBySide => 'side_by_side',
    };

/// Dynamic layout for 1-4 screens: equal screens, 2-screen side-by-side or
/// stacked, or 1 enlarged screen placed top, bottom, left, or right scaled
/// by [enlargeFactor] relative to other screens.
@visibleForTesting
List<Rect?> multiviewSlotRects(Size area, int slots,
    {int? enlarged,
    int? fullscreen,
    bool portrait = false,
    EnlargedPosition enlargedPosition = EnlargedPosition.top,
    TwoScreenLayout twoScreenLayout = TwoScreenLayout.sideBySide,
    double enlargeFactor = 2.0,
    @Deprecated('Use enlarged and enlargedPosition instead') bool main = false}) {
  const m = 12.0, g = 10.0;
  final out = List<Rect?>.filled(4, null);
  final w0 = area.width, h0 = area.height;
  if (fullscreen != null) {
    out[fullscreen] = Offset.zero & area;
    return out;
  }
  Rect at(double left, double top, double w) =>
      Rect.fromLTWH(left, top, w, w * 9 / 16);
  if (portrait) {
    final n = slots.clamp(1, 2);
    final w = math.min(w0 - 2 * m, ((h0 - 2 * m - (n - 1) * g) / n) * 16 / 9);
    final h = w * 9 / 16;
    var top = (h0 - (n * h + (n - 1) * g)) / 2;
    for (var i = 0; i < n; i++) {
      out[i] = at((w0 - w) / 2, top, w);
      top += h + g;
    }
    return out;
  }
  if (main) {
    enlarged ??= 0;
    enlargedPosition = EnlargedPosition.left;
    enlargeFactor = 2.0;
  }
  final n = slots.clamp(1, 4);
  if (n == 1) {
    final w = math.min(w0 - 2 * m, (h0 - 2 * m) * 16 / 9);
    out[0] = at((w0 - w) / 2, (h0 - w * 9 / 16) / 2, w);
    return out;
  }
  final W = w0 - 2 * m;
  final H = h0 - 2 * m;
  if (enlarged != null && enlarged < n) {
    final others = [
      for (var i = 0; i < n; i++)
        if (i != enlarged) i
    ];
    final k = others.length;
    final F = math.max(1.2, math.min(4.0, enlargeFactor));

    switch (enlargedPosition) {
      case EnlargedPosition.top:
        final smallW = math.min(
          W / F,
          math.min(
            (W - (k - 1) * g) / k,
            ((H - g) / (F + 1)) * 16 / 9,
          ),
        );
        final bigW = smallW * F;
        final bigH = bigW * 9 / 16;
        final smallH = smallW * 9 / 16;
        final totalH = bigH + g + smallH;
        final startTop = (h0 - totalH) / 2;

        out[enlarged] = at((w0 - bigW) / 2, startTop, bigW);

        final rowTop = startTop + bigH + g;
        final totalRowW = k * smallW + (k - 1) * g;
        var curLeft = (w0 - totalRowW) / 2;
        for (final i in others) {
          out[i] = at(curLeft, rowTop, smallW);
          curLeft += smallW + g;
        }
        return out;

      case EnlargedPosition.bottom:
        final smallW = math.min(
          W / F,
          math.min(
            (W - (k - 1) * g) / k,
            ((H - g) / (F + 1)) * 16 / 9,
          ),
        );
        final bigW = smallW * F;
        final bigH = bigW * 9 / 16;
        final smallH = smallW * 9 / 16;
        final totalH = bigH + g + smallH;
        final startTop = (h0 - totalH) / 2;

        final rowTop = startTop;
        final totalRowW = k * smallW + (k - 1) * g;
        var curLeft = (w0 - totalRowW) / 2;
        for (final i in others) {
          out[i] = at(curLeft, rowTop, smallW);
          curLeft += smallW + g;
        }

        out[enlarged] = at((w0 - bigW) / 2, startTop + smallH + g, bigW);
        return out;

      case EnlargedPosition.left:
        final smallW = math.min(
          (W - g) / (F + 1),
          math.min(
            (H / F) * 16 / 9,
            ((H - (k - 1) * g) / k) * 16 / 9,
          ),
        );
        final bigW = smallW * F;
        final bigH = bigW * 9 / 16;
        final smallH = smallW * 9 / 16;
        final totalW = bigW + g + smallW;
        final startLeft = (w0 - totalW) / 2;

        out[enlarged] = at(startLeft, (h0 - bigH) / 2, bigW);

        final colLeft = startLeft + bigW + g;
        final totalColH = k * smallH + (k - 1) * g;
        var curTop = (h0 - totalColH) / 2;
        for (final i in others) {
          out[i] = at(colLeft, curTop, smallW);
          curTop += smallH + g;
        }
        return out;

      case EnlargedPosition.right:
        final smallW = math.min(
          (W - g) / (F + 1),
          math.min(
            (H / F) * 16 / 9,
            ((H - (k - 1) * g) / k) * 16 / 9,
          ),
        );
        final bigW = smallW * F;
        final bigH = bigW * 9 / 16;
        final smallH = smallW * 9 / 16;
        final totalW = bigW + g + smallW;
        final startLeft = (w0 - totalW) / 2;

        final colLeft = startLeft;
        final totalColH = k * smallH + (k - 1) * g;
        var curTop = (h0 - totalColH) / 2;
        for (final i in others) {
          out[i] = at(colLeft, curTop, smallW);
          curTop += smallH + g;
        }

        out[enlarged] = at(startLeft + smallW + g, (h0 - bigH) / 2, bigW);
        return out;
    }
  }

  if (n == 2) {
    if (twoScreenLayout == TwoScreenLayout.stacked) {
      final h = math.min((H - g) / 2, W * 9 / 16);
      final w = h * 16 / 9;
      final left = (w0 - w) / 2;
      final top = (h0 - (2 * h + g)) / 2;
      out[0] = at(left, top, w);
      out[1] = at(left, top + h + g, w);
      return out;
    }
    final w = math.min((W - g) / 2, H * 16 / 9);
    final top = (h0 - w * 9 / 16) / 2;
    final left = (w0 - (2 * w + g)) / 2;
    out[0] = at(left, top, w);
    out[1] = at(left + w + g, top, w);
    return out;
  }
  final w = math.min((W - g) / 2, ((H - g) / 2) * 16 / 9);
  final h = w * 9 / 16;
  final top = (h0 - (2 * h + g)) / 2;
  final left = (w0 - (2 * w + g)) / 2;
  out[0] = at(left, top, w);
  out[1] = at(left + w + g, top, w);
  out[2] = n == 3 ? at((w0 - w) / 2, top + h + g, w) : at(left, top + h + g, w);
  if (n == 4) out[3] = at(left + w + g, top + h + g, w);
  return out;
}

class _MultiviewScreenState extends State<MultiviewScreen> {
  static const _cellCount = 4;
  static const _anim = Duration(milliseconds: 280);
  final List<_MultiviewCell> _cells =
      List.generate(_cellCount, (_) => _MultiviewCell());
  int _activeCell = 0;

  /// Screens on show: Add screen adds one, Remove screen closes it
  /// (TiviMate-style, owner 2026-11-03). Cells 0 .. _slots-1 are on screen.
  int _slots = 1;

  /// Hold OK: this screen big at the top, the others small underneath.
  /// Nothing reconnects, the tiles (and their native video views) move.
  int? _enlarged;

  /// OK > Full screen: the tile grows over the whole screen in place (no
  /// route, so the video never leaves its view); Back shrinks it back.
  int? _fullscreen;

  /// The other screens stay hidden while one grows to / shrinks from full
  /// screen: native video views have no order among themselves, so an
  /// overlapping one could show on top of it.
  bool _othersHidden = false;
  int? _shrinking;

    EnlargedPosition _enlargedPosition = EnlargedPosition.top;
  TwoScreenLayout _twoScreenLayout = TwoScreenLayout.sideBySide;
  double _enlargeFactor = 2.0;

  /// Last layout, for "is this screen in the top row" (Up opens the header).
  List<Rect?> _rects = List.filled(4, null);

  /// The header (back, the audio hint) is an overlay, not a row: it took
  /// height from the grid (user report, 2026-10-19). It slides down on Up
  /// from the top row (or a tap on the handle, touch/mouse), shows for a
  /// few seconds on entering so it's discoverable, and slides away once
  /// focus leaves it.
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

  /// Up from a top-row screen opens the header (nothing is above it).
  KeyEventResult _onGridKey(FocusNode node, KeyEvent e) {
    if (_swapMode) return _onSwapKey(e);
    if (e is! KeyDownEvent ||
        e.logicalKey != LogicalKeyboardKey.arrowUp ||
        _fullscreen != null) {
      return KeyEventResult.ignored;
    }
    final i = _cells.indexWhere((c) => c.focusNode.hasFocus);
    if (i < 0 || _rects[i] == null) return KeyEventResult.ignored;
    final top = _rects.whereType<Rect>().map((r) => r.top).reduce(math.min);
    if (_rects[i]!.top > top + 1) return KeyEventResult.ignored;
    _revealHeader(focus: true);
    return KeyEventResult.handled;
  }

  /// Portrait phone: at most the first 2 screens, stacked (owner,
  /// 2026-10-19). Screens 3-4 are paused (not dropped) until it's rotated
  /// back.
  bool _portrait = false;

  Future<void> _setPortrait(bool on) async {
    if (on == _portrait || !mounted) return;
    setState(() {
      _portrait = on;
      if (on) _enlarged = null;
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

  int get _maxSlots => _portrait ? 2 : _cellCount;

    bool _swapMode = false;
  int? _swapSource;
  int? _swapTarget;
  int _swapCount = 0;

  void _enterSwapMode({int? sourceIndex}) {
    final playingIndices = [
      for (var i = 0; i < _slots; i++)
        if (_cells[i].channel != null) i
    ];
    if (playingIndices.length < 2) return;

    final src = sourceIndex ?? _activeCell;
    final initialTarget = playingIndices.firstWhere(
      (i) => i != src,
      orElse: () => (src + 1) % _slots,
    );

    setState(() {
      _swapMode = true;
      _swapSource = src;
      _swapTarget = initialTarget;
    });

    _cells[initialTarget].focusNode.requestFocus();
    _hideHeaderSoon(Duration.zero);
  }

  void _exitSwapMode() {
    if (_swapMode) {
      setState(() {
        _swapMode = false;
        _swapSource = null;
        _swapTarget = null;
      });
      _cells[_activeCell].focusNode.requestFocus();
    }
  }

  void _performSwap(int i, int j) {
    if (i == j || i >= _slots || j >= _slots) return;
    final a = _cells[i], b = _cells[j];
    final channel = a.channel, controller = a.controller;
    a
      ..channel = b.channel
      ..controller = b.controller;
    b
      ..channel = channel
      ..controller = controller;

    if (_activeCell == i) {
      _activeCell = j;
    } else if (_activeCell == j) {
      _activeCell = i;
    }

    if (a.controller != null) {
      unawaited(a.controller!.setVolume(_activeCell == i ? 1.0 : 0.0));
    }
    if (b.controller != null) {
      unawaited(b.controller!.setVolume(_activeCell == j ? 1.0 : 0.0));
    }

    setState(() {
      _swapCount++;
      _swapSource = j;
      _swapTarget = i;
    });

    _cells[j].focusNode.requestFocus();
  }

  int? _findNeighbor(int fromIndex, LogicalKeyboardKey key) {
    final fromRect = _rects[fromIndex];
    if (fromRect == null) return null;
    int? best;
    double bestDist = double.infinity;
    for (var i = 0; i < _slots; i++) {
      if (i == fromIndex || _rects[i] == null) continue;
      final r = _rects[i]!;
      bool inDirection = false;
      if (key == LogicalKeyboardKey.arrowRight) {
        inDirection = r.left >= fromRect.right - 2;
      } else if (key == LogicalKeyboardKey.arrowLeft) {
        inDirection = r.right <= fromRect.left + 2;
      } else if (key == LogicalKeyboardKey.arrowDown) {
        inDirection = r.top >= fromRect.bottom - 2;
      } else if (key == LogicalKeyboardKey.arrowUp) {
        inDirection = r.bottom <= fromRect.top + 2;
      }
      if (inDirection) {
        final dist = (r.center - fromRect.center).distance;
        if (dist < bestDist) {
          bestDist = dist;
          best = i;
        }
      }
    }
    return best;
  }

  KeyEventResult _onSwapKey(KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final key = e.logicalKey;
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.escape) {
      _exitSwapMode();
      return KeyEventResult.handled;
    }

    final curFocus = _cells.indexWhere((c) => c.focusNode.hasFocus);
    final cur = curFocus >= 0 ? curFocus : (_swapTarget ?? 0);

    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      if (_swapSource != null && cur != _swapSource) {
        _performSwap(_swapSource!, cur);
      } else if (_slots == 2 && _swapSource != null) {
        final other = _swapSource == 0 ? 1 : 0;
        _performSwap(_swapSource!, other);
      } else {
        _exitSwapMode();
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      final neighbor = _findNeighbor(cur, key);
      if (neighbor != null) {
        setState(() => _swapTarget = neighbor);
        _cells[neighbor].focusNode.requestFocus();
        return KeyEventResult.handled;
      } else if (_slots == 2 && _swapSource != null) {
        final other = cur == 0 ? 1 : 0;
        _performSwap(cur, other);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  String get _enlargedPositionLabel =>
      _enlargedPositionName(_enlargedPosition);

  static String _enlargedPositionName(EnlargedPosition p) => switch (p) {
        EnlargedPosition.top => 'Top',
        EnlargedPosition.bottom => 'Bottom',
        EnlargedPosition.left => 'Left',
        EnlargedPosition.right => 'Right',
      };

  Future<void> _chooseEnlargedPosition() async {
    final picked = await showDialog<EnlargedPosition>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(tr('Enlarged screen position')),
        children: [
          for (final pos in EnlargedPosition.values)
            TvDialogOption(
              autofocus: pos == _enlargedPosition,
              onPressed: () => Navigator.of(dialogContext).pop(pos),
              child: Row(
                children: [
                  Icon(pos == _enlargedPosition
                      ? Icons.check_circle
                      : Icons.circle_outlined),
                  const SizedBox(width: 12),
                  Text(tr(_enlargedPositionName(pos))),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _enlargedPosition = picked);
    final storage = context.read<StorageService>();
    unawaited(
        storage.setMultiviewEnlargedPosition(enlargedPositionToString(picked)));
  }

  Future<void> _toggleTwoScreenLayout() async {
    final picked = await showDialog<TwoScreenLayout>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(tr('Two-screen layout')),
        children: [
          for (final layout in TwoScreenLayout.values)
            TvDialogOption(
              autofocus: layout == _twoScreenLayout,
              onPressed: () => Navigator.of(dialogContext).pop(layout),
              child: Row(
                children: [
                  Icon(layout == _twoScreenLayout
                      ? Icons.check_circle
                      : Icons.circle_outlined),
                  const SizedBox(width: 12),
                  Text(tr(layout == TwoScreenLayout.sideBySide
                      ? 'Side by side'
                      : 'Stacked (one on top of the other)')),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _twoScreenLayout = picked);
    final storage = context.read<StorageService>();
    unawaited(
        storage.setMultiviewTwoScreenLayout(twoScreenLayoutToString(picked)));
  }

  Future<void> _addScreen() async {
    if (_slots >= _maxSlots) return;
    final index = _slots;
    setState(() => _slots++);
    _cells[index].focusNode.requestFocus();
    await _openPicker(index);
    if (!mounted || _cells[index].channel != null) return;
    if (_slots == index + 1) setState(() => _slots--);
    _cells[math.max(0, index - 1)].focusNode.requestFocus();
  }

  /// Remove screen: closes it and moves the later screens up one place
  /// (their streams keep playing, nothing reconnects).
  void _removeScreen(int index) {
    final old = _cells[index].controller;
    final wasActive = index == _activeCell;
    setState(() {
      for (var j = index; j < _slots - 1; j++) {
        _cells[j]
          ..channel = _cells[j + 1].channel
          ..controller = _cells[j + 1].controller;
      }
      _cells[_slots - 1]
        ..channel = null
        ..controller = null;
      if (_slots > 1) _slots--;
      if (_activeCell > index) _activeCell--;
      if (_activeCell >= _slots) _activeCell = _slots - 1;
      final e = _enlarged;
      _enlarged = e == null || e == index
          ? null
          : e > index
              ? e - 1
              : e;
      if (_fullscreen == index) {
        _fullscreen = null;
        _othersHidden = false;
      }
      if (_slots < 2) _enlarged = null;
      if (_swapSource == index) _swapSource = null;
      if (_swapTarget == index) _swapTarget = null;
      if (_slots < 2) _swapMode = false;
    });
    unawaited(old?.dispose());
    final focus = math.min(index, _slots - 1);
    _cells[focus].focusNode.requestFocus();
    if (wasActive && _cells[focus].controller != null) {
      // The sound follows the selected screen.
      unawaited(_cells[focus].controller!.setVolume(1.0));
      _activeCell = focus;
    }
  }

  void _toggleEnlarge(int index) {
    if (_slots < 2 || _portrait || _fullscreen != null) return;
    setState(() => _enlarged = _enlarged == index ? null : index);
  }

  Future<void> _enterFullscreen(int index) async {
    if (_cells[index].channel == null) return;
    await _setActive(index);
    if (!mounted) return;
    setState(() {
      _fullscreen = index;
      _othersHidden = true;
    });
    _hideHeaderSoon(Duration.zero);
  }

  void _exitFullscreen() {
    final index = _fullscreen;
    if (index == null) return;
    setState(() {
      _fullscreen = null;
      _shrinking = index;
    });
    // The others come back once this one has shrunk into place.
    Future<void>.delayed(_anim, () {
      if (mounted && _fullscreen == null) {
        setState(() => _othersHidden = false);
      }
    });
    _cells[index].focusNode.requestFocus();
  }

  Future<void> _togglePause(int index) async {
    final c = _cells[index].controller;
    if (c == null) return;
    await (c.value.isPlaying ? c.pause() : c.play());
    if (mounted) setState(() {});
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
                  tr('Every screen in Multiview is its own connection to your provider. Your playlist must allow at least as many connections as screens you open (see Max connections in Playlist Manager).\n\nIf two screens share an account that allows only one connection, they keep kicking each other off and will freeze or buffer. Tip: use channels from different playlists, one per account.\n\nA screen that freezes restarts on its own. If it doesn\'t, press OK on it and choose Reload.'),
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

  /// Send log: one line per playing screen every 10 s (buffer, freezes,
  /// frames shown per second, dropped frames), to tell a provider that
  /// runs dry from a box that can't decode/draw every screen.
  Timer? _statsTimer;
  static const _stats = MethodChannel('vespertv/stats');
  final _lastRendered = <VideoPlayerHdrController, int>{};
  final _lastDropped = <VideoPlayerHdrController, int>{};

  /// Previous native decoder counters per screen (queued, droppedInput,
  /// offsetSumUs, offsetCount), for the per-10 s deltas in the log line.
  final _lastCounters = <VideoPlayerHdrController, List<int>>{};

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
        // Decoder input per second, frames thrown away before decoding
        // (catching up to a keyframe) and how early (+) or late (-) frames
        // reached the renderer: late = decoder latency, low input = the
        // decoder can't keep up.
        final now = [
          n('queued'),
          n('droppedInput'),
          n('offsetSumUs'),
          n('offsetCount')
        ];
        final before = _lastCounters[c] ?? now;
        _lastCounters[c] = now;
        final offsets = now[3] - before[3];
        final early = offsets > 0 ? (now[2] - before[2]) / offsets / 1000 : 0.0;
        debugPrint('Multiview: screen ${i + 1} ${_cells[i].channel?.name}: '
            'buffer ${(n('bufferedMs') / 1000).toStringAsFixed(1)} s, '
            'freezes ${n('stalls')} (last ${(n('lastStallMs') / 1000).toStringAsFixed(1)} s), '
            '${fps.toStringAsFixed(1)} fps, dropped +$newDrops, '
            '${n('height')}p${c.value.isBuffering ? ', buffering now' : ''}'
            ', ${_tileControllers[c] == true ? 'native' : 'texture'}'
            ', decoder in ${((now[0] - before[0]) / 10).toStringAsFixed(1)}/s'
            ', dropped before decode +${now[1] - before[1]}'
            ', avg ${early.toStringAsFixed(0)} ms early'
            ', max run ${n('maxConsecutiveDropped')}');
      } on MissingPluginException {
        _statsTimer?.cancel();
        return;
      } on PlatformException {
        // Screen changed between the check and the call.
      }
    }
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
      // Native video surface on: this screen draws into its own SurfaceView
      // behind Flutter instead of a texture (see NativeMultiviewTiles).
      final tile = NativeMultiviewTiles.enabled;
      if (tile) {
        await NativeMultiviewTiles.nextIsTile();
        _tileControllers[newController] = true;
      }
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

  /// The live guide's game groups: Sports Trak's live games with a channel.
  Future<List<LivePanelGame>> _panelLiveGames() async {
    final games = await MultiviewSports.liveGames(
      storage: context.read<StorageService>(),
      playlist: context.read<PlaylistManager>(),
      epg: context.read<EpgService>(),
    );
    return [
      for (final g in games)
        (
          id: g.game.id,
          title: g.game.title,
          note: trSports(g.game.statusText),
          channels: [for (final m in g.matches) m.channel],
        ),
    ];
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

  /// Add screen / Change channel / OK on an empty screen: the live guide
  /// (groups + see-through channel guide, the Sports Mode Live TV panel) over
  /// the left of the screens, which keep playing (TiviMate-style, owner
  /// 2026-11-03). OK on a channel puts it on [index]; Back walks guide ->
  /// groups -> closed.
  Future<void> _openPicker(int index) async {
    if (_openingPicker) return;
    _openingPicker = true;
    try {
      await _assignPicked(index, await _pickFromGuide(index));
    } finally {
      _openingPicker = false;
    }
  }

  Future<void> _assignPicked(int index, Channel? chosen) async {
    if (chosen == null || !mounted) return;
    await _assign(index, chosen);
    // The sound follows the selected screen.
    if (mounted && _cells[index].focusNode.hasFocus) {
      await _setActive(index);
    }
  }

  /// The screen the live guide picks a channel for (null = guide closed).
  int? _panelFor;
  Completer<Channel?>? _panelPick;
  final _panelKey = GlobalKey<SportsModeLivePanelState>();

  Future<Channel?> _pickFromGuide(int index) {
    _panelPick?.complete(null);
    final done = Completer<Channel?>();
    _panelPick = done;
    setState(() => _panelFor = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final panel = _panelKey.currentState;
      if (!mounted || panel == null) return;
      panel.focusGroups();
      panel.openGuide();
    });
    return done.future;
  }

  void _closePanel([Channel? picked]) {
    final index = _panelFor;
    final done = _panelPick;
    _panelPick = null;
    setState(() => _panelFor = null);
    if (done != null && !done.isCompleted) done.complete(picked);
    if (index != null) _cells[index].focusNode.requestFocus();
  }

  /// Menu > Search and add: the full channel search page (also Live now and
  /// Sports shortcuts).
  Future<void> _searchAndAdd(int index) async {
    if (_openingPicker) return;
    _openingPicker = true;
    try {
      final playlist = context.read<PlaylistManager>();
      final channels = playlist.visibleChannels(category: 'tv');
      // Same Favourites list and order as the TV tab (playlist priority,
      // favourited groups, the viewer's own moves).
      final favorites = playlist.orderedFavoriteLiveChannels(
          mixPlaylists: context.read<AppPreferences>().mixFavoritePlaylists);
      final chosen = await Navigator.of(context).push<Channel>(
        MaterialPageRoute(
            builder: (_) => _ChannelPickerScreen(
                channels: channels,
                favorites: favorites,
                groupOrder: [for (final g in playlist.tvGroups) g.title])),
      );
      await _assignPicked(index, chosen);
    } finally {
      _openingPicker = false;
    }
  }

  /// OK on a screen (TiviMate-style): a small menu inside the tile's top
  /// right corner. Hold OK enlarges instead (see [_buildCell]).
  Future<void> _showCellActions(int index) async {
    final cell = _cells[index];
    if (cell.channel == null || _menuOpen) return;
    // One remote press can reach both HoldToActivate's tap and the InkWell's
    // own Activate (see _openingPicker): never two menus.
    _menuOpen = true;
    try {
      await _cellMenu(index);
    } finally {
      _menuOpen = false;
    }
  }

  bool _menuOpen = false;

  Future<void> _cellMenu(int index) async {
    final cell = _cells[index];
    final rect = rollDownAnchorOf(cell.focusNode.context);
    const width = 280.0;
    final anchor = rect == null
        ? null
        : Rect.fromLTWH(math.max(rect.left + 8, rect.right - width - 8),
            rect.top, width, 0);
        final playing = cell.controller?.value.isPlaying ?? false;
    final full = _fullscreen == index;
    final isEnlarged = _enlarged == index;
    final hasEnlarged = _enlarged != null;
    final playingCount = _cells.where((c) => c.channel != null).length;

    final action = await showRollDownMenu<String>(
      context,
      anchor: anchor,
      centered: false,
      width: width,
      title: cell.channel!.name,
      items: [
        if (_slots < _maxSlots && !full)
          RollDownMenuItem(
              value: 'add',
              icon: Icons.add_box_outlined,
              label: tr('Add screen')),
        if (playingCount >= 2 && !full)
          RollDownMenuItem(
              value: 'swapMode',
              icon: Icons.swap_horiz,
              label: tr('Swap screens'),
              subtitle: tr('Control screen positions')),
        if (_slots >= 2 && !_portrait && !full) ...[
          RollDownMenuItem(
              value: 'enlarge',
              icon: isEnlarged ? Icons.grid_view : Icons.open_in_full,
              label: isEnlarged
                  ? tr('Exit enlarged mode')
                  : tr('Enlarge this screen')),
          if (hasEnlarged)
            RollDownMenuItem(
                value: 'enlarged_pos',
                icon: Icons.dashboard_customize,
                label: tr('Enlarged position'),
                subtitle: tr(_enlargedPositionLabel)),
          if (!hasEnlarged && _slots == 2)
            RollDownMenuItem(
                value: 'two_screen_layout',
                icon: _twoScreenLayout == TwoScreenLayout.sideBySide
                    ? Icons.view_agenda
                    : Icons.view_column,
                label: tr('Layout'),
                subtitle: _twoScreenLayout == TwoScreenLayout.sideBySide
                    ? tr('Side by side')
                    : tr('Stacked (top & bottom)')),
        ],
        RollDownMenuItem(
            value: 'search', icon: Icons.search, label: tr('Search and add')),
        RollDownMenuItem(
            value: 'change',
            icon: Icons.replay,
            label: tr('Change channel')),
        RollDownMenuItem(
            value: 'pause',
            icon: playing ? Icons.pause : Icons.play_arrow,
            label: playing ? tr('Pause') : tr('Play')),
        RollDownMenuItem(
            value: 'full',
            icon: full ? Icons.fullscreen_exit : Icons.fullscreen,
            label: full ? tr('Exit full screen') : tr('Full screen')),
        RollDownMenuItem(
            value: 'reload', icon: Icons.refresh, label: tr('Reload')),
        RollDownMenuItem(
            value: 'remove', icon: Icons.close, label: tr('Remove screen')),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case 'add':
        await _addScreen();
      case 'swapMode':
        _enterSwapMode(sourceIndex: index);
      case 'enlarge':
        _toggleEnlarge(index);
      case 'enlarged_pos':
        await _chooseEnlargedPosition();
      case 'two_screen_layout':
        await _toggleTwoScreenLayout();
      case 'search':
        await _searchAndAdd(index);
      case 'change':
        await _openPicker(index);
      case 'pause':
        await _togglePause(index);
      case 'full':
        full ? _exitFullscreen() : await _enterFullscreen(index);
      case 'reload':
        await _reload(index);
      case 'remove':
        _removeScreen(index);
    }
  }

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
    // Opened from the player bar ("Open in Multiview"): always equal screens
    // first (owner, 2026-11-03); 1 + 3 only when chosen in the header.
    final initial = [
      if (widget.initialChannel case final c?) c,
      ...widget.initialChannels,
    ].take(_cellCount).toList();
    if (initial.length > 1) _slots = initial.length;

    final storage = context.read<StorageService>();
    _enlargeFactor = storage.getMultiviewEnlargeFactor();
    _enlargedPosition =
        enlargedPositionFromString(storage.getMultiviewEnlargedPosition());
    _twoScreenLayout =
        twoScreenLayoutFromString(storage.getMultiviewTwoScreenLayout());
    // One at a time: weak boxes (and 1-connection accounts) choke on
    // several streams opening together.
    if (initial.isNotEmpty) {
      unawaited(() async {
        for (final (i, channel) in initial.indexed) {
          if (!mounted) return;
          await _assign(i, channel);
        }
      }());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _cells[0].focusNode.requestFocus();
      await _showTips();
      if (mounted) _cells[0].focusNode.requestFocus();
    });
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back closes the live guide (guide -> groups -> closed), then shrinks
      // a full-screen screen, then leaves.
      canPop: _fullscreen == null && _panelFor == null && !_swapMode,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_swapMode) {
          _exitSwapMode();
          return;
        }
        if (_panelFor != null) {
          if (!(_panelKey.currentState?.back() ?? false)) _closePanel();
          return;
        }
        _exitFullscreen();
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
    if (portrait != _portrait) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _setPortrait(portrait));
    }
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
        // Down from the header: back to the first screen.
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
              focusNode: _headerFirst,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Text(tr('Multiview'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.volume_up, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                  tr('= audio follows the selected screen Â· OK on screen for menu & options'),
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
        // Every tile is placed by [multiviewSlotRects] and slides to its new
        // place (Add / Remove / Enlarge / Full screen) instead of jumping;
        // the native video views follow the tiles frame by frame.
        Positioned.fill(
          child: Focus(
            // Listen-only: it only hears keys bubbling up from the focused
            // tile. Focusable (the default), D-pad traversal could land on
            // this invisible grid-sized node instead of the next tile, and
            // the remote looked stuck (Fire Stick, 2026-10-20).
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: _onGridKey,
            child: LayoutBuilder(builder: (context, box) {
              final area = box.biggest;
              _rects = multiviewSlotRects(
                area,
                math.min(_slots, _maxSlots),
                enlarged: _enlarged,
                fullscreen: _fullscreen,
                portrait: _portrait,
                enlargedPosition: _enlargedPosition,
                twoScreenLayout: _twoScreenLayout,
                enlargeFactor: _enlargeFactor,
              );
              if (_othersHidden && _fullscreen == null) {
                // Shrinking back: only the former full-screen tile for now.
                final keep = _shrinking;
                for (var i = 0; i < _cellCount; i++) {
                  if (i != keep) _rects[i] = null;
                }
              }
              // The big / full-screen tile last, so it's painted on top.
              final order = [
                for (var i = 0; i < _cellCount; i++)
                  if (i != (_fullscreen ?? _enlarged)) i,
                if ((_fullscreen ?? _enlarged) != null)
                  _fullscreen ?? _enlarged!,
              ];
              return Stack(
                children: [
                  for (final i in order)
                    if (_rects[i] != null)
                      AnimatedPositioned.fromRect(
                        key: ValueKey(i),
                        rect: _rects[i]!,
                        duration: _anim,
                        curve: Curves.easeInOutCubic,
                        child: _buildCell(i, full: i == _fullscreen),
                      ),
                ],
              );
            }),
          ),
        ),
        if (_swapMode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: _SwapModePill(isTwoScreens: _slots == 2),
            ),
          ),
        if (_panelFor != null)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: FocusScope(
              child: SportsModeLivePanel(
                key: _panelKey,
                current: _cells[_panelFor!].channel,
                onPlay: (channel, _) async => _closePanel(channel),
                onRight: () => _panelKey.currentState?.focusGroups(),
                liveGames: _panelLiveGames,
              ),
            ),
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
        // it's there. Up from a top-row screen opens it (_onGridKey).
        if (isTv && !_headerShown && _fullscreen == null)
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

    Widget _buildCell(int index, {bool full = false}) {
    final cell = _cells[index];
    final active = index == _activeCell && cell.channel != null;
    final isSource = _swapMode && _swapSource == index;
    final isTarget =
        _swapMode && _swapTarget == index && _swapTarget != _swapSource;

    void onTap() {
      if (_swapMode) {
        if (_swapSource == null) {
          setState(() => _swapSource = index);
          return;
        }
        if (index != _swapSource) {
          _performSwap(_swapSource!, index);
        } else {
          if (_slots == 2) {
            final other = index == 0 ? 1 : 0;
            _performSwap(index, other);
          } else {
            _exitSwapMode();
          }
        }
        return;
      }
      if (cell.channel == null) {
        _openPicker(index);
        return;
      }
      _setActive(index);
      _showCellActions(index);
    }

    void onHold() {
      if (cell.channel == null || _swapMode) return;
      _slots < 2 || _portrait
          ? (full ? _exitFullscreen() : _enterFullscreen(index))
          : _toggleEnlarge(index);
    }

    Widget? badge;
    if (_swapMode) {
      if (isSource) {
        badge = _SwapSourceBadge(swaps: _swapCount);
      } else if (isTarget) {
        badge = const _SwapTargetBadge();
      }
    }

    return HoldToActivate(
      onTap: onTap,
      onHold: cell.channel == null ? null : onHold,
      child: _MultiviewCellTile(
        focusNode: cell.focusNode,
        channel: cell.channel,
        controller: cell.controller,
        active: active,
        isSwapSource: isSource,
        isSwapTarget: isTarget,
        onTap: onTap,
        onLongPress: cell.channel == null ? null : onHold,
        onFocused: () {
          if (_swapMode) {
            setState(() => _swapTarget = index);
          } else {
            _setActive(index);
          }
        },
        widthBoost: 1,
        fill: true,
        bare: full,
        alignment: Alignment.center,
        badge: badge,
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

/// Swap mode: gold flash and source badge over the tile.
class _SwapSourceBadge extends StatefulWidget {
  const _SwapSourceBadge({required this.swaps});

  final int swaps;

  @override
  State<_SwapSourceBadge> createState() => _SwapSourceBadgeState();
}

class _SwapSourceBadgeState extends State<_SwapSourceBadge>
    with SingleTickerProviderStateMixin {
  late final _flash = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void didUpdateWidget(_SwapSourceBadge old) {
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
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                border: Border.all(color: Colors.amber, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swap_horiz, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(tr('SWAP FROM'),
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwapTargetBadge extends StatelessWidget {
  const _SwapTargetBadge();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                border: Border.all(color: Colors.cyanAccent, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app, color: Colors.cyanAccent, size: 14),
                  const SizedBox(width: 4),
                  Text(tr('SWAP TO'),
                      style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwapModePill extends StatefulWidget {
  const _SwapModePill({this.isTwoScreens = false});

  final bool isTwoScreens;

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
        opacity: Tween(begin: 0.45, end: 1.0).animate(_blink),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            border: Border.all(color: Colors.amber, width: 2),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black87, blurRadius: 12, spreadRadius: 3),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_horiz, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(tr('SWAP MODE'),
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
              const SizedBox(width: 12),
              Text(
                widget.isTwoScreens
                    ? tr('OK / arrows / tap to swap Â· Back to finish')
                    : tr('Arrows to choose target Â· OK or tap to swap Â· Back to finish'),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
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
    this.bare = false,
    this.onFocused,
    this.badge,
    this.isSwapSource = false,
    this.isSwapTarget = false,
  });

  final bool isSwapSource;
  final bool isSwapTarget;

  /// Drawn over the video (Swap mode's flash on the big screen).
  final Widget? badge;

  /// Full screen: no frame, no rounded corners.
  final bool bare;

  /// Focus landed on this tile (the sound follows it).
  final VoidCallback? onFocused;

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
          onFocusChange: (f) {
            setState(() => _focused = f);
            if (f) widget.onFocused?.call();
          },
          child: Container(
            decoration: BoxDecoration(
              border: widget.bare
                  ? null
                  : Border.all(
                      color: widget.isSwapSource
                          ? Colors.amber
                          : widget.isSwapTarget
                              ? Colors.cyanAccent
                              : widget.active
                                  ? Colors.amber
                                  : (_focused ? Colors.white : Colors.white24),
                      width: widget.isSwapSource ||
                              widget.isSwapTarget ||
                              widget.active ||
                              _focused
                          ? 3
                          : 1,
                    ),
              borderRadius: BorderRadius.circular(widget.bare ? 0 : 8),
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
                  ? multiviewVideo(widget.controller!)
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
  const _ChannelPickerScreen(
      {required this.channels,
      required this.favorites,
      this.groupOrder = const []});

  final List<Channel> channels;

  /// The TV tab's Favourites, in its order.
  final List<Channel> favorites;

  /// The TV tab's group titles in its order; groups not in it follow.
  final List<String> groupOrder;

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

  /// 'All', 'Favorites' (only when [widget.favorites] isn't empty, from
  /// the TV tab), then every real group name in first-seen order.
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
    final rank = <String, int>{};
    for (final t in widget.groupOrder) {
      rank.putIfAbsent(t, () => rank.length);
    }
    final firstSeen = {for (var i = 0; i < groups.length; i++) groups[i]: i};
    groups.sort((a, b) {
      final ra = rank[a], rb = rank[b];
      if (ra != null && rb != null) return ra.compareTo(rb);
      if (ra != null) return -1;
      if (rb != null) return 1;
      return firstSeen[a]!.compareTo(firstSeen[b]!);
    });
    final hasFavorites = widget.favorites.isNotEmpty;
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
      base = widget.favorites;
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
