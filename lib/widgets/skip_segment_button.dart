import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter/services.dart';
import 'package:video_player_hdr/video_player_hdr.dart';

import '../l10n/l10n.dart';
import '../services/skip_segments.dart';
import '../services/watch_tracker.dart';

/// Follows the playing episode's position and says which intro / recap /
/// credits range it's in ([visible]). Like Nuvio: the button shows when the
/// range starts, hides itself after [autoHide], and comes back while the
/// player bar is showing. Notifies only when that answer changes, not on
/// every position tick.
class SkipSegmentWatcher extends ChangeNotifier {
  SkipSegmentWatcher({SkipSegments? source})
      : _source = source ?? SkipSegments.instance;

  final SkipSegments _source;
  static const autoHide = Duration(seconds: 10);

  /// Not worth a button with less than this left of the range.
  static const _minLeft = Duration(milliseconds: 1500);

  VideoPlayerHdrController? _controller;

  /// Windows: the mpv player ([attachDesktop]) instead of [_controller].
  Player? _desktop;
  StreamSubscription<Duration>? _desktopTicks;
  String? _channelId;
  bool _requested = false;
  bool _missingLogged = false;
  List<SkipSegment> _segments = const [];
  SkipSegment? _active;
  SkipSegment? _shownFor;
  final Set<SkipSegment> _skipped = {};
  bool _autoHidden = false;
  Timer? _hideTimer;

  /// The range to offer now, or null ([controlsVisible]: the player bar is
  /// showing, which brings an auto-hidden button back).
  SkipSegment? visibleWith(bool controlsVisible) =>
      _active != null && (!_autoHidden || controlsVisible) ? _active : null;

  /// For change checks: the answer with the bar hidden or shown.
  (SkipSegment?, SkipSegment?) get _state =>
      (visibleWith(false), visibleWith(true));

  /// Called on every player build: the playing controller and channel.
  /// Off ([enabled] false), a live channel or a channel without episode ids
  /// = no button.
  void attach(VideoPlayerHdrController? controller, String channelId,
      {required bool enabled,
      required bool episodeCandidate,
      String? tmdbKey}) {
    if (!identical(controller, _controller)) {
      _controller?.removeListener(_onTick);
      _controller = controller;
      controller?.addListener(_onTick);
    }
    _attachChannel(channelId,
        enabled: enabled, episodeCandidate: episodeCandidate, tmdbKey: tmdbKey);
  }

  /// Windows ([DesktopPlayerScreen]): the same button over the mpv player.
  void attachDesktop(Player player, String channelId,
      {required bool enabled,
      required bool episodeCandidate,
      String? tmdbKey}) {
    if (!identical(player, _desktop)) {
      _desktopTicks?.cancel();
      _desktop = player;
      _desktopTicks = player.stream.position.listen((_) => _onTick());
    }
    _attachChannel(channelId,
        enabled: enabled, episodeCandidate: episodeCandidate, tmdbKey: tmdbKey);
  }

  Duration? get _position =>
      _desktop?.state.position ?? _controller?.value.position;
  Duration get _duration =>
      _desktop?.state.duration ?? _controller?.value.duration ?? Duration.zero;

  void _attachChannel(String channelId,
      {required bool enabled,
      required bool episodeCandidate,
      String? tmdbKey}) {
    if (channelId != _channelId) {
      // Called from the player's build: no notify (the button below is
      // rebuilt in the same pass anyway).
      _channelId = channelId;
      _requested = false;
      _missingLogged = false;
      _segments = const [];
      _skipped.clear();
      _shownFor = null;
      _active = null;
      _hideTimer?.cancel();
    }
    if (_requested || !enabled || !episodeCandidate) return;
    final item = WatchTracker.instance.itemFor(channelId);
    // Ids are registered when the series page / Media Hub starts the
    // episode; until then later builds try again.
    if (item == null || !item.isEpisode) {
      // Send log: an IPTV show without a TMDB id (or episode numbers) is
      // never registered, so it never asks IntroDB.
      if (!_missingLogged) debugPrint('SkipIntro: no episode ids (yet)');
      _missingLogged = true;
      return;
    }
    _requested = true;
    unawaited(_source
        .forEpisode(
            imdb: item.imdb,
            tmdb: item.tmdb,
            season: item.season!,
            episode: item.episode!,
            tmdbKey: tmdbKey)
        .then((segments) {
      if (_channelId != channelId) return;
      _segments = segments;
      _onTick();
    }));
  }

  void _onTick() {
    final position = _position;
    if (position == null || _segments.isEmpty) return _setActive(null);
    final duration = _duration;
    SkipSegment? found;
    for (final s in _segments) {
      final end =
          duration > Duration.zero && s.end > duration ? duration : s.end;
      if (!_skipped.contains(s) &&
          s.contains(position) &&
          end - position > _minLeft) {
        found = s;
        break;
      }
    }
    _setActive(found);
  }

  void _setActive(SkipSegment? segment) {
    if (segment == _active) return;
    final before = _state;
    _active = segment;
    if (segment != null && segment != _shownFor) {
      // A new range (or the same one entered again after leaving it).
      _shownFor = segment;
      _autoHidden = false;
      _hideTimer?.cancel();
      _hideTimer = Timer(autoHide, () {
        final was = _state;
        _autoHidden = true;
        if (_state != was) notifyListeners();
      });
    } else if (segment == null) {
      _shownFor = null;
      _hideTimer?.cancel();
    }
    if (_state != before) notifyListeners();
  }

  /// Jumps past [segment]: credits with a next episode queued play it
  /// ([playNext]); otherwise the end of the range.
  Future<void> skip(SkipSegment segment, {VoidCallback? playNext}) async {
    final controller = _controller;
    final desktop = _desktop;
    if (controller == null && desktop == null) return;
    if (segment.kind == SkipKind.outro && playNext != null) {
      _skipped.add(segment);
      _setActive(null);
      playNext();
      return;
    }
    final duration = _duration;
    var target = segment.end;
    if (duration > Duration.zero &&
        target > duration - const Duration(milliseconds: 500)) {
      target = duration - const Duration(milliseconds: 500);
    }
    // Never offered again for this episode (the seek lands a moment later).
    _skipped.add(segment);
    _setActive(null);
    if (desktop != null) {
      await desktop.seek(target);
    } else {
      await controller!.seekTo(target);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_onTick);
    _desktopTicks?.cancel();
    super.dispose();
  }
}

/// The remote hint on the pill: none (touch), OK (it takes OK now) or Up
/// (the player bar has the focus; Up from the bar reaches the pill).
enum SkipHint { none, ok, up }

/// The white "Skip intro ⏭" pill above the player bar. Always returns a
/// `Positioned` (it sits straight in the player's Stack; see `_UpNextBubble`
/// for why a bare widget there collapsed the whole player). A TV remote
/// uses OK (the player maps it while this shows and nothing else has the
/// focus), or Up from the player bar to [focusNode]; a touch screen taps it.
class SkipSegmentButton extends StatelessWidget {
  const SkipSegmentButton({
    super.key,
    required this.watcher,
    required this.controlsVisible,
    required this.hasNext,
    required this.hint,
    required this.onSkip,
    this.focusNode,
    this.onDown,
    this.onUp,
  });

  final SkipSegmentWatcher watcher;
  final bool controlsVisible;
  final bool hasNext;
  final SkipHint hint;
  final ValueChanged<SkipSegment> onSkip;

  /// Focused from the player bar (Up). OK skips, Down goes back to the bar
  /// ([onDown]), Left/Right/Up stay.
  final FocusNode? focusNode;
  final VoidCallback? onDown;

  /// Up from the pill (the Watch game pill above it); null = stay.
  final VoidCallback? onUp;

  static const _hidden = Positioned(
      right: 24, bottom: 200, width: 0, height: 0, child: SizedBox.shrink());

  static String label(SkipKind kind, bool hasNext) => switch (kind) {
        SkipKind.intro => tr('Skip intro'),
        SkipKind.recap => tr('Skip recap'),
        SkipKind.outro => hasNext ? tr('Next episode') : tr('Skip credits'),
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: watcher,
      builder: (context, _) {
        final segment = watcher.visibleWith(controlsVisible);
        if (segment == null) return _hidden;
        return Positioned(
          right: 24,
          // Above the player bar and the Up Next card.
          bottom: 200,
          child: Focus(
            focusNode: focusNode,
            canRequestFocus: focusNode != null,
            skipTraversal: true,
            onKeyEvent: (_, event) {
              final key = event.logicalKey;
              if (key == LogicalKeyboardKey.select ||
                  key == LogicalKeyboardKey.enter ||
                  key == LogicalKeyboardKey.numpadEnter) {
                if (event is KeyDownEvent) onSkip(segment);
                return KeyEventResult.handled;
              }
              if (key == LogicalKeyboardKey.arrowDown) {
                if (event is KeyDownEvent) onDown?.call();
                return KeyEventResult.handled;
              }
              if (key == LogicalKeyboardKey.arrowUp && onUp != null) {
                if (event is KeyDownEvent) onUp!();
                return KeyEventResult.handled;
              }
              if (key == LogicalKeyboardKey.arrowUp ||
                  key == LogicalKeyboardKey.arrowLeft ||
                  key == LogicalKeyboardKey.arrowRight) {
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Builder(builder: (context) {
              final focused = Focus.of(context).hasFocus;
              return _pill(segment, focused);
            }),
          ),
        );
      },
    );
  }

  Widget _pill(SkipSegment segment, bool focused) {
    final shown = focused ? SkipHint.ok : hint;
    return AnimatedScale(
      scale: focused ? 1.08 : 1,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: Colors.white,
        shape: StadiumBorder(
            side: focused
                ? const BorderSide(color: Color(0xFFD4AF37), width: 3)
                : BorderSide.none),
        elevation: focused ? 10 : 6,
        child: InkWell(
          customBorder: const StadiumBorder(),
          canRequestFocus: false,
          onTap: () => onSkip(segment),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label(segment.kind, hasNext),
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                const Icon(Icons.skip_next_rounded,
                    color: Colors.black, size: 24),
                if (shown != SkipHint.none) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.black45),
                    ),
                    child: shown == SkipHint.up
                        ? const Icon(Icons.keyboard_arrow_up_rounded,
                            color: Colors.black54, size: 16)
                        : Text(tr('OK'),
                            style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
