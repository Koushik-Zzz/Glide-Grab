-- KOUSHIK_ROJO_SYNC_CHECK: Hello Koushik! This comment was edited from the project folder.
-- Rojo manages this script from scripts/EggLoop.server.lua.
-- Requires anchored Parts: HomeIsland, EggIsland, ChallengeIsland in Workspace.
-- Two shared eggs; one carried egg per player; session coins (no saving yet).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local function islandPart(name)
	local part = Workspace:WaitForChild(name, 10)
	assert(part and part:IsA("BasePart"), "Create an anchored Part named " .. name .. " in Workspace")
	return part
end

local home = islandPart("HomeIsland")
local definitions = {
	{Island = islandPart("EggIsland"), Name = "Common Egg", Value = 10, Color = Color3.fromRGB(255, 220, 110)},
	{Island = islandPart("ChallengeIsland"), Name = "Uncommon Egg", Value = 25, Color = Color3.fromRGB(140, 255, 176)},
}
assert(not Workspace:FindFirstChild("EggLoopPrototype"), "Keep only one EggLoop script")
local objects = Instance.new("Folder")
objects.Name = "EggLoopPrototype"
objects.Parent = Workspace

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

local function validNearby(player, part, prompt)
	if not prompt.Enabled or player.Parent ~= Players then return nil end
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
	if record.DeathConnection then record.DeathConnection:Disconnect() end
	if record.Cargo then record.Cargo:Destroy() end
	local source = record.Source
	source.Carrier = nil
	-- Keep the source unavailable until its respawn timer finishes.
	task.delay(respawnDelay, function()
		if source.Part.Parent then
			source.Part.Transparency = 0
			source.Prompt.Enabled = true
		end
	end)
end

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
for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
Players.PlayerRemoving:Connect(function(player)
	releaseEgg(player, 0)
end)

for index, definition in ipairs(definitions) do
	local egg = Instance.new("Part")
	egg.Name = "Egg" .. tostring(index)
	egg.Shape = Enum.PartType.Ball
	egg.Size = Vector3.new(3, 4, 3)
	egg.Color = definition.Color
	egg.Material = Enum.Material.Neon
	egg.Anchored = true
	egg.CanCollide = false
	egg.CFrame = definition.Island.CFrame * CFrame.new(0, definition.Island.Size.Y / 2 + 2, 0)
	egg:SetAttribute("EggName", definition.Name)
	egg:SetAttribute("BankValue", definition.Value)
	egg.Parent = objects
	local prompt = makePrompt(egg, "Grab egg", definition.Name .. " | " .. definition.Value .. " coins")
	local source = {Part = egg, Prompt = prompt, Definition = definition, Carrier = nil}
	prompt.Triggered:Connect(function(player)
		local root, humanoid = validNearby(player, egg, prompt)
		if not root or source.Carrier or carried[player] then return end
		-- No yields between checking availability and reserving the egg.
		source.Carrier = player
		prompt.Enabled = false
		egg.Transparency = 1
		local cargo = egg:Clone()
		cargo:ClearAllChildren()
		cargo.Name = "CarriedEgg"
		cargo.Transparency = 0
		cargo.Anchored = false
		cargo.CanCollide = false
		cargo.CanTouch = false
		cargo.CanQuery = false
		cargo.Massless = true
		cargo.CFrame = root.CFrame * CFrame.new(0, 0, -3)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = cargo
		weld.Parent = cargo
		cargo.Parent = player.Character
		local record = {Source = source, Cargo = cargo}
		carried[player] = record
		record.DeathConnection = humanoid.Died:Connect(function()
			releaseEgg(player, 0)
		end)
	end)
end

deposit.Triggered:Connect(function(player)
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
