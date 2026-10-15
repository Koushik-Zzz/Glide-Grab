-- Shared presentation tokens. Gameplay state and prices never live in this module.
local Theme = {
	Ink = Color3.fromRGB(13, 24, 42),
	White = Color3.fromRGB(255, 255, 255),
	Cream = Color3.fromRGB(255, 246, 210),
	Gold = Color3.fromRGB(255, 207, 49),
	Green = Color3.fromRGB(126, 255, 42),
	Sky = Color3.fromRGB(41, 199, 255),
	Mint = Color3.fromRGB(88, 235, 179),
	Purple = Color3.fromRGB(181, 112, 255),
	Red = Color3.fromRGB(255, 97, 109),
	Muted = Color3.fromRGB(135, 155, 170),
}

function Theme.short(value)
	value = math.max(0, tonumber(value) or 0)
	for _, unit in ipairs({{1e12, "T"}, {1e9, "B"}, {1e6, "M"}, {1e3, "K"}}) do
		if value >= unit[1] then
			local amount = value / unit[1]
			return string.format(amount >= 100 and "%.0f%s" or amount >= 10 and "%.1f%s" or "%.2f%s", amount, unit[2])
		end
	end
	return tostring(math.floor(value))
end

return Theme
