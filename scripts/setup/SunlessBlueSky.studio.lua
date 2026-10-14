-- Edit-mode sky styling. Lighting is authored in the saved place, outside Rojo.
-- Import Creator Store asset 591067775 into ServerStorage before first use.
local RunService = game:GetService("RunService")
assert(not RunService:IsRunning(), "Stop Play before changing the saved sky")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local name = "Sunless Blue Sky Skybox"
local sky = ServerStorage:FindFirstChild(name) or Lighting:FindFirstChild(name)
assert(sky and sky:IsA("Sky"), "Import Sunless Blue Sky Skybox (591067775) first")
for _, face in ipairs({"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}) do
	assert(sky[face] ~= "", "Missing skybox face: " .. face)
end
local backups = ServerStorage:WaitForChild("ImportedAssetBackups")
local saved = backups:FindFirstChild("BeforeSunlessBlueSky")
if not saved then
	saved = Instance.new("Folder")
	saved.Name = "BeforeSunlessBlueSky"
	saved.Parent = backups
end
for _, old in ipairs(Lighting:GetChildren()) do
	if old:IsA("Sky") and old ~= sky then
		old.Parent = saved
	end
end
-- The supplied asset leaves celestial bodies enabled; hide the rendered sun/moon.
sky.CelestialBodiesShown = false
sky:SetAttribute("SourceAssetId", 591067775)
for _, tag in ipairs(game:GetService("CollectionService"):GetTags(sky)) do
	if string.sub(tag, 1, 10) == "Assistant:" then
		game:GetService("CollectionService"):RemoveTag(sky, tag)
	end
end
sky.Parent = Lighting
game:GetService("ChangeHistoryService"):SetWaypoint("Sunless blue sky for camp and Meadow")
return {sky = sky:GetFullName(), sharedByCampAndMeadow = true, previousSky = saved:GetFullName()}
