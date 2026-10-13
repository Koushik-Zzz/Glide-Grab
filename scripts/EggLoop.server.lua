-- KOUSHIK_ROJO_SYNC_CHECK: Hello Koushik! This comment was edited from the project folder.
-- Rojo manages this script from scripts/EggLoop.server.lua.
-- Requires anchored Parts: HomeIsland, EggIsland, ChallengeIsland in Workspace.
-- Optional art templates: ServerStorage > EggModels > CommonEgg / UncommonEgg.
-- Two shared eggs; one carried egg per player; session coins (no saving yet).

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local function islandPart(name)
	local part = Workspace:WaitForChild(name, 10)
	assert(part and part:IsA("BasePart"), "Create an anchored Part named " .. name .. " in Workspace")
	return part
end

local home = islandPart("HomeIsland")
local definitions = {
	{Island = islandPart("EggIsland"), Template = "CommonEgg", Name = "Common Egg", Value = 10, Color = Color3.fromRGB(255, 220, 110)},
	{Island = islandPart("ChallengeIsland"), Template = "UncommonEgg", Name = "Uncommon Egg", Value = 25, Color = Color3.fromRGB(140, 255, 176)},
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
			or child:IsA("Constraint") then
			child:Destroy()
		end
	end
end

local function makeEgg(definition)
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
		egg.Size = Vector3.new(3, 4, 3)
		egg.Color = definition.Color
		egg.Material = Enum.Material.Neon
	else
		-- Scale all axes together so the imported egg keeps its proportions.
		local _, size = eggBounds(egg)
		local factor = 4 / math.max(size.Y, 0.01)
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

local pad = Instance.new("Part")
pad.Name = "DepositPad"
pad.Size = Vector3.new(12, 1, 12)
pad.Color = Color3.fromRGB(80, 200, 255)
pad.Material = Enum.Material.Neon
pad.Anchored = true
pad.CFrame = home.CFrame * CFrame.new(20, home.Size.Y / 2 + 0.5, 0)
pad.Parent = objects
local deposit = makePrompt(pad, "Bank egg", "Home Nest")

local carried = {}
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
	if not prompt.Enabled or player.Parent ~= Players then return nil end
	if player:GetAttribute("PortalTraveling") then return nil end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then return nil end
	if (root.Position - part.Position).Magnitude > prompt.MaxActivationDistance then return nil end
	return root, humanoid
end

local function releaseEgg(player, respawnDelay)
	local record = carried[player]
	if not record then return end
	carried[player] = nil
	if record.DeathConnection then
		record.DeathConnection:Disconnect()
	end
	if record.Cargo then
		record.Cargo:Destroy()
	end
	local source = record.Source
	source.Carrier = nil
	-- Keep the source unavailable until its respawn timer finishes.
	task.delay(respawnDelay, function()
		if objects.Parent and source.Egg.Parent == hiddenEggs then
			chooseSpawn(source)
			source.Egg.Parent = objects
			source.Prompt.Enabled = true
		end
	end)
end

-- Server-only interface: guardian catches go through the same ownership cleanup
-- as banking/death. No client remote can drop or transfer an egg.
local guardianCatch = Instance.new("BindableFunction")
guardianCatch.Name = "GuardianCatch"
guardianCatch.OnInvoke = function(player, cargo)
	local record = carried[player]
	if not record or record.Cargo ~= cargo or record.Source.Carrier ~= player then return false end
	if cargo.Parent ~= player.Character or record.Source.Definition.Template ~= "UncommonEgg" then return false end
	if player:GetAttribute("CurrentBiome") ~= "Meadow" or player:GetAttribute("PortalTraveling") then return false end
	releaseEgg(player, 3)
	return true
end
guardianCatch.Parent = script

local function setupPlayer(player)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = player
	end
	if not stats:FindFirstChild("Coins") then
		local coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Parent = stats
	end
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
end)

for index, definition in ipairs(definitions) do
	local egg, promptPart = makeEgg(definition)
	egg.Name = "Egg" .. tostring(index)
	local _, size = eggBounds(egg)
	positionEgg(egg, definition.Island.CFrame * CFrame.new(0, definition.Island.Size.Y / 2 + size.Y / 2, 0))
	egg:SetAttribute("EggName", definition.Name)
	egg:SetAttribute("BankValue", definition.Value)
	egg.Parent = objects
	local prompt = makePrompt(promptPart, "Grab egg", definition.Name .. " | " .. definition.Value .. " coins")
	local source = {Egg = egg, Prompt = prompt, Definition = definition, Carrier = nil}
	chooseSpawn(source)
	local beacon = Instance.new("BillboardGui")
	beacon.Name = "PickupBeacon"
	beacon.Size = UDim2.fromOffset(170, 44)
	beacon.StudsOffset = Vector3.new(0, 4, 0)
	beacon.MaxDistance = 70
	beacon.AlwaysOnTop = false
	beacon.Parent = promptPart
	local caption = Instance.new("TextLabel")
	caption.Size = UDim2.fromScale(1, 1)
	caption.BackgroundTransparency = 1
	caption.Text = definition.Name .. "\n" .. definition.Value .. " coins at camp"
	caption.TextColor3 = definition.Color
	caption.TextStrokeTransparency = 0.2
	caption.TextSize = 17
	caption.Font = Enum.Font.GothamBold
	caption.Parent = beacon
	prompt.Triggered:Connect(function(player)
		if player:GetAttribute("CurrentBiome") ~= "Meadow" then return end
		local root, humanoid = validNearby(player, promptPart, prompt)
		if not root or source.Carrier or carried[player] then return end
		local cargo = makeCargo(egg, root)
		-- No yields between checking availability and reserving the egg.
		source.Carrier = player
		prompt.Enabled = false
		-- Moving the whole source also hides decals, lights and other effects.
		egg.Parent = hiddenEggs
		cargo.Parent = player.Character
		local record = {Source = source, Cargo = cargo}
		carried[player] = record
		record.DeathConnection = humanoid.Died:Connect(function()
			releaseEgg(player, 0)
		end)
	end)
end

deposit.Triggered:Connect(function(player)
	if player:GetAttribute("CurrentBiome") ~= "Base Camp" then return end
	local record = carried[player]
	if not record or not validNearby(player, pad, deposit) then return end
	if record.Source.Carrier ~= player or record.Cargo.Parent ~= player.Character then return end
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if not coins or not coins:IsA("IntValue") then return end
	-- Value comes from our server definition, never from the client.
	local definition = record.Source.Definition
	releaseEgg(player, 3)
	coins.Value = coins.Value + definition.Value
	print(player.Name .. " banked " .. definition.Name .. " for " .. definition.Value .. " coins! Total: " .. coins.Value)
end)

print("Two egg routes ready: Common = 10 coins, Uncommon = 25 coins.")
