// VesperTV patch: counts the bytes a player's HTTP data source really downloads, for the Data
// pool's measured bitrate (live MPEG-TS declares none). See StatsBridge.
package io.flutter.plugins.videoplayer;

import android.net.Uri;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.media3.common.C;
import androidx.annotation.OptIn;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.datasource.DataSource;
import androidx.media3.datasource.DataSpec;
import androidx.media3.datasource.TransferListener;
import java.util.concurrent.atomic.AtomicLong;
import java.util.List;
import java.util.Map;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@OptIn(markerClass = UnstableApi.class)
final class StreamStats implements TransferListener {
  /** Network bytes since the player was created; written on loader threads. */
  final AtomicLong bytes = new AtomicLong();
  /** Total resource size, never downloaded bytes or an adaptive segment size. */
  final AtomicLong fileSizeBytes = new AtomicLong(-1);
  @Nullable private final Uri fileUri;
  // LiveReconnectDataSource: allowed on the main player only, never for a movie /
  // episode (onDemand) or catch-up (finite); set from VideoPlayer.
  volatile boolean allowReconnect;
  volatile boolean onDemand;
  volatile boolean finite;
  final java.util.concurrent.atomic.AtomicInteger reconnects =
      new java.util.concurrent.atomic.AtomicInteger();
  @Nullable volatile String lastReconnect;

  /** A single progressive resource (not HLS/DASH): what LiveReconnectDataSource wraps. */
  boolean isProgressive() {
    return fileUri != null;
  }
  private static final Pattern RANGE = Pattern.compile(
      "bytes\\s+(\\d+)-(\\d+)/(\\d+)", Pattern.CASE_INSENSITIVE);

  StreamStats(@Nullable Uri fileUri) {
    this.fileUri = fileUri;
  }

  /** Read headers from the player's own progressive-file request, no extra connection. */
  static long fileSizeFromHeaders(Map<String, List<String>> headers, DataSpec spec) {
    String encoding = header(headers, "Content-Encoding");
    if (encoding != null && !encoding.equalsIgnoreCase("identity")) return -1;
    String type = header(headers, "Content-Type");
    if (type != null) {
      type = type.toLowerCase(Locale.ROOT);
      if (type.startsWith("text/") || type.contains("json") || type.contains("xml")
          || type.contains("mpegurl")) return -1;
    }
    String range = header(headers, "Content-Range");
    try {
      if (range != null) {
        Matcher match = RANGE.matcher(range.trim());
        if (!match.matches()) return -1;
        long start = Long.parseLong(match.group(1));
        long end = Long.parseLong(match.group(2));
        long total = Long.parseLong(match.group(3));
        return total > 0 && start <= end && end < total ? total : -1;
      }
      // A partial request's Content-Length is not the file's total size.
      if (spec.position != 0 || spec.length != C.LENGTH_UNSET) return -1;
      String length = header(headers, "Content-Length");
      long size = length == null ? -1 : Long.parseLong(length.trim());
      return size > 0 ? size : -1;
    } catch (NumberFormatException ignored) {
      return -1;
    }
  }

  @Nullable
  private static String header(Map<String, List<String>> headers, String name) {
    if (headers == null) return null;
    for (Map.Entry<String, List<String>> entry : headers.entrySet()) {
      if (name.equalsIgnoreCase(entry.getKey()) && entry.getValue() != null
          && !entry.getValue().isEmpty()) return entry.getValue().get(0);
    }
    return null;
  }

  @Override
  public void onTransferInitializing(
      @NonNull DataSource source, @NonNull DataSpec dataSpec, boolean isNetwork) {}

  @Override
  public void onTransferStart(
      @NonNull DataSource source, @NonNull DataSpec dataSpec, boolean isNetwork) {
    if (!isNetwork || fileUri == null || !fileUri.equals(dataSpec.uri)) return;
    long size = fileSizeFromHeaders(source.getResponseHeaders(), dataSpec);
    if (size > 0) fileSizeBytes.set(size);
  }

  @Override
  public void onBytesTransferred(
      @NonNull DataSource source,
      @NonNull DataSpec dataSpec,
      boolean isNetwork,
      int bytesTransferred) {
    if (isNetwork) bytes.addAndGet(bytesTransferred);
  }

  @Override
  public void onTransferEnd(
      @NonNull DataSource source, @NonNull DataSpec dataSpec, boolean isNetwork) {}
}
