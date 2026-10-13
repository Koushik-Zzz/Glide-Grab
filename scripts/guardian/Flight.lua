-- Bird motion, obstacle queries, swept hit math and wing poses. No egg ownership.
local Workspace = game:GetService("Workspace")
local Flight = {}
Flight.__index = Flight

function Flight.new(model, config)
	local self = setmetatable({}, Flight)
	self.Model, self.Config = model, config
	self.Position = config.HomePosition
	self.Facing = Vector3.new(0, 0, -1)
	self.Stuck = 0
	self.Query = RaycastParams.new()
	self.Query.FilterType = Enum.RaycastFilterType.Exclude
	self.Query.RespectCanCollide = true
	return self
end

function Flight:excludeCharacters(players)
	local excluded = {self.Model}
	for _, player in ipairs(players) do
		if player.Character then
			table.insert(excluded, player.Character)
		end
	end
	self.Query.FilterDescendantsInstances = excluded
end

function Flight:blocked(from, to)
	local delta = to - from
	return delta.Magnitude > 0.01 and Workspace:Spherecast(from, 2, delta, self.Query) or nil
end

function Flight:clipAtObstacle(goal)
	local hit = self:blocked(self.Position, goal)
	if not hit then return goal, false end
	local delta = goal - self.Position
	-- Keep the legal part of a fast step: it may hit a player before the floor.
	return self.Position + delta.Unit * math.max(0, hit.Distance - 0.05), true
end

function Flight:moveToward(goal, speed, dt)
	local delta = goal - self.Position
	if delta.Magnitude < 0.1 then
		return
	end
	local direction = delta.Unit
	local step = direction * math.min(delta.Magnitude, speed * dt)
	if self:blocked(self.Position, self.Position + step) then
		self.Stuck += dt
		step = Vector3.new(0, speed * dt, 0)
		if self:blocked(self.Position, self.Position + step) then
			return
		end
	else
		self.Stuck = 0
	end
	self.Position += step
	self.Facing = direction
end

function Flight:aimDash(root)
	-- Solve |offset + velocity * time| = dashSpeed * time. Predict steady
	-- flight at launch; changing direction afterward still defeats the straight dash.
	local offset = root.Position - self.Position
	local velocity = root.AssemblyLinearVelocity
	local speed = self.Config.DashSpeed
	local a = velocity:Dot(velocity) - speed * speed
	local b = 2 * offset:Dot(velocity)
	local c = offset:Dot(offset)
	local intercept = offset.Magnitude / speed
	if math.abs(a) < 0.001 then
		if b < -0.001 then
			intercept = -c / b
		end
	else
		local discriminant = b * b - 4 * a * c
		if discriminant >= 0 then
			local first = (-b - math.sqrt(discriminant)) / (2 * a)
			local second = (-b + math.sqrt(discriminant)) / (2 * a)
			if first > 0 then
				intercept = first
			end
			if second > 0 and (first <= 0 or second < first) then
				intercept = second
			end
		end
	end
	local lead = velocity * math.clamp(intercept, 0, self.Config.MaxLeadSeconds)
	if lead.Magnitude > self.Config.MaxLeadDistance then
		lead = lead.Unit * self.Config.MaxLeadDistance
	end
	local aim = root.Position + lead
	local delta = aim - self.Position
	local direction = delta.Magnitude > 0.1 and delta.Unit or self.Facing
	return self.Position, aim + direction * self.Config.DashOvershoot
end

function Flight.sweptDistance(a, b)
	local delta = b - a
	local t = delta:Dot(delta) > 0.0001 and math.clamp(-a:Dot(delta) / delta:Dot(delta), 0, 1) or 0
	return (a + delta * t).Magnitude
end

function Flight:pose(state, now)
	local pose = CFrame.lookAt(self.Position, self.Position + self.Facing)
	self.Model:PivotTo(pose)
	local flap = math.sin(now * (state == "Swoop" and 26 or 12)) * 0.3
	if state == "Windup" then
		flap = 0.7
	end
	if state == "Slap" then
		flap = -0.85
	end
	self.Model.LeftWing.CFrame = pose * CFrame.new(-2, 0.5, 0) * CFrame.Angles(0, 0, flap) * CFrame.new(-4, 0, 0)
	self.Model.RightWing.CFrame = pose * CFrame.new(2, 0.5, 0) * CFrame.Angles(0, 0, -flap) * CFrame.new(4, 0, 0)
end

return Flight
