// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import static androidx.media3.common.Player.REPEAT_MODE_ALL;
import static androidx.media3.common.Player.REPEAT_MODE_OFF;

import android.os.Handler;
import android.os.Looper;
import android.content.Context;
import android.view.SurfaceHolder;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.media3.common.AudioAttributes;
import androidx.media3.common.C;
import androidx.media3.common.Format;
import androidx.media3.common.MediaItem;
import androidx.media3.common.PlaybackParameters;
import androidx.media3.common.Player;
import androidx.media3.common.TrackGroup;
import androidx.media3.common.TrackSelectionOverride;
import androidx.media3.common.Tracks;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.analytics.AnalyticsListener;
import androidx.media3.exoplayer.source.MediaSource;
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector;
import io.flutter.view.TextureRegistry.SurfaceProducer;
import java.util.ArrayList;
import java.util.List;

/**
 * A class responsible for managing video playback using {@link ExoPlayer}.
 *
 * <p>It provides methods to control playback, adjust volume, and handle seeking.
 */
public abstract class VideoPlayer implements VideoPlayerInstanceApi {
  @NonNull protected final VideoPlayerCallbacks videoPlayerEvents;
  @Nullable protected final SurfaceProducer surfaceProducer;
  @Nullable private DisposeHandler disposeHandler;
  @Nullable private ExoPlayerEventListener exoPlayerEventListener;
  @NonNull protected ExoPlayer exoPlayer;
  // TODO: Migrate to stable API, see https://github.com/flutter/flutter/issues/147039.
  @UnstableApi @Nullable protected DefaultTrackSelector trackSelector;
  // VesperTV patch: set by VideoPlayerPlugin from the asset, read by StatsBridge.
  @Nullable StreamStats streamStats;
  // Native-surface diagnostics may attach after prepare has started the decoder.
  // Keep its actual name from creation; DecoderCounters does not expose a name.
  @Nullable String nativeVideoDecoderName;
  @Nullable SurfaceHolder nativeSurfaceHolder;
  // VesperTV patch: frame rate from the first frames' timestamps (Match frame rate).
  FrameRateProbe frameRateProbe = new FrameRateProbe();
  private final boolean nativePassthrough;

  private final Handler mainHandler = new Handler(Looper.getMainLooper());
  private boolean isDisposed = false;
  @Nullable private OnDemandLoadControl onDemandLoadControl;
  @NonNull private final VodPlaybackTrace vodTrace;

  /** A closure-compatible signature since {@link java.util.function.Supplier} is API level 24. */
  public interface ExoPlayerProvider {
    /**
     * Returns a new {@link ExoPlayer}.
     *
     * @return new instance.
     */
    @NonNull
    ExoPlayer get();
  }

  /** A handler to run when dispose is called. */
  public interface DisposeHandler {
    void onDispose();
  }

  // TODO: Migrate to stable API, see https://github.com/flutter/flutter/issues/147039.
  @UnstableApi
  // Error thrown for this-escape warning on JDK 21+ due to
  // https://bugs.openjdk.org/browse/JDK-8015831.
  // Keeping behavior as-is and addressing the warning could cause a regression:
  // https://github.com/flutter/packages/pull/10193
  @SuppressWarnings("this-escape")
  public VideoPlayer(
      @NonNull VideoPlayerCallbacks events,
      @NonNull MediaItem mediaItem,
      @NonNull VideoPlayerOptions options,
      @Nullable SurfaceProducer surfaceProducer,
      @NonNull ExoPlayerProvider exoPlayerProvider) {
    this.videoPlayerEvents = events;
    this.surfaceProducer = surfaceProducer;
    exoPlayer = exoPlayerProvider.get();
    vodTrace = new VodPlaybackTrace(exoPlayer);
    nativePassthrough = AudioPassthrough.isEnabled();
    nativeSurfaceHolder = options.nativeSurfaceHolder;
    exoPlayer.addAnalyticsListener(
        new AnalyticsListener() {
          @Override public void onPlaybackStateChanged(EventTime time, int state) {
            vodTrace.onPlaybackStateChanged(time, state);
          }
          @Override public void onPlayWhenReadyChanged(EventTime time, boolean ready, int reason) {
            vodTrace.onPlayWhenReadyChanged(time, ready, reason);
          }
          @Override public void onAudioUnderrun(EventTime time, int bytes, long bufferMs, long elapsedMs) {
            vodTrace.onAudioUnderrun(time, bytes, bufferMs, elapsedMs);
          }
          @Override public void onPositionDiscontinuity(EventTime time,
              androidx.media3.common.Player.PositionInfo before,
              androidx.media3.common.Player.PositionInfo after, int reason) {
            vodTrace.onPositionDiscontinuity(time, before, after, reason);
          }
          @Override
          public void onVideoDecoderInitialized(
              @NonNull EventTime eventTime, @NonNull String decoderName,
              long initializedTimestampMs, long initializationDurationMs) {
            nativeVideoDecoderName = decoderName;
          }

          @Override
          public void onVideoDecoderReleased(
              @NonNull EventTime eventTime, @NonNull String decoderName) {
            if (decoderName.equals(nativeVideoDecoderName)) nativeVideoDecoderName = null;
          }
        });

    // Try to get the track selector from the ExoPlayer if it was built with one
    if (exoPlayer.getTrackSelector() instanceof DefaultTrackSelector) {
      trackSelector = (DefaultTrackSelector) exoPlayer.getTrackSelector();
    }

    exoPlayer.setVideoFrameMetadataListener(frameRateProbe);
    // Bind before prepare, so 4K does not start on a placeholder output and
    // then switch to the real SurfaceView after Dart receives initialized.
    if (nativeSurfaceHolder != null) exoPlayer.setVideoSurfaceHolder(nativeSurfaceHolder);
    exoPlayer.setMediaItem(mediaItem);
    exoPlayer.prepare();
    exoPlayerEventListener = createExoPlayerEventListener(exoPlayer, surfaceProducer);
    exoPlayer.addListener(exoPlayerEventListener);
    exoPlayer.addListener(liveQueue);
    setAudioAttributes(exoPlayer, options.mixWithOthers);
  }

  // VesperTV patch: seamless live reconnect. While a live progressive channel
  // plays on the main player, a second copy of it waits in the playlist. When
  // the provider closes the connection (or it drops, see
  // LiveReconnectDataSource), the first copy plays out its buffer and ExoPlayer
  // moves to the copy, which opens a new connection only after the old one
  // closed. A playlist boundary absorbs the new connection's timestamp jump
  // (splicing bytes did not: frozen picture, looping audio after a Tuliprox
  // restart, +557). Replaces the decoder reset + buffer loss + jump to "now"
  // of the in-place restart.
  @Nullable private MediaSource.Factory liveSourceFactory;
  private static final long LIVE_STALL_MS = 2500;
  private final Runnable liveStallCheck = () -> {
    // The copy could not be queued ahead of the end (duration still unknown):
    // nothing left to load, still buffering = jump to the copy ourselves.
    if (exoPlayer.getPlaybackState() == Player.STATE_BUFFERING
        && !exoPlayer.isLoading()
        && exoPlayer.hasNextMediaItem()) {
      note("stalled at the end of a copy, moving on");
      exoPlayer.seekToNextMediaItem();
    }
  };
  private final Player.Listener liveQueue = new Player.Listener() {
    @Override
    public void onPlaybackStateChanged(int state) {
      mainHandler.removeCallbacks(liveStallCheck);
      if (state == Player.STATE_READY) {
        queueLiveCopy();
      } else if (state == Player.STATE_BUFFERING && exoPlayer.hasNextMediaItem()) {
        mainHandler.postDelayed(liveStallCheck, LIVE_STALL_MS);
      }
    }

    @Override
    public void onMediaItemTransition(@Nullable MediaItem item, int reason) {
      if (reason != Player.MEDIA_ITEM_TRANSITION_REASON_AUTO
          && reason != Player.MEDIA_ITEM_TRANSITION_REASON_SEEK) {
        return;
      }
      int index = exoPlayer.getCurrentMediaItemIndex();
      if (index > 0) exoPlayer.removeMediaItems(0, index);
      if (streamStats != null) {
        int n = streamStats.reconnects.incrementAndGet();
        String why = streamStats.lastReconnect;
        streamStats.lastReconnect = "switched to copy " + n + (why == null ? "" : " after " + why);
      }
    }
  };

  private void note(@NonNull String what) {
    android.util.Log.w("VesperReconnect", what);
    if (streamStats != null) streamStats.lastReconnect = what;
  }

  private boolean liveCopiesWanted() {
    StreamStats stats = streamStats;
    return reconnectLiveStreams()
        && stats != null
        && stats.isProgressive()
        && !stats.onDemand
        && !stats.finite
        && exoPlayer.isCurrentMediaItemLive();
  }

  private void queueLiveCopy() {
    if (isDisposed || !liveCopiesWanted() || exoPlayer.hasNextMediaItem()) return;
    MediaItem item = exoPlayer.getCurrentMediaItem();
    if (item == null) return;
    if (liveSourceFactory != null) {
      exoPlayer.addMediaSource(liveSourceFactory.createMediaSource(item));
    } else {
      exoPlayer.addMediaItem(item);
    }
  }

  /** A movie / episode / catch-up must never move on to a queued live copy. */
  private void dropLiveCopies() {
    mainHandler.removeCallbacks(liveStallCheck);
    int next = exoPlayer.getCurrentMediaItemIndex() + 1;
    int count = exoPlayer.getMediaItemCount();
    if (count > next) exoPlayer.removeMediaItems(next, count);
  }

  public void setDisposeHandler(@Nullable DisposeHandler handler) {
    disposeHandler = handler;
  }

  boolean canReplaceNativeStream() {
    return !isDisposed && nativeSurfaceHolder != null
        && nativePassthrough == AudioPassthrough.isEnabled();
  }

  /** A live zap keeps the same ExoPlayer and output; no detach/release/placeholder. */
  void replaceNativeStream(@NonNull Context context, @NonNull VideoAsset asset) {
    setOnDemandBuffering(false);
    if (exoPlayerEventListener != null) exoPlayerEventListener.resetForNewSource();
    if (trackSelector != null) {
      trackSelector.setParameters(trackSelector.buildUponParameters()
          .clearOverrides().setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true));
    }
    streamStats = asset.streamStats();
    if (streamStats != null) streamStats.allowReconnect = reconnectLiveStreams();
    frameRateProbe = new FrameRateProbe();
    exoPlayer.setVideoFrameMetadataListener(frameRateProbe);
    liveSourceFactory = asset.getMediaSourceFactory(context);
    exoPlayer.setMediaSource(liveSourceFactory.createMediaSource(asset.getMediaItem()));
    exoPlayer.prepare();
    exoPlayer.play();
  }

  @NonNull
  protected abstract ExoPlayerEventListener createExoPlayerEventListener(
      @NonNull ExoPlayer exoPlayer, @Nullable SurfaceProducer surfaceProducer);

  private static void setAudioAttributes(ExoPlayer exoPlayer, boolean isMixMode) {
    exoPlayer.setAudioAttributes(
        new AudioAttributes.Builder().setContentType(C.AUDIO_CONTENT_TYPE_MOVIE).build(),
        !isMixMode);
  }

  /**
   * Helper method to extract a long value from a Format field, returning null if the value is
   * Format.NO_VALUE.
   *
   * @param value The format value to check.
   * @return The value as a Long, or null if it's Format.NO_VALUE.
   */
  private static Long getFormatValue(int value) {
    return value != Format.NO_VALUE ? (long) value : null;
  }

  /**
   * Helper method to extract a double value from a Format field, returning null if the value is
   * Format.NO_VALUE.
   *
   * @param value The format value to check.
   * @return The value as a Double, or null if it's Format.NO_VALUE.
   */
  private static Double getFormatValue(double value) {
    return value != Format.NO_VALUE ? value : null;
  }

  @Override
  public void play() {
    exoPlayer.play();
  }

  @Override
  public void pause() {
    exoPlayer.pause();
  }

  @Override
  public void setLooping(boolean looping) {
    exoPlayer.setRepeatMode(looping ? REPEAT_MODE_ALL : REPEAT_MODE_OFF);
  }

  @Override
  public void setVolume(double volume) {
    float bracketedValue = (float) Math.max(0.0, Math.min(1.0, volume));
    exoPlayer.setVolume(bracketedValue);
  }

  @Override
  public void setPlaybackSpeed(double speed) {
    // We do not need to consider pitch and skipSilence for now as we do not handle them and
    // therefore never diverge from the default values.
    final PlaybackParameters playbackParameters = new PlaybackParameters((float) speed);

    exoPlayer.setPlaybackParameters(playbackParameters);
  }

  @Override
  public long getCurrentPosition() {
    return exoPlayer.getCurrentPosition();
  }

  @Override
  public long getBufferedPosition() {
    return exoPlayer.getBufferedPosition();
  }

  @Override
  public void seekTo(long position) {
    vodTrace.seekRequested(position);
    exoPlayer.seekTo(position);
  }

  /** LiveReconnectDataSource: reconnect live streams underneath this player. */
  protected boolean reconnectLiveStreams() {
    return false;
  }

  /** Called by the plugin after creation (and by replaceNativeStream). */
  void attachStreamStats(@Nullable StreamStats stats) {
    streamStats = stats;
    if (stats != null) stats.allowReconnect = reconnectLiveStreams();
  }

  /** Factory-only wiring; one policy instance per main player. */
  protected void setOnDemandLoadControl(OnDemandLoadControl control) {
    onDemandLoadControl = control;
  }

  /** See {@link OnDemandLoadControl#setLiveReserveMs}. Main player only. */
  void setLiveBuffer(long ms) {
    if (onDemandLoadControl != null) onDemandLoadControl.setLiveReserveMs(ms);
  }

  void setOnDemandBuffering(boolean on) {
    if (onDemandLoadControl != null) onDemandLoadControl.setOnDemand(on);
    vodTrace.setEnabled(on);
    if (exoPlayerEventListener != null) exoPlayerEventListener.setOnDemand(on);
    if (streamStats != null) streamStats.onDemand = on;
    if (on) dropLiveCopies();
  }

  @NonNull
  /** Catch-up playback: see ExoPlayerEventListener.setFiniteMode. */
  void setFiniteMode(boolean on) {
    if (exoPlayerEventListener != null) exoPlayerEventListener.setFiniteMode(on);
    if (streamStats != null) streamStats.finite = on;
    if (on) dropLiveCopies();
  }

  public ExoPlayer getExoPlayer() {
    return exoPlayer;
  }

  // TODO: Migrate to stable API, see https://github.com/flutter/flutter/issues/147039.
  @UnstableApi
  @Override
  public @NonNull NativeAudioTrackData getAudioTracks() {
    List<ExoPlayerAudioTrackData> audioTracks = new ArrayList<>();

    // Get the current tracks from ExoPlayer
    Tracks tracks = exoPlayer.getCurrentTracks();

    // Iterate through all track groups
    for (int groupIndex = 0; groupIndex < tracks.getGroups().size(); groupIndex++) {
      Tracks.Group group = tracks.getGroups().get(groupIndex);

      // Only process audio tracks
      if (group.getType() == C.TRACK_TYPE_AUDIO) {
        for (int trackIndex = 0; trackIndex < group.length; trackIndex++) {
          Format format = group.getTrackFormat(trackIndex);
          boolean isSelected = group.isTrackSelected(trackIndex);

          // Create audio track data with metadata
          ExoPlayerAudioTrackData audioTrack =
              new ExoPlayerAudioTrackData(
                  (long) groupIndex,
                  (long) trackIndex,
                  format.label,
                  format.language,
                  isSelected,
                  getFormatValue(format.bitrate),
                  getFormatValue(format.sampleRate),
                  getFormatValue(format.channelCount),
                  format.codecs != null ? format.codecs : null);

          audioTracks.add(audioTrack);
        }
      }
    }
    return new NativeAudioTrackData(audioTracks);
  }

  // TODO: Migrate to stable API, see https://github.com/flutter/flutter/issues/147039.
  @UnstableApi
  @Override
  public void selectAudioTrack(long groupIndex, long trackIndex) {
    if (trackSelector == null) {
      throw new IllegalStateException("Cannot select audio track: track selector is null");
    }

    // Get current tracks
    Tracks tracks = exoPlayer.getCurrentTracks();

    if (groupIndex < 0 || groupIndex >= tracks.getGroups().size()) {
      throw new IllegalArgumentException(
          "Cannot select audio track: groupIndex "
              + groupIndex
              + " is out of bounds (available groups: "
              + tracks.getGroups().size()
              + ")");
    }

    Tracks.Group group = tracks.getGroups().get((int) groupIndex);

    // Verify it's an audio track
    if (group.getType() != C.TRACK_TYPE_AUDIO) {
      throw new IllegalArgumentException(
          "Cannot select audio track: group at index "
              + groupIndex
              + " is not an audio track (type: "
              + group.getType()
              + ")");
    }

    // Verify the track index is valid
    if (trackIndex < 0 || (int) trackIndex >= group.length) {
      throw new IllegalArgumentException(
          "Cannot select audio track: trackIndex "
              + trackIndex
              + " is out of bounds (available tracks in group: "
              + group.length
              + ")");
    }

    // Get the track group and create a selection override
    TrackGroup trackGroup = group.getMediaTrackGroup();
    TrackSelectionOverride override = new TrackSelectionOverride(trackGroup, (int) trackIndex);

    // Apply the track selection override
    trackSelector.setParameters(
        trackSelector.buildUponParameters().setOverrideForType(override).build());
  }

  // TODO: Migrate to stable API, see https://github.com/flutter/flutter/issues/147039.
  @UnstableApi
  @Override
  public void setAudioTrackTypeDisabled(boolean disabled) {
    if (trackSelector == null) {
      throw new IllegalStateException(
          "Cannot set audio track type disabled: track selector is null");
    }
    // Only ever called once, right after creation — see this method's own
    // Dart-side doc comment (pigeons/messages.dart) for why toggling an
    // already-playing instance isn't safe.
    trackSelector.setParameters(
        trackSelector.buildUponParameters().setTrackTypeDisabled(C.TRACK_TYPE_AUDIO, disabled).build());
  }

  // TODO: Migrate to stable API, see https://github.com/flutter/flutter/issues/147039.
  @UnstableApi
  @Override
  public @NonNull NativeVideoTrackData getVideoTracks() {
    List<ExoPlayerVideoTrackData> videoTracks = new ArrayList<>();

    // Get the current tracks from ExoPlayer
    Tracks tracks = exoPlayer.getCurrentTracks();

    // Iterate through all track groups
    for (int groupIndex = 0; groupIndex < tracks.getGroups().size(); groupIndex++) {
      Tracks.Group group = tracks.getGroups().get(groupIndex);

      // Only process video tracks
      if (group.getType() == C.TRACK_TYPE_VIDEO) {
        for (int trackIndex = 0; trackIndex < group.length; trackIndex++) {
          Format format = group.getTrackFormat(trackIndex);
          boolean isSelected = group.isTrackSelected(trackIndex);

          // Create video track data with metadata
          ExoPlayerVideoTrackData videoTrack =
              new ExoPlayerVideoTrackData(
                  (long) groupIndex,
                  (long) trackIndex,
                  format.label,
                  isSelected,
                  getFormatValue(format.bitrate),
                  getFormatValue(format.width),
                  getFormatValue(format.height),
                  getFormatValue(format.frameRate),
                  format.codecs != null ? format.codecs : null);

          videoTracks.add(videoTrack);
        }
      }
    }
    return new NativeVideoTrackData(videoTracks);
  }

  // TODO: Migrate to stable API, see https://github.com/flutter/flutter/issues/147039.
  @UnstableApi
  @Override
  public void enableAutoVideoQuality() {
    if (trackSelector == null) {
      throw new IllegalStateException("Cannot enable auto video quality: track selector is null");
    }

    // Clear video track override to enable adaptive streaming
    trackSelector.setParameters(
        trackSelector.buildUponParameters().clearOverridesOfType(C.TRACK_TYPE_VIDEO).build());
  }

  // TODO: Migrate to stable API, see https://github.com/flutter/flutter/issues/147039.
  @UnstableApi
  @Override
  public void selectVideoTrack(long groupIndex, long trackIndex) {
    if (trackSelector == null) {
      throw new IllegalStateException("Cannot select video track: track selector is null");
    }

    // Get current tracks
    Tracks tracks = exoPlayer.getCurrentTracks();

    if (groupIndex < 0 || groupIndex >= tracks.getGroups().size()) {
      throw new IllegalArgumentException(
          "Cannot select video track: groupIndex "
              + groupIndex
              + " is out of bounds (available groups: "
              + tracks.getGroups().size()
              + ")");
    }

    Tracks.Group group = tracks.getGroups().get((int) groupIndex);

    // Verify it's a video track
    if (group.getType() != C.TRACK_TYPE_VIDEO) {
      throw new IllegalArgumentException(
          "Cannot select video track: group at index "
              + groupIndex
              + " is not a video track (type: "
              + group.getType()
              + ")");
    }

    // Verify the track index is valid
    if (trackIndex < 0 || (int) trackIndex >= group.length) {
      throw new IllegalArgumentException(
          "Cannot select video track: trackIndex "
              + trackIndex
              + " is out of bounds (available tracks in group: "
              + group.length
              + ")");
    }

    // Get the track group and create a selection override
    TrackGroup trackGroup = group.getMediaTrackGroup();
    TrackSelectionOverride override = new TrackSelectionOverride(trackGroup, (int) trackIndex);

    // Check if the new track has different dimensions than the current track
    Format currentFormat = exoPlayer.getVideoFormat();
    Format newFormat = trackGroup.getFormat((int) trackIndex);
    boolean dimensionsChanged =
        currentFormat == null
            || currentFormat.width != newFormat.width
            || currentFormat.height != newFormat.height;

    // When video dimensions change, we need to force a complete renderer reset to avoid
    // surface rendering issues. We do this by temporarily disabling the video track type,
    // which causes ExoPlayer to release the current video renderer and MediaCodec decoder.
    // After a brief delay, we re-enable video with the new track selection, which creates
    // a fresh renderer properly configured for the new dimensions.
    //
    // Why is this necessary?
    // When switching between video tracks with different resolutions (e.g., 720p to 1080p),
    // the existing video surface and MediaCodec decoder may not properly reconfigure for the
    // new dimensions. This can cause visual glitches where the video appears in the wrong
    // position (e.g., top-left corner) or the old surface remains partially visible.
    // By disabling the video track type, we force ExoPlayer to completely release the
    // current renderer and decoder, ensuring a clean slate for the new resolution.
    //
    // References:
    // - ExoPlayer TrackSelection documentation:
    //   https://developer.android.com/media/media3/exoplayer/track-selection
    // - DefaultTrackSelector.setParameters() for track type disabling:
    //
    // https://developer.android.com/reference/androidx/media3/exoplayer/trackselection/DefaultTrackSelector.Parameters.Builder#setTrackTypeDisabled(int,boolean)
    // - This approach is necessary because ExoPlayer doesn't provide a direct API to force
    //   a renderer reset when dimensions change. Disabling and re-enabling the track type
    //   is the recommended way to ensure proper resource cleanup and reinitialization.
    // TODO(nateshmbhat): Remove this workaround once Media3 provides a supported
    // renderer reset path or reliable resolution-changing track switches.
    // https://github.com/flutter/flutter/issues/183824
    if (dimensionsChanged) {
      final boolean wasPlaying = exoPlayer.isPlaying();
      final long currentPosition = exoPlayer.getCurrentPosition();

      // Disable video track type to force renderer release
      trackSelector.setParameters(
          trackSelector
              .buildUponParameters()
              .setTrackTypeDisabled(C.TRACK_TYPE_VIDEO, true)
              .build());

      // Re-enable video with the new track selection after allowing renderer to release.
      //
      // Why 150ms delay?
      // This delay is necessary to allow the MediaCodec decoder and video renderer to fully
      // release their resources before we attempt to create new ones. Without this delay,
      // the new decoder may be initialized before the old one is completely released, leading
      // to resource conflicts and rendering artifacts. The 150ms value was determined through
      // empirical testing across various Android devices and provides a reliable balance
      // between responsiveness and ensuring complete resource cleanup. Shorter delays (e.g.,
      // 50-100ms) were found to still cause glitches on some devices, while longer delays
      // would unnecessarily impact user experience.
      mainHandler.postDelayed(
          () -> {
            // Guard against player disposal during the delay. The isDisposed flag
            // is the authoritative check; the trackSelector null-check is kept for
            // safety even though it is set in the constructor.
            if (isDisposed || trackSelector == null) {
              return;
            }

            trackSelector.setParameters(
                trackSelector
                    .buildUponParameters()
                    .setTrackTypeDisabled(C.TRACK_TYPE_VIDEO, false)
                    .setOverrideForType(override)
                    .build());

            // Restore playback state
            exoPlayer.seekTo(currentPosition);
            if (wasPlaying) {
              exoPlayer.play();
            }
          },
          150);
      return;
    }

    // Apply the track selection override normally if dimensions haven't changed
    trackSelector.setParameters(
        trackSelector.buildUponParameters().setOverrideForType(override).build());
  }

  public void dispose() {
    isDisposed = true;
    vodTrace.dispose();
    mainHandler.removeCallbacksAndMessages(null);
    if (disposeHandler != null) {
      disposeHandler.onDispose();
    }
    if (exoPlayerEventListener != null) {
      exoPlayerEventListener.dispose();
      // VesperTV: detached before release. A 4K stream's release can pass
      // ExoPlayer's 500 ms timeout (Fire Stick), which reports an error, and
      // the in-place recovery then re-prepared the released player on the
      // main thread ("Ignoring messages sent after release").
      exoPlayer.removeListener(exoPlayerEventListener);
      exoPlayerEventListener = null;
    }
    exoPlayer.release();
  }
}
