local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local remote = RS:WaitForChild("Rebirth")
local gui = player.PlayerGui:WaitForChild("RebirthHUD")
local root, modal = gui.SafeScreen, gui.SafeScreen.Modal
local confirm, cancel = modal.Confirm, modal.Cancel
confirm.NextSelectionLeft, confirm.NextSelectionRight = cancel, cancel
cancel.NextSelectionLeft, cancel.NextSelectionRight = confirm, confirm
local token, cost, saving, priorSelection
local connections = {}
local function close()
	if saving then return end
	root.Visible = false
	token = nil
	CAS:UnbindAction("CloseRebirth")
	GuiService.SelectedObject = priorSelection and priorSelection.Parent and priorSelection or nil
end
local function render()
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	local enough = coins and coins.Value >= (cost or math.huge)
	confirm.Active = token ~= nil and enough and not saving
	confirm.AutoButtonColor = confirm.Active
	confirm.Text = saving and "Saving..." or enough and "Confirm rebirth" or "Need more coins"
	confirm.BackgroundColor3 = confirm.Active and Color3.fromRGB(28, 130, 110) or Color3.fromRGB(82, 111, 120)
end
table.insert(connections, confirm.Activated:Connect(function()
	if not token or not confirm.Active or saving then return end
	local value = token
	saving = true
	cancel.Active = false
	render()
	remote:FireServer("Confirm", value)
end))
table.insert(connections, cancel.Activated:Connect(close))
table.insert(connections, remote.OnClientEvent:Connect(function(action, value, price, keepGear)
	if action == "Offer" then
		token, cost, saving = value, price, false
		task.delay(20, function()
			if token == value and not saving then
				close()
			end
		end)
		modal.Title.Text = "First rebirth • 250,000 coins"
		modal.Body.Copy.Text = "UNLOCK\nStorm Isles: stronger crosswinds and Epic eggs\nSecond camp floor: 12 pillow slots\n\nRESET\nAll coins, stored eggs, ready income and boost upgrades\n\n"
			.. (keepGear and "KEEP\nYour purchased bat and unused shield charges" or "Gear purchases and shield charges also reset.")
		cancel.Active, cancel.Visible = true, true
		priorSelection = GuiService.SelectedObject
		root.Visible = true
		render()
		CAS:BindAction("CloseRebirth", function(_, state)
			if state == Enum.UserInputState.Begin then
				close()
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.Escape, Enum.KeyCode.ButtonB)
		if UIS.GamepadEnabled then
			GuiService.SelectedObject = cancel
		end
	elseif action == "Saving" then
		saving = true
		render()
	elseif action == "Notice" then
		token, saving = nil, false
		modal.Title.Text = "Rebirth"
		modal.Body.Copy.Text = value
		cancel.Active, cancel.Visible = true, true
		confirm.Active, confirm.Visible = false, false
		root.Visible = true
		if UIS.GamepadEnabled then
			GuiService.SelectedObject = cancel
		end
	end
	if action == "Offer" then
		confirm.Visible = true
	end
end))
local function layout()
	modal.Size = UDim2.new(0.92, 0, 0, math.min(350, math.max(210, root.AbsoluteSize.Y - 24)))
end
table.insert(connections, root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
table.insert(connections, player.CharacterRemoving:Connect(function()
	saving = false
	close()
end))
task.spawn(function()
	local coins = player:WaitForChild("leaderstats"):WaitForChild("Coins")
	table.insert(connections, coins:GetPropertyChangedSignal("Value"):Connect(render))
end)
layout()
script.Destroying:Connect(function()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	saving = false
	close()
end)
