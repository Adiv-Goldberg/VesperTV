import 'package:flutter_test/flutter_test.dart';
import 'package:nox_iptv/models/channel.dart';
import 'package:nox_iptv/models/sports.dart';
import 'package:nox_iptv/services/epg_service.dart';
import 'package:nox_iptv/services/sports_channel_matcher.dart';
import 'package:nox_iptv/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boxing channels say "Canelo", the feeds "Saul Alvarez"; an event-only
/// card's whole title never appears word for word (user report, 1.0.51:
/// no stream matched though several named Canelo).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Channel ch(String id, String name) => Channel(
      id: 'p::$id',
      rawId: id,
      playlistId: 'p',
      name: name,
      group: 'PPV',
      url: 'http://x/$id.ts');

  SportsTeam fighter(String name) => SportsTeam(
      id: name,
      name: name,
      shortName: name,
      abbreviation: name.isEmpty ? '' : name[0]);

  final start = DateTime.now().toUtc().add(const Duration(hours: 2));

  Future<List<String>> match(List<Channel> channels, SportsGame g) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final matcher = SportsChannelMatcher(EpgService(storage));
    await matcher.prepare(channels);
    final out = await matcher.matchDay([g], SportsChannelPicks.load(storage));
    return [
      for (final m in out[SportsChannelPicks.eventKey(g)] ?? const [])
        m.channel.rawId
    ];
  }

  final channels = [
    ch('both', 'DAZN PPV 1: Canelo vs Crawford'),
    ch('one', 'PPV 02: Canelo Fight Night'),
    ch('doc', 'Canelo: The Documentary'),
    ch('other', 'PPV 03: Inoue vs Nery'),
  ];

  test('a bout: ring name, and one fighter on a fight channel', () async {
    final g = SportsGame(
      id: 'b1',
      league: sportsLeagueById('boxing')!,
      start: start,
      state: GameState.pre,
      statusText: '',
      home: fighter('Saul Alvarez'),
      away: fighter('Terence Crawford'),
    );
    final found = await match(channels, g);
    expect(found.first, 'both');
    expect(found, contains('one'));
    expect(found, isNot(contains('doc')));
    expect(found, isNot(contains('other')));
  });

  test('an event-only card is split into its two fighters', () async {
    final g = SportsGame(
      id: 'e1',
      league: sportsLeagueById('boxing')!,
      start: start,
      state: GameState.pre,
      statusText: '',
      home: fighter('Canelo Alvarez vs. Terence Crawford'),
      away: fighter(''),
      event:
          const SportsEventInfo(title: 'Canelo Alvarez vs. Terence Crawford'),
    );
    expect(g.isEventOnly, isTrue);
    final found = await match(channels, g);
    expect(found.first, 'both');
    expect(found, contains('one'));
    expect(found, isNot(contains('other')));
  });
}
