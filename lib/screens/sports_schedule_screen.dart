import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/sports.dart';
import '../services/game_reminders.dart';
import '../services/sports_channel_matcher.dart';
import '../services/sports_service.dart';
import '../utils/time_format.dart';
import '../utils/tv_theme.dart';
import '../widgets/hold_to_activate.dart';
import '../widgets/settings_scaffold.dart';
import '../widgets/sports_widgets.dart';
import 'sports_live_list_screen.dart';
import 'sports_my_teams_screen.dart' show SportsGameAction;

/// A team's season as a month calendar (hold OK on a team in Standings or
/// My Teams > Schedule). Each game day shows the opponent's logo and the
/// time or result; soccer includes its cups ([SportsService.teamSeason]),
/// a cup game marked with the cup's logo. The selected day's games are
/// detailed beside the calendar (below it on a phone).
///
/// D-pad: the calendar is one focus node with its own arrows (a day each,
/// a week up/down, crossing into the next/previous month); CH+/CH- or
/// PgUp/PgDn change month. OK: a finished game = stats, a live one =
/// watch, an upcoming one = the game menu (reminder, record, channel);
/// hold OK = the game menu. Without the Sports screen's actions (none
/// passed) an upcoming game's OK toggles its reminder.
class SportsScheduleScreen extends StatefulWidget {
  const SportsScheduleScreen({
    super.key,
    required this.league,
    required this.teamId,
    this.team,
    required this.hideScores,
    this.matchGames,
    this.onActivate,
    this.onMenu,
    this.service,
  });

  final SportsLeague league;
  final String teamId;

  /// Shown while the schedule loads (from the Standings row).
  final SportsTeam? team;
  final bool hideScores;
  final Future<Map<String, List<ChannelMatch>>> Function(List<SportsGame>)?
      matchGames;
  final SportsGameAction? onActivate;
  final SportsGameAction? onMenu;

  /// Tests pass their own; the app uses [SportsService.instance].
  final SportsService? service;

  @override
  State<SportsScheduleScreen> createState() => _SportsScheduleScreenState();
}

class _SportsScheduleScreenState extends State<SportsScheduleScreen> {
  final FocusNode _gridNode = FocusNode(debugLabel: 'schedule-grid');
  SportsTeamSchedule? _schedule;
  bool _loading = true;
  Map<String, List<ChannelMatch>> _matches = const {};

  /// Local midnight of the selected day; the month shown is its month.
  late DateTime _day;

  /// Games by local day (midnight).
  Map<DateTime, List<SportsGame>> _byDay = const {};

  static DateTime _dateOf(DateTime t) {
    final l = t.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  @override
  void initState() {
    super.initState();
    _day = _dateOf(DateTime.now());
    unawaited(_load());
  }

  @override
  void dispose() {
    _gridNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await (widget.service ?? SportsService.instance)
        .teamSeason(widget.league, widget.teamId);
    if (!mounted) return;
    final byDay = <DateTime, List<SportsGame>>{};
    for (final g in s?.games ?? const <SportsGame>[]) {
      byDay.putIfAbsent(_dateOf(g.start), () => []).add(g);
    }
    setState(() {
      _schedule = s;
      _byDay = byDay;
      _loading = false;
    });
    if (s != null) context.read<GameReminders>().reconcile(s.games);
    final match = widget.matchGames;
    if (s == null || match == null) return;
    final soon = DateTime.now().toUtc().add(const Duration(days: 14));
    final games = [
      for (final g in s.games)
        if (g.state == GameState.live ||
            (g.state == GameState.pre && g.start.isBefore(soon)))
          g,
    ];
    if (games.isEmpty) return;
    try {
      final m = await match(games);
      if (mounted) setState(() => _matches = m);
    } catch (e) {
      debugPrint('SportsSchedule: channel matching failed: $e');
    }
  }

  SportsTeam? get _team => _schedule?.team ?? widget.team;

  List<SportsGame> get _dayGames => _byDay[_day] ?? const [];

  List<ChannelMatch> _matchesFor(SportsGame g) =>
      _matches[SportsChannelPicks.eventKey(g)] ?? const [];

  void _select(DateTime day) => setState(() => _day = day);

  void _moveDays(int n) =>
      _select(DateTime(_day.year, _day.month, _day.day + n));

  void _moveMonths(int n) {
    final target = DateTime(_day.year, _day.month + n, 1);
    final last = DateTime(target.year, target.month + 1, 0).day;
    _select(DateTime(target.year, target.month, _day.day.clamp(1, last)));
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowLeft) {
      _moveDays(-1);
    } else if (k == LogicalKeyboardKey.arrowRight) {
      _moveDays(1);
    } else if (k == LogicalKeyboardKey.arrowUp) {
      _moveDays(-7);
    } else if (k == LogicalKeyboardKey.arrowDown) {
      _moveDays(7);
    } else if (k == LogicalKeyboardKey.channelUp ||
        k == LogicalKeyboardKey.pageUp) {
      _moveMonths(-1);
    } else if (k == LogicalKeyboardKey.channelDown ||
        k == LogicalKeyboardKey.pageDown) {
      _moveMonths(1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Future<void> _activate() async {
    final g = _dayGames.firstOrNull;
    if (g == null) return;
    switch (g.state) {
      case GameState.post:
        await showDialog<void>(
          context: context,
          builder: (_) => SportsGameDetailsDialog(
              game: g, matches: _matchesFor(g), hideScores: widget.hideScores),
        );
      case GameState.live:
        if (widget.onActivate != null) {
          await widget.onActivate!(g, _matchesFor(g));
        } else {
          await _openMenu();
        }
      case GameState.pre:
        await _openMenu();
    }
    if (mounted) _gridNode.requestFocus();
  }

  Future<void> _openMenu() async {
    final g = _dayGames.firstOrNull;
    if (g == null) return;
    if (widget.onMenu != null) {
      await widget.onMenu!(g, _matchesFor(g));
    } else if (g.state == GameState.pre) {
      final reminders = context.read<GameReminders>();
      if (reminders.canSet(g) || reminders.isSet(g)) {
        await reminders.toggle(g);
      }
    }
    if (mounted) {
      setState(() {});
      _gridNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = _team;
    final color = sportsTeamColor(team?.color);
    return SportsScreenFrame(
      child: withTvThemeIfNeeded(
        context,
        (context) => Stack(
          children: [
            const Positioned.fill(child: SettingsGradientBackground()),
            if (team?.logoUrl != null)
              Positioned.fill(
                  child: SportsBackdrop(
                      logoUrl: team!.logoUrl, color: team.color)),
            Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(team),
                      const SizedBox(height: 12),
                      Expanded(child: _body(color)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(SportsTeam? team) {
    final month = DateFormat.yMMMM().format(_day);
    return Row(
      children: [
        const SportsBackButton(),
        SportsLogo(
            url: team?.logoUrl,
            size: 44,
            fallback: team?.abbreviation ?? widget.league.shortName,
            color: team?.color),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(team?.name ?? widget.league.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              Text(
                  [
                    tr('Schedule'),
                    if (_schedule?.team.record case final r?) r,
                    if (_schedule?.standingSummary case final s?) s,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ExcludeFocus(
          child: IconButton(
            tooltip: tr('Previous month'),
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => _moveMonths(-1),
          ),
        ),
        Text(month,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        ExcludeFocus(
          child: IconButton(
            tooltip: tr('Next month'),
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () => _moveMonths(1),
          ),
        ),
      ],
    );
  }

  Widget _body(Color? color) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_schedule == null) {
      return Center(
        child: Text(tr('Could not load the schedule.'),
            style: const TextStyle(color: Colors.white70, fontSize: 16)),
      );
    }
    final calendar = HoldToActivate(
      onTap: _activate,
      onHold: _openMenu,
      child: Focus(
        focusNode: _gridNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: _calendar(color),
      ),
    );
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 700) {
        return Column(
          children: [
            Expanded(flex: 3, child: calendar),
            const SizedBox(height: 8),
            Expanded(flex: 2, child: _details(color)),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: calendar),
          const SizedBox(width: 16),
          SizedBox(
              width: (c.maxWidth * 0.32).clamp(260, 420),
              child: _details(color)),
        ],
      );
    });
  }

  Widget _calendar(Color? color) {
    final first = DateTime(_day.year, _day.month, 1);
    final daysInMonth = DateTime(_day.year, _day.month + 1, 0).day;
    final firstWeekday =
        MaterialLocalizations.of(context).firstDayOfWeekIndex; // 0 = Sunday
    final lead = (first.weekday % 7 - firstWeekday) % 7;
    final weeks = ((lead + daysInMonth) / 7).ceil();
    final today = _dateOf(DateTime.now());
    final labels = [
      for (var i = 0; i < 7; i++)
        DateFormat.E()
            // 2023-01-01 was a Sunday.
            .format(DateTime(2023, 1, 1 + (firstWeekday + i) % 7)),
    ];
    return Column(
      children: [
        Row(children: [
          for (final l in labels)
            Expanded(
              child: Center(
                child: Text(l,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ),
        ]),
        const SizedBox(height: 4),
        Expanded(
          child: Column(children: [
            for (var w = 0; w < weeks; w++)
              Expanded(
                child: Row(children: [
                  for (var d = 0; d < 7; d++)
                    Expanded(
                      child: Builder(builder: (context) {
                        final n = w * 7 + d - lead + 1;
                        if (n < 1 || n > daysInMonth) {
                          return const SizedBox.shrink();
                        }
                        final day = DateTime(_day.year, _day.month, n);
                        return _DayCell(
                          day: day,
                          games: _byDay[day] ?? const [],
                          teamId: _schedule!.team.id,
                          teamLeague: widget.league.id,
                          selected: day == _day,
                          today: day == today,
                          color: color,
                          hideScores: widget.hideScores,
                          onTap: () {
                            if (day == _day) {
                              _activate();
                            } else {
                              _select(day);
                              _gridNode.requestFocus();
                            }
                          },
                        );
                      }),
                    ),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 6),
        Text(
            tr('OK: stats, watch or game menu · Hold OK: game menu · CH+/CH-: month'),
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  Widget _details(Color? color) {
    final games = _dayGames;
    final next = _schedule!.games
        .where((g) =>
            g.state != GameState.post && !_dateOf(g.start).isBefore(_day))
        .firstOrNull;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: (color ?? Colors.white24).withValues(alpha: 0.6)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat.MMMMEEEEd().format(_day),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (games.isEmpty) ...[
              Text(tr('No game this day.'),
                  style: const TextStyle(color: Colors.white60, fontSize: 14)),
              if (next != null) ...[
                const SizedBox(height: 16),
                Text(tr('Next game'),
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 6),
                _GameDetails(
                    game: next,
                    teamId: _schedule!.team.id,
                    hideScores: widget.hideScores,
                    showDate: true),
              ],
            ],
            for (final g in games) ...[
              _GameDetails(
                  game: g,
                  teamId: _schedule!.team.id,
                  hideScores: widget.hideScores),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

/// The opponent of [teamId] in [g].
SportsTeam _opponent(SportsGame g, String teamId) =>
    g.home.id == teamId ? g.away : g.home;

/// "W 2-1" / "L 0-3" / "D 1-1" for [teamId], null without scores.
String? _result(SportsGame g, String teamId) {
  final us = g.home.id == teamId ? g.home : g.away;
  final them = _opponent(g, teamId);
  final a = num.tryParse(us.score ?? '');
  final b = num.tryParse(them.score ?? '');
  if (a == null || b == null) return null;
  final letter = a > b
      ? tr('W')
      : a < b
          ? tr('L')
          : tr('D');
  return '$letter ${us.score}-${them.score}';
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.games,
    required this.teamId,
    required this.teamLeague,
    required this.selected,
    required this.today,
    required this.color,
    required this.hideScores,
    required this.onTap,
  });

  final DateTime day;
  final List<SportsGame> games;
  final String teamId;
  final String teamLeague;
  final bool selected;
  final bool today;
  final Color? color;
  final bool hideScores;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final g = games.firstOrNull;
    final opponent = g == null ? null : _opponent(g, teamId);
    final cup = g != null && g.league.id != teamLeague;
    final String? line = g == null
        ? null
        : switch (g.state) {
            GameState.live => tr('LIVE'),
            GameState.post =>
              hideScores ? tr('Final') : (_result(g, teamId) ?? tr('Final')),
            GameState.pre => TimeFormat.hm.format(g.start.toLocal()),
          };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: g == null
              ? Colors.white.withValues(alpha: 0.03)
              : (color ?? Colors.white).withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? accent
                : today
                    ? Colors.white70
                    : Colors.white12,
            width: selected ? 3 : 1,
          ),
        ),
        child: LayoutBuilder(builder: (context, c) {
          final logo = (c.maxHeight * 0.42).clamp(14.0, 48.0);
          return Stack(
            children: [
              Positioned(
                left: 6,
                top: 4,
                child: Text('${day.day}',
                    style: TextStyle(
                        color: today ? Colors.white : Colors.white60,
                        fontSize: 12,
                        fontWeight: today ? FontWeight.w800 : FontWeight.w500)),
              ),
              if (cup)
                Positioned(
                  right: 4,
                  top: 4,
                  child: SportsLogo(
                      url: g.league.logoUrl,
                      size: (logo * 0.45).clamp(12.0, 22.0),
                      fallback: g.league.shortName),
                ),
              if (opponent != null)
                Positioned.fill(
                  top: 14,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SportsLogo(
                          url: opponent.logoUrl,
                          size: logo,
                          fallback: opponent.abbreviation,
                          color: opponent.color),
                      if (line != null && c.maxHeight > 52)
                        Text(
                          '${g!.home.id == teamId ? '' : '@ '}$line',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: g.state == GameState.live
                                  ? Colors.redAccent
                                  : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _GameDetails extends StatelessWidget {
  const _GameDetails({
    required this.game,
    required this.teamId,
    required this.hideScores,
    this.showDate = false,
  });

  final SportsGame game;
  final String teamId;
  final bool hideScores;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final g = game;
    final opponent = _opponent(g, teamId);
    final home = g.home.id == teamId;
    final reminders = context.watch<GameReminders>();
    final status = switch (g.state) {
      GameState.live => '${tr('LIVE')} · ${g.statusText}',
      GameState.post =>
        hideScores ? tr('Final') : (_result(g, teamId) ?? g.statusText),
      GameState.pre => showDate
          ? TimeFormat.dayTime(g.start.toLocal())
          : TimeFormat.hm.format(g.start.toLocal()),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          SportsLogo(
              url: g.league.logoUrl, size: 22, fallback: g.league.shortName),
          const SizedBox(width: 8),
          Flexible(
            child: Text(g.league.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          SportsLogo(
              url: opponent.logoUrl,
              size: 40,
              fallback: opponent.abbreviation,
              color: opponent.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${home ? tr('vs') : '@'} ${opponent.name}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                Text(status,
                    style: TextStyle(
                        color: g.state == GameState.live
                            ? Colors.redAccent
                            : Colors.white70,
                        fontSize: 13)),
              ],
            ),
          ),
        ]),
        if (g.broadcasts.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(g.broadcasts.join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
        if (g.state == GameState.pre && reminders.isSet(g)) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.notifications_active,
                size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            Text(tr('Reminder set'),
                style: const TextStyle(color: Colors.amber, fontSize: 12)),
          ]),
        ],
      ],
    );
  }
}
