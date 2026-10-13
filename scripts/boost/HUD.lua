-- Render the authored BoostHUD shell. Input and purchases are owned elsewhere.
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local HUD = {}
HUD.__index = HUD
local ink = Color3.fromRGB(35, 58, 68)
local mint = Color3.fromRGB(221, 255, 240)
local teal = Color3.fromRGB(28, 130, 110)
local muted = Color3.fromRGB(82, 111, 120)
local amber = Color3.fromRGB(255, 235, 179)

function HUD.new(gui, player, config)
	local self = setmetatable({Gui = gui, Player = player, Config = config, NoticeUntil = 0}, HUD)
	self.Root = gui:WaitForChild("SafeScreen")
	self.Button = self.Root:WaitForChild("BoostButton")
	self.Status = self.Button:WaitForChild("Status")
	self.Hint = self.Button:WaitForChild("Hint")
	self.Fill = self.Button:WaitForChild("Meter"):WaitForChild("Fill")
	self.Notice = self.Root:WaitForChild("Notice")
	self.LayoutConnection = self.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:layout()
	end)
	self:layout()
	return self
end

function HUD:layout()
	local size = self.Root.AbsoluteSize
	if size.X <= 0 then return end
	local touch = UserInputService.TouchEnabled
	local narrow = size.X < 760
	local compact = size.Y < 480 and size.X >= 460
	-- Center action on small/touch screens, clear of joystick/jump and the hotbar.
	if compact then
		self.Button.AnchorPoint = Vector2.new(1, 0)
		self.Button.Position = UDim2.new(1, -16, 0, 84)
		self.Button.Size = UDim2.fromOffset(180, 60)
	elseif narrow or touch then
		self.Button.AnchorPoint = Vector2.new(0.5, 1)
		self.Button.Position = UDim2.new(0.5, 0, 1, -86)
		self.Button.Size = UDim2.fromOffset(math.min(200, size.X - 32), 60)
	else
		self.Button.AnchorPoint = Vector2.new(1, 1)
		self.Button.Position = UDim2.new(1, -20, 1, -24)
		self.Button.Size = UDim2.fromOffset(228, 68)
	end
	self.Notice.AnchorPoint = Vector2.new(compact and 0 or 0.5, 0)
	self.Notice.Size = UDim2.fromOffset(math.min(380, size.X - (compact and 228 or 32)), compact and 30 or 42)
	self.Notice.Position = compact and UDim2.fromOffset(16, 136)
		or UDim2.new(0.5, 0, 0, narrow and 212 or 142)
end

function HUD:showNotice(text)
	self.Notice.Text = text
	self.NoticeUntil = Workspace:GetServerTimeNow() + 2.5
	self.Notice.Visible = true
end

function HUD:render(character)
	local player, config = self.Player, self.Config
	local now = Workspace:GetServerTimeNow()
	local level = player:GetAttribute("BoostLevel") or 0
	local settings = config.atLevel(level)
	local untilTime = player:GetAttribute("BoostUntil") or 0
	local readyAt = player:GetAttribute("BoostReadyAt") or 0
	local flying = character and character:GetAttribute("GliderFlying") == true
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local knockedUntil = character and character:GetAttribute("GuardianKnockbackUntil") or 0
	local blocked = not humanoid or humanoid.Health <= 0 or not root or root.Anchored
		or player:GetAttribute("PortalTraveling") or knockedUntil > now
	local fraction, status, hint = 1, "BOOST READY", ""
	local active = untilTime > now and not blocked and flying
	local recharge = player:GetAttribute("BoostRecharge") or settings.Recharge
	if active then
		fraction = math.clamp((untilTime - now) / settings.Duration, 0, 1)
		status, hint = "BOOSTING!", "Make your escape"
	elseif readyAt > now then
		fraction = math.clamp(1 - (readyAt - now) / recharge, 0, 1)
		status, hint = string.format("RECHARGING %.1fs", readyAt - now), "Boost level " .. level
	elseif blocked then
		status, hint = "BOOST PAUSED", "Ready when flight resumes"
	elseif not flying then
		status, hint = "BOOST READY", "Equip glider + Space to fly"
	else
		local input = UserInputService:GetLastInputType()
		local gamepad = string.find(input.Name, "Gamepad") ~= nil
		status = "BOOST READY"
		hint = input == Enum.UserInputType.Touch and "Tap to boost" or gamepad and "R1 to boost" or "Shift to boost"
	end
	self.Status.Text, self.Hint.Text = status, hint
	self.Fill.Size = UDim2.fromScale(fraction, 1)
	self.Fill.BackgroundColor3 = active and ink or teal
	self.Button.BackgroundColor3 = active and amber or mint
	self.Status.TextColor3 = blocked and muted or ink
	self.Notice.Visible = now < self.NoticeUntil
end

function HUD:destroy()
	self.LayoutConnection:Disconnect()
end

return HUD
