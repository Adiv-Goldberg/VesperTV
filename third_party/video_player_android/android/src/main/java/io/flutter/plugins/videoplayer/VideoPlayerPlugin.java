// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import android.content.Context;
import android.util.LongSparseArray;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.OptIn;
import androidx.media3.common.util.UnstableApi;
import io.flutter.FlutterInjector;
import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugins.videoplayer.platformview.PlatformVideoViewFactory;
import io.flutter.plugins.videoplayer.platformview.PlatformViewVideoPlayer;
import io.flutter.plugins.videoplayer.texture.TextureVideoPlayer;
import io.flutter.view.TextureRegistry;

/** Android platform implementation of the VideoPlayerPlugin. */
public class VideoPlayerPlugin implements FlutterPlugin, ActivityAware, AndroidVideoPlayerApi {
  private static final String TAG = "VideoPlayerPlugin";
  private final LongSparseArray<VideoPlayer> videoPlayers = new LongSparseArray<>();
  private FlutterState flutterState;
  private final VideoPlayerOptions sharedOptions = new VideoPlayerOptions();
  private long nextPlayerIdentifier = 1;
  // VesperTV patch: embedded subtitles, see SubtitleBridge.
  @Nullable private SubtitleBridge subtitleBridge;
  // VesperTV patch: Data pool measured bitrate / frame rate, see StatsBridge.
  @Nullable private StatsBridge statsBridge;
  // VesperTV patch: opt-in HDMI audio passthrough, see AudioPassthrough.
  @Nullable private AudioPassthrough audioPassthrough;
  // VesperTV patch: opt-in Shield green-flicker fix, see VideoLayering.
  @Nullable private VideoLayering videoLayering;
  // VesperTV patch: Native video surface (beta), see NativeVideoSurface.
  @Nullable private NativeVideoSurface nativeVideoSurface;
  // VesperTV patch: native Multiview tiles, see MultiviewTiles.
  @Nullable private MultiviewTiles multiviewTiles;

  /** Register this with the v2 embedding for the plugin to respond to lifecycle callbacks. */
  public VideoPlayerPlugin() {}

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    final FlutterInjector injector = FlutterInjector.instance();
    this.flutterState =
        new FlutterState(
            binding.getApplicationContext(),
            binding.getBinaryMessenger(),
            injector.flutterLoader()::getLookupKeyForAsset,
            injector.flutterLoader()::getLookupKeyForAsset,
            binding.getTextureRegistry());
    flutterState.startListening(this, binding.getBinaryMessenger());
    subtitleBridge = new SubtitleBridge(binding.getBinaryMessenger(), videoPlayers);
    statsBridge = new StatsBridge(binding.getBinaryMessenger(), videoPlayers);
    audioPassthrough = new AudioPassthrough(binding.getBinaryMessenger());
    videoLayering = new VideoLayering(binding.getBinaryMessenger());
    nativeVideoSurface = new NativeVideoSurface(binding.getBinaryMessenger(), videoPlayers);
    multiviewTiles = new MultiviewTiles(binding.getBinaryMessenger());

    binding
        .getPlatformViewRegistry()
        .registerViewFactory(
            "plugins.flutter.dev/video_player_android",
            new PlatformVideoViewFactory(videoPlayers::get));
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (flutterState == null) {
      Log.wtf(TAG, "Detached from the engine before registering to it.");
    }
    flutterState.stopListening(binding.getBinaryMessenger());
    flutterState = null;
    if (subtitleBridge != null) {
      subtitleBridge.dispose();
      subtitleBridge = null;
    }
    if (statsBridge != null) {
      statsBridge.dispose();
      statsBridge = null;
    }
    if (videoLayering != null) {
      videoLayering.dispose();
      videoLayering = null;
    }
    if (audioPassthrough != null) {
      audioPassthrough.dispose();
      audioPassthrough = null;
    }
    if (nativeVideoSurface != null) {
      nativeVideoSurface.dispose();
      nativeVideoSurface = null;
    }
    onDestroy();
    if (multiviewTiles != null) {
      multiviewTiles.dispose();
      multiviewTiles = null;
    }
  }

  // VesperTV patch: the native video surface lives in the activity's content view.
  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    if (nativeVideoSurface != null) nativeVideoSurface.setActivity(binding.getActivity());
    if (multiviewTiles != null) multiviewTiles.setActivity(binding.getActivity());
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    if (nativeVideoSurface != null) nativeVideoSurface.setActivity(null);
    if (multiviewTiles != null) multiviewTiles.setActivity(null);
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivity() {
    if (nativeVideoSurface != null) nativeVideoSurface.setActivity(null);
    if (multiviewTiles != null) multiviewTiles.setActivity(null);
  }

  private void disposeAllPlayers() {
    for (int i = 0; i < videoPlayers.size(); i++) {
      videoPlayers.valueAt(i).dispose();
    }
    videoPlayers.clear();
  }

  public void onDestroy() {
    // The whole FlutterView is being destroyed. Here we release resources acquired for all
    // instances
    // of VideoPlayer. Once https://github.com/flutter/flutter/issues/19358 is resolved this may
    // be replaced with just asserting that videoPlayers.isEmpty().
    // https://github.com/flutter/flutter/issues/20989 tracks this.
    disposeAllPlayers();
  }

  @Override
  public void initialize() {
    disposeAllPlayers();
  }

  @OptIn(markerClass = UnstableApi.class)
  @Override
  public long createForPlatformView(@NonNull CreationOptions options) {
    final VideoAsset videoAsset = videoAssetWithOptions(options);

    long id = nextPlayerIdentifier++;
    final String streamInstance = Long.toString(id);
    VideoPlayerOptions playerOptions = new VideoPlayerOptions(sharedOptions);
    playerOptions.backBufferDurationMs = options.getBackBufferDurationMs();
    if (nativeVideoSurface != null) {
      playerOptions.nativeSurfaceHolder = nativeVideoSurface.holderForPreparation();
    }

    VideoPlayer videoPlayer =
        PlatformViewVideoPlayer.create(
            flutterState.applicationContext,
            VideoPlayerEventCallbacks.bindTo(flutterState.binaryMessenger, streamInstance),
            videoAsset,
            playerOptions);

    videoPlayer.attachStreamStats(videoAsset.streamStats());
    registerPlayerInstance(videoPlayer, id);
    return id;
  }

  @OptIn(markerClass = UnstableApi.class)
  @Override
  public @NonNull TexturePlayerIds createForTextureView(@NonNull CreationOptions options) {
    final VideoAsset videoAsset = videoAssetWithOptions(options);

    long id = nextPlayerIdentifier++;
    final String streamInstance = Long.toString(id);
    // Force the SurfaceTexture-backed producer instead of the ImageReader one Flutter picks on
    // API 29+. The ImageReader path doesn't apply the decoder's crop rectangle
    // (handlesCropAndRotation() == false, and nothing downstream applies it either): a Fire
    // Stick's MTK decoder hands 720p frames in a 1920x1080 buffer, so Multiview tiles showed the
    // picture in the top-left 2/3 and the rest solid green. SurfaceTexture applies the crop through
    // its transform matrix. The flag is read only at creation, so it's set just for this call.
    // Safe here: the app runs the Skia/OpenGL renderer (Impeller is off in AndroidManifest), which
    // is what SurfaceTexture is native to. Texture players are Multiview-only (the main player is
    // a platform view).
    io.flutter.embedding.engine.renderer.FlutterRenderer.debugForceSurfaceProducerGlTextures = true;
    TextureRegistry.SurfaceProducer handle;
    try {
      handle = flutterState.textureRegistry.createSurfaceProducer();
    } finally {
      io.flutter.embedding.engine.renderer.FlutterRenderer.debugForceSurfaceProducerGlTextures =
          false;
    }
    VideoPlayerOptions playerOptions = new VideoPlayerOptions(sharedOptions);
    playerOptions.backBufferDurationMs = options.getBackBufferDurationMs();
    // A native Multiview tile: the player draws into its own SurfaceView (bound before
    // prepare); the texture above stays registered but receives no frames.
    playerOptions.nativeSurfaceHolder =
        multiviewTiles == null ? null : multiviewTiles.claimTile(id);

    VideoPlayer videoPlayer =
        TextureVideoPlayer.create(
            flutterState.applicationContext,
            VideoPlayerEventCallbacks.bindTo(flutterState.binaryMessenger, streamInstance),
            handle,
            videoAsset,
            playerOptions);

    videoPlayer.attachStreamStats(videoAsset.streamStats());
    registerPlayerInstance(videoPlayer, id);
    return new TexturePlayerIds(id, handle.id());
  }

  private @NonNull VideoAsset videoAssetWithOptions(@NonNull CreationOptions options) {
    final @NonNull String uri = options.getUri();
    if (uri.startsWith("asset:")) {
      return VideoAsset.fromAssetUrl(uri);
    } else if (uri.startsWith("rtsp:")) {
      return VideoAsset.fromRtspUrl(uri);
    } else {
      VideoAsset.StreamingFormat streamingFormat = VideoAsset.StreamingFormat.UNKNOWN;
      PlatformVideoFormat formatHint = options.getFormatHint();
      if (formatHint != null) {
        switch (formatHint) {
          case SS:
            streamingFormat = VideoAsset.StreamingFormat.SMOOTH;
            break;
          case DASH:
            streamingFormat = VideoAsset.StreamingFormat.DYNAMIC_ADAPTIVE;
            break;
          case HLS:
            streamingFormat = VideoAsset.StreamingFormat.HTTP_LIVE;
            break;
        }
      }
      return VideoAsset.fromRemoteUrl(
          uri, streamingFormat, options.getHttpHeaders(), options.getUserAgent());
    }
  }

  private void registerPlayerInstance(VideoPlayer player, long id) {
    // VesperTV patch: player.streamStats is set by the create methods before this.
    // Set up the instance-specific API handler, and make sure it is removed when the player is
    // disposed.
    BinaryMessenger messenger = flutterState.binaryMessenger;
    final String channelSuffix = Long.toString(id);
    VideoPlayerInstanceApi.Companion.setUp(messenger, player, channelSuffix);
    player.setDisposeHandler(
        () -> VideoPlayerInstanceApi.Companion.setUp(messenger, null, channelSuffix));

    videoPlayers.put(id, player);
    if (nativeVideoSurface != null) nativeVideoSurface.onPlayerCreated(player, id);
    if (subtitleBridge != null) subtitleBridge.attach(player, id);
  }

  @NonNull
  private VideoPlayer getPlayer(long playerId) {
    VideoPlayer player = videoPlayers.get(playerId);

    // Avoid a very ugly un-debuggable NPE that results in returning a null player.
    if (player == null) {
      String message = "No player found with playerId <" + playerId + ">";
      if (videoPlayers.size() == 0) {
        message += " and no active players created by the plugin.";
      }
      throw new IllegalStateException(message);
    }

    return player;
  }

  @Override
  public void dispose(long playerId) {
    VideoPlayer player = getPlayer(playerId);
    if (nativeVideoSurface != null) nativeVideoSurface.onPlayerDisposed(playerId);
    try {
      player.dispose();
    } finally {
      videoPlayers.remove(playerId);
      if (multiviewTiles != null) multiviewTiles.onPlayerDisposed(playerId);
    }
  }

  @Override
  public void setMixWithOthers(boolean mixWithOthers) {
    sharedOptions.mixWithOthers = mixWithOthers;
  }

  @Override
  public @NonNull String getLookupKeyForAsset(@NonNull String asset, @Nullable String packageName) {
    return packageName == null
        ? flutterState.keyForAsset.get(asset)
        : flutterState.keyForAssetAndPackageName.get(asset, packageName);
  }

  private interface KeyForAssetFn {
    String get(String asset);
  }

  private interface KeyForAssetAndPackageName {
    String get(String asset, String packageName);
  }

  private static final class FlutterState {
    final Context applicationContext;
    final BinaryMessenger binaryMessenger;
    final KeyForAssetFn keyForAsset;
    final KeyForAssetAndPackageName keyForAssetAndPackageName;
    final TextureRegistry textureRegistry;

    FlutterState(
        Context applicationContext,
        BinaryMessenger messenger,
        KeyForAssetFn keyForAsset,
        KeyForAssetAndPackageName keyForAssetAndPackageName,
        TextureRegistry textureRegistry) {
      this.applicationContext = applicationContext;
      this.binaryMessenger = messenger;
      this.keyForAsset = keyForAsset;
      this.keyForAssetAndPackageName = keyForAssetAndPackageName;
      this.textureRegistry = textureRegistry;
    }

    void startListening(VideoPlayerPlugin methodCallHandler, BinaryMessenger messenger) {
      AndroidVideoPlayerApi.Companion.setUp(messenger, methodCallHandler);
    }

    void stopListening(BinaryMessenger messenger) {
      AndroidVideoPlayerApi.Companion.setUp(messenger, null);
    }
  }
}
