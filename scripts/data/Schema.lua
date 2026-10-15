-- Plain versioned data only. Invalid/newer saves fail closed, never become defaults.
local Rolls = require(script.Parent.Parent.CollectionModules.Rolls)
local Schema = {}
Schema.Version = 1
function Schema.defaults()
	return {Version = 1, Coins = 0, BoostLevel = 0, Rebirths = 0, Bat = false,
		Shields = 0, Eggs = {}, Pending = 0}
end
local function number(value, maximum, integer)
	return type(value) == "number" and value == value and value >= 0 and value <= maximum
		and (not integer or value % 1 == 0)
end
function Schema.copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for k, v in pairs(value) do
		result[k] = Schema.copy(v)
	end
	return result
end
function Schema.validate(data)
	if type(data) ~= "table" or data.Version ~= Schema.Version then return false end
	if not number(data.Coins, 1e15, true) or not number(data.Pending, 1e15)
		or not number(data.BoostLevel, 5, true) or not number(data.Rebirths, 1, true)
		or type(data.Bat) ~= "boolean" or not number(data.Shields, 3, true)
		or type(data.Eggs) ~= "table" then return false end
	local slots, ids, count = {}, {}, 0
	for key, egg in pairs(data.Eggs) do
		count += 1
		if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > 12
			or type(egg) ~= "table" or not number(egg.Slot, data.Rebirths > 0 and 12 or 6, true)
			or egg.Slot < 1 or slots[egg.Slot] or not Rolls.valid(egg.Template, egg.Economy)
			or ids[egg.Economy.EggId] then return false end
		slots[egg.Slot], ids[egg.Economy.EggId] = true, true
	end
	return count <= 12 and count == #data.Eggs
end
return Schema
