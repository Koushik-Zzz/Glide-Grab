# Glide & Grab illustrated UI

Four original illustrations were generated with the built-in image generation tool on 18 October 2026. The shop basket established the style reference; the boost bottle, rebirth egg/arrows and coin use the same outlined, cel-shaded toy palette. Full prompts and provenance are in `manifest.json`. Original RGBA PNGs and generator metadata are preserved in `source/`.

| Illustration | Roblox Image asset |
| --- | --- |
| Shop | 125696880626812 |
| Boost / Upgrades | 93776915952616 |
| Rebirth | 81767217052938 |
| Coins | 102817728214958 |

All four were uploaded to creator 4105644482 using Roblox Open Cloud, then reported Active / Approved. `*.upload.json` records the original upload operation; `*.metadata.json` records the later approved state. These files contain no API key. Source alpha checks passed (RGBA, 1254×1254, transparent corners). The four source textures total about 24 MiB uncompressed RGBA before Roblox processing; Roblox may downsample/compress them. These are shared static textures, not per-frame image allocations.

`tools/author_stud_ui.py` reads this manifest and creates editable ImageLabels plus the prior vector symbols as fallbacks. `Illustrations.client.lua` keeps those symbols until a successful content fetch; this also handles images inside closed menus, where `IsLoaded` alone is insufficient. Text, prices, button hit areas, selection and motion remain authored Roblox UI.

Executed Studio checks: all visible HUD illustrations loaded; the boost menu header changed from the shop to upgrade artwork; its row image loaded; an empty-image fixture displayed the fallback and restoring the uploaded asset restored the artwork. No client script errors were observed. The native screenshot showed the illustrated wallet, navigation and boost status against the camp scene.

To upload a deliberate new asset version, configure `roblox_api` or `ROBLOX_API_KEY` in the ignored root `.env`, then use:

```powershell
python tools/roblox_assets.py assets/ui/source/shop.png --name "Glide Grab UI Shop" --creator-id 4105644482 --result assets/ui/shop.upload.json
```

That command creates a new Roblox asset. It caps expected price at zero, sends credentials only to `apis.roblox.com`, refuses redirects, and preserves the acknowledged operation before polling. Do not rerun a create request after a network interruption without checking its recorded operation. The runtime game never reads `.env` or uses the API key.
