# Meadow loading reliability

On October 15, 2026, the published game showed the Meadow loading screen and then cancelled with "The area couldn't load." Studio entry worked. The landing floor in the opened published place (135204243659176, version 2) was present, anchored, collidable and correctly positioned. Streaming was enabled.

The old protocol depended on a client-side, best-effort six-second streaming request completing before polling the floor, with an eight-second total client loading window and no sustained destination replication focus. A Studio request completed quickly, so the exact live-server failure was not reproduced. The fix addresses the short loading window and transient prefetch behavior without bypassing floor checks.

## Change

- After validating portal access, the server adds one temporary replication focus per travelling player and prefetches the server-chosen destination asynchronously.
- The client immediately polls for the real collidable landing floor. It has 20 seconds to prepare and 10 seconds to confirm arrival; server deadlines are 24 and 12 seconds. A 40-second client watchdog prevents a stranded loading screen.
- Successful arrival, cancellation, death and disconnect all destroy the temporary focus. Streaming remains enabled; the entire map is not made persistent.
- Existing distance, biome, cargo, rebirth and request-ID checks remain authoritative. Failed loads return the character safely and restore its anchored state.
- Failed prefetch/focus calls and client floor/arrival timeouts now log diagnostics.

## Verification

Executed a StudioTestService server with two actual clients, using native E input and scripted positioning. Both clients entered Meadow concurrently and returned. A deliberately non-collidable destination floor delayed readiness for 11 seconds, beyond the old timeout; restoring it allowed both trips to complete. Leaving it unavailable cancelled both trips safely. Killing one player during loading released that player's focus without cancelling the other player's successful trip. Completed/cancelled trips had no remaining focus Parts and surviving roots were unanchored.

Two initial harness attempts did not complete: client startup exceeded the first allowance, and the second did not complete prompt activation. The successful harness waits for client readiness and uses native keyboard input. These are local tests, not proof of the published-server result. No packet-loss or real mobile testing was performed.

Both changed scripts pass the offline Luau Selene check without warnings; the Rojo scripts-only build succeeds. Temporary test scripts/remotes were removed from Edit mode afterward. Harness and raw results remain in ignored `tmp/`.

## Apply to the live game

The source files and the currently open Studio place contain the fix. Save the full place locally, then publish the existing **Glide & Grab [Testing]** experience. Leave the old server and join a newly started server; running servers may still use the old scripts. This task did not publish the game or overwrite the saved binary place.

References: [Roblox streaming techniques](https://create.roblox.com/docs/workspace/streaming/techniques), [replication focus](https://create.roblox.com/docs/workspace/streaming#replication-focus), [Player streaming APIs](https://create.roblox.com/docs/reference/engine/classes/Player).
