-- Ordered UpdateAsync writes with an expiring, token-owned lease.
-- The store/clock/wait dependencies also allow deterministic failure tests.
local Schema = require(script.Parent.Schema)
local Session = {}
function Session.open(store, key, token, options)
	options = options or {}
	local clock, pause = options.clock or os.time, options.pause or task.wait
	local lease = options.lease or 240
	local data, reason
	for attempt = 1, 5 do
		local acquired = false
		local ok, result = pcall(function()
			return store:UpdateAsync(key, function(old)
				acquired = false
				if old ~= nil and (type(old) ~= "table" or not Schema.validate(old.Data)) then
					reason = "Saved data needs recovery or a newer server."
					return nil
				end
				if old and old.Session and old.Session.Token ~= token and old.Session.Expires > clock() then
					reason = "Your previous server is still saving. Please rejoin shortly."
					return nil
				end
				local nextValue = old and Schema.copy(old) or {Data = Schema.defaults()}
				nextValue.Session = {Token = token, Expires = clock() + lease}
				acquired = true
				return nextValue
			end)
		end)
		if ok and acquired and result then
			data = Schema.copy(result.Data)
			break
		end
		if ok and reason == "Saved data needs recovery or a newer server." then return nil, reason end
		if not ok then
			reason = "Roblox could not load your save. Please try again."
		end
		if attempt < 5 then
			pause(math.min(2 ^ attempt, 6))
		end
	end
	if not data then return nil, reason end
	local api = {Data = data, LastSuccess = clock(), Closed = false, Busy = false}
	local serial = 0
	function api:save(snapshot, release)
		if self.Busy or self.Closed then return false, "busy" end
		if not Schema.validate(snapshot) then return false, "invalid snapshot" end
		self.Busy = true
		serial += 1
		local writeId = token .. ":" .. serial
		local frozen = Schema.copy(snapshot)
		local succeeded, failure = false, "unavailable"
		for attempt = 1, 3 do
			local accepted, lost = false, false
			local ok = pcall(function()
				store:UpdateAsync(key, function(old)
					accepted, lost = false, false
					-- A response may fail after the backend wrote. Recognize this retry.
					if old and old.LastWrite == writeId then
						accepted = release or (old.Session and old.Session.Token == token and old.Session.Expires > clock())
						lost = not accepted
						return nil
					end
					if not old or not old.Session or old.Session.Token ~= token
						or old.Session.Expires <= clock() then
						lost = true
						return nil
					end
					local nextValue = {Data = frozen, LastWrite = writeId,
						Session = not release and {Token = token, Expires = clock() + lease} or nil}
					accepted = true
					return nextValue
				end)
			end)
			if ok and accepted then
				succeeded = true
				break
			end
			if ok and lost then
				failure = "lost session"
				break
			end
			if attempt < 3 then
				pause(2 ^ attempt)
			end
		end
		self.Busy = false
		if succeeded then
			self.LastSuccess = clock()
			self.Closed = release == true
		end
		return succeeded, failure
	end
	return api
end
return Session
