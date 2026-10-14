# Held bat and arm swing

The old Bat effect cloned a centred mesh for 0.38 seconds, rotated it near the right hand, then destroyed it. The bat now remains held by its handle in the left hand after purchase, keeping the existing glider Tool and right-hand grip intact. It is a replicated cosmetic Model, not a second equipped Tool.

`combat/HeldBat.lua` binds the private purchase entitlement to the current character. It clones the existing sanitized template, uses the original imported handle offset (1.3 studs on the four-stud source bat, scaled with the template), and attaches it through BatGrip. Parts are unanchored, massless and non-colliding. Character removal, death and player removal clean up the prop; respawn recreates it for an owner. Client-visible OwnsBat alone does not grant a weapon.

`combat_client/BatPose.lua` owns the left shoulder, elbow and wrist hold/swing presentation. It supports finding both Motor6D and newer AnimationConstraint joints and applies procedural poses during PreSimulation. Before the animator evaluates again, it restores the previous unmodified pose to avoid accumulating offsets. Server-approved BatSwingStartedAt supplies timing to every viewer. The pose has windup, a cross-body swing, follow-through and return to the holding position. Travel and stun suspend the arm override. No imported animation asset or upload is needed for this procedural pose.

The old temporary Bat clone has been removed from Effects.lua. Slap is still the previous temporary effect and needs its own presentation pass. Combat prices, hit validation, stun, knockback and cooldowns retain their existing behavior.

## Verification — October 15, 2026

- Single-player Studio: actual shop purchase created HeldBat, the palm-to-handle error was approximately 0.000011 studs, and the glider retained its right-hand grip. Respawn restored the held model.
- Two actual StudioTestService clients: both purchased for 5,000 coins, entered Meadow, equipped and flew their gliders. Native R input generated an accepted swing. Both observers measured approximately 102 degrees of shoulder movement and less than 0.00013 studs of palm-to-grip error. The bat remained attached after the swing, the glider remained equipped, and no LocalBatSwing clone appeared. Respawn retained entitlement and rebuilt HeldBat.
- An initial two-client harness attempt failed at automated shop input. The retry used the native ProximityPrompt hold API for purchase, with keyboard fallback; the swing used native keyboard input. No production checks were bypassed.
- Both changed controller/effects files and new modules pass the offline Luau lint check; the scripts-only Rojo build succeeds. Temporary test scripts and the reporting remote were removed from the Edit place. Test sources/results remain in ignored tmp.
- Studio could not fetch the bat's existing mesh/texture (54983181/54983107), alongside several avatar/audio assets. A screenshot showed the arm pose but not the bat mesh. Grip, motion and replication were measured in-engine; the final rendered silhouette, clearance from the glider and appearance across camera angles still need a human visual check with assets loaded. R6 fallback logic has not been playtested, and the imported glider currently requires R15.

Save the open place locally and publish the existing testing experience before checking the change in a fresh Roblox server. This task does not publish the experience.

References: [Motor6D animation timing](https://create.roblox.com/docs/reference/engine/classes/Motor6D), [AnimationConstraint migration and procedural animation](https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint).
