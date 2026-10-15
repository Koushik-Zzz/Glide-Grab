-- Boost eligibility and camp purchases are server-owned; levels use the save profile.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Profiles = require(script.Parent:WaitForChild("DataModules"):WaitForChild("Profiles"))
local Config = require(ReplicatedStorage:WaitForChild("BoostModules"):WaitForChild("Config"))
local station = Workspace:WaitForChild("BoostWorkshop", 10)
assert(station, "Create the camp BoostWorkshop with the Edit-mode setup")
local prompt = station:WaitForChild("Counter"):WaitForChild("UpgradePrompt")
assert(not ReplicatedStorage:FindFirstChild("RequestGliderBoost"), "Keep one GliderBoost server script")
local remote = Instance.new("RemoteEvent")
remote.Name = "RequestGliderBoost"
remote.Parent = ReplicatedStorage
local records = {}

local function cancel(player, record)
	if record.Character then
		record.Character:SetAttribute("GliderBoostUntil", nil)
		record.Character:SetAttribute("GliderBoostSpeed", nil)
		record.Character = nil
	end
	player:SetAttribute("BoostUntil", 0)
end

local function living(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not Profiles.get(player) or player.Parent ~= Players or not humanoid or humanoid.Health <= 0
		or not root or root.Anchored or player:GetAttribute("PortalTraveling") then
		return nil
	end
	return character, root
end

local function flightEligible(player, character)
	local glider = character:FindFirstChild("Glider")
	local untilTime = character:GetAttribute("GuardianKnockbackUntil")
	local combatUntil = character:GetAttribute("CombatStunnedUntil") or 0
	return glider and glider:IsA("Tool") and glider:GetAttribute("IsGliding") == true
		and not player:GetAttribute("PortalTraveling")
		and not (type(untilTime) == "number" and untilTime > Workspace:GetServerTimeNow())
		and combatUntil <= Workspace:GetServerTimeNow()
end

local function bind(player)
	local profile = Profiles.await(player)
	if not profile then return end
	local record = {Level = profile.BoostLevel, ReadyAt = 0, LastRequest = 0, LastBuy = 0}
	records[player] = record
	player:SetAttribute("BoostLevel", record.Level)
	player:SetAttribute("BoostUntil", 0)
	player:SetAttribute("BoostReadyAt", 0)
	player:SetAttribute("BoostRecharge", Config.atLevel(record.Level).Recharge)
	record.ResetConnection = player:GetAttributeChangedSignal("Rebirths"):Connect(function()
		cancel(player, record)
		record.Level = profile.BoostLevel
		record.ReadyAt = 0
		player:SetAttribute("BoostLevel", record.Level)
		player:SetAttribute("BoostRecharge", Config.atLevel(record.Level).Recharge)
		player:SetAttribute("BoostReadyAt", 0)
	end)
	record.Connection = player.CharacterRemoving:Connect(function()
		cancel(player, record)
	end)
end
Players.PlayerAdded:Connect(bind)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(bind, player)
end
Players.PlayerRemoving:Connect(function(player)
	local record = records[player]
	if record then
		cancel(player, record)
		record.Connection:Disconnect()
		record.ResetConnection:Disconnect()
		records[player] = nil
	end
end)

remote.OnServerEvent:Connect(function(player, ...)
	local record = records[player]
	local now = Workspace:GetServerTimeNow()
	if not record or now - record.LastRequest < 0.2 then return end
	record.LastRequest = now
	-- A request has no client-provided duration, level, position or price.
	if select("#", ...) ~= 0 or now < record.ReadyAt then return end
	local character = living(player)
	if not character or not flightEligible(player, character) then return end
	local settings = Config.atLevel(record.Level)
	local untilTime = now + settings.Duration
	record.ReadyAt = untilTime + settings.Recharge
	record.Character = character
	character:SetAttribute("GliderBoostSpeed", Config.ExtraSpeed)
	character:SetAttribute("GliderBoostUntil", untilTime)
	player:SetAttribute("BoostUntil", untilTime)
	player:SetAttribute("BoostReadyAt", record.ReadyAt)
end)

prompt.Triggered:Connect(function(player)
	local record = records[player]
	local now = Workspace:GetServerTimeNow()
	if not record or now - record.LastBuy < 0.5 then return end
	record.LastBuy = now
	local character, root = living(player)
	if not character or not prompt.Enabled or player:GetAttribute("CurrentBiome") ~= "Base Camp"
		or (root.Position - prompt.Parent.Position).Magnitude > prompt.MaxActivationDistance then return end
	local nextSettings = Config.Levels[record.Level + 1]
	if not nextSettings then
		remote:FireClient(player, "Boost fully upgraded!")
		return
	end
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if not coins or not coins:IsA("IntValue") then return end
	if coins.Value < nextSettings.Price then
		remote:FireClient(player, "Need " .. (nextSettings.Price - coins.Value) .. " more coins")
		return
	end
	-- Atomic transaction: no yield between checking funds and granting the next level.
	coins.Value -= nextSettings.Price
	record.Level += 1
	Profiles.get(player).BoostLevel = record.Level
	player:SetAttribute("BoostLevel", record.Level)
	player:SetAttribute("BoostRecharge", nextSettings.Recharge)
	remote:FireClient(player, "Boost upgraded! Longer burst, faster recharge")
end)

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.05 then return end
	elapsed = 0
	local now = Workspace:GetServerTimeNow()
	for player, record in pairs(records) do
		local character = record.Character
		if character and (player.Character ~= character or not living(player)
			or not flightEligible(player, character)
			or now >= (character:GetAttribute("GliderBoostUntil") or 0)) then
			cancel(player, record)
		end
	end
end)
