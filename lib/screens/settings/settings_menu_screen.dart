import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../utils/tv_theme.dart';
import '../../widgets/settings_scaffold.dart';
import '../../widgets/tv_menu_tile.dart';
import '../../services/backup_service.dart';
import '../../services/recording_service.dart';
import 'backup_screen.dart';
import 'check_updates_screen.dart';
import 'epg_settings_screen.dart';
import 'general_settings_screen.dart';
import 'playlist_manager_screen.dart';
import 'profiles_screen.dart';
import 'recording_settings_screen.dart';
import 'send_log_screen.dart';
import 'transfer_screen.dart';
import 'guide_settings_screen.dart';
import 'theme_screen.dart';
import 'addons_screen.dart';
import 'archive_posters_screen.dart';
import 'archive_sources_screen.dart';
import 'trackers_screen.dart';
import 'tmdb_settings_screen.dart';
import 'debrid_settings_screen.dart';
import 'remote_tips_screen.dart';
import 'support_screen.dart';
import 'community_screen.dart';
import '../../l10n/l10n.dart';
import '../../widgets/sports_mode_toggle.dart';
import '../../utils/constants.dart';
import 'sports_country_settings_screen.dart';
import 'sports_playlist_settings_screen.dart';
import 'sports_league_visibility_settings_screen.dart';
import 'sports_auto_play_settings_screen.dart';
import 'sports_odds_settings_screen.dart';
import 'sports_quality_settings_screen.dart';
import 'playlist_editor_screen.dart';

/// One destination row of a Settings category.
class _Entry {
  const _Entry(this.icon, this.title, this.subtitle, this.open);
  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder open;
}

/// A Settings category: a row of the left panel, and the description +
/// destinations its right pane shows.
class _Category {
  const _Category(this.icon, this.title, this.description, this.entries);
  final IconData icon;
  final String title;
  final String description;
  final List<_Entry> entries;
}

/// Settings entry point: a left panel of categories (owner, 2026-10-21:
/// related settings under one roof — Media Hub sources + Add-ons + Trakt
/// + TMDB together, the small display switches together) and, beside it,
/// the focused category's description and destinations. Right / OK goes
/// into them, Left / Back returns to the panel. A portrait phone gets the
/// categories as a list, each opening its own page.
///
/// Up/Down inside each column is plain Flutter default traversal on
/// purpose — every custom Up/Down interception tried on these screens
/// (`DpadVerticalNav`, `ExplicitFocusOrder`...) was unreliable on real
/// hardware, while plain top-to-bottom lists always worked. Each column is
/// its own [FocusScope] so Up/Down never crosses over; only Left/Right
/// between the two are explicit ([CallbackShortcuts], CLAUDE.md §10).
class SettingsMenuScreen extends StatefulWidget {
  const SettingsMenuScreen({super.key});

  @override
  State<SettingsMenuScreen> createState() => _SettingsMenuScreenState();
}

class _SettingsMenuScreenState extends State<SettingsMenuScreen> {
  final _railScope = FocusScopeNode(debugLabel: 'settings-rail');
  final _paneScope = FocusScopeNode(debugLabel: 'settings-pane');
  final List<FocusNode> _railNodes = [];
  final _firstEntryNode = FocusNode(debugLabel: 'settings-first-entry');
  int _selected = 0;
  bool _inPane = false;

  @override
  void initState() {
    super.initState();
    _paneScope.addListener(_onPaneFocus);
  }

  void _onPaneFocus() {
    if (_paneScope.hasFocus != _inPane) {
      setState(() => _inPane = _paneScope.hasFocus);
    }
  }

  @override
  void dispose() {
    _paneScope.removeListener(_onPaneFocus);
    _railScope.dispose();
    _paneScope.dispose();
    _firstEntryNode.dispose();
    for (final n in _railNodes) {
      n.dispose();
    }
    super.dispose();
  }

  FocusNode _railNode(int i) {
    while (_railNodes.length <= i) {
      _railNodes.add(FocusNode(debugLabel: 'settings-category'));
    }
    return _railNodes[i];
  }

  /// Category destinations open the shared settings screen on one section.
  static _Entry _general(
          String id, IconData icon, String title, String subtitle) =>
      _Entry(icon, title, subtitle,
          (_) => GeneralSettingsScreen(sections: {id}, title: title));

  List<_Category> _categories() => [
        _Category(
          Icons.video_library_outlined,
          tr('Playlists & guide'),
          tr('Your playlists and their logins, the TV guide (EPG) and the viewer profiles.'),
          [
            _Entry(
                Icons.video_library_outlined,
                tr('Playlist Manager'),
                tr('Every playlist: login, groups, enable/disable'),
                (_) => const PlaylistManagerScreen()),
            _Entry(
                Icons.calendar_month_outlined,
                tr('EPG'),
                tr('Auto-refresh, channel matching & pairing, clear cache'),
                (_) => const EpgSettingsScreen()),
            _Entry(
                Icons.edit_note,
                tr('Playlist editor (Test flight)'),
                tr('Rename, hide copies, fallbacks and stream test, from your phone or PC'),
                (_) => const PlaylistEditorScreen()),
            _Entry(
                Icons.people_outline,
                tr('Profiles'),
                tr('Separate favorites, history & hidden groups per viewer'),
                (_) => const ProfilesScreen()),
          ],
        ),
        _Category(
          Icons.local_movies_outlined,
          tr('Media Hub'),
          tr('Everything the Media Hub uses: its add-on sources, online subtitles, Trakt & Simkl watch tracking and the optional TMDB key.'),
          [
            _Entry(
                Icons.local_movies_outlined,
                tr('Media Hub sources'),
                tr('Add-on sources for the Media Hub tab'),
                (_) => const ArchiveSourcesScreen()),
            // Online subtitles: both players (Windows' own since its
            // Subtitles button, desktop_subtitles.dart).
            _Entry(
                Icons.extension_outlined,
                tr('Add-ons'),
                tr('Online subtitles in more languages'),
                (_) => const AddonsScreen()),
            _Entry(
                Icons.playlist_add_check,
                tr('Trakt & Simkl'),
                tr('Track what you watch, lists in the Media Hub'),
                (_) => const TrackersScreen()),
            _Entry(
                Icons.movie_filter_outlined,
                tr('TMDB (Release Dates)'),
                tr('Optional key for sorting by real release date'),
                (_) => const TmdbSettingsScreen()),
            _Entry(
                Icons.image_outlined,
                tr('Custom posters'),
                tr('Media Hub posters from a poster service'),
                (_) => const ArchivePostersScreen()),
            _Entry(
                Icons.cloud_done_outlined,
                tr('Debrid accounts'),
                tr('Optional keys for the "Ready" tag'),
                (_) => const DebridSettingsScreen()),
            _general(
                'streamselection',
                Icons.video_library_outlined,
                tr('Media Hub playback'),
                tr('Default stream selection for movies and episodes')),
          ],
        ),
        _Category(
          Icons.dashboard_customize_outlined,
          tr('Interface'),
          tr('Theme, tabs, favourites and how the app looks.'),
          [
            _Entry(Icons.palette_outlined, tr('Theme'),
                tr('Clock, accent color, layout'), (_) => const ThemeScreen()),
            _Entry(
                Icons.view_timeline_outlined,
                tr('Guide'),
                tr('Live TV guide layout, full-screen video, compact rows'),
                (_) => const GuideSettingsScreen()),
            _general('tabs', Icons.tab_outlined, tr('Tabs'),
                tr('Hide Movies, TV Shows, Media Hub, Recordings or Multiview')),
            _general('goals', Icons.sports_score, tr('Goals alert'),
                tr('Score alerts for My Teams on any screen')),
            _general('favourites', Icons.star_outline, tr('Favourites'),
                tr('One list for every playlist, or one per playlist')),
          ],
        ),
        _Category(
          Icons.play_circle_outline,
          tr('Playback'),
          tr('Video, audio, subtitles, trailers and player behaviour.'),
          [
            if (!Platform.isWindows)
              _general(
                  'background',
                  Icons.picture_in_picture_alt,
                  tr('Background video'),
                  tr('Fixes for the picture on some Fire TV sticks')),
            if (Platform.isAndroid)
              _general('audio', Icons.surround_sound_outlined, tr('Audio'),
                  tr('Audio languages, subtitles and surround sound')),
            if (Platform.isAndroid)
              _general(
                  'display',
                  Icons.tv_outlined,
                  tr('Frame rate & resolution'),
                  tr('Match the TV to the video\'s frame rate and resolution')),
            if (!Platform.isWindows)
              _general('datapool', Icons.analytics_outlined, tr('Data pool'),
                  tr('Stream details when you press OK while watching')),
            if (Platform.isAndroid)
              _general('catchup', Icons.history_toggle_off, tr('Catch-up'),
                  tr('What happens when a catch-up programme ends')),
            if (Platform.isAndroid || Platform.isWindows)
              _general('skipintro', Icons.skip_next_outlined, tr('Skip intro'),
                  tr('Skip intros and credits on TV show episodes')),
            if (Platform.isAndroid || Platform.isWindows)
              _general('upnext', Icons.queue_play_next, tr('Up Next'),
                  tr('When the next episode starts by itself')),
            if (Platform.isAndroid || Platform.isWindows)
              _general('livebuffer', Icons.av_timer, tr('Live buffer'),
                  tr('Hide short dropouts on live channels')),
            if (Platform.isWindows)
              _general('softvideo', Icons.memory, tr('Software video'),
                  tr('For PCs where video stays black')),
            _general('trailers', Icons.movie_outlined, tr('Trailers'),
                tr('Play trailers automatically on movie and show pages')),
            if (!Platform.isWindows)
              _general('multiview', Icons.grid_view, tr('Multiview'),
                  tr('The connections tip when opening Multiview')),
            _general('resume', Icons.play_circle_outline, tr('Resume reminder'),
                tr('The "Hold > to resume" pill')),
          ],
        ),
        _Category(
          Icons.sports,
          AppConstants.sportsTabName,
          tr('Channel preferences and settings for {tab}.',
              {'tab': AppConstants.sportsTabName}),
          [
            _Entry(
                Icons.sports,
                tr('Sports Mode'),
                tr('Make Sports Trak your home, with your top five leagues at the side.'),
                (_) => const SportsModeSettingsScreen()),
            _Entry(
                Icons.flag_outlined,
                tr('Preferred channel countries'),
                tr('Prefer local channels while keeping other matches available'),
                (_) => const SportsCountrySettingsScreen()),
            _Entry(
                Icons.playlist_play,
                tr('Preferred playlist'),
                tr('Try matching channels from this playlist first'),
                (_) => const SportsPlaylistSettingsScreen()),
            _Entry(
                Icons.high_quality,
                tr('Prefer highest quality'),
                tr('Prefer higher-quality channels among game matches'),
                (_) => const SportsQualitySettingsScreen()),
            _Entry(
                Icons.filter_list,
                tr('Hide leagues with no games'),
                tr('Show only leagues with games on the selected day'),
                (_) => const SportsLeagueVisibilitySettingsScreen()),
            _Entry(
                Icons.trending_up,
                tr('Betting odds'),
                tr('Show the line and over/under on games'),
                (_) => const SportsOddsSettingsScreen()),
            _Entry(
                Icons.play_circle_outline,
                tr('Watch game button'),
                tr('A reminded game offers Watch game in the player at kickoff'),
                (_) => const SportsAutoPlaySettingsScreen()),
          ],
        ),
        _Category(
          Icons.tune,
          tr('General'),
          tr('Language and clock, what plays when the app starts, Fast startup, clearing your history, and remote tips.'),
          [
            _general('language', Icons.translate, tr('Language'),
                tr('App language and 24-hour clock')),
            _general('startup', Icons.power_settings_new, tr('Startup'),
                tr('Resume the last channel, Fast startup')),
            _general('history', Icons.history, tr('History'),
                tr('Clear searches, channels, Continue Watching')),
            _Entry(
                Icons.settings_remote_outlined,
                tr('Remote tips'),
                tr('Every hold menu and shortcut, on your phone'),
                (_) => const RemoteTipsScreen()),
          ],
        ),
        _Category(
          Icons.devices,
          tr('Device & data'),
          tr('Move your whole setup to another device, keep a backup of it, and update VesperTV.'),
          [
            _Entry(
                Icons.devices,
                tr('Transfer to another device'),
                tr('Copy all of your data to another device'),
                (_) => const TransferScreen()),
            if (BackupService.supported)
              _Entry(
                  Icons.settings_backup_restore,
                  tr('Backup & restore'),
                  tr('Save everything to a file on this device'),
                  (_) => const BackupScreen()),
            _Entry(
                Icons.system_update_outlined,
                tr('Check for Updates'),
                tr('Download and install the latest release'),
                (_) => const CheckUpdatesScreen()),
            if (RecordingService.supported)
              _Entry(
                  Icons.fiber_smart_record_outlined,
                  tr('Recordings'),
                  tr('Margins, space and where recordings are saved'),
                  (_) => const RecordingSettingsScreen()),
            _Entry(
                Icons.bug_report_outlined,
                tr('Send log'),
                tr('Send the app\'s log to the developer'),
                (_) => const SendLogScreen()),
            _Entry(
                Icons.forum_outlined,
                tr('Discord'),
                tr('Direct support through Discord'),
                (_) => const CommunityScreen()),
          ],
        ),
        _Category(
          Icons.local_cafe_outlined,
          tr('Support VesperTV'),
          tr('VesperTV is free, with no ads. A coffee or a Supporter membership helps cover its costs.'),
          [
            _Entry(
                Icons.local_cafe_outlined,
                tr('Support VesperTV'),
                tr('Buy a coffee or become a Supporter'),
                (_) => const SupportScreen()),
          ],
        ),
      ];

  void _open(_Entry e) =>
      Navigator.of(context).push(MaterialPageRoute(builder: e.open));

  void _enterPane() => _firstEntryNode.requestFocus();

  void _backToRail() => _railNode(_selected).requestFocus();

  @override
  Widget build(BuildContext context) {
    final categories = _categories();
    final narrow = MediaQuery.sizeOf(context).width < 700;
    return withTvThemeIfNeeded(
      context,
      (context) => PopScope(
        canPop: narrow || !_inPane,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _backToRail();
        },
        child: SettingsScaffold(
          title: tr('Settings'),
          body: narrow
              ? ListView(children: [
                  for (final c in categories)
                    TvMenuTile(
                      icon: c.icon,
                      title: c.title,
                      subtitle: c.description,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => _CategoryScreen(category: c))),
                    ),
                  const _Footer(),
                ])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 280, child: _buildRail(categories)),
                    const VerticalDivider(width: 1, color: Colors.white24),
                    Expanded(child: _buildPane(categories[_selected])),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildRail(List<_Category> categories) {
    return FocusScope(
      node: _railScope,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowRight): _enterPane,
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (var i = 0; i < categories.length; i++)
              // Focus follows the selector: the pane shows whichever
              // category is focused (wrapper not itself a focus target,
              // CLAUDE.md §10).
              Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onFocusChange: (f) {
                  if (f && _selected != i) setState(() => _selected = i);
                },
                child: TvMenuTile(
                  focusNode: _railNode(i),
                  autofocus: i == 0,
                  icon: categories[i].icon,
                  title: categories[i].title,
                  trailing: i == _selected
                      ? Icon(Icons.chevron_right,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _selected = i);
                    _enterPane();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPane(_Category c) {
    return FocusScope(
      node: _paneScope,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): _backToRail,
        },
        child: ListView(
          key: ValueKey(c.title),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          children: [
            _PaneHeader(category: c),
            for (var i = 0; i < c.entries.length; i++)
              TvMenuTile(
                focusNode: i == 0 ? _firstEntryNode : null,
                icon: c.entries[i].icon,
                title: c.entries[i].title,
                subtitle: c.entries[i].subtitle,
                onTap: () => _open(c.entries[i]),
              ),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

/// The pane's top: the category's icon, name and what's inside it.
class _PaneHeader extends StatelessWidget {
  const _PaneHeader({required this.category});
  final _Category category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(category.icon, size: 36, color: scheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(category.description,
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Portrait phone: one category's destinations on their own page.
class _CategoryScreen extends StatelessWidget {
  const _CategoryScreen({required this.category});
  final _Category category;

  @override
  Widget build(BuildContext context) {
    return withTvThemeIfNeeded(
      context,
      (context) => SettingsScaffold(
        title: category.title,
        body: ListView(
          padding: const EdgeInsets.only(top: 8),
          children: [
            _PaneHeader(category: category),
            for (final e in category.entries)
              TvMenuTile(
                icon: e.icon,
                title: e.title,
                subtitle: e.subtitle,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: e.open)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Version, bug-report address and the TMDB / Trakt / Simkl credits.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    const small = TextStyle(fontSize: 11, color: Colors.grey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reads whatever code is actually running via PackageInfo (same
        // source CheckUpdatesScreen's "Current version" line uses) rather
        // than a hand-typed constant — requested directly: "so I can
        // confirm easily the current version inside the app".
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version;
              return Text(
                version == null
                    ? tr('Version —')
                    : tr('Version {version}', {'version': version}),
                style: small,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(tr('Report any bugs or glitches to noxqcx@gmail.com'),
              style: small),
        ),
        // TMDB's terms ask for this wherever their data/images show —
        // posters and backdrops come from TMDB's image CDN even without a
        // key (provider links, upgraded to HD by hdImageUrl), so it lives
        // here, not only in the TMDB key screen.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            '${tr('Movie and TV artwork and data may come from TMDB (The Movie Database).')} '
            '${tr('This product uses the TMDB API but is not endorsed or certified by TMDB.')} '
            // Credit for the watch trackers (Settings > Trakt & Simkl),
            // owner 2026-10-19.
            '${tr('Watch tracking powered by Trakt and Simkl; VesperTV is not affiliated with or endorsed by either.')}',
            style: small,
          ),
        ),
      ],
    );
  }
}
