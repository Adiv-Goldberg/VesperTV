import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player_hdr/video_player_hdr.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/catchup.dart';
import '../models/channel.dart';
import '../models/epg_program.dart';
import '../models/playlist_profile.dart';
import '../utils/constants.dart';
import '../widgets/native_video_hole.dart';
import 'playlist_manager.dart';
import 'm3u_parser.dart';
import 'real_4k_channels.dart';
import 'storage_service.dart';
import 'audio_track_preferences.dart';
import 'catchup_session.dart';
import 'archive_ready_watch.dart';
import 'device_memory_service.dart';
import 'display_match.dart';
import 'archive_service.dart';
import 'watch_tracker.dart';
import 'vod_buffering.dart';
import 'live_reconnect_log.dart';
import '../l10n/l10n.dart';

/// Owns the single, app-wide [VideoPlayerHdrController] for whatever channel
/// is currently playing.
///
/// Was a plain `VideoPlayerController` (the stock `video_player` package) —
/// switched after a long, evidence-backed diagnosis of a real bug: on
/// Android, going fullscreen showed solid black while the exact same
/// stream played fine in a smaller inline preview elsewhere in the app,
/// even though the decoder logs showed successful decoding the entire
/// time (confirmed via logcat on real Formuler and Firestick hardware). A
/// side-by-side comparison against a native player app on the same
/// hardware showed identical MediaCodec-level success in both — the
/// difference was specifically in how each *displays* the decoded frame,
/// not decoding itself. `video_player`'s Android implementation renders
/// through a GPU-texture path that has a known, documented weakness here;
/// `video_player_hdr` is a drop-in-API fork that can render through a
/// platform view instead, closer to how a native app's own `SurfaceView`
/// works. `EnableImpeller` (Flutter's newer renderer, which fixes this
/// properly) can't be turned on here — it crashes on startup on this
/// hardware's GPU driver (see AndroidManifest.xml) — so this is the
/// practical way to get the same effective fix without it.
///
/// Previously each screen (the inline pane, the fullscreen player) created
/// and disposed its own controller, so navigating back from fullscreen on a
/// phone killed playback entirely — there was nothing left to resume into.
/// Hoisting the controller up here means any number of presentation widgets
/// (the inline pane, the fullscreen screen, a mini-player bar) can all watch
/// the same live controller — switching between them is just a different
/// wrapper around the same video, never a restart.
class PlaybackService extends ChangeNotifier {
  /// Set by the app (main.dart): asked before a channel opens; false =
  /// don't play (a recording holds the playlist's only connection).
  static Future<bool> Function(Channel channel)? confirmOpen;

  /// Set by the app: a different URL to open [channel] from (the
  /// recorder's local tap while that channel records), or null.
  static Future<String?> Function(Channel channel)? openUrlFor;

  PlaybackService(this._storage, this._playlistManager) {
    _reconnectLog.start();
  }

  /// Send log lines for the native player's silent live reconnects.
  late final _reconnectLog = LiveReconnectLog(() {
    final c = controller;
    return currentChannel?.isLive == true ? c : null;
  });

  static const _recentlyPlayedCacheKey = 'recently_played';
  static const _maxRecentlyPlayed = 30;

  /// Main keeps the bare `recently_played` cache file name an upgrading
  /// install already has — every other viewer gets its own, so "Continue
  /// Watching" doesn't mix one viewer's history into another's. Same
  /// suffix convention as `StorageService`'s per-viewer prefs keys, just
  /// applied to a cache *file* name instead of a prefs key, since this
  /// list has always lived in the file cache, not SharedPreferences.
  String get _recentlyPlayedCacheKeyForViewer {
    final viewerId = _storage.getActiveViewerId();
    return viewerId == AppConstants.mainViewerId
        ? _recentlyPlayedCacheKey
        : '${_recentlyPlayedCacheKey}_vp_$viewerId';
  }

  final StorageService _storage;
  final PlaylistManager _playlistManager;

  Channel? currentChannel;

  /// Set while a past programme plays from a live channel's catch-up
  /// ([playCatchup]); [currentChannel] is then its transient `cu_` channel
  /// and [CatchupSession.live] the channel Back to now returns to.
  CatchupSession? catchup;
  CatchupSession? _pendingCatchup;

  /// The guide's programmes for a live channel (set in main.dart from
  /// EpgService): catch-up stops at the end of the programme it was
  /// started on unless Settings > Playback > Catch-up says keep playing.
  List<EpgProgram> Function(Channel live)? catchupGuide;

  /// Bumped by every catch-up / Back to now request: a late continuation
  /// or retry from an older one sees the change and does nothing.
  int _catchupGen = 0;

  /// Bumped by every [_playChannel] past its same-channel guard (and by
  /// [stop]). Two plays overlapping across their awaits (Back to now while
  /// a catch-up request opens, a fast zap) used to both create a player:
  /// the older one leaked with its provider connection still open. Now
  /// the older one gives up at its next await.
  int _playGen = 0;
  final _catchupErrors = <DateTime>[];

  /// Playlists whose Xtream panel only serves `.ts` timeshift links (the
  /// `.m3u8` form answered 404 — user report, 2026-10-27). Learned once per
  /// launch; every later request on that playlist asks for `.ts` at once.
  final _catchupTsOnly = <String>{};

  @visibleForTesting
  void debugLearnCatchupTsOnly(String playlistId) =>
      _catchupTsOnly.add(playlistId);

  /// The live channel behind what's playing — the catch-up's live channel
  /// while catch-up plays.
  Channel? get liveChannel => catchup?.live ?? currentChannel;

  /// When a live channel with catch-up was paused (pause = timeshift).
  DateTime? get livePausedAt => _livePausedAt;
  DateTime? _livePausedAt;

  /// Paused longer than this, Play resumes from the pause through catch-up;
  /// shorter, the live player's own buffer carries on from the pause.
  static const timeshiftAfter = CatchupSession.liveEdge;

  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  @visibleForTesting
  VideoPlayerHdrController Function(String url,
      {Future<ClosedCaptionFile>? closedCaptionFile,
      Map<String, String> httpHeaders}) createController = streamController;

  /// The live list the user last picked a channel from (TvHomeScreen's
  /// Live list / Timeline guide, Favourites included) — what the player's
  /// CH+/CH- step through. Plain field, no notify; PlayerScreen falls back
  /// to the channel's own group when the playing channel isn't in it.
  List<Channel>? zapList;
  VideoPlayerHdrController? controller;

  /// When the current channel was tuned (the Data pool's "Playing for"; a
  /// live stream's position doesn't advance). Kept across a server retry.
  DateTime? playingSince;

  /// True from the start of [play] until the new controller exists. The
  /// old player's release can take most of a second (4K decoders), and a
  /// pane built meanwhile — the guide mounts a fresh one per channel — saw
  /// no controller and drew its empty black state, then the spinner: the
  /// "black flash before the loading circle" (owner, 2026-10-20). With
  /// this the pane shows the spinner from the first frame.
  bool switching = false;
  Future<void>? initFuture;
  String? error;

  /// Set while a failed live stream is being retried against this
  /// playlist's backup servers (see [PlaylistProfile.backupServers]) —
  /// shown by `PlayerControls` in place of the dead-end playback error it
  /// would otherwise land on immediately. Null whenever no such retry is
  /// in progress, which is the overwhelmingly common case.
  String? reconnectStatus;

  /// True while `PlayerScreen` is actually mounted and showing this
  /// channel fullscreen — set/cleared by that screen's own
  /// `initState`/`dispose` via [setFullscreenActive]. `LiveResumeHint`
  /// reads this both to stop the global hold-Right gesture from firing
  /// again on top of an already-showing fullscreen view, and to hide its
  /// own reminder text while fullscreen is already showing.
  bool isFullscreenActive = false;

  /// A plain field assignment here wouldn't notify `LiveResumeHint`,
  /// which listens via [addListener] — confirmed on real hardware as the
  /// cause of its reminder text still showing the just-left channel's
  /// name for a moment right after entering fullscreen for a *different*
  /// one, since nothing had told it anything changed yet.
  void setFullscreenActive(bool value) {
    if (isFullscreenActive == value) return;
    isFullscreenActive = value;
    notifyListeners();
  }

  /// The live channel a previous session was last playing, surfaced by
  /// `LiveResumeHint` as a pill the user can act on — never auto-played.
  /// Cold launch used to start this playing silently in the background
  /// (`main.dart`'s old `_autoResumeLastChannel`), which was itself enough
  /// extra concurrent work (a decoder opening, an EPG fetch queued up) to
  /// make the whole first 10-20s of a cold start feel sluggish, on top of
  /// catalog loading that was already the slow part. Reported directly.
  /// Set once at launch (see `main.dart`'s `_autoResumeLastChannel`, now
  /// just a lookup) and cleared the moment *any* real [play] call happens
  /// — whether the user actually resumed this exact channel or picked a
  /// different one instead, the pending state has nothing left to offer
  /// once real playback has started.
  Channel? pendingResumeChannel;

  void setPendingResumeChannel(Channel? channel) {
    pendingResumeChannel = channel;
    notifyListeners();
  }

  Timer? _positionSaveTimer;

  /// Ordered episodes the currently playing channel came from (e.g. a
  /// whole series, season-by-season) — set by `SeriesDetailScreen` when an
  /// episode is opened, so playback can auto-advance near the end (see the
  /// position timer in [play]). Left in place across a switch rather than
  /// cleared, so advancing repeatedly through a season/series just keeps
  /// working — a channel that isn't actually in here (a movie, a live
  /// channel picked afterward) simply finds no match in [_nextInQueue] and
  /// this becomes a no-op until the next episode is opened.
  List<Channel>? _upNextQueue;

  /// Turns a queued episode with no URL yet (Archive: its stream is only
  /// looked up when it's about to play) into a playable one — see [play].
  /// Null for queues whose episodes already carry their URL.
  Future<Channel?> Function(Channel)? _upNextResolver;
  bool _resolvingQueued = false;

  void setUpNextQueue(List<Channel>? queue,
      {Future<Channel?> Function(Channel)? resolve}) {
    _upNextQueue = queue;
    _upNextResolver = resolve;
  }

  Channel? get _nextInQueue {
    final queue = _upNextQueue;
    final current = currentChannel;
    if (queue == null || current == null) return null;
    final index = queue.indexWhere((c) => c.id == current.id);
    if (index < 0 || index + 1 >= queue.length) return null;
    return queue[index + 1];
  }

  /// Public alias of [_nextInQueue] — lets the "Up Next" bubble in
  /// [PlayerScreen] show what's coming without duplicating the lookup.
  Channel? get nextUpChannel => _nextInQueue;

  Channel? get _previousInQueue {
    final queue = _upNextQueue;
    final current = currentChannel;
    if (queue == null || current == null) return null;
    final index = queue.indexWhere((c) => c.id == current.id);
    if (index <= 0) return null;
    return queue[index - 1];
  }

  /// Public alias of [_previousInQueue] — lets [PlayerControls]' explicit
  /// "Previous episode" button jump back without duplicating the lookup.
  /// Null (button hidden) for a movie/live channel — anything not actually
  /// in [_upNextQueue] — the same way [nextUpChannel] already behaves.
  Channel? get previousUpChannel => _previousInQueue;

  /// Set when the user dismisses the "Up Next" bubble — reset on every
  /// [play] call, so it only ever suppresses auto-advance for the episode
  /// it was dismissed on, not every episode after it.
  bool _autoAdvanceDismissed = false;

  void dismissAutoAdvance() {
    _autoAdvanceDismissed = true;
    notifyListeners();
  }

  List<Channel> _recentlyPlayed = [];

  /// Most-recently-played items, newest first — the raw material for a
  /// "Continue Watching" row. Filter by id prefix (`xt_vod_`/`xt_ep_`) and
  /// [StorageService.getLastPosition] to find what's actually resumable.
  List<Channel> get recentlyPlayed => _recentlyPlayed;

  bool get isPlayingSomething => currentChannel != null;

  Future<void> init() async {
    final raw = await _storage.readCacheFile(_recentlyPlayedCacheKeyForViewer);
    if (raw == null) {
      _recentlyPlayed = [];
      return;
    }
    try {
      // Older M3U history snapshots predate the explicit movie type too.
      // Only M3U profiles use group-title routing; a real Xtream live group
      // named "Movies 24/7" must remain live.
      final m3uIds = _playlistManager.profiles
          .where((p) => !p.isXtream)
          .map((p) => p.id)
          .toSet();
      _recentlyPlayed = (jsonDecode(raw) as List)
          .map((e) => Channel.fromJson(e as Map<String, dynamic>))
          .map((c) =>
              m3uIds.contains(c.playlistId) ? M3uParser.withCatalogType(c) : c)
          .toList();
    } catch (_) {
      _recentlyPlayed = [];
    }
  }

  /// Called by `ViewerProfileService.switchTo` after the active viewer has
  /// already changed — re-reads whichever viewer's recently-played list is
  /// now active (same logic as [init], just callable again later) and
  /// re-stamps `isFavorite` on every item against the newly-active
  /// viewer's own favorites, since these [Channel] objects don't live long
  /// enough to go through `PlaylistSession.restampFavorites`' own pass
  /// over its in-memory catalog lists.
  Future<void> reloadForViewer() async {
    await init();
    for (final c in _recentlyPlayed) {
      c.isFavorite = _playlistManager.isChannelFavorited(c.id);
    }
    notifyListeners();
  }

  /// The last [limit] distinct *live* channels watched, newest first — the
  /// TV layout's "History" popup. [recentlyPlayed] also carries movies/
  /// episodes (Continue Watching), so it's filtered here.
  List<Channel> recentLiveChannels({int limit = 10}) {
    final seen = <String>{};
    final result = <Channel>[];
    for (final c in _recentlyPlayed) {
      if (!c.isLive || !seen.add(c.id)) continue;
      result.add(c);
      if (result.length >= limit) break;
    }
    return result;
  }

  /// Records [channel] in [recentlyPlayed] without playing it — for the
  /// Windows player, which never goes through [play] (see
  /// `DesktopPlayerScreen`'s doc comment) but should still feed History.
  Future<void> recordWatched(Channel channel) => _recordRecentlyPlayed(channel);

  /// Remove the chosen Home history card; resume/watched state remains available.
  /// An episode card represents its series, so remove that series' history entries.
  Future<void> removeFromHistory(Channel channel) async {
    _recentlyPlayed.removeWhere((c) =>
        c.id == channel.id ||
        (channel.seriesId != null &&
            c.seriesId == channel.seriesId &&
            c.playlistId == channel.playlistId));
    await _storage.writeCacheFile(_recentlyPlayedCacheKeyForViewer,
        jsonEncode(_recentlyPlayed.map((c) => c.toJson()).toList()));
    notifyListeners();
  }

  /// Settings > General history clearing, for the active viewer. [live]
  /// true drops the live channels (the "History" popup); false drops the
  /// movies/episodes (Continue Watching) plus their saved positions.
  Future<void> clearRecentlyPlayed({required bool live}) async {
    _recentlyPlayed.removeWhere((c) => c.isLive == live);
    await _storage.writeCacheFile(
      _recentlyPlayedCacheKeyForViewer,
      jsonEncode(_recentlyPlayed.map((c) => c.toJson()).toList()),
    );
    if (!live) await _storage.clearPlaybackPositions();
    notifyListeners();
  }

  Future<void> _recordRecentlyPlayed(Channel channel) async {
    if (channel.transientPlayback) return;
    _recentlyPlayed.removeWhere((c) => c.id == channel.id);
    _recentlyPlayed.insert(0, channel);
    if (_recentlyPlayed.length > _maxRecentlyPlayed) {
      _recentlyPlayed = _recentlyPlayed.sublist(0, _maxRecentlyPlayed);
    }
    await _storage.writeCacheFile(
      _recentlyPlayedCacheKeyForViewer,
      jsonEncode(_recentlyPlayed.map((c) => c.toJson()).toList()),
    );
    notifyListeners();
  }

  /// Starts playing [channel]. No-ops if it's already the current channel
  /// (so re-opening the fullscreen view for the channel the mini-player is
  /// already showing doesn't restart it).
  /// Main player as a texture instead of a native (platform) view — the
  /// Settings > General "Compatibility video" switch, on by default for
  /// Android 7 and older (see AppPreferences.compatVideo). Read when a
  /// channel starts, so a change applies from the next channel.
  static bool textureVideo = false;

  static VideoViewType get _viewType =>
      textureVideo ? VideoViewType.textureView : VideoViewType.platformView;

  static final _nativeSurfaceControllers = Expando<bool>();

  /// The view type for [c], remembering whether it draws through the native
  /// video surface (beta): decided when its channel starts, like
  /// [textureVideo], so a settings change never flips a running player.
  static VideoViewType _viewTypeFor(VideoPlayerHdrController c) {
    if (NativeVideoSurface.active && !textureVideo) {
      _nativeSurfaceControllers[c] = true;
    }
    return _viewType;
  }

  /// [VideoPlayerPane] shows a [NativeVideoHole] instead of the platform
  /// view for this controller.
  static bool drawsNativeSurface(VideoPlayerHdrController c) =>
      _nativeSurfaceControllers[c] ?? false;

  /// Whether the current controller uses the restart-applied native beta.
  /// Consult the controller's original choice, not a newly changed setting.
  bool get usesNativeSurface {
    final current = controller;
    return current != null && drawsNativeSurface(current);
  }

  final _nativeSwitchReleases = <VoidCallback>{};

  Future<void> play(Channel channel) async {
    if (!usesNativeSurface ||
        !NativeVideoSurface.active ||
        textureVideo ||
        currentChannel?.id == channel.id) {
      return _playChannel(channel);
    }
    final release = NativeVideoSurface.retainForPlayerSwitch();
    _nativeSwitchReleases.add(release);
    void finish() {
      _nativeSwitchReleases.remove(release);
      release();
    }

    try {
      await _playChannel(channel);
      final initializing = initFuture;
      if (initializing == null) {
        finish();
      } else {
        unawaited(initializing.then((_) => finish(),
            onError: (Object _, StackTrace __) => finish()));
      }
    } catch (_) {
      finish();
      rethrow;
    }
  }

  void _cancelNativeSwitchHolds() {
    for (final release in _nativeSwitchReleases) {
      release();
    }
    _nativeSwitchReleases.clear();
  }

  Future<void> _playChannel(Channel channel) async {
    // A queued episode whose stream isn't known yet (Archive Next / auto-
    // advance): resolve it first. Guarded, so the position timer's repeat
    // calls near the end don't start a second lookup.
    if (channel.url.isEmpty) {
      final resolve = _upNextResolver;
      if (resolve == null || _resolvingQueued) return;
      _resolvingQueued = true;
      Channel? resolved;
      try {
        resolved = await resolve(channel);
      } catch (e) {
        debugPrint('PlaybackService: up-next lookup failed: $e');
      } finally {
        _resolvingQueued = false;
      }
      if (resolved == null || resolved.url.isEmpty) {
        error = tr('No playable stream for this title.');
        notifyListeners();
        return;
      }
      channel = resolved;
    }
    // Archive titles and recordings belong to no playlist (see
    // ArchiveService, RecordingService).
    if (!Channel.isArchiveId(channel.rawId) &&
        !Channel.isRecordingId(channel.rawId) &&
        !_playlistManager.isPlaylistEnabled(channel.playlistId)) {
      error = tr(
          'This playlist is disabled on this device — enable it in Settings > Playlist Manager to watch.');
      notifyListeners();
      return;
    }
    // A Media Hub source switch keeps the title ID (and its resume point)
    // but supplies a different file URL. Only the identical file is a no-op.
    if (currentChannel?.id == channel.id &&
        controller != null &&
        (!Channel.isArchiveId(channel.rawId) ||
            currentChannel?.url == channel.url)) {
      return;
    }

    final gen = ++_playGen;
    // A recording uses this playlist's only connection: ask first (the
    // app shows the Stop recording / Cancel popup, see main.dart).
    final confirm = confirmOpen;
    if (confirm != null && !await confirm(channel)) return;
    if (gen != _playGen) return;
    // The channel being recorded plays from the recorder's local tap, so
    // both share one provider connection.
    final openUrl = await openUrlFor?.call(channel) ?? channel.url;
    if (gen != _playGen) return;

    if (await _reuseNativeLive(channel, openUrl)) return;
    if (gen != _playGen) return;

    // Before the teardown: it reads currentChannel for the old title's
    // resume save, so only the flag changes here.
    switching = true;
    await _teardown();
    if (gen != _playGen) return;
    if (NativeVideoSurface.active && !textureVideo) {
      await NativeVideoSurface.prepareNewPlayer();
      if (gen != _playGen) return;
    }
    _livePausedAt = null;
    final pending = _pendingCatchup;
    _pendingCatchup = null;
    catchup =
        pending != null && pending.channel.id == channel.id ? pending : null;
    final session = catchup;
    currentChannel = channel;
    error = null;
    reconnectStatus = null;
    _autoAdvanceDismissed = false;
    // Real playback has started — whatever cold-launch pill this might
    // have been about has nothing left to offer, whether this is the same
    // channel or a different one the user picked instead.
    pendingResumeChannel = null;
    notifyListeners();
    unawaited(_recordRecentlyPlayed(channel));

    // Confirmed on real hardware as the cause of a live channel looking
    // "stuck paused": a live id can carry a *stale* saved position from
    // a completely unrelated past session (the periodic save below used
    // to write one unconditionally, live or not), and seeking a live
    // stream to an old position lands outside its actual sliding DVR
    // window — the player then just sits there buffering/frozen instead
    // of joining live. A live channel has no meaningful "resume point" at
    // all, so this is skipped entirely rather than trying to validate the
    // saved value.
    // rawId, not the composite `id` — Channel.isLiveId documents that it
    // expects the raw, unprefixed id. Confirmed as a real regression:
    // with `id` here this always read false for a real live channel,
    // silently reintroducing the exact "stuck paused" bug described
    // above (a live channel getting treated as if it had a saved VOD
    // resume position).
    final isLive = channel.isLive;
    final savedPositionMs = isLive || channel.transientPlayback
        ? 0
        : _storage.getLastPosition(channel.id);
    final newController = createController(
      openUrl,
      httpHeaders: channel.httpHeaders,
      closedCaptionFile: channel.subtitleUrl != null
          ? _loadCaptions(channel.subtitleUrl!)
          : null,
    );
    controller = newController;
    _watchRestartLoop(newController, channel);
    switching = false;
    playingSince = DateTime.now();

    initFuture = newController
        .initialize(viewType: _viewTypeFor(newController))
        .then((_) async {
      if (controller != newController) return;
      await VodBuffering.configure(newController, channel);
      if (controller != newController) return;
      if (savedPositionMs > 0) {
        var seekMs = savedPositionMs;
        // A Trakt/Simkl resume point saved as a fraction (length unknown
        // until now): the real time, then the flag goes.
        if (_storage.isResumeFraction(channel.id)) {
          seekMs = (savedPositionMs /
                  StorageService.resumeFractionScale *
                  newController.value.duration.inMilliseconds)
              .round();
          await _storage.clearResumeFraction(channel.id);
        }
        await newController.seekTo(Duration(milliseconds: seekMs));
      }
      // Surface first, then play. The video view (a platform view) is only
      // built once this controller reads as initialized; playing before
      // that meant the decoder started with no surface and got one
      // mid-stream, which some TV boxes' decoders answer with a restart:
      // one frame, black until the next keyframe, then the picture
      // (Formuler, Timeline guide, owner 2026-10-18).
      if (controller == newController) {
        notifyListeners();
        await SchedulerBinding.instance.endOfFrame;
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      // Switched channel meanwhile: this controller is already disposed.
      if (controller != newController) return;
      if (session != null) {
        await CatchupSession.markFinite(newController);
        if (session.startOffset > Duration.zero) {
          await newController.seekTo(session.startOffset);
        }
        if (controller != newController) return;
        _watchCatchupEnd(newController, session);
      }
      await newController.play();
      unawaited(AudioTrackPreferences.apply(_storage, channel, newController,
          isCurrent: () => controller == newController));
      // Fire TV/Android TV boxes otherwise sleep the screen mid-stream on
      // idle-input timeout, exactly like they would for any non-video app —
      // there was nothing here telling the OS playback is active.
      unawaited(WakelockPlus.enable());
      // Trakt/Simkl, for Media Hub titles (a no-op otherwise).
      if (!channel.transientPlayback) {
        unawaited(WatchTracker.instance.started(channel.id));
      }
      if (isLive) unawaited(_recordRealResolution(newController, channel));
      unawaited(DisplayMatch.start(
          _storage,
          newController,
          () =>
              controller == newController && currentChannel?.id == channel.id));
      // Catch-up: the live channel is what a restart resumes.
      await _storage.setLastChannelId(session?.live.id ?? channel.id);
      // Live streams report zero/unknown duration — that's fine, it just
      // means StorageService.getWatchedFraction has nothing to compute a
      // percentage from for those, which is the correct outcome (a live
      // channel doesn't have a "% watched").
      final duration = newController.value.duration;
      if (duration > Duration.zero) {
        await _storage.setLastDuration(channel.id, duration.inMilliseconds);
      }
      notifyListeners();
    }).catchError((e) async {
      if (session != null) {
        if (catchup == session) _onCatchupError(session, newController, e);
        return;
      }
      // A `.ts` that was really HLS: once more as HLS, through [play]
      // (clearing currentChannel lets it past its same-channel guard).
      if ((await learnHlsHost(channel.url, e) ||
              unlearnHlsUrl(channel.url, e)) &&
          currentChannel?.id == channel.id) {
        currentChannel = null;
        unawaited(play(channel));
        return;
      }
      // Any other link the player couldn't read: what did it really serve?
      final sniff = await _sniffUnreadable(channel, e);
      if (currentChannel?.id != channel.id) return;
      // A `.strm`-style reply (Jellyfin/Emby debrid libraries): the body
      // is just the real link — play that.
      if (sniff?.kind == 'link') {
        currentChannel = null;
        unawaited(play(channel.copyWith(url: sniff!.text)));
        return;
      }
      if (sniff?.kind == 'hls') {
        _hlsUrls.add(channel.url);
        currentChannel = null;
        unawaited(play(channel));
        return;
      }
      if (await _retryOnBackupServers(channel, e)) return;
      error = sniff == null ? e.toString() : '$e\n${sniff.tag}';
      notifyListeners();
    });

    _positionSaveTimer?.cancel();
    _positionSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final c = controller;
      final ch = currentChannel;
      // See the doc comment above `isLive` — never persist a "resume
      // point" for a live channel in the first place, not just skip
      // reading one back.
      if (c != null &&
          ch != null &&
          !ch.transientPlayback &&
          c.value.isInitialized &&
          !ch.isLive &&
          // A "being downloaded" clip: no resume point, and no auto-advance
          // (its last 30 s are all of it).
          !ArchiveReadyWatch.instance.isClip(ch.id, c.value.duration)) {
        _storage.setLastPosition(ch.id, c.value.position.inMilliseconds);
        final duration = c.value.duration;
        if (duration > Duration.zero) {
          _storage.setLastDuration(ch.id, duration.inMilliseconds);
          // Auto-advance a season/series near the end (Settings >
          // Playback > Up Next; a user missed every episode's last seconds,
          // 1.0.51).
          final remaining = duration - c.value.position;
          final mode = _storage.getUpNextMode();
          final due = switch (mode) {
            'off' => false,
            'end' => c.value.isCompleted ||
                remaining <= const Duration(milliseconds: 500),
            _ => remaining <= const Duration(seconds: 30),
          };
          if (due && !_autoAdvanceDismissed) {
            final next = _nextInQueue;
            if (next != null) unawaited(play(next));
          }
        }
      }
    });

    notifyListeners();
  }

  /// The live list's 4K tag ([Real4kChannels]): what [channel] really
  /// decodes at, read a few seconds in (the size is 0 until the first
  /// frame) and again later (adaptive streams settle on their top
  /// rendition).
  Future<void> _recordRealResolution(
      VideoPlayerHdrController c, Channel channel) async {
    for (final wait in const [Duration(seconds: 4), Duration(seconds: 12)]) {
      await Future<void>.delayed(wait);
      if (controller != c ||
          currentChannel?.id != channel.id ||
          !c.value.isInitialized) {
        return;
      }
      final size = c.value.size;
      Real4kChannels.record(
          channel.id, size.width.round(), size.height.round());
    }
  }

  /// Plays [live]'s catch-up from [at] (anywhere in its archive; older is
  /// clamped to the oldest the provider keeps). Within
  /// [CatchupSession.liveEdge] of now it plays the live channel instead.
  /// [toProgrammeEnd]: stop at the end of the programme on at [at] (when
  /// the setting asks for it); false for a paused live channel resuming
  /// through catch-up, which carries on like the channel.
  Future<void> playCatchup(Channel live, DateTime at,
      {bool retry = false, bool toProgrammeEnd = true}) async {
    final gen = ++_catchupGen;
    final now = clock();
    if (!live.hasCatchup || now.difference(at) < CatchupSession.liveEdge) {
      return _playLive(live);
    }
    final oldest = CatchupSession.oldest(live, now);
    final from = at.isBefore(oldest) ? oldest : at;
    final start = CatchupSession.floorToMinute(from);
    final span = CatchupSession.spanFrom(start, now);
    final url = CatchupSession.linkFor(live, _profileFor(live.playlistId),
        start: start,
        span: span,
        now: now,
        ext: _catchupTsOnly.contains(live.playlistId) ? 'ts' : 'm3u8');
    if (url == null) {
      debugPrint('Catchup: no link for ${live.name} (${live.catchupKind})');
      error = tr('Catch-up is not available for this channel.');
      notifyListeners();
      return;
    }
    if (gen != _catchupGen) return;
    final ch = CatchupSession.channelFor(live, start, url);
    if (!retry) _catchupErrors.clear();
    final guide = catchupGuide;
    final until =
        toProgrammeEnd && guide != null && !_storage.getCatchupKeepPlaying()
            ? CatchupSession.programmeAt(guide(live), from)?.stop
            : null;
    _pendingCatchup = CatchupSession(
        live: live,
        requestStart: start,
        channel: ch,
        startOffset: from.difference(start),
        until: until);
    // Asking again from the same minute (a retry) is still a real switch.
    if (currentChannel?.id == ch.id) currentChannel = null;
    final profile = _profileFor(live.playlistId);
    debugPrint('Catchup: ${live.name} from ${start.toIso8601String()} '
        '+${from.difference(start).inSeconds}s, ${span.inMinutes} min · '
        '${live.catchupKind?.name} ${CatchupSession.linkShape(url)} · '
        'server offset ${profile?.serverTimeOffsetMinutes ?? '-'} min · '
        'archive ${live.catchupDays} d');
    // Recall / Last channels return to the live channel.
    unawaited(_recordRecentlyPlayed(live));
    await play(ch);
  }

  /// Back to now: leaves catch-up for its live channel. The catch-up
  /// player is released first (play -> _teardown awaits its dispose), so a
  /// one-connection account never holds two streams.
  Future<void> backToLive() async {
    final s = catchup ?? _pendingCatchup;
    _catchupGen++;
    if (s == null) return;
    await _playLive(s.live);
  }

  Future<void> _playLive(Channel live) async {
    _pendingCatchup = null;
    debugPrint('Catchup: back to live ${live.name}');
    final c = controller;
    // Already on it (a short pause): just carry on.
    if (currentChannel?.id == live.id && c != null) {
      _livePausedAt = null;
      await c.play();
      notifyListeners();
      return;
    }
    await play(live);
  }

  /// Play/Pause from the remote or the bar. Pausing a live channel with
  /// catch-up remembers when; Play after [timeshiftAfter] resumes from
  /// that moment through catch-up (owner, 2026-10-27: pause = timeshift),
  /// sooner the live player's buffer simply carries on.
  Future<void> togglePlayPause() async {
    final c = controller;
    final ch = currentChannel;
    if (c == null) return;
    if (c.value.isPlaying) {
      if (ch != null && ch.hasCatchup) _livePausedAt = clock();
      await c.pause();
      notifyListeners();
      return;
    }
    final pausedAt = _livePausedAt;
    _livePausedAt = null;
    if (ch != null &&
        ch.hasCatchup &&
        pausedAt != null &&
        clock().difference(pausedAt) > timeshiftAfter) {
      await playCatchup(ch, pausedAt, toProgrammeEnd: false);
      return;
    }
    await c.play();
    notifyListeners();
  }

  PlaylistProfile? _profileFor(String playlistId) {
    for (final p in _playlistManager.profiles) {
      if (p.id == playlistId) return p;
    }
    return null;
  }

  /// A request's stream ended (the provider sends a span, or only what has
  /// aired): carry on from where it stopped, or go live once caught up.
  void _watchCatchupEnd(VideoPlayerHdrController c, CatchupSession s) {
    late final VoidCallback listener;
    listener = () {
      if (controller != c || catchup != s) {
        c.removeListener(listener);
        return;
      }
      final v = c.value;
      if (v.hasError) {
        c.removeListener(listener);
        _onCatchupError(s, c, v.errorDescription ?? 'playback error');
      } else if (!s.endReached &&
          v.isPlaying &&
          s.pastEnd(s.playhead(v.position))) {
        // The programme it was started on is over: stop there (no next
        // episode rolling in). Play carries on.
        s.endReached = true;
        debugPrint('Catchup: programme ended, paused');
        unawaited(c.pause());
        notifyListeners();
      } else if (v.isCompleted) {
        c.removeListener(listener);
        unawaited(_continueCatchup(s, v.position));
      }
    };
    c.addListener(listener);
  }

  Future<void> _continueCatchup(CatchupSession s, Duration position) async {
    final t = s.playhead(position);
    // The stream ran out at the programme's end: stay stopped there.
    if (!s.endReached && s.pastEnd(t)) {
      s.endReached = true;
      notifyListeners();
      return;
    }
    // An empty request means the provider has nothing newer: caught up.
    if (position - s.startOffset < CatchupSession.minUsefulPlay ||
        clock().difference(t) < CatchupSession.liveEdge) {
      _catchupGen++;
      return _playLive(s.live);
    }
    await playCatchup(s.live, t,
        toProgrammeEnd: s.until != null && !s.endReached);
  }

  /// A catch-up error the native player didn't recover in place. A link the
  /// provider doesn't have (404/410/400) shows a plain message; anything
  /// else asks again from the playhead, at most 3 times a minute.
  void _onCatchupError(CatchupSession s, VideoPlayerHdrController c, Object e) {
    final raw = e.toString();
    final status = httpStatusFromPlaybackError(raw);
    final position = c.value.isInitialized ? c.value.position : Duration.zero;
    debugPrint('Catchup: error at ${position.inSeconds}s '
        '(HTTP ${status ?? '-'}): ${raw.split('\n').first}');
    // MANIFEST_MALFORMED: the panel answered the `.m3u8` link with the video
    // itself or an error page, not a playlist (Shield user, Reddit
    // 2026-10-28: raw error after three retries).
    final notPlaylist = raw.contains('ERROR_CODE_PARSING_MANIFEST_MALFORMED');
    if (status == 400 || status == 404 || status == 410 || notPlaylist) {
      // Some panels route only `.ts` timeshift links: ask once more that way
      // (dev-notes/catchup-plan.md), and keep using it on this playlist.
      final live = s.live;
      if (live.catchupKind == CatchupKind.xc &&
          !_catchupTsOnly.contains(live.playlistId) &&
          Uri.tryParse(s.channel.url)?.path.endsWith('.m3u8') == true) {
        _catchupTsOnly.add(live.playlistId);
        debugPrint('Catchup: .m3u8 refused '
            '(${notPlaylist ? 'not a playlist' : 'HTTP $status'}), '
            'retrying as .ts');
        unawaited(playCatchup(live, s.playhead(s.startOffset),
            retry: true, toProgrammeEnd: s.until != null));
        return;
      }
      if (notPlaylist) {
        error = raw;
        notifyListeners();
        return;
      }
      error = tr('This programme is not available in catch-up.');
      notifyListeners();
      return;
    }
    final now = clock();
    _catchupErrors
        .removeWhere((t) => now.difference(t) > const Duration(seconds: 60));
    if (_catchupErrors.length >= 3) {
      error = raw;
      notifyListeners();
      return;
    }
    _catchupErrors.add(now);
    final at = s.playhead(position < s.startOffset ? s.startOffset : position);
    unawaited(playCatchup(s.live, at,
        retry: true, toProgrammeEnd: s.until != null && !s.endReached));
  }

  /// True while a manual [reloadCurrentChannel] is in flight — guards
  /// against mashing the button mid-reload starting a second overlapping
  /// swap.
  bool _reloadingCurrentChannel = false;

  static const _audioChannel = MethodChannel('vespertv/audio');
  static const _videoChannel = MethodChannel('vespertv/video');

  /// Tells the vendored player whether new main players' video surface is a
  /// media overlay ([AppPreferences.videoMediaOverlay]); from the next channel.
  static Future<void> setVideoMediaOverlay(bool enabled) async {
    if (!Platform.isAndroid) return;
    try {
      await _videoChannel
          .invokeMethod<void>('setMediaOverlay', {'enabled': enabled});
    } catch (e) {
      debugPrint('PlaybackService: video layering not set: $e');
    }
  }

  /// Tells the vendored player whether new main players pass Dolby audio
  /// through over HDMI ([AppPreferences.audioPassthrough]). Read when a
  /// player is created, so it applies from the next channel.
  static Future<void> setAudioPassthrough(bool enabled) async {
    if (!Platform.isAndroid) return;
    try {
      await _audioChannel
          .invokeMethod<void>('setPassthrough', {'enabled': enabled});
    } catch (e) {
      debugPrint('PlaybackService: audio passthrough not set: $e');
    }
  }

  /// Channel id → when [_watchRestartLoop] last reloaded it.
  final Map<String, DateTime> _restartLoopReloads = {};
  final _restartLoopListeners = Expando<VoidCallback>();
  int _nativeZapGeneration = 0;

  Future<bool> _reuseNativeLive(Channel channel, String url) async {
    final c = controller;
    final previous = currentChannel;
    if (!NativeVideoSurface.active ||
        textureVideo ||
        !usesNativeSurface ||
        c == null ||
        !c.value.isInitialized ||
        c.value.hasError ||
        previous == null ||
        !previous.isLive ||
        !channel.isLive ||
        previous.subtitleUrl != null ||
        channel.subtitleUrl != null) {
      return false;
    }
    final generation = ++_nativeZapGeneration;
    currentChannel = channel;
    error = null;
    reconnectStatus = null;
    notifyListeners();
    try {
      // The native response waits for READY; it never creates a new player.
      // ignore: invalid_use_of_visible_for_testing_member
      final response = await NativeVideoSurface.replaceLive(c.textureId, url,
          hls: _streamUsesHls(url));
      if (generation != _nativeZapGeneration ||
          controller != c ||
          currentChannel?.id != channel.id) {
        return true;
      }
      if (response?['accepted'] != true) {
        currentChannel = previous;
        return false;
      }
      final width = (response?['width'] as num?)?.toDouble() ?? 0;
      final height = (response?['height'] as num?)?.toDouble() ?? 0;
      c.value = c.value.copyWith(
          position: Duration.zero,
          duration: Duration.zero,
          buffered: [],
          size: width > 0 && height > 0 ? Size(width, height) : c.value.size,
          isCompleted: false,
          errorDescription: null);
      pendingResumeChannel = null;
      playingSince = DateTime.now();
      _autoAdvanceDismissed = false;
      _watchRestartLoop(c, channel);
      unawaited(_recordRecentlyPlayed(channel));
      unawaited(_recordRealResolution(c, channel));
      unawaited(DisplayMatch.start(_storage, c,
          () => controller == c && currentChannel?.id == channel.id));
      debugPrint('NativeSurface: reused live player for channel zap');
      unawaited(NativeVideoSurface.logDiagnostics());
      notifyListeners();
      return true;
    } catch (e) {
      if (generation != _nativeZapGeneration ||
          controller != c ||
          currentChannel?.id != channel.id) {
        return true;
      }
      // Retry with the established creation/format-learning/backup path.
      debugPrint(
          'NativeSurface: live reuse failed; recreating player (${e.runtimeType})');
      currentChannel = previous;
      return false;
    }
  }

  /// The main player tags its error `[RESTART_LOOP n in 60 s: reasons]`
  /// when it restarted in place more than 6 times in a minute (vendored
  /// `ExoPlayerEventListener.restartLooping`): the preview flashed until
  /// the viewer changed channel or pressed Reload (Discord video,
  /// 2026-10-22). Those restarts happen natively and never reach the app
  /// log, so this line is the only trace Send log gets. A live channel is
  /// reloaded from scratch once — what cured it by hand — after the
  /// backup-server pause, so the provider has dropped the stopped player's
  /// connection first (see [reloadCurrentChannel] on why an instant
  /// automatic reload failed). A second loop within 2 minutes, or a VOD
  /// title, shows the error instead.
  void _watchRestartLoop(VideoPlayerHdrController c, Channel channel) {
    final previous = _restartLoopListeners[c];
    if (previous != null) c.removeListener(previous);
    late final VoidCallback listener;
    listener = () {
      final raw = c.value.errorDescription;
      if (raw == null || !raw.contains('[RESTART_LOOP')) return;
      c.removeListener(listener);
      if (controller != c || currentChannel?.id != channel.id) return;
      final live = channel.isLive;
      debugPrint('PlaybackService: ${live ? 'live' : 'vod'} $raw');
      final now = DateTime.now();
      final last = _restartLoopReloads[channel.id];
      if (!live ||
          (last != null && now.difference(last) < const Duration(minutes: 2))) {
        error = raw;
        notifyListeners();
        return;
      }
      _restartLoopReloads[channel.id] = now;
      reconnectStatus = tr('Reconnecting...');
      notifyListeners();
      Future<void>.delayed(_backupServerDelay, () {
        if (controller == c && currentChannel?.id == channel.id) {
          unawaited(reloadCurrentChannel());
        }
      });
    };
    c.addListener(listener);
    _restartLoopListeners[c] = listener;
  }

  /// Manually relaunches the current live channel against the exact same
  /// URL — the "Reload" button in [PlayerControls], for a channel that's
  /// silently stalled (frozen frame, no spinner, no error — see
  /// `_checkStall`'s removal from this file in git history for why that
  /// can't be detected and fixed automatically). A fresh connection is a
  /// new "initial open" as far as a reverse-proxying relay is concerned,
  /// which is what actually recovers a stream stuck on a dead connection
  /// the relay never retries mid-session on its own.
  ///
  /// Deliberately manual rather than automatic: an automatic watchdog
  /// tried this and made things worse — relaunching within seconds of a
  /// detected stall raced the relay's own per-user connection limit (the
  /// dead connection wasn't reaped on the relay's side yet, so the new one
  /// got rejected outright). A human noticing and pressing a button
  /// naturally takes longer than that race window, which is the entire
  /// reason this is safe as a manual action when the automatic version
  /// wasn't.
  Future<void> reloadCurrentChannel() async {
    final channel = currentChannel;
    if (channel == null ||
        controller == null ||
        !channel.isLive ||
        _reloadingCurrentChannel) {
      return;
    }
    _reloadingCurrentChannel = true;
    reconnectStatus = tr('Reconnecting...');
    error = null;
    notifyListeners();

    final newController = streamController(
        await openUrlFor?.call(channel) ?? channel.url,
        httpHeaders: channel.httpHeaders);
    try {
      final future =
          newController.initialize(viewType: _viewTypeFor(newController));
      initFuture = future;
      await future;
      if (currentChannel?.id != channel.id) {
        unawaited(newController.dispose());
        return;
      }
      // Same "build the replacement fully before touching the old one"
      // technique as [_retryOnBackupServers] — disposing the dead
      // controller before the new one is proven just guarantees a black
      // screen if this attempt fails too.
      final previous = controller;
      controller = newController;
      _watchRestartLoop(newController, channel);
      await newController.play();
      unawaited(AudioTrackPreferences.apply(_storage, channel, newController,
          isCurrent: () => controller == newController));
      unawaited(previous?.dispose());
      reconnectStatus = null;
      error = null;
      notifyListeners();
    } catch (e) {
      unawaited(newController.dispose());
      reconnectStatus = null;
      error = e.toString();
      notifyListeners();
    } finally {
      _reloadingCurrentChannel = false;
    }
  }

  /// Same spacing as `PlaylistSession`'s catalog-side fallback, for the
  /// same reason — don't fire every one of a provider's hostnames at once.
  static const _backupServerDelay = Duration(seconds: 3);

  /// A live stream that failed to open gets retried against this
  /// playlist's configured backup servers before the viewer is shown a
  /// dead end. Returns true if one of them took over, in which case the
  /// caller leaves [error] alone.
  ///
  /// Deliberately narrow about when it even tries:
  /// * live only — a VOD/episode URL is a specific file on a specific
  ///   server, not a channel every mirror of an account carries.
  /// * connection-shaped failures only — see [isDecoderPlaybackError]. No
  ///   number of alternate hostnames makes a decoder that can't handle
  ///   4K HDR HEVC suddenly handle it, and cycling servers for half a
  ///   minute before admitting that is strictly worse than saying so.
  Future<bool> _retryOnBackupServers(Channel channel, Object failure) async {
    if (!channel.isLive) return false;
    if (isDecoderPlaybackError(failure.toString())) return false;

    PlaylistProfile? profile;
    for (final p in _playlistManager.profiles) {
      if (p.id == channel.playlistId) {
        profile = p;
        break;
      }
    }
    if (profile == null || !profile.isXtream) return false;

    final currentOrigin = _originOf(channel.url);
    final candidates = profile.serverCandidates
        .where((s) => _originOf(s) != currentOrigin)
        .toList();
    if (candidates.isEmpty) return false;

    for (var i = 0; i < candidates.length; i++) {
      // Still the current channel? A viewer who changed channel (or
      // backed out entirely) while this was retrying has already said
      // what they want, and hijacking that with a late reconnect would
      // be worse than the failure being retried. [reconnectStatus] is
      // deliberately left alone on these bail-outs — whoever took over
      // (`play`/`stop`) has already cleared it, and clearing it here
      // could stomp a status that now belongs to *their* attempt.
      if (currentChannel?.id != channel.id) return false;

      final server = candidates[i];
      reconnectStatus = tr(
          'Trying to reconnect on backup servers ({p}/{candidates})...',
          {'p': i + 1, 'candidates': candidates.length});
      error = null;
      notifyListeners();
      await Future<void>.delayed(_backupServerDelay);
      if (currentChannel?.id != channel.id) return false;

      final retryUrl = _swapOrigin(channel.url, server);
      final retryController =
          streamController(retryUrl, httpHeaders: channel.httpHeaders);
      try {
        final future =
            retryController.initialize(viewType: _viewTypeFor(retryController));
        initFuture = future;
        await future;
        await VodBuffering.configure(retryController, channel);
        // Initialising took real time, and the viewer may have moved on
        // during it — handing them a channel they've already left would
        // be worse than the failure this is recovering from. Dispose the
        // one nobody asked for rather than installing it.
        if (currentChannel?.id != channel.id) {
          unawaited(retryController.dispose());
          return false;
        }
        // Only now is the old one safe to drop — disposing before the
        // replacement is proven just guarantees a black screen if this
        // candidate turns out to be down too.
        final previous = controller;
        controller = retryController;
        _watchRestartLoop(retryController, channel);
        await retryController.play();
        unawaited(AudioTrackPreferences.apply(
            _storage, channel, retryController,
            isCurrent: () => controller == retryController));
        unawaited(previous?.dispose());
        reconnectStatus = null;
        error = null;
        unawaited(_playlistManager.rememberWorkingServer(profile.id, server));
        notifyListeners();
        return true;
      } catch (_) {
        unawaited(retryController.dispose());
      }
    }

    reconnectStatus = null;
    notifyListeners();
    return false;
  }

  /// The `scheme://host:port` of a URL, with nothing after it — what has
  /// to change to point the same stream at a different server.
  static String _originOf(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    return uri.hasPort
        ? '${uri.scheme}://${uri.host}:${uri.port}'
        : '${uri.scheme}://${uri.host}';
  }

  /// Rebuilds a stream URL against [server], keeping the whole path
  /// (`/live/user/pass/12345.ts`) as-is — a backup server for the same
  /// account serves the same stream ids under the same credentials, so
  /// only the origin ever differs.
  static String _swapOrigin(String url, String server) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    var base = server.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    final query = uri.hasQuery ? '?${uri.query}' : '';
    return '$base${uri.path}$query';
  }

  /// Same-channel scheduled recording: release the provider before its alarm,
  /// then rejoin through openUrlFor's local recording tap. A later user action
  /// or viewer/background change must win over this delayed continuation.
  Future<void> handOverScheduledRecording(
      Channel channel, Future<void> Function() waitForRecorder,
      {required bool Function() canResume}) async {
    if (currentChannel?.id != channel.id ||
        !channel.isLive ||
        catchup != null) {
      return;
    }
    final generation = _playGen + 1; // stop() owns exactly one increment.
    await stop();
    if (generation != _playGen) return;
    await waitForRecorder();
    if (generation != _playGen || currentChannel != null || !canResume()) {
      return;
    }
    await play(channel);
  }

  Future<void> stop() async {
    _nativeZapGeneration++;
    _playGen++;
    _catchupGen++;
    catchup = null;
    _pendingCatchup = null;
    _cancelNativeSwitchHolds();
    await _teardown();
    // Nothing plays any more: the TV goes back to its own mode. A channel
    // change doesn't come here, so zapping keeps a matched mode.
    unawaited(DisplayMatch.reset());
    currentChannel = null;
    reconnectStatus = null;
    // Otherwise `LiveResumeHint` reads "currentChannel is null" as "show
    // the cold-launch pending-resume pill" unconditionally — reported
    // directly as the pill reappearing inside Multiview (which calls stop()
    // on entry specifically to free the main tab's decode session, but
    // never touches this field since it never calls play() either): a
    // pending channel set once at cold launch and never consumed by a real
    // play() call would otherwise keep surfacing long after it's stale,
    // anywhere else in the app that also calls stop().
    pendingResumeChannel = null;
    notifyListeners();
  }

  /// Once per link: when the player couldn't read [channel]'s stream at
  /// all (ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED), what the link really
  /// served — an HLS playlist (retried as HLS), or a source's error reply
  /// instead of the file (a debrid service's plan limit, an expired
  /// account… — Media Hub TV show, user photo 2026-10-21). Logged without
  /// the link, for Send log.
  Future<StreamSniff?> _sniffUnreadable(Channel channel, Object error) async {
    final raw = error.toString();
    // MANIFEST_MALFORMED: opened as HLS, but the reply wasn't a playlist —
    // usually the provider's own error page (Romanian channel, Discord
    // photo 2026-10-22: "Input does not start with the #EXTM3U header").
    if (!(raw.contains('ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED') ||
            raw.contains('ERROR_CODE_PARSING_MANIFEST_MALFORMED')) ||
        channel.url.startsWith('/') ||
        !_sniffedUrls.add(channel.url)) {
      return null;
    }
    final sniff = await sniffStream(channel.url);
    final what = channel.isLive
        ? 'live'
        : channel.playlistId == ArchiveService.playlistId
            ? 'media hub'
            : 'vod';
    final path = Uri.tryParse(channel.url)?.path ?? '';
    final dot = path.lastIndexOf('.');
    final ext = dot > path.lastIndexOf('/') ? path.substring(dot) : 'none';
    debugPrint('PlaybackService: unreadable $what stream (extension $ext): '
        'served ${sniff?.tag ?? 'nothing (request failed)'}');
    return sniff;
  }

  Future<ClosedCaptionFile> _loadCaptions(String url) async {
    final response = await http.get(Uri.parse(url));
    final content = response.body;
    if (url.toLowerCase().endsWith('.vtt')) {
      return WebVTTCaptionFile(content);
    }
    return SubRipCaptionFile(content);
  }

  Future<void> _teardown() async {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = null;
    // A final exact-position save before disposing — the periodic timer
    // above only runs every 5 seconds, so without this, stopping shortly
    // after the last tick could leave Continue Watching up to 5 seconds
    // stale instead of reflecting exactly where playback actually left
    // off. Same isLive guard as the periodic save: never persist a
    // "resume point" for a live channel in the first place.
    final ch = currentChannel;
    final old = controller;
    if (ch != null &&
        !ch.transientPlayback &&
        old != null &&
        old.value.isInitialized &&
        !ch.isLive &&
        // A Media Hub source's "being downloaded" clip: no resume point
        // and no Trakt/Simkl "watched" for it.
        !ArchiveReadyWatch.instance.ended(ch.id, old.value.duration)) {
      await _storage.setLastPosition(ch.id, old.value.position.inMilliseconds);
      final duration = old.value.duration;
      if (duration > Duration.zero) {
        await _storage.setLastDuration(ch.id, duration.inMilliseconds);
        // Watched / paused at, for Trakt/Simkl (Media Hub titles only).
        unawaited(
            WatchTracker.instance.stopped(ch.id, old.value.position, duration));
      }
    }
    controller = null;
    playingSince = null;
    initFuture = null;
    unawaited(WakelockPlus.disable());
    await old?.dispose();
  }

  @override
  void dispose() {
    _reconnectLog.dispose();
    _nativeZapGeneration++;
    _cancelNativeSwitchHolds();
    _teardown();
    super.dispose();
  }
}

/// True for the one failure class that's about this device rather than
/// the stream's source: a `MediaCodecVideoRenderer` giving up on a format
/// (in practice 4K HDR HEVC 10-bit on a box whose decoder claims support
/// it doesn't actually have). Shared deliberately rather than pattern-
/// matched separately in each place that cares — `PlayerControls` uses it
/// to explain the limitation, `PlaybackService` uses it to *not* waste
/// the viewer's time cycling backup servers over something no server
/// change can fix, and those two must agree on what counts.
/// The HTTP status the stream's server answered with, when the native
/// player put one in its error (`... [HTTP 404 Not Found]`, appended by
/// `ExoPlayerEventListener.describeCause` in the vendored plugin) — the
/// usual reason a stream won't start is the provider, not the app.
/// Null for anything else (decoder, network, unknown).
int? httpStatusFromPlaybackError(String raw) {
  final match = RegExp(r'\[HTTP (\d{3})').firstMatch(raw);
  return match == null ? null : int.parse(match.group(1)!);
}

bool isDecoderPlaybackError(String raw) {
  final lower = raw.toLowerCase();
  return lower.contains('mediacodecvideorenderer') ||
      lower.contains('[unsupported_video:') ||
      (lower.contains('hevc') && lower.contains('10bit'));
}

/// Hosts whose live `.ts` URLs answer with an HLS playlist instead of a TS
/// stream (a 302 to `….m3u8`: Strong8K behind live.flixnest.app, user
/// photo 2026-10-20). ExoPlayer picks its reader from the URL, so it read
/// the playlist text as video: ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED
/// ("None of the available extractors…"). TiviMate goes by the response.
/// Learned per host on the first such failure, for the app session.
final Set<String> _hlsHosts = {};

/// Live `.ts` links on an [_hlsHosts] host that were NOT a playlist when
/// opened as HLS ([unlearnHlsUrl]): opened the normal way again.
final Set<String> _notHlsUrls = {};

/// Links of any shape found to serve an HLS playlist ([sniffStream]),
/// opened as HLS for the app session.
final Set<String> _hlsUrls = {};

/// Links already sniffed after a read failure — one look each.
final Set<String> _sniffedUrls = {};

/// What a stream link really served, from its first bytes ([sniffStream]).
class StreamSniff {
  const StreamSniff(this.kind, {this.text, this.status});

  /// `hls`, `link` (the body is only another http(s) link: a `.strm`
  /// file), `json`, `html`, `text` (a reply, not a video) or `binary`
  /// (media data the player has no reader for).
  final String kind;

  /// The reply's own words: a JSON `error`/`message`/`detail`, a page's
  /// `<title>`, or the start of a plain text (one line, ≤160 chars).
  final String? text;
  final int? status;

  /// Appended to the player's error: shown under "Technical details",
  /// read back by the error screen (`_friendlyPlaybackError`). A `link`'s
  /// address is never shown (it may carry a token).
  String get tag =>
      '[SOURCE_REPLY:$kind${status == null ? '' : ' HTTP $status'}]'
      '${text == null || kind == 'link' ? '' : ' $text'}';
}

/// The first KB of [url] (redirects followed), classified. Null when the
/// request itself failed.
Future<StreamSniff?> sniffStream(String url, {http.Client? client}) async {
  final c = client ?? http.Client();
  try {
    final req = http.Request('GET', Uri.parse(url))
      ..headers['Range'] = 'bytes=0-1023';
    final r = await c.send(req).timeout(const Duration(seconds: 10));
    final bytes = <int>[];
    await for (final chunk in r.stream.timeout(const Duration(seconds: 10))) {
      bytes.addAll(chunk);
      if (bytes.length >= 1024) break;
    }
    final status = r.statusCode >= 400 ? r.statusCode : null;
    final type = (r.headers['content-type'] ?? '').toLowerCase();
    final body = utf8
        .decode(bytes.take(1024).toList(), allowMalformed: true)
        .replaceFirst('\uFEFF', '')
        .trimLeft();
    String oneLine(String s) {
      final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
      return t.length > 160 ? '${t.substring(0, 160)}…' : t;
    }

    if (body.startsWith('#EXTM3U')) return StreamSniff('hls', status: status);
    final link = RegExp(r'^https?://\S+$').firstMatch(body.trim())?.group(0);
    if (link != null && status == null) return StreamSniff('link', text: link);
    if (type.contains('json') || body.startsWith('{') || body.startsWith('[')) {
      final m = RegExp(
              r'"(?:error_message|error|message|detail|msg)"\s*:\s*"([^"]{1,300})"')
          .firstMatch(body);
      return StreamSniff('json',
          text: oneLine(m?.group(1) ?? body), status: status);
    }
    if (type.contains('html') || body.startsWith('<')) {
      final title = RegExp(r'<title[^>]*>([^<]{1,300})', caseSensitive: false)
          .firstMatch(body)
          ?.group(1);
      return StreamSniff('html',
          text: title == null ? null : oneLine(title), status: status);
    }
    final printable = body.runes
        .where((r) => r == 9 || r == 10 || r == 13 || (r >= 32 && r != 0xFFFD))
        .length;
    if (body.isNotEmpty && printable / body.runes.length > 0.95) {
      return StreamSniff('text', text: oneLine(body), status: status);
    }
    return StreamSniff('binary', status: status);
  } catch (e) {
    debugPrint('sniffStream failed: $e');
    return null;
  } finally {
    if (client == null) c.close();
  }
}

/// A network controller for [url], told to expect HLS when [url] is a
/// live `.ts` on a host [learnHlsHost] has seen redirect to HLS. VOD files
/// on the same host keep the normal detection.
VideoPlayerHdrController streamController(
  String url, {
  Future<ClosedCaptionFile>? closedCaptionFile,
  VideoPlayerOptions? videoPlayerOptions,
  Map<String, String> httpHeaders = const {},
}) {
  // On a TV box another app taking audio focus (launcher previews, voice
  // assistant, CEC) made ExoPlayer pause silently: a frozen picture with
  // the buffer full and no error (Xiaomi MIBOX4, LOG-V5ET8S:
  // onAudioFocusChange(-1)). mixWithOthers = don't handle audio focus.
  // Phones keep it (pause for a call). The plugin keeps this flag shared,
  // so phones send false explicitly to undo Multiview's true.
  if (videoPlayerOptions == null && Platform.isAndroid) {
    videoPlayerOptions =
        VideoPlayerOptions(mixWithOthers: DeviceTypeService.television);
  }
  // A recording (RecordingService.channelFor): a local .ts file.
  if (url.startsWith('/')) {
    return VideoPlayerHdrController.file(File(url),
        closedCaptionFile: closedCaptionFile,
        videoPlayerOptions: videoPlayerOptions);
  }
  final uri = Uri.parse(url);
  if (uri.scheme == 'file') {
    return VideoPlayerHdrController.file(File.fromUri(uri),
        closedCaptionFile: closedCaptionFile,
        videoPlayerOptions: videoPlayerOptions);
  }
  if (uri.scheme == 'content' && Platform.isAndroid) {
    return VideoPlayerHdrController.contentUri(uri,
        closedCaptionFile: closedCaptionFile,
        videoPlayerOptions: videoPlayerOptions);
  }
  final hls = _streamUsesHls(url);
  return VideoPlayerHdrController.networkUrl(
    uri,
    formatHint: hls ? VideoFormat.hls : null,
    httpHeaders: httpHeaders,
    closedCaptionFile: closedCaptionFile,
    videoPlayerOptions: videoPlayerOptions,
  );
}

/// True (once per host) when [error] says [url]'s live `.ts` was not a TS
/// stream **and** the link really answers with an HLS playlist: the caller
/// then retries it, and [streamController] opens that host's channels as
/// HLS from now on. Checked first since 1.0.36: one dead channel answering
/// with an error page used to mark the whole server, and every other
/// channel on it then failed with "Input does not start with the #EXTM3U
/// header" until the app restarted (Romanian channels, Discord photo,
/// 2026-10-22).
Future<bool> learnHlsHost(String url, Object error,
    {http.Client? client}) async {
  if (!error.toString().contains('ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED')) {
    return false;
  }
  final uri = Uri.tryParse(url);
  if (uri == null ||
      !uri.path.toLowerCase().endsWith('.ts') ||
      _hlsHosts.contains(uri.host)) {
    return false;
  }
  final sniff = await sniffStream(url, client: client);
  if (sniff?.kind != 'hls') return false;
  return _hlsHosts.add(uri.host);
}

/// True (once per link) when [url] was opened as HLS only because its host
/// is in [_hlsHosts] and the reply was not a playlist
/// (MANIFEST_MALFORMED): this channel is a plain TS stream on a mixed
/// server, so the caller retries it the normal way.
bool unlearnHlsUrl(String url, Object error) {
  if (!error.toString().contains('ERROR_CODE_PARSING_MANIFEST_MALFORMED')) {
    return false;
  }
  final uri = Uri.tryParse(url);
  if (uri == null ||
      !uri.path.toLowerCase().endsWith('.ts') ||
      !_hlsHosts.contains(uri.host) ||
      _hlsUrls.contains(url)) {
    return false;
  }
  return _notHlsUrls.add(url);
}

bool _streamUsesHls(String url) {
  final uri = Uri.parse(url);
  return _hlsUrls.contains(url) ||
      (_hlsHosts.contains(uri.host) &&
          uri.path.toLowerCase().endsWith('.ts') &&
          !_notHlsUrls.contains(url));
}
