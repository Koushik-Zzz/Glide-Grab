-- Rarity presentation for authored display slots. Does not grant or consume eggs.
local Workspace = game:GetService("Workspace")
local Appearance = require(script.Parent:WaitForChild("CollectionModules"):WaitForChild("PillowAppearance"))
local plots = Workspace:WaitForChild("CampPlots")
local records = {}
local eggNames = { ["Common Egg"] = "Common", ["Uncommon Egg"] = "Uncommon" }

local function bind(slot)
	if not slot:IsA("Model") or records[slot] then return end
	local connections, eggConnections = {}, {}
	records[slot] = connections
	local function clearEggConnections()
		for _, connection in ipairs(eggConnections) do
			connection:Disconnect()
		end
		eggConnections = {}
	end
	local function refresh()
		local pillow = slot:FindFirstChild("Pillow")
		if not pillow then return end
		local egg = slot:FindFirstChild("DisplayedEgg")
		local rarity = slot:GetAttribute("EggRarity")
		if egg then
			rarity = egg:GetAttribute("Rarity") or eggNames[egg:GetAttribute("EggName")] or rarity
		end
		Appearance.apply(pillow, rarity or "Empty")
	end
	local function watchEgg()
		clearEggConnections()
		local egg = slot:FindFirstChild("DisplayedEgg")
		if egg then
			for _, attribute in ipairs({"Rarity", "EggName"}) do
				table.insert(eggConnections, egg:GetAttributeChangedSignal(attribute):Connect(refresh))
			end
		end
		refresh()
	end
	table.insert(connections, slot:GetAttributeChangedSignal("EggRarity"):Connect(refresh))
	table.insert(connections, slot.ChildAdded:Connect(watchEgg))
	table.insert(connections, slot.ChildRemoved:Connect(watchEgg))
	table.insert(connections, slot.Destroying:Connect(function()
		clearEggConnections()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		records[slot] = nil
	end))
	watchEgg()
end

local function bindPlot(plot)
	local slots = plot:WaitForChild("Slots", 10)
	if not slots then return end
	for _, slot in ipairs(slots:GetChildren()) do
		bind(slot)
	end
	slots.ChildAdded:Connect(bind)
end
for _, plot in ipairs(plots:GetChildren()) do
	bindPlot(plot)
end
plots.ChildAdded:Connect(bindPlot)
