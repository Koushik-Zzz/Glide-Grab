# Glide & Grab

This is a scripts-only Rojo project connected to the existing Roblox Studio place.
Open `GlideAndGrab_Prototype.rbxl` to build the map and playtest the game.

## What Rojo syncs

| File | Existing Studio object |
| --- | --- |
| `scripts/EggLoop.server.lua` | `ServerScriptService/EggLoop` |
| `scripts/PortalLoop.server.lua` | `ServerScriptService/PortalLoop` |
| `scripts/FlightHUD.client.lua` | `StarterPlayer/StarterPlayerScripts/FlightHUD` |
| `scripts/PortalTravel.client.lua` | `StarterPlayer/StarterPlayerScripts/PortalTravel` |
| `scripts/MeadowWind.server.lua` | `ServerScriptService/MeadowWind` |
| `scripts/NestGuardian.server.lua` | `ServerScriptService/NestGuardian` |
| `scripts/guardian/*.lua` | `ServerScriptService/GuardianModules` (four ModuleScripts) |
| `scripts/MeadowWind.client.lua` | `StarterPlayer/StarterPlayerScripts/MeadowWind` |
| `scripts/glider/Glider.client.lua` | `StarterPack/Glider/LocalScript` |
| `scripts/glider/Glider.server.lua` | `StarterPack/Glider/Script` |
| `scripts/GliderBoost.server.lua` | `ServerScriptService/GliderBoost` |
| `scripts/GliderBoost.client.lua` | `StarterPlayer/StarterPlayerScripts/GliderBoost` |
| `scripts/boost/*.lua` | `ReplicatedStorage/BoostModules` (Config and HUD ModuleScripts) |
| `ui/GliderBoostHUD.model.json` | `StarterGui/GliderBoostHUD` (editable UI template) |

The source files were checked against and imported from the saved place. No gameplay changes were made during migration.
Workspace, the glider model and its mouse script, the rest of StarterGui, and other assets remain managed in Studio. The glider's LocalScript and server Script are owned by Rojo so wind/boost can contribute to its flight target and the server can track flight state. The boost HUD template is also owned by Rojo.
The project explicitly preserves unknown instances at every mapped level.

## Connect Studio

1. Stop any running playtest and open the existing place.
2. If the sync server isn't running, use VS Code: Terminal > Run Task > **Rojo: Serve Glide & Grab**. Alternatively run `rojo serve default.project.json` in a terminal in this folder.
3. Open the Rojo plugin in Studio's Plugins tab.
4. Connect to **127.0.0.1**, port **34872**. Confirm the project is **Glide & Grab**.
5. If Rojo displays a proposed sync, it should manage the eleven executable scripts, six ModuleScripts and boost HUD template listed above. There should be no proposed deletions of map parts or the glider's art. Reconnect Rojo if it reports a network or `InstanceMap` warning.
6. Apply the script sync, then press Play. Enter the green Meadow portal, glide to an egg island, return through the blue portal, and bank at camp for 10 or 25 coins.

If the terminal reports the port is already in use, a server may already be running. The Rojo plugin should show the expected project name before you connect.

## Daily workflow

- Edit the managed scripts and modules in this folder (VS Code or Codex), then save. Rojo sends changes to Studio while connected. Restart Play after changing a ModuleScript because `require` caches it for that running session.
- Make map and asset changes in Studio. Save the `.rbxl` place after editing.
- Avoid editing managed scripts inside Studio: disk files are their source of truth.
- A generated Rojo build contains only the mapped scripts. It does not contain your Studio-built map or glider. Continue using the existing place, rather than replacing it with a scripts-only build.
- New script files outside mapped folders need a mapping in `default.project.json` before they sync. Files in `scripts/guardian` are already covered by its folder mapping.

## Imported egg models

In Studio, place two individual egg designs directly inside `ServerStorage/EggModels`, named `CommonEgg` and `UncommonEgg`. Each template can be a MeshPart, another BasePart, or a Model containing the parts of one egg. Keep unused designs in a separate pack; do not rename the entire collection as one egg.

EggLoop clones these templates, scales their height to 4 studs, and uses them for the island pickups and carried eggs. Meshes and textures are preserved; imported scripts, prompts, and joints are removed from the runtime clones. If a template is missing or invalid, its route keeps the prototype egg and prints a setup warning.

After naming the templates, stop and restart Play. Check both pickups, the carried egg and HUD, rewards of 10/25 coins, and the 3-second respawn after banking. Reset while carrying to check cleanup. HomeIsland remains the camp floor. EggIsland and ChallengeIsland are now invisible spawn markers on the imported Meadow islands; keep these named Parts.

## First Meadow route

The first playable biome is in the same place as camp. PortalLoop creates a green camp portal and blue return portal at runtime. Hold E briefly to travel. Players must bank cargo before entering Meadow again; returning to camp preserves the glider and carried egg. Portals check distance and living characters on the server and have a two-second cooldown.

PortalTravel fades the screen, requests streaming around the destination, and checks that its landing floor is present. The server holds the character in place until the client confirms arrival, then restores movement. Missing floors, interrupted clients, and death cancel the trip and release the character. Server deadlines are 10 seconds to prepare and 6 seconds to confirm arrival; clients cannot choose destinations or start travel by sending acknowledgements. No cross-place teleport or separate server is used.

The `regions` table in PortalLoop defines generous flight volumes around camp and Meadow. Players receive a warning within 75 studs of an edge; leaving the volume returns them to their current biome's landing area. Biome membership is server-owned. Egg pickup requires Meadow membership, banking requires camp membership, and both are blocked during travel. Future portal unlock requirements should be added to the server's `usePortal` checks; no rebirth gates exist yet.

`Workspace/Map/Meadow` contains the entrance island and landing floor (`MeadowEntrance`), the common egg island, and the farther/higher uncommon egg island. Fly between them with the existing glider. HUD objectives follow the player's CurrentBiome attribute and cargo.

The original imported island, five-egg pack, and prototype floors are preserved in `ServerStorage/ImportedAssetBackups`. The working islands use only natural terrain, trees, and rocks; the imported booth scripts, prompts, buildings, and extra spawn are excluded. The other three egg designs remain in `ServerStorage/EggModels/UnusedEggPack`.

`scripts/setup/MeadowScene.studio.lua` records the one-time Edit-mode setup used through Studio MCP. It is not mapped by Rojo and does not run during play. Do not rerun it on the configured scene. Save the place in Studio after map changes; filesystem code and a scripts-only Rojo build do not save the Studio scene.

Portal playtests covered normal entry/return, active flight with cargo, common egg banking, edge warnings and recovery, invalid travel acknowledgements, missing destination floors, death while loading, and a client that stops responding. The checks used one Studio player, with scripted positioning and normal E/Space/W input. Slow-network and multiplayer testing are still needed before release.

## Meadow wind and egg hunting

`Workspace/Map/Meadow/WindGust` is an editable, non-colliding volume between the common and uncommon islands. Its attributes configure the cycle: 5 seconds calm, 1.5 seconds warning, then 2.4 seconds of crosswind. Peak wind adds 64 studs/second along world +X to the existing glider flight target, with a 0.2-second onset and 0.4-second release. The server computes eligibility, excludes dead/anchored/traveling players, and feathers the zone edges. Wind causes no damage and does not remove eggs. Timing and strength changes take effect on the next Play session. Strength is capped at 80 so the base glider can countersteer.

The world sign, two guide rails, nearby HUD message, wing banking, and 22 local leaf shapes make the gust readable. Leaf effects only exist near the zone while in Meadow. The glider's imported movement controller remains otherwise unchanged; adding wind to its target avoids a second force controller fighting its steering. Its pre-change LocalScript is backed up in `ServerStorage/ImportedAssetBackups/GliderClientBeforeWind`.

`Meadow/EggSpawns/CommonEgg` and `UncommonEgg` each contain four invisible, anchored spot markers. Their positions were raycast onto terrain and checked for nearby collidable obstructions. Each source egg chooses a spot on startup and a different spot after banking, death, or release. Rewards remain 10/25 coins and one carried egg per player. Nearby egg labels help searching, and a brief pickup message confirms collection.

`scripts/setup/MeadowFun.studio.lua` records the one-time authored scene setup. It is not mapped by Rojo; do not rerun it on the configured map. As with other Studio assets, save the place after editing these markers.

Single-player checks observed sideways drift during a gust, countersteering overcoming it, no damage, wind clearing on exit/portal travel, uncommon banking for 25 coins, changed spawn spots after banking/death, and effect cleanup after respawn. Multiplayer and device-specific flight controls are not verified by those tests.

## Uncommon egg guardian

`Meadow/NestGuardian` is an editable placeholder bird built from parts. The old laser-like `GuardianAttackLane` is archived in `ServerStorage/ImportedAssetBackups`; attacks no longer draw a lane. The one-time setup is recorded in `scripts/setup/NestGuardian.studio.lua`; do not rerun it on this scene. Save the place in Studio to preserve these authored objects.

Carrying the uncommon egg within 300 studs of the nest starts a pursuit. After a 0.55-second alert, the bird chases at 145 studs/second. It raises its wings and flashes orange for 0.35 seconds, then launches at 245 studs/second. Aim is calculated at launch with bounded velocity interception, so steady flight and tiny movements during the warning cannot easily fool it. Once launched, its direction stays fixed: make a sharp turn or altitude change to dodge. It recovers for 0.6 seconds after missing, then tries again while you still carry the egg nearby. Fly outside its territory to escape; an already-launched swoop finishes before checking that boundary. Returning with the egg starts another pursuit. Missed attacks, blocked approaches and elapsed time do not make a carried egg immune. Common eggs do not trigger the guardian.

`NestGuardian.server.lua` is a four-line entry point. `scripts/guardian/Config.lua` owns difficulty settings, `Controller.lua` owns pursuit states and validated hits, `Flight.lua` owns movement/queries/wing poses, and `Knockback.lua` owns temporary character forces and their cleanup. Rojo maps these modules into ServerScriptService. See `docs/code-organization.md` for the boundaries and Roblox references.

The bird's server script uses swept sphere queries against collidable scenery and relative swept hit detection against its target. Attacks do not pass through walls; open-air movement climbs around local obstructions. This is a simple open-sky prototype, not general navigation through caves or mazes. A confirmed hit performs a wing slap and releases the real carried-egg record through the server-only `EggLoop.GuardianCatch` BindableFunction. The egg disappears at impact and its source respawns after three seconds. HUD chase messages take priority over the wind banner.

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
| 1 | 50 coins | 1.5 seconds | 5.5 seconds |
| 2 — maximum | 125 coins | 1.8 seconds | 5 seconds |

At camp, hold E at the **Boost Workshop**, near the spawn, to buy the next level. Each player sees their own next price. Purchases validate a living nearby character, camp membership, travel state and funds on the server; checking funds, deducting coins and increasing the private level do not yield. Insufficient funds and maximum level have explicit feedback. Upgrades survive character respawns within the current server, but coins and upgrades reset when the server session ends. Persistence is not implemented yet.

Portal travel, death, unequipping, stopping flight, anchoring and a bird slap cancel an active burst. Cancellation keeps the existing cooldown, so respawning or toggling the tool cannot repeatedly reset it. Knockback suppresses boost and the glider's normal force until the slap ends. The imported glider is sandboxed; it reads server-approved character speed/deadline attributes instead of requiring our unsandboxed module. Its original server Script is backed up in `ServerStorage/ImportedAssetBackups/GliderServerBeforeBoost`.

The new UI shell is editable under StarterGui and is sourced from `ui/GliderBoostHUD.model.json`. Ability input/controller, UI rendering, shared tuning and server transactions have separate files; see `docs/code-organization.md`. `scripts/setup/BoostWorkshop.studio.lua` records the authored camp fixture and is not mapped as a runtime script. Save the place in Studio for the workshop/model changes; Rojo's validation build is still scripts/UI only.

Single-player tests observed a roughly 169-stud/second free burst, about 1.15 seconds active at the sample rate, no extension from repeated Shift input, correct purchase costs, invalid-payload and grounded-request rejection, common egg banking for 10 coins, active-boost cancellation during portal travel with cargo retained, death/respawn with cooldown and level retained, and unequipping/re-equipping. Crosswind reached 64 while boost contributed to the same target. A bird hit during boost removed the egg, cancelled boost, suppressed movement force and cleaned up after impact. The final UI layout was checked against five simulated safe-area sizes without boost overlapping the objective, cargo or wind banner; desktop and portrait arrangements were visually inspected. These are geometry checks, not actual phone/controller flight verification. Results are in `tmp/glider-boost-playtest-results.json`.

Read `docs/gameplay-research.md` for research sources, design hypotheses, next progression ideas and the deferred mid-air PvP theft plan.

## Toolchain

Rojo is pinned to **7.6.1** in `rokit.toml`. On another computer, install Rokit and run `rokit install` from this folder.
The VS Code Rojo and Luau language-server extensions and the Studio Rojo plugin are installed on this computer.

## Backup

`backups/GlideAndGrab_before_Rojo_2026-10-13.rbxl` is an exact copy of the saved place before migration.
The `backups` and `tmp` folders are excluded from Git.
This setup does not add player-progress saving; test coins still reset between server sessions.

References: [Rojo workflows](https://rojo.space/docs/v7/workflows/), [project format](https://rojo.space/docs/v7/project-format/).
