# Shared camp and friend playtest — 15 October 2026

Use the full `backup_update.rbxl` scene with the current Rojo sources. Six gardens
are authored. Each owner starts with six pillows and unlocks twelve after the
first rebirth. Shops and biome portals are shared; purchases, carried eggs,
collections and progression are private server state.

## Existing executed evidence

- Two actual StudioTestService clients received different gardens, independently
  picked up the same Common source, returned and placed separate eggs. An
  exclusive offer was awarded to only one player during a pickup race. See
  `docs/egg-offers.md` for the focused pickup run.
- Two-client progression run: private shop purchases, pre-rebirth Storm denial,
  native rebirth confirmation, reset of only the confirming player's coins,
  eggs and boost, retained bat/shield charges, twelve versus six usable pillows,
  both Storm portal directions and upstairs Epic placement. The stored Epic
  retained its 1,352/sec roll and identity. Respawn preserved the collection.
- Current two-client combat regression, with the final stud UI and telemetry
  sources: separate 5,000-coin bat, 500-coin boost and 3,000-coin shield purchases;
  safe base; slap/bat stun without health loss or cargo deletion; stun cleanup;
  shield rejection; malformed/unowned-bat rejection; grounded theft rejection;
  successful air transfer retaining a Low Rare at 390/sec and scale
  1.161111; immediate take-back rejection; former carrier respawn cleanup; and
  placement/income by the new owner. These are automation results, not a human
  judgement of combat feel.
- Edit fixtures exercised production Plot ownership, range/death/debounce checks,
  separate ledgers and forged display attributes. These fixtures alone do not
  prove networking behaviour.
- Saved collection restoration was exercised through production Session and Plot
  with a deterministic test backend. Cloud saving is a separate check below.

The current native-input combat fixtures are
`tests/multiplayer-combat.server.lua` and `.client.lua`, using
`ExecuteMultiplayerTestAsync(2, "SkyCombatProof")`. Early reruns stopped at shop
automation: client test teleports had not reached the server, and fixed short
holds ended before the background client's native prompt completed. The final
fixture waits for a server-observed position acknowledgement, the native
PromptShown event and Triggered/entitlement completion before ending its hold.
Both clients acknowledge scripted pose stages before attacks. Production
distance checks and purchases were kept intact. This uses scripted setup
positions; it is not a latency, packet-loss or natural-flight playtest.

The final complete two-client regression passed. Studio returned to Edit and
all temporary fixture Scripts, reporting remotes and modules were removed.

The open local scene still reports `GameId == 0` and `PlaceId == 0`; its clearly
labeled local preview resets between Play sessions. A successful Studio run does
not establish that the published build or Roblox cloud backend has been tested.

## Two-person published test

Publish the current full scene to the owner's testing experience, then both
people join that same server from Roblox Player. One person should use **Join**
from the other's profile/experience server list if needed. Set the experience's
maximum server size to six before broader testing; the currently inspected local
place reports a maximum of thirty. This document does not change publication,
access permissions or the server-size setting.

Record a short video from both players, or write down the values in the table.
Start each case with empty hands unless it specifically needs carried cargo.

| Case | Actions | Expected result |
| --- | --- | --- |
| Separate gardens | Join together and inspect gate names and blue pads. | Different CampPlotId/garden names; each player sees their own prompts. |
| Shared Common | Both approach the same Common egg and grab at almost the same time. | Both carry independent copies; the source remains available; one egg per player. |
| Exclusive race | With empty hands, both try the same Rare offer. | Exactly one receives it. Its source stays unavailable while it is carried, then respawns after the configured delay. |
| Own placement | Return and place eggs on the two private gardens. | Only the placing player's count/rate changes; the egg remains on its pillow. |
| Foreign garden | Visit the other plot; attempt place, replace, sell and income collection. | No other-owner egg, ledger or coin change; carried cargo is retained. |
| Independent upgrades | Both buy a boost level or gear at the shared shop. | Each pays their own quoted price and receives only their own entitlement. |
| Safe landing | Try Q/R/F in camp and near a biome landing; then leave the safe radius and wait out arrival grace. | Camp/landing reject attacks and theft. Gear works only in eligible outdoor areas after grace. |
| Slap / bat | Outside safety, stand/fly within range facing the opponent and use Q/R. | A readable hand-held swing, brief knockback/stun and recovery; no health damage or automatic egg loss. |
| Miss and distance | Swing facing away, from too far away and with a solid obstacle between players. | No hit. The visible swing alone does not grant a hit. |
| Air theft | Carry a Rare or Storm egg; both glide more than seven studs above ground. Empty-handed pursuer gets close behind and uses F. | One transfer, old carrier empty, new carrier has the same tier/income/size. Grounded or occupied-hand theft fails. |
| Transfer grace | Immediately try to steal the egg back, then retry after six seconds. | Immediate return theft fails; later valid theft can work. |
| Shield | Buy a charge; while carrying an egg outside safety use G, then let the other player attempt F. | One charge spent; theft blocked for twelve seconds. A second shield cannot stack; the Meadow bird can still catch protected cargo. |
| Former owner reset | After a successful theft, reset the former carrier's character. | Stolen cargo stays with its new owner; the source is still reserved. |
| Guardian catch | Take a guarded Meadow egg and let the bird physically hit the carrier. | Knockback and egg loss occur together; a failed pass does not remove the egg. Guardian returns and can chase a later heist. |
| Rebirth gate | A zero-rebirth player tries Storm while a reborn player enters. | Only the privately eligible player travels; higher rebirths continue satisfying a minimum requirement. |
| Respawn | Reset either player mid-flight and return to camp. | Their stored collection/boost/gear remain; carried cargo is lost; the other player's state is untouched. |
| Leave and rejoin | Follow the persistence checklist in `docs/saving-and-first-rebirth.md`. | Stored offers and progression restore into an available garden; carried cargo does not. |

Human feedback to record: whether a hit looked fair, whether the theft range was
understandable, whether the shield feedback was clear, and whether the chase was
fun for both the thief and the carrier. Automation cannot answer those questions.

## Six-player follow-up

Check six unique garden allocations, simultaneous Common access, exclusive-egg
wait times, portal/guardian responsiveness and independent shop purchases. With
an overflow test with more than six players, a seventh player waits without access to
another garden; when an owner leaves, only that garden clears and the waiting
player's own saved collection should restore there. This overflow restoration
has not yet been executed with seven actual clients.

Capture server and client Output for errors. Do not use an obsolete public
progression setter or weaken eligibility for testing; the current progression
owner is the loaded private profile. Temporary test fixtures must stay unmapped,
Studio-only and be removed from the Edit scene before saving or publishing.
