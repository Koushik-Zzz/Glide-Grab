-- The runner wraps the VERBATIM production module in createTelemetry(game,
-- task, Enum, typeof). All four globals are local mocks; no Roblox/network call.
local checks = 0
local function check(value, message)
	assert(value, message)
	checks += 1
end
local function environment(studio, gameId)
	local players, queue, events = {}, {}, {}
	local unavailable, attempts = false, 0
	local analytics = {LogEconomyEvent = function(_, ...)
		attempts += 1
		if unavailable then
			error("simulated analytics outage")
		end
		table.insert(events, {...})
	end}
	local gameMock = {GameId = gameId, GetService = function(_, name)
		if name == "Players" then return players end
		if name == "AnalyticsService" then return analytics end
		assert(name == "RunService", "Unexpected telemetry service dependency")
		return {IsStudio = function()
			return studio
		end}
	end}
	local taskMock = {defer = function(callback)
		table.insert(queue, callback)
	end}
	local enumMock = {AnalyticsEconomyFlowType = {Source = "Source", Sink = "Sink"},
		AnalyticsEconomyTransactionType = {Gameplay = {Name = "Gameplay"}, Shop = {Name = "Shop"}}}
	local player = {ClassName = "Player", Parent = players, IsA = function(_, name)
		return name == "Player"
	end}
	local module = createTelemetry(gameMock, taskMock, enumMock, function(value)
		return type(value) == "table" and value.ClassName and "Instance" or type(value)
	end)
	return {Telemetry = module, Player = player, Queue = queue, Events = events,
		fail = function()
			unavailable = true
		end,
		attempts = function()
			return attempts
		end,
		flush = function()
			for _, callback in ipairs(queue) do
				callback()
			end
			table.clear(queue)
		end}
end
local preview = environment(true, 123)
check(not preview.Telemetry.source(preview.Player, 10, 20, "CollectEggIncome"), "Studio never emits")
check(#preview.Queue == 0 and preview.attempts() == 0, "preview has no queued or attempted reporting")
local localPlace = environment(false, 0)
check(not localPlace.Telemetry.purchase(localPlace.Player, 500, 0, "BoostLevel1"), "unassociated place never emits")
local live = environment(false, 123)
local telemetry, player = live.Telemetry, live.Player
check(telemetry.source(player, 100, 200, "CollectEggIncome"), "published source accepted")
check(#live.Queue == 1 and #live.Events == 0, "report is deferred beyond gameplay transaction")
check(telemetry.purchase(player, 500, 20, "BoostLevel1"), "published purchase accepted")
check(telemetry.rebirth(player, 310000, 0), "whole-wallet rebirth sink accepted")
live.flush()
local source, purchase, rebirth = live.Events[1], live.Events[2], live.Events[3]
check(#source == 7 and source[1] == player and source[2] == "Source" and source[3] == "Coins"
	and source[4] == 100 and source[5] == 200 and source[6] == "Gameplay" and source[7] == "CollectEggIncome",
	"source payload has only the intended player/flow/currency/amount/balance/type/SKU arguments")
check(purchase[2] == "Sink" and purchase[4] == 500 and purchase[5] == 20 and purchase[6] == "Shop"
	and purchase[7] == "BoostLevel1", "purchase payload uses cost and post-purchase balance")
check(rebirth[2] == "Sink" and rebirth[4] == 310000 and rebirth[5] == 0 and rebirth[7] == "FirstRebirth",
	"rebirth reports every removed wallet coin, not just the requirement")
check(not telemetry.source(player, 0, 20, "EmptyCollection"), "zero income ignored")
check(not telemetry.source(player, -1, 20, "Invalid"), "negative amount rejected")
check(not telemetry.source(player, 0 / 0, 20, "Invalid"), "NaN amount rejected")
check(not telemetry.source(player, math.huge, 20, "Invalid"), "infinite amount rejected")
check(not telemetry.source(player, 10, -1, "Invalid"), "negative balance rejected")
check(not telemetry.purchase(player, 10, 20, string.rep("x", 65)), "oversized SKU rejected")
check(not telemetry.purchase(player, 10, 20, ""), "empty SKU rejected")
check(not telemetry.purchase({}, 10, 20, "Invalid"), "non-player rejected")
check(#live.Queue == 0, "invalid calls do not enqueue work")
check(telemetry.source(player, 10, 30, "SellCommonEgg"), "sale accepted before deferred disconnect")
player.Parent = nil
live.flush()
check(#live.Events == 3 and live.attempts() == 3, "departed player skipped at deferred execution")
local failing = environment(false, 123)
failing.fail()
check(failing.Telemetry.purchase(failing.Player, 3000, 0, "EggShieldCharge"), "outage cannot reject gameplay purchase")
check(pcall(failing.flush) and failing.attempts() == 1 and #failing.Events == 0,
	"analytics failure is caught once without retry or gameplay exception")
print("PASS: " .. checks .. " production telemetry checks (mock services only)")
return {passed = true, checks = checks, realAnalyticsCalls = 0}
