-- One-time Edit-mode setup. Rojo does not run this file.
local meadow = workspace.Map.Meadow
assert(not meadow:FindFirstChild("EggSpawns") and not meadow:FindFirstChild("WindGust"), "Meadow fun assets already exist")
local backup = game.StarterPack.Glider.LocalScript:Clone()
backup.Name = "GliderClientBeforeWind"
backup.Parent = game.ServerStorage.ImportedAssetBackups
local spawns = Instance.new("Folder")
spawns.Name = "EggSpawns"
spawns.Parent = meadow
local counts = {}
for _,entry in ipairs({{"CommonEgg","MeadowIsland01"},{"UncommonEgg","MeadowIsland02"}}) do
 local model = meadow[entry[2]]
 local center = model:GetAttribute("GroundTop")
 local rays = RaycastParams.new()
 rays.FilterType = Enum.RaycastFilterType.Include
 rays.FilterDescendantsInstances = {model.TerrainGeometry}
 local overlaps = OverlapParams.new()
 overlaps.FilterType = Enum.RaycastFilterType.Include
 overlaps.FilterDescendantsInstances = {model}
 local folder = Instance.new("Folder")
 folder.Name = entry[1]
 folder.Parent = spawns
 local accepted = {}
 for _,xy in ipairs({{-18,-12},{18,10},{-12,20},{15,-20},{-26,8},{0,0},{0,-28},{26,-8},{8,28},{-22,-24}}) do
  local hit = workspace:Raycast(center+Vector3.new(xy[1],60,xy[2]),Vector3.new(0,-120,0),rays)
  local clear = hit ~= nil
  if hit then
   for _,part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(hit.Position+Vector3.new(0,4,0)),Vector3.new(8,6,8),overlaps)) do
    if part.CanCollide then clear = false end
   end
   for _,pos in ipairs(accepted) do if (pos-hit.Position).Magnitude < 15 then clear = false end end
  end
  if clear and #accepted < 4 then
   table.insert(accepted,hit.Position)
   local marker=Instance.new("Part")
   marker.Name="Spot"..#accepted
   marker.Size=Vector3.new(1,1,1)
   marker.CFrame=CFrame.new(hit.Position)
   marker.Anchored=true
   marker.Transparency=1
   marker.CanCollide=false
   marker.CanTouch=false
   marker.CanQuery=false
   marker.Parent=folder
  end
 end
 assert(#accepted>=3,"Need at least three clear spots for "..entry[1])
 counts[entry[1]]=#accepted
end
local zone=Instance.new("Part")
zone.Name="WindGust"
zone.Size=Vector3.new(140,90,115)
zone.CFrame=CFrame.new(90,162,-2060)
zone.Transparency=1
zone.Anchored=true
zone.CanCollide=false
zone.CanTouch=false
zone.CanQuery=false
zone:SetAttribute("CalmSeconds",6)
zone:SetAttribute("WarningSeconds",2.5)
zone:SetAttribute("GustSeconds",4)
zone:SetAttribute("WindVelocity",Vector3.new(28,0,0))
zone:SetAttribute("Phase","Calm")
zone.Parent=meadow
local art=Instance.new("Folder")
art.Name="WindMarkers"
art.Parent=meadow
-- A few open guide rails mark a volume players can fly around, above, or below.
for i,delta in ipairs({Vector3.new(-70,0,0),Vector3.new(70,0,0)}) do
 local post=Instance.new("Part")
 post.Name="Edge"..i
 post.Size=Vector3.new(0.6,90,0.6)
 post.CFrame=zone.CFrame*CFrame.new(delta)
 post.Anchored=true
 post.CanCollide=false
 post.CanTouch=false
 post.CanQuery=false
 post.Material=Enum.Material.Neon
 post.Color=Color3.fromRGB(158,223,184)
 post.Transparency=0.55
 post.Parent=art
end
local gui=Instance.new("BillboardGui")
gui.Name="WindSign"
gui.Size=UDim2.fromOffset(280,64)
gui.StudsOffset=Vector3.new(0,50,0)
gui.MaxDistance=400
gui.AlwaysOnTop=false
gui.Parent=zone
local label=Instance.new("TextLabel")
label.Name="Status"
label.Size=UDim2.fromScale(1,1)
label.BackgroundTransparency=1
label.Font=Enum.Font.GothamBold
label.TextSize=21
label.TextColor3=Color3.fromRGB(221,255,240)
label.TextStrokeTransparency=0.35
label.Text="CROSSWIND\nWait for calm or fly around"
label.Parent=gui
game:GetService("ChangeHistoryService"):SetWaypoint("Meadow wind and egg spawn spots")
return counts
