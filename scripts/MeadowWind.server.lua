-- Each biome owns one authored gust volume. Existing glider attributes are shared.
local Players = game:GetService("Players")
local W = workspace
local zones = {}
for biome, folder in pairs({Meadow = "Meadow", ["Storm Isles"] = "StormIsles"}) do
	local zone = W:WaitForChild("Map"):WaitForChild(folder):WaitForChild("WindGust")
	local function duration(name, fallback)
		local value = zone:GetAttribute(name)
		return type(value) == "number" and value == value and math.clamp(value, 1, 30) or fallback
	end
	local wind = zone:GetAttribute("WindVelocity")
	if typeof(wind) ~= "Vector3" or wind.Magnitude ~= wind.Magnitude then
		wind = Vector3.new(64, 0, 0)
	end
	if wind.Magnitude > 80 then
		wind = wind.Unit * 80
	end
	zones[biome] = {Zone = zone, Calm = duration("CalmSeconds", 5), Warning = duration("WarningSeconds", 1.5),
		Gust = duration("GustSeconds", 2.4), Wind = wind, Sign = zone.WindSign.Status}
end
local started = W:GetServerTimeNow()
local function setWind(player, velocity, state)
	if player:GetAttribute("MeadowWindVelocity") ~= velocity then
		player:SetAttribute("MeadowWindVelocity", velocity)
	end
	if player:GetAttribute("MeadowWindState") ~= state then
		player:SetAttribute("MeadowWindState", state)
	end
end
local function bind(player)
	setWind(player, Vector3.zero, "")
	player.CharacterRemoving:Connect(function()
		setWind(player, Vector3.zero, "")
	end)
end
Players.PlayerAdded:Connect(bind)
for _, player in ipairs(Players:GetPlayers()) do
	bind(player)
end
while script.Parent do
	local now = W:GetServerTimeNow()
	for _, r in pairs(zones) do
		local elapsed = (now - started) % (r.Calm + r.Warning + r.Gust)
		if elapsed < r.Calm then
			r.Phase, r.Remaining = "Calm", r.Calm - elapsed
		elseif elapsed < r.Calm + r.Warning then
			r.Phase, r.Remaining = "Warning", r.Calm + r.Warning - elapsed
		else
			r.Phase, r.Remaining = "Gust", r.Calm + r.Warning + r.Gust - elapsed
		end
		if r.Zone:GetAttribute("Phase") ~= r.Phase then
			r.Zone:SetAttribute("Phase", r.Phase)
			r.Zone:SetAttribute("NextChangeTime", now + r.Remaining)
		end
		r.Sign.Text = r.Phase == "Gust" and "CROSSWIND\nSteer against it or fly around"
			or r.Phase == "Warning" and ("GUST IN " .. math.ceil(r.Remaining) .. "\nGet ready to steer!")
			or ("CALM FOR " .. math.ceil(r.Remaining) .. "\nClear to cross")
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local c = player.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		local h = c and c:FindFirstChildOfClass("Humanoid")
		local r = zones[player:GetAttribute("CurrentBiome")]
		local velocity, state = Vector3.zero, ""
		if r and root and h and h.Health > 0 and not root.Anchored and not player:GetAttribute("PortalTraveling") then
			local point, half = r.Zone.CFrame:PointToObjectSpace(root.Position), r.Zone.Size / 2
			local edge = math.min(half.X - math.abs(point.X), half.Y - math.abs(point.Y), half.Z - math.abs(point.Z))
			if edge > -50 then
				state = r.Phase
			end
			if edge > 0 and r.Phase == "Gust" then
				local envelope = math.min(math.clamp((r.Gust - r.Remaining) / 0.2, 0, 1), math.clamp(r.Remaining / 0.4, 0, 1))
				velocity = r.Wind * envelope * math.clamp(edge / 8, 0, 1)
			end
		end
		setWind(player, velocity, state)
	end
	task.wait(0.1)
end
