-- Imported art is a skin of the guardian, independent of AI/egg ownership.
local Appearance = {}
Appearance.__index = Appearance

function Appearance.new(model)
	local self = setmetatable({Model = model, Body = model.Body}, Appearance)
	self.OriginalColor = self.Body.Color
	local visual = model:FindFirstChild("Visual")
	if visual then
		self.Flash = visual:FindFirstChild("AttackFlash")
		self.Wings = {}
		for _, part in ipairs(visual:GetDescendants()) do
			local side = part:GetAttribute("WingSide")
			local hinge = part:FindFirstChild("WingHinge")
			if part:IsA("BasePart") and type(side) == "number" and hinge then
				table.insert(self.Wings, {
					Part = part, Side = side, Hinge = hinge.CFrame,
					RestHinge = part:GetAttribute("WingRestHinge") or model:GetPivot():ToObjectSpace(part.CFrame * hinge.CFrame),
				})
			end
		end
	end
	return self
end

function Appearance:setState(state)
	if self.Flash then
		self.Flash.Enabled = state == "Windup"
	else
		self.Body.Color = state == "Windup" and Color3.fromRGB(255, 185, 65) or self.OriginalColor
	end
end

function Appearance:pose(pose, state, now)
	local flap = math.sin(now * (state == "Swoop" and 26 or 12)) * 0.22
	if self.Wings then
		-- Folded source wings rotate around authored shoulders, not their centers.
		local spread = state == "Windup" and 1.4 or state == "Slap" and 0.15 or 0.95 + flap
		for _, wing in ipairs(self.Wings) do
			wing.Part.CFrame = pose * wing.RestHinge
				* CFrame.Angles(0, 0, wing.Side * spread) * wing.Hinge:Inverse()
		end
	else
		-- Support the archived primitive bird for development fixtures.
		if state == "Windup" then
			flap = 0.7
		end
		if state == "Slap" then
			flap = -0.85
		end
		self.Model.LeftWing.CFrame = pose * CFrame.new(-2, 0.5, 0) * CFrame.Angles(0, 0, flap) * CFrame.new(-4, 0, 0)
		self.Model.RightWing.CFrame = pose * CFrame.new(2, 0.5, 0) * CFrame.Angles(0, 0, -flap) * CFrame.new(4, 0, 0)
	end
end

function Appearance:destroy()
	self.Body.Color = self.OriginalColor
	if self.Flash then
		self.Flash.Enabled = false
	end
end

return Appearance
