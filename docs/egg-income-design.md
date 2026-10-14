# Egg display and income proposal — 14 October 2026

Research followed by an egg-income prototype and six-garden shared camp. Rates are starting tuning; persistent saving, offline income and actual multiplayer verification are pending.

## Verified comparisons

- [Steal a Brainrot's official Roblox description](https://www.roblox.com/games/109983668079237/Steal-a-Brainrot) lists buying/stealing collectibles, generating money, rebirth, and slap/troll equipment. It supports the collection → income → progression pattern. It does not specify income rates or prove which mechanic causes retention.
- [The Steal An Egg listing by “and Collect Rare Pets”](https://www.roblox.com/games/107778070777162/Steal-An-Egg) describes stealing eggs, hatching rare pets, earning money from pets, upgrading speed/base systems, and stealing from players. Several similarly named experiences exist; this identifies the listing inspected, without assuming it is the exact version Koushik has played.
- [Roblox's core-loop guide](https://create.roblox.com/docs/production/game-design/core-loops) separates moment-to-moment play, repeated actions and progression. Our moment-to-moment mechanic remains gliding, the repeated action remains retrieving an egg through hazards, and display income becomes the progression reward.
- [Roblox's virtual-economy guide](https://create.roblox.com/docs/production/game-design/balance-virtual-economies) recommends planning currency sources and spending, estimating the effect of new rewards, and measuring player behavior. Adding continuous income requires retuning upgrade prices rather than preserving the current cash-out economy unchanged.

These sources describe mechanics and design practices. The proposals below are our hypotheses to playtest, not evidence that this change guarantees popularity.

## Recommended loop

Fly through a biome portal → find an egg → take it → dodge its guardian and hazards → return to camp → place it on a cushion → earn coins while hunting the next egg → upgrade flight and unlock routes.

No hatching. The egg itself remains the collectible and income source. Keep the glider, wind, boost and bird encounter as the active part of the game. Higher income must come with a harder route, stronger encounter or more difficult discovery; do not make waiting the only way to reach the next enjoyable flight.

## Base prototype

Implemented on 14 October: six personal gardens with six Flower Pillow slots each, direct or private blue-pad placement, server ownership, Common 1/sec and Uncommon 3/sec online income, collection, full-slot cargo retention, hold-to-sell/replace and HUD feedback. Petals change rarity color while the yellow center is preserved. Old delivery cash-out is removed. Public portals and workshop sit outside the fences; portal access uses a private minimum-rebirth gate. Boost now has five paid levels from 500 to 1,000,000 coins. Bat/shield spending and actual two-client pickup/PvP tests are implemented; see docs/economy-and-air-pvp.md. Saving, offline income, rebirth/reset and long-term pacing remain pending.

- Six personal plots with isolated ownership and elapsed-time income ledgers. Joining assigns a free garden; character respawn retains it and leaving clears only that garden. Do not mistake fixtures for actual multiplayer verification.
- Six display slots, each with a cushion, egg model, name/rarity and coin rate.
- A low decorative border and a clear landing opening. A fence marks the plot; it is not a sufficient flying-player protection rule.
- Delivery places the carried egg in an empty slot and confirms the new total income. Replace the current default destruction-for-10/25-coins behavior for deposited eggs; do not silently grant both full old payouts and permanent income.
- A single collection pad for the whole plot is a reasonable initial choice: earnings accumulate while the player flies, and the player can claim them on returning. Show the pending amount and total coins/second clearly. Automatic credit is an alternative if collecting proves to be an unnecessary extra action.
- Start with online income only. Offline earnings are a later, separately balanced feature.

When slots are full, preserve the carried egg and show a clear choice. Let the player sell/replace a selected owned egg; never automatically delete a rare display to make room. Duplicates may occupy separate slots initially, keeping the first implementation understandable. The slot limit makes better eggs valuable even after the plot fills.

## Illustrative tuning, not finalized prices

| Egg | Coins/second | Route idea |
| --- | ---: | --- |
| Common | 1 | Safe Meadow practice |
| Uncommon | 3 | Existing bird-protected route |
| Rare | 8 | Future harder route or biome |

These are our starting examples, not rates copied from another game. Six common eggs produce 6 coins/second; replacing one with an uncommon raises that to 8. This creates a reason to revisit the guarded route.

The previous 50/125-coin boost prices become cheap as a plot fills. Two commons and one uncommon produce 5 coins/second, enough for those prices in ten/twenty-five seconds. The early income prototype used 200/600 coins. After adding rolled Rares, boost expanded to five paid levels from 500 to 1,000,000 coins, plus bat/shield purchases. See docs/economy-and-air-pvp.md for the current economy. Measure actual trip time and successful deliveries before settling these prices. Keep the free boost available from the start and recheck full-plot income and later rarity jumps.

## Protection and future multiplayer

Placed eggs remain safe. The bird risks carried cargo; it does not remove a displayed collection. Mid-air stealing, free slap, a purchased bat and egg shields are now implemented; see docs/economy-and-air-pvp.md. Base raiding remains a separate scope decision with different ownership/protection rules.

Income, plot ownership, depositing, selling, purchases and transfers must remain server-owned. The client displays values and requests actions. Every stored egg needs a stable instance identity so later duplicate prevention, persistence and transfers do not rely on the visible model alone.

## Build order

1. Settle the deposit/display/income rules before implementing persistence for the old cash-out loop.
2. Prototype six cushions and ownership, delivery into an empty slot, online income and collection. Preserve the working flight/guardian systems.
3. Add full-slot feedback and explicit sell/replace, retune boost prices, then test several consecutive collection trips.
4. Save coins, owned/displayed eggs, boost level and plot-slot state together so reconnecting cannot lose or duplicate collections. [Roblox's DataStore guide](https://create.roblox.com/docs/cloud-services/data-stores) explains published-game Studio access; use a separate published test experience for real save testing.
5. Add the collection book and a rarer route/biome.
6. Add rebirth when there are worthwhile new biomes/slots to unlock. Define and show reset/keep rules before any confirmation; avoid implementing a reset just for a multiplier without new play to unlock.

## What to measure

- Time to the first displayed egg and first paid upgrade.
- Number of active flights versus time spent waiting at camp.
- How often players choose the guardian route after common slots fill.
- Whether a lost carried egg encourages another flight or feels too costly.
- Whether total income, pending earnings and replacement choices are understood.
- Whether a rare egg remains exciting as an income improvement and visible trophy.

Recommendation: adopt the egg display/income loop, with gliding and escape as its active core. Start small and verify it feels better than the current cash-out loop before adding rebirth or offline income.
