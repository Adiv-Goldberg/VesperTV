import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Native video surface (beta, Android, [AppPreferences.nativeVideoSurface]).
///
/// With it on, MainActivity starts Flutter transparent and the vendored
/// player draws the main video into one plain Android SurfaceView *behind*
/// Flutter (`NativeVideoSurface.java`), like a native player — no platform
/// view around it. A [NativeVideoHole] stands where the video goes: it clears
/// its rect to transparent and, after every frame, the topmost visible hole's
/// rect (physical pixels) and player id go to the native side, which moves
/// the SurfaceView there. A covered route retains its last rect beneath
/// Flutter until it returns. When no video hole remains (or the current one
/// is explicitly hidden), the surface moves off screen without being destroyed.
///
/// Why: through the platform view AMD's Fire TV Cube showed 4K HDR10 as
/// washed-out 1080p (LOG-CFN2FE) and Sam's NVIDIA Shield green flicker under
/// the guide. Every step logs `NativeSurface:` lines for Send log.
class NativeVideoSurface {
  NativeVideoSurface._();

  /// Read once at startup (main.dart): the transparent Flutter view is fixed
  /// at launch, so a change in Settings applies after a restart.
  static bool active = false;

  static const _channel = MethodChannel('vespertv/native_surface');

  /// Enable early binding before any platform-view player can prepare its
  /// decoder. This is called only at beta startup, never for texture players.
  static Future<void> configure() async {
    await _channel.invokeMethod<void>('configure', {'enabled': active});
  }

  static Future<void> prepareNewPlayer() =>
      _channel.invokeMethod<void>('prepareNewPlayer');

  static Future<Map<String, Object?>?> replaceLive(int playerId, String url,
          {required bool hls}) =>
      _channel.invokeMapMethod<String, Object?>(
          'replaceLive', {'playerId': playerId, 'url': url, 'hls': hls});

  static final _holes = <_NativeVideoHoleState>[];
  static bool _hooked = false;
  static int? _attached;
  static Rect? _sentRect;
  static bool _shown = false;
  static Timer? _diagTimer;
  static int _switchHolds = 0;

  /// Keep the native output in place while a replacement initializes. The
  /// owner must release on completion, failure or explicit stop/disposal.
  static VoidCallback retainForPlayerSwitch() {
    _switchHolds++;
    var released = false;
    return () {
      if (released) return;
      released = true;
      _switchHolds--;
      SchedulerBinding.instance.scheduleFrame();
    };
  }

  static void _register(_NativeVideoHoleState hole) {
    _holes.add(hole);
    if (!_hooked) {
      _hooked = true;
      // Registered after the renderer's own callback, so it runs once layout
      // and paint for the frame are done.
      SchedulerBinding.instance.addPersistentFrameCallback(_afterFrame);
    }
    SchedulerBinding.instance.scheduleFrame();
  }

  static void _unregister(_NativeVideoHoleState hole) {
    _holes.remove(hole);
    if (_holes.isEmpty) {
      _diagTimer?.cancel();
      _diagTimer = null;
    }
    SchedulerBinding.instance.scheduleFrame();
  }

  static void _afterFrame(Duration _) {
    _NativeVideoHoleState? top;
    // Last registered visible hole wins (a pushed full-screen player over the
    // guide's preview). Holes on routes covered by an opaque route have their
    // tickers off.
    for (final hole in _holes.reversed) {
      if (hole.visible) {
        top = hole;
        break;
      }
    }
    final box = top?.renderBox;
    if (top == null || box == null || !box.attached || !box.hasSize) {
      // An opaque route turns the retained preview's tickers off. Keep its
      // last native rect beneath that route, including its reverse transition;
      // recalculating an offstage box can send an intermediate/negative rect.
      if (_shown &&
          (_switchHolds > 0 || _holes.any((hole) => hole.coveredByRoute))) {
        return;
      }
      if (_shown) {
        _shown = false;
        _sentRect = null;
        _invoke('hide');
      }
      return;
    }
    final id = top.widget.playerId;
    if (id != _attached) {
      _attached = id;
      debugPrint('NativeSurface: attach player $id');
      _invoke('attach', {'playerId': id});
      _diagTimer?.cancel();
      _diagTimer = Timer(const Duration(seconds: 5), logDiagnostics);
    }
    final dpr = top.devicePixelRatio;
    final origin = box.localToGlobal(Offset.zero);
    final rect = Rect.fromLTWH(
      (origin.dx * dpr).roundToDouble(),
      (origin.dy * dpr).roundToDouble(),
      (box.size.width * dpr).roundToDouble(),
      (box.size.height * dpr).roundToDouble(),
    );
    if (rect == _sentRect && _shown) return;
    if (_sentRect?.size != rect.size || !_shown) {
      debugPrint('NativeSurface: hole ${rect.width.toInt()}x'
          '${rect.height.toInt()} at ${rect.left.toInt()},${rect.top.toInt()}'
          ' (dpr $dpr)');
    }
    _sentRect = rect;
    _shown = true;
    _invoke('setRect', {
      'left': rect.left.toInt(),
      'top': rect.top.toInt(),
      'width': rect.width.toInt(),
      'height': rect.height.toInt(),
    });
  }

  static void _invoke(String method, [Map<String, Object?>? args]) {
    unawaited(_channel.invokeMethod<Object?>(method, args).catchError((e) {
      debugPrint('NativeSurface: $method failed: $e');
      return null;
    }));
  }

  /// One line for Settings: is the beta really running (Dart flag set at
  /// launch, transparent window, video attached to the native surface)?
  static Future<String> statusLine() async {
    if (!active) return 'off';
    try {
      final s = await _channel.invokeMapMethod<String, Object?>('status');
      if (s == null) return 'unknown';
      final transparent = s['windowTransparent'] == true;
      final attached = s['attached'];
      final line =
          'on · window ${transparent ? 'transparent' : 'NOT transparent'}'
          ' · video ${s['surfaceAdded'] == true && attached != -1 ? 'on native surface (${s['surface']})' : 'not playing on it yet'}';
      debugPrint('NativeSurface: status $line');
      return line;
    } catch (e) {
      return 'error: $e';
    }
  }

  /// Writes what the native side knows (decoder, input format incl. HDR
  /// colour info, video/surface size, display mode + HDR support, dropped
  /// frames, tunneling) into the session log — logcat rolls over, this
  /// doesn't. Runs 5 s after each attach.
  static Future<void> logDiagnostics() async {
    try {
      final d = await _channel.invokeMapMethod<String, Object?>('diagnostics');
      if (d == null) return;
      for (final e in d.entries) {
        debugPrint('NativeSurface: ${e.key} = ${e.value}');
      }
    } catch (e) {
      debugPrint('NativeSurface: diagnostics failed: $e');
    }
  }
}

/// Where the main player's video shows when [NativeVideoSurface.active]:
/// a transparent hole the native SurfaceView behind Flutter shows through.
class NativeVideoHole extends StatefulWidget {
  const NativeVideoHole({super.key, required this.playerId});

  /// The plugin's player id (`VideoPlayerHdrController.textureId`).
  final int playerId;

  @override
  State<NativeVideoHole> createState() => _NativeVideoHoleState();
}

class _NativeVideoHoleState extends State<NativeVideoHole> {
  final _key = GlobalKey();
  bool _tickerOn = true;
  ModalRoute<dynamic>? _route;
  double devicePixelRatio = 1;

  RenderBox? get renderBox =>
      _key.currentContext?.findRenderObject() as RenderBox?;

  bool get visible => mounted && _tickerOn;

  bool get coveredByRoute {
    final route = _route;
    if (!mounted || route == null || !route.isActive) return false;
    return !route.isCurrent ||
        (route.secondaryAnimation?.value ?? 0) > 0 ||
        (route.secondaryAnimation?.isAnimating ?? false);
  }

  @override
  void initState() {
    super.initState();
    NativeVideoSurface._register(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Off on a route covered by an opaque one (and in hidden Visibility).
    _tickerOn = TickerMode.valuesOf(context).enabled;
    _route = ModalRoute.of(context);
    devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    SchedulerBinding.instance.scheduleFrame();
  }

  @override
  void dispose() {
    NativeVideoSurface._unregister(this);
    super.dispose();
  }

  // Own repaint boundary: the clear must be its own tiny picture, drawn onto
  // the frame after what's behind it. Inside a bigger cached picture it
  // would only clear that picture's pixels.
  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(child: _Hole(key: _key));
}

class _Hole extends LeafRenderObjectWidget {
  const _Hole({super.key});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHole();
}

class _RenderHole extends RenderBox {
  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas
        .drawRect(offset & size, Paint()..blendMode = BlendMode.clear);
  }
}

/// Native Multiview tiles (Android, only while [NativeVideoSurface.active]):
/// each Multiview screen's player draws into its own SurfaceView behind
/// Flutter (`MultiviewTiles.java`) instead of a Flutter texture, and a
/// [NativeTileHole] marks where it shows. Through textures every frame of
/// every tile went through Flutter's raster thread: 3 tiles played at ~7 fps
/// each (LOG-C47KFD) on a box that decodes 4K60 full screen.
///
/// The surface belongs to the player, not to the grid slot: Swap mode and
/// full screen only move it (no reconnect, no decoder restart).
class NativeMultiviewTiles {
  NativeMultiviewTiles._();

  static const _channel = MethodChannel('vespertv/multiview_tiles');

  static bool get enabled => NativeVideoSurface.active;

  /// Call right before `initialize(viewType: textureView)`: that player gets
  /// its own SurfaceView (bound before its decoder starts).
  static Future<void> nextIsTile() => _channel.invokeMethod<void>('nextIsTile');

  static final _holes = <_NativeTileHoleState>[];
  static bool _hooked = false;
  static String? _sent;

  static void _register(_NativeTileHoleState hole) {
    _holes.add(hole);
    if (!_hooked) {
      _hooked = true;
      SchedulerBinding.instance.addPersistentFrameCallback(_afterFrame);
    }
    SchedulerBinding.instance.scheduleFrame();
  }

  static void _unregister(_NativeTileHoleState hole) {
    _holes.remove(hole);
    SchedulerBinding.instance.scheduleFrame();
  }

  static void _afterFrame(Duration _) {
    if (_holes.isEmpty && (_sent == null || _sent == '')) return;
    final tiles = <int, Map<String, int>>{};
    // Later holes win for the same player (the pushed full-screen view over
    // its grid tile). Holes on a covered route are left out: the native
    // surfaces under an opaque route would otherwise overlap the full-screen
    // one, and SurfaceViews have no order among themselves.
    for (final hole in _holes) {
      if (!hole.visible) continue;
      final box = hole.renderBox;
      if (box == null || !box.attached || !box.hasSize) continue;
      final dpr = hole.devicePixelRatio;
      final origin = box.localToGlobal(Offset.zero);
      tiles[hole.widget.playerId] = {
        'playerId': hole.widget.playerId,
        'left': (origin.dx * dpr).round(),
        'top': (origin.dy * dpr).round(),
        'width': (box.size.width * dpr).round(),
        'height': (box.size.height * dpr).round(),
      };
    }
    final list = tiles.values.toList();
    final key = list
        .map((t) => '${t['playerId']}:${t['left']},${t['top']},'
            '${t['width']}x${t['height']}')
        .join(';');
    if (key == _sent) return;
    _sent = key;
    unawaited(_channel
        .invokeMethod<void>('setTiles', {'tiles': list}).catchError((Object e) {
      debugPrint('Multiview: native tiles failed: $e');
    }));
  }
}

/// Where a native Multiview tile's video shows: a transparent hole its
/// SurfaceView behind Flutter shows through. See [NativeMultiviewTiles].
class NativeTileHole extends StatefulWidget {
  const NativeTileHole({super.key, required this.playerId});

  /// The plugin's player id (`VideoPlayerHdrController.textureId`).
  final int playerId;

  @override
  State<NativeTileHole> createState() => _NativeTileHoleState();
}

class _NativeTileHoleState extends State<NativeTileHole> {
  final _key = GlobalKey();
  bool _tickerOn = true;
  double devicePixelRatio = 1;

  RenderBox? get renderBox =>
      _key.currentContext?.findRenderObject() as RenderBox?;

  bool get visible => mounted && _tickerOn;

  @override
  void initState() {
    super.initState();
    NativeMultiviewTiles._register(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerOn = TickerMode.valuesOf(context).enabled;
    devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    SchedulerBinding.instance.scheduleFrame();
  }

  @override
  void dispose() {
    NativeMultiviewTiles._unregister(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(child: _Hole(key: _key));
}
