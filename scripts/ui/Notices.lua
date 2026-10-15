-- One client status channel prevents travel, boost and HUD messages overlapping.
local Notices = {}
local listeners, message, revision = {}, nil, 0

local function changed()
	for callback in pairs(listeners) do
		callback(message)
	end
end

function Notices.current()
	return message
end

function Notices.subscribe(callback)
	listeners[callback] = true
	return {Disconnect = function()
		listeners[callback] = nil
	end}
end

function Notices.clear()
	revision += 1
	message = nil
	changed()
end

function Notices.show(text, duration)
	if type(text) ~= "string" or text == "" then return end
	revision += 1
	local version = revision
	message = text
	changed()
	task.delay(duration or 3, function()
		if revision == version then
			Notices.clear()
		end
	end)
end

return Notices
