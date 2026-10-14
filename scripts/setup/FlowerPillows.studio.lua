-- One-time Edit-mode foundation for egg displays. Does not change cash-out gameplay.
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local home = Workspace:WaitForChild("HomeIsland")
assert(not Workspace:FindFirstChild("CampEggDisplays"), "Display layout already exists; edit it directly")
local source = ServerStorage:WaitForChild("FlowerPillowSource")
local backup = ServerStorage:WaitForChild("ImportedAssetBackups")
source.Parent = backup
local templates = ServerStorage:FindFirstChild("DisplayModels") or Instance.new("Folder")
templates.Name = "DisplayModels"
templates.Parent = ServerStorage
local template = source:Clone()
template.Name = "FlowerPillow"
local petalIndex = 0
for _, child in ipairs(template:GetDescendants()) do
	if child:IsA("LuaSourceContainer") or child:IsA("ProximityPrompt")
		or child:IsA("Constraint") or child:IsA("JointInstance") then
		child:Destroy()
	elseif child:IsA("BasePart") then
		local isPetal = child.Name == "Egg"
		if isPetal then
			petalIndex += 1
			child.Name = "Petal" .. petalIndex
		else
			child.Name = "Center"
		end
		child:SetAttribute("PillowTint", isPetal)
		child.Anchored = true
		child.CanCollide = false
		child.CanTouch = false
		child.CanQuery = false
	end
end
assert(petalIndex == 6, "Inspect the template before using a different pillow model")
local _, originalSize = template:GetBoundingBox()
template:ScaleTo(template:GetScale() * 7 / math.max(originalSize.X, originalSize.Z))
local bounds = template:GetBoundingBox()
template:PivotTo(CFrame.new() * template:GetPivot():ToObjectSpace(bounds):Inverse())
template:SetAttribute("SourceAssetId", "15490887339")
template.Parent = templates
local displays = Instance.new("Model")
displays.Name = "CampEggDisplays"
displays.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
local slots = Instance.new("Folder")
slots.Name = "Slots"
slots.Parent = displays
local top = home.Size.Y / 2
for index = 1, 6 do
	local slot = Instance.new("Model")
	slot.Name = "Slot" .. index
	slot:SetAttribute("SlotIndex", index)
	local root = Instance.new("Part")
	root.Name = "SlotRoot"
	root.Size = Vector3.new(8, 0.2, 8)
	root.CFrame = home.CFrame * CFrame.new(-30 + (index - 1) * 12, top + 0.15, 32)
	root.Anchored = true
	root.Transparency = 1
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.Parent = slot
	slot.PrimaryPart = root
	local pillow = template:Clone()
	pillow.Name = "Pillow"
	local pillowBounds, pillowSize = pillow:GetBoundingBox()
	local center = root.CFrame * CFrame.new(0, pillowSize.Y / 2 + 0.05, 0)
	pillow:PivotTo(center * pillow:GetPivot():ToObjectSpace(pillowBounds):Inverse())
	pillow.Parent = slot
	local anchor = Instance.new("Attachment")
	anchor.Name = "EggAnchor"
	anchor.Position = Vector3.new(0, pillowSize.Y + 0.2, 0)
	anchor.Parent = root
	slot.Parent = slots
end
displays.Parent = Workspace
game:GetService("ChangeHistoryService"):SetWaypoint("Add six Flower Pillow display spots")
return {template = template:GetFullName(),slots = #slots:GetChildren(),petalsPerPillow = petalIndex}
