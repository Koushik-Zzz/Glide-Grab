-- Catalogue comes from existing authoritative configs. No client supplies a price.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Access = require(script.Parent.ProgressionModules.ShopAccess)
local Gear = require(script.Parent.CombatModules.Config)
local Boost = require(RS.BoostModules.Config)
local buyGear = script.Parent:WaitForChild("SkyCombat"):WaitForChild("PurchaseGear")
local buyBoost = script.Parent:WaitForChild("GliderBoost"):WaitForChild("PurchaseBoost")
local remote = Instance.new("RemoteEvent")
remote.Name, remote.Parent = "CampShop", RS
local last = {}
local function catalogue()
	local levels = {}
	for level, settings in Boost.Levels do levels[tostring(level)] = settings end
	return {BatPrice = Gear.BatPrice, ShieldPrice = Gear.ShieldPrice,
		ShieldMax = Gear.ShieldMaxCharges, Levels = levels, MaxLevel = Boost.MaxLevel}
end
remote.OnServerEvent:Connect(function(player, ...)
	if select("#", ...) ~= 4 then return end
	local action, id, item, expected = ...
	if type(id) ~= "number" or id ~= id or id % 1 ~= 0 or id < 1 or id > 1e9 then return end
	local now = os.clock()
	if last[player] and now - last[player] < 0.2 then
		remote:FireClient(player, id, false, "Please wait a moment.")
		return
	end
	last[player] = now
	if action == "Browse" then
		remote:FireClient(player, id, true, "", catalogue())
		return
	end
	if action ~= "Buy" or type(item) ~= "string" then return end
	if not Access.allowed(player) then
		remote:FireClient(player, id, false, "Return to Base Camp to buy upgrades and gear.")
		return
	end
	local ok, message
	if item == "Bat" or item == "Shield" then
		ok, message = buyGear:Invoke(player, item, expected)
	elseif item == "Boost" then
		ok, message = buyBoost:Invoke(player, expected)
	else
		ok, message = false, "That item is not for sale."
	end
	remote:FireClient(player, id, ok == true, message or "Please wait a moment.")
end)
Players.PlayerRemoving:Connect(function(player) last[player] = nil end)
