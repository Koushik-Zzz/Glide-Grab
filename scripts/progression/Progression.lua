-- Server-only session progression. Attributes mirror UI, never determine unlocks.
local Players = game:GetService("Players")
local Progression = {}
local rebirths = {}
local function valid(value)
	return type(value) == "number" and value >= 0 and value < math.huge and value % 1 == 0
end
local function bind(player)
	if rebirths[player] ~= nil then return end
	rebirths[player] = 0
	player:SetAttribute("Rebirths", 0)
end
Players.PlayerAdded:Connect(bind)
Players.PlayerRemoving:Connect(function(player)
	rebirths[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do
	bind(player)
end
function Progression.getRebirths(player)
	return rebirths[player]
end
-- Reserved for server rebirth transactions / a future persistence loader.
function Progression.setRebirths(player, value)
	if player.Parent ~= Players or rebirths[player] == nil or not valid(value) then return false end
	rebirths[player] = value
	player:SetAttribute("Rebirths", value)
	return true
end
function Progression.canEnter(player, required)
	local count = rebirths[player]
	return valid(required) and count ~= nil and count >= required
end
return Progression
