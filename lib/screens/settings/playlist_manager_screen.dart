import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/playlist_profile.dart';
import '../../services/playback_service.dart';
import '../../services/playlist_manager.dart';
import '../../utils/time_format.dart';
import '../../utils/constants.dart';
import '../../utils/tv_theme.dart';
import '../../widgets/mode_button.dart';
import '../../widgets/section_label.dart';
import '../../widgets/settings_panel.dart';
import '../../widgets/settings_scaffold.dart';
import '../../widgets/tv_app_bar_button.dart';
import '../../widgets/tv_text_field_gate.dart';
import '../../widgets/tv_menu_tile.dart';
import '../../widgets/tv_switch_list_tile.dart';
import 'add_playlist_screen.dart';
import 'group_management_screen.dart';
import 'hidden_channels_screen.dart';
import 'playlist_priority_screen.dart';
import '../../l10n/l10n.dart';

/// Playlist selection and management share one route. Highlighting a playlist
/// only selects its detail pane; it does not enable it or start playback.
class PlaylistManagerScreen extends StatefulWidget {
  const PlaylistManagerScreen({super.key});

  @override
  State<PlaylistManagerScreen> createState() => _PlaylistManagerScreenState();
}

class _PlaylistManagerScreenState extends State<PlaylistManagerScreen> {
  String? _selectedId;
  final _detailsFocus = FocusScopeNode(debugLabel: 'Playlist details');
  final _enabledFocus = FocusNode(debugLabel: 'Playlist enabled');
  final _listFocus = FocusScopeNode(debugLabel: 'Playlist list');
  final _playlistNodes = <String, FocusNode>{};

  FocusNode _playlistNode(String id) => _playlistNodes.putIfAbsent(
      id, () => FocusNode(debugLabel: 'Playlist $id'));

  void _backToList() {
    final profiles = context.read<PlaylistManager>().profiles;
    final id = profiles.any((p) => p.id == _selectedId)
        ? _selectedId
        : profiles.firstOrNull?.id;
    if (id != null && _playlistNode(id).context != null) {
      _playlistNode(id).requestFocus();
    } else {
      _listFocus.nextFocus();
    }
  }

  @override
  void dispose() {
    _enabledFocus.dispose();
    _detailsFocus.dispose();
    _listFocus.dispose();
    for (final node in _playlistNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _select(String id) {
    if (_selectedId != id) setState(() => _selectedId = id);
  }

  @override
  Widget build(BuildContext context) {
    final playlist = context.watch<PlaylistManager>();
    final profiles = playlist.profiles;
    final selectedId = profiles.any((p) => p.id == _selectedId)
        ? _selectedId
        : profiles.firstOrNull?.id;
    return withTvThemeIfNeeded(
        context,
        (context) => PopScope(
            canPop: !_detailsFocus.hasFocus,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _backToList();
            },
            child: SettingsScaffold(
              title: tr('Playlist Manager'),
              body: LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final list = ListView(
                  key: const PageStorageKey('playlist-manager-list'),
                  padding: const EdgeInsets.all(12),
                  children: [
                    _PlaylistPanel(padding: EdgeInsets.zero, children: [
                      TvMenuTile(
                        icon: Icons.add,
                        title: tr('Add Playlist'),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AddPlaylistScreen())),
                      ),
                      if (profiles.where((p) => p.enabled).length >= 2) ...[
                        const Divider(height: 1),
                        TvMenuTile(
                          icon: Icons.low_priority,
                          title: tr('Playlist Priority'),
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const PlaylistPriorityScreen())),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 12),
                    for (final profile in profiles)
                      Padding(
                        key: ValueKey(profile.id),
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Focus(
                          canRequestFocus: false,
                          onFocusChange: (focused) {
                            if (focused) _select(profile.id);
                          },
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: selectedId == profile.id
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: .12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: selectedId == profile.id
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: .5)
                                      : Colors.transparent),
                            ),
                            child: Material(
                              type: MaterialType.transparency,
                              child: TvMenuTile(
                                key: ValueKey('playlist-row-${profile.id}'),
                                focusNode: _playlistNode(profile.id),
                                autofocus: profile.id == selectedId,
                                icon: profile.isXtream ? Icons.dns : Icons.link,
                                title: profile.name,
                                titleMaxLines: 2,
                                subtitle: profile.isXtream
                                    ? tr('Xtream Codes')
                                    : 'M3U',
                                trailing: Icon(
                                    profile.enabled
                                        ? Icons.check_circle
                                        : Icons.pause_circle_outline,
                                    color: profile.enabled
                                        ? Colors.greenAccent
                                        : Colors.white38,
                                    size: 20),
                                onTap: () {
                                  _select(profile.id);
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (mounted && _selectedId == profile.id) {
                                      _enabledFocus.requestFocus();
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (profiles.isEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(tr(
                              'No playlists yet — tap "Add Playlist" above to get started.'))),
                  ],
                );
                final details = FocusScope(
                  node: _detailsFocus,
                  onFocusChange: (_) {
                    if (mounted) setState(() {});
                  },
                  child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.arrowLeft):
                            _backToList,
                      },
                      child: selectedId == null
                          ? const SizedBox.expand()
                          : _PlaylistDetailsPane(
                              key: ValueKey(selectedId),
                              playlistId: selectedId,
                              enabledFocus: _enabledFocus)),
                );
                final rail = FocusScope(
                    node: _listFocus,
                    child: CallbackShortcuts(bindings: {
                      const SingleActivator(LogicalKeyboardKey.arrowRight):
                          () => _enabledFocus.requestFocus(),
                    }, child: list));
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            SizedBox(
                                width: constraints.maxWidth < 1000 ? 250 : 300,
                                child: rail),
                            const VerticalDivider(width: 1),
                            Expanded(child: details),
                          ])
                    : Column(children: [
                        SizedBox(
                            height: constraints.maxHeight * .32, child: rail),
                        const Divider(height: 1),
                        Expanded(child: details),
                      ]);
              }),
            )));
  }
}

class _PlaylistDetailsPane extends StatefulWidget {
  const _PlaylistDetailsPane(
      {super.key, required this.playlistId, required this.enabledFocus});

  final String playlistId;
  final FocusNode enabledFocus;

  @override
  State<_PlaylistDetailsPane> createState() => _PlaylistDetailsPaneState();
}

class _PlaylistDetailsPaneState extends State<_PlaylistDetailsPane> {
  final _contentFocus = FocusNode(debugLabel: 'Playlist content controls');

  @override
  void dispose() {
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(
      PlaylistManager playlist, PlaylistProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Delete playlist?')),
        content: Text(
          tr('This removes "{name}"\'s login and cached catalog from this device. Its favorited channels/movies stay in your shared Favorites list, but will no longer play unless you add this playlist back.',
              {'name': profile.name}),
        ),
        // Plain TextButton/FilledButton left which one has D-pad focus
        // ambiguous — FilledButton's permanent solid fill looks the same
        // whether it's actually focused or not. ModeButton is this app's
        // established fix elsewhere for exactly this.
        actions: [
          ModeButton(
            label: tr('Cancel'),
            selected: false,
            onTap: () => Navigator.of(context).pop(false),
          ),
          ModeButton(
            label: tr('Delete'),
            selected: false,
            onTap: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await playlist.removePlaylist(profile.id);
  }

  Future<void> _promptForBackupServer(
      BuildContext context, PlaylistManager playlist) async {
    final controller = TextEditingController();
    final entered = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Add backup server')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('The full address, exactly like the main one — for example http://backup.example.com:8080'),
            ),
            const SizedBox(height: 12),
            FocusNodeOwner(
              builder: (context, node) => TvTextFieldGate(
                focusNode: node,
                builder: (context, readOnly) => TextField(
                  controller: controller,
                  focusNode: node,
                  readOnly: readOnly,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: tr('Server address'),
                    hintText: 'http://',
                  ),
                  onSubmitted: (value) => Navigator.of(context).pop(value),
                ),
              ),
            ),
          ],
        ),
        // Same ModeButton reasoning as _confirmDelete above.
        actions: [
          ModeButton(
            label: tr('Cancel'),
            selected: false,
            onTap: () => Navigator.of(context).pop(),
          ),
          ModeButton(
            label: tr('Add'),
            selected: false,
            onTap: () => Navigator.of(context).pop(controller.text),
          ),
        ],
      ),
    );
    controller.dispose();
    if (entered == null || entered.trim().isEmpty) return;
    await playlist.addBackupServer(widget.playlistId, entered);
    // Reported directly: the new entry only appeared after backing out of
    // this screen and re-entering. The write itself is fine (it *was*
    // persisted) — this is purely about this screen repainting, so don't
    // rely solely on the PlaylistManager notification arriving while a
    // dialog route is unwinding on top of it.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final playlist = context.watch<PlaylistManager>();
    PlaylistProfile? found;
    for (final p in playlist.profiles) {
      if (p.id == widget.playlistId) {
        found = p;
        break;
      }
    }
    if (found == null) {
      return const SizedBox.shrink();
    }
    // A separate, genuinely final binding — `found` above is reassigned
    // inside the loop, so Dart won't promote its type across the
    // null-check for the rest of this method.
    final profile = found;

    final summary = playlist.summaryFor(profile.id);
    final lastLoaded = playlist.lastLoadedFor(profile.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(children: [
            Expanded(
                child: Text(profile.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge)),
            TvAppBarButton.icon(
              icon: Icons.edit_outlined,
              tooltip: tr('Edit login'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        AddPlaylistScreen(editPlaylistId: profile.id)),
              ),
            ),
            TvAppBarButton.icon(
              icon: Icons.delete_outline,
              tooltip: tr('Delete playlist'),
              onTap: () => _confirmDelete(playlist, profile),
            ),
          ]),
        ),
        Expanded(
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _PlaylistSections(
            focusEnabled: widget.enabledFocus.requestFocus,
            focusContent: _contentFocus.requestFocus,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(tr('This Playlist')),
                    const SizedBox(height: 8),
                    _PlaylistPanel(
                      padding: EdgeInsets.zero,
                      children: [
                        TvSwitchListTile(
                          focusNode: widget.enabledFocus,
                          title: Text(tr('Playlist enabled')),
                          subtitle: Text(
                            tr('Frees up this account\'s stream slot for another device — stops playback here immediately, keeps everything else intact.'),
                          ),
                          value: profile.enabled,
                          onChanged: (value) {
                            playlist.setPlaylistEnabled(profile.id, value);
                            if (!value) {
                              context.read<PlaybackService>().stop();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SectionLabel(tr('Login Details')),
                    const SizedBox(height: 8),
                    _PlaylistPanel(
                      children: [
                        if (profile.isXtream) ...[
                          _DetailRow(
                              label: tr('Server'),
                              value: profile.xtreamServer ?? ''),
                          _DetailRow(
                              label: tr('Username'),
                              value: profile.xtreamUsername ?? ''),
                          _DetailRow(
                              label: tr('Password'),
                              value:
                                  '•' * (profile.xtreamPassword?.length ?? 0)),
                          // Only ever shown once a connect has
                          // actually reported one (see
                          // PlaylistProfile.expiresAt's doc
                          // comment) — an M3U playlist, or an
                          // Xtream account that hasn't connected
                          // yet or genuinely has no expiry to
                          // report, shows nothing here rather than
                          // a fabricated placeholder.
                          if (profile.expiresAt != null)
                            _DetailRow(
                              label: tr('Expires'),
                              value: DateFormat('yyyy-MM-dd')
                                  .format(profile.expiresAt!),
                              valueColor:
                                  profile.expiresAt!.isBefore(DateTime.now())
                                      ? Colors.redAccent
                                      : null,
                            ),
                          // Same "only shown once actually reported"
                          // rule as Expires above — see
                          // PlaylistProfile.maxConnections' own doc
                          // comment for why this is worth surfacing:
                          // a provider's own per-stream connection
                          // cap is easy to mistake for a playback
                          // bug, especially in Multiview.
                          if (profile.maxConnections != null)
                            _DetailRow(
                              label: tr('Max connections'),
                              value: '${profile.maxConnections}',
                            ),
                        ] else
                          _DetailRow(
                              label: tr('M3U URL'),
                              value: profile.m3uUrl ?? ''),
                      ],
                    ),
                    if (profile.isXtream) ...[
                      const SizedBox(height: 20),
                      SectionLabel(tr('Backup Servers')),
                      const SizedBox(height: 8),
                      _PlaylistPanel(
                        children: [
                          if (profile.backupServers.isEmpty)
                            Text(
                              tr('None yet. If your provider gave you more than one server address for this same account, add them here and this playlist will try them in order whenever the main one can\'t be reached.'),
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          else
                            for (final backup in profile.backupServers)
                              _BackupServerRow(
                                server: backup,
                                isLastWorking:
                                    profile.lastWorkingServer == backup,
                                onRemove: () async {
                                  await playlist.removeBackupServer(
                                      profile.id, backup);
                                  // Same repaint reasoning as
                                  // _promptForBackupServer.
                                  if (mounted) setState(() {});
                                },
                              ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.dns_outlined),
                            label: Text(tr('Add backup server')),
                            onPressed: () =>
                                _promptForBackupServer(context, playlist),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              tr('Same username and password as above — only the address differs. Tried in order, a few seconds apart, and whichever answers is used first next time.'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(tr('Content Overview')),
                    const SizedBox(height: 8),
                    _PlaylistPanel(
                      children: [
                        if (summary == null)
                          Text(tr('Not loaded yet.'))
                        else
                          Text(
                            profile.isXtream
                                ? tr(
                                    '{p} live channels · {p2} movie categories · {p3} TV show categories',
                                    {
                                        'p': summary['tv'],
                                        'p2': summary['vod'],
                                        'p3': summary['series']
                                      })
                                : tr('{p} live · {p2} movies · {p3} TV shows', {
                                    'p': summary['tv'],
                                    'p2': summary['vod'],
                                    'p3': summary['series']
                                  }),
                          ),
                        if (lastLoaded != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              tr('Last updated: {p}',
                                  {'p': TimeFormat.dateTime(lastLoaded)}),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        // Persisted, unlike "Last updated" above
                        // (only ever set in-memory during a live
                        // add/edit — resets to nothing on every
                        // cold restart regardless of which playlist
                        // it is). Reported directly as needed after
                        // several failed add attempts against the
                        // same login silently left duplicate
                        // profiles behind (fixed separately) — with
                        // several identically-named entries and no
                        // "Last updated" to go by post-restart,
                        // there was no way to tell which one was
                        // the original, deliberately-configured
                        // playlist apart from the orphaned retries.
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            tr('Added: {p}',
                                {'p': TimeFormat.dateTime(profile.createdAt)}),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.visibility_outlined),
                          focusNode: _contentFocus,
                          label: Text(tr('Group Management')),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => GroupManagementScreen(
                                    playlistId: profile.id)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.visibility_off_outlined),
                            label: Text(tr('Hidden Channels')),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => HiddenChannelsScreen(
                                      playlistId: profile.id)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            tr('Hide a group here and it\'s excluded from the background download too, not just the browse tabs.'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    if (profile.isXtream) ...[
                      const SizedBox(height: 20),
                      SectionLabel(tr('Full Catalog Sync')),
                      const SizedBox(height: 8),
                      _PlaylistPanel(
                        children: [
                          DropdownButtonFormField<int>(
                            key: ValueKey(
                                '${profile.id}:${profile.syncIntervalHours}'),
                            initialValue: profile.syncIntervalHours,
                            decoration: InputDecoration(
                              labelText: tr('Update content every'),
                              border: const OutlineInputBorder(),
                            ),
                            items: {
                              ...AppConstants.syncFrequencyHoursOptions,
                              profile.syncIntervalHours,
                            }
                                .map((h) => DropdownMenuItem(
                                    value: h,
                                    child: Text(h < 24
                                        ? h == 1
                                            ? tr('1 hour')
                                            : tr('{h} hours', {'h': h})
                                        : h % 24 != 0
                                            ? tr('{h} hours', {'h': h})
                                            : h == 24
                                                ? tr('1 day')
                                                : tr('{d} days',
                                                    {'d': h ~/ 24}))))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                // Whole days also go in the legacy
                                // field, read by older app versions.
                                playlist.updatePlaylist(profile.copyWith(
                                    syncFrequencyDays:
                                        value % 24 == 0 ? value ~/ 24 : null,
                                    syncFrequencyHours: value));
                              }
                            },
                          ),
                          TvSwitchListTile(
                            title: Text(tr('Update automatically')),
                            subtitle: Text(tr(
                                'On: when an update is due, it runs at launch without asking. Off: the app asks "Update content now?" first.')),
                            value: profile.autoSync,
                            onChanged: (v) => playlist
                                .updatePlaylist(profile.copyWith(autoSync: v)),
                          ),
                          if (profile.isXtream)
                            TvSwitchListTile(
                              title: Text(tr('Live stream format: HLS')),
                              subtitle: Text(tr(
                                  'Off: MPEG-TS (default, fastest start). On: HLS, like the HLS option in TiviMate. Plays about 10 seconds further behind live, but hides servers that send live TV in bursts. Applies from the next channel.')),
                              value: profile.liveHls,
                              onChanged: (v) => playlist
                                  .updatePlaylist(profile.copyWith(liveHls: v)),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

/// Ink paints above the panel fill instead of beneath its decoration.
class _PlaylistPanel extends StatelessWidget {
  const _PlaylistPanel(
      {required this.children, this.padding = const EdgeInsets.all(16)});
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) =>
      SettingsPanel(padding: padding, children: [
        Material(
            type: MaterialType.transparency,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children))
      ]);
}

/// Keep the detail quadrants readable after reserving space for the playlist rail.
class _PlaylistSections extends StatelessWidget {
  const _PlaylistSections(
      {required this.children,
      required this.focusEnabled,
      required this.focusContent});
  final VoidCallback focusEnabled;
  final VoidCallback focusContent;
  final List<Expanded> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        // Group each column; horizontal movement has
        // concrete targets rather than skipping the tall enabled tile.
        final sections = [
          for (var i = 0; i < children.length; i++)
            FocusTraversalGroup(
              child: CallbackShortcuts(
                bindings: {
                  if (i == 0)
                    const SingleActivator(LogicalKeyboardKey.arrowRight):
                        focusContent
                  else
                    const SingleActivator(LogicalKeyboardKey.arrowLeft):
                        focusEnabled,
                },
                child: children[i].child,
              ),
            ),
        ];
        return c.maxWidth >= 640
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: sections[0]),
                const SizedBox(width: 16),
                Expanded(child: sections[1]),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                sections[0],
                const SizedBox(height: 20),
                sections[1],
              ]);
      });
}

/// One configured backup server, with its own remove action. Marks the
/// one this playlist actually connected through last, so a list of
/// near-identical hostnames still tells you which is currently carrying
/// the account.
class _BackupServerRow extends StatelessWidget {
  const _BackupServerRow({
    required this.server,
    required this.isLastWorking,
    required this.onRemove,
  });

  final String server;
  final bool isLastWorking;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(server,
                      style: const TextStyle(fontFamily: 'monospace')),
                ),
                if (isLastWorking) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle,
                      size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(tr('in use'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary)),
                ],
              ],
            ),
          ),
          TvAppBarButton.icon(
            icon: Icons.close,
            tooltip: tr('Remove {server}', {'server': server}),
            onTap: onRemove,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
              child: Text(value,
                  style:
                      TextStyle(fontFamily: 'monospace', color: valueColor))),
        ],
      ),
    );
  }
}
