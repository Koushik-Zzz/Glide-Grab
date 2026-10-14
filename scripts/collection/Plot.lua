-- One plot's display transactions, prompts and private elapsed-time ledger.
-- EggLoop supplies private carried records; attributes are presentation only.
local Players = game:GetService("Players")
local Config = require(script.Parent.Config)
local Rolls = require(script.Parent.Rolls)
local Income = require(script.Parent.Income)
local Visuals = require(script.Parent.Visuals)
local Plot = {}

local function prompt(root, name, key, button, hold)
	local object = Instance.new("ProximityPrompt")
	object.Name = name
	object.KeyboardKeyCode = key
	object.GamepadKeyCode = button
	object.HoldDuration = hold
	object.MaxActivationDistance = Config.InteractionDistance
	object.RequiresLineOfSight = false
	object.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	object.Parent = root
	return object
end

function Plot.new(plot, callbacks, notice)
	local folder = plot:WaitForChild("Slots")
	local pad = plot:WaitForChild("CollectionPad")
	local deposit = pad:WaitForChild("DepositPrompt")
	local slots, owner, ledger = {}, nil, Income.new(os.clock())
	local lastAction = {}
	local api = {Model = plot}
	local padLabel = Visuals.label(pad, "CollectionSign")
	local function refreshPlotSign()
		local sign = plot:FindFirstChild("PlotSign")
		if not sign then return end
		for _, label in ipairs(sign:GetDescendants()) do
			if label:IsA("TextLabel") and label.Name == "OwnerLabel" then
				label.Text = owner and string.upper(owner.DisplayName .. "'s Camp") or "AVAILABLE CAMP"
			end
		end
	end
	padLabel.Parent.StudsOffset = Vector3.new(0, 3.5, 0)
	deposit.ActionText = "Place egg / collect income"
	deposit.ObjectText = "Camp collection"
	deposit.HoldDuration = 0.3

	local function publish()
		deposit:SetAttribute("Available", owner ~= nil)
		deposit.Enabled = owner ~= nil
		local pending = ledger:accrue(os.clock())
		local count, rate = 0, 0
		for _, slot in ipairs(slots) do
			if slot.Egg then
				count += 1
				rate += slot.Economy.Income
			end
		end
		if owner then
			owner:SetAttribute("EggIncomeRate", rate)
			owner:SetAttribute("EggIncomePending", pending)
			owner:SetAttribute("EggDisplayCount", count)
			owner:SetAttribute("EggDisplayCapacity", #slots)
		end
		padLabel.Text = string.format("COLLECT: %d coins\n%d/%d eggs • %d coins/sec", pending, count, #slots, rate)
	end

	local function refreshSlot(slot)
		local occupied = slot.Egg ~= nil
		slot.Place.ActionText = occupied and "Replace (sells old egg)" or "Place carried egg"
		slot.Place.ObjectText = occupied
			and string.format("%s • sell +%d", slot.Definition.Name, slot.Economy.SellValue)
			or "Empty pillow " .. slot.Index
		slot.Place.HoldDuration = occupied and Config.ReplaceHold or 0.3
		-- Different keys can show simultaneously; give their native cards separate rows.
		slot.Place.UIOffset = occupied and Vector2.new(0, -55) or Vector2.zero
		slot.Sell.UIOffset = Vector2.new(0, 55)
		slot.Place:SetAttribute("Available", owner ~= nil)
		slot.Place.Enabled = owner ~= nil
		slot.Sell:SetAttribute("Available", owner ~= nil and occupied)
		slot.Sell.Enabled = owner ~= nil and occupied
		slot.Sell.ActionText = "Sell egg +" .. tostring(occupied and slot.Economy.SellValue or 0)
		slot.Sell.ObjectText = occupied and slot.Definition.Name or "Empty pillow"
		slot.Model:SetAttribute("EggRarity", occupied and slot.Economy.Rarity or nil)
		slot.Model:SetAttribute("OwnerUserId", owner and owner.UserId or nil)
		-- Keep the label above the larger rolled egg rather than inside its mesh.
		slot.Label.Parent.StudsOffset = Vector3.new(0, 6.5 + (occupied and 4 * (slot.Economy.Scale - 1) or 0), 0)
		slot.Label.Text = occupied
			and string.format("%s%s\n+%d coins/sec", slot.Definition.Name,
				slot.Economy.Tier ~= "Standard" and " • " .. slot.Economy.Tier or "", slot.Economy.Income)
			or "EMPTY PILLOW " .. slot.Index
	end

	local function changeRate()
		local rate = 0
		for _, slot in ipairs(slots) do
			if slot.Egg then
				rate += slot.Economy.Income
			end
		end
		ledger:setRate(rate, os.clock())
		publish()
	end

	local function eligible(player, rootPart, interaction)
		if player.Parent ~= Players or not interaction.Enabled then return nil end
		if player ~= owner then
			notice(player, "This is another player's camp. Use your own pillows and blue pad.")
			return nil
		end
		if player:GetAttribute("CurrentBiome") ~= "Base Camp" or player:GetAttribute("PortalTraveling") then return nil end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or humanoid.Health <= 0 or not root or root.Anchored
			or not ((root.Position - rootPart.Position).Magnitude <= interaction.MaxActivationDistance) then return nil end
		local now = os.clock()
		if now - (lastAction[player] or -math.huge) < 0.5 then return nil end
		local stats = player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins")
		if not coins or not coins:IsA("IntValue") then return nil end
		lastAction[player] = now
		return coins
	end

	local function place(player, slot, coins)
		local record = callbacks.peek(player)
		if not record then
			notice(player, "Bring a carried egg to this pillow first.")
			return false
		end
		local definition = record.Source.Definition
		local economy = record.Economy
		if not Rolls.valid(definition.Template, economy) then return false end
		-- Build before consuming cargo. A failed visual cannot lose a player's egg.
		local ok, egg = pcall(Visuals.create, record.Cargo, slot.Anchor, definition, economy, player.UserId)
		if not ok then
			warn("Collection display failed: " .. tostring(egg))
			return false
		end
		if not callbacks.consume(player, record) then
			egg:Destroy()
			return false
		end
		-- No yields during consumption, replacement, accounting or publication.
		ledger:accrue(os.clock())
		local sold = 0
		if slot.Egg then
			sold = slot.Economy.SellValue
			slot.Egg:Destroy()
			coins.Value += sold
		end
		slot.Egg, slot.Definition, slot.Economy = egg, definition, economy
		egg.Parent = slot.Model
		refreshSlot(slot)
		changeRate()
		notice(player, definition.Name .. " placed! +" .. economy.Income .. " coins/sec"
			.. (sold > 0 and " • old egg sold +" .. sold or ""))
		return true
	end

	local function sell(player, slot)
		local coins = eligible(player, slot.Root, slot.Sell)
		if not coins or not slot.Egg then return false end
		ledger:accrue(os.clock())
		local name, amount = slot.Definition.Name, slot.Economy.SellValue
		slot.Egg:Destroy()
		slot.Egg, slot.Definition, slot.Economy = nil, nil, nil
		coins.Value += amount
		refreshSlot(slot)
		changeRate()
		notice(player, name .. " sold for " .. amount .. " coins.")
		return true
	end

	local models = folder:GetChildren()
	table.sort(models, function(a, b)
		return (a:GetAttribute("SlotIndex") or 0) < (b:GetAttribute("SlotIndex") or 0)
	end)
	for _, model in ipairs(models) do
		if model:IsA("Model") then
			local root = model:FindFirstChild("SlotRoot")
			local anchor = root and root:FindFirstChild("EggAnchor")
			assert(root and root:IsA("BasePart") and anchor and anchor:IsA("Attachment"), "Invalid camp pillow: " .. model.Name)
			assert(not model:FindFirstChild("DisplayedEgg"), "Keep runtime DisplayedEgg out of the saved scene")
			local slot = {Model = model, Root = root, Anchor = anchor, Index = model:GetAttribute("SlotIndex") or #slots + 1}
			slot.Place = prompt(root, "PlaceEgg", Enum.KeyCode.E, Enum.KeyCode.ButtonX, 0.3)
			slot.Sell = prompt(root, "SellEgg", Enum.KeyCode.F, Enum.KeyCode.ButtonY, Config.SellHold)
			slot.Label = Visuals.label(root, "EggDisplaySign")
			table.insert(slots, slot)
			refreshSlot(slot)
			slot.Place.Triggered:Connect(function(player)
				local coins = eligible(player, root, slot.Place)
				if coins then
					place(player, slot, coins)
				end
			end)
			slot.Sell.Triggered:Connect(function(player)
				sell(player, slot)
			end)
		end
	end
	assert(#slots > 0, "Collection needs at least one pillow")

	local function useDeposit(player)
		local coins = eligible(player, pad, deposit)
		if not coins then return false end
		if callbacks.peek(player) then
			for _, slot in ipairs(slots) do
				if not slot.Egg then
					return place(player, slot, coins)
				end
			end
			notice(player, "Pillows full! At a pillow: hold E to replace or F to sell.")
			return
		end
		local amount = ledger:collect(os.clock())
		coins.Value += amount
		publish()
		notice(player, amount > 0 and "Collected " .. amount .. " coins!" or "No income ready yet. Placed eggs earn while you play.")
		return true
	end
	deposit.Triggered:Connect(useDeposit)

	function api:claim(player)
		if owner or player.Parent ~= Players then return false end
		owner = player
		refreshPlotSign()
		plot:SetAttribute("OwnerUserId", player.UserId)
		for _, slot in ipairs(slots) do
			refreshSlot(slot)
		end
		publish()
		return true
	end

	function api:release(player)
		if owner ~= player then return false end
		owner = nil
		refreshPlotSign()
		ledger = Income.new(os.clock())
		lastAction[player] = nil
		plot:SetAttribute("OwnerUserId", nil)
		for _, slot in ipairs(slots) do
			if slot.Egg then
				slot.Egg:Destroy()
			end
			slot.Egg, slot.Definition, slot.Economy = nil, nil, nil
			refreshSlot(slot)
		end
		publish()
		return true
	end

	function api:isAvailable()
		return owner == nil
	end

	function api:publish()
		publish()
	end

	-- Server-only transaction entry shared by native prompts and Studio tests.
	-- Every call still validates private ownership, living state and proximity.
	function api:use(player, action, index)
		if action == "Deposit" then
			return useDeposit(player)
		end
		local slot = slots[index]
		if not slot then return false end
		if action == "Place" then
			local coins = eligible(player, slot.Root, slot.Place)
			return coins and place(player, slot, coins) or false
		elseif action == "Sell" then
			return sell(player, slot)
		end
		return false
	end

	refreshPlotSign()
	publish()
	return api
end

return Plot
