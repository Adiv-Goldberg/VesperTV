// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer.platformview;

import android.content.Context;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import androidx.media3.common.MediaItem;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.exoplayer.DefaultLoadControl;
import androidx.media3.exoplayer.DefaultRenderersFactory;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.audio.AudioSink;
import androidx.media3.exoplayer.audio.DefaultAudioSink;
import io.flutter.plugins.videoplayer.AudioPassthrough;
import io.flutter.plugins.videoplayer.ExoPlayerEventListener;
import io.flutter.plugins.videoplayer.OnDemandLoadControl;
import io.flutter.plugins.videoplayer.VideoAsset;
import io.flutter.plugins.videoplayer.VideoPlayer;
import io.flutter.plugins.videoplayer.VideoPlayerCallbacks;
import io.flutter.plugins.videoplayer.VideoPlayerOptions;
import io.flutter.view.TextureRegistry.SurfaceProducer;

/**
 * A subclass of {@link VideoPlayer} that adds functionality related to platform view as a way of
 * displaying the video in the app.
 */
public class PlatformViewVideoPlayer extends VideoPlayer {
  // TODO: Migrate to stable API, see https://github.com/flutter/flutter/issues/147039.
  @UnstableApi
  @VisibleForTesting
  public PlatformViewVideoPlayer(
      @NonNull VideoPlayerCallbacks events,
      @NonNull MediaItem mediaItem,
      @NonNull VideoPlayerOptions options,
      @NonNull ExoPlayerProvider exoPlayerProvider) {
    super(events, mediaItem, options, /* surfaceProducer */ null, exoPlayerProvider);
  }

  /**
   * Creates a platform view video player.
   *
   * @param context application context.
   * @param events event callbacks.
   * @param asset asset to play.
   * @param options options for playback.
   * @return a video player instance.
   */
  // TODO: Migrate to stable API, see https://github.com/flutter/flutter/issues/147039.
  @UnstableApi
  @NonNull
  public static PlatformViewVideoPlayer create(
      @NonNull Context context,
      @NonNull VideoPlayerCallbacks events,
      @NonNull VideoAsset asset,
      @NonNull VideoPlayerOptions options) {
    final OnDemandLoadControl[] policy = new OnDemandLoadControl[1];
    PlatformViewVideoPlayer player = new PlatformViewVideoPlayer(
        events,
        asset.getMediaItem(),
        options,
        () -> {
          ExoPlayer.Builder builder = new ExoPlayer.Builder(context);
          DefaultLoadControl.Builder loadControlBuilder = new DefaultLoadControl.Builder();
          // See TextureVideoPlayer.create()'s identical setup for why the
          // min/max buffer is raised well past media3's default (an
          // unconfirmed attempt to prevent the corruption/discontinuity
          // before it happens, not just recover faster from it) and why
          // the playback-start thresholds are still cut down regardless.
          loadControlBuilder.setBufferDurationsMs(
              /* minBufferMs= */ 90_000,
              /* maxBufferMs= */ 120_000,
              /* bufferForPlaybackMs= */ 500,
              /* bufferForPlaybackAfterRebufferMs= */ 500);
          // Small-RAM devices: a byte cap too (4K remux ANR, see BufferBudget).
          io.flutter.plugins.videoplayer.BufferBudget.apply(
              context, loadControlBuilder,
              io.flutter.plugins.videoplayer.BufferBudget.MAIN_PLAYER_BYTES);
          if (options.backBufferDurationMs != null) {
            if (options.backBufferDurationMs < 0) {
              throw new IllegalArgumentException("backBufferDurationMs must be at least 0");
            }
            if (options.backBufferDurationMs > 0) {
              // Clamp the value to ensure it fits within the int range expected by
              // DefaultLoadControl.
              int backBufferInt =
                  (int) Math.min(options.backBufferDurationMs.longValue(), Integer.MAX_VALUE);
              loadControlBuilder.setBackBuffer(backBufferInt, /* retainBackBufferFromKeyframe= */ true);
            }
          }
          policy[0] = new OnDemandLoadControl(loadControlBuilder.build());
          builder.setLoadControl(policy[0]);
          androidx.media3.exoplayer.trackselection.DefaultTrackSelector trackSelector =
              new androidx.media3.exoplayer.trackselection.DefaultTrackSelector(context);
          // Root cause of the multiview/mini-player audio bleed-through
          // (confirmed via two A/B diagnostic builds): DefaultAudioSink
          // auto-detects the device's real HDMI passthrough capability
          // whenever a Context reaches it, and once AC3/E-AC3 becomes
          // passthrough-eligible, setVolume() silently becomes a no-op for
          // that track — the compressed bitstream goes straight to the
          // receiver, bypassing ExoPlayer's own per-instance gain stage
          // entirely (a well-documented ExoPlayer limitation, not specific
          // to this app). That's exactly why every simultaneous player
          // instance's audio became un-mutable. This app has no need for
          // genuine receiver passthrough (it's a casual viewing app, not a
          // home-theater-focused player), so AudioSink is built without a
          // Context below — per DefaultAudioSink's own documented
          // behavior, that keeps it permanently at its default "no
          // encoded audio passthrough support" capability, forcing AC3/
          // E-AC3 to always decode to PCM (hardware MediaCodec, or the
          // FFmpeg extension below as fallback) instead of ever being
          // passed through as a raw bitstream — which keeps setVolume()
          // reliable regardless of how many instances are playing at once.
          // Exception (opt-in, Settings > Interface > Audio): with
          // AudioPassthrough on, this main player's sink gets the Context so
          // Dolby Atmos / AC3 / DTS reach the receiver untouched; its volume
          // is then the TV's. Multiview tiles are texture players and never
          // get here.
          final boolean passthrough = AudioPassthrough.isEnabled();
          DefaultRenderersFactory renderersFactory =
              new DefaultRenderersFactory(context) {
                @Override
                protected void buildVideoRenderers(
                    Context rendererContext, int extensionMode,
                    androidx.media3.exoplayer.mediacodec.MediaCodecSelector selector,
                    boolean fallback, android.os.Handler handler,
                    androidx.media3.exoplayer.video.VideoRendererEventListener listener,
                    long joiningMs, java.util.ArrayList<androidx.media3.exoplayer.Renderer> out) {
                  if (options.nativeSurfaceHolder != null && FormulerVideoRenderer.isTargetDevice()) {
                    out.add(new FormulerVideoRenderer(rendererContext,
                        new androidx.media3.exoplayer.video.MediaCodecVideoRenderer.Builder(rendererContext)
                            .setCodecAdapterFactory(getCodecAdapterFactory())
                            .setMediaCodecSelector(selector).setEnableDecoderFallback(fallback)
                            .setAllowedJoiningTimeMs(joiningMs).setEventHandler(handler)
                            .setEventListener(listener).setMaxDroppedFramesToNotify(50)));
                    return;
                  }
                  super.buildVideoRenderers(rendererContext, extensionMode, selector, fallback,
                      handler, listener, joiningMs, out);
                }

                @Nullable
                @Override
                protected AudioSink buildAudioSink(
                    Context context,
                    boolean enableFloatOutput,
                    boolean enableAudioOutputPlaybackParams) {
                  if (passthrough) {
                    return new DefaultAudioSink.Builder(context)
                        .setEnableFloatOutput(enableFloatOutput)
                        .setEnableAudioOutputPlaybackParameters(enableAudioOutputPlaybackParams)
                        .build();
                  }
                  //noinspection deprecation — deliberate: see the comment above.
                  return new DefaultAudioSink.Builder()
                      .setEnableFloatOutput(enableFloatOutput)
                      .setEnableAudioOutputPlaybackParameters(enableAudioOutputPlaybackParams)
                      .build();
                }
              };
          // ON, not PREFER: PREFER makes ExoPlayer always choose the
          // software FFmpeg decoder over the hardware one for any format
          // the extension supports at all, not just the ones the hardware
          // genuinely can't handle (AC3/E-AC3 on a device with no licensed
          // Dolby decoder, this extension's original reason for existing
          // here) — reported directly as real instability on a Formuler
          // under Multiview's concurrent-decode load with this set to
          // PREFER: an audio-focused cell's plain AAC audio was being
          // needlessly software-decoded instead of using the hardware
          // decoder it could handle natively, and that's what gave out
          // after ~35-60s with 3 simultaneous streams — never stress-
          // tested under concurrent load when PREFER was first set, only
          // as a single always-on stream. ON keeps the software decoder
          // purely as a fallback for formats hardware truly can't do.
          renderersFactory.setExtensionRendererMode(
              DefaultRenderersFactory.EXTENSION_RENDERER_MODE_ON);
          // A decoder that fails to start (a Formuler Z10 Max's first HEVC
          // decoder on a 4K HDR channel that TiviMate plays fine on the same
          // box, 2026-10-19) makes ExoPlayer try the next one the device
          // lists instead of failing the stream.
          renderersFactory.setEnableDecoderFallback(true);
          builder
              .setTrackSelector(trackSelector)
              .setMediaSourceFactory(asset.getMediaSourceFactory(context))
              .setRenderersFactory(renderersFactory);
          return builder.build();
        });
    player.setOnDemandLoadControl(policy[0]);
    return player;
  }

  /** Main player only: Multiview tiles keep their own recovery (one connection each). */
  @Override
  protected boolean reconnectLiveStreams() {
    return true;
  }

  @NonNull
  @Override
  protected ExoPlayerEventListener createExoPlayerEventListener(
      @NonNull ExoPlayer exoPlayer, @Nullable SurfaceProducer surfaceProducer) {
    return new PlatformViewExoPlayerEventListener(exoPlayer, videoPlayerEvents);
  }
}
