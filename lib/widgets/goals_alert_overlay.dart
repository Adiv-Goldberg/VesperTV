import 'popup_surface.dart';
import '../utils/refined_finish.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/app_preferences.dart';
import '../models/sports.dart';
import '../services/goals_alerts.dart';
import '../services/viewer_profile_service.dart';
import 'game_reminder_overlay.dart';

/// App-wide, non-interactive score card. Never requests focus or touches playback.
class GoalsAlertOverlay extends StatefulWidget {
  const GoalsAlertOverlay({super.key});

  /// Settings' "Show a test popup": each bump shows a sample goal card for
  /// 8 s, so the look (e.g. Transparent popups) can be checked any time.
  static final ValueNotifier<int> previewRequests = ValueNotifier(0);
  @override
  State<GoalsAlertOverlay> createState() => _GoalsAlertOverlayState();
}

class _GoalsAlertOverlayState extends State<GoalsAlertOverlay>
    with WidgetsBindingObserver {
  GoalsAlerts? _service;
  String? _viewer;
  bool _enabled = false;
  bool _teamAlerts = false;
  bool _active = true;
  int _epoch = 0;
  Timer? _poll;
  Timer? _hide;
  final _queue = <GoalAlertNotice>[];
  GoalAlertNotice? _notice;
  bool _preview = false;

  @override
  void initState() {
    super.initState();
    GoalsAlertOverlay.previewRequests.addListener(_showPreview);
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _active = state == null || state == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.watch<GoalsAlerts>();
    final viewer = context.watch<ViewerProfileService>().active.id;
    final teamAlerts = context.watch<AppPreferences>().goalsAlert;
    final enabled = service.enabled;
    if (_service != service ||
        _viewer != viewer ||
        _enabled != enabled ||
        _teamAlerts != teamAlerts) {
      _service = service;
      _viewer = viewer;
      _enabled = enabled;
      _teamAlerts = teamAlerts;
      _clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refresh();
      });
    }
  }

  void _clear() {
    _epoch++;
    _poll?.cancel();
    _hide?.cancel();
    _queue.clear();
    _notice = null;
    _service?.reset();
  }

  Future<void> _refresh() async {
    _poll?.cancel();
    if (!mounted || !_active || !_enabled) return;
    final epoch = _epoch;
    try {
      final notices = await _service!.poll();
      if (!mounted || !_active || epoch != _epoch) return;
      _queue.addAll(notices.where(_service!.isCurrent));
      // Show the most recent scores if several leagues update together.
      if (_queue.length > 8) _queue.removeRange(0, _queue.length - 8);
      if (_notice != null && !_service!.isCurrent(_notice!)) {
        _notice = null;
      }
      if (_notice == null) _showNext();
    } finally {
      if (mounted && _active && _enabled && epoch == _epoch) {
        _poll = Timer(const Duration(seconds: 30), _refresh);
      }
    }
  }

  void _showPreview() {
    if (!mounted) return;
    _hide?.cancel();
    const home = SportsTeam(
        id: 'preview-home',
        name: 'Montreal',
        shortName: 'Montreal',
        abbreviation: 'MTL',
        score: '2');
    const away = SportsTeam(
        id: 'preview-away',
        name: 'Toronto',
        shortName: 'Toronto',
        abbreviation: 'TOR',
        score: '1');
    final game = SportsGame(
        id: 'preview',
        league: kSportsLeagues.first,
        start: DateTime.now(),
        state: GameState.live,
        statusText: '2nd',
        home: home,
        away: away);
    setState(() {
      _preview = true;
      _notice = GoalAlertNotice(
          viewerId: _viewer ?? '',
          game: game,
          team: home,
          observedAt: DateTime.now());
    });
    _hide = Timer(const Duration(seconds: 8), _showNext);
  }

  void _showNext() {
    _hide?.cancel();
    _preview = false;
    GoalAlertNotice? next;
    while (_queue.isNotEmpty) {
      final item = _queue.removeAt(0);
      if (_service!.isCurrent(item)) {
        next = item;
        break;
      }
    }
    setState(() => _notice = next);
    if (next != null) _hide = Timer(const Duration(seconds: 8), _showNext);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _clear();
    setState(() {});
    if (_active) _refresh();
  }

  @override
  void dispose() {
    _epoch++;
    _poll?.cancel();
    _hide?.cancel();
    _service?.reset();
    GoalsAlertOverlay.previewRequests.removeListener(_showPreview);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notice = _notice;
    if (!_active ||
        notice == null ||
        (!_preview && !_service!.isCurrent(notice))) {
      return const SizedBox.shrink();
    }
    final game = notice.game;
    final accent = Theme.of(context).colorScheme.primary;
    return IgnorePointer(
      child: ExcludeFocus(
        child: SafeArea(
          child: ValueListenableBuilder<double>(
            valueListenable: GameReminderOverlay.occupiedHeight,
            builder: (context, reminderHeight, _) => Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    20,
                    20 +
                        (MediaQuery.sizeOf(context).width < 800
                            ? reminderHeight
                            : 0),
                    20,
                    20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Semantics(
                    liveRegion: true,
                    child: Material(
                      key: const ValueKey('goal-alert'),
                      color: transparentPopups(context)
                          ? Colors.transparent
                          : RefinedFinish.surface(
                              context, const Color(0xFA15171C)),
                      elevation: transparentPopups(context) ? 0 : 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: transparentPopups(context)
                            ? BorderSide.none
                            : BorderSide(color: accent.withValues(alpha: 0.55)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: PopupTextShadow(
                          child: Stack(children: [
                        if (notice.team.logoUrl?.isNotEmpty == true)
                          Positioned(
                              top: -12,
                              bottom: -12,
                              right: -8,
                              width: 115,
                              child: Opacity(
                                  opacity: 0.16,
                                  child: _ScoreLogo(
                                      url: notice.team.logoUrl, size: 100))),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  _ScoreLogo(
                                      key: const ValueKey('goal-league-logo'),
                                      url: game.league.logoUrl,
                                      size: 22),
                                  const SizedBox(width: 7),
                                  Expanded(
                                      child: Text(game.league.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12))),
                                ]),
                                const SizedBox(height: 8),
                                Row(children: [
                                  _ScoreLogo(
                                      key: const ValueKey('goal-team-logo'),
                                      url: notice.team.logoUrl,
                                      size: 44),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(
                                            tr('{team} scored!', {
                                              'team': notice.team.shortName
                                            }),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: accent,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 4),
                                        Text(
                                            tr(
                                                '{first} {firstScore} – {secondScore} {second}',
                                                {
                                                  'first':
                                                      game.first.abbreviation,
                                                  'firstScore':
                                                      game.first.score!,
                                                  'secondScore':
                                                      game.second.score!,
                                                  'second':
                                                      game.second.abbreviation,
                                                }),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold)),
                                        if (game.statusText.isNotEmpty)
                                          Text(game.statusText,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11)),
                                      ])),
                                ]),
                              ]),
                        ),
                      ])),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreLogo extends StatelessWidget {
  const _ScoreLogo({super.key, required this.url, required this.size});
  final String? url;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: size,
      height: size,
      child: url?.isNotEmpty == true
          ? Image.network(url!,
              fit: BoxFit.contain,
              cacheWidth: 128,
              cacheHeight: 128,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.sports, size: size * 0.7, color: Colors.white70))
          : Icon(Icons.sports, size: size * 0.7, color: Colors.white70));
}
