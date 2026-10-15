# Glide & Grab

This is a scripts-only Rojo project connected to the existing Roblox Studio place.
Open **`backup_update.rbxl`** to build the map and playtest the game. This is the current full place, saved from Studio's recovered session on October 15, 2026.

`GlideAndGrab_Prototype.rbxl` is an older snapshot that predates the combat shop and assets. Keep it as a fallback; continue editing and saving `backup_update.rbxl`. The place filename is not referenced by `default.project.json`, so the new name does not change Rojo syncing.

The recovered file was inspected directly: all 35 mapped Luau scripts match the disk source, and the shared camps, perimeter walls, Meadow guardian, Rare egg template, combat shop/assets/HUD, and skybox are present. Save both code files and the Studio place when making changes; a scripts-only Rojo build does not include the authored map. Saving the place preserves development work, but player coins, upgrades and eggs still use session-only data until persistence is implemented.

## What Rojo syncs

| File | Existing Studio object |
| --- | --- |
| `scripts/EggLoop.server.lua` | `ServerScriptService/EggLoop` |
| `scripts/PortalLoop.server.lua` | `ServerScriptService/PortalLoop` |
| `scripts/FlightHUD.client.lua` | `StarterPlayer/StarterPlayerScripts/FlightHUD` |
| `scripts/PortalTravel.client.lua` | `StarterPlayer/StarterPlayerScripts/PortalTravel` |
| `scripts/MeadowWind.server.lua` | `ServerScriptService/MeadowWind` |
| `scripts/NestGuardian.server.lua` | `ServerScriptService/NestGuardian` |
| `scripts/guardian/*.lua` | `ServerScriptService/GuardianModules` (five ModuleScripts) |
| `scripts/MeadowWind.client.lua` | `StarterPlayer/StarterPlayerScripts/MeadowWind` |
| `scripts/glider/Glider.client.lua` | `StarterPack/Glider/LocalScript` |
| `scripts/glider/Glider.server.lua` | `StarterPack/Glider/Script` |
| `scripts/GliderBoost.server.lua` | `ServerScriptService/GliderBoost` |
| `scripts/GliderBoost.client.lua` | `StarterPlayer/StarterPlayerScripts/GliderBoost` |
| `scripts/boost/*.lua` | `ReplicatedStorage/BoostModules` (Config and HUD ModuleScripts) |
| `ui/GliderBoostHUD.model.json` | `StarterGui/GliderBoostHUD` (editable UI template) |
| `scripts/PillowColors.server.lua` | `ServerScriptService/PillowColors` |
| `scripts/collection/*.lua` | `ServerScriptService/CollectionModules` |
| `scripts/progression/Progression.lua` | `ServerScriptService/ProgressionModules/Progression` |
| `scripts/CampPlots.client.lua` | `StarterPlayer/StarterPlayerScripts/CampPlots` |

The source files were checked against and imported from the saved place. No gameplay changes were made during migration.
Workspace, the glider model and its mouse script, the rest of StarterGui, and other assets remain managed in Studio. The glider's LocalScript and server Script are owned by Rojo so wind/boost can contribute to its flight target and the server can track flight state. The boost HUD template is also owned by Rojo.
The project explicitly preserves unknown instances at every mapped level.

## Connect Studio

1. Stop any running playtest and open the existing place.
2. If the sync server isn't running, use VS Code: Terminal > Run Task > **Rojo: Serve Glide & Grab**. Alternatively run `rojo serve default.project.json` in a terminal in this folder.
3. Open the Rojo plugin in Studio's Plugins tab.
4. Connect to **127.0.0.1**, port **34872**. Confirm the project is **Glide & Grab**.
5. If Rojo displays a proposed sync, it should manage the executable scripts, ModuleScript folders and boost HUD template listed above. There should be no proposed deletions of map parts or the glider's art. Reconnect Rojo if it reports a network or `InstanceMap` warning.
6. Apply the script sync, then press Play. Enter Meadow, retrieve an egg, return to camp and hold E at a pillow to display it. Placed eggs earn income; use E at the blue pad without cargo to collect it.

If the terminal reports the port is already in use, a server may already be running. The Rojo plugin should show the expected project name before you connect.

## Daily workflow

- Edit the managed scripts and modules in this folder (VS Code or Codex), then save. Rojo sends changes to Studio while connected. Restart Play after changing a ModuleScript because `require` caches it for that running session.
- Make map and asset changes in Studio. Save the `.rbxl` place after editing.
- Avoid editing managed scripts inside Studio: disk files are their source of truth.
- A generated Rojo build contains only the mapped scripts. It does not contain your Studio-built map or glider. Continue using the existing place, rather than replacing it with a scripts-only build.
- New script files outside mapped folders need a mapping in `default.project.json` before they sync. Files in `scripts/guardian` are already covered by its folder mapping.

## Imported egg models

The three active art templates are `ServerStorage/EggModels/CommonEgg`, `UncommonEgg` and `RareEgg`. Each template can be a MeshPart, another BasePart, or a Model containing the parts of one egg. RareEgg reuses a spare imported design; the unused originals remain preserved.

EggLoop clones these templates, scales their height to 4 studs, and uses them for the island pickups and carried eggs. Meshes and textures are preserved; imported scripts, prompts, and joints are removed from the runtime clones. If a template is missing or invalid, its route keeps the prototype egg and prints a setup warning.

After editing templates, restart Play. Common remains visible and available to other players when picked up, with a three-second personal cooldown after placement. Uncommon respawns after three seconds and Rare after twenty seconds following placement/slap, each with a new exclusive offer identity. Reset while carrying to check cleanup. HomeIsland remains the camp floor. EggIsland and ChallengeIsland are invisible spawn markers on the imported Meadow islands; keep these named Parts.

## First Meadow route

The first playable biome is in the same place as camp. PortalLoop creates a green camp portal and blue return portal at runtime. Hold E briefly to travel. Players must place cargo before entering Meadow again; returning to camp preserves the glider and carried egg. Portals check distance and living characters on the server and have a two-second cooldown.

PortalTravel fades the screen and checks that the actual landing floor is present. The server prefetches the destination and adds a temporary per-player replication focus, retaining the distant area through arrival and removing the focus on completion, cancellation, death or disconnect. The server holds the character in place until the client confirms arrival, then restores movement. Missing floors, interrupted clients, and death cancel the trip and release the character. Server deadlines are 24 seconds to prepare and 12 seconds to confirm arrival; client checks allow 20 and 10 seconds respectively, with a 40-second presentation watchdog; clients cannot choose destinations or start travel by sending acknowledgements. No cross-place teleport or separate server is used.

The `regions` table in PortalLoop defines generous flight volumes around camp and Meadow. Players receive a warning within 75 studs of an edge; leaving the volume returns them to their current biome's landing area. Biome membership is server-owned. Egg pickup requires Meadow membership, placement/collection requires camp membership, and both are blocked during travel. The shared portal checks the private server rebirth count against its minimum requirement before loading and again before arrival. Meadow requires zero. Set the authored `SharedCamp/Anchors/MeadowPortal.RequiredRebirths` before Play; the runtime field receives that value. Higher counts retain access to earlier biomes. No rebirth/reset transaction or advanced biome is playable yet.

`Workspace/Map/Meadow` contains the entrance island and landing floor (`MeadowEntrance`), the common egg island, and the farther/higher uncommon egg island. Fly between them with the existing glider. HUD objectives follow the player's CurrentBiome attribute and cargo.

The original imported island, five-egg pack, and prototype floors are preserved in `ServerStorage/ImportedAssetBackups`. The working islands use only natural terrain, trees, and rocks; the imported booth scripts, prompts, buildings, and extra spawn are excluded. The other three egg designs remain in `ServerStorage/EggModels/UnusedEggPack`.

`scripts/setup/MeadowScene.studio.lua` records the one-time Edit-mode setup used through Studio MCP. It is not mapped by Rojo and does not run during play. Do not rerun it on the configured scene. Save the place in Studio after map changes; filesystem code and a scripts-only Rojo build do not save the Studio scene.

Portal playtests covered normal entry/return, active flight with cargo, common egg banking, edge warnings and recovery, invalid travel acknowledgements, missing destination floors, death while loading, and a client that stops responding. The checks used one Studio player, with scripted positioning and normal E/Space/W input. Slow-network and multiplayer testing are still needed before release.

## Meadow wind and egg hunting

`Workspace/Map/Meadow/WindGust` is an editable, non-colliding volume between the common and uncommon islands. Its attributes configure the cycle: 5 seconds calm, 1.5 seconds warning, then 2.4 seconds of crosswind. Peak wind adds 64 studs/second along world +X to the existing glider flight target, with a 0.2-second onset and 0.4-second release. The server computes eligibility, excludes dead/anchored/traveling players, and feathers the zone edges. Wind causes no damage and does not remove eggs. Timing and strength changes take effect on the next Play session. Strength is capped at 80 so the base glider can countersteer.

The world sign, two guide rails, nearby HUD message, wing banking, and 22 local leaf shapes make the gust readable. Leaf effects only exist near the zone while in Meadow. The glider's imported movement controller remains otherwise unchanged; adding wind to its target avoids a second force controller fighting its steering. Its pre-change LocalScript is backed up in `ServerStorage/ImportedAssetBackups/GliderClientBeforeWind`.

`Meadow/EggSpawns/CommonEgg` and `UncommonEgg` each contain four invisible, anchored spot markers. Their positions were raycast onto terrain and checked for nearby collidable obstructions. Each source chooses a spot on startup and a different spot after placement, death or release. One egg can be carried at a time. Nearby labels show the display income rate, and a brief pickup message confirms collection. Historical banking tests below predate the display economy.

`scripts/setup/MeadowFun.studio.lua` records the one-time authored scene setup. It is not mapped by Rojo; do not rerun it on the configured map. As with other Studio assets, save the place after editing these markers.

Single-player checks observed sideways drift during a gust, countersteering overcoming it, no damage, wind clearing on exit/portal travel, uncommon banking for 25 coins, changed spawn spots after banking/death, and effect cleanup after respawn. Multiplayer and device-specific flight controls are not verified by those tests.

## Uncommon egg guardian

`Meadow/NestGuardian` now uses the [Opila Bird model](https://create.roblox.com/store/asset/14135165934/Opila-Bird-killer-NPC-garten-of-banban). Only its ten visible mesh parts are used: imported damage, chase, humanoid and respawn logic stay out of the working guardian. The full source is preserved as `ServerStorage/ImportedAssetBackups/OpilaBirdSource`, and the primitive bird is archived as `PrimitiveGuardianBeforeOpila`. Our invisible `Body` root, status sign, home position, AI and difficulty settings remain in place. `scripts/setup/OpilaGuardian.studio.lua` records this one-time Edit setup; do not rerun it on the configured scene. Save the place to retain the art.

`guardian/Appearance.lua` owns the imported shoulder-hinge flapping, wings-up warning, downstroke slap and orange windup highlight. It supports the archived primitive bird for development fixtures. This presentation module does not decide hits, rewards or target selection. The old laser-like `GuardianAttackLane` remains archived; attacks do not draw a lane.

Carrying the uncommon egg within 300 studs of the nest starts a pursuit. After a 0.55-second alert, the bird chases at 145 studs/second. It raises its wings and flashes orange for 0.35 seconds, then launches at 245 studs/second. Aim is calculated at launch with bounded velocity interception, so steady flight and tiny movements during the warning cannot easily fool it. Once launched, its direction stays fixed: make a sharp turn or altitude change to dodge. It recovers for 0.6 seconds after missing, then tries again while you still carry the egg nearby. Fly outside its territory to escape; an already-launched swoop finishes before checking that boundary. Returning with the egg starts another pursuit. Missed attacks, blocked approaches and elapsed time do not make a carried egg immune. Common eggs do not trigger the guardian.

`NestGuardian.server.lua` is a four-line entry point. `scripts/guardian/Config.lua` owns difficulty settings, `Controller.lua` owns pursuit states and validated hits, `Flight.lua` owns movement/queries, `Appearance.lua` owns wing poses/attack flash, and `Knockback.lua` owns temporary character forces and their cleanup. Rojo maps these modules into ServerScriptService. See `docs/code-organization.md` for the boundaries and Roblox references.

The bird's server script uses swept sphere queries against collidable scenery and relative swept hit detection against its target. Attacks do not pass through walls; movement tries an outward/tangential slide if climbing is blocked. This is a simple open-sky prototype, not general navigation through caves or mazes. A confirmed hit performs a wing slap and releases the real carried-egg record through the server-only `EggLoop.GuardianCatch` BindableFunction. The egg disappears at impact and its source respawns after three seconds. HUD chase messages take priority over the wind banner.

The return path first climbs to 20 studs above the higher of the bird's current height and its nest, crosses above the nest, then descends. If an island overhang blocks that ascent, it probes eight horizontal directions and follows a cached detour out from underneath. A return that still cannot finish within eight seconds resets to a checked, unoccupied nest-area position. This recovery is only for returning, never an attack teleport. The bird can acquire an eligible uncommon-egg carrier during return when the approach is clear; a carrier behind an overhang does not interrupt its escape route prematurely. `ReturnClearance` and `ReturnTimeout` live in the guardian Config module.

The reported stuck bird was observed at approximately `(160.64, 134.92, -2161.60)` with no movement over two seconds in Return. Tests of the production flight module against the real island got it home from that exact position in about 2.2 seconds and from beneath the center in about 2.6 seconds. An actual steal/escape/re-entry sequence reacquired the carrier during Return and completed another escape/return. A confirmed slap still removed cargo with health/coins unchanged and returned to patrol. A fully enclosed return in the live controller recovered to the nest after about eight seconds. Temporary fixtures were removed. Evidence is in `tmp/guardian-return-recovery-playtest-results.json`; these are single-player prototype tests.

The slap adds a 0.42-second decaying `LinearVelocity` shove away from the bird, starting at 72 studs/second horizontally with 26 studs/second of upward lift. A brief character highlight and wing motion confirm contact. The glider yields its force while the character's server-owned `GuardianKnockbackUntil` deadline is active, then resumes flight and steering. Normal automatic character network ownership is retained; the client does not decide hits or egg loss. Death, character removal, portal travel or anchoring cancel the temporary force. Health and banked coins are unchanged.

The faster modular guardian was checked against straight native W flight at about 102 studs/second (caught on the first swoop), a six-stud pre-launch sidestep (caught on the first swoop), a scripted 40-stud perpendicular turn after launch (egg retained), and a temporary solid wall inserted after launch (egg retained). Force/attachment/deadline cleanup passed, including death during an active shove. The fast movement sweep checks the unobstructed portion of a step before stopping at a floor/wall, avoiding missed contact when both lie in the same step. No attack lane or runtime errors were observed. Results are in `tmp/guardian-fast-flight-playtest-results.json`. These scripted scenarios establish behavior, not final difficulty balance.

Slap checks observed egg removal at impact, approximately 27 studs of ground knockback and 25 studs during flight, temporary glider force suppression followed by normal W steering, and force/attachment/deadline cleanup during death. No runtime errors appeared. `tmp/guardian-slap-playtest-results.json` records these single-player observations; multiplayer and mobile behavior are not verified.

Trees on all three Meadow islands are decorative pass-through scenery: their parts have CanCollide, CanTouch and CanQuery disabled, letting both players and the guardian move through them. Terrain and rocks retain their collision. `scripts/setup/MeadowTreeCollision.studio.lua` records the Edit-mode update; original settings are kept as attributes on each tree part. Save the place to retain this map change.

The tree/pursuit fix was checked with a ground catch inside a tree trunk, five repeated attack attempts over approximately 18 seconds (including a blocked swoop), leaving the leash with cargo then returning and being reacquired, and death clearing the pursuit. All 183 parts across 51 trees were non-colliding, non-touching and non-querying; terrain collision remained enabled. Results are in `tmp/guardian-tree-fix-playtest-results.json`. The historical 12-second escape rule in the original test report is superseded by territory-based pursuit.

Observed single-player checks: stationary catch; locked-direction dodge and escape; return through portal and banking for 25 coins; temporary obstacle blocking a swoop; death/respawn clearing cargo, wind, leaves and HUD state; egg source returning; bird returning to patrol. Wind retest reached 64 studs/second and displaced an idle flying character about 83 studs, while native A input could overcome the crosswind. Tests used scripted positions and native E/Space/A input; they do not establish difficulty balance, mobile controls, slow-network behavior or multiplayer correctness. Evidence is in `tmp/guardian-playtest-results.json`.

## Glider boost and camp workshop

Equip the glider and press Space to fly, then press Shift for a burst. The boost button uses the same request path; R1 is also bound while flying. Boost adds 70 studs/second along the current flight direction (camera forward when hovering) through the existing movement controller. Steering and Meadow wind remain available. The meter drains during the burst, then fills during recharge. The server owns cooldown deadlines and purchased levels; clients send an empty request, never a duration or price.

| Boost level | Upgrade price | Burst duration | Recharge after burst |
| --- | --- | --- | --- |
| 0 — free | 0 | 1.2 seconds | 6 seconds |
| 1 | 500 coins | 1.5 seconds | 5.5 seconds |
| 2 | 5,000 coins | 1.8 seconds | 5 seconds |
| 3 | 50,000 coins | 2.1 seconds | 4.7 seconds |
| 4 | 250,000 coins | 2.4 seconds | 4.4 seconds |
| 5 — maximum | 1,000,000 coins | 2.7 seconds | 4.2 seconds |

At camp, hold E at the **Boost Workshop**, in the shared north plaza, to buy the next level. Each player sees their own next price. Purchases validate a living nearby character, camp membership, travel state and funds on the server; checking funds, deducting coins and increasing the private level do not yield. Insufficient funds and maximum level have explicit feedback. Upgrades survive character respawns within the current server, but coins and upgrades reset when the server session ends. Persistence is not implemented yet.

Portal travel, death, unequipping, stopping flight, anchoring and a bird slap cancel an active burst. Cancellation keeps the existing cooldown, so respawning or toggling the tool cannot repeatedly reset it. Knockback suppresses boost and the glider's normal force until the slap ends. The imported glider is sandboxed; it reads server-approved character speed/deadline attributes instead of requiring our unsandboxed module. Its original server Script is backed up in `ServerStorage/ImportedAssetBackups/GliderServerBeforeBoost`.

The new UI shell is editable under StarterGui and is sourced from `ui/GliderBoostHUD.model.json`. Ability input/controller, UI rendering, shared tuning and server transactions have separate files; see `docs/code-organization.md`. `scripts/setup/BoostWorkshop.studio.lua` records the authored camp fixture and is not mapped as a runtime script. Save the place in Studio for the workshop/model changes; Rojo's validation build is still scripts/UI only.

Single-player tests observed a roughly 169-stud/second free burst, about 1.15 seconds active at the sample rate, no extension from repeated Shift input, correct purchase costs, invalid-payload and grounded-request rejection, common egg banking for 10 coins, active-boost cancellation during portal travel with cargo retained, death/respawn with cooldown and level retained, and unequipping/re-equipping. Crosswind reached 64 while boost contributed to the same target. A bird hit during boost removed the egg, cancelled boost, suppressed movement force and cleaned up after impact. The final UI layout was checked against five simulated safe-area sizes without boost overlapping the objective, cargo or wind banner; desktop and portrait arrangements were visually inspected. These are geometry checks, not actual phone/controller flight verification. Results are in `tmp/glider-boost-playtest-results.json`.

Read `docs/gameplay-research.md` for research sources, design hypotheses, next progression ideas and the deferred mid-air PvP theft plan.

## Flower Pillow display foundation

The [Flower Pillow asset](https://create.roblox.com/store/asset/15490887339/Flower-Pillow) is imported as an unchanged backup in `ServerStorage/ImportedAssetBackups/FlowerPillowSource`. A normalized, anchored, non-colliding template lives in `ServerStorage/DisplayModels/FlowerPillow`. Its six petals have `PillowTint = true`; the yellow center has it set to false, so rarity changes preserve the center.

Each of the six gardens has six slots in `Workspace/CampPlots/PlotN/Slots`, along its outer edge. Each has a `Pillow`, invisible `SlotRoot` and `EggAnchor` attachment marking the displayed egg’s bottom. Pillows are seven studs wide and retain their mesh proportions. Their CanCollide, CanTouch and CanQuery properties are disabled.

`PillowColors` renders a slot's `EggRarity` attribute, or its `DisplayedEgg` child's `Rarity` attribute. It also recognizes the existing Common Egg / Uncommon Egg names. Empty is the original pink; Common is cream, Uncommon green, Rare blue, Epic purple, Legendary gold and Mythic rose. Future rarities have colors only; they are not implemented egg routes. The module handles only appearance, never currency or egg ownership.

For a replacement pillow, keep the slot and EggAnchor structure, replace the `Pillow` model and mark its tintable BaseParts with `PillowTint = true`. Keep center/detail parts false. `PillowColors` refreshes when the replacement model or displayed egg is added/removed. The source template and authored clones are Studio-managed; save the place after editing them. `scripts/setup/FlowerPillows.studio.lua` records the one-time layout setup and is not a runtime script.

The display economy now replaces the old 10/25-coin delivery cash-out. See the controls and limits below. Historical banking and boost-price observations above describe the earlier prototype.

Studio checks covered all six tintable petals, yellow-center preservation, Common-name detection, live Uncommon/Rare changes, unknown-rarity fallback, egg removal, explicit slot rarity changes and reset to empty. All pillow parts remained non-colliding/non-touching/non-querying. Lint and Rojo build passed. The attempted scene screenshot did not return, so no visual screenshot approval is claimed.

## Egg placement and online income

- Hold **E** at an empty pillow to place a carried egg in that slot. E at the blue pad with cargo selects the first empty pillow. Placement gives no immediate coins.
- Common eggs earn **1 coin/sec**; Uncommon eggs earn **3 coins/sec**. The separate Rare pickup rolls **100–1000/sec** with Low/High tiers and an income-dependent size. Copies of Common can be collected by different players concurrently; exclusive Uncommon/Rare sources have one carrier at a time. Earnings accumulate while you explore; the coin HUD shows total rate and ready earnings. See `docs/egg-offers.md` for roll ranges, weights, lifecycle and test evidence.
- Use **E** at the blue pad without cargo to collect the whole accumulated amount. Fractions are retained, so repeated collection cannot duplicate or discard income.
- Six full pillows preserve your carried egg and show feedback. At a selected occupied pillow, hold **E for 1.2 seconds** to replace it and sell the previous egg, or hold **F for 1.2 seconds** to sell it. Sale values are 10/25 coins for Common/Uncommon. The prompt states the sale value before replacement; the blue pad never automatically replaces an egg.
- Displayed eggs survive character death and are protected from the bird and PvP. Carried eggs remain at risk. Boost has five paid levels from 500 to 1,000,000 coins as initial tuning for Rare income.

`scripts/collection/Controller.lua` owns private display records, plot ownership and transactions; `Income.lua` owns elapsed-time accounting; `Config.lua` owns rates/sale values; `Visuals.lua` freezes cargo clones onto the authored anchors. `PillowAppearance.lua` remains presentation only. EggLoop owns carried eggs and releases their source after a successful display transaction. Neither client attributes nor visible display models determine payouts.

There are **six personal plots with separate server ownership and session-only income**. Joining assigns a free plot; only its owner can place, sell, replace or claim there. Other gardens’ prompts are hidden locally, with independent server validation. Leaving clears only that garden and makes it available again. A seventh player waits for a free plot; the published experience’s maximum-player setting has not been changed. Character respawns keep plots, eggs, coins and upgrades in-session. Stopping Play ends the session. Saving, offline income and the rebirth/reset action remain future work.

Occupied pillows offset the native **E Replace** and **F Sell** cards into separate rows at -55/+55 pixels. Empty pillows show a single centered E prompt. Each key still uses native prompt exclusivity, and sale/replace holds and server validation are unchanged.

Studio Play checks with one player and normal E/F input covered direct pillow and blue-pad delivery, both rates/colors, six consecutive deliveries, seventh-egg retention, explicit replacement/selling, income-funded purchases at both new prices, protection of displayed eggs and respawn retention. A deterministic test exercised fractional collection and rate changes in the production ledger. HUD geometry passed five simulated safe-area sizes after fixing a 640x480 notice overlap; this is not actual mobile/controller testing. Native flight/boost remained available. Evidence: `tmp/egg-collection-playtest-results.json`. No new game-script errors were observed. Temporary AssistantCommand assertions were retried after correcting pickup-input timing, allowing the existing portal cooldown and sampling boost acceptance through its cooldown instead of after its short burst ended.

## Classic studded ground

Camp, the Meadow landing floor and the three green island-top unions have a named `StuddedGround` Texture on their top faces. The [Classic stud texture](https://create.roblox.com/store/asset/18878366001/Classic-stud-texture) resolves to image `18878365966`; its original Decal is preserved as `ImportedAssetBackups/ResolvedClassicStudTexture`. Tiles repeat every four studs, use the existing floor tint and have 0.12 transparency. No extra stud Parts or floor collision changes are added. Original material/variant/top-surface values are preserved in `GroundOriginal*` attributes. `scripts/setup/StuddedGround.studio.lua` records the repeatable Edit styling step.

The Opila skin passed a native uncommon-egg pickup/slap/return test, including the orange Windup flash, server knockback deadline, egg removal, unchanged 100 health and return to Patrol. Both wings moved during patrol. All working mesh parts are anchored and non-colliding, with no imported scripts or humanoid. Pillow placement and F selling still worked; occupied offsets and empty reset were verified. Bird meshes/textures and the ground image all loaded successfully when preloading the actual streamed Instances. MCP screenshots rendered the screen HUD but a black 3D viewport, even though the user confirmed Studio's game was visible; visual approval of the art/texture and native prompt rectangles is therefore still a user check. Tests used one player with scripted positions; phone/controller/multiplayer are not verified. Evidence: `tmp/opila-prompts-ground-playtest-results.json`.

## Shared camp and future floors

The 256-by-336-stud camp has six 76-by-76-stud fenced gardens, three on each side of a shared walkway. Gates face the public corridor. Each garden has six flower pillows, owner signage and its own blue placement/collection pad. The workshop and Meadow portal are in the public north plaza; spawn and portal return land in public space. Light/dark green checker tiles use the existing stud texture. Wood fences define walking boundaries while retaining glider access.

`scripts/setup/SharedCamp.studio.lua` records the one-time Edit migration. Native scene backups and a reusable plot template live in `ServerStorage/ImportedAssetBackups/BeforeSharedCamp`. Save the place in Studio after map changes. Historical solo setup scripts should not be rerun on the shared scene.

Each garden has `Presentation/PlotOrigin/UpperFloorAnchor` for a future upper deck. No second playable floor, additional biome or rebirth/reset action is implemented yet. See `docs/rebirth-progression.md`.

Executed checks: one Play client completed shared-portal entry/return with cargo, owner-pillow placement, private-pad income collection, a shared-shop upgrade and respawn retaining its plot/egg. A requirement of 1 blocked rebirth 0 and accepted rebirth 2. A separate Edit fixture used Player test doubles and actual cloned plots to check independent 1/3-per-second ledgers, wrong-owner/forged-attribute rejection, range/death/debounce rejection and release/reclaim cleanup. These are not network multiplayer tests.

Evidence: `tmp/shared-camp-playtest-results.json` and `tmp/shared-camp-preview.jpg`. A later actual two-client StudioTestService run verified separate plots, concurrent Common copies, an exclusive Rare race and separate display income; see `tmp/egg-offers-playtest-results.json`. The remaining join/leave, purchases and targeted-visibility matrix is in `docs/shared-camp-testing.md`. The published maximum-player setting is unchanged. Before publication, complete that matrix and configure the experience's server capacity to six.

## Sky gear, stuns and mid-air stealing

The public `SkyGearShop` has a 5,000-coin bat counter and 3,000-coin egg shield counter. Hold E to buy. Gear/charges stay per player and survive character respawn in this session; Slap is free. In Meadow, use **Q slap**, **R bat**, **F steal** and **G shield**, with the glider still equipped. HUD buttons use the same request path; D-pad left/up/right/down bind these actions.

Base camp and the Meadow landing are safe. Slap/bat briefly stun and shove without removing health or eggs, with recovery protection against repeat hits. F transfers the real carried egg only when both players are airborne with approved gliders, close/in front, and unobstructed. The thief needs empty hands. Identity, rolled income/tier/size and the exclusive source reservation follow the egg. The new owner gets six seconds of theft protection. G spends one charge for twelve seconds of theft protection, with a blue glow/countdown; the guardian and knockback still work.

Server rules, forces, cosmetic effects and input have separate combat modules. `SkyCombatHUD` is editable in StarterGui and comes from `ui/SkyCombatHUD.model.json`. Working bat/hand visuals exclude imported Lua, remotes and physics; original sources remain backed up. `scripts/setup/SkyGear.studio.lua` records the native authoring step. Save the place for shop/assets.

The free slap glove is held upright by its handle in the left hand, while the glider keeps the right-hand Tool grip. Q selects the glove and slaps; R selects the purchased bat and swings. Only one weapon is held at a time, and it remains visible after the swing. `combat/HeldWeapon.lua` owns the replicated prop and respawn cleanup; `combat_client/WeaponPose.lua` evaluates each viewer's arm pose from server-approved timestamps. Both weapons have windup, contact, follow-through and recovery. The glove uses the art from [Slap Glove Tool](https://create.roblox.com/store/asset/120133129723048/Slap-Glove-Tool), with its imported R6 scripts, remotes, animations, sounds and hitboxes removed. The prior hand template is archived in ServerStorage. Save the Studio place to retain the new native template. See `docs/bat-presentation.md` for the held-weapon implementation and verification.

Research, coin-spending ideas, prices and controls are in `docs/economy-and-air-pvp.md`. An actual two-client native-input test passed purchases, safe-base rejection, slap/bat stuns and cleanup, shield protection, grounded-theft rejection, airborne Rare transfer, take-back protection, former-owner respawn and new-owner display income. A High Rare retained 832/sec, tier, scale and identity. Final single-client checks verified the glow/countdown and charge consumption. Evidence: `tmp/sky-combat-playtest-results.json`. Six-player stress, slow networks, complete phone/controller flight and final balance remain unverified. Saving is still future work.

## Camp perimeter walls

`SharedCamp/PerimeterWalls` encloses the shared base on all four sides with closed corners. Walls are four studs thick and rise 48 studs above the camp floor; the sky remains open overhead. Interior faces use the same light/dark green 16-stud checker panels and four-stud repeating stud texture as the ground. Four solid wall Parts provide collision; decorative checker panels do not collide or answer queries. The shop, portals and six plots remain inside the enclosure.

`scripts/setup/CampWalls.studio.lua` records the authored Edit change. Raycast checks confirmed collision on each side and at all four corners, and the result was visually inspected in Studio. Save the place to retain these map objects.

## Sunless blue sky

Base Camp and Meadow share `Lighting/Sunless Blue Sky Skybox`, imported from Creator Store asset 591067775. All six face textures loaded successfully. Celestial bodies are hidden so no sun/moon disc is drawn; other lighting settings stay as authored. The previous Sky is preserved in `ServerStorage/ImportedAssetBackups/BeforeSunlessBlueSky`. The Edit-mode change is recorded in `scripts/setup/SunlessBlueSky.studio.lua`; save the place in Studio to retain it.

## Toolchain

Rojo is pinned to **7.6.1** in `rokit.toml`. On another computer, install Rokit and run `rokit install` from this folder.
The VS Code Rojo and Luau language-server extensions and the Studio Rojo plugin are installed on this computer.

## Backup

`backups/GlideAndGrab_before_Rojo_2026-10-13.rbxl` is an exact copy of the saved place before migration.
The `backups` and `tmp` folders are excluded from Git.
This setup does not add player-progress saving; test coins still reset between server sessions.

References: [Rojo workflows](https://rojo.space/docs/v7/workflows/), [project format](https://rojo.space/docs/v7/project-format/).
