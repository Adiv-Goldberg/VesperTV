# Media Hub experience update

Implemented on `codex/media-hub-experience`, based on release commit `84256c1`.
This follows the three delivery groups in [the Nuvio investigation](nuvio-media-hub-investigation.md).
Changes remain local for review. The release version and Windows build are unchanged.

## Source selection and playback

- Play opens the source picker immediately. Up to three metadata requests run
  concurrently; usable files appear while slower sources continue loading.
- Each source shows Loading, Ready, No streams, or Retry. Retry uses the same
  bounded queue. Arriving results append without moving the highlighted file.
- Completed searches are cached in memory for two minutes, with a twelve-session
  limit. Sessions include the viewer generation, episode, and playback-source
  configuration. Profile changes and source changes invalidate old work.
- The in-player Sources drawer also consumes progressive results and retains
  both the playing file and the highlighted file as new replies arrive.
- Stream rows show advertised formats, file size, and available subtitle count.
  Row identities hash URLs and headers rather than exposing them in widget keys.
- The picker gear, or Media Hub > Customize > gear, opens profile-scoped playback
  preferences: automatic selection, preferred source/audio language, maximum
  quality, and Prefer SDR. Automatic selection stays off by default. Unknown
  language/quality does not silently satisfy an explicitly configured constraint.
- Exact remembered resume choices remain preferred. Next Episode first retains
  an available release group from the same source; a missing group or lack of
  suitable alternatives returns to manual selection. Existing Auto Largest is
  retained and respects the new selection constraints.
- Add-on request headers reach Android playback and resume/redirect probes.
  Transport-owned/malformed headers are rejected; credential headers are removed
  across origins. Redirect resolution returns the headers valid at the final
  destination. Playback headers remain in memory, outside channel history.
- All supplied sidecar subtitles, including languages, are retained and offered
  in the existing subtitle menu. Preferred subtitle language also works when the
  playing stream supplies subtitles and no subtitle add-on is enabled.

Main implementation: `archive_stream_session.dart`,
`archive_playback_preferences.dart`, `archive_stream_picker.dart`,
`archive_source_drawer.dart`, `archive_playback.dart`, `archive_service.dart`,
`stream_headers.dart`, and the existing player/subtitle integration.

## Library and row personalization

- Codex 2026-10-29: movie/series title pages add Customize title page beside
  Explore more. Collection / related / cast rows can be reordered, including
  Cast and credits first. Order is per viewer (`vesper_archive_detail_rows`),
  transfers with Hub data, and retains missing rows' positions for other titles.
  The default stays collection / related / cast. Dialog Save restores Explore
  more focus; directional traversal follows the visible order. This does not
  move the series episode section or change TMDB-key requirements.

- Media Hub has Continue watching and Upcoming episodes rows in addition to the
  existing Recently watched/Favourites rows. Cards identify the episode, progress,
  and Resume/Next action; unaired episodes stay outside the playback queue.
- Home Continue Watching uses the same title/episode selection. Progress refreshes
  after returning from playback, including the player's deferred final save.
- Source-specific channel IDs stay intact. Profile-scoped aliases migrate
  existing progress, fractional resume state, and remembered file fingerprints
  into canonical IMDb/TMDB identities where a reliable mapping exists.
- A later IMDb mapping can join earlier TMDB-only progress. Custom content types
  and local IDs without reliable global mappings retain their source namespace.
- History and favorites deduplicate mapped titles across catalogs. Episodes keep
  season/episode identity. Migration is batched for a series, avoiding a separate
  preference-map rewrite for each episode.
- Existing history acquires episode details lazily. The history JSON and parsed
  metadata are reused during builds; this does not scan the full catalog.
- Customize, at the end of the Media Hub toolbar, provides Show/Hide, Pin, Move,
  and Rename. Hidden rows remain in that editor so they can be restored. Playback
  sources remain enabled when their catalog rows are hidden. Row settings belong
  to the active viewer and transfer with Media Hub data.
- The row hold menu exposes these actions as well. Hold on a Continue Watching
  title uses the existing confirmed history-removal flow.

Main implementation: `archive_library.dart`, `archive_service.dart`,
`storage_service.dart`, `archive_row_settings.dart`, `archive_screen.dart`, and
`home_screen.dart`.

## Discovery and search

- Movie and Media Hub series pages provide collections/franchises, related
  titles, and cast credits using the existing user-supplied TMDB key.
- Selecting an actor opens movie/TV credits. Selecting a recommendation resolves
  its identity on demand and uses an available playback source. Server libraries
  can be searched for the selected title beyond the catalog pages already loaded.
- Without a TMDB key, matching genres in loaded catalogs provide a local
  discovery fallback, with an entry to the existing TMDB settings page.
- Supplemental metadata loads after the main title and does not block Play.
  D-pad navigation explicitly crosses the discovery rows; Back restores the
  originating card. Credits and recommendation cards handle remote OK directly.
- Media Hub and global search publish cached/network matches progressively,
  use request generations, and stop queued work for stale queries/profiles.
  Requests already in flight can finish but their stale results are discarded.
- Once the user enters a search row, additional matches append without replacing
  the focused title. Unfocused result rows can retain normal relevance ranking.
- The search Sources control shows per-source states and filters results.
  Catalog refresh uses three workers and prioritizes the focused rows, while
  retaining the existing cache-first presentation and lazy poster lists.

Main implementation: `archive_discovery_service.dart`,
`archive_discovery_panel.dart`, `archive_service.dart`, `archive_screen.dart`,
`search_screen.dart`, and the shared movie/series detail pages.

## Validation

- Full Flutter suite: **935 passing**; logs in `build/media-hub-all-tests.log`.
- Analyzer: the existing **16 info-level issues**, no warnings/errors.
  `flutter analyze --no-pub --no-fatal-infos`; `build/media-hub-analyze.log`.
- Android debug APK builds successfully (69.8 s). Artifact:
  `build/app/outputs/flutter-apk/app-debug.apk`; `build/media-hub-android-build.log`.
  This is a compilation smoke check, not a signed release/install build.
- Tests cover slow/failed add-ons, queued retries, profile invalidation, header
  redirects, subtitle choices, migration across catalog IDs, later IMDb mappings,
  exact episode resume, future episodes, row settings, progressive/stale search,
  discovery metadata, server-title lookup, and D-pad focus/Back restoration.
- UI checks include TV and phone dialog sizes and real-font fixture previews:
  `build/media-hub-stream-picker.png`, `build/media-hub-discovery.png`.
- No Formuler/Fire Stick installation or Windows build/run was performed.
  Real provider playback, device subtitle rendering, and metadata with the
  owner's TMDB account still need their normal device smoke check.

Suggested device check: open Media Hub, start a title with multiple sources,
choose an early result, open Sources during playback, resume a series from Home,
hide/restore/reorder a row, and browse a collection and an actor's credits.

## Claude follow-up (2026-10-29, test +517)

- Windows parity: add-on request headers now reach media_kit (`Media(httpHeaders:)`
  in `DesktopPlayerScreen` open/reload and `DesktopMiniPlayer`); the Windows
  subtitle menu offers stream-supplied subtitles even with no subtitle add-on
  (same rule as Android `player_controls`). Windows still not built or run.
- The 41 new UI strings had no entries in fr/es/it/el: added (machine-authored).

## Design reference: Nuvio home (owner, 2026-11-01)

Screenshot: `dev-notes/references/nuvio-media-hub-home.png` (Nuvio on a TV). What to take from it:
- **Hero = the focused title**, backdrop on the right ~60% fading into black to the left and
  bottom; no separate hero card. Text sits over the dark left part.
- **Title as logo art** (stylised "CLAYFACE" clearlogo) instead of plain text; fall back to
  text when there is no logo. `ArchiveMeta.logoUrl` already reads the add-on/Cinemeta `logo`.
- **One metadata line:** `Movie • Horror • 2026` + a yellow **IMDb 7.6** badge, then a
  4-line description with ellipsis.
- **Focused card expands to landscape:** the focused poster becomes a wide backdrop card
  with the title logo on it and a white outline; the rest of the row stays portrait posters.
- Rows titled "Trending Movies - Movie" / "Trending Series - Series"; the next row peeks
  at the bottom so users see there is more.
- Slim left icon rail (Home, Search, Library, Settings), no labels.
Watch on weak boxes: the expanding card changes row geometry (keep `itemExtent`/focus maths
exact, see the 1.0.31 `_cardExtent` fix) and the hero backdrop swap must stay
dark -> backdrop without a poster flash (`_focusedArtPending`).

**Done (Claude, 2026-11-01, uncommitted, no APK yet):**
- `ArchiveMeta.logoUrl` (`logo`, cached in toJson) + getter `logo` (falls back to MetaHub
  `images.metahub.space/logo/medium/{imdb}/img` by IMDb id; may 404). Jellyfin/Emby ask for
  `Logo` images. Plex: no logo (name shown).
- Hero (`archive_screen.dart`): 200 px tall on TV (150 phone), `_HeroTitle` logo with the name
  as fallback (failed logo URLs remembered for the session), `_HeroInfoLine` "Movie • Horror •
  2026 • runtime" + yellow IMDb badge (media servers: star, their rating is a community one) +
  source chip, 4-line description. Backdrop area grew (left 30 %, 70 % of the height).
- Focused card wide: `PosterCard.wideWidth/wideImageUrl/wideLogoUrl`, 16:9 at poster height
  (`PosterCard.wideCardWidth`), logo bottom-left, zoom 1.04. Only the focused card of the
  focused row, only with a backdrop, only at widths >= 700. Rows use `itemExtentBuilder`
  (cached per row, `_extentBuilder`) — never switch to `itemExtent` (sliver type change drops
  focus). `_focusCard` maths assumes cards before the focused one are normal slots; a
  post-frame `_revealCard` fixes the clamp near a row's end. Test: `archive_wide_card_test.dart`.
- Not done: Nuvio's slim icon rail (ours keeps Movies / TV Shows / catalog jumps).
- Device check pending: decode cost of the backdrop on each Right on the Fire Stick.
- **Rail redesign (2026-11-01, owner):** the left rail is the top bar's glass pill stood up (`_glassPill`,
  `_BarButton(expand, alignStart)`), 250 px wide. Search moved into it (top): OK pulls out a small
  Movies / TV Shows menu beside it (`_pickSearchType`, `showRollDownMenu` with a side anchor),
  then opens that category's search. The top bar keeps Newest, row jumps, Genre, Customize, and
  (only while a search is active) Sources + a Clear button labelled with the query. Phones keep
  Search in the top bar (`_narrow`). Test: `archive_rail_search_test.dart`.
- **Collapsing rail (2026-11-01, owner: "way too big"):** the rail is open (240 px, labels) only while it
  has focus or Search's pull-out is up (`_railOpen`, `_railPinned`); otherwise an 80 px icon strip.
  Open, it pushes the hero/rows aside (`Row` + `AnimatedContainer`); never over the posters (owner,
  +553 photo: the overlay showed the hero text and rows through the glass). Glass stays see-through.
  80 px = an entry with its label still fits at the start of the open animation (no overflow).
