-- Rojo manages this script. The map and imported glider remain Studio-managed.
-- Map contract: anchored Workspace.HomeIsland is the camp floor; anchored
-- Workspace.Map.Meadow.MeadowEntrance is the Meadow landing floor.
-- These portals move the existing character in this place, preserving carried eggs.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local function floorPart(parent, name)
	local part = parent:WaitForChild(name, 10)
	assert(part and part:IsA("BasePart") and part.Anchored,
		"PortalLoop: Create an anchored Part named " .. name .. " under " .. parent:GetFullName())
	return part
end

local home = floorPart(Workspace, "HomeIsland")
local map = Workspace:WaitForChild("Map", 10)
local meadow = map and map:WaitForChild("Meadow", 10)
assert(meadow, "PortalLoop: Create Workspace/Map/Meadow")
local entrance = floorPart(meadow, "MeadowEntrance")
assert(not Workspace:FindFirstChild("PortalLoopPrototype"), "Keep only one PortalLoop script")

local objects = Instance.new("Folder")
objects.Name = "PortalLoopPrototype"
objects.Parent = Workspace

local function part(parent, name, size, transform, color, material)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = transform
	object.Color = color
	object.Material = material or Enum.Material.SmoothPlastic
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.Parent = parent
	return object
end

local function makePortal(name, floor, x, z, color, title, action, description)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = objects
	local center = floor.CFrame * CFrame.new(x, floor.Size.Y / 2 + 6, z)
	part(model, "LeftPost", Vector3.new(1.5, 12, 1.5), center * CFrame.new(-5, 0, 0), color, Enum.Material.Neon)
	part(model, "RightPost", Vector3.new(1.5, 12, 1.5), center * CFrame.new(5, 0, 0), color, Enum.Material.Neon)
	part(model, "Top", Vector3.new(11.5, 1.5, 1.5), center * CFrame.new(0, 6, 0), color, Enum.Material.Neon)
	part(model, "Step", Vector3.new(11.5, 0.4, 4), center * CFrame.new(0, -5.8, 0), color, Enum.Material.Neon)
	local field = part(model, "PortalField", Vector3.new(8.5, 10, 0.25), center, color, Enum.Material.Neon)
	field.Transparency = 0.72
	field.CanQuery = false

	local sign = Instance.new("BillboardGui")
	sign.Name = "PortalSign"
	sign.Size = UDim2.fromOffset(250, 55)
	sign.StudsOffset = Vector3.new(0, 8, 0)
	sign.AlwaysOnTop = true
	sign.MaxDistance = 150
	sign.Parent = field
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundColor3 = Color3.fromRGB(28, 43, 54)
	text.BackgroundTransparency = 0.15
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.Font = Enum.Font.GothamBold
	text.TextSize = 19
	text.Text = title
	text.Parent = sign
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = text

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TravelPrompt"
	prompt.ActionText = action
	prompt.ObjectText = description
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = field
	return field, prompt
end

local entryField, entryPrompt = makePortal("MeadowPortal", home, -22, -18,
	Color3.fromRGB(100, 255, 154), "MEADOW", "Enter Meadow", "Glide between islands and find eggs")
local exitField, exitPrompt = makePortal("CampReturnPortal", entrance, -12, 0,
	Color3.fromRGB(80, 200, 255), "BASE CAMP", "Return to camp", "Bring your egg home to bank it")

local cooldownUntil = {}

local function travel(player, field, prompt, destination, biome, allowCargo)
	if not prompt.Enabled or player.Parent ~= Players then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return end
	if (root.Position - field.Position).Magnitude > prompt.MaxActivationDistance then return end
	if not allowCargo and character:FindFirstChild("CarriedEgg") then return end
	local now = os.clock()
	if now < (cooldownUntil[player] or 0) then return end
	cooldownUntil[player] = now + 2

	-- Arrive away from the portal prompt. PivotTo moves welded cargo with the
	-- character; it does not respawn, unequip, or replace the player's glider.
	character:PivotTo(destination.CFrame * CFrame.new(0, destination.Size.Y / 2 + 4, 10))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	player:SetAttribute("CurrentBiome", biome)
end

entryPrompt.Triggered:Connect(function(player)
	travel(player, entryField, entryPrompt, entrance, "Meadow", false)
end)
exitPrompt.Triggered:Connect(function(player)
	travel(player, exitField, exitPrompt, home, "Base Camp", true)
end)

local function setupPlayer(player)
	player:SetAttribute("CurrentBiome", "Base Camp")
	player.CharacterAdded:Connect(function()
		player:SetAttribute("CurrentBiome", "Base Camp")
		cooldownUntil[player] = nil
	end)
end
Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end
Players.PlayerRemoving:Connect(function(player)
	cooldownUntil[player] = nil
end)

print("Meadow portals ready: E to travel; glide for eggs, return to camp, then bank.")
