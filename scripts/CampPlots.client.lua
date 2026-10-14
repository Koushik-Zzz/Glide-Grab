-- Personal prompt visibility; server private records enforce every transaction.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local folder = workspace:WaitForChild("CampPlots")
local bound = {}
local function bind(plot)
	if not plot:IsA("Model") or bound[plot] then return end
	local connections, prompts = {}, {}
	bound[plot] = connections
	local function refresh(prompt)
		prompt.Enabled = plot:GetAttribute("OwnerUserId") == player.UserId
			and prompt:GetAttribute("Available") == true
	end
	local function add(object)
		if not object:IsA("ProximityPrompt") or prompts[object] then return end
		prompts[object] = object:GetAttributeChangedSignal("Available"):Connect(function()
			refresh(object)
		end)
		refresh(object)
	end
	table.insert(connections, plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		for prompt in pairs(prompts) do
			refresh(prompt)
		end
	end))
	table.insert(connections, plot.DescendantAdded:Connect(add))
	table.insert(connections, plot.DescendantRemoving:Connect(function(object)
		if prompts[object] then
			prompts[object]:Disconnect()
			prompts[object] = nil
		end
	end))
	table.insert(connections, plot.AncestryChanged:Connect(function()
		if plot.Parent == folder then return end
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		for _, connection in pairs(prompts) do
			connection:Disconnect()
		end
		bound[plot] = nil
	end))
	for _, object in ipairs(plot:GetDescendants()) do
		add(object)
	end
end
folder.ChildAdded:Connect(bind)
for _, plot in ipairs(folder:GetChildren()) do
	bind(plot)
end
