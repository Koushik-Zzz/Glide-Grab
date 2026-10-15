-- One-time Edit migration after inserting asset 120133129723048 under
-- ServerStorage/SlapGloveImport. Art only; the imported R6 combat code is unused.
local RunService = game:GetService("RunService")
assert(not RunService:IsRunning(), "Stop Play before replacing the slap model")
local storage = game:GetService("ServerStorage")
local assets = game:GetService("ReplicatedStorage"):WaitForChild("CombatAssets")
local imported = storage:WaitForChild("SlapGloveImport")
local tool = imported:FindFirstChildWhichIsA("Tool", true)
assert(tool and tool:FindFirstChild("Handle") and tool:FindFirstChild("stick"), "Unexpected glove structure")
local model = Instance.new("Model")
model.Name = "Slap"
model:SetAttribute("SourceAssetId", 120133129723048)
local handle = tool.Handle:Clone()
local stick = tool.stick:Clone()
-- Keep only the two visible pieces and the stick's primitive mesh.
handle:ClearAllChildren()
for _, child in ipairs(stick:GetChildren()) do
	if not child:IsA("SpecialMesh") then
		child:Destroy()
	end
end
handle.Parent, stick.Parent = model, model
model.PrimaryPart = handle
local grip = Instance.new("Attachment")
grip.Name = "GripPoint"
-- Preserve the source handle position, turning the palm upright in our left hand.
grip.CFrame = CFrame.new(tool.Grip.Position) * CFrame.Angles(math.pi / 2, 0, 0)
grip.Parent = handle
model:ScaleTo(0.65)
model:PivotTo(CFrame.identity)
for _, part in ipairs({handle, stick}) do
	part.Anchored, part.Massless = true, true
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
end
local old = assets:FindFirstChild("Slap")
if old then
	local backups = storage:WaitForChild("ImportedAssetBackups")
	old.Name = "SlapBeforeHeldGlove"
	old.Parent = backups
end
model.Parent = assets
-- Raw scripts, remotes, borrowed animations, sounds and hitboxes never enter play.
imported:Destroy()
return {model = model:GetFullName(), parts = 2, grip = tostring(grip.CFrame.Position)}
