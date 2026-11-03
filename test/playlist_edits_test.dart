import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nox_iptv/models/channel.dart';
import 'package:nox_iptv/services/channel_copy_fallback.dart';
import 'package:nox_iptv/services/playlist_edits.dart';
import 'package:nox_iptv/services/stream_probe.dart';
import 'package:nox_iptv/utils/channel_name_matching.dart';

Channel ch(String raw, String name, {String group = 'CA| SPORTS'}) => Channel(
    id: 'p1::$raw',
    rawId: raw,
    playlistId: 'p1',
    name: name,
    group: group,
    url: 'http://x/$raw.ts');

void main() {
  test('renames show, matching keeps the provider name', () {
    final c = ch('1', 'US| ESPN FHD ᴿᴬᵂ');
    final e = PlaylistEdits(rules: [
      EditRule(type: 'replace', find: 'US| '),
      EditRule(type: 'replace', find: 'ᴿᴬᵂ'),
    ]);
    e.apply([c]);
    expect(c.name, 'ESPN FHD');
    expect(c.sourceName, 'US| ESPN FHD ᴿᴬᵂ');
    e.names['1'] = 'ESPN';
    e.apply([c]);
    expect(c.name, 'ESPN');
    // copyWith keeps the override; JSON keeps the provider's name.
    expect(c.copyWith(url: 'u').name, 'ESPN');
    expect(c.toJson()['name'], 'US| ESPN FHD ᴿᴬᵂ');
  });

  test('TSN2 FHD and TSN 2 HD are copies; 4K stays a tag', () {
    expect(channelCopyKey('CA| TSN2 FHD'), channelCopyKey('CA| TSN 2 HD'));
    expect(channelCopyKey('CA| TSN 1 4K'), channelCopyKey('CA| TSN1'));
    expect(channelCopyKey('CA| TSN 1'), isNot(channelCopyKey('CA| TSN 2')));
  });

  test('group renames merge groups', () {
    final e = PlaylistEdits(groupNames: {'US| SPORTS': 'Sports', 'CA| SPORT': 'Sports'});
    expect(e.groupTitle('US| SPORTS'), 'Sports');
    expect(e.groupTitle('CA| SPORT'), 'Sports');
    expect(e.groupTitle('Other'), 'Other');
    expect(PlaylistEdits.decode(e.encode()).groupNames, e.groupNames);
  });

  test('broken regex never hides everything', () {
    final e =
        PlaylistEdits(rules: [EditRule(type: 'hide', find: '([', regex: true)]);
    expect(e.apply([ch('1', 'TSN 1')]), isEmpty);
  });

  test('hide rules on name and group, separators, always show', () {
    final list = [
      ch('1', 'PPV 1'),
      ch('2', 'TSN 1', group: 'UK| 24/7'),
      ch('3', '##### SPORTS #####'),
      ch('4', 'TSN 2'),
    ];
    final e = PlaylistEdits(rules: [
      EditRule(type: 'hide', find: 'ppv'),
      EditRule(type: 'hide', find: 'UK|', field: 'group'),
    ], hideSeparators: true);
    expect(e.apply(list), {'1', '2', '3'});
    e.shown.add('1');
    expect(e.apply(list), {'2', '3'});
  });

  test('collapse copies keeps the best, never mixes channels', () {
    final list = [
      ch('a', 'CA| TSN 1 4K'),
      ch('b', 'CA| TSN 1 FHD'),
      ch('c', 'CA| TSN 1 HD'),
      ch('d', 'CA| TSN 2 HD'),
      ch('e', 'CA| CTV East HD'),
      ch('f', 'CA| CTV West HD'),
      ch('g', 'US| TSN 1 HD'),
    ];
    final e = PlaylistEdits(hideLowerCopies: true);
    expect(e.apply(list), {'b', 'c'});
    // A tested-dead 4K loses to the FHD.
    e.probes['a'] =
        ProbeResult(ok: false, at: DateTime.now(), error: 'HTTP 404');
    expect(e.apply(list), {'a', 'c'});
  });

  test('failover order: label rank, then reliability', () {
    final list = [
      ch('a', 'CA| TSN 1 4K'),
      ch('b', 'CA| TSN 1 FHD'),
      ch('c', 'CA| TSN 1 HD'),
      ch('d', 'CA| TSN 2 HD'),
    ];
    final copies = ChannelCopyFallback.copiesOf(list[0], list);
    expect(copies.map((c) => c.rawId), ['b', 'c']);
    final f = ChannelCopyFallback();
    expect(f.next(list[0], copies)?.rawId, 'b');
    expect(f.next(list[0].copyWith(url: list[1].url), copies)?.rawId, 'c');
    expect(f.next(list[0].copyWith(url: list[2].url), copies), isNull);
  });

  test('edits survive JSON and reject junk', () {
    final e = PlaylistEdits(names: {
      '1': 'A'
    }, fallbacks: {
      '1': ['p2::9']
    }, rules: [
      EditRule(type: 'hide', find: 'x', regex: true)
    ], hideLowerCopies: true);
    final back = PlaylistEdits.decode(e.encode());
    expect(back.names, {'1': 'A'});
    expect(back.fallbacks['1'], ['p2::9']);
    expect(back.rules.single.regex, isTrue);
    expect(back.hideLowerCopies, isTrue);
    expect(
        PlaylistEdits.decode('{"rules":[{"type":"rm","find":"x"}],"names":5}')
            .isEmpty,
        isTrue);
    expect(PlaylistEdits.decode('not json').isEmpty, isTrue);
  });

  test('TS probe reads an H.264 1080p SPS and the frame rate', () {
    final ts = _fakeTs();
    final r = StreamProbe.parseTs(ts, DateTime.now())!;
    expect(r.ok, isTrue);
    expect(r.codec, 'H.264');
    expect(r.height, 1080);
    expect(r.width, 1920);
    expect(r.fps, 50);
  });
}

/// PAT + PMT (H.264 on PID 0x100) + video PES packets every 1800 ticks
/// (50 fps), the first carrying a 1920x1080 High-profile SPS.
Uint8List _fakeTs() {
  final out = BytesBuilder();
  List<int> packet(int pid, bool pusi, List<int> payload) {
    final p = List<int>.filled(188, 0xFF);
    p[0] = 0x47;
    p[1] = (pusi ? 0x40 : 0) | (pid >> 8);
    p[2] = pid & 0xFF;
    p[3] = 0x10;
    for (var i = 0; i < payload.length && i + 4 < 188; i++) {
      p[4 + i] = payload[i];
    }
    return p;
  }

  // PAT: program 1 -> PMT PID 0x1000.
  out.add(packet(0, true,
      [0, 0x00, 0xB0, 13, 0, 1, 0xC1, 0, 0, 0, 1, 0xF0, 0x00, 0, 0, 0, 0]));
  // PMT: PCR PID 0x100, stream type 0x1B on PID 0x100.
  out.add(packet(0x1000, true, [
    0,
    0x02,
    0xB0,
    18,
    0,
    1,
    0xC1,
    0,
    0,
    0xE1,
    0x00,
    0xF0,
    0x00,
    0x1B,
    0xE1,
    0x00,
    0xF0,
    0x00,
    0,
    0,
    0,
    0
  ]));
  // High profile 1920x1080 SPS (from a real encoder).
  const sps = [
    0,
    0,
    0,
    1,
    0x67,
    0x64,
    0x00,
    0x28,
    0xAC,
    0xD9,
    0x40,
    0x78,
    0x02,
    0x27,
    0xE5,
    0xC0,
    0x44,
    0x00,
    0x00,
    0x03,
    0x00,
    0x04,
    0x00,
    0x00,
    0x03,
    0x00,
    0xC8,
    0x3C,
    0x60,
    0xC6,
    0x58,
    0x00,
    0x00,
    0x00,
    0x01,
    0x68
  ];
  for (var i = 0; i < 8; i++) {
    final pts = 90000 + i * 1800;
    final pes = [
      0,
      0,
      1,
      0xE0,
      0,
      0,
      0x80,
      0x80,
      5,
      0x21 | ((pts >> 29) & 0x0E),
      (pts >> 22) & 0xFF,
      0x01 | ((pts >> 14) & 0xFE),
      (pts >> 7) & 0xFF,
      0x01 | ((pts << 1) & 0xFE),
      if (i == 0) ...sps,
    ];
    out.add(packet(0x100, true, pes));
  }
  return out.takeBytes();
}
