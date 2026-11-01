# Sports tab — design + v1 status (2026-10-13)

Roadmap item from CLAUDE.md §13. **v1 is built and committed (test build 1.0.3+221 on the Formuler, not released)** — see "v1 as built"
right below; the rest of this file is the design and the tests behind it.

## v1 as built

### My Teams preferred channel (Codex, 2026-10-29)

Hold a followed team > Set preferred channel opens the existing single-channel
picker over the viewer's visible live channels, with search and playlist groups.
It works with no upcoming games. Automatic channel clears this team's preference
in its followed league. Existing per-match picks still override the default.
Storage reuses SportsChannelPicks.teams (league id + team id, composite channel
id), so profile isolation and Backup/Transfer already apply. Hidden/unavailable
channels stay outside matching. The team menu identifies an unavailable saved
channel and can replace/reset it. Completing or cancelling the picker restores
the team's focus; changed defaults force a rematch and invalidate older results.
See test/my_teams_preferred_channel_test.dart for storage/matcher/remote checks.

- Entry: a **Sports** row in the TV tabs column (under Multiview) opens `SportsScreen` full-screen
  (`lib/screens/sports_screen.dart`). Phone layout has no entry yet.
- Data: `SportsService` (ESPN scoreboard, key-less, one call per league per ESPN date; fetches the day
  either side and filters by *local* date; in-memory cache, 50 s freshness while a game is live).
  Leagues in `models/sports.dart` (`kSportsLeagues`): NHL, NFL, NBA, MLB, NCAAF, WNBA, MLS, EPL, UCL,
  LaLiga, Bundesliga, Serie A, Ligue 1. Logos via ESPN's resizer (~8 KB) and the `/500-dark/` variant
  (falls back to the normal logo on 404) so navy/black logos show on black.
- Matching: `SportsChannelMatcher` — user pick > event channel name (both team names, a date in the
  name must fit) > guide title (one SQL `LIKE` scan per day, `EpgService.findProgrammesByTitle`) >
  exact national-network name. Region bias ranks US/CA/UK feeds first, sinks foreign-tagged ones,
  and drops foreign networks ("RU: TNT"). Measured on trex_5 (57k channels): index 0.3 s on PC,
  32 games matched in 13 ms; NHL 18/18 today, NBA 7/12 (misses = tomorrow, no event channels yet).
- Manual: game dialog lists channels + "Choose a different channel" (chips for team names /
  league / networks, plus a text field) → "Just this game" or "Always for <team>"; stored per viewer
  (`vesper_sports_channel_picks`, game picks expire after 7 days). "Forget my pick" undoes it.
- UI: league chips (+ Edit leagues, Scores shown/hidden), day strip (Yesterday..+6), hero of the
  focused game with team-colour glow, rows Live now / Later today / Final. Explicit Up/Down zones.
- Standings: a centered **Standings** button between the day strip and the hero (was the last league
  chip — owner: hard to find; label names the filtered league, e.g. "NHL standings") opens
  `SportsStandingsScreen` (shared widgets live in `widgets/sports_widgets.dart`). Data:
  `site.api.espn.com/apis/v2/sports/{path}/standings` (note `/apis/v2`, not `/apis/site/v2`), 15 min
  cache, parsed off-isolate (`parseEspnStandings`). ESPN's entries are **not in table order** — sorted
  by `rank` (soccer) / `playoffSeed`, falling back to points/win % when seeds are all 0. Season label
  from the table's `seasonDisplayName` (top-level `season` says 2027 for a finished MLB 2026);
  "Preseason" only for non-soccer `seasonType == 1` (soccer always reports 1). College football
  repeats its stat set per split — keep the first (overall). NHL "Last Ten" has a trailing ", 0".
  Columns per sport, trimmed to fit the width; soccer zone stripes + legend from `note`. D-pad: league
  chips / conference chips / rows (explicit Up/Down, jumpTo scrolling), Left/Right on rows flips
  conference.
- Owner feedback round (2026-10-14, +217..+221):
  - Focus look = the app's gold sheen (`sportsFocusSheen`, same as `_SelectableRow`) on chips and
    cards; *selected* chip = gold text + faint outline, clearly quieter than focus.
  - Game card: **OK plays** the best match (user pick ranks first); no match → the game menu.
    **Hold OK** = game menu (other channels / pick / forget). A small hint under the focused card says
    "Hold OK to pick or swap the channel" (height always reserved, so rows don't jump).
  - Hold-opened menus must swallow the held press: the remote keeps sending Select *repeats* and the
    ambient ActivateIntent accepts repeats, so the menu's first item fired instantly ("hold does
    nothing"). `SwallowHeldActivate` (hold_to_activate.dart) wraps the game menu.
  - League chips: **hold OK = move mode** (‹ › arrows, Left/Right moves, OK/Back done, saved each
    step to `setSportsLeagues`); other chips dimmed + unfocusable meanwhile. Chips are **keyed by
    league id** — unkeyed, the reorder swapped focus nodes between States: focus lost and stale
    "focused" outlines (three at once). `SportsChip` also re-seeds `_focused` when its node changes.
  - Channel picker: the search field's own `FocusNode.onKeyEvent` maps Down → first result, Up →
    suggestion chips, OK → reopen keyboard (Back closes the keyboard but EditableText kept the arrows).
- **My Teams — built 2026-10-14 (+222..+225), owner approved.** On the real 1080p TV the details
  column is only ~300 logical px wide: game rows are three lines (opponent / date / channel) and the
  mini table uses short names and 36 px stat columns — don't widen them back into one line. Code:
  `sports_my_teams_screen.dart` (gets play/menu/match callbacks from `SportsScreen`, so picks and
  player are shared), `SportsFollows` (`sports_follows.dart`, prefs `vesper_sports_followed_teams`,
  `leagueId|teamId` per viewer), `SportsService.teamSchedule` + `parseEspnTeamSchedule`. Schedule JSON
  differs from the scoreboard: `score` is `{displayValue}`, record is `record[0].displayValue`
  ("2-1-0, 4 PTS"), logos in `team.logos[]`, broadcasts `{media: {shortName}}`, no team colours
  (the followed team's own is filled in). Soccer: default = played games only, `?fixture=true` =
  upcoming only → two calls, merged by id. Standings: OK or hold OK on a row = Follow/Unfollow
  dialog, star on followed rows. Original decisions:
  - Entry: a **My Teams** button next to Standings.
  - Layout: **team list on the left + details on the right** (like Standings). Rows: logo, name,
    record, next game. Details: record + standing line, a mini table around the team, the **next
    2 weeks** of games (OK to watch, hold to pick, same as cards). Details pane takes the **team's
    colours** (glow like the hero's `_TeamGlow`).
  - Adding: **from Standings** — hold OK on a team row → Follow/Unfollow. A "+ Add team" row in My
    Teams just opens Standings with that hint. (No separate team picker, no game-menu follow.)
  - **Star** followed teams' games on the cards and sort them first in Live now / Later today.
  - Data: `site.api.espn.com/apis/site/v2/sports/{path}/teams/{id}/schedule` = full season, with
    broadcasts, `team.recordSummary` and `team.standingSummary` ("7th in Pacific Division"), one call
    per team. Check the soccer variant (may need `?fixture=true` for upcoming games). Store followed
    teams per viewer as `{leagueId, teamId}`.
- Not yet: Sports Multiview, phone layout (only My Teams + Standings adapted in 1.0.6), BYOK providers, division view for standings.
- Reference (owner, 2026-10-14): **SportioTV** https://github.com/trenntl/SportioTV/releases/tag/v1.0.6
  has 81 leagues in its sports hub — investigated, see "SportioTV comparison" below.

## SportioTV comparison (2026-10-14)
Kotlin Android TV app (fork of OwnTV, GPL-3.0 like us), files under
`app/src/main/java/tv/own/owntv/features/sport/` (`SportsLeagues.kt`, `EspnApi.kt`, `SportsMatcher.kt`), doc `docs/SPORTS_HUB.md`.
- **Same data source as ours**: ESPN's key-less site API. No key, no backend. The "81 leagues" is a
  **static catalogue of ESPN slugs**. Only **16 are active by default**. The rest are metadata (no
  request until the user activates one) behind a "Manage all" page with search. Region tags
  (Europe/Americas/Germany/International/Rest) group them.
- Breakdown: **57 soccer** (top-2 tiers of big countries, NED/POR/TUR/SCO/BEL/AUT/SUI/GRE/RUS/DEN/
  NOR/SWE, MEX/ARG/BRA, JPN/CHN/AUS/IND/RSA, UEFA cups + super cup + Euro + Nations, FA/League Cup,
  DFB-Pokal, Copa del Rey, Coppa Italia, FIFA World Cup/WWC, AFC/CAF/CONCACAF, women's leagues + NWSL),
  basketball 5 (NBA, WNBA, Euroleague, men's/women's college), football 2, baseball 2 (MLB, college),
  hockey 1, golf 4 (PGA, LPGA, LIV, DP World `eur`), tennis 2, mma 2 (UFC, PFL), racing 2 (F1, NHRA),
  AFL, rugby (`rugby/270557`), cricket (`cricket/8039`), women's college volleyball.
- **Event sports** (`kind = EVENT`: golf/F1/UFC/tennis): competitors parsed from `athlete`
  (headshot/flag) instead of home/away teams. That's the same need as our planned PGA leaderboard.
- Matching: channel-name `LIKE` search on team abbrev/name/first word + broadcast words, plus EPG
  title in [start −2 h, +4 h]; scores +2/+2/+3/+5, no threshold, top 6. Our approach (provider event
  channel names first, see "Channel-matching test") is already stronger. Their good idea: pass the
  matched channels as the **zap list**, so CH+/CH− cycles through the channels showing that game.
- Their gotcha: standings must use host `site.web.api.espn.com` (`site.api` returned an empty body
  for them). Ours uses `site.api.espn.com/apis/v2/.../standings` and works. Keep this in mind if
  standings ever come back empty.
- **Built (1.0.7+235): League manager** — `screens/sports_league_manager_screen.dart`, opened by
  the Edit leagues chip. "Your leagues" = 13 base (`kSportsLeagues`, hide only) + added bank
  leagues (OK = show/hide, hold = send back to the bank); "League bank" = `kSportsLeagueBank`
  (63, grouped by `region`, `kSportsLeagueRegions`), OK = add + show. Two columns with explicit
  Left/Right on TV, one list on phones. Stored per viewer: `vesper_sports_added_leagues` +
  the existing shown/order list. `SportsLeague.hasStandings=false` (cups) keeps a league out of
  Standings. Empty day with one league selected → `SportsService.nextGameStart` (dateless
  scoreboard = current/next round) → "Next game: <date>" chip; the day strip grows a chip for
  dates past +6. **Bank vetting:** an ESPN feed can answer but be dead — CFL's newest event is
  the 2022 Grey Cup, Swiss Super League stopped Sept 2025; both removed. Check the default
  window's event dates (not just HTTP 200) before adding a league. Event sports: golf/UFC/PFL/F1/
  NASCAR/IndyCar added in 1.0.9 (see "Event sports" below); tennis not yet.
- **2026-10-23: English league tiers** - added EFL League One (`eng.3`, EFL1) and
  EFL League Two (`eng.4`, EFL2) to the England bank beside the existing Championship
  (`eng.2`). Premier League (`eng.1`) remains a base league; Carabao/EFL Cup is separate.
  ESPN scoreboard for 2026-10-24 returned 12/11 upcoming fixtures; both standings feeds
  returned 24 teams. League logos verified as `25.png` / `26.png`. Add through League manager.
- **Takeaway for us:** adding leagues is cheap: one `SportsLeague(espnPath: ...)` entry each (we have 13).
  To scale past a handful we'd need what they built: a lazy catalogue (active vs available), a
  searchable "all leagues" picker, and event-sport (athlete) parsing for golf/F1/UFC/tennis.

## Event sports (1.0.9+246, 2026-10-14)
`SportsLeague.kind` (`SportsKind.team|golf|racing|fight`) + `seriesPhrases`; bank regions Golf
(PGA `golf/pga`, LPGA, DP World `golf/eur`, LIV), Fighting (UFC `mma/ufc`, PFL), Motorsport (F1,
NASCAR Cup `racing/nascar-premier`, IndyCar `racing/irl`). Parsing in `sports_service.dart`:
- **Golf** (`_parseGolf`): one game per tournament, `SportsGame.end` = ESPN `endDate`; dated at
  US-Eastern midnight (`04:00Z`), so `_tournamentDay` shows it on every Eastern date start..end
  (not `sameDay`, which put it on the previous evening in California). Leaders top 5 with ties
  ("T2"), only once started; pre cards read "Oct 15 – 18" (`_preLabel`), no tee time exists.
- **Racing** (`_parseRacing`): one game per *session* (comp id), `FP1-3` skipped, `SS`/`SR`/`Qual`/
  `Race` → "Sprint Qualifying"/"Sprint"/"Qualifying"/"Race"; untyped single comp = Race.
- **Fight** (`_parseFightCard`): one game per card; the main event = the comp whose two last names
  are in the event name, else the last comp. Fighters are home/away (flag as logo, record, score
  "W"/"L" when decided); `SportsGame.first/joiner` read "A vs B" for non-team kinds.
- Golf/racing use placeholder sides (`_placeholderSide`, id '') + `SportsEventInfo` (title,
  session, venue, leaders): `_EventCardBody` / `_EventHero` in sports_screen.dart. Hide scores
  hides leaderboards.
- Matching: `_nameGroups` (team pair / fighter full+last names / event title + "x grand prix" or
  the last two words for golf), guide window `_guideWindow` (fights +5 h, golf = today while on),
  then series phrases (guide 70, channel names 60, max 3). Picks: event sports offer one
  "Always for {league}" (`SportsChannelPicks.seriesKey` = `league:*`).
- "Next game" for event sports queries a 60-day `?dates=a-b` range (the dateless scoreboard is the
  *last* event — UFC said "no upcoming games"); team leagues keep the dateless call (NHL range failed).
- **Standings:** racing only (`hasStandings: true`) — driver (athlete + flag) and F1 constructor
  tables, sorted by `rank`, one PTS column (`championshipPts`, constructors' `points` aliased);
  button "{name} championship"; no Follow on racing rows; hidden from My Teams' Add team.
  **Not done:** UFC rankings (ESPN's are frozen ~2021: Usman P4P #1), golf points race (core API:
  600 unsorted athlete `$ref`s — top 30 would need 30 extra calls). Owner: racing only for now.
- cdx, 2026-10-26: Boxing / WWE / AEW added to the Fighting bank on
  `codex/boxing-wrestling-events`. TheSportsDB IDs 4445/4444/4563; verified real upcoming/day
  responses, unlike ESPN boxing/wrestling endpoints (400/404). Name searches are truncated and
  misleading: these leagues all use sport Fighting, not Boxing/Wrestling. Free next returns one
  event; season/day responses are capped. Existing daily loading/rate limiting still applies.
- cdx: Combat parser reads strEvent (team fields are null). Clearly named boxing bouts use the
  UFC fighter layout; branded cards/WWE/AEW shows use event-title cards (SportsGame.isEventOnly),
  not fictional teams. Source status only; no inferred live/end/winners. Missing title/time omitted.
  Show aliases omit episode numbers for Raw/SmackDown/NXT/Dynamite/Collision channel matching.
  Existing manual picks, whole-series picks, preview/fullscreen and recording flows reused.
  No standings/My Teams; no full match card/results guarantee. Recording fallback length4h like UFC.
- cdx: Official WWE/AEW/TNA pages are alternative future schedule importers, not used here.
  Arena/taping times can differ from broadcast times; provider timings are not independently
  verified against TV schedules. Horse racing remains unimplemented.
- Lazy-list focus gotcha (fixed twice here): `requestFocus` on a chip/tile that a lazy `ListView`
  hasn't built does nothing — League manager `_bank` is now in screen (region) order; the Sports
  league chip row is a `SingleChildScrollView` + `ensureVisible`.

## CFL (2026-10-21)
- CFL is a **base league** beside NFL (`kSportsLeagues`, also in the new-install defaults),
  not a bank entry. Existing saved league selections still apply; CFL is available in Your leagues.
- `services/cfl_source.dart` uses CFL's own public feeds: scoreboard
  `https://cflscoreboard.cfl.ca/json/scoreboard/rounds.json`, team metadata
  `https://api.stats.cfl.ca/teams`, and official division standings
  `https://api.stats.cfl.ca/standings/<scoreboard season>`. ESPN's CFL feed remains frozen in 2022.
- The scoreboard is the whole season (~300 KB): one shared/in-flight snapshot for all dates,
  My Teams and next-game lookups. Refresh after 50 s live/near kickoff, otherwise 10 min;
  metadata once per session. Parsing runs off the UI isolate. Failed loads retain cached scores.
- **Team ids are abbreviations**, e.g. `MTL`: the two official APIs use different numeric ids.
  The stats API supplies division membership and ranking (including tiebreak order), with CFL
  points columns. Records on cards come from completed regular-season games only.
- Quarter states are `first_quarter`..`fourth_quarter`, `half_time`, `overtime`; `clock` is display
  text, `possession` is Home/Away. They are not just `playing`. Hidden scores stay hidden;
  unassigned TBD playoff fixtures are omitted. PNG logos come from the official scoreboard.
- Channel matching uses team/guide names with Canadian preference (no broadcaster list in the
  scoreboard). Follow, My Teams, next-game dates and recording use the same stable team/game identities.
- `services/cfl_game_stats.dart` parses CFL.ca's public Genius gametracker `teamStats` and
  `playerStats` widgets, using the scoreboard fixture id. Public route:
  `https://gsm-widgets.betstream.betgenius.com/v1/widget/<widget>/customer/democfl_light/locale/en-US/geolocale/any-?fixtureId=<id>`.
  No key/authentication. Team totals and the top eight players in each category appear in the
  shared stats dialog, including fullscreen left-arrow menu stats. Live summaries refresh every
  30 s; unavailable optional feeds retain previous detail or fall back to standings. No injury feed.
  Home/away order is explicit; player participation flags can be wrong, so actual stats determine
  inclusion. Verified against the completed Oct 17 Calgary–BC game, not an observed live game.
- Live observation on Oct 21: **no game in progress** (86 complete, 9 scheduled including TBD
  playoff slots; next games Oct 23). Quarter/halftime/OT behavior is covered by fixtures based on
  CFL's actual client schema; confirm live updates on a box during a real game.

## Goals
- A Sports tab with: **league filter** (NHL, NFL, NBA, MLB, PGA, ...), **My Teams**, **Standings**,
  scoreboard by day, game detail, and a **Watch** button that opens the matching IPTV channel.
- Zero infrastructure cost, no embedded API keys (open-source rule, CLAUDE.md §10).
- Works on Android TV / Fire Stick with a D-pad, on phones, and on Windows.

## Key decisions / findings
1. **BYOK is about keyed APIs only.** VesperTV has no server: every request goes device → provider,
   so a key-less source costs the project nothing either. Don't gate the whole tab behind a key; keys
   unlock *extra* leagues/detail.
2. **API-SPORTS has no WebSocket that we could find** — it is REST, polled. The earlier "use
   WebSockets to save the 100/day quota" plan does not hold.
3. **API-SPORTS quota is 100 requests/day per sport API** (hockey, american-football, basketball,
   baseball are separate hosts, same key) and per *key*, so every device using the same key shares it.
   A 3 h game polled every 60 s = 180 calls → free tier = minutes-old scores, not live.
   **Unverified: whether the free plan includes the current season** (sources conflict). Test below.
   API-SPORTS has **no golf** API.
4. **TheSportsDB is not keyless**: free v1 uses the shared public test key `123` (has changed before),
   30 req/min, heavily truncated results (team next events: 1, home only; day schedule: 3). Livescores
   and v2 are premium ($9/mo). Artwork is mostly fan-made, no stated licence → decorative only, cache
   it, always have a fallback (team initials on team colour).
5. **Fixed 30–60 s "spoiler delay" doesn't fit**: polling is coarser than the delay, and IPTV latency
   varies 5 s – 2 min+ (catch-up/timeshift break any fixed value). Use a **spoiler mode** (hide scores
   until a game is opened / hide the score of the game you're watching) + optional delay slider 0–120 s.
6. **Channel matching uses the user's EPG** (already in SQLite, `EpgDatabase`): find programmes
   overlapping the game start whose title contains both teams (name / nickname / abbreviation), rank
   channels by the API's broadcaster names (TSN, SN, ESPN, TNT, RDS, ...). Show best match +
   "Other channels"; allow a per-user override ("always this channel for team X").

## Provider plan
Pluggable providers behind one internal model, so a provider that breaks is one adapter to disable.

| Layer | Provider | Use |
|---|---|---|
| Default, no key | ESPN public JSON (`site.api.espn.com/apis/site/v2/sports/<sport>/<league>/scoreboard`, `.../standings`) — fallbacks NHL `api-web.nhle.com`, MLB `statsapi.mlb.com` | NHL/NFL/NBA/MLB/PGA/MLS/college: scores, standings, logos, **broadcasts** |
| BYOK #1 | API-SPORTS | Soccer + international leagues, deeper stats |
| BYOK #2 | TheSportsDB premium | Artwork, TV schedule, backup livescores |

Risk: ESPN/NHL endpoints are unofficial/undocumented (Home Assistant's TeamTracker relies on ESPN's).
MLB StatsAPI carries "individual non-commercial use" terms. Revisit if any of them breaks or objects.

```dart
abstract class SportsProvider {
  Set<LeagueId> get leagues;
  bool get needsKey;
  Future<List<Event>> scoreboard(LeagueId league, DateTime day);
  Future<List<StandingGroup>> standings(LeagueId league);
  Future<Event> eventDetail(String id);
}
```

Model: `League`, `Team`, `Event` (with a `competitors` list — **not** home/away only, so golf/F1/UFC
leaderboards fit), `Competitor`, `StandingGroup`. All times stored UTC, converted only for display.

## Request budget (keyed providers)
- One "games for date" call per league per refresh returns every game's score — never one call per game.
- Standings: once per day per league. Game detail: only on demand.
- Poll only while the Sports tab is visible or a My Teams game is live; pause when covered (`RouteAware`),
  backgrounded or asleep.
- Read the provider's remaining-quota response headers, back off automatically, and show
  "N updates left today". Quota exhausted = a real state ("limit reached, resets at …" + cached data).

## Key entry (TV-friendly — no QR code)
Owner: a QR code is impractical for a TV app. Instead:
1. **Need a key less often**: the default layer is key-less, so most users never enter one.
2. **Custom on-screen key pad** for TV (like `widgets/pin_pad.dart`): if the provider's keys are
   hex (API-SPORTS keys look like 32 hex chars — **verify**), a 16-key 0-9/a-f grid with big
   Backspace/Paste/Done is far faster than the system keyboard and sidesteps the Fire OS keyboard
   Back-button problem (CLAUDE.md §10). Physical number keys on the Formuler remote type digits
   directly. Show the key in groups of 4 so it's easy to check against the dashboard.
3. Phones/Windows: normal text field with paste.
4. Optional later: "On your phone or PC, open `http://<box-ip>:<port>`" — a tiny LAN page served by the
   app for pasting the key (typed address, no camera needed). Only if (2) proves insufficient.
- Validate the key on save with a status call (API-SPORTS `/status`; believed not to count against
  quota — verify), and show a clear error: invalid key / no access to this sport / current season not in plan.

## Security
- Store keys with `flutter_secure_storage` (Android Keystore, Windows Credential Manager), never
  SharedPreferences. Keys per app, not per viewer profile.
- Never log keys; redact them from URLs (TheSportsDB puts the key in the path) and request headers.
- Leave keys out of any export/backup; check Android `allowBackup`.
- No default/demo key in the repo.

## State / performance
- `SportsService` is its own `ChangeNotifier`; `TvHomeScreen` must **not** watch it wholesale (same
  rebuild trap as the EPG → use narrow signals like `guideRowsLoaded`).
- Cache scoreboards/standings/teams in sqflite (like `catalog_database.dart`); show cache first, then refresh.
- One shared HTTP client with timeouts and back-off; small cached logos (reuse the poster cache approach).
- **My Teams per viewer profile**, without rewriting Main's storage keys (CLAUDE.md §12).

## UI (TV)
- **League chips** row (user picks which leagues show + order; remembers last).
- **Date strip** (yesterday / today / tomorrow / …), Left/Right changes day.
- **Scoreboard grid**: logos, score or start time, status (LIVE in gold, period + clock),
  "on TSN 1" when a channel matched. Select → game detail.
- **My Teams**: one cross-league row of next/current games; in-app pill when a My Teams game starts
  (like the live island), Select → watch. Later: score toast while watching another channel.
- **Standings**: division / conference / league toggle, My Teams rows highlighted.
- **PGA**: leaderboard view (pos, player, to-par, thru) instead of game cards.
- **Game detail**: score by period, scorers, matched channels, Watch.
- **Settings > Sports**: keys, remaining quota, spoiler mode/delay, leagues shown, channel-match overrides.
- Focus: one `FocusScopeNode` per zone (chips, dates, grid) + explicit D-pad dispatch (CLAUDE.md §10).
- Windows needs its own entry points where the desktop stack differs; the data layer is shared Dart.

## Test results (2026-10-13, owner's free key)
- **API-SPORTS free plan has NO current season**: `games?league=57&season=2026` (NHL) and NFL
  `season=2026` both return `{"plan": "Free plans do not have access to this season, try from 2022 to
  2024."}`. `games?date=` alone fails ("The Season field is required"). → The free tier is useless
  for live scores/schedules; API-SPORTS can only be a *paid* BYOK option. Key-less ESPN default is
  now the plan of record.
- Confirmed: quota is per sport (hockey and american-football each 100/day, separate counters);
  `/status` did not consume quota; rate-limit headers `x-ratelimit-requests-remaining/-limit` are
  present on counted calls (absent on plan errors); keys are 32 lowercase hex chars → the 16-key
  hex pad works.

## Channel-matching test (2026-10-13, ESPN week Oct 13-19 vs trex_5 / BlckTV via Tuliprox)
- ESPN scoreboard (`site.api.espn.com/apis/site/v2/sports/{hockey/nhl|basketball/nba|football/nfl}/scoreboard?dates=YYYYMMDD`,
  one day per call — a `dates=A-B` range returned an error) works key-less: 91 games, broadcasters
  in `competitions[0].broadcasts[].names` + `geoBroadcasts[].media.shortName`. **US networks only**
  (no TSN/Sportsnet/RDS/TVA) — e.g. Sabres @ Canadiens listed only MSGB.
- Provider: 57k live channels, only 8.3k with an EPG id; **guide horizon ~1 day** (latest programme
  Oct 14 16:00 UTC) → only 21/91 games fell inside the guide.
- **EPG title match** (both team names in a programme starting −45/+20 min): NHL 13/51 overall, but
  13 of the 16 NHL games inside the guide horizon (~80%); NBA 1/5 inside horizon.
- **Channel-NAME match is the strongest signal**: providers pre-name event channels, e.g.
  `NHL | 01 - 6pm Devils at Red Wings`, `NHL: Montreal Canadiens vs Buffalo Sabres @ Oct 14 00:35 :TeliaPlay SE 23`,
  `US (ESPN+ 065) | Washington Capitals vs. Carolina Hurricanes Oct 13 6:15PM ET`,
  `Molson Habs Hockey: Sabres vs. Canadiens @ Oct 13 18:30 :TSN+ 47` (this is how Canadian regional
  coverage shows up). NHL 28/51, NBA 8/26, NFL 3/14 for the whole week — effectively all of
  *today's* NHL games. Caveat: names include stale events (yesterday's) and repeat match-ups → parse
  the date/time in the name or only match games within ~±12 h.
- **Broadcaster-name match is weak**: substring search explodes ("Fox" → 565 channels, "CBS" → CBS
  Drama/Reality); regional US nets mostly absent. Use only an exact canonical map for national nets
  (ESPN, TNT, NBA TV, NHL Network, ABC/NBC/CBS/Fox) as a last fallback.
- → Matching order: (1) event channel names for today's games, (2) EPG titles inside the guide
  horizon, (3) national-network map, (4) user override. One provider tested — others name event
  channels differently; keep the name parser tolerant (`vs`, `vs.`, `at`, `@`, full name or nickname).

## Open questions / tests before building
- [x] **Owner: test the API-SPORTS free tier on the current season.** (Done — no current season, see above.) Sign up at dashboard.api-sports.io,
      then (header `x-apisports-key: <key>`):
      - `GET https://v1.hockey.api-sports.io/status` — plan + requests used today
      - `GET https://v1.hockey.api-sports.io/leagues?search=NHL` — get the NHL league id
      - `GET https://v1.hockey.api-sports.io/games?league=<id>&season=2026` (season = start year)
        and `.../games?date=2026-10-13` — do current-season games and live scores come back, or a
        plan/season error?
      Repeat one call on `v1.american-football.api-sports.io` (NFL) to confirm the per-sport quota.
- [x] Check ESPN scoreboard broadcaster names against the owner's EPG channel names (match quality). (Done — see above.)
- [x] Confirm API-SPORTS key format (hex?) for the custom key pad. (32 lowercase hex.)
- [ ] Pick BYOK #2 for sure (TheSportsDB premium vs. another).

## Windows (1.0.5, 2026-10-14)
Owner tested Sports on a 4K Windows display: no way out (no remote Back) and everything tiny. Fixed in
`widgets/sports_widgets.dart`, all Windows-only or a no-op on TV boxes:
- `SportsScreenFrame` wraps Sports, Standings, My Teams and the channel picker: when the logical
  width exceeds 1440 it lays the screen out at 1440 px and scales it up (FittedBox + MediaQuery
  with scaled size/devicePixelRatio, so logos decode sharp); never shrinks. Esc = maybePop on Windows.
- `SportsBackButton`: a back arrow before each screen title (ExcludeFocus — stays out of the D-pad zones).
- `SportsRowArrows`: mouse ‹ › over each game-card row (per-row ScrollController `_rowScrolls`),
  shown only when there's more that way, ~one screen per click via jumpTo.
- Dialogs (game menu, pick scope) are separate routes and are not scaled.

## Hero mini player (1.0.16, 2026-10-17, Android only)
Play/Pause (or Play/Pause keys) on a game card plays its best channel in the hero: video on the left
(the TV guide's `VideoPlayerPane`, keyed by channel id), the normal VS layout shrunk on the right
(`_Hero._buildPlaying`, `_side(compact:)`), hint "OK: full screen · ▶❚❚ or Back: stop". The card
gets a gold ▶ + outline. Owner tested on the Formuler: "very very nice and works well" (stacked
info version rejected — keep the VS layout). Fire Stick check pending.
- State: `_previewGame`/`_previewChannel`; only live while `PlaybackService.currentChannel` is that
  channel (`_livePreview`; a CH+/- zap ends it). Hero stays on the playing game whatever is focused.
- `_setPreview` serialises starts/stops (`_previewChain`, latest press wins, waits up to 10 s for
  the stream to open) — overlapping `play()` calls could orphan a stream (audio underneath).
- **1.0.17 controls (owner):** OK on a card only selects it (hero shows it, nothing plays) — ▶❚❚
  starts the hero; OK on the playing game = fullscreen on the same stream (no wait for the stream to
  open, the Fire Stick showed the hero first). Hold = channel menu; a channel picked there plays in
  the hero. Selecting another card while one plays does NOT switch the hero (owner: Back stops it,
  then pick). No match = OK opens the menu. Phone: 1st tap focuses, 2nd tap plays in the hero, 3rd
  = fullscreen; long-press = menu. Back from fullscreen shows it in the hero; Back on Sports stops it
  first (PopScope), then leaves.
- Phone layout (1.0.17): the whole page scrolls (`_touch` = Android non-TV; header + hero + rows in
  one `SingleChildScrollView`, `_buildBody(inPage:)`), portrait hero stacks (`_narrowInfo`, video
  full width above the game). `_ensureRowVisible` is off on touch.
- Game menu (hold OK) opens on **Play here** (1.0.18): plays the best match in the
  hero, for remotes with no Play/Pause key (user report). Hidden while that game plays, with no match,
  and on Windows (`_GameDialog.offerPlayHere`).
- "▶❚❚" in hint strings is drawn as white play/pause icons (`_KeyHintText`) — as text Android shows
  an orange emoji.
- Platform-view rules: one video per stream, stays mounted under the pushed player (like the TV
  preview box), fixed tree position, no overlay/clip on it. RedZone pill: no preview, plain fullscreen.
- Windows (+336): built on `DesktopMiniPlayer` — `_setPreview` calls `mini.play` (one reused
  `Player`, no overlap), the hero draws `Video(mini.controller)`, `_livePreview` reads
  `mini.channel` (`_playingNow`, a listener rebuilds). Second click / Enter on a card = hero (like a
  phone's second tap), again = `DesktopPlayerScreen` with the hero's session (`mini.take()`); its Back
  minimizes the live channel back into the mini player = the hero. RedZone: plain fresh player.

## Live games list ("See all · stats", 1.0.20+330, 2026-10-17)
- Entry: a chip beside **Live now N** when 2+ games are live; Up from Live now's first two cards
  reaches it, Down goes back (`_liveAllStep` in `sports_screen.dart`). Owner wanted it for fantasy
  players.
- `sports_live_list_screen.dart`: one dense row per live game (clock + `SportsSituation` = down &
  distance / RED ZONE / possession icon, or baseball count-outs-bases; both teams with record +
  score; up to 3 `SportsGame.leaders` from the scoreboard; matched channel). Games live at open
  stay listed after they end (Final). Polls every 30 s. Explicit Up/Down, non-lazy list.
- OK on a row = `SportsGameDetailsDialog`: Watch on <channel> chips (up to 3 matches) + Close, then
  per team top performers, a trimmed box score (`_boxColumns` picks the best-matching column set
  per category), injuries, soccer scorers, team stats side by side, the standings groups holding
  either team (highlighted). Data: ESPN `.../summary?event=<id>` (~400 KB, `parseEspnSummary`
  off-isolate, 30 s cache while live). Up/Down scroll by `jumpTo`.
- ▶❚❚ on a row = watch full screen at once. Back from the player **stops** the stream and returns
  to the list (it would otherwise play unseen under it). Picking a channel stays in the hub (hold OK).
- hideScores: rows hide scores + leaders; the dialog hides scores / last play only.
- Hold OK on a row = the hub's game menu (`_openGame(game, matches, watch)`), first entry "Play"
  = full screen (owner: remotes without ▶❚❚). The list starts from the hub's games + matches and
  only searches games the hub hasn't (`initialGames` / `initialMatches`).
- Owner-tested on the Formuler (+321..+329): stats load fast (focus prefetch), backdrop opacity
  0.10 "perfect", channels instant on re-entering the hub.


## Per-game reminders (Codex, 2026-10-23; unreleased)

- Hold OK on an upcoming followed-team game, including My Teams, then choose
  **Remind me**. The same menu offers **Cancel reminder** afterwards.
- `GameReminders` persists opt-in games per viewer, on this device only; reminders
  are excluded from transfer/backup. No OS alarms. Automatic team reminders refresh opted-in team schedules every
  30 minutes while foregrounded, using the existing SportsService cache.
- `GameReminderOverlay` lives above the root Navigator, including fullscreen
  players. Popups at 15 minutes before and at scheduled start dismiss after 12
  seconds, queue simultaneous games, and never request playback focus.
- App must be foregrounded. On resume, skip advance alerts over one minute late
  and start alerts over two minutes late; delivery state prevents repeats.
- Fresh My Teams schedules reconcile changed start times and remove cancelled,
  postponed, suspended or completed games. With no fresh schedule, the saved
  scheduled time is used. Profile switches clear visible/queued notices.
- Tests cover timing, persistence, viewer isolation, rescheduling/cancellation,
  focus during a pushed stream, background/resume, and narrow phone layout.

- Extension: the same game hold menu offers **Remind me for every game: {team}**
  for each followed side, and **Stop team reminders: {team}**. Unfollow also stops
  that team's automatic reminders. Individual cancellations survive refresh/restart;
  disabling a team keeps manual reminders and games covered by another enabled team.
- Popup background: selected enabled team's logo at 14% opacity behind the text,
  clipped to the rounded panel. Missing/failed images leave the readable dark panel.
- Preference schema reads the original per-game list and now writes entries,
  enabled team keys and skipped game keys together; viewer fences reject late
  schedule responses after switching profiles. Duplicate games share one notice.

- Unreleased reminder card restyle (`codex/reminder-card-style`, owner feedback):
  64px foreground crest plus a 28% background watermark (was 14%), rounded accent
  border, My Teams header and time badge. No new strings or scheduler changes.

## My Teams Goals alert (Codex, 2026-10-26; 1.0.41)

- Settings > Interface > Goals alert is off by default, per viewer, and copied with
  Sports preferences. Applies to every followed team in supported team leagues.
- `GoalsAlerts` compares valid numeric scores from the existing cached SportsService
  day loader (two concurrent league fetches maximum). First observation is a silent
  baseline; profile changes, opt-out and app backgrounding reset it. Corrections
  downwards, cancelled games and already-final score edits do not notify.
- `GoalsAlertOverlay` sits above the root navigator without taking focus or changing
  playback: compact top-left card, league/team logos, faded team watermark, 8 seconds.
  Existing reminders stay top-right; narrow screens stack below the measured reminder.
- Checks every 30 seconds while foregrounded; the shared feed cache still applies
  (ESPN live about 50s; SportsDB about 120s). These are feed updates, not instant push.
  Hide scores suppresses the popup immediately. No OS/background notification service.
- Pending fetches from previous viewers are discarded. Overnight live games keep their
  start-day lookup through the final update. Temporary feed errors preserve baselines.
- Widget fixtures must create GameReminders inside testWidgets, not an outer async
  setUp: its initial Future chain otherwise crosses the fake clock and stalls pumps.

## Reminders on all upcoming cards (Codex, 2026-10-26; unreleased)

The Sports Trak game menu no longer gates GameReminderMenuTile on My Teams
membership. Its existing canSet/isSet checks offer Remind me on any upcoming
eligible game, or Cancel reminder on a saved game, including unmatched games.
Main rows, Later today grids and My Teams share this menu. Live/final/past or
cancelled games remain ineligible. Team-wide automatic reminders still use followed
teams. Scheduler, timing, persistence and reminder popup are unchanged.

## Match-specific score alerts (Codex, 2026-10-27; unreleased)

Hold an upcoming/live team-game card and choose **Set goals alert for this match**;
the same shared Sports Trak menu offers **Remove goals alert for this match** afterward.
Both sides are tracked, including teams outside My Teams. The saved match opt-in is
independent of the Interface My Teams toggle, per viewer, on this device only, and
excluded from backup/transfer. Saved entries expire 48 hours after scheduled start
and are pruned on the next subscription save (at most64 valid subscriptions).

The existing top-left card/league and scoring-team logos are reused over every
screen/stream. First observation/reopen/resume is silent; Hide scores suspends all
alerts. Shared league/day queries retain the existing two-worker limit and cached
30-second polling; updates may combine multiple scores between feed refreshes.
Following a team and selecting its match produces one notice per scoring side.
Cancellation, profile changes and stale in-flight responses cannot leak notices.
No new endpoint, background service, decoder changes or playback/focus changes.

## Game reminder timing (Codex, 2026-10-27; unreleased)

The shared game-card menu's Remind me action opens a compact right-side timing
menu: 15 minutes (default),1hour,1day or1week before, or game-time-only.
Every advance choice retains the kickoff reminder. Saved games keep Cancel reminder
and gain Reminder timing to edit the lead time. Passed advance deadlines are disabled.

GameReminder.leadMinutes persists per game/viewer/device. Existing saved reminders
without it keep15minutes. Editing invalidates queued notices for the old timing;
rescheduling preserves the selected lead and recomputes its deadline. Missed advance
notices remain silent outside the existing1minute grace window. Popups say the chosen
lead; startup/background behavior is unchanged (VesperTV must be open). Automatic
team reminders still default to15minutes; a game-specific override becomes manual.

## Team Schedule (Claude, 2026-10-27)
Hold OK on a team in Standings or My Teams -> Schedule / Follow-Unfollow. Month calendar
(`sports_schedule_screen.dart`): opponent logo + time/result per day, cup logo in the corner when the
game's competition isn't the team's league, details of the selected day beside it (below on phones).
OK: finished = `SportsGameDetailsDialog`, live = the Sports screen's `onActivate`, upcoming = its game
menu (`onMenu`; without one, reminder toggle). Data `SportsService.teamSeason` (10 min cache): soccer
uses `soccer/all/teams/{id}/schedule` (verified live 2026-10-27, Arsenal: Carabao Cup, UCL, Community
Shield, friendlies); other sports / CFL / TheSportsDB = `teamSchedule`. Channel matches are computed for
the next 14 days only. Tests: `test/sports_schedule_test.dart`.

## Rugby, cricket, PDC darts (Claude, 2026-11-01, owner request, uncommitted)

League bank regions Rugby / Cricket / Darts (`kSportsLeagueBank`, test
`sports_rugby_cricket_darts_test.dart`).
- Rugby: ESPN `rugby/{id}` (Six Nations 180659, Rugby Championship 244293, World Cup 164205,
  Tests 289234, Prem 267979, URC 270557, Top 14 270559, Champions Cup 271937, Super Rugby
  242041) + NRL `rugby-league/3`. Tables use gamesWon/gamesDrawn/gamesLost/pointsDifference/
  bonusPoints/points. ESPN has no per-competition rugby logos (generic icon).
- Cricket: TheSportsDB (IPL 4460, BBL 4461, PSL 5067, SA20 5532, CPL 5176, T20 Blast 4463).
  Scores are runs only (no wickets/overs), free tables empty -> no Standings. ESPN cricket is one
  id per series (no league feed); internationals (Tests/ODIs) have no free source.
- Darts: TheSportsDB PDC 4554, `SportsKind.fight` event-only cards (tournament days, no matches
  or scores). 00:00 UTC = no time -> date-only card (`end` set, like golf). Channel search uses
  the title without numbers/"Day N" plus series phrases pdc/darts.
- `SportsLeague.homeFirst` (soccer, rugby, cricket read Home vs Away), `sport`, `isDarts`.
- Darts times are per tournament day/session, not per match (owner, 2026-11-01): a timed PDC
  card keeps its time, but the guide search looks 12 h past it (`_guideWindow`).
