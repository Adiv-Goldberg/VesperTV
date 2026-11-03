import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_preferences.dart';
import '../../services/archive_service.dart';
import '../../services/device_defaults.dart';
import '../../services/playback_service.dart';
import '../../services/recording_service.dart';
import '../../services/storage_service.dart';
import '../../services/vod_buffering.dart';
import '../../services/subtitle_tracks.dart';
import '../../utils/constants.dart';
import '../../utils/tv_theme.dart';
import '../../widgets/goals_alert_overlay.dart';
import '../../widgets/native_video_hole.dart';
import '../../widgets/live_resume_hint.dart';
import '../../widgets/settings_scaffold.dart';
import '../../widgets/tv_dialog_option.dart';
import '../../widgets/tv_menu_tile.dart';
import '../../widgets/tv_switch_list_tile.dart';
import '../../l10n/l10n.dart';

/// Small behaviour switches that don't belong to one feature's own screen —
/// a home for future ones too (planned candidates: start-on tab, default
/// picture fit, preferred audio language, confirm on exit).
/// Multiview is Android only (Windows has its own Multiview without the
/// tip); everything else is shown on every platform. Startup and Tabs are
/// device-wide, not per viewer profile.
///
/// No custom D-pad handling — see SettingsMenuScreen's doc comment.
///
/// Settings' Interface and General categories open it on one section each
/// ([sections] = that id, shown open without its header, [title] = the
/// section's name); null shows every section, collapsible.
class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key, this.sections, this.title});

  final Set<String>? sections;
  final String? title;

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  late final StorageService _storage = context.read<StorageService>();
  late bool _resumeAtStartup = _storage.getResumeLastChannelAtStartup();
  late bool _resumeInGuide =
      !_resumeAtStartup && _storage.getResumeLastChannelInGuide();
  late bool _showMultiviewTip = !_storage.getMultiviewHideTips();
  late bool _showResumePill = _storage.getShowResumePill();

  /// Cancel is focused by default so a stray Select can't wipe anything.
  Future<bool> _confirm(String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(tr('Clear')),
          ),
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(tr('Cancel')),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _clearSearchAndChannelHistory() async {
    if (!await _confirm(tr('Clear search & channel history?'),
        tr('Removes your recent searches and the History list of live channels.'))) {
      return;
    }
    if (!mounted) return;
    final playback = context.read<PlaybackService>();
    await _storage.clearRecentSearches();
    await playback.clearRecentlyPlayed(live: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Search and channel history cleared.'))));
  }

  Future<void> _clearMoviesAndShowsHistory() async {
    if (!await _confirm(tr('Clear Movies & TV Shows history?'),
        tr('Removes Continue Watching and the saved progress of every movie and episode.'))) {
      return;
    }
    if (!mounted) return;
    await context.read<PlaybackService>().clearRecentlyPlayed(live: false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Movies & TV Shows history cleared.'))));
  }

  /// Language settings in the picker, in order. A new language = one entry
  /// here (native name, never translated) plus its dictionary in l10n.
  static const _languages = [
    ('auto', ''),
    ('en', 'English'),
    ('fr', 'Français'),
    ('es', 'Español'),
    ('it', 'Italiano'),
    ('el', 'Ελληνικά'),
    ('de', 'Deutsch'),
  ];

  String _languageLabel(String setting) => setting == 'auto'
      ? tr('Automatic')
      : _languages.firstWhere((l) => l.$1 == setting).$2;

  /// One row + a short pop-up list (current one focused) instead of a
  /// button per language, so the row stays small as languages are added.
  Future<void> _pickLanguage() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(tr('Language')),
        children: [
          for (final (code, _) in _languages)
            TvMenuTile(
              autofocus: code == L10n.setting,
              title: _languageLabel(code),
              subtitle:
                  code == 'auto' ? tr('Follows the device language') : null,
              trailing: code == L10n.setting
                  ? Icon(Icons.check,
                      color: Theme.of(dialogContext).colorScheme.primary)
                  : null,
              onTap: () => Navigator.of(dialogContext).pop(code),
            ),
        ],
      ),
    );
    if (picked != null) await _setLanguage(picked);
  }

  Future<void> _pickTrackLanguage({required bool audio}) async {
    final viewer = _storage.getActiveViewerId();
    final current = audio
        ? _storage.getPreferredAudioLanguage()
        : _storage.getPreferredSubtitleLanguage();
    final picked = await showDialog<String>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text(tr(audio
            ? 'Preferred audio language'
            : 'Preferred subtitle language')),
        children: [
          for (final code in [audio ? '' : 'off', ...trackLanguages])
            TvMenuTile(
              autofocus: code == current,
              title: code.isEmpty
                  ? tr('Source default')
                  : code == 'off'
                      ? tr('Off')
                      : languageName(code),
              onTap: () => Navigator.of(dialog).pop(code),
            ),
        ],
      ),
    );
    if (picked == null || !mounted || _storage.getActiveViewerId() != viewer) {
      return;
    }
    if (audio) {
      await _storage.setPreferredAudioLanguage(picked);
    } else {
      await _storage.setPreferredSubtitleLanguage(picked);
    }
    if (mounted) setState(() {});
  }

  /// Back to home first: main.dart remounts home on a language change, but
  /// routes already pushed above it would keep their old-language strings.
  Future<void> _setLanguage(String value) async {
    if (value == L10n.setting || !mounted) return;
    final prefs = context.read<AppPreferences>();
    Navigator.of(context).popUntil((route) => route.isFirst);
    await prefs.setLanguage(value);
  }

  /// Sections open right now (all closed on entry — the screen had grown
  /// into a long scroll).
  final Set<String> _open = {};

  /// [text] plus a note when [setting] is on only because this device is on
  /// the automatic list (DeviceDefaults); the user's own choice drops it.
  String _withAutomatic(BuildContext context, String setting, String text) =>
      context.watch<AppPreferences>().isAutomaticOn(setting)
          ? '$text\n${tr('Automatic: on for this device.')}'
          : text;

  /// One collapsible category: a [TvMenuTile] header (same focus look as
  /// the rest of Settings, so D-pad needs nothing special) that rolls its
  /// [children] open underneath on OK / tap.
  Widget _section(String id, IconData icon, String title,
      {String? subtitle, required List<Widget> children}) {
    final only = widget.sections;
    if (only != null && !only.contains(id)) return const SizedBox.shrink();
    if (only != null && only.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    final open = _open.contains(id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TvMenuTile(
          icon: icon,
          title: title,
          subtitle: subtitle,
          trailing: AnimatedRotation(
            turns: open ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.expand_more),
          ),
          onTap: () => setState(() => open ? _open.remove(id) : _open.add(id)),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 0, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return withTvThemeIfNeeded(
        context,
        (context) => SettingsScaffold(
              title: widget.title ?? tr('General'),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _section('language', Icons.translate, tr('Language'),
                      subtitle: _languageLabel(L10n.setting),
                      children: [
                        TvMenuTile(
                          icon: Icons.translate,
                          title: _languageLabel(L10n.setting),
                          subtitle: L10n.setting == 'auto'
                              ? tr('Follows the device language')
                              : null,
                          onTap: _pickLanguage,
                        ),
                        TvSwitchListTile(
                          title: Text(tr('24-hour clock')),
                          subtitle: Text(context.watch<AppPreferences>().use24h
                              ? tr('Times show as 21:30')
                              : tr('Times show as 9:30 PM')),
                          value: context.watch<AppPreferences>().use24h,
                          onChanged: (v) =>
                              context.read<AppPreferences>().setUse24h(v),
                        ),
                      ]),
                  _section('startup', Icons.power_settings_new, tr('Startup'),
                      children: [
                        TvSwitchListTile(
                          title: Text(tr('Launch with profiles selector')),
                          subtitle: Text(tr(
                              'Choose a profile after the splash, before the app opens. Applies from the next start.')),
                          value: context
                              .watch<AppPreferences>()
                              .launchWithProfiles,
                          onChanged: (value) => context
                              .read<AppPreferences>()
                              .setLaunchWithProfiles(value),
                        ),
                        _StartSectionPicker(),
                        // At most one of the two is on; both off = nothing
                        // plays.
                        TvSwitchListTile(
                          title: Text(tr('Resume last channel in full screen')),
                          subtitle: Text(tr(
                              'Opens the last live channel full screen after the splash.')),
                          value: _resumeAtStartup,
                          onChanged: (v) {
                            setState(() {
                              _resumeAtStartup = v;
                              if (v) _resumeInGuide = false;
                            });
                            _storage.setResumeLastChannelAtStartup(v);
                            if (v) _storage.setResumeLastChannelInGuide(false);
                          },
                        ),
                        TvSwitchListTile(
                          title: Text(
                              tr('Resume last channel with the guide open')),
                          subtitle: Text(tr(
                              'Plays the last live channel in the small preview, with the channel list.')),
                          value: _resumeInGuide,
                          onChanged: (v) {
                            setState(() {
                              _resumeInGuide = v;
                              if (v) _resumeAtStartup = false;
                            });
                            _storage.setResumeLastChannelInGuide(v);
                            if (v) {
                              _storage.setResumeLastChannelAtStartup(false);
                            }
                          },
                        ),
                        TvSwitchListTile(
                          title: Text(tr('Fast startup')),
                          subtitle: Text(tr(
                              'Opens the app without waiting for Movies and TV Shows to load; they fill in a few seconds later. For fast devices — leave it off on an older box if the app closes by itself right after starting. Applies from the next start.')),
                          value: context.watch<AppPreferences>().fastStartup,
                          onChanged: (v) =>
                              context.read<AppPreferences>().setFastStartup(v),
                        ),
                        if (!Platform.isWindows)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                            child: Text(
                              tr('Both off: nothing plays at startup (a "Hold > to resume" reminder instead).'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ]),
                  _section('goals', Icons.sports_score, tr('Goals alert'),
                      children: [
                        TvSwitchListTile(
                          title: Text(tr('Goals alert')),
                          subtitle: Text(tr(
                              'Show a top-left popup when a team in My Teams scores. Alerts follow the score feed and pause when scores are hidden.')),
                          value: context.watch<AppPreferences>().goalsAlert,
                          onChanged: (value) => context
                              .read<AppPreferences>()
                              .setGoalsAlert(value),
                        ),
                        TvSwitchListTile(
                          title: Text(tr('Transparent popups')),
                          subtitle: Text(tr(
                              'Reminders and goal alerts lose their background and outline, keeping only the logo and text.')),
                          value:
                              context.watch<AppPreferences>().transparentPopups,
                          onChanged: (value) => context
                              .read<AppPreferences>()
                              .setTransparentPopups(value),
                        ),
                        TvMenuTile(
                          icon: Icons.visibility_outlined,
                          title: tr('Show a test popup'),
                          subtitle: tr('A sample goal alert for 8 seconds.'),
                          onTap: () =>
                              GoalsAlertOverlay.previewRequests.value++,
                        ),
                      ]),
                  _section('tabs', Icons.tab_outlined, tr('Tabs'), children: [
                    TvSwitchListTile(
                      title: Text(tr('Open groups as expanded catalog')),
                      subtitle: Text(tr(
                          'Movies and TV Shows groups open the full poster grid instead of the rows.')),
                      value: context.watch<AppPreferences>().expandedBrowse,
                      onChanged: (v) =>
                          context.read<AppPreferences>().setExpandedBrowse(v),
                    ),
                    TvSwitchListTile(
                      title: Text(tr('Hide profiles')),
                      subtitle: Text(tr('Hides the profiles row on Home.')),
                      value: context.watch<AppPreferences>().hideProfiles,
                      onChanged: (v) =>
                          context.read<AppPreferences>().setHideProfiles(v),
                    ),
                    TvSwitchListTile(
                      title: Text(tr('Show group counts')),
                      subtitle: Text(tr(
                          'How many channels, movies or shows each group holds, beside its name.')),
                      value: context.watch<AppPreferences>().showGroupCounts,
                      onChanged: (v) =>
                          context.read<AppPreferences>().setShowGroupCounts(v),
                    ),
                    TvSwitchListTile(
                      title: Text(tr('Hide Movies')),
                      subtitle: Text(tr(
                          'Removes the Movies tab and movie search results.')),
                      value: context.watch<AppPreferences>().hideMovies,
                      onChanged: (v) =>
                          context.read<AppPreferences>().setHideMovies(v),
                    ),
                    TvSwitchListTile(
                      title: Text(tr('Hide TV Shows')),
                      subtitle: Text(tr(
                          'Removes the TV Shows tab and show search results.')),
                      value: context.watch<AppPreferences>().hideShows,
                      onChanged: (v) =>
                          context.read<AppPreferences>().setHideShows(v),
                    ),
                    TvSwitchListTile(
                      title: Text(tr('Hide Media Hub')),
                      subtitle: Text(tr('Removes the Media Hub tab.')),
                      value: context.watch<AppPreferences>().hideArchive,
                      onChanged: (v) =>
                          context.read<AppPreferences>().setHideArchive(v),
                    ),
                    if (RecordingService.supported)
                      TvSwitchListTile(
                        title: Text(tr('Hide Recordings')),
                        subtitle: Text(tr('Removes the Recordings tab.')),
                        value: context.watch<AppPreferences>().hideRecordings,
                        onChanged: (v) =>
                            context.read<AppPreferences>().setHideRecordings(v),
                      ),
                    if (!Platform.isWindows)
                      TvSwitchListTile(
                        title: Text(tr('Hide Catch-up group')),
                        subtitle: Text(tr(
                            'Removes the TV tab\'s Catch-up row (every channel you can replay).')),
                        value: context.watch<AppPreferences>().hideCatchupGroup,
                        onChanged: (v) => context
                            .read<AppPreferences>()
                            .setHideCatchupGroup(v),
                      ),
                    TvSwitchListTile(
                      title: Text(tr('Recently added channels')),
                      subtitle: Text(tr(
                          'Adds a TV tab group with the channels your playlists added in the last 14 days.')),
                      value:
                          context.watch<AppPreferences>().recentChannelsGroup,
                      onChanged: (v) => context
                          .read<AppPreferences>()
                          .setRecentChannelsGroup(v),
                    ),
                    TvSwitchListTile(
                      title: Text(tr('Hide Multiview')),
                      subtitle: Text(tr(
                          'Removes the Multiview row and the player\'s Open in Multiview button.')),
                      value: context.watch<AppPreferences>().hideMultiview,
                      onChanged: (v) =>
                          context.read<AppPreferences>().setHideMultiview(v),
                    ),
                  ]),
                  if (!Platform.isWindows)
                    _section('background', Icons.picture_in_picture_alt,
                        tr('Background video'),
                        children: [
                          TvSwitchListTile(
                            title: Text(
                                tr('Hide the live picture behind other pages')),
                            subtitle: Text(_withAutomatic(
                                context,
                                DeviceDefaults.hideVideoOnSports,
                                tr('A live channel keeps playing behind {tab}, Settings and Search. Some Fire TV sticks keep showing its picture on top of those pages. Turn this on if that happens: the sound keeps going, only the picture is hidden until you go back. Updating the device\'s software (Fire TV: Settings > My Fire TV > About > Check for Updates) may fix it too.',
                                    {'tab': AppConstants.sportsTabName}))),
                            value: context
                                .watch<AppPreferences>()
                                .hideVideoOnSports,
                            onChanged: (v) => context
                                .read<AppPreferences>()
                                .setHideVideoOnSports(v),
                          ),
                          if (Platform.isAndroid)
                            TvSwitchListTile(
                              title: Text(tr('Native video surface (beta)')),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tr(
                                      'Plays the picture the way native TV apps do, for HDR that looks washed out or green flashes under the guide (Fire TV Cube, NVIDIA Shield). Restart the app after changing it. If the picture is missing, in the wrong place or menus look wrong, turn it off and send us a log.')),
                                  // Live state, so testers can see it's
                                  // really on (English: diagnostic text).
                                  FutureBuilder<String>(
                                    future: NativeVideoSurface.statusLine(),
                                    builder: (context, snap) => Text(
                                        'Status: ${snap.data ?? '…'}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70)),
                                  ),
                                ],
                              ),
                              value: context
                                  .watch<AppPreferences>()
                                  .nativeVideoSurface,
                              onChanged: (v) {
                                context
                                    .read<AppPreferences>()
                                    .setNativeVideoSurface(v);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(tr(
                                        'Close the app completely and open it again to apply this change.'))));
                              },
                            ),
                        ]),
                  // Android only: Windows plays through media_kit.
                  if (Platform.isAndroid)
                    _section(
                        'audio', Icons.surround_sound_outlined, tr('Audio'),
                        children: [
                          TvMenuTile(
                            title: tr('Preferred audio language'),
                            subtitle:
                                _storage.getPreferredAudioLanguage().isEmpty
                                    ? tr('Source default')
                                    : languageName(
                                        _storage.getPreferredAudioLanguage()),
                            onTap: () => _pickTrackLanguage(audio: true),
                          ),
                          TvMenuTile(
                            title: tr('Preferred subtitle language'),
                            subtitle: _storage.getPreferredSubtitleLanguage() ==
                                    'off'
                                ? tr('Off')
                                : languageName(
                                    _storage.getPreferredSubtitleLanguage()),
                            onTap: () => _pickTrackLanguage(audio: false),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                                tr('Movies and episodes use these languages when available. Your manual track choices take priority when resuming.'),
                                style: const TextStyle(color: Colors.white70)),
                          ),
                          TvSwitchListTile(
                            title:
                                Text(tr('Surround passthrough (Dolby Atmos)')),
                            subtitle: Text(tr(
                                'Sends Dolby Digital, Dolby Atmos and DTS sound to your soundbar or receiver untouched (HDMI passthrough), so it can play Atmos. Off: this device turns that sound into plain stereo/5.1 first, so Atmos is lost. While on, the volume of that sound is set on your TV or receiver only, and if you hear nothing on a channel, turn this off. Multiview always uses plain sound (passthrough there kept muted screens playing). Applies from the next channel.')),
                            value: context
                                .watch<AppPreferences>()
                                .audioPassthrough,
                            onChanged: (v) => context
                                .read<AppPreferences>()
                                .setAudioPassthrough(v),
                          ),
                        ]),
                  // Android only (DisplayMatch); Windows follows the monitor.
                  if (Platform.isAndroid)
                    _section('display', Icons.tv_outlined,
                        tr('Frame rate & resolution'),
                        children: [
                          TvSwitchListTile(
                            title: Text(tr('Match frame rate')),
                            subtitle: Text(tr(
                                'Switches the TV to the video\'s frame rate a few seconds after it starts (50 Hz for UK and European channels, 24 Hz for films), for smooth motion. The screen goes black for a second or two while the TV switches; channels with the same rate don\'t switch again. Leaving the app gives the TV its own setting back.')),
                            value:
                                context.watch<AppPreferences>().matchFrameRate,
                            onChanged: (v) => context
                                .read<AppPreferences>()
                                .setMatchFrameRate(v),
                          ),
                          if (context.watch<AppPreferences>().matchFrameRate)
                            TvSwitchListTile(
                              title:
                                  Text(tr('Only switch between 50 and 60 Hz')),
                              subtitle: Text(tr(
                                  'Films at 24 frames per second keep the current rate, so fewer switches.')),
                              value:
                                  context.watch<AppPreferences>().match5060Only,
                              onChanged: (v) => context
                                  .read<AppPreferences>()
                                  .setMatch5060Only(v),
                            ),
                          TvSwitchListTile(
                            title: Text(tr('Match resolution')),
                            subtitle: Text(tr(
                                'Switches the TV to the video\'s resolution (1080p, 4K…) so the TV does the upscaling. Off: this device scales every video to its current resolution.')),
                            value:
                                context.watch<AppPreferences>().matchResolution,
                            onChanged: (v) => context
                                .read<AppPreferences>()
                                .setMatchResolution(v),
                          ),
                        ]),
                  // Windows has no OK info card yet, so no Data pool there.
                  if (!Platform.isWindows)
                    _section(
                        'datapool', Icons.analytics_outlined, tr('Data pool'),
                        children: [
                          TvSwitchListTile(
                            title: Text(tr('Data pool display')),
                            subtitle: Text(tr(
                                'Press OK while a channel, movie or episode plays to open a card with the stream\'s details: resolution, frame rate, codecs, bitrate, quality variants, audio tracks, buffer and HDR. Off: OK shows only the channel info.')),
                            value: context.watch<AppPreferences>().dataPool,
                            onChanged: (v) =>
                                context.read<AppPreferences>().setDataPool(v),
                          ),
                        ]),
                  if (Platform.isAndroid)
                    _section(
                        'catchup', Icons.history_toggle_off, tr('Catch-up'),
                        children: [
                          TvSwitchListTile(
                            title: Text(tr('Keep playing after the programme')),
                            subtitle: Text(tr(
                                "Off: catch-up pauses when the programme you picked ends, so the next one doesn't start on its own; press Play to carry on. On: it keeps going like the channel did.")),
                            value: _storage.getCatchupKeepPlaying(),
                            onChanged: (v) async {
                              await _storage.setCatchupKeepPlaying(v);
                              if (mounted) setState(() {});
                            },
                          ),
                        ]),
                  if (Platform.isAndroid)
                    _section(
                        'skipintro', Icons.skip_next_outlined, tr('Skip intro'),
                        children: [
                          TvSwitchListTile(
                            title: Text(tr('Skip intro and credits button')),
                            subtitle: Text(tr(
                                'On TV show episodes, a button skips the intro, the recap and the credits (or plays the next episode). Press OK while it shows. Times come from IntroDB (introdb.app), a free community database: it is asked with the show\'s IMDb id, season and episode number, nothing else.')),
                            value: _storage.getSkipSegments(),
                            onChanged: (v) async {
                              await _storage.setSkipSegments(v);
                              if (mounted) setState(() {});
                            },
                          ),
                        ]),
                  if (Platform.isAndroid)
                    _section('upnext', Icons.queue_play_next, tr('Up Next'),
                        children: [_UpNextPicker()]),
                  if (Platform.isAndroid)
                    _section('livebuffer', Icons.av_timer, tr('Live buffer'),
                        children: [_LiveBufferPicker()]),
                  _section('trailers', Icons.movie_outlined, tr('Trailers'),
                      children: [
                        TvSwitchListTile(
                          title: Text(tr('Automatic trailers')),
                          subtitle: Text([
                            tr('Play available trailers automatically with sound on IPTV and Media Hub movie and show pages.'),
                            if (Platform.isAndroid)
                              tr('On Fire TV sticks, the trailer plays full screen.'),
                          ].join(' ')),
                          value: context.watch<AppPreferences>().autoTrailers,
                          onChanged: (v) =>
                              context.read<AppPreferences>().setAutoTrailers(v),
                        ),
                      ]),
                  if (context.watch<ArchiveService?>() case final archive?)
                    _section('streamselection', Icons.video_library_outlined,
                        tr('Media Hub playback'),
                        children: [
                          TvSwitchListTile(
                            title:
                                Text(tr('Automatically play the largest file')),
                            subtitle: Text(tr(
                                'Use the largest known file size when starting a title. Resume keeps your selected stream.')),
                            value: archive.autoPlayLargest,
                            onChanged: archive.setAutoPlayLargest,
                          ),
                        ]),
                  _section('favourites', Icons.star_outline, tr('Favourites'),
                      children: [
                        TvSwitchListTile(
                          title: Text(tr('Mix playlists in Favourites')),
                          subtitle: Text(tr(
                              'TV, Movies and TV Shows favourites from every playlist in one A-Z list, instead of one list per playlist.')),
                          value: context
                              .watch<AppPreferences>()
                              .mixFavoritePlaylists,
                          onChanged: (v) => context
                              .read<AppPreferences>()
                              .setMixFavoritePlaylists(v),
                        ),
                      ]),
                  if (!Platform.isWindows)
                    _section('multiview', Icons.grid_view, tr('Multiview'),
                        children: [
                          TvSwitchListTile(
                            title: Text(tr('Show the Multiview tip')),
                            subtitle: Text(tr(
                                'The connections reminder shown when opening Multiview.')),
                            value: _showMultiviewTip,
                            onChanged: (v) {
                              setState(() => _showMultiviewTip = v);
                              _storage.setMultiviewHideTips(!v);
                            },
                          ),
                        ]),
                  _section('resume', Icons.play_circle_outline,
                      tr('Resume reminder'),
                      children: [
                        TvSwitchListTile(
                          title:
                              Text(tr('Show the "Hold > to resume" reminder')),
                          subtitle: Text(Platform.isWindows
                              ? tr(
                                  'The pill at the bottom while a channel plays in the background. Off: hidden.')
                              : tr(
                                  'The pill at the bottom while a channel plays in the background. Off: hidden — holding Right still resumes.')),
                          value: _showResumePill,
                          onChanged: (v) {
                            setState(() => _showResumePill = v);
                            LiveResumeHint.pillEnabled.value = v;
                            _storage.setShowResumePill(v);
                          },
                        ),
                      ]),
                  _section('history', Icons.history, tr('History'), children: [
                    TvMenuTile(
                      icon: Icons.manage_search,
                      title: tr('Clear search & channel history'),
                      subtitle:
                          tr('Recent searches and the live channel History'),
                      onTap: _clearSearchAndChannelHistory,
                    ),
                    TvMenuTile(
                      icon: Icons.movie_outlined,
                      title: tr('Clear Movies & TV Shows history'),
                      subtitle: tr('Continue Watching and saved progress'),
                      onTap: _clearMoviesAndShowsHistory,
                    ),
                  ]),
                ],
              ),
            ));
  }
}

/// Playback > Up Next ([StorageService.getUpNextMode]): when the next
/// episode starts by itself. One row; OK opens the choices.
/// Settings > Playback > Live buffer: how much live video is stored before
/// playing (and after a stall). Bigger hides server dropouts, but the
/// channel starts later and plays that much behind live.
class _LiveBufferPicker extends StatefulWidget {
  @override
  State<_LiveBufferPicker> createState() => _LiveBufferPickerState();
}

class _LiveBufferPickerState extends State<_LiveBufferPicker> {
  static const _choices = [
    (0, 'Off'),
    // Native player: fast start, then plays at 96 % until a reserve covers
    // the server's gaps (VideoPlayer.cushionTick).
    (-1, 'Gradual (starts fast, builds up)'),
    (1500, 'Small (1.5 seconds)'),
    (4000, '4 seconds'),
    (8000, '8 seconds'),
    (12000, '12 seconds'),
  ];

  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();
    final current = storage.getLiveBufferMs();
    final name = _choices
        .firstWhere((c) => c.$1 == current, orElse: () => _choices.first)
        .$2;
    return TvMenuTile(
      leading: const Icon(Icons.av_timer),
      title: tr('Live buffer'),
      subtitle: tr(
          '{size}. Live channels store this much before playing, so short dropouts from the server don\'t show. Bigger hides longer dropouts, but channels start later and play that much behind live. Applies from the next channel.',
          {'size': tr(name)}),
      onTap: () async {
        final picked = await showDialog<int>(
          context: context,
          builder: (dialogContext) => SimpleDialog(
            title: Text(tr('Live buffer')),
            children: [
              for (final (ms, label) in _choices)
                TvDialogOption(
                  autofocus: ms == current,
                  onPressed: () => Navigator.of(dialogContext).pop(ms),
                  child: Row(children: [
                    Icon(ms == current
                        ? Icons.check_circle
                        : Icons.circle_outlined),
                    const SizedBox(width: 12),
                    Text(tr(label)),
                  ]),
                ),
            ],
          ),
        );
        if (picked == null) return;
        await storage.setLiveBufferMs(picked);
        await VodBuffering.setLiveBufferDefault(picked);
        if (mounted) setState(() {});
      },
    );
  }
}

class _UpNextPicker extends StatefulWidget {
  @override
  State<_UpNextPicker> createState() => _UpNextPickerState();
}

class _UpNextPickerState extends State<_UpNextPicker> {
  static const _modes = [
    ('early', '30 seconds before the end'),
    ('end', 'When the episode ends'),
    ('off', 'Never'),
  ];

  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();
    final current = storage.getUpNextMode();
    final name = _modes.firstWhere((m) => m.$1 == current).$2;
    return TvMenuTile(
      leading: const Icon(Icons.queue_play_next),
      title: tr('Play the next episode'),
      subtitle: tr(
          '{when}. On TV show episodes, the Up Next card counts down and the next episode starts by itself. Never: no countdown; the episode plays to its end.',
          {'when': tr(name)}),
      onTap: () async {
        final picked = await showDialog<String>(
          context: context,
          builder: (dialogContext) => SimpleDialog(
            title: Text(tr('Play the next episode')),
            children: [
              for (final (id, label) in _modes)
                TvDialogOption(
                  autofocus: id == current,
                  onPressed: () => Navigator.of(dialogContext).pop(id),
                  child: Row(children: [
                    Icon(id == current
                        ? Icons.check_circle
                        : Icons.circle_outlined),
                    const SizedBox(width: 12),
                    Text(tr(label)),
                  ]),
                ),
            ],
          ),
        );
        if (picked == null) return;
        await storage.setUpNextMode(picked);
        if (mounted) setState(() {});
      },
    );
  }
}

/// Startup > Open on: TV / Movies / TV Shows / Media Hub / Sports Trak
/// ([AppPreferences.startSection]). One row; OK opens the choices.
class _StartSectionPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<AppPreferences>();
    final current = prefs.startSection;
    final name = AppPreferences.startSections
        .firstWhere((s) => s.$1 == current,
            orElse: () => AppPreferences.startSections.first)
        .$2;
    return TvMenuTile(
      leading: const Icon(Icons.home_outlined),
      title: tr('Open on'),
      subtitle: tr(
          '{section}. Where the app opens after starting. With "Resume last channel in full screen" on, the channel then plays in the background instead.',
          {'section': tr(name)}),
      onTap: () async {
        final picked = await showDialog<String>(
          context: context,
          builder: (dialogContext) => SimpleDialog(
            title: Text(tr('Open on')),
            children: [
              for (final (id, label) in AppPreferences.startSections)
                TvDialogOption(
                  autofocus: id == current,
                  onPressed: () => Navigator.of(dialogContext).pop(id),
                  child: Row(children: [
                    Icon(id == current
                        ? Icons.check_circle
                        : Icons.circle_outlined),
                    const SizedBox(width: 12),
                    Text(tr(label)),
                  ]),
                ),
            ],
          ),
        );
        if (picked != null) prefs.setStartSection(picked);
      },
    );
  }
}
