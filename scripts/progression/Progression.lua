-- Unlocks always use the private loaded profile; attributes only mirror UI.
local Profiles = require(script.Parent.Parent:WaitForChild("DataModules"):WaitForChild("Profiles"))
local Players = game:GetService("Players")
local Progression = {}
local function bind(player)
	local profile = Profiles.await(player)
	if profile then
		player:SetAttribute("Rebirths", profile.Rebirths)
	end
end
Players.PlayerAdded:Connect(bind)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(bind, player)
end
function Progression.getRebirths(player)
	local profile = Profiles.get(player)
	return profile and profile.Rebirths or nil
end
function Progression.canEnter(player, required)
	local count = Progression.getRebirths(player)
	return type(required) == "number" and required == required and required >= 0
		and required % 1 == 0 and count ~= nil and count >= required
end
return Progression
