-- Sole save lifecycle owner. Gameplay modules retain their transaction boundaries.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local Schema, Session = require(script.Parent.Schema), require(script.Parent.Session)
local Profiles = {}
local records, capturers = {}, {}
local preview = RunService:IsStudio() and game.GameId == 0
local memory = {}
local store
if preview then
	store = {UpdateAsync = function(_, key, update)
		local value = update(Schema.copy(memory[key]))
		if value ~= nil then
			memory[key] = Schema.copy(value)
		end
		return Schema.copy(memory[key])
	end}
	warn("Local place: save preview only. Open the published test place to verify persistent saves.")
else
	store = DataStoreService:GetDataStore(RunService:IsStudio() and "GlideGrab_Studio_v1" or "GlideGrab_Player_v1")
end
function Profiles.get(player)
	local r = records[player]
	if not r or not r.Ready or r.Closing or r.Transaction then return nil end
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if coins then
		r.Session.Data.Coins = math.clamp(coins.Value, 0, 1e15)
	end
	return r.Session.Data
end
function Profiles.await(player)
	while player.Parent == Players do
		local r = records[player]
		if r and r.Ready then return Profiles.get(player) end
		if r and r.Failed then return nil end
		task.wait(0.05)
	end
	return nil
end
function Profiles.capture(callback)
	table.insert(capturers, callback)
end
local function snapshot(player, r)
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if coins then
		r.Session.Data.Coins = math.clamp(coins.Value, 0, 1e15)
	end
	for _, callback in ipairs(capturers) do
		callback(player, r.Session.Data)
	end
	return Schema.copy(r.Session.Data)
end
function Profiles.save(player, release)
	local r = records[player]
	if not r or not r.Ready or r.UncertainCommit then return false end
	if release and r.ReleaseStarted then
		-- PlayerRemoving and BindToClose may arrive together. Share one final write.
		while not r.ReleaseFinished do
			task.wait(0.05)
		end
		return r.ReleaseSucceeded
	end
	if r.Session.Closed then return release == true end
	local function finish(ok)
		if release then
			r.ReleaseSucceeded, r.ReleaseFinished = ok, true
		end
		return ok
	end
	if release then
		r.ReleaseStarted = true
		r.Closing = true
		player:SetAttribute("DataLoaded", false)
	end
	while r.Session.Busy do
		task.wait(0.05)
	end
	if r.Session.Closed then return finish(true) end
	while r.Transaction do
		task.wait(0.05)
	end
	if r.Session.Closed or r.UncertainCommit then return finish(not r.UncertainCommit) end
	local captured, value = pcall(snapshot, player, r)
	local ok, err = false, "capture failed"
	if captured then
		ok, err = r.Session:save(value, release)
	end
	player:SetAttribute("SaveStatus", ok and (preview and "Preview only" or "Saved") or "Retrying save")
	if not ok then
		warn("Player save failed: " .. player.UserId .. " (" .. tostring(err) .. ")")
		if not release and (err == "lost session" or os.time() - r.Session.LastSuccess >= 200) then
			r.Closing = true
			player:SetAttribute("DataLoaded", false)
			player:Kick("Your save connection was interrupted. Please rejoin to protect your progress.")
		end
	end
	return finish(ok)
end
function Profiles.commit(player, proposed, apply)
	local r = records[player]
	if not Profiles.get(player) or not Schema.validate(proposed) then return false end
	r.Transaction = true
	player:SetAttribute("DataLoaded", false)
	while r.Session.Busy do
		task.wait(0.05)
	end
	if r.Closing then
		r.Transaction = false
		return false
	end
	local ok, reason = r.Session:save(proposed, false)
	if not ok then
		r.Closing = true
		if reason == "lost session" then
			player:Kick("Your save moved to another server. Please rejoin to protect your progress.")
		else
			-- A failed response can follow a successful backend write. Continuing with
			-- old live data would let the next autosave undo the saved rebirth.
			r.UncertainCommit = true
			r.Session:releaseCurrent()
			player:Kick("The rebirth save could not be confirmed. Please rejoin to load its saved outcome.")
		end
	end
	if ok then
		-- Keep existing server references valid (boost and gear own these records).
		local data = r.Session.Data
		table.clear(data)
		for key, value in pairs(Schema.copy(proposed)) do
			data[key] = value
		end
		if player.Parent == Players then
			player.leaderstats.Coins.Value = data.Coins
			local applied, applyError = pcall(apply, data)
			if not applied then
				warn("Saved rebirth could not refresh the scene: " .. tostring(applyError))
				r.Closing = true
				player:Kick("Your rebirth was saved. Please rejoin to load your upgraded camp.")
			end
		end
	end
	r.Transaction = false
	player:SetAttribute("DataLoaded", not r.Closing)
	player:SetAttribute("SaveStatus", ok and (preview and "Preview only" or "Saved") or "Retrying save")
	return ok, not ok and "rejoin" or nil
end
local function bind(player)
	if records[player] then return end
	local r = {Ready = false}
	records[player] = r
	player:SetAttribute("DataLoaded", false)
	player:SetAttribute("SaveStatus", "Loading progress")
	local session, err = Session.open(store, "Player_" .. player.UserId, HttpService:GenerateGUID(false))
	if not session then
		r.Failed = true
		player:Kick(err or "Could not load progress. Please rejoin.")
		return
	end
	r.Session = session
	if player.Parent ~= Players then
		session:save(session.Data, true)
		records[player] = nil
		return
	end
	local stats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	stats.Name, stats.Parent = "leaderstats", player
	local coins = stats:FindFirstChild("Coins") or Instance.new("IntValue")
	coins.Name, coins.Value, coins.Parent = "Coins", session.Data.Coins, stats
	r.CoinsConnection = coins:GetPropertyChangedSignal("Value"):Connect(function()
		session.Data.Coins = math.clamp(coins.Value, 0, 1e15)
	end)
	r.Ready = true
	player:SetAttribute("DataLoaded", true)
	player:SetAttribute("SaveStatus", preview and "Preview only" or "Saved")
	task.spawn(function()
		while records[player] == r and not r.Closing do
			task.wait(55 + math.random() * 15)
			if records[player] == r and not r.Closing then
				Profiles.save(player, false)
			end
		end
	end)
end
Players.PlayerAdded:Connect(bind)
Players.PlayerRemoving:Connect(function(player)
	Profiles.save(player, true)
	local r = records[player]
	if r and r.CoinsConnection then
		r.CoinsConnection:Disconnect()
	end
	records[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(bind, player)
end
game:BindToClose(function()
	local remaining = 0
	for player, r in pairs(records) do
		if r.Ready and not r.Session.Closed then
			remaining += 1
			task.spawn(function()
				Profiles.save(player, true)
				remaining -= 1
			end)
		end
	end
	local deadline = os.clock() + 25
	while remaining > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)
return Profiles
