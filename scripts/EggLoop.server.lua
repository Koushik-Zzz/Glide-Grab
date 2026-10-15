-- KOUSHIK_ROJO_SYNC_CHECK: Hello Koushik! This comment was edited from the project folder.
-- Rojo manages this script from scripts/EggLoop.server.lua.
-- Requires anchored Parts: HomeIsland, EggIsland, ChallengeIsland in Workspace.
-- Optional art templates: ServerStorage > EggModels > CommonEgg / UncommonEgg.
-- Common sources serve every player; guarded offers are exclusive and roll on spawn.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local Profiles = require(script.Parent:WaitForChild("DataModules"):WaitForChild("Profiles"))
local collectionModules = script.Parent:WaitForChild("CollectionModules")
local Collection = require(collectionModules:WaitForChild("Controller"))
local Economy = require(collectionModules:WaitForChild("Config"))
local Claims = require(collectionModules:WaitForChild("Claims"))
local Rolls = require(collectionModules:WaitForChild("Rolls"))
local combatModules = script.Parent:WaitForChild("CombatModules")
local PvPRules = require(combatModules.Rules)
local PvPConfig = require(combatModules.Config)

local function islandPart(name)
	local part = Workspace:WaitForChild(name, 10)
	assert(part and part:IsA("BasePart"), "Create an anchored Part named " .. name .. " in Workspace")
	return part
end

islandPart("HomeIsland")
local definitions = {
	{Island = islandPart("EggIsland"), Template = "CommonEgg", Name = "Common Egg", Color = Color3.fromRGB(255, 220, 110)},
	{Island = islandPart("ChallengeIsland"), Template = "UncommonEgg", Name = "Uncommon Egg", Color = Color3.fromRGB(140, 255, 176)},
	{Island = islandPart("ChallengeIsland"), Template = "RareEgg", Name = "Rare Egg", Color = Color3.fromRGB(109, 181, 255)},
	{Island = Workspace.Map.StormIsles.StormEggIsland, Template = "StormEgg", Name = "Storm Egg",
		Biome = "Storm Isles", Color = Color3.fromRGB(190, 137, 244)},
}
assert(not Workspace:FindFirstChild("EggLoopPrototype"), "Keep only one EggLoop script")
local objects = Instance.new("Folder")
objects.Name = "EggLoopPrototype"
objects.Parent = Workspace
local hiddenEggs = Instance.new("Folder")
hiddenEggs.Name = "EggLoopHiddenEggs"
hiddenEggs.Parent = ServerStorage

local function eggParts(egg)
	local parts = {}
	if egg:IsA("BasePart") then
		table.insert(parts, egg)
	end
	for _, child in ipairs(egg:GetDescendants()) do
		if child:IsA("BasePart") then
			table.insert(parts, child)
		end
	end
	return parts
end

local function eggBounds(egg)
	if egg:IsA("Model") then return egg:GetBoundingBox() end
	return egg.CFrame, egg.Size
end

local function positionEgg(egg, center)
	-- Imported models can have pivots far away from their visible geometry.
	local bounds = eggBounds(egg)
	local pivotToBounds = egg:GetPivot():ToObjectSpace(bounds)
	egg:PivotTo(center * pivotToBounds:Inverse())
end

local function cleanTemplate(egg)
	-- Keep mesh/texture/appearance children; use only our own gameplay code.
	for _, child in ipairs(egg:GetDescendants()) do
		if child:IsA("LuaSourceContainer") or child:IsA("ProximityPrompt")
			or (child:IsA("BillboardGui") and child.Name == "PickupBeacon")
			or child:IsA("JointInstance") or child:IsA("WeldConstraint")
			or child:IsA("Constraint") or child:IsA("Highlight") then
			child:Destroy()
		end
	end
end

local function makeEgg(definition, offer)
	local templates = ServerStorage:FindFirstChild("EggModels")
	local template = templates and templates:FindFirstChild(definition.Template)
	local egg = nil
	if template and (template:IsA("BasePart") or template:IsA("Model")) then
		egg = template:Clone()
		if egg then
			cleanTemplate(egg)
			local parts = eggParts(egg)
			if #parts == 0 then
				egg:Destroy()
				egg = nil
			elseif egg:IsA("BasePart") and #parts > 1 then
				-- A Model makes nested parts move and scale as one design.
				local model = Instance.new("Model")
				egg.Parent = model
				egg = model
			end
		end
	end
	if not egg then
		warn("EggLoop: Add an individual egg named " .. definition.Template
			.. " directly inside ServerStorage/EggModels. Using the prototype egg for now.")
		egg = Instance.new("Part")
		egg.Shape = Enum.PartType.Ball
		egg.Size = Vector3.new(3, 4, 3) * offer.Scale
		egg.Color = definition.Color
		egg.Material = Enum.Material.Neon
	else
		-- Scale all axes together so the imported egg keeps its proportions.
		local _, size = eggBounds(egg)
		local factor = (4 * offer.Scale) / math.max(size.Y, 0.01)
		if egg:IsA("Model") then
			egg:ScaleTo(egg:GetScale() * factor)
		else
			egg.Size = egg.Size * factor
		end
	end
	local parts = eggParts(egg)
	for _, part in ipairs(parts) do
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
	end
	return egg, parts[1]
end

local function makeCargo(egg, root)
	-- Clone before hiding the source; preserve all of its visual children.
	local cargo = egg:Clone()
	assert(cargo, "EggLoop: The runtime egg must be Archivable")
	cleanTemplate(cargo)
	cargo.Name = "CarriedEgg"
	positionEgg(cargo, root.CFrame * CFrame.new(0, 0, -3))
	for _, part in ipairs(eggParts(cargo)) do
		part.Anchored = false
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = part
		weld.Parent = part
	end
	return cargo
end

local function makePrompt(part, action, text)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = text
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	return prompt
end

local claims = Claims.new()
local random = Random.new()

local function chooseSpawn(source)
	local map = Workspace:FindFirstChild("Map")
	local meadow = map and map:FindFirstChild("Meadow")
	local spawns = meadow and meadow:FindFirstChild("EggSpawns")
	local folder = spawns and spawns:FindFirstChild(source.Definition.Template)
	local choices = {}
	if folder then
		for _, marker in ipairs(folder:GetChildren()) do
			if marker:IsA("BasePart") and marker.Anchored and marker ~= source.LastSpot then
				table.insert(choices, marker)
			end
		end
	end
	local _, size = eggBounds(source.Egg)
	if #choices > 0 then
		local spot = choices[random:NextInteger(1, #choices)]
		source.LastSpot = spot
		positionEgg(source.Egg, spot.CFrame * CFrame.new(0, size.Y / 2 + 0.35, 0))
		source.Egg:SetAttribute("SpawnSpot", spot.Name)
	else
		local island = source.Definition.Island
		positionEgg(source.Egg, island.CFrame * CFrame.new(0, island.Size.Y / 2 + size.Y / 2, 0))
	end
end

local function validNearby(player, part, prompt)
	if not Profiles.get(player) or not prompt.Enabled or player.Parent ~= Players then return nil end
	if player:GetAttribute("PortalTraveling") then return nil end
	if player.Character and Workspace:GetServerTimeNow() < (player.Character:GetAttribute("CombatStunnedUntil") or 0) then return nil end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or root.Anchored then return nil end
	if not ((root.Position - part.Position).Magnitude <= prompt.MaxActivationDistance) then return nil end
	return root, humanoid
end

local function releaseEgg(player, respawnDelay)
	local record = claims:release(player, os.clock(), respawnDelay)
	if not record then return end
	if record.DeathConnection then
		record.DeathConnection:Disconnect()
	end
	if record.Cargo then
		record.Cargo:Destroy()
	end
	local source = record.Source
	if source.Shared then return end
	-- Exclusive offers respawn with a new identity, value and size.
	task.delay(respawnDelay, function()
		if objects.Parent and source.Egg.Parent == hiddenEggs then
			source.Refresh()
			source.Egg.Parent = objects
			source.Prompt.Enabled = true
		end
	end)
end

-- Server-only interface: guardian catches go through the same ownership cleanup
-- as placement/death. No client remote can drop or transfer an egg.
local guardianCatch = Instance.new("BindableFunction")
guardianCatch.Name = "GuardianCatch"
guardianCatch.OnInvoke = function(player, cargo)
	local record = claims:peek(player)
	if not record or record.Cargo ~= cargo then return false end
	if cargo.Parent ~= player.Character or not Economy.Eggs[record.Source.Definition.Template].GuardianProtected then return false end
	if player:GetAttribute("CurrentBiome") ~= "Meadow" or player:GetAttribute("PortalTraveling") then return false end
	releaseEgg(player, Economy.Eggs[record.Source.Definition.Template].RespawnSeconds)
	return true
end
guardianCatch.Parent = script

local function setupPlayer(player)
	player.CharacterRemoving:Connect(function()
		releaseEgg(player, 0)
	end)
end
Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end
Players.PlayerRemoving:Connect(function(player)
	releaseEgg(player, 0)
	claims:forget(player)
end)

local function ownedCargo(player)
	local record = claims:peek(player)
	if record and record.Cargo.Parent == player.Character then
		return record
	end
	return nil
end
local hasCargo = Instance.new("BindableFunction")
hasCargo.Name = "HasCargo"
hasCargo.OnInvoke = function(player, stealable)
	local r = ownedCargo(player)
	return r ~= nil and (not stealable or Workspace:GetServerTimeNow() >= (r.TheftReadyAt or 0))
end
hasCargo.Parent = script
local protect = Instance.new("BindableFunction")
protect.Name = "ProtectCargo"
local function showCargoProtection(cargo, seconds)
	local flash = Instance.new("Highlight")
	flash.Name = "EggProtectionGlow"
	flash.Adornee = cargo
	flash.DepthMode = Enum.HighlightDepthMode.Occluded
	flash.FillColor = Color3.fromRGB(105, 215, 245)
	flash.OutlineColor = Color3.fromRGB(220, 255, 255)
	flash.FillTransparency = 0.75
	flash.OutlineTransparency = 0.1
	flash.Parent = cargo
	Debris:AddItem(flash, seconds)
end
protect.OnInvoke = function(player)
	local r = ownedCargo(player)
	local now = Workspace:GetServerTimeNow()
	if not r or not PvPRules.allowed(player, false) or now < (r.ShieldUntil or 0) then return false end
	r.ShieldUntil = now + PvPConfig.ShieldSeconds
	r.TheftReadyAt = math.max(r.TheftReadyAt or 0, r.ShieldUntil)
	r.Cargo:SetAttribute("TheftProtectedUntil", r.TheftReadyAt)
	r.Cargo:SetAttribute("EggShieldUntil", r.ShieldUntil)
	showCargoProtection(r.Cargo, PvPConfig.ShieldSeconds)
	return true
end
protect.Parent = script
local transfer = Instance.new("BindableFunction")
transfer.Name = "TryAirSteal"
transfer.OnInvoke = function(thief, victim)
	local _, victimRoot = PvPRules.pair(thief, victim, PvPConfig.StealRange, true)
	local r = ownedCargo(victim)
	if not victimRoot or not r or ownedCargo(thief) then return false end
	local now = Workspace:GetServerTimeNow()
	if now < (r.TheftReadyAt or 0) then return false end
	local root = thief.Character:FindFirstChild("HumanoidRootPart")
	local ok, cargo = pcall(makeCargo, r.Cargo, root)
	if not ok then return false end
	local oldCargo, oldConnection = r.Cargo, r.DeathConnection
	if not claims:transfer(victim, thief, r, cargo, now, PvPConfig.TransferProtection) then
		cargo:Destroy()
		return false
	end
	if oldConnection then
		oldConnection:Disconnect()
	end
	oldCargo:Destroy()
	r.ShieldUntil = nil
	cargo:SetAttribute("OwnerUserId", thief.UserId)
	cargo:SetAttribute("EggShieldUntil", nil)
	cargo:SetAttribute("TheftProtectedUntil", r.TheftReadyAt)
	showCargoProtection(cargo, PvPConfig.TransferProtection)
	cargo.Parent = thief.Character
	r.DeathConnection = thief.Character:FindFirstChildOfClass("Humanoid").Died:Connect(function()
		releaseEgg(thief, 0)
	end)
	return true, r.Source.Definition.Name
end
transfer.Parent = script
Collection.start({
	peek = ownedCargo,
	createSaved = function(template, economy)
		return makeEgg({Template = template, Color = Color3.fromRGB(109, 181, 255)}, economy)
	end,
	consume = function(player, expected)
		if ownedCargo(player) ~= expected then return false end
		releaseEgg(player, Economy.Eggs[expected.Source.Definition.Template].RespawnSeconds)
		return true
	end,
})

local function offerAttributes(egg, definition, offer)
	egg:SetAttribute("EggName", definition.Name)
	egg:SetAttribute("SellValue", offer.SellValue)
	egg:SetAttribute("Rarity", offer.Rarity)
	egg:SetAttribute("IncomeRate", offer.Income)
	egg:SetAttribute("EggTier", offer.Tier)
	egg:SetAttribute("EggScale", offer.Scale)
	egg:SetAttribute("EggId", offer.EggId)
	egg:SetAttribute("GuardianProtected", Economy.Eggs[definition.Template].GuardianProtected == true)
end

for index, definition in ipairs(definitions) do
	local policy = assert(Economy.Eggs[definition.Template], "Missing egg economy")
	local source = {Definition = definition, Shared = policy.Shared == true}
	function source.Refresh()
		-- Reroll only at spawn, never during pickup, travel or display.
		if source.Egg then
			source.Egg:Destroy()
		end
		source.Economy = Rolls.create(definition.Template, random)
		local egg, promptPart = makeEgg(definition, source.Economy)
		source.Egg = egg
		egg.Name = "Egg" .. index
		offerAttributes(egg, definition, source.Economy)
		egg:SetAttribute("SharedPickup", source.Shared)
		chooseSpawn(source)
		local details = (policy.Tiers and source.Economy.Tier .. " tier • " or "")
			.. "+" .. source.Economy.Income .. " coins/sec"
		local prompt = makePrompt(promptPart, "Grab egg", definition.Name .. " | " .. details)
		source.Prompt = prompt
		local beacon = Instance.new("BillboardGui")
		beacon.Name = "PickupBeacon"
		beacon.Size = UDim2.fromOffset(230, 58)
		beacon.StudsOffset = Vector3.new(0, 4, 0)
		beacon.MaxDistance = 70
		beacon.AlwaysOnTop = false
		beacon.Parent = promptPart
		local caption = Instance.new("TextLabel")
		caption.Size = UDim2.fromScale(1, 1)
		caption.BackgroundTransparency = 1
		caption.Text = definition.Name .. "\n" .. details .. (source.Shared and "\nAvailable to everyone" or "")
		caption.TextColor3 = definition.Color
		caption.TextStrokeTransparency = 0.2
		caption.TextSize = 17
		caption.Font = Enum.Font.GothamBold
		caption.Parent = beacon
		prompt.Triggered:Connect(function(player)
			if player:GetAttribute("CurrentBiome") ~= (definition.Biome or "Meadow") then return end
			local root, humanoid = validNearby(player, promptPart, prompt)
			if not root or not claims:canClaim(player, source, os.clock()) then return end
			local cargo = makeCargo(egg, root)
			-- Shared eggs get independent identities; exclusive cargo keeps the visible offer.
			local offer = source.Shared and Rolls.create(definition.Template, random) or source.Economy
			offerAttributes(cargo, definition, offer)
			local record = claims:claim(player, source, cargo, offer, os.clock())
			if not record then
				cargo:Destroy()
				return
			end
			if not source.Shared then
				prompt.Enabled = false
				egg.Parent = hiddenEggs
			end
			cargo.Parent = player.Character
			record.TheftReadyAt = Workspace:GetServerTimeNow() + 1
			cargo:SetAttribute("TheftProtectedUntil", record.TheftReadyAt)
			cargo:SetAttribute("OwnerUserId", player.UserId)
			record.DeathConnection = humanoid.Died:Connect(function()
				releaseEgg(player, 0)
			end)
		end)
		egg.Parent = objects
	end
	source.Refresh()
end

print("Egg collection ready: shared Common pickups, exclusive guarded eggs and fixed per-egg income rolls.")
