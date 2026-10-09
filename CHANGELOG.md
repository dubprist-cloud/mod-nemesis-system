# Changelog

## 0.6.2 - 2026-10-08

- addon: the Top button relabels itself to `Map` while the leaderboard is open, so one button is both the opener and the way back
- docs: README and the addon specification brought in line with the shipped behaviour. The README had been claiming a resizable window, a detail panel that does not exist, "no waypoint integration yet", and that the addon bridge had never been verified

## 0.6.1 - 2026-10-08

- addon: the Top pane pins your own line to the bottom of the pane under a separator, so a character outside the visible top - or one who has not killed anything this month - still sees their place and totals. A character who IS in the top has their row highlighted instead of being listed twice
- server: the leaderboard query now carries the character guid, and when the requester is not inside the returned top their exact month position is sent as a separate `V2:TOP_SELF` line

## 0.6.0 - 2026-10-06

- a nemesis now plays a one-shot visual when it gains a rank (`NemesisSystem.RankUpFlashVisual`), so promotions are noticed in the world and not only in chat
- the addon colours the rank label by the server-computed threat class, so an extreme nemesis reads at a glance without hovering
- fixed the map's zone arrows: map markers are children of the canvas and therefore sat one frame level above them, so a marker could swallow the click and the arrows appeared dead. They now sit above the canvas and show the target zone on hover
- replaced the per-tick creature poll with events: auras are refreshed on evade and on world load, and dead nemeses are cleaned up in `OnUnitDeath`. `OnAllCreatureUpdate` is gone, so the module no longer touches every creature in the world every tick
- revenge now belongs to EVERY player a nemesis has killed, not just its most recent victim: relations, reward class and the revenge/bounty split all consider the full victim list
- added the `character_nemesis_victims` table to record those victims
- attack power is now scaled together with weapon damage, so a rank gives the same effective multiplier regardless of the mob's class (it used to be x1.82 for a warrior mob and nearly x2.0 for a caster)
- Swift now adds 25% damage on top of its faster swings and movement speed, instead of being damage-neutral (`NemesisSystem.SwiftDamageMultiplier`)
- addon: the row tooltip lists the affixes and explains what each one does, with the wording sent by the server so it always matches the configured values
- addon: the Waypoint button and row double-click hand off to TomTom when it is installed (it is not part of the client, so this is a no-op otherwise)
- addon: new Top button opens a monthly leaderboard pane fed from `character_nemesis_monthly_kills`

## 0.5.0 - 2026-10-06

- relaid the window out: every control (refresh, waypoint, relation filters, zone scopes, pager) now sits in a single row above the map, and the nemesis list starts directly under that row
- removed the search box
- removed the "Public" relation filter button
- fixed the guild relation: it was resolved through a live-player lookup, which only knows online characters, so a guildmate's nemesis was reported as public whenever that guildmate was offline
- the window is now fixed at 860x520 instead of resizable

- restyled the companion addon to match the Guild Hegemony and Battle Pass windows: shared gold-on-dark palette, 1px gold borders, a title strip with a gold rule, matching buttons, and a highlighted active filter
- the tracker window is now toplevel (no more z-fighting with the other module windows) and closes on ESC
- no behaviour change: every frame, anchor and handler is untouched, and the old `SetBackdropColor` / `SetText` call sites still work through compatibility shims

## 0.4.0 - 2026-10-05

- fixed decay so it is measured from creation or the last rank-up instead of being reset on every promotion, and stopped overwriting `creation_date` on rank-up
- stopped refreshing a nemesis lifetime on grid load, which previously made every nemesis in a busy zone immortal
- added a lock-free hot path so the per-tick creature hooks no longer take the global store mutex while no nemesis is tracked
- made store access consistent: bootstrap collection is locked, expired records are erased under the lock, and packet broadcasts no longer happen while the store mutex is held
- validated player addon sightings: a report is only accepted when the nemesis is loaded next to the reporting player, and the stored position now comes from the creature instead of the client
- reduced the addon chunk size so a chunked frame stays below the 255 byte addon message limit
- decoupled nemesis damage scaling from health scaling and capped the combined `Savage` + `Enraged` bonus
- added `NemesisSystem.HealthScalingReferenceLevel` so the health ladder scales down below max level; a rank 5 nemesis in a levelling zone is no longer unbeatable
- made the Vampiric heal percentage configurable and reduced it from 50% to 25%, since Vampiric + Regenerating could out-sustain a solo player
- made gold rewards configurable and implemented the documented overlevel/underdog reward scaling
- replaced the hand-rolled addon chat packet with `ChatHandler::BuildChatPacket`
- fixed the nemesis name suffix stacking on every rank-up; the tier label is now replaced instead of appended
- fixed an undefined `L` global in the addon data module that could raise an error when a zone name was missing
- aligned the addon sighting throttle with the server-side report cooldown
- fixed the addon zone label: it used `GetAreaInfo(zoneId)`, which in 3.3.5a ignores the argument and returns the player's current area
- persisted refreshed sightings on creature load so decay stays consistent between the in-memory store and the database
- synced the addon version and removed the unused standalone `ClientAddon/Ace3` copy

## 0.3.1 - 2026-04-05

- added `character_nemesis_monthly_kills` tracking so websites can build monthly nemesis kill leaderboards directly from the characters database

## 0.3.0 - 2026-04-04

- fixed companion addon `V2:CHUNK` reassembly so larger bootstrap and upsert payloads are rebuilt correctly client-side
- added non-rank-5 live addon upsert broadcasts after nemesis promotion so trackers receive new sightings sooner
- expanded addon zone and texture mapping for real world map tile rendering across more zones and common subzones
- refactored the companion addon into modular files for core bootstrap, data/state, communication, lifecycle, and UI concerns

## 0.2.0 - 2026-03-22

- reworked the companion addon around an AceDB-backed local cache
- replaced player-safe full snapshot sync with filtered V2 bootstrap flow
- added addon sighting report validation and persisted last-seen nemesis locations
- restricted full addon sync to GM use only
- added peer sync scaffolding for guild, party, raid, and public sharing scopes
- updated tracker UI to show stale state, source, and refresh-based behavior
