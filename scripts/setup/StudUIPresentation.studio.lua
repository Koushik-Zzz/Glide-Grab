-- Run once in Edit mode; retained original distances allow an easy scene rollback.
assert(not game:GetService("RunService"):IsRunning(), "Run in Edit mode")
local changed = 0
for _, name in {"RebirthStation", "SkyGearShop", "BoostWorkshop"} do
	local station = workspace:FindFirstChild(name)
	if station then
		for _, object in station:GetDescendants() do
			if object:IsA("BillboardGui") then
				if object:GetAttribute("BeforeStudMenuMaxDistance") == nil then
					object:SetAttribute("BeforeStudMenuMaxDistance", object.MaxDistance)
				end
				object.MaxDistance = 32
				changed += 1
			end
		end
	end
end
return {signs = changed}
