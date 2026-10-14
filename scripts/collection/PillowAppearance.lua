-- Appearance only. Egg ownership and income do not belong in this module.
local PillowAppearance = {}
PillowAppearance.Colors = {
	Empty = Color3.fromRGB(237, 155, 146),
	Common = Color3.fromRGB(255, 248, 218),
	Uncommon = Color3.fromRGB(140, 230, 164),
	Rare = Color3.fromRGB(109, 181, 255),
	Epic = Color3.fromRGB(190, 137, 244),
	Legendary = Color3.fromRGB(255, 203, 83),
	Mythic = Color3.fromRGB(248, 110, 136),
}

function PillowAppearance.apply(pillow, rarity)
	local resolved = PillowAppearance.Colors[rarity] and rarity or "Empty"
	local color = PillowAppearance.Colors[resolved]
	for _, part in ipairs(pillow:GetDescendants()) do
		if part:IsA("BasePart") and part:GetAttribute("PillowTint") == true then
			part.Color = color
		end
	end
	pillow:SetAttribute("DisplayedRarity", resolved)
	return resolved
end

return PillowAppearance
