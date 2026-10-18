# UI audit — 15 October 2026

Sources reviewed: six supplied current-game captures, Oil Empire shop/walls references, two original concept illustrations, the supplied master brief, mapped source files and the running Studio client (1254×494 safe canvas).

## Existing owners

| Surface | Source / authoritative data | Replacement |
| --- | --- | --- |
| Currency, objective, cargo, notices | FlightHUD.client.lua; FlightHUD.model.json; leaderstats.Coins, EggIncomeRate, EggIncomePending | Larger amount, coin icon, separate ready income, bounded reward effects above amount |
| Boost status | boost/HUD.lua; GliderBoostHUD.model.json; BoostUntil/ReadyAt/Level | Golden icon-led status; same flight inputs |
| Q/R/F/G abilities | SkyCombat.client.lua; SkyCombatHUD.model.json | Icon-led states; preserve controls and server combat rules |
| Rebirth | Rebirth.client/server.lua; RebirthHUD.model.json | Camp menu entry; same token confirmation, reset, save transaction |
| Gear purchase | SkyCombat.server.lua, world PurchasePrompt | Menu purchases share the existing transaction; world prompts remain |
| Boost purchases | GliderBoost.server.lua; BoostModules.Config | Current/next effects and five real levels |
| Glider equipment | Roblox Backpack, one Glider Tool | Custom slot only when it can faithfully represent the backpack; fallback if other tools appear |
| World interactions | ProximityPrompt; CampPlots.client.lua manages personal visibility | Shared custom BillboardGui template and native hold/proximity lifecycle |

The current design has stud color treatments but weak icon hierarchy, small money, no browsing menu and generic prompts. Some world signs duplicate HUD instructions. The generated concepts are art direction only: their extra gliders, storage purchases, income multipliers and prices are not features.

## Live catalogue

Slap is free. Bat unlock costs 5,000. Shield charges cost 3,000, maximum three, protect for 12 seconds. Boost levels cost 500 / 5,000 / 50,000 / 250,000 / 1,000,000. Rebirth costs 250,000 and clears all coins, eggs, ready income and boost levels while keeping gear. There is no persistent collectible inventory or glider catalogue.

## Ownership and risks

Rojo owns scripts and JSON StarterGui templates; backup_update.rbxl owns the native scene and meshes. No scene replacement. Git d863f5f preserves the prior UI. New menus will allow purchases throughout Base Camp, with living/profile/travel checks on the server. World purchases still check distance. Expected level/charge state prevents replayed requests advancing an extra upgrade or charging twice. No pricing, save schema, income or combat changes.

Unimplemented inventory and settings menus will not be advertised. Roblox reduced-motion preference is honored. The supplied references are sufficient for art direction; original editable icon geometry avoids new asset permissions or external dependencies.
