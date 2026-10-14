local Visuals = {}

function Visuals.create(cargo, anchor, definition, economy, ownerId)
	local egg = assert(cargo:Clone(), "Carried egg must be Archivable")
	egg.Name = "DisplayedEgg"
	-- Remove cargo welds to the character; freeze every part at the display.
	for _, child in ipairs(egg:GetDescendants()) do
		if child:IsA("LuaSourceContainer") or child:IsA("JointInstance")
			or child:IsA("Constraint") or child:IsA("WeldConstraint")
			or child:IsA("ProximityPrompt") or child:IsA("BillboardGui") or child:IsA("Highlight") then
			child:Destroy()
		end
	end
	local parts = egg:GetDescendants()
	if egg:IsA("BasePart") then
		table.insert(parts, egg)
	end
	for _, part in ipairs(parts) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
	local bounds, size
	if egg:IsA("Model") then
		bounds, size = egg:GetBoundingBox()
	else
		bounds, size = egg.CFrame, egg.Size
	end
	local pivotToBounds = egg:GetPivot():ToObjectSpace(bounds)
	egg:PivotTo(anchor.WorldCFrame * CFrame.new(0, size.Y / 2, 0) * pivotToBounds:Inverse())
	egg:SetAttribute("EggName", definition.Name)
	egg:SetAttribute("TemplateId", definition.Template)
	egg:SetAttribute("Rarity", economy.Rarity)
	egg:SetAttribute("IncomeRate", economy.Income)
	egg:SetAttribute("EggTier", economy.Tier)
	egg:SetAttribute("EggScale", economy.Scale)
	egg:SetAttribute("EggId", economy.EggId)
	egg:SetAttribute("OwnerUserId", ownerId)
	return egg
end

function Visuals.label(root, name)
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Size = UDim2.fromOffset(200, 48)
	gui.StudsOffset = Vector3.new(0, 6.5, 0)
	gui.MaxDistance = 32
	gui.AlwaysOnTop = false
	local text = Instance.new("TextLabel")
	text.Name = "Caption"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 252, 237)
	text.TextStrokeTransparency = 0.2
	text.Font = Enum.Font.GothamBold
	text.TextSize = 14
	text.Parent = gui
	gui.Parent = root
	return text
end

return Visuals
