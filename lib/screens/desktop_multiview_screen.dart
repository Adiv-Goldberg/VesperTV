import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

import '../models/channel.dart';
import '../services/epg_service.dart';
import '../services/multiview_sports.dart';
import '../services/playlist_manager.dart';
import '../services/storage_service.dart';
import '../widgets/auto_hide_overlay.dart';
import '../widgets/game_channel_chooser.dart';
import '../l10n/l10n.dart';
import '../services/desktop_stream_setup.dart';
import '../services/desktop_live_recovery.dart';

/// Windows-only: a grid of simultaneously-playing live channels —
/// requested directly, citing TiviMate's own multiview (proven to run
/// fine even on a Fire Stick) and that a Windows PC has far more headroom
/// than any box this app otherwise targets. Each cell owns a completely
/// independent `media_kit` `Player`/`VideoController` — safe to run
/// several at once the same way `DesktopMiniPlayer`'s preview box already
/// is (see its own doc comment): `media_kit`'s texture-based rendering
/// supports many simultaneous `Video` widgets, unlike `video_player_hdr`'s
/// platform views, which is exactly why this exists only here and not on
/// mobile/TV. Deliberately standalone, same "doesn't touch
/// PlaybackService" shape as `DesktopPlayerScreen` — see that screen's own
/// doc comment for the fuller reasoning this one shares.
///
/// Only one cell's audio plays at a time (every other `Player` is muted,
/// not paused — all four keep decoding/rendering their video live) —
/// tapping a filled cell makes it the audio-focused one, mirroring
/// TiviMate's own "tap to swap audio" multiview behavior rather than
/// trying to invent a different convention.
class DesktopMultiviewScreen extends StatefulWidget {
  const DesktopMultiviewScreen({super.key});

  @override
  State<DesktopMultiviewScreen> createState() => _DesktopMultiviewScreenState();
}

class _MultiviewCell {
  Channel? channel;
  Player? player;
  VideoController? controller;

  /// See `DesktopPlayerScreen`'s identical field's doc comment — mpv's
  /// native reconnect config doesn't reliably catch every way a live
  /// stream can end up reporting `completed` on its own, so this forces
  /// a fresh re-open whenever that happens instead.
  StreamSubscription<bool>? completedSubscription;
}

/// Requested directly: a smaller, 2-channel layout alongside the
/// original 4-channel grid — fewer simultaneous decode sessions when you
/// only actually want to watch two things, and each cell gets twice the
/// width to show it. [DesktopMultiviewScreen] always keeps 4 `_cells`
/// allocated regardless of which is active; only [dual]'s own two extra
/// cells get disposed when switching down to it (see [_setLayout]) to
/// actually free their connections rather than just hiding them.
enum _MultiviewLayout { dual, quad }

class _DesktopMultiviewScreenState extends State<DesktopMultiviewScreen> {
  static const _cellCount = 4;
  final List<_MultiviewCell> _cells =
      List.generate(_cellCount, (_) => _MultiviewCell());
  int _activeCell = 0;
  _MultiviewLayout _layout = _MultiviewLayout.quad;

  void _setLayout(_MultiviewLayout layout) {
    if (layout == _layout) return;
    if (layout == _MultiviewLayout.dual) {
      // Actually free cells 2/3's connections/decode sessions, not just
      // hide them — leaving them playing, muted, off-screen would still
      // hold a connection slot and a decoder for nothing visible.
      for (var i = 2; i < _cellCount; i++) {
        _cells[i].completedSubscription?.cancel();
        DesktopLiveRecovery.disposePlayer(_cells[i].player);
        _cells[i] = _MultiviewCell();
      }
      if (_activeCell >= 2) _activeCell = 0;
    }
    setState(() => _layout = layout);
  }

  @override
  void dispose() {
    for (final cell in _cells) {
      cell.completedSubscription?.cancel();
      DesktopLiveRecovery.disposePlayer(cell.player);
    }
    super.dispose();
  }

  void _assign(int index, Channel channel) {
    final cell = _cells[index];
    cell.completedSubscription?.cancel();
    DesktopLiveRecovery.disposePlayer(cell.player);
    final player = Player();
    // See DesktopPlayerScreen's identical fix for the full story —
    // reconnect_streamed=1 is necessary (not optional) to recover from a
    // genuine dropped read on a live/non-seekable stream, which is exactly
    // what reconnect_streamed governs; reconnect_on_network_error doesn't
    // cover it (that one's only for failures during the initial connect).
    // rw_timeout is what avoids reopening the *original* hang-forever bug
    // reconnect_streamed=0 was first added for: it bounds any single
    // blocked read/write (including a hanging Range-reconnect attempt on a
    // server that doesn't support it) to a fixed ceiling instead of
    // letting it hang forever, so ffmpeg's own reconnect loop can retry.
    configureDesktopStreamPlayer(player, 'multiview');
    final controller = desktopVideoController(player);
    unawaited(openDesktopStream(player, channel)
        .then((_) => DesktopLiveRecovery.of(player).watch(channel)));
    player.setVolume(index == _activeCell ? 100 : 0);
    // Reconnects: DesktopLiveRecovery (waits, retries, copies).
    setState(() {
      cell.channel = channel;
      cell.player = player;
      cell.controller = controller;
      cell.completedSubscription = null;
    });
  }

  /// Same manual-relaunch idea as `DesktopPlayerScreen._reload`/
  /// `PlayerControls`' own Reload button — for a cell that's silently
  /// stalled (frozen frame, no error), requested directly for every
  /// multiview cell the same way.
  void _reload(int index) {
    final cell = _cells[index];
    final channel = cell.channel;
    if (channel == null) return;
    final player = cell.player;
    if (player == null) return;
    unawaited(openDesktopStream(player, channel)
        .then((_) => DesktopLiveRecovery.of(player).watch(channel)));
  }

  void _clear(int index) {
    _cells[index].completedSubscription?.cancel();
    DesktopLiveRecovery.disposePlayer(_cells[index].player);
    setState(() => _cells[index] = _MultiviewCell());
  }

  void _setActive(int index) {
    if (_cells[index].channel == null) return;
    setState(() => _activeCell = index);
    for (var i = 0; i < _cells.length; i++) {
      _cells[i].player?.setVolume(i == _activeCell ? 100 : 0);
    }
  }

  Future<void> _openPicker(int index) async {
    final playlist = context.read<PlaylistManager>();
    final channels = playlist.visibleChannels(category: 'tv');
    final chosen = await showDialog<Channel>(
      context: context,
      builder: (_) => _ChannelPickerDialog(channels: channels),
    );
    if (chosen != null) _assign(index, chosen);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: tr('Back'),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(tr('Multiview'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    PopupMenuButton<_MultiviewLayout>(
                      tooltip: tr('Layout'),
                      icon: const Icon(Icons.grid_view, color: Colors.white),
                      onSelected: _setLayout,
                      itemBuilder: (context) => [
                        CheckedPopupMenuItem(
                          value: _MultiviewLayout.dual,
                          checked: _layout == _MultiviewLayout.dual,
                          child: Text(tr('2 channels')),
                        ),
                        CheckedPopupMenuItem(
                          value: _MultiviewLayout.quad,
                          checked: _layout == _MultiviewLayout.quad,
                          child: Text(tr('4 channels')),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.volume_up, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(tr('= audio — click a channel to switch'),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  // Stacked (Column), not side-by-side — requested
                  // directly: splitting a landscape screen into left/
                  // right halves squeezes each cell into a tall, narrow
                  // near-square, badly distorting a widescreen video's
                  // actual shape. Splitting top/bottom instead lets each
                  // cell span the full screen width, keeping something
                  // much closer to its real aspect ratio even though it's
                  // shorter.
                  // The cell *frame* (border/header/buttons) fills the
                  // whole row, same as a quad cell fills its quarter —
                  // constraining the whole frame to 16:9 (an earlier
                  // version of this fix) made dual cells look noticeably
                  // smaller than quad's. Only the video itself is aspect-
                  // constrained now (inside `_buildCell`), letterboxing
                  // within the full-size frame instead of shrinking the
                  // frame around it.
                  // Flex 13:7 instead of a flat 50/50 split when only one
                  // of the two cells actually has a channel in it — a
                  // plain even split made a single active stream look
                  // small (letterboxed within an exactly-half-height row),
                  // reported directly as needing to be "bigger by 30%".
                  // 13:7 gives the occupied row exactly 65% of the
                  // available height, i.e. 1.3x the even-split baseline —
                  // once both cells are filled they're back to equal flex
                  // (13:13) and split evenly like a normal multiview grid.
                  child: _layout == _MultiviewLayout.dual
                      ? Column(
                          children: [
                            Expanded(
                                flex: _cells[0].channel != null ? 13 : 7,
                                child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: _buildCell(0))),
                            Expanded(
                                flex: _cells[1].channel != null ? 13 : 7,
                                child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: _buildCell(1))),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Padding(
                                          padding: const EdgeInsets.all(3),
                                          child: _buildCell(0))),
                                  Expanded(
                                      child: Padding(
                                          padding: const EdgeInsets.all(3),
                                          child: _buildCell(1))),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Padding(
                                          padding: const EdgeInsets.all(3),
                                          child: _buildCell(2))),
                                  Expanded(
                                      child: Padding(
                                          padding: const EdgeInsets.all(3),
                                          child: _buildCell(3))),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int index) {
    final cell = _cells[index];
    final active = index == _activeCell && cell.channel != null;
    return InkWell(
      onTap: () =>
          cell.channel == null ? _openPicker(index) : _setActive(index),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: active ? Colors.amber : Colors.white24,
              width: active ? 3 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        // The name bar fades after a few seconds (it covered the score
        // bug); it's back on a new channel, when the sound moves here, and
        // while the mouse is over the tile (its buttons live there).
        child: AutoHideOverlay(
          flashKey: (cell.channel?.id, active),
          hidden: active ? const MultiviewAudioBadge() : null,
          video: cell.controller != null
              // AspectRatio wraps only the video, not the frame around it
              // — media_kit's Video widget has no fit/letterbox option of
              // its own and otherwise just stretches to fill whatever box
              // it's handed.
              ? Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Video(
                        controller: cell.controller!,
                        controls: NoVideoControls),
                  ),
                )
              : const ColoredBox(
                  color: Color(0xFF1A1A1A),
                  child: Center(
                    child: Icon(Icons.add_circle_outline,
                        color: Colors.white38, size: 40),
                  ),
                ),
          overlay: cell.channel == null
              ? const SizedBox.shrink()
              : Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                        if (active) ...[
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
                            cell.channel!.name,
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
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Colors.white70, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: tr('Reload'),
                          onPressed: () => _reload(index),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.swap_horiz,
                              color: Colors.white70, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: tr('Change channel'),
                          onPressed: () => _openPicker(index),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white70, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: tr('Remove'),
                          onPressed: () => _clear(index),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// A plain search-and-pick list — the live channel list this draws from
/// can run into the tens of thousands across every enabled playlist (see
/// `PlaylistManager.visibleChannels`), so a simple substring filter over
/// a lazily-built `ListView` is what keeps this responsive rather than
/// anything fancier.
class _ChannelPickerDialog extends StatefulWidget {
  const _ChannelPickerDialog({required this.channels});

  final List<Channel> channels;

  @override
  State<_ChannelPickerDialog> createState() => _ChannelPickerDialogState();
}

/// The picker's quick filters: every channel, games playing now (with
/// their matched channel) and sports channels — see [MultiviewSports].
enum _PickerFilter { all, live, sports }

class _ChannelPickerDialogState extends State<_ChannelPickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';
  _PickerFilter _filter = _PickerFilter.all;

  /// Loaded the first time Live now is picked; null until then.
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Live now: one row per game; search matches the game or its channels.
    final live = MultiviewSports.search(_live ?? const [], _query);
    final Iterable<Channel> base = switch (_filter) {
      _PickerFilter.all => widget.channels,
      _PickerFilter.live => [for (final l in live) l.channel],
      _PickerFilter.sports => widget.channels.where(MultiviewSports.isSports),
    };
    final q = _query.toLowerCase();
    final filtered = q.isEmpty || _filter == _PickerFilter.live
        ? base.toList()
        : base.where((c) => c.name.toLowerCase().contains(q)).toList();
    Widget chip(_PickerFilter f, String label, IconData icon) => ChoiceChip(
          avatar: Icon(icon, size: 18),
          label: Text(label),
          selected: _filter == f,
          onSelected: (_) {
            setState(() => _filter = f);
            if (f == _PickerFilter.live) _loadLive();
          },
        );
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      child: SizedBox(
        width: 480,
        height: 560,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              // tv-text-field-gate: exempt — Windows only (no TV keyboard).
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: tr('Search channels...'),
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Wrap(spacing: 8, children: [
                chip(_PickerFilter.all, tr('All'), Icons.apps),
                chip(_PickerFilter.live, tr('Live now'), Icons.sports_score),
                chip(_PickerFilter.sports, tr('Sports'), Icons.sports),
              ]),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: _filter == _PickerFilter.live && _live == null
                          ? const CircularProgressIndicator()
                          : Text(
                              _filter == _PickerFilter.live
                                  ? tr(
                                      'No live games on your channels right now')
                                  : tr('No channels found'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white54)),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final c = filtered[i];
                        final row =
                            _filter == _PickerFilter.live && i < live.length
                                ? live[i]
                                : null;
                        if (row != null) {
                          final n = row.matches.length;
                          return ListTile(
                            leading: const Icon(Icons.sports_score,
                                color: Colors.white54),
                            title: Text(MultiviewSports.label(row.game),
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                                n > 1
                                    ? '${c.name} · ${tr('{n} channels', {
                                            'n': n
                                          })}'
                                    : c.name,
                                style: const TextStyle(color: Colors.white54)),
                            trailing: n > 1
                                ? const Icon(Icons.chevron_right,
                                    color: Colors.white54)
                                : null,
                            onTap: () async {
                              final navigator = Navigator.of(context);
                              final picked =
                                  await chooseGameChannel(context, row);
                              if (picked != null && mounted) {
                                navigator.pop(picked);
                              }
                            },
                          );
                        }
                        return ListTile(
                          leading: (c.logoUrl != null && c.logoUrl!.isNotEmpty)
                              ? Image.network(c.logoUrl!,
                                  width: 32,
                                  height: 32,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.tv,
                                      color: Colors.white54))
                              : const Icon(Icons.tv, color: Colors.white54),
                          title: Text(c.name,
                              style: const TextStyle(color: Colors.white)),
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
