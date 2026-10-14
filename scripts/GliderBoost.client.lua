-- Ability input/controller. The server approves boosts; HUD only renders its state.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local modules = ReplicatedStorage:WaitForChild("BoostModules")
local Config = require(modules:WaitForChild("Config"))
local HUD = require(modules:WaitForChild("HUD"))
local remote = ReplicatedStorage:WaitForChild("RequestGliderBoost")
local gui = player:WaitForChild("PlayerGui"):WaitForChild("GliderBoostHUD")
local hud = HUD.new(gui, player, Config)
local character, characterConnection, bound = nil, nil, false
local lastRequest = 0
local connections = {}

local function request()
	if UserInputService:GetFocusedTextBox() then return end
	local now = Workspace:GetServerTimeNow()
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or root.Anchored
		or player:GetAttribute("PortalTraveling") then return end
	if character:GetAttribute("GliderFlying") ~= true then
		hud:showNotice("Equip your glider and press Space to fly")
		return
	end
	if now < (character:GetAttribute("GuardianKnockbackUntil") or 0)
		or now < (character:GetAttribute("CombatStunnedUntil") or 0)
		or now < (player:GetAttribute("BoostReadyAt") or 0) or now - lastRequest < 0.2 then return end
	lastRequest = now
	remote:FireServer()
end

local function refreshBinding()
	local flying = character and character:GetAttribute("GliderFlying") == true
	if flying and not bound then
		ContextActionService:BindAction("GliderBoost", function(_, state)
			if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
			if state == Enum.UserInputState.Begin then
				request()
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.ButtonR1)
		bound = true
	elseif not flying and bound then
		ContextActionService:UnbindAction("GliderBoost")
		bound = false
	end
end

local function bindCharacter(newCharacter)
	if characterConnection then
		characterConnection:Disconnect()
	end
	character = newCharacter
	characterConnection = character:GetAttributeChangedSignal("GliderFlying"):Connect(refreshBinding)
	refreshBinding()
end
table.insert(connections, player.CharacterAdded:Connect(bindCharacter))
table.insert(connections, player.CharacterRemoving:Connect(function(oldCharacter)
	if character == oldCharacter then
		if characterConnection then
			characterConnection:Disconnect()
		end
		characterConnection, character = nil, nil
		refreshBinding()
	end
end))
if player.Character then
	bindCharacter(player.Character)
end
table.insert(connections, hud.Button.Activated:Connect(request))
table.insert(connections, remote.OnClientEvent:Connect(function(message)
	if type(message) == "string" then
		hud:showNotice(message)
	end
end))
table.insert(connections, UserInputService.LastInputTypeChanged:Connect(function()
	hud:layout()
end))
table.insert(connections, RunService.RenderStepped:Connect(function()
	hud:render(character)
end))

-- Each player sees their own next price; server cost/level never comes from this text.
local prompt = Workspace:WaitForChild("BoostWorkshop"):WaitForChild("Counter"):WaitForChild("UpgradePrompt")
local function refreshShop()
	local level = player:GetAttribute("BoostLevel") or 0
	local nextSettings = Config.Levels[level + 1]
	prompt.ActionText = nextSettings and ("Upgrade boost — " .. nextSettings.Price .. " coins") or "Fully upgraded"
	prompt.ObjectText = nextSettings and string.format("Level %d: %.1fs burst / %.1fs recharge", level + 1,
		nextSettings.Duration, nextSettings.Recharge) or "Boost workshop — MAX"
end
table.insert(connections, player:GetAttributeChangedSignal("BoostLevel"):Connect(refreshShop))
refreshShop()
script.Destroying:Connect(function()
	if characterConnection then
		characterConnection:Disconnect()
	end
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	ContextActionService:UnbindAction("GliderBoost")
	hud:destroy()
end)
