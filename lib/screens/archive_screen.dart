import 'dart:async';
import '../models/archive_library.dart';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show ItemExtentBuilder, ScrollCacheExtent, SliverLayoutDimensions;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/archive_models.dart';
import '../services/archive_ready_watch.dart';
import '../services/archive_service.dart';
import '../services/archive_stream_session.dart';
import '../utils/image_urls.dart';
import '../widgets/detail_header.dart';
import '../widgets/hd_network_image.dart';
import '../widgets/archive_row_settings.dart';
import '../widgets/hold_to_activate.dart';
import '../widgets/live_resume_hint.dart';
import '../widgets/poster_card.dart';
import '../widgets/roll_down_menu.dart';
import '../widgets/tv_text_field_gate.dart';
import 'archive_catalog_screen.dart';
import 'archive_detail_screen.dart';
import 'archive_playback.dart';
import 'settings/archive_sources_screen.dart';
import 'settings/media_server_screen.dart';

/// The Archive tab: classic, public-domain films and series from the
/// user's own sources (Settings > Archive sources, any server speaking the
/// Stremio catalog/stream schema). Same shape as Movies/TV Shows — a rail
/// on the left (Movies / TV Shows, then each catalog as a jump target), a
/// hero with the focused title's backdrop and description, and one
/// [PosterCard] row per catalog. Its own page (like Sports Trak), not a
/// column of TvHomeScreen: nothing here belongs to a playlist.
///
/// D-pad: explicit dispatch inside the rows (Up/Down = neighbour row at
/// its remembered card, Left on the first card = rail), per CLAUDE.md's
/// rule that default traversal is unreliable across differently shaped
/// rows. Both rows and cards are lazy: navigation scrolls an off-screen row
/// into the viewport before requesting its card's focus. Moving
/// along a row jumps its own scroll controller to the card first (a card
/// the list hasn't built can't take focus), and nearing the end of a row
/// loads its next page. Search and Genre sit in a floating bar at the top
/// centre (phone tab bar look), for the category picked in the rail — each
/// of Movies / TV Shows keeps its own search and genre; Up from the first
/// row reaches it. Search puts the results first.
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  ArchiveType _type = ArchiveType.movie;
  final _railScope = FocusScopeNode(debugLabel: 'archive-rail');
  final _contentScope = FocusScopeNode(debugLabel: 'archive-content');
  final _firstRailNode = FocusNode(debugLabel: 'archive-rail-first');
  final _emptyActionNode = FocusNode(debugLabel: 'archive-empty-action');
  final _barScope = FocusScopeNode(debugLabel: 'archive-bar');
  final _railSearchNode = FocusNode(debugLabel: 'archive-rail-search');
  final _barClearNode = FocusNode(debugLabel: 'archive-bar-clear');
  final _barGenreNode = FocusNode(debugLabel: 'archive-bar-genre');
  final _barNewestNode = FocusNode(debugLabel: 'archive-bar-newest');
  final _barSourceNode = FocusNode(debugLabel: 'archive-search-source');
  final _barManageNode = FocusNode(debugLabel: 'archive-bar-manage');
  final _barBackNode = FocusNode(debugLabel: 'archive-bar-back');

  /// The floating bar's row jumps ("Popular", "New"...), by row key.
  final Map<String, FocusNode> _barRowNodes = {};
  final _scroll = ScrollController();

  /// Card focus nodes by row key, created on demand.
  final Map<String, Map<int, FocusNode>> _nodes = {};

  /// Last focused card index per row, so Up/Down lands where you were.
  final Map<String, int> _lastIndex = {};
  final Map<String, GlobalKey> _rowKeys = {};
  final Map<String, ScrollController> _rowScrolls = {};

  Timer? _progressRefresh;
  String? _focusedRowKey;
  int _focusedRow = 0;
  ArchiveMeta? _focused;
  String? _focusedLabel;

  /// The focused title is a Jellyfin/Emby/Plex item: its rating is the
  /// server's community rating, not IMDb's.
  bool _focusedFromServer = false;
  late final VoidCallback _releaseResumeHint;

  @override
  void initState() {
    super.initState();
    _releaseResumeHint = LiveResumeHint.hideWhileMounted();
    // PopScope's canPop reads _contentScope.hasFocus at build time; moving
    // focus rows -> rail doesn't rebuild by itself, which left Back stuck
    // sending focus to the rail forever. Rebuild whenever that flips.
    _contentScope.addListener(_onContentFocus);
    _barScope.addListener(_onContentFocus);
    _railScope.addListener(_onRailFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ArchiveService>().open();
      _firstRailNode.requestFocus();
    });
  }

  bool _contentHadFocus = false;

  /// The rail is open (icons + labels, over the rows) only while it has
  /// focus; elsewhere it is a slim strip of icons (owner, 2026-11-01: the
  /// open pill took too much of the screen).
  bool _railOpen = true;

  /// Icon + both paddings + the label gap: an entry fits even while the
  /// rail starts to open (labels appear at once, the width animates).
  static const double _railSlim = 80;
  static const double _railWide = 240;

  /// Search's pull-out and dialog take the focus: the rail stays open
  /// behind them instead of closing under the menu.
  bool _railPinned = false;

  void _onRailFocus() {
    final open = _railScope.hasFocus || _railPinned;
    if (open == _railOpen || !mounted) return;
    setState(() => _railOpen = open);
  }

  bool get _narrow => MediaQuery.sizeOf(context).width < 700;

  /// Rows or the floating bar focused: Back goes to the rail first.
  bool get _awayFromRail => _contentScope.hasFocus || _barScope.hasFocus;

  void _onContentFocus() {
    final has = _awayFromRail;
    if (has == _contentHadFocus || !mounted) return;
    _contentHadFocus = has;
    setState(() {});
  }

  @override
  void dispose() {
    _contentScope.removeListener(_onContentFocus);
    _barScope.removeListener(_onContentFocus);
    _railScope.removeListener(_onRailFocus);
    _releaseResumeHint();
    _progressRefresh?.cancel();
    _barScope.dispose();
    _railSearchNode.dispose();
    _barClearNode.dispose();
    _barGenreNode.dispose();
    _barNewestNode.dispose();
    _barBackNode.dispose();
    _barManageNode.dispose();
    _barSourceNode.dispose();
    for (final n in _barRowNodes.values) {
      n.dispose();
    }
    _railScope.dispose();
    _contentScope.dispose();
    _firstRailNode.dispose();
    _emptyActionNode.dispose();
    _scroll.dispose();
    for (final c in _rowScrolls.values) {
      c.dispose();
    }
    for (final list in _nodes.values) {
      for (final n in list.values) {
        n.dispose();
      }
    }
    super.dispose();
  }

  FocusNode _node(String rowKey, int i) {
    // Jumping into a large catalog must not allocate nodes for every earlier item.
    return _nodes
        .putIfAbsent(rowKey, () => {})
        .putIfAbsent(i, () => FocusNode(debugLabel: 'archive-card'));
  }

  double get _rowHeaderHeight =>
      MediaQuery.textScalerOf(context).scale(15) * 1.3 + 20;
  double get _rowExtent => _rowHeaderHeight + PosterCard.height + 16;

  GlobalKey _rowKey(String key) => _rowKeys.putIfAbsent(key, GlobalKey.new);

  ScrollController _rowScroll(String key) =>
      _rowScrolls.putIfAbsent(key, ScrollController.new);

  /// Card slot width in a row: the card, PosterCard's own 6 px padding and
  /// the row's 4 px each side. Was `width + 8` (PosterCard's padding
  /// missed): each Right scrolled 12 px short, so the selector crept off
  /// the right edge after ~15 presses (owner, 2026-10-21).
  static const _cardExtent = PosterCard.width + 12 + 8;
  static const _rowPadding = 20.0;

  /// The focused card's slot when it is drawn wide (Nuvio style, owner
  /// 2026-11-01): 16:9 backdrop + title logo, same height as a poster.
  static const _wideExtent = PosterCard.wideCardWidth + 12 + 8;

  /// Wide focused cards: TV/desktop widths only (a phone row has no room).
  bool get _wideCards => MediaQuery.sizeOf(context).width >= 700;

  /// The card of [row] drawn wide: its focused card while the rows have
  /// focus, when that title has a backdrop. Every card before it is a
  /// normal slot, which keeps [_focusCard]'s maths exact.
  int? _wideIndex(ArchiveRow row) {
    if (!_wideCards || !_contentScope.hasFocus || row.key != _focusedRowKey) {
      return null;
    }
    final i = _lastIndex[row.key];
    if (i == null || i >= row.items.length) return null;
    return row.items[i].backgroundUrl == null ? null : i;
  }

  /// One extent builder per row, replaced only when that row's wide card
  /// changes: the varied-extent list sums every slot to lay out, so a new
  /// closure on each rebuild would re-measure every visible row.
  final Map<String, (int?, ItemExtentBuilder)> _extentBuilders = {};

  ItemExtentBuilder _extentBuilder(String key, int? wideAt) {
    final cached = _extentBuilders[key];
    if (cached != null && cached.$1 == wideAt) return cached.$2;
    double? builder(int i, SliverLayoutDimensions _) =>
        i == wideAt ? _wideExtent : _cardExtent;
    _extentBuilders[key] = (wideAt, builder);
    return builder;
  }

  /// Scrolls [row] so card [i] is on screen (with a card of room past it),
  /// then focuses it — after a frame when the jump had to build it, retried
  /// for a few frames on a slow box (owner, 2026-10-21: holding Right, the
  /// selector got lost on titles not built yet). Card [i] will be the wide
  /// one once focused, and the cards before it normal slots.
  void _focusCard(ArchiveRow row, int i) {
    _revealCard(row, i);
    _focusWhenBuilt(_node(row.key, i));
    // Again once the card is wide: the jump above was clamped to the row's
    // old length, short by the wide slot near the end of a row.
    if (_wideCards) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _revealCard(row, i);
      });
    }
  }

  void _revealCard(ArchiveRow row, int i) {
    final c = _rowScrolls[row.key];
    if (c != null && c.hasClients && i < row.items.length) {
      final pos = c.position;
      final start = _rowPadding + i * _cardExtent;
      final extent = _wideCards && row.items[i].backgroundUrl != null
          ? _wideExtent
          : _cardExtent;
      double? to;
      if (start - _cardExtent < pos.pixels) {
        to = start - _cardExtent;
      } else if (start + extent + _cardExtent >
          pos.pixels + pos.viewportDimension) {
        to = start + extent + _cardExtent - pos.viewportDimension;
      }
      if (to != null) c.jumpTo(to.clamp(0.0, pos.maxScrollExtent));
    }
  }

  void _focusWhenBuilt(FocusNode node, [int framesLeft = 4]) {
    if (node.context != null) {
      node.requestFocus();
    } else if (framesLeft > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusWhenBuilt(node, framesLeft - 1);
      });
      WidgetsBinding.instance.scheduleFrame();
    }
  }

  /// Provider rows ("Popular", "New", "Featured") are translated; a
  /// source's own catalog names are shown as sent. With a genre picked the
  /// rows say so: "Popular · Horror".
  String _rowTitle(ArchiveService service, ArchiveRow row) {
    if (row.isSearch) {
      // Several search rows: name the source(s) each one comes from.
      return '${tr('Results for "{query}"', {'query': row.searchQuery})}'
          ' · ${row.labelAt(0)}';
    }
    if (row.customTitle != null) return row.customTitle!;
    if (row.continuations != null) return tr(row.title);
    if (row.isHistory) return tr('Recently watched');
    if (row.isFavorites) return tr('Favourites');
    final title = row.source.streamOnly || row.source.tracker != null
        ? tr(row.title)
        : row.title;
    final genre = service.genre(_type);
    return genre == null ? title : '$title · ${_genreName(genre)}';
  }

  /// A genre's display name. Genres are ids sent to the source, so they're
  /// translated under `genre.` keys ("History" alone is watch history);
  /// one the dictionaries don't know (a source's own) is shown as sent.
  static String _genreName(String genre) {
    if (genre == ArchiveService.otherGenre) return tr('Other');
    final key = 'genre.$genre';
    final s = tr(key);
    return s == key ? genre : s;
  }

  /// Genre filter, in the floating bar's style: "All genres" then every
  /// genre the rows can be narrowed to, as a grid of pills (equal cells, so
  /// the D-pad moves predictably). Rows that can't be narrowed (the
  /// provider's "New") hide while a genre is picked.
  Future<void> _pickGenre(ArchiveService service) async {
    final type = _type;
    final current = service.genre(type);
    final genres = ['', ...service.genres(type)]; // '' = All genres
    final narrow = MediaQuery.sizeOf(context).width < 700;
    final picked = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _FloatingPanel(
        title: type == ArchiveType.movie
            ? tr('Movie genres')
            : tr('TV show genres'),
        width: narrow ? 360 : 660,
        child: Flexible(
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: narrow ? 2 : 3,
              mainAxisExtent: 50,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: genres.length,
            itemBuilder: (_, i) {
              final g = genres[i];
              final selected = g == (current ?? '');
              return _BarButton(
                autofocus: selected,
                expand: true,
                icon: i == 0
                    ? Icons.apps
                    : selected
                        ? Icons.check
                        : Icons.category_outlined,
                label: i == 0 ? tr('All genres') : _genreName(g),
                active: selected,
                onTap: () => Navigator.of(ctx).pop(g),
              );
            },
          ),
        ),
      ),
    );
    if (picked == null || !mounted || type != _type) return;
    await _applyGenre(service, picked.isEmpty ? null : picked);
  }

  /// Shows [genre]'s rows (null = all) from the top.
  Future<void> _applyGenre(ArchiveService service, String? genre) async {
    final type = _type;
    setState(() {
      _focusedRow = 0;
      _focusedRowKey = null;
      _focused = null;
      _focusedLabel = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    await service.setGenre(type, genre);
  }

  /// Search for the current category: a field plus that category's recent
  /// searches as one-press pills (the first focused when there are any, so
  /// the keyboard doesn't open by itself).
  Future<void> _openSearch(ArchiveService service) async {
    final type = _type;
    final query = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _SearchPanel(
        title: type == ArchiveType.movie
            ? tr('Search movies')
            : tr('Search TV shows'),
        initial: service.searchQuery(type) ?? '',
        recent: service.recentSearches(type),
        onForgetRecent: () => service.forgetRecentSearches(type),
      ),
    );
    if (query == null || query.trim().isEmpty || !mounted) return;
    setState(() => _focusedRow = 0);
    if (_scroll.hasClients) _scroll.jumpTo(0);
    await service.search(type, query);
    if (!mounted || type != _type) return;
    if (!_railSearchNode.hasFocus ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final rows = service.rows(type);
    if (rows.isNotEmpty && rows.first.isSearch) {
      _lastIndex[rows.first.key] = 0;
      _rowScrolls[rows.first.key]?.jumpTo(0);
      _focusRow(rows, 0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(tr('No results for "{query}"', {'query': query.trim()}))));
    }
  }

  /// Search on a wide screen lives in the left rail: it pulls a small menu
  /// out to its right (Movies / TV Shows), then opens that category's search.
  /// A category no source can search isn't offered.
  Future<void> _pickSearchType(ArchiveService service) async {
    final types = [
      for (final t in ArchiveType.values)
        if (service.canSearch(t)) t,
    ];
    if (types.isEmpty) return;
    _railPinned = true;
    try {
      await _searchFromRail(service, types);
    } finally {
      _railPinned = false;
      _onRailFocus();
    }
  }

  Future<void> _searchFromRail(
      ArchiveService service, List<ArchiveType> types) async {
    final anchor = rollDownAnchorOf(_railSearchNode.context);
    final type = types.length == 1
        ? types.first
        : await showRollDownMenu<ArchiveType>(
            context,
            // Beside the button, not under it (the menu sits 8 px below its
            // anchor's bottom).
            anchor: anchor == null
                ? null
                : Rect.fromLTWH(anchor.right + 6, anchor.top - 8, 1, 0),
            centered: false,
            width: 220,
            title: tr('Search'),
            items: [
              for (final t in types)
                RollDownMenuItem(
                    value: t,
                    icon: t == ArchiveType.movie
                        ? Icons.movie
                        : Icons.video_library,
                    label:
                        t == ArchiveType.movie ? tr('Movies') : tr('TV Shows'),
                    selected: t == _type),
            ],
          );
    if (!mounted) return;
    _railSearchNode.requestFocus();
    if (type == null) return;
    _setType(type);
    await _openSearch(service);
  }

  Future<void> _chooseSearchSource(ArchiveService service) async {
    final picked = await showDialog<String>(
        context: context,
        builder: (ctx) => AnimatedBuilder(
            animation: service,
            builder: (_, child) =>
                SimpleDialog(title: Text(tr('Search sources')), children: [
                  SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, ''),
                      child: Text(tr('All sources'))),
                  for (final entry in service.searchStates(_type).entries)
                    SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, entry.key),
                        child: Text(
                            '${service.searchSourceNames(_type)[entry.key] ?? ''} · ${switch (entry.value) {
                          ArchiveSourceStatus.loading => tr('Loading'),
                          ArchiveSourceStatus.ready => tr('Results'),
                          ArchiveSourceStatus.empty => tr('No results'),
                          ArchiveSourceStatus.failed => tr('Unavailable'),
                        }}'))
                ])));
    if (!mounted || picked == null) return;
    service.selectSearchSource(_type, picked.isEmpty ? null : picked);
    _focusBarNode(_barSourceNode);
  }

  void _clearSearch(ArchiveService service) {
    setState(() => _focusedRow = 0);
    if (_scroll.hasClients) _scroll.jumpTo(0);
    service.clearSearch(_type);
  }

  void _setType(ArchiveType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _focusedRow = 0;
      _focusedRowKey = null;
      _focused = null;
      _focusedLabel = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  /// Focuses row [r]'s remembered card and scrolls the row into view.
  void _focusRow(List<ArchiveRow> rows, int r) {
    if (rows.isEmpty) return;
    r = r.clamp(0, rows.length - 1);
    final row = rows[r];
    final i = (_lastIndex[row.key] ?? 0).clamp(0, row.items.length - 1);
    final ctx = _rowKey(row.key).currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, alignment: 0.05);
    } else if (_scroll.hasClients) {
      // Lazy rows have no context yet. Materialize the destination first,
      // including long jumps from the catalog buttons in the floating bar.
      _scroll.jumpTo(
          (r * _rowExtent).clamp(0.0, _scroll.position.maxScrollExtent));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusCard(row, i);
    });
  }

  KeyEventResult _onContentKey(
      List<ArchiveRow> rows, FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (rows.isEmpty) return KeyEventResult.ignored;
    final row = rows[_focusedRow.clamp(0, rows.length - 1)];
    final i = _lastIndex[row.key] ?? 0;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      if (_focusedRow < rows.length - 1) _focusRow(rows, _focusedRow + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_focusedRow > 0) {
        _focusRow(rows, _focusedRow - 1);
      } else {
        _focusBar();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      if (i < row.items.length - 1) _focusCard(row, i + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (i > 0) {
        _focusCard(row, i - 1);
      } else {
        _railScope.requestFocus();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Shows open the regular series page (episode cards, Play SxEy);
  /// movies the Archive movie page.
  void _refreshHistoryProgress() {
    if (!mounted) return;
    setState(() {});
    _progressRefresh?.cancel();
    _progressRefresh = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _openContinuation(ArchiveContinueItem item) async {
    await openArchiveContinuation(context, item);
    _refreshHistoryProgress();
  }

  Future<void> _open(ArchiveSource source, ArchiveMeta meta) async {
    if (meta.type == ArchiveType.series) {
      await openArchiveSeries(context, source, meta);
    } else {
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ArchiveDetailScreen(source: source, preview: meta)));
    }
    _refreshHistoryProgress();
  }

  void _openSources() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ArchiveSourcesScreen()));
  }

  /// Sign in to a Jellyfin/Emby server; its libraries become rows.
  void _connectMediaServer() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MediaServerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ArchiveService>();
    final rows = service.rows(_type);
    final keptRow = rows.indexWhere((row) => row.key == _focusedRowKey);
    if (keptRow >= 0 && _contentScope.hasFocus) _focusedRow = keptRow;
    final narrow = MediaQuery.sizeOf(context).width < 700;
    final scheme = Theme.of(context).colorScheme;

    final focused = _focused;
    final backdrop = focused?.backgroundUrl ?? focused?.posterUrl;

    return PopScope(
      // Back from the rows (or the bar) goes to the rail first, then leaves.
      canPop: !_awayFromRail,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_awayFromRail) {
          _railScope.requestFocus();
        } else {
          // canPop was stale (built while the rows had focus): leave anyway.
          Navigator.of(context).pop();
        }
      },
      // Windows has no remote Back: Esc does what Back does (rows -> rail ->
      // leave), plus a clickable arrow in the rail (user report: no way
      // back to the main UI). Same as SportsScreenFrame / SportsBackButton.
      child: CallbackShortcuts(
        bindings: {
          if (Platform.isWindows)
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.of(context).maybePop(),
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              if (backdrop != null)
                Positioned(
                  top: 0,
                  right: 0,
                  // Nuvio-style: the backdrop fills the top right and fades
                  // into black under the hero text and the first row.
                  left: narrow ? 0 : MediaQuery.sizeOf(context).width * 0.3,
                  height:
                      MediaQuery.sizeOf(context).height * (narrow ? 0.6 : 0.7),
                  child: DetailBackdrop(url: backdrop, fadeLeft: true),
                ),
              SafeArea(
                child: narrow
                    ? Column(children: [
                        _buildTopBar(service),
                        _buildFloatingBar(service, rows),
                        Expanded(child: _buildContent(service, rows, scheme)),
                      ])
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Open, the rail pushes the hero and rows aside
                          // (owner, +553: never over the posters); closed,
                          // they get the room back.
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            width: _railOpen ? _railWide : _railSlim,
                            child: ClipRect(child: _buildRail(service, rows)),
                          ),
                          Expanded(
                            child: Column(children: [
                              _buildFloatingBar(service, rows),
                              Expanded(
                                  child: _buildContent(service, rows, scheme)),
                            ]),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRail(ArchiveService service, List<ArchiveRow> rows) {
    return FocusScope(
      node: _railScope,
      child: Focus(
        // Right from anywhere in the rail = into the rows.
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (rows.isNotEmpty) {
              _focusRow(rows, _focusedRow);
            } else if (_emptyActionNode.context != null) {
              _emptyActionNode.requestFocus();
            }
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        // The same floating glass pill as the top bar (owner, 2026-11-01),
        // stood up: Search (pulls out Movies / TV Shows), the two
        // categories, then Refresh and the sources. Closed: icons only.
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 16, 4, 16),
          children: [
            SizedBox(
              height: 48,
              child: Row(children: [
                if (Platform.isWindows)
                  ExcludeFocus(
                    child: IconButton(
                      tooltip: tr('Back'),
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                if (_railOpen)
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(tr('Media Hub'),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        softWrap: false,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  )),
              ]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: _glassPill(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (ArchiveType.values.any(service.canSearch)) ...[
                    _railButton(
                      node: _railSearchNode,
                      icon: Icons.search,
                      label:
                          service.searching ? tr('Searching…') : tr('Search'),
                      active: ArchiveType.values
                          .any((t) => service.searchQuery(t) != null),
                      onTap: () => _pickSearchType(service),
                    ),
                    _railDivider(),
                  ],
                  _railButton(
                    node: _firstRailNode,
                    icon: Icons.movie,
                    label: tr('Movies'),
                    active: _type == ArchiveType.movie,
                    onTap: () => _setType(ArchiveType.movie),
                  ),
                  _railButton(
                    icon: Icons.video_library,
                    label: tr('TV Shows'),
                    active: _type == ArchiveType.series,
                    onTap: () => _setType(ArchiveType.series),
                  ),
                  _railDivider(),
                  _railButton(
                    icon: Icons.refresh,
                    label: service.refreshing ? tr('Updating…') : tr('Refresh'),
                    onTap: () => service.refresh(force: true, manifests: true),
                  ),
                  _railButton(
                    icon: Icons.extension_outlined,
                    label: tr('Media Hub sources'),
                    onTap: _openSources,
                  ),
                  _railButton(
                    icon: Icons.dns_outlined,
                    label: tr('Connect Jellyfin / Emby'),
                    onTap: _connectMediaServer,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A rail entry: icon + label while the rail is open, the icon alone
  /// (label as tooltip, for the mouse) while it is closed.
  Widget _railButton({
    FocusNode? node,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) =>
      _BarButton(
        focusNode: node,
        icon: icon,
        label: _railOpen ? label : null,
        tooltip: _railOpen ? null : label,
        expand: true,
        alignStart: _railOpen,
        dense: true,
        active: active,
        onTap: onTap,
      );

  /// The floating bar's look: dark glass, hairline border, soft shadow.
  static BoxDecoration _glassPill(double radius) => BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.04),
        ]),
        color: Colors.black,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white24),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 12),
        ],
      );

  Widget _railDivider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        color: Colors.white24,
      );

  /// Phone / narrow window: the rail's two choices + sources as a row.
  Widget _buildTopBar(ArchiveService service) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: FocusScope(
        node: _railScope,
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _RailTile(
                  focusNode: _firstRailNode,
                  icon: Icons.movie,
                  label: tr('Movies'),
                  selected: _type == ArchiveType.movie,
                  onTap: () => _setType(ArchiveType.movie),
                ),
                const SizedBox(width: 8),
                _RailTile(
                  icon: Icons.video_library,
                  label: tr('TV Shows'),
                  selected: _type == ArchiveType.series,
                  onTap: () => _setType(ArchiveType.series),
                ),
              ]),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => service.refresh(force: true, manifests: true),
          ),
          IconButton(
            icon: const Icon(Icons.extension_outlined),
            onPressed: _openSources,
          ),
          IconButton(
            tooltip: tr('Connect Jellyfin / Emby'),
            icon: const Icon(Icons.dns_outlined),
            onPressed: _connectMediaServer,
          ),
        ]),
      ),
    );
  }

  /// Rows that get a jump button in the floating bar: all but search
  /// results (the lit Search button stands for those).
  List<int> _barRows(List<ArchiveRow> rows) => [
        for (var r = 0; r < rows.length; r++)
          if (!rows[r].isSearch) r,
      ];

  /// Hold OK (or long-press) on a row's jump button: a small menu rolls
  /// down under it — Expand catalog (the whole row as a poster grid,
  /// [ArchiveCatalogScreen], like the IPTV groups' hold menu) or Go to row.
  Future<void> _showRowMenu(List<ArchiveRow> rows, int r) async {
    final row = rows[r];
    final anchorNode = _barRowNode(row.key);
    final title = _barRowLabel(row);
    final choice = await showRollDownMenu<String>(
      context,
      anchor: rollDownAnchorOf(anchorNode.context),
      title: title,
      items: [
        RollDownMenuItem(
            value: 'expand',
            icon: Icons.grid_view_rounded,
            label: tr('Expand catalog')),
        RollDownMenuItem(
            value: 'row', icon: Icons.south, label: tr('Go to row')),
        RollDownMenuItem(
            value: 'customize', icon: Icons.tune, label: tr('Customize rows')),
        RollDownMenuItem(
            value: 'rename',
            icon: Icons.edit_outlined,
            label: tr('Rename row')),
        if (row.continuations == null) ...[
          RollDownMenuItem(
              value: 'up', icon: Icons.arrow_upward, label: tr('Move up')),
          RollDownMenuItem(
              value: 'down',
              icon: Icons.arrow_downward,
              label: tr('Move down')),
          RollDownMenuItem(
              value: 'pin',
              icon: Icons.push_pin_outlined,
              label: tr('Pin row')),
        ],
        RollDownMenuItem(
            value: 'hide', icon: Icons.visibility_off, label: tr('Hide row')),
      ],
    );
    if (!mounted) return;
    final service = context.read<ArchiveService>();
    if (['customize', 'rename', 'up', 'down', 'pin', 'hide'].contains(choice)) {
      switch (choice) {
        case 'customize':
          await showArchiveRowSettings(context, _type);
        case 'rename':
          await renameArchiveRow(context, row);
        case 'up':
          await service.moveRow(_type, row.key, -1);
        case 'down':
          await service.moveRow(_type, row.key, 1);
        case 'pin':
          await service.setRowFlag(
              row.key, 'pinned', !service.rowPinned(row.key));
        case 'hide':
          await service.setRowFlag(row.key, 'hidden', true);
      }
      if (mounted) _focusBarNode(_barManageNode);
      return;
    }
    switch (choice) {
      case 'expand':
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ArchiveCatalogScreen(
                type: row.catalog.type, rowKey: row.key, title: title)));
        // Back lands on the button that opened it, not wherever Flutter's
        // focus restoration guesses (CLAUDE.md §10: explicit beats default).
        if (mounted && anchorNode.context != null) _focusBarNode(anchorNode);
      case 'row':
        _focusRow(rows, r);
      default:
        if (anchorNode.context != null) _focusBarNode(anchorNode);
    }
  }

  FocusNode _barRowNode(String rowKey) => _barRowNodes.putIfAbsent(
      rowKey, () => FocusNode(debugLabel: 'archive-bar-row'));

  /// A row's jump label: its own title, without the " · Genre" suffix
  /// (the Genre button shows that).
  String _barRowLabel(ArchiveRow row) {
    if (row.customTitle != null) return row.customTitle!;
    if (row.continuations != null) return tr(row.title);
    if (row.isHistory) return tr('Recently watched');
    if (row.isFavorites) return tr('Favourites');
    return row.source.streamOnly || row.source.tracker != null
        ? tr(row.title)
        : row.title;
  }

  /// The floating bar's buttons, in order (for explicit Left/Right).
  List<FocusNode> _barNodes(ArchiveService service, List<ArchiveRow> rows) => [
        if (_showNewest(service)) _barNewestNode,
        if (_narrow && service.canSearch(_type)) _railSearchNode,
        if (service.searchQuery(_type) != null) ...[
          _barSourceNode,
          _barClearNode
        ],
        if (service.genre(_type) == ArchiveService.otherGenre) _barBackNode,
        for (final r in _barRows(rows)) _barRowNode(rows[r].key),
        if (service.genres(_type).isNotEmpty) _barGenreNode,
        _barManageNode,
      ];

  /// The Newest button: only when a source has a release-year catalog, and
  /// not under Other (custom catalogs have none).
  bool _showNewest(ArchiveService service) =>
      service.genre(_type) != ArchiveService.otherGenre &&
      service.canNewest(_type);

  /// Newest on/off: new releases only (narrowed by the genre, if any).
  Future<void> _toggleNewest(ArchiveService service) async {
    final type = _type;
    setState(() {
      _focusedRow = 0;
      _focusedRowKey = null;
      _focused = null;
      _focusedLabel = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    await service.setNewest(type, !service.newest(type));
  }

  /// Up into the bar lands on the current row's jump button (else the
  /// first button).
  void _focusBar() {
    final service = context.read<ArchiveService>();
    final rows = service.rows(_type);
    final nodes = _barNodes(service, rows);
    if (nodes.isEmpty) return;
    final r = _focusedRow;
    final current = r >= 0 && r < rows.length && !rows[r].isSearch
        ? _barRowNodes[rows[r].key]
        : null;
    _focusBarNode(current ?? nodes.first);
  }

  /// The bar scrolls sideways when a source has many catalogs: bring the
  /// newly focused button into view.
  void _focusBarNode(FocusNode node) {
    node.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = node.context;
      if (mounted && ctx != null) {
        Scrollable.ensureVisible(ctx, alignment: 0.5);
      }
    });
  }

  /// Search, then the category's row jumps (Popular / New / Featured /
  /// Recently watched...) and Genre, centred at the top in the phone
  /// tab bar's floating pill. D-pad: Left/Right along it (Left past the
  /// first = rail), Down = the rows.
  Widget _buildFloatingBar(ArchiveService service, List<ArchiveRow> rows) {
    final nodes = _barNodes(service, rows);
    if (nodes.isEmpty) return const SizedBox.shrink();
    final narrow = MediaQuery.sizeOf(context).width < 700;
    final barRows = _barRows(rows);
    final canSearch = service.canSearch(_type);
    final hasGenres = service.genres(_type).isNotEmpty;
    final other = service.genre(_type) == ArchiveService.otherGenre;
    void move(int delta) {
      final i = nodes.indexWhere((n) => n.hasFocus);
      final to = i + delta;
      if (to >= 0 && to < nodes.length) {
        _focusBarNode(nodes[to]);
      } else if (to < 0 && !narrow) {
        _railScope.requestFocus();
      }
    }

    final query = service.searchQuery(_type);
    final genre = service.genre(_type);
    final movies = _type == ArchiveType.movie;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Center(
        child: FocusScope(
          node: _barScope,
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                  move(-1),
              const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                  move(1),
              const SingleActivator(LogicalKeyboardKey.arrowDown): () {
                if (rows.isNotEmpty) {
                  _focusRow(rows, _focusedRow);
                } else if (_emptyActionNode.context != null) {
                  _emptyActionNode.requestFocus();
                }
              },
              const SingleActivator(LogicalKeyboardKey.arrowUp): () {},
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: _glassPill(34),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Newest leads the bar (owner, 2026-10-28), then
                    // Search, the row jumps and Genre.
                    if (_showNewest(service)) ...[
                      _BarButton(
                        focusNode: _barNewestNode,
                        icon: Icons.new_releases_outlined,
                        label: tr('Newest'),
                        active: service.newest(_type),
                        onTap: () => _toggleNewest(service),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        color: Colors.white24,
                      ),
                    ],
                    if (canSearch && _narrow)
                      _BarButton(
                        focusNode: _railSearchNode,
                        icon: Icons.search,
                        label: service.searching
                            ? tr('Searching…')
                            : query ??
                                (movies
                                    ? tr('Search movies')
                                    : tr('Search TV shows')),
                        active: query != null,
                        onTap: () => _openSearch(service),
                      ),
                    if (query != null)
                      _BarButton(
                          focusNode: _barSourceNode,
                          icon: Icons.filter_list,
                          label: service.searching
                              ? tr('Sources · searching…')
                              : tr('Sources'),
                          onTap: () => _chooseSearchSource(service)),
                    if (query != null)
                      _BarButton(
                        focusNode: _barClearNode,
                        icon: Icons.close,
                        // Wide screens: the rail's Search button no longer
                        // shows the query, so this one does.
                        label: _narrow ? null : '"$query"',
                        tooltip: tr('Clear search'),
                        onTap: () {
                          _clearSearch(service);
                          _focusBarNode(_railSearchNode);
                        },
                      ),
                    if ((canSearch || query != null) &&
                        (other || barRows.isNotEmpty || hasGenres))
                      Container(
                        width: 1,
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        color: Colors.white24,
                      ),
                    // Under Other, its many category buttons pushed Genre
                    // far to the right: leaving Other comes right after
                    // Search (user request, 2026-10-20).
                    if (other) ...[
                      _BarButton(
                        focusNode: _barBackNode,
                        icon: Icons.arrow_back,
                        label: tr('Back to main'),
                        onTap: () async {
                          await _applyGenre(service, null);
                          if (mounted) _focusBar();
                        },
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        color: Colors.white24,
                      ),
                    ],
                    for (final r in barRows)
                      _BarButton(
                        focusNode: _barRowNode(rows[r].key),
                        icon: rows[r].isHistory
                            ? Icons.history
                            : rows[r].isFavorites
                                ? Icons.star_outline
                                : Icons.grid_view_rounded,
                        label: _barRowLabel(rows[r]),
                        onTap: () => _focusRow(rows, r),
                        onHold: () => _showRowMenu(rows, r),
                      ),
                    if (barRows.isNotEmpty && hasGenres)
                      Container(
                        width: 1,
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        color: Colors.white24,
                      ),
                    if (hasGenres)
                      _BarButton(
                        focusNode: _barGenreNode,
                        icon: Icons.category_outlined,
                        label: genre == null
                            ? (movies
                                ? tr('Movie genres')
                                : tr('TV show genres'))
                            : _genreName(genre),
                        active: genre != null,
                        onTap: () => _pickGenre(service),
                      ),
                    _BarButton(
                        focusNode: _barManageNode,
                        icon: Icons.tune,
                        label: tr('Customize'),
                        onTap: () async {
                          await showArchiveRowSettings(context, _type);
                          if (mounted) _focusBarNode(_barManageNode);
                        }),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      ArchiveService service, List<ArchiveRow> rows, ColorScheme scheme) {
    if (service.sources.isEmpty) {
      return _EmptyState(
        text: tr(
            'Add a source to browse films and series. Any source that follows the catalog/stream add-on format works.'),
        action: tr('Add a source'),
        onAction: _openSources,
        focusNode: _emptyActionNode,
      );
    }
    if (rows.isEmpty) {
      if (service.refreshing) {
        return const Center(child: CircularProgressIndicator());
      }
      return _EmptyState(
        text: service.hasAny(_type)
            ? (service.lastError != null
                ? tr("Couldn't load the catalog: {error}",
                    {'error': service.lastError})
                : tr('Nothing here yet.'))
            : (_type == ArchiveType.movie
                ? tr('None of your sources has movies.')
                : tr('None of your sources has TV shows.')),
        action: tr('Refresh'),
        onAction: () => service.refresh(force: true, manifests: true),
        focusNode: _emptyActionNode,
        onUp: _focusBar,
      );
    }

    final focused = _focused;
    final narrow = MediaQuery.sizeOf(context).width < 700;
    return FocusScope(
      node: _contentScope,
      child: Focus(
        onKeyEvent: (node, e) => _onContentKey(rows, node, e),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero: the focused title, Nuvio style (owner, 2026-11-01):
            // title logo, one info line with the IMDb rating, 4 lines of
            // description. Sized so a TV shows one row plus the next one's
            // top, which tells the user there is more below.
            SizedBox(
              height: narrow ? 150 : 200,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: focused == null
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroTitle(
                              key: ValueKey(focused.id),
                              meta: focused,
                              height: narrow ? 36 : 64),
                          const SizedBox(height: 8),
                          _HeroInfoLine(
                              meta: focused,
                              sourceLabel: _focusedLabel,
                              imdbRating: !_focusedFromServer),
                          const SizedBox(height: 8),
                          if (focused.description != null)
                            Flexible(
                              child: SizedBox(
                                width: 520,
                                child: Text(focused.description!,
                                    maxLines: narrow ? 2 : 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.35,
                                        color: Colors.white70)),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.only(bottom: 40),
                itemExtent: _rowExtent,
                scrollCacheExtent: ScrollCacheExtent.pixels(_rowExtent),
                itemCount: rows.length,
                findChildIndexCallback: (key) {
                  final index =
                      rows.indexWhere((row) => _rowKeys[row.key] == key);
                  return index < 0 ? null : index;
                },
                itemBuilder: (_, r) => _buildRow(service, rows, r, scheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(ArchiveService service, List<ArchiveRow> rows, int r,
      ColorScheme scheme) {
    final row = rows[r];
    final wideAt = _wideIndex(row);
    return Column(
      key: _rowKey(row.key),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _rowHeaderHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
            child: Text(_rowTitle(service, row),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: r == _focusedRow && _contentScope.hasFocus
                        ? scheme.primary
                        : Colors.white)),
          ),
        ),
        SizedBox(
          height: PosterCard.height + 16,
          child: ListView.builder(
            controller: _rowScroll(row.key),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: _rowPadding),
            // Exact slot width: [_focusCard]'s jump lands where the card
            // really is, even far past the built ones (the TV tab's rows
            // do the same, see `_categoryRowHeight`). Cards ~5 ahead are
            // built early, so Right always finds the next one ready. Always
            // a builder (never switching to itemExtent): another sliver type
            // would rebuild the cards and drop the focus.
            itemExtentBuilder: _extentBuilder(row.key, wideAt),
            scrollCacheExtent: const ScrollCacheExtent.pixels(_cardExtent * 5),
            itemCount: row.items.length,
            itemBuilder: (_, i) {
              final meta = row.items[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ValueListenableBuilder<Set<String>>(
                  valueListenable: ArchiveReadyWatch.instance.tags,
                  builder: (context, ready, _) => PosterCard(
                    ready: ready.contains(meta.id),
                    fetching: ArchiveReadyWatch.instance.fetching.value
                        .contains(meta.id),
                    focusNode: _node(row.key, i),
                    title: meta.name,
                    imageUrl: meta.posterUrl,
                    wideWidth: i == wideAt ? PosterCard.wideCardWidth : null,
                    wideImageUrl: meta.backgroundUrl,
                    wideLogoUrl: meta.logo,
                    rating: row.continuations != null
                        ? (row.continuations![i].episodeLabel.isNotEmpty
                            ? row.continuations![i].episodeLabel
                            : meta.year)
                        : meta.year,
                    progressFraction: row.continuations?[i].progress,
                    sourceLabel: row.continuations != null
                        ? (row.upcoming
                            ? tr('Airs {date}', {
                                'date':
                                    (row.continuations![i].episode?.released ??
                                            '')
                                        .split('T')
                                        .first
                              })
                            : row.continuations![i].resume
                                ? tr('Resume')
                                : meta.type == ArchiveType.movie
                                    ? tr('Play')
                                    : row.continuations![i].episode == null
                                        ? tr('Continue series')
                                        : tr('Next episode'))
                        : null,
                    tapToPreview:
                        Theme.of(context).platform == TargetPlatform.android &&
                            MediaQuery.sizeOf(context).width < 700,
                    onTap: () => row.continuations != null
                        ? _openContinuation(row.continuations![i])
                        : _open(row.sourceAt(i), meta),
                    isFavorite: context
                        .read<ArchiveService>()
                        .isFavorite(row.sourceAt(i), meta),
                    onToggleFavorite: () =>
                        holdArchiveTitle(context, row, row.sourceAt(i), meta),
                    onFocusGained: () {
                      service.prioritizeRow(row);
                      service.retainSearchFocus(row);
                      _focusedRowKey = row.key;
                      _lastIndex[row.key] = i;
                      if (i >= row.items.length - 12) {
                        context.read<ArchiveService>().loadMore(row);
                      }
                      if (_focused?.id == meta.id &&
                          _focusedRow == r &&
                          wideAt == i) {
                        return;
                      }
                      setState(() {
                        _focusedRow = r;
                        _focused = meta;
                        _focusedLabel = row.labelAt(i);
                        _focusedFromServer = row.sourceAt(i).server != null;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A button of the floating Search / Genre bar: the phone tab bar's pill
/// look, gold outline when focused, lit when its filter is on.
class _BarButton extends StatefulWidget {
  const _BarButton({
    this.focusNode,
    required this.icon,
    required this.onTap,
    this.label,
    this.tooltip,
    this.active = false,
    this.autofocus = false,
    this.expand = false,
    this.alignStart = false,
    this.dense = false,
    this.onHold,
  });

  final FocusNode? focusNode;

  /// Hold OK / long-press (a row button's menu); null = no hold action.
  final VoidCallback? onHold;
  final bool autofocus;

  /// Fill the width (grid cells), content centred.
  final bool expand;

  /// With [expand]: content at the start (the rail), not centred.
  final bool alignStart;

  /// The rail's tighter padding.
  final bool dense;
  final IconData icon;
  final String? label;
  final String? tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_BarButton> createState() => _BarButtonState();
}

class _BarButtonState extends State<_BarButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lit = _focused || widget.active;
    final button = InkWell(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (f) => setState(() => _focused = f),
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(28),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
            horizontal: widget.label == null ? 10 : (widget.dense ? 12 : 18),
            vertical: widget.dense ? 8 : 9),
        decoration: BoxDecoration(
          color:
              lit ? Colors.white.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: _focused
                  ? scheme.primary
                  : widget.active
                      ? Colors.white24
                      : Colors.transparent,
              width: _focused ? 2 : 1),
        ),
        child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: widget.alignStart
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(widget.icon,
                  size: 20, color: lit ? scheme.primary : Colors.white70),
              if (widget.label != null) ...[
                const SizedBox(width: 8),
                // Grid cells and the rail give the label the room that is
                // left (ellipsis); a lone pill sizes to its text.
                Flexible(
                    child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: widget.expand ? double.infinity : 220),
                  child: Text(widget.label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: lit ? Colors.white : Colors.white70,
                          fontSize: 14,
                          fontWeight: widget.active
                              ? FontWeight.w700
                              : FontWeight.w500)),
                )),
              ],
            ]),
      ),
    );
    final held = widget.onHold == null
        ? button
        : HoldToActivate(
            onTap: widget.onTap, onHold: widget.onHold, child: button);
    return widget.tooltip == null
        ? held
        : Tooltip(message: widget.tooltip!, child: held);
  }
}

/// A dialog in the floating bar's style: the same dark gradient pill
/// shape, rounded, with a title.
class _FloatingPanel extends StatelessWidget {
  const _FloatingPanel(
      {required this.title, required this.child, this.width = 520});

  final String title;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: width,
            maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            color: const Color(0xF20D0D10),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white24),
            boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 24)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 14),
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Search box + the category's recent searches. Pops the query to search.
class _SearchPanel extends StatefulWidget {
  const _SearchPanel({
    required this.title,
    required this.initial,
    required this.recent,
    required this.onForgetRecent,
  });

  final String title;
  final String initial;
  final List<String> recent;
  final Future<void> Function() onForgetRecent;

  @override
  State<_SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<_SearchPanel> {
  late final _controller = TextEditingController(text: widget.initial);
  final _fieldNode = FocusNode(debugLabel: 'archive-search-field');
  final _firstRecentNode = FocusNode(debugLabel: 'archive-search-recent');
  late List<String> _recent = widget.recent;

  @override
  void dispose() {
    _controller.dispose();
    _fieldNode.dispose();
    _firstRecentNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _FloatingPanel(
      title: widget.title,
      child: Flexible(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Down from the field = the recent searches (a text field
              // keeps the arrows otherwise).
              CallbackShortcuts(
                bindings: {
                  if (_recent.isNotEmpty)
                    const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                        _firstRecentNode.requestFocus(),
                },
                child: TvTextFieldGate(
                  focusNode: _fieldNode,
                  builder: (context, readOnly) => TextField(
                    controller: _controller,
                    focusNode: _fieldNode,
                    readOnly: readOnly,
                    autofocus: _recent.isEmpty,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: tr('Title'),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide(color: scheme.primary, width: 2),
                      ),
                    ),
                    onSubmitted: (v) => Navigator.of(context).pop(v),
                  ),
                ),
              ),
              if (_recent.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                  child: Text(tr('Recent searches'),
                      style:
                          const TextStyle(fontSize: 13, color: Colors.white54)),
                ),
                for (final (i, q) in _recent.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _BarButton(
                      focusNode: i == 0 ? _firstRecentNode : null,
                      autofocus: i == 0,
                      expand: true,
                      icon: Icons.history,
                      label: q,
                      onTap: () => Navigator.of(context).pop(q),
                    ),
                  ),
                _BarButton(
                  expand: true,
                  icon: Icons.delete_outline,
                  label: tr('Clear recent searches'),
                  onTap: () async {
                    await widget.onForgetRecent();
                    if (!mounted) return;
                    setState(() => _recent = const []);
                    _fieldNode.requestFocus();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A rail row: same focus look as the detail pages' pills.
class _RailTile extends StatefulWidget {
  const _RailTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.focusNode,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final FocusNode? focusNode;

  @override
  State<_RailTile> createState() => _RailTileState();
}

class _RailTileState extends State<_RailTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = (_focused || widget.selected) ? scheme.primary : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        focusNode: widget.focusNode,
        onFocusChange: (f) => setState(() => _focused = f),
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: detailFocusDecoration(scheme,
              focused: _focused, selected: widget.selected, radius: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 20, color: fg),
            const SizedBox(width: 10),
            Flexible(
              child: Text(widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: fg,
                      fontSize: 15,
                      fontWeight:
                          widget.selected ? FontWeight.w700 : FontWeight.w500)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.text,
      required this.action,
      required this.onAction,
      required this.focusNode,
      this.onUp});

  final FocusNode focusNode;
  final VoidCallback? onUp;
  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.local_movies_outlined,
              size: 48, color: Colors.white38),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
          ),
          const SizedBox(height: 16),
          CallbackShortcuts(
            bindings: {
              if (onUp != null)
                const SingleActivator(LogicalKeyboardKey.arrowUp): onUp!,
            },
            child: OutlinedButton(
                focusNode: focusNode, onPressed: onAction, child: Text(action)),
          ),
        ]),
      ),
    );
  }
}

/// The hero's title: the title's logo art (Nuvio style), else its name.
class _HeroTitle extends StatelessWidget {
  const _HeroTitle({super.key, required this.meta, required this.height});

  final ArchiveMeta meta;
  final double height;

  /// Logo URLs that failed (MetaHub has no logo for many titles): those
  /// show the name at once on the next visit instead of retrying.
  static final Set<String> _failed = {};

  @override
  Widget build(BuildContext context) {
    final name = Align(
      alignment: Alignment.bottomLeft,
      child: Text(meta.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: height >= 60 ? 30 : 24, fontWeight: FontWeight.w700)),
    );
    final logo = meta.logo;
    return SizedBox(
      height: height,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: logo == null || _failed.contains(logo)
            ? name
            : HdNetworkImage(
                url: logo,
                kind: ImageKind.poster,
                fit: BoxFit.contain,
                alignment: Alignment.bottomLeft,
                decodeWidth:
                    HdNetworkImage.cardDecodeWidth(context, 360, oversample: 1),
                fadeInDuration: const Duration(milliseconds: 200),
                onFailed: () => _failed.add(logo),
                errorWidget: (_) => name,
              ),
      ),
    );
  }
}

/// "Movie • Horror • 2026" plus the rating badge and the source chip.
class _HeroInfoLine extends StatelessWidget {
  const _HeroInfoLine({
    required this.meta,
    required this.sourceLabel,
    required this.imdbRating,
  });

  final ArchiveMeta meta;
  final String? sourceLabel;

  /// The rating is IMDb's (add-ons send `imdbRating`); a media server's
  /// community rating gets a plain star instead.
  final bool imdbRating;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white);
    final parts = [
      meta.type == ArchiveType.movie ? tr('Movie') : tr('Series'),
      ...meta.genres.take(2),
      if (meta.year != null) meta.year!,
      if (meta.runtime != null) meta.runtime!,
    ];
    final rating = meta.rating;
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(parts.join('  •  '), style: style),
        if (rating != null)
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (imdbRating)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5C518),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text('IMDb',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w900)),
              )
            else
              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
            const SizedBox(width: 5),
            Text(rating, style: style),
          ]),
        if (sourceLabel != null) DetailMetaChip(scale: 1, label: sourceLabel!),
      ],
    );
  }
}
