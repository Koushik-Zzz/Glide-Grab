# Shared Common pickups and rolled Rare eggs — 14 October 2026

Common is a shared source: different players can collect their own copy without hiding or reserving it globally. Each copy gets a unique server-generated EggId. A player still carries one egg at a time and has a three-second personal Common cooldown after placement. One player's placement, death or departure does not clear another player's cargo or change the Common source.

Uncommon remains an exclusive, bird-guarded 3/sec egg. A separate Rare uses one spare imported egg design and four markers on the rear half of the existing guardian island. The original unused art is preserved.

## Rare offers

The server rolls each offer at spawn and shows its income before pickup:

| Tier | Income/sec | Initial tier probability |
| --- | ---: | ---: |
| Low | 100–500 | 75% |
| High | 500–1000 | 25% |

500 is deliberately allowed in both tier bands. Values within a band are uniformly selected integers. These weights are initial tuning, not provided by the reference games.

Height grows smoothly with income: 100/sec is 4 studs tall; 1000/sec is 6 studs tall. The complete imported mesh scales uniformly, and pillow labels move above larger eggs. The egg's rate, tier, scale and ID stay fixed through pickup, travel and placement. Twenty seconds after an exclusive Rare is placed or slapped away, a new offer spawns at another marker with a new ID and roll. Death/departure releases the source immediately as before.

The bird protects Uncommon and Rare. Only a confirmed slap consumes carried cargo through the private pickup record. Common remains unguarded. Rare sale value is provisionally 100 coins; its income remains independent of sale value.

Mythic/other rarities have no playable source or defined economy yet. They will use the exclusive policy when introduced; no fabricated Mythic reward range is added.

The requested Rare income is much higher than the starter 1/3-per-second rates. Boost has expanded to five paid levels from 500 to 1,000,000 coins, with bat/shield spending added; see docs/economy-and-air-pvp.md. This remains a test economy: biome unlocks, costs, rarity frequency and trip difficulty need pacing work before release.

## Code ownership

- EggLoop owns world offers, validated native prompt pickups, cargo construction and lifecycle.
- CollectionModules/Claims owns private per-player reservations and shared-source cooldowns.
- CollectionModules/Rolls owns weighted income rolls, bounded size and immutable identities.
- CollectionModules/Config owns catalogue/policies and tier ranges.
- Plot consumes the private record's validated Economy snapshot. Cargo/display Attributes are presentation only; modifying them cannot increase payouts.
- Visuals copies the stable identity/tier/scale to the displayed model. HUD and labels show the rolled rate.

## Verification

Executed one-client native Common pickup/return/placement with the source and prompt remaining available. A High Rare at 957/sec retained its ID, tier and roughly 5.904-stud height through cargo and display, despite test corruption of visible income/tier Attributes. It respawned as a new Low offer at 455/sec with a new identity. The guardian caught a subsequent Rare and removed cargo with health unchanged.

Executed an actual StudioTestService two-client simulation using temporary Studio-only server/client scripts and native VirtualInput key presses. Both clients picked independent Common copies from one source, returned and displayed them in different plots at 1/sec each. In a Rare race exactly one carrier won a Low offer at 175/sec, displayed it with the same ID/value, and earned 176/sec total while the other stayed at 1/sec. Temporary scripts/folders were removed after the session.

A production-module fixture reserved Common simultaneously for six representative players, tested independent release/cooldown and exclusive rejection, and sampled 2000 Rare rolls: 1514 Low and 486 High, spanning 100–1000. Endpoint heights/scales and immutable snapshots passed. This fixture is not a six-client networking test.

The first multiplayer automation attempt timed out waiting for clients at 15 seconds; retrying with a longer startup allowance passed. This was a harness startup timing issue. Rojo build, sourcemap and offline Luau lint cover mapped source; they do not replace Roblox type checks. Saving/offline income remain unimplemented.
