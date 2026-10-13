-- Guardian difficulty lives here. Model attributes can override these defaults.
local Config = {}
local defaults = {
	ChaseSpeed = 145,
	LeashRadius = 300,
	AttackRange = 52,
	AlertSeconds = 0.55,
	WarningSeconds = 0.35,
	DashSpeed = 245,
	DashOvershoot = 44,
	MaxLeadSeconds = 0.65,
	MaxLeadDistance = 65,
	HitRadius = 7,
	RecoverSeconds = 0.6,
	PatrolSpeed = 32,
	ReturnSpeed = 115,
	KnockbackSpeed = 72,
	KnockbackLift = 26,
	KnockbackSeconds = 0.42,
}
local limits = {
	ChaseSpeed = {60, 180}, LeashRadius = {80, 350}, AttackRange = {15, 65},
	AlertSeconds = {0.2, 2}, WarningSeconds = {0.2, 1.5}, DashSpeed = {150, 300},
	DashOvershoot = {10, 50}, MaxLeadSeconds = {0.1, 0.8}, MaxLeadDistance = {10, 80},
	HitRadius = {4, 9}, RecoverSeconds = {0.3, 2}, PatrolSpeed = {10, 50},
	ReturnSpeed = {40, 160}, KnockbackSpeed = {20, 100}, KnockbackLift = {10, 40},
	KnockbackSeconds = {0.15, 0.6},
}

function Config.fromModel(model)
	local settings = table.clone(defaults)
	for key, range in pairs(limits) do
		local value = model:GetAttribute(key)
		if type(value) == "number" and value == value then
			settings[key] = math.clamp(value, range[1], range[2])
		end
	end
	settings.HomePosition = model:GetAttribute("HomePosition")
	assert(typeof(settings.HomePosition) == "Vector3", "NestGuardian needs a HomePosition attribute")
	return settings
end

return Config
