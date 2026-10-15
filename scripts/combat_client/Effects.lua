-- Every viewer poses the replicated held weapon. No floating swing clones.
local WeaponPose = require(script.Parent:WaitForChild("WeaponPose"))
local Effects = {}
function Effects.new()
	local pose = WeaponPose.new()
	local api = {}
	function api:destroy()
		pose:destroy()
	end
	return api
end
return Effects
