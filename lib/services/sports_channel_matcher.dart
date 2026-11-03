import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import '../models/channel.dart';
import '../models/epg_program.dart';
import '../models/sports.dart';
import 'greek_sports_names.dart';
import '../utils/channel_name_matching.dart';
import 'epg_service.dart';
import 'storage_service.dart';
import 'real_4k_channels.dart';
import 'sports_channel_countries.dart';
import '../l10n/l10n.dart';

/// Why a channel was suggested for a game — shown next to it so the user
/// can judge a match at a glance.
/// [teamChannel] and [network] are suggestions the guide didn't confirm
/// (a team's own channel, the broadcaster the schedule lists), and say so.
enum MatchReason { pick, name, guide, teamChannel, network }

extension MatchReasonLabel on MatchReason {
  String get label => switch (this) {
        MatchReason.pick => tr('Your pick'),
        MatchReason.name => tr('Found by its name'),
        MatchReason.guide => tr('Found in the guide'),
        MatchReason.teamChannel => tr("Team's channel, no guide listing"),
        MatchReason.network => tr('Broadcaster, no guide listing'),
      };
}

enum NoMatchCause { hiddenChannel, guideNotReaching, notFound }

/// Why a game has no channel — Discord's top Sports Trak complaint was an
/// unexplained "No channel found" (matching audit, 2026-10-21: of 63 empty
/// results, 45 had no guide programme at game time and 25 matched only a
/// channel the viewer had hidden).
class NoMatch {
  const NoMatch(this.cause, [this.channelName]);
  final NoMatchCause cause;

  /// The hidden channel that names the game ([NoMatchCause.hiddenChannel]).
  final String? channelName;

  /// One line under a game card.
  String get short => switch (cause) {
        NoMatchCause.hiddenChannel =>
          tr('On a hidden channel — OK to pick one'),
        NoMatchCause.guideNotReaching =>
          tr('Not in your guide yet — OK to pick one'),
        NoMatchCause.notFound => tr('No channel found — OK to pick one'),
      };

  /// The channel line of a small game card, where "Pick a channel" goes;
  /// null when nothing more specific than that can be said.
  String? get card => switch (cause) {
        NoMatchCause.hiddenChannel => tr('Only on a hidden channel'),
        NoMatchCause.guideNotReaching => tr('Not in your guide yet'),
        NoMatchCause.notFound => null,
      };

  /// The reason in full (game menu, live games list, player side panel);
  /// each screen adds how to pick a channel there.
  String get reason => switch (cause) {
        NoMatchCause.hiddenChannel => tr(
            'Only found on {channel}, which is hidden in your lists.',
            {'channel': channelName ?? ''}),
        NoMatchCause.guideNotReaching => tr(
            "Your guide doesn't cover this game's time yet. Update the guide closer to the game."),
        NoMatchCause.notFound =>
          tr('No channel name or guide listing names this game.'),
      };
}

/// [sorted] (best first) cut to [limit] distinct channels: each one's best
/// copy in order, then the other quality copies of those same channels
/// (`TSN 1 4K` / `FHD` / `HD`, [channelCopyKey]) after them. Copies used to
/// fill the 8 slots and push real matches out (audit item 5: 39 of 73
/// over-full games lost a guide-matched channel at the cut), and the live
/// list shows only the first 3. The copies stay pickable further down.
List<ChannelMatch> distinctCopiesFirst(List<ChannelMatch> sorted, int limit) {
  final leaders = <ChannelMatch>[];
  final copies = <String, List<ChannelMatch>>{};
  for (final m in sorted) {
    final key = channelCopyKey(m.channel.sourceName);
    final group = key.isEmpty ? null : copies[key];
    if (group != null) {
      group.add(m);
    } else if (leaders.length < limit) {
      leaders.add(m);
      if (key.isNotEmpty) copies[key] = [];
    }
  }
  return [
    ...leaders,
    for (final m in leaders) ...?copies[channelCopyKey(m.channel.sourceName)],
  ];
}

class ChannelMatch {
  const ChannelMatch(this.channel, this.reason, this.score,
      {this.detail, this.gameEvidence = false});
  final Channel channel;
  final MatchReason reason;
  final int score;

  /// Both-team/event-name or time-aligned guide evidence; generic series,
  /// team-channel and broadcaster fallbacks remain unconfirmed suggestions.
  final bool gameEvidence;

  /// Guide programme title / network name that produced the match.
  final String? detail;
}

/// The user's own game -> channel choices, per viewer. A pick for one game
/// (`events`) wins over a pick for a team (`teams`, "always use TSN 1 for
/// the Canadiens"). Event-named channels are renumbered by providers every
/// day, so those are only ever remembered for the one game.
class SportsChannelPicks {
  SportsChannelPicks._(this._storage, this._events, this.teams);

  factory SportsChannelPicks.load(StorageService storage) {
    final events = <String, _EventPick>{};
    final teams = <String, String>{};
    final raw = storage.getSportsChannelPicks();
    if (raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        final cutoff = DateTime.now()
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch;
        (m['events'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
          final p =
              _EventPick((v as Map)['c'] as String, (v['t'] as num).toInt());
          if (p.savedAtMs > cutoff) events[k] = p;
        });
        (m['teams'] as Map<String, dynamic>? ?? {})
            .forEach((k, v) => teams[k] = v as String);
      } catch (_) {
        // Corrupt prefs read back as "no picks", like the other JSON prefs.
      }
    }
    return SportsChannelPicks._(storage, events, teams);
  }

  final StorageService _storage;
  final Map<String, _EventPick> _events;
  final Map<String, String> teams;

  static String eventKey(SportsGame g) => '${g.league.id}:${g.id}';
  static String teamKey(SportsGame g, SportsTeam t) => '${g.league.id}:${t.id}';

  /// Event sports' "always for this series" pick (Sky Sports F1 for every
  /// F1 session). Stored with the team picks, under an empty team id.
  static String seriesKey(SportsGame g) => '${g.league.id}:*';

  /// Channel id the user chose for [g], game pick first, then either team
  /// (event sports: the series).
  String? channelIdFor(SportsGame g) =>
      _events[eventKey(g)]?.channelId ??
      (g.league.kind != SportsKind.team
          ? teams[seriesKey(g)]
          : teams[teamKey(g, g.first)] ?? teams[teamKey(g, g.second)]);

  Future<void> pickForSeries(SportsGame g, String channelId) {
    _reload();
    teams[seriesKey(g)] = channelId;
    _events.remove(eventKey(g));
    return _save();
  }

  Future<void> pickForGame(SportsGame g, String channelId) {
    _reload();
    _events[eventKey(g)] =
        _EventPick(channelId, DateTime.now().millisecondsSinceEpoch);
    return _save();
  }

  Future<void> pickForTeam(SportsGame g, SportsTeam t, String channelId) {
    _reload();
    teams[teamKey(g, t)] = channelId;
    // A fresh team pick should win over an older pick for this game.
    _events.remove(eventKey(g));
    return _save();
  }

  String? preferredChannel(String leagueId, String teamId) =>
      teams['$leagueId:$teamId'];

  /// The My Teams editor does not require a current/upcoming game. A
  /// separately chosen channel for one match continues to override this
  /// team default. Reload first so other open pickers cannot be overwritten.
  Future<void> setPreferredChannel(
      String leagueId, String teamId, String? channelId) {
    _reload();
    final key = '$leagueId:$teamId';
    if (channelId == null) {
      teams.remove(key);
    } else {
      teams[key] = channelId;
    }
    return _save();
  }

  /// The NFL RedZone pill's chosen channel (hold the pill). Stored with the
  /// team picks under a key no league/team id can produce; null = automatic.
  static const _redZoneKey = 'redzone';
  String? get redZoneChannelId => teams[_redZoneKey];

  Future<void> setRedZone(String? channelId) {
    _reload();
    if (channelId == null) {
      teams.remove(_redZoneKey);
    } else {
      teams[_redZoneKey] = channelId;
    }
    return _save();
  }

  Future<void> clearFor(SportsGame g) {
    _reload();
    _events.remove(eventKey(g));
    final c = teams[teamKey(g, g.first)];
    final d = teams[teamKey(g, g.second)];
    if (c != null) teams.remove(teamKey(g, g.first));
    if (d != null) teams.remove(teamKey(g, g.second));
    teams.remove(seriesKey(g));
    return _save();
  }

  bool get preferQuality => _storage.getSportsPreferQuality();

  SportsCountryPreferences get countryPreferences =>
      SportsCountryPreferences.load(_storage);

  String? get preferredPlaylist => _storage.getSportsPreferredPlaylist();

  List<ChannelMatch> orderMatches(List<ChannelMatch> matches,
      {SportsCountryPreferences? countries}) {
    final ordered = preferQuality ? preferSportsSources(matches) : matches;
    final preferences = countries ?? countryPreferences;
    final playlist = preferredPlaylist;
    if (preferences.selected.isEmpty && playlist == null) return ordered;
    final indices = {for (final (i, match) in ordered.indexed) match: i};
    final preferred = {
      for (final match in ordered)
        match: preferences.selected.isNotEmpty &&
            preferences.prefers(match.channel)
    };
    if (!preferred.values.any((value) => value) &&
        !ordered.any((match) => match.channel.playlistId == playlist)) {
      return ordered;
    }
    int tier(ChannelMatch match) => match.reason == MatchReason.pick
        ? (match.score >= 1000 ? 0 : 1)
        : match.gameEvidence
            ? 2
            : 3;
    return [...ordered]..sort((a, b) {
        final evidence = tier(a).compareTo(tier(b));
        if (evidence != 0) return evidence;
        if (tier(a) != 0 && playlist != null) {
          final aPlaylist = a.channel.playlistId == playlist;
          final bPlaylist = b.channel.playlistId == playlist;
          if (aPlaylist != bPlaylist) return aPlaylist ? -1 : 1;
        }
        if (tier(a) != 0 && preferred[a] != preferred[b]) {
          return preferred[a]! ? -1 : 1;
        }
        // Retain quality/copy ordering within each playlist/country group.
        return indices[a]!.compareTo(indices[b]!);
      });
  }

  void _reload() {
    final latest = SportsChannelPicks.load(_storage);
    _events
      ..clear()
      ..addAll(latest._events);
    teams
      ..clear()
      ..addAll(latest.teams);
  }

  Future<void> _save() => _storage.setSportsChannelPicks(jsonEncode({
        'events': _events
            .map((k, v) => MapEntry(k, {'c': v.channelId, 't': v.savedAtMs})),
        'teams': teams,
      }));
}

class _EventPick {
  const _EventPick(this.channelId, this.savedAtMs);
  final String channelId;
  final int savedAtMs;
}

/// Lower-case, accent-free, punctuation as spaces, single-spaced and padded
/// with a space each side — so `' red wings '` matches a whole phrase and
/// never the inside of another word.
String sportsNormalize(String s) {
  // Greek guides and channel names compare in Latin (greek_sports_names).
  if (hasGreek(s)) s = greekToLatin(s);
  final buffer = StringBuffer(' ');
  var lastSpace = true;
  // Code-unit checks, not a RegExp per character: this runs over every
  // channel name (tens of thousands) when the tab opens.
  for (final rune in s.toLowerCase().runes) {
    final isAscii = (rune >= 0x61 && rune <= 0x7a) ||
        (rune >= 0x30 && rune <= 0x39) ||
        rune == 0x2b;
    String? ch = isAscii ? String.fromCharCode(rune) : null;
    if (ch == null && rune > 0x7f) ch = _foldAccents[String.fromCharCode(rune)];
    if (ch != null) {
      buffer.write(ch);
      lastSpace = false;
    } else if (!lastSpace) {
      buffer.write(' ');
      lastSpace = true;
    }
  }
  if (!lastSpace) buffer.write(' ');
  return buffer.toString();
}

const Map<String, String> _foldAccents = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'ç': 'c',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ñ': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ø': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ý': 'y',
  'ß': 'ss',
  // Balkan, Turkish and Central European guides (Sport Klub, Arena:
  // "Beşiktaş", "Žalgiris", "Crvena zvezda") — unfolded they split words.
  'č': 'c',
  'ć': 'c',
  'š': 's',
  'ž': 'z',
  'đ': 'd',
  'ş': 's',
  'ğ': 'g',
  'ı': 'i',
  'ł': 'l',
  'ą': 'a',
  'ę': 'e',
  'ń': 'n',
  'ś': 's',
  'ź': 'z',
  'ż': 'z',
  'ő': 'o',
  'ű': 'u',
  'ř': 'r',
  'ě': 'e',
  'ů': 'u',
  'ț': 't',
  'ș': 's',
  'ă': 'a',
};

/// Streaming-only services ESPN lists that have no linear channel to find.
const Set<String> _streamingOnly = {
  'ESPN+',
  'PEACOCK',
  'PRIME VIDEO',
  'APPLE TV',
  'APPLE TV+',
  'PARAMOUNT+',
  'NETFLIX',
  'DAZN',
  'NFL+',
  'NBA LEAGUE PASS',
  'NHL.TV',
  'MLB.TV',
  'MAX',
  'YOUTUBE',
  'FUBO',
  'ESPN UNLMTD',
};

/// Regional sports networks as ESPN writes them in `broadcasts` (an
/// abbreviation) -> phrases their channels go by in playlists (normalized,
/// lower case). The exact-name check in matchDay finds none of these:
/// "MNMT" is "US - Monumental Sports Network HD" (NBA user report,
/// 2026-10-21: most regional games had no channel). FanDuel's networks keep
/// their old Bally Sports names on many providers, so both are listed.
const Map<String, List<String>> _networkAliases = {
  'MNMT': ['monumental'],
  'MONUMENTAL': ['monumental'],
  'NBC SPORTS CA': ['nbc sports california', 'nbcs california'],
  'NBCS-CA': ['nbc sports california', 'nbcs california'],
  'NBC SPORTS BA': ['nbc sports bay area', 'nbcs bay area'],
  'NBCS-BA': ['nbc sports bay area', 'nbcs bay area'],
  'NBC SPORTS PH': ['nbc sports philadelphia', 'nbcs philadelphia'],
  'NBCS-PH': ['nbc sports philadelphia', 'nbcs philadelphia'],
  'NBC SPORTS BOS': ['nbc sports boston', 'nbcs boston'],
  'NBCS-BOS': ['nbc sports boston', 'nbcs boston'],
  'CHSN': ['chicago sports network', 'chsn'],
  'GCSEN': ['gulf coast sports', 'gcsen'],
  'YES': ['yes network'],
  'MSG': ['msg'],
  'MSGSN': ['msg sportsnet', 'msg 2', 'msg'],
  'SNY': ['sny'],
  'NESN': ['nesn'],
  'MASN': ['masn'],
  'MARQUEE': ['marquee'],
  'SPECTRUM SN': ['spectrum sportsnet'],
  'SPECTRUM SPORTSNET': ['spectrum sportsnet'],
  'SPECTRUM SPORTSNET LA': ['spectrum sportsnet la', 'sportsnet la'],
  'SNLA': ['spectrum sportsnet la', 'sportsnet la'],
  'ALT': ['altitude'],
  'ALTITUDE': ['altitude'],
  'ROOT SPORTS': ['root sports'],
  'ROOT': ['root sports'],
  'SCHN': ['space city'],
  'SPACE CITY HOME NETWORK': ['space city'],
  'FDSDET': [
    'fanduel sports network detroit',
    'fanduel sports detroit',
    'bally sports detroit'
  ],
  'FDSFL': [
    'fanduel sports network florida',
    'fanduel sports florida',
    'bally sports florida'
  ],
  'FDSSUN': [
    'fanduel sports network sun',
    'fanduel sports sun',
    'bally sports sun'
  ],
  'FDSSE': [
    'fanduel sports network southeast',
    'fanduel sports southeast',
    'bally sports southeast'
  ],
  'FDSSO': [
    'fanduel sports network south',
    'fanduel sports south',
    'bally sports south'
  ],
  'FDSIN': [
    'fanduel sports network indiana',
    'fanduel sports indiana',
    'bally sports indiana'
  ],
  'FDSOH': [
    'fanduel sports network ohio',
    'fanduel sports ohio',
    'bally sports ohio'
  ],
  'FDSWI': [
    'fanduel sports network wisconsin',
    'fanduel sports wisconsin',
    'bally sports wisconsin'
  ],
  'FDSN': [
    'fanduel sports network north',
    'fanduel sports north',
    'bally sports north'
  ],
  'FDSNO': [
    'fanduel sports network new orleans',
    'fanduel sports new orleans',
    'bally sports new orleans'
  ],
  'FDSSW': [
    'fanduel sports network southwest',
    'fanduel sports southwest',
    'bally sports southwest'
  ],
  'FDSMW': [
    'fanduel sports network midwest',
    'fanduel sports midwest',
    'bally sports midwest'
  ],
  'FDSOK': [
    'fanduel sports network oklahoma',
    'fanduel sports oklahoma',
    'bally sports oklahoma'
  ],
  'FDSSD': [
    'fanduel sports network san diego',
    'fanduel sports san diego',
    'bally sports san diego'
  ],
  'FDSWC': [
    'fanduel sports network socal',
    'fanduel sports socal',
    'bally sports socal'
  ],
  'FDSKC': [
    'fanduel sports network kansas city',
    'fanduel sports kansas city',
    'bally sports kansas city'
  ],
  'FDSCIN': [
    'fanduel sports network cincinnati',
    'fanduel sports cincinnati',
    'bally sports ohio'
  ],
};

/// Schedule labels for US national networks that no exact channel name
/// matches ("CBSSN", "NFL Net"). Stricter than [_networkAliases]: the
/// channel must be tagged US and be exactly that network once the tag and
/// quality are stripped — no Canadian USA Network, no West feed, no Plus
/// service, no dated event channel named after the network. Measured on
/// three providers' guides (dev-notes/sports-matcher-audit): 14 empty
/// results got a channel, no wrong ones.
const Map<String, List<String>> _usNetworkNames = {
  'CBSSN': ['cbs sports network'],
  'NFL NET': ['nfl network'],
  'NHL NET': ['nhl network'],
  'NBC SPORTS PHIL': ['nbc sports philadelphia'],
  'USA NET': ['usa network', 'usa network east'],
};

/// A US/Canadian TV station's call sign ("KJZZ-TV", "KUNP 16", "WGN"):
/// its channel names carry it ("US - KJZZ 14 SALT LAKE CITY").
final RegExp _callSign =
    RegExp(r'^([KW][A-Z]{2,3})(?:-(?:TV|DT|CD|LD))?(?: \d+)?$');

const Set<String> _englishTags = {'us', 'usa', 'ca', 'uk', 'en', 'english'};

/// Country/language tags providers put in channel names. Two-letter tags
/// only count as whole words (names are normalized and split on spaces).
const Set<String> _foreignTags = {
  'es',
  'se',
  'fi',
  'de',
  'fr',
  'nl',
  'it',
  'pt',
  'pl',
  'ru',
  'ar',
  'tr',
  'br',
  'mx',
  'dk',
  'no',
  'gr',
  'ro',
  'hu',
  'cz',
  'al',
  'rs',
  'hr',
  'bg',
  'espanol',
  'beisbol',
  'latino',
  'latam',
  'arabic',
  'francais',
};

const _months = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'sept': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

/// Team codes that providers and ESPN spell differently ("WAS" vs ESPN's
/// "WSH"). Each group is one team per league; leagues share the groups
/// because a game's two codes are always checked together.
const List<List<String>> _abbrGroups = [
  ['WSH', 'WAS'],
  ['GS', 'GSW'],
  ['NO', 'NOP', 'NOR', 'NOS'],
  ['NY', 'NYK'],
  ['SA', 'SAS'],
  ['UTAH', 'UTA'],
  ['PHX', 'PHO'],
  ['BKN', 'BRK'],
  ['JAX', 'JAC'],
  ['LV', 'LVR'],
  ['VGK', 'VEG'],
  ['NE', 'NWE'],
  ['GB', 'GNB'],
  ['SF', 'SFO', 'SFG'],
  ['TB', 'TAM', 'TBL', 'TBR'],
  ['KC', 'KCC', 'KCR'],
  ['LA', 'LAK'],
  ['NJ', 'NJD'],
  ['SJ', 'SJS'],
  ['MTL', 'MON'],
  ['CGY', 'CAL'],
  ['NSH', 'NAS'],
  ['CBJ', 'CLB'],
  ['CHW', 'CWS'],
  ['SD', 'SDP'],
  ['ARI', 'AZ'],
];

final Map<String, String> _abbrCanonical = {
  for (final group in _abbrGroups)
    for (final code in group) code: group.first,
};

String _canonicalAbbr(String code) => _abbrCanonical[code] ?? code;

/// A channel named after one game in team codes: "B01: 7pm CHA @ DET",
/// "FB01 : 8:15 DAL @ PHI". [minutes] is the 12-hour clock time written in
/// the name (minutes past 12), [zone] its US zone tag (et/ct/mt/pt) if any.
typedef _AbbrEvent = ({
  int index,
  String first,
  String second,
  bool at,
  int minutes,
  String? zone,
  Set<String> sports,
});

/// Words in a provider group that name a sport (ESPN path's first part).
/// "Football" alone may be soccer outside North America.
const Map<String, List<String>> _groupSports = {
  'basketball': ['basketball'],
  'nba': ['basketball'],
  'wnba': ['basketball'],
  'ncaab': ['basketball'],
  'hockey': ['hockey'],
  'nhl': ['hockey'],
  'ahl': ['hockey'],
  'echl': ['hockey'],
  'baseball': ['baseball'],
  'mlb': ['baseball'],
  'nfl': ['football'],
  'ncaaf': ['football'],
  'cfl': ['football'],
  'football': ['football', 'soccer'],
  'soccer': ['soccer'],
  'mls': ['soccer'],
  'futbol': ['soccer'],
};

/// The sports a channel's group names ("Baseball Playoffs" -> baseball);
/// empty when it names none.
Set<String> _sportsOfGroup(String group) => {
      for (final w in sportsNormalize(group).trim().split(' '))
        ...?_groupSports[w],
    };

final _abbrPair = RegExp(
    r'(?<![A-Za-z])([A-Z]{2,4})\s*(@|vs\.?|VS\.?|v|V|at|AT)\s*([A-Z]{2,4})(?![A-Za-z])');
final _clock = RegExp(
    r'(?<![\d:])(\d{1,2})(?::(\d{2}))?\s*(am|pm|a|p)?(?![\w:])',
    caseSensitive: false);
final _zoneTag = RegExp(r'\b(E|C|M|P)(?:S|D)?T\b');

/// [name] as an abbreviated event channel, or null. Needs both codes and a
/// clock time ("7pm", "7:30pm", "8:15"); a bare "01" is a channel number.
_AbbrEvent? _parseAbbrEvent(int index, String name, String group) {
  if (!name.contains('@') && !name.contains(RegExp(r'\b(vs|VS|v|V|at|AT)\b'))) {
    return null;
  }
  final pair = _abbrPair.firstMatch(name);
  if (pair == null) return null;
  int? minutes;
  for (final m in _clock.allMatches(name)) {
    if (m.group(2) == null && m.group(3) == null) continue;
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2) ?? '0');
    if (h > 23 || min > 59) continue;
    minutes = (h % 12) * 60 + min;
    break;
  }
  if (minutes == null) return null;
  final sep = pair.group(2)!.toLowerCase();
  return (
    index: index,
    first: _canonicalAbbr(pair.group(1)!),
    second: _canonicalAbbr(pair.group(3)!),
    at: sep == '@' || sep == 'at',
    minutes: minutes,
    zone: _zoneTag.firstMatch(name)?.group(1)?.toLowerCase(),
    sports: _sportsOfGroup(group),
  );
}

/// US Eastern offset from UTC at [utc] (DST: second Sunday of March to the
/// first Sunday of November, 2 a.m. local). Event channel times are Eastern.
Duration _easternOffset(DateTime utc) {
  DateTime nthSunday(int month, int n) {
    final first = DateTime.utc(utc.year, month, 1);
    final toSunday = (DateTime.sunday - first.weekday) % 7;
    return first.add(Duration(days: toSunday + 7 * (n - 1)));
  }

  final start = nthSunday(3, 2).add(const Duration(hours: 7));
  final end = nthSunday(11, 1).add(const Duration(hours: 6));
  final dst = !utc.isBefore(start) && utc.isBefore(end);
  return Duration(hours: dst ? -4 : -5);
}

/// App language -> the channel-name country tag that viewer watches. Only
/// Greek so far: French/Spanish/Italian viewers of this app mostly watch
/// North American feeds, which rank first by default.
const Map<String, String> _languageTags = {'el': 'gr'};

/// Finds IPTV channels for games, best signal first (measured on a real
/// provider, see dev-notes/sports-tab.md "Channel-matching test"):
/// 1. the user's own pick,
/// 2. **event channels named after the game** ("NHL | 01 - 7pm Kraken @ Red
///    Wings") — the strongest automatic signal,
/// 3. a guide programme around the start time naming both teams,
/// 4. the national network the provider lists (ESPN, TNT, ...), exact
///    channel-name match only — fuzzy network matching ("Fox" -> 500+
///    channels) was useless in testing.
///
/// Build once per channel list ([prepare]), then [matchDay] per day shown.
class SportsChannelMatcher {
  SportsChannelMatcher(this._epg);

  static SportsChannelMatcher? _shared;

  /// One matcher for the whole app (Sports hub, live list, player side
  /// panel): its channel index and guide-scan cache then survive leaving
  /// Sports — a new one per visit re-indexed every channel and re-ran the
  /// guide scan each time the hub was reopened (owner, 2026-10-17).
  static SportsChannelMatcher shared(EpgService epg) {
    final m = _shared;
    if (m != null && identical(m._epg, epg)) return m;
    return _shared = SportsChannelMatcher(epg);
  }

  final EpgService _epg;

  List<Channel> _channels = const [];
  List<String> _names = const [];
  Map<String, List<int>> _tokenIndex = {};
  Map<String, List<int>> _byCanonical = {};
  Map<String, List<int>> _byEpgId = {};
  Map<String, int> _byId = {};
  List<_AbbrEvent> _abbrEvents = const [];
  int? _preparedFor;

  /// Channels the viewer hid (groups or one by one), never suggested — only
  /// used to say a game's channel is one of them ([whyNoMatch]).
  List<Channel> _hidden = const [];
  List<String>? _hiddenNames;
  Map<String, String> _hiddenByEpgId = {};

  /// [_hidden]'s names normalized, on first need: hidden groups can hold
  /// most of a provider (every foreign country), and most days every game
  /// has a channel.
  Future<List<String>> _hiddenNormalized() async {
    final done = _hiddenNames;
    if (done != null) return done;
    final hidden = _hidden;
    final names = List<String>.filled(hidden.length, '');
    for (var i = 0; i < hidden.length; i++) {
      if (i % 3000 == 2999) await Future<void>.delayed(Duration.zero);
      names[i] = sportsNormalize(hidden[i].sourceName);
    }
    if (identical(hidden, _hidden)) _hiddenNames = names;
    return names;
  }

  final Map<String, NoMatch> _noMatch = {};

  /// Why [g] got no channel at its last [matchDay]; null when it has one or
  /// hasn't been matched.
  NoMatch? whyNoMatch(SportsGame g) => _noMatch[SportsChannelPicks.eventKey(g)];

  /// [whyNoMatch] on the app's shared matcher; null before Sports Trak
  /// has matched anything.
  static NoMatch? sharedWhyNoMatch(SportsGame g) => _shared?.whyNoMatch(g);

  Channel? channelById(String id) {
    final i = _byId[id];
    return i == null ? null : _channels[i];
  }

  List<Channel> get channels => _channels;

  /// Indexes [channels] (tens of thousands on big providers). Yields to the
  /// event loop every few thousand rows so a weak box keeps drawing.
  /// [hidden]: the viewer's hidden live channels, see [whyNoMatch].
  Future<void> prepare(List<Channel> channels,
      {List<Channel> hidden = const []}) async {
    // visibleChannels() builds a new list per call, so compare a signature
    // rather than identity. Every id, name and guide id goes into it: the
    // old count + first/last id missed a renamed channel or a changed EPG
    // override in the middle, and kept matching against the stale index
    // (matching audit, 2026-10-21).
    var signature = Object.hash(channels.length, hidden.length);
    for (final list in [channels, hidden]) {
      for (final c in list) {
        signature = Object.hash(signature, c.id, c.sourceName, c.epgId);
      }
    }
    if (_preparedFor == signature) return;
    final tokenIndex = <String, List<int>>{};
    final byCanonical = <String, List<int>>{};
    final byEpgId = <String, List<int>>{};
    final byId = <String, int>{};
    final abbrEvents = <_AbbrEvent>[];
    channels = List.of(channels);
    hidden = List.of(hidden);
    final names = List<String>.filled(channels.length, '');
    for (var i = 0; i < channels.length; i++) {
      if (i % 3000 == 2999) await Future<void>.delayed(Duration.zero);
      final c = channels[i];
      final norm = sportsNormalize(c.sourceName);
      names[i] = norm;
      byId[c.id] = i;
      for (final t in norm.trim().split(' ')) {
        if (t.length < 3) continue;
        final list = tokenIndex[t] ??= <int>[];
        if (list.isEmpty || list.last != i) list.add(i);
      }
      final canon = canonicalChannelKey(c.sourceName);
      if (canon.isNotEmpty) (byCanonical[canon] ??= <int>[]).add(i);
      (byEpgId[normalizeEpgId(c.epgId)] ??= <int>[]).add(i);
      if (_parseAbbrEvent(i, c.sourceName, c.group) case final e?) abbrEvents.add(e);
    }
    _channels = channels;
    _abbrEvents = abbrEvents;
    _names = names;
    _tokenIndex = tokenIndex;
    _byCanonical = byCanonical;
    _byEpgId = byEpgId;
    _byId = byId;
    _hidden = hidden;
    _hiddenNames = null;
    _hiddenByEpgId = {
      for (final c in hidden.reversed) normalizeEpgId(c.epgId): c.sourceName,
    };
    _preparedFor = signature;
  }

  /// Name phrases a channel or programme title may use for [t] — nickname
  /// and full name. City names alone are skipped (two New York teams).
  static List<String> _teamPhrases(SportsTeam t) {
    final out = <String>{};
    for (final s in [t.shortName, t.name]) {
      final n = sportsNormalize(s);
      if (n.trim().length >= 4) out.add(n);
      // A Greek club: how a transliterated Greek title spells it (short
      // ones like "aek" included — they're whole words).
      if (greekTeamFor(n) case final greek?) out.addAll(greek.phrases);
    }
    return out.toList();
  }

  /// The name groups a channel name or guide title must all contain (one
  /// phrase from each). Team sports: the two teams. Fights: the two
  /// fighters (tennis: players), by full or last name — event channels say
  /// "Allen vs Duncan".
  /// Golf/racing: the event alone ("singapore grand prix").
  static List<List<String>> _nameGroups(SportsGame g) {
    if (g.isEventOnly && g.league.kind == SportsKind.fight) {
      var title = (g.event?.title ?? '').replaceAll(RegExp(r'#\d+'), '').trim();
      // "Players Championship 33", "Bahrain Darts Masters Day 1": guides
      // name the event, not its number or day.
      if (g.league.isDarts) {
        title = title
            .replaceAll(RegExp(r'\bday\s*\d+\b', caseSensitive: false), '')
            .replaceAll(RegExp(r'\b\d+\b'), '')
            .trim();
      }
      final normalized = sportsNormalize(title);
      // "Canelo Alvarez vs Terence Crawford": each fighter, not the whole
      // title word for word (channels say "Canelo vs Crawford", a user
      // found no match, 1.0.51).
      final sides = _fightTitleSides(normalized);
      if (sides != null) return sides;
      final names = <String>{if (title.isNotEmpty) normalized};
      final lower = title.toLowerCase();
      final shows = g.league.id == 'wrestling.wwe'
          ? ['raw', 'smackdown', 'nxt']
          : g.league.id == 'wrestling.aew'
              ? ['dynamite', 'collision']
              : <String>[];
      for (final show in shows) {
        if (RegExp('\\b$show\\b').hasMatch(lower)) {
          names.add(sportsNormalize('${g.league.shortName} $show'));
          names.add(sportsNormalize(show));
        }
      }
      return names.isEmpty ? const [] : [names.toList()];
    }
    switch (g.league.kind) {
      case SportsKind.team:
        return [_teamPhrases(g.home), _teamPhrases(g.away)];
      case SportsKind.fight:
      case SportsKind.tennis:
        return [_fighterPhrases(g.home), _fighterPhrases(g.away)];
      case SportsKind.golf:
      case SportsKind.racing:
        final title = sportsNormalize(g.event?.title ?? g.home.name);
        final out = <String>{if (title.trim().length >= 6) title};
        // Sponsors pad the names ("Singapore Airlines Singapore Grand
        // Prix", "Butterfield Bermuda Championship"); guides use the core.
        final words = title.trim().split(' ');
        final gp = title.indexOf(' grand prix ');
        if (gp > 0) {
          final before = title.substring(0, gp).trim().split(' ').last;
          out.add(' $before grand prix ');
        } else if (g.league.kind == SportsKind.golf && words.length > 2) {
          out.add(' ${words.sublist(words.length - 2).join(' ')} ');
        }
        return [out.toList()];
    }
  }

  static const _nameSuffixes = {'jr', 'sr', 'ii', 'iii', 'iv'};

  /// Fighters known by a ring name, which channel names use instead of the
  /// legal name the schedule feeds give: full name -> ring name.
  static const _fighterAliases = {
    ' saul alvarez ': ' canelo ',
    ' santos saul alvarez ': ' canelo ',
  };

  static List<String> _fighterPhrases(SportsTeam t) {
    final full = sportsNormalize(t.name);
    final words =
        full.trim().split(' ').where((w) => !_nameSuffixes.contains(w));
    final last = words.isEmpty ? null : words.last;
    return {
      if (full.trim().length >= 4) full,
      if (last != null && last.length >= 4) ' $last ',
      for (final e in _fighterAliases.entries)
        if (full.contains(e.key)) e.value,
      // "Canelo Alvarez" as a listed name: the ring name alone too.
      if (full.contains(' canelo ')) ' canelo ',
    }.toList();
  }

  /// An event-only fight title split at "vs": each fighter is the two
  /// words next to it ("ufc 300 alex pereira", "terence crawford main
  /// card"), plus each side whole and known ring names.
  /// Null when the title is not "A vs B" (shows, cards without a bout).
  static List<List<String>>? _fightTitleSides(String normalized) {
    final parts = normalized.split(RegExp(r' (?:vs|v|x) '));
    if (parts.length != 2) return null;
    List<String> side(String text, {required bool left}) {
      final words = text
          .trim()
          .split(' ')
          .where((w) => w.isNotEmpty && !_nameSuffixes.contains(w))
          .toList();
      if (words.isEmpty) return const [];
      // The two words next to "vs" (first and last name), minus filler.
      final near = (left ? words.reversed : words)
          .where((w) => !_fightFiller.contains(w))
          .take(2);
      final whole = ' ${words.join(' ')} ';
      return {
        for (final w in near)
          if (w.length >= 4) ' $w ',
        if (whole.trim().length >= 4) whole,
        for (final e in _fighterAliases.entries)
          if (whole.contains(e.key)) e.value,
        if (whole.contains(' canelo ')) ' canelo ',
      }.toList();
    }

    final a = side(parts[0], left: true);
    final b = side(parts[1], left: false);
    if (a.isEmpty || b.isEmpty) return null;
    return [a, b];
  }

  static const _fightFiller = {
    'main',
    'card',
    'event',
    'fight',
    'night',
    'boxing',
    'title',
    'ufc',
    'ppv',
    'live',
    'undisputed',
    'championship',
    'world',
    'prelims',
  };

  /// A channel name that carries fights ("DAZN PPV 1", "Boxing: ...",
  /// "... vs ..."): one fighter's name is enough there.
  static final _fightChannelCue = RegExp(
      r' (?:ppv|boxing|box|fight|fights|fight night|dazn|vs|v|ufc|mma|pbc|main event|undercard|ring) ');

  /// When a guide programme for [g] may start: around a game's start; a
  /// fight card's main event comes hours after the prelims; a golf round
  /// runs all day, so its day (today's, while it's on).
  static (DateTime, DateTime) _guideWindow(SportsGame g) {
    if (g.end != null) {
      final now = DateTime.now().toUtc();
      final from = now.isAfter(g.start) &&
              now.isBefore(g.end!.add(const Duration(days: 1)))
          ? now.subtract(const Duration(hours: 2))
          : g.start;
      return (from, from.add(const Duration(hours: 24)));
    }
    // Tennis times are "not before": a match often starts hours late.
    // Darts: TheSportsDB times the tournament day/session, not each match,
    // and a PDC day runs from the afternoon into the evening session.
    final after = g.league.isDarts
        ? const Duration(hours: 12)
        : switch (g.league.kind) {
            SportsKind.fight => const Duration(hours: 5),
            SportsKind.tennis => const Duration(hours: 4),
            _ => const Duration(minutes: 30),
          };
    return (g.start.subtract(const Duration(minutes: 60)), g.start.add(after));
  }

  /// Channel indexes whose name contains one of [phrases] as whole words.
  Set<int> _channelsNaming(List<String> phrases) {
    final hits = <int>{};
    for (final phrase in phrases) {
      final words = phrase.trim().split(' ').where((w) => w.length >= 3);
      if (words.isEmpty) continue;
      // Walk the rarest word's postings, verify the full phrase.
      List<int>? best;
      for (final w in words) {
        final list = _tokenIndex[w];
        if (list == null) {
          best = null;
          break;
        }
        if (best == null || list.length < best.length) best = list;
      }
      if (best == null) continue;
      for (final i in best) {
        if (_names[i].contains(phrase)) hits.add(i);
      }
    }
    return hits;
  }

  /// A date written in an event channel's name ("Oct 13", "13 Oct",
  /// "2026-10-13"), or null. Lets yesterday's leftover event channels — and the
  /// next meeting of the same two teams — be told apart from today's.
  static ({int month, int day})? _dateInName(String norm) {
    final m1 = RegExp(
            r' (jan|feb|mar|apr|may|jun|jul|aug|sept?|oct|nov|dec)[a-z]* (\d{1,2})(?:st|nd|rd|th)? ')
        .firstMatch(norm);
    if (m1 != null) {
      return (month: _months[m1.group(1)]!, day: int.parse(m1.group(2)!));
    }
    final m2 = RegExp(
            r' (\d{1,2})(?:st|nd|rd|th)? (jan|feb|mar|apr|may|jun|jul|aug|sept?|oct|nov|dec)[a-z]* ')
        .firstMatch(norm);
    if (m2 != null) {
      return (month: _months[m2.group(2)]!, day: int.parse(m2.group(1)!));
    }
    // ISO "2026-10-13" (normalized to " 2026 10 13 ").
    final m3 = RegExp(r' 20\d\d (\d{1,2}) (\d{1,2}) ').firstMatch(norm);
    if (m3 != null) {
      final month = int.parse(m3.group(1)!);
      final day = int.parse(m3.group(2)!);
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return (month: month, day: day);
      }
    }
    return null;
  }

  static bool _dateFits(({int month, int day}) d, DateTime startUtc) {
    // The name's date may be the provider's local date, Eastern time, or
    // Europe's next day for an evening game — any of start-1d..start+1d.
    for (final offset in const [-1, 0, 1]) {
      final day = startUtc.add(Duration(days: offset));
      if (day.month == d.month && day.day == d.day) return true;
    }
    return false;
  }

  /// Providers carry the same game in many languages; the app's audience
  /// watches North American / English feeds, so those rank first and
  /// obviously foreign ones (country tags in the name) sink. Only reorders —
  /// nothing is dropped except for network matches.
  ///
  /// A league's own country ([SportsLeague.homeTags]: "gr" for the Greek
  /// leagues) ranks its channels first instead (+20, above English), and so
  /// does the viewer's own when the app is in Greek ([_languageTags]: a Greek
  /// viewer's EuroLeague game listed the Croatian feeds above Nova, owner,
  /// 2026-10-20).
  int _regionBias(int index, [SportsLeague? league]) {
    final tokens = _names[index].trim().split(' ');
    final home = league?.homeTags ?? const <String>[];
    final own = _languageTags[L10n.code];
    var bias = 0;
    for (final t in tokens) {
      if (home.contains(t) || t == own) return 20;
    }
    for (final t in tokens) {
      if (_englishTags.contains(t)) bias = math.max(bias, 10);
      if (_foreignTags.contains(t)) return -30;
    }
    return bias;
  }

  /// The guide title scan, by its window + terms. It's one SQL `LIKE` per
  /// term over the whole guide — on a busy Saturday (dozens of college
  /// games, hundreds of terms) the Formuler took long enough that the Sports
  /// hub stayed on "Looking…", and every 30 s score refresh ran it again.
  /// The guide barely changes, so a hit is reused for 15 minutes, and a
  /// scan already running is shared instead of started twice.
  Map<String, (Future<List<EpgProgram>>, DateTime)> _guideCache = {};

  Future<List<EpgProgram>> _guideHits(
      DateTime from, DateTime to, Set<String> terms) {
    // Stable outward-rounded hours preserve candidates and cache reuse.
    const hour = Duration.millisecondsPerHour;
    from = DateTime.fromMillisecondsSinceEpoch(
        from.millisecondsSinceEpoch ~/ hour * hour,
        isUtc: true);
    to = DateTime.fromMillisecondsSinceEpoch(
        (to.millisecondsSinceEpoch + hour - 1) ~/ hour * hour,
        isUtc: true);
    // A guide refresh changes lastUpdated: rescan at once, not after 15 min.
    final key = '${_epg.lastUpdated?.millisecondsSinceEpoch}|'
        '${from.millisecondsSinceEpoch}|${to.millisecondsSinceEpoch}|'
        '${(terms.toList()..sort()).join('\u0001')}';
    final now = DateTime.now();
    _guideCache.removeWhere(
        (_, v) => now.difference(v.$2) > const Duration(minutes: 15));
    final hit = _guideCache[key];
    if (hit != null) return hit.$1;
    if (_guideCache.length >= 128) _guideCache.remove(_guideCache.keys.first);
    final future = _epg.findProgrammesByTitle(from, to, terms.toList());
    _guideCache[key] = (future, now);
    return future;
  }

  /// Suggestions for every game in [games], keyed by
  /// [SportsChannelPicks.eventKey], best first, at most [limit] each.
  Future<Map<String, List<ChannelMatch>>> matchDay(
      List<SportsGame> games, SportsChannelPicks picks,
      {int limit = 8}) async {
    // prepare() can replace the shared index during a guide query or hidden
    // name normalization. One match uses an immutable snapshot throughout.
    final snapshot = SportsChannelMatcher(_epg)
      .._channels = _channels
      .._names = _names
      .._tokenIndex = _tokenIndex
      .._byCanonical = _byCanonical
      .._byEpgId = _byEpgId
      .._byId = _byId
      .._abbrEvents = _abbrEvents
      .._hidden = _hidden
      .._hiddenNames = _hiddenNames
      .._hiddenByEpgId = _hiddenByEpgId
      .._guideCache = _guideCache;
    final result =
        await snapshot._matchDay(List.of(games), picks, limit: limit);
    if (identical(_channels, snapshot._channels)) {
      for (final g in games) {
        final key = SportsChannelPicks.eventKey(g);
        final reason = snapshot._noMatch[key];
        if (reason == null) {
          _noMatch.remove(key);
        } else {
          _noMatch[key] = reason;
        }
      }
    }
    return result;
  }

  Future<Map<String, List<ChannelMatch>>> _matchDay(
      List<SportsGame> games, SportsChannelPicks picks,
      {int limit = 8}) async {
    final out = <String, List<ChannelMatch>>{};
    if (games.isEmpty) return out;
    final countries = picks.countryPreferences;
    final preferredPlaylist = picks.preferredPlaylist;
    // Keep the existing capped series/network suggestions, but let a valid
    // preferred-playlist candidate reach the cap before other playlists.
    // With no preference this returns the exact original iteration order.
    Iterable<int> playlistFirst(Iterable<int> hits) {
      if (preferredPlaylist == null) return hits;
      final list = hits.toList();
      return [
        ...list.where((i) => _channels[i].playlistId == preferredPlaylist),
        ...list.where((i) => _channels[i].playlistId != preferredPlaylist),
      ];
    }

    // One guide query for the whole day. A title must name every group
    // (both teams), and the loop below checks that — so SQL only needs one
    // group per game to find every candidate. Terms containing a shorter
    // term are dropped too ("georgia bulldogs" ⊃ "georgia"). Each term is a
    // LIKE over every guide row of the day: fewer terms, faster hub.
    final now = DateTime.now().toUtc();
    // A selected future day still works; mixed My Teams dates may not expand
    // a scan across weeks. Only nearby games contribute SQL candidate terms.
    final ordered = [...games]..sort((a, b) => a.start.compareTo(b.start));
    final anchor =
        ordered.where((g) => _guideWindow(g).$2.isAfter(now)).firstOrNull ??
            ordered.last;
    final lower = _guideWindow(anchor).$1;
    final upper = lower.add(const Duration(hours: 36));
    final scanGames = games.where((g) {
      final (from, to) = _guideWindow(g);
      return from.isBefore(upper) && to.isAfter(lower);
    }).toList();
    final raw = <String>{};
    for (final g in scanGames) {
      final groups = _nameGroups(g);
      if (groups.isNotEmpty) {
        for (final p in groups.first) {
          if (p.trim().isNotEmpty) raw.add(p.trim());
        }
      }
      for (final p in g.league.seriesPhrases) {
        if (p.trim().isNotEmpty) raw.add(p.trim());
      }
      // Greek clubs: the guide may write them in Greek. Both teams, since
      // a Latin term can't find a Greek title for the other one.
      for (final t in [g.home, g.away]) {
        final greek = greekTeamFor(sportsNormalize(t.name)) ??
            greekTeamFor(sportsNormalize(t.shortName));
        if (greek != null) raw.addAll(greek.stems);
      }
    }
    final byLength = raw.toList()..sort((a, b) => a.length.compareTo(b.length));
    final terms = <String>{};
    for (final t in byLength) {
      if (!terms.any(t.contains)) terms.add(t);
    }
    final earliest = lower;
    var latest = _guideWindow(anchor).$2;
    for (final g in scanGames) {
      final (_, to) = _guideWindow(g);
      if (to.isAfter(latest)) latest = to;
    }
    if (latest.isAfter(upper)) latest = upper;
    final List<EpgProgram> programmes =
        _byEpgId.isEmpty ? const [] : await _guideHits(earliest, latest, terms);

    // Team leagues with series phrases (EuroLeague): a title naming the
    // series but not this game's teams still counts — Greek guides write
    // foreign clubs in Greek ("Euroleague: Χάποελ Τελ Αβίβ - Βίρτους
    // Μπολόνια", user report 2026-10-20) — unless it names another game.
    final groupsByGame = {for (final g in games) g: _nameGroups(g)};
    bool namesOtherGame(SportsGame g, String title) =>
        groupsByGame.entries.any((o) =>
            o.key != g &&
            o.key.league.id == g.league.id &&
            o.value.every((group) => group.any(title.contains)));

    for (final g in games) {
      // A guide programme naming the game on a channel the viewer hid.
      String? hiddenInGuide;
      final found = <String, ChannelMatch>{};
      void add(int index, MatchReason reason, int score,
          [String? detail, bool gameEvidence = false]) {
        final c = _channels[index];
        final existing = found[c.id];
        if (existing == null || existing.score < score) {
          found[c.id] = ChannelMatch(c, reason, score,
              detail: detail,
              gameEvidence: gameEvidence || (existing?.gameEvidence ?? false));
        } else if (gameEvidence && !existing.gameEvidence) {
          found[c.id] = ChannelMatch(c, existing.reason, existing.score,
              detail: existing.detail, gameEvidence: true);
        }
      }

      final picked = picks.channelIdFor(g);
      if (picked != null) {
        final i = _byId[picked];
        if (i != null) add(i, MatchReason.pick, 1000);
      }

      // 2. Event channels naming both teams (event sports: the event).
      final groups = groupsByGame[g]!;
      Set<int>? named;
      for (final group in groups) {
        final hits = _channelsNaming(group);
        named = named == null ? hits : named.intersection(hits);
        if (named.isEmpty) break;
      }
      for (final i in named ?? const <int>{}) {
        final d = _dateInName(_names[i]);
        if (d != null && !_dateFits(d, g.start)) continue;
        add(i, MatchReason.name,
            (d != null ? 120 : 100) + _regionBias(i, g.league), null, true);
      }

      // 2a. Fights: one fighter's name on a fight channel ("DAZN PPV:
      // Canelo") counts too, below both names (user report, 1.0.51: no
      // stream found though several named Canelo). Names of 5+ letters
      // only, so a short surname can't hit unrelated channels.
      if (g.league.kind == SportsKind.fight && groups.length == 2) {
        for (final group in groups) {
          final distinctive = [
            for (final p in group)
              if (p.trim().length >= 5) p,
          ];
          if (distinctive.isEmpty) continue;
          for (final i in _channelsNaming(distinctive)) {
            if (!_fightChannelCue.hasMatch(_names[i])) continue;
            final d = _dateInName(_names[i]);
            if (d != null && !_dateFits(d, g.start)) continue;
            add(i, MatchReason.name, 75 + _regionBias(i, g.league), null, true);
          }
        }
      }

      // 2b. A team's own channel: one team's full name plus the league
      // ("US - NBA TEAMS - ATLANTA HAWKS FHD"). Providers carry every
      // team's local broadcast that way, without a guide (NBA user report,
      // 2026-10-21: Hawks-Magic and Jazz-Grizzlies had nothing else). The
      // full name only — "heat" or "magic" alone would hit other channels.
      if (g.league.kind == SportsKind.team) {
        final league = sportsNormalize(g.league.shortName).trim();
        if (league.length >= 2) {
          for (final t in [g.home, g.away]) {
            final full = sportsNormalize(t.name).trim();
            if (full.split(' ').length < 2) continue;
            for (final i in _channelsNaming([full])) {
              if (!_names[i].trim().split(' ').contains(league)) continue;
              // A dated event feed is not a permanent team channel. Apply
              // the same stale-date guard as the both-team event path above.
              final date = _dateInName(_names[i]);
              if (date != null && !_dateFits(date, g.start)) continue;
              final bias = _regionBias(i, g.league);
              if (bias < 0) continue;
              add(i, MatchReason.teamChannel, 65 + bias, t.shortName);
            }
          }
        }
      }

      // 2c. Event channels in team codes, without a guide ("B01: 7pm CHA @
      // DET", "FB01 : 8:15 DAL @ PHI", user report 2026-10-28). Codes are
      // short and shared across sports (DAL, PHI), so both codes AND the
      // written time must fit: away @ home (either order for "vs"), the
      // start in Eastern time (or the zone the name gives, or the device's).
      // A group naming a sport ("Basketball", "Baseball Playoffs") must be
      // this game's: an NHL and an NBA DET @ TOR can share a 7pm start.
      if (g.league.kind == SportsKind.team &&
          _abbrEvents.isNotEmpty &&
          g.home.abbreviation.isNotEmpty &&
          g.away.abbreviation.isNotEmpty) {
        final home = _canonicalAbbr(g.home.abbreviation.toUpperCase());
        final away = _canonicalAbbr(g.away.abbreviation.toUpperCase());
        int clock(DateTime t) => (t.hour % 12) * 60 + t.minute;
        final eastern = g.start.add(_easternOffset(g.start));
        final local = clock(g.start.toLocal());
        final sport = g.league.espnPath.split('/').first;
        for (final e in _abbrEvents) {
          if (e.sports.isNotEmpty && !e.sports.contains(sport)) continue;
          final fits = e.at
              ? e.first == away && e.second == home
              : (e.first == away && e.second == home) ||
                  (e.first == home && e.second == away);
          if (!fits) continue;
          final zoneShift = switch (e.zone) {
            'c' => 1,
            'm' => 2,
            'p' => 3,
            _ => 0,
          };
          final written = clock(eastern.subtract(Duration(hours: zoneShift)));
          bool near(int a) {
            final d = (a - e.minutes).abs() % 720;
            return math.min(d, 720 - d) <= 10;
          }

          if (!near(written) && !near(local)) continue;
          final date = _dateInName(_names[e.index]);
          if (date != null && !_dateFits(date, g.start)) continue;
          add(e.index, MatchReason.name, 95 + _regionBias(e.index, g.league),
              null, true);
        }
      }

      // 3. Guide programmes naming both teams near the start time — or,
      // for event sports, the event or its series ("Formula 1: Qualifying",
      // "PGA Tour Golf").
      final (from, to) = _guideWindow(g);
      final series = [
        for (final p in g.league.seriesPhrases) sportsNormalize(p)
      ];
      for (final p in programmes) {
        final start = p.start.toUtc();
        if (start.isBefore(from) || !start.isBefore(to)) continue;
        final title = sportsNormalize(p.title);
        final byName = groups.every((group) => group.any(title.contains));
        if (!byName && !series.any(title.contains)) continue;
        if (!byName &&
            g.league.kind == SportsKind.team &&
            namesOtherGame(g, title)) {
          continue;
        }
        final diff = g.end != null
            ? 0 // golf: all day, nothing to be early or late for
            : start.difference(g.start).inMinutes;
        if (byName && !_byEpgId.containsKey(p.channelId)) {
          hiddenInGuide ??= _hiddenByEpgId[p.channelId];
        }
        for (final i in _byEpgId[p.channelId] ?? const <int>[]) {
          add(
              i,
              MatchReason.guide,
              (byName ? 80 : 70) -
                  math.min(diff.abs(), 60) ~/ 6 +
                  _regionBias(i, g.league),
              p.title,
              true);
        }
      }

      // 3b. Event sports: channels named after the series ("Sky Sports F1",
      // "NASCAR"), a few at most — they carry it, if not always live. Not
      // team leagues: "EuroLeague 03 | ..." channels are one game each.
      if (series.isNotEmpty && g.league.kind != SportsKind.team) {
        var taken = 0;
        for (final i in playlistFirst(_channelsNaming(series))) {
          if (taken >= 3) break;
          if (_regionBias(i, g.league) < 0) continue;
          add(i, MatchReason.name, 60 + _regionBias(i, g.league));
          taken++;
        }
      }

      // 4. National networks, exact channel name only — or, for regional
      // networks and local stations, the names they go by
      // ([_networkAliases], [_callSign]).
      for (final network in g.broadcasts) {
        final upper = network.toUpperCase().trim();
        if (_streamingOnly.contains(upper)) continue;
        final key = canonicalChannelKey(network);
        var hits = _byCanonical[key] ?? const <int>[];
        final usNames = _usNetworkNames[upper];
        if (hits.isEmpty && usNames != null) {
          final identities = usNames.map(canonicalChannelKey).toSet();
          hits = (_channelsNaming(usNames).where((i) {
            final n = _names[i];
            if (!n.contains(' us ') ||
                n.contains(' plus ') ||
                n.contains(' alternate ')) {
              return false;
            }
            // "(D)" is one provider's decoration on its channel names.
            final name = _channels[i]
                .name
                .replaceAll(RegExp(r'\s*\(D\)\s*', caseSensitive: false), ' ');
            return identities.contains(canonicalChannelKey(name));
          }).toList()
                ..sort((a, b) => _names[a].length.compareTo(_names[b].length)))
              .toList();
        } else if (hits.isEmpty) {
          final call = _callSign.firstMatch(upper)?.group(1);
          final phrases = _networkAliases[upper] ??
              (call != null ? [call.toLowerCase()] : const <String>[]);
          if (phrases.isNotEmpty) {
            hits = (_channelsNaming(phrases).toList()
                  ..sort(
                      (a, b) => _names[a].length.compareTo(_names[b].length)))
                .toList();
          }
        }
        if (picks.preferQuality) {
          hits = preferSportsSources([
            for (final index in hits)
              ChannelMatch(_channels[index], MatchReason.network, 0)
          ]).map((m) => _byId[m.channel.id]!).toList();
        }
        var taken = 0;
        for (final i in playlistFirst(hits)) {
          if (taken >= 3) break;
          // Same name, different country's channel ("RU: TNT" is not TNT).
          final bias = _regionBias(i, g.league);
          if (bias < 0) continue;
          add(i, MatchReason.network, 50 + bias, network);
          taken++;
        }
      }

      final list = found.values.toList()
        ..sort((x, y) {
          final s = y.score.compareTo(x.score);
          return s != 0
              ? s
              : x.channel.sourceName.length.compareTo(y.channel.sourceName.length);
        });
      final key = SportsChannelPicks.eventKey(g);
      out[key] = distinctCopiesFirst(
          picks.orderMatches(list, countries: countries), limit);
      if (list.isNotEmpty) {
        _noMatch.remove(key);
        continue;
      }
      var hiddenChannel = hiddenInGuide;
      if (hiddenChannel == null && _hidden.isNotEmpty && groups.isNotEmpty) {
        final names = await _hiddenNormalized();
        final hidden = _hidden;
        for (var i = 0; i < names.length && i < hidden.length; i++) {
          if (i % 5000 == 4999) await Future<void>.delayed(Duration.zero);
          if (groups.every((group) => group.any(names[i].contains))) {
            hiddenChannel = hidden[i].sourceName;
            break;
          }
        }
      }
      if (hiddenChannel != null) {
        _noMatch[key] = NoMatch(NoMatchCause.hiddenChannel, hiddenChannel);
        continue;
      }
      // Under half the channels listed at kickoff: the guide hasn't
      // reached the game yet, whatever a few week-long listings say. Only
      // for games still to come: ended programmes are deleted, so every
      // past kickoff would look uncovered.
      final coverage = g.start.isAfter(DateTime.now())
          ? await _epg.guideCoverageAt(g.start)
          : null;
      _noMatch[key] = NoMatch(coverage != null && coverage < 0.5
          ? NoMatchCause.guideNotReaching
          : NoMatchCause.notFound);
    }
    return out;
  }

  /// Channels whose name contains every word of [query] — the manual
  /// "Pick channel" search. Empty query = nothing.
  List<Channel> search(String query, {int limit = 200}) {
    final words = sportsNormalize(query)
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return const [];
    final out = <Channel>[];
    for (var i = 0; i < _names.length && out.length < limit; i++) {
      final n = _names[i];
      if (words.every((w) => n.contains(w))) out.add(_channels[i]);
    }
    return out;
  }
}

int _sportsQuality(Channel c) {
  if (Real4kChannels.contains(c.id)) return 5;
  final name = c.sourceName.toUpperCase();
  if (RegExp(r'\b(4K|UHD|2160P?)\b').hasMatch(name)) return 4;
  if (RegExp(r'\b(FHD|1080P?)\b').hasMatch(name)) return 3;
  if (RegExp(r'\bHD\b').hasMatch(name)) return 2;
  if (RegExp(r'\bSD\b').hasMatch(name)) return 0;
  return 1;
}

/// Saved choices first, then matched 4K sources across all broadcasters.
/// Keep the existing copy/score ordering for the remaining fallback sources.
List<ChannelMatch> preferSportsSources(List<ChannelMatch> matches) {
  final groups = <String, List<ChannelMatch>>{};
  for (final m in matches) {
    final key = channelCopyKey(m.channel.sourceName);
    (groups[key.isEmpty ? m.channel.id : key] ??= []).add(m);
  }
  for (final group in groups.values) {
    group.sort((a, b) {
      if (a.reason == MatchReason.pick || b.reason == MatchReason.pick) {
        return b.score.compareTo(a.score);
      }
      final quality =
          _sportsQuality(b.channel).compareTo(_sportsQuality(a.channel));
      return quality != 0 ? quality : b.score.compareTo(a.score);
    });
  }
  final ordered = [for (final group in groups.values) ...group];
  final previousOrder = {for (final (i, m) in ordered.indexed) m: i};
  int priority(ChannelMatch m) =>
      m.reason == MatchReason.pick && m.score >= 1000
          ? 3
          : _sportsQuality(m.channel) >= 4
              ? 2
              : m.reason == MatchReason.pick
                  ? 1
                  : 0;
  ordered.sort((a, b) {
    final rank = priority(b).compareTo(priority(a));
    if (rank != 0) return rank;
    if (priority(a) == 3 || priority(a) == 1) {
      final pick = b.score.compareTo(a.score);
      if (pick != 0) return pick;
    } else if (priority(a) == 2) {
      final quality =
          _sportsQuality(b.channel).compareTo(_sportsQuality(a.channel));
      if (quality != 0) return quality;
      final evidence = b.score.compareTo(a.score);
      if (evidence != 0) return evidence;
    }
    return previousOrder[a]!.compareTo(previousOrder[b]!);
  });
  return ordered;
}
