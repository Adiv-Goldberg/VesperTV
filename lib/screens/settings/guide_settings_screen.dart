import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_preferences.dart';
import '../../utils/tv_theme.dart';
import '../../widgets/mode_button.dart';
import '../../widgets/settings_scaffold.dart';
import '../../widgets/tv_switch_list_tile.dart';
import '../../l10n/l10n.dart';

/// Settings > Interface > Guide: the Live TV guide's layout (Live or
/// Timeline, full-screen video, Expand, Compact). Was part of Theme.
///
/// No custom D-pad handling, same as ThemeScreen.
class GuideSettingsScreen extends StatelessWidget {
  const GuideSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<AppPreferences>();

    return withTvThemeIfNeeded(
        context,
        (context) => SettingsScaffold(
              title: tr('Guide'),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    tr('Timeline shows every channel at once, on a scrollable schedule grid, instead of one channel\'s now/next at a time.'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final option in const [
                        ('live', 'Live'),
                        ('timeline', 'Timeline')
                      ]) ...[
                        Expanded(
                          child: ModeButton(
                            label: tr(option.$2),
                            selected: prefs.guideViewMode == option.$1,
                            onTap: () => prefs.setGuideViewMode(option.$1),
                          ),
                        ),
                        if (option.$1 != 'timeline') const SizedBox(width: 12),
                      ],
                    ],
                  ),
                  if (prefs.guideViewMode == 'timeline') ...[
                    const SizedBox(height: 8),
                    TvSwitchListTile(
                      title: Text(tr('Compact guide')),
                      subtitle: Text(tr(
                          'Shorter Timeline rows so more channels fit in the same space.')),
                      value: prefs.guideCompact,
                      onChanged: prefs.setGuideCompact,
                    ),
                  ],
                  // Android only for now — Windows' preview runs on its
                  // own media_kit player and isn't wired for this yet.
                  if (prefs.guideViewMode == 'timeline' &&
                      !Platform.isWindows) ...[
                    const SizedBox(height: 8),
                    TvSwitchListTile(
                      title: Text(tr('Full-screen video behind the guide')),
                      subtitle: Text(tr(prefs.guideExpanded
                          ? 'The live channel fills the screen behind a see-through guide'
                          : 'The live channel fills the screen behind a see-through guide showing 3 rows')),
                      value: prefs.guideFullVideo,
                      onChanged: prefs.setGuideFullVideo,
                    ),
                    if (prefs.guideFullVideo)
                      TvSwitchListTile(
                        title: Text(tr('Expand')),
                        subtitle:
                            Text(tr('Fill the screen with the Timeline guide')),
                        value: prefs.guideExpanded,
                        onChanged: prefs.setGuideExpanded,
                      ),
                  ],
                ],
              ),
            ));
  }
}
