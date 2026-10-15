-- One-time Edit presentation cleanup. Not mapped as a runtime script.
-- Current PickupBeacon labels already show the actual per-egg income.
assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(), "Run in Edit only")
local map = assert(workspace:FindFirstChild("Map"), "Map missing")
local changed = 0
for _, object in ipairs(map:GetDescendants()) do
	if object:IsA("BillboardGui") and object.Parent.Name == "RouteSign" then
		local label = object:FindFirstChildWhichIsA("TextLabel", true)
		if label and string.find(label.Text, "coins at camp", 1, true) then
			if object:GetAttribute("BeforeStudUIEnabled") == nil then
				object:SetAttribute("BeforeStudUIEnabled", object.Enabled)
			end
			if object.Enabled then
				object.Enabled = false
				changed += 1
			end
		end
	end
end
game:GetService("ChangeHistoryService"):SetWaypoint("Remove outdated instant egg payout signs")
return {outdatedRouteSignsHidden = changed}
