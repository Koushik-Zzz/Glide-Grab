-- One-time Edit authoring: inspectable locked decks, public rebirth station,
-- and a three-island Storm Isles route using the project's existing art.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play first")
local W, S = workspace, game.ServerStorage
assert(not W.Map:FindFirstChild("StormIsles"), "First rebirth scene already authored")
local function part(parent, name, size, cf, color, collide)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Anchored, p.CanCollide, p.CanTouch = true, collide == true, false
	p.Material = Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end
local texture = S.ImportedAssetBackups.ResolvedClassicStudTexture.Texture
local function stud(p)
	local t = Instance.new("Texture")
	t.Texture, t.Face = texture, Enum.NormalId.Top
	t.StudsPerTileU, t.StudsPerTileV = 4, 4
	t.Color3, t.Transparency = p.Color, 0.12
	t.Parent = p
end
local function hide(group)
	for _, o in ipairs(group:GetDescendants()) do
		if o:IsA("BasePart") then
			o:SetAttribute("UnlockedTransparency", o.Transparency)
			o:SetAttribute("UnlockedCollision", o.CanCollide)
			o.Transparency, o.CanCollide = 1, false
		elseif o:IsA("Texture") then
			o:SetAttribute("UnlockedTransparency", o.Transparency)
			o.Transparency = 1
		end
	end
end
for _, plot in ipairs(W.CampPlots:GetChildren()) do
	local upper = Instance.new("Model")
	upper.Name = "UpperFloor"
	upper.Parent = plot
	local cf = plot:GetPivot()
	for x = 0, 5 do
		for z = 0, 1 do
			local tile = part(upper, "DeckTile", Vector3.new(12, 1, 12),
				cf * CFrame.new(-30 + x * 12, 17.5, 22 + z * 12),
				(x + z) % 2 == 0 and Color3.fromRGB(137, 207, 80) or Color3.fromRGB(104, 182, 65), true)
			stud(tile)
		end
	end
	for step = 1, 18 do
		local stair = part(upper, "Stair" .. step, Vector3.new(6, 1, 2),
			cf * CFrame.new(32, step - 0.5, -19 + step * 2), Color3.fromRGB(166, 112, 61), true)
		stud(stair)
	end
	for _, edge in ipairs({{0, 40, 72, 1}, {-36, 28, 1, 24}, {36, 28, 1, 24}, {-6, 16, 60, 1}}) do
		for _, height in ipairs({20, 22}) do
			part(upper, "Rail", Vector3.new(edge[3], 0.7, edge[4]),
				cf * CFrame.new(edge[1], height, edge[2]), Color3.fromRGB(137, 87, 42), true)
		end
	end
	for index = 1, 6 do
		local slot = plot.Slots["Slot" .. index]:Clone()
		slot.Name = "Slot" .. (index + 6)
		slot:SetAttribute("SlotIndex", index + 6)
		slot:PivotTo(CFrame.new(0, 18, 0) * slot:GetPivot())
		slot.Parent = plot.Slots
		hide(slot)
	end
	hide(upper)
	task.wait()
end
local station = Instance.new("Model")
station.Name, station.Parent = "RebirthStation", W
local counter = part(station, "Counter", Vector3.new(9, 3, 5), CFrame.new(0, 105.5, 116), Color3.fromRGB(237, 186, 62), true)
local prompt = Instance.new("ProximityPrompt")
prompt.Name, prompt.ActionText, prompt.ObjectText = "RebirthPrompt", "View rebirth", "250,000 coins • Storm Isles + 12 pillows"
prompt.HoldDuration, prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 0.5, 12, false
prompt.Parent = counter
local sign = Instance.new("BillboardGui")
sign.Name, sign.Size, sign.StudsOffset = "RebirthSign", UDim2.fromOffset(280, 64), Vector3.new(0, 6, 0)
sign.MaxDistance, sign.Parent = 80, counter
local title = Instance.new("TextLabel")
title.Size, title.BackgroundTransparency = UDim2.fromScale(1, 1), 1
title.Font, title.TextSize = Enum.Font.GothamBold, 18
title.TextColor3, title.TextStrokeTransparency = Color3.fromRGB(255, 220, 110), 0.2
title.Text, title.Parent = "FIRST REBIRTH\nStorm Isles + upstairs storage", sign
local storm = Instance.new("Folder")
storm.Name, storm.Parent = "StormIsles", W.Map
local centers = {Vector3.new(2400, 140, -1700), Vector3.new(2400, 165, -1920), Vector3.new(2540, 195, -2130)}
for i, top in ipairs(centers) do
	local island = W.Map.Meadow.MeadowIsland01:Clone()
	island.Name = "StormIsland" .. i
	local routeSign = island:FindFirstChild("RouteSign")
	if routeSign then routeSign:Destroy() end
	local ground = island.TerrainGeometry
	local oldCF, oldSize = ground:GetBoundingBox()
	local offset = top - (oldCF.Position + Vector3.new(0, oldSize.Y / 2, 0))
	island:PivotTo(CFrame.new(offset) * island:GetPivot())
	island:SetAttribute("GroundTop", top)
	for _, p in ipairs(island:GetDescendants()) do
		if p:IsA("BasePart") and p.Color.G > p.Color.R * 1.1 then
			p.Color = p.Color:Lerp(Color3.fromRGB(70, 163, 180), 0.5)
		end
	end
	island.Parent = storm
	task.wait()
end
local landing = part(storm, "StormEntrance", Vector3.new(50, 1, 50), CFrame.new(centers[1] + Vector3.new(0, 0.5, 0)), Color3.fromRGB(125, 182, 195), true)
stud(landing)
local marker = part(storm, "StormEggIsland", Vector3.one, CFrame.new(centers[3] - Vector3.new(0, 0.5, 0)), Color3.new(), false)
marker.Transparency = 1
local zone = W.Map.Meadow.WindGust:Clone()
zone.Name, zone.CFrame, zone.Size = "WindGust", CFrame.new(2460, 196, -2015), Vector3.new(230, 150, 200)
zone:SetAttribute("WindVelocity", Vector3.new(-80, 0, 0))
zone:SetAttribute("CalmSeconds", 2)
zone:SetAttribute("WarningSeconds", 1.2)
zone:SetAttribute("GustSeconds", 4)
zone.Parent = storm
local anchor = part(W.SharedCamp.Anchors, "StormPortal", Vector3.one, CFrame.new(64, 110, -146), Color3.new(), false)
anchor.Transparency = 1
anchor:SetAttribute("RequiredRebirths", 1)
local egg = S.EggModels.RareEgg:Clone()
egg.Name = "StormEgg"
for _, p in ipairs(egg:GetDescendants()) do
	if p:IsA("BasePart") then p.Color = Color3.fromRGB(190, 137, 244) end
end
egg.Parent = S.EggModels
return "First rebirth scene ready: six locked upper decks and Storm Isles. Save the place."
