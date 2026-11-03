# IPTV Editor (plan, 2026-11-02, not started)

An in-app playlist editor: clean up provider lineups (rename, logos, duplicates, dead
streams, countries) and the EPG, with the heavy editing done from the user's phone or PC.
Everything stays on the device: the app never hosts a rewritten playlist or a user's
provider login (that would make VesperTV a content relay).

## Prior art to reuse

**Already in the app** (the editor builds on these, it doesn't replace them):
- Hide channels / groups, hide a playlist's groups per tab (`keyHiddenPlaylistGroups`).
- Own groups across playlists (`services/user_groups.dart`), Move Up/Down (`nox_channel_order`),
  favourite order across playlists.
- EPG matching / channel linking, custom EPG URL, backup servers + failover.
- `channelCopyKey` (`utils/channel_name_matching.dart`): groups copies of one channel by
  dropping 4K/FHD/HD tags, keeps the region tag. `distinctCopiesFirst` in Sports.
- Real 4K tag (`services/real_4k_channels.dart`): resolution measured from real playback.
- From phone pairing (LAN + relay) for sending data from a phone browser to the TV.

**Reference only: the owner's private server-side cleanup test** (outside this repo,
built for his own proxy users; don't copy its server details here). Owner, 2026-11-02:
a suggestion, not a spec; do better where possible. Its identity edge cases are worth
keeping as test cases for our own matcher:
- Station identity = country prefix (`CA|`, `US|`…) + name folded (accents, case,
  spacing, `+` -> PLUS) with only the quality tags FHD/HD/SD removed.
- Region, language, East/West, +1, channel numbers, Extra/PPV/event names stay part of
  the identity: "TSN 1" and "TSN 2", "CTV East" and "CTV West" are never duplicates.
- A shared EPG id alone never proves two channels are the same (providers reuse ids).
  A name alias (ARTV = ICI ARTV) counts only when it's an explicit pair **and** both have
  the same non-empty EPG id.
- Rank FHD > HD > SD > unlabelled. UHD/4K/8K copies are kept, not ranked away, until
  policy says otherwise (labels lie; see probing below).
- A tie at the top rank (two "FHD" copies) = keep both and show it for review.
- Separator rows (`##### SPORTS #####`) are removed by a pattern.
- **Guide retention check:** if the copy being hidden has future guide data and the
  kept one has none, flag it (or move the guide link to the kept copy) before applying.
- Preview first (counts before/after per group, every hidden pair with its reason), then
  apply.
- Its known weakness: exclusions are static, so newly renamed provider channels need a new
  run. **In the app, rules are re-applied on every content update** instead.
- The tool covers a server the owner controls; most VesperTV users have no proxy, so the
  in-app editor is the client-side version of the same idea.

## Data model: an edit layer, never rewriting provider data

Per viewer (like own groups), carried by Backup & Transfer, keyed by composite `Channel.id`
(`playlistId::rawId`; ids are made unique by `Channel.withUniqueIds`):
- **Overrides:** display name, logo URL, group (own groups already), hidden, order.
- **Rules:** ordered list, re-run after each content update and on edit:
  rename (find/replace or regex, e.g. strip `US| `), hide by country/group/keyword,
  keep-best-copy, remove separators, hide dead streams.
- Manual override > rule > provider value.
- **Sports matching, EPG lookups and search keep using the provider name / `epgId`**;
  only the display uses the override. A user rename must never break game matching.
  Search matches both names.
- Rule results are computed at load time into a cache (one pass over the live list,
  like `withUniqueIds`); never per row per build.

## Phase 1: TV quick edits
- Hold OK on a channel > **Rename** / **Change logo** / **Reset**.
- Every display site reads the override: live list, Timeline guide, player bar/info card,
  side panel, search, Multiview picker, recordings, favourites.

## Phase 2: phone / PC editor
- Settings > Playlists > **Edit on phone or PC**: QR + code (same pairing as From phone).
  The TV serves the edit page over LAN (relay path later, encrypted like Transfer).
- Page: searchable table of channels per playlist/group, multi-select, bulk
  hide/move/rename/logo, rules editor with live preview ("142 channels match").
- Saves go to the TV as one edit-layer document; TV applies and confirms.
- Windows: the same page opened in the PC's browser, or directly in the app window.

## Phase 3: quality and duplicates

Better than hide-the-rest (what server-side cleanups do): **collapse copies into one
channel row** and let the app pick which copy plays.

- **One identity function** for the whole app: extend `channelCopyKey` (already used by
  Sports) with the edge cases above, and use it for the editor, Sports, Multiview and
  failover. Never a second, separate matcher.
- **Collapse copies** (switch, per playlist or across playlists): the live list and guide
  show "TSN 1" once; hold OK > Choose copy lists them (4K, FHD, HD, which playlist).
- **Best copy = quality and reliability**, not the label alone. The app learns from
  every real playback, with no probing: measured resolution/fps/HDR (the Real 4K tag,
  extended to all sizes), time to first frame, rebuffers, errors and restart loops per
  copy (rolling, local). A "4K" that buffers every minute loses to a solid FHD.
- Before any data exists, rank by label (user-ordered, default 4K > FHD > HD > SD >
  unlabelled); measured data replaces the guess as it comes in.
- **Automatic inline failover** (FHD fails -> HD plays, no error screen, no user action):
  a new step `_retryOnCopies` in `PlaybackService`, modelled on `_retryOnBackupServers`
  (same "is it still the current channel?" checks after every await, same 3 s spacing,
  `reconnectStatus` "Trying the HD copy (2/3)…", then a short "Playing the HD copy" note).
  - Order: backup servers for the same copy first (same stream, other host), then the
    next copy, then the next.
  - **Unlike backup servers, decoder errors DO move to the next copy:** a box that can't
    decode a 4K HDR HEVC copy can usually play the FHD one. That's the case where this
    helps most (Formuler/Fire Stick 4K failures).
  - Also mid-stream: when the restart-loop cap fires (`_watchRestartLoop`), or a dead
    link (404/410), go to the next copy instead of the error screen.
  - **Connection limit:** a copy on the same provider account must release the failed
    player **before** opening the next one (1-connection accounts would reject it).
    Only a copy on another playlist/account may be built before dropping the old one
    (the backup-server "build first" pattern).
  - The requested channel stays `currentChannel` (guide, zapping, history, favourites,
    EPG, Sports pick); the copy actually playing is separate, like catch-up's
    `liveChannel`. The badge/Data pool show which copy and quality is playing.
  - The failure counts against that copy's reliability, so next time the best working
    copy is tried first; a recovered copy earns its place back over time.
  - Stops after every copy has failed once (no loops), then the normal error screen.
  - Per-device switch in Settings > Playback ("Switch to another copy when a channel
    fails", on by default) and per-channel off in the editor.
  - Windows needs its own version in `DesktopPlayerScreen` (separate stack).
- A user's explicit copy choice is kept (like Sports saved picks).
- **Manual fallbacks for any live channel**, same pattern as Sports' Add sources
  (`_addSources` in `sports_screen.dart`: picker from All channels / My lists, user
  choices keep their own label): hold OK on a channel > **Fallback channels** > add any
  channel from any playlist, even a different name or feed (e.g. "TSN 1" from another
  provider, or "TSN 4" as a last resort), and order them.
  - Failover order: user's pick > manual fallbacks in their order > automatic copies
    (best first). The automatic copies still apply after the manual list, unless the
    user turns them off for that channel.
  - Also the manual swap: in the player, hold OK / the info card > "Switch to fallback",
    one press per step, like Sports' pick/swap.
  - Stored in the edit layer by composite `Channel.id`; a fallback whose channel is gone
    after an update is skipped (and shown as missing in the editor), never deleted.
  - Sports keeps its own scoped sources (game/team/league); when it plays a channel
    that has editor fallbacks, those apply too.
  - The phone/PC editor shows fallbacks per channel and lets the user drag them in order.
- **Duplicates view** in the phone/PC editor: each station with its copies, labels,
  measured quality, reliability, dead/working; merge or split a wrong grouping there
  (manual merges/splits override the identity function).
- Still possible: really hide a copy (the user's choice), or hide dead copies.

### Optional stream test (probing), opt-in with a warning
- Warning before starting: "Testing opens each stream one at a time. If your provider
  allows only 1 connection, or watches for unusual activity, your account could be
  suspended. Continue?"
- Xtream: read `user_info` `max_connections` / `active_cons` first and show them; refuse
  while a connection is in use (someone watching elsewhere).
- Never while this device is playing, recording or in Multiview.
- Strictly sequential, 2-3 s pause between streams, a few seconds per stream:
  HLS = master playlist `RESOLUTION`/`FRAME-RATE` (often no video bytes needed);
  TS = read ~1 s, parse the SPS/PMT for codec, size, fps, HDR without a decoder.
- Only duplicate groups or a user selection; show count + estimated time first.
- Auto-stop on HTTP 401/403/429, "max connections" replies, or several failures in a row.
- Stoppable, resumes where it stopped; the phone/PC page can start it and watch progress.
- Results per channel, dated (stale after ~30 days): "1080p 50fps", "4K HDR", "dead".
  They seed the same per-copy quality data as real playback (catches fake 4K early).
  Most users never need it: passive learning fills the data in as they watch.

## Phase 4: EPG filtering
- **Prune the guide to kept channels:** skip programmes of hidden/filtered channels when
  importing into `EpgDatabase` (big win on weak Fire Sticks: smaller DB, faster Update EPG).
  Re-showing a channel needs an EPG refresh (say so in the UI).
- **EPG source per channel / per group** when several guides cover it.
- **"No guide data" filter** with a jump to the existing EPG matching.
- Days to keep per playlist, never below what catch-up needs (7 days past for catch-up ids).

## Phase 5: merged lineup
- One curated "My lineup" across playlists: own groups + keep-best across providers,
  other providers' copies as failover.

## Optional: export
- Export the edited lineup as an M3U file to local storage (no hosting). Contains the
  provider's stream URLs with credentials: warn before saving, never upload it.

## Open questions for the owner
- Edit layer per viewer (like own groups) or per device?
- Probing on Windows too (media_kit path) or Android only first?
- Should Collapse copies be on by default for new playlists (preview shown once)?
