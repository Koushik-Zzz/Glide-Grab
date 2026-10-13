-- Server-owned gust timing and eligibility. The glider consumes the wind target.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local meadow = Workspace:WaitForChild("Map"):WaitForChild("Meadow")
local zone = meadow:WaitForChild("WindGust", 10)
assert(zone and zone:IsA("BasePart"), "Create Meadow/WindGust with MeadowFun.studio.lua")

local function duration(name, fallback)
	local value = zone:GetAttribute(name)
	if type(value) ~= "number" or value ~= value then return fallback end
	return math.clamp(value, 1, 30)
end
local calm = duration("CalmSeconds", 5)
local warning = duration("WarningSeconds", 1.5)
local gust = duration("GustSeconds", 2.4)
local wind = zone:GetAttribute("WindVelocity")
if typeof(wind) ~= "Vector3" or wind.Magnitude ~= wind.Magnitude then
	wind = Vector3.new(64, 0, 0)
end
if wind.Magnitude > 80 then
	wind = wind.Unit * 80
end
local cycle = calm + warning + gust
local started = Workspace:GetServerTimeNow()
local lastPhase = nil
local sign = zone:WaitForChild("WindSign"):WaitForChild("Status")

local function setWind(player, velocity, state)
	if player:GetAttribute("MeadowWindVelocity") ~= velocity then
		player:SetAttribute("MeadowWindVelocity", velocity)
	end
	if player:GetAttribute("MeadowWindState") ~= state then
		player:SetAttribute("MeadowWindState", state)
	end
end

local function bindPlayer(player)
	setWind(player, Vector3.zero, "")
	player.CharacterRemoving:Connect(function()
		setWind(player, Vector3.zero, "")
	end)
end
Players.PlayerAdded:Connect(bindPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	bindPlayer(player)
end

while zone.Parent do
	local now = Workspace:GetServerTimeNow()
	local elapsed = (now - started) % cycle
	local phase, remaining
	if elapsed < calm then
		phase, remaining = "Calm", calm - elapsed
	elseif elapsed < calm + warning then
		phase, remaining = "Warning", calm + warning - elapsed
	else
		phase, remaining = "Gust", cycle - elapsed
	end
	if phase ~= lastPhase then
		zone:SetAttribute("Phase", phase)
		zone:SetAttribute("NextChangeTime", now + remaining)
		lastPhase = phase
	end
	local text = phase == "Gust" and "CROSSWIND  →\nSteer against it or fly around"
		or phase == "Warning" and ("GUST IN " .. math.ceil(remaining) .. "\nGet ready to steer!")
		or ("CALM FOR " .. math.ceil(remaining) .. "\nClear to cross")
	if sign.Text ~= text then
		sign.Text = text
	end
	local half = zone.Size / 2
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local velocity, state = Vector3.zero, ""
		if root and humanoid and humanoid.Health > 0 and not root.Anchored
			and player:GetAttribute("CurrentBiome") == "Meadow"
			and not player:GetAttribute("PortalTraveling") then
			local point = zone.CFrame:PointToObjectSpace(root.Position)
			local edge = math.min(half.X - math.abs(point.X), half.Y - math.abs(point.Y), half.Z - math.abs(point.Z))
			if edge > -50 then
				state = phase
			end
			if edge > 0 and phase == "Gust" then
				-- Feather the edge; there is no damage or egg loss in the starter biome.
				local attack = math.clamp((gust - remaining) / 0.2, 0, 1)
				local release = math.clamp(remaining / 0.4, 0, 1)
				velocity = wind * math.min(attack, release) * math.clamp(edge / 8, 0, 1)
			end
		end
		setWind(player, velocity, state)
	end
	task.wait(0.1)
end
for _, player in ipairs(Players:GetPlayers()) do
	setWind(player, Vector3.zero, "")
end
