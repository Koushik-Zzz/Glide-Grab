-- One-time Edit-mode migration of the decorated solo camp to six private gardens.
-- Source-only Rojo builds never replace the authored place.
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before migrating camp")
assert(not Workspace:FindFirstChild("CampPlots"), "Shared camp already exists; edit it directly")
local home = Workspace:WaitForChild("HomeIsland")
local displays = Workspace:WaitForChild("CampEggDisplays")
local presentation = Workspace:WaitForChild("CampPresentation")
local backups = ServerStorage:WaitForChild("ImportedAssetBackups")
assert(not backups:FindFirstChild("BeforeSharedCamp"), "Shared camp backup already exists")
assert(not displays:FindFirstChild("DisplayedEgg", true), "Do not save runtime displays")
local saved = Instance.new("Folder")
saved.Name = "BeforeSharedCamp"
saved.Parent = backups
for _, object in ipairs({home, displays, presentation, Workspace.BoostWorkshop, Workspace.SpawnLocation}) do
	object:Clone().Parent = saved
	task.wait()
end

local rootCF = home.CFrame * CFrame.new(0, home.Size.Y / 2, 0)
local template = displays:Clone()
template.Name = "SharedCampPlotTemplate"
local decor = presentation:Clone()
decor.Name = "Presentation"
for _, name in ipairs({"CheckerGround", "Routes", "CornerPlanters"}) do
	decor[name]:Destroy()
end
decor.Parent = template
local origin = decor.PlotOrigin
template.PrimaryPart = origin
local function part(parent, name, size, cf, color)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = cf
	object.Anchored = true
	object.CanCollide, object.CanTouch, object.CanQuery = false, false, false
	object.CastShadow = false
	object.Color = color
	object.Material = Enum.Material.Plastic
	object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end
local pad = part(template, "CollectionPad", Vector3.new(12, 0.4, 12),
	rootCF * CFrame.new(20, 0.25, 0), Color3.fromRGB(80, 200, 255))
pad.Material = Enum.Material.Neon
local prompt = Instance.new("ProximityPrompt")
prompt.Name = "DepositPrompt"
prompt.ActionText = "Place egg / collect income"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
prompt.HoldDuration = 0.3
prompt.MaxActivationDistance = 12
prompt.RequiresLineOfSight = false
prompt.Enabled = false
prompt.Parent = pad
for _, label in ipairs(template.PlotSign:GetDescendants()) do
	if label:IsA("TextLabel") and label.Name == "OwnerLabel" then
		label.Text = "AVAILABLE CAMP"
	end
end
template.Parent = saved

home.Size = Vector3.new(256, home.Size.Y, 336)
local shared = Instance.new("Model")
shared.Name = "SharedCamp"
shared.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
shared.Parent = Workspace
local ground = Instance.new("Folder")
ground.Name = "CheckerGround"
ground.Parent = shared
local studSource = backups.ResolvedClassicStudTexture
for z = 0, 20 do
	for x = 0, 15 do
		local tint = (x + z) % 2 == 0 and Color3.fromRGB(137, 207, 80) or Color3.fromRGB(104, 182, 65)
		local tile = part(ground, "Tile_" .. x .. "_" .. z, Vector3.new(16, 0.04, 16),
			rootCF * CFrame.new(-120 + x * 16, 0.02, -160 + z * 16), tint)
		local texture = Instance.new("Texture")
		texture.Name = "StuddedGround"
		texture.Texture = studSource.Texture
		texture.Face = Enum.NormalId.Top
		texture.StudsPerTileU, texture.StudsPerTileV = 4, 4
		texture.Color3 = tint
		texture.Transparency = 0.12
		texture.Parent = tile
	end
	task.wait()
end
local plots = Instance.new("Folder")
plots.Name = "CampPlots"
plots.Parent = Workspace
local centers = {
	Vector3.new(-72, 0, 0), Vector3.new(72, 0, 0),
	Vector3.new(-72, 0, -100), Vector3.new(72, 0, -100),
	Vector3.new(-72, 0, 100), Vector3.new(72, 0, 100),
}
for index, center in ipairs(centers) do
	local plot = template:Clone()
	plot.Name = "Plot" .. index
	plot:SetAttribute("PlotIndex", index)
	plot:SetAttribute("OwnerUserId", nil)
	plot.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local angle = center.X < 0 and -math.pi / 2 or math.pi / 2
	plot:PivotTo(rootCF * CFrame.new(center) * CFrame.Angles(0, angle, 0))
	plot.Parent = plots
	task.wait()
end

local anchors = Instance.new("Folder")
anchors.Name = "Anchors"
anchors.Parent = shared
local portal = part(anchors, "MeadowPortal", Vector3.new(0.2, 0.2, 0.2),
	rootCF * CFrame.new(18, 6, -146), Color3.fromRGB(100, 255, 154))
portal.Transparency = 1
portal:SetAttribute("RequiredRebirths", 0)
Workspace.BoostWorkshop:PivotTo(rootCF * CFrame.new(-22, 5.5, -146))
Workspace.SpawnLocation.CFrame = rootCF * CFrame.new(0, 0.5, 146)
local routes = Instance.new("Folder")
routes.Name = "Routes"
routes.Parent = shared
part(routes, "PublicWalkway", Vector3.new(12, 0.04, 294),
	rootCF * CFrame.new(0, 0.07, 0), Color3.fromRGB(215, 231, 163))
for _, z in ipairs({-100, 0, 100}) do
	part(routes, "GardenWalkway", Vector3.new(66, 0.04, 6),
		rootCF * CFrame.new(0, 0.08, z), Color3.fromRGB(215, 231, 163))
end
part(routes, "PublicPlaza", Vector3.new(64, 0.04, 22),
	rootCF * CFrame.new(0, 0.09, -146), Color3.fromRGB(201, 235, 197))
local welcome = part(routes, "WelcomePad", Vector3.new(0.12, 14, 14),
	rootCF * CFrame.new(0, 0.11, 146) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(249, 244, 214))
welcome.Shape = Enum.PartType.Cylinder
presentation:Destroy()
displays:Destroy()
game:GetService("ChangeHistoryService"):SetWaypoint("Six personal egg gardens and shared portal workshop plaza")
return {plots = #plots:GetChildren(), pillows = 36, tiles = #ground:GetChildren(), floor = tostring(home.Size)}
