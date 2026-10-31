import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/catalog_database.dart';
import '../../services/epg_service.dart';
import '../../services/playlist_manager.dart';
import '../../services/storage_service.dart';
import '../../utils/time_format.dart';
import '../../utils/constants.dart';
import '../../utils/tv_theme.dart';
import '../../utils/xtream.dart';
import '../../models/playlist_profile.dart';
import '../../widgets/tv_text_field_gate.dart';
import '../../widgets/settings_scaffold.dart';
import '../catalog_sync_screen.dart';
import 'channel_linking_screen.dart';
import 'epg_channel_matching_screen.dart';
import '../../l10n/l10n.dart';

/// Three tabs — General / EPG Matching / Channel Pairing — one entry
/// point for everything to do with getting a channel's programme guide
/// and live failover right, rather than three separately-named things
/// scattered across Settings (a plain EPG refresh screen, a standalone
/// "Channel Matching" screen (now "EPG Matching") reached via a button inside it, and a wholly
/// separate top-level "Channel Linking" menu entry). Requested directly:
/// the previous, more scattered shape didn't read as "this is where you
/// go for channel matching/pairing" to someone who didn't already know
/// each piece existed.
///
/// Left/Right (and 1/2/3) switch tabs, same shape as
/// `GroupManagementScreen`'s own TabBar — that screen's own doc comment
/// covers why plain default D-pad traversal alone doesn't reach a TabBar
/// reliably, so a plain "no custom handling" Settings screen (which this
/// otherwise still mostly is) needs this one exception once it has tabs
/// at all.
class EpgSettingsScreen extends StatefulWidget {
  const EpgSettingsScreen({super.key});

  @override
  State<EpgSettingsScreen> createState() => _EpgSettingsScreenState();
}

class _EpgSettingsScreenState extends State<EpgSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late int _refreshInterval;

  final List<FocusScopeNode> _tabScopes =
      List.generate(3, (i) => FocusScopeNode(debugLabel: 'epg-tab-$i'));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      // Rebuilds on every tab change regardless of how it happened (a
      // tap on the TabBar itself, a swipe, or _goToTab below) — needed so
      // the ExcludeFocus below always reflects whichever tab is actually
      // selected. Reported directly on real hardware: Up/Down inside a
      // tab's own channel list occasionally landing somewhere in a
      // *different* tab's list instead. Root cause: TabBarView keeps
      // every tab's content built at once (not just the visible one), so
      // without this, a directional arrow-key search has hundreds of
      // off-screen channel rows in the other two tabs to consider as
      // candidates alongside the ones actually on screen. Same fix
      // shape already used in this app for the same underlying problem —
      // see VideoPlayerPane's auto-hiding controls' own ExcludeFocus.
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _refreshInterval = context.read<StorageService>().getRefreshInterval();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final scope in _tabScopes) {
      scope.dispose();
    }
    super.dispose();
  }

  /// See `GroupManagementScreen._goToTab`'s doc comment.
  void _goToTab(int index) {
    final clamped = index.clamp(0, 2);
    if (clamped == _tabController.index) return;
    setState(() => _tabController.index = clamped);
    _tabScopes[clamped].requestFocus();
  }

  /// See `GroupManagementScreen._handleTabArrow`'s doc comment.
  void _handleTabArrow(TraversalDirection direction, int tabDelta) {
    final moved =
        FocusManager.instance.primaryFocus?.focusInDirection(direction) ??
            false;
    if (!moved) _goToTab(_tabController.index + tabDelta);
  }

  /// Every enabled playlist's EPG source — same shape `main.dart`'s own
  /// app-wide auto-refresh timer builds fresh on each tick.
  List<EpgSource> _sources() {
    final playlist = context.read<PlaylistManager>();
    return playlist.profiles
        .where((p) => p.enabled && (p.epgUrl?.isNotEmpty ?? false))
        .map((p) => (
              url: p.epgUrl!,
              knownChannelIds: playlist.knownChannelIdsFor(p.id)
            ))
        .toList();
  }

  Future<void> _applyInterval(int minutes) async {
    setState(() => _refreshInterval = minutes);
    final storage = context.read<StorageService>();
    await storage.setRefreshInterval(minutes);
    if (mounted) {
      context.read<EpgService>().startAutoRefresh(minutes, _sources);
    }
  }

  Future<void> _updateNow() async {
    final sources = _sources();
    if (sources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr('No EPG URL set yet — add a playlist first.'))),
      );
      return;
    }
    await context.read<EpgService>().refreshAll();
  }

  Future<void> _clearCache() async {
    final storage = context.read<StorageService>();
    final catalogDb = context.read<CatalogDatabase>();
    final playlist = context.read<PlaylistManager>();
    final epg = context.read<EpgService>();
    await storage.clearCache();
    // Programmes live in EpgDatabase, not the cache dir clearCache() wipes.
    await epg.clearAll();
    // The VOD/series catalog itself lives in its own local database now
    // (not the JSON-file cache `storage.clearCache()` wipes) — see
    // CatalogDatabase's doc comment.
    await catalogDb.clearAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(tr('Cache cleared.'))));
    // clearCache() also wipes the last-full-sync timestamp, so the
    // catalog is unconditionally stale right after this — reported
    // directly as confusing when clearing cache showed no reaction at
    // all (the automatic sync only re-checks at the *next* full app
    // restart, not mid-session). Offering it immediately here means the
    // user doesn't have to know to relaunch to see it.
    if (playlist.isXtream && mounted) {
      await confirmAndRunFullCatalogSync(context, playlist);
    }
  }

  @override
  Widget build(BuildContext context) {
    final epg = context.watch<EpgService>();

    return withTvThemeIfNeeded(
        context,
        (context) => SettingsScaffold(
              title: tr('EPG'),
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: tr('General')),
                  Tab(text: tr('EPG Matching')),
                  Tab(text: tr('Channel Pairing')),
                ],
              ),
              body: CallbackShortcuts(
                bindings: <ShortcutActivator, VoidCallback>{
                  const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                      _handleTabArrow(TraversalDirection.left, -1),
                  const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                      _handleTabArrow(TraversalDirection.right, 1),
                  const SingleActivator(LogicalKeyboardKey.digit1): () =>
                      _goToTab(0),
                  const SingleActivator(LogicalKeyboardKey.digit2): () =>
                      _goToTab(1),
                  const SingleActivator(LogicalKeyboardKey.digit3): () =>
                      _goToTab(2),
                },
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ExcludeFocus(
                      excluding: _tabController.index != 0,
                      child: FocusScope(
                        node: _tabScopes[0],
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            DropdownButtonFormField<int>(
                              initialValue: _refreshInterval,
                              decoration: InputDecoration(
                                labelText: tr('Auto-refresh interval'),
                                border: const OutlineInputBorder(),
                              ),
                              items: AppConstants.refreshIntervalOptions
                                  .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(
                                          tr('{p} hours', {'p': m ~/ 60}))))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) _applyInterval(value);
                              },
                            ),
                            const SizedBox(height: 12),
                            Text(
                              epg.lastUpdated == null
                                  ? tr('EPG never updated')
                                  : tr('EPG last updated: {p}', {
                                      'p': TimeFormat.dateTime(epg.lastUpdated!)
                                    }),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: epg.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.calendar_month),
                              label: Text(tr('Update EPG Now')),
                              onPressed: epg.isLoading ? null : _updateNow,
                            ),
                            const Divider(height: 32),
                            const _CustomEpgSection(),
                            const Divider(height: 32),
                            OutlinedButton(
                              onPressed: _clearCache,
                              child: Text(tr('Clear Cache')),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr('Clears the cached EPG and catalog data — playlist source, favorites, and group visibility are kept.'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    ExcludeFocus(
                      excluding: _tabController.index != 1,
                      child: FocusScope(
                        node: _tabScopes[1],
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: _TabIntro(
                                title: tr('EPG Matching'),
                                body: tr(
                                    'Fixes a channel with no program data by manually assigning it to an entry in the loaded EPG feed — useful when a provider\'s own id doesn\'t match a third-party source.'),
                              ),
                            ),
                            const Expanded(child: EpgChannelMatchingScreen()),
                          ],
                        ),
                      ),
                    ),
                    ExcludeFocus(
                      excluding: _tabController.index != 2,
                      child: FocusScope(
                        node: _tabScopes[2],
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: _TabIntro(
                                title: tr('Channel Pairing'),
                                body: tr(
                                    'Links a channel on one playlist to its equivalent on another. If a live channel fails to load, or you switch to it yourself from the player, playback can fall back to the paired channel on the other playlist instead.'),
                              ),
                            ),
                            const Expanded(child: ChannelLinkingScreen()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ));
  }
}

/// A short "what is this tab" explanation shown above the Channel
/// Matching/Channel Pairing tabs' own content — requested directly:
/// neither concept is obvious from a bare channel list and two buttons
/// alone to someone who doesn't already know why they'd want either one.
class _TabIntro extends StatelessWidget {
  const _TabIntro({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Custom EPG (XMLTV) URL for one chosen playlist — the same per-playlist
/// `epgUrl` Add Playlist edits, reachable from here. Blank on an Xtream
/// playlist re-derives the panel's own xmltv.php (see `_save` in
/// `add_playlist_screen.dart`); blank on an M3U playlist clears it.
class _CustomEpgSection extends StatefulWidget {
  const _CustomEpgSection();

  @override
  State<_CustomEpgSection> createState() => _CustomEpgSectionState();
}

class _CustomEpgSectionState extends State<_CustomEpgSection> {
  final _controller = TextEditingController();
  final _fieldFocus = FocusNode(debugLabel: 'custom-epg-field');
  String? _playlistId;

  @override
  void dispose() {
    _controller.dispose();
    _fieldFocus.dispose();
    super.dispose();
  }

  /// The URL worth pre-filling: an Xtream profile's auto-derived link is not
  /// something the user typed, so it shows as blank (same rule as Add Playlist).
  String _customUrlOf(PlaylistProfile p) {
    if (p.mode == 'xtream') {
      final auto = XtreamHelper.buildEpgUrl(
          server: p.xtreamServer ?? '',
          username: p.xtreamUsername ?? '',
          password: p.xtreamPassword ?? '');
      if (p.epgUrl == auto) return '';
    }
    return p.epgUrl ?? '';
  }

  void _select(PlaylistProfile? p) {
    setState(() => _playlistId = p?.id);
    _controller.text = p == null ? '' : _customUrlOf(p);
  }

  Future<void> _save(PlaylistProfile p) async {
    final manager = context.read<PlaylistManager>();
    final epg = context.read<EpgService>();
    final custom = _controller.text.trim();
    final url = custom.isNotEmpty
        ? custom
        : p.mode == 'xtream'
            ? XtreamHelper.buildEpgUrl(
                server: p.xtreamServer ?? '',
                username: p.xtreamUsername ?? '',
                password: p.xtreamPassword ?? '')
            : '';
    await manager.updatePlaylist(p.copyWith(epgUrl: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(custom.isEmpty && url.isEmpty
            ? tr('Custom EPG URL cleared.')
            : tr('Custom EPG URL saved.'))));
    if (url.isNotEmpty && p.enabled) {
      // refreshAll walks every enabled playlist's source, this one included.
      await epg.refreshAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<PlaylistManager>().profiles;
    PlaylistProfile? selected;
    for (final p in profiles) {
      if (p.id == _playlistId) selected = p;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('Custom EPG (XMLTV) URL — optional'),
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selected?.id,
          decoration: InputDecoration(
            labelText: tr('Use with playlist'),
            border: const OutlineInputBorder(),
          ),
          items: profiles
              .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
              .toList(),
          onChanged: (id) {
            PlaylistProfile? pick;
            for (final p in profiles) {
              if (p.id == id) pick = p;
            }
            _select(pick);
          },
        ),
        if (selected != null) ...[
          const SizedBox(height: 12),
          TvTextFieldGate(
            focusNode: _fieldFocus,
            builder: (context, readOnly) => TextField(
              controller: _controller,
              focusNode: _fieldFocus,
              readOnly: readOnly,
              decoration: InputDecoration(
                labelText: tr('Custom EPG (XMLTV) URL — optional'),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.save_outlined),
            label: Text(tr('Save EPG URL')),
            onPressed: () => _save(selected!),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          tr('Pick a playlist, then paste a third-party XMLTV link. Leave it blank to use the guide of that playlist. A channel is only filled in when the ids in the feed match the playlist.'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
