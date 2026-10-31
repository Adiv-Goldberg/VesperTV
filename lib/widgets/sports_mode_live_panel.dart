import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../services/app_preferences.dart';
import '../services/epg_service.dart';
import '../services/playback_service.dart';
import '../services/playlist_manager.dart';
import '../services/storage_service.dart';
import '../utils/live_group_sort.dart';
import '../utils/time_format.dart';
import 'sports_widgets.dart';

/// Sports Mode's own Live TV (owner, 2026-10-28): a groups column that pushes
/// the sports page right and a see-through channel guide over it, so channels
/// can be browsed without leaving Sports Mode. OK on a channel = full screen,
/// Back from there returns here with both still open. Back walks guide ->
/// groups -> closed ([back]).
///
/// Deliberately not the TV home's live list (TvHomeScreen is untouched): one
/// focus node per column with its own index, fixed-extent lazy lists and
/// `jumpTo`, so a big group costs only the rows on screen (CLAUDE.md §10).
class SportsModeLivePanel extends StatefulWidget {
  const SportsModeLivePanel({
    super.key,
    required this.onPlay,
    required this.onLeft,
    required this.onOpenFull,
    this.onRight,
  });

  /// Right from the groups with no guide open: into the sports page (owner,
  /// 2026-10-29: OK opens a group's guide, Right means "go right").
  final VoidCallback? onRight;

  /// OK on a channel: full screen, [list] being the guide's channels (CH+/-).
  final Future<void> Function(Channel channel, List<Channel> list) onPlay;

  /// Left from the groups column (the rail).
  final VoidCallback onLeft;

  /// "Open full Live TV": the regular TV home, for everything not here.
  final VoidCallback onOpenFull;

  static const groupsWidth = 230.0;
  static const guideWidth = 440.0;

  @override
  State<SportsModeLivePanel> createState() => SportsModeLivePanelState();
}

/// One groups-column row: the full Live TV link, Favourites, an own group or
/// a playlist's group.
class _Group {
  const _Group(this.key, this.title, this.icon,
      {this.playlistId, this.playlistName});
  final String key;
  final String title;
  final IconData icon;
  final String? playlistId;
  final String? playlistName;
}

const _fullKey = 'full';
const _favoritesKey = 'favorites';

class SportsModeLivePanelState extends State<SportsModeLivePanel> {
  // Remembered for the app session, like the TV home's last group.
  static String? _lastGroupKey;
  static int _lastChannelIndex = 0;

  final _groupsNode = FocusNode(debugLabel: 'sports-live-groups');
  final _guideNode = FocusNode(debugLabel: 'sports-live-guide');
  final _groupsScroll = ScrollController();
  final _guideScroll = ScrollController();

  static const _groupExtent = 46.0;
  static const _channelExtent = 64.0;

  int _groupIndex = 0;
  int _channelIndex = 0;

  /// The group the guide shows (null = guide closed).
  String? _openKey;

  List<_Group> _groups = const [];
  List<Channel> _channels = const [];

  bool get guideOpen => _openKey != null;

  @override
  void initState() {
    super.initState();
    _groupsNode.addListener(_repaint);
    _guideNode.addListener(_repaint);
    // Sports Mode can be the root: the live lists load after launch.
    context.read<PlaylistManager>().ensureLiveChannelsLoaded();
  }

  void _repaint() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _groupsNode.dispose();
    _guideNode.dispose();
    _groupsScroll.dispose();
    _guideScroll.dispose();
    super.dispose();
  }

  /// Focus the groups column on the last group (first open) or the current.
  void focusGroups() {
    _groupsNode.requestFocus();
    _keepVisible(_groupsScroll, _groupIndex, _groupExtent);
  }

  /// The remote's Guide button: the guide on the playing channel's group
  /// (else the last group, else the first channel group), focus on the
  /// playing channel.
  void openGuide() {
    if (_groups.isEmpty) return;
    final playing = context.read<PlaybackService>().liveChannel;
    var index = playing == null
        ? -1
        : _groups.indexWhere(
            (g) => g.key == '${playing.playlistId}::${playing.group}');
    if (index < 0 && _lastGroupKey != null) {
      index = _groups.indexWhere((g) => g.key == _lastGroupKey);
    }
    if (index < 0) index = _groups.indexWhere((g) => g.key != _fullKey);
    if (index < 0) return;
    if (_groupsScroll.hasClients) {
      _keepVisible(_groupsScroll, index, _groupExtent);
    }
    _openGroup(index);
  }

  /// Back to the guide (after full screen), else the groups.
  void focusLast() => guideOpen ? _focusGuide() : focusGroups();

  void _focusGuide() {
    _guideNode.requestFocus();
    _keepVisible(_guideScroll, _channelIndex, _channelExtent);
  }

  /// Back: closes the guide (true), or says the panel should close (false).
  bool back() {
    if (guideOpen) {
      setState(() => _openKey = null);
      focusGroups();
      return true;
    }
    return false;
  }

  List<_Group> _buildGroups(PlaylistManager playlist) {
    final prefs = context.read<AppPreferences>();
    final hidden = context.read<StorageService>().getHiddenPlaylistGroups('tv');
    final visible = playlist.tvGroups
        .where((g) => !g.isHidden && !hidden.contains(g.playlistId))
        .toList();
    final sort = prefs.liveGroupSort;
    final ids = visible.map((g) => g.playlistId).toSet();
    final named = ids.length > 1;
    return [
      _Group(_fullKey, tr('Open full Live TV'), Icons.open_in_new),
      _Group(_favoritesKey, tr('Favourites'), Icons.star),
      for (final title in sort.sorted(playlist.userGroups, (t) => t))
        _Group('my::$title', title, Icons.folder_special_outlined),
      for (final id in ids)
        for (final g in sort.sorted(
            visible.where((g) => g.playlistId == id), (g) => g.title))
          _Group('$id::${g.title}', g.title, Icons.grid_view_rounded,
              playlistId: id,
              playlistName: named ? playlist.playlistNameFor(id) : null),
    ];
  }

  List<Channel> _channelsFor(PlaylistManager playlist, String key) {
    if (key == _favoritesKey) {
      return playlist.orderedFavoriteLiveChannels(
          mixPlaylists: context.read<AppPreferences>().mixFavoritePlaylists);
    }
    final group = _groups.where((g) => g.key == key).firstOrNull;
    if (group == null) return const [];
    return playlist.visibleChannels(
        playlistId: group.playlistId, groupTitle: group.title, category: 'tv');
  }

  void _keepVisible(ScrollController scroll, int index, double extent) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scroll.hasClients) return;
      final pos = scroll.position;
      final top = index * extent;
      double? to;
      if (top < pos.pixels) {
        to = top;
      } else if (top + extent > pos.pixels + pos.viewportDimension) {
        to = top + extent - pos.viewportDimension;
      }
      if (to != null) {
        scroll.jumpTo(to.clamp(0.0, pos.maxScrollExtent));
      }
    });
  }

  void _openGroup(int index) {
    if (index < 0 || index >= _groups.length) return;
    final group = _groups[index];
    if (group.key == _fullKey) {
      widget.onOpenFull();
      return;
    }
    final reopen = group.key == _lastGroupKey;
    _lastGroupKey = group.key;
    final channels = _channelsFor(context.read<PlaylistManager>(), group.key);
    final playing = context.read<PlaybackService>().liveChannel?.id;
    final playingIndex = channels.indexWhere((c) => c.id == playing);
    setState(() {
      _groupIndex = index;
      _openKey = group.key;
      _channelIndex = playingIndex >= 0
          ? playingIndex
          : reopen
              ? _lastChannelIndex.clamp(
                  0, channels.isEmpty ? 0 : channels.length - 1)
              : 0;
    });
    if (_guideScroll.hasClients) _guideScroll.jumpTo(0);
    _focusGuide();
  }

  bool _isActivate(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.gameButtonA;

  int _step(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowDown) return 1;
    if (key == LogicalKeyboardKey.arrowUp) return -1;
    if (key == LogicalKeyboardKey.channelDown ||
        key == LogicalKeyboardKey.pageDown) {
      return 8;
    }
    if (key == LogicalKeyboardKey.channelUp ||
        key == LogicalKeyboardKey.pageUp) {
      return -8;
    }
    return 0;
  }

  KeyEventResult _onGroupsKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final step = _step(key);
    if (step != 0) {
      if (_groups.isEmpty) return KeyEventResult.handled;
      setState(() =>
          _groupIndex = (_groupIndex + step).clamp(0, _groups.length - 1));
      _keepVisible(_groupsScroll, _groupIndex, _groupExtent);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      widget.onLeft();
      return KeyEventResult.handled;
    }
    // Right: into the open guide, else into the sports page.
    if (key == LogicalKeyboardKey.arrowRight && event is KeyDownEvent) {
      if (guideOpen) {
        _focusGuide();
      } else {
        widget.onRight?.call();
      }
      return KeyEventResult.handled;
    }
    // A held OK repeats: open once.
    if (_isActivate(key) && event is KeyDownEvent) {
      _openGroup(_groupIndex);
      return KeyEventResult.handled;
    }
    return key == LogicalKeyboardKey.arrowRight
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  KeyEventResult _onGuideKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final step = _step(key);
    if (step != 0) {
      if (_channels.isEmpty) return KeyEventResult.handled;
      setState(() => _channelIndex =
          (_channelIndex + step).clamp(0, _channels.length - 1));
      _lastChannelIndex = _channelIndex;
      _keepVisible(_guideScroll, _channelIndex, _channelExtent);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      focusGroups();
      return KeyEventResult.handled;
    }
    // Right from a channel: into the sports page, like Right on a group
    // (owner, 2026-10-31: the guide collapses and the page takes focus).
    if (key == LogicalKeyboardKey.arrowRight) {
      if (event is KeyDownEvent) {
        // Close the guide first (as Back does), then hand focus to the page.
        setState(() => _openKey = null);
        widget.onRight?.call();
      }
      return KeyEventResult.handled;
    }
    if (_isActivate(key)) {
      if (event is KeyDownEvent) _play(_channelIndex);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _play(int index) {
    if (index < 0 || index >= _channels.length) return;
    _channelIndex = index;
    _lastChannelIndex = index;
    widget.onPlay(_channels[index], List.of(_channels));
  }

  @override
  Widget build(BuildContext context) {
    final playlist = context.watch<PlaylistManager>();
    context.watch<AppPreferences>();
    _groups = _buildGroups(playlist);
    if (_groups.isNotEmpty) {
      if (_lastGroupKey != null && !_groupsNode.hasFocus && !guideOpen) {
        final i = _groups.indexWhere((g) => g.key == _lastGroupKey);
        if (i >= 0) _groupIndex = i;
      }
      _groupIndex = _groupIndex.clamp(0, _groups.length - 1);
    }
    if (_openKey != null && !_groups.any((g) => g.key == _openKey)) {
      _openKey = null;
    }
    _channels = _openKey == null ? const [] : _channelsFor(playlist, _openKey!);
    if (_channels.isNotEmpty) {
      _channelIndex = _channelIndex.clamp(0, _channels.length - 1);
    }
    return Row(
      key: const ValueKey('sports-live-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
            width: SportsModeLivePanel.groupsWidth,
            child: _buildGroupsColumn()),
        if (guideOpen)
          SizedBox(width: SportsModeLivePanel.guideWidth, child: _buildGuide()),
      ],
    );
  }

  Widget _frame(
          {required Key key,
          required String title,
          required Widget child,
          double alpha = .55}) =>
      Container(
        key: key,
        margin: const EdgeInsets.fromLTRB(8, 8, 0, 8),
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 8),
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800))),
          Expanded(child: child),
        ]),
      );

  Widget _buildGroupsColumn() {
    final scheme = Theme.of(context).colorScheme;
    final focused = _groupsNode.hasFocus;
    return _frame(
      key: const ValueKey('sports-live-groups'),
      title: tr('Live TV'),
      child: Focus(
        focusNode: _groupsNode,
        onKeyEvent: _onGroupsKey,
        child: ListView.builder(
          controller: _groupsScroll,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          itemExtent: _groupExtent,
          itemCount: _groups.length,
          itemBuilder: (context, i) {
            final g = _groups[i];
            final current = i == _groupIndex;
            final open = g.key == _openKey;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _groupsNode.requestFocus();
                setState(() => _groupIndex = i);
                _openGroup(i);
              },
              child: _Row(
                focused: focused && current,
                marked: open || (!focused && current && !guideOpen),
                scheme: scheme,
                child: Row(children: [
                  Icon(g.icon,
                      size: 18,
                      color: g.key == _favoritesKey
                          ? Colors.amber
                          : Colors.white70),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(g.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14))),
                  if (g.playlistName != null)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 64),
                      child: Text(g.playlistName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white38)),
                    ),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGuide() {
    final scheme = Theme.of(context).colorScheme;
    final focused = _guideNode.hasFocus;
    final title =
        _groups.where((g) => g.key == _openKey).firstOrNull?.title ?? '';
    final playing = context.watch<PlaybackService>().liveChannel?.id;
    return _frame(
      key: const ValueKey('sports-live-guide'),
      title: title,
      alpha: .78,
      child: Focus(
        focusNode: _guideNode,
        onKeyEvent: _onGuideKey,
        child: _channels.isEmpty
            ? Center(
                child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                    _openKey == _favoritesKey
                        ? tr(
                            'No favorite channels yet — press Down while watching one to add it.')
                        : tr('No channels found.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70)),
              ))
            : ListView.builder(
                key: ValueKey('sports-live-guide-$_openKey'),
                controller: _guideScroll,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemExtent: _channelExtent,
                itemCount: _channels.length,
                itemBuilder: (context, i) {
                  final channel = _channels[i];
                  final current = i == _channelIndex;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _guideNode.requestFocus();
                      setState(() => _channelIndex = i);
                      _play(i);
                    },
                    child: _Row(
                      focused: focused && current,
                      marked: !focused && current,
                      scheme: scheme,
                      child: _ChannelRow(
                          channel: channel, playing: channel.id == playing),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// A row's gold focus look (same sheen as the rail) or a quiet mark for the
/// column's current row while another column has the focus.
class _Row extends StatelessWidget {
  const _Row(
      {required this.focused,
      required this.marked,
      required this.scheme,
      required this.child});
  final bool focused;
  final bool marked;
  final ColorScheme scheme;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: focused ? sportsFocusSheen(scheme) : null,
          color: focused
              ? null
              : marked
                  ? scheme.primary.withValues(alpha: .12)
                  : Colors.transparent,
          border: Border.all(
              width: 2, color: focused ? scheme.primary : Colors.transparent),
        ),
        alignment: Alignment.centerLeft,
        child: child,
      );
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.channel, required this.playing});
  final Channel channel;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final epg = context.watch<EpgService>();
    final now = epg.getCurrentProgram(channel.epgId);
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final logo = channel.logoUrl;
    double? progress;
    if (now != null) {
      final total = now.stop.difference(now.start).inSeconds;
      if (total > 0) {
        progress = (DateTime.now().difference(now.start).inSeconds / total)
            .clamp(0.0, 1.0);
      }
    }
    return Row(children: [
      SizedBox(
        width: 44,
        height: 40,
        child: logo != null && logo.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: logo,
                fit: BoxFit.contain,
                memCacheWidth: (44 * dpr).round(),
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.tv, color: Colors.white54))
            : const Icon(Icons.tv, color: Colors.white54),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (playing)
                const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child:
                        Icon(Icons.play_arrow, size: 16, color: Colors.amber)),
              Expanded(
                  child: Text(channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700))),
              if (channel.isFavorite)
                const Icon(Icons.star, size: 14, color: Colors.amber),
            ]),
            const SizedBox(height: 2),
            Text(
                now == null
                    ? tr('No program data')
                    : '${TimeFormat.hm.format(now.start.toLocal())}  ${now.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
            if (progress != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 2,
                      backgroundColor: Colors.white12),
                ),
              ),
          ],
        ),
      ),
    ]);
  }
}
