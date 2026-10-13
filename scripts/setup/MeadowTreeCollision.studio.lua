-- Edit-mode scenery update. Not mapped by Rojo. Safe to rerun on these islands.
-- Imported tree parts retain their original settings as attributes for restoration.
local meadow = workspace.Map.Meadow
local trees, parts = 0, 0
for _, islandName in ipairs({"MeadowEntranceIsland", "MeadowIsland01", "MeadowIsland02"}) do
	local island = meadow:FindFirstChild(islandName)
	assert(island and island:IsA("Model"), "Missing Meadow island: " .. islandName)
	for _, model in ipairs(island:GetChildren()) do
		if not model:IsA("Model") or model.Name == "TerrainGeometry" then continue end
		local name = string.lower(model.Name)
		local isTree = string.find(name, "tree", 1, true) or string.find(name, "palm", 1, true)
		local descendants = model:GetDescendants()
		for _, part in ipairs(descendants) do
			if part:IsA("BasePart") and string.match(string.lower(part.Name), "^trunk") then
				isTree = true
				break
			end
		end
		if not isTree then continue end
		model:SetAttribute("PassThroughScenery", true)
		trees += 1
		for _, part in ipairs(descendants) do
			if not part:IsA("BasePart") then continue end
			for _, property in ipairs({"CanCollide", "CanTouch", "CanQuery"}) do
				local originalName = "OriginalTree" .. property
				if part:GetAttribute(originalName) == nil then
					part:SetAttribute(originalName, part[property])
				end
				part[property] = false
			end
			parts += 1
		end
	end
end
meadow.NestGuardian:SetAttribute("EncounterSeconds", nil)
game:GetService("ChangeHistoryService"):SetWaypoint("Pass-through Meadow trees")
return {Trees = trees, TreeParts = parts}
