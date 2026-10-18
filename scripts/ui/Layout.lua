-- Shared regions in CoreUISafeInsets. Narrow screens recompose instead of shrinking.
local Layout = {}
function Layout.forSize(size, touch)
 local w, h = size.X, size.Y
 local narrow = w < 620
 local compact = h < 540 and not narrow
 local r = {Mode = narrow and "Narrow" or compact and "Compact" or "Wide"}
 if narrow and h >= 540 then
  r.Coins = {12, 8, w - 24, 104}
  r.Objective = {12, 124, w - 24, 56}
  r.Boost = {w - 240, 190, 228, 70}
  r.Menu = {12, 274, 150, 156}
  r.Toggle = {12, 190, math.max(80, w - 266), 44}
  r.Actions = {(w - 304) / 2, math.max(310, h - 284), 304, 74}
  r.Cargo = {w / 2 - 140, h - 198, 280, 55}
  r.Wind = {12, 264, w - 24, 36}
  r.HideWind = true
 elseif w < 760 then
  r.Coins = {12, 8, 200, 88}
  r.Objective = {224, 8, w - 236, 60}
  r.Boost = {w - 224, 80, 212, 70}
  r.Menu = {12, 150, 142, 156}
  r.Toggle = {12, 106, 112, 40}
  r.Actions = {(w - 288) / 2, 160, 288, 70}
  r.Cargo = {(w - 244) / 2, 240, 244, 50}
  r.Wind = {12, 106, 200, 38}
  r.HideWind = true
 else
  r.Coins = {18, 14, compact and 260 or 280, 108}
  local sw = math.min(350, w - 360)
  r.Objective = {w - sw - 18, 14, sw, 64}
  r.Boost = {w - 274, 90, 256, 76}
  r.Menu = {18, 142, 148, 156}
  r.Toggle = {18, 142, 112, 42}
  r.Actions = touch and {(w - 304) / 2, 176, 304, 76} or {18, h - 94, 304, 76}
  r.Cargo = {(w - 290) / 2, h - 158, 290, 56}
  r.Wind = {(w - 320) / 2, 90, 320, 48}
 end
 if h < 370 then
  r.Mode = "Compact"
  r.Coins = {16, 8, 168, 80}
  r.Toggle = {196, 12, 44, 44}
  r.Objective = {254, 8, w - 270, 60}
  local aw = math.min(248, w - 248)
  r.Actions = {16, 100, aw, 64}
  r.Boost = {w - 220, 100, 204, 68}
  r.Menu = {16, 96, 148, 156}
 end
 r.HideWind = r.HideWind or w < 1000
 r.HideCargo = h < 370 or (touch and h < 430)
 r.Notice = r.Wind
 r.Slot = h < 370 and {w / 2 - 35, h - 62, 70, 56} or {w / 2 - 42, h - 86, 84, 74}
 r.CollapsedMenu = w < 760 or touch or h < 370
 return r
end
function Layout.place(object, rect)
 object.AnchorPoint = Vector2.zero
 object.Position = UDim2.fromOffset(rect[1], rect[2])
 object.Size = UDim2.fromOffset(rect[3], rect[4])
end
return Layout
