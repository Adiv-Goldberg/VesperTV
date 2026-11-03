import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/archive_models.dart';
import '../models/archive_library.dart';
import '../services/archive_discovery_service.dart';
import '../services/archive_service.dart';
import '../services/storage_service.dart';
import '../screens/archive_detail_screen.dart';
import '../screens/archive_playback.dart';
import '../screens/settings/tmdb_settings_screen.dart';
import 'poster_card.dart';
import 'hold_to_activate.dart';
import 'dart:convert';
import 'archive_detail_layout.dart';

Widget _remoteCard(PosterCard card) =>
    HoldToActivate(onTap: card.onTap, child: card);

class ArchiveDiscoveryPanel extends StatefulWidget {
  const ArchiveDiscoveryPanel(
      {super.key,
      required this.source,
      required this.meta,
      required this.entryNode,
      required this.onReturn,
      this.discovery})
      : assert(source != null),
        castOnly = false,
        openTitle = null;
  const ArchiveDiscoveryPanel.iptvCast(
      {super.key,
      required this.meta,
      required this.entryNode,
      required this.onReturn,
      required this.openTitle,
      this.discovery})
      : assert(openTitle != null),
        source = null,
        castOnly = true;
  final ArchiveSource? source;
  final bool castOnly;
  final Future<void> Function(ArchiveMeta)? openTitle;
  final ArchiveMeta meta;
  final FocusNode entryNode;
  final VoidCallback onReturn;
  final ArchiveDiscoveryService? discovery;
  @override
  State<ArchiveDiscoveryPanel> createState() => _ArchiveDiscoveryPanelState();
}

class _ArchiveDiscoveryPanelState extends State<ArchiveDiscoveryPanel> {
  late final _api = widget.discovery ?? ArchiveDiscoveryService();
  ArchiveDiscovery _data = const ArchiveDiscovery();
  bool _loading = true, _failed = false, _opening = false;
  final _nodes = <String, FocusNode>{};
  final _scrolls = <String, ScrollController>{};
  final _indices = <String, int>{};
  final _rowKeys = <String, GlobalKey>{};
  final _customizeNode = FocusNode();
  late List<String> _order;
  late final int _viewer;
  List<String> _rows = [];
  final _localSources = <ArchiveMeta, ArchiveSource>{};
  int _request = 0;
  StorageService get storage => context.read<StorageService>();
  String get key => storage.getTmdbApiKey() ?? '';
  @override
  void initState() {
    super.initState();
    _viewer = storage.viewerGeneration;
    _order = widget.castOnly ? ['cast'] : ArchiveDetailLayout.load(storage);
    _load();
  }

  bool get current => mounted && storage.viewerGeneration == _viewer;
  @override
  void didUpdateWidget(covariant ArchiveDiscoveryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meta.id != widget.meta.id ||
        oldWidget.meta.imdb != widget.meta.imdb ||
        (widget.castOnly &&
            !widget.meta.id.startsWith('tmdb:') &&
            (oldWidget.meta.name != widget.meta.name ||
                oldWidget.meta.year != widget.meta.year))) {
      _loading = true;
      if (widget.castOnly) {
        _data = const ArchiveDiscovery();
        _failed = false;
      }
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    try {
      final result = widget.castOnly
          ? ArchiveDiscovery(
              cast: await _api.castForTitle(widget.meta, key, L10n.code))
          : await _api.discover(widget.meta, key, L10n.code);
      if (current && request == _request) {
        setState(() {
          _data = result;
          _loading = false;
          _failed = false;
        });
      }
    } catch (_) {
      if (current && request == _request) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _customizeNode.dispose();
    _api.dispose();
    for (final n in _nodes.values) {
      n.dispose();
    }
    for (final c in _scrolls.values) {
      c.dispose();
    }
    super.dispose();
  }

  FocusNode node(String row, int i) => _nodes.putIfAbsent(
      '$row:$i', () => FocusNode(debugLabel: 'discovery-$row'));
  void _focus(String row, int index) {
    final count = row == 'cast'
        ? _data.cast.length
        : row == 'collection'
            ? _data.collection.length
            : _related.length;
    if (count == 0) return;
    final i = index.clamp(0, count - 1);
    _indices[row] = i;
    // Move the row only when the card would be off screen, and only by
    // what it takes: jumping it to the left edge and then animating it to
    // 65% across on focus made the row lurch on every press (owner photo).
    final c = _scrolls[row];
    if (c != null && c.hasClients) {
      const stride = PosterCard.width + 20;
      final p = c.position;
      final left = i * stride;
      final target = left < p.pixels
          ? left
          : left + stride > p.pixels + p.viewportDimension
              ? left + stride - p.viewportDimension
              : p.pixels;
      final clamped = target.clamp(0.0, p.maxScrollExtent);
      if (clamped != p.pixels) c.jumpTo(clamped);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) node(row, i).requestFocus();
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  List<ArchiveMeta> get _related {
    if (widget.castOnly) return const [];
    if (_data.related.isNotEmpty) return _data.related;
    final hub = context.read<ArchiveService>();
    final seen = <String>{archiveTitleIdentity(widget.source!, widget.meta)};
    final result = <ArchiveMeta>[];
    _localSources.clear();
    for (final row in hub.rows(widget.meta.type)) {
      for (var i = 0; i < row.items.length; i++) {
        final item = row.items[i];
        if (!item.genres.any(widget.meta.genres.contains) ||
            !seen.add(archiveTitleIdentity(row.sourceAt(i), item))) {
          continue;
        }
        result.add(item);
        _localSources[item] = row.sourceAt(i);
        if (result.length == 16) return result;
      }
    }
    return result;
  }

  Future<void> _open(ArchiveMeta preview) async {
    if (!current) return;
    if (_opening) return;
    if (widget.openTitle case final open?) {
      setState(() => _opening = true);
      try {
        await open(preview);
      } finally {
        if (current) setState(() => _opening = false);
      }
      return;
    }
    setState(() => _opening = true);
    final hub = context.read<ArchiveService>();
    ArchiveSource? source = _localSources[preview];
    var meta = preview;
    try {
      if (source == null && key.isNotEmpty && preview.imdb == null) {
        meta = await _api.identify(preview, key, L10n.code);
      }
      if (!mounted || !current) return;
      for (final row in source == null
          ? hub.rows(meta.type, includeHidden: true)
          : const <ArchiveRow>[]) {
        for (var i = 0; i < row.items.length; i++) {
          final candidate = row.items[i];
          if (meta.wireType == null &&
              candidate.wireType == null &&
              ((meta.imdb != null && meta.imdb == candidate.imdb) ||
                  (meta.id.startsWith('tmdb:') && candidate.id == meta.id))) {
            source = row.sourceAt(i);
            meta = candidate;
            break;
          }
        }
        if (source != null) break;
      }
      if (source == null) {
        final match = await hub.findServerTitle(meta);
        if (!mounted || !current) return;
        if (match != null) {
          source = match.source;
          meta = match.meta;
        }
      }
      if (source == null && meta.imdb != null) {
        source = hub.enabledSources
            .where((s) =>
                s.server == null &&
                (s.streamOnly || s.supportsImdb('stream', meta.type.wire)))
            .firstOrNull;
      }
      if (!mounted || !current) return;
      if (source == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr(
                'No compatible source for this title. Add a playback source in Media Hub settings.'))));
        return;
      }
      if (meta.type == ArchiveType.series) {
        await openArchiveSeries(context, source, meta);
      } else {
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                ArchiveDetailScreen(source: source!, preview: meta)));
      }
    } catch (_) {
      if (mounted && current) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr('Could not load this title. Try again.'))));
      }
    } finally {
      if (current) setState(() => _opening = false);
    }
  }

  Future<void> _person(ArchivePerson person) async {
    if (!current) return;
    final apiKey = key, language = L10n.code;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _ArchiveCreditsScreen(
            name: person.name,
            load: () => _api.credits(person, apiKey, language),
            open: _open)));
  }

  Widget _row(String id, String title, int count, Widget Function(int) card) {
    final row = _rows.indexOf(id);
    return Column(
        key: _rowKeys.putIfAbsent(id, GlobalKey.new),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600))),
          Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onKeyEvent: (_, e) {
                if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
                  return KeyEventResult.ignored;
                }
                final i = _indices[id] ?? 0;
                if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  _focus(id, i - 1);
                } else if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
                  _focus(id, i + 1);
                } else if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
                  if (row == 0) {
                    widget.entryNode.requestFocus();
                  } else {
                    _focus(_rows[row - 1], _indices[_rows[row - 1]] ?? 0);
                  }
                } else if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
                  if (row + 1 < _rows.length) {
                    _focus(_rows[row + 1], _indices[_rows[row + 1]] ?? 0);
                  }
                } else {
                  return KeyEventResult.ignored;
                }
                return KeyEventResult.handled;
              },
              child: SizedBox(
                  height: PosterCard.height + 20,
                  child: ListView.builder(
                      controller:
                          _scrolls.putIfAbsent(id, ScrollController.new),
                      scrollDirection: Axis.horizontal,
                      itemExtent: PosterCard.width + 20,
                      itemCount: count,
                      itemBuilder: (_, i) => card(i)))),
        ]);
  }

  Widget _titleCard(String row, int i, ArchiveMeta meta) =>
      _remoteCard(PosterCard(
          focusNode: node(row, i),
          title: meta.name,
          imageUrl: meta.posterUrl,
          rating: meta.year,
          onTap: () async {
            await _open(meta);
            if (current) _focus(row, i);
          },
          onFocusGained: () => _reveal(row, i)));
  void _reveal(String row, int i) {
    _indices[row] = i;
    _keepVisible(_rowKeys[row]?.currentContext);
  }

  /// Scrolls the page (vertically, instantly) only as far as it takes to
  /// show [target]; a horizontal row's own scroll is [_focus]'s.
  /// [target] must sit directly in the page, not inside a row's own
  /// scrollable: ScrollPosition.ensureVisible measures against the nearest
  /// viewport, so a card made the page never move (+521).
  void _keepVisible(BuildContext? target) {
    final card = target?.findRenderObject();
    final page = Scrollable.maybeOf(context)?.position;
    if (card == null || page == null) return;
    for (final policy in [
      ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      ScrollPositionAlignmentPolicy.keepVisibleAtStart
    ]) {
      page.ensureVisible(card, alignmentPolicy: policy);
    }
  }

  @override
  Widget build(BuildContext context) {
    final related = _related;
    _rows = [
      for (final id in _order)
        if (switch (id) {
          'collection' => _data.collection.isNotEmpty,
          'related' => related.isNotEmpty,
          _ => _data.cast.isNotEmpty,
        })
          id,
    ];
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 12, runSpacing: 8, children: [
            Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onKeyEvent: (_, e) {
                  if (e is! KeyDownEvent) return KeyEventResult.ignored;
                  if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
                    widget.onReturn();
                    return KeyEventResult.handled;
                  }
                  if (!widget.castOnly &&
                      e.logicalKey == LogicalKeyboardKey.arrowRight) {
                    _customizeNode.requestFocus();
                    return KeyEventResult.handled;
                  }
                  if (e.logicalKey == LogicalKeyboardKey.arrowDown &&
                      _rows.isNotEmpty) {
                    _focus(_rows.first, 0);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: OutlinedButton.icon(
                    focusNode: widget.entryNode,
                    icon: Icon(_failed
                        ? Icons.refresh
                        : widget.castOnly
                            ? Icons.groups_outlined
                            : Icons.explore_outlined),
                    label: Text(widget.castOnly
                        ? _loading
                            ? tr('Loading')
                            : _failed
                                ? tr('Try Again')
                                : tr('Cast and credits')
                        : _loading
                            ? tr('Loading recommendations…')
                            : _failed
                                ? tr('Retry recommendations')
                                : tr('Explore more')),
                    // Minimal scroll: pinning it 20% from the top scrolled the
                    // page down when coming Up from a row (owner photo).
                    onFocusChange: (has) {
                      if (has) _keepVisible(widget.entryNode.context);
                    },
                    onPressed: () {
                      if (_failed) {
                        setState(() => _loading = true);
                        _load();
                      } else if (_rows.isNotEmpty) {
                        _focus(_rows.first, 0);
                      }
                    })),
            if (!widget.castOnly)
              Focus(
                  canRequestFocus: false,
                  skipTraversal: true,
                  onKeyEvent: (_, e) {
                    if (e is! KeyDownEvent) return KeyEventResult.ignored;
                    if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
                      widget.entryNode.requestFocus();
                    } else if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
                      widget.onReturn();
                    } else if (e.logicalKey == LogicalKeyboardKey.arrowDown &&
                        _rows.isNotEmpty) {
                      _focus(_rows.first, 0);
                    } else {
                      return KeyEventResult.ignored;
                    }
                    return KeyEventResult.handled;
                  },
                  child: OutlinedButton.icon(
                      focusNode: _customizeNode,
                      icon: const Icon(Icons.tune),
                      label: Text(tr('Customize title page')),
                      onFocusChange: (has) {
                        if (has) _keepVisible(_customizeNode.context);
                      },
                      onPressed: _customize)),
          ]),
          if (_opening) const LinearProgressIndicator(),
          if (widget.castOnly && !_loading && !_failed && _data.cast.isEmpty)
            Text(tr('No credits found.')),
          if (key.isEmpty)
            TextButton.icon(
                // Left-aligned: centred, a large font broke it into a
                // ragged block with the icon at the bottom.
                style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                icon: const Icon(Icons.movie_outlined),
                label: Flexible(
                  child: Text(
                      tr('Add your TMDB key for collections and cast credits'),
                      textAlign: TextAlign.start),
                ),
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const TmdbSettingsScreen()));
                  if (current) {
                    setState(() => _loading = true);
                    await _load();
                    widget.entryNode.requestFocus();
                  }
                }),
          for (final id in _rows)
            if (id == 'collection')
              _row(
                  'collection',
                  _data.collectionName ?? tr('Collection'),
                  _data.collection.length,
                  (i) => _titleCard('collection', i, _data.collection[i]))
            else if (id == 'related')
              _row(
                  'related',
                  _data.related.isEmpty
                      ? tr('Explore this genre')
                      : tr('More like this'),
                  related.length,
                  (i) => _titleCard('related', i, related[i]))
            else
              _row('cast', tr('Cast and credits'), _data.cast.length, (i) {
                final person = _data.cast[i];
                return _remoteCard(PosterCard(
                    focusNode: node('cast', i),
                    title: person.name,
                    imageUrl: person.image,
                    sourceLabel: person.role,
                    onTap: () async {
                      await _person(person);
                      if (current) _focus('cast', i);
                    },
                    onFocusGained: () => _reveal('cast', i)));
              }),
          if (key.isNotEmpty)
            Text(tr('Metadata provided by TMDB.'),
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]));
  }

  Future<void> _customize() async {
    final order = await showArchiveDetailLayout(context, _order);
    if (!current || order == null) return;
    await storage.setArchiveOptionsJson('detail_rows', jsonEncode(order));
    if (!current) return;
    setState(() => _order = order);
    widget.entryNode.requestFocus();
  }
}

class _ArchiveCreditsScreen extends StatefulWidget {
  const _ArchiveCreditsScreen(
      {required this.name, required this.load, required this.open});
  final String name;
  final Future<List<ArchiveMeta>> Function() load;
  final Future<void> Function(ArchiveMeta) open;
  @override
  State<_ArchiveCreditsScreen> createState() => _ArchiveCreditsScreenState();
}

class _ArchiveCreditsScreenState extends State<_ArchiveCreditsScreen> {
  final _nodes = <int, FocusNode>{};
  bool _focused = false;
  late final Future<List<ArchiveMeta>> _future = widget.load();
  @override
  void dispose() {
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: FutureBuilder<List<ArchiveMeta>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data ?? const <ArchiveMeta>[];
            if (items.isEmpty) {
              return Center(
                  child: Text(snap.hasError
                      ? tr('Could not load credits.')
                      : tr('No credits found.')));
            }
            return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    mainAxisExtent: PosterCard.height + 16,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final node = _nodes.putIfAbsent(
                      i, () => FocusNode(debugLabel: 'cast-credit'));
                  if (!_focused && i == 0) {
                    _focused = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) node.requestFocus();
                    });
                  }
                  return _remoteCard(PosterCard(
                      focusNode: node,
                      title: items[i].name,
                      imageUrl: items[i].posterUrl,
                      rating: items[i].year,
                      onTap: () async {
                        await widget.open(items[i]);
                        if (mounted) node.requestFocus();
                      },
                      onFocusGained: () {
                        if (node.context case final c?) {
                          Scrollable.ensureVisible(c);
                        }
                      }));
                });
          }));
}
