-- NOT mapped by Rojo. Run only as a temporary ordinary server Script in a
-- two-client StudioTestService run using token "ProfilesResilienceProof".
-- It injects a failing backend into a CLONE of production Profiles; no cloud
-- key is touched. Client1 is deliberately kicked to verify the failure path.
-- First run stage-profiles-resilience.studio.lua in EDIT, then remove its
-- TemporaryResilienceModules folder and this test Script after Stop.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local StudioTestService = game:GetService("StudioTestService")
if not RunService:IsStudio() or StudioTestService:GetTestArgs() ~= "ProfilesResilienceProof" then return end
if game.GameId ~= 0 then
	StudioTestService:EndTest({passed = false, error = "Use the local preview scene for fixture currency"})
	return
end

local function waitFor(predicate, seconds)
	local deadline = os.clock() + seconds
	repeat
		local result = predicate()
		if result then return result end
		task.wait(0.1)
	until os.clock() >= deadline
	error("Resilience fixture timed out")
end
local function run()
	local clients = waitFor(function()
		local list = Players:GetPlayers()
		if #list == 2 and list[1]:FindFirstChild("leaderstats") and list[2]:FindFirstChild("leaderstats") then return list end
	end, 100)
	table.sort(clients, function(a, b)
		return a.UserId < b.UserId
	end)
	local folder = assert(ServerScriptService:FindFirstChild("TemporaryResilienceModules"), "Run Edit-only staging first")
	local backend, Schema = require(folder.Backend), require(folder.Schema)
	local Profiles = require(folder.Profiles)
	for _, p in ipairs(clients) do
		waitFor(function()
			return Profiles.get(p)
		end, 10)
	end

	local a, b = clients[1], clients[2]
	local keyA, keyB = "Player_" .. a.UserId, "Player_" .. b.UserId
	a.leaderstats.Coins.Value = 300000
	assert(Profiles.save(a, false), "seed profile save")
	local proposed = Schema.copy(Profiles.get(a))
	proposed.Coins, proposed.Rebirths = 0, 1
	backend.Policies[keyA] = {Before = 0, After = 3}
	local applied = false
	local committed, reason = Profiles.commit(a, proposed, function()
		applied = true
	end)
	assert(not committed and reason == "rejoin" and not applied, "uncertain commit must not resume old live progress")
	assert(backend.Values[keyA].Data.Rebirths == 1 and backend.Values[keyA].Data.Coins == 0,
		"backend checkpoint preserved")
	assert(backend.Values[keyA].Session == nil, "uncertain profile releases backend lease only")
	local callsA = backend.Calls[keyA]
	assert(not Profiles.save(a, true) and backend.Calls[keyA] == callsA, "departure cannot write stale pre-rebirth data")
	assert(Profiles.get(a) == nil, "uncertain profile is unavailable for further gameplay")

	b.leaderstats.Coins.Value = 4242
	local captures = 0
	Profiles.capture(function(player)
		if player == b then
			captures += 1
		end
	end)
	backend.Policies[keyB] = {Before = 4, After = 0}
	local callsB = backend.Calls[keyB]
	local result1, result2
	task.spawn(function()
		result1 = Profiles.save(b, true)
	end)
	task.wait(0.1)
	task.spawn(function()
		result2 = Profiles.save(b, true)
	end)
	waitFor(function()
		return result1 ~= nil and result2 ~= nil
	end, 30)
	assert(result1 and result2, "concurrent departure/shutdown callers share final success")
	assert(backend.Calls[keyB] - callsB == 5 and captures == 1, "one final snapshot and one bounded retry sequence")
	assert(backend.Values[keyB].Data.Coins == 4242 and backend.Values[keyB].Session == nil,
		"final retry keeps currency and releases lease")
	return {passed = true, uncertainCommitStopped = true, backendCheckpointPreserved = true,
		noStaleDepartureWrite = true, concurrentFinalCallers = true, finalAttempts = 5, finalCaptures = captures}
end
local ok, result = pcall(run)
StudioTestService:EndTest(ok and result or {passed = false, error = tostring(result)})
