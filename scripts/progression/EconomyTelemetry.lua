-- Owner opted in to Roblox economy reporting on 2026-10-15 after the payload
-- and Creator Dashboard purpose were explained: coin amount, balance and SKU.
-- Best-effort measurement only; this module never owns or changes player data.
local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local enabled = not RunService:IsStudio() and game.GameId > 0
local Telemetry = {}
local function finite(value)
	return type(value) == "number" and value == value and value >= 0 and value <= 1e15
end
local function report(player, flow, amount, balance, transaction, sku)
	if not enabled or typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players
		or not finite(amount) or amount <= 0 or not finite(balance)
		or type(sku) ~= "string" or #sku == 0 or #sku > 64 then return false end
	-- Defer network reporting until after the atomic gameplay transaction. A
	-- reporting failure cannot repeat a purchase or delay a placement/save.
	task.defer(function()
		if player.Parent ~= Players then return end
		pcall(function()
			AnalyticsService:LogEconomyEvent(player, flow, "Coins", amount, balance, transaction, sku)
		end)
	end)
	return true
end
function Telemetry.source(player, amount, balance, sku)
	return report(player, Enum.AnalyticsEconomyFlowType.Source, amount, balance,
		Enum.AnalyticsEconomyTransactionType.Gameplay.Name, sku)
end
function Telemetry.purchase(player, amount, balance, sku)
	return report(player, Enum.AnalyticsEconomyFlowType.Sink, amount, balance,
		Enum.AnalyticsEconomyTransactionType.Shop.Name, sku)
end
function Telemetry.rebirth(player, amount, balance)
	return report(player, Enum.AnalyticsEconomyFlowType.Sink, amount, balance,
		Enum.AnalyticsEconomyTransactionType.Gameplay.Name, "FirstRebirth")
end
return Telemetry
