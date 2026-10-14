-- One-time Edit authoring: reuse one unused imported egg design for a guarded Rare.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before editing egg templates")
local ServerStorage = game:GetService("ServerStorage")
local models = ServerStorage:WaitForChild("EggModels")
assert(not models:FindFirstChild("RareEgg"), "Rare art already exists; edit it directly")
local spare = assert(models.UnusedEggPack:FindFirstChildWhichIsA("BasePart"), "No spare egg design")
local rare = spare:Clone()
rare.Name = "RareEgg"
for _, child in ipairs(rare:GetDescendants()) do
	if child:IsA("LuaSourceContainer") or child:IsA("ProximityPrompt") then
		child:Destroy()
	end
end
rare:SetAttribute("Source", "Unused imported egg pack; original preserved")
rare.Parent = models
local meadow = workspace.Map.Meadow
local spots = Instance.new("Folder")
spots.Name = "RareEgg"
spots.Parent = meadow.EggSpawns
-- Rear half of the existing bird island, separated from the Uncommon spots.
for index, position in ipairs({
	Vector3.new(180, 155, -2208), Vector3.new(160, 155, -2208),
	Vector3.new(200, 155, -2206), Vector3.new(185, 155, -2223),
}) do
	local marker = Instance.new("Part")
	marker.Name = "Spot" .. index
	marker.Size = Vector3.new(0.2, 0.2, 0.2)
	local hit = workspace:Raycast(position + Vector3.new(0, 45, 0), Vector3.new(0, -80, 0))
	assert(hit and hit.Instance:IsDescendantOf(meadow), "Rare marker must be above island terrain")
	marker.CFrame = CFrame.new(position.X, hit.Position.Y, position.Z)
	marker.Anchored = true
	marker.Transparency = 1
	marker.CanCollide, marker.CanTouch, marker.CanQuery = false, false, false
	marker.Parent = spots
end
game:GetService("ChangeHistoryService"):SetWaypoint("Rare egg art and guarded pickup markers")
return {art = rare:GetFullName(), spots = #spots:GetChildren()}
