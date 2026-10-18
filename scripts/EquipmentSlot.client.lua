-- Replace the prototype backpack slot only while this game's sole Tool is Glider.
-- Any additional Tool restores Roblox's backpack so unknown equipment remains usable.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local CAS = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local modules = RS:WaitForChild("UIModules")
local Layout, Menus = require(modules.Layout), require(modules.Menus)
local motion = require(modules.Motion).new()
local gui = player:WaitForChild("PlayerGui"):WaitForChild("CampMenu")
local root, slot = gui.SafeScreen, gui.SafeScreen.GliderSlot
local backpack = player:WaitForChild("Backpack")
local connections, characterConnections = {}, {}
local backpackConnections = {}
local current, managed = nil, false
local previous = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack)
local function refresh()
	local count, glider = 0, nil
	local containers = {}
	if backpack and backpack.Parent == player then table.insert(containers, backpack) end
	if player.Character then table.insert(containers, player.Character) end
	for _, container in containers do
		for _, child in container:GetChildren() do
			if child:IsA("Tool") then count += 1 if child.Name == "Glider" then glider = child end end
		end
	end
	current = glider
	local shouldManage = count == 1 and glider ~= nil
	if shouldManage ~= managed then
		managed = shouldManage
		if managed then StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		else StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, previous) end
	end
	slot.Visible = managed and Menus.Current == nil and not player:GetAttribute("PortalTraveling")
	slot.Outline.Color = glider and glider.Parent == player.Character and Color3.fromRGB(32, 189, 242) or Color3.fromRGB(16, 38, 52)
	slot.Label.Text = glider and glider.Parent == player.Character and "Equipped" or "Glider"
	local input = UIS:GetLastInputType()
	slot.Key.Text = input == Enum.UserInputType.Touch and "" or string.find(input.Name, "Gamepad") and "" or "1"
	local rect = Layout.forSize(root.AbsoluteSize, UIS.TouchEnabled).Slot
	Layout.place(slot, rect)
	slot.Icon.Size = UDim2.fromOffset(rect[4] < 60 and 34 or 50, rect[4] < 60 and 30 or 44)
	slot.Icon.Position = UDim2.fromOffset((rect[3] - slot.Icon.Size.X.Offset) / 2, 3)
end
local function equip()
	if not managed or not current or Menus.Current or player:GetAttribute("PortalTraveling") or UIS:GetFocusedTextBox() then return end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	if current.Parent == player.Character then humanoid:UnequipTools() else humanoid:EquipTool(current) end
end
local function bind(character)
	for _, connection in characterConnections do connection:Disconnect() end
	table.clear(characterConnections)
	table.insert(characterConnections, character.ChildAdded:Connect(refresh))
	table.insert(characterConnections, character.ChildRemoved:Connect(refresh))
	refresh()
end
local function bindBackpack(container)
	for _, connection in backpackConnections do connection:Disconnect() end
	table.clear(backpackConnections)
	backpack = container
	table.insert(backpackConnections, container.ChildAdded:Connect(refresh))
	table.insert(backpackConnections, container.ChildRemoved:Connect(refresh))
	refresh()
end
motion:button(slot)
table.insert(connections, slot.Activated:Connect(equip))
table.insert(connections, player.ChildAdded:Connect(function(child)
	if child:IsA("Backpack") then bindBackpack(child) end
end))
table.insert(connections, player.ChildRemoved:Connect(function(child)
	if child == backpack then refresh() end
end))
bindBackpack(backpack)
table.insert(connections, player.CharacterAdded:Connect(bind))
table.insert(connections, player.CharacterRemoving:Connect(function() slot.Visible = false end))
table.insert(connections, root:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh))
table.insert(connections, UIS.LastInputTypeChanged:Connect(refresh))
table.insert(connections, player:GetAttributeChangedSignal("PortalTraveling"):Connect(refresh))
table.insert(connections, Menus.subscribe(refresh))
CAS:BindActionAtPriority("GliderSlot", function(_, state)
	if not managed or UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
	if state == Enum.UserInputState.Begin then equip() end
	return Enum.ContextActionResult.Sink
end, false, 2100, Enum.KeyCode.One)
if player.Character then bind(player.Character) else refresh() end
script.Destroying:Connect(function()
	for _, connection in connections do connection:Disconnect() end
	for _, connection in characterConnections do connection:Disconnect() end
	for _, connection in backpackConnections do connection:Disconnect() end
	CAS:UnbindAction("GliderSlot")
	if managed then StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, previous) end
	motion:destroy()
end)
