-- Server-only offer rolls. Each exclusive spawn rolls once, before anyone picks it up.
local HttpService = game:GetService("HttpService")
local Config = require(script.Parent.Config)
local Rolls = {}
function Rolls.create(template, random)
	local definition = assert(Config.Eggs[template], "Unknown egg template")
	local income, tier = definition.Income, "Standard"
	if definition.Tiers then
		local total = 0
		for _, band in ipairs(definition.Tiers) do
			total += band.Weight
		end
		local value = random:NextNumber(0, total)
		local band = definition.Tiers[#definition.Tiers]
		for _, candidate in ipairs(definition.Tiers) do
			value -= candidate.Weight
			if value <= 0 then
				band = candidate
				break
			end
		end
		income, tier = random:NextInteger(band.Min, band.Max), band.Name
	end
	local scale = 1
	if definition.ScaleRange then
		local t = math.clamp((income - definition.MinIncome) / (definition.MaxIncome - definition.MinIncome), 0, 1)
		scale = definition.ScaleRange.Min + t * (definition.ScaleRange.Max - definition.ScaleRange.Min)
	end
	return table.freeze({Rarity = definition.Rarity, Income = income, SellValue = definition.SellValue,
		Tier = tier, Scale = scale, EggId = HttpService:GenerateGUID(false)})
end

function Rolls.valid(template, record)
	local definition = Config.Eggs[template]
	if not definition or type(record) ~= "table" then return false end
	if record.Rarity ~= definition.Rarity or record.SellValue ~= definition.SellValue
		or type(record.EggId) ~= "string" or #record.EggId ~= 36 then return false end
	if definition.Tiers then
		if type(record.Income) ~= "number" or record.Income % 1 ~= 0 then return false end
		local matched = false
		for _, band in ipairs(definition.Tiers) do
			if record.Tier == band.Name and record.Income >= band.Min and record.Income <= band.Max then
				matched = true
				break
			end
		end
		if not matched then return false end
		local t = (record.Income - definition.MinIncome) / (definition.MaxIncome - definition.MinIncome)
		local expected = definition.ScaleRange.Min + t * (definition.ScaleRange.Max - definition.ScaleRange.Min)
		return type(record.Scale) == "number" and math.abs(record.Scale - expected) < 0.00001
	end
	return record.Income == definition.Income and record.Tier == "Standard" and record.Scale == 1
end
return Rolls
