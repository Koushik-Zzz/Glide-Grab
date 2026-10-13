-- One-time EDIT MODE scene setup, run through Studio MCP or the Command Bar.
-- Not a runtime script and not mapped by Rojo. Originals stay in ServerStorage.
local ServerStorage = game:GetService("ServerStorage")
local meadow = workspace.Map.Meadow
assert(not meadow:GetAttribute("MeadowSceneReady"), "Meadow scene is already configured")
local island = meadow:FindFirstChild("Shadow's Island")
assert(island and island:IsA("Model"), "Expected the imported Shadow's Island model")
local eggModels = ServerStorage.EggModels
local pack = eggModels:FindFirstChild("Model")
assert(pack and not eggModels:FindFirstChild("CommonEgg"), "Expected the original egg pack")

local backups = ServerStorage:FindFirstChild("ImportedAssetBackups")
if not backups then
	backups = Instance.new("Folder")
	backups.Name = "ImportedAssetBackups"
	backups.Parent = ServerStorage
end
assert(not backups:FindFirstChild("OriginalMeadowIsland"), "Original backup already exists; inspect before rerunning")

-- Parent small subtrees separately so the Studio editor stays responsive.
local backup = island:Clone()
backup.Name = "OriginalMeadowIsland"
local copiedChildren = backup:GetChildren()
for _, child in ipairs(copiedChildren) do
	child.Parent = nil
end
backup.Parent = backups
for index, child in ipairs(copiedChildren) do
	child.Parent = backup
	if index % 20 == 0 then task.wait() end
end
assert(#backup:GetDescendants() == #island:GetDescendants(), "Island backup incomplete")
local eggBackup = pack:Clone()
eggBackup.Name = "OriginalEggPack"
eggBackup.Parent = backups
local anchorBackup = Instance.new("Folder")
anchorBackup.Name = "OriginalPrototypeFloors"
anchorBackup.Parent = backups
for _, name in ipairs({"HomeIsland", "EggIsland", "ChallengeIsland", "LaunchPad"}) do
	workspace[name]:Clone().Parent = anchorBackup
end

local eggs = {}
for _, child in ipairs(pack:GetChildren()) do
	if child:IsA("MeshPart") then table.insert(eggs, child) end
end
assert(#eggs == 5, "Expected five individual egg MeshParts")
table.sort(eggs, function(a, b) return a.Position.X < b.Position.X end)
eggs[1].Name = "CommonEgg"
eggs[1].Anchored = true
eggs[1].Parent = eggModels
eggs[5].Name = "UncommonEgg"
eggs[5].Anchored = true
eggs[5].Parent = eggModels
pack.Name = "UnusedEggPack"

-- Keep the floating terrain and natural scenery. Booths, houses, signs,
-- fences, the imported spawn and their gameplay logic remain in the backup.
local terrain = nil
local removed = 0
for index, child in ipairs(island:GetChildren()) do
	local keep = false
	if child:IsA("Model") then
		local _, size = child:GetBoundingBox()
		if size.X > 200 and size.Y > 100 then
			terrain = child
			child.Name = "TerrainGeometry"
			keep = true
		elseif #child:GetDescendants() <= 10 and size.Y > 20 then
			keep = true -- the imported low-poly trees
		elseif string.find(string.lower(child.Name), "rock", 1, true) then
			keep = true
		end
	elseif child:IsA("BasePart") and string.find(string.lower(child.Name), "rock", 1, true) then
		keep = true
	end
	if not keep then
		removed += 1
		child:Destroy()
	end
	if index % 20 == 0 then task.wait() end
end
assert(terrain, "Could not identify the imported floating terrain")
for index, child in ipairs(island:GetDescendants()) do
	if child:IsA("LuaSourceContainer") or child:IsA("ProximityPrompt") then
		child:Destroy()
	elseif child:IsA("BasePart") then
		child.Anchored = true
	end
	if index % 500 == 0 then task.wait() end
end

local function placeIsland(model, name, width, topCenter)
	model.Name = name
	local ground = model.TerrainGeometry
	local _, size = ground:GetBoundingBox()
	model:ScaleTo(model:GetScale() * width / size.X)
	local groundCF, groundSize = ground:GetBoundingBox()
	local oldTop = groundCF.Position + Vector3.new(0, groundSize.Y / 2, 0)
	model:PivotTo(CFrame.new(topCenter - oldTop) * model:GetPivot())
	model:SetAttribute("GroundTop", topCenter)
	model.Parent = meadow
end

local entranceArt = island:Clone()
placeIsland(entranceArt, "MeadowEntranceIsland", 82, Vector3.new(0, 104, -1700))
local uncommonArt = island:Clone()
placeIsland(uncommonArt, "MeadowIsland02", 95, Vector3.new(180, 155, -2190))
placeIsland(island, "MeadowIsland01", 110, Vector3.new(0, 125, -1930))

local entrance = Instance.new("Part")
entrance.Name = "MeadowEntrance"
entrance.Size = Vector3.new(50, 1, 50)
entrance.CFrame = CFrame.new(0, 104.5, -1700)
entrance.Anchored = true
entrance.Material = Enum.Material.Slate
entrance.Color = Color3.fromRGB(154, 189, 168)
entrance.Parent = meadow

-- Existing EggLoop uses these named Parts as spawn markers. The natural
-- island terrain supplies the actual floor; markers are invisible.
for _, entry in ipairs({
	{workspace.EggIsland, Vector3.new(0, 124.5, -1930)},
	{workspace.ChallengeIsland, Vector3.new(180, 154.5, -2190)},
}) do
	local marker = entry[1]
	marker.Size = Vector3.new(1, 1, 1)
	marker.CFrame = CFrame.new(entry[2])
	marker.Transparency = 1
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
end

local function islandLabel(parent, text, topCenter, color)
	local point = Instance.new("Part")
	point.Name = "RouteSign"
	point.Size = Vector3.new(1, 1, 1)
	point.CFrame = CFrame.new(topCenter + Vector3.new(0, 11, 0))
	point.Anchored = true
	point.Transparency = 1
	point.CanCollide = false
	point.CanTouch = false
	point.CanQuery = false
	point.Parent = parent
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(240, 56)
	gui.MaxDistance = 450
	gui.AlwaysOnTop = false
	gui.Parent = point
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.25
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
end
islandLabel(island, "COMMON EGG\n+10 coins at camp", Vector3.new(0, 125, -1930), Color3.fromRGB(255, 229, 146))
islandLabel(uncommonArt, "UNCOMMON EGG\n+25 coins at camp", Vector3.new(180, 155, -2190), Color3.fromRGB(158, 255, 202))
meadow:SetAttribute("MeadowSceneReady", true)
game:GetService("ChangeHistoryService"):SetWaypoint("Organize eggs and build Meadow route")
return "Meadow configured: two egg templates, three natural floating islands, original assets backed up. Removed " .. removed .. " unrelated root objects."
