import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_hdr/video_player_hdr.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:nox_iptv/models/channel.dart';
import 'package:nox_iptv/screens/player_screen.dart';
import 'package:nox_iptv/services/app_preferences.dart';
import 'package:nox_iptv/services/epg_service.dart';
import 'package:nox_iptv/services/playback_service.dart';
import 'package:nox_iptv/services/playlist_manager.dart';
import 'package:nox_iptv/services/storage_service.dart';
import 'package:nox_iptv/utils/route_observer.dart';
import 'package:nox_iptv/widgets/player_side_panel.dart';
import 'package:nox_iptv/widgets/player_touch_lock.dart';

import 'native_live_zap_test.dart' show ZapController, ZapStorage, ZapPlaylist;

class _VideoPlatform extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}
  @override
  Widget buildView(int textureId) => const SizedBox();
  @override
  Future<void> dispose(int textureId) async {}
}

class _Controller extends ZapController {
  _Controller() {
    value = const VideoPlayerHdrValue(
      duration: Duration(hours: 2),
      position: Duration(minutes: 5),
      size: Size(1920, 1080),
      isInitialized: true,
      isPlaying: true,
    );
  }
  int pauses = 0;
  int seeks = 0;
  @override
  bool isVideoTrackSupportAvailable() => false;
  @override
  bool isAudioTrackSupportAvailable() => false;
  @override
  Future<void> pause() async {
    pauses++;
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> seekTo(Duration position) async {
    seeks++;
    value = value.copyWith(position: position);
  }
}

class _Player {
  _Player(this.controller, this.playback);
  final _Controller controller;
  final PlaybackService playback;
}

void main() {
  const pipChannel = MethodChannel('vespertv/phone_pip');
  late VideoPlayerPlatform previousPlatform;
  setUp(() {
    previousPlatform = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = _VideoPlatform();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pipChannel, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
            'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
            (_) async => const StandardMessageCodec().encodeMessage([null]));
  });
  tearDown(() {
    VideoPlayerPlatform.instance = previousPlatform;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pipChannel, null);
  });

  Future<_Player> open(WidgetTester tester,
      {bool live = false, bool tv = false, bool forcedTvLayout = false}) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 32, bottom: 24);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final storage = ZapStorage();
    await storage.init();
    await storage.setSkipSegments(false);
    final prefs = AppPreferences(storage);
    await prefs.init();
    prefs.isTelevision = tv;
    if (forcedTvLayout) prefs.setLayoutMode('tv');
    final playlist = ZapPlaylist(storage);
    final controller = _Controller();
    final channel = Channel(
      id: live ? 'p::live' : 'archive::arc_vod_movie',
      rawId: live ? 'live' : 'arc_vod_movie',
      playlistId: live ? 'p' : 'archive',
      name: live ? 'Live channel' : 'Movie',
      group: '',
      url: 'https://example.com/video',
    );
    final playback = PlaybackService(storage, playlist)
      ..controller = controller
      ..currentChannel = channel;
    final epg = EpgService(storage);
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider<AppPreferences>.value(value: prefs),
        ChangeNotifierProvider<PlaylistManager>.value(value: playlist),
        ChangeNotifierProvider<PlaybackService>.value(value: playback),
        ChangeNotifierProvider<EpgService>.value(value: epg),
      ],
      child: MaterialApp(
        navigatorObservers: [appRouteObserver],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => PlayerScreen(channel: channel))),
              child: const Text('Open player'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open player'));
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      playback.dispose();
      playlist.dispose();
      epg.dispose();
      prefs.dispose();
      await tester.pump();
    });
    return _Player(controller, playback);
  }

  Future<void> lock(WidgetTester tester) async {
    await tester.tapAt(const Offset(250, 300));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Lock touch controls'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('player-touch-unlock')), findsOneWidget);
  }

  for (final live in [false, true]) {
    testWidgets('phone lock blocks controls, swipes and Back; live=$live',
        (tester) async {
      final player = await open(tester, live: live);
      await lock(tester);
      final unlock = find.byKey(const ValueKey('player-touch-unlock'));
      expect(tester.getSize(unlock), const Size(56, 56));
      await tester.tapAt(const Offset(250, 300));
      await tester.tapAt(const Offset(200, 810));
      await tester.flingFrom(const Offset(20, 300), const Offset(300, 0), 1000);
      await tester.pump(const Duration(seconds: 8));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PlayerScreen), findsOneWidget);
      expect(find.byType(PlayerSidePanel), findsNothing);
      // The unlock button fades away, and any touch brings it back.
      expect(unlock.hitTestable(), findsNothing);
      await tester.tapAt(const Offset(250, 300));
      await tester.pumpAndSettle();
      expect(unlock.hitTestable(), findsOneWidget);
      expect(find.byTooltip('Lock touch controls').hitTestable(), findsNothing);
      expect(player.controller.value.isPlaying, isTrue);
      expect(player.controller.pauses, 0);
      expect(player.controller.seeks, 0);
      expect(player.controller.disposed, isFalse);

      await tester.tap(unlock);
      await tester.pumpAndSettle();
      expect(unlock, findsNothing);
      expect(
          find.byTooltip('Lock touch controls').hitTestable(), findsOneWidget);
      // The same controller resumes accepting the normal player controls.
      await tester.tap(find.byIcon(Icons.pause).hitTestable());
      await tester.pump();
      expect(player.controller.pauses, 1);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PlayerScreen), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }

  testWidgets(
      'lock survives rotation and episode changes; reopening starts unlocked',
      (tester) async {
    final player = await open(tester, forcedTvLayout: true);
    await lock(tester);
    tester.view.physicalSize = const Size(900, 412);
    await tester.pumpAndSettle();
    player.playback.currentChannel = player.playback.currentChannel!
        .copyWith(id: 'archive::arc_ep_next', rawId: 'arc_ep_next');
    player.playback.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('player-touch-unlock')).hitTestable(),
        findsOneWidget);
    expect(player.controller.disposed, isFalse);
    await tester.tap(find.byKey(const ValueKey('player-touch-unlock')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open player'));
    await tester.pumpAndSettle();
    expect(tester.widget<PlayerTouchLock>(find.byType(PlayerTouchLock)).locked,
        isFalse);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('PiP hides the lock and restores it on return', (tester) async {
    final player = await open(tester);
    await lock(tester);
    Future<void> pip(bool active) async {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
              pipChannel.name,
              const StandardMethodCodec()
                  .encodeMethodCall(MethodCall('modeChanged', active)),
              (_) {});
      await tester.pumpAndSettle();
    }

    await pip(true);
    expect(find.byKey(const ValueKey('player-touch-unlock')), findsNothing);
    expect(player.controller.value.isPlaying, isTrue);
    await pip(false);
    expect(find.byKey(const ValueKey('player-touch-unlock')).hitTestable(),
        findsOneWidget);
    expect(player.controller.pauses, 0);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  for (final platform in [TargetPlatform.android, TargetPlatform.windows]) {
    testWidgets(
        'no lock on ${platform.name} ${platform == TargetPlatform.android ? 'TV' : 'desktop'}',
        (tester) async {
      await open(tester, tv: platform == TargetPlatform.android);
      await tester.tapAt(const Offset(250, 300));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Lock touch controls'), findsNothing);
    }, variant: TargetPlatformVariant.only(platform));
  }
}
