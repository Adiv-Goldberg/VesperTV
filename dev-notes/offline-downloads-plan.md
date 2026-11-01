# Offline downloads (plan, not started)

Owner request (2026-11-01): let users download movies/episodes and watch them with no
internet (plane, car). Built on the Recording infrastructure (1.0.32), but simpler: a VOD
title is one finite file, so it is a resumable HTTP download, not a live capture.

## Scope
- **Phase 1 — Android phones/tablets** (TV boxes get it too, but they are not the target).
  IPTV movies + episodes (Xtream / M3U VOD) and Media Hub titles (add-ons, debrid,
  Jellyfin/Emby/Plex direct streams).
- **Phase 2 — Windows** (laptops on a plane). Separate playback stack (`media_kit`), so a
  Dart-side downloader + its own Downloads screen; features built twice as usual.
- Not in scope: live channels (that is Recording), catch-up, transcoding, DRM'd anything.

## User-facing behavior
- **Download** button on movie pages, episode rows and Media Hub detail pages; hold OK on
  a poster / episode adds it to the menu. Series page: **Download season** (queues episodes
  in order) and "Download next N episodes".
- Media Hub with several streams: the stream picker opens first (show size; warn above a
  configurable size, e.g. a 47 GB remux).
- **Downloads** tab/row (next to Recordings, same card style): progress, speed, ETA,
  Pause / Resume / Cancel / Delete, "Waiting for Wi-Fi", "Link expired — retrying".
- Finished items play from the local file in the normal player: resume points, skip intro
  (if segments were cached), subtitles, Data pool.
- Settings > **Downloads**: storage location (app storage / USB / SD, shared with
  Recording), Wi-Fi only (default on for phones), max simultaneous downloads (default 1),
  storage cap, auto-delete after watched (off by default).
- Notification while downloading (foreground service), translated strings via `tr()`
  (notification text in Recording is English only — fix both here).

## Architecture (Android)
- **Native:** new `DownloadService.kt` (or a download mode in `RecorderService.kt` if that
  stays clean) — foreground service, wake + Wi-Fi lock, `Range` requests to resume, writes
  `<id>.part` then renames. Checks free space before start (reuse the Recording/updater
  free-space rules: need file size + margin; stop at 1 GB free). Reuse the recorder's
  storage-location code. Channel: `vespertv/downloads` (start, pause, cancel, list,
  progress events).
- **HLS VOD** (rare): reuse the recorder's HLS segment loop, write a local `.ts`.
- **Dart:** `services/download_service.dart` — queue + metadata in device-only
  `downloads.json` (title, poster/backdrop cached locally, type, series/season/episode,
  source playlist / Media Hub ids, IMDb/TMDB ids, size, local path, subtitle files, state).
  Never transferred/backed up as files (Transfer/Backup skip the key, like recordings).
- **Playback:** a transient channel with a `file://` URL, `isLive = false`, same ids as the
  original title so resume positions and tracker scrobbles match the online copy.
- **Artwork:** save poster/backdrop next to the file; the offline UI must not touch network
  images.

## Hard parts (decide/solve before coding)
1. **Offline cold start.** Today the splash waits on catalog pre-load, EPG, update check,
   device-defaults fetch, sports polling. With no network the app must detect offline fast
   (connectivity check + short timeouts), skip the waits and offer **Downloads** directly
   ("You're offline — Watch downloads"). Every startup network call needs a timeout that
   can't hang the splash. Test this first, on a phone in airplane mode, before building UI.
2. **Provider connection limits.** A download holds one provider connection for its whole
   duration. On 1-connection accounts (most behind Tuliprox) watching anything from that
   account kicks the download (or vice versa). Show the Recording-style conflict popup;
   offer "Pause download while watching". Media Hub/debrid downloads don't have this issue.
3. **Expiring links.** Debrid/add-on URLs expire. Resolve with `stream_resolver.dart` at
   start; on 403/404/410 during resume, re-ask the source for a fresh link matching the same
   file (reuse the Media Hub resume-file matching: filename/videoHash/size) and continue the
   `.part` only if the size matches, else restart.
4. **Uncached debrid clips.** Reject anything that looks like the "being downloaded" clip
   (`ArchiveReadyWatch` rules: < ~90 s / tiny size); offer "Download when Ready".
5. **Subtitles.** Embedded tracks come with the file. Add-on subtitles: fetch the preferred
   language(s) at download time and store `.srt` files; the subtitle menu lists them offline.
6. **Trackers offline.** Queue Trakt/Simkl start/stop/watched events in `downloads.json`
   (or a small outbox) and flush when back online. Never block playback on it.
7. **Storage on TV boxes.** Small internal storage (Fire Stick ~8 GB usable): default to
   USB when present; refuse files that don't fit.
8. **Legal/positioning.** Same as the rest of the app: users' own sources, nothing shipped.
   Don't add download buttons to anything the source marks as not downloadable (Plex
   `allowSync=0`, if exposed).

## Order of work
1. Offline cold-start path + "You're offline" screen (works even with zero downloads).
2. Native downloader (progressive HTTP, resume, free space, pause/cancel) + channel.
3. Dart queue/metadata + Downloads screen + local playback (resume, ids).
4. Download buttons: IPTV movies/episodes, then Media Hub (stream picker, link refresh).
5. Subtitles + tracker outbox + artwork caching.
6. Season download, Wi-Fi only, auto-delete, settings page, remote tips page + help index.
7. Windows (phase 2).

## Testing
- Phone in airplane mode: cold start, Downloads, play, resume, subtitles.
- Kill the app mid-download, reboot, switch Wi-Fi → mobile data (Wi-Fi only pauses).
- Debrid link expiry (leave a download paused overnight).
- 1-connection IPTV account: download + watch live → conflict popup.
- Fire Stick: low storage, USB stick.
