# Gameplay direction — 13 October 2026

## Research and what it supports

- [Steal a Brainrot's official Roblox description](https://www.roblox.com/games/109983668079237/Steal-a-Brainrot) describes buying/stealing income-producing collectibles, rebirth, and slap/troll equipment. This ties collecting to progression and player interference.
- [A firsthand PC Gamer play report](https://www.pcgamer.com/games/sim/one-of-robloxs-biggest-experiences-right-now-is-a-bizarre-italian-brainrot-character-stealing-simulator-and-lord-help-me-i-now-understand-why-its-so-popular/) describes waiting for a base to open, stealing, escaping, and being stopped by a bat. That creates a vulnerable return journey.
- [Los Polo's Steal an Egg video description](https://www.youtube.com/watch?v=UObbiAx5mUI) describes taking eggs, escaping animal guardians, improving speed and reaching more powerful creatures. Only its description was available; this is not a frame-by-frame gameplay review. Several similarly named games exist, so exact balance, controls and PvP details were not assumed from third-party wikis.
- [Roblox's core-loop design guide](https://create.roblox.com/docs/production/game-design/core-loops) recommends defining the repeated actions that drive progress.

These sources document mechanics, not proof of what causes popularity or retention. The design conclusions below are hypotheses to playtest.

## Our loop

**Scout by gliding → choose an egg → steal → dodge and escape → return through portal → bank → improve/collect.**

Keep gliding the main skill. A flying guardian can challenge altitude changes and turns; a ground-only pursuer would often be bypassed by flying upward. Start with one readable encounter before adding several biomes.

1. Common egg: safe practice, 10 coins.
2. Uncommon egg: a bird guardian responds to carrying an egg near its nest, 25 coins. A brief alert gives a head start; raised wings and an orange body flash warn of a swoop. Aim is calculated when the bird launches, predicting steady velocity before committing to a straight path. A sharp turn after launch can evade it; a tiny pre-launch sidestep is tracked. A miss creates recovery time, followed by another attempt. Outdistance the guardian's territory to escape; an already-launched attack finishes. Returning with the egg triggers another pursuit. Early play feedback showed that ending pursuit after a timer made carriers immune around the nest, so that rule was removed. Later feedback showed that a long warning lane and slow chase made every attempt trivial; the lane was removed and the encounter made faster. The current timing is a playtest hypothesis, not a proven difficulty balance.
3. Failure: a confirmed bird slap knocks the player backward with a small upward lift and removes the unbanked egg at impact. Its source returns to a new nest spot after three seconds. The short shove yields movement briefly, then normal steering resumes. No coin loss, health damage, forced unequip or repeated stun chain in this prototype.
4. Wind: short, visible 64-stud/second crosswind bursts; steering remains available. Calm windows and a route around the zone provide choice. Replaces the previous 28-stud/second, four-second drift.

## Next after testing this encounter

- Tune warning time and chase speed from actual player flights; difficulty must come from readable decisions.
- Boost is now implemented: a free 1.2-second burst with six-second recharge, plus 50/125-coin camp upgrades that extend it to 1.5/1.8 seconds and shorten recharge to 5.5/5 seconds. It adds 70 studs/second to existing flight and is cancelled by a guardian slap. This gives coins an immediate use and an escape decision without charging for the basic ability. Timing/prices still need Koushik's play feedback; progress is session-only.
- Add an egg collection book and a first-discovery reward so new routes have a reason to exist.
- Build one additional biome with one distinctive hazard, then progression gates and rebirth. Do not multiply unfinished routes yet.

## Multiplayer later — mid-air egg stealing

Explicitly deferred. A short-range air swipe can transfer a carried egg, followed by escape to camp. Prototype fair timing before adding bats or upgrades: attack tell, cooldown, no repeated stun chain, and brief immunity after a steal. Camp, spawning and portal arrivals need protected areas. Only carried cargo should be at risk; already banked rewards remain safe. Server must validate distance, sight, cooldown and ownership, atomically transfer one egg, and handle death/disconnect during a steal. Two-client tests are required; today's NPC encounter is not proof of PvP readiness.

## Playtest questions

- Can a new player see the guardian, understand the warning, and dodge after one failed attempt?
- Is the uncommon trip a meaningful risk compared with the safe common route?
- Does the player want another attempt after losing an egg?
- Is the stronger wind immediately noticeable while still controllable?
- Are hazards creating decisions, or merely making the route take longer?

Technical smoke tests verify correctness. Koushik's play feedback decides whether it feels fun.
