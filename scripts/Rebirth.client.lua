local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")
local modules = RS:WaitForChild("UIModules")
local Theme = require(modules.Theme)
local Motion = require(modules.Motion)
local motion = Motion.new()
local player = Players.LocalPlayer
local remote = RS:WaitForChild("Rebirth")
local gui = player.PlayerGui:WaitForChild("RebirthHUD")
local root, modal = gui.SafeScreen, gui.SafeScreen.Modal
local confirm, cancel = modal.Confirm, modal.Cancel
motion:button(confirm)
motion:button(cancel)
local modalScale = Instance.new("UIScale")
modalScale.Name = "OpenFeedback"
modalScale.Parent = modal
confirm.NextSelectionLeft, confirm.NextSelectionRight = cancel, cancel
cancel.NextSelectionLeft, cancel.NextSelectionRight = confirm, confirm
confirm.NextSelectionUp, confirm.NextSelectionDown = cancel, cancel
cancel.NextSelectionUp, cancel.NextSelectionDown = confirm, confirm
local token, cost, saving, priorSelection
local connections = {}
local function close()
	if saving then return end
	root.Visible = false
	token = nil
	CAS:UnbindAction("CloseRebirth")
	if not GuiService.MenuIsOpen then
		GuiService.SelectedObject = priorSelection and priorSelection.Parent and priorSelection or nil
	end
end
local function render()
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	local enough = coins and coins.Value >= (cost or math.huge)
	confirm.Active = token ~= nil and enough and not saving
	confirm:SetAttribute("UIDisabled", not confirm.Active)
	confirm.Text = saving and "Saving..." or enough and "Confirm rebirth" or "Need more coins"
	confirm.BackgroundColor3 = confirm.Active and Theme.Green or Theme.Muted
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
		modal.Title.Text = "REBIRTH • " .. Theme.short(price) .. " coins"
		modal.Body.Copy.RichText = true
		modal.Body.Copy.Text = '<b><font color="#9CFF73">UNLOCK</font></b>\nStorm Isles: stronger crosswinds and Epic eggs\nSecond camp floor: 12 pillow slots\n\n<b><font color="#FFB36B">RESET</font></b>\nAll coins, stored eggs, ready income and boost upgrades\n\n'
			.. (keepGear and '<b><font color="#7DDEFF">KEEP</font></b>\nYour purchased bat and unused shield charges' or "Gear purchases and shield charges also reset.")
		cancel.Active, cancel.Visible = true, true
		priorSelection = GuiService.SelectedObject
		root.Visible = true
		modal.Body.CanvasPosition = Vector2.zero
		motion:pop(modalScale, 0.96)
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
		modal.Body.Copy.RichText = false
		modal.Body.Copy.Text = value
		cancel.Active, cancel.Visible = true, true
		confirm.Active, confirm.Visible = false, false
		root.Visible = true
		motion:pop(modalScale, 0.96)
		CAS:BindAction("CloseRebirth", function(_, state)
			if state == Enum.UserInputState.Begin then
				close()
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.Escape, Enum.KeyCode.ButtonB)
		if UIS.GamepadEnabled then
			GuiService.SelectedObject = cancel
		end
	end
	if action == "Offer" then
		confirm.Visible = true
	end
end))
local function layout()
	modal.Size = UDim2.new(0.92, 0, 0, math.min(392, math.max(210, root.AbsoluteSize.Y - 24)))
end
table.insert(connections, root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
table.insert(connections, player.CharacterRemoving:Connect(function()
	saving = false
	close()
end))
table.insert(connections, GuiService.MenuOpened:Connect(close))
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
	motion:destroy()
end)
