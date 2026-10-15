-- Bundled with the production Config/Rolls/Schema/Session modules by run-data-tests.py.
local now = 1000
local values, calls, failBefore, failAfter = {}, 0, 0, 0
local store = {}
function store:UpdateAsync(key, callback)
	calls += 1
	if failBefore > 0 then
		failBefore -= 1
		error("simulated unavailable backend")
	end
	local result = callback(Schema.copy(values[key]))
	if result ~= nil then
		values[key] = Schema.copy(result)
	end
	if failAfter > 0 then
		failAfter -= 1
		error("simulated lost success response")
	end
	return Schema.copy(values[key])
end
local options = {clock = function()
	return now
end, pause = function() end, lease = 240}
local checks = 0
local function check(value, message)
	assert(value, message)
	checks += 1
end
local first = assert(Session.open(store, "Player_123", "A", options))
check(Schema.validate(first.Data), "new profile schema")
check(first.Data.Coins == 0 and #first.Data.Eggs == 0, "new player defaults")
local competing = Session.open(store, "Player_123", "B", options)
check(competing == nil and values.Player_123.Session.Token == "A", "active session cannot be stolen")
local random = {NextNumber = function(_, _, maximum) return maximum - 0.001 end,
	NextInteger = function(_, _, maximum)
		return maximum
	end}
first.Data.Coins, first.Data.BoostLevel, first.Data.Bat, first.Data.Shields = 182321, 3, true, 2
first.Data.Eggs = {{Slot = 6, Template = "RareEgg", Economy = Rolls.create("RareEgg", random)}}
first.Data.Pending = 123.75
local originalId = first.Data.Eggs[1].Economy.EggId
check(first:save(first.Data, true), "save-and-release")
check(values.Player_123.Session == nil, "final save releases session")
local second = assert(Session.open(store, "Player_123", "B", options))
check(second.Data.Coins == 182321 and second.Data.BoostLevel == 3 and second.Data.Bat and second.Data.Shields == 2, "currency/boost/gear restored")
check(second.Data.Eggs[1].Slot == 6 and second.Data.Eggs[1].Economy.EggId == originalId, "slot and identity retained")
check(second.Data.Eggs[1].Economy.Income == 1000 and second.Data.Eggs[1].Economy.Scale == 1.5, "fixed rare roll retained")
check(second.Data.Pending == 123.75, "fractional pending income retained without offline grant")
local invalid = Schema.copy(second.Data)
invalid.Eggs[2] = Schema.copy(invalid.Eggs[1])
check(not Schema.validate(invalid), "duplicate slot/egg ID rejected")
invalid = Schema.copy(second.Data)
invalid.Coins = 0 / 0
check(not second:save(invalid, false), "NaN rejected before backend")
invalid = Schema.copy(second.Data)
invalid.Eggs[1].Slot = 7
check(not Schema.validate(invalid), "locked upper slot rejected")
failAfter = 1
second.Data.Coins = 200000
check(second:save(second.Data, false) and values.Player_123.Data.Coins == 200000, "ambiguous success retry idempotent")
failBefore = 3
second.Data.Coins = 250000
check(not second:save(second.Data, false) and values.Player_123.Data.Coins == 200000, "failed save preserves previous value")
check(second:save(second.Data, false), "retry later succeeds")
now += 241
local third = assert(Session.open(store, "Player_123", "C", options))
local staleOk, staleReason = second:save(second.Data, false)
check(not staleOk and staleReason == "lost session" and values.Player_123.Session.Token == "C", "expired owner cannot overwrite replacement")
local rebirth = Schema.copy(third.Data)
rebirth.Rebirths, rebirth.Coins, rebirth.BoostLevel, rebirth.Pending, rebirth.Eggs = 1, 0, 0, 0, {}
check(third:save(rebirth, true), "atomic rebirth checkpoint")
local fourth = assert(Session.open(store, "Player_123", "D", options))
check(fourth.Data.Rebirths == 1 and fourth.Data.Coins == 0 and fourth.Data.BoostLevel == 0 and #fourth.Data.Eggs == 0, "rebirth reset persisted")
check(fourth.Data.Bat and fourth.Data.Shields == 2, "rebirth retains gear")
fourth.Data.Eggs = {{Slot = 12, Template = "StormEgg", Economy = Rolls.create("StormEgg", random)}}
check(Schema.validate(fourth.Data) and fourth:save(fourth.Data, true), "upper-floor epic egg save")
local fifth = assert(Session.open(store, "Player_123", "E", options))
check(fifth.Data.Eggs[1].Slot == 12 and fifth.Data.Eggs[1].Economy.Income == 2500, "upper-floor epic restored")
values.Future = {Data = {Version = 99}}
check(Session.open(store, "Future", "F", options) == nil and values.Future.Data.Version == 99, "newer schema never overwritten")
local before = calls
failBefore = 5
check(Session.open(store, "Unavailable", "G", options) == nil and values.Unavailable == nil and calls == before + 5, "failed load never creates defaults")

-- Exhaust every response after a rebirth reached the backend. Fail closed rather
-- than resume the old live snapshot and undo the checkpoint on the next autosave.
local ambiguous = assert(Session.open(store, "AmbiguousRebirth", "H", options))
ambiguous.Data.Coins = 300000
check(ambiguous:save(ambiguous.Data, false), "seed pre-rebirth snapshot")
local proposed = Schema.copy(ambiguous.Data)
proposed.Coins, proposed.Rebirths = 0, 1
failAfter = 3
check(not ambiguous:save(proposed, false) and values.AmbiguousRebirth.Data.Rebirths == 1,
	"exhausted responses can hide a committed rebirth")
failAfter = 1
check(ambiguous:releaseCurrent() and values.AmbiguousRebirth.Session == nil,
	"lease-only release is idempotent after a lost response")
check(values.AmbiguousRebirth.Data.Rebirths == 1 and values.AmbiguousRebirth.Data.Coins == 0,
	"uncertain checkpoint release preserves backend outcome")
check(not ambiguous:save(ambiguous.Data, true), "retired handle cannot overwrite checkpoint with stale data")
local confirmed = assert(Session.open(store, "AmbiguousRebirth", "I", options))
check(confirmed.Data.Rebirths == 1 and confirmed.Data.Coins == 0,
	"successor loads confirmed backend rebirth")

local unavailable = assert(Session.open(store, "UnwrittenRebirth", "J", options))
unavailable.Data.Coins = 310000
check(unavailable:save(unavailable.Data, false), "seed uncommitted checkpoint case")
proposed = Schema.copy(unavailable.Data)
proposed.Coins, proposed.Rebirths = 0, 1
failBefore = 3
check(not unavailable:save(proposed, false) and unavailable:releaseCurrent(),
	"failed-before-write checkpoint can release without committing")
local unchanged = assert(Session.open(store, "UnwrittenRebirth", "K", options))
check(unchanged.Data.Rebirths == 0 and unchanged.Data.Coins == 310000,
	"unwritten rebirth keeps last saved progress")

local final = assert(Session.open(store, "FinalRetry", "L", options))
final.Data.Coins = 42
before, failBefore = calls, 4
check(final:save(final.Data, true) and calls == before + 5 and values.FinalRetry.Data.Coins == 42,
	"final release retries four transient failures then saves exactly once")
check(values.FinalRetry.Session == nil and final.Closed, "successful final retry releases lease")

local expired = assert(Session.open(store, "ReleaseTakeover", "M", options))
now += 241
local replacement = assert(Session.open(store, "ReleaseTakeover", "N", options))
local released, releaseReason = expired:releaseCurrent()
check(not released and releaseReason == "lost session" and values.ReleaseTakeover.Session.Token == "N",
	"lease-only release cannot unlock a newer owner")
check(replacement:save(replacement.Data, true), "replacement owner can still save")
print("PASS: " .. checks .. " production save/session checks")
