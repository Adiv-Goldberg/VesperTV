// VesperTV patch: native Multiview tiles (MethodChannel "vespertv/multiview_tiles"). Only used
// while the native video surface is on (Flutter window transparent, see NativeVideoSurface).
// Each Multiview screen's player draws into its own plain SurfaceView behind the Flutter view
// instead of a Flutter texture; Dart's NativeTileHole clears the tile's rect and reports it here.
// Why: through textures every decoded frame of every tile went through Flutter's raster thread.
// LOG-C47KFD: 1 tile 60 fps, 2 tiles 44/25 fps, 3 tiles ~7 fps each, while the decoder plays
// 4K60 full screen. A SurfaceView goes straight to the display compositor.
// The surface belongs to the player, not to the grid slot: Swap mode and full screen only move it.
package io.flutter.plugins.videoplayer;

import android.app.Activity;
import android.util.Log;
import android.view.Gravity;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

final class MultiviewTiles implements MethodChannel.MethodCallHandler {
  private static final String TAG = "VesperMultiviewTiles";

  private final MethodChannel methods;
  @Nullable private Activity activity;
  /** Texture-view creations still owed a tile (Dart's "nextIsTile" before each initialize). */
  private int pendingTiles = 0;
  private final Map<Long, SurfaceView> tiles = new HashMap<>();
  /** Last rect per tile, {left, top, width, height}; absent = off screen. */
  private final Map<Long, int[]> rects = new HashMap<>();

  MultiviewTiles(@NonNull BinaryMessenger messenger) {
    methods = new MethodChannel(messenger, "vespertv/multiview_tiles");
    methods.setMethodCallHandler(this);
  }

  void dispose() {
    methods.setMethodCallHandler(null);
    for (Long id : new ArrayList<>(tiles.keySet())) removeTile(id);
  }

  void setActivity(@Nullable Activity activity) {
    if (this.activity == activity) return;
    // Players keep running across a config change; their surfaces can't follow to a new
    // activity, so they lose their output (the Multiview route is rebuilt anyway).
    for (Long id : new ArrayList<>(tiles.keySet())) removeTile(id);
    this.activity = activity;
  }

  /**
   * Called by createForTextureView: a SurfaceHolder for this new player when Dart asked for a
   * tile, else null (a normal texture player).
   */
  @Nullable SurfaceHolder claimTile(long id) {
    if (pendingTiles <= 0) return null;
    pendingTiles--;
    if (activity == null) {
      Log.w(TAG, "no activity: player " + id + " falls back to a texture");
      return null;
    }
    ViewGroup content = activity.findViewById(android.R.id.content);
    if (content == null) {
      Log.w(TAG, "no content view: player " + id + " falls back to a texture");
      return null;
    }
    SurfaceView view = new SurfaceView(activity);
    view.getHolder().addCallback(
        new SurfaceHolder.Callback() {
          @Override
          public void surfaceCreated(@NonNull SurfaceHolder holder) {
            Log.i(TAG, "tile " + id + " surface created");
          }

          @Override
          public void surfaceChanged(@NonNull SurfaceHolder holder, int format, int w, int h) {
            Log.i(TAG, "tile " + id + " surface " + w + "x" + h);
          }

          @Override
          public void surfaceDestroyed(@NonNull SurfaceHolder holder) {
            Log.i(TAG, "tile " + id + " surface destroyed");
          }
        });
    // Index 0 = behind the Flutter view, like NativeVideoSurface. Starts off screen (not GONE:
    // GONE destroys the surface) until Dart reports where the tile is.
    content.addView(view, 0, params(null));
    tiles.put(id, view);
    Log.i(TAG, "tile surface for player " + id + " (" + tiles.size() + " tiles)");
    return view.getHolder();
  }

  /** After the player released its decoder: the surface can go. */
  void onPlayerDisposed(long id) {
    if (tiles.containsKey(id)) removeTile(id);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    try {
      switch (call.method) {
        case "nextIsTile":
          pendingTiles++;
          result.success(null);
          return;
        case "setTiles":
          {
            List<?> list = call.argument("tiles");
            setTiles(list == null ? new ArrayList<>() : list);
            result.success(null);
            return;
          }
        default:
          result.notImplemented();
      }
    } catch (Exception e) {
      Log.w(TAG, call.method + " failed", e);
      result.error("multiview_tiles", String.valueOf(e), null);
    }
  }

  /** Every tile on screen now; any tile not listed moves off screen. */
  private void setTiles(List<?> list) {
    Set<Long> seen = new HashSet<>();
    for (Object o : list) {
      if (!(o instanceof Map)) continue;
      Map<?, ?> m = (Map<?, ?>) o;
      long id = num(m.get("playerId"));
      SurfaceView view = tiles.get(id);
      if (view == null) continue;
      seen.add(id);
      int[] r = {
        (int) num(m.get("left")), (int) num(m.get("top")),
        (int) Math.max(1, num(m.get("width"))), (int) Math.max(1, num(m.get("height")))
      };
      int[] old = rects.get(id);
      if (old != null && java.util.Arrays.equals(old, r)) continue;
      if (old == null || old[2] != r[2] || old[3] != r[3]) {
        Log.i(TAG, "tile " + id + " rect " + r[2] + "x" + r[3] + " at " + r[0] + "," + r[1]);
      }
      rects.put(id, r);
      view.setLayoutParams(params(r));
    }
    for (Map.Entry<Long, SurfaceView> e : tiles.entrySet()) {
      if (seen.contains(e.getKey()) || !rects.containsKey(e.getKey())) continue;
      // Off screen at its last size, so the surface isn't resized for nothing.
      int[] last = rects.remove(e.getKey());
      FrameLayout.LayoutParams p = params(null);
      p.width = last[2];
      p.height = last[3];
      e.getValue().setLayoutParams(p);
      Log.i(TAG, "tile " + e.getKey() + " off screen");
    }
  }

  private static long num(Object o) {
    return o instanceof Number ? ((Number) o).longValue() : 0;
  }

  private void removeTile(long id) {
    SurfaceView view = tiles.remove(id);
    rects.remove(id);
    if (view == null) return;
    ViewGroup parent = (ViewGroup) view.getParent();
    if (parent != null) parent.removeView(view);
    Log.i(TAG, "tile surface for player " + id + " removed (" + tiles.size() + " left)");
  }

  /** {@code r} = {left, top, width, height}; null = off screen (right of the display). */
  private FrameLayout.LayoutParams params(@Nullable int[] r) {
    if (r != null) {
      FrameLayout.LayoutParams p =
          new FrameLayout.LayoutParams(r[2], r[3], Gravity.TOP | Gravity.START);
      p.leftMargin = r[0];
      p.topMargin = r[1];
      return p;
    }
    FrameLayout.LayoutParams p = new FrameLayout.LayoutParams(16, 16, Gravity.TOP | Gravity.START);
    int screenW = activity == null ? 4000 : activity.getWindow().getDecorView().getWidth();
    p.leftMargin = Math.max(screenW, 1) + 16;
    return p;
  }
}
