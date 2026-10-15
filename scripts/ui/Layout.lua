-- Every HUD uses the same regions so independent controllers cannot overlap.
local Layout = {}

function Layout.forSize(size, touch)
	local width, height = size.X, size.Y
	local compact = height < 540 and width >= 460
	local narrow = width < 900 and not compact
	local mode = compact and "Compact" or narrow and "Narrow" or "Wide"
	local result = {Mode = mode}
	if compact then
		result.Coins = {16, 10, 202, 72}
		result.Objective = {width - math.min(320, width - 250) - 16, 10, math.min(320, width - 250), 56}
		result.Wind = {16, 94, math.min(300, width - 262), 38}
		result.Boost = {width - 220, 78, 204, 68}
		result.Actions = {16, 150, 248, 64}
		local cargoWidth = math.min(270, width - 296)
		result.Cargo = {width - cargoWidth - 16, 158, cargoWidth, 54}
		result.Notice = {16, 222, math.min(340, width - 260), 36}
		if touch then
			-- Keep interactive actions above the bottom control corners. The
			-- secondary status is folded into Objective.Hint in this composition.
			local actionWidth = width < 600 and 200 or 248
			local boostWidth = width < 600 and 140 or 204
			local start = (width - actionWidth - boostWidth - 16) / 2
			local touchCargoWidth = math.clamp(width - 304, 156, 280)
			result.Coins[4] = 70
			result.Actions = {start, 88, actionWidth, 64}
			result.Boost = {start + actionWidth + 16, 88, boostWidth, 64}
			result.Cargo = {(width - touchCargoWidth) / 2, 162, touchCargoWidth, 54}
			result.HideWind = true
		end
	elseif narrow then
		result.Coins = {12, 8, math.min(230, width - 24), 70}
		result.Objective = {12, 90, width - 24, 54}
		result.Wind = {12, 154, width - 24, 40}
		result.Actions = {(width - 288) / 2, 208, 288, 64}
		result.Boost = {(width - 200) / 2, height - 148, 200, 62}
		result.Cargo = {(width - math.min(300, width - 24)) / 2, height - 216, math.min(300, width - 24), 54}
		result.Notice = {12, 282, width - 24, 38}
	else
		result.Coins = {18, 14, 230, 86}
		result.Objective = {(width - 372) / 2, 14, 372, 64}
		result.Wind = {(width - 372) / 2, 90, 372, 42}
		result.Actions = touch and {(width - 304) / 2, 150, 304, 72} or {18, height - 92, 304, 72}
		result.Boost = touch and {(width - 222) / 2, height - 158, 222, 70} or {width - 244, height - 100, 226, 76}
		result.Cargo = {(width - 320) / 2, height - (touch and 230 or 164), 320, 60}
		result.Notice = {(width - 400) / 2, touch and 234 or 144, 400, 40}
	end
	return result
end

function Layout.place(object, rect)
	object.AnchorPoint = Vector2.zero
	object.Position = UDim2.fromOffset(rect[1], rect[2])
	object.Size = UDim2.fromOffset(rect[3], rect[4])
end

return Layout
