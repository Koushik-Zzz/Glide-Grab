-- Private reservations. Shared sources can serve different players simultaneously.
-- A player still carries at most one egg; releasing one never releases another.
local Claims = {}
function Claims.new()
	local records, cooldowns = {}, {}
	local api = {}
	function api:canClaim(player, source, now)
		local times = cooldowns[player]
		return records[player] == nil and (source.Shared or source.Carrier == nil)
			and now >= (times and times[source] or 0)
	end
	function api:claim(player, source, cargo, economy, now)
		if not api:canClaim(player, source, now) then return nil end
		local record = {Owner = player, Source = source, Cargo = cargo, Economy = economy}
		records[player] = record
		if not source.Shared then
			source.Carrier = player
		end
		return record
	end
	function api:peek(player)
		local record = records[player]
		if record and record.Owner == player and (record.Source.Shared or record.Source.Carrier == player) then
			return record
		end
		return nil
	end
	function api:release(player, now, delay)
		local record = api:peek(player)
		if not record then return nil end
		records[player] = nil
		local source = record.Source
		if source.Shared then
			cooldowns[player] = cooldowns[player] or {}
			cooldowns[player][source] = now + delay
		else
			source.Carrier = nil
		end
		return record
	end
	function api:forget(player)
		assert(records[player] == nil, "Release cargo before removing a player")
		cooldowns[player] = nil
	end
	-- Atomic handoff: retain the immutable economy/identity and exclusive reservation.
	function api:transfer(from, to, expected, cargo, now, protection)
		if from == to or records[to] or api:peek(from) ~= expected
			or now < (expected.TheftReadyAt or 0) then return false end
		records[from], records[to] = nil, expected
		expected.Owner, expected.Cargo = to, cargo
		expected.TheftReadyAt = now + protection
		if not expected.Source.Shared then
			expected.Source.Carrier = to
		end
		return true
	end
	return api
end
return Claims
