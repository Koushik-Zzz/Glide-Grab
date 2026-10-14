-- Temporary physical slap effects and cleanup. Hits and egg loss are decided by Controller.
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local combatModules = script.Parent.Parent:FindFirstChild("CombatModules")
local CombatImpact = combatModules and require(combatModules:WaitForChild("Impact"))
local Knockback = {}
Knockback.__index = Knockback

function Knockback.new(config)
	return setmetatable({Config = config, Active = {}}, Knockback)
end

function Knockback:clear(player)
	local record = self.Active[player]
	if not record then return end
	self.Active[player] = nil
	record.Velocity:Destroy()
	record.Attachment:Destroy()
	if record.Character.Parent then
		record.Character:SetAttribute("GuardianKnockbackUntil", nil)
	end
end

function Knockback:apply(player, hitRoot, origin, facing)
	self:clear(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or hitRoot.Parent ~= character or hitRoot.Anchored
		or not humanoid or humanoid.Health <= 0 then return end
	-- A guardian slap takes over physical motion from an existing player stun.
	if CombatImpact then
		CombatImpact.clear(player)
	end
	local away = (hitRoot.Position - origin) * Vector3.new(1, 0, 1)
	if away.Magnitude < 0.1 then
		away = facing * Vector3.new(1, 0, 1)
	end
	if away.Magnitude < 0.1 then
		away = Vector3.new(0, 0, 1)
	end
	local kick = away.Unit * self.Config.KnockbackSpeed + Vector3.new(0, self.Config.KnockbackLift, 0)
	local duration = self.Config.KnockbackSeconds
	local untilTime = Workspace:GetServerTimeNow() + duration
	-- Character-scoped deadline lets the glider yield its movement force. Normal
	-- character network ownership remains automatic; egg loss is server-authoritative.
	character:SetAttribute("GuardianKnockbackUntil", untilTime)
	local attachment = Instance.new("Attachment")
	attachment.Name = "GuardianSlapAttachment"
	attachment.Parent = hitRoot
	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "GuardianSlapVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.ForceLimitsEnabled = true
	velocity.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	velocity.MaxForce = hitRoot.AssemblyMass * 4000
	velocity.VectorVelocity = kick
	velocity.Parent = hitRoot
	local record = {Character = character, Attachment = attachment, Velocity = velocity}
	self.Active[player] = record
	local flash = Instance.new("Highlight")
	flash.Name = "GuardianSlapFlash"
	flash.Adornee = character
	flash.DepthMode = Enum.HighlightDepthMode.Occluded
	flash.FillColor = Color3.fromRGB(255, 190, 95)
	flash.OutlineColor = Color3.fromRGB(255, 246, 220)
	flash.FillTransparency = 0.35
	flash.OutlineTransparency = 0.15
	flash.Parent = character
	TweenService:Create(flash, TweenInfo.new(0.25), {FillTransparency = 1, OutlineTransparency = 1}):Play()
	Debris:AddItem(flash, 0.3)
	task.spawn(function()
		while self.Active[player] == record and Workspace:GetServerTimeNow() < untilTime do
			if player.Character ~= character or not hitRoot.Parent or hitRoot.Anchored
				or humanoid.Health <= 0 or player:GetAttribute("PortalTraveling") then break end
			local remaining = math.clamp((untilTime - Workspace:GetServerTimeNow()) / duration, 0, 1)
			velocity.VectorVelocity = kick * (0.45 + 0.55 * remaining)
			task.wait(1 / 30)
		end
		if self.Active[player] == record then
			self:clear(player)
		end
	end)
end

function Knockback:destroy()
	for player in pairs(self.Active) do
		self:clear(player)
	end
end

return Knockback
