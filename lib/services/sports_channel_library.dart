import 'dart:convert';
import '../models/channel.dart';
import '../models/sports.dart';
import '../utils/channel_name_matching.dart';
import 'multiview_sports.dart';
import 'sports_networks.dart';
import 'storage_service.dart';

/// References only: never copies stream URLs or changes groups/favourites.
class SportsChannelList {
  SportsChannelList(
      {required this.id,
      required this.name,
      Iterable<String> channels = const []})
      : channels = channels.toList();
  final String id;
  String name;
  final List<String> channels;
  Map<String, List<String>> filters = {};
  final Set<String> excluded = {};
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'channels': channels,
        'filters': filters,
        'excluded': excluded.toList()
      };
}

class SportsChannelLists {
  SportsChannelLists(this.storage, {String? viewerId})
      : _viewerId = viewerId ?? storage.getActiveViewerId() {
    try {
      final data =
          jsonDecode(storage.getSportsChannelLists(viewerId: _viewerId) ?? '{}')
              as Map;
      for (final row in data['lists'] as List? ?? []) {
        final list = SportsChannelList(
            id: row['id'] as String,
            name: row['name'] as String,
            channels: (row['channels'] as List).cast<String>());
        list.filters = _filters(row['filters']);
        list.excluded.addAll((row['excluded'] as List? ?? []).cast<String>());
        lists.add(list);
      }
      favoriteNetworks
          .addAll((data['favoriteNetworks'] as List? ?? []).cast<String>());
      for (final entry in (data['picks'] as Map? ?? {}).entries) {
        if (entry.value is String) {
          networkPicks[entry.key as String] = entry.value as String;
        }
      }
      for (final entry in (data['tags'] as Map? ?? {}).entries) {
        tags[entry.key as String] = _filters(entry.value);
      }
      for (final entry in (data['sources'] as Map? ?? {}).entries) {
        final value = Map<String, dynamic>.from(entry.value as Map);
        if ((value['until'] as num? ?? double.infinity) >
            DateTime.now().millisecondsSinceEpoch) {
          sources[entry.key as String] = value;
        }
      }
    } catch (_) {
      lists.clear();
    }
    _savedFields = _encodedFields();
    _savedFavorites = {...favoriteNetworks};
  }
  final StorageService storage;
  final String _viewerId;
  late Map<String, String> _savedFields;
  late Set<String> _savedFavorites;
  final List<SportsChannelList> lists = [];

  /// Network card ids ([SportsNetworkGroup.id]) favourited with hold OK:
  /// their own first row on the Networks page.
  final Set<String> favoriteNetworks = {};

  /// The channel picked for a network card with hold OK (card id ->
  /// channel id): what OK on the card plays. Was kept only while the page
  /// was open, so it was forgotten on every visit (user report, 2026-10-23).
  final Map<String, String> networkPicks = {};
  final Map<String, Map<String, List<String>>> tags = {};
  final Map<String, Map<String, dynamic>> sources = {};
  static Map<String, List<String>> _filters(dynamic raw) => raw is Map
      ? {
          for (final e in raw.entries)
            e.key as String: (e.value as List).cast<String>(),
        }
      : {};
  Map<String, dynamic> _data() => {
        'version': 1,
        'lists': lists.map((e) => e.toJson()).toList(),
        'favoriteNetworks': favoriteNetworks.toList(),
        'picks': networkPicks,
        'tags': tags,
        'sources': sources,
      };

  Map<String, String> _encodedFields() => {
        for (final entry in _data().entries) entry.key: jsonEncode(entry.value),
      };

  Future<void> save() {
    // Networks, list editors and game-source pickers hold separate snapshots.
    // A save must not overwrite a section this caller never edited. Favourites
    // merge per id so independent additions/removals survive an older picker.
    final current = SportsChannelLists(storage, viewerId: _viewerId)._data();
    final local = _data();
    for (final key in ['lists', 'picks', 'tags', 'sources']) {
      if (jsonEncode(local[key]) != _savedFields[key]) {
        current[key] = local[key];
      }
    }
    final favorites =
        (current['favoriteNetworks'] as List).cast<String>().toSet()
          ..removeAll(_savedFavorites.difference(favoriteNetworks))
          ..addAll(favoriteNetworks.difference(_savedFavorites));
    favoriteNetworks
      ..clear()
      ..addAll(favorites);
    current['favoriteNetworks'] = favorites.toList();
    final result =
        storage.setSportsChannelLists(jsonEncode(current), viewerId: _viewerId);
    _savedFields = _encodedFields();
    _savedFavorites = {...favoriteNetworks};
    return result;
  }

  SportsChannelList create(String name, Iterable<String> ids) {
    final list = SportsChannelList(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        channels: ids.toSet());
    lists.add(list);
    return list;
  }

  Future<void> setSources(String scope, Iterable<String> ids,
      {bool event = false}) async {
    sources[scope] = {
      'ids': ids.toSet().toList(),
      if (event)
        'until':
            DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch
    };
    await save();
  }

  Set<String> sourcesFor(SportsGame game, String eventKey) => {
        for (final key in [
          'event:$eventKey',
          'team:${game.league.id}:${game.home.id}',
          'team:${game.league.id}:${game.away.id}',
          'league:${game.league.id}'
        ])
          ...(sources[key]?['ids'] as List? ?? []).cast<String>(),
      };
}

/// One Channels card: a network and the user's channels of it.
class SportsNetworkGroup {
  SportsNetworkGroup(this.id, this.name, this.network);
  final String id;
  final String name;
  final SportsNetwork? network;
  final List<Channel> channels = [];

  /// The network's own logo, else the first channel with a logo (providers
  /// mostly share one per brand).
  String? get logoUrl =>
      network?.logoUrl ??
      channels
          .map((c) => c.logoUrl)
          .firstWhere((u) => u != null && u.isNotEmpty, orElse: () => null);
}

class SportsChannelLibrary {
  SportsChannelLibrary(Iterable<Channel> visible, {this.store})
      : channels = {
          for (final c in visible)
            if (c.isLive) c.id: c,
        }.values.toList();
  final List<Channel> channels;
  final SportsChannelLists? store;
  static final _baseTags = Expando<Map<String, List<String>>>();
  Map<String, List<String>> tagsFor(Channel c) => {
        ...(_baseTags[c] ??= _infer(c)),
        ...?store?.tags[c.id],
      };
  Map<String, List<String>> _infer(Channel c) {
    final name = c.sourceName.toUpperCase();
    final text = '$name ${c.group.toUpperCase()}';
    final country = RegExp(
            r'^\s*(US|USA|CA|CAFR|UK|GB|GR|FR|IT|ES|DE|BR|PT|AU|NZ|IE|RO|RS|HR|BG)\s*[:|\-]')
        .firstMatch(name)
        ?.group(1);
    final network = sportsNetworkOf(c);
    final sports = <String>[];
    for (final e in {
      'hockey': r'\b(HOCKEY|NHL|AHL)\b',
      'basketball': r'\b(BASKETBALL|NBA|WNBA)\b',
      'football': r'\b(NFL|CFL|AMERICAN FOOTBALL)\b',
      'soccer': r'\b(SOCCER|FUTBOL|UEFA|PREMIER LEAGUE)\b',
      'baseball': r'\b(BASEBALL|MLB)\b',
      'tennis': r'\b(TENNIS|ATP|WTA)\b',
      'golf': r'\b(GOLF|PGA)\b',
      'racing': r'\b(FORMULA|NASCAR|RACING)\b'
    }.entries) {
      if (RegExp(e.value).hasMatch(text)) sports.add(e.key);
    }
    // A network counts for the sports it carries: every sport for TSN,
    // ESPN, Sportsnet… (the hockey filter missed them all — owner,
    // 2026-10-22), only its own for NHL Network.
    if (network != null) {
      for (final sport in network.sports ?? kChannelSports) {
        if (!sports.contains(sport)) sports.add(sport);
      }
    }
    return {
      'Playlist': [c.playlistId],
      'Group': ['${c.playlistId}::${c.group}'],
      'Country': [
        country == 'USA'
            ? 'US'
            : country == 'CAFR'
                ? 'CA'
                : country == 'GB'
                    ? 'UK'
                    : country ?? 'Unknown'
      ],
      'Network': [network?.name ?? 'Unknown'],
      'Sport': sports.isEmpty ? ['Unknown'] : sports,
      'League': [
        for (final token in (RegExp(
                r'\b(NFL|NBA|WNBA|NHL|MLB|MLS|CFL|AHL|ECHL|ATP|WTA|PGA|F1)\b')
            .allMatches(text)))
          for (final l in [...kSportsLeagues, ...kSportsLeagueBank])
            if (l.shortName.toUpperCase() == token.group(1)) l.id
      ],
    };
  }

  bool accepts(Channel c, Map<String, List<String>> filters) {
    // No filter set: skip building every channel's tags.
    if (filters.values.every((v) => v.isEmpty)) return true;
    final tags = tagsFor(c);
    return filters.entries.every((e) =>
        e.key == 'All' ||
        (e.key == 'Query'
            ? e.value.any((v) => v
                .toLowerCase()
                .split(RegExp(r'\s+'))
                .every(c.name.toLowerCase().contains))
            : e.value.isEmpty ||
                e.value.any((v) => (tags[e.key]?.isNotEmpty ?? false)
                    ? tags[e.key]!.contains(v)
                    : v == 'Unknown')));
  }

  /// The Channels row [c] sits in ('' = not a sports channel). Cached per
  /// channel object, like [sportsNetworkOf].
  static String category(Channel c) =>
      _category[c] ??= switch (sportsNetworkOf(c)?.kind) {
        SportsNetworkKind.league => 'League networks',
        SportsNetworkKind.regional => 'Regional channels',
        SportsNetworkKind.sports => 'Sports networks',
        // No known network (often a whole "Sports" group of event
        // feeds): their own last row, so Sports networks stays networks.
        null => MultiviewSports.isSports(c) ? 'Other sports channels' : '',
      };
  static final _category = Expando<String>('sportsCategory');

  /// [channels] as network cards for [row] (a [category] name): every TSN
  /// feed and copy in one "TSN" card, ordered by [compareNetworkChannels].
  /// A sports channel of no known network gets a card of its own (its
  /// quality copies together). Cards with more channels first, then A–Z.
  static List<SportsNetworkGroup> groups(Iterable<Channel> channels,
      {required String row}) {
    final byId = <String, SportsNetworkGroup>{};
    for (final c in channels) {
      if (category(c) != row) continue;
      final network = sportsNetworkOf(c);
      final copy = channelCopyKey(c.sourceName);
      final id = network?.id ?? 'own:${copy.isEmpty ? c.id : copy}';
      (byId[id] ??= SportsNetworkGroup(
              id, network?.name ?? _displayName(c.name), network))
          .channels
          .add(c);
    }
    final out = byId.values.toList();
    for (final g in out) {
      g.channels.sort(compareNetworkChannels);
    }
    out.sort((a, b) {
      final known = (b.network != null ? 1 : 0) - (a.network != null ? 1 : 0);
      if (known != 0) return known;
      final size = b.channels.length.compareTo(a.channels.length);
      return size != 0 ? size : a.name.compareTo(b.name);
    });
    return out;
  }

  /// "US| ESPN NEWS FHD" -> "ESPN NEWS": the region tag and quality words
  /// off, for a card of no known network.
  static String _displayName(String name) {
    final noTag = name.replaceFirst(RegExp(r'^[^:|]{1,6}[:|]\s*'), '');
    final clean = noTag
        .replaceAll(
            RegExp(r'\b(FHD|UHD|HD|SD|4K|HEVC|1080P?|2160P?)\b',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return clean.isEmpty ? name : clean;
  }

  List<Channel> search({String query = '', String? group, Set<String>? ids}) {
    final words =
        query.toLowerCase().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    return channels
        .where((c) =>
            (group == null || '${c.playlistId}::${c.group}' == group) &&
            (ids == null || ids.contains(c.id)) &&
            words.every(c.name.toLowerCase().contains))
        .toList();
  }

  List<Channel> members(SportsChannelList list) {
    final byId = {for (final c in channels) c.id: c};
    final ids = {
      ...list.channels,
      if (list.filters.isNotEmpty)
        ...channels.where((c) => accepts(c, list.filters)).map((c) => c.id)
    }..removeAll(list.excluded);
    return [
      for (final id in ids)
        if (byId[id] case final c?) c
    ];
  }

  List<Channel> versions(Channel channel) {
    final key = channelCopyKey(channel.sourceName);
    return key.isEmpty
        ? [channel]
        : channels.where((c) => channelCopyKey(c.sourceName) == key).toList();
  }
}
