import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/sports.dart';
import '../services/goals_alerts.dart';
import 'tv_menu_tile.dart';

class GameScoreAlertMenuTile extends StatelessWidget {
  const GameScoreAlertMenuTile({super.key, required this.game});
  final SportsGame game;

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<GoalsAlerts>();
    final enabled = alerts.isSet(game);
    final league = LeagueGoalAlertMenuTile(league: game.league);
    if (!enabled && !alerts.canSet(game)) return league;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _matchTile(context, alerts, enabled),
      league,
    ]);
  }

  Widget _matchTile(BuildContext context, GoalsAlerts alerts, bool enabled) {
    return TvMenuTile(
      icon: enabled ? Icons.notifications_off_outlined : Icons.sports_score,
      title: tr(enabled
          ? 'Remove goals alert for this match'
          : 'Set goals alert for this match'),
      subtitle: tr(
          'Notify me when either team scores (while VesperTV is open). Hide scores pauses alerts.'),
      onTap: () async {
        try {
          await alerts.setGame(game, !enabled);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('Could not save score alert.'))));
          }
        }
      },
    );
  }
}

/// Goals alert for every game of a league (owner, 1.0.51): game hold menu
/// and League manager.
class LeagueGoalAlertMenuTile extends StatelessWidget {
  const LeagueGoalAlertMenuTile(
      {super.key, required this.league, this.onDone, this.autofocus = false});
  final SportsLeague league;

  /// Called after the switch is saved (a menu closes itself).
  final VoidCallback? onDone;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<GoalsAlerts>();
    if (!alerts.canSetLeague(league)) return const SizedBox.shrink();
    final enabled = alerts.isLeagueSet(league);
    return TvMenuTile(
      autofocus: autofocus,
      icon:
          enabled ? Icons.notifications_off_outlined : Icons.campaign_outlined,
      title: tr(
          enabled
              ? 'Remove goals alert for {league}'
              : 'Goals alert for all of {league}',
          {'league': league.shortName}),
      subtitle: tr(
          'Notify me of every goal in this league (while VesperTV is open). Hide scores pauses alerts.'),
      onTap: () async {
        await alerts.setLeague(league, !enabled);
        onDone?.call();
      },
    );
  }
}
