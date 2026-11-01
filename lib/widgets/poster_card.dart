import '../utils/refined_finish.dart';
import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../utils/image_urls.dart';
import 'hd_network_image.dart';
import 'hold_to_activate.dart';

/// One poster/backdrop tile in a browse row — scales and glows when
/// focused, which is the standard "this is where the D-pad is" affordance
/// on TV browse UIs. Shared by the Movies/TV Shows catalog rows
/// ([TvHomeScreen]'s `_CategoryRow`) and the season/episode rows
/// ([SeriesDetailScreen]) — same card shape either way, just fed a movie's
/// poster or an episode's still image.
class PosterCard extends StatefulWidget {
  const PosterCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.onTap,
    required this.onFocusGained,
    this.rating,
    this.watched = false,
    this.progressFraction,
    this.focusNode,
    this.isFavorite = false,
    this.ready = false,
    this.fetching = false,
    this.onToggleFavorite,
    this.cardWidth = PosterCard.width,
    this.cardPosterHeight = PosterCard.posterHeight,
    this.fit = BoxFit.cover,
    this.sourceLabel,
    this.tapToPreview = false,
    this.wideWidth,
    this.wideImageUrl,
    this.wideLogoUrl,
  });

  /// Media Hub's focused card (Nuvio style): set by the caller while this
  /// card is the focused one, the artwork grows to this width and shows
  /// [wideImageUrl] (the backdrop) with [wideLogoUrl] over it. Same height,
  /// so the row keeps its shape; the caller widens the list slot to match.
  final double? wideWidth;
  final String? wideImageUrl;
  final String? wideLogoUrl;

  /// A wide card's width for [posterHeight]: 16:9 artwork.
  static const double wideCardWidth = posterHeight * 16 / 9;

  /// Touch: the first tap only focuses the card (the browse hero shows
  /// its description), a tap on the focused card or a double tap opens
  /// it — like Select-to-preview on the live list. Always on for Windows.
  final bool tapToPreview;

  /// Was 120x168 with the title overlaid on the poster (and only shown at
  /// all when there was no artwork) — reported directly as a real
  /// usability gap: plenty of titles have no poster, and there was no
  /// way to read one without moving D-pad focus onto it first (the hero
  /// banner at the top of the screen is the only other place a title
  /// shows). The title now always renders in its own row below the
  /// poster, for every card, so this is smaller than before (less to
  /// decode/cache per poster too — see cacheWidth/cacheHeight below).
  /// Shrunk again (was 104x148/34) per feedback that the catalog should
  /// show more at once and leave more room for a bigger hero banner —
  /// same ~0.70 poster aspect ratio kept; titleHeight only trimmed to
  /// what 11pt/2 lines actually needs, not the font itself.
  static const double width = 84;
  static const double posterHeight = 120;
  static const double titleHeight = 30;
  static const double height = posterHeight + titleHeight;

  /// Extra height a card needs when it shows a [sourceLabel] line.
  static const double sourceHeight = 14;

  final String title;

  /// One small grey line under the title — Search uses it for the
  /// playlist an item came from when more than one playlist is enabled.
  final String? sourceLabel;
  final String? imageUrl;
  final String? rating;
  final VoidCallback onTap;
  final VoidCallback onFocusGained;

  /// Only the groups quick-jump needs this (on the first card of a row,
  /// so it can focus that row directly after scrolling to it) — every
  /// other card leaves this null and gets its own internal node as usual.
  final FocusNode? focusNode;

  /// Shows a checkmark badge instead of the rating — used by episode cards
  /// for "fully watched" (see StorageService.isFullyWatched).
  final bool watched;

  /// 0.0-1.0 — shows a progress bar + percentage when set and not
  /// [watched] (an episode/movie partway through, not finished).
  final double? progressFraction;

  /// Shows a star badge when true. [onToggleFavorite] is null for callers
  /// that don't have a favorite concept for this item (e.g. episode cards)
  /// — the hold-to-favorite gesture is only wired up when it's provided.
  final bool isFavorite;

  /// Media Hub: the source finished preparing a title that played as a
  /// "being downloaded" clip (`ArchiveReadyWatch`) — gold "Ready" tag in
  /// the rating's corner.
  final bool ready;

  /// Media Hub: that title is still being checked — outlined "Fetching…".
  final bool fetching;
  final VoidCallback? onToggleFavorite;

  /// Override [PosterCard.width]/[PosterCard.posterHeight] per instance —
  /// a search result's channel-logo row sits in the same row shape as
  /// Movies/TV Shows results but reads better noticeably smaller, since a
  /// broadcast logo carries far less detail than a movie poster. Every
  /// existing call site keeps the original static sizing unchanged.
  final double cardWidth;
  final double cardPosterHeight;

  /// `BoxFit.cover` (the default) is right for a movie/show poster
  /// designed to fill its whole rectangle — a broadcast logo is usually a
  /// transparent-background mark meant to be seen whole, so search's
  /// channel row passes `BoxFit.contain` instead, same convention
  /// `ChannelListTile` already uses for the same kind of image.
  final BoxFit fit;

  @override
  State<PosterCard> createState() => _PosterCardState();
}

class _PosterCardState extends State<PosterCard> {
  bool _focused = false;

  /// Only [widget.focusNode] (the first-card-of-a-row case) gives this an
  /// externally-owned node — every other instance needs its own stable
  /// handle too, on Windows, to call `.requestFocus()` on directly (see
  /// the `onTap` doc comment below); left as `null` on InkWell otherwise,
  /// it manages one internally that this widget has no reference to.
  FocusNode? _ownedFocusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void dispose() {
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wide = widget.wideWidth != null;
    final cardWidth = widget.wideWidth ?? widget.cardWidth;
    final imageUrl =
        wide ? (widget.wideImageUrl ?? widget.imageUrl) : widget.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final logoUrl = wide ? widget.wideLogoUrl : null;
    final showProgress = !widget.watched && widget.progressFraction != null;
    // Derived from however much bigger than the TV-tuned default
    // `cardWidth` actually is (1.0 for every caller that doesn't override
    // it) — the title row's height and its text both need to grow along
    // with a much bigger poster (Windows's browse rows, see
    // TvHomeScreen's `_browsePosterWidth`/`_browseCardHeight`), or a
    // fixed 30px/11pt title underneath a ~1.8x taller poster reads as a
    // mismatched sliver of mostly-blank space under tiny text.
    final scale = widget.cardWidth / PosterCard.width;
    final titleHeight = PosterCard.titleHeight * scale;
    final sourceHeight =
        widget.sourceLabel == null ? 0.0 : PosterCard.sourceHeight * scale;

    final card = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        focusNode: _effectiveFocusNode,
        borderRadius: BorderRadius.circular(10),
        // The poster's own border + glow is the focus look. InkWell's grey
        // focus highlight sat around the unscaled card, so under the 1.10
        // zoom it showed as a stray box below the title (Media Hub photo,
        // 2026-10-20).
        focusColor: Colors.transparent,
        // Windows only — same fix/reasoning as TvHomeScreen's
        // _ProgramBlock (the Timeline guide's program cells): a single
        // click immediately opening the detail screen (the old, only
        // behavior here) never gave the hero banner above this grid a
        // chance to show anything — the click that would populate it via
        // onFocusGained also navigated away in the same instant,
        // reported directly as "nothing shows in the hero banner."
        // Explicit `.requestFocus()` on the first click, not left to
        // InkWell's own tap-triggers-focus behavior — confirmed
        // unreliable there once onTap itself is null. A second click
        // (onDoubleTap) is the only thing that still opens it. Remote/
        // touch (HoldToActivate below, and every other platform) is
        // untouched — same scoping as the Timeline guide fix.
        onTap: Platform.isWindows
            ? _effectiveFocusNode.requestFocus
            : widget.tapToPreview
                ? () => _focused
                    ? widget.onTap()
                    : _effectiveFocusNode.requestFocus()
                : widget.onTap,
        onDoubleTap:
            Platform.isWindows || widget.tapToPreview ? widget.onTap : null,
        onFocusChange: (f) {
          setState(() => _focused = f);
          if (f) widget.onFocusGained();
        },
        child: AnimatedScale(
          // Bumped from 1.08 — the same relative scale at this smaller
          // card size grew it by fewer pixels, so the focus "pop" read
          // as noticeably weaker; this restores a similarly visible glow.
          // A wide card zooms less: 10 % of its width ran over both
          // neighbours.
          scale: _focused ? (wide ? 1.04 : 1.10) : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: SizedBox(
            width: cardWidth,
            height: widget.cardPosterHeight + titleHeight + sourceHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: cardWidth,
                  height: widget.cardPosterHeight,
                  foregroundDecoration: RefinedFinish.artworkRim(
                      context, BorderRadius.circular(10),
                      focused: _focused),
                  decoration: RefinedFinish.decorate(
                      context,
                      BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(10),
                        border: _focused
                            ? Border.all(color: scheme.primary, width: 3)
                            : null,
                        // Was two layered shadows (primary + secondary at
                        // different blur/spread) for a duo-tone glow — on this
                        // hardware (Impeller already disabled elsewhere for GPU
                        // weakness) that showed up as part of a real flicker
                        // during scrolling. One shadow in a blended color keeps
                        // the "not just one flat accent" feel at half the
                        // compositing cost.
                        boxShadow: _focused
                            ? [
                                BoxShadow(
                                  color: Color.lerp(scheme.primary,
                                          scheme.secondary, 0.5)!
                                      .withValues(alpha: 0.6),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      focused: _focused,
                      artwork: true),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      if (hasImage)
                        Positioned.fill(
                          child: HdNetworkImage(
                            // Keyed: the wide card swaps poster -> backdrop.
                            key: ValueKey(imageUrl),
                            url: imageUrl,
                            kind: wide && widget.wideImageUrl != null
                                ? ImageKind.backdrop
                                : ImageKind.poster,
                            fit: widget.fit,
                            // Provider posters commonly come in well above
                            // this card's on-screen size; without a cap,
                            // Flutter decodes and caches each one at full
                            // source resolution, which is the real memory
                            // cost of browsing a catalog (not the item
                            // metadata) — this was still causing device-
                            // wide OOM kills on a memory-constrained
                            // Firestick even after capping items per
                            // category. Decode-time downsampling to the
                            // card's physical size cuts each cached image
                            // by an order of magnitude or more. Width only
                            // (a width + height pair stretched every image
                            // to the card's exact shape), and 1.2x so the
                            // 1.10 focus zoom isn't an upscale. Also picks
                            // the TMDB rendition (w342 on a 1080p TV box)
                            // — see hdImageUrl.
                            decodeWidth: HdNetworkImage.cardDecodeWidth(
                                context, cardWidth),
                            // A poster popping in instantly from the grey
                            // placeholder reads as a jarring flash,
                            // especially when scrolling back re-triggers a
                            // fetch after the tight in-memory cache evicted
                            // it — fadeInDuration is purely cosmetic, same
                            // cost either way. The disk cache underneath
                            // (this package's whole point over plain
                            // Image.network) is what actually avoids a full
                            // network re-fetch on that same scroll-back,
                            // which the memory cache ceiling alone
                            // couldn't do.
                            fadeInDuration: const Duration(milliseconds: 250),
                            errorWidget: (_) => const _PosterFallbackIcon(),
                          ),
                        )
                      else
                        const _PosterFallbackIcon(),
                      if (logoUrl != null)
                        Positioned(
                          left: 10,
                          right: cardWidth * 0.35,
                          bottom: showProgress ? 26 : 8,
                          height: widget.cardPosterHeight * 0.32,
                          child: HdNetworkImage(
                            url: logoUrl,
                            kind: ImageKind.poster,
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomLeft,
                            decodeWidth: HdNetworkImage.cardDecodeWidth(
                                context, cardWidth * 0.65),
                            fadeInDuration: const Duration(milliseconds: 200),
                            errorWidget: (_) => const SizedBox.shrink(),
                          ),
                        ),
                      if (widget.watched)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(Icons.check_circle,
                              color: scheme.primary,
                              size: 18,
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 4),
                              ]),
                        )
                      else if (widget.ready || widget.fetching)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.ready
                                  ? scheme.primary
                                  : Colors.black.withValues(alpha: 0.75),
                              border: widget.ready
                                  ? null
                                  : Border.all(color: scheme.primary),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: const [
                                BoxShadow(color: Colors.black54, blurRadius: 4),
                              ],
                            ),
                            child: Text(
                              widget.ready ? tr('Ready') : tr('Fetching…'),
                              style: TextStyle(
                                  color: widget.ready
                                      ? scheme.onPrimary
                                      : scheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      else if (widget.rating != null)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '★ ${widget.rating}',
                              style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      // Stacked below the watched checkmark (not on top of
                      // it) when both apply, rather than picking one over
                      // the other.
                      if (widget.isFavorite)
                        Positioned(
                          top: widget.watched ? 26 : 4,
                          right: 4,
                          child: const Icon(Icons.star,
                              color: Colors.amber,
                              size: 16,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 4),
                              ]),
                        ),
                      if (showProgress)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                            // Was a plain 4px `scheme.primary` bar directly
                            // on the poster — reported directly as barely
                            // visible, and on a focused card actively
                            // blending into the focus border/glow above it
                            // (also `scheme.primary`, by design, so the two
                            // were never going to read as separate things).
                            // An opaque backing strip plus a percentage
                            // label fixes both at once: legible against any
                            // poster art regardless of focus state, and a
                            // real number reads at a glance without having
                            // to notice a thin bar's fill length at all.
                            // `scheme.secondary` for the fill — this app's
                            // whole duo-tone design already guarantees that
                            // reads as a distinct hue from whatever
                            // `scheme.primary` the focus glow is using.
                            child: ColoredBox(
                              color: Colors.black.withValues(alpha: 0.78),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(4, 2, 4, 3),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${(widget.progressFraction! * 100).round()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        height: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: widget.progressFraction,
                                        minHeight: 4,
                                        backgroundColor: Colors.white24,
                                        color: scheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: titleHeight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _focused ? scheme.primary : Colors.white,
                        fontSize: 11 * scale,
                        fontWeight:
                            _focused ? FontWeight.bold : FontWeight.normal,
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
                if (widget.sourceLabel != null)
                  SizedBox(
                    height: sourceHeight,
                    child: Text(
                      widget.sourceLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 9.5 * scale,
                        height: 1.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final onToggleFavorite = widget.onToggleFavorite;
    if (onToggleFavorite == null) return card;
    return HoldToActivate(
        onTap: widget.onTap, onHold: onToggleFavorite, child: card);
  }
}

class _PosterFallbackIcon extends StatelessWidget {
  const _PosterFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade800,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: const Icon(Icons.movie_creation_outlined,
          color: Colors.white38, size: 40),
    );
  }
}
