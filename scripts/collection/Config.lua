-- Income accrues online; saved eggs retain their original rolls. No hatch mechanic.
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
		StormEgg = {
			Rarity = "Epic", SellValue = 500, RespawnSeconds = 25,
			MinIncome = 1000, MaxIncome = 2500, ScaleRange = {Min = 1.1, Max = 1.65},
			Tiers = {
				{Name = "Low", Min = 1000, Max = 1750, Weight = 75},
				{Name = "High", Min = 1750, Max = 2500, Weight = 25},
			},
		},
	},
	InteractionDistance = 7,
	ReplaceHold = 1.2,
	SellHold = 1.2,
}
