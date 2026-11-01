import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../widgets/settings_scaffold.dart';
import '../../widgets/tv_switch_list_tile.dart';

/// Settings > Sports Trak > Watch game button: at a game reminder's kickoff,
/// the player shows a Watch game pill for its channel, reached with Up from
/// the player bar like Skip intro (owner, 1.0.51). Off by default, per viewer.
class SportsAutoPlaySettingsScreen extends StatefulWidget {
  const SportsAutoPlaySettingsScreen({super.key});

  @override
  State<SportsAutoPlaySettingsScreen> createState() =>
      _SportsAutoPlaySettingsScreenState();
}

class _SportsAutoPlaySettingsScreenState
    extends State<SportsAutoPlaySettingsScreen> {
  late final StorageService _storage;
  late final int _viewer;
  late bool _enabled;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _storage = context.read<StorageService>();
    _viewer = _storage.viewerGeneration;
    _enabled = _storage.getSportsAutoPlay();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _save(bool value) async {
    if (!mounted || _storage.viewerGeneration != _viewer) return;
    setState(() => _enabled = value);
    await _storage.setSportsAutoPlay(value);
  }

  @override
  Widget build(BuildContext context) => SettingsScaffold(
        title: tr('Watch game button'),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TvSwitchListTile(
              focusNode: _focus,
              title: Text(tr('Watch game button')),
              subtitle: Text(tr(
                  'A reminded game offers Watch game in the player at kickoff')),
              value: _enabled,
              onChanged: _save,
            ),
            const SizedBox(height: 12),
            Text(tr(
                'When a reminded game is about to start, a Watch game button shows in the player for 10 minutes. Press Up from the player bar to reach it, then OK to switch to the game on its best channel. Set a reminder with a hold on the game. {app} must be open. Saved for this viewer.',
                {'app': AppConstants.appName})),
          ],
        ),
      );
}
