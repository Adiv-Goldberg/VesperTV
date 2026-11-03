// VesperTV patch: lets a dropped live connection end cleanly so the next copy
// of the channel (queued by VideoPlayer.queueLiveCopy) takes over.
//
// When a provider closed a live MPEG-TS connection (or a read failed), the
// player used to restart in place: the decoder reset and the buffered video
// (up to 90 s) was thrown away, so the viewer saw a blip and a jump to "now"
// (owner, 2026-11-01: other apps hide these drops). Splicing the new
// connection's bytes into the old stream was tried first (+557) and froze the
// picture with looping audio after a Tuliprox restart: the new connection's
// timestamps don't continue the old ones. A playlist item boundary handles
// that jump, so a server closing the stream ends the item and the reopen of
// the next copy is retried a few times (the provider may be restarting).
// Read errors stay with ExoPlayer's own retry.
//
// Only for the main player's live streams (StreamStats.allowReconnect, not
// onDemand, not finite).
package io.flutter.plugins.videoplayer;

import android.net.Uri;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.OptIn;
import androidx.media3.common.C;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.datasource.DataSource;
import androidx.media3.datasource.DataSpec;
import androidx.media3.datasource.HttpDataSource;
import androidx.media3.datasource.TransferListener;
import java.io.IOException;
import java.io.InterruptedIOException;
import java.util.List;
import java.util.Map;

@OptIn(markerClass = UnstableApi.class)
final class LiveReconnectDataSource implements DataSource {
  private static final String TAG = "VesperReconnect";
  /** Waits before each open attempt of a reconnect copy. */
  private static final long[] ATTEMPT_DELAYS_MS = {0, 500, 1000, 2000, 3000, 3000};

  private final DataSource upstream;
  private final StreamStats stats;
  private boolean unknownLength;
  private long bytesSinceOpen;

  LiveReconnectDataSource(@NonNull DataSource upstream, @NonNull StreamStats stats) {
    this.upstream = upstream;
    this.stats = stats;
  }

  private boolean live() {
    return stats.allowReconnect && !stats.onDemand && !stats.finite;
  }

  @Override
  public void addTransferListener(@NonNull TransferListener transferListener) {
    upstream.addTransferListener(transferListener);
  }

  @Override
  public long open(@NonNull DataSpec dataSpec) throws IOException {
    bytesSinceOpen = 0;
    // ExoPlayer's own load retry after a dropped connection reopens at the byte
    // position it had reached. A live server ignores the Range and sends "now"
    // (HTTP 200), and DefaultHttpDataSource then reads and discards that many
    // bytes to honour the position: everything received since the channel
    // started, hundreds of MB after a while, so the picture froze (+559
    // connection cut test). Ask for the stream from its start ("now") instead.
    boolean liveRetry = unknownLength && live() && dataSpec.position > 0;
    if (liveRetry) {
      note("reconnecting live stream (no skip of " + dataSpec.position / 1024 + " KB)");
      dataSpec = dataSpec.buildUpon().setPosition(0).setLength(C.LENGTH_UNSET).build();
    }
    // The first connection fails normally (dead channel = error screen at once);
    // a reconnect (this stream already delivered data) gets a few tries.
    boolean retry = live() && stats.bytes.get() > 0 && dataSpec.position == 0;
    IOException last = null;
    int attempts = retry ? ATTEMPT_DELAYS_MS.length : 1;
    for (int i = 0; i < attempts; i++) {
      if (ATTEMPT_DELAYS_MS[i] > 0 && i > 0) {
        try {
          Thread.sleep(ATTEMPT_DELAYS_MS[i]);
        } catch (InterruptedException e) {
          Thread.currentThread().interrupt();
          throw new InterruptedIOException();
        }
      }
      try {
        long length = upstream.open(dataSpec);
        unknownLength = liveRetry || (length == C.LENGTH_UNSET && dataSpec.position == 0);
        if (retry && i > 0) note("reopened on attempt " + (i + 1));
        return liveRetry ? C.LENGTH_UNSET : length;
      } catch (IOException e) {
        last = e;
        try {
          upstream.close();
        } catch (IOException ignored) {
          // Nothing open.
        }
        if (e instanceof InterruptedIOException) throw e;
        if (e instanceof HttpDataSource.InvalidResponseCodeException) {
          int code = ((HttpDataSource.InvalidResponseCodeException) e).responseCode;
          if (code == 404 || code == 410) break;
        }
      }
    }
    if (retry) note("reopen failed: " + reasonOf(last));
    throw last;
  }

  @Override
  public int read(@NonNull byte[] buffer, int offset, int length) throws IOException {
    int n;
    try {
      n = upstream.read(buffer, offset, length);
    } catch (IOException e) {
      // Left to ExoPlayer's own load retry (reopens ~1 s later and carries on in
      // the same stream: near invisible when the provider's feed continues).
      // Ending the copy here instead (+558) froze 2.5 s on a cut connection.
      if (unknownLength && live() && !(e instanceof InterruptedIOException)) {
        note("connection lost (" + reasonOf(e) + ") after " + bytesSinceOpen / 1024
            + " KB, player retries");
      }
      throw e;
    }
    if (n == C.RESULT_END_OF_INPUT) {
      if (unknownLength && live()) {
        note("server closed after " + bytesSinceOpen / 1024 + " KB");
      }
      return n;
    }
    bytesSinceOpen += n;
    return n;
  }

  private void note(@NonNull String what) {
    Log.w(TAG, what);
    stats.lastReconnect = what;
  }

  @NonNull
  private static String reasonOf(@Nullable IOException e) {
    if (e == null) return "?";
    if (e instanceof HttpDataSource.InvalidResponseCodeException) {
      return "HTTP " + ((HttpDataSource.InvalidResponseCodeException) e).responseCode;
    }
    Throwable cause = e.getCause() != null ? e.getCause() : e;
    return cause.getClass().getSimpleName();
  }

  @Nullable
  @Override
  public Uri getUri() {
    return upstream.getUri();
  }

  @NonNull
  @Override
  public Map<String, List<String>> getResponseHeaders() {
    return upstream.getResponseHeaders();
  }

  @Override
  public void close() throws IOException {
    upstream.close();
  }
}
