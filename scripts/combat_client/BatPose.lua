-- Left-arm hold and swing, evaluated on every viewer. The server supplies the
-- held prop and accepted swing time; this module never decides hits or ownership.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local BatPose = {}

local function joint(c, name)
	local candidate = c:FindFirstChild(name, true)
	if candidate and (candidate:IsA("AnimationConstraint") or candidate:IsA("Motor6D")) then
		return candidate
	end
	return nil
end
local function ease(t)
	return t * t * (3 - 2 * t)
end
-- Pitch/yaw/roll for shoulder, elbow and wrist; windup, cross-body contact,
-- follow-through and return. The bat rotates with the hand at its handle.
local frames = {
	{Time = 0, Shoulder = Vector3.new(20, 0, -8), Elbow = 50, Wrist = -70},
	{Time = 0.08, Shoulder = Vector3.new(55, -40, -24), Elbow = 75, Wrist = -55},
	{Time = 0.16, Shoulder = Vector3.new(85, 45, 18), Elbow = 25, Wrist = -35},
	{Time = 0.27, Shoulder = Vector3.new(65, 70, 25), Elbow = 20, Wrist = -35},
	{Time = 0.55, Shoulder = Vector3.new(20, 0, -8), Elbow = 50, Wrist = -70},
}
local function sample(t)
	if t < 0 or t >= frames[#frames].Time then return frames[1] end
	for i = 2, #frames do
		local b, a = frames[i], frames[i - 1]
		if t <= b.Time then
			local alpha = ease((t - a.Time) / (b.Time - a.Time))
			return {
				Shoulder = a.Shoulder:Lerp(b.Shoulder, alpha),
				Elbow = a.Elbow + (b.Elbow - a.Elbow) * alpha,
				Wrist = a.Wrist + (b.Wrist - a.Wrist) * alpha,
			}
		end
	end
	return frames[1]
end
local function rotation(v)
	return CFrame.Angles(math.rad(v.X), math.rad(v.Y), math.rad(v.Z))
end

function BatPose.new()
	local records = {}
	local api = {}
	local function release(record)
		-- PreAnimation restores the last animator pose before the next evaluation,
		-- preventing offset accumulation when an animator is throttled.
		for j, base in pairs(record.Base) do
			if j.Parent then
				j.Transform = base
			end
		end
		table.clear(record.Base)
	end
	local preAnimation = RunService.PreAnimation:Connect(function()
		for _, record in pairs(records) do
			release(record)
		end
	end)
	local preSimulation = RunService.PreSimulation:Connect(function()
		for _, p in ipairs(Players:GetPlayers()) do
			local c = p.Character
			local r = records[p]
			if r and r.Character ~= c then
				release(r)
				records[p] = nil
				r = nil
			end
			local held = c and c:FindFirstChild("HeldBat")
			local h = c and c:FindFirstChildOfClass("Humanoid")
			local enabled = held and h and h.Health > 0 and not p:GetAttribute("PortalTraveling")
				and Workspace:GetServerTimeNow() >= math.max(c:GetAttribute("CombatStunnedUntil") or 0,
					c:GetAttribute("GuardianKnockbackUntil") or 0)
			if not enabled then
				if r then
					release(r)
				end
				continue
			end
			if not r then
				r = {Character = c, Base = {}, Shoulder = joint(c, "LeftShoulder") or joint(c, "Left Shoulder"),
					Elbow = joint(c, "LeftElbow"), Wrist = joint(c, "LeftWrist")}
				records[p] = r
			end
			if not r.Shoulder or not r.Shoulder.Parent then
				r.Shoulder = joint(c, "LeftShoulder") or joint(c, "Left Shoulder")
				r.Elbow, r.Wrist = joint(c, "LeftElbow"), joint(c, "LeftWrist")
			end
			local pose = sample(Workspace:GetServerTimeNow() - (c:GetAttribute("BatSwingStartedAt") or -math.huge))
			local function apply(j, angles)
				if not j or not j.Parent then return end
				r.Base[j] = j.Transform
				-- Resolve the joint's attachment axes (also supports the R6 shoulder).
				j.Transform = CFrame.new(j.Transform.Position)
					* j.C0.Rotation:Inverse() * rotation(angles) * j.C1.Rotation
			end
			if h.RigType == Enum.HumanoidRigType.R6 then
				apply(r.Shoulder, pose.Shoulder + Vector3.new(45, 0, 0))
				local grip = held.PrimaryPart and held.PrimaryPart:FindFirstChild("BatGrip")
				if grip then
				r.Base[grip] = grip.Transform
				grip.Transform = rotation(Vector3.new(-65, 0, 0))
			end
			else
				apply(r.Shoulder, pose.Shoulder)
				apply(r.Elbow, Vector3.new(pose.Elbow, 0, 0))
				apply(r.Wrist, Vector3.new(pose.Wrist, 0, 0))
			end
		end
	end)
	local removing = Players.PlayerRemoving:Connect(function(p)
		if records[p] then
			release(records[p])
		end
		records[p] = nil
	end)
	function api:destroy()
		preAnimation:Disconnect()
		preSimulation:Disconnect()
		removing:Disconnect()
		for _, record in pairs(records) do
			release(record)
		end
		table.clear(records)
	end
	return api
end
return BatPose
