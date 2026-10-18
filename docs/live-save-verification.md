# Published save verification — 18 October 2026

Target: **Glide & Grab [Testing]**, universe 10770918233, root place 135204243659176, private, six players. The owner confirmed saving and publishing through Studio. The associated Studio DataModel reports these IDs and contains CampShop, Illustrations and six authored illustration ImageLabels.

The API key remains in ignored `.env`. All backend checks use read-only requests against the owner's `Player_4105644482` entry in `GlideGrab_Player_v1`. No live profile was written, reset or repaired through Open Cloud. Private raw snapshots are stored only under ignored `tmp/`.

## Executed

- **Initial live write:** the store, previously absent, now contains the owner's version 1 profile with one stored egg. The session lease was present and unexpired.
- **Real departure:** the owner left Roblox Player and returned to its main menu. The next backend read retained the exact egg record, including slot and complete rolled offer, and the same coins/boost/rebirth/bat/shield values. Pending income did not decrease. The session field was removed, confirming final save and lease release.
- **Real rejoin:** the owner rejoined and confirmed that the egg appeared at camp. The backend contained the same complete egg record and a fresh, unexpired lease with a different token. Boost, rebirth, bat and shield values matched. The wallet and pending income had changed by the next read, so those readings alone do not establish an unchanged-balance or no-offline-income result.
- **Positive purchase departure:** after the owner reported purchases and leaving again, the saved profile contained 89,511 coins, boost level 2, an owned bat and the identical stored egg, with no lease. The owner subsequently confirmed using the shield charge, explaining the saved zero count. Restoration of an unused charge remains untested.
- **Second fresh session:** a later backend read had a different, unexpired session lease and retained the owned bat and exact egg. Boost was now level 3 with 39,511 coins: a 50,000-coin difference, matching the configured next upgrade price. The owner confirmed seeing 39.5K coins, the owned bat and boost level 3 in-game. Further live gameplay means this read is not an unchanged-wallet assertion.

## Pending

- Nonzero unused shield and rebirth restoration remain separate checks. Existing Studio tests cover these paths but do not replace published tests.
- Offline-income behavior, slow networks and live backend-failure recovery.

The basic live progress-saving check passed: exact egg restoration, session release/reacquisition, and user-visible wallet, bat and boost values matching the latest backend read. This does not yet verify every persisted feature or failure case.
