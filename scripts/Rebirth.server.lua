-- A short-lived offer opens the confirmation UI. Save the complete reset atomically
-- before publishing it to the live garden; no client supplies cost or unlocks.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Profiles = require(script.Parent:WaitForChild("DataModules"):WaitForChild("Profiles"))
local Schema = require(script.Parent.DataModules.Schema)
local Config = require(script.Parent.ProgressionModules.RebirthConfig)
local Collection = require(script.Parent.CollectionModules.Controller)
local hasCargo = script.Parent:WaitForChild("EggLoop"):WaitForChild("HasCargo")
local station = workspace:WaitForChild("RebirthStation"):WaitForChild("Counter")
local prompt = station:WaitForChild("RebirthPrompt")
local remote = Instance.new("RemoteEvent")
remote.Name, remote.Parent = "Rebirth", RS
local offers, busy = {}, {}
local function eligible(player)
	local data = Profiles.get(player)
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	local root = c and c:FindFirstChild("HumanoidRootPart")
	return data and h and h.Health > 0 and root and not root.Anchored
		and player:GetAttribute("CurrentBiome") == "Base Camp" and not player:GetAttribute("PortalTraveling")
		and (root.Position - station.Position).Magnitude <= prompt.MaxActivationDistance and data or nil
end
prompt.Triggered:Connect(function(player)
	local data = eligible(player)
	if not data or busy[player] then return end
	if data.Rebirths >= Config.MaxRebirths then
		remote:FireClient(player, "Notice", "First rebirth complete! Storm Isles and your upstairs pillows are unlocked.")
		return
	end
	if offers[player] and os.clock() < offers[player].Created + 1 then return end
	local token = HttpService:GenerateGUID(false)
	offers[player] = {Token = token, Created = os.clock()}
	remote:FireClient(player, "Offer", token, Config.Cost, Config.KeepGear)
end)
remote.OnServerEvent:Connect(function(player, ...)
	if select("#", ...) ~= 2 then return end
	local action, token = ...
	local offer = offers[player]
	if action ~= "Confirm" or type(token) ~= "string" or not offer or offer.Token ~= token or busy[player] then return end
	offers[player] = nil
	if os.clock() > offer.Created + 20 then
		remote:FireClient(player, "Notice", "This offer expired. Use the rebirth station again.")
		return
	end
	local data = eligible(player)
	if not data or data.Rebirths >= Config.MaxRebirths then
		remote:FireClient(player, "Notice", "Return to the rebirth station and try again.")
		return
	end
	if data.Coins < Config.Cost or hasCargo:Invoke(player, false) then
		remote:FireClient(player, "Notice", "Need 250,000 coins and empty hands. Place your carried egg first.")
		return
	end
	busy[player] = true
	local proposed = Schema.copy(data)
	proposed.Rebirths += 1
	proposed.Coins, proposed.Pending, proposed.BoostLevel, proposed.Eggs = 0, 0, 0, {}
	if not Config.KeepGear then
		proposed.Bat, proposed.Shields = false, 0
	end
	remote:FireClient(player, "Saving")
	local ok = Profiles.commit(player, proposed, function(saved)
		Collection.rebirth(player, saved)
		player:SetAttribute("Rebirths", saved.Rebirths)
	end)
	busy[player] = nil
	if player.Parent == Players then
		remote:FireClient(player, "Notice", ok and "Rebirth complete! Storm Isles unlocked. Your camp now has 12 pillows."
			or "Could not save the rebirth. Your progress was kept. Please try again.")
	end
end)
Players.PlayerRemoving:Connect(function(player)
	offers[player], busy[player] = nil, nil
end)
