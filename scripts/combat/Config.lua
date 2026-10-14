-- Server-owned combat tuning and coin purchases. Prices are initial pacing values.
return {
	SafeRadius = 80, ArrivalGrace = 5, AirClearance = 7, HitRecovery = 2,
	BatPrice = 5000, ShieldPrice = 3000, ShieldMaxCharges = 3, ShieldSeconds = 12,
	StealRange = 10, TransferProtection = 6, RequestInterval = 0.15,
	Cooldowns = {Slap = 1.2, Bat = 2, Steal = 3, Shield = 0.5},
	Weapons = {
		Slap = {Range = 10, Windup = 0.08, Stun = 0.7, Push = 35, Lift = 14},
		Bat = {Range = 12, Windup = 0.12, Stun = 0.9, Push = 55, Lift = 18},
	},
}
