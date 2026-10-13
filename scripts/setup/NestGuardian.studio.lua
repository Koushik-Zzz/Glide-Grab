-- One-time Edit-mode scene setup. Not mapped by Rojo; preserves existing art.
local meadow = workspace.Map.Meadow
assert(not meadow:FindFirstChild("NestGuardian"), "Guardian already exists; do not rerun setup")
local home = meadow.MeadowIsland02:GetAttribute("GroundTop") + Vector3.new(0, 38, 0)
local bird = Instance.new("Model")
bird.Name = "NestGuardian"
bird:SetAttribute("HomePosition", home)
bird:SetAttribute("State", "Patrol")
local function part(name, size, offset, color, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Shape = shape or Enum.PartType.Block
	p.CFrame = CFrame.new(home + offset)
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Parent = bird
	return p
end
local body = part("Body", Vector3.new(6, 5, 7), Vector3.zero, Color3.fromRGB(192, 113, 50), Enum.PartType.Ball)
bird.PrimaryPart = body
part("Breast", Vector3.new(4.5, 3.8, 2), Vector3.new(0, -0.3, -3), Color3.fromRGB(255, 221, 140), Enum.PartType.Ball)
part("Head", Vector3.new(4.5, 4.3, 4.5), Vector3.new(0, 2, -3), Color3.fromRGB(209, 135, 61), Enum.PartType.Ball)
part("Beak", Vector3.new(1.8, 1.3, 2.5), Vector3.new(0, 1.5, -5.5), Color3.fromRGB(255, 187, 52), Enum.PartType.Ball)
for _, side in ipairs({-1, 1}) do
	part(side == -1 and "LeftWing" or "RightWing", Vector3.new(9, 0.9, 3.8), Vector3.new(side * 6, 0.5, 0), Color3.fromRGB(134, 77, 38))
	part("EyeWhite", Vector3.new(1.65, 1.8, 0.8), Vector3.new(side * 1.15, 2.6, -4.8), Color3.fromRGB(255, 250, 227), Enum.PartType.Ball)
	part("Pupil", Vector3.new(0.7, 0.85, 0.5), Vector3.new(side * 1.15, 2.6, -5.22), Color3.fromRGB(37, 39, 44), Enum.PartType.Ball)
end
part("Tail", Vector3.new(4, 0.8, 4), Vector3.new(0, 0.2, 4), Color3.fromRGB(134, 77, 38))
local sign = Instance.new("BillboardGui")
sign.Name = "GuardianSign"
sign.Size = UDim2.fromOffset(240, 55)
sign.StudsOffset = Vector3.new(0, 7, 0)
sign.MaxDistance = 170
sign.AlwaysOnTop = false
sign.Parent = body
local text = Instance.new("TextLabel")
text.Name = "Status"
text.Size = UDim2.fromScale(1, 1)
text.BackgroundTransparency = 1
text.Font = Enum.Font.GothamBold
text.TextSize = 18
text.TextColor3 = Color3.fromRGB(255, 231, 168)
text.TextStrokeTransparency = 0.15
text.Text = "NEST GUARDIAN\nTake the egg... then fly!"
text.Parent = sign
bird.Parent = meadow
local wind = meadow.WindGust
wind:SetAttribute("WindVelocity", Vector3.new(64, 0, 0))
wind:SetAttribute("CalmSeconds", 5)
wind:SetAttribute("WarningSeconds", 1.5)
wind:SetAttribute("GustSeconds", 2.4)
return "Authored NestGuardian; wind tuned to 64 studs/s, 2.4-second bursts."
