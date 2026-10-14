# Code organization

Roblox's [ModuleScript guide](https://create.roblox.com/docs/scripting/module) documents reusable code, configuration tables and encapsulation. Its [scripting locations guide](https://create.roblox.com/docs/scripting/locations) explains where executable scripts and modules belong. A module runs when required; it is not another automatically running server script.

For this game, split code by responsibility when systems grow. A small cohesive script can stay together. Arbitrary line limits or a separate file for every function would add navigation without improving ownership. Smaller focused modules let us inspect and change the relevant behavior without loading unrelated physics, UI and economy code into context.

## Guardian boundaries

| Disk file | Responsibility |
| --- | --- |
| `scripts/NestGuardian.server.lua` | Start the guardian once; four-line server entry point. |
| `scripts/guardian/Config.lua` | Difficulty defaults and bounded model-attribute overrides. |
| `scripts/guardian/Controller.lua` | Target eligibility, pursuit states, hit validation and lifecycle. |
| `scripts/guardian/Flight.lua` | Bird movement, obstacle sweeps, velocity interception and contact math. |
| `scripts/guardian/Appearance.lua` | Imported skin/legacy presentation, shoulder wing poses and windup highlight. |
| `scripts/guardian/Knockback.lua` | Character shove, feedback and temporary-force cleanup. |

These five modules live in `ServerScriptService/GuardianModules`, mapped by Rojo from the guardian folder. The controller requires motion/config/knockback; Flight requires Appearance. They do not require the controller. `EggLoop.GuardianCatch` retains ownership of the private carried-egg record. Motion/presentation cannot remove eggs, and clients cannot authorize a hit.

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

## Collection boundaries

| File | Responsibility |
| --- | --- |
| `scripts/EggLoop.server.lua` | Source pickups and private carried ownership, guardian release and validated handoff to collection. |
| `scripts/collection/Controller.lua` | Six-plot allocation, per-player assignments, waiting list, join/leave cleanup and ledger publication. |
| `scripts/collection/Plot.lua` | One plot's private owner, display/sell/replace/collect transactions, proximity checks, prompts and income ledger. |
| `scripts/CampPlots.client.lua` | Local visibility of personal plot prompts; never authorizes transactions. |
| `scripts/collection/Income.lua` | Elapsed-time ledger; accrue before rate changes; integer claims with fractional retention. |
| `scripts/collection/Config.lua` | Server income and sell-value catalogue; input distances and deliberate hold durations. |
| `scripts/collection/Claims.lua` | Private one-cargo-per-player records, shared/exclusive source reservations and personal Common cooldowns. |
| `scripts/collection/Rolls.lua` | Spawn-time weighted income rolls, bounded size, immutable snapshots and per-egg identities. |
| `scripts/collection/Visuals.lua` | Cargo-clone cleanup, display alignment and labels. |
| `scripts/collection/PillowAppearance.lua` | Rarity colors only. |
| `scripts/PillowColors.server.lua` | Bind authored pillow presentation to displayed-egg/slot changes. |

Rojo maps the collection folder into ServerScriptService/CollectionModules. Private records supply identity/rates; client HUDs read published attributes. Future persistence should restore those private records and rebuild visuals, never reconstruct ownership or pay rates from client-visible models.

Rolled Economy snapshots travel in the private carried record. Plot validates that snapshot against the catalogue and consumes it without rerolling or reading an IncomeRate Attribute. The display retains its EggId, EggTier and EggScale. Shared Common pickups have independent records/IDs; exclusive offers reserve one source until it is released and respawns.

## Progression and shared facilities

`scripts/progression/Progression.lua` is a server-only session rebirth record, mapped under ServerScriptService/ProgressionModules. PortalLoop checks `canEnter(player, required)` before departure and again before arrival. Counts use a minimum threshold, never equality or a client-provided number. Meadow starts at zero; no client rebirth setter exists. A future server rebirth transaction and persistence loader must update these records.

The workshop is public but its existing private boost levels, prices and cooldowns stay per player. Each plot's ledger is a separate closure, never shared through a pad or mutable owner attribute. The authored shared scene remains Studio-owned; setup files record migrations and do not execute at runtime.

## Air combat boundaries

| File | Responsibility |
| --- | --- |
| `scripts/SkyCombat.server.lua` | Private gear purchases/charges, limits, server-picked hits and theft outcomes. |
| `scripts/combat/Config.lua` | Costs, safe zones, reach, cooldowns and stun tuning. |
| `scripts/combat/Rules.lua` | Alive/biome/arrival eligibility, ground clearance, facing and line-of-sight queries. |
| `scripts/combat/Impact.lua` | Temporary LinearVelocity/stun, restoration and interruption cleanup. |
| `scripts/SkyCombat.client.lua` | Keyboard/gamepad/button intents, shop text and ability presentation. |
| `scripts/combat_client/Effects.lua` | Brief local bat/hand swings without gameplay authority. |
| `ui/SkyCombatHUD.model.json` | Editable four-action GUI. |

EggLoop's server-only HasCargo, ProtectCargo and TryAirSteal bindings use private Claims records. Claims transfers a record atomically while preserving Economy/EggId and the exclusive source lock. EggLoop replaces welds/death binding so the former owner's lifecycle cannot release the new owner's cargo. Glider/boost read server character deadlines to yield during combat. A guardian slap clears a player stun before taking over physical motion; player actions exclude active guardian knockback.
