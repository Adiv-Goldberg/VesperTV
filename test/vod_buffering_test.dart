import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox_iptv/models/channel.dart';
import 'package:nox_iptv/services/m3u_parser.dart';
import 'package:nox_iptv/services/vod_buffering.dart';
import 'package:video_player_hdr/video_player_hdr.dart';

class _Controller extends VideoPlayerHdrController {
  _Controller() : super.networkUrl(Uri.parse('https://example.test/video'));
  @override
  int get textureId => 37;
}

Channel _channel(String rawId, {bool transient = false}) => Channel(
    id: 'p::$rawId',
    rawId: rawId,
    playlistId: 'p',
    name: 'Fixture',
    group: 'Movies',
    url: 'https://example.test/video',
    transientPlayback: transient);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const methods = MethodChannel('vespertv/stats');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(methods, null);
  });

  test('shared policy includes IPTV and Hub movies/episodes with explicit IDs',
      () {
    for (final raw in ['xt_vod_1', 'xt_ep_1', 'arc_vod_1', 'arc_ep_1']) {
      expect(VodBuffering.appliesTo(_channel(raw)), isTrue, reason: raw);
    }
    expect(VodBuffering.appliesTo(_channel('xt_live_1')), isFalse);
    expect(VodBuffering.appliesTo(_channel('cu_1', transient: true)), isFalse);
    expect(VodBuffering.appliesTo(_channel('arc_vod_trailer', transient: true)),
        isFalse);
  });

  test('M3U group classification survives ordinary live-looking tvg IDs', () {
    final channels = M3uParser.parse(
        '#EXTM3U\n'
        '#EXTINF:-1 tvg-id="ordinary" group-title="Movies",Film\n'
        'https://example.test/film\n'
        '#EXTINF:-1 group-title="TV Shows",Episode\n'
        'https://example.test/episode\n'
        '#EXTINF:120 tvg-id="live" group-title="News",Live\n'
        'https://example.test/live.mp4\n',
        playlistId: 'p');
    expect(channels.map(VodBuffering.appliesTo), [true, true, false]);
  });

  test('bridge sends only player identity and explicit content classification',
      () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call);
      return null;
    });
    final controller = _Controller();
    VodBuffering.liveBufferMs = 4000;
    addTearDown(() => VodBuffering.liveBufferMs = 0);
    await VodBuffering.configure(controller, _channel('arc_ep_1'));
    await VodBuffering.configure(controller, _channel('xt_live_1'));
    expect(calls.map((c) => c.method), [
      'setOnDemandBuffering',
      'setLiveBuffer',
      'setOnDemandBuffering',
      'setLiveBuffer',
    ]);
    // The live buffer applies to live channels only.
    expect(calls.map((c) => c.arguments), [
      {'playerId': 37, 'on': true},
      {'playerId': 37, 'ms': 0},
      {'playerId': 37, 'on': false},
      {'playerId': 37, 'ms': 4000},
    ]);
  });

  test('absent bridge or disposed player does not block playback', () async {
    messenger.setMockMethodCallHandler(methods, (call) async {
      throw PlatformException(code: 'no_player');
    });
    await VodBuffering.configure(_Controller(), _channel('xt_vod_1'));
    messenger.setMockMethodCallHandler(methods, null);
    await VodBuffering.configure(_Controller(), _channel('xt_vod_1'));
  });

  test('Windows remains on its independent playback stack', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    var called = false;
    messenger.setMockMethodCallHandler(methods, (_) async {
      called = true;
      return null;
    });
    await VodBuffering.configure(_Controller(), _channel('arc_vod_1'));
    expect(called, isFalse);
  });
}
