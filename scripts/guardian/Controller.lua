-- Pursuit state machine and server-authoritative egg hits. Motion and slap physics
-- live in their own modules so behavior can be changed without rereading both.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Config = require(script.Parent.Config)
local Flight = require(script.Parent.Flight)
local Knockback = require(script.Parent.Knockback)
local Controller = {}

function Controller.start(ownerScript)
	local meadow = Workspace:WaitForChild("Map"):WaitForChild("Meadow")
	local bird = meadow:WaitForChild("NestGuardian", 10)
	assert(bird and bird:IsA("Model"), "Create Meadow/NestGuardian with the Edit-mode setup")
	assert(not bird:GetAttribute("GuardianRunning"), "Keep only one NestGuardian server entry script")
	local catchEgg = ownerScript.Parent:WaitForChild("EggLoop"):WaitForChild("GuardianCatch")
	local config = Config.fromModel(bird)
	local flight = Flight.new(bird, config)
	local knockback = Knockback.new(config)
	local sign = bird.Body.GuardianSign.Status
	local originalColor = bird.Body.Color
	local state, deadline = "Patrol", 0
	local target, cargo, root = nil, nil, nil
	local dashStart, dashEnd, previousRoot = Vector3.zero, Vector3.zero, Vector3.zero
	local dashStarted, dashDuration = 0, 1
	local noticeVersions, characterConnections, connections = {}, {}, {}
	local running = true
	bird:SetAttribute("GuardianRunning", true)

	local function notice(player, text)
		if player and player.Parent == Players then
			noticeVersions[player] = (noticeVersions[player] or 0) + 1
			player:SetAttribute("GuardianMessage", text)
		end
	end
	local messages = {
		Alert = "Guardian spotted you! Fly away!",
		Chase = "Guardian closing in — keep flying!",
		Windup = "Wings up! Get ready to turn!",
		Swoop = "DODGE! Make a sharp turn!",
		Recover = "It missed! Keep flying away!",
	}
	local function transition(nextState, duration)
		state = nextState
		if state == "Return" then
			flight:beginReturn()
			duration = config.ReturnTimeout
		end
		deadline = Workspace:GetServerTimeNow() + (duration or 0)
		bird:SetAttribute("State", state)
		bird.Body.Color = state == "Windup" and Color3.fromRGB(255, 185, 65) or originalColor
		sign.Text = state == "Patrol" and "NEST GUARDIAN\nTake the egg... then fly!"
			or state == "Return" and "RETURNING TO NEST"
			or state == "Windup" and "! WING SLAP !" or string.upper(state)
		if messages[state] then
			notice(target, messages[state])
		end
	end
	local function finish(message, slapped)
		local oldTarget = target
		notice(oldTarget, message or "")
		if oldTarget then
			local version = noticeVersions[oldTarget]
			task.delay(2.5, function()
				if running and oldTarget.Parent == Players and target ~= oldTarget
					and noticeVersions[oldTarget] == version then
					notice(oldTarget, "")
				end
			end)
		end
		target, cargo, root = nil, nil, nil
		flight.Stuck = 0
		transition(slapped and "Slap" or "Return", 0.24)
	end
	local function validTarget()
		local character = target and target.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		return target and target.Parent == Players and character and cargo.Parent == character
			and root.Parent == character and humanoid and humanoid.Health > 0
			and not root.Anchored and target:GetAttribute("CurrentBiome") == "Meadow"
			and not target:GetAttribute("PortalTraveling")
	end

	local function acquireTarget(requireClearApproach)
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local egg = character and character:FindFirstChild("CarriedEgg")
			local candidateRoot = character and character:FindFirstChild("HumanoidRootPart")
			if egg and candidateRoot and egg:GetAttribute("EggName") == "Uncommon Egg"
				and (candidateRoot.Position - config.HomePosition).Magnitude < config.LeashRadius
				and (not requireClearApproach or not flight:blocked(flight.Position, candidateRoot.Position)) then
				target, cargo, root = player, egg, candidateRoot
				if validTarget() then
					transition("Alert", config.AlertSeconds)
					return true
				else
					target, cargo, root = nil, nil, nil
				end
			end
		end
		return false
	end

	local handlers = {}
	handlers.Patrol = function(now, dt)
		flight:moveToward(config.HomePosition + Vector3.new(math.cos(now * 0.65) * 18,
			math.sin(now) * 2, math.sin(now * 0.65) * 18), config.PatrolSpeed, dt)
		acquireTarget()
	end
	handlers.Alert = function(now)
		if now >= deadline then
			transition("Chase")
		end
	end
	handlers.Chase = function(_, dt)
		if (root.Position - flight.Position).Magnitude < config.AttackRange
			and not flight:blocked(flight.Position, root.Position) then
			transition("Windup", config.WarningSeconds)
		else
			flight:moveToward(root.Position + Vector3.new(0, 8, 0), config.ChaseSpeed, dt)
			if flight.Stuck > 2 then
				flight.Stuck = 0
				transition("Recover", config.RecoverSeconds)
			end
		end
	end
	handlers.Windup = function(now)
		local delta = root.Position - flight.Position
		if delta.Magnitude > 0.1 then
			flight.Facing = delta.Unit
		end
		if now < deadline then
			return
		end
		if flight:blocked(flight.Position, root.Position) then
			transition("Recover", config.RecoverSeconds)
			return
		end
		-- Commit at launch, not when the warning begins. After launch a deliberate
		-- turn can evade the straight dash; tiny pre-launch movements cannot fool it.
		dashStart, dashEnd = flight:aimDash(root)
		dashStarted = now
		dashDuration = math.max(0.12, (dashEnd - dashStart).Magnitude / config.DashSpeed)
		previousRoot = root.Position
		transition("Swoop")
	end
	handlers.Swoop = function(now)
		local fraction = math.clamp((now - dashStarted) / dashDuration, 0, 1)
		local nextPosition, obstructed = flight:clipAtObstacle(dashStart:Lerp(dashEnd, fraction))
		local distance = Flight.sweptDistance(flight.Position - previousRoot, nextPosition - root.Position)
		if distance < config.HitRadius and not flight:blocked(nextPosition, root.Position) then
			if catchEgg:Invoke(target, cargo) then
				knockback:apply(target, root, dashStart, flight.Facing)
				flight.Position = nextPosition
				finish("SLAP! Knocked back — egg gone!", true)
			else
				finish("")
			end
			return
		end
		previousRoot = root.Position
		flight.Facing = (dashEnd - dashStart).Unit
		flight.Position = nextPosition
		if obstructed or fraction >= 1 then
			transition("Recover", config.RecoverSeconds)
		end
	end
	handlers.Recover = function(now, dt)
		flight:moveToward(flight.Position + Vector3.new(0, 5, 0), 14, dt)
		if now >= deadline then
			transition("Chase")
		end
	end
	handlers.Slap = function(now)
		if now >= deadline then
			transition("Return")
		end
	end
	handlers.Return = function(now, dt)
		-- Finish the escape from an overhang before chasing a carrier behind it.
		if acquireTarget(true) then return end
		if flight:returnHome(dt) or (now >= deadline and flight:recoverHome()) then
			transition("Patrol")
		end
	end

	local function bind(player)
		notice(player, "")
		characterConnections[player] = player.CharacterRemoving:Connect(function()
			knockback:clear(player)
			if target == player then
				finish("")
			end
			notice(player, "")
		end)
	end
	local function cleanup()
		if not running then
			return
		end
		running = false
		knockback:destroy()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		for player, connection in pairs(characterConnections) do
			connection:Disconnect()
			notice(player, "")
		end
		bird:SetAttribute("GuardianRunning", nil)
		bird.Body.Color = originalColor
	end
	table.insert(connections, Players.PlayerAdded:Connect(bind))
	for _, player in ipairs(Players:GetPlayers()) do
		bind(player)
	end
	table.insert(connections, Players.PlayerRemoving:Connect(function(player)
		knockback:clear(player)
		if target == player then
			finish("")
		end
		if characterConnections[player] then
			characterConnections[player]:Disconnect()
		end
		characterConnections[player], noticeVersions[player] = nil, nil
	end))
	table.insert(connections, ownerScript.Destroying:Connect(cleanup))
	transition("Patrol")
	local last = Workspace:GetServerTimeNow()
	while running and bird.Parent and ownerScript.Parent do
		local now = Workspace:GetServerTimeNow()
		local dt = math.min(now - last, 0.1)
		last = now
		flight:excludeCharacters(Players:GetPlayers())
		if target then
			if not validTarget() then finish("")
			elseif state ~= "Swoop" and (root.Position - config.HomePosition).Magnitude > config.LeashRadius then
				-- Finish an already-launched slap; the territory edge must not cancel
				-- it immediately before contact. Misses still release escaped targets.
				finish("Escaped! Take your egg back to camp.")
			end
		end
		handlers[state](now, dt)
		flight:pose(state, now)
		task.wait(1 / 30)
	end
	cleanup()
end

return Controller
