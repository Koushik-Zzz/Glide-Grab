# Coin spending and mid-air PvP — 14 October 2026

## Research and direction

[Roblox's virtual-economy guide](https://create.roblox.com/docs/production/game-design/balance-virtual-economies) recommends planning sources and sinks together, estimating reward impact and measuring purchases, currency earned/spent and time to useful purchases. Its examples include cosmetic/event spending. [Roblox's core-loop guide](https://create.roblox.com/docs/production/game-design/core-loops) connects repeated actions to a progression engine. For this game, spending should improve flight, escapes or the collection's presentation.

Our current Rare roll has an expected income of 412.5/sec: Low mean 300 × 75% plus High mean 750 × 25%. Six average Rares produce 2,475/sec; six maximum Rares produce 6,000/sec. Raising every price indiscriminately would make Common/Uncommon-only players wait while barely slowing a full Rare collection.

The following are design choices for this prototype, not prices copied from another game:

| Spending option | Purpose | Status |
| --- | --- | --- |
| Boost upgrades | Better escape bursts; increasing costs give Rare collectors later goals | Implemented, five paid levels |
| Bat unlock | More knockback with a slower attack cadence; everyone still has a free slap | Implemented, 5,000 coins |
| Egg shield charges | Repeat purchase before risky flights; protects a carried egg from theft briefly | Implemented, 3,000 coins/charge |
| Glider skins/trails and pillow/fence styles | High-value optional goals without making combat increasingly one-sided | Recommended next cosmetics |
| Additional display floors/slots | Collection growth with real capacity; increasing income must be included in price estimates | Future progression, tied to rebirth/persistence |
| Special-biome expeditions/event shop | A repeat destination and situational rewards; separate event currency can limit inflation | Future biome/event work |
| Rebirth cost and route requirements | Long-term reset/unlock goal with visible reset/keep rules | Future; saving and a worthwhile new biome first |

Do not add idle waiting or mandatory repair charges simply to delete coins. Measure active flight trips, first upgrade time, gear usage, losses, currency earned versus spent and how often players return after losing cargo. Prices below are initial tuning.

## Current prices and controls

| Boost level | Price | Burst | Recharge |
| --- | ---: | ---: | ---: |
| Free | 0 | 1.2s | 6s |
| 1 | 500 | 1.5s | 5.5s |
| 2 | 5,000 | 1.8s | 5s |
| 3 | 50,000 | 2.1s | 4.7s |
| 4 | 250,000 | 2.4s | 4.4s |
| 5 | 1,000,000 | 2.7s | 4.2s |

Boost speed remains capped at +70 studs/sec. A million coins takes about 40.4 minutes at one average Rare, 6.7 minutes with six average Rares, or 2.8 minutes at the six-maximum-Rare extreme, before existing savings. Late costs may need further goals rather than extending flight power indefinitely.

The bat and shield counters are public, beside the central north walkway. Hold E to purchase; prices/ownership/charges are private server records. Bat and remaining charges survive character respawn in the session. Maximum shield inventory is three charges. Current progress is session-only; ending/rejoining the server resets it.

In Meadow, Q slaps, R swings a purchased bat, F attempts a mid-air steal and G activates a purchased shield on the carried egg. The glider stays equipped. D-pad left/up/right/down bind the same four actions; UI buttons also use Activated. Existing legacy flight remains primarily a keyboard prototype, so no complete phone/controller flight claim is made.

## Combat rules

- Base Camp has no PvP. The Meadow landing has an 80-stud safe radius and five seconds of arrival grace.
- Slap: 10-stud reach, 1.2-second cooldown, 0.7-second stun and a 35-stud/sec horizontal shove.
- Bat: 12-stud reach, two-second cooldown, 0.9-second stun and a 55-stud/sec shove.
- Hits do not remove eggs or health. They interrupt movement and boost briefly. A hit target gets stun duration plus two seconds of recovery protection against further hits.
- F steals only from a living, nearby player in front with a clear line of sight. Both must have their glider equipped/approved as flying, and both must be more than seven studs above collidable ground. The thief must carry no egg and cannot be stunned/traveling.
- A stolen egg retains its ID, rolled income, tier and physical size. The exclusive world reservation moves to its new owner atomically. No new egg is rolled, no source respawns during transfer, and the former owner's later death/respawn cannot release the new owner's egg.
- An egg has one second of initial pickup protection and six seconds after a transfer. Steal has a three-second attacker cooldown. Immediate steal-back chains are blocked.
- G consumes one charge for 12 seconds of theft protection. Charges cannot be stacked during an active shield. A blue glow/timer shows protection; it does not prevent bat/slap stuns or guardian catches.
- Placed eggs and collected coins cannot be stolen. Future base raiding is a separate feature.

The client sends one allowlisted action string. The server selects targets and validates alive state, biome, travel, ownership, purchases, range, facing, ground clearance, line of sight, cooldown and private cargo records. Invalid payloads are rejected before work. Character movement still has normal Roblox client network ownership; this is not a general teleport/speed anti-cheat system.

## Models and code

The free [Baseball Bat by 12gcepj](https://create.roblox.com/store/asset/13233709250) and [Slap Hand by O0110100](https://create.roblox.com/store/asset/115624435463813) supply visuals only. Original sources are archived in ImportedAssetBackups. Working CombatAssets contain visible geometry/appearance only: no imported scripts, remotes, tools, joints or constraints. Their referenced meshes/textures preloaded successfully.

SkyCombat.server owns purchases, rate limits and action outcomes. CombatModules/Rules owns eligibility and targeting; Impact owns temporary forces/stun restoration; Config owns costs/tuning. EggLoop's server-only HasCargo, ProtectCargo and TryAirSteal interfaces preserve the canonical Claims records. CombatClientModules/Effects renders cosmetic swings; SkyCombat.client owns input/presentation. SkyCombatHUD is an editable StarterGui template mapped by Rojo.

## Executed verification

- Native single-client shop purchases deducted exactly 5,000 and 3,000 coins and granted the corresponding private entitlements.
- Combat bar bounds checked against five simulated safe sizes: 1920×1080, 390×720, 844×340, 768×900 and 640×480. These are geometry checks, not real device/controller gameplay tests.
- Actual StudioTestService two-client run with native input and scripted setup positions: separate purchases, 500-coin boost upgrade, safe-base attack rejection, slap stun without egg/health loss, movement/force restoration, shield theft rejection, purchased bat stun, unowned-bat attribute spoof/malformed-action rejection, grounded theft rejection and successful airborne transfer.
- The transfer preserved a High Rare at 832/sec with its identity and scale. Immediate take-back was rejected. Resetting the former owner did not release/respawn it; the new owner placed it and received its income while the other plot remained at zero.
- Temporary test scripts were removed and the test session ended. A final native single-client smoke check passed shield charge consumption, glow Instance creation and countdown text. Ability text strokes were changed to border strokes after a screenshot exposed poor legibility. The 3D viewport captures were black/stalling; no final art-rendering signoff is claimed.
- A production-module check applied player stun and then a guardian shove, observed only the guardian force remaining with walking restored, and verified cleanup. Player actions exclude active guardian knockback. No latency/packet-loss, six-player stress, phone/controller flight or long-term balance claim is made.

Evidence is in tmp/sky-combat-playtest-results.json. Save the native place for gear counters/assets; Rojo builds remain source/UI validation artifacts.
