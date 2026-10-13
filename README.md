# Glide & Grab

This is a scripts-only Rojo project connected to the existing Roblox Studio place.
Open `GlideAndGrab_Prototype.rbxl` to build the map and playtest the game.

## What Rojo syncs

| File | Existing Studio object |
| --- | --- |
| `scripts/EggLoop.server.lua` | `ServerScriptService/EggLoop` |
| `scripts/PortalLoop.server.lua` | `ServerScriptService/PortalLoop` |
| `scripts/FlightHUD.client.lua` | `StarterPlayer/StarterPlayerScripts/FlightHUD` |

The source files were checked against and imported from the saved place. No gameplay changes were made during migration.
Workspace, StarterPack, the imported glider and its scripts, StarterGui, and other services remain managed in Studio.
The project explicitly preserves unknown instances at every mapped level.

## Connect Studio

1. Stop any running playtest and open the existing place.
2. If the sync server isn't running, use VS Code: Terminal > Run Task > **Rojo: Serve Glide & Grab**. Alternatively run `rojo serve default.project.json` in a terminal in this folder.
3. Open the Rojo plugin in Studio's Plugins tab.
4. Connect to **127.0.0.1**, port **34872**. Confirm the project is **Glide & Grab**.
5. If Rojo displays a proposed sync, it should manage only EggLoop, PortalLoop, and FlightHUD. There should be no proposed deletions of map parts or the glider.
6. Apply the script sync, then press Play. Enter the green Meadow portal, glide to an egg island, return through the blue portal, and bank at camp for 10 or 25 coins.

If the terminal reports the port is already in use, a server may already be running. The Rojo plugin should show the expected project name before you connect.

## Daily workflow

- Edit the three managed scripts in this folder (VS Code or Codex), then save. Rojo sends changes to Studio while connected.
- Make map and asset changes in Studio. Save the `.rbxl` place after editing.
- Avoid editing managed scripts inside Studio: disk files are their source of truth.
- A generated Rojo build contains only the mapped scripts. It does not contain your Studio-built map or glider. Continue using the existing place, rather than replacing it with a scripts-only build.
- New script files need a mapping in `default.project.json` before they sync.

## Imported egg models

In Studio, place two individual egg designs directly inside `ServerStorage/EggModels`, named `CommonEgg` and `UncommonEgg`. Each template can be a MeshPart, another BasePart, or a Model containing the parts of one egg. Keep unused designs in a separate pack; do not rename the entire collection as one egg.

EggLoop clones these templates, scales their height to 4 studs, and uses them for the island pickups and carried eggs. Meshes and textures are preserved; imported scripts, prompts, and joints are removed from the runtime clones. If a template is missing or invalid, its route keeps the prototype egg and prints a setup warning.

After naming the templates, stop and restart Play. Check both pickups, the carried egg and HUD, rewards of 10/25 coins, and the 3-second respawn after banking. Reset while carrying to check cleanup. HomeIsland remains the camp floor. EggIsland and ChallengeIsland are now invisible spawn markers on the imported Meadow islands; keep these named Parts.

## First Meadow route

The first playable biome is in the same place as camp. PortalLoop creates a green camp portal and blue return portal at runtime. Hold E briefly to travel. Players must bank cargo before entering Meadow again; returning to camp preserves the glider and carried egg. Portals check distance and living characters on the server and have a two-second cooldown.

`Workspace/Map/Meadow` contains the entrance island and landing floor (`MeadowEntrance`), the common egg island, and the farther/higher uncommon egg island. Fly between them with the existing glider. HUD objectives follow the player's CurrentBiome attribute and cargo.

The original imported island, five-egg pack, and prototype floors are preserved in `ServerStorage/ImportedAssetBackups`. The working islands use only natural terrain, trees, and rocks; the imported booth scripts, prompts, buildings, and extra spawn are excluded. The other three egg designs remain in `ServerStorage/EggModels/UnusedEggPack`.

`scripts/setup/MeadowScene.studio.lua` records the one-time Edit-mode setup used through Studio MCP. It is not mapped by Rojo and does not run during play. Do not rerun it on the configured scene. Save the place in Studio after map changes; filesystem code and a scripts-only Rojo build do not save the Studio scene.

## Toolchain

Rojo is pinned to **7.6.1** in `rokit.toml`. On another computer, install Rokit and run `rokit install` from this folder.
The VS Code Rojo and Luau language-server extensions and the Studio Rojo plugin are installed on this computer.

## Backup

`backups/GlideAndGrab_before_Rojo_2026-10-13.rbxl` is an exact copy of the saved place before migration.
The `backups` and `tmp` folders are excluded from Git.
This setup does not add player-progress saving; test coins still reset between server sessions.

References: [Rojo workflows](https://rojo.space/docs/v7/workflows/), [project format](https://rojo.space/docs/v7/project-format/).
