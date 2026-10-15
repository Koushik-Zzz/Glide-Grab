-- Ability input and presentation. Server picks targets and approves every result.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local modules = ReplicatedStorage:WaitForChild("UIModules")
local Layout = require(modules.Layout)
local Motion = require(modules.Motion)
local Theme = require(modules.Theme)
local motion = Motion.new()
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("SkyCombat")
local Effects = require(ReplicatedStorage:WaitForChild("CombatClientModules"):WaitForChild("Effects"))
local effects = Effects.new()
local gui = player:WaitForChild("PlayerGui"):WaitForChild("SkyCombatHUD")
local root, bar = gui.SafeScreen, gui.SafeScreen.ActionBar
local keys = {Slap = Enum.KeyCode.Q, Bat = Enum.KeyCode.R, Steal = Enum.KeyCode.F, Shield = Enum.KeyCode.G}
local pads = {Slap = Enum.KeyCode.DPadLeft, Bat = Enum.KeyCode.DPadUp, Steal = Enum.KeyCode.DPadRight, Shield = Enum.KeyCode.DPadDown}
local padText = {Slap = "←", Bat = "↑", Steal = "→", Shield = "↓"}
local connections, bound = {}, false
local function request(action)
	local biome = player:GetAttribute("CurrentBiome")
	if UserInputService:GetFocusedTextBox() or (biome ~= "Meadow" and biome ~= "Storm Isles") then return end
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	if not h or h.Health <= 0 or player:GetAttribute("PortalTraveling")
		or Workspace:GetServerTimeNow() < (c:GetAttribute("CombatStunnedUntil") or 0) then return end
	remote:FireServer(action)
end
local function layout()
	local size = root.AbsoluteSize
	if size.X <= 0 then return end
	local regions = Layout.forSize(size, UserInputService.TouchEnabled)
	Layout.place(bar, regions.Actions)
	local width = (regions.Actions[3] - 24) / 4
	for index, action in ipairs({"Slap", "Bat", "Steal", "Shield"}) do
		bar[action].Position = UDim2.fromOffset((index - 1) * (width + 8), 0)
		bar[action].Size = UDim2.fromOffset(width, regions.Actions[4])
		bar[action].ActionName.TextLimit.MaxTextSize = regions.Mode == "Compact" and 14 or 16
	end
end
local function context()
	local biome = player:GetAttribute("CurrentBiome")
	local enabled = biome == "Meadow" or biome == "Storm Isles"
	bar.Visible = enabled
	if enabled and not bound then
		for action, key in pairs(keys) do
			ContextActionService:BindAction("Sky" .. action, function(_, state)
				if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
				if state == Enum.UserInputState.Begin then
					request(action)
				end
				return Enum.ContextActionResult.Sink
			end, false, key, pads[action])
		end
		bound = true
	elseif not enabled and bound then
		for action in pairs(keys) do
			ContextActionService:UnbindAction("Sky" .. action)
		end
		bound = false
	end
end
for action in pairs(keys) do
	motion:button(bar[action])
	table.insert(connections, bar[action].Activated:Connect(function()
		request(action)
	end))
end
local function render()
	local now = Workspace:GetServerTimeNow()
	local input = UserInputService:GetLastInputType()
	local gamepad = string.find(input.Name, "Gamepad") ~= nil
	for action, key in pairs(keys) do
		local waitTime = math.max(0, (player:GetAttribute(action .. "ReadyAt") or 0) - now)
		local prefix = input == Enum.UserInputType.Touch and "" or (gamepad and padText[action] or key.Name)
		local name = action == "Shield" and ("Shield ×" .. (player:GetAttribute("EggShieldCharges") or 0)) or action
		local c = player.Character
		local cargo = c and c:FindFirstChild("CarriedEgg")
		local protectedUntil = cargo and cargo:GetAttribute("TheftProtectedUntil") or 0
		if action == "Shield" and protectedUntil > now then
			name = "Shielded"
			waitTime = protectedUntil - now
		end
		local button = bar[action]
		button.Key.Text = prefix
		button.ActionName.Text = name
		button.Cooldown.Text = waitTime > 0 and string.format("%.1fs", waitTime) or ""
		local available = action ~= "Bat" or player:GetAttribute("OwnsBat")
		button:SetAttribute("UIDisabled", not available or waitTime > 0)
		button.ActionName.TextColor3 = available and Theme.White or Theme.Muted
		if not available then
			button.Cooldown.Text = "Shop"
		end
	end
end
table.insert(connections, player:GetAttributeChangedSignal("CurrentBiome"):Connect(context))
table.insert(connections, root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
table.insert(connections, UserInputService.LastInputTypeChanged:Connect(layout))
local elapsed = 0
table.insert(connections, RunService.RenderStepped:Connect(function(dt)
	elapsed += dt
	if elapsed >= 0.1 then
		elapsed = 0
		render()
	end
end))
local shop = Workspace:WaitForChild("SkyGearShop")
local function refreshShop()
	shop.BatCounter.PurchasePrompt.ActionText = player:GetAttribute("OwnsBat") and "Bat owned — R to swing" or "Buy bat — 5,000 coins"
	shop.ShieldCounter.PurchasePrompt.ObjectText = "Egg shields: " .. (player:GetAttribute("EggShieldCharges") or 0) .. "/3"
end
table.insert(connections, player:GetAttributeChangedSignal("OwnsBat"):Connect(refreshShop))
table.insert(connections, player:GetAttributeChangedSignal("EggShieldCharges"):Connect(refreshShop))
context()
layout()
render()
refreshShop()
script.Destroying:Connect(function()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	for action in pairs(keys) do
		ContextActionService:UnbindAction("Sky" .. action)
	end
	effects:destroy()
	motion:destroy()
end)
