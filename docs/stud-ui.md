# Stud UI presentation

The interface uses the reference screenshots' broad visual ideas: colored plastic surfaces, shallow bevels, bold outlined type, and a repeating stud texture. The sky-blue, gold, green and purple palette belongs to Glide & Grab. Oil Empire branding, icons, stores and monetization panels are not included.

## Editable structure

Four `StarterGui` templates own the visible interface. `FlightHUD` now uses an authored shell instead of constructing every frame in its LocalScript.

| Template | Named regions |
| --- | --- |
| `ui/FlightHUD.model.json` → `GlideAndGrabHUD` | Coins, Objective, Cargo, WindWarning, PickupNotice, CoinReward |
| `ui/GliderBoostHUD.model.json` | BoostButton, Status, Hint, Meter.Fill, Notice |
| `ui/SkyCombatHUD.model.json` | ActionBar with Slap, Bat, Steal and Shield buttons; each has Key, ActionName and Cooldown |
| `ui/RebirthHUD.model.json` | Modal, Header, Title, Body.Copy, Cancel, Confirm |

`ReplicatedStorage.UIModules` maps to `scripts/ui`. `Theme` supplies shared colors and short money formatting through trillions. `Layout` assigns consistent regions to the independently owned HUD controllers. `Motion` supplies interruptible button/focus/open/number feedback and cancels its connections and tweens during teardown. `Notices` routes boost and portal notices into the existing HUD status region so separate overlays do not compete. The old authored `GliderBoostHUD.SafeScreen.Notice` path remains hidden for compatibility.

The tiled stud image is the same resolved asset already used on the game's ground: `rbxassetid://18878365966`. Each panel uses one static tiled `ImageLabel`, rather than a frame for each stud, a live ViewportFrame, or a continuously animated background. No new uploaded artwork is required. Fredoka One supplies the chunky headings; explanatory rebirth copy remains in a plain body font.

The cargo badge has an editable native egg icon with a cream silhouette, gold spots and a dark outline. World-label cleanup removes the obsolete one-time cash reward signs and fixes literal `\\n` sequences in current egg labels so the new HUD agrees with the eggs' actual income behavior.

## Behavior

- Coin totals count toward the latest server value over 0.32 seconds. A new value interrupts the previous count. A positive change adds one short `+$…` notice and a small pulse; it never changes coins locally.
- Button hover, keyboard/gamepad focus and press states share short scale feedback. Cooldowns and locked gear keep their explicit labels. Touch input hides keyboard labels.
- Cargo acquisition and rebirth opening each animate their stable parent once. Compact landscape omits the optional floating pickup line because the cargo card already provides feedback there.
- `GuiService.ReducedMotionEnabled` disables spatial/number motion. Travel uses a shorter opacity fade; it retains the existing server travel protocol and readiness deadlines.
- Rebirth's unlock/reset/keep copy is grouped with restrained color accents. Confirmation stays server validated. ButtonB/CAS back handling is wired for both offers and result notices; opening the Roblox menu dismisses a non-saving modal instead of competing for the reserved Escape key. Focus remains inside the modal.
- All HUD templates persist through respawn and use `CoreUISafeInsets`. The full-screen travel curtain intentionally covers the world.

## Responsive compositions

`Layout.forSize()` uses the available safe-root size. Desktop uses separate currency, objective and bottom action regions. Below 900 pixels it stacks the objective/status/abilities below currency. Short landscape windows at least 460 pixels wide use two side groups. Short touch landscape groups ability and boost buttons in an upper row, centers cargo in the lower middle, and folds status into the objective hint; this avoids placing the interactive ability bar over the bottom-left joystick. Narrow portrait keeps actions above the default movement/jump corners and backpack area. The optional gain notice overlays its currency region in constrained compositions instead of the objective. Actual touch controls still require device validation.

Review desktop, 360×640 portrait, 720×300 landscape, tablet-like and controller input. Inspect a carried egg, a long status message, all cooldowns, an insufficient-funds rebirth offer and a result notice. Verify screen bounds, native pickup prompt clearance, default Roblox control clearance, button activation/focus, cancelled tweens, reduced motion and respawn. Root-size checks alone do not prove a physical phone's notch, jump controls or a real controller.

Initial verification on 2026-10-15: the complete Rojo build passed, and Selene reported zero errors, warnings or parse errors across the UI-owned Luau files. Live Studio screenshots at a 1254×494 safe root showed readable Base Camp and Meadow compositions, including the ability bar and carried egg. The compact landscape composition left the playfield center open. Device and controller checks remain separate from that visual review.

The coordinator additionally verified bounds and pairwise separation for the seven original HUD regions plus the modal at 1366×768, 360×640, 720×300, 1024×768, 900×540, 640×480 and 480×300 simulated safe-root sizes. Native Meadow entry, pickup, return, pillow placement, insufficient-funds state, mouse cancel and successful mouse-confirmed rebirth passed.

Final smoke checks passed after the touch-specific layout and shared notice changes:

- Ten final `Layout.forSize()` projections (five sizes with mouse and touch flags) stayed within bounds and kept visible HUD regions separate. Compact touch intentionally hides the separate wind card and folds its text into the objective hint.
- A native VirtualInput click on Boost while grounded displayed the flight instruction through the shared status channel. The old boost notice remained hidden.
- A server `PortalTravel` notice displayed through the same channel, with no separate portal notice object.
- Character respawn retained one copy of each of the four HUDs and the current coin total.
- Native Escape dismissed the rebirth result while opening Roblox's menu. The interface did not override the core menu's reserved input.

Physical touch controls, device cutouts and real controller activation/navigation remain unverified. VirtualInput ButtonB testing was blocked by Roblox's core input binding, so it is not recorded as a controller pass. Reduced-motion handling is implemented but was not verified using a changed platform accessibility preference.

## Implementation references

Roblox documents [tiled ImageLabels](https://create.roblox.com/docs/reference/engine/classes/ImageLabel), [appearance modifiers](https://create.roblox.com/docs/ui/appearance-modifiers), [UI animation](https://create.roblox.com/docs/ui/animation), [safe on-screen containers](https://create.roblox.com/docs/ui/on-screen-containers), and [GuiService motion/input preferences](https://create.roblox.com/docs/reference/engine/classes/GuiService). These informed the implementation. The visual direction is derived from the user's provided screenshots rather than a downloaded UI pack.
