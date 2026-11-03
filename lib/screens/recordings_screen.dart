import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../services/recording_service.dart';
import '../utils/constants.dart';
import '../utils/time_format.dart';
import '../utils/tv_theme.dart';
import '../widgets/hold_to_activate.dart';
import '../widgets/settings_scaffold.dart';
import '../widgets/sports_widgets.dart';
import '../widgets/tv_menu_tile.dart';
import 'player_screen.dart';

/// The Recordings tab (Android): what's recording, what's scheduled, and
/// what's been recorded. A game shows as a Sports Trak style card with
/// both teams (never the score); a channel recording as a card with the
/// channel's logo and the guide programme that was on. OK = play (a
/// recording in progress plays live through the recorder's tap), hold
/// OK = Play from the start / Stop / Cancel / Delete.
class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  final _service = RecordingService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_changed);
    unawaited(_service.init().then((_) => _service.refreshStatus()));
  }

  @override
  void dispose() {
    _service.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _open(RecordingEntry r) async {
    if (r.state == RecState.recording) {
      // Live, from the recorder's tap (PlaybackService.openUrlFor).
      return _push(_liveChannel(r));
    }
    if (r.playable) return _push(_service.channelFor(r));
    return _menu(r);
  }

  Channel _liveChannel(RecordingEntry r) {
    final i = r.channelId.indexOf('::');
    return Channel(
      id: r.channelId,
      rawId: i < 0 ? r.channelId : r.channelId.substring(i + 2),
      playlistId: r.playlistId,
      name: r.channelName,
      group: r.league,
      url: r.url,
      logoUrl: r.channelLogo,
    );
  }

  Future<void> _push(Channel c) => Navigator.of(context)
      .push(PlayerPageRoute(builder: (_) => PlayerScreen(channel: c)));

  Future<void> _menu(RecordingEntry r) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => SwallowHeldActivate(
        child: AlertDialog(
          backgroundColor: const Color(0xFF15151A),
          title: Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (r.state == RecState.recording) ...[
                  TvMenuTile(
                    autofocus: true,
                    icon: Icons.live_tv,
                    title: tr('Watch live'),
                    subtitle: r.channelName,
                    onTap: () => Navigator.of(context).pop('live'),
                  ),
                  if (r.bytes > 0)
                    TvMenuTile(
                      icon: Icons.replay,
                      title: tr('Play from the start'),
                      subtitle: tr('What has been recorded so far'),
                      onTap: () => Navigator.of(context).pop('play'),
                    ),
                  TvMenuTile(
                    icon: Icons.stop_circle_outlined,
                    title: tr('Stop recording'),
                    subtitle: tr('Keeps what has been recorded'),
                    onTap: () => Navigator.of(context).pop('stop'),
                  ),
                ] else if (r.state == RecState.scheduled ||
                    r.state == RecState.waiting)
                  TvMenuTile(
                    autofocus: true,
                    icon: Icons.event_busy,
                    title: tr('Cancel recording'),
                    subtitle: _when(r),
                    onTap: () => Navigator.of(context).pop('stop'),
                  )
                else if (r.playable)
                  TvMenuTile(
                    autofocus: true,
                    icon: Icons.play_arrow,
                    title: tr('Play'),
                    subtitle: _size(r.bytes),
                    onTap: () => Navigator.of(context).pop('play'),
                  ),
                if (r.state != RecState.scheduled &&
                    r.state != RecState.waiting &&
                    r.state != RecState.recording)
                  TvMenuTile(
                    autofocus: !r.playable,
                    icon: Icons.delete_outline,
                    title: tr('Delete recording'),
                    subtitle: r.bytes > 0
                        ? tr('Frees {size}', {'size': _size(r.bytes)})
                        : tr('Removes it from the list'),
                    onTap: () => Navigator.of(context).pop('delete'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'live':
        await _push(_liveChannel(r));
      case 'play':
        await _push(_service.channelFor(r));
      case 'stop':
        await _service.stop(r);
      case 'delete':
        await _service.delete(r);
    }
  }

  static String _size(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    return '${(bytes / (1024 * 1024)).round()} MB';
  }

  static String _when(RecordingEntry r) {
    final start = r.startAt;
    final now = DateTime.now();
    final sameDay = start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
    final day = sameDay ? tr('Today') : DateFormat('EEE d MMM').format(start);
    return '$day ${TimeFormat.hm.format(start)}–${TimeFormat.hm.format(r.endAt)}';
  }

  @override
  Widget build(BuildContext context) {
    final all =
        _service.items.where((r) => r.state != RecState.cancelled).toList();
    final now = all.where((r) => r.state == RecState.recording).toList();
    final upcoming = all
        .where(
            (r) => r.state == RecState.scheduled || r.state == RecState.waiting)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final done = all
        .where((r) =>
            r.state != RecState.recording &&
            r.state != RecState.scheduled &&
            r.state != RecState.waiting)
        .toList();
    final auto = _service.autoTeam;
    var first = true;
    Widget section(String title, List<RecordingEntry> list) {
      final autofocus = first;
      first = false;
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(),
                style: const TextStyle(
                    fontSize: 12, letterSpacing: 1.2, color: Colors.white54)),
            const SizedBox(height: 8),
            Wrap(
              children: [
                for (var i = 0; i < list.length; i++)
                  _RecordingCard(
                    entry: list[i],
                    autofocus: autofocus && i == 0,
                    status: _status(list[i]),
                    onTap: () => _open(list[i]),
                    onHold: () => _menu(list[i]),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return withTvThemeIfNeeded(
      context,
      (context) => SettingsScaffold(
        title: tr('Recordings'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            if (auto != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(children: [
                  Icon(Icons.event_repeat,
                      size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                      tr('Recording every {team} game',
                          {'team': auto.teamName}),
                      style: const TextStyle(color: Colors.white70)),
                ]),
              ),
            if (all.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  tr('Nothing recorded yet. Hold OK on a game in {tab} and pick Record, or hold OK on a live channel.',
                      {'tab': AppConstants.sportsTabName}),
                  style: const TextStyle(color: Colors.white60, fontSize: 16),
                ),
              ),
            if (now.isNotEmpty) section(tr('Recording now'), now),
            if (upcoming.isNotEmpty) section(tr('Scheduled'), upcoming),
            if (done.isNotEmpty) section(tr('Recorded'), done),
            if (all.isNotEmpty)
              Text(
                tr('{used} of {cap} GB used', {
                  'used': _size(_service.usedBytes),
                  'cap': _service.settings.capGb,
                }),
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  String _status(RecordingEntry r) => switch (r.state) {
        RecState.recording => tr('REC · {size}', {'size': _size(r.bytes)}),
        RecState.scheduled => _when(r),
        RecState.waiting => tr('Waiting for a channel'),
        RecState.done ||
        RecState.stopped =>
          '${DateFormat('EEE d MMM').format(r.gameStart)} · ${_size(r.bytes)}',
        RecState.interrupted =>
          tr('Interrupted · {size}', {'size': _size(r.bytes)}),
        RecState.missed => tr('Missed'),
        RecState.failed => tr('Failed'),
        RecState.cancelled => '',
      };
}

class _RecordingCard extends StatefulWidget {
  const _RecordingCard({
    required this.entry,
    required this.status,
    required this.onTap,
    required this.onHold,
    this.autofocus = false,
  });

  final RecordingEntry entry;
  final String status;
  final VoidCallback onTap;
  final VoidCallback onHold;
  final bool autofocus;

  // Same size as a Sports Trak game card.
  static const double width = 268;
  static const double height = 132;

  @override
  State<_RecordingCard> createState() => _RecordingCardState();
}

class _RecordingCardState extends State<_RecordingCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = widget.entry;
    final rec = r.state == RecState.recording;
    final bad = r.state == RecState.failed ||
        r.state == RecState.missed ||
        r.state == RecState.interrupted;

    Widget teamLine(String? logo, String name, String abbr, String? color,
        {String? joiner}) {
      return Row(children: [
        SizedBox(
          width: 22,
          child: joiner == null
              ? const SizedBox()
              : Text(joiner,
                  style: const TextStyle(fontSize: 12, color: Colors.white54)),
        ),
        SportsLogo(url: logo, size: 30, fallback: abbr, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
      ]);
    }

    final body = r.isChannel
        ? Row(children: [
            SportsLogo(
                url: r.channelLogo,
                size: 52,
                fallback: r.channelName.isEmpty
                    ? 'TV'
                    : r.channelName.substring(0, 1),
                color: null),
            const SizedBox(width: 10),
            Expanded(
              child: Text(r.program.isEmpty ? tr('Live channel') : r.program,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ])
        : r.team2.isEmpty
            // Golf / racing: one line, the event.
            ? teamLine(r.logo, r.team1, r.abbr1, r.color1)
            : Column(children: [
                teamLine(r.logo, r.team1, r.abbr1, r.color1),
                const SizedBox(height: 4),
                teamLine(r.logo2, r.team2, r.abbr2, r.color2, joiner: 'vs'),
              ]);

    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 4, bottom: 8),
      child: HoldToActivate(
        onTap: widget.onTap,
        onHold: widget.onHold,
        child: InkWell(
          autofocus: widget.autofocus,
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          onLongPress: widget.onHold,
          onFocusChange: (f) => setState(() => _focused = f),
          child: AnimatedScale(
            scale: _focused ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            child: Container(
              width: _RecordingCard.width,
              height: _RecordingCard.height,
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
              decoration: BoxDecoration(
                color: _focused ? null : Colors.white.withValues(alpha: 0.07),
                gradient: _focused ? sportsFocusSheen(scheme) : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _focused
                        ? scheme.primary
                        : rec
                            ? Colors.redAccent.withValues(alpha: 0.6)
                            : Colors.white10,
                    width: _focused ? 2.5 : 1),
                boxShadow: _focused
                    ? [
                        BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.35),
                            blurRadius: 16)
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(
                          (r.isChannel ? r.channelName : r.league)
                              .toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: 1,
                              color: Colors.white54)),
                    ),
                    const SizedBox(width: 6),
                    if (rec)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.redAccent),
                      ),
                    Text(widget.status,
                        maxLines: 1,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color:
                                rec || bad ? Colors.redAccent : Colors.white)),
                  ]),
                  const Spacer(),
                  body,
                  const Spacer(),
                  if (!r.isChannel && r.channelName.isNotEmpty)
                    Text(r.channelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, color: Colors.white54)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
