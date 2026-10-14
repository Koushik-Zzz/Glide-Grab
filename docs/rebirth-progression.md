# Camp floors and rebirth direction — 14 October 2026

The camp now has six allocated personal plots with six working slots each, shared shop/portals, and a private server minimum-rebirth gate. No rebirth/reset action, second playable floor or additional biome is implemented yet. Actual two-client behavior remains to be tested.

The intended progression is:

1. Start with Meadow and one floor containing six egg pillows.
2. A first rebirth deliberately resets coins, pending income, collected/displayed eggs and boost purchases, after showing the exact reset/keep list and receiving confirmation in the game.
3. Keep the rebirth count, the newly unlocked biome and increased camp capacity. The first expansion adds an upper deck with six more slots, for twelve total.
4. Use the newly unlocked biome for better eggs and a new flight/escape challenge. Players should have a reason to fly again after the reset, rather than only replaying Meadow for a multiplier.

Prices, egg requirements and later floor counts need pacing tests before being finalized. Implement saving of the complete progression record before releasing rebirth; a destructive reset must not outrun persistence. The next biome and its reward should be playable when the first rebirth becomes available.

The authored layout prepares that expansion:

- `CampPlots/Plot1..Plot6` are 76-by-76-stud fenced gardens with 19-stud openings, on a 256-by-336-stud shared camp foundation. Joining assigns a free garden; leaving releases only that garden. Public spawn, shop, portal and return landing are outside the plots.
- Each plot's `Presentation/PlotOrigin/UpperFloorAnchor` is an invisible authoring Attachment 22 studs above its floor, with a planned 72-by-44-stud footprint and six additional pillows. Its world position follows the plot's orientation and location.
- Each plot has `FloorCount = 1` and `SlotsPerFloor = 6` as authoring metadata. Capacity comes from its real slots, not from these attributes. Future rebirth must add/restore owned slot records and floors consistently.
- Leave glider clearance at the outer edge of the upper deck, with a visible landing opening. The glider remains the main travel mechanic.
- The original decoration backup remains in `ServerStorage/ImportedAssetBackups/CampBeforePresentation`. The scene before six-plot migration and its reusable template are in `ImportedAssetBackups/BeforeSharedCamp`. Historical setup files should not be rerun on the migrated scene.

Placed eggs remain protected. Mid-air theft now affects carried eggs, with safe camp/landing zones and preserved identity/income. Fences establish walking boundaries; plot authority remains in the server collection system. Rebirth/reset and extra floors are future work.

All players use the same shop and biome portals. Portal eligibility is `private player rebirths >= required rebirths`, preserving access to earlier biomes. The authored Meadow anchor starts at zero; every session's private progression starts at zero until persistence/rebirth are implemented. Displayed attributes do not authorize unlocks.
