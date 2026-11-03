import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'hold_to_activate.dart';
import '../utils/refined_finish.dart';
import 'sports_widgets.dart';

/// One row of [SportsLeagueRail]: a league (logo) or a tool (icon).
class SportsLeagueRailItem {
  const SportsLeagueRailItem({
    required this.id,
    required this.label,
    required this.focusNode,
    required this.onTap,
    this.onHold,
    this.onFocus,
    this.logoUrl,
    this.icon,
    this.selected = false,
    this.enabled = true,
    this.moving = false,
    this.dividerBefore = false,
  });

  final String id;
  final String label;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final VoidCallback? onHold;
  final VoidCallback? onFocus;
  final String? logoUrl;
  final IconData? icon;
  final bool selected;
  final bool enabled;
  final bool moving;
  final bool dividerBefore;
}

/// Regular Sports Trak's leagues as a left rail (owner, 2026-11-03): logos
/// only, the first row's arrow widens it to show the names. The D-pad is
/// handled by the screen (`onKeyEvent`): Up/Down walk [items] explicitly
/// (CLAUDE.md §10), Right returns to the page.
class SportsLeagueRail extends StatelessWidget {
  const SportsLeagueRail({
    super.key,
    required this.items,
    required this.expanded,
    required this.onKeyEvent,
  });

  static const double collapsedWidth = 76;
  static const double expandedWidth = 232;

  final List<SportsLeagueRailItem> items;
  final bool expanded;
  final FocusOnKeyEventCallback onKeyEvent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: const ValueKey('sports-league-rail'),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: expanded ? expandedWidth : collapsedWidth,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .45),
        border: const Border(right: BorderSide(color: Colors.white10)),
      ),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: onKeyEvent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
              child: Row(children: [
                const SportsBackButton(),
                if (expanded)
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text(AppConstants.sportsTabName,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          softWrap: false,
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in items) ...[
                      if (item.dividerBefore)
                        const Divider(color: Colors.white24, height: 14),
                      _RailTile(
                          key: ValueKey('rail-${item.id}'),
                          item: item,
                          expanded: expanded),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailTile extends StatefulWidget {
  const _RailTile({super.key, required this.item, required this.expanded});
  final SportsLeagueRailItem item;
  final bool expanded;

  @override
  State<_RailTile> createState() => _RailTileState();
}

class _RailTileState extends State<_RailTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final scheme = Theme.of(context).colorScheme;
    final leading = item.logoUrl != null
        ? SportsLogo(url: item.logoUrl, size: 28, fallback: item.label)
        : Icon(item.icon ?? Icons.sports,
            size: 26, color: item.selected ? scheme.primary : Colors.white70);
    return HoldToActivate(
      onTap: () {
        if (item.enabled) item.onTap();
      },
      onHold: item.enabled ? item.onHold : null,
      child: Tooltip(
        message: widget.expanded ? '' : item.label,
        child: InkWell(
          focusNode: item.focusNode,
          canRequestFocus: item.enabled,
          borderRadius: BorderRadius.circular(12),
          onTap: item.enabled ? item.onTap : null,
          onFocusChange: (f) {
            setState(() => _focused = f);
            if (!f) return;
            item.onFocus?.call();
            // Jump, never animate (CLAUDE.md §10).
            Scrollable.ensureVisible(context,
                alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
                alignment: 0.5);
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 46),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: RefinedFinish.decorate(
                context,
                BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _focused
                      ? null
                      : item.selected
                          ? scheme.primary.withValues(alpha: .16)
                          : Colors.transparent,
                  gradient: _focused ? sportsFocusSheen(scheme) : null,
                  border: Border.all(
                      width: 2,
                      color: _focused
                          ? scheme.primary
                          : item.selected
                              ? scheme.primary.withValues(alpha: .5)
                              : Colors.transparent),
                ),
                focused: _focused),
            child: Opacity(
              opacity: item.enabled ? 1 : .35,
              // The label only once the rail is wide enough (it widens over
              // 180 ms; the label overflowed the narrow tile meanwhile).
              child: LayoutBuilder(builder: (context, box) {
                final label = widget.expanded && box.maxWidth > 90;
                return Row(
                  mainAxisAlignment: label
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    leading,
                    if (label) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: item.selected
                                    ? FontWeight.w700
                                    : FontWeight.w500)),
                      ),
                      if (item.moving) const Icon(Icons.swap_vert, size: 18),
                    ],
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
