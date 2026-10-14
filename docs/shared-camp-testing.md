# Shared camp verification — 14 October 2026

The direct MCP startup tool supports one Play client. The StudioTestService API was subsequently used for an actual two-client pickup/placement/race test; see docs/egg-offers.md. Do not treat the two-owner Edit fixture as networking verification or that focused run as the entire matrix below.

## Executed

- Six real authored gardens, 36 pillows, separate pads, public plaza outside plot bounds, inward-facing gates, both green checker colors.
- One Play client: Plot1 allocation, other-plot prompts hidden, shared portal trip with carried egg, own-pillow placement, own-pad income claim, public workshop purchase for 200 coins, character respawn preserving egg/plot/boost.
- Temporary runtime requirement 1: native prompt blocked count 0 and accepted private count 2. A Studio-only server Script changed test progression through the production module; it destroyed itself and all test state disappeared on Stop.
- Production Plot module with Player test doubles and real cloned characters/plots in Edit: separate Common 1/sec and Uncommon 3/sec, private-owner rejection despite a forged OwnerUserId attribute, separate claims, range/death/debounce rejection, release clearing only that plot and reclaim starting empty. Fixtures removed.
- Rojo build/sourcemap and offline Luau lint; no full Roblox type-checking or device emulation claimed.

## Prepared, not run: Studio Server & Clients

Stop Play, then use Studio's Server & Clients test mode with two clients:

1. Both join: different CampPlotId and gate owner names, six slots each.
2. Each client sees only their own garden prompts. Workshop and Meadow portal visible to both.
3. Both travel to Meadow. Both should receive independent Common copies from the same source, which stays available. Race for Uncommon/Rare: exactly one carrier receives the exclusive offer; the other gets no duplicate.
4. Retrieve one Common and one Uncommon, return, place on own pillows. Rates are 1/sec and 3/sec, not summed or overwritten between players.
5. Walk/fly into the other plot. Attempt place, replace, sell and collect; both ledgers, displayed eggs, coins and carried cargo remain unchanged.
6. Claim income concurrently at each private pad: only the claimant's balance changes.
7. Both use the public shop: private next prices and levels, one player's purchase leaves the other's coins/boost unchanged.
8. For this test only, create a temporary Studio-only server Script that requires ProgressionModules.Progression and sets one player to 0 and the other to 2. Set the runtime entry field RequiredRebirths to 1. Count 0 is blocked with a notice only on that client; count 2 enters. A local client attribute edit to Rebirths must not unlock it. Remove the temporary Script after the test; do not use an MCP require cache to modify the running server's private progression.
9. Reset either character mid-flight/travel. Their plot/eggs survive and the other player's state remains untouched.
10. Disconnect one client. Only that garden clears. Rejoin assigns an empty available plot; this session-only prototype does not restore previous earnings.
11. Test six joins and a seventh overflow: six unique allocations; seventh waits without access to others. Leave an owner: the waiting player receives the empty garden.
12. Inspect server and every client Output, including rapid E/F holds and travel cancellation. Stop tests, remove test progression modifications, restart clean.

The published maximum-player setting is unchanged. Configure six players in the experience's settings before release, then repeat ownership, lifecycle and input checks on the published test experience.
