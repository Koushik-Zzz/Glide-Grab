-- Interruptible feedback, shared by buttons, rewards and the rebirth modal.
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Motion = {}
Motion.__index = Motion

function Motion.new()
	return setmetatable({Tweens = {}, Connections = {}, Alive = true}, Motion)
end

function Motion:to(object, duration, properties, style)
	if not self.Alive then return end
	if self.Tweens[object] then
		self.Tweens[object]:Cancel()
	end
	if GuiService.ReducedMotionEnabled then
		for key, value in pairs(properties) do
			object[key] = value
		end
		return
	end
	local tween = TweenService:Create(object, TweenInfo.new(duration, style or Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out), properties)
	self.Tweens[object] = tween
	tween:Play()
end

function Motion:pop(scale, amount)
	if GuiService.ReducedMotionEnabled then return end
	if self.Tweens[scale] then
		self.Tweens[scale]:Cancel()
	end
	scale.Scale = amount or 1.055
	self:to(scale, 0.22, {Scale = 1}, Enum.EasingStyle.Back)
end

function Motion:button(button)
	button.AutoButtonColor = false
	local scale = button:FindFirstChild("FeedbackScale") or Instance.new("UIScale")
	scale.Name = "FeedbackScale"
	scale.Parent = button
	local hover, pressed = false, false
	local function refresh()
		local disabled = button:GetAttribute("UIDisabled") == true
		self:to(scale, 0.1, {Scale = disabled and 1 or pressed and 0.96 or hover and 1.035 or 1})
	end
	local function connect(signal, callback)
		table.insert(self.Connections, signal:Connect(callback))
	end
	connect(button.MouseEnter, function()
		hover = true
		refresh()
	end)
	connect(button.MouseLeave, function()
		hover, pressed = false, false
		refresh()
	end)
	connect(button.SelectionGained, function()
		hover = true
		refresh()
	end)
	connect(button.SelectionLost, function()
		hover, pressed = false, false
		refresh()
	end)
	connect(button.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA then
			pressed = true
			refresh()
		end
	end)
	connect(button.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA then
			pressed = false
			refresh()
		end
	end)
	connect(button:GetAttributeChangedSignal("UIDisabled"), refresh)
end

function Motion:destroy()
	self.Alive = false
	for _, tween in pairs(self.Tweens) do
		tween:Cancel()
	end
	for _, connection in ipairs(self.Connections) do
		connection:Disconnect()
	end
	table.clear(self.Tweens)
	table.clear(self.Connections)
end

return Motion
