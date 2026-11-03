// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import android.content.Context;
import android.net.Uri;
import androidx.media3.common.C;
import androidx.media3.common.util.Util;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.OptIn;
import androidx.annotation.VisibleForTesting;
import androidx.media3.common.Format;
import androidx.media3.common.MediaItem;
import androidx.media3.common.MimeTypes;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.datasource.DataSource;
import androidx.media3.datasource.DefaultDataSource;
import androidx.media3.datasource.DefaultHttpDataSource;
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory;
import androidx.media3.exoplayer.source.MediaSource;
import androidx.media3.extractor.DefaultExtractorsFactory;
import androidx.media3.extractor.ExtractorsFactory;
import java.util.Collections;
import java.util.Map;

final class HttpVideoAsset extends VideoAsset {
  static final int LIVE_READ_TIMEOUT_MS = 30_000;
  @NonNull private final StreamingFormat streamingFormat;
  @NonNull private final Map<String, String> httpHeaders;
  @Nullable private final String userAgent;
  // VesperTV patch: Data pool measured bitrate, see StatsBridge.
  private final StreamStats stats;

  @Nullable
  @Override
  StreamStats streamStats() {
    return stats;
  }

  @OptIn(markerClass = UnstableApi.class)
  HttpVideoAsset(
      @Nullable String assetUrl,
      @NonNull StreamingFormat streamingFormat,
      @NonNull Map<String, String> httpHeaders,
      @Nullable String userAgent) {
    super(assetUrl);
    this.streamingFormat = streamingFormat;
    this.httpHeaders = httpHeaders;
    this.userAgent = userAgent;
    // Only a progressive file has one resource whose Content-Length is its size.
    // Never expose an HLS/DASH manifest, segment, subtitle or encryption key size.
    Uri fileUri = assetUrl == null ? null : Uri.parse(assetUrl);
    stats = new StreamStats(streamingFormat == StreamingFormat.UNKNOWN && fileUri != null
        && Util.inferContentType(fileUri) == C.CONTENT_TYPE_OTHER ? fileUri : null);
  }

  @NonNull
  @Override
  public MediaItem getMediaItem() {
    MediaItem.Builder builder = new MediaItem.Builder().setUri(assetUrl);
    String mimeType = null;
    switch (streamingFormat) {
      case SMOOTH:
        mimeType = MimeTypes.APPLICATION_SS;
        break;
      case DYNAMIC_ADAPTIVE:
        mimeType = MimeTypes.APPLICATION_MPD;
        break;
      case HTTP_LIVE:
        mimeType = MimeTypes.APPLICATION_M3U8;
        break;
    }
    if (mimeType != null) {
      builder.setMimeType(mimeType);
    }
    return builder.build();
  }

  @NonNull
  @Override
  public MediaSource.Factory getMediaSourceFactory(@NonNull Context context) {
    return getMediaSourceFactory(context, new DefaultHttpDataSource.Factory());
  }

  /**
   * Returns a configured media source factory, starting at the provided factory.
   *
   * <p>This method is provided for ease of testing without making real HTTP calls.
   *
   * @param context application context.
   * @param initialFactory initial factory, to be configured.
   * @return configured factory, or {@code null} if not needed for this asset type.
   */
  @OptIn(markerClass = UnstableApi.class) // VesperTV patch: setTransferListener
  @VisibleForTesting
  MediaSource.Factory getMediaSourceFactory(
      Context context, DefaultHttpDataSource.Factory initialFactory) {
    unstableUpdateDataSourceFactory(initialFactory, httpHeaders, userAgent);
    initialFactory.setTransferListener(stats);
    DataSource.Factory http = initialFactory;
    if (stats.isProgressive()) {
      http = () -> new LiveReconnectDataSource(initialFactory.createDataSource(), stats);
    }
    DataSource.Factory dataSourceFactory = new DefaultDataSource.Factory(context, http);
    return new DefaultMediaSourceFactory(dataSourceFactory, liveCaptionExtractors());
  }

  /**
   * VesperTV patch: CEA-608 closed captions ride inside the video stream of a live MPEG-TS
   * channel, and TsExtractor only looks for them when the stream declares them, which IPTV
   * streams almost never do. Always expecting them gives every .ts stream a "CC" text track
   * (empty on channels without captions — accepted by the owner, 2026-10-19). HLS already
   * exposes undeclared CEA-608 by default.
   */
  @OptIn(markerClass = UnstableApi.class)
  private static ExtractorsFactory liveCaptionExtractors() {
    return new DefaultExtractorsFactory()
        .setTsSubtitleFormats(
            Collections.singletonList(
                new Format.Builder().setSampleMimeType(MimeTypes.APPLICATION_CEA608).build()));
  }

  // TODO: Migrate to stable API, see https://github.com/flutter/flutter/issues/147039.
  @OptIn(markerClass = UnstableApi.class)
  private static void unstableUpdateDataSourceFactory(
      @NonNull DefaultHttpDataSource.Factory factory,
      @NonNull Map<String, String> httpHeaders,
      @Nullable String userAgent) {
    factory.setUserAgent(userAgent).setAllowCrossProtocolRedirects(true);
    // VesperTV patch: wait up to 30 s for data, not media3's 8 s. Some IPTV servers send live
    // .ts in bursts with 8-9.5 s of silence between them (Blcktv, measured 2026-11-03: 48
    // such gaps in 30 min on one healthy connection). At 8 s the player timed out, reconnected
    // and the server replayed seconds already shown: the "skips back 5-10 s" repeat. Opening
    // still fails fast (connect timeout unchanged), so channel changes are not slower.
    factory.setReadTimeoutMs(LIVE_READ_TIMEOUT_MS);
    if (!httpHeaders.isEmpty()) {
      factory.setDefaultRequestProperties(httpHeaders);
    }
  }
}
