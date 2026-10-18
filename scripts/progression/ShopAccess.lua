-- A menu can buy anywhere in camp; vendors additionally require proximity.
local Players = game:GetService("Players")
local Profiles = require(script.Parent.Parent.DataModules.Profiles)
local Access = {}
function Access.allowed(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return player.Parent == Players and Profiles.get(player) ~= nil
		and humanoid ~= nil and humanoid.Health > 0 and root ~= nil and not root.Anchored
		and player:GetAttribute("CurrentBiome") == "Base Camp" and not player:GetAttribute("PortalTraveling")
end
return Access
