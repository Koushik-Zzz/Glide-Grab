-- Bird motion, obstacle queries, swept hit math and wing poses. No egg ownership.
local Workspace = game:GetService("Workspace")
local Appearance = require(script.Parent.Appearance)
local Flight = {}
Flight.__index = Flight

function Flight.new(model, config)
	local self = setmetatable({}, Flight)
	self.Model, self.Config = model, config
	self.Appearance = Appearance.new(model)
	self.Position = config.HomePosition
	self.Facing = Vector3.new(0, 0, -1)
	self.Stuck = 0
	self.Query = RaycastParams.new()
	self.Query.FilterType = Enum.RaycastFilterType.Exclude
	self.Query.RespectCanCollide = true
	self.ClearanceQuery = OverlapParams.new()
	self.ClearanceQuery.FilterType = Enum.RaycastFilterType.Exclude
	self.ClearanceQuery.RespectCanCollide = true
	self.ClearanceQuery.MaxParts = 1
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
	self.ClearanceQuery.FilterDescendantsInstances = excluded
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
	return self.Position + delta.Unit * math.max(0, hit.Distance - 0.35), true
end

function Flight:moveToward(goal, speed, dt)
	local delta = goal - self.Position
	if delta.Magnitude < 0.1 then
		return
	end
	local direction = delta.Unit
	local step = direction * math.min(delta.Magnitude, speed * dt)
	local hit = self:blocked(self.Position, self.Position + step)
	if hit then
		self.Stuck += dt
		local outward = Vector3.new(hit.Normal.X, 0, hit.Normal.Z)
		local slide = direction - hit.Normal * math.min(0, direction:Dot(hit.Normal))
		local alternatives = {Vector3.yAxis, outward + Vector3.yAxis * 0.35, slide + hit.Normal * 0.35}
		local found = false
		for _, candidate in ipairs(alternatives) do
			if candidate.Magnitude > 0.1 then
				local alternative = candidate.Unit * speed * dt
				if not self:blocked(self.Position, self.Position + alternative) then
					step, found = alternative, true
					break
				end
			end
		end
		if not found then return end
	else
		self.Stuck = 0
	end
	self.Position += step
	self.Facing = direction
end

function Flight:beginReturn()
	self.ReturnExit = nil
	self.ReturnHeight = math.max(self.Position.Y, self.Config.HomePosition.Y) + self.Config.ReturnClearance
	self.ReturnStage = "Rise"
end

function Flight:findReturnExit()
	local best, bestScore = nil, -math.huge
	-- Look around a roof rather than repeatedly trying to fly through its underside.
	-- Probe only when planning a detour; cache the chosen waypoint until reached.
	for index = 0, 7 do
		local angle = index * math.pi / 4
		local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local hit = self:blocked(self.Position, self.Position + direction * 72)
		local distance = hit and math.max(0, hit.Distance - 0.35) or 72
		if distance > 4 then
			local candidate = self.Position + direction * distance
			local above = Vector3.new(candidate.X, self.ReturnHeight, candidate.Z)
			local clearUp = not self:blocked(candidate, above)
			local score = (clearUp and 1000 or 0) + distance
				- (candidate - self.Config.HomePosition).Magnitude * 0.1
			if score > bestScore then
				best, bestScore = candidate, score
			end
		end
	end
	return best
end

function Flight:returnHome(dt)
	local home = self.Config.HomePosition
	if self.ReturnStage == "Rise" then
		if self.ReturnExit then
			self:moveToward(self.ReturnExit, self.Config.ReturnSpeed, dt)
			if (self.Position - self.ReturnExit).Magnitude < 3 or self.Stuck > 0.5 then
				self.ReturnExit = nil
				self.Stuck = 0
			end
		elseif self.Position.Y < self.ReturnHeight - 1 then
			local above = Vector3.new(self.Position.X, self.ReturnHeight, self.Position.Z)
			if self:blocked(self.Position, above) then
				self.ReturnExit = self:findReturnExit()
			end
			if not self.ReturnExit then
				self:moveToward(above, self.Config.ReturnSpeed, dt)
			end
		else
			self.ReturnStage = "Cross"
		end
	elseif self.ReturnStage == "Cross" then
		local aboveHome = Vector3.new(home.X, self.ReturnHeight, home.Z)
		self:moveToward(aboveHome, self.Config.ReturnSpeed, dt)
		if (self.Position - aboveHome).Magnitude < 3 then
			self.ReturnStage = "Descend"
		end
	else
		self:moveToward(home, self.Config.ReturnSpeed, dt)
	end
	return (self.Position - home).Magnitude < 3
end

function Flight:recoverHome()
	-- Last resort for an enclosed/trapped return. Never used during an attack;
	-- only reset to an unoccupied nest-area position, not through a wall to a player.
	for _, lift in ipairs({0, 16, 32, 64}) do
		local candidate = self.Config.HomePosition + Vector3.yAxis * lift
		if #Workspace:GetPartBoundsInRadius(candidate, 2.35, self.ClearanceQuery) == 0 then
			self.Position, self.Stuck, self.ReturnExit = candidate, 0, nil
			return true
		end
	end
	return false
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
	self.Appearance:pose(pose, state, now)
end

return Flight
