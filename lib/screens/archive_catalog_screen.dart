import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/archive_models.dart';
import '../services/archive_ready_watch.dart';
import '../services/archive_service.dart';
import '../utils/display_title.dart';
import '../utils/tv_theme.dart';
import '../widgets/detail_header.dart';
import '../widgets/poster_card.dart';
import 'archive_detail_screen.dart';
import 'archive_playback.dart';

/// One Media Hub row (Popular / New / Featured / Recently watched / a
/// source's catalog) expanded into a full poster grid — "Expand catalog" in
/// the menu that rolls down when a floating-bar row button is held (see
/// `_ArchiveScreenState._showRowMenu`). The Media Hub twin of the IPTV
/// [GroupCatalogScreen]: a pushed route, so Back is just Navigator's pop.
///
/// Reads the row live from [ArchiveService] by key, so pages appended by
/// [ArchiveService.loadMore] (asked for as focus nears the end) show up in
/// place; the grid keeps whatever order the source sent.
class ArchiveCatalogScreen extends StatefulWidget {
  const ArchiveCatalogScreen({
    super.key,
    required this.type,
    required this.rowKey,
    required this.title,
  });

  final ArchiveType type;

  /// [ArchiveRow.key] of the expanded row.
  final String rowKey;
  final String title;

  @override
  State<ArchiveCatalogScreen> createState() => _ArchiveCatalogScreenState();
}

class _ArchiveCatalogScreenState extends State<ArchiveCatalogScreen> {
  /// The first poster takes focus on entry — the lazy grid otherwise left
  /// the remote with nothing (or a random visible card) focused.
  final FocusNode _firstPoster = FocusNode(debugLabel: 'archive-grid-first');

  /// The focused title, shown full screen behind the grid like the IPTV
  /// expanded catalog (owner, 1.0.51). A notifier: moving focus must not
  /// rebuild the grid.
  final ValueNotifier<ArchiveMeta?> _spot = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _firstPoster.requestFocus();
    });
  }

  @override
  void dispose() {
    _firstPoster.dispose();
    _spot.dispose();
    super.dispose();
  }

  void _open(ArchiveSource source, ArchiveMeta meta) {
    if (meta.type == ArchiveType.series) {
      openArchiveSeries(context, source, meta);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ArchiveDetailScreen(source: source, preview: meta)));
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ArchiveService>();
    ArchiveRow? row;
    for (final r in service.rows(widget.type)) {
      if (r.key == widget.rowKey) row = r;
    }
    final items = row?.items ?? const <ArchiveMeta>[];
    final touchPreview = Theme.of(context).platform == TargetPlatform.android &&
        MediaQuery.sizeOf(context).width < 700;
    return withTvThemeIfNeeded(
      context,
      (context) => Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Colors.black)),
          // Same backdrop as GroupCatalogScreen: full height, faded left.
          Positioned.fill(
            child: ValueListenableBuilder<ArchiveMeta?>(
              valueListenable: _spot,
              builder: (context, spot, _) => DetailBackdrop(
                  url: spot?.backgroundUrl ?? spot?.posterUrl, fadeLeft: true),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                tooltip: tr('Back'),
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
              ),
              toolbarHeight: 64,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      items.isEmpty
                          ? widget.title
                          : '${widget.title}   ·   ${tr('{n} titles', {
                                  'n': items.length
                                })}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.white70)),
                  ValueListenableBuilder<ArchiveMeta?>(
                    valueListenable: _spot,
                    builder: (context, spot, _) => _spotLine(context, spot),
                  ),
                ],
              ),
            ),
            body: row == null || items.isEmpty
                ? Center(child: Text(tr('No items in this group.')))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: PosterCard.width + 12,
                      mainAxisExtent: PosterCard.height + 10,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final current = row!;
                      final meta = items[i];
                      return ValueListenableBuilder<Set<String>>(
                        valueListenable: ArchiveReadyWatch.instance.tags,
                        builder: (context, ready, _) => PosterCard(
                          ready: ready.contains(meta.id),
                          fetching: ArchiveReadyWatch.instance.fetching.value
                              .contains(meta.id),
                          focusNode: i == 0 ? _firstPoster : null,
                          title: meta.name,
                          imageUrl: meta.posterUrl,
                          rating: meta.year,
                          tapToPreview: touchPreview,
                          onTap: () => _open(current.sourceAt(i), meta),
                          // Same hold as the row it came from.
                          isFavorite: context
                              .read<ArchiveService>()
                              .isFavorite(current.sourceAt(i), meta),
                          onToggleFavorite: () => holdArchiveTitle(
                              context, current, current.sourceAt(i), meta),
                          onFocusGained: () {
                            _spot.value = meta;
                            // A grid row holds several cards: ask for the
                            // next page a few rows before the end.
                            if (i >= items.length - 24) {
                              context.read<ArchiveService>().loadMore(current);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// The focused title with its year and rating, one line (the IPTV
  /// expanded catalog's spotlight line).
  Widget _spotLine(BuildContext context, ArchiveMeta? spot) {
    if (spot == null) return const SizedBox.shrink();
    final info = [
      if (spot.year != null && spot.year!.isNotEmpty) spot.year!,
      if (spot.rating != null && spot.rating!.isNotEmpty) '★ ${spot.rating}',
    ];
    return Row(children: [
      Flexible(
        child: Text(cleanDisplayTitle(spot.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(color: Colors.black, blurRadius: 8)])),
      ),
      if (info.isNotEmpty) ...[
        const SizedBox(width: 14),
        Text(info.join('   ·   '),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary)),
      ],
    ]);
  }
}
