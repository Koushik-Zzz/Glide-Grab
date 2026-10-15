-- Shared server eligibility; clients never choose targets, damage or transfer results.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Config = require(script.Parent.Config)
local Profiles = require(script.Parent.Parent:WaitForChild("DataModules"):WaitForChild("Profiles"))
local Rules = {}
local grace = {}
local function bind(p)
	local function update()
		if p:GetAttribute("CurrentBiome") == "Meadow" or p:GetAttribute("CurrentBiome") == "Storm Isles" then
			grace[p] = Workspace:GetServerTimeNow() + Config.ArrivalGrace
		end
	end
	p:GetAttributeChangedSignal("CurrentBiome"):Connect(update)
	update()
end
Players.PlayerAdded:Connect(bind)
Players.PlayerRemoving:Connect(function(p)
	grace[p] = nil
end)
for _, p in ipairs(Players:GetPlayers()) do
	bind(p)
end
function Rules.living(p)
	local c = p.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	local root = c and c:FindFirstChild("HumanoidRootPart")
	if not Profiles.get(p) or p.Parent ~= Players or not h or h.Health <= 0 or not root or root.Anchored
		or p:GetAttribute("PortalTraveling") then return nil end
	return c, h, root
end
function Rules.allowed(p, allowStunned)
	local c, h, root = Rules.living(p)
	local biome = p:GetAttribute("CurrentBiome")
	if not c or (biome ~= "Meadow" and biome ~= "Storm Isles") then return nil end
	local now = Workspace:GetServerTimeNow()
	if now < (c:GetAttribute("GuardianKnockbackUntil") or 0) then return nil end
	if now < (grace[p] or 0) or (not allowStunned and now < (c:GetAttribute("CombatStunnedUntil") or 0)) then return nil end
	local entrance = biome == "Storm Isles" and Workspace.Map.StormIsles.StormEntrance or Workspace.Map.Meadow.MeadowEntrance
	if not ((root.Position - entrance.Position).Magnitude > Config.SafeRadius) then return nil end
	return c, h, root
end
local function params(exclude)
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	p.FilterDescendantsInstances = exclude
	p.RespectCanCollide = true
	return p
end
function Rules.airborne(c, root)
	local glider = c:FindFirstChild("Glider")
	return glider and glider:IsA("Tool") and glider:GetAttribute("IsGliding") == true
		and Workspace:Raycast(root.Position, Vector3.new(0, -Config.AirClearance, 0), params({c})) == nil
end
function Rules.facing(c, root)
	local v = Rules.airborne(c, root) and root.AssemblyLinearVelocity or root.CFrame.LookVector
	local flat = v * Vector3.new(1, 0, 1)
	if flat.Magnitude < 0.2 then
		flat = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	end
	if flat.Magnitude < 0.2 then
		flat = root.CFrame.UpVector * Vector3.new(1, 0, 1)
	end
	return flat.Magnitude > 0.2 and flat.Unit or Vector3.new(0, 0, -1)
end
function Rules.pair(attacker, victim, range, airOnly)
	if attacker == victim then return nil end
	local a, _, ar = Rules.allowed(attacker, false)
	local b, _, br = Rules.allowed(victim, true)
	if not a or not b then return nil end
	if attacker:GetAttribute("CurrentBiome") ~= victim:GetAttribute("CurrentBiome") then return nil end
	local difference = br.Position - ar.Position
	local distance = difference.Magnitude
	if not (distance > 0.05 and distance <= range) then return nil end
	local flat = difference * Vector3.new(1, 0, 1)
	if flat.Magnitude > 0.2 and flat.Unit:Dot(Rules.facing(a, ar)) < 0.15 then return nil end
	if airOnly and (not Rules.airborne(a, ar) or not Rules.airborne(b, br)) then return nil end
	if Workspace:Raycast(ar.Position, difference, params({a, b})) then return nil end
	return ar, br, distance
end
function Rules.target(attacker, range, airOnly, predicate)
	local best, distance = nil, math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		local _, _, d = Rules.pair(attacker, p, range, airOnly)
		if d and d < distance and (not predicate or predicate(p)) then
			best, distance = p, d
		end
	end
	return best
end
return Rules
