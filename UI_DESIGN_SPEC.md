# Glide & Grab UI design

## Visual system

Ink #102634; content #153747; shop/header #FFAC13; purchase #61E923; information #20BDF2; boost #FFE032; danger #F0443B; rebirth #A659EE. Spacing 4/8/12/16/24. Rectangular 6px corners, 3px outer border, restrained 3px lower lip. FredokaOne headings, Gotham body. Outlines on headings/actions, quiet small descriptions. Existing stud texture is restricted to colored surfaces. Original editable coin, basket, bolt, glider, bat, hand and shield symbols form one icon family.

## Composition

Top-left: icon, large wallet, separate income/ready line. Below: Shop, Upgrades, Rebirth rail. Top-right: objective then boost. Center-top: transient status. Bottom-center: glider equipment. Flight abilities sit below the rail or in an upper compact row on touch. Narrow HUD composition starts below 620 safe pixels; menus collapse below 760, on touch, or below 370 safe height. Below 540 height the wide layout becomes compact; below 370 height controls use a separate landscape arrangement and cargo moves out of the HUD. Cargo instructions remain in the objective. Menus have a dark full-screen input shield, orange header, close button, real-item scrolling list and feedback footer. Shop rows stack below 590 panel width. Panels shorter than 380 use a smaller header.

## Modules and integration

Extend Theme/Layout/Motion. CoinPopFX owns six reusable labels, combines rewards within 0.12 seconds and fires only on replicated positive wallet deltas. Menus coordinates one modal and gameplay input suppression. CampMenu owns Shop/Upgrades; existing Rebirth controller owns confirmation. WorldPrompts clones an editable BillboardGui template and uses InputHoldBegin/End, PromptShown/Hidden and hold events. Prompt records are explicitly removed when objects stream out. EquipmentSlot reads actual backpack/character Tools, rebinds replacement Backpacks on respawn and preserves equip behavior; no invented equipment state.

CampShop remote returns catalogue metadata from server configs, accepts only whitelisted item IDs and expected state, delegates to the same purchase functions as vendors. No client prices accepted. Existing Rebirth remote gains an Open action; all confirmation validation/save behavior retained. Menu access is camp-wide; purchases unavailable during travel, death, locked profile or outside camp.

## States and behavior

Every row supports owned/free, affordability, capped, return-to-camp, pending and server feedback. Booster lists current and next duration/recharge from Config. Slap is shown as Included, not sold. No fake equip button: Slap/Bat are abilities selected by Q/R, not separate Backpack tools. Rebirth is one compact confirmation. Modal closes on respawn/travel and restores focus; controls use Activated and selection groups. Reduced motion replaces positional effects with a highlight and reward label.

## References

User-provided Oil Empire and generated concepts establish visual direction, not catalogue data. Roblox implementation references: [custom proximity prompts](https://create.roblox.com/docs/ui/proximity-prompts), [responsive UI skill](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/tree/main/skills/other-engines/roblox-ui), and its responsive-layout/input-navigation references. No third-party screenshot is shipped as UI art.

18 October follow-up: original raster illustrations now lead Shop, Boost/Upgrades, Rebirth and Coins; simpler secondary ability/equipment symbols remain editable geometry. The illustrated assets share the original palette and have vector fallbacks during content fetching. `assets/ui/manifest.json` is the art/asset-ID source; `Illustrations.client.lua` handles fetch completion without changing interaction or gameplay state.
