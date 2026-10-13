# Glide & Grab

This is a scripts-only Rojo project connected to the existing Roblox Studio place.
Open `GlideAndGrab_Prototype.rbxl` to build the map and playtest the game.

## What Rojo syncs

| File | Existing Studio object |
| --- | --- |
| `scripts/EggLoop.server.lua` | `ServerScriptService/EggLoop` |
| `scripts/FlightHUD.client.lua` | `StarterPlayer/StarterPlayerScripts/FlightHUD` |

The source files were checked against and imported from the saved place. No gameplay changes were made during migration.
Workspace, StarterPack, the imported glider and its scripts, StarterGui, and other services remain managed in Studio.
The project explicitly preserves unknown instances at every mapped level.

## Connect Studio

1. Stop any running playtest and open the existing place.
2. If the sync server isn't running, use VS Code: Terminal > Run Task > **Rojo: Serve Glide & Grab**. Alternatively run `rojo serve default.project.json` in a terminal in this folder.
3. Open the Rojo plugin in Studio's Plugins tab.
4. Connect to **127.0.0.1**, port **34872**. Confirm the project is **Glide & Grab**.
5. If Rojo displays a proposed sync, it should manage only EggLoop and FlightHUD. There should be no proposed deletions of map parts or the glider.
6. Apply the script sync, then press Play. Bank a Common Egg for 10 coins and an Uncommon Egg for 25 coins.

If the terminal reports the port is already in use, a server may already be running. The Rojo plugin should show the expected project name before you connect.

## Daily workflow

- Edit the two managed scripts in this folder (VS Code or Codex), then save. Rojo sends changes to Studio while connected.
- Make map and asset changes in Studio. Save the `.rbxl` place after editing.
- Avoid editing managed scripts inside Studio: disk files are their source of truth.
- A generated Rojo build contains only the mapped scripts. It does not contain your Studio-built map or glider. Continue using the existing place, rather than replacing it with a scripts-only build.
- New script files need a mapping in `default.project.json` before they sync.

## Toolchain

Rojo is pinned to **7.6.1** in `rokit.toml`. On another computer, install Rokit and run `rokit install` from this folder.
The VS Code Rojo and Luau language-server extensions and the Studio Rojo plugin are installed on this computer.

## Backup

`backups/GlideAndGrab_before_Rojo_2026-10-13.rbxl` is an exact copy of the saved place before migration.
The `backups` and `tmp` folders are excluded from Git.
This setup does not add player-progress saving; test coins still reset between server sessions.

References: [Rojo workflows](https://rojo.space/docs/v7/workflows/), [project format](https://rojo.space/docs/v7/project-format/).
