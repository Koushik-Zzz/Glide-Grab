-- Edit-only ground styling. Preserve imported geometry and all collision settings.
local backups = game:GetService("ServerStorage").ImportedAssetBackups
local source = backups:WaitForChild("ResolvedClassicStudTexture")
assert(source:IsA("Decal"), "Stud texture source missing")
local targets = {workspace.HomeIsland, workspace.Map.Meadow.MeadowEntrance}
for _, island in ipairs(workspace.Map.Meadow:GetChildren()) do
	local terrain = island:FindFirstChild("TerrainGeometry")
	if terrain then
		for _, part in ipairs(terrain:GetDescendants()) do
			if part:IsA("BasePart") and part.Color.G > part.Color.R * 1.2
				and part.Color.G > part.Color.B * 1.2 then
				table.insert(targets, part)
			end
		end
	end
end
for _, part in ipairs(targets) do
	if part:GetAttribute("GroundOriginalMaterial") == nil then
		part:SetAttribute("GroundOriginalMaterial", part.Material.Name)
		part:SetAttribute("GroundOriginalVariant", part.MaterialVariant)
		part:SetAttribute("GroundOriginalTopSurface", part.TopSurface.Name)
	end
	part.Material = Enum.Material.Plastic
	part.MaterialVariant = ""
	part.TopSurface = Enum.SurfaceType.Smooth
	local texture = part:FindFirstChild("StuddedGround") or Instance.new("Texture")
	texture.Name = "StuddedGround"
	texture.Texture = source.Texture
	texture.Face = Enum.NormalId.Top
	texture.StudsPerTileU = 4
	texture.StudsPerTileV = 4
	texture.Color3 = part.Color
	texture.Transparency = 0.12
	texture.Parent = part
end
game:GetService("ChangeHistoryService"):SetWaypoint("Apply classic studded ground")
return "Studded top textures applied to " .. #targets .. " camp/Meadow ground surfaces."
