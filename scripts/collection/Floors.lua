-- Authored upper decks start hidden. The owner's private rebirth count unlocks them.
local Floors = {}
function Floors.apply(plot, unlocked)
	local upper = plot:FindFirstChild("UpperFloor")
	local groups = upper and {upper} or {}
	for _, slot in ipairs(plot.Slots:GetChildren()) do
		if (slot:GetAttribute("SlotIndex") or 0) > 6 then
			table.insert(groups, slot)
		end
	end
	for _, group in ipairs(groups) do
		for _, object in ipairs(group:GetDescendants()) do
			if object:IsA("BasePart") then
				object.Transparency = unlocked and (object:GetAttribute("UnlockedTransparency") or 0) or 1
				object.CanCollide = unlocked and object:GetAttribute("UnlockedCollision") == true
			elseif object:IsA("Texture") then
				object.Transparency = unlocked and (object:GetAttribute("UnlockedTransparency") or 0) or 1
			elseif object:IsA("BillboardGui") then
				object.Enabled = unlocked
			end
		end
	end
	plot:SetAttribute("FloorsUnlocked", unlocked and 2 or 1)
end
return Floors
