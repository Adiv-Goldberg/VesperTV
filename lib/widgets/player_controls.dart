import '../utils/refined_finish.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player_hdr/video_player_hdr.dart';

import '../models/channel.dart';
import '../models/epg_program.dart';
import '../services/app_preferences.dart';
import '../services/epg_service.dart';
import '../services/playback_service.dart';
import '../services/playlist_manager.dart';
import '../services/addon_service.dart';
import '../services/storage_service.dart';
import '../services/subtitle_tracks.dart';
import '../services/audio_track_preferences.dart';
import '../services/catchup_session.dart';
import '../utils/time_format.dart';
import '../utils/video_quality.dart';
import 'data_pool_card.dart';
import 'epg_guide.dart';
import 'gold_tag.dart';
import 'native_video_hole.dart';
import 'rec_cue.dart';
import 'player_bar_title.dart';
import 'tv_menu_tile.dart';
import '../l10n/l10n.dart';

/// Renders whatever [PlaybackService] is currently playing.
///
/// Purely presentational — it doesn't own a controller or start playback
/// itself; call `context.read<PlaybackService>().play(channel)` to start
/// something, and every mounted [VideoPlayerPane] (inline pane, fullscreen
/// screen, mini-player) reflects the same live video.
class VideoPlayerPane extends StatelessWidget {
  const VideoPlayerPane(
      {super.key,
      this.showEpgBar = true,
      this.showControls = true,
      this.fillScreen = false,
      this.switchButtonFocusNode});

  /// Zoom the picture to cover the whole pane (edges cropped, no black
  /// bars) — the fullscreen player's ⛶ button. Not clipped here: the pane
  /// is the whole screen there, the display edge does the cropping (a clip
  /// on a platform view costs weak boxes a lot).
  final bool fillScreen;

  final bool showEpgBar;

  /// [PlayerScreen] renders its own auto-hiding controls overlay (so the
  /// seek bar can't permanently steal D-pad focus) and just wants the bare
  /// video here — pass false there.
  final bool showControls;

  /// [PlayerScreen] needs to know when this button has focus (and be able
  /// to move focus onto/off of it itself) so its own D-pad handling can
  /// treat it as a third explicit zone alongside its top/bottom bars,
  /// rather than leaving it to Flutter's directional focus search — that
  /// search isn't bounded to "the bar you're currently in" the way you'd
  /// expect, and was confirmed to jump straight from the bottom bar to the
  /// top bar, skipping this button entirely, once it existed as a third
  /// focusable thing geometrically between two very differently-shaped
  /// full-width bars. Null (this pane's small inline preview instances,
  /// tv_home_screen.dart/home_screen.dart) just falls back to an internal,
  /// non-autofocusing node — those have no such handling and shouldn't
  /// steal focus for an errored preview tile anyway.
  final FocusNode? switchButtonFocusNode;

  /// Sizes the video to fit the pane (black bars) or, with [fillScreen], to
  /// cover it. The same widgets either way, so toggling never recreates the
  /// platform view.
  Widget _fit(double ratio, Widget child) => LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          if (!w.isFinite || !h.isFinite || h == 0) return child;
          final paneWider = w / h > ratio;
          final size =
              paneWider != fillScreen ? Size(h * ratio, h) : Size(w, w / ratio);
          return OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: SizedBox.fromSize(size: size, child: child),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackService>();
    final channel = playback.currentChannel;
    final controller = playback.controller;

    // Mid-switch: the old player is still being released (see
    // PlaybackService.switching) — loading, not "nothing playing".
    if (controller == null && playback.switching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (channel == null || controller == null) {
      // play() can refuse before anything starts (a disabled playlist):
      // say why instead of "Select a channel".
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(playback.error ?? tr('Select a channel to start watching'),
            textAlign: TextAlign.center),
      ));
    }

    if (playback.error != null) {
      // Reached only once this playlist's own connection attempt *and*
      // its backup servers (see PlaylistProfile.backupServers) have both
      // already failed — a manually-linked channel on another playlist
      // (see PlayerControls.linkedChannel's doc comment) is offered here
      // front-and-center, since at this point this playlist genuinely has
      // nothing left to try on its own.
      final channelLink =
          context.watch<PlaylistManager>().channelLinkFor(channel);
      final linkedChannel = channelLink == null
          ? null
          : context.read<PlaylistManager>().resolveChannelLink(channelLink);
      // 48 px sides + width cap: a long message ran past both edges of a
      // TV with overscan (Formuler photo, 2026-10-21).
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_friendlyPlaybackError(playback.error!),
                  textAlign: TextAlign.center),
              if (linkedChannel != null) ...[
                const SizedBox(height: 16),
                _SwitchToLinkedChannelButton(
                  focusNode: switchButtonFocusNode,
                  label: tr('Switch to {p}: {name}', {
                    'p': context
                        .read<PlaylistManager>()
                        .playlistNameFor(linkedChannel.playlistId),
                    'name': linkedChannel.name
                  }),
                  onPressed: () =>
                      context.read<PlaybackService>().play(linkedChannel),
                ),
              ],
              const SizedBox(height: 12),
              // Always shown (not collapsed): user reports arrive as a
              // photo of the TV, and the raw error is what diagnoses them.
              Text(tr('Technical details'),
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 4),
              Text(
                playback.error!,
                textAlign: TextAlign.center,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<void>(
      future: playback.initFuture,
      builder: (context, snapshot) {
        if (!controller.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // rawId, not the composite `id` — see
            // PlaylistManager.knownChannelIdsFor's doc comment.
            if (showEpgBar) EpgGuide(channelId: channel.epgId),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Plain AspectRatio again — the FittedBox-at-native-size
                  // workaround tried here was for the stock `video_player`
                  // package's Texture-stretch bug specifically, which is
                  // exactly what switching to `video_player_hdr`'s
                  // platform-view rendering is meant to avoid needing a
                  // workaround for at all.
                  _fit(
                    controller.value.aspectRatio == 0
                        ? 16 / 9
                        : controller.value.aspectRatio,
                    AspectRatio(
                      aspectRatio: controller.value.aspectRatio == 0
                          ? 16 / 9
                          : controller.value.aspectRatio,
                      // Keyed to the controller instance — confirmed on
                      // real hardware as the cause of a frozen frame
                      // surviving a channel switch: with no key here,
                      // Flutter sees "same widget type, same position"
                      // when a new controller replaces the old one and
                      // tries to update the existing platform view
                      // element in place instead of tearing it down and
                      // creating a fresh one. On this device's renderer
                      // that in-place rebind doesn't actually take — the
                      // native surface keeps showing whatever the
                      // previous channel last painted. Same fix shape as
                      // Group Management's checkbox stale-repaint bug
                      // earlier this session: force element recreation
                      // via a changing key instead of relying on an
                      // in-place update this hardware silently drops.
                      // Native video surface (beta): a hole the
                      // SurfaceView behind Flutter shows through.
                      child: PlaybackService.drawsNativeSurface(controller)
                          ? NativeVideoHole(
                              // The plugin player id; no public getter.
                              // ignore: invalid_use_of_visible_for_testing_member
                              playerId: controller.textureId,
                              key: ObjectKey(controller))
                          : VideoPlayerHdr(controller,
                              key: ObjectKey(controller)),
                    ),
                  ),
                  // A reconnect (either a manual Reload or an automatic
                  // backup-server retry) used to replace this whole pane
                  // with a plain `Center` — the frozen last frame has no
                  // reason to disappear while a fresh connection comes up
                  // behind it, and a full black takeover read as a crash,
                  // not a recovery in progress (reported directly: "looks
                  // less like Windows restart"). A small floating card is
                  // the same translucent-scrim look the Recall picker
                  // already uses, just centered over the video instead of
                  // anchored to the controls bar.
                  if (playback.reconnectStatus != null)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 22),
                        decoration: RefinedFinish.decorate(
                            context,
                            BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.62),
                              borderRadius: BorderRadius.circular(16),
                            )),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                                width: 28,
                                height: 28,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                            const SizedBox(height: 16),
                            Text(playback.reconnectStatus!,
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  if (showControls)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: PlayerControls(
                        controller: controller,
                        title: channel.name,
                        // rawId, not the composite `id` — see
                        // PlaylistManager.knownChannelIdsFor's doc comment.
                        channelId: channel.epgId,
                        isLive: channel.isLive,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Takes an externally-owned [FocusNode] when the caller needs to drive/
/// observe this button's focus itself (see
/// [VideoPlayerPane.switchButtonFocusNode]'s doc comment — [PlayerScreen]
/// is the only such caller) and requests focus for it once this widget is
/// actually built. A plain `autofocus: true` isn't reliable here: whoever
/// hosts this pane typically claims focus for its own key handling well
/// before a stream error (and this button) can exist, so an ambient
/// autofocus flag has nothing to preempt at that point. Falls back to an
/// owned, non-autofocusing node when none is supplied, for this pane's
/// small inline preview instances that have no need for any of this.
class _SwitchToLinkedChannelButton extends StatefulWidget {
  const _SwitchToLinkedChannelButton(
      {required this.label, required this.onPressed, this.focusNode});

  final String label;
  final VoidCallback onPressed;
  final FocusNode? focusNode;

  @override
  State<_SwitchToLinkedChannelButton> createState() =>
      _SwitchToLinkedChannelButtonState();
}

class _SwitchToLinkedChannelButtonState
    extends State<_SwitchToLinkedChannelButton> {
  FocusNode? _ownedFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ??
      (_ownedFocusNode ??= FocusNode(debugLabel: 'switch-to-linked-channel'));

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => widget.focusNode!.requestFocus());
    }
  }

  @override
  void dispose() {
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      focusNode: _focusNode,
      icon: const Icon(Icons.swap_horiz),
      label: Text(widget.label),
      onPressed: widget.onPressed,
    );
  }
}

/// Translates the handful of raw platform exceptions actually seen in the
/// wild into something a viewer can act on. Confirmed on real hardware
/// (a Formuler box) via a `MediaCodecVideoRenderer` error dumping a 4K
/// HEVC 10-bit HDR (`ColorInfo(BT2020, ..., ST2084 PQ, ..., 10bit)`)
/// stream's format — the device's decoder reports the format as
/// supported (`format_supported=YES`) but still fails to actually decode
/// it. That's a real hardware/driver limitation on that box, not
/// something `video_player`/Flutter can route around — no amount of app
/// code makes an incapable decoder chip decode 10-bit HDR. This just
/// stops surfacing that as a raw stack-trace-shaped string.
String _friendlyPlaybackError(String raw) {
  // No decoder for the video at all (ExoPlayerEventListener's
  // [UNSUPPORTED_VIDEO: mime codecs size] tag). Dolby Vision profile 5/7 is
  // the usual one: profile 8 already plays as HDR10 on a plain HEVC decoder.
  if (raw.contains('[UNSUPPORTED_VIDEO: video/dolby-vision')) {
    return tr(
        "This is a Dolby Vision video, and this device can't play this kind of Dolby Vision. Pick a version without DV (HDR10 or SDR) if your source has one.");
  }
  // ExoPlayerEventListener.restartLooping: kept failing and restarting, and
  // a fresh reload didn't hold either (PlaybackService._watchRestartLoop).
  if (raw.contains('[RESTART_LOOP')) {
    return tr(
        'This stream kept dropping and restarting, so playback was stopped. Try the channel again in a moment, or pick another one.');
  }
  if (isDecoderPlaybackError(raw)) {
    return tr(
        'This device\'s video decoder couldn\'t play this stream — likely 4K HDR (HEVC 10-bit). If your provider offers an HD (non-4K) version of this channel or title, try that. If another app plays this stream on this device, please report it with a photo of the technical details below.');
  }
  // What the link really served (PlaybackService._sniffUnreadable).
  final reply = RegExp(r'\[SOURCE_REPLY:(\w+)[^\]]*\] ?(.*)').firstMatch(raw);
  if (reply != null) {
    if (reply[1] == 'binary') {
      return tr(
          'This file\'s format can\'t be played here. Try another stream (an MKV or MP4 one).');
    }
    final said = reply[2]?.trim() ?? '';
    return [
      tr('Your source sent a message instead of the video:'),
      if (said.isNotEmpty) '"$said"',
      tr('Check your source or debrid account (plan limits, active downloads), or pick another stream.'),
    ].join('\n');
  }
  final status = httpStatusFromPlaybackError(raw);
  if (status != null) {
    final hint = status >= 500
        ? tr('The provider\'s server had a problem. Try again in a moment.')
        : status == 401 || status == 403
            ? tr(
                'The provider refused the stream: check that your account is active and not already in use on another device.')
            : status == 404 || status == 410
                ? tr(
                    'The provider has no stream at this address: the channel or title may have been removed.')
                : tr('The provider rejected the request.');
    return '${tr('Server error {code}', {'code': '$status'})}\n$hint';
  }
  if (_isDnsLookupFailure(raw)) {
    return tr(
        'Couldn\'t find the provider\'s server address. Check your internet connection or DNS settings, or try again later.');
  }
  if (raw.contains('ERROR_CODE_IO_NETWORK_CONNECTION_FAILED') ||
      raw.contains('ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT')) {
    return tr(
        'Couldn\'t reach the provider\'s server. Check your internet connection, or the server may be down.');
  }
  // Details are printed in full below the message, so only name the code.
  final code = RegExp(r'\[(ERROR_CODE_\w+)\]').firstMatch(raw)?.group(1);
  return tr('Playback error:\n{raw}', {'raw': code ?? tr('unknown error')});
}

bool _isDnsLookupFailure(String raw) {
  final lower = raw.toLowerCase();
  return lower.contains('unknownhostexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('unable to resolve host') ||
      lower.contains('no address associated with hostname') ||
      lower.contains('getaddrinfo failed') ||
      lower.contains('eai_noname') ||
      lower.contains('name or service not known') ||
      lower.contains('nodename nor servname');
}

/// Bottom-anchored playback controls: play/pause, seek bar, elapsed/total
/// duration. Rebuilds on every controller tick via [ValueListenableBuilder]
/// rather than manual `setState` calls. Fullscreen/immersive mode is a
/// screen-level concern (see [PlayerScreen]), not a control-bar one.
class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.controller,
    required this.title,
    required this.channelId,
    required this.isLive,
    this.isFavorite,
    this.onToggleFavorite,
    this.onPrevious,
    this.onNext,
    this.onActivity,
    this.linkedChannel,
    this.channel,
    this.showMore = false,
    this.onToggleMore,
    this.onOpenMultiview,
    this.playFocusNode,
    this.insetForSystemBars = false,
  });

  /// The full-screen player's bar: kept clear of the system navigation bar
  /// and cutouts (it sat under a phone's 3-button bar, Pixel 10 Pro XL), and
  /// laid out on two lines on a portrait phone.
  final bool insetForSystemBars;

  final VideoPlayerHdrController controller;
  final String title;

  /// Which EPG programme to check remaining time against — only read
  /// when [isLive] is true.
  final String channelId;

  /// Whether [controller]'s own `duration`/`position` should be trusted
  /// at all for the seek bar and skip buttons. Confirmed on real hardware:
  /// some live HLS streams report a small *nonzero* duration here — the
  /// length of their current DVR sliding window (e.g. ~60s), not the
  /// zero/unknown value a clean live stream reports — which made the seek
  /// bar activate and show a constantly-resetting ~1-minute timer instead
  /// of staying hidden the way a real live stream's `duration == 0` case
  /// already did. `video_player_hdr` has no live/VOD signal of its own to
  /// check instead (its `VideoPlayerHdrValue` has no `isLive` field) — so
  /// this comes from the caller, which already knows the channel's
  /// catalog classification (`Channel.isLive`), never from the video
  /// duration. When true, the seek bar/skip buttons/elapsed-duration text
  /// are replaced by the current EPG programme's remaining time instead
  /// (see [_LiveRemainingLabel]) — actually meaningful for a live channel,
  /// unlike a number that resets every minute.
  final bool isLive;

  /// Null hides the favorite button entirely (the shared inline preview
  /// panes don't pass these) — [PlayerScreen] is the one caller that does,
  /// so pressing Down to reveal these controls also surfaces "add to
  /// favorites" for whatever's playing.
  final bool? isFavorite;
  final VoidCallback? onToggleFavorite;

  /// Null hides the button entirely — a movie or live channel has no
  /// previous/next *episode* concept (see PlaybackService.previousUpChannel/
  /// nextUpChannel, both null in that case), and only [PlayerScreen] passes
  /// these at all, same as [onToggleFavorite] above.
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  /// Called on every skip-button seek tick (a tap, or each tick of a
  /// held fast-seek) — reported directly: this bar's own auto-hide timer
  /// keeps counting down completely untouched by an in-progress fast-
  /// seek, since nothing about pressing Select on the skip button was
  /// ever wired to reset it. A hold long enough to be worth doing at all
  /// (several seconds, easily past the 6s auto-hide) could have the bar
  /// disappear mid-seek, leaving the user to bring it back and start
  /// over. [PlayerScreen] wires this to the same reset its own Up/Down
  /// handling already calls.
  final VoidCallback? onActivity;

  /// Null hides the button entirely — see [Channel.epgIdOverride]'s
  /// sibling concept, `PlaylistManager.channelLinkFor`: a manually-linked
  /// equivalent channel on another playlist, always offered here
  /// (whether or not anything's currently wrong) as a one-press manual
  /// failover, requested directly for exactly the case a shared/rebranded
  /// provider outage takes one playlist down but not another. Deliberately
  /// not automatic — see [VideoPlayerPane]'s own error-state version of
  /// this same button for why the app can't yet tell a genuine outage
  /// apart from an ordinary rebuffer on its own.
  final Channel? linkedChannel;

  /// The live channel actually playing — only used to exclude it from its
  /// own Recall history below. Null hides that button entirely, same
  /// convention as [onToggleFavorite]/[linkedChannel] — the shared inline
  /// preview panes don't pass it.
  final Channel? channel;

  /// Whether the secondary ("more") action row — Recall, Reload, audio
  /// track, linked-channel failover — is currently expanded. Owned by the
  /// caller (`PlayerScreen`'s `_moreVisible`), same "parent owns bar
  /// visibility" convention [PlayerScreen] already uses for its own top/
  /// bottom bars — this widget stays presentational, not stateful.
  final bool showMore;

  /// Reveals/hides the secondary row — null (the default, and what
  /// `VideoPlayerPane`'s own bare inline construction passes implicitly by
  /// omission) hides the chevron hint entirely, so a caller that hasn't
  /// wired this up gets the unchanged single-row layout rather than a
  /// chevron that does nothing.
  final VoidCallback? onToggleMore;

  /// Opens Multiview with whatever's currently playing already loaded as
  /// the first cell — lives in the secondary row, gated on [isLive]
  /// (Multiview is live-TV only) at the call site, same as Recall/Reload.
  /// Null hides the button entirely, same convention as every other
  /// optional action here; kept as a callback rather than this widget
  /// importing `MultiviewScreen` itself and navigating directly, so this
  /// file stays navigation-agnostic — [PlayerScreen] owns the actual
  /// `Navigator.push`.
  final VoidCallback? onOpenMultiview;

  /// Play/Pause's node, so the caller can land the remote's focus on it
  /// when the bar opens (PlayerScreen._focusBottomBar).
  final FocusNode? playFocusNode;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final inset = insetForSystemBars
        ? MediaQuery.viewPaddingOf(context)
        : EdgeInsets.zero;
    return Container(
      color: RefinedFinish.surface(context, Colors.black54),
      padding: EdgeInsets.fromLTRB(
          12 + inset.left, 6, 12 + inset.right, 6 + inset.bottom),
      child: ValueListenableBuilder<VideoPlayerHdrValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final position = value.position;
          final duration = value.duration;
          // See [isLive]'s doc comment — never inferred from duration.
          final showSeek = !isLive && duration.inMilliseconds > 0;
          // Not every host provides the service (widget tests).
          PlaybackService? playback;
          try {
            playback = context.watch<PlaybackService>();
          } on ProviderNotFoundException {
            playback = null;
          }
          // A past programme from the live channel's catch-up: programme
          // jumps, Start and Back to live join the transport.
          final session = playback?.catchup;
          final catchup = session != null &&
                  channel != null &&
                  session.channel.id == channel!.id
              ? session
              : null;
          final ownsPlayer =
              playback != null && playback.controller == controller;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Excluded from D-pad focus always: a focused Slider consumes
              // Left/Right itself for seeking, ahead of any ancestor
              // Shortcuts/CallbackShortcuts trying to use those keys for
              // navigation (e.g. PlayerScreen's "Left always goes back").
              // Touch/mouse dragging is unaffected — this only removes it
              // from keyboard/remote focus traversal.
              // The Slider itself stays out of focus; [_ScrubBar] is the
              // remote's way onto it (Up from the buttons).
              if (showSeek)
                _ScrubBar(
                  controller: controller,
                  position: position,
                  duration: duration,
                  onActivity: onActivity,
                ),
              // Favorite sits with the transport: alone above the seek bar
              // it was out of reach of up/down movement within this bar.
              // One line for every button (owner, 2026-10-18: cleaner than
              // the old chevron-revealed second row). The situational ones
              // (Recall, Reload, tracks, failover, Multiview) only in the
              // fullscreen player — the caller that passes [onToggleMore];
              // inline previews keep just the transport. Never wraps (a
              // second line made the bar huge): compact buttons, and the
              // whole line scales down where it doesn't fit (phone portrait).
              // One row (owner, 2026-10-18: slimmer): title left, buttons
              // centred, badges + time right — the two sides share the
              // leftover width equally so the buttons stay centred.
              // Portrait phone (full-screen player only): title and time on
              // one line, the buttons on their own full-width line below —
              // squeezed into 60% of a portrait width they were tiny
              // (owner + Discord, 2026-10-28).
              LayoutBuilder(builder: (context, box) {
                final twoLines = insetForSystemBars && box.maxWidth < 600;
                final titleCell = Expanded(
                  child: catchup == null
                      ? PlayerBarTitle(title: title)
                      : Row(children: [
                          GoldTag(
                              label: tr('Catch-up').toUpperCase(),
                              margin: const EdgeInsets.only(right: 6)),
                          Expanded(
                              child: PlayerBarTitle(
                                  title: _catchupTitle(
                                      context, catchup, position))),
                        ]),
                );
                final buttons = ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: twoLines ? box.maxWidth : box.maxWidth * 0.6),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(visualDensity: VisualDensity.compact),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onToggleFavorite != null)
                            IconButton(
                              icon: Icon(
                                isFavorite == true
                                    ? Icons.star
                                    : Icons.star_border,
                                color: isFavorite == true
                                    ? Colors.amber
                                    : Colors.white,
                              ),
                              tooltip: isFavorite == true
                                  ? tr('Remove from favorites')
                                  : tr('Add to favorites'),
                              onPressed: onToggleFavorite,
                            ),
                          // Episode nav — distinct icon shape (skip_previous/next,
                          // not replay_10/forward_10) so it doesn't read as "seek
                          // within this episode" the way the buttons either side
                          // of play/pause already do.
                          if (onPrevious != null)
                            IconButton(
                              icon: const Icon(Icons.skip_previous,
                                  color: Colors.white),
                              tooltip: tr('Previous episode'),
                              onPressed: onPrevious,
                            ),
                          if (catchup != null)
                            ..._catchupLeading(context, playback!, catchup),
                          // Skip/fast-seek only makes sense for VOD.
                          if (showSeek)
                            _SkipButton(
                              icon: Icons.replay_10,
                              onSeek: (amount) {
                                onActivity?.call();
                                final target = position - amount;
                                controller.seekTo(target < Duration.zero
                                    ? Duration.zero
                                    : target);
                              },
                            ),
                          IconButton(
                            tooltip: value.isPlaying ? tr('Pause') : tr('Play'),
                            focusNode: playFocusNode,
                            icon: Icon(
                                value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white),
                            // The service's toggle: pausing a live
                            // channel with catch-up is a timeshift.
                            onPressed: () => ownsPlayer
                                ? playback!.togglePlayPause()
                                : value.isPlaying
                                    ? controller.pause()
                                    : controller.play(),
                          ),
                          if (showSeek)
                            _SkipButton(
                              icon: Icons.forward_10,
                              onSeek: (amount) {
                                onActivity?.call();
                                final target = position + amount;
                                controller.seekTo(
                                    target > duration ? duration : target);
                              },
                            ),
                          if (onNext != null)
                            IconButton(
                              icon: const Icon(Icons.skip_next,
                                  color: Colors.white),
                              tooltip: tr('Next episode'),
                              onPressed: onNext,
                            ),
                          if (catchup != null)
                            ..._catchupTrailing(context, playback!, catchup),
                          if (onToggleMore != null) ...[
                            if (isLive && channel != null)
                              _LabeledIconButton(
                                icon: Icons.history,
                                label:
                                    tr('Recall — go back to a recent channel'),
                                onPressed: () {
                                  onActivity?.call();
                                  showRecallPicker(context, channel!);
                                },
                              ),
                            // Start over: the programme on now, from
                            // its start (catch-up channels only).
                            if (isLive &&
                                channel != null &&
                                channel!.hasCatchup)
                              _LabeledIconButton(
                                icon: Icons.restart_alt,
                                label: tr('Watch from the start'),
                                onPressed: () {
                                  onActivity?.call();
                                  final now = context
                                      .read<EpgService>()
                                      .getCurrentProgram(channel!.epgId);
                                  if (now != null) {
                                    playback?.playCatchup(channel!, now.start);
                                  }
                                },
                              ),
                            // Manual recovery for a channel that's silently
                            // stalled (frozen frame, no spinner, no error) — see
                            // PlaybackService.reloadCurrentChannel's doc comment
                            // for why this is a manual button rather than an
                            // automatic watchdog. Live only, same gating as Recall
                            // above.
                            if (isLive && channel != null)
                              _LabeledIconButton(
                                icon: Icons.refresh,
                                label: tr('Reload channel'),
                                onPressed: () {
                                  onActivity?.call();
                                  context
                                      .read<PlaybackService>()
                                      .reloadCurrentChannel();
                                },
                              ),
                            // Keyed by stream: the bar stays mounted
                            // across zaps (and a native live zap
                            // keeps the controller), so without a
                            // new key the track lists were read
                            // once per player screen and a later
                            // channel's audio tracks never showed
                            // (CBC Montreal described-video track,
                            // owner 2026-10-26).
                            _AudioTrackButton(
                                key: ValueKey(Object.hash(
                                    'audio', controller, channel?.id)),
                                controller: controller),
                            _SubtitleButton(
                                key: ValueKey(Object.hash(
                                    'subs', controller, channel?.id)),
                                controller: controller),
                            if (linkedChannel != null)
                              _LinkedChannelButton(
                                  linkedChannel: linkedChannel!),
                            if (isLive && onOpenMultiview != null)
                              _LabeledIconButton(
                                icon: Icons.grid_view,
                                label: tr('Open in Multiview'),
                                onPressed: () {
                                  onActivity?.call();
                                  onOpenMultiview!();
                                },
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
                final side = Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (channel != null && isLive) RecPill(channel: channel),
                      _QualityBadge(controller: controller),
                      const SizedBox(width: 4),
                      _AudioChannelBadge(controller: controller),
                      const SizedBox(width: 8),
                      if (catchup != null)
                        Flexible(
                          child: _CatchupClock(
                              session: catchup, position: position),
                        )
                      else if (showSeek)
                        Flexible(
                          child: Text(
                            '${_formatDuration(position)} / ${_formatDuration(duration)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        )
                      else if (isLive)
                        Flexible(
                            child: _LiveRemainingLabel(channelId: channelId)),
                    ],
                  ),
                );
                if (!twoLines) return Row(children: [titleCell, buttons, side]);
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [titleCell, side]),
                  const SizedBox(height: 2),
                  buttons,
                ]);
              }),
            ],
          );
        },
      ),
    );
  }

  /// "Programme · Channel" at the catch-up playhead (the channel alone
  /// when the guide has no listing then).
  String _catchupTitle(
      BuildContext context, CatchupSession s, Duration position) {
    final on = CatchupSession.programmeAt(
        context.read<EpgService>().getPrograms(s.live.epgId),
        s.playhead(position));
    return on == null ? title : '${on.title} · $title';
  }

  /// The catch-up's programmes and its playhead, read at press time.
  ({List<EpgProgram> list, DateTime at}) _catchupPlace(
      BuildContext context, CatchupSession s) {
    final list = context.read<EpgService>().getPrograms(s.live.epgId);
    return (list: list, at: s.playhead(controller.value.position));
  }

  List<Widget> _catchupLeading(
          BuildContext context, PlaybackService playback, CatchupSession s) =>
      [
        IconButton(
          icon: const Icon(Icons.skip_previous, color: Colors.white),
          tooltip: tr('Previous programme'),
          onPressed: () {
            onActivity?.call();
            final place = _catchupPlace(context, s);
            final before = CatchupSession.programmeBefore(place.list, place.at);
            if (before != null) playback.playCatchup(s.live, before.start);
          },
        ),
        IconButton(
          icon: const Icon(Icons.restart_alt, color: Colors.white),
          tooltip: tr('Watch from the start'),
          onPressed: () {
            onActivity?.call();
            final place = _catchupPlace(context, s);
            final on = CatchupSession.programmeAt(place.list, place.at);
            if (on != null) playback.playCatchup(s.live, on.start);
          },
        ),
      ];

  List<Widget> _catchupTrailing(
          BuildContext context, PlaybackService playback, CatchupSession s) =>
      [
        IconButton(
          icon: const Icon(Icons.skip_next, color: Colors.white),
          tooltip: tr('Next programme'),
          onPressed: () {
            onActivity?.call();
            final place = _catchupPlace(context, s);
            final after = CatchupSession.programmeAfter(place.list, place.at);
            // No later programme known: that's now, so live.
            if (after == null) {
              playback.backToLive();
            } else {
              playback.playCatchup(s.live, after.start);
            }
          },
        ),
        _BackToLiveButton(onPressed: () {
          onActivity?.call();
          playback.backToLive();
        }),
      ];
}

/// Catch-up's gold Back to live: the way out of the past, always visible.
class _BackToLiveButton extends StatelessWidget {
  const _BackToLiveButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.amber,
            side: const BorderSide(color: Colors.amber, width: 1.4),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            visualDensity: VisualDensity.compact,
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.focused)
                    ? Colors.amber.withValues(alpha: 0.28)
                    : null),
          ),
          icon: const Icon(Icons.fast_forward, size: 18),
          label: Text(tr('LIVE'),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          onPressed: onPressed,
        ),
      );
}

/// Where catch-up is: the playhead's clock time and how far behind live.
class _CatchupClock extends StatelessWidget {
  const _CatchupClock({required this.session, required this.position});

  final CatchupSession session;
  final Duration position;

  @override
  Widget build(BuildContext context) {
    context.select<AppPreferences, bool>((p) => p.use24h);
    final at = session.playhead(position);
    final behind = DateTime.now().difference(at);
    final h = behind.inHours;
    final m = behind.inMinutes % 60;
    final lag = h > 0 ? '$h:${m.toString().padLeft(2, '0')}' : '$m min';
    return Text(
      '${TimeFormat.hm.format(at.toLocal())} · '
      '${tr('{time} behind live', {'time': lag})}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Colors.white70, fontSize: 12),
    );
  }
}

/// Opens the Recall picker — a bottom sheet listing the last few *live*
/// channels actually watched before this one (not a program guide, not
/// catchup/timeshift — a plain "go back to what I was just watching"
/// shortcut, the same concept as a cable remote's dedicated Recall/Last
/// button). Built entirely from [PlaybackService.recentlyPlayed], which
/// every [PlaybackService.play] call already records — no new tracking
/// needed. Filtered to live entries only ([Channel.isLiveId]) and deduped
/// by id, since the same underlying list also carries VOD/episode history
/// for the "Continue Watching" row.
Future<void> showRecallPicker(BuildContext context, Channel current) async {
  final playback = context.read<PlaybackService>();
  final seen = <String>{current.id};
  final history = <Channel>[];
  for (final c in playback.recentlyPlayed) {
    if (!c.isLive) continue;
    if (!seen.add(c.id)) continue;
    history.add(c);
    if (history.length >= 4) break;
  }

  await showModalBottomSheet<void>(
    context: context,
    // Transparent sheet chrome + transparent barrier — the actual visible
    // panel is the translucent scrim inside _RecallPickerSheet, matching
    // the Live TV channel list's own floating-over-the-video look
    // (Colors.black.withValues(alpha: 0.62), see tv_home_screen.dart)
    // rather than the default opaque modal sheet dimming everything
    // behind it.
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    builder: (sheetContext) => _RecallPickerSheet(channels: history),
  );
}

class _RecallPickerSheet extends StatelessWidget {
  const _RecallPickerSheet({required this.channels});

  final List<Channel> channels;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: RefinedFinish.decorate(
            context,
            BoxDecoration(
              color: Colors.black.withValues(alpha: 0.62),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            )),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                tr('Recall — recently watched'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ),
            if (channels.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  tr('No other live channels watched yet this session.'),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              )
            else
              ...channels.map((c) => TvMenuTile(
                    icon: Icons.tv,
                    title: c.name,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.read<PlaybackService>().play(c);
                    },
                  )),
          ],
        ),
      ),
    );
  }
}

/// Replaces the elapsed/duration text for a live channel with something
/// actually meaningful: how long is left in whatever's currently airing,
/// from EPG data (`EpgProgram.stop`) — not the video controller's own
/// duration, which is exactly the number that turned out not to be
/// trustworthy for live streams (see [PlayerControls.isLive]). Sits
/// inside the same [ValueListenableBuilder] that already rebuilds on
/// every video position tick, so "N min left" counts down at the same
/// cadence for free, no separate timer needed; `context.watch<EpgService>`
/// additionally keeps it correct across a real EPG data refresh.
class _LiveRemainingLabel extends StatelessWidget {
  const _LiveRemainingLabel({required this.channelId});

  final String channelId;

  @override
  Widget build(BuildContext context) {
    final epg = context.watch<EpgService>();
    final programme = epg.getCurrentProgram(channelId);
    if (programme == null) return const SizedBox.shrink();
    final remaining = programme.stop.difference(DateTime.now());
    if (remaining.isNegative) return const SizedBox.shrink();
    final minutes = remaining.inMinutes;
    return Text(
      minutes < 1
          ? tr('Ending now')
          : tr('{minutes} min left', {'minutes': minutes}),
      style: const TextStyle(color: Colors.white70, fontSize: 12),
    );
  }
}

/// Real decoded resolution/frame-rate tier, not the channel's (often
/// aspirational) name — see `video_quality.dart`'s own doc comment for
/// why this reads the actual selected video track instead. Polls rather
/// than reacting to an event: `video_player_hdr` doesn't publicly expose
/// its internal video-track-changed event stream, and polling every few
/// seconds is more than enough for a cosmetic badge — adaptive-bitrate
/// switches aren't frequent enough to need anything faster. Hidden
/// entirely below 1080p or whenever track info isn't available at all,
/// same "don't show something that can't be trusted" reasoning as
/// [_AudioTrackButton] hiding for a single-track stream.
class _QualityBadge extends StatefulWidget {
  const _QualityBadge({required this.controller});

  final VideoPlayerHdrController controller;

  @override
  State<_QualityBadge> createState() => _QualityBadgeState();
}

class _QualityBadgeState extends State<_QualityBadge> {
  String? _label;

  /// The same selected video track's own frame rate, shown as a second
  /// pill alongside the quality label — confirmed as data this widget
  /// already fetches every refresh (it's what decides FHD vs. plain HD),
  /// just never previously displayed on its own. Rounded for display
  /// only; the raw value still goes to [qualityLabelForTrack] unrounded.
  int? _frameRate;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void didUpdateWidget(_QualityBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _label = null;
      _frameRate = null;
      _refresh();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!widget.controller.isVideoTrackSupportAvailable()) return;
    try {
      final tracks = await widget.controller.getVideoTracks();
      VideoTrack? selected;
      for (final track in tracks) {
        if (track.isSelected) {
          selected = track;
          break;
        }
      }
      final height = selected?.height;
      if (!mounted || height == null) return;
      final label = qualityLabelForTrack(
          height: height,
          width: selected?.width,
          frameRate: selected?.frameRate);
      final frameRate = selected?.frameRate?.round();
      if (label != _label || frameRate != _frameRate) {
        setState(() {
          _label = label;
          _frameRate = frameRate;
        });
      }
    } catch (_) {
      // Not every stream/platform combination reports track info — leave
      // the badge hidden rather than show something stale/wrong.
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _label;
    if (label == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    // Same blended duo-tone glow as poster_card.dart's own focus glow —
    // one shadow, not two, for the same compositing-cost reason
    // documented there.
    final glowColor = Color.lerp(scheme.primary, scheme.secondary, 0.5)!;
    final frameRate = _frameRate;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InfoPill(label, glowColor: glowColor),
        if (frameRate != null) ...[
          const SizedBox(width: 4),
          _InfoPill('$frameRate FPS', glowColor: glowColor),
        ],
      ],
    );
  }
}

/// Shared small pill style for [_QualityBadge]/[_AudioChannelBadge] —
/// extracted once a second badge needed the exact same look rather than
/// duplicating the container/glow decoration a third time.
class _InfoPill extends StatelessWidget {
  const _InfoPill(this.text, {required this.glowColor});

  final String text;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: glowColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.6),
            blurRadius: 10,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
            color: glowColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5),
      ),
    );
  }
}

/// Real selected audio channel layout (stereo/5.1/7.1), not the stream's
/// own advertised label — same "decoded, not aspirational" reasoning as
/// [_QualityBadge], polling on the same cadence for the same reason (no
/// track-changed event to react to instead). Hidden for a plain mono/
/// stereo track (`channelCount <= 2`) — not worth a badge for the common
/// case — or whenever track info isn't available at all.
class _AudioChannelBadge extends StatefulWidget {
  const _AudioChannelBadge({required this.controller});

  final VideoPlayerHdrController controller;

  @override
  State<_AudioChannelBadge> createState() => _AudioChannelBadgeState();
}

class _AudioChannelBadgeState extends State<_AudioChannelBadge> {
  String? _label;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void didUpdateWidget(_AudioChannelBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _label = null;
      _refresh();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String? _channelLabel(int channels) {
    return switch (channels) {
      <= 2 => null,
      6 => '5.1',
      8 => '7.1',
      _ => '${channels}ch',
    };
  }

  Future<void> _refresh() async {
    if (!widget.controller.isAudioTrackSupportAvailable()) return;
    try {
      final tracks = await widget.controller.getAudioTracks();
      VideoAudioTrack? selected;
      for (final track in tracks) {
        if (track.isSelected) {
          selected = track;
          break;
        }
      }
      final channels = selected?.channelCount;
      if (!mounted || channels == null) return;
      final label = _channelLabel(channels);
      if (label != _label) setState(() => _label = label);
    } catch (_) {
      // Same "leave it hidden rather than show something stale/wrong"
      // reasoning as _QualityBadge.
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _label;
    if (label == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final glowColor = Color.lerp(scheme.primary, scheme.secondary, 0.5)!;
    return _InfoPill(label, glowColor: glowColor);
  }
}

/// Lets the user pick an audio track — some providers mislabel a stream's
/// language in its title (confirmed: a title that says "EN" but whose
/// actual audio track isn't English), and there's no way to tell or fix
/// that without a picker like this. `video_player_hdr`'s underlying
/// platform interface already exposes multi-track audio (it wraps
/// ExoPlayer on Android, which has always supported this internally) —
/// this is a UI on top of an existing capability, not new plumbing.
/// Hidden entirely for a stream with only one (or zero known) tracks —
/// showing a picker with a single, unchangeable option is just noise.
class _AudioTrackButton extends StatefulWidget {
  const _AudioTrackButton({super.key, required this.controller});

  final VideoPlayerHdrController controller;

  @override
  State<_AudioTrackButton> createState() => _AudioTrackButtonState();
}

class _AudioTrackButtonState extends State<_AudioTrackButton> {
  List<VideoAudioTrack>? _tracks;
  Timer? _retry;
  int _tries = 0;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }

  Future<void> _loadTracks() async {
    if (!widget.controller.isAudioTrackSupportAvailable()) return;
    try {
      final tracks = await widget.controller.getAudioTracks();
      if (mounted) setState(() => _tracks = tracks);
      // Once per stream, for Send log: what the player actually exposes
      // (a channel whose audio menu never appears, CBC Montreal 2026-10-26).
      if (_tries == 5 && mounted) {
        final channel = context.read<PlaybackService>().currentChannel;
        final url = channel?.url.toLowerCase() ?? '';
        debugPrint('AudioTracks: ${channel?.name} n=${tracks.length} '
            'm3u8=${url.contains('.m3u8')} ts=${url.contains('.ts')} '
            '${tracks.map((t) => '[${t.language}|${t.label}|${t.codec}|'
                '${t.channelCount}ch${t.isSelected ? '*' : ''}]').join(' ')}');
      }
    } catch (_) {
      // Not every stream/platform combination actually has track info
      // available even when the capability check passes — leave the
      // button hidden (_tracks stays null) rather than show a picker
      // that can't do anything.
    }
    // Loaded once only, the list could be read before the file's header
    // was (controls shown early): a multi-language movie then never got
    // the button. Re-read a few times (user report, 2026-10-18) — even
    // after 2+ tracks: right after a native live zap the old stream's
    // tracks are still the player's current ones.
    if (!mounted || ++_tries > 5) return;
    _retry = Timer(const Duration(seconds: 3), _loadTracks);
  }

  /// Placeholder codes broadcasters put on tracks: "MIS"/"MUL" as names
  /// told nobody anything (TSN2's four tracks, owner photo 2026-10-26).
  static const _noLanguage = {'und', 'mis', 'mul', 'zxx', 'qaa'};

  /// Track name, else its language, else "Audio n" — then codec and
  /// channel layout, which is what tells two same-language tracks apart.
  String _trackLabel(VideoAudioTrack track, int index) {
    final label = track.label?.trim() ?? '';
    final language = track.language?.toLowerCase() ?? '';
    final name = label.isNotEmpty
        ? label
        : language.isNotEmpty && !_noLanguage.contains(language)
            ? languageName(language)
            : '';
    return [
      name.isNotEmpty ? name : tr('Audio {n}', {'n': index + 1}),
      DataPoolCard.codecName(track.codec),
      DataPoolCard.channelsName(track.channelCount),
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
  }

  Future<void> _openPicker() async {
    // Re-fetch right before showing rather than trusting the initState
    // snapshot — reflects the actual current selection (isSelected) even
    // if something else changed it since this button first loaded.
    List<VideoAudioTrack> tracks;
    try {
      tracks = await widget.controller.getAudioTracks();
    } catch (_) {
      return;
    }
    if (!mounted || tracks.length < 2) return;
    setState(() => _tracks = tracks);

    final chosen = await showModalBottomSheet<VideoAudioTrack>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      // Scrolls past ~5 tracks (a 12-language movie ran off the screen,
      // owner 2026-10-18). Not lazy: autofocus needs the selected tile built.
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.8),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    tr('Audio Track'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                // TvMenuTile: the app's gold focus look (a plain ListTile
                // showed Material's pastel fill on TV, owner 2026-10-18).
                for (final (i, track) in tracks.indexed)
                  TvMenuTile(
                    autofocus: track.isSelected,
                    leading: Icon(
                      track.isSelected
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: track.isSelected ? Colors.amber : Colors.white54,
                    ),
                    title: _trackLabel(track, i),
                    onTap: () => Navigator.of(sheetContext).pop(track),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (chosen != null && mounted) {
      final storage = context.read<StorageService>();
      final playback = context.read<PlaybackService>();
      final channel = playback.currentChannel;
      final controller = widget.controller;
      final viewer = storage.getActiveViewerId();
      await controller.selectAudioTrack(chosen.id);
      if (channel != null &&
          storage.getActiveViewerId() == viewer &&
          playback.controller == controller &&
          playback.currentChannel == channel) {
        await AudioTrackPreferences.remember(storage, channel, chosen);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracks = _tracks;
    if (tracks == null || tracks.length < 2) return const SizedBox.shrink();
    return _LabeledIconButton(
      icon: Icons.multitrack_audio,
      label: tr('Audio track'),
      onPressed: _openPicker,
    );
  }
}

/// Subtitles built into the file (MKV/MP4 text tracks) — providers' movie
/// files often carry 20-30 languages (user report, 2026-10-18). Same shape
/// as [_AudioTrackButton]: hidden when the file has none. The text is drawn
/// by PlayerScreen's subtitle overlay (see SubtitleTracks).
class _SubtitleButton extends StatefulWidget {
  const _SubtitleButton({super.key, required this.controller});

  final VideoPlayerHdrController controller;

  @override
  State<_SubtitleButton> createState() => _SubtitleButtonState();
}

class _SubtitleButtonState extends State<_SubtitleButton> {
  List<SubtitleTrack> _tracks = const [];
  Timer? _retry;
  int _tries = 0;

  int get _playerId => SubtitleTracks.playerIdOf(widget.controller);

  Channel? get _channel => context.read<PlaybackService>().currentChannel;

  AddonService get _addons => AddonService(context.read<StorageService>());

  /// Movies/episodes can get subtitles from an add-on (Settings > Add-ons).
  bool get _canSearchOnline {
    final c = _channel;
    return c != null &&
        (c.subtitles.isNotEmpty ||
            (AddonService.supports(c) && _addons.anyEnabled));
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }

  // The track list only exists once the file's header is read, which can
  // be after this button is built — retry a few times.
  Future<void> _load() async {
    try {
      final tracks = await SubtitleTracks.list(_playerId);
      if (!mounted) return;
      setState(() => _tracks = tracks);
    } catch (_) {
      // No player yet: stay hidden.
    }
    if (!mounted || ++_tries > 5) return;
    _retry = Timer(const Duration(seconds: 3), _load);
  }

  /// The file's own track name when it has one ("French (France) Full"),
  /// else the language; "Forced" added unless the name already says it
  /// (it read "Français · French (France) Forced · Forced").
  String _trackLabel(SubtitleTrack t) {
    if (t.closedCaptions) {
      return tr('Closed captions (CC) — if the channel broadcasts them');
    }
    final label = t.label?.trim() ?? '';
    final name = languageName(t.language);
    final base = label.isNotEmpty
        ? label
        : name.isNotEmpty
            ? name
            : tr('Track {id}', {'id': t.track + 1});
    return t.forced && !base.toLowerCase().contains('forced')
        ? '$base · ${tr('Forced')}'
        : base;
  }

  Widget _option(BuildContext sheetContext,
      {required bool selected,
      required String title,
      String? subtitle,
      IconData? icon,
      required Object result}) {
    return TvMenuTile(
      autofocus: selected,
      leading: Icon(
        icon ?? (selected ? Icons.check_circle : Icons.circle_outlined),
        color: selected ? Colors.amber : Colors.white54,
      ),
      title: title,
      subtitle: subtitle,
      onTap: () => Navigator.of(sheetContext).pop(result),
    );
  }

  Future<T?> _sheet<T>(
      String title, List<Widget> Function(BuildContext) items) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.8),
          // Not a lazy ListView: autofocus on the selected language (often
          // far down a 30-track list) needs its tile built.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                ...items(sheetContext),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPicker() async {
    final id = _playerId;
    var tracks = const <SubtitleTrack>[];
    try {
      tracks = await SubtitleTracks.list(id);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _tracks = tracks);
    final online = _canSearchOnline;
    if (tracks.isEmpty && !online) return;
    final external = SubtitleTracks.externalFor.value == id
        ? SubtitleTracks.externalLabel[id]
        : null;
    final anySelected = external != null || tracks.any((t) => t.selected);
    final remembered = online
        ? context.read<StorageService>().getOnlineSubtitleLangs()
        : const <String>[];
    // 'off', 'online', or a SubtitleTrack.
    final chosen = await _sheet<Object>(
      tr('Subtitles'),
      (sheet) => [
        _option(sheet,
            selected: false,
            icon: Icons.translate,
            title: tr('Preferred subtitle language'),
            subtitle: _preferredName(),
            result: 'preferred'),
        _option(sheet, selected: !anySelected, title: tr('Off'), result: 'off'),
        if (external != null)
          _option(sheet,
              selected: true,
              title: external,
              subtitle: tr('Online'),
              result: 'keep'),
        for (final t in tracks)
          _option(sheet,
              selected: external == null && t.selected,
              title: _trackLabel(t),
              result: t),
        // Languages picked online before, one press each (owner,
        // 2026-10-18): the first match in that language for this title.
        if (online)
          for (final lang in remembered)
            if (external != _langLabel(lang))
              _option(sheet,
                  selected: false,
                  icon: Icons.cloud_outlined,
                  title: _langLabel(lang),
                  subtitle: tr('Online'),
                  result: (lang: lang)),
        if (online)
          _option(sheet,
              selected: false,
              icon: Icons.cloud_download_outlined,
              title: tr('Search online subtitles'),
              subtitle: tr('From your add-ons (Settings > Add-ons)'),
              result: 'online'),
        _option(sheet,
            selected: false,
            icon: Icons.format_size,
            title: tr('Subtitle size'),
            subtitle: tr(AppPreferences.subtitleSizeName(
                context.read<AppPreferences>().subtitleScale)),
            result: 'size'),
      ],
    );
    if (chosen == null || chosen == 'keep' || !mounted) return;
    if (chosen == 'size') return _pickSize();
    if (chosen == 'preferred') return _pickPreferred();
    if (chosen == 'online') return _searchOnline();
    if (chosen is ({String lang})) return _applyOnlineLang(chosen.lang);
    final track = chosen is SubtitleTrack ? chosen : null;
    // An episode: the choice carries on to the rest of the series; Off
    // forgets it (SubtitleTracks.rememberForSeries).
    unawaited(SubtitleTracks.rememberForSeries(
        context.read<StorageService>(), _channel,
        kind: track == null ? null : 'embedded',
        lang: track?.language,
        label: track?.label,
        forced: track?.forced ?? false));
    try {
      await SubtitleTracks.clearExternal(widget.controller);
      await SubtitleTracks.select(id, track);
    } catch (_) {
      // The stream changed underneath: nothing to select any more.
    }
  }

  String _preferredName() {
    final code = context.read<StorageService>().getPreferredSubtitleLanguage();
    return code == 'off' ? tr('Off') : languageName(code);
  }

  /// The viewer's preferred subtitle language (also Settings > Playback >
  /// Audio), set from the player: saved, and applied to this title now
  /// (its own remembered choice dropped). Not in the file = an add-on's.
  Future<void> _pickPreferred() async {
    final storage = context.read<StorageService>();
    final current = storage.getPreferredSubtitleLanguage();
    final picked = await _sheet<String>(
      tr('Preferred subtitle language'),
      (sheet) => [
        for (final code in ['off', ...trackLanguages])
          _option(sheet,
              selected: code == current,
              title: code == 'off' ? tr('Off') : languageName(code),
              result: code),
      ],
    );
    final channel = _channel;
    if (picked == null || channel == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final language = {'language': languageName(picked)};
    await storage.setPreferredSubtitleLanguage(picked);
    await SubtitleTracks.forgetForSeries(storage, channel);
    if (!mounted) return;
    if (picked != 'off') {
      messenger.showSnackBar(SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(tr('Looking for {language} subtitles…', language))));
    }
    final applied = await SubtitleTracks.applyForSeries(
        storage, channel, widget.controller,
        isCurrent: () =>
            mounted &&
            context.read<PlaybackService>().controller == widget.controller);
    if (!mounted) return;
    if (!applied && picked != 'off') {
      messenger.showSnackBar(SnackBar(
          content:
              Text(tr('No {language} subtitles for this title.', language))));
    }
  }

  /// Extra small / Small / Normal / Large / Extra large ([AppPreferences.subtitleScale]).
  Future<void> _pickSize() async {
    final prefs = context.read<AppPreferences>();
    final current = AppPreferences.subtitleSizeName(prefs.subtitleScale);
    final scale = await _sheet<double>(
      tr('Subtitle size'),
      (sheet) => [
        for (final (value, name) in AppPreferences.subtitleSizes)
          _option(sheet,
              selected: name == current, title: tr(name), result: value),
      ],
    );
    if (scale != null) prefs.setSubtitleScale(scale);
  }

  Future<void> _searchOnline() async {
    final channel = _channel;
    if (channel == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final results = _addons.search(channel);
    final chosen = await _sheet<OnlineSubtitle>(
      tr('Online subtitles'),
      (sheet) => [
        FutureBuilder<List<OnlineSubtitle>>(
          future: results,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final list = snap.data ?? const <OnlineSubtitle>[];
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(tr('No subtitles found for this title.'),
                    style: const TextStyle(color: Colors.white70)),
              );
            }
            return Column(
              children: [
                for (var i = 0; i < list.length; i++)
                  TvMenuTile(
                    autofocus: i == 0,
                    icon: Icons.subtitles_outlined,
                    title: languageName(list[i].lang).isEmpty
                        ? list[i].lang
                        : languageName(list[i].lang),
                    subtitle: [list[i].addonName, list[i].fileName ?? '']
                        .where((x) => x.isNotEmpty)
                        .join(' · '),
                    onTap: () => Navigator.of(sheet).pop(list[i]),
                  ),
              ],
            );
          },
        ),
      ],
    );
    if (chosen == null || !mounted) return;
    await _applyOnline(chosen, messenger);
  }

  static String _langLabel(String lang) =>
      languageName(lang).isEmpty ? lang : languageName(lang);

  Future<void> _applyOnline(
      OnlineSubtitle chosen, ScaffoldMessengerState messenger) async {
    final storage = context.read<StorageService>();
    try {
      final text = await AddonService.download(chosen);
      await SubtitleTracks.useExternal(widget.controller, text);
      SubtitleTracks.externalLabel[_playerId] = _langLabel(chosen.lang);
      await storage.addOnlineSubtitleLang(chosen.lang);
      await SubtitleTracks.rememberForSeries(storage, _channel,
          kind: 'online', lang: chosen.lang);
    } catch (_) {
      messenger.showSnackBar(SnackBar(
          content: Text(tr('Couldn\'t download that subtitle. Try another.'))));
    }
  }

  /// A remembered language: the first match for this title, else the full
  /// online list to pick from.
  Future<void> _applyOnlineLang(String lang) async {
    final channel = _channel;
    if (channel == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(tr('Looking for {language} subtitles…',
            {'language': _langLabel(lang)}))));
    final results = await _addons.search(channel);
    if (!mounted) return;
    final match = results.where((s) => s.lang == lang).firstOrNull;
    if (match == null) {
      messenger.showSnackBar(SnackBar(
          content: Text(tr('No {language} subtitles online for this title.',
              {'language': _langLabel(lang)}))));
      return _searchOnline();
    }
    await _applyOnline(match, messenger);
  }

  @override
  Widget build(BuildContext context) {
    if (_tracks.isEmpty && !_canSearchOnline) return const SizedBox.shrink();
    return _LabeledIconButton(
      icon: Icons.subtitles,
      label: tr('Subtitles'),
      onPressed: _openPicker,
    );
  }
}

/// Manual one-press failover to a linked channel on another playlist —
/// see [PlayerControls.linkedChannel]'s doc comment. Always shown (not
/// conditional on anything actually being wrong right now), same
/// "there whether you need it or not" shape as the skip/next-episode
/// buttons either side of it. The bare swap icon means nothing on its
/// own — there's no established icon convention for "cross-playlist
/// failover" the way there is for play/pause or skip — so this was the
/// first button to get [_LabeledIconButton]'s on-focus label treatment;
/// every other situational button in the secondary row has it now too.
class _LinkedChannelButton extends StatelessWidget {
  const _LinkedChannelButton({required this.linkedChannel});

  final Channel linkedChannel;

  @override
  Widget build(BuildContext context) {
    final playlistName = context
        .watch<PlaylistManager>()
        .playlistNameFor(linkedChannel.playlistId);
    return _LabeledIconButton(
      icon: Icons.swap_horiz,
      label: tr('Switch to {playlistName}: {name}',
          {'playlistName': playlistName, 'name': linkedChannel.name}),
      onPressed: () => context.read<PlaybackService>().play(linkedChannel),
    );
  }
}

/// An icon button that explains itself on focus — [IconButton]'s own
/// `tooltip` doesn't reach anyone driving by D-pad remote (no hover, no
/// long-press-for-tooltip gesture, so that text only ever reached a
/// screen reader). Originally built just for [_LinkedChannelButton];
/// reported directly that revealing `PlayerControls`'s secondary row at
/// all only solved "I didn't know this existed" and not "I don't know
/// what this icon does" for every *other* button in it — this is now
/// shared by all of them (Recall, Reload, audio track, linked-channel)
/// instead of leaving one explained and the rest bare.
class _LabeledIconButton extends StatefulWidget {
  const _LabeledIconButton(
      {required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_LabeledIconButton> createState() => _LabeledIconButtonState();
}

class _LabeledIconButtonState extends State<_LabeledIconButton> {
  // IconButton has no onFocusChange of its own to hook — an explicit
  // FocusNode passed to it, listened to directly, is the reliable way to
  // track its real D-pad focus state regardless of that (a second, outer
  // Focus wrapper risks not being the node the D-pad actually lands on,
  // since IconButton manages its own internally when none is given).
  final FocusNode _focusNode = FocusNode(debugLabel: 'labeled-icon-button');
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Stack, not a Column — a Column makes the label a real sibling of
    // the icon, growing (and visibly shifting) the whole row every time a
    // label appears, confirmed directly on real hardware the first time
    // this pattern was built. Clip.none plus Positioned below means only
    // the IconButton itself (the sole non-positioned child) sizes this
    // Stack — the label floats up over the video without the row's own
    // layout ever knowing it's there.
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        IconButton(
          focusNode: _focusNode,
          icon: Icon(widget.icon, color: Colors.white),
          tooltip: widget.label,
          onPressed: widget.onPressed,
        ),
        // A negative `bottom` (not just stacked above via normal flow) is
        // what actually lets this float free of the button's own
        // footprint — paired with Clip.none above, so it renders over the
        // video rather than being clipped at the button's edge.
        // Deliberately quiet (no border, lower opacity, small text) — a
        // "ghost" hint reads as unfocused decoration, not another solid
        // control competing with the real button underneath it.
        if (_focused)
          Positioned(
            bottom: 44,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                constraints: const BoxConstraints(maxWidth: 220),
                decoration: RefinedFinish.decorate(
                    context,
                    BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    )),
                child: Text(
                  widget.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A tap jumps 10 seconds; holding it down keeps seeking in that direction,
/// accelerating the longer it's held — same "hold to fast-forward" most
/// video players have. Handles both touch (hold gesture) and D-pad (a
/// held Select/Enter key) — Flutter has no built-in "key held for N ms"
/// primitive, so this tracks key down/up timing by hand, the same
/// technique used for the group-row long-press menu in TvHomeScreen.
/// The VOD seek bar. Touch/mouse drag it as before; on a remote, Up from
/// the buttons focuses it and Left/Right scrub a target marker — jumps grow
/// while the key is held (10 s → 30 s → 1 → 2 → 5 min) — then one seek
/// lands 700 ms after the last press (or at once on OK). One seek instead
/// of one per step: each seek re-buffers, and IPTV servers are slow to.
class _ScrubBar extends StatefulWidget {
  const _ScrubBar({
    required this.controller,
    required this.position,
    required this.duration,
    this.onActivity,
  });

  final VideoPlayerHdrController controller;
  final Duration position;
  final Duration duration;
  final VoidCallback? onActivity;

  @override
  State<_ScrubBar> createState() => _ScrubBarState();
}

class _ScrubBarState extends State<_ScrubBar> {
  final _focus = FocusNode(debugLabel: 'scrub-bar');
  Duration? _target;
  int _steps = 0;
  Timer? _commit;

  static const _commitDelay = Duration(milliseconds: 700);

  @override
  void dispose() {
    _commit?.cancel();
    _focus.dispose();
    super.dispose();
  }

  /// Seconds per step: the more steps in this scrub, the bigger the jump.
  static int stepSeconds(int steps) => steps < 3
      ? 10
      : steps < 6
          ? 30
          : steps < 10
              ? 60
              : steps < 15
                  ? 120
                  : 300;

  void _move(int sign) {
    widget.onActivity?.call();
    final from = _target ?? widget.position;
    final next = from + Duration(seconds: sign * stepSeconds(_steps++));
    setState(() => _target = next < Duration.zero
        ? Duration.zero
        : next > widget.duration
            ? widget.duration
            : next);
    _commit?.cancel();
    _commit = Timer(_commitDelay, _seek);
  }

  void _seek() {
    _commit?.cancel();
    final target = _target;
    if (target != null) widget.controller.seekTo(target);
    if (mounted) setState(() => _target = null);
    _steps = 0;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (_target != null &&
        event is KeyDownEvent &&
        (key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter)) {
      _seek();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focused = _focus.hasFocus;
    final shown = _target ?? widget.position;
    final max = widget.duration.inMilliseconds;
    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      onFocusChange: (has) {
        // Leaving mid-scrub still lands the seek the viewer picked.
        if (!has && _target != null) _seek();
        setState(() {});
      },
      child: Row(children: [
        Expanded(
          child: ExcludeFocus(
            // 24 px instead of Slider's 48: the bar was too tall.
            child: SizedBox(
              height: 24,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: focused ? 5 : 3,
                  activeTrackColor: focused ? scheme.primary : null,
                  thumbColor: focused ? Colors.white : null,
                  thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: focused ? 9 : 6),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: shown.inMilliseconds.clamp(0, max).toDouble(),
                  max: max.toDouble(),
                  onChanged: (v) => widget.controller
                      .seekTo(Duration(milliseconds: v.toInt())),
                ),
              ),
            ),
          ),
        ),
        if (_target != null)
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              '${_clock(shown)}  (${_target! >= widget.position ? '+' : '−'}'
              '${_clock((_target! - widget.position).abs())})',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
      ]),
    );
  }

  static String _clock(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }
}

class _SkipButton extends StatefulWidget {
  const _SkipButton({required this.icon, required this.onSeek});

  final IconData icon;

  /// Called once with a 10-second amount for a normal tap/click, or
  /// repeatedly with a growing amount for as long as it's held.
  final void Function(Duration amount) onSeek;

  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton> {
  Timer? _holdTimer;
  int _tick = 0;
  bool _heldPastTap = false;
  bool _focused = false;

  static const _tapAmount = Duration(seconds: 10);
  static const _holdInterval = Duration(milliseconds: 400);

  // Reported directly, and confirmed by exactly how it was reproduced —
  // "even if you'd stop hold, hit stop or hit -10, it would never stop
  // the ticks": pressing *any other button* moves D-pad focus away from
  // this one, so the KeyUpEvent this relied on to call _endHold() lands
  // on whatever's focused now instead — never here. Nothing ever told
  // this widget's own Timer.periodic to stop, so it kept firing forever,
  // independent of anything the user did afterward. `_holdTimer` isn't
  // tied to the widget's own lifecycle either — it survives a rebuild,
  // and only Flutter calling dispose() (this widget actually being torn
  // down) would stop it on its own.
  //
  // Two backstops, not just one, since the trigger for the stuck state
  // wasn't really "no way to detect key-up" (that part already worked
  // for a clean single press) — it was "no *other* signal ever stops an
  // in-progress hold once focus moves." onFocusChange below closes the
  // actual gap (losing focus always means losing control over whether
  // this is still being held, regardless of why); _maxHoldTicks is a
  // hard ceiling regardless of cause, so a hold can never run away
  // indefinitely even if some other, not-yet-seen path has the same gap.
  static const _maxHoldTicks = 50; // 50 * 400ms = 20s of continuous hold

  void _startHold() {
    _tick = 0;
    _heldPastTap = false;
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(_holdInterval, (timer) {
      _heldPastTap = true;
      _tick++;
      if (_tick >= _maxHoldTicks) {
        timer.cancel();
        _holdTimer = null;
      }
      // Accelerates the longer it's held: 10s, 10s, 10s, then 20s a tick,
      // then 30s a tick, and so on — not just a constant fast-seek speed.
      widget.onSeek(Duration(seconds: 10 * (1 + _tick ~/ 3)));
    });
  }

  void _endHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (!_heldPastTap) widget.onSeek(_tapAmount);
  }

  /// Same cleanup as [_endHold], minus the tap-fallback seek — losing
  /// focus mid-hold isn't a clean release to treat as "was actually just
  /// a tap," it's an interruption; the only thing that matters here is
  /// making sure nothing keeps running.
  void _stopHoldOnFocusLoss() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final isActivateKey = event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA;
    if (!isActivateKey) return KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      _startHold();
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) {
      _endHold();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Every palette now gets the same contour + gradient-sheen treatment
    // — see `TvHomeScreen._SelectableRow`'s doc comment for the full
    // story.
    return Focus(
      onKeyEvent: _handleKeyEvent,
      onFocusChange: (f) {
        setState(() => _focused = f);
        if (!f) _stopHoldOnFocusLoss();
      },
      child: GestureDetector(
        onTapDown: (_) => _startHold(),
        onTapUp: (_) => _endHold(),
        onTapCancel: _endHold,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: RefinedFinish.decorate(
              context,
              BoxDecoration(
                shape: BoxShape.circle,
                color: _focused ? null : Colors.transparent,
                gradient: _focused
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black,
                          Color.lerp(
                              Colors.black, scheme.primaryContainer, 0.4)!,
                          Colors.black,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      )
                    : null,
                border: _focused
                    ? Border.all(color: scheme.primary, width: 2)
                    : null,
                boxShadow: _focused
                    ? [
                        BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.45),
                            blurRadius: 12)
                      ]
                    : const [],
              ),
              focused: _focused),
          // `scheme.tertiary` — a dedicated icon/symbol-glyph accent,
          // separate from the border/gradient accent (`scheme.primary`)
          // — see `buildPaletteColorScheme`'s own doc comment for why
          // (Habs: white contour, blue icons).
          child: Icon(widget.icon,
              color: _focused ? scheme.tertiary : Colors.white, size: 28),
        ),
      ),
    );
  }
}
