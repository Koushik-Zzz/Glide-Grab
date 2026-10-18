# Saving and first rebirth

Player progress now has one private server profile. The saved snapshot includes coins, boost level, bat entitlement, shield charges, rebirth count, stored eggs and uncollected online income. Every egg retains its template, pillow index, identity, tier, income, sell value and scale. Camp ownership is reassigned on join; the player's collection moves into the available camp. Carried eggs and temporary shields/stuns/boost timers do not persist. There is no offline income.

## Source and ownership

| Source | Responsibility |
| --- | --- |
| `scripts/data/Schema.lua` | Version 1 validation, defaults and independent snapshots; unknown/newer saves fail closed. |
| `scripts/data/Session.lua` | UpdateAsync acquisition, token-owned 240-second session lease, ordered retries, idempotent writes and lease-only retirement of uncertain checkpoints. |
| `scripts/data/Profiles.lua` | Load readiness, server profile access, coin publication, 55–70-second autosaves, leave/shutdown saves and saved-before-applied rebirth commit. |
| `scripts/collection/Plot.lua` | Restore/save the private pillow ledger and exact egg offers; ownership and proximity still gate transactions. |
| `scripts/collection/Floors.lua` | Reveal the owner's authored upper deck and slots only after the private rebirth unlock. |
| `scripts/Rebirth.server.lua` | Short-lived confirmation offers, eligibility and atomic reset/checkpoint. |
| `scripts/Rebirth.client.lua` and `ui/RebirthHUD.model.json` | Editable, scrollable confirmation modal and cross-device button/focus handling. |
| `scripts/progression/RebirthConfig.lua` | First rebirth cost and reset policy. |

The implementation follows Roblox's [data-store best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices): one key per player, memory during play, periodic/final writes, UpdateAsync and bounded retries. Session ownership is rechecked on each write. An expired server cannot overwrite a new owner. A failed load never supplies writable empty defaults. Rebirth freezes transactions, writes the entire new snapshot and only then resets the live camp and publishes the unlock.

A failed network response does not prove that the backend rejected the write.
If all checkpoint responses fail, the server stops gameplay and asks the player
to rejoin. It retires only its lease while preserving the backend's actual
snapshot; departure/autosave cannot overwrite a possibly committed rebirth with
old progress. If the checkpoint never reached storage, the next load restores
the last saved progress. If it committed, the next load restores the rebirth.
An unavailable lease release may require waiting for the 240-second lease to
expire. The message does not promise that an unknown save outcome was rolled back.

Normal saves use three attempts; a final departure uses five, with waits of
2/4/6/6 seconds between requests. PlayerRemoving and BindToClose share one final
snapshot and retry sequence. Shutdown waits up to 25 seconds; long backend calls
or a sustained outage can still outlast that budget. This is bounded recovery,
not a guarantee against every server failure.

## Local, Studio and published data

- An unassociated local place (`GameId == 0` in Studio) uses a clearly labeled **COINS • LOCAL** preview. It resets between Play sessions. It never attempts to overwrite published data.
- A published experience opened in Studio uses `GlideGrab_Studio_v1`, separate from live player progress. To test this path, enable **Studio Access to API Services** for the testing experience yourself; this setting is not changed by the code.
- A Roblox server uses `GlideGrab_Player_v1`. Both stores use `Player_<UserId>` keys and the same versioned record. No API key is required by the game scripts.
- The HUD caption reports Saved, Local, Loading or a save retry. Failed published loads disconnect the player with a recovery message. Lost leases or a prolonged save outage stop play to protect the existing record.

The published testing game supplied by the owner is a [Roblox experience share link](https://www.roblox.com/share?code=3359fb975b7f13439230317cb2076a00&type=ExperienceDetails&stamp=1792047388819). Publishing remains a separate owner action.

On 18 October the owner's Creator Dashboard URL and read-only Open Cloud checks confirmed universe **10770918233**, root place **135204243659176**, PRIVATE visibility and owner 4105644482. Its [permanent game link](https://www.roblox.com/games/135204243659176) can be used for the real rejoin test. Server capacity was corrected from 50 to six and verified by reading it back. A baseline read of the owner's live profile returned DatastoreNotFound. This is expected before the first session of a build using this store; it does not establish successful saving.

Publish the current full scene from Studio: its 78 union objects fall under the place API's [documented publishing limitations](https://create.roblox.com/docs/cloud/guides/usage-place-publishing). The asset-upload key is configured locally, and the four UI images are approved. `python tools/check_testing_game.py` reads the confirmed game settings and only the owner's live save, storing the private record in ignored `tmp/`. It performs no save writes or publication. Live rejoin verification remains pending until the new build is published and played.

**Later on 18 October:** the owner published and completed the first real live leave/rejoin. The exact egg record survived, departure released the lock, a fresh lock appeared on rejoin and the owner confirmed the egg at camp. [Live verification](live-save-verification.md) records those results and the remaining positive purchase/rebirth checks. The Studio-only verification and prepared checklist below predate this cloud check.

## First rebirth

The shared station is on the camp's central path near spawn. View the offer and explicitly confirm. Requirements are **250,000 coins**, empty hands, a living character in base camp and proximity to the station. The offer expires after 20 seconds and is single-use; the server rechecks the requirements at confirmation.

The first rebirth resets all coins, stored eggs, ready income and boost levels. The purchased bat and unused shield charges stay. The reset and new rebirth count share one saved checkpoint. Only the first rebirth is available in this version; subsequent rebirth content is not advertised as playable.

Rewards:

- A second camp deck, stairs and railings, increasing usable pillows from 6 to 12. The lower floor stays usable. Upper-floor prompts and collisions remain locked for zero-rebirth owners.
- A shared purple **Storm Isles** portal requiring at least one private rebirth. Lower-count players cannot unlock it by changing client attributes or flying across the map. Requirements are checked at departure and arrival.
- Three floating islands, a blue return portal and a scarcer Epic Storm egg. The egg rolls 1,000–2,500 coins/sec once per spawn, with Low/High tiers and scale 1.1–1.65. Its roll is preserved on pickup, transfer, display and save.
- Stronger wind pacing: 2 seconds calm, 1.2 seconds warning and 4 seconds gust, at up to 80 studs/sec leftward. Wind does not damage or delete eggs. The original Meadow stays available.

The authored scene was added with `scripts/setup/FirstRebirth.studio.lua`; do not rerun it after authoring. It is not a runtime script. Map geometry, templates and decks remain in the full Studio place. Source scripts and RebirthHUD are mapped by Rojo. Keep using `backup_update.rbxl`; a scripts-only build is only a validation artifact.

## Verification status

- Executed: scripts-only Rojo build and offline Luau lint of changed gameplay scripts (zero errors/warnings).
- Executed in Studio against the production modules: **36 save/session assertions** (51 UpdateAsync calls), covering exact egg/gear restoration, pending fractions, invalid/duplicate/locked slot data, failed load/save, ambiguous success, lease takeover, stale writes, the rebirth checkpoint, exhausted response retries, lease-only retirement and final retry recovery. The backend was a deterministic UpdateAsync test double, not Roblox cloud storage. The same test is in `tests/data-session.luau`; the optional CLI runner is `tests/run-data-tests.py <path-to-luau.exe>`.
- Executed in a separate **two-client StudioTestService resilience run**: a dependency-injected clone of production Profiles received three lost responses after a committed rebirth, stopped the player, retained the backend checkpoint, released its lease and refused a stale departure write. Two simultaneous departure callers for the other player captured once, shared five bounded attempts after four transient failures, saved 4,242 coins and released the lease. `tests/stage-profiles-resilience.studio.lua` stages modules in Edit; `tests/profiles-resilience.server.lua` runs only in Studio with token `ProfilesResilienceProof`. Neither file is mapped by Rojo. Fixtures were removed after the passing run.
- Executed with **two actual StudioTestService clients**: separate gardens, shop purchases, pre-rebirth Storm rejection, simultaneous Common pickups and separate displays, native mouse confirmation, isolated coin/egg/boost reset, retained bat/two shield charges, 12 versus 6 usable pillows, unlocked versus locked deck collisions, both Storm portal directions and an upstairs Epic placement. The Epic retained its 1,352/sec roll and identity. Respawn kept the camp collection. The first attempt stopped at automated shop input; the retry waited for gear initialization and used longer native prompt holds.
- Executed after current UI/telemetry integration: the full two-client native
  combat regression passed, including separate purchases, safe base, stun and
  cleanup, shield/malformed/grounded rejection, air theft preserving a Low Rare
  at 390/sec, transfer grace, former-owner respawn and new-owner display/income.
  Its scripted setup waits for server-observed position and native prompt
  completion; it is not a human or network-latency test. Temporary fixture
  objects were removed and Studio returned to Edit.
- Executed with one StudioTestService client: save/release/reload through production Session with a test backend, then production Plot restoration into a fresh native garden. The original offers, slots 1/12, 2,001/sec combined rate, upper deck and pending fractions were restored. Forging the displayed egg's rate and identity did not alter its private saved offer.
- Executed in single-player Play: native confirmation, insufficient-funds disabled state, rendered desktop confirmation and geometry previews. Modal bounds passed at simulated root sizes 1366×768, 360×640 and 720×300; these are layout checks, not real phone/controller input tests.
- The temporary test scripts, reporting remotes, cloned garden and preview were removed. Evidence remains in ignored `tmp/progression-playtest-results.json`. Studio execution access was restored after the earlier permission block. Managed sources and the authored RebirthHUD were synced to the open Edit place.
- Still unverified: real leave/rejoin through Roblox DataStoreService, backend outage behavior in a live server, high latency, native phone/controller inputs and six-player stress. The open local file has no universe association, so it correctly uses the explicit preview mode.

Before release, save and publish the testing place, then verify a real player's coins, gear, an upstairs stored egg and rebirth count survive leaving and rejoining. Keep Studio and live records distinct when checking the results. Publishing and saving the native place remain owner actions; neither was performed automatically during these tests.

## Published leave/rejoin checklist

1. Publish the current **full** scene to the intended testing experience, then
   join it in Roblox Player. Do not use a scripts-only validation build as the
   place. The owner can also open the cloud-associated place in Studio for
   test-store checks; the current local file remains a preview.
2. Record the wallet, boost level, bat entitlement, unused shield count and
   rebirth count. Store an egg with a recognisable tier/income/size, and record
   its pillow number. A reborn player should include an upstairs egg.
3. Collect income and make a normal purchase. Record the resulting wallet and
   entitlement. Leave no carried egg if the aim is to check stored restoration;
   carried cargo intentionally disappears on departure.
4. Play for at least 75 seconds, then leave and rejoin. Compare the recorded
   values and egg offers. Gardens may have different plot numbers, but the
   player's stored pillow indices and exact offers must restore. The wallet
   changes only through gameplay transactions, not time spent offline.
5. Repeat an immediate leave/rejoin once to exercise final saving and session
   release. An active old lease should block a duplicate load rather than
   silently creating a new profile. Do not delete a cloud record to bypass it.
6. Test the first rebirth when ready to reset testing progress: confirm the
   reset/keep policy, leave, rejoin, and verify one rebirth, twelve pillows and
   Storm access remain. Do not advertise a second rebirth in this build.
7. For no-offline-income verification, record uncollected income just before
   leaving and again immediately after rejoining. Allow only the short **online**
   interval around the readings; the offline interval must not generate income.

This checklist is prepared, not marked complete. The current tool session has
not joined the owner's published server, inspected a live record or verified a
real Roblox backend rejoin. The supplied share redirect could not be resolved
through the available read-only web requests; it does not establish a place ID.
