-- Authored Edit-mode perimeter for the shared camp. Not mapped as runtime code.
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before building camp walls")
local home = Workspace:WaitForChild("HomeIsland")
local shared = Workspace:WaitForChild("SharedCamp")
assert(not shared:FindFirstChild("PerimeterWalls"), "Walls already exist; edit them directly")
local source = shared.CheckerGround:FindFirstChildWhichIsA("BasePart")
local stud = assert(source and source:FindFirstChild("StuddedGround"), "Missing camp stud texture")
local rootCF = home.CFrame * CFrame.new(0, home.Size.Y / 2, 0)
local halfX, halfZ = home.Size.X / 2, home.Size.Z / 2
local height, thickness, tileSize = 48, 4, 16
local light, dark = Color3.fromRGB(137, 207, 80), Color3.fromRGB(104, 182, 65)
local walls = Instance.new("Model")
walls.Name = "PerimeterWalls"
walls.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
walls:SetAttribute("HeightAboveFloor", height)
walls:SetAttribute("Thickness", thickness)
walls.Parent = shared
local saved = Instance.new("Folder")
saved.Name = "BeforeCampWalls"
saved.Parent = ServerStorage:WaitForChild("ImportedAssetBackups")
home:Clone().Parent = saved

local function part(parent, name, size, cf, color, collide)
	local object = Instance.new("Part")
	object.Name, object.Size, object.CFrame, object.Color = name, size, cf, color
	object.Anchored = true
	object.CanCollide, object.CanQuery = collide == true, collide == true
	object.CanTouch = false
	object.CastShadow = collide == true
	object.Material = Enum.Material.Plastic
	object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end
local function texture(object, face, tint)
	local t = stud:Clone()
	t.Face, t.Color3 = face, tint
	t.StudsPerTileU, t.StudsPerTileV = 4, 4
	t.Parent = object
end
local descriptions = {
	{Name = "North", Length = home.Size.X, Position = Vector3.new(0, 0, -halfZ),
		Inward = Vector3.zAxis, Size = Vector3.new(home.Size.X + thickness * 2, height + home.Size.Y, thickness)},
	{Name = "South", Length = home.Size.X, Position = Vector3.new(0, 0, halfZ),
		Inward = -Vector3.zAxis, Size = Vector3.new(home.Size.X + thickness * 2, height + home.Size.Y, thickness)},
	{Name = "West", Length = home.Size.Z, Position = Vector3.new(-halfX, 0, 0),
		Inward = Vector3.xAxis, Size = Vector3.new(thickness, height + home.Size.Y, home.Size.Z)},
	{Name = "East", Length = home.Size.Z, Position = Vector3.new(halfX, 0, 0),
		Inward = -Vector3.xAxis, Size = Vector3.new(thickness, height + home.Size.Y, home.Size.Z)},
}
local tiles = 0
for _, description in ipairs(descriptions) do
	local side = Instance.new("Model")
	side.Name = description.Name
	side.Parent = walls
	local position = description.Position - description.Inward * (thickness / 2)
	local wall = part(side, "Wall", description.Size,
		rootCF * CFrame.new(position + Vector3.yAxis * ((height - home.Size.Y) / 2)), dark, true)
	texture(wall, Enum.NormalId.Top, light)
	local facePosition = description.Position + description.Inward * 0.02
	local faceCF = rootCF * CFrame.lookAt(facePosition, facePosition + description.Inward)
	local columns = math.ceil(description.Length / tileSize)
	for row = 0, height / tileSize - 1 do
		for column = 0, columns - 1 do
			local start = -description.Length / 2 + column * tileSize
			local width = math.min(tileSize, description.Length - column * tileSize)
			local tint = (column + row) % 2 == 0 and light or dark
			local tile = part(side, "Checker_" .. column .. "_" .. row,
				Vector3.new(width, tileSize, 0.04),
				faceCF * CFrame.new(start + width / 2, row * tileSize + tileSize / 2, 0), tint, false)
			texture(tile, Enum.NormalId.Front, tint)
			tiles += 1
		end
		task.wait()
	end
end
game:GetService("ChangeHistoryService"):SetWaypoint("Enclose shared camp with four studded checker walls")
return {sides = #walls:GetChildren(), checkerTiles = tiles, height = height, thickness = thickness}
