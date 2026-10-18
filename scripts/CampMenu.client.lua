-- One authored shell, data-driven rows, real server catalogue and transactions.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local GS = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local modules, assets = RS:WaitForChild("UIModules"), RS:WaitForChild("UIAssets")
local Theme, Layout = require(modules.Theme), require(modules.Layout)
local Motion, Menus = require(modules.Motion), require(modules.Menus)
local remote = RS:WaitForChild("CampShop")
local rebirth = RS:WaitForChild("Rebirth")
local gui = player:WaitForChild("PlayerGui"):WaitForChild("CampMenu")
local root = gui.SafeScreen
local overlay, rail = root.Overlay, root.Rail
local modal = overlay.Modal
local motion, rowMotion = Motion.new(), Motion.new()
local connections, rows = {}, {}
local catalogue, pending, prior, category = nil, nil, nil, "Gear"
local serial, expanded, alive = 0, false, true
local render, layout, close
local function watch(signal, callback) table.insert(connections, signal:Connect(callback)) end
local function feedback(message, success)
	modal.Feedback.Text = message
	modal.Feedback.TextColor3 = success and Theme.Green or Theme.Cream
end
local function request(action, item, expected)
	if pending then return end
	serial += 1
	local id = serial
	pending = id
	if expected == nil then expected = false end
	remote:FireServer(action, id, item or "", expected)
	if render then render() end
	task.delay(8, function()
		if alive and pending == id then
			pending = nil
			feedback("No response yet. Check the item state before trying again.", false)
			render()
		end
	end)
end
local function addRow(id, title, description, icon, order)
	local row = assets.ShopRow:Clone()
	row.Name, row.LayoutOrder = id, order
	row.Title.Text, row.Description.Text = title, description
	local art = assets.Icons[icon]:Clone()
	art.Size, art.Position, art.Parent = UDim2.new(1, -16, 1, -16), UDim2.fromOffset(8, 8), row.Art
	row.Parent = modal.Items
	rows[id] = row
	rowMotion:button(row.Action)
	watch(row.Action.Activated, function()
		if row.Action:GetAttribute("UIDisabled") then return end
		local expected = id == "Bat" and player:GetAttribute("OwnsBat") == true
			or id == "Shield" and (player:GetAttribute("EggShieldCharges") or 0)
			or id == "Boost" and (player:GetAttribute("BoostLevel") or 0) or false
		request("Buy", id, expected)
	end)
end
addRow("Slap", "Slap Glove", "Stun a nearby rival. Your glider stays equipped.", "Slap", 1)
addRow("Bat", "Bat", "A stronger swing to interrupt a rival's escape.", "Bat", 2)
addRow("Shield", "Egg Shield", "Protect your carried egg from theft for 12 seconds.", "Shield", 3)
addRow("Boost", "Glider Boost", "Longer bursts and faster recharge for your glider.", "Boost", 4)
local function levelSettings(level)
	-- Remote serialization can turn zero-based level keys into strings.
	return catalogue and (catalogue.Levels[level] or catalogue.Levels[tostring(level)])
end
render = function()
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	local balance = coins and coins.Value or 0
	local camp = player:GetAttribute("CurrentBiome") == "Base Camp" and not player:GetAttribute("PortalTraveling")
	for id, row in rows do
		row.Visible = (category == "Boost") == (id == "Boost")
		local owned, price, detail = false, 0, ""
		if id == "Slap" then owned, detail = true, "Included • Q / D-pad left"
		elseif id == "Bat" then
			owned = player:GetAttribute("OwnsBat") == true
			price = catalogue and catalogue.BatPrice or 0
			detail = "Permanent gear • R / D-pad up"
		elseif id == "Shield" then
			local charges = player:GetAttribute("EggShieldCharges") or 0
			owned = catalogue and charges >= catalogue.ShieldMax
			price = catalogue and catalogue.ShieldPrice or 0
			detail = string.format("%d / %d charges • G / D-pad down", charges, catalogue and catalogue.ShieldMax or 3)
		else
			local level = player:GetAttribute("BoostLevel") or 0
			local current, nextLevel = levelSettings(level), levelSettings(level + 1)
			owned = catalogue and level >= catalogue.MaxLevel
			price = nextLevel and nextLevel.Price or 0
			row.Title.Text = "Glider Boost • Level " .. level
			if current then
				row.Description.Text = nextLevel and string.format("Burst %.1fs → %.1fs\nRecharge %.1fs → %.1fs", current.Duration, nextLevel.Duration, current.Recharge, nextLevel.Recharge)
					or string.format("%.1fs burst • %.1fs recharge", current.Duration, current.Recharge)
			end
			detail = "Level " .. level .. " / " .. (catalogue and catalogue.MaxLevel or 5) .. " • resets on rebirth"
		end
		row.Detail.Text = detail
		local disabled = owned or not catalogue or pending ~= nil or not camp or balance < price
		row.Action:SetAttribute("UIDisabled", disabled)
		row.Action.BackgroundColor3 = owned and Theme.Sky or disabled and Theme.Muted or Theme.Green
		row.Action.Price.Text = id == "Slap" and "FREE" or not catalogue and "..." or owned and (id == "Shield" and "FULL" or id == "Boost" and "MAX" or "OWNED") or "$" .. Theme.short(price)
		row.Action.Label.Text = not catalogue and "Loading..." or pending and "Wait..." or owned and (id == "Slap" and "Included" or "Ready")
			or not camp and "At camp" or balance < price and "Need coins" or id == "Boost" and "Upgrade" or "Buy"
	end
	modal.Header.Title.Text = category == "Boost" and "Boost Workshop" or "Glider & Gear Shop"
	modal.Header.Subtitle.Text = category == "Boost" and "Your next burst starts here." or "Sky gear. One glider. More ways to escape."
	modal.Tabs.Gear.BackgroundColor3 = category == "Gear" and Theme.Sky or Theme.Panel
	modal.Tabs.Boost.BackgroundColor3 = category == "Boost" and Theme.Purple or Theme.Panel
	if layout then layout() end
end
layout = function()
	local size = root.AbsoluteSize
	if size.X < 1 then return end
	local regions = Layout.forSize(size, UIS.TouchEnabled)
	Layout.place(rail, regions.Menu)
	Layout.place(root.MenuToggle, regions.Toggle)
	root.MenuToggle.Label.Text = regions.Toggle[3] < 60 and "+" or "Menu"
	root.MenuToggle.Visible = regions.CollapsedMenu and (Menus.Current == nil or Menus.Current == "Navigation")
	rail.Visible = (Menus.Current == nil or Menus.Current == "Navigation") and (not regions.CollapsedMenu or expanded)
	for _, button in rail:GetChildren() do
		if button:IsA("GuiButton") then button.Size = UDim2.new(1, 0, 0, 46) end
	end
	local width, height = math.min(780, size.X - 24), math.min(category == "Boost" and 332 or 510, size.Y - 24)
	modal.Size = UDim2.fromOffset(width, height)
	local stacked = width < 590
	local short = height < 380
	modal.Header.Size = UDim2.new(1, 0, 0, short and 60 or 72)
	modal.Header.Title.TextLimit.MaxTextSize = stacked and 23 or 32
	modal.Header.Subtitle.Visible = not short and width > 420
	modal.Header.Icon.Size = UDim2.fromOffset(short and 42 or 57, short and 42 or 57)
	modal.Tabs.Position = UDim2.fromOffset(14, short and 70 or 83)
	local tabWidth = math.min(160, (width - 48) / 2)
	modal.Tabs.Gear.Size, modal.Tabs.Boost.Size = UDim2.fromOffset(tabWidth, 38), UDim2.fromOffset(tabWidth, 38)
	modal.Tabs.Boost.Position = UDim2.fromOffset(tabWidth + 12, 0)
	local top = short and 120 or 137
	modal.Items.Position = UDim2.fromOffset(14, top)
	modal.Items.Size = UDim2.new(1, -28, 1, -top - 52)
	local buttons = {modal.Header.Close, modal.Tabs.Gear, modal.Tabs.Boost}
	for _, id in {"Slap", "Bat", "Shield", "Boost"} do
		local row = rows[id]
		row.Size = UDim2.new(1, -2, 0, stacked and 196 or 118)
		row.Art.Size = UDim2.fromOffset(stacked and 66 or 94, stacked and 66 or 94)
		row.Title.Position = UDim2.fromOffset(stacked and 90 or 122, 12)
		row.Title.Size = UDim2.new(1, stacked and -100 or -305, 0, 30)
		row.Title.TextLimit.MaxTextSize = stacked and 21 or 25
		row.Description.Position = UDim2.fromOffset(stacked and 90 or 122, 44)
		row.Description.Size = UDim2.new(1, stacked and -100 or -305, 0, stacked and 50 or 38)
		row.Detail.Position = UDim2.fromOffset(stacked and 12 or 122, stacked and 101 or 86)
		row.Detail.Size = UDim2.new(1, stacked and -24 or -305, 0, 22)
		row.Action.Position = stacked and UDim2.fromOffset(12, 134) or UDim2.new(1, -174, 0, 18)
		row.Action.Size = stacked and UDim2.new(1, -24, 0, 48) or UDim2.fromOffset(160, 82)
		row.Action.Price.Position = UDim2.fromOffset(8, 8)
		row.Action.Price.Size = stacked and UDim2.new(.5, -12, 0, 30) or UDim2.new(1, -16, 0, 28)
		row.Action.Label.Position = stacked and UDim2.new(.5, 0, 0, 8) or UDim2.fromOffset(8, 42)
		row.Action.Label.Size = stacked and UDim2.new(.5, -8, 0, 30) or UDim2.new(1, -16, 0, 27)
		if row.Visible then table.insert(buttons, row.Action) end
	end
	for i, button in buttons do
		button.NextSelectionUp = buttons[(i - 2) % #buttons + 1]
		button.NextSelectionDown = buttons[i % #buttons + 1]
	end
end
close = function()
	expanded = false
	overlay.Visible = false
	CAS:UnbindAction("CloseCampMenu")
	if Menus.Current == "Shop" or Menus.Current == "Navigation" then Menus.set(nil) end
	if not GS.MenuIsOpen then GS.SelectedObject = prior and prior.Parent and prior or nil end
	layout()
end
local function open(tab)
	if player:GetAttribute("PortalTraveling") then return end
	category, expanded = tab, false
	if not overlay.Visible then prior = GS.SelectedObject end
	Menus.set("Shop")
	overlay.Visible = true
	modal.Items.CanvasPosition = Vector2.zero
	feedback(player:GetAttribute("CurrentBiome") == "Base Camp" and "Purchases use coins. Gear stays with you through rebirth." or "Browse here; return to Base Camp to buy.", false)
	render()
	motion:pop(modal.OpenFeedback, .97)
	CAS:BindActionAtPriority("CloseCampMenu", function(_, state)
		if state == Enum.UserInputState.Begin then close() end
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.KeyCode.ButtonB)
	if string.find(UIS:GetLastInputType().Name, "Gamepad") then GS.SelectedObject = modal.Header.Close end
	if not catalogue then request("Browse") end
end
for _, button in {rail.Shop, rail.Upgrades, rail.Rebirth, root.MenuToggle, modal.Header.Close, modal.Tabs.Gear, modal.Tabs.Boost} do motion:button(button) end
watch(rail.Shop.Activated, function() open("Gear") end)
watch(rail.Upgrades.Activated, function() open("Boost") end)
watch(rail.Rebirth.Activated, function() expanded = false layout() rebirth:FireServer("Open") end)
watch(root.MenuToggle.Activated, function() expanded = not expanded Menus.set(expanded and "Navigation" or nil) layout() end)
watch(modal.Header.Close.Activated, close)
watch(overlay.Dim.Activated, close)
watch(modal.Tabs.Gear.Activated, function() open("Gear") end)
watch(modal.Tabs.Boost.Activated, function() open("Boost") end)
watch(remote.OnClientEvent, function(id, ok, message, data)
	if id ~= pending then return end
	pending = nil
	if data then catalogue = data end
	if message ~= "" then feedback(message, ok) end
	render()
end)
table.insert(connections, Menus.subscribe(function(name)
	if name ~= "Navigation" then expanded = false end
	if name ~= "Shop" and overlay.Visible then close() else layout() end
end))
watch(GS.MenuOpened, close)
watch(root:GetPropertyChangedSignal("AbsoluteSize"), layout)
watch(UIS.LastInputTypeChanged, layout)
watch(player.CharacterRemoving, close)
for _, attr in {"CurrentBiome", "PortalTraveling", "OwnsBat", "EggShieldCharges", "BoostLevel"} do
	watch(player:GetAttributeChangedSignal(attr), function()
		if player:GetAttribute("PortalTraveling") then close() end
		render()
	end)
end
task.spawn(function()
	local coins = player:WaitForChild("leaderstats"):WaitForChild("Coins")
	if alive then watch(coins.Changed, render) render() end
end)
render()
script.Destroying:Connect(function()
	alive = false
	close()
	for _, connection in connections do connection:Disconnect() end
	motion:destroy()
	rowMotion:destroy()
end)
