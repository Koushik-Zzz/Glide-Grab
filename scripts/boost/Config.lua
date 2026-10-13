-- Shared presentation/tuning; the server owns each player's purchased level.
local Config = {}
Config.ExtraSpeed = 70
Config.Levels = {
	[0] = {Duration = 1.2, Recharge = 6, Price = 0},
	[1] = {Duration = 1.5, Recharge = 5.5, Price = 50},
	[2] = {Duration = 1.8, Recharge = 5, Price = 125},
}
Config.MaxLevel = 2

function Config.atLevel(level)
	return Config.Levels[math.clamp(math.floor(level or 0), 0, Config.MaxLevel)]
end

return Config
