-- One-time Edit setup. The imported NPC stays unchanged in ServerStorage.
local ServerStorage = game:GetService("ServerStorage")
local backups = ServerStorage:WaitForChild("ImportedAssetBackups")
local source = backups:WaitForChild("OpilaBirdSource")
local art = source:FindFirstChild("Opila Bird", true)
local bird = workspace.Map.Meadow.NestGuardian
assert(art and art:IsA("Model"), "Opila source visual model missing")
assert(not bird:FindFirstChild("Visual"), "Guardian art already replaced")
assert(not backups:FindFirstChild("PrimitiveGuardianBeforeOpila"), "Guardian backup already exists")

local backup = bird:Clone()
backup.Name = "PrimitiveGuardianBeforeOpila"
backup.Parent = backups
local visual = art:Clone()
visual.Name = "Visual"
for _, child in ipairs(visual:GetDescendants()) do
	if child:IsA("LuaSourceContainer") or child:IsA("JointInstance")
		or child:IsA("Constraint") or child:IsA("WeldConstraint")
		or child:IsA("Humanoid") or child:IsA("ProximityPrompt") then
		child:Destroy()
	elseif child:IsA("BasePart") then
		child.Anchored = true
		child.CanCollide = false
		child.CanTouch = false
		child.CanQuery = false
	end
end
local visibleBody = assert(visual:FindFirstChild("Body"), "Opila mesh body missing")
local _, size = visual:GetBoundingBox()
visual:ScaleTo(visual:GetScale() * 10 / size.Y)
visual.PrimaryPart = visibleBody
visual:PivotTo(bird.Body.CFrame)

-- Keep our root/sign and difficulty attributes, replacing only the primitive art.
for _, child in ipairs(bird:GetChildren()) do
	if child:IsA("BasePart") and child ~= bird.Body then
		child:Destroy()
	end
end
bird.Body.Transparency = 1
bird.Body.CanCollide = false
bird.Body.CanTouch = false
bird.Body.CanQuery = false
bird.PrimaryPart = bird.Body
visual.Parent = bird
bird:SetAttribute("VisualAssetId", "14135165934")

local legs = {}
for _, part in ipairs(visual:GetDescendants()) do
	if part:IsA("BasePart") then
		if part.Name == "LeftWing" or part.Name == "RightWing" then
			local x = bird.Body.CFrame:PointToObjectSpace(part.Position).X
			local side = x < 0 and -1 or 1
			part.Name = side == -1 and "LeftWing" or "RightWing"
			part:SetAttribute("WingSide", side)
			local hinge = Instance.new("Attachment")
			hinge.Name = "WingHinge"
			hinge.CFrame = CFrame.new(-side * part.Size.X * 0.35, part.Size.Y * 0.4, 0)
			hinge.Parent = part
			local rest = bird.Body.CFrame:ToObjectSpace(part.CFrame * hinge.CFrame)
			part:SetAttribute("WingRestHinge", rest)
			part.CFrame = bird.Body.CFrame * rest * CFrame.Angles(0, 0, side * 0.95) * hinge.CFrame:Inverse()
		elseif part.Name == "Meshes/kekleg1" then
			table.insert(legs, part)
		end
	end
end
table.sort(legs, function(a, b)
	return a.Position.X < b.Position.X
end)
for index, leg in ipairs(legs) do
	leg.Name = index == 1 and "LeftLeg" or "RightLeg"
end
local flash = Instance.new("Highlight")
flash.Name = "AttackFlash"
flash.Adornee = visual
flash.FillColor = Color3.fromRGB(255, 185, 65)
flash.FillTransparency = 0.45
flash.OutlineTransparency = 1
flash.DepthMode = Enum.HighlightDepthMode.Occluded
flash.Enabled = false
flash.Parent = visual
game:GetService("ChangeHistoryService"):SetWaypoint("Replace guardian art with Opila bird")
return "Guardian replaced with cleaned Opila visual, animated shoulder hinges and attack flash."
