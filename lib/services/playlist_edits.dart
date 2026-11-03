import 'dart:convert';

import '../models/channel.dart';
import '../utils/channel_name_matching.dart';
import 'channel_copy_fallback.dart';

/// One playlist editor rule, re-applied on every content update (see
/// `dev-notes/iptv-editor-plan.md`).
///
/// * `replace`: find -> replace in the channel name ([field] 'name') or
///   the group title ([field] 'group', display only for the group isn't
///   supported yet, so group rules only *match* for `hide`).
/// * `hide`: hide every live channel whose name/group matches [find].
class EditRule {
  EditRule({
    required this.type,
    required this.find,
    this.replace = '',
    this.regex = false,
    this.field = 'name',
    this.enabled = true,
  });

  final String type;
  final String find;
  final String replace;
  final bool regex;
  final String field;
  final bool enabled;

  RegExp? _compiled;
  bool _invalid = false;

  /// Null for an empty or broken pattern (a typo in a regex never hides or
  /// renames everything).
  RegExp? get pattern {
    if (_compiled != null || _invalid) return _compiled;
    if (find.isEmpty) {
      _invalid = true;
      return null;
    }
    try {
      _compiled = RegExp(regex ? find : RegExp.escape(find),
          caseSensitive: false, unicode: true);
    } catch (_) {
      _invalid = true;
    }
    return _compiled;
  }

  bool matches(Channel c) {
    final p = pattern;
    if (p == null) return false;
    return p.hasMatch(field == 'group' ? c.group : c.sourceName);
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'find': find,
        if (replace.isNotEmpty) 'replace': replace,
        if (regex) 'regex': true,
        if (field != 'name') 'field': field,
        if (!enabled) 'enabled': false,
      };

  static EditRule? fromJson(Object? json) {
    if (json is! Map) return null;
    final type = json['type'];
    final find = json['find'];
    if (type is! String || find is! String) return null;
    if (type != 'replace' && type != 'hide') return null;
    final field = json['field'];
    return EditRule(
      type: type,
      find: find.length > 300 ? find.substring(0, 300) : find,
      replace: (json['replace'] as String?) ?? '',
      regex: json['regex'] == true,
      field: field == 'group' ? 'group' : 'name',
      enabled: json['enabled'] != false,
    );
  }
}

/// What a stream test (or real playback) measured for one channel.
class ProbeResult {
  ProbeResult({
    required this.ok,
    required this.at,
    this.height,
    this.width,
    this.fps,
    this.codec,
    this.error,
  });

  final bool ok;
  final DateTime at;
  final int? height;
  final int? width;
  final double? fps;
  final String? codec;
  final String? error;

  static const staleAfter = Duration(days: 30);
  bool get isStale => DateTime.now().difference(at) > staleAfter;

  /// "1080p 50fps H.264", "dead (HTTP 404)".
  String get label {
    if (!ok) return error == null ? 'dead' : 'dead ($error)';
    final parts = <String>[
      if (height != null) height! >= 2000 ? '4K' : '${height}p',
      if (fps != null) '${fps!.round()}fps',
      if (codec != null) codec!,
    ];
    return parts.isEmpty ? 'works' : parts.join(' ');
  }

  Map<String, dynamic> toJson() => {
        'ok': ok,
        'at': at.millisecondsSinceEpoch,
        if (height != null) 'h': height,
        if (width != null) 'w': width,
        if (fps != null) 'fps': fps,
        if (codec != null) 'codec': codec,
        if (error != null) 'err': error,
      };

  static ProbeResult? fromJson(Object? json) {
    if (json is! Map || json['at'] is! int) return null;
    return ProbeResult(
      ok: json['ok'] == true,
      at: DateTime.fromMillisecondsSinceEpoch(json['at'] as int),
      height: (json['h'] as num?)?.toInt(),
      width: (json['w'] as num?)?.toInt(),
      fps: (json['fps'] as num?)?.toDouble(),
      codec: json['codec'] as String?,
      error: json['err'] as String?,
    );
  }
}

/// A playlist's editor layer: never rewrites the provider's data, only
/// stamps display overrides and computes which live channels to hide.
/// Keyed by `Channel.rawId` (stable across content updates; made unique by
/// `Channel.withUniqueIds`). Stored per playlist and per viewer.
class PlaylistEdits {
  PlaylistEdits({
    Map<String, String>? names,
    Map<String, String>? logos,
    Set<String>? hidden,
    Set<String>? shown,
    Map<String, List<String>>? fallbacks,
    List<EditRule>? rules,
    Map<String, ProbeResult>? probes,
    Map<String, String>? groupNames,
    this.hideLowerCopies = false,
    this.hideSeparators = false,
  })  : names = names ?? {},
        logos = logos ?? {},
        hidden = hidden ?? {},
        shown = shown ?? {},
        fallbacks = fallbacks ?? {},
        rules = rules ?? [],
        probes = probes ?? {},
        groupNames = groupNames ?? {};

  /// Live group renames: provider title -> shown title. Several provider
  /// groups with the same new title are merged into one group.
  final Map<String, String> groupNames;

  /// The live group title shown for the provider's [title].
  String groupTitle(String title) => groupNames[title] ?? title;

  /// rawId -> display name.
  final Map<String, String> names;

  /// rawId -> logo URL.
  final Map<String, String> logos;

  /// Hidden by hand in the editor (separate from the TV's own Hide
  /// channel list, which stays as it always was).
  final Set<String> hidden;

  /// Always shown, whatever a rule or Collapse copies says.
  final Set<String> shown;

  /// rawId -> ordered composite ids (`playlistId::rawId`) to try when this
  /// channel fails, before its automatic copies.
  final Map<String, List<String>> fallbacks;

  final List<EditRule> rules;
  final Map<String, ProbeResult> probes;

  /// Hide the lower-quality copies of a channel (they stay as automatic
  /// fallbacks).
  bool hideLowerCopies;

  /// Hide `##### SPORTS #####`-style divider rows.
  bool hideSeparators;

  bool get isEmpty =>
      names.isEmpty &&
      groupNames.isEmpty &&
      logos.isEmpty &&
      hidden.isEmpty &&
      rules.isEmpty &&
      fallbacks.isEmpty &&
      !hideLowerCopies &&
      !hideSeparators;

  static final _separator = RegExp(
      r'^\s*[#=*~•_\-|+]{3,}|[#=*~•_\-|+]{3,}\s*$|^[^\p{L}\p{N}]*$',
      unicode: true);

  static bool isSeparator(Channel c) => _separator.hasMatch(c.sourceName);

  /// The name after the replace rules (manual names win in [apply]).
  String ruleName(Channel c) {
    var name = c.sourceName;
    for (final r in rules) {
      if (!r.enabled || r.type != 'replace' || r.field != 'name') continue;
      final p = r.pattern;
      if (p == null) continue;
      try {
        name = name.replaceAll(p, r.replace);
      } catch (_) {}
    }
    name = name.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return name.isEmpty ? c.sourceName : name;
  }

  /// Higher = better copy: measured height first, then the name label.
  /// A copy measured dead ranks below everything.
  int copyRank(Channel c) {
    final probe = probes[c.rawId];
    if (probe != null && !probe.isStale) {
      if (!probe.ok) return -10;
      final h = probe.height;
      if (h != null) {
        if (h >= 2000) return 5;
        if (h >= 1000) return 4;
        if (h >= 700) return 3;
        return 1;
      }
    }
    return ChannelCopyFallback.qualityRank(c.sourceName);
  }

  /// Stamps [Channel.nameOverride]/[Channel.logoOverride] on [live] and
  /// returns the rawIds the editor hides.
  Set<String> apply(Iterable<Channel> live) {
    final out = <String>{};
    final activeHide = [
      for (final r in rules)
        if (r.enabled && r.type == 'hide' && r.pattern != null) r
    ];
    final hasRename = rules.any((r) => r.enabled && r.type == 'replace');
    final byCopy = <String, List<Channel>>{};
    for (final c in live) {
      final manual = names[c.rawId];
      final display = manual ?? (hasRename ? ruleName(c) : c.sourceName);
      c.nameOverride = display == c.sourceName ? null : display;
      c.logoOverride = logos[c.rawId];
      if (shown.contains(c.rawId)) continue;
      if (hidden.contains(c.rawId) ||
          (hideSeparators && isSeparator(c)) ||
          activeHide.any((r) => r.matches(c))) {
        out.add(c.rawId);
        continue;
      }
      if (hideLowerCopies) {
        final key = channelCopyKey(c.sourceName);
        if (key.isNotEmpty) (byCopy[key] ??= []).add(c);
      }
    }
    for (final copies in byCopy.values) {
      if (copies.length < 2) continue;
      var best = -100;
      for (final c in copies) {
        final r = copyRank(c);
        if (r > best) best = r;
      }
      for (final c in copies) {
        if (copyRank(c) < best) out.add(c.rawId);
      }
    }
    return out;
  }

  Map<String, dynamic> toJson() => {
        if (names.isNotEmpty) 'names': names,
        if (groupNames.isNotEmpty) 'groupNames': groupNames,
        if (logos.isNotEmpty) 'logos': logos,
        if (hidden.isNotEmpty) 'hidden': hidden.toList(),
        if (shown.isNotEmpty) 'shown': shown.toList(),
        if (fallbacks.isNotEmpty) 'fallbacks': fallbacks,
        if (rules.isNotEmpty) 'rules': [for (final r in rules) r.toJson()],
        if (probes.isNotEmpty)
          'probes': {for (final e in probes.entries) e.key: e.value.toJson()},
        if (hideLowerCopies) 'hideLowerCopies': true,
        if (hideSeparators) 'hideSeparators': true,
      };

  String encode() => jsonEncode(toJson());

  /// Accepts anything: a bad or foreign blob gives an empty layer, never
  /// an exception (the editor page posts this shape too).
  static PlaylistEdits fromJson(Object? json) {
    if (json is! Map) return PlaylistEdits();
    Map<String, String> strMap(Object? v, int maxLen) => {
          if (v is Map)
            for (final e in v.entries)
              if (e.key is String &&
                  e.value is String &&
                  (e.value as String).trim().isNotEmpty)
                e.key as String: _cap((e.value as String).trim(), maxLen),
        };
    Set<String> strSet(Object? v) => {
          if (v is List)
            for (final x in v)
              if (x is String) x
        };
    final fallbacks = <String, List<String>>{};
    final f = json['fallbacks'];
    if (f is Map) {
      for (final e in f.entries) {
        if (e.key is! String || e.value is! List) continue;
        final list = [
          for (final x in e.value as List)
            if (x is String && x.contains('::')) x
        ];
        if (list.isNotEmpty) {
          fallbacks[e.key as String] = list.take(10).toList();
        }
      }
    }
    final probes = <String, ProbeResult>{};
    final p = json['probes'];
    if (p is Map) {
      for (final e in p.entries) {
        if (e.key is! String) continue;
        if (ProbeResult.fromJson(e.value) case final r?) {
          probes[e.key as String] = r;
        }
      }
    }
    return PlaylistEdits(
      names: strMap(json['names'], 120),
      groupNames: strMap(json['groupNames'], 120),
      logos: strMap(json['logos'], 1000),
      hidden: strSet(json['hidden']),
      shown: strSet(json['shown']),
      fallbacks: fallbacks,
      rules: [
        if (json['rules'] is List)
          for (final r in json['rules'] as List)
            if (EditRule.fromJson(r) case final rule?) rule
      ].take(100).toList(),
      probes: probes,
      hideLowerCopies: json['hideLowerCopies'] == true,
      hideSeparators: json['hideSeparators'] == true,
    );
  }

  static PlaylistEdits decode(String? s) {
    if (s == null || s.isEmpty) return PlaylistEdits();
    try {
      return fromJson(jsonDecode(s));
    } catch (_) {
      return PlaylistEdits();
    }
  }

  static String _cap(String s, int max) =>
      s.length > max ? s.substring(0, max) : s;
}
