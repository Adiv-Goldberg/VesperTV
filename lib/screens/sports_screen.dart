import '../utils/refined_finish.dart';
import '../widgets/sports_mode_live_panel.dart';
import '../widgets/sports_mode_shell.dart';
import '../widgets/sports_mode_toggle.dart';
import '../services/viewer_profile_service.dart';
import 'archive_screen.dart';
import 'tv_home_screen.dart';
import 'search_screen.dart';
import 'home_screen.dart';
import 'multiview_screen.dart';
import 'desktop_multiview_screen.dart';
import 'recordings_screen.dart';
import 'settings/settings_menu_screen.dart';
import 'settings/profiles_screen.dart';
import 'package:window_manager/window_manager.dart';
import '../services/game_reminders.dart';
import '../widgets/game_reminder_menu_tile.dart';
import '../widgets/game_score_alert_menu_tile.dart';
import '../widgets/game_reminder_timing_menu.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:media_kit/media_kit.dart' show Player;
import 'package:media_kit_video/media_kit_video.dart'
    show NoVideoControls, Video, VideoController;
import 'package:provider/provider.dart';

import '../utils/constants.dart';
import '../models/channel.dart';
import '../models/sports.dart';
import '../services/app_preferences.dart';
import '../services/desktop_mini_player.dart';
import '../services/epg_service.dart';
import '../services/playback_service.dart';
import '../services/guide_key.dart';
import '../services/profile_gate.dart';
import '../services/playlist_manager.dart';
import '../services/recording_service.dart';
import '../services/sports_channel_matcher.dart';
import '../services/sports_channel_library.dart';
import '../services/sports_follows.dart';
import '../services/sports_ranks.dart';
import '../services/sports_service.dart';
import '../services/storage_service.dart';
import '../utils/time_format.dart';
import '../utils/route_observer.dart';
import '../utils/tv_theme.dart';
import '../widgets/video_tap_layer.dart';
import '../widgets/hold_to_activate.dart';
import '../widgets/roll_down_menu.dart';
import '../widgets/live_resume_hint.dart';
import '../widgets/player_controls.dart';
import '../widgets/rec_cue.dart';
import '../widgets/sports_matchup_stats.dart';
import '../widgets/settings_scaffold.dart';
import '../widgets/sports_widgets.dart';
import '../widgets/tv_menu_tile.dart';
import '../widgets/tv_text_field_gate.dart';
import 'desktop_player_screen.dart';
import 'player_screen.dart';
import 'sports_channels_screen.dart';
import 'sports_live_list_screen.dart';
import 'sports_my_teams_screen.dart';
import 'sports_league_manager_screen.dart';
import 'sports_standings_screen.dart';
import '../l10n/l10n.dart';

// Keep UI and playback routing on the same Flutter target. This also lets
// Android widget tests on a Windows development PC exercise the TV path.
bool get _desktopSports => defaultTargetPlatform == TargetPlatform.windows;

/// Sports: today's games across the user's leagues with logos, records,
/// live scores and the IPTV channel each game is on (see
/// [SportsChannelMatcher] for how channels are found). Select a game for its
/// channels; when none was found — or the wrong one — the user picks it once
/// and can have it remembered for that team.
///
/// D-pad layout, top to bottom: league chips, day strip, then one horizontal
/// row per section (Live now / Later / Final). Up/Down move between those
/// zones explicitly (CLAUDE.md §10: default traversal across differently
/// shaped rows is unreliable); Left/Right is plain traversal inside a row.
class SportsScreen extends StatefulWidget {
  const SportsScreen({super.key, this.home = false, this.service});
  final bool home;

  /// A supplied service lets navigation tests run without live feeds.
  final SportsService? service;

  @override
  State<SportsScreen> createState() => _SportsScreenState();
}

class _Section {
  _Section(this.id, this.label, this.games);
  final String id;
  final String label;
  final List<SportsGame> games;
}

class _SportsScreenState extends State<SportsScreen> with RouteAware {
  bool _channelsMode = false;
  final _modeShell = GlobalKey<SportsModeShellState>();
  final Map<int, String> _lastModeControls = {};
  bool _modeRailFocused = false;

  // Sports Mode's own Live TV (owner, 2026-10-28): groups + see-through guide
  // beside the sports page instead of leaving it for the TV home.
  final _livePanel = GlobalKey<SportsModeLivePanelState>();
  bool _liveOpen = false;

  /// The rail's Live TV is the in-page panel (TV layout), not the TV home.
  bool _livePanelLayout = false;

  // Sports Mode while a game plays (TV): the left column is a feed of the
  // day's games beside the big video ("watching"); Down past its end shows
  // the card rows under a small hero ("browsing"), Up from them comes back
  // (owner, 2026-10-28). One focus node, rows drawn selected (no per-row
  // nodes, like PlayerSidePanel).
  final _feedNode = FocusNode(debugLabel: 'sports-mode-feed');
  final _feedScroll = ScrollController();
  int _feedIndex = 0;
  bool _modeBrowsing = false;
  bool _feedVisible = false;
  bool _feedFocused = false;
  bool _feedSelectDown = false;
  bool _feedHoldFired = false;
  final Stopwatch _feedHeld = Stopwatch();
  static const double _feedRowHeight = 58;
  bool _exitPromptOpen = false;
  SportsService get _service => widget.service ?? SportsService.instance;
  bool get _modeActive => context.read<AppPreferences>().sportsMode;

  late final StorageService _storage;
  late final SportsChannelMatcher _matcher;
  late SportsChannelPicks _picks;
  late SportsFollows _follows;

  late List<SportsLeague> _leagues;
  bool _hideEmptyLeagues = false;
  Set<String> _emptyLeagues = {};
  Set<String>? _movingVisibleLeagues;

  /// Display-only filtering. Saved membership/order and the league manager,
  /// standings, My Teams and matching sources keep the complete league list.
  List<SportsLeague> get _navigationLeagues {
    final moving = _movingVisibleLeagues;
    if (moving != null) {
      return _leagues.where((league) => moving.contains(league.id)).toList();
    }
    if (!_hideEmptyLeagues) {
      return _leagues;
    }
    return _leagues
        .where((league) => !_emptyLeagues.contains(league.id))
        .toList();
  }

  /// A refresh can remove a focused chip or move it across the top-five
  /// rail boundary. Keep its node when possible, otherwise land on a real
  /// visible league/All control after the new widgets have mounted.
  void _updateLeagueNavigation(VoidCallback update) {
    final focused = _chipNodes.entries
        .where(
            (entry) => entry.key.startsWith('league:') && entry.value.hasFocus)
        .firstOrNull;
    final before = _navigationLeagues.map((league) => league.id).join('|');
    final wasRail = _modeRailFocused;
    setState(update);
    if (focused == null ||
        before == _navigationLeagues.map((league) => league.id).join('|')) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_navigationLeagues
          .any((league) => 'league:${league.id}' == focused.key)) {
        focused.value.requestFocus();
      } else if (_modeActive && wasRail) {
        _modeShell.currentState?.focusRail();
      } else {
        _focusModeNode('league:all');
      }
    });
  }

  String? _leagueFilter;
  int _dayOffset = 0;

  /// Empty day with one league picked: that league's next game (from
  /// [SportsService.nextGameStart]), offered as a jump. Null = none found.
  DateTime? _nextGame;
  bool _nextGameLooked = false;
  bool _hideScores = false;

  List<SportsGame> _games = const [];

  /// Last visit's channels, shown at once on the way back in while the
  /// silent re-match confirms them (owner: reopening Sports said
  /// "Looking…" again for channels it had just found).
  static Map<String, List<ChannelMatch>> _lastMatches = const {};
  Map<String, List<ChannelMatch>> _matches = _lastMatches;
  bool _loading = true;
  bool _matching = false;
  String? _error;
  int _loadToken = 0;

  SportsGame? _heroGame;
  Timer? _pollTimer;
  bool _covered = false;

  /// Android: the game whose channel plays in the hero (Play/Pause on its
  /// card, or back from its fullscreen) — see [_setPreview]. Only counts
  /// while [PlaybackService] still plays [_previewChannel] (see
  /// [_livePreview]); a CH+/CH- zap in the player ends it.
  SportsGame? _previewGame;
  Channel? _previewChannel;

  /// Focusing another card shows its details beside the still-playing video.
  /// OK previews it; Back returns to the playing game's information.
  /// Cleared by any [_setPreview].
  SportsGame? _heroPick;

  /// The game previewing in the hero when Networks opened: back from
  /// Networks it plays there again ([_closeNetworks]).
  SportsGame? _gameBeforeNetworks;
  Channel? _channelBeforeNetworks;

  void _openNetworks() {
    final live = _livePreview(context.read<PlaybackService>()) != null;
    _gameBeforeNetworks = live ? _previewGame : null;
    _channelBeforeNetworks = live ? _previewChannel : null;
    setState(() => _channelsMode = true);
  }

  /// Back from Networks (owner: the mini player stopped). The hero shows a
  /// game, so: the same stream still playing goes back to its game (no
  /// restart); another channel picked in Networks gives way to the game
  /// that played before; a Networks-only preview stops (nothing left
  /// playing unseen behind Games).
  void _closeNetworks() {
    final game = _gameBeforeNetworks;
    final channel = _channelBeforeNetworks;
    _gameBeforeNetworks = null;
    _channelBeforeNetworks = null;
    setState(() => _channelsMode = false);
    if (_modeActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusModeNode('networks');
      });
    }
    final playing = _previewChannel;
    if (game != null && channel != null) {
      if (playing?.id == channel.id) {
        if (_previewGame == null) setState(() => _previewGame = game);
      } else {
        unawaited(_setPreview(game, channel));
      }
    } else if (playing != null && _previewGame == null) {
      unawaited(_setPreview(null, null));
    }
  }

  /// Preview starts/stops run one at a time (see [_setPreview]).
  Future<void> _previewChain = Future.value();
  Completer<void>? _previewOpened;
  bool _fullScreenPending = false;
  int _previewSeq = 0;
  int? _previewFeedFocusSeq;

  /// The "Hold > to resume" pill covered the cards and Standings' table;
  /// hidden for as long as Sports (and anything pushed over it) is open.
  late final VoidCallback _showResumeHint;

  // Focus bookkeeping — see the class doc for the zone model.
  // Zones: 0 league chips, 1 day chips, 2 Standings button, 3+ game rows.
  static const _firstRowZone = 3;
  int _zone = _firstRowZone;
  final Map<String, FocusNode> _chipNodes = {};
  final Map<String, FocusNode> _cardNodes = {};
  final Map<String, String> _lastCardInRow = {};
  final Map<String, GlobalKey> _rowKeys = {};

  /// Per card row, for the Windows ‹ › mouse arrows (SportsRowArrows).
  final Map<String, ScrollController> _rowScrolls = {};
  bool _initialFocusDone = false;

  @override
  void initState() {
    super.initState();
    _showResumeHint = LiveResumeHint.hideWhileMounted();
    FocusManager.instance.addListener(_rememberModeControlFocus);
    // Sports Mode root: the remote's Guide button opens Live TV on its
    // guide, through the rail's own page path ([GuideKey]).
    if (widget.home) GuideKey.registerOpener(this, _openGuide);
    // Windows: the hero plays through DesktopMiniPlayer, not PlaybackService.
    if (_desktopSports) {
      DesktopMiniPlayer.instance.channel.addListener(_onMiniPlayerChanged);
    }
    _storage = context.read<StorageService>();
    _matcher = SportsChannelMatcher.shared(context.read<EpgService>());
    _picks = SportsChannelPicks.load(_storage);
    _follows = SportsFollows.load(_storage);
    _leagues = _savedLeagues();
    _hideEmptyLeagues = _storage.getSportsHideEmptyLeagues();
    // Opens on the favourite league (League manager, hold OK), if any.
    _leagueFilter = favoriteSportsLeague(_storage)?.id;
    _hideScores = _storage.getSportsHideScores();
    if (_modeActive) _ensureInitialFocus();
    unawaited(_load());
    // Live scores tick while the screen is visible; SportsService's own
    // freshness window decides whether a tick actually hits the network.
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_covered && mounted) unawaited(_load(silent: true));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) appRouteObserver.subscribe(this, route);
  }

  @override
  void didPushNext() => _covered = true;

  void _onMiniPlayerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didPopNext() {
    _covered = false;
    unawaited(_load(silent: true));
  }

  @override
  void dispose() {
    GuideKey.unregisterOpener(this);
    _previewSeq++;
    appRouteObserver.unsubscribe(this);
    FocusManager.instance.removeListener(_rememberModeControlFocus);
    if (_desktopSports) {
      DesktopMiniPlayer.instance.channel.removeListener(_onMiniPlayerChanged);
    }
    _showResumeHint();
    _pollTimer?.cancel();
    for (final n in _chipNodes.values) {
      n.dispose();
    }
    for (final n in _cardNodes.values) {
      n.dispose();
    }
    for (final c in _rowScrolls.values) {
      c.dispose();
    }
    _feedNode.dispose();
    _feedScroll.dispose();
    super.dispose();
  }

  DateTime get _day {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day + _dayOffset);
  }

  List<SportsLeague> get _shownLeagues => _leagueFilter == null
      ? _leagues
      : _leagues.where((l) => l.id == _leagueFilter).toList();

  Future<void> _load({bool silent = false}) async {
    final token = ++_loadToken;
    final viewer = _storage.viewerGeneration;
    final day = _day;
    final hideEmpty = _storage.getSportsHideEmptyLeagues();
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final dayGames =
        await _service.gamesForDay(hideEmpty ? _leagues : _shownLeagues, day);
    if (!mounted ||
        token != _loadToken ||
        viewer != _storage.viewerGeneration) {
      return;
    }
    if (day != _day) return _load(silent: silent);
    final active = dayGames.map((game) => game.league.id).toSet();
    final empty = <String>{
      if (hideEmpty)
        for (final league in _leagues)
          if (!active.contains(league.id) &&
              _service.hasReliableSchedule(league, day))
            league.id,
    };
    final filter = empty.contains(_leagueFilter) ? null : _leagueFilter;
    final games = hideEmpty && filter != null
        ? dayGames.where((game) => game.league.id == filter).toList()
        : dayGames;
    final filtered = sportsLeagueById(filter ?? '');
    DateTime? next;
    if (games.isEmpty && filtered != null) {
      next = await _service.nextGameStart(filtered, day);
      if (!mounted ||
          token != _loadToken ||
          viewer != _storage.viewerGeneration) {
        return;
      }
    }
    _updateLeagueNavigation(() {
      _hideEmptyLeagues = hideEmpty;
      _emptyLeagues = empty;
      _leagueFilter = filter;
      _nextGame = next;
      _nextGameLooked = games.isEmpty && filtered != null;
      _games = games;
      _loading = false;
      _error = games.isEmpty ? _service.lastError : null;
      final heroKey = _heroGame == null ? null : _gameKey(_heroGame!);
      _heroGame = games.where((g) => _gameKey(g) == heroKey).firstOrNull ??
          _defaultHero(games);
    });
    _ensureInitialFocus();
    // Team ranks beside the names, from the cached standings tables.
    unawaited(SportsRanks.ensure(games.map((g) => g.league)).then((changed) {
      if (changed && mounted) setState(() {});
    }));
    await _rematch(token);
  }

  Future<void> _rematch([int? token]) async {
    final myToken = token ?? _loadToken;
    setState(() => _matching = true);
    final playlist = context.read<PlaylistManager>();
    await playlist.ensureLiveChannelsLoaded();
    if (!mounted) return;
    final live = playlist.visibleChannels(category: 'tv');
    await _matcher.prepare(live, hidden: playlist.hiddenLiveChannels());
    _picks = SportsChannelPicks.load(_storage);
    final matches = await _matcher.matchDay(_games, _picks);
    if (!mounted || myToken != _loadToken) return;
    final sourceStore = SportsChannelLists(context.read<StorageService>());
    final countries = _picks.countryPreferences;
    for (final game in _games) {
      final saved = sourceStore.sourcesFor(game, _gameKey(game));
      if (saved.isEmpty) continue;
      matches[_gameKey(game)] = [
        for (final c in live.where((c) => saved.contains(c.id)).take(8))
          ChannelMatch(c, MatchReason.pick,
              _picks.channelIdFor(game) == c.id ? 1000 : 950,
              detail: tr('Your added source')),
        for (final m in matches[_gameKey(game)] ?? <ChannelMatch>[])
          if (!saved.contains(m.channel.id)) m,
      ]..sort((a, b) => b.score.compareTo(a.score));
      matches[_gameKey(game)] =
          _picks.orderMatches(matches[_gameKey(game)]!, countries: countries);
    }
    setState(() {
      _redZoneChoices = _findRedZones(live);
      _redZone = _redZoneChoices
              .where((c) => c.id == _picks.redZoneChannelId)
              .firstOrNull ??
          _redZoneChoices.firstOrNull;
      _matches = matches;
      _lastMatches = {..._lastMatches, ...matches};
      _matching = false;
    });
  }

  static String _gameKey(SportsGame g) => SportsChannelPicks.eventKey(g);

  /// The playlist's NFL RedZone channels for the pill next to Standings /
  /// My Teams: names with "redzone"/"red zone", best first — ones also
  /// saying "NFL", then the shortest name (the plain channel, not an event
  /// copy). The first is the automatic choice; hold the pill to pick
  /// another (e.g. a 4K one) — see [_chooseRedZone].
  static List<Channel> _findRedZones(Iterable<Channel> channels) {
    final re = RegExp(r'red\s*zone', caseSensitive: false);
    int score(Channel c) =>
        (c.name.toLowerCase().contains('nfl') ? 1000 : 0) - c.name.length;
    return channels.where((c) => re.hasMatch(c.name)).toList()
      ..sort((a, b) => score(b).compareTo(score(a)));
  }

  List<Channel> _redZoneChoices = const [];

  /// The pill's channel: the held-pill pick if it's still in the playlist,
  /// else the automatic one. Null hides the pill.
  Channel? _redZone;

  /// Hold on the RedZone pill: pick which RedZone channel it plays.
  Future<void> _chooseRedZone() async {
    final choices = _redZoneChoices;
    if (choices.isEmpty) return;
    final savedId = _picks.redZoneChannelId;
    final auto = choices.first;
    final picked = await showDialog<Object>(
      context: context,
      // Opened by a hold: drop the held OK's repeats.
      builder: (context) => SwallowHeldActivate(
        child: AlertDialog(
          backgroundColor: const Color(0xFF15151A),
          title: Text(tr('NFL RedZone channel')),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TvMenuTile(
                    autofocus: savedId == null,
                    icon: Icons.auto_awesome,
                    title: tr('Automatic'),
                    subtitle: auto.name,
                    trailing: savedId == null
                        ? const Icon(Icons.check, color: Colors.white)
                        : const SizedBox.shrink(),
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                  for (final c in choices)
                    TvMenuTile(
                      autofocus: c.id == savedId,
                      icon: Icons.sports_football,
                      title: c.name,
                      subtitle: c.group,
                      trailing: c.id == savedId
                          ? const Icon(Icons.check, color: Colors.white)
                          : const SizedBox.shrink(),
                      onTap: () => Navigator.of(context).pop(c),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await _picks.setRedZone(picked is Channel ? picked.id : null);
    if (!mounted) return;
    setState(() => _redZone = picked is Channel ? picked : auto);
  }

  /// Only with all leagues or the NFL shown.
  bool get _showRedZone =>
      _redZone != null && (_leagueFilter == null || _leagueFilter == 'nfl');

  SportsGame? _defaultHero(List<SportsGame> games) {
    if (games.isEmpty) return null;
    return games.where((g) => g.state == GameState.live).firstOrNull ??
        games.where((g) => g.state == GameState.pre).firstOrNull ??
        games.first;
  }

  /// [games] grouped by league in the user's league order (start order
  /// kept inside each league), so a night of NHL + NBA + NFL reads as
  /// blocks with a league divider between them (user request: "each league
  /// on its own row" — kept as one row per Live / Later / Final instead, so
  /// what's live stays first).
  List<SportsGame> _byLeague(Iterable<SportsGame> games) {
    final order = {for (final (i, l) in _leagues.indexed) l.id: i};
    final list = games.indexed.toList()
      ..sort((a, b) {
        final c = (order[a.$2.league.id] ?? order.length)
            .compareTo(order[b.$2.league.id] ?? order.length);
        return c != 0 ? c : a.$1.compareTo(b.$1);
      });
    return [for (final e in list) e.$2];
  }

  List<_Section> get _sections {
    final mode = _modeActive;
    final followed =
        mode ? _games.where(_follows.involves).toList() : <SportsGame>[];
    final remaining = _games.where((game) => !mode || !_follows.involves(game));
    // My Teams' games first (stable: start order kept within each half),
    // then the rest by league.
    List<SportsGame> followedFirst(Iterable<SportsGame> games) => [
          ...games.where(_follows.involves),
          ..._byLeague(games.where((g) => !_follows.involves(g))),
        ];
    final live =
        followedFirst(remaining.where((g) => g.state == GameState.live));
    final pre = followedFirst(remaining.where((g) => g.state == GameState.pre));
    final post = _byLeague(remaining.where((g) => g.state == GameState.post));
    final laterLabel = switch (_dayOffset) {
      0 => tr('Later today'),
      1 => tr('Tomorrow'),
      _ when _dayOffset < 0 => tr('Not played'),
      _ => tr('Scheduled'),
    };
    return [
      if (followed.isNotEmpty) _Section('teams', tr('My Teams'), followed),
      if (live.isNotEmpty) _Section('live', tr('Live now'), live),
      if (pre.isNotEmpty) _Section('pre', laterLabel, pre),
      if (post.isNotEmpty) _Section('post', tr('Final'), post),
    ];
  }

  // ---------------------------------------------------------------- focus

  FocusNode _chipNode(String id) =>
      _chipNodes[id] ??= FocusNode(debugLabel: 'sports-chip-$id');

  FocusNode _cardNode(String key) =>
      _cardNodes[key] ??= FocusNode(debugLabel: 'sports-card-$key');

  String get _leagueChipId => 'league:${_leagueFilter ?? 'all'}';
  String get _dayChipId => 'day:$_dayOffset';

  void _ensureInitialFocus() {
    if (_initialFocusDone) return;
    _initialFocusDone = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_modeActive) {
        _modeShell.currentState?.focusRail();
        return;
      }
      // The league row, not the first game card (owner's request).
      _focusZone(0, _sections);
    });
  }

  void _focusZone(int zone, List<_Section> sections) {
    if (_modeActive && _feedVisible && zone >= _firstRowZone) {
      _focusFeed();
      return;
    }
    if (_modeActive && zone < _firstRowZone) {
      final ids = _modeControlIds(zone);
      if (ids.isEmpty) return;
      final remembered = _lastModeControls[zone];
      final selected = zone == 0
          ? _leagueChipId
          : zone == 1
              ? _dayChipId
              : ids.first;
      final id = ids.contains(remembered)
          ? remembered!
          : ids.contains(selected)
              ? selected
              : ids.first;
      _focusModeNode(id);
      _zone = zone;
      return;
    }
    if (zone >= _firstRowZone && sections.isNotEmpty) {
      zone = zone.clamp(_firstRowZone, _firstRowZone + sections.length - 1);
    }
    if (zone == 0) {
      // requestFocus alone doesn't scroll the chip row to it.
      final node = _chipNode(_leagueChipId);
      node.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = node.context;
        if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.5);
      });
    } else if (zone == 1) {
      _chipNode(_dayChipId).requestFocus();
    } else if (zone == 2) {
      _chipNode(_showStandingsChip ? 'standings' : 'myteams').requestFocus();
    } else if (sections.isEmpty) {
      if (_modeActive && _chipNode('nextgame').context == null) {
        _focusZone(0, sections);
        return;
      }
      _chipNode('nextgame').requestFocus();
    } else {
      final s = sections[zone - _firstRowZone];
      final remembered = _lastCardInRow[s.id];
      final key = s.games.any((g) => _gameKey(g) == remembered)
          ? remembered!
          : _gameKey(s.games.first);
      if (_modeActive) {
        _focusModeCard(s, key);
      } else {
        _cardNode(key).requestFocus();
      }
    }
    _zone = zone;
  }

  static const _liveAllId = 'liveall';

  /// "See all" beside Live now: with 2+ live games (owner, 2026-10-17).
  bool get _showLiveAll =>
      _games.where((g) => g.state == GameState.live).length >= 2;

  /// Later / Final rows this long get "See all" (a grid of the row).
  static const _seeAllMin = 5;

  /// The chip in [s]'s header: Live now's "See all" (live card grid),
  /// or "See all" (grid, [_openSectionGrid]); null = none.
  String? _headerChipId(_Section s) => s.id == 'live'
      ? (_showLiveAll ? _liveAllId : null)
      : (s.games.length >= _seeAllMin ? 'seeall-${s.id}' : null);

  /// Up from one of a row's first two cards reaches its header chip (it
  /// sits above them); Down from the chip goes back to the row, Up to the
  /// row (or header) above.
  bool _headerChipStep(int delta, List<_Section> sections) {
    for (final (i, s) in sections.indexed) {
      final id = _headerChipId(s);
      if (id == null) continue;
      final zone = _firstRowZone + i;
      if (_chipNodes[id]?.hasFocus ?? false) {
        if (!_backToFeed(delta, zone)) {
          _focusZone(delta < 0 ? zone - 1 : zone, sections);
        }
        return true;
      }
      if (delta > 0 || _zone != zone) continue;
      final c =
          s.games.indexWhere((g) => _cardNodes[_gameKey(g)]?.hasFocus ?? false);
      if (c < 0 || c > 1) return false;
      _chipNode(id).requestFocus();
      _ensureRowVisible(s.id);
      return true;
    }
    return false;
  }

  /// "See all" on a long row: its games as a grid; OK on one comes back to
  /// it in the row (selected, like moving there with the remote).
  Future<void> _openSectionGrid(_Section s) async {
    final picked = await Navigator.of(context).push<SportsGame>(
      MaterialPageRoute(
        builder: (_) => _SectionGridScreen(
          title: s.label,
          games: s.games,
          cardFor: (g, focusNode, onTap) => _GameCard(
            focusNode: focusNode,
            game: g,
            match: _matches[_gameKey(g)]?.firstOrNull,
            matching: _matching,
            hideScores: _hideScores,
            starred: _follows.involves(g),
            previewing: false,
            onFocus: () {},
            onTap: onTap,
            onHold: onTap,
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final sections = _sections;
    final i = sections.indexWhere((x) => x.id == s.id);
    if (i < 0) return;
    final key = _gameKey(picked);
    _lastCardInRow[s.id] = key;
    // The row is lazy: scroll near the card first, then focus it.
    final index = sections[i].games.indexWhere((g) => _gameKey(g) == key);
    final c = _rowScrolls[s.id];
    if (index >= 0 && c != null && c.hasClients) {
      c.jumpTo((index * (_GameCard.width + 12))
          .clamp(c.position.minScrollExtent, c.position.maxScrollExtent));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusZone(_firstRowZone + i, sections);
      final ctx = _cardNodes[key]?.context;
      if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.5);
      _ensureRowVisible(s.id);
    });
  }

  Future<void> _openLiveList() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (pageContext) => SportsLiveListScreen(
        leagues: _shownLeagues,
        day: _day,
        follows: _follows,
        hideScores: _hideScores,
        matchGames: _matchGames,
        onWatch: (channel) => _play(channel, source: pageContext),
        onMenu: (game, matches, watch) => _openGame(game, matches, watch),
        initialGames: _games,
        initialMatches: _matches,
        cardWidth: _GameCard.width,
        cardBuilder: (game, match, matching, node, onFocus, onTap, onHold) =>
            _GameCard(
          focusNode: node,
          game: game,
          match: match,
          matching: matching,
          hideScores: _hideScores,
          starred: _follows.involves(game),
          previewing: false,
          onFocus: onFocus,
          onTap: onTap,
          onHold: onHold,
        ),
      ),
    ));
  }

  void _moveZone(int delta) {
    final sections = _sections;
    if (_modeActive && _feedVisible && delta > 0 && _zone == 2) {
      _focusFeed();
      return;
    }
    // Up from the first card row while browsing: straight back to the big
    // player (before its See all chip, owner 2026-10-29).
    if (_backToFeed(delta, _zone)) return;
    if (_headerChipStep(delta, sections)) return;
    var target = _zone + delta;
    if (_modeActive && target == 1) target += delta;
    final rows = sections.isEmpty && _nextGame != null ? 1 : sections.length;
    if (target < 0 || target >= _firstRowZone + rows) return;
    _focusZone(target, sections);
  }

  /// A phone (touch, no remote): the whole page scrolls (see [build]).
  bool get _touch =>
      defaultTargetPlatform == TargetPlatform.android &&
      !context.read<AppPreferences>().isTelevision;

  /// Portrait phone: the hero stacks and the side padding shrinks.
  bool get _narrow => MediaQuery.sizeOf(context).width < 600;

  void _ensureRowVisible(String sectionId) {
    // A tap focuses the card; scrolling the page then would yank it away.
    if (_touch) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _rowKeys[sectionId]?.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx,
            duration:
                _modeActive ? Duration.zero : const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: 0.05);
      }
    });
  }

  // -------------------------------------------------------------- actions

  /// Sports Mode's All dropdown (hold All in regular Sports Trak): every
  /// enabled league, including sidebar/off-screen ones, with its game / live
  /// counts for the day shown — pick one to
  /// filter to it (owner, 2026-10-22). With a league filter on, only its
  /// games are loaded, so the day is fetched for every league (cached).
  Future<void> _openLeagueMenu() async {
    final anchor = rollDownAnchorOf(_chipNode('league:all').context);
    List<SportsGame> games;
    try {
      games = _leagueFilter == null
          ? _games
          : await _service.gamesForDay(_leagues, _day);
    } catch (_) {
      games = _games;
    }
    if (!mounted) return;
    final counts = <String, (int, int)>{};
    for (final g in games) {
      final (n, live) = counts[g.league.id] ?? (0, 0);
      counts[g.league.id] = (n + 1, live + (g.state == GameState.live ? 1 : 0));
    }
    // Every league in the bar (owner: ECHL / AHL were missing on a day
    // without their games), in bar order; a quiet one says No games.
    final shown = _navigationLeagues;
    String gamesLabel(int n) =>
        n == 1 ? tr('1 game') : tr('{n} games', {'n': n});
    final picked = await showRollDownMenu<String>(
      context,
      anchor: anchor,
      centered: false,
      width: 340,
      title: tr('Your leagues'),
      items: [
        RollDownMenuItem(
          value: '',
          icon: Icons.apps,
          label: tr('All leagues'),
          subtitle: gamesLabel(games.length),
          selected: _leagueFilter == null,
        ),
        for (final l in shown)
          RollDownMenuItem(
            value: l.id,
            icon: SportsBackdrop.sportIcon(l),
            label: l.name,
            subtitle: switch (counts[l.id]) {
              null => tr('No games'),
              (final n, 0) => gamesLabel(n),
              (final n, final live) =>
                '${gamesLabel(n)} · ${tr('{live} live', {'live': live})}',
            },
            selected: _leagueFilter == l.id,
          ),
      ],
    );
    if (picked == null || !mounted) return;
    _setLeagueFilter(picked.isEmpty ? null : picked);
  }

  void _setLeagueFilter(String? id) {
    if (_leagueFilter == id) return;
    setState(() => _leagueFilter = id);
    unawaited(_load());
  }

  void _jumpToNextGame() {
    final next = _nextGame;
    if (next == null) return;
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final day = DateTime(next.year, next.month, next.day);
    // Calendar-day difference, safe across a DST change.
    final offset = (day.difference(today).inHours / 24).round();
    _setDay(offset);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _chipNode(_modeActive ? 'day:menu' : 'day:$offset').requestFocus();
      }
    });
  }

  void _setDay(int offset) {
    if (_dayOffset == offset) return;
    setState(() {
      _dayOffset = offset;
      _emptyLeagues = {};
      _heroGame = null;
    });
    unawaited(_load());
  }

  Future<void> _toggleScores() async {
    setState(() => _hideScores = !_hideScores);
    await context.read<AppPreferences>().setSportsHideScores(_hideScores);
  }

  /// Shown leagues from storage: base leagues plus bank leagues the user
  /// added (a bank id that was sent back is dropped).
  List<SportsLeague> _savedLeagues() => savedSportsLeagues(_storage);

  Future<void> _editLeagues() async {
    final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const SportsLeagueManagerScreen()));
    if (changed != true || !mounted) return;
    setState(() {
      _leagues = _savedLeagues();
      if (_leagueFilter != null &&
          !_leagues.any((l) => l.id == _leagueFilter)) {
        _leagueFilter = null;
      }
    });
    unawaited(_load());
  }

  // ------------------------------------------------------- league reorder

  /// League chip in "move" mode (hold OK on it), or null. Same model as the
  /// TV groups column's `_movingGroupKey`: focus stays on the chip,
  /// Left/Right move it, OK or Back is "done". Saved on every step.
  String? _movingLeague;

  void _tapLeague(String id) {
    if (_movingLeague != null) {
      _endLeagueMove();
    } else {
      _setLeagueFilter(id);
    }
  }

  void _startLeagueMove(String id) => setState(() {
        _movingVisibleLeagues =
            _navigationLeagues.map((league) => league.id).toSet();
        _movingLeague = id;
      });

  void _endLeagueMove() {
    if (_movingLeague == null) return;
    _updateLeagueNavigation(() {
      _movingLeague = null;
      _movingVisibleLeagues = null;
    });
  }

  void _moveLeague(int delta) {
    final id = _movingLeague;
    if (id == null) return;
    final visible = _navigationLeagues;
    final index = visible.indexWhere((l) => l.id == id);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= visible.length) return;
    final from = _leagues.indexWhere((l) => l.id == id);
    final to = _leagues.indexWhere((l) => l.id == visible[target].id);
    setState(() {
      final l = _leagues.removeAt(from);
      _leagues.insert(to, l);
    });
    unawaited(_storage.setSportsLeagues([for (final l in _leagues) l.id]));
    // The chip keeps its node (keyed by league id) and focus; just keep it on
    // screen. Zero duration = jump (CLAUDE.md §10).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final node = _chipNode('league:$id');
      if (_modeActive) node.requestFocus();
      final ctx = node.context;
      if (ctx != null && ctx.mounted) Scrollable.ensureVisible(ctx);
    });
  }

  Future<void> _openStandings() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (pageContext) => SportsStandingsScreen(
        leagues: _leagues,
        initialLeague: sportsLeagueById(_leagueFilter ?? '') ?? _leagues.first,
        follows: _follows,
        hideScores: _hideScores,
        matchGames: _matchGames,
        onActivate: (game, matches) =>
            _activateFromPage(pageContext, game, matches),
        onMenu: _openGame,
      ),
    ));
  }

  Future<void> _openMyTeams() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (pageContext) => SportsMyTeamsScreen(
        leagues: _leagues,
        follows: _follows,
        hideScores: _hideScores,
        matchGames: _matchGames,
        onActivate: (game, matches) =>
            _activateFromPage(pageContext, game, matches),
        onMenu: _openGame,
      ),
    ));
  }

  /// Channel matches for games outside the day being shown (My Teams).
  Future<Map<String, List<ChannelMatch>>> _matchGames(
      List<SportsGame> games) async {
    final playlist = context.read<PlaylistManager>();
    await playlist.ensureLiveChannelsLoaded();
    await _matcher.prepare(playlist.visibleChannels(category: 'tv'),
        hidden: playlist.hiddenLiveChannels());
    _picks = SportsChannelPicks.load(_storage);
    return _matcher.matchDay(games, _picks);
  }

  /// Focus shows the matchup; a first activation starts its matched stream in
  /// the hero and another opens that same session full screen. Hold stays menu.
  Future<void> _activateGame(SportsGame game,
      [List<ChannelMatch>? matches]) async {
    if (_previewRequested(game)) {
      return _play(_previewChannel!, game: game);
    }
    final best = (matches ?? _matches[_gameKey(game)])?.firstOrNull;
    if (best == null) return _openGame(game, matches);
    await _setPreview(game, best.channel);
  }

  // Schedule pages have no mini-player surface. Keep their watch action
  // visible by opening the player on that page, reusing an existing preview.
  Future<void> _activateFromPage(
      BuildContext page, SportsGame game, List<ChannelMatch>? matches) async {
    final best = matches?.firstOrNull;
    if (best == null) return _openGame(game, matches);
    await _play(best.channel, game: game, source: page);
  }

  bool _previewRequested(SportsGame game) =>
      _previewGame != null &&
      _previewChannel != null &&
      _gameKey(_previewGame!) == _gameKey(game) &&
      (_previewOpened?.isCompleted == false || _isPreviewing(game));

  void _focusGame(SportsGame game) {
    setState(() {
      _heroGame = game;
      // Looking at another card changes information, never the playing stream.
      _heroPick = _livePreview(context.read<PlaybackService>()) != null &&
              !_isPreviewing(game)
          ? game
          : null;
    });
  }

  /// A channel chosen from the game's menu plays in the hero (OK there =
  /// full screen).
  Future<void> _watch(Channel channel, SportsGame game) =>
      _setPreview(game, channel);

  /// What plays now: Windows' mini player (DesktopPlayerScreen hands a live
  /// channel to it on Back), else PlaybackService.
  static Channel? _playingNow(PlaybackService playback) => _desktopSports
      ? DesktopMiniPlayer.instance.channel.value
      : playback.currentChannel;

  // ------------------------------------------------------------- preview

  /// The game playing in the hero, refreshed from the latest scores, or null
  /// when nothing Sports started is still what [PlaybackService] plays.
  SportsGame? _livePreview(PlaybackService playback) {
    final game = _previewGame;
    final channel = _previewChannel;
    if (game == null || channel == null) return null;
    if (_playingNow(playback)?.id != channel.id) return null;
    final key = _gameKey(game);
    return _games.where((g) => _gameKey(g) == key).firstOrNull ?? game;
  }

  bool _isPreviewing(SportsGame game) =>
      _livePreview(context.read<PlaybackService>()) != null &&
      _gameKey(_previewGame!) == _gameKey(game);

  SportsGame? _focusedCardGame() {
    for (final g in _games) {
      if (_cardNodes[_gameKey(g)]?.hasFocus ?? false) return g;
    }
    return null;
  }

  /// Play/Pause on a game card: its channel plays in the hero; again on the
  /// same card stops it. No channel yet = the menu, to pick one.
  void _onPlayKey() {
    if (_movingLeague != null) return;
    final game = _focusedCardGame();
    if (game == null) return;
    if (_isPreviewing(game)) {
      unawaited(_setPreview(null, null));
      return;
    }
    final best = _matches[_gameKey(game)]?.firstOrNull;
    if (best == null) {
      unawaited(_openGame(game));
      return;
    }
    unawaited(_setPreview(game, best.channel));
  }

  /// Starts [channel] for [game] in the hero, or stops the hero's stream
  /// (null). [PlaybackService.play] closes whatever played before (a
  /// background channel too), so audio never overlaps — but only if two
  /// plays never run at once: overlapping calls can leave the first stream
  /// orphaned and still playing (same family as Multiview's audio-underneath
  /// bug). So presses run one at a time, and a press superseded while
  /// waiting is skipped. Each start also waits for the stream to open (max
  /// 10 s) before the next one: 1-connection accounts reject a new
  /// connection while the old one is still closing.
  /// [waitReady]: hold the chain until the stream is up, so a quick second
  /// Play/Pause can't start a stream over one still connecting. OK skips it:
  /// it goes full screen at once (waiting kept the Fire Stick showing the
  /// hero for seconds first, owner 2026-10-18).
  Future<void> _setPreview(SportsGame? game, Channel? channel,
      {bool waitReady = true}) {
    final seq = ++_previewSeq;
    final stopId = _previewChannel?.id;
    final playback = context.read<PlaybackService>();
    final storage = context.read<StorageService>();
    final feedHadFocus = _feedFocused;
    // Sports Mode: the first game opens the big player beside the feed;
    // once Down has moved to the cards (small player), a game picked there
    // keeps playing in the small player (owner, 2026-10-29).
    final stayOnCards = _modeActive && game != null && _modeBrowsing;
    _previewFeedFocusSeq =
        _modeActive && game != null && !stayOnCards ? seq : null;
    setState(() {
      _previewGame = game;
      _previewChannel = channel;
      _heroPick = null;
      _modeBrowsing = stayOnCards;
    });
    if (_modeActive && game == null && feedHadFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            seq != _previewSeq ||
            !(ModalRoute.of(context)?.isCurrent ?? false)) {
          return;
        }
        _feedFocused = false;
        _focusZone(_firstRowZone, _sections);
      });
    }
    final opened = Completer<void>();
    _previewOpened = opened;
    return _previewChain = _previewChain.then((_) async {
      try {
        if (seq != _previewSeq) return;
        if (_desktopSports) {
          final mini = DesktopMiniPlayer.instance;
          if (channel == null) {
            if (stopId != null && mini.channel.value?.id == stopId) {
              mini.clear();
            }
          } else {
            mini.play(channel);
            unawaited(storage.setLastChannelId(channel.id));
            unawaited(playback.recordWatched(channel));
          }
          return;
        }
        if (channel == null) {
          if (stopId != null && playback.currentChannel?.id == stopId) {
            await playback.stop();
          }
          return;
        }
        await playback.play(channel);
        // Full screen may reuse the opening session without waiting for the
        // separate ready/buffering reserve or issuing another play request.
        opened.complete();
        if (waitReady) {
          await playback.initFuture
              ?.timeout(const Duration(seconds: 10), onTimeout: () {});
        }
      } catch (_) {
        // The playback services report their own errors; keep the chain alive.
      } finally {
        if (!opened.isCompleted) opened.complete();
      }
    });
  }

  Future<bool> _ensurePreviewForFullScreen(
      Channel channel, SportsGame? game) async {
    final sameRequest = _previewChannel?.id == channel.id &&
        (game == null ||
            _previewGame != null &&
                _gameKey(_previewGame!) == _gameKey(game)) &&
        (_previewOpened?.isCompleted == false ||
            _playingNow(context.read<PlaybackService>())?.id == channel.id);
    if (!sameRequest) {
      final pending = _setPreview(game, channel, waitReady: false);
      final seq = _previewSeq;
      await pending;
      return mounted && seq == _previewSeq;
    }
    final seq = _previewSeq;
    // Full screen returns to the view it was opened from.
    setState(() => _heroPick = null);
    await _previewOpened?.future;
    return mounted && seq == _previewSeq;
  }

  /// [watch]: how a chosen channel plays — the hero by default; the live
  /// list passes its own (full screen, back to the list). It also turns
  /// "Play here" into "Play" full screen (no hero there).
  Future<void> _openGame(SportsGame game,
      [List<ChannelMatch>? gameMatches,
      Future<void> Function(Channel, SportsGame)? watch]) async {
    // The mixed My Teams schedule only scans a near-day window. An explicitly
    // opened future game gets its own bounded lookup (and shares the cache).
    if (game.start.isAfter(DateTime.now().add(const Duration(hours: 36)))) {
      final found = await _matchGames([game]);
      if (!mounted) return;
      gameMatches = found[_gameKey(game)];
    }
    final play = watch ?? _watch;
    final playlist = context.read<PlaylistManager>();
    final store = SportsChannelLists(context.read<StorageService>());
    final saved = store.sourcesFor(game, _gameKey(game));
    var matches = <ChannelMatch>[
      for (final c in playlist.visibleChannels(category: 'tv'))
        if (saved.contains(c.id))
          ChannelMatch(c, MatchReason.pick,
              _picks.channelIdFor(game) == c.id ? 1000 : 950,
              detail: tr('Your added source')),
      for (final m
          in gameMatches ?? _matches[_gameKey(game)] ?? const <ChannelMatch>[])
        if (!saved.contains(m.channel.id)) m,
    ];
    matches.sort((a, b) => b.score.compareTo(a.score));
    matches = _picks.orderMatches(matches);
    final result = await showDialog<_GameAction>(
      context: context,
      // Opened by a hold too: drop the held OK's repeats (see the widget).
      builder: (_) => SwallowHeldActivate(
          child: _GameDialog(
        game: game,
        matches: matches,
        matching: gameMatches == null && _matching,
        hideScores: _hideScores,
        hasPick: _picks.channelIdFor(game) != null,
        offerPlayHere: watch != null || !_isPreviewing(game),
        playFullScreen: watch != null,
        recording: RecordingService.supported
            ? RecordingService.instance.entryFor(game)
            : null,
        autoTeam: RecordingService.supported
            ? RecordingService.instance.autoTeam
            : null,
      )),
    );
    if (result == null || !mounted) return;
    switch (result) {
      case _WatchAction(:final channel):
        // Watching another of the listed channels makes it this game's
        // default (owner: the card kept showing the first match) — a game
        // pick only; team-wide picks stay a deliberate "Pick a channel".
        if (channel.id != matches.firstOrNull?.channel.id) {
          await _picks.pickForGame(game, channel.id);
          unawaited(_rematch());
        }
        await play(channel, game);
      case _PickAction():
        await _pickChannel(game, play);
      case _ReminderAction(:final edit):
        final reminders = context.read<GameReminders>();
        if (!reminders.isSet(game) && !reminders.canSet(game)) {
          _toast(tr('This game has already started.'));
          return;
        }
        try {
          final bool enabled;
          if (reminders.isSet(game) && !edit) {
            enabled = await reminders.toggle(game);
          } else {
            final lead =
                await showGameReminderTimingMenu(context, game, reminders);
            if (lead == null || !mounted) return;
            await reminders.setReminder(game, leadMinutes: lead);
            enabled = true;
          }
          if (mounted) {
            _toast(enabled ? tr('Reminder set') : tr('Reminder cancelled'));
          }
        } catch (_) {
          if (mounted) _toast(tr('Could not save reminder.'));
        }

      case _AddSourcesAction():
        await _addSources(game);
      case _MoreSourcesAction():
        final found = await _matcher.matchDay([game], _picks, limit: 100000);
        if (!mounted) return;
        final all = found[_gameKey(game)] ?? [];
        await showDialog<void>(
            context: context,
            builder: (dialog) =>
                SimpleDialog(title: Text(tr('More sources')), children: [
                  SizedBox(
                      width: 600,
                      height: MediaQuery.sizeOf(context).height * 0.65,
                      child: SportsChannelTiles(
                          channels: all.map((m) => m.channel).toList(),
                          onTap: (c) {
                            Navigator.pop(dialog);
                            play(c, game);
                          })),
                ]));
      case _ForgetPickAction():
        await _picks.clearFor(game);
        await _rematch();
      case _RecordAction(:final channel):
        await _record(game, channel);
      case _StopRecordAction(:final entry):
        await RecordingService.instance.stop(entry);
        _toast(tr('Recording cancelled'));
      case _AutoTeamAction(:final team):
        await _setAutoTeam(game, team);
    }
  }

  Future<void> _addSources(SportsGame game) async {
    final playlist = context.read<PlaylistManager>();
    final store = SportsChannelLists(context.read<StorageService>());
    final library = SportsChannelLibrary(
        playlist.visibleChannels(category: 'tv'),
        store: store);
    final listId = await showDialog<String>(
        context: context,
        builder: (dialog) =>
            SimpleDialog(title: Text(tr('Add sources')), children: [
              TvMenuTile(
                  icon: Icons.live_tv,
                  title: tr('Browse all channels'),
                  onTap: () => Navigator.pop(dialog, 'all')),
              for (final list in store.lists)
                TvMenuTile(
                    icon: Icons.list,
                    title: list.name,
                    onTap: () => Navigator.pop(dialog, list.id)),
            ]));
    if (listId == null || !mounted) return;
    final list = store.lists.where((l) => l.id == listId).firstOrNull;
    final chosen = await Navigator.push<Set<String>>(
        context,
        MaterialPageRoute(
            builder: (_) => SportsChannelPicker(
                channels:
                    list == null ? library.channels : library.members(list),
                selected: store.sourcesFor(game, _gameKey(game)))));
    if (chosen == null || !mounted) return;
    final scope = await showDialog<String>(
        context: context,
        builder: (dialog) =>
            SimpleDialog(title: Text(tr('Add sources')), children: [
              TvMenuTile(
                  icon: Icons.event,
                  title: tr('This game'),
                  onTap: () =>
                      Navigator.pop(dialog, 'event:${_gameKey(game)}')),
              for (final team in [game.home, game.away])
                TvMenuTile(
                    icon: Icons.groups,
                    title: team.name,
                    onTap: () => Navigator.pop(
                        dialog, 'team:${game.league.id}:${team.id}')),
              TvMenuTile(
                  icon: Icons.sports,
                  title: game.league.name,
                  onTap: () =>
                      Navigator.pop(dialog, 'league:${game.league.id}')),
            ]));
    if (scope == null) return;
    await store.setSources(scope, chosen, event: scope.startsWith('event:'));
    if (mounted) await _rematch();
  }

  Future<void> _record(SportsGame game, Channel channel) async {
    final service = RecordingService.instance;
    await service.askNotifications();
    if (!await service.hasRoom()) {
      _toast(tr('Not enough free space to record'));
      return;
    }
    if (!mounted) return;
    await service.handOver(channel, context.read<PlaybackService>(),
        () => service.recordGame(game, channel));
    if (!mounted) return;
    _toast(game.state == GameState.live
        ? tr('Recording {title}', {'title': game.title})
        : tr('{title} will be recorded', {'title': game.title}));
    setState(() {});
  }

  Future<void> _setAutoTeam(SportsGame game, SportsTeam? team) async {
    final service = RecordingService.instance;
    if (team == null) {
      final name = service.autoTeam?.teamName ?? '';
      await service.clearAutoTeam();
      _toast(tr('No longer recording every {team} game', {'team': name}));
      return;
    }
    await service.askNotifications();
    await service.setAutoTeam(game.league, team);
    _toast(tr('Every {team} game will be recorded', {'team': team.shortName}));
    if (!mounted) return;
    final playlist = context.read<PlaylistManager>();
    await playlist.ensureLiveChannelsLoaded();
    await service.refreshAutoTeam(
      viewerLeagues: _leagues,
      matcher: _matcher,
      picks: _picks,
      channels: playlist.visibleChannels(category: 'tv'),
      hiddenChannels: playlist.hiddenLiveChannels(),
    );
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickChannel(SportsGame game,
      [Future<void> Function(Channel, SportsGame)? watch]) async {
    final channel = await Navigator.of(context).push<Channel>(
      MaterialPageRoute(
        builder: (_) => _ChannelPickerScreen(game: game, matcher: _matcher),
      ),
    );
    if (channel == null || !mounted) return;
    final scope = await showDialog<_PickScope>(
      context: context,
      builder: (_) => _PickScopeDialog(game: game, channel: channel),
    );
    if (scope == null || !mounted) return;
    switch (scope) {
      case _PickScope.game:
        await _picks.pickForGame(game, channel.id);
      case _PickScope.first when game.league.kind != SportsKind.team:
        await _picks.pickForSeries(game, channel.id);
      case _PickScope.first:
        await _picks.pickForTeam(game, game.first, channel.id);
      case _PickScope.second:
        await _picks.pickForTeam(game, game.second, channel.id);
    }
    await _rematch();
    if (!mounted) return;
    await (watch ?? _watch)(channel, game);
  }

  /// Fullscreen [channel]. With [game] (Android), it goes through the hero
  /// preview, so Back from the player shows it there (one stream, no
  /// reconnect — the hero's VideoPlayerPane stays under the player the same
  /// way the TV guide's preview box does).
  Future<void> _play(Channel channel,
      {SportsGame? game,
      bool keepPreview = false,
      BuildContext? source}) async {
    if (_fullScreenPending) return;
    _fullScreenPending = true;
    final origin = source ?? context;
    try {
      // Same split as SearchScreen._openChannel: Windows has its own player.
      // A game takes the hero's session full screen (no reconnect); Back
      // there hands it back to DesktopMiniPlayer, i.e. the hero again.
      if (_desktopSports) {
        final mini = DesktopMiniPlayer.instance;
        (Player, VideoController)? session;
        if (game != null || keepPreview) {
          if (!await _ensurePreviewForFullScreen(channel, game)) return;
          if (!mounted ||
              _previewChannel?.id != channel.id ||
              !origin.mounted ||
              (source == null &&
                  !(ModalRoute.of(origin)?.isCurrent ?? false))) {
            return;
          }
          if (mini.channel.value?.id == channel.id) session = mini.take();
        } else {
          _previewSeq++;
          setState(() {
            _previewGame = null;
            _previewChannel = null;
          });
          mini.clear();
        }
        await Navigator.of(origin).push(MaterialPageRoute(
            builder: (_) => DesktopPlayerScreen(
                  channel: channel,
                  existingPlayer: session?.$1,
                  existingController: session?.$2,
                )));
        _refocusAfterFeed();
        return;
      }
      if (game != null || keepPreview) {
        if (!await _ensurePreviewForFullScreen(channel, game)) return;
      } else {
        // RedZone: not a game; the hero goes back to normal and a preview
        // still waiting in the chain is skipped.
        _previewSeq++;
        setState(() {
          _previewGame = null;
          _previewChannel = null;
        });
        await _previewChain;
        if (!mounted) return;
        await context.read<PlaybackService>().play(channel);
      }
      if (!mounted ||
          !origin.mounted ||
          (source == null && !(ModalRoute.of(origin)?.isCurrent ?? false))) {
        return;
      }
      if ((game != null || keepPreview) && _previewChannel?.id != channel.id) {
        return;
      }
      await Navigator.of(origin).push(
          MaterialPageRoute(builder: (_) => PlayerScreen(channel: channel)));
      _refocusAfterFeed();
    } finally {
      _fullScreenPending = false;
    }
  }

  /// Back from full screen returns focus to the mounted game feed, or to
  /// the cards when a channel change has ended that feed's preview.
  void _refocusAfterFeed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_modeActive ||
          !(ModalRoute.of(context)?.isCurrent ?? false)) {
        return;
      }
      // Full screen from the Live TV guide: back on the guide, not the
      // feed under it (user report, Shield 1.0.48: the selector sat under
      // the see-through guide and the arrows scrolled the page).
      if (_liveOpen) {
        _livePanel.currentState?.focusLast();
        return;
      }
      if (_feedVisible) {
        _focusFeed();
        return;
      }
      if (!_feedFocused) return;
      _feedFocused = false;
      _focusZone(_firstRowZone, _sections);
    });
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<AppPreferences>().sportsMode;
    final channelPage = SportsChannelsScreen(
      // What the Games hero plays carries into Networks' hero.
      initialPreview: _desktopSports
          ? DesktopMiniPlayer.instance.channel.value
          : (_livePreview(context.read<PlaybackService>()) != null
              ? _previewChannel
              : null),
      onGames: _closeNetworks,
      onPreview: (channel) => _setPreview(null, channel),
      onFullScreen: (channel) => _play(channel, keepPreview: true),
    );
    final sections = _sections;
    final playback = context.watch<PlaybackService>();
    final preview = _livePreview(playback);
    // Sports Mode: a Live TV guide channel plays in the same big player.
    final channelOnly = _modeActive && _panelPreview(playback) != null;
    // Focus can show another matchup beside the same video. Re-read its
    // information from the latest scoreboard without changing the stream.
    final pickKey = _heroPick == null ? null : _gameKey(_heroPick!);
    final pick = preview == null ||
            pickKey == null ||
            pickKey == _gameKey(preview)
        ? null
        : _games.where((g) => _gameKey(g) == pickKey).firstOrNull ?? _heroPick;
    final hero = pick ?? preview ?? _heroGame;
    Widget heroWidget({double? playingHeight, _HeroPart? part}) => _Hero(
          game: hero!,
          service: _service,
          matches: _matches[_gameKey(hero)],
          matching: _matching,
          hideScores: _hideScores,
          playing: preview != null || channelOnly,
          showingOther: pick != null,
          touch: _touch,
          narrow: _narrow,
          playingHeight: playingHeight,
          part: part,
          // Tap/click the playing video = full screen on the same stream
          // (owner, 2026-10-18); a remote keeps OK.
          onVideoTap: (_touch || _desktopSports) &&
                  _previewGame != null &&
                  _previewChannel != null
              ? () => _play(_previewChannel!, game: _previewGame)
              : null,
        );
    final header = [
      _buildLeagueBar(mode: mode),
      const SizedBox(height: 8),
      _buildDayBar(),
      const SizedBox(height: 6),
      _buildStandingsButton(),
      const SizedBox(height: 4),
      if (hero != null) heroWidget(),
    ];
    // Back while moving a league chip = "done", not leave Sports; Back while
    // the hero plays stops it first.
    final gamesPage = PopScope(
      // Networks handles Back itself (back to Games, never out of Sports
      // Trak: leaving from there moved its preview to the main player).
      canPop: !_channelsMode &&
          !_liveOpen &&
          _movingLeague == null &&
          preview == null &&
          !channelOnly &&
          (!mode || (!widget.home && _modeRailFocused)),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _channelsMode) return;
        if (_liveOpen) {
          _liveBack();
        } else if (_movingLeague != null) {
          _endLeagueMove();
        } else if (pick != null) {
          setState(() => _heroPick = null);
        } else if (!mode && preview != null) {
          unawaited(_setPreview(null, null));
        } else if (mode && !_modeRailFocused) {
          // Sports Mode (owner, 2026-10-29): Back opens the rail and the
          // player keeps playing; Back on the rail stops it; Back again
          // quits (Who's watching / exit prompt).
          _modeShell.currentState?.backToMenu();
        } else if (mode && (preview != null || channelOnly)) {
          unawaited(_setPreview(null, null));
        } else if (mode && widget.home) {
          unawaited(_confirmModeExit());
        }
      },
      child: SportsScreenFrame(
          child: withTvThemeIfNeeded(
        context,
        (context) => Stack(
          children: [
            const Positioned.fill(child: SettingsGradientBackground()),
            // The picked league's banner (none on "All").
            if (_leagueFilter != null)
              Positioned.fill(
                child: Builder(builder: (context) {
                  final league = sportsLeagueById(_leagueFilter!);
                  return SportsBackdrop(
                      logoUrl: league?.logoUrl, league: league);
                }),
              ),
            Positioned.fill(child: _TeamGlow(game: hero)),
            Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: CallbackShortcuts(
                  bindings: _movingLeague != null
                      ? {
                          const SingleActivator(LogicalKeyboardKey.arrowLeft):
                              () => _moveLeague(-1),
                          const SingleActivator(LogicalKeyboardKey.arrowRight):
                              () => _moveLeague(1),
                          // Stay on the chip until OK/Back says "done".
                          const SingleActivator(LogicalKeyboardKey.arrowUp):
                              () {},
                          const SingleActivator(LogicalKeyboardKey.arrowDown):
                              () {},
                        }
                      : {
                          const SingleActivator(LogicalKeyboardKey.arrowUp):
                              () => _moveZone(-1),
                          const SingleActivator(LogicalKeyboardKey.arrowDown):
                              () => _moveZone(1),
                          // Remotes send one combined key or separate ones.
                          const SingleActivator(
                              LogicalKeyboardKey.mediaPlayPause): _onPlayKey,
                          const SingleActivator(LogicalKeyboardKey.mediaPlay):
                              _onPlayKey,
                          const SingleActivator(LogicalKeyboardKey.mediaPause):
                              _onPlayKey,
                        },
                  child: mode
                      ? _buildSportsMode(header.first,
                          hero == null ? null : heroWidget, sections, preview,
                          channelOnly: channelOnly)
                      : _touch
                          // Phones: the bars and hero left the game rows a
                          // sliver of the screen, so nothing could be swiped
                          // (owner, 2026-10-18). The whole page scrolls instead.
                          ? SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(
                                  _narrow ? 12 : 24, 12, _narrow ? 12 : 24, 32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...header,
                                  _buildBody(sections, preview, inPage: true),
                                ],
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...header,
                                  Expanded(
                                      child: _buildBody(sections, preview)),
                                ],
                              ),
                            ),
                ),
              ),
            ),
          ],
        ),
      )),
    );
    // Channels is built only while shown: hidden in the stack it ran its
    // whole-catalogue grouping on every Games rebuild and took the focus
    // (Fire Stick froze on opening Sports Trak, owner 2026-10-22).
    return IndexedStack(index: _channelsMode ? 1 : 0, children: [
      ExcludeFocus(excluding: _channelsMode, child: gamesPage),
      if (_channelsMode) channelPage else const SizedBox.shrink(),
    ]);
  }

  void _openSportsModeSettings() {
    // A queued preview must not restart after the switch releases the player.
    _previewSeq++;
    showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
              title: Text(tr('Sports Mode')),
              content: const SizedBox(width: 520, child: SportsModeToggle()),
            ));
  }

  List<String> _modeControlIds(int zone) => switch (zone) {
        0 => [
            'league:all',
            for (final l in _navigationLeagues.skip(5)) 'league:${l.id}',
            'league:edit',
            'league:scores',
            'league:mode'
          ],
        // Sports Mode has no day strip (owner, 2026-10-28: room for a bigger
        // video): the day is one menu chip leading the tools row.
        1 => [],
        2 => [
            'day:menu',
            if (_showStandingsChip) 'standings',
            'myteams',
            'networks',
            if (_showRedZone) 'redzone'
          ],
        _ => [],
      };

  void _rememberModeControlFocus() {
    if (!mounted || !_modeActive) return;
    for (var zone = 0; zone < _firstRowZone; zone++) {
      for (final id in _modeControlIds(zone)) {
        if (_chipNodes[id]?.hasFocus ?? false) {
          _lastModeControls[zone] = id;
          _zone = zone;
          return;
        }
      }
    }
  }

  void _focusModeNode(String id) {
    final node = _chipNode(id);
    node.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = node.context;
      if (mounted && ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx);
      }
    });
  }

  KeyEventResult _onModeControlKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final delta = event.logicalKey == LogicalKeyboardKey.arrowLeft
        ? -1
        : event.logicalKey == LogicalKeyboardKey.arrowRight
            ? 1
            : 0;
    if (delta == 0 || _movingLeague != null) return KeyEventResult.ignored;
    final ids = _modeControlIds(_zone);
    final index = ids.indexWhere((id) => _chipNodes[id]?.hasFocus ?? false);
    if (index >= 0) {
      final target = index + delta;
      if (target < 0) {
        _leftFromContent();
      } else if (target < ids.length) {
        _focusModeNode(ids[target]);
      }
      return KeyEventResult.handled;
    }
    // Row headers and the empty-day action have no horizontal neighbours.
    if (_chipNodes.values.any((node) => node.hasFocus)) {
      if (delta < 0) {
        _leftFromContent();
      } else {
        _focusZone(_zone, _sections);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _openModePage(Widget page,
      {bool settings = false, bool stopPlayback = false}) async {
    if (settings) {
      final unlocked =
          await context.read<ViewerProfileService>().requireUnlock(context);
      if (!unlocked || !mounted) return;
    }
    // Share one stream owner with the destination, just as the normal sports
    // Back path does. Preserve rail focus when the destination is closed.
    await _setPreview(null, null);
    if (!mounted) return;
    // Multiview runs its own players: no other stream may keep playing
    // underneath (same as the Live TV column's Multiview row).
    if (stopPlayback) {
      if (_desktopSports) {
        DesktopMiniPlayer.instance.clear();
      } else {
        await context.read<PlaybackService>().stop();
      }
      if (!mounted) return;
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (!mounted) return;
    // A closed destination has no video surface on the sports home. Release
    // its player instead of leaving an unseen stream consuming a connection.
    if (_desktopSports) {
      DesktopMiniPlayer.instance.clear();
    } else {
      await context.read<PlaybackService>().stop();
    }
    if (mounted) _modeShell.currentState?.focusRail();
  }

  /// The remote's Guide button on the Sports Mode root ([GuideKey]): the
  /// rail's Live TV panel on the playing channel's group, the game in the
  /// small player keeps playing (owner, 2026-10-29: the TV home stopped
  /// it). Touch/narrow layouts have no panel: the TV home, as the rail does.
  void _openGuide() {
    if (!_livePanelLayout) {
      GuideKey.openGuideOnNextHome();
      unawaited(_openModePage(const TvHomeScreen()));
      return;
    }
    if (!_liveOpen) setState(() => _liveOpen = true);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _livePanel.currentState?.openGuide());
  }

  /// Left from the page's left edge: the Live TV panel when it's open (its
  /// guide, else its groups; owner 2026-10-29), else the rail.
  void _leftFromContent() {
    final panel = _liveOpen ? _livePanel.currentState : null;
    if (panel != null) {
      panel.focusLast();
    } else {
      _modeShell.currentState?.focusRail();
    }
  }

  void _openLive() {
    if (_liveOpen) {
      _livePanel.currentState?.focusLast();
      return;
    }
    setState(() => _liveOpen = true);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _livePanel.currentState?.focusGroups());
  }

  /// Back with the Live TV panel open: guide -> groups -> closed, then the
  /// page again (the rail stays hidden: all three collapsed). From the rail
  /// it closes the panel at once.
  void _liveBack() {
    final panel = _livePanel.currentState;
    if (!_modeRailFocused && panel != null && panel.back()) return;
    setState(() => _liveOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_modeRailFocused) {
        _modeShell.currentState?.focusRail();
      } else {
        _focusZone(_zone, _sections);
      }
    });
  }

  /// The channel previewing from the Live TV panel (no game, so the hero
  /// stays as it is), while it really plays.
  Channel? _panelPreview(PlaybackService playback) {
    final channel = _previewChannel;
    if (_previewGame != null || channel == null) return null;
    return _playingNow(playback)?.id == channel.id ? channel : null;
  }

  /// OK on a guide channel plays it in the Sports Mode player itself (the
  /// big video beside the feed, same spot as a game; owner, 2026-10-29),
  /// like the TV guide's preview; one stream, so a game's preview ends. OK
  /// again on it: full screen on the same session; Back returns with it
  /// still playing (the channel full screen ended on, after CH+/-). It
  /// stays when the guide/panel close; Back on the page stops it.
  Future<void> _playLive(Channel channel, List<Channel> list) async {
    if (!_desktopSports) {
      context.read<PlaybackService>().zapList = list;
    }
    if (_previewGame != null || _previewChannel?.id != channel.id) {
      await _setPreview(null, channel);
      return;
    }
    await _play(channel, keepPreview: true);
    if (!mounted) return;
    final now = _playingNow(context.read<PlaybackService>());
    if (_previewGame == null && now != null && now.id != _previewChannel?.id) {
      setState(() => _previewChannel = now);
    }
    if (mounted && _liveOpen) _livePanel.currentState?.focusLast();
  }

  Future<void> _confirmModeExit() async {
    if (_exitPromptOpen) return;
    if (ProfileGate.backToSelector()) return;
    _exitPromptOpen = true;
    final exit = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
              title: Text(
                  tr('Exit {appName}?', {'appName': AppConstants.appName})),
              content: Text(tr('Are you sure you want to exit {appName}?',
                  {'appName': AppConstants.appName})),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialog).pop(true),
                    child: Text(tr('Exit'))),
                TextButton(
                    autofocus: true,
                    onPressed: () => Navigator.of(dialog).pop(false),
                    child: Text(tr('Stay'))),
              ],
            ));
    _exitPromptOpen = false;
    if (exit == true && mounted) {
      if (_desktopSports) {
        await windowManager.close();
      } else {
        await SystemNavigator.pop();
      }
    }
  }

  bool get _previewOn => _livePreview(context.read<PlaybackService>()) != null;

  /// Up from the top card row while browsing: back to the feed + big video.
  bool _backToFeed(int delta, int zone) {
    if (!_modeActive ||
        !_modeBrowsing ||
        delta > 0 ||
        zone != _firstRowZone ||
        !_previewOn) {
      return false;
    }
    setState(() => _modeBrowsing = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusFeed(last: true);
    });
    return true;
  }

  List<SportsGame> get _feedGames => [for (final s in _sections) ...s.games];

  void _focusFeed({SportsGame? game, bool last = false}) {
    _zone = _firstRowZone;
    final games = _feedGames;
    if (game != null) {
      final i = games.indexWhere((g) => _gameKey(g) == _gameKey(game));
      if (i >= 0) _feedIndex = i;
    } else if (last) {
      _feedIndex = games.length - 1;
    }
    _selectFeed(_feedIndex.clamp(0, games.isEmpty ? 0 : games.length - 1));
    _feedNode.requestFocus();
  }

  /// Position of game [index] in the feed's list, section headers included.
  int _feedItemOf(int index) {
    var item = 0;
    var seen = 0;
    for (final s in _sections) {
      item++; // its header
      if (index < seen + s.games.length) return item + index - seen;
      item += s.games.length;
      seen += s.games.length;
    }
    return item;
  }

  void _selectFeed(int index) {
    setState(() => _feedIndex = index);
    // Keep the row on screen - jumpTo, never animateTo (CLAUDE.md 10).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_feedScroll.hasClients) return;
      final pos = _feedScroll.position;
      final item = _feedItemOf(index);
      // A section's header comes along with its first row.
      final top = (item - 1) * _feedRowHeight;
      final bottom = (item + 1) * _feedRowHeight;
      if (top < pos.pixels) {
        _feedScroll.jumpTo(top.clamp(0.0, pos.maxScrollExtent));
      } else if (bottom > pos.pixels + pos.viewportDimension) {
        _feedScroll.jumpTo(
            (bottom - pos.viewportDimension).clamp(0.0, pos.maxScrollExtent));
      }
    });
  }

  /// OK on a feed row: the game plays in the big video (OK on the playing
  /// one = full screen); no channel yet = its menu.
  Future<void> _watchFeedGame(SportsGame game) async {
    await _activateGame(game);
  }

  /// Hold OK on a feed row: its stats, as from the player's side panel.
  Future<void> _feedStats(SportsGame game) async {
    final channel = await showDialog<Channel>(
      context: context,
      builder: (_) => SwallowHeldActivate(
        child: SportsGameDetailsDialog(
          game: game,
          matches: _matches[_gameKey(game)] ?? const [],
          hideScores: _hideScores,
        ),
      ),
    );
    if (!mounted) return;
    if (channel != null) {
      await _setPreview(game, channel);
    } else {
      _feedNode.requestFocus();
    }
  }

  KeyEventResult _onFeedKey(FocusNode _, KeyEvent event) {
    final games = _feedGames;
    final key = event.logicalKey;
    final selected =
        games.isEmpty ? null : games[_feedIndex.clamp(0, games.length - 1)];
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.gameButtonA) {
      // Tap = watch (on key-up), hold = stats; a hold needs the remote's
      // own repeats, as in HoldToActivate / PlayerSidePanel.
      if (event is KeyDownEvent) {
        _feedSelectDown = true;
        _feedHoldFired = false;
        _feedHeld
          ..reset()
          ..start();
      } else if (event is KeyRepeatEvent) {
        if (_feedSelectDown &&
            !_feedHoldFired &&
            _feedHeld.elapsed >= const Duration(milliseconds: 550)) {
          _feedHoldFired = true;
          if (selected != null) unawaited(_feedStats(selected));
        }
      } else if (event is KeyUpEvent) {
        final tap = _feedSelectDown && !_feedHoldFired;
        _feedSelectDown = false;
        _feedHeld.stop();
        if (tap && selected != null) unawaited(_watchFeedGame(selected));
      }
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.mediaPlay ||
        key == LogicalKeyboardKey.mediaPause) {
      if (event is KeyDownEvent && selected != null) {
        if (_isPreviewing(selected)) {
          unawaited(_setPreview(null, null));
        } else {
          unawaited(_watchFeedGame(selected));
        }
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_feedIndex > 0) {
        _selectFeed(_feedIndex - 1);
      } else {
        _focusZone(2, _sections);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      if (_feedIndex < games.length - 1) {
        _selectFeed(_feedIndex + 1);
      } else if (games.isNotEmpty) {
        _browseCards();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _leftFromContent();
      return KeyEventResult.handled;
    }
    // Right no longer opens full screen (owner, 2026-10-31): OK plays in
    // the player, OK again goes full screen.
    if (key == LogicalKeyboardKey.arrowRight) return KeyEventResult.handled;
    return KeyEventResult.ignored;
  }

  /// Down past the feed: the card rows under a small hero.
  void _browseCards() {
    setState(() => _modeBrowsing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusZone(_firstRowZone, _sections);
    });
  }

  Widget _buildFeed(List<_Section> sections) {
    final scheme = Theme.of(context).colorScheme;
    final items = <Object>[
      for (final s in sections) ...[s, ...s.games]
    ];
    var gameIndex = -1;
    final indexOf = <int, int>{};
    for (final (i, item) in items.indexed) {
      if (item is SportsGame) indexOf[i] = ++gameIndex;
    }
    return Focus(
      focusNode: _feedNode,
      onKeyEvent: _onFeedKey,
      onFocusChange: (focused) {
        _feedFocused = focused;
        if (mounted) setState(() {});
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(tr('No games on this day for your leagues'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70)))
                : ListView.builder(
                    key: const ValueKey('sports-mode-feed'),
                    controller: _feedScroll,
                    itemCount: items.length,
                    itemExtent: _feedRowHeight,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      if (item is _Section) {
                        return Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                            child: Text('${item.label}  ${item.games.length}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ),
                        );
                      }
                      final game = item as SportsGame;
                      final index = indexOf[i]!;
                      return ListenableBuilder(
                          listenable: _feedNode,
                          builder: (context, _) => _FeedRow(
                                key: ValueKey('feed-${_gameKey(game)}'),
                                game: game,
                                channel: _isPreviewing(game)
                                    ? _previewChannel
                                    : _matches[_gameKey(game)]
                                        ?.firstOrNull
                                        ?.channel,
                                selected:
                                    index == _feedIndex && _feedNode.hasFocus,
                                watching: _isPreviewing(game),
                                starred: _follows.involves(game),
                                hideScores: _hideScores,
                                accent: scheme.primary,
                                onTap: () {
                                  _feedIndex = index;
                                  _feedNode.requestFocus();
                                  unawaited(_watchFeedGame(game));
                                },
                                onLongPress: () {
                                  _feedIndex = index;
                                  unawaited(_feedStats(game));
                                },
                              ));
                    },
                  ),
          ),
          GestureDetector(
            onTap: items.isEmpty ? null : _browseCards,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
              child: _KeyHintText(
                  tr('OK: watch  ·  OK again: full screen  ·  Hold OK: stats  ·  ▼ all games'),
                  style: const TextStyle(fontSize: 12, color: Colors.white54)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsMode(
      Widget leagueBar,
      Widget Function({double? playingHeight, _HeroPart? part})? hero,
      List<_Section> sections,
      SportsGame? preview,
      {bool channelOnly = false}) {
    final prefs = context.watch<AppPreferences>();
    final scrollPage =
        _touch || _narrow || MediaQuery.sizeOf(context).height < 500;
    if (scrollPage) _feedVisible = false;
    _livePanelLayout = !scrollPage;
    SportsModeRailEntry app(String id, String label, IconData icon, Widget page,
            {bool settings = false, bool stopPlayback = false}) =>
        SportsModeRailEntry(
          id: id,
          label: label,
          icon: icon,
          focusNode: _chipNode('mode:$id'),
          enabled: _movingLeague == null,
          onTap: () => _openModePage(page,
              settings: settings, stopPlayback: stopPlayback),
        );
    return SportsModeShell(
      key: _modeShell,
      // TV: the rail hides while the content has focus and Left brings it
      // back, like the Live TV columns (owner, 2026-10-28: bigger video).
      collapse: !scrollPage,
      moving: _movingLeague != null,
      onMove: _moveLeague,
      topCount: prefs.hideMultiview ? 2 : 3,
      leagueCount: _navigationLeagues.take(5).length,
      entries: [
        // The top of the Live TV tabs column, so Sports Mode keeps every
        // destination in its own rail (owner, 2026-10-28).
        app('home', tr('Home'), Icons.home_outlined, const HomeScreen()),
        app('search', tr('Search'), Icons.search,
            const SearchScreen(initialScope: 'TV')),
        if (!prefs.hideMultiview)
          app(
              'multiview',
              tr('Multiview'),
              Icons.grid_view,
              _desktopSports
                  ? const DesktopMultiviewScreen()
                  : const MultiviewScreen(),
              stopPlayback: true),
        for (final league in _navigationLeagues.take(5))
          SportsModeRailEntry(
            id: 'league:${league.id}',
            label: league.shortName,
            focusNode: _chipNode('league:${league.id}'),
            logoUrl: league.logoUrl,
            selected: _leagueFilter == league.id,
            enabled: _movingLeague == null || _movingLeague == league.id,
            moving: _movingLeague == league.id,
            onTap: () => _tapLeague(league.id),
            onHold: () => _startLeagueMove(league.id),
          ),
        // TV: the Live TV panel inside Sports Mode; touch/narrow layouts
        // keep the TV home (the panel needs the side-by-side room).
        scrollPage
            ? app('tv', tr('Live TV'), Icons.live_tv, const TvHomeScreen())
            : SportsModeRailEntry(
                id: 'tv',
                label: tr('Live TV'),
                icon: Icons.live_tv,
                focusNode: _chipNode('mode:tv'),
                enabled: _movingLeague == null,
                selected: _liveOpen,
                onTap: _openLive),
        if (!prefs.hideMovies)
          app('movies', tr('Movies'), Icons.movie_outlined,
              const TvHomeScreen(initialTab: 'Movies')),
        if (!prefs.hideShows)
          app('series', tr('TV Shows'), Icons.video_library_outlined,
              const TvHomeScreen(initialTab: 'TV Shows')),
        if (!prefs.hideArchive)
          app('hub', tr('Media Hub'), Icons.explore_outlined,
              const ArchiveScreen()),
        if (!_desktopSports && !prefs.hideRecordings)
          app('recordings', tr('Recordings'), Icons.fiber_manual_record,
              const RecordingsScreen()),
        if (!prefs.hideProfiles)
          app('profiles', tr('Profiles'), Icons.people_outline,
              const ProfilesScreen()),
        app('settings', tr('Settings'), Icons.settings_outlined,
            const SettingsMenuScreen(),
            settings: true),
        SportsModeRailEntry(
            id: 'mode',
            label: tr('Sports Mode'),
            icon: Icons.sports,
            focusNode: _chipNode('mode:toggle'),
            enabled: _movingLeague == null,
            selected: true,
            onTap: _openSportsModeSettings),
      ],
      onEnterContent: () => _liveOpen
          ? _livePanel.currentState?.focusLast()
          : _feedVisible
              ? _focusFeed()
              : _focusZone(_zone, sections),
      live: _liveOpen && !scrollPage
          ? SportsModeLivePanel(
              key: _livePanel,
              onPlay: _playLive,
              onLeft: () => _modeShell.currentState?.focusRail(),
              onRight: () =>
                  _feedVisible ? _focusFeed() : _focusZone(_zone, sections),
              onOpenFull: () => _openModePage(const TvHomeScreen()))
          : null,
      onRailFocusChanged: (value) {
        if (mounted && value != _modeRailFocused) {
          setState(() => _modeRailFocused = value);
        }
      },
      bar: Focus(
          canRequestFocus: false,
          onKeyEvent: _onModeControlKey,
          child: leagueBar),
      content: Focus(
        canRequestFocus: false,
        onKeyEvent: _onModeControlKey,
        child: scrollPage
            ? SingleChildScrollView(
                key: const ValueKey('sports-mode-content'),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      _buildModeTools(),
                      const SizedBox(height: 6),
                      if (hero != null) hero(),
                      _buildBody(sections, preview, inPage: true),
                    ]),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LayoutBuilder(builder: (context, constraints) {
                  const tools = 50.0;
                  _feedVisible = hero != null &&
                      (preview != null || channelOnly) &&
                      !_modeBrowsing;
                  if (_feedVisible && _previewFeedFocusSeq == _previewSeq) {
                    final seq = _previewSeq;
                    _previewFeedFocusSeq = null;
                    // Playback can open several frames after OK. Transfer
                    // focus only once the replacement feed is mounted.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted ||
                          seq != _previewSeq ||
                          !_feedVisible ||
                          !(ModalRoute.of(context)?.isCurrent ?? false)) {
                        return;
                      }
                      _focusFeed(game: preview);
                    });
                  }
                  // A guide channel on a day without games (no hero to
                  // lend its player): the same player at the same spot.
                  if (channelOnly && hero == null) {
                    final height = math
                        .min(
                            (constraints.maxWidth - _GameCard.width - 56) *
                                9 /
                                16,
                            constraints.maxHeight - tools - 32)
                        .clamp(_Hero.height - 8, 600.0);
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          _buildModeTools(),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildBody(sections, preview)),
                                const SizedBox(width: 16),
                                _HeroVideo(
                                    key: const ValueKey('sports-mode-player'),
                                    width: height * 16 / 9,
                                    height: height),
                              ],
                            ),
                          ),
                        ]);
                  }
                  if (!_feedVisible) {
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          _buildModeTools(),
                          const SizedBox(height: 6),
                          if (hero != null) hero(),
                          Expanded(child: _buildBody(sections, preview)),
                        ]);
                  }
                  // Playing: a big video on the right, the game and its rows
                  // in a column on its left (owner, 2026-10-28: the cards
                  // were cut off under a wider hero). The left column keeps
                  // room for one card; the video takes the rest, below its
                  // frame (8) and hint line (24).
                  final videoHeight = math
                      .min(
                          (constraints.maxWidth - _GameCard.width - 56) *
                              9 /
                              16,
                          constraints.maxHeight - tools - 32)
                      .clamp(_Hero.height - 8, 600.0);
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        _buildModeTools(),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildFeed(sections)),
                              const SizedBox(width: 16),
                              hero!(
                                  part: _HeroPart.video,
                                  playingHeight: videoHeight + 8),
                            ],
                          ),
                        ),
                      ]);
                }),
              ),
      ),
    );
  }

  List<Widget> _leagueControls({bool mode = false}) => [
        // Sports Mode makes the existing menu visible and one press away.
        // Regular Sports Trak retains short OK = All, hold OK = league menu.
        HoldToActivate(
          key: const ValueKey('league:all'),
          onTap: mode ? _openLeagueMenu : () => _setLeagueFilter(null),
          onHold: _movingLeague == null ? _openLeagueMenu : null,
          child: SportsChip(
            focusNode: _chipNode('league:all'),
            enabled: _movingLeague == null,
            label: tr('All'),
            dropdown: mode,
            selected: _leagueFilter == null,
            onFocus: () => _zone = 0,
            onTap: mode ? _openLeagueMenu : () => _setLeagueFilter(null),
          ),
        ),
        for (final l in _navigationLeagues.skip(mode ? 5 : 0))
          HoldToActivate(
            // Keyed: the list reorders in move mode, and unkeyed chips
            // swapped focus nodes — focus dropped and stale "focused"
            // outlines stuck on other chips (owner: three focuses).
            key: ValueKey('league:${l.id}'),
            onTap: () => _tapLeague(l.id),
            onHold: () => _startLeagueMove(l.id),
            child: SportsChip(
              focusNode: _chipNode('league:${l.id}'),
              enabled: _movingLeague == null || _movingLeague == l.id,
              label: l.shortName,
              logoUrl: l.logoUrl,
              selected: _leagueFilter == l.id,
              moving: _movingLeague == l.id,
              onFocus: () => _zone = 0,
              onTap: () => _tapLeague(l.id),
            ),
          ),
        SportsChip(
          key: const ValueKey('league:edit'),
          focusNode: _chipNode('league:edit'),
          enabled: _movingLeague == null,
          label: tr('Edit leagues'),
          icon: Icons.tune,
          selected: false,
          onFocus: () => _zone = 0,
          onTap: _editLeagues,
        ),
        SportsChip(
          key: const ValueKey('league:scores'),
          focusNode: _chipNode('league:scores'),
          enabled: _movingLeague == null,
          label: _hideScores ? tr('Scores hidden') : tr('Scores shown'),
          icon: _hideScores ? Icons.visibility_off : Icons.visibility,
          selected: false,
          onFocus: () => _zone = 0,
          onTap: _toggleScores,
        ),
        SportsChip(
          key: const ValueKey('league:mode'),
          focusNode: _chipNode('league:mode'),
          enabled: _movingLeague == null,
          label: tr('Sports Mode'),
          icon: Icons.sports,
          selected: _modeActive,
          onFocus: () => _zone = 0,
          onTap: _openSportsModeSettings,
        ),
      ];

  Widget _buildLeagueBar({bool mode = false}) {
    if (mode) {
      return SizedBox(
          height: 40,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _leagueControls(mode: true)),
          ));
    }
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const SportsBackButton(),
          Text(AppConstants.sportsTabName,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(width: 16),
          Expanded(
            // Not a lazy ListView: Up from the day row focuses the selected
            // league's chip, and once enough leagues are added it sat off
            // screen, unbuilt — Up did nothing. ~20 chips, all built is fine.
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._leagueControls(mode: mode),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(int offset) {
    if (offset == -1) return tr('Yesterday');
    if (offset == 0) return tr('Today');
    if (offset == 1) return tr('Tomorrow');
    final n = DateTime.now();
    return DateFormat(offset < -1 || offset > 6 ? 'EEE d MMM' : 'EEE d')
        .format(DateTime(n.year, n.month, n.day + offset));
  }

  /// Sports Mode's day chip: the day strip's days in a roll-down menu.
  Future<void> _openDayMenu() async {
    final node = _chipNode('day:menu');
    final picked = await showRollDownMenu<int>(
      context,
      anchor: rollDownAnchorOf(node.context),
      centered: false,
      width: 260,
      title: tr('Day'),
      items: [
        for (final o in [
          for (var o = -1; o <= 6; o++) o,
          if (_dayOffset < -1 || _dayOffset > 6) _dayOffset,
        ])
          RollDownMenuItem(
            value: o,
            icon: o == 0 ? Icons.today : Icons.event,
            label: _dayLabel(o),
            selected: o == _dayOffset,
          ),
      ],
    );
    if (!mounted) return;
    if (picked != null) _setDay(picked);
    node.requestFocus();
  }

  /// Sports Mode's one tools row: live count, day menu, Standings / My
  /// Teams / Networks / RedZone (zone 2).
  Widget _buildModeTools() {
    final live = _games.where((g) => g.state == GameState.live).length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_dayOffset == 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _LiveCount(count: live),
            ),
          SportsChip(
            focusNode: _chipNode('day:menu'),
            label: _dayLabel(_dayOffset),
            icon: Icons.calendar_month,
            selected: false,
            compact: true,
            onFocus: () => _zone = 2,
            onTap: _openDayMenu,
          ),
          ..._toolChips(),
        ],
      ),
    );
  }

  Widget _buildDayBar() {
    String label(int offset) => _dayLabel(offset);

    final live = _games.where((g) => g.state == GameState.live).length;
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          if (_dayOffset == 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _LiveCount(count: live),
            ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (var o = -1; o <= 6; o++)
                  SportsChip(
                    focusNode: _chipNode('day:$o'),
                    label: label(o),
                    selected: _dayOffset == o,
                    compact: true,
                    onFocus: () => _zone = 1,
                    onTap: () => _setDay(o),
                  ),
                // A day reached through "Next game" beyond the strip.
                if (_dayOffset < -1 || _dayOffset > 6)
                  SportsChip(
                    focusNode: _chipNode('day:$_dayOffset'),
                    label: DateFormat('EEE d MMM').format(_day),
                    selected: true,
                    compact: true,
                    onFocus: () => _zone = 1,
                    onTap: () {},
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Its own centered spot under the day row (was the last chip of the
  /// league bar — owner: hard to find there). Names the filtered league so
  /// it's clear which table opens.
  /// Golf, fighting, racing and cups have no table.
  bool get _showStandingsChip =>
      sportsLeagueById(_leagueFilter ?? '')?.hasStandings ?? true;

  Widget _buildStandingsButton() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(mainAxisSize: MainAxisSize.min, children: _toolChips()),
    );
  }

  List<Widget> _toolChips() {
    final league = sportsLeagueById(_leagueFilter ?? '');
    return [
      if (_showStandingsChip)
        SportsChip(
          focusNode: _chipNode('standings'),
          label: league == null
              ? tr('Standings')
              : league.kind == SportsKind.racing
                  ? tr('{name} championship', {'name': league.name})
                  : tr('{name} standings', {'name': league.name}),
          icon: Icons.leaderboard,
          selected: false,
          compact: true,
          onFocus: () => _zone = 2,
          onTap: _openStandings,
        ),
      SportsChip(
        focusNode: _chipNode('myteams'),
        label: tr('My Teams'),
        icon: Icons.star,
        selected: false,
        compact: true,
        onFocus: () => _zone = 2,
        onTap: _openMyTeams,
      ),
      // Sports networks (TSN, ESPN…) as cards (SportsChannelsScreen).
      SportsChip(
        focusNode: _chipNode('networks'),
        label: tr('Networks'),
        icon: Icons.live_tv,
        selected: false,
        compact: true,
        onFocus: () => _zone = 2,
        onTap: _openNetworks,
      ),
      if (_showRedZone)
        RedZonePill(
          focusNode: _chipNode('redzone'),
          onFocus: () => _zone = 2,
          onTap: () => _play(_redZone!),
          onHold: _chooseRedZone,
        ),
    ];
  }

  /// [inPage]: inside the phone's page scroll — a plain column (an Expanded
  /// or a nested vertical ListView has no height to fill there).
  Widget _buildBody(List<_Section> sections, SportsGame? preview,
      {bool inPage = false}) {
    if (inPage && (sections.isEmpty || (_loading && _games.isEmpty))) {
      return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 280),
          child: _buildBody(sections, preview, inPage: false));
    }
    if (inPage) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final s in sections) _buildSection(s, preview)],
        ),
      );
    }
    if (_loading && _games.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_error != null ? Icons.cloud_off : Icons.event_busy,
                size: 44, color: Colors.white38),
            const SizedBox(height: 10),
            Text(_error ?? tr('No games on this day for your leagues'),
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
            if (_error == null && _nextGame != null) ...[
              const SizedBox(height: 14),
              SportsChip(
                focusNode: _chipNode('nextgame'),
                label: tr('Next game: {date}', {
                  'date': DateFormat('EEE d MMM').format(_nextGame!),
                }),
                icon: Icons.event,
                selected: false,
                onFocus: () => _zone = _firstRowZone,
                onTap: _jumpToNextGame,
              ),
            ] else if (_error == null && _nextGameLooked) ...[
              const SizedBox(height: 4),
              Text(tr('No upcoming games listed yet for this league.'),
                  style: const TextStyle(color: Colors.white38, fontSize: 13)),
            ] else if (_error == null) ...[
              const SizedBox(height: 4),
              Text(tr('Try another day, or add leagues with Edit leagues.'),
                  style: const TextStyle(color: Colors.white38, fontSize: 13)),
            ],
          ],
        ),
      );
    }
    if (_modeActive) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: _buildBody(sections, preview, inPage: true),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      children: [
        for (final s in sections) _buildSection(s, preview),
      ],
    );
  }

  void _focusModeCard(_Section section, String key, {int delta = 0}) {
    final index = section.games.indexWhere((game) => _gameKey(game) == key);
    if (index < 0) return;
    final node = _cardNode(key);
    if (node.context == null) {
      final scroll = _rowScrolls[section.id];
      if (scroll != null && scroll.hasClients) {
        final mixed = _leagueFilter == null &&
            section.games
                .any((game) => game.league.id != section.games.first.league.id);
        var offset = index * (_GameCard.width + 12);
        if (mixed) {
          for (var i = 0; i <= index; i++) {
            if (i == 0 ||
                section.games[i - 1].league.id != section.games[i].league.id) {
              offset += 64;
            }
          }
        }
        scroll.jumpTo(offset.clamp(
            scroll.position.minScrollExtent, scroll.position.maxScrollExtent));
      }
    }
    void focus() {
      final ctx = node.context;
      if (!mounted || ctx == null || !ctx.mounted) return;
      node.requestFocus();
      // Left/Right: scroll only as far as needed (a plain ensureVisible put
      // every card at the row's left edge: jumpy, and under the Live TV
      // groups, owner photos 1.0.51). After the frame, on the whole card:
      // its hold hint appears on focus and widens it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !ctx.mounted) return;
        var target = ctx;
        ctx.visitAncestorElements((e) {
          if (e.widget.key == ValueKey('card-$key')) {
            target = e;
            return false;
          }
          return true;
        });
        _revealInRow(target);
      });
    }

    if (node.context != null) {
      focus();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => focus());
    }
  }

  /// Scrolls the card's row sideways just enough to show [card] with a
  /// 20 px margin (its focus zoom, frame and shadow), and nothing else: an
  /// ensureVisible re-aligned cards already in view (jumpy), and walking up
  /// to the page scrolled it too; the first card then lost its left edge
  /// behind the collapsed Sports Mode rail (owner photos, 1.0.51). The page
  /// itself follows through [_ensureRowVisible].
  static void _revealInRow(BuildContext card) {
    final scrollable = Scrollable.maybeOf(card);
    final box = card.findRenderObject();
    final view = scrollable?.context.findRenderObject();
    if (scrollable == null ||
        box is! RenderBox ||
        view is! RenderBox ||
        !box.attached ||
        !view.attached) {
      return;
    }
    const margin = 20.0;
    final left = box.localToGlobal(Offset.zero, ancestor: view).dx;
    final right = left + box.size.width;
    final position = scrollable.position;
    final double to;
    if (left < margin) {
      to = position.pixels + left - margin;
    } else if (right > view.size.width - margin) {
      to = position.pixels + right - (view.size.width - margin);
    } else {
      return;
    }
    position
        .jumpTo(to.clamp(position.minScrollExtent, position.maxScrollExtent));
  }

  /// Left/Right along a game row, explicitly (CLAUDE.md §10): the row is a
  /// lazy list, and holding Right on a long row (a full NHL night) reached
  /// a card not built yet — default traversal then jumped to the nearest
  /// card it could find, in the row below (owner, 2026-10-17). An unbuilt
  /// neighbour is scrolled into existence first, then focused.
  KeyEventResult _onRowKey(_Section s, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final delta = event.logicalKey == LogicalKeyboardKey.arrowRight
        ? 1
        : event.logicalKey == LogicalKeyboardKey.arrowLeft
            ? -1
            : 0;
    if (delta == 0 || _movingLeague != null) return KeyEventResult.ignored;
    final i =
        s.games.indexWhere((g) => _cardNodes[_gameKey(g)]?.hasFocus ?? false);
    if (i < 0) return KeyEventResult.ignored;
    final target = i + delta;
    // Row ends: stay put rather than leave the row.
    if (target < 0 || target >= s.games.length) {
      if (target < 0 && _modeActive) _leftFromContent();
      return KeyEventResult.handled;
    }
    if (_modeActive) {
      _focusModeCard(s, _gameKey(s.games[target]), delta: delta);
      return KeyEventResult.handled;
    }
    final node = _cardNode(_gameKey(s.games[target]));
    void focus() {
      final ctx = node.context;
      if (ctx == null) return;
      node.requestFocus();
      // No duration = a jump (CLAUDE.md §10).
      Scrollable.ensureVisible(ctx,
          alignmentPolicy: delta > 0
              ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
              : ScrollPositionAlignmentPolicy.keepVisibleAtStart);
    }

    if (node.context != null) {
      focus();
    } else {
      final c = _rowScrolls[s.id];
      if (c != null && c.hasClients) {
        final p = c.position;
        c.jumpTo((p.pixels + delta * (_GameCard.width + 12))
            .clamp(p.minScrollExtent, p.maxScrollExtent));
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) focus();
      });
    }
    return KeyEventResult.handled;
  }

  Widget _buildSection(_Section s, SportsGame? preview) {
    final cardHeight = _GameCard.height *
        (MediaQuery.textScalerOf(context).scale(14) / 14)
            .clamp(1.0, double.infinity);
    final rowKey = _rowKeys[s.id] ??= GlobalKey();
    final zoneIndex = _firstRowZone + _sections.indexWhere((x) => x.id == s.id);
    return Padding(
      key: rowKey,
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                  child: Text(s.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white))),
              const SizedBox(width: 8),
              Text('${s.games.length}',
                  style: const TextStyle(fontSize: 15, color: Colors.white54)),
              if (s.id == 'live' && _showLiveAll) ...[
                const SizedBox(width: 14),
                SportsChip(
                  focusNode: _chipNode(_liveAllId),
                  label: tr('See all'),
                  icon: Icons.grid_view,
                  compact: true,
                  selected: false,
                  onFocus: () {
                    _zone = zoneIndex;
                  },
                  onTap: _openLiveList,
                ),
              ] else if (_headerChipId(s) case final id?) ...[
                const SizedBox(width: 14),
                SportsChip(
                  focusNode: _chipNode(id),
                  label: tr('See all'),
                  icon: Icons.grid_view,
                  compact: true,
                  selected: false,
                  onFocus: () => _zone = zoneIndex,
                  onTap: () => _openSectionGrid(s),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: cardHeight + 18 + _HoldHint.height,
            child: SportsRowArrows(
              controller: _rowScrolls[s.id] ??= ScrollController(),
              arrowAreaHeight: cardHeight,
              child: Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onKeyEvent: (_, event) => _onRowKey(s, event),
                // Clip.none below lets the focused card zoom past the row,
                // but scrolled-away cards also drew to the left of it, under
                // the Sports Mode Live TV groups (owner photo, 1.0.51): clip
                // the sides just past the zoom room, never top/bottom.
                child: ClipRect(
                  clipper: const _RowSideClipper(),
                  child: ListView(
                    controller: _rowScrolls[s.id],
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    // Room for the focused card's 1.05 zoom: the page's scroll
                    // view clipped its left edge in Sports Mode (owner photo).
                    padding: _modeActive
                        ? const EdgeInsets.symmetric(horizontal: 8)
                        : null,
                    children: [
                      for (final (k, g) in s.games.indexed) ...[
                        // A league divider where the league changes (and
                        // before the first card) when the row mixes leagues.
                        if (_leagueFilter == null &&
                            s.games.any((x) => x.league.id != g.league.id) &&
                            (k == 0 || s.games[k - 1].league.id != g.league.id))
                          _LeagueDivider(league: g.league),
                        _GameCard(
                          key: ValueKey('card-${_gameKey(g)}'),
                          cardHeight: cardHeight,
                          focusNode: _cardNode(_gameKey(g)),
                          game: g,
                          match: _matches[_gameKey(g)]?.firstOrNull,
                          matching: _matching,
                          hideScores: _hideScores,
                          starred: _follows.involves(g),
                          previewing: preview != null &&
                              _gameKey(preview) == _gameKey(g),
                          onFocus: () {
                            _zone = zoneIndex;
                            _lastCardInRow[s.id] = _gameKey(g);
                            _ensureRowVisible(s.id);
                            if (_heroGame != g || _heroPick != null) {
                              _focusGame(g);
                            }
                          },
                          onTap: () => _activateGame(g),
                          onHold: () => _openGame(g),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================== widgets

/// A game row's clip: 10 px past each side (the focused card's 1.05 zoom),
/// unbounded above and below (the zoom and the hold hint).
class _RowSideClipper extends CustomClipper<Rect> {
  const _RowSideClipper();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-10, -1000, size.width + 10, size.height + 1000);

  @override
  bool shouldReclip(_RowSideClipper oldClipper) => false;
}

/// Between two leagues' blocks in a game row: the league's logo and short
/// name over a thin line. Not focusable (row navigation is by game).
class _LeagueDivider extends StatelessWidget {
  const _LeagueDivider({required this.league});
  final SportsLeague league;

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      child: SizedBox(
        width: 64,
        height: _GameCard.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SportsLogo(
                url: league.logoUrl, size: 34, fallback: league.shortName),
            const SizedBox(height: 6),
            Text(league.shortName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.white60)),
            const SizedBox(height: 6),
            Container(width: 2, height: 28, color: Colors.white12),
          ],
        ),
      ),
    );
  }
}

/// "See all": one row's games as a grid (user request: "multiple rows
/// instead of one row scrolling right"). Not lazy, so D-pad traversal
/// always has its neighbour built; OK returns the game to the row.
class _SectionGridScreen extends StatefulWidget {
  const _SectionGridScreen(
      {required this.title, required this.games, required this.cardFor});
  final String title;
  final List<SportsGame> games;
  final Widget Function(SportsGame, FocusNode, VoidCallback) cardFor;

  @override
  State<_SectionGridScreen> createState() => _SectionGridScreenState();
}

class _SectionGridScreenState extends State<_SectionGridScreen> {
  late final List<FocusNode> _nodes = [
    for (final _ in widget.games) FocusNode()
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _nodes.isNotEmpty) _nodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SportsScreenFrame(
      child: withTvThemeIfNeeded(
        context,
        (context) => Stack(
          children: [
            const Positioned.fill(child: SettingsGradientBackground()),
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                title: Text('${widget.title} · ${widget.games.length}'),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final (i, g) in widget.games.indexed)
                      SizedBox(
                        width: _GameCard.width,
                        child: widget.cardFor(
                            g, _nodes[i], () => Navigator.of(context).pop(g)),
                      ),
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

String _timeLabel(DateTime utc) => TimeFormat.hm.format(utc.toLocal());

/// What a not-yet-started card shows: the start time — except golf, which
/// ESPN dates at midnight with no tee time; it reads "Oct 15 – 18" (US
/// Eastern dates, see SportsService._tournamentDay).
String _preLabel(SportsGame g) {
  final end = g.end;
  if (end == null) return _timeLabel(g.start);
  DateTime eastern(DateTime utc) => utc.subtract(const Duration(hours: 4));
  final a = eastern(g.start);
  final b = eastern(end);
  final first = DateFormat.MMMd().format(a);
  if (a.year == b.year && a.month == b.month && a.day == b.day) return first;
  return '$first – ${a.month == b.month ? DateFormat.d().format(b) : DateFormat.MMMd().format(b)}';
}

/// Golf / racing card body: the event's name, then the top three — or,
/// before it starts (or with scores hidden), the session and venue.
class _EventCardBody extends StatelessWidget {
  const _EventCardBody({required this.game, required this.hideScores});
  final SportsGame game;
  final bool hideScores;

  @override
  Widget build(BuildContext context) {
    final ev = game.event;
    final leaders =
        hideScores ? const <SportsEventEntry>[] : (ev?.leaders ?? const []);
    var details = [
      if (ev?.session != null) trSports(ev!.session!),
      if (ev?.venue != null) ev!.venue!,
    ].join(' · ');
    // Golf lists no course; the network is the next useful thing.
    if (details.isEmpty) details = game.broadcasts.take(2).join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(game.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        const SizedBox(height: 3),
        if (leaders.isEmpty)
          Text(details,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.white60))
        else
          for (final e in leaders.take(3))
            _EventLeaderLine(entry: e, fontSize: 12.5, flagSize: 13),
      ],
    );
  }
}

class _EventLeaderLine extends StatelessWidget {
  const _EventLeaderLine(
      {required this.entry, required this.fontSize, required this.flagSize});
  final SportsEventEntry entry;
  final double fontSize;
  final double flagSize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: fontSize, color: Colors.white);
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        children: [
          SizedBox(
            width: fontSize * 2.2,
            child: Text(entry.position,
                style: style.copyWith(color: Colors.white54)),
          ),
          if (entry.flagUrl != null) ...[
            CachedNetworkImage(
              imageUrl: sportsLogoUrl(entry.flagUrl, size: 64) ?? '',
              width: flagSize * 1.4,
              height: flagSize,
              fit: BoxFit.cover,
              memCacheWidth: 64,
              errorWidget: (_, __, ___) => SizedBox(width: flagSize * 1.4),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.copyWith(fontWeight: FontWeight.w600)),
          ),
          if (entry.value != null)
            Text(entry.value!,
                style: style.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// The hero for golf / racing: league logo and the event on the left, the
/// status and channel in the middle (same as a game), the top five right.
class _EventHero extends StatelessWidget {
  const _EventHero(
      {required this.game, required this.center, required this.hideScores});
  final SportsGame game;
  final Widget center;
  final bool hideScores;

  @override
  Widget build(BuildContext context) {
    final ev = game.event;
    final leaders =
        hideScores ? const <SportsEventEntry>[] : (ev?.leaders ?? const []);
    return LayoutBuilder(builder: (context, constraints) {
      if (game.league.kind == SportsKind.fight && constraints.maxWidth < 650) {
        return SizedBox(
            height: 168,
            child: Row(children: [
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  if (ev?.venue case final venue?)
                    Text(venue,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12)),
                ],
              )),
              SizedBox(width: constraints.maxWidth * 0.45, child: center),
            ]));
      }
      return SizedBox(
        height: 168,
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  SportsLogo(
                      url: game.league.logoUrl,
                      size: 92,
                      fallback: game.league.shortName),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(game.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        if (ev?.session != null)
                          Text(trSports(ev!.session!),
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.white70)),
                        if (ev?.venue != null)
                          Text(ev!.venue!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.white54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 230, child: center),
            Expanded(
              child: leaders.isEmpty
                  ? const SizedBox()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final e in leaders.take(5))
                          _EventLeaderLine(
                              entry: e, fontSize: 15, flagSize: 15),
                      ],
                    ),
            ),
          ],
        ),
      );
    });
  }
}

/// Soft glow of the focused game's two team colours behind everything —
/// the screen takes on the matchup's identity instead of a flat panel.
class _TeamGlow extends StatelessWidget {
  const _TeamGlow({required this.game});
  final SportsGame? game;

  @override
  Widget build(BuildContext context) {
    final a = sportsTeamColor(game?.first.color) ?? Colors.transparent;
    final b = sportsTeamColor(game?.second.color) ?? Colors.transparent;
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        // SizedBox.expand: AnimatedSwitcher lays children out loosely, so
        // a bare DecoratedBox would collapse to zero size.
        child: SizedBox.expand(
          key: ValueKey('${game?.id}'),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.topRight,
                colors: [
                  a.withValues(alpha: 0.32),
                  Colors.transparent,
                  b.withValues(alpha: 0.32),
                ],
                stops: const [0, 0.5, 1],
              ),
            ),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                  stops: [0.3, 0.85],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveCount extends StatelessWidget {
  const _LiveCount({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final on = count > 0;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? Colors.redAccent : Colors.white24,
          ),
        ),
        const SizedBox(width: 6),
        Text(tr('Live now  {count}', {'count': count}),
            style: TextStyle(
                color: on ? Colors.white : Colors.white54,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Big summary of the focused game above the rows.
/// One game in Sports Mode's feed beside the big video: the fullscreen
/// player's side-panel row (logos, scores, league / status / channel).
class _FeedRow extends StatelessWidget {
  const _FeedRow({
    super.key,
    required this.game,
    required this.channel,
    required this.selected,
    required this.watching,
    required this.starred,
    required this.hideScores,
    required this.accent,
    required this.onTap,
    required this.onLongPress,
  });

  final SportsGame game;
  final Channel? channel;
  final bool selected;
  final bool watching;
  final bool starred;
  final bool hideScores;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final g = game;
    final status = switch (g.state) {
      GameState.pre => TimeFormat.hm.format(g.start.toLocal()),
      _ => trSports(g.statusText),
    };
    final showScore = !hideScores && g.state != GameState.pre && !g.isEventOnly;
    final scoreStyle = TextStyle(color: accent, fontWeight: FontWeight.w800);
    final sub = [
      g.league.shortName,
      status,
      if (channel != null) channel!.name,
    ].join('  ·  ');
    Widget team(SportsTeam t) => SizedBox(
          width: 32,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SportsLogo(
                  url: t.logoUrl,
                  size: 26,
                  fallback: t.abbreviation,
                  color: t.color),
              if (showScore)
                Text(t.score ?? '',
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70)),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        canRequestFocus: false,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? Color.lerp(Colors.black, accent, 0.25)
                : watching
                    ? accent.withValues(alpha: .10)
                    : Colors.transparent,
            border: Border.all(
                color: selected
                    ? accent
                    : watching
                        ? accent.withValues(alpha: .5)
                        : Colors.transparent,
                width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (g.isEventOnly)
                SportsLogo(
                    url: g.league.logoUrl,
                    size: 30,
                    fallback: g.league.shortName)
              else ...[
                team(g.first),
                const SizedBox(width: 2),
                team(g.second),
              ],
              const SizedBox(width: 8),
              if (watching)
                Icon(Icons.play_arrow, color: accent, size: 16)
              else if (g.state == GameState.live)
                const Icon(Icons.circle, color: Colors.redAccent, size: 8),
              if (watching || g.state == GameState.live)
                const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                        g.isEventOnly
                            ? TextSpan(text: g.title)
                            : TextSpan(children: [
                                if (starred) const TextSpan(text: '★ '),
                                TextSpan(text: '${g.first.abbreviation} '),
                                if (showScore) ...[
                                  TextSpan(
                                      text: g.first.score ?? '',
                                      style: scoreStyle),
                                  const TextSpan(text: '  -  '),
                                  TextSpan(
                                      text: g.second.score ?? '',
                                      style: scoreStyle),
                                ] else
                                  TextSpan(text: tr(g.joiner)),
                                TextSpan(text: ' ${g.second.abbreviation}'),
                              ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text(sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sports Mode's split playing hero: the game (left column, above the rows)
/// or the video with its hint (right).
enum _HeroPart { info, video }

/// The Sports Mode / hero player's video frame. Shared by the game hero and
/// a Live TV guide channel on a day without games, so a stream always sits
/// in the same player.
class _HeroVideo extends StatelessWidget {
  const _HeroVideo(
      {super.key, required this.width, required this.height, this.onTap});

  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final playingChannel = _desktopSports
        ? DesktopMiniPlayer.instance.channel.value
        : context.read<PlaybackService>().currentChannel;
    final miniController =
        _desktopSports ? DesktopMiniPlayer.instance.controller : null;
    return VideoTapLayer(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: scheme.primary, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: SizedBox(
            width: width,
            height: height,
            child: playingChannel == null
                ? const SizedBox()
                : miniController != null
                    // Windows: media_kit renders the mini player's texture.
                    ? Video(
                        controller: miniController, controls: NoVideoControls)
                    : VideoPlayerPane(
                        key: ValueKey(playingChannel.id),
                        showEpgBar: false,
                        showControls: false),
          ),
        ));
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.game,
    required this.service,
    required this.matches,
    required this.matching,
    required this.hideScores,
    required this.playing,
    this.showingOther = false,
    this.touch = false,
    this.narrow = false,
    this.onVideoTap,
    this.playingHeight,
    this.part,
  });

  /// Playing only: build just this part of the hero (null = both).
  final _HeroPart? part;

  /// Sports Mode on a TV: the playing hero's height (bigger video), sized
  /// by the screen to the room the rows leave; null = [height].
  final double? playingHeight;

  /// Touch/mouse: the playing video goes full screen when tapped.
  final VoidCallback? onVideoTap;

  /// [playing], but [game] is a card picked with OK, not the one whose
  /// stream the video shows (see `_heroPick`): its own channel is named.
  final bool showingOther;

  static const double height = 168;

  final SportsGame game;
  final SportsService service;
  final List<ChannelMatch>? matches;
  final bool matching;
  final bool hideScores;

  /// [game]'s channel is what [PlaybackService] plays: video on the left,
  /// the game compacted to the right (see [_buildPlaying]).
  final bool playing;

  /// A phone: the hint speaks of taps, not remote keys.
  final bool touch;

  /// Portrait phone: teams stacked over their names, the playing video
  /// above the game instead of beside it.
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final showScore = game.state != GameState.pre && !hideScores;
    if (playing) return _buildPlaying(context, showScore);
    if (game.isEventOnly) {
      return _EventHero(
          game: game, center: _center(context, false), hideScores: hideScores);
    }
    if (narrow) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        _narrowInfo(context, showScore),
        _stats(context),
      ]);
    }
    return SizedBox(
      height: height,
      child: Column(children: [
        Expanded(
            child: Row(children: [
          Expanded(
              child:
                  _side(context, game.first, alignEnd: false, compact: true)),
          SizedBox(width: 230, child: _center(context, showScore)),
          Expanded(
              child:
                  _side(context, game.second, alignEnd: true, compact: true)),
        ])),
        _stats(context, compact: true),
      ]),
    );
  }

  Widget _stats(BuildContext context, {bool compact = false}) =>
      SportsMatchupStats(
          game: game,
          service: service,
          hideScores: hideScores,
          compact: compact,
          showOdds: context.read<StorageService>().getSportsShowOdds());

  /// The playing hero. Rules from the platform-view bugs (CLAUDE.md §10,
  /// LiveResumeHint, PlayerControls):
  /// * the video is the same [VideoPlayerPane] the TV guide's preview box
  ///   uses, keyed by channel id, so a new stream gets a fresh platform view
  ///   (an in-place rebind kept the old channel's last frame frozen);
  /// * it is the only video of that stream on this screen (cards never show
  ///   one) and it stays mounted under a pushed fullscreen player, exactly
  ///   like that preview box — hiding/re-adding it per push raced the
  ///   platform view teardown (the old Live Island bug);
  /// * it always sits at the same place in this tree so score refreshes
  ///   don't recreate it, and nothing is drawn over it or clips it (overlays
  ///   and rounded clips on a platform view cost weak boxes a lot) — the
  ///   gold frame is a border around it.
  Widget _buildPlaying(BuildContext context, bool showScore) {
    final playingChannel = _desktopSports
        ? DesktopMiniPlayer.instance.channel.value
        : context.read<PlaybackService>().currentChannel;
    // The channel named under the score: the picked game's own match, not
    // the stream still playing.
    final channel = showingOther ? null : playingChannel;
    final heroHeight = playingHeight ?? height;
    final videoHeight = heroHeight - 8;
    // The normal VS layout, smaller, beside the video (owner: the stacked
    // version wasn't nice).
    final info = game.isEventOnly
        ? Row(
            children: [
              Expanded(
                child: Text(game.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
              SizedBox(
                  width: 190, child: _center(context, false, channel: channel)),
            ],
          )
        : Row(
            children: [
              Expanded(
                  child: _side(context, game.first,
                      alignEnd: false, compact: true)),
              SizedBox(
                  width: 190,
                  child: _center(context, showScore, channel: channel)),
              Expanded(
                  child: _side(context, game.second,
                      alignEnd: true, compact: true)),
            ],
          );

    Widget video(double w, double h) =>
        _HeroVideo(width: w, height: h, onTap: onVideoTap);
    final hint = _KeyHintText(
        showingOther
            ? touch
                ? tr('Tap: watch here  ·  Hold: pick the channel')
                : _desktopSports
                    ? tr('Click: watch here  ·  Hold: pick the channel')
                    : tr('OK: watch here  ·  Hold: pick the channel')
            : touch
                ? tr('Tap the game again: full screen  ·  Back: stop')
                : _desktopSports
                    ? tr(
                        'Click the game again or Enter: full screen  ·  Esc: stop')
                    : tr('OK: full screen  ·  ▶❚❚ or Back: stop'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: Colors.white54));

    if (part == _HeroPart.video) {
      final videoHint = touch || _desktopSports || showingOther
          ? hint
          // Sports Mode: Back opens the rail, the player keeps playing.
          : _KeyHintText(tr('OK again on a game: full screen  ·  ▶❚❚: stop'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.white54));
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          video(videoHeight * 16 / 9, videoHeight),
          const SizedBox(height: 6),
          SizedBox(width: videoHeight * 16 / 9 + 8, child: videoHint),
        ],
      );
    }
    if (part == _HeroPart.info) {
      return game.isEventOnly
          ? SizedBox(
              height: 130, child: _center(context, false, channel: channel))
          : Column(mainAxisSize: MainAxisSize.min, children: [
              _narrowInfo(context, showScore, channel: channel),
              _stats(context, compact: true),
            ]);
    }
    if (narrow) {
      // Portrait phone: no room beside the video, so the game sits under it.
      return Column(
        children: [
          LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth - 8;
            return video(w, w * 9 / 16);
          }),
          const SizedBox(height: 8),
          if (game.isEventOnly)
            SizedBox(
                height: 130, child: _center(context, false, channel: channel))
          else
            _narrowInfo(context, showScore, channel: channel),
          if (!game.isEventOnly) _stats(context),
          hint,
        ],
      );
    }

    return SizedBox(
      height: heroHeight,
      child: Row(
        children: [
          video(videoHeight * 16 / 9, videoHeight),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                Expanded(child: info),
                if (!game.isEventOnly) _stats(context, compact: true),
                hint,
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Portrait phone VS layout: each team's logo above its name, the time or
  /// score in a narrower middle.
  Widget _narrowInfo(BuildContext context, bool showScore, {Channel? channel}) {
    Widget side(SportsTeam t) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SportsLogo(
                url: t.logoUrl,
                size: 52,
                fallback: t.abbreviation,
                color: t.color),
            const SizedBox(height: 6),
            Text(SportsRanks.name(game.league, t),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            if (t.record != null)
              Text(t.record!,
                  style: const TextStyle(fontSize: 12, color: Colors.white60)),
          ],
        );
    return SizedBox(
      height: 140,
      child: Row(
        children: [
          Expanded(child: side(game.first)),
          SizedBox(
              width: 150,
              child:
                  _center(context, showScore, channel: channel, small: true)),
          Expanded(child: side(game.second)),
        ],
      ),
    );
  }

  Widget _side(BuildContext context, SportsTeam t,
      {required bool alignEnd, bool compact = false}) {
    final logo = SportsLogo(
        url: t.logoUrl,
        size: compact ? 56 : 92,
        fallback: t.abbreviation,
        color: t.color);
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(SportsRanks.name(game.league, t),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: compact ? 19 : 26,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        if (t.record != null)
          Text(t.record!,
              style: TextStyle(
                  fontSize: compact ? 13 : 15, color: Colors.white60)),
      ],
    );
    final gap = SizedBox(width: compact ? 10 : 14);
    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignEnd
          ? [Flexible(child: text), gap, logo]
          : [logo, gap, Flexible(child: text)],
    );
  }

  /// [channel]: what the playing hero shows (it may not be the best match).
  Widget _center(BuildContext context, bool showScore,
      {Channel? channel, bool small = false}) {
    final scheme = Theme.of(context).colorScheme;
    final best = matches?.firstOrNull;
    final channelName = channel?.name ?? best?.channel.name;
    String status;
    Color statusColor = Colors.white70;
    switch (game.state) {
      case GameState.live:
        status =
            game.statusText.isEmpty ? tr('Live') : trSports(game.statusText);
        statusColor = Colors.redAccent;
      case GameState.post:
        status =
            game.statusText.isEmpty ? tr('Final') : trSports(game.statusText);
      case GameState.pre:
        final until = game.start.difference(DateTime.now().toUtc());
        status = game.end != null
            // Golf: no tee time to count down to.
            ? DateFormat.MMMEd()
                .format(game.start.subtract(const Duration(hours: 4)))
            : until.inMinutes > 0 && until.inHours < 24
                ? tr('Starts in {p}{p2}m', {
                    'p': until.inHours > 0
                        ? tr('{h}h ', {'h': until.inHours})
                        : '',
                    'p2': until.inMinutes % 60
                  })
                : DateFormat.MMMEd().format(game.start.toLocal());
        statusColor = scheme.primary;
    }
    final ev = game.event;
    return LayoutBuilder(
        builder: (context, constraints) => FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
                width: constraints.maxWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A fight card's name ("UFC 320: Ankalaev vs. Pereira 2") says more
                    // than "UFC".
                    Text(
                        (game.league.kind == SportsKind.fight ||
                                    game.league.kind == SportsKind.tennis) &&
                                ev != null
                            ? ev.title
                            : game.league.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            letterSpacing: 1.2,
                            color: Colors.white54)),
                    const SizedBox(height: 4),
                    if (game.isEventOnly)
                      Text(
                          game.state == GameState.pre
                              ? _preLabel(game)
                              : trSports(ev?.session ?? game.league.shortName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white))
                    else if (showScore)
                      Text(
                          '${game.first.score ?? '-'}  -  ${game.second.score ?? '-'}',
                          maxLines: 1,
                          style: TextStyle(
                              fontSize: small ? 28 : 38,
                              fontWeight: FontWeight.w800,
                              color: Colors.white))
                    else
                      Text(
                          game.state == GameState.pre
                              ? _timeLabel(game.start)
                              : game.joiner,
                          maxLines: 1,
                          style: TextStyle(
                              fontSize: small ? 24 : 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor)),
                        ),
                        RecPill(game: game, small: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (channelName != null)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.live_tv,
                                  size: 15, color: scheme.primary),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(channelName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Text(
                          matching
                              ? tr('Looking for the channel…')
                              : SportsChannelMatcher.sharedWhyNoMatch(game)
                                      ?.short ??
                                  tr('No channel found — OK to pick one'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white54)),
                  ],
                ))));
  }
}

/// A hint whose "▶❚❚" (the remote's Play/Pause key, in every language's
/// string) is drawn as plain white play / pause icons — as text, Android
/// renders ▶ as an orange emoji (owner, 2026-10-18).
class _KeyHintText extends StatelessWidget {
  const _KeyHintText(this.text, {required this.style, this.textAlign});
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('▶❚❚');
    final size = (style.fontSize ?? 12) + 2;
    final keys = WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow, size: size, color: Colors.white),
          Text('/', style: style.copyWith(color: Colors.white)),
          Icon(Icons.pause, size: size, color: Colors.white),
        ],
      ),
    );
    return Text.rich(
      TextSpan(children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0) keys,
          TextSpan(text: parts[i]),
        ],
      ]),
      textAlign: textAlign,
      style: style,
    );
  }
}

/// Small hint under the focused game card (owner: the floating pill was too
/// big). The first-press preview and hold are spelled out. Its height is
/// always reserved in the row so focus moves don't shift the layout.
class _HoldHint extends StatelessWidget {
  const _HoldHint({required this.visible});
  final bool visible;

  static const double height = 22;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 120),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.6), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app, size: 11, color: scheme.primary),
                const SizedBox(width: 4),
                _KeyHintText(
                    _desktopSports
                        ? tr('Click: watch here  ·  Hold: pick the channel')
                        : !context.read<AppPreferences>().isTelevision
                            ? tr('Tap: watch here  ·  Hold: pick the channel')
                            : tr('OK: watch here  ·  Hold: pick the channel'),
                    style:
                        const TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatefulWidget {
  const _GameCard({
    super.key,
    this.cardHeight = height,
    required this.focusNode,
    required this.game,
    required this.match,
    required this.matching,
    required this.hideScores,
    required this.starred,
    required this.previewing,
    required this.onFocus,
    required this.onTap,
    required this.onHold,
  });

  static const double width = 268;
  static const double height = 132;

  final double cardHeight;
  final FocusNode focusNode;
  final SportsGame game;
  final ChannelMatch? match;
  final bool matching;
  final bool hideScores;

  /// One of My Teams plays.
  final bool starred;

  /// Its channel is playing in the hero.
  final bool previewing;
  final VoidCallback onFocus;
  final VoidCallback onTap;
  final VoidCallback onHold;

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final g = widget.game;
    final live = g.state == GameState.live;
    final showScore = g.state != GameState.pre && !widget.hideScores;
    // Settings > Sports Trak > Betting odds (off by default).
    final odds = g.state != GameState.post &&
            context.read<StorageService>().getSportsShowOdds()
        ? g.odds?.line
        : null;
    final status = switch (g.state) {
      GameState.pre => _preLabel(g),
      GameState.live =>
        g.statusText.isEmpty ? tr('LIVE') : trSports(g.statusText),
      GameState.post =>
        g.statusText.isEmpty ? tr('Final') : trSports(g.statusText),
    };

    Widget teamLine(SportsTeam t, {required bool leading}) {
      final firstScore = int.tryParse(g.first.score ?? '');
      final secondScore = int.tryParse(g.second.score ?? '');
      final mine = int.tryParse(t.score ?? '');
      final other = identical(t, g.first) ? secondScore : firstScore;
      final winning = g.state == GameState.post &&
          (t.score == 'W' || (mine != null && other != null && mine > other));
      return Row(
        children: [
          SizedBox(
            width: 22,
            child: leading
                ? const SizedBox()
                : Text(g.joiner,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white54)),
          ),
          SportsLogo(
              url: t.logoUrl,
              size: 30,
              fallback: t.abbreviation,
              color: t.color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(SportsRanks.name(g.league, t),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: g.state == GameState.post && !winning
                        ? Colors.white70
                        : Colors.white)),
          ),
          if (showScore)
            Text(t.score ?? '',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: winning || live ? Colors.white : Colors.white70))
          else if (t.record != null)
            Text(t.record!,
                style: const TextStyle(fontSize: 13, color: Colors.white54)),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 4, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Remote OK: short = watch, hold = channel menu (key path). Mouse/touch
          // long-press opens the menu too; a plain click keeps InkWell's onTap.
          HoldToActivate(
            onTap: widget.onTap,
            onHold: widget.onHold,
            child: InkWell(
              focusNode: widget.focusNode,
              borderRadius: BorderRadius.circular(16),
              // Pointer focus and activation are one action, just like OK on
              // a remote: first press previews, next press is full screen.
              onTap: () {
                widget.focusNode.requestFocus();
                widget.onTap();
              },
              onFocusChange: (f) {
                setState(() => _focused = f);
                if (f) widget.onFocus();
              },
              child: AnimatedScale(
                scale: _focused ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                child: Container(
                  width: _GameCard.width,
                  height: widget.cardHeight,
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
                  decoration: RefinedFinish.decorate(
                      context,
                      BoxDecoration(
                        // Watching: a light gold tint + thin frame (the
                        // "WATCHING" pill is the main cue; a thick frame read
                        // like the focused card, owner 2026-10-17).
                        color: _focused
                            ? null
                            : widget.previewing
                                ? scheme.primary.withValues(alpha: 0.14)
                                : Colors.white.withValues(alpha: 0.07),
                        gradient: _focused ? sportsFocusSheen(scheme) : null,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _focused
                                ? scheme.primary
                                : widget.previewing
                                    ? scheme.primary.withValues(alpha: 0.6)
                                    : Colors.white10,
                            width:
                                _focused ? 2.5 : (widget.previewing ? 1.5 : 1)),
                        boxShadow: _focused
                            ? [
                                BoxShadow(
                                    color:
                                        scheme.primary.withValues(alpha: 0.35),
                                    blurRadius: 16)
                              ]
                            : null,
                      ),
                      focused: _focused),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.starred)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.star,
                                  size: 13, color: scheme.primary),
                            ),
                          Text(g.league.shortName.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1,
                                  color: Colors.white54)),
                          const SizedBox(width: 6),
                          // The game playing in the hero (it can be another
                          // card's details the hero shows, see _heroPick).
                          if (widget.previewing)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.fromLTRB(4, 2, 7, 2),
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow,
                                      size: 13, color: scheme.onPrimary),
                                  const SizedBox(width: 2),
                                  Text(tr('Watching').toUpperCase(),
                                      style: TextStyle(
                                          fontSize: 9.5,
                                          letterSpacing: 0.6,
                                          fontWeight: FontWeight.w800,
                                          color: scheme.onPrimary)),
                                ],
                              ),
                            ),
                          RecPill(game: g, small: true),
                          // Takes the rest of the row (status right-aligned)
                          // and shrinks a long status next to the pill.
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (live)
                                  Container(
                                    width: 7,
                                    height: 7,
                                    margin: const EdgeInsets.only(right: 5),
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.redAccent),
                                  ),
                                Flexible(
                                  child: Text(status,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: live
                                              ? Colors.redAccent
                                              : Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      if (g.isEventOnly)
                        _EventCardBody(game: g, hideScores: widget.hideScores)
                      else ...[
                        teamLine(g.first, leading: true),
                        const SizedBox(height: 4),
                        teamLine(g.second, leading: false),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                              widget.match != null
                                  ? Icons.live_tv
                                  : Icons.add_circle_outline,
                              size: 13,
                              color: widget.match != null
                                  ? scheme.primary
                                  : Colors.white38),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              widget.match?.channel.name ??
                                  (widget.matching
                                      ? tr('Looking…')
                                      : SportsChannelMatcher.sharedWhyNoMatch(g)
                                              ?.card ??
                                          tr('Pick a channel')),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: widget.match != null
                                      ? scheme.primary
                                      : Colors.white38),
                            ),
                          ),
                          if (odds != null && odds.isNotEmpty)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 140),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(odds,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _HoldHint(visible: _focused),
        ],
      ),
    );
  }
}

// =================================================================== dialogs

sealed class _GameAction {}

class _WatchAction extends _GameAction {
  _WatchAction(this.channel);
  final Channel channel;
}

class _PickAction extends _GameAction {}

class _ReminderAction extends _GameAction {
  _ReminderAction({this.edit = false});
  final bool edit;
}

class _AddSourcesAction extends _GameAction {}

class _MoreSourcesAction extends _GameAction {}

class _ForgetPickAction extends _GameAction {}

class _RecordAction extends _GameAction {
  _RecordAction(this.channel);
  final Channel channel;
}

class _StopRecordAction extends _GameAction {
  _StopRecordAction(this.entry);
  final RecordingEntry entry;
}

/// Record every game of [team] (null = stop auto-recording).
class _AutoTeamAction extends _GameAction {
  _AutoTeamAction(this.team);
  final SportsTeam? team;
}

class _GameDialog extends StatelessWidget {
  const _GameDialog({
    required this.game,
    required this.matches,
    required this.matching,
    required this.hideScores,
    required this.hasPick,
    this.recording,
    this.autoTeam,
    required this.offerPlayHere,
    this.playFullScreen = false,
  });

  final SportsGame game;
  final List<ChannelMatch> matches;
  final bool matching;
  final bool hideScores;
  final bool hasPick;

  /// First entry "Play here" (the hero mini player): some remotes have no
  /// Play/Pause key (user report, 2026-10-18), so hold OK > OK starts it.
  final bool offerPlayHere;

  /// Live list: that first entry is "Play" (full screen) — no hero there.
  final bool playFullScreen;

  /// This game's recording (scheduled / running / done), null = none.
  final RecordingEntry? recording;

  /// The team whose every game is recorded, if any.
  final AutoTeam? autoTeam;

  /// Record / Stop recording / Record every <team> game (Android).
  List<Widget> _recordTiles(BuildContext context) {
    if (!RecordingService.supported) return const [];
    final rec = recording;
    final tiles = <Widget>[];
    if (rec != null &&
        (rec.state == RecState.scheduled ||
            rec.state == RecState.waiting ||
            rec.state == RecState.recording)) {
      final running = rec.state == RecState.recording;
      tiles.add(TvMenuTile(
        icon: running ? Icons.stop_circle_outlined : Icons.event_busy,
        title: running ? tr('Stop recording') : tr('Cancel recording'),
        subtitle: rec.state == RecState.waiting
            ? tr('Waiting for a channel in the guide')
            : '${rec.channelName} · ${_timeLabel(rec.startAt)}–${_timeLabel(rec.endAt)}',
        onTap: () => Navigator.of(context).pop(_StopRecordAction(rec)),
      ));
    } else if (game.state != GameState.post && matches.isNotEmpty) {
      tiles.add(TvMenuTile(
        icon: Icons.fiber_manual_record,
        title: tr('Record'),
        subtitle: game.state == GameState.live
            ? tr('{channel} · starts now',
                {'channel': matches.first.channel.name})
            : tr('{channel} · from {time}', {
                'channel': matches.first.channel.name,
                'time': _timeLabel(game.start),
              }),
        onTap: () =>
            Navigator.of(context).pop(_RecordAction(matches.first.channel)),
      ));
    }
    if (!game.isEventOnly) {
      for (final team in [game.first, game.second]) {
        final isAuto = RecordingService.instance.isAutoTeam(game, team);
        tiles.add(TvMenuTile(
          icon: isAuto ? Icons.event_repeat : Icons.repeat,
          title: isAuto
              ? tr('Stop recording every {team} game', {'team': team.shortName})
              : tr('Record every {team} game', {'team': team.shortName}),
          subtitle: isAuto
              ? tr('Recordings already made are kept')
              : autoTeam == null
                  ? tr('One team at a time, on the channel {tab} picks',
                      {'tab': AppConstants.sportsTabName})
                  : tr('Replaces {team}', {'team': autoTeam!.teamName}),
          onTap: () =>
              Navigator.of(context).pop(_AutoTeamAction(isAuto ? null : team)),
        ));
      }
    }
    return tiles;
  }

  @override
  Widget build(BuildContext context) {
    final showScore =
        game.state != GameState.pre && !hideScores && !game.isEventOnly;
    return Dialog(
      backgroundColor: const Color(0xFF15151A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SportsLogo(
                      url: game.first.logoUrl,
                      size: 44,
                      fallback: game.first.abbreviation,
                      color: game.first.color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            showScore
                                ? '${game.first.shortName} ${game.first.score ?? ''}  ${game.joiner}  ${game.second.shortName} ${game.second.score ?? ''}'
                                : game.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Text(
                            '${game.league.name} · ${game.state == GameState.pre ? '${DateFormat('EEE').format(game.start.toLocal())} ${_timeLabel(game.start)}' : trSports(game.statusText)}'
                            '${game.broadcasts.isEmpty ? '' : ' · ${game.broadcasts.take(3).join(', ')}'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.white60)),
                      ],
                    ),
                  ),
                  // Golf/racing: both "sides" are the league placeholder.
                  if (!game.isEventOnly) ...[
                    const SizedBox(width: 10),
                    SportsLogo(
                        url: game.second.logoUrl,
                        size: 44,
                        fallback: game.second.abbreviation,
                        color: game.second.color),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Text(
                  matches.isEmpty
                      ? (matching
                          ? tr('Still looking for channels…')
                          : SportsChannelMatcher.sharedWhyNoMatch(game)
                                  ?.reason ??
                              tr('No channel found for this game'))
                      : tr('On {matches} channel{s}', {
                          'matches': matches.length,
                          's': matches.length == 1 ? '' : 's'
                        }),
                  style: const TextStyle(
                      fontSize: 12, letterSpacing: 1, color: Colors.white54)),
              const SizedBox(height: 6),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    GameScoreAlertMenuTile(game: game),
                    GameReminderMenuTile(
                        game: game,
                        onEdit: () =>
                            Navigator.pop(context, _ReminderAction(edit: true)),
                        onTap: () => Navigator.pop(context, _ReminderAction())),
                    TvMenuTile(
                        icon: Icons.playlist_add,
                        title: tr('Add sources'),
                        onTap: () =>
                            Navigator.pop(context, _AddSourcesAction())),
                    TvMenuTile(
                        icon: Icons.list,
                        title: tr('More sources'),
                        onTap: () =>
                            Navigator.pop(context, _MoreSourcesAction())),
                    if (offerPlayHere && matches.isNotEmpty)
                      TvMenuTile(
                        autofocus: true,
                        icon: Icons.play_arrow,
                        title: playFullScreen ? tr('Play') : tr('Play here'),
                        subtitle: playFullScreen
                            ? tr('{channel} · full screen',
                                {'channel': matches.first.channel.name})
                            : tr('{channel} · plays at the top of {tab}', {
                                'channel': matches.first.channel.name,
                                'tab': AppConstants.sportsTabName,
                              }),
                        onTap: () => Navigator.of(context)
                            .pop(_WatchAction(matches.first.channel)),
                      ),
                    for (var i = 0; i < matches.length; i++)
                      TvMenuTile(
                        autofocus: i == 0 && !offerPlayHere,
                        titleMaxLines: 2,
                        leading: _ChannelLogo(channel: matches[i].channel),
                        title: matches[i].channel.name,
                        subtitle: matches[i].detail == null ||
                                matches[i].reason == MatchReason.name
                            ? matches[i].reason.label
                            : '${matches[i].reason.label} · ${matches[i].detail}',
                        onTap: () => Navigator.of(context)
                            .pop(_WatchAction(matches[i].channel)),
                      ),
                    TvMenuTile(
                      autofocus: matches.isEmpty,
                      icon: Icons.search,
                      title: matches.isEmpty
                          ? tr('Pick the channel')
                          : tr('Choose a different channel'),
                      subtitle: tr(
                          'Search your channels — it can be remembered for this game or team'),
                      onTap: () => Navigator.of(context).pop(_PickAction()),
                    ),
                    if (hasPick)
                      TvMenuTile(
                        icon: Icons.restart_alt,
                        title: tr('Forget my pick'),
                        subtitle: tr('Go back to the automatic match'),
                        onTap: () =>
                            Navigator.of(context).pop(_ForgetPickAction()),
                      ),
                    ..._recordTiles(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelLogo extends StatelessWidget {
  const _ChannelLogo({required this.channel});
  final Channel channel;

  @override
  Widget build(BuildContext context) {
    final url = channel.logoUrl;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: url == null || url.isEmpty
          ? const Icon(Icons.live_tv, color: Colors.white54, size: 20)
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              memCacheWidth: 96,
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.live_tv, color: Colors.white54, size: 20),
            ),
    );
  }
}

enum _PickScope { game, first, second }

class _PickScopeDialog extends StatelessWidget {
  const _PickScopeDialog({required this.game, required this.channel});
  final SportsGame game;
  final Channel channel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF15151A),
      title: Text(tr('Remember this channel?')),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(channel.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TvMenuTile(
              autofocus: true,
              icon: Icons.event,
              title: tr('Just this game'),
              subtitle: tr('Best for channels named after one game'),
              onTap: () => Navigator.of(context).pop(_PickScope.game),
            ),
            // Event sports: one "always" choice for the whole series (Sky
            // Sports F1, Golf Channel) — remembering a channel per golfer or
            // fighter would never come up again.
            if (game.league.kind != SportsKind.team)
              TvMenuTile(
                leading: SportsLogo(
                    url: game.league.logoUrl,
                    size: 36,
                    fallback: game.league.shortName),
                title: tr('Always for {name}', {'name': game.league.name}),
                subtitle:
                    tr('Best for a channel that carries the whole series'),
                onTap: () => Navigator.of(context).pop(_PickScope.first),
              )
            else
              for (final (scope, team) in [
                (_PickScope.first, game.first),
                (_PickScope.second, game.second),
              ])
                TvMenuTile(
                  leading: SportsLogo(
                      url: team.logoUrl,
                      size: 36,
                      fallback: team.abbreviation,
                      color: team.color),
                  title: tr('Always for the {shortName}',
                      {'shortName': team.shortName}),
                  subtitle:
                      tr('Best for a regular channel, like a regional network'),
                  onTap: () => Navigator.of(context).pop(scope),
                ),
          ],
        ),
      ),
    );
  }
}

/// Manual "which channel is this game on" search. Quick chips (team names,
/// league, networks) avoid typing — on a Fire Stick the on-screen keyboard
/// is slow and swallows Back (CLAUDE.md §10) — but a text field is there
/// for anything else.
class _ChannelPickerScreen extends StatefulWidget {
  const _ChannelPickerScreen({required this.game, required this.matcher});
  final SportsGame game;
  final SportsChannelMatcher matcher;

  @override
  State<_ChannelPickerScreen> createState() => _ChannelPickerScreenState();
}

class _ChannelPickerScreenState extends State<_ChannelPickerScreen> {
  final _controller = TextEditingController();
  late final List<FocusNode> _chipNodes;
  late final FocusNode _fieldNode = FocusNode(onKeyEvent: _onFieldKey);
  final _firstResult = FocusNode();
  late String _query;
  late final List<String> _suggestions;

  @override
  void initState() {
    super.initState();
    final g = widget.game;
    // Golf/racing have no team names: offer the series ("Formula 1", "PGA
    // Tour") and the network. Fighters go by last name on event channels.
    String lastName(SportsTeam t) =>
        t.name.split(' ').where((w) => w.length > 3).lastOrNull ?? t.name;
    _suggestions = (g.isEventOnly
            ? {
                g.league.name,
                g.league.shortName,
                ...g.broadcasts.take(4),
              }
            : g.league.kind == SportsKind.fight ||
                    g.league.kind == SportsKind.tennis
                ? {
                    lastName(g.second),
                    lastName(g.first),
                    g.league.shortName,
                    ...g.broadcasts.take(4),
                  }
                : {
                    g.first.shortName,
                    g.second.shortName,
                    g.league.shortName,
                    ...g.broadcasts.take(4),
                  })
        .toList();
    _chipNodes = [for (final _ in _suggestions) FocusNode()];
    _query = _suggestions.first == g.first.shortName
        ? g.second.shortName
        : _suggestions.first;
    _controller.text = _query;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _chipNodes[_suggestions.indexOf(_query)].requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final n in _chipNodes) {
      n.dispose();
    }
    _fieldNode.dispose();
    _firstResult.dispose();
    super.dispose();
  }

  /// `EditableText` keeps the arrow keys for itself, so after Back closes the
  /// keyboard (Formuler) the D-pad had no way out of the field. The field's
  /// own node sees keys before EditableText's shortcuts do: Down -> results,
  /// Up -> suggestion chips — same idea as Add Playlist's
  /// `_handleFieldEscapeKey`.
  KeyEventResult _onFieldKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      if (_firstResult.context == null) return KeyEventResult.ignored;
      _firstResult.requestFocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      final i = _suggestions.indexOf(_query);
      _chipNodes[i < 0 ? 0 : i].requestFocus();
      return KeyEventResult.handled;
    }
    // OK = keyboard is TvTextFieldGate's job (this also reopened it on the
    // Enter Fire OS sends when Back closes its keyboard).
    return KeyEventResult.ignored;
  }

  void _setQuery(String q) {
    _controller.text = q;
    setState(() => _query = q);
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.matcher.search(_query);
    final epg = context.read<EpgService>();
    return SportsScreenFrame(
        child: withTvThemeIfNeeded(
      context,
      (context) => SettingsScaffold(
        title: tr('Pick the channel for {title}', {'title': widget.game.title}),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final (i, s) in _suggestions.indexed)
                      SportsChip(
                        focusNode: _chipNodes[i],
                        label: s,
                        selected: _query == s,
                        compact: true,
                        onFocus: () {},
                        onTap: () => _setQuery(s),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // TV: keyboard only on OK, so Down from the chips can pass the
              // field to the results (Fire OS: the keyboard took the remote
              // as soon as the field was focused).
              TvTextFieldGate(
                focusNode: _fieldNode,
                builder: (context, readOnly) => TextField(
                  controller: _controller,
                  focusNode: _fieldNode,
                  readOnly: readOnly,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: tr('Search channels'),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                  // Done / Fire OS Back: on to the results, never nothing.
                  onSubmitted: (_) {
                    if (_firstResult.context != null) {
                      _firstResult.requestFocus();
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                  results.isEmpty
                      ? tr('No channels match "{query}"', {'query': _query})
                      : tr('{results}{p} channels', {
                          'results': results.length,
                          'p': results.length >= 200 ? '+' : ''
                        }),
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final c = results[i];
                    final now = epg.getCurrentProgram(c.epgId)?.title;
                    return TvMenuTile(
                      focusNode: i == 0 ? _firstResult : null,
                      titleMaxLines: 2,
                      leading: _ChannelLogo(channel: c),
                      title: c.name,
                      subtitle: now == null
                          ? c.group
                          : tr('{group} · Now: {now}',
                              {'group': c.group, 'now': now}),
                      onTap: () => Navigator.of(context).pop(c),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
