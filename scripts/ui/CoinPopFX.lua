-- Confirmed wallet deltas only. A bounded pool; no currency writes or idle render loop.
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local Theme = require(script.Parent.Theme)
local FX = {}
FX.__index = FX
function FX.new(canvas, amount)
	local self = setmetatable({Canvas = canvas, Amount = amount, Pool = {}, Pending = 0, Alive = true}, FX)
	local template = RS:WaitForChild("UIAssets"):WaitForChild("Reward")
	for i = 1, 6 do
		local label = template:Clone()
		label.Name, label.Parent = "CoinPop" .. i, canvas
		self.Pool[i] = {Label = label, Version = 0, Tweens = {}}
	end
	self.Next = 0
	return self
end
function FX:emit(gain)
	self.Next = self.Next % #self.Pool + 1
	local slot = self.Pool[self.Next]
	for _, tween in slot.Tweens do tween:Cancel() end
	slot.Tweens = {}
	slot.Version += 1
	local version, label = slot.Version, slot.Label
	local relative = self.Amount.AbsolutePosition - self.Canvas.AbsolutePosition
	local size = self.Amount.AbsoluteSize
	local x = math.clamp(relative.X + size.X / 2 - 72, 4, math.max(4, self.Canvas.AbsoluteSize.X - 150))
	local y = math.max(4, relative.Y - 27)
	local reduced = GuiService.ReducedMotionEnabled
	label.Text = "+$" .. Theme.short(gain)
	label.Position = UDim2.fromOffset(x, y)
	label.TextTransparency, label.Outline.Transparency, label.Visible = 0, 0, true
	label.Pop.Scale = reduced and 1 or 0.75
	local function tween(object, seconds, properties, style)
		local t = TweenService:Create(object, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
		table.insert(slot.Tweens, t)
		t:Play()
	end
	if not reduced then
		tween(label.Pop, 0.2, {Scale = 1.12}, Enum.EasingStyle.Back)
		tween(label, 0.25, {Position = UDim2.fromOffset(x + math.random(-15, 15), math.max(2, y - 15))})
	end
	task.delay(0.25, function()
		if not self.Alive or version ~= slot.Version then return end
		tween(label.Pop, 0.18, {Scale = 1})
		tween(label, 0.5, {TextTransparency = 1})
		tween(label.Outline, 0.5, {Transparency = 1})
	end)
	task.delay(0.8, function()
		if self.Alive and slot.Version == version then label.Visible = false end
	end)
end
function FX:reward(gain)
	self.Pending += gain
	if self.Scheduled then return end
	self.Scheduled = true
	task.delay(0.12, function()
		if not self.Alive then return end
		local total = self.Pending
		self.Pending, self.Scheduled = 0, false
		self:emit(total)
	end)
end
function FX:destroy()
	self.Alive = false
	for _, slot in self.Pool do
		for _, tween in slot.Tweens do tween:Cancel() end
		slot.Label:Destroy()
	end
end
return FX
