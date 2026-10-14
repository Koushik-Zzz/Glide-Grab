-- One-time Edit-mode camp refresh. Not a runtime script or a Rojo scene build.
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local home = Workspace:WaitForChild("HomeIsland")
local displays = Workspace:WaitForChild("CampEggDisplays")
local backups = ServerStorage:WaitForChild("ImportedAssetBackups")
assert(not Workspace:FindFirstChild("CampPresentation"), "Camp presentation already exists; edit it directly")
assert(not backups:FindFirstChild("CampBeforePresentation"), "Camp backup already exists")
assert(not displays:FindFirstChild("DisplayedEgg", true), "Stop Play before refreshing camp")
local saved = Instance.new("Folder")
saved.Name = "CampBeforePresentation"
for _, object in ipairs({home, Workspace.SpawnLocation, displays, Workspace.BoostWorkshop}) do
	object:Clone().Parent = saved
end
saved.Parent = backups
local legacyLaunch = Workspace:FindFirstChild("LaunchPad")
if legacyLaunch then
	legacyLaunch.Name = "LegacyLaunchPad"
	legacyLaunch.Parent = saved
end

local scene = Instance.new("Model")
scene.Name = "CampPresentation"
scene.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
scene:SetAttribute("PresentationVersion", 1)
scene:SetAttribute("PlotWidth", 76)
scene:SetAttribute("PlotDepth", 76)
scene:SetAttribute("EntryWidth", 19)
scene.Parent = Workspace
home.Size = Vector3.new(112, home.Size.Y, 112)
home.Color = Color3.fromRGB(117, 80, 48)
home.Material = Enum.Material.Plastic
local top = home.Size.Y / 2
local rootCF = home.CFrame * CFrame.new(0, top, 0)
local studSource = backups.ResolvedClassicStudTexture
local oldTexture = home:FindFirstChild("StuddedGround")
if oldTexture then
	oldTexture.Transparency = 1
end

local colors = {
	light = Color3.fromRGB(137, 207, 80), dark = Color3.fromRGB(104, 182, 65),
	wood = Color3.fromRGB(175, 104, 40), rail = Color3.fromRGB(208, 134, 53),
	post = Color3.fromRGB(73, 57, 58), cap = Color3.fromRGB(110, 83, 70),
	cream = Color3.fromRGB(249, 244, 214), gold = Color3.fromRGB(229, 185, 73),
}

local function group(name)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = scene
	return folder
end

local function part(parent, name, size, transform, color, material, collide)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = transform
	object.Color = color
	object.Material = material or Enum.Material.Plastic
	object.Anchored = true
	object.CanCollide = collide == true
	object.CanTouch = false
	object.CanQuery = collide == true
	object.CastShadow = material == Enum.Material.Wood
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function texture(object, face, tint)
	local t = Instance.new("Texture")
	t.Name = "StuddedGround"
	t.Texture = studSource.Texture
	t.Face = face
	t.StudsPerTileU, t.StudsPerTileV = 4, 4
	t.Color3 = tint
	t.Transparency = 0.12
	t.Parent = object
end

local ground = group("CheckerGround")
for z = 0, 6 do
	for x = 0, 6 do
		local tint = (x + z) % 2 == 0 and colors.light or colors.dark
		local tile = part(ground, "Tile_" .. x .. "_" .. z, Vector3.new(16, 0.04, 16),
			rootCF * CFrame.new(-48 + x * 16, 0.02, -48 + z * 16), tint)
		texture(tile, Enum.NormalId.Top, tint)
	end
	task.wait()
end

local fences = group("PlotFence")
local posts = {}
local function post(x, z, tall)
	local key = string.format("%.2f,%.2f", x, z)
	if posts[key] then return end
	posts[key] = true
	local height = tall and 12 or 5.2
	part(fences, "Post", Vector3.new(1.35, height, 1.35), rootCF * CFrame.new(x, height / 2, z), colors.post, Enum.Material.Wood)
	part(fences, "PostCap", Vector3.new(1.65, 0.35, 1.65), rootCF * CFrame.new(x, height + 0.12, z), colors.cap, Enum.Material.Wood)
	-- Smooth invisible box collisions avoid catching feet on individual braces.
	local collider = part(fences, "PostCollision", Vector3.new(1.35, 5.2, 1.35),
		rootCF * CFrame.new(x, 2.6, z), colors.post, nil, true)
	collider.Transparency = 1
	collider.CastShadow = false
end

local function beam(parent, name, from, to, width, thickness, color)
	local a, b = rootCF:PointToWorldSpace(from), rootCF:PointToWorldSpace(to)
	return part(parent, name, Vector3.new(width, thickness, (b - a).Magnitude),
		CFrame.lookAt((a + b) / 2, b), color, Enum.Material.Wood)
end

local function panel(from, to)
	local model = Instance.new("Model")
	model.Name = "CrossBracedPanel"
	model.Parent = fences
	local direction = (to - from).Unit
	local a, b = from + direction * 0.5, to - direction * 0.5
	beam(model, "LowerRail", a + Vector3.yAxis * 0.8, b + Vector3.yAxis * 0.8, 0.6, 0.65, colors.wood)
	beam(model, "UpperRail", a + Vector3.yAxis * 4.2, b + Vector3.yAxis * 4.2, 0.6, 0.65, colors.rail)
	beam(model, "BraceA", a + Vector3.yAxis * 1.15, b + Vector3.yAxis * 3.85, 0.35, 0.45, colors.wood)
	beam(model, "BraceB", a + Vector3.yAxis * 3.85, b + Vector3.yAxis * 1.15, 0.35, 0.45, colors.rail)
	local wall = beam(model, "PanelCollision", from + Vector3.yAxis * 2.5,
		to + Vector3.yAxis * 2.5, 0.8, 5, colors.wood)
	wall.Transparency = 1
	wall.CanCollide, wall.CanQuery = true, true
	wall.CastShadow = false
	post(from.X, from.Z, false)
	post(to.X, to.Z, false)
end

for i = 0, 7 do
	local a, b = -38 + i * 9.5, -38 + (i + 1) * 9.5
	panel(Vector3.new(a, 0, 38), Vector3.new(b, 0, 38))
	panel(Vector3.new(-38, 0, a), Vector3.new(-38, 0, b))
	panel(Vector3.new(38, 0, a), Vector3.new(38, 0, b))
	if i ~= 3 and i ~= 4 then
		panel(Vector3.new(a, 0, -38), Vector3.new(b, 0, -38))
	end
	if i % 2 == 1 then
		task.wait()
	end
end

-- Taller entry posts and a double-sided, owner-labelled board over the opening.
local entrance = group("Entrance")
for _, x in ipairs({-9.5, 9.5}) do
	part(entrance, "GatePost", Vector3.new(1.7, 12, 1.7), rootCF * CFrame.new(x, 6, -38), colors.post, Enum.Material.Wood)
	part(entrance, "GateCap", Vector3.new(2.1, 0.4, 2.1), rootCF * CFrame.new(x, 12.1, -38), colors.gold)
end
local board = part(displays, "PlotSign", Vector3.new(18, 3.4, 0.65), rootCF * CFrame.new(0, 10.8, -38), colors.post, Enum.Material.Wood)
for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
	local gui = Instance.new("SurfaceGui")
	gui.Name = face.Name .. "Sign"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = board
	local title = Instance.new("TextLabel")
	title.Name = "OwnerLabel"
	title.Size = UDim2.new(1, -24, 0.62, 0)
	title.Position = UDim2.fromOffset(12, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Text = "YOUR CAMP"
	title.TextColor3 = colors.cream
	title.TextScaled = true
	title.Parent = gui
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Position = UDim2.fromScale(0, 0.68)
	subtitle.Size = UDim2.fromScale(1, 0.25)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.GothamBold
	subtitle.Text = "GLIDE & GRAB • EGG GARDEN"
	subtitle.TextColor3 = colors.gold
	subtitle.TextScaled = true
	subtitle.Parent = gui
end

-- Low decorative frames below the existing flowers; anchors and slots stay put.
for _, slot in ipairs(displays.Slots:GetChildren()) do
	local transform = slot.SlotRoot.CFrame
	part(slot, "DisplayFrame", Vector3.new(9.2, 0.08, 9.2),
		transform * CFrame.new(0, -0.045, 0), colors.gold)
	part(slot, "DisplayMat", Vector3.new(8.8, 0.07, 8.8),
		transform * CFrame.new(0, 0, 0), colors.cream)
end

local routes = group("Routes")
local walkway = beam(routes, "MeadowWalkway", Vector3.new(0, 0.065, 20), Vector3.new(-22, 0.065, -18), 4, 0.02, Color3.fromRGB(215, 231, 163))
walkway.Material = Enum.Material.Plastic
walkway.CastShadow = false
local collectPath = beam(routes, "CollectionWalkway", Vector3.new(0, 0.07, 10), Vector3.new(20, 0.07, 0), 3, 0.02, Color3.fromRGB(201, 235, 197))
collectPath.Material = Enum.Material.Plastic
collectPath.CastShadow = false

local spawn = Workspace.SpawnLocation
spawn.Transparency = 1
spawn.CanCollide = false
for _, child in ipairs(spawn:GetChildren()) do
	if child:IsA("Decal") then
		child.Transparency = 1
	end
end
local welcome = part(routes, "WelcomeRing", Vector3.new(0.12, 14, 14), rootCF * CFrame.new(0, 0.1, 20) * CFrame.Angles(0, 0, math.pi / 2), colors.gold)
welcome.Shape = Enum.PartType.Cylinder
local center = part(routes, "WelcomePad", Vector3.new(0.13, 12.8, 12.8), rootCF * CFrame.new(0, 0.13, 20) * CFrame.Angles(0, 0, math.pi / 2), colors.cream)
center.Shape = Enum.PartType.Cylinder

local plants = group("CornerPlanters")
for _, x in ipairs({-45, 45}) do
	for _, z in ipairs({-45, 45}) do
		part(plants, "Planter", Vector3.new(4, 1.3, 4), rootCF * CFrame.new(x, 0.65, z), colors.wood, Enum.Material.Wood)
		for index = 1, 3 do
			local offset = Vector3.new((index - 2) * 0.9, 2, (index % 2) * 0.6 - 0.3)
			local bush = part(plants, "Bush", Vector3.new(2.1, 2, 2.1), rootCF * CFrame.new(Vector3.new(x, 0, z) + offset), Color3.fromRGB(66, 153, 68))
			bush.Shape = Enum.PartType.Ball
			local blossom = part(plants, "Blossom", Vector3.new(0.65, 0.65, 0.65), rootCF * CFrame.new(Vector3.new(x, 1, z) + offset), index == 2 and colors.cream or Color3.fromRGB(248, 152, 171))
			blossom.Shape = Enum.PartType.Ball
		end
	end
end

-- Authoring markers only: no locked fake floor or extra income slots yet.
local marker = part(scene, "PlotOrigin", Vector3.new(0.2, 0.2, 0.2), rootCF, colors.cream)
marker.Transparency = 1
local upper = Instance.new("Attachment")
upper.Name = "UpperFloorAnchor"
upper.CFrame = CFrame.new(0, 22, 16)
upper:SetAttribute("Width", 72)
upper:SetAttribute("Depth", 44)
upper:SetAttribute("PlannedAdditionalSlots", 6)
upper.Parent = marker
displays:SetAttribute("FloorCount", 1)
displays:SetAttribute("SlotsPerFloor", 6)
game:GetService("ChangeHistoryService"):SetWaypoint("Build checkerboard camp and cross-braced plot fence")
return {tiles = #ground:GetChildren(), panels = 30, slots = #displays.Slots:GetChildren(), footprint = home.Size}
