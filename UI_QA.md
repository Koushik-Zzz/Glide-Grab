# Stud UI verification — 15–16 October 2026

Target: the existing `backup_update.rbxl` native scene, with Rojo-managed scripts and UI. Studio reports GameId/PlaceId 0: all balances and rebirths below were disposable local previews, not published player saves.

## Executed

| Check | Result |
| --- | --- |
| Real shop buttons | Bat purchase deducted 5,000 and became owned; boost deducted 500 and advanced one level; shield deducted 3,000 and added one charge. Native vendor purchases still work. |
| Two-player shop test | `tests/camp-shop.server.lua` and `.client.lua`: two Studio clients, 23 client assertions each, plus server assertions. Independent 15,000 wallets finished at 6,500 with bat, one shield and boost level 1. Duplicate/stale purchases, malformed/unknown requests and travel-time purchases were rejected. |
| Camp-wide rebirth menu | Opened away from the station with 300,000 local preview coins, boost level 1 and owned bat. Native confirmation reset coins and boost to zero, retained the bat, set rebirth 1 and unlocked 12 pillows. This verifies the menu integration, not cloud persistence. |
| Real world interaction sequence | Native E entered Meadow; after the destination streamed in, E grabbed a Common egg; E returned to camp with cargo; hold E placed it for 1/sec; hold F sold it for 10 coins and removed its income. |
| Custom prompt lifecycle | Runtime cards existed for upgrade, travel, grab, placement and sale. Occupied pillow E/F cards retained -55/+55 offsets. The user confirmed the workshop card was visible. MCP image capture omits these world-attached cards even when the user sees them; screenshots alone were not used to claim prompt visual validation. |
| Coin feedback | Observed a confirmed +420 wallet change produce `+$420` above the amount and within the safe canvas. Pool is bounded to six labels. |
| Equipment fallback | Adding a temporary second Tool restored the native backpack and hid the custom slot; removing it restored the custom slot. Fixture removed. |
| Respawn | Each HUD had exactly one copy. Menus closed, no new client script errors, and clicking the new slot equipped the actual Glider after Backpack replacement. |
| Narrow navigation | At 360×640 safe-root size, opening the drawer then opening/closing the Roblox menu cleared the drawer state and restored prompts. |
| Cargo resize | A temporary local cargo fixture hid the cargo card at 720×300 and showed it at 1440×900; removing the fixture cleared it on the following update. Real pickup/placement also exercised cargo changes. |
| Layout bounds | Actual GUI roots were temporarily sized to 1570×700, 1440×900, 2100×900, 360×640, 720×300, 1024×768 and 480×300. Checked visible main HUD bounds and pairwise overlap. All passed after fixing compact action/slot overlap. |
| Menu layout/text | 1570×700, 360×640, 720×300 and 480×300: modal bounds and visible row text fit passed, with scrolling for excess rows. |
| Static validation | Rojo 7.6.1 build passed. Selene reported zero errors, warnings and parse errors on selected changed controllers, UI modules, shop access and shop tests using the Luau check configuration (Roblox undefined globals and compact multiple statements allowed). UI authoring generator is idempotent. |

The last single-client session had no client script errors. Existing Roblox CorePackages FoundationProvider and imported-asset warnings are separate from these UI scripts. Tests used scripted character positions to reach interactions, then native keyboard/mouse input for the actions; this is not a complete natural-flight playtest.

## Fixes found during verification

- Removed a UI-module require from the sandboxed imported glider. Its input guard reads a local player attribute instead.
- Made custom prompt ownership explicit with cleanup on streaming removal and style checks when shown.
- Corrected UTF-8 hold text and replaced an unsupported rebirth glyph with editable geometry.
- Reset the compact navigation drawer when closing or switching menus.
- Rebind the equipment controller when Roblox replaces the Backpack on respawn.
- Recompute cargo visibility on viewport changes without triggering repeated pickup effects.
- Keep unloaded catalogue prices as `...`, and send an explicit false expected-state value for Browse.

## Still requires release testing

- Actual Device Emulator/mobile touch and Controller Emulator/gamepad navigation. The size checks above are desktop safe-root simulations, not hardware tests.
- Native mouse/touch holds on the world cards and the reduced-motion preference on a real client. Keyboard holds passed; reduced-motion handling has code review coverage only.
- Published saving/rejoin with the latest build. It remains local and has not been published by this UI pass.
- A friend playtest for combat feel, flight readability, slow connections and progression pacing. No claim of completed human or six-player testing.

## Clean handoff

The temporary multiplayer scripts were removed from the Studio Edit tree. Runtime funds, temporary Tools/cargo and prompt-render fixtures disappeared when Play stopped. `tests/` and `scripts/setup/` are not mapped into production. The native scene was not replaced with the scripts-only build. Save the open scene in Studio to retain the synced UI and the reduced-distance workshop signs before publishing.

UI sources are in `ui/`, with controllers in `scripts/` and shared behavior in `scripts/ui/`. `tools/author_stud_ui.py` regenerates the editable JSON templates; modify the authoring recipe alongside generated UI to preserve changes on regeneration.

## Illustrated artwork follow-up — 18 October 2026

The owner's newly supplied Open Cloud key was validated as enabled and unexpired; `.env` and its variants are ignored by Git and never mapped into the game. Generated and uploaded four original transparent icons for Shop, Boost/Upgrades, Rebirth and Coins. Roblox returned Active / Approved for all four. Artwork, full prompts, IDs and upload results are recorded in `assets/ui/`.

Executed in the native Studio place: visible HUD icons loaded, the boost header and dynamic row loaded, switching tabs selected the correct header illustration, and an empty image switched to the editable fallback then restored the uploaded artwork. An initial hidden-ImageLabel loading problem was corrected by using content-fetch completion rather than `IsLoaded` alone. Client errors: none. Rojo build and selected-controller lint passed.

Phone/controller emulation remains unverified: Windows-control app approval timed out before the device controls could be selected. The user subsequently supplied the Creator Dashboard URL, confirming universe **10770918233** and root place **135204243659176**, owned by user 4105644482. Open Cloud reads confirmed the name **Glide & Grab [Testing]**, PRIVATE visibility and a previous update on 14 October. The place's capacity was 50 and was changed to **6**, then read back successfully, matching the six personal camps. The owner's `GlideGrab_Player_v1` baseline read returned DatastoreNotFound; there was no live profile to compare yet.

The scene contains 78 PartOperations (union objects). Roblox documents limitations when updating these through the place publishing API, so the owner was asked to save and publish the full scene through Studio to the confirmed existing experience. No binary place upload or live save mutation was performed. `python tools/check_testing_game.py` can recheck the exact target and read only the owner's live profile; private evidence stays under ignored `tmp/`. A real published join, save, leave and rejoin is still pending.

The owner subsequently saved and published through Studio. The first actual live egg save/leave/rejoin passed: the exact saved egg was retained, departure removed the lease, and rejoin acquired a different live lease; the owner confirmed the egg at camp. Current results and narrower remaining persistence checks are recorded in [live save verification](docs/live-save-verification.md).

A subsequent purchase/departure snapshot retained a nonzero coin balance, boost level 2, owned bat and exact egg with the lease released. The next fresh session kept the bat and egg and recorded a further boost purchase. Nonzero shield/rebirth restoration and an unchanged-wallet comparison are not claimed from that session. The read-only checker now distinguishes a present lease from an unexpired active lease.

The owner confirmed seeing 39.5K coins, the owned bat and boost level 3, matching the latest backend read of 39,511 coins and boost level 3. They also confirmed consuming the shield charge, explaining its saved zero count. Basic live progress saving is confirmed; unused shield and rebirth restoration still require separate published checks.
