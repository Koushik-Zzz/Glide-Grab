-- Prototype economy: income is online and session-only; no hatch mechanic.
return {
	Eggs = {
		CommonEgg = {Rarity = "Common", Income = 1, SellValue = 10, Shared = true, RespawnSeconds = 3},
		UncommonEgg = {Rarity = "Uncommon", Income = 3, SellValue = 25, GuardianProtected = true, RespawnSeconds = 3},
		RareEgg = {
			Rarity = "Rare", SellValue = 100, GuardianProtected = true, RespawnSeconds = 20,
			MinIncome = 100, MaxIncome = 1000, ScaleRange = {Min = 1, Max = 1.5},
			Tiers = {
				{Name = "Low", Min = 100, Max = 500, Weight = 75},
				{Name = "High", Min = 500, Max = 1000, Weight = 25},
			},
		},
	},
	InteractionDistance = 7,
	ReplaceHold = 1.2,
	SellHold = 1.2,
}
