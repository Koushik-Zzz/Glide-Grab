-- Shared presentation/tuning; the server owns each player's purchased level.
local Config = {}
Config.ExtraSpeed = 70
Config.Levels = {
	[0] = {Duration = 1.2, Recharge = 6, Price = 0},
	[1] = {Duration = 1.5, Recharge = 5.5, Price = 500},
	[2] = {Duration = 1.8, Recharge = 5, Price = 5000},
	[3] = {Duration = 2.1, Recharge = 4.7, Price = 50000},
	[4] = {Duration = 2.4, Recharge = 4.4, Price = 250000},
	[5] = {Duration = 2.7, Recharge = 4.2, Price = 1000000},
}
Config.MaxLevel = 5

function Config.atLevel(level)
	return Config.Levels[math.clamp(math.floor(level or 0), 0, Config.MaxLevel)]
end

return Config
