import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/channel.dart';
import '../models/xtream_series.dart';
import '../services/catalog_database.dart';
import '../services/playlist_manager.dart';
import '../services/storage_service.dart';
import '../services/tmdb_enrichment_service.dart';
import '../utils/catalog_sort.dart';
import '../utils/tv_theme.dart';
import '../utils/display_title.dart';
import '../widgets/detail_header.dart';
import '../widgets/poster_card.dart';
import 'movie_detail_screen.dart';
import 'series_detail_screen.dart';
import '../l10n/l10n.dart';

/// A single movies/TV-shows group expanded into its own full poster grid —
/// "Expand catalog" on a group's hold-Select menu (see
/// `TvHomeScreen._showGroupOptions`). Previously the only way to see a
/// group laid out this way (rather than one horizontal row in the normal
/// browse view) was to favorite it and go find it under the Favorites tab
/// — reported directly as a roundabout way to do something that should
/// just be available on any group directly. A real pushed route rather
/// than new state folded into `TvHomeScreen` — the physical Back button
/// popping back to the normal browse view is then just how `Navigator`
/// already behaves, no new link needed in that screen's own, already
/// intricate content → groups → tabs back-handling chain.
class GroupCatalogScreen extends StatefulWidget {
  const GroupCatalogScreen({
    super.key,
    required this.category,
    required this.playlistId,
    required this.title,
  });

  /// 'vod' or 'series'.
  final String category;
  final String playlistId;
  final String title;

  @override
  State<GroupCatalogScreen> createState() => _GroupCatalogScreenState();
}

class _GroupCatalogScreenState extends State<GroupCatalogScreen> {
  /// Explicit initial focus target, not Flutter's default guess — reported
  /// directly: on entry, focus landed "at the bottom of the screen"
  /// instead of near the top-left title/back button. `GridView.builder` is
  /// lazy, so at push time only whatever's already visible is realized as
  /// focusable at all, and Flutter's default initial-focus scan apparently
  /// resolved to one of those grid items rather than the AppBar. Same
  /// "explicit beats default" fix already used for this screen's own
  /// back-focus bug (`TvHomeScreen._showGroupOptions`'s `.then()`).
  final FocusNode _backButtonFocus = FocusNode();

  /// Defaults to whatever order the provider sent (`none`) rather than
  /// forcing a sort nobody asked for — A-Z/Rating/Release Date are all
  /// opt-in via the top-bar menu, per direct feedback wanting a filter bar
  /// up there rather than buried in a menu elsewhere. The last one picked
  /// is kept per category and used again next time (user request,
  /// 2026-10-21: "Date added/updated" was forgotten on leaving).
  CatalogSort _sort = CatalogSort.none;

  /// Set only once real TMDB-fetched dates start arriving, so the grid
  /// doesn't re-sort to "everything with no date yet" the instant the user
  /// picks Release Date, before any lookups have actually completed.
  bool _enrichmentStarted = false;

  /// Non-null exactly while TMDB enrichment is running — shown as a
  /// progress banner so a partially-sorted category reads as "still
  /// loading" rather than "wrong"/stuck. Reported directly: a newer title
  /// sitting below an older one looked like a broken sort, when it was
  /// really just a title further down the fetch queue that hadn't been
  /// looked up yet — the in-progress order is only ever a prefix of the
  /// final one, never wrong once [_enrichDone] reaches [_enrichTotal].
  int? _enrichDone;
  int? _enrichTotal;

  /// The category's *full* contents, queried straight from
  /// `CatalogDatabase` rather than `PlaylistManager.vodGroups`/
  /// `visibleSeries` — those only ever hold up to
  /// `PlaylistSession._maxItemsPerCategory` (300) items in memory at once
  /// (a deliberate cap for the normal browse rows, which only ever show a
  /// handful at a time anyway). Reported directly: a 900+ item category
  /// only ever showed/sorted its first 300 titles here. The database
  /// itself was never capped — only what got paged into memory was — so
  /// querying it directly is the fix, not raising the in-memory cap (which
  /// would reintroduce the memory-pressure problem that cap exists for,
  /// for every normal browse row too).
  /// The focused title, shown in the spotlight above the grid (backdrop,
  /// name, year, rating). A notifier, not setState: moving focus must not
  /// rebuild the whole grid on a weak box.
  final ValueNotifier<_Spot?> _spot = ValueNotifier(null);

  List<Channel> _vodItems = [];
  List<XtreamSeries> _seriesItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final saved =
        context.read<StorageService>().getCatalogSort(widget.category);
    _sort = catalogSortFrom(saved);
    _loadItems();
  }

  String _sortLabel(CatalogSort mode) => switch (mode) {
        CatalogSort.none => tr('Default'),
        CatalogSort.aToZ => tr('A to Z'),
        CatalogSort.zToA => tr('Z to A'),
        CatalogSort.rating => tr('Rating (high to low)'),
        CatalogSort.addedDate => tr('Date added/updated'),
        CatalogSort.tmdb => 'TMDB',
      };

  Future<void> _loadItems() async {
    final db = context.read<CatalogDatabase>();
    if (widget.category == 'vod') {
      final items = await db.getVodCategory(widget.playlistId, widget.title);
      if (!mounted) return;
      setState(() {
        _vodItems = items;
        _loading = false;
      });
      if (items.isNotEmpty) _spot.value = _Spot.vod(_sortedChannels(items)[0]);
      _resumeTmdbSort();
    } else {
      final items = await db.getSeriesCategory(widget.playlistId, widget.title);
      if (!mounted) return;
      setState(() {
        _seriesItems = items;
        _loading = false;
      });
      if (items.isNotEmpty) {
        _spot.value = _Spot.series(_sortedSeries(items)[0]);
      }
      _resumeTmdbSort();
    }
  }

  @override
  void dispose() {
    _backButtonFocus.dispose();
    _spot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return withTvThemeIfNeeded(
        context,
        (context) => Stack(
              children: [
                const Positioned.fill(child: ColoredBox(color: Colors.black)),
                // Full height: a shorter box left a visible seam where
                // the image ended (Formuler, 2026-10-31).
                Positioned.fill(
                  child: ValueListenableBuilder<_Spot?>(
                    valueListenable: _spot,
                    builder: (context, spot, _) =>
                        DetailBackdrop(url: spot?.backdrop, fadeLeft: true),
                  ),
                ),
                Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      tooltip: tr('Back'),
                      focusNode: _backButtonFocus,
                      autofocus: true,
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    toolbarHeight: 64,
                    // Group + count on top, the focused title under it: the
                    // whole body stays a dense grid (more titles per screen).
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            _loading
                                ? widget.title
                                : '${widget.title}   ·   ${tr('{n} titles', {
                                        'n': widget.category == 'vod'
                                            ? _vodItems.length
                                            : _seriesItems.length
                                      })}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.white70)),
                        ValueListenableBuilder<_Spot?>(
                          valueListenable: _spot,
                          builder: (context, spot, _) =>
                              _spotLine(context, spot),
                        ),
                      ],
                    ),
                    actions: [
                      PopupMenuButton<CatalogSort>(
                        // The sort in use, beside the icon: a remembered
                        // one must not look like the provider's order.
                        icon: _sort == CatalogSort.none
                            ? const Icon(Icons.sort)
                            : Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.sort),
                                const SizedBox(width: 6),
                                Text(_sortLabel(_sort),
                                    style: const TextStyle(fontSize: 14)),
                              ]),
                        tooltip: tr('Sort'),
                        initialValue: _sort,
                        onSelected: _onSortSelected,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                              value: CatalogSort.none,
                              child: Text(tr('Default'))),
                          PopupMenuItem(
                              value: CatalogSort.aToZ,
                              child: Text(tr('A to Z'))),
                          PopupMenuItem(
                              value: CatalogSort.zToA,
                              child: Text(tr('Z to A'))),
                          PopupMenuItem(
                              value: CatalogSort.rating,
                              child: Text(tr('Rating (high to low)'))),
                          PopupMenuItem(
                              value: CatalogSort.addedDate,
                              child: Text(tr('Date added/updated'))),
                          const PopupMenuItem(
                              value: CatalogSort.tmdb, child: Text('TMDB')),
                        ],
                      ),
                    ],
                  ),
                  body: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            if (_enrichDone != null && _enrichTotal != null)
                              _buildEnrichmentBanner(context),
                            Expanded(
                              child: widget.category == 'vod'
                                  ? _buildVodGrid(context)
                                  : _buildSeriesGrid(context),
                            ),
                          ],
                        ),
                ),
              ],
            ));
  }

  /// A saved TMDB sort needs its lookups once the items are in.
  void _resumeTmdbSort() {
    if (_sort == CatalogSort.tmdb && !_enrichmentStarted) {
      _enrichmentStarted = true;
      _startEnrichment();
    }
  }

  void _onSortSelected(CatalogSort mode) {
    setState(() => _sort = mode);
    context
        .read<StorageService>()
        .setCatalogSort(widget.category, mode.name)
        .then((_) {
      if (mounted) {
        context.read<PlaylistManager>().applyCatalogSort(widget.category);
      }
    });
    if (mode == CatalogSort.tmdb && !_enrichmentStarted) {
      _enrichmentStarted = true;
      _startEnrichment();
    }
  }

  /// Kicks off TMDB enrichment for exactly this category's items — see
  /// `TmdbEnrichmentService`'s doc comment for why this is the *only*
  /// place that ever triggers a TMDB lookup at all (never proactively for
  /// a whole catalog, never for a hidden group). Items re-sort
  /// incrementally as each lookup resolves rather than waiting for the
  /// whole category to finish, so the grid visibly settles into place
  /// over a few seconds instead of looking frozen.
  void _startEnrichment() {
    final storage = context.read<StorageService>();
    final db = context.read<CatalogDatabase>();
    final service = TmdbEnrichmentService(storage, db);

    // Throttled separately from the fetching itself — a category like this
    // one can be ~2,900 items, and calling setState (which re-sorts the
    // *entire* list and rebuilds the whole grid) on every single one of
    // those resolutions is what actually broke this: confirmed directly
    // as the cause of "looks frozen, barely anything moved" — not a logic
    // bug, a rebuild-frequency one. The fetching itself stays at full
    // speed (5 concurrent requests throughout); only how often the UI
    // re-sorts/repaints is capped, same "expensive work shouldn't run on
    // every tick" lesson already learned elsewhere in this app (EPG
    // persistence, poster scroll, etc.).
    var lastUiUpdate = DateTime.fromMillisecondsSinceEpoch(0);
    const uiThrottle = Duration(milliseconds: 400);
    void onProgress(int done, int total) {
      if (!mounted) return;
      final isDone = done >= total;
      final now = DateTime.now();
      if (!isDone && now.difference(lastUiUpdate) < uiThrottle) return;
      lastUiUpdate = now;
      setState(() {
        if (isDone) {
          // Done (or nothing needed enrichment at all) — drop the banner
          // rather than leaving it stuck at "100%" forever.
          _enrichDone = null;
          _enrichTotal = null;
        } else {
          _enrichDone = done;
          _enrichTotal = total;
        }
      });
    }

    if (widget.category == 'vod') {
      service.enrichVod(_vodItems, onProgress: onProgress);
    } else {
      service.enrichSeries(_seriesItems, onProgress: onProgress);
    }
  }

  Widget _buildEnrichmentBanner(BuildContext context) {
    final done = _enrichDone!;
    final total = _enrichTotal!;
    return Container(
      width: double.infinity,
      color: Colors.black.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              tr('Fetching TMDB release dates... {done}/{total}',
                  {'done': done, 'total': total}),
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: total == 0 ? null : done / total),
        ],
      ),
    );
  }

  Widget _buildVodGrid(BuildContext context) {
    final playlist = context.watch<PlaylistManager>();
    final storage = context.read<StorageService>();
    final items = _sortedChannels(_vodItems);
    return _posterGrid(
      items,
      (c) => PosterCard(
        title: c.name,
        // TMDB's own poster, when enrichment has found one, over the
        // provider's — see `Channel.posterUrl`'s doc comment.
        imageUrl: c.posterUrl ?? c.logoUrl,
        rating: c.rating,
        watched: storage.isFullyWatched(c.id),
        progressFraction: storage.getWatchedFraction(c.id),
        isFavorite: playlist.isChannelFavorited(c.id),
        onToggleFavorite: () =>
            _toggleFavoriteWithFeedback(context, playlist, c),
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MovieDetailScreen(channel: c))),
        onFocusGained: () => _spot.value = _Spot.vod(c),
      ),
    );
  }

  Widget _buildSeriesGrid(BuildContext context) {
    final playlist = context.watch<PlaylistManager>();
    final items = _sortedSeries(_seriesItems);
    return _posterGrid(
      items,
      (s) => PosterCard(
        title: s.name,
        imageUrl: s.posterUrl ?? s.coverUrl,
        rating: s.rating,
        isFavorite: playlist.isSeriesFavorited(s.id),
        onToggleFavorite: () => _toggleSeriesFavoriteWithFeedback(playlist, s),
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SeriesDetailScreen(series: s))),
        onFocusGained: () => _spot.value = _Spot.series(s),
      ),
    );
  }

  /// A new list, never mutating [items] in place — [items] here is the
  /// *live* list `PlaylistManager`/the catalog database hands back, and
  /// sorting it directly would silently reorder that shared data for
  /// every other screen reading the same group.
  List<Channel> _sortedChannels(List<Channel> items) =>
      sortCatalogChannels(items, _sort);

  List<XtreamSeries> _sortedSeries(List<XtreamSeries> items) =>
      sortCatalogSeries(items, _sort);

  // Catalog rows are separate DB objects. Stars read the manager's saved ids,
  // so returning from a detail page also reflects a toggle made there.
  void _toggleFavoriteWithFeedback(
      BuildContext context, PlaylistManager playlist, Channel channel) {
    playlist.toggleFavorite(channel);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(channel.isFavorite
          ? tr('Added to Favorites')
          : tr('Removed from Favorites')),
      duration: const Duration(seconds: 2),
    ));
  }

  void _toggleSeriesFavoriteWithFeedback(
      PlaylistManager playlist, XtreamSeries series) {
    playlist.toggleSeriesFavorite(series);
    setState(() {});
  }

  /// Same shape as `TvHomeScreen._posterGrid` — a plain rectangular grid
  /// (not a row-per-category layout), which default D-pad traversal
  /// handles reliably on its own; the unbounded-search failure mode this
  /// app has repeatedly hit elsewhere is specifically about *many rows of
  /// differing length*, not a single regular grid like this one.
  Widget _posterGrid<T>(List<T> items, Widget Function(T) posterBuilder) {
    if (items.isEmpty) {
      return Center(child: Text(tr('No items in this group.')));
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: PosterCard.width + 12,
        mainAxisExtent: PosterCard.height + 10,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => posterBuilder(items[i]),
    );
  }

  /// The focused title with its year and rating, one line.
  Widget _spotLine(BuildContext context, _Spot? spot) {
    if (spot == null) return const SizedBox.shrink();
    final meta = [
      if (spot.year != null) '${spot.year}',
      if (spot.rating != null) '★ ${spot.rating}',
    ];
    return Row(children: [
      Flexible(
        child: Text(spot.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(color: Colors.black, blurRadius: 8)])),
      ),
      if (meta.isNotEmpty) ...[
        const SizedBox(width: 14),
        Text(meta.join('   ·   '),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary)),
      ],
    ]);
  }
}

/// What the spotlight shows for one title.
class _Spot {
  const _Spot(this.title, this.backdrop, this.year, this.rating);

  factory _Spot.vod(Channel c) => _Spot(cleanDisplayTitle(c.name),
      c.anyBackdropUrl, c.releaseDate?.year, _ratingOf(c.rating));
  factory _Spot.series(XtreamSeries s) => _Spot(cleanDisplayTitle(s.name),
      s.anyBackdropUrl, s.releaseDate?.year, _ratingOf(s.rating));

  final String title;
  final String? backdrop;
  final int? year;
  final String? rating;

  static String? _ratingOf(String? raw) {
    final v = double.tryParse(raw ?? '');
    if (v == null || v <= 0) return null;
    return v.toStringAsFixed(1);
  }
}
