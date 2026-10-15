# Economy review and measurement plan — 15 October 2026

The current source of excess money is the large income jump between Uncommon and
Rare, followed by Storm. Increasing every price would also slow the players who
have not won an exclusive egg. Keep the current saved egg offers and prices for
the first friend test; measure delivery, loss and purchase timing before changing
the curve.

Roblox recommends estimating random rewards by expected value and observing
currency sources, spending and feature use before tuning an economy. These are
the basis of this review, rather than a price copied from another game.
([Balance virtual economies](https://create.roblox.com/docs/production/game-design/balance-virtual-economies),
[Economy events](https://create.roblox.com/docs/production/analytics/economy-events).)

## Owner-approved reporting

The owner opted in to Roblox economy reporting on 15 October after the purpose
and payload were explained. `ProgressionModules/EconomyTelemetry` reports actual
coin transaction amounts, resulting wallet balances and stable item identifiers
to Roblox's own AnalyticsService. It adds no third-party endpoint or API key.

| Source or sink | Event identifiers |
| --- | --- |
| Claimed online income | `CollectEggIncome` source |
| Sold/replaced stored eggs | `SellCommonEgg`, `ReplaceRareEgg` and corresponding template names, source |
| Successful boost purchases | `BoostLevel1` through `BoostLevel5`, shop sink |
| Successful gear purchases | `BatUnlock`, `EggShieldCharge`, shop sink |
| Confirmed first rebirth | `FirstRebirth`, gameplay sink for the entire removed wallet |

Passive accrual is reported once when claimed into the wallet, not every second.
Zero claims, failed purchases, pickup attempts and shield consumption do not
generate a coin event. Rebirth reporting follows the confirmed save. Events are
deferred and protected by pcall; an analytics error does not retry a purchase,
change a balance or block the player. Studio and unassociated local places do
not send reports. Delivery is best effort, not a financial audit log.

After publishing and playing the testing experience, open its **Analytics →
Economy** page in Creator Dashboard. **View Events** shows recent events for
validation; aggregate charts typically take 24 hours to appear. These event
dashboards are free. This reporting will help compare income claims against
upgrade/gear/rebirth spending and reveal wallet surplus.
([Roblox event types and validation](https://create.roblox.com/docs/production/analytics/event-types).)

The mock test is `tests/economy-telemetry.luau`, bundled with the verbatim module
by `python tests/run-telemetry-tests.py`. It shadows the Roblox services locally
and makes no real analytics call. Executed in Studio Edit: **23 assertions
passed**, with zero real AnalyticsService calls, covering preview suppression,
deferred payloads, invalid values, disconnect and caught reporting failure.
Published event receipt and the owner's actual dashboard are still unverified
until a published session produces transactions.

## Current numbers

| Egg | Offer income per second | Mean offer income | Full unlocked display at that mean |
| --- | --- | --- | --- |
| Common | 1 | 1 | 6/sec before rebirth |
| Uncommon | 3 | 3 | 18/sec before rebirth |
| Rare | Low 100–500 at 75%; High 500–1,000 at 25% | 412.5 | 2,475/sec across six |
| Storm / Epic | Low 1,000–1,750 at 75%; High 1,750–2,500 at 25% | 1,562.5 | 18,750/sec across twelve |

Tier bands use inclusive integer rolls; boundary values can occur in either tier.
Every exclusive egg keeps its original income, size and identity through carrying,
stealing, display and saving. `Rolls.valid` currently validates against these exact
catalogue definitions: changing the existing bands or sell values would require
an explicit saved-offer migration, not just a config edit.

The first boost costs 500; the bat 5,000; a shield charge 3,000. Boost levels cost
500, 5,000, 50,000, 250,000 and 1,000,000: 1,305,500 total. First rebirth requires
250,000, then resets the **whole wallet**, eggs, uncollected income and boost. It
keeps the purchased bat and unused shield charges. Only one rebirth is available.

## Forecasts, not measured playtimes

Run `python tests/economy-model.py` to regenerate
`tmp/economy-model-results.json` from current Luau configuration. It models
sequential successful deliveries, filling six/twelve pillows, and then accrual
at the full display rate. It uses a mean offer, not a sampled individual's luck.
The resulting time is conditional on those assumptions, not the statistical mean
of every player's completion time.

For an assumed **45-second successful loop**:

| Path | Full-display fill time | Accrue first 500 | Accrue 250,000 | Accrue all five boost prices |
| --- | --- | --- | --- | --- |
| Six Common | 4m30s | 3m55s | 11h37m | 60h29m |
| Six Uncommon | 4m30s | 2m26s | 3h54m | 20h11m |
| Six mean Rare | 4m30s | 46s | 4m16s | 11m25s |
| Twelve mean Storm | 9m28s | 45s | 2m26s | 5m03s |

Goals in each column are independent gross accrual, not cumulative purchases.
The Storm 250,000 column is only a benchmark: there is no second rebirth to buy.
The forecasts assume no deaths, guardian catches, theft, spending or travel
failures and omit any extra trip to claim income or reach a shop. They are
optimistic accrual estimates. A single Common alone needs 8m20s of income for a
500 purchase, but sequential Common deliveries reduce that to about 3m08s–4m35s
for hypothetical successful loops of 30–60 seconds.

An exclusive source stays reserved for the entire carry, then waits 20 seconds
(Rare) or 25 seconds (Storm) after release before returning. With pickup-to-deposit
assumed to take half of a 45-second loop, one Rare source can serve roughly one
successful carrier per 42.5 seconds. In an ideal fair six-player rotation, a
player would receive a Rare about every 255 seconds; filling six takes about
23m46s from the model's average first turn. At a mean offer they may reach
250,000 in about 9m42s with fewer than six eggs. Actual fairness is not enforced:
a repeatedly winning player can make another player wait much longer.

This makes the source competition a separate balance lever from price. Record
both the winning carrier and the person who struggled to obtain their first
Rare. Higher prices alone would widen their progression gap.

## First test targets

These are provisional design targets for discussion after the friend test,
not claims that the current game meets them:

- First secure egg within 1–2 minutes; first useful purchase within 3–5 minutes.
- A first Rare should feel like a major win, with its risk and ownership clear.
- First rebirth should require several successful heists, rather than one lucky
  egg followed by a long idle wait or repeated exclusive-source losses.
- A reborn player should still have a reason to fly after maxing boost; adding a
  second area without meaningful spending goals will produce idle surplus.

Do not ship a price increase or income nerf based only on this model. If first
Rare winners finish the whole progression in minutes while other players make
little progress, first improve the Common/Uncommon path and exclusive opportunity
distribution. Preserve rare exclusivity; possible later changes include more
separated nest opportunities and a safe first-delivery reward. Those features
are not implemented in this pass.

For established players, future coin sinks can be optional glider skins/trails,
camp fences/pillow decorations and additional useful flight upgrades. Their
prices should match measured earning rates. They need actual content and clear
benefits, rather than expensive empty buttons. None is advertised as available.

## Friend-test worksheet

Use fresh testing progress if possible; do not delete an existing cloud save just
to run the test. Record both players separately for 15–20 minutes.

| Measurement | Player A | Player B |
| --- | --- | --- |
| First Common secured at camp | | |
| First Uncommon secured / failed attempts | | |
| First Rare pickup / secured / income roll | | |
| Successful loop durations (at least five) | | |
| Guardian catches / falls / stolen eggs | | |
| Time waiting for an exclusive offer | | |
| First boost / bat / shield purchase times | | |
| Coins and income per second at 5 / 10 / 15 minutes | | |
| First rebirth time; coins discarded above the requirement | | |
| First Storm egg secured / income roll | | |
| Time spent flying versus waiting at camp | | |
| What felt unfair, confusing or satisfying | | |

Compare an observed loop median and failure rate against the model, then choose
one small change and repeat. Real friend combat feel, published leave/rejoin,
six-player scarcity and long-term sinks remain separate unverified outcomes.
