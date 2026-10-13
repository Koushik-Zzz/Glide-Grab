-- A small local leaf effect makes the gust volume readable without asset downloads.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local leaves = {}
local effects = nil

local function clear()
	if effects then
		effects:Destroy()
	end
	effects = nil
	leaves = {}
end

local function create()
	effects = Instance.new("Folder")
	effects.Name = "LocalMeadowLeaves"
	for index = 1, 22 do
		local leaf = Instance.new("WedgePart")
		leaf.Name = "Leaf" .. index
		leaf.Size = Vector3.new(1.6, 0.2, 0.8)
		leaf.Anchored = true
		leaf.CanCollide = false
		leaf.CanTouch = false
		leaf.CanQuery = false
		leaf.CastShadow = false
		leaf.Material = Enum.Material.Neon
		leaf.Color = index % 2 == 0 and Color3.fromRGB(190, 235, 147) or Color3.fromRGB(116, 204, 156)
		leaf.Parent = effects
		table.insert(leaves, leaf)
	end
	effects.Parent = Workspace
end

script.Destroying:Connect(clear)
while script.Parent do
	local map = Workspace:FindFirstChild("Map")
	local meadow = map and map:FindFirstChild("Meadow")
	local zone = meadow and meadow:FindFirstChild("WindGust")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local visible = zone and root and player:GetAttribute("CurrentBiome") == "Meadow"
		and (root.Position - zone.Position).Magnitude < 450
	if visible then
		if not effects then
			create()
		end
		local phase = zone:GetAttribute("Phase")
		local speed = phase == "Gust" and 90 or phase == "Warning" and 24 or 6
		local now = Workspace:GetServerTimeNow()
		for index, leaf in ipairs(leaves) do
			local x = ((now * speed + index * 23) % zone.Size.X) - zone.Size.X / 2
			local y = ((index * 17) % 76) - 38 + math.sin(now * 2 + index) * 3
			local z = ((index * 29) % 100) - 50
			leaf.CFrame = zone.CFrame * CFrame.new(x, y, z) * CFrame.Angles(0, now + index, math.sin(now + index) * 0.6)
			leaf.Size = phase == "Gust" and Vector3.new(4, 0.15, 0.65) or Vector3.new(1.6, 0.2, 0.8)
			leaf.Transparency = phase == "Calm" and 0.5 or 0.05
		end
	else
		if effects then
			clear()
		end
	end
	task.wait(visible and 1 / 30 or 0.25)
end
clear()
