-- One-time Edit authoring. Imported Lua/physics are never used for combat.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before authoring gear")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local backups = ServerStorage:WaitForChild("ImportedAssetBackups")
assert(not workspace:FindFirstChild("SkyGearShop"), "Gear shop already exists")
local assets = Instance.new("Folder")
assets.Name = "CombatAssets"
assets.Parent = ReplicatedStorage
for _, entry in ipairs({
	{Name = "Bat", Source = "Baseball Bat source", Id = 13233709250, Height = 3.5},
	{Name = "Slap", Source = "Slap Hand source", Id = 115624435463813, Height = 2.2},
}) do
	local source = assert(ServerStorage:FindFirstChild(entry.Source), "Import " .. entry.Source)
	local model = Instance.new("Model")
	model.Name = entry.Name
	local primary
	for _, original in ipairs(source:GetDescendants()) do
		if original:IsA("BasePart") and original.Transparency < 0.99 then
			local part = original:Clone()
			for _, child in ipairs(part:GetDescendants()) do
				if not (child:IsA("DataModelMesh") or child:IsA("Texture") or child:IsA("Decal") or child:IsA("SurfaceAppearance")) then
					child:Destroy()
				end
			end
			part.Anchored = true
			part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
			part.Massless = true
			part.Parent = model
			if not primary or part.Name == "Handle" then
				primary = part
			end
		end
	end
	assert(primary, "Imported model has no visible geometry")
	model.PrimaryPart = primary
	model:PivotTo(CFrame.new())
	local _, size = model:GetBoundingBox()
	model:ScaleTo(entry.Height / math.max(size.X, size.Y, size.Z))
	model:SetAttribute("SourceAssetId", entry.Id)
	model.Parent = assets
	source.Parent = backups
end

local shop = Instance.new("Model")
shop.Name = "SkyGearShop"
shop.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
shop.Parent = workspace
local home = workspace.HomeIsland
local rootCF = home.CFrame * CFrame.new(0, home.Size.Y / 2, 0)
local function part(parent, name, size, cf, color)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material = Enum.Material.Plastic
	p.Anchored = true
	p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
	p.Parent = parent
	return p
end
for _, entry in ipairs({
	{Name = "Bat", X = -20, Color = Color3.fromRGB(255, 211, 106), Title = "BAT • 5,000 COINS\nR to swing — glider stays equipped"},
	{Name = "Shield", X = 20, Color = Color3.fromRGB(119, 217, 239), Title = "EGG SHIELDS • 3,000 EACH\nG to protect your egg for 12 seconds"},
}) do
	local cf = rootCF * CFrame.new(entry.X, 2.5, -126)
	local counter = part(shop, entry.Name .. "Counter", Vector3.new(10, 4, 5), cf, entry.Color)
	part(shop, entry.Name .. "Top", Vector3.new(11, 0.3, 6), cf * CFrame.new(0, 2.1, 0), Color3.fromRGB(249, 244, 214))
	local sign = Instance.new("BillboardGui")
	sign.Name = "ShopSign"
	sign.Size = UDim2.fromOffset(270, 60)
	sign.StudsOffset = Vector3.new(0, 6, 0)
	sign.MaxDistance = 70
	sign.Parent = counter
	local text = Instance.new("TextLabel")
	text.Name = "Title"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextSize = 17
	text.TextColor3 = entry.Color
	text.TextStrokeTransparency = 0.15
	text.Text = entry.Title
	text.Parent = sign
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PurchasePrompt"
	prompt.ActionText = entry.Name == "Bat" and "Buy bat — 5,000 coins" or "Buy shield — 3,000 coins"
	prompt.ObjectText = "Shared sky gear shop"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter
	if entry.Name == "Bat" then
		local display = assets.Bat:Clone()
		display.Name = "BatDisplay"
		display:PivotTo(cf * CFrame.new(0, 4, 0) * CFrame.Angles(math.rad(-20), 0, math.rad(35)))
		display.Parent = shop
	else
		local orb = part(shop, "ShieldDisplay", Vector3.new(3, 3, 3), cf * CFrame.new(0, 4, 0), entry.Color)
		orb.Shape = Enum.PartType.Ball
		orb.Material = Enum.Material.Neon
		orb.Transparency = 0.45
	end
end
game:GetService("ChangeHistoryService"):SetWaypoint("Public bat and egg shield shop with sanitized marketplace art")
return {shop = shop:GetFullName(), models = #assets:GetChildren()}
