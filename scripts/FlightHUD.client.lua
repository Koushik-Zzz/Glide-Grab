-- Render the editable StarterGui shell; all rewards and cargo remain server owned.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RS = game:GetService("ReplicatedStorage")
local modules = RS:WaitForChild("UIModules")
local Theme = require(modules.Theme)
local Layout = require(modules.Layout)
local Motion = require(modules.Motion)
local Notices = require(modules.Notices)
local CoinPopFX = require(modules.CoinPopFX)
local motion = Motion.new()
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("GlideAndGrabHUD")
local canvas = gui.SafeScreen
local coinCard, missionCard, cargoCard, windCard = canvas.Coins, canvas.Objective, canvas.Cargo, canvas.WindWarning
local coinLabel, incomeLabel, saveCaption = coinCard.Amount, coinCard.Income, coinCard.Caption
local coinScale, cargoScale = coinCard.FeedbackScale, cargoCard.FeedbackScale
local coinFX = CoinPopFX.new(canvas, coinLabel)
local missionIcon = missionCard.Direction
local missionTitle, missionHint = missionCard.Title, missionCard.Hint
local cargoName, cargoValue = cargoCard.EggName, cargoCard.Value
local windText, pickupNotice = windCard.Status, canvas.PickupNotice
local colors = {gold = Theme.Gold, mint = Theme.Sky, amber = Theme.Gold, white = Theme.White}
local missionBaseHint = "Use a camp portal to explore"
local connections, alive = {}, true
local function track(connection)
	table.insert(connections, connection)
	return connection
end
local function refreshSave()
	local status = player:GetAttribute("SaveStatus")
	saveCaption.Text = "COINS"
	coinCard.SaveHint.Text = status == "Preview only" and "Studio preview" or status == "Loading progress" and "Loading progress..."
		or (status ~= "Saved" and "Saving retry..." or "")
end
track(player:GetAttributeChangedSignal("SaveStatus"):Connect(refreshSave))
refreshSave()
local function refreshIncome()
	incomeLabel.Text = "+" .. Theme.short(player:GetAttribute("EggIncomeRate")) .. "/sec   |   Ready: "
		.. Theme.short(player:GetAttribute("EggIncomePending"))
end
track(player:GetAttributeChangedSignal("EggIncomeRate"):Connect(refreshIncome))
track(player:GetAttributeChangedSignal("EggIncomePending"):Connect(refreshIncome))
refreshIncome()
local pickupVersion = 0
local pickupTween = nil

local function showPickup(name)
	-- The compact landscape composition already shows the cargo summary beside
	-- the controls; an extra floating line would obscure the boost button.
	if Layout.forSize(canvas.AbsoluteSize, UserInputService.TouchEnabled).Mode == "Compact" then return end
	pickupVersion = pickupVersion + 1
	local version = pickupVersion
	if pickupTween then
		pickupTween:Cancel()
	end
	pickupNotice.Text = "Got " .. name .. "!"
	pickupNotice.TextTransparency = 0
	pickupNotice.Outline.Transparency = 0
	pickupNotice.Visible = true
	task.delay(1.1, function()
		if not alive or pickupVersion ~= version then return end
		pickupTween = TweenService:Create(pickupNotice, TweenInfo.new(0.35), {TextTransparency = 1})
		pickupTween:Play()
		motion:to(pickupNotice.Outline, 0.35, {Transparency = 1})
	end)
	task.delay(1.5, function()
		if alive and pickupVersion == version then
			pickupNotice.Visible = false
		end
	end)
end

local function refreshWind()
	local traveling = player:GetAttribute("PortalTraveling")
	local message = Notices.current() or player:GetAttribute("PvPMessage")
	local state = player:GetAttribute("MeadowWindState")
	local collection = player:GetAttribute("CollectionMessage")
	local guardian = player:GetAttribute("GuardianMessage")
	if not message and player:GetAttribute("CurrentBiome") == "Base Camp" then
		message = collection
	end
	if not message and guardian and guardian ~= "" then
		message = guardian
	end
	local velocity = player:GetAttribute("MeadowWindVelocity")
	local arrow = typeof(velocity) == "Vector3" and velocity.X < 0 and "←" or "→"
	local visible = (message ~= nil or (state ~= nil and state ~= "")) and not traveling
	windText.Text = message or (state == "Gust" and ("CROSSWIND " .. arrow .. " Steer against it!")
		or state == "Warning" and "Wind picking up • get ready!" or "Calm winds • a good time to cross")
	windText.TextColor3 = message and colors.amber or state == "Calm" and colors.mint or colors.amber
	local regions = Layout.forSize(canvas.AbsoluteSize, UserInputService.TouchEnabled)
	windCard.Visible = visible and not regions.HideWind
	missionHint.Text = regions.HideWind and visible and windText.Text or missionBaseHint
end
track(Notices.subscribe(refreshWind))
track(player:GetAttributeChangedSignal("MeadowWindState"):Connect(refreshWind))
track(player:GetAttributeChangedSignal("MeadowWindVelocity"):Connect(refreshWind))
track(player:GetAttributeChangedSignal("GuardianMessage"):Connect(refreshWind))
track(player:GetAttributeChangedSignal("PvPMessage"):Connect(refreshWind))
track(player:GetAttributeChangedSignal("PortalTraveling"):Connect(refreshWind))
track(player:GetAttributeChangedSignal("CollectionMessage"):Connect(refreshWind))
track(player:GetAttributeChangedSignal("CurrentBiome"):Connect(refreshWind))
refreshWind()

canvas.CoinReward.Visible = false
local hasCargo = false

local function layout()
	local size = canvas.AbsoluteSize
	if size.X <= 0 then return end
	local regions = Layout.forSize(size, UserInputService.TouchEnabled)
	cargoCard.Visible = hasCargo and not regions.HideCargo
	for name, object in pairs({Coins = coinCard, Objective = missionCard, Cargo = cargoCard, Wind = windCard}) do
		Layout.place(object, regions[name])
	end
	local small = regions.Coins[3] < 240
	local mini = regions.Coins[4] <= 80
	coinCard.Income.Position = mini and UDim2.fromOffset(10, 50) or UDim2.new(0, 14, 1, -36)
	coinCard.Income.Size = UDim2.new(1, mini and -20 or -28, 0, mini and 20 or 22)
	coinCard.SaveHint.Visible = not mini
	coinCard.Icon.Size = UDim2.fromOffset(mini and 32 or small and 42 or 56, mini and 32 or small and 42 or 56)
	coinCard.Icon.Position = UDim2.fromOffset(10, mini and 14 or small and 20 or 22)
	coinLabel.Position = UDim2.fromOffset(small and 60 or 78, mini and 22 or 27)
	coinLabel.Size = UDim2.new(1, small and -70 or -90, 0, mini and 26 or small and 30 or 40)
	coinCard.Caption.Position = UDim2.fromOffset(small and 60 or 78, 9)
	coinCard.Caption.Size = UDim2.new(1, small and -70 or -90, 0, 17)
	missionHint.Position = UDim2.fromOffset(52, regions.Mode == "Wide" and 35 or 30)
	missionTitle.Size = UDim2.new(1, -66, 0, regions.Mode == "Wide" and 24 or 20)
	pickupNotice.Position = UDim2.fromOffset(regions.Cargo[1], regions.Cargo[2] - 36)
	pickupNotice.Size = UDim2.fromOffset(regions.Cargo[3], 30)
	refreshWind()
end
track(canvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
track(UserInputService.LastInputTypeChanged:Connect(layout))
layout()

local cargoTween = nil
local function showReward(gain)
	coinFX:reward(gain)
	motion:pop(coinScale, 1.035)
end

local character = nil
local characterConnections = {}

local function refreshCargo()
	local biome = player:GetAttribute("CurrentBiome")
	local inMeadow = biome == "Meadow" or biome == "Storm Isles"
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local egg = character and character:FindFirstChild("CarriedEgg")
	local carrying = character and humanoid and humanoid.Health > 0
		and egg ~= nil
	local wasCarrying = hasCargo
	hasCargo = carrying == true
	cargoCard.Visible = carrying and not Layout.forSize(canvas.AbsoluteSize, UserInputService.TouchEnabled).HideCargo or false
	if carrying then
		local tier = egg:GetAttribute("EggTier")
		cargoName.Text = (egg:GetAttribute("EggName") or "Common Egg")
			.. (tier and tier ~= "Standard" and " • " .. tier or "")
		cargoValue.Text = "+" .. Theme.short(egg:GetAttribute("IncomeRate") or 1) .. "/sec when placed"
		local capacity = player:GetAttribute("EggDisplayCapacity") or 6
		local full = capacity > 0 and (player:GetAttribute("EggDisplayCount") or 0) >= capacity
		missionTitle.Text = inMeadow and "Fly back to camp!" or (full and "Pillows full!" or "Place your egg!")
		missionHint.Text = inMeadow and "Fly to the blue return portal" or (full and "At a pillow: hold E replace / F sell" or "Use E at your pillow or blue pad")
		missionCard.BackgroundColor3 = colors.amber
		missionIcon.TextColor3 = colors.white
		if not wasCarrying then
			showPickup(cargoName.Text)
			if cargoTween then
				cargoTween:Cancel()
			end
			cargoScale.Scale = GuiService.ReducedMotionEnabled and 1 or 0.94
			cargoTween = TweenService:Create(cargoScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
			cargoTween:Play()
		end
	else
		local pending = player:GetAttribute("EggIncomePending") or 0
		missionTitle.Text = inMeadow and "Glide and find an egg" or (pending > 0 and "Income ready!" or "Explore Meadow")
		missionHint.Text = inMeadow and ("Fly between the " .. biome .. " islands") or (pending > 0 and "Use E at your blue pad to collect" or "Use a camp portal to explore")
		missionCard.BackgroundColor3 = colors.mint
		missionIcon.TextColor3 = colors.gold
	end
	if not inMeadow and player:GetAttribute("EggDisplayCapacity") == 0 then
		missionTitle.Text = "Waiting for a camp"
		missionHint.Text = "All six gardens are occupied"
	end
	missionBaseHint = missionHint.Text
	refreshWind()
end

track(player:GetAttributeChangedSignal("CurrentBiome"):Connect(refreshCargo))
track(player:GetAttributeChangedSignal("EggDisplayCapacity"):Connect(refreshCargo))
track(player:GetAttributeChangedSignal("EggDisplayCount"):Connect(refreshCargo))
track(player:GetAttributeChangedSignal("EggIncomePending"):Connect(refreshCargo))
refreshCargo()

local function disconnectCharacter()
	for _, connection in ipairs(characterConnections) do
		connection:Disconnect()
	end
	characterConnections = {}
end

local function bindCharacter(newCharacter)
	disconnectCharacter()
	character = newCharacter
	local watchedHumanoid = nil
	local function watchHumanoid()
		local humanoid = newCharacter:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid ~= watchedHumanoid then
			watchedHumanoid = humanoid
			table.insert(characterConnections, humanoid.Died:Connect(refreshCargo))
		end
	end
	table.insert(characterConnections, newCharacter.ChildAdded:Connect(function()
		watchHumanoid()
		refreshCargo()
	end))
	table.insert(characterConnections, newCharacter.ChildRemoved:Connect(refreshCargo))
	watchHumanoid()
	refreshCargo()
end

track(player.CharacterAdded:Connect(bindCharacter))
track(player.CharacterRemoving:Connect(function(oldCharacter)
	if character == oldCharacter then
		disconnectCharacter()
		character = nil
		refreshCargo()
	end
end))
if player.Character then
	bindCharacter(player.Character)
end

-- Build the HUD first, then wait for the existing server coin counter.
task.spawn(function()
	local stats = player:WaitForChild("leaderstats", 60)
	local coins = stats and stats:WaitForChild("Coins", 15)
	if not alive then return end
	if not coins or not coins:IsA("IntValue") then
		warn("FlightHUD: Coins not found. Check EggLoop in ServerScriptService.")
		return
	end
	local previous = coins.Value
	local displayed = Instance.new("NumberValue")
	displayed.Name = "DisplayedCoins"
	displayed.Value = previous
	displayed.Parent = gui
	track(displayed.Changed:Connect(function(value)
		coinLabel.Text = "$" .. Theme.short(value)
	end))
	script.Destroying:Once(function()
		displayed:Destroy()
	end)
	local function refreshCoins()
		local current = coins.Value
		if GuiService.ReducedMotionEnabled then
			displayed.Value = current
		else
			motion:to(displayed, 0.32, {Value = current})
		end
		coinLabel.Text = "$" .. Theme.short(displayed.Value)
		local gain = current - previous
		previous = current
		if gain > 0 then
			showReward(gain)
		end
	end
	track(coins:GetPropertyChangedSignal("Value"):Connect(refreshCoins))
	refreshCoins()
end)

script.Destroying:Connect(function()
	alive = false
	disconnectCharacter()
	motion:destroy()
	coinFX:destroy()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	for _, tween in pairs({pickupTween, cargoTween}) do
		tween:Cancel()
	end
end)
