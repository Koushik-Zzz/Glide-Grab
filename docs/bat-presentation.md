# Held glove, bat and arm swings

The previous effects briefly cloned a centred weapon near the right hand. Both weapons now attach at the handle in the left hand, keeping the glider Tool and its right-hand grip intact. Players start with the free glove. An accepted Q action selects the glove; R selects the privately purchased bat. Purchasing the bat also selects it. Successful mid-air theft selects the glove for its swipe. Only one weapon Model is present, and the selected weapon survives respawn within the session.

`combat/HeldWeapon.lua` binds presentation to the current character. The bat retains its imported handle offset (1.3 studs on the four-stud source bat, scaled with the template). The glove uses an authored GripPoint Attachment at the source Tool.Grip position, rotated upright for the left hand. BatGrip/SlapGrip connects the model to LeftGripAttachment. Parts are unanchored, massless and non-colliding. Character removal, death and player removal clean up the prop; respawn recreates the selected eligible weapon. Client-visible OwnsBat alone does not grant a bat.

`combat_client/WeaponPose.lua` owns the left shoulder, elbow and wrist hold/swing presentation. It supports Motor6D and AnimationConstraint joints and applies procedural poses during PreSimulation. Before the animator evaluates again, it restores the previous unmodified pose to avoid accumulating offsets. Server-approved BatSwingStartedAt/SlapSwingStartedAt supplies timing to every viewer. Each weapon has windup, a cross-body swing, follow-through and return to the holding position. Slap contact is at 0.08 seconds, matching its existing server hit delay. Travel and stun suspend the arm override. No imported animation asset or upload is needed.

Effects.lua only owns pose lifecycle. Both floating swing clones and their cosmetic Swing remote broadcasts were removed. Combat prices, hit validation, stun, knockback and cooldowns retain their existing behavior.

The replacement [Slap Glove Tool](https://create.roblox.com/store/asset/120133129723048/Slap-Glove-Tool) is native art in ReplicatedStorage/CombatAssets/Slap. Its visible Handle and stick are scaled to 65% of the imported size. The imported attack/input scripts target R6, so they are excluded, along with remotes, sounds, borrowed animations, effects and invisible hitboxes. `scripts/setup/SlapGlove.studio.lua` records the one-time Edit migration; do not rerun it on the configured scene. The old sanitized template remains in ServerStorage/ImportedAssetBackups/SlapBeforeHeldGlove. Save the full Studio place as well as the source files.

## Glove verification — October 15, 2026

- Single-player Studio: visually checked the upright rendered glove and its black handle in the left palm, including with the glider equipped and its right-hand grip intact. The first grip orientation hung downward; it was corrected before the multiplayer run.
- Two actual StudioTestService clients: both spawned with a glove, bought bats through the ordinary prompt, entered Meadow and flew their gliders. Native Q, R, Q input switched glove/bat/glove and swung. Both clients observed about 102 degrees of shoulder movement, less than 0.000125 studs of palm-to-handle error, a persistent selected model, no duplicate held weapon and no old LocalSlapSwing clone. The glider stayed equipped.
- Native Q against the other grounded player triggered the existing server stun. Respawn rebuilt the selected glove and preserved the private bat entitlement.
- Temporary test scripts/reporting remote were removed. Test source and results are in ignored tmp. Phone/controller and R6 visual checks were not run; the existing glider requires R15.

## Verification — October 15, 2026

- Single-player Studio: actual shop purchase created HeldBat, the palm-to-handle error was approximately 0.000011 studs, and the glider retained its right-hand grip. Respawn restored the held model.
- Two actual StudioTestService clients: both purchased for 5,000 coins, entered Meadow, equipped and flew their gliders. Native R input generated an accepted swing. Both observers measured approximately 102 degrees of shoulder movement and less than 0.00013 studs of palm-to-grip error. The bat remained attached after the swing, the glider remained equipped, and no LocalBatSwing clone appeared. Respawn retained entitlement and rebuilt HeldBat.
- An initial two-client harness attempt failed at automated shop input. The retry used the native ProximityPrompt hold API for purchase, with keyboard fallback; the swing used native keyboard input. No production checks were bypassed.
- Both changed controller/effects files and new modules pass the offline Luau lint check; the scripts-only Rojo build succeeds. Temporary test scripts and the reporting remote were removed from the Edit place. Test sources/results remain in ignored tmp.
- Studio could not fetch the bat's existing mesh/texture (54983181/54983107), alongside several avatar/audio assets. A screenshot showed the arm pose but not the bat mesh. Grip, motion and replication were measured in-engine; the final rendered silhouette, clearance from the glider and appearance across camera angles still need a human visual check with assets loaded. R6 fallback logic has not been playtested, and the imported glider currently requires R15.

Save the open place locally and publish the existing testing experience before checking the change in a fresh Roblox server. This task does not publish the experience.

References: [Motor6D animation timing](https://create.roblox.com/docs/reference/engine/classes/Motor6D), [AnimationConstraint migration and procedural animation](https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint).
