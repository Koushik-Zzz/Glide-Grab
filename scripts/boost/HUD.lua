-- Render the authored BoostHUD shell. Input and purchases are owned elsewhere.
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local modules = game:GetService("ReplicatedStorage"):WaitForChild("UIModules")
local Theme = require(modules.Theme)
local Layout = require(modules.Layout)
local Motion = require(modules.Motion)
local Notices = require(modules.Notices)
local HUD = {}
HUD.__index = HUD

function HUD.new(gui, player, config)
	local self = setmetatable({Gui = gui, Player = player, Config = config, NoticeUntil = 0}, HUD)
	self.Root = gui:WaitForChild("SafeScreen")
	self.Button = self.Root:WaitForChild("BoostButton")
	self.Status = self.Button:WaitForChild("Status")
	self.Hint = self.Button:WaitForChild("Hint")
	self.Fill = self.Button:WaitForChild("Meter"):WaitForChild("Fill")
	self.Notice = self.Root:WaitForChild("Notice")
	self.Motion = Motion.new()
	self.Motion:button(self.Button)
	self.LayoutConnection = self.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:layout()
	end)
	self:layout()
	return self
end

function HUD:layout()
	local size = self.Root.AbsoluteSize
	if size.X <= 0 then return end
	local regions = Layout.forSize(size, UserInputService.TouchEnabled)
	Layout.place(self.Button, regions.Boost)
	Layout.place(self.Notice, regions.Notice)
	self.Status.Size = UDim2.new(1, -67, 0, 23)
	self.Hint.Position = UDim2.fromOffset(55, 36)
end

function HUD:showNotice(text)
	self.Notice.Text = text
	Notices.show(text, 2.5)
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
	knockedUntil = math.max(knockedUntil, character and character:GetAttribute("CombatStunnedUntil") or 0)
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
		status, hint = "BOOST READY", UserInputService:GetLastInputType() == Enum.UserInputType.Touch
			and "Equip glider to fly" or "Equip glider + Space to fly"
	else
		local input = UserInputService:GetLastInputType()
		local gamepad = string.find(input.Name, "Gamepad") ~= nil
		status = "BOOST READY"
		hint = input == Enum.UserInputType.Touch and "Tap to boost" or gamepad and "R1 to boost" or "Shift to boost"
	end
	self.Status.Text, self.Hint.Text = status, hint
	self.Fill.Size = UDim2.fromScale(fraction, 1)
	self.Fill.BackgroundColor3 = active and Theme.Gold or Theme.White
	self.Button.BackgroundColor3 = active and Theme.Gold or Theme.Yellow
	self.Status.TextColor3 = blocked and Theme.Muted or Theme.White
	self.Button:SetAttribute("UIDisabled", blocked or readyAt > now)
	self.Notice.Visible = false -- retained authored path; shared status renders notices
end

function HUD:destroy()
	self.LayoutConnection:Disconnect()
	self.Motion:destroy()
end

return HUD
