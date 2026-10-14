-- Character-scoped stun, modern velocity constraint, and restoration on interruption.
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local Impact = {}
local active = {}
function Impact.clear(p)
	local r = active[p]
	if not r then return end
	active[p] = nil
	r.Velocity:Destroy()
	r.Attachment:Destroy()
	if r.Character.Parent then
		r.Character:SetAttribute("CombatStunnedUntil", nil)
		r.Character:SetAttribute("CombatKnockbackUntil", nil)
		if r.Humanoid.Parent then
			r.Humanoid.WalkSpeed, r.Humanoid.JumpPower, r.Humanoid.JumpHeight = r.WalkSpeed, r.JumpPower, r.JumpHeight
		end
	end
end
function Impact.apply(p, origin, settings)
	Impact.clear(p)
	local c = p.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	local root = c and c:FindFirstChild("HumanoidRootPart")
	if not h or h.Health <= 0 or not root or root.Anchored then return false end
	local direction = (root.Position - origin) * Vector3.new(1, 0, 1)
	if direction.Magnitude < 0.1 then
		direction = Vector3.zAxis
	end
	local untilTime = Workspace:GetServerTimeNow() + settings.Stun
	local attachment = Instance.new("Attachment")
	attachment.Name = "CombatImpactAttachment"
	attachment.Parent = root
	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "CombatImpactVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.ForceLimitsEnabled = true
	velocity.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	velocity.MaxForce = root.AssemblyMass * 4000
	velocity.VectorVelocity = direction.Unit * settings.Push + Vector3.yAxis * settings.Lift
	velocity.Parent = root
	local r = {Character = c, Humanoid = h, Attachment = attachment, Velocity = velocity,
		WalkSpeed = h.WalkSpeed, JumpPower = h.JumpPower, JumpHeight = h.JumpHeight}
	active[p] = r
	h.WalkSpeed, h.JumpPower, h.JumpHeight = 0, 0, 0
	c:SetAttribute("CombatStunnedUntil", untilTime)
	c:SetAttribute("CombatKnockbackUntil", untilTime)
	local flash = Instance.new("Highlight")
	flash.Name = "CombatHitFlash"
	flash.Adornee = c
	flash.FillColor = Color3.fromRGB(255, 195, 90)
	flash.FillTransparency = 0.4
	flash.OutlineTransparency = 1
	flash.Parent = c
	Debris:AddItem(flash, 0.25)
	task.spawn(function()
		local start = Workspace:GetServerTimeNow()
		while active[p] == r and Workspace:GetServerTimeNow() < untilTime do
			if p.Character ~= c or h.Health <= 0 or root.Anchored or not root.Parent or p:GetAttribute("PortalTraveling") then
				break
			end
			local t = math.clamp((Workspace:GetServerTimeNow() - start) / settings.Stun, 0, 1)
			-- A decaying lift/velocity keeps the brief stun readable during flight.
			velocity.VectorVelocity = (direction.Unit * settings.Push + Vector3.yAxis * settings.Lift) * (1 - 0.75 * t)
			task.wait(1 / 30)
		end
		if active[p] == r then
			Impact.clear(p)
		end
	end)
	return true
end
return Impact
