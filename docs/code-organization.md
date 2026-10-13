# Code organization

Roblox's [ModuleScript guide](https://create.roblox.com/docs/scripting/module) documents reusable code, configuration tables and encapsulation. Its [scripting locations guide](https://create.roblox.com/docs/scripting/locations) explains where executable scripts and modules belong. A module runs when required; it is not another automatically running server script.

For this game, split code by responsibility when systems grow. A small cohesive script can stay together. Arbitrary line limits or a separate file for every function would add navigation without improving ownership. Smaller focused modules let us inspect and change the relevant behavior without loading unrelated physics, UI and economy code into context.

## Guardian boundaries

| Disk file | Responsibility |
| --- | --- |
| `scripts/NestGuardian.server.lua` | Start the guardian once; four-line server entry point. |
| `scripts/guardian/Config.lua` | Difficulty defaults and bounded model-attribute overrides. |
| `scripts/guardian/Controller.lua` | Target eligibility, pursuit states, hit validation and lifecycle. |
| `scripts/guardian/Flight.lua` | Bird movement, obstacle sweeps, velocity interception, contact math and wing pose. |
| `scripts/guardian/Knockback.lua` | Character shove, feedback and temporary-force cleanup. |

These four modules live in `ServerScriptService/GuardianModules`, mapped by Rojo from the guardian folder. The controller requires the other modules; they do not require the controller. `EggLoop.GuardianCatch` retains ownership of the private carried-egg record and rewards. Flight cannot remove eggs, and clients cannot authorize a hit.

The project already separates egg collection, portals, wind, HUD and glider controls. We extracted the growing guardian now because AI and character physics have clear independent responsibilities. Future egg persistence or progression should have its own module boundary when implemented; no framework migration is needed for this change.

`require` caches a module in each running environment. Restart Play after changing modules. Save files for Rojo to sync code, and save the place in Studio for map/model changes. A scripts-only Rojo build is a validation artifact, not a replacement for the authored place.

## Boost boundaries

| File | Responsibility |
| --- | --- |
| `scripts/GliderBoost.server.lua` | Private upgrade levels, eligibility, cooldowns, cleanup and camp transactions. |
| `scripts/GliderBoost.client.lua` | Input context, request submission, character rebinding and personal shop text. |
| `scripts/boost/Config.lua` | Shared boost timing, speed and price definitions. |
| `scripts/boost/HUD.lua` | Responsive layout, meter/status rendering and brief notices. |
| `ui/GliderBoostHUD.model.json` | Authored, editable UI hierarchy; mapped into StarterGui. |
| `scripts/glider/Glider.server.lua` | Imported tool controller; also exposes validated `IsGliding` on the equipped tool. |
| `scripts/glider/Glider.client.lua` | Imported flight controller; mixes approved boost with momentum and wind, yielding during knockback. |

Shared boost modules live in ReplicatedStorage. The sandboxed imported glider cannot require an unsandboxed module: it reads the server's character attributes instead. Server boost/purchase validation uses private records and server-approved tool state. Progress remains session-only; future persistence should load/save these records without moving transaction authority into UI code.
