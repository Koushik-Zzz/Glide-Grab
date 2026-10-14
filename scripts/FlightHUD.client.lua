-- Rojo manages FlightHUD in StarterPlayer > StarterPlayerScripts.
-- Reads EggLoop cargo and PortalLoop's CurrentBiome player attribute.
-- Reads Coins and the server-created CarriedEgg. Rewards stay on the server.
-- Compact HUD: coins, objective banner, carried egg badge, animated reward.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local existing = playerGui:FindFirstChild("GlideAndGrabHUD")
if existing then
	warn("FlightHUD already exists. Keep only one FlightHUD LocalScript.")
	return
end

local colors = {
	ink = Color3.fromRGB(35, 58, 68),
	muted = Color3.fromRGB(82, 111, 120),
	cream = Color3.fromRGB(255, 252, 237),
	gold = Color3.fromRGB(255, 202, 62),
	goldEdge = Color3.fromRGB(187, 119, 26),
	mint = Color3.fromRGB(221, 255, 240),
	teal = Color3.fromRGB(28, 130, 110),
	amber = Color3.fromRGB(255, 235, 179),
	white = Color3.fromRGB(255, 255, 255),
}

local gui = Instance.new("ScreenGui")
gui.Name = "GlideAndGrabHUD"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.DisplayOrder = 10
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local canvas = Instance.new("Frame")
canvas.Name = "SafeScreen"
canvas.Size = UDim2.fromScale(1, 1)
canvas.BackgroundTransparency = 1
canvas.Parent = gui

local function round(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = object
end

local function outline(object, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = object
	return stroke
end

local function frame(parent, name, position, size, color, radius)
	local object = Instance.new("Frame")
	object.Name = name
	object.Position = position
	object.Size = size
	object.BackgroundColor3 = color
	object.BorderSizePixel = 0
	object.Parent = parent
	if radius then
		round(object, radius)
	end
	return object
end

local function label(parent, name, position, size, text, fontSize, color, font)
	local object = Instance.new("TextLabel")
	object.Name = name
	object.Position = position
	object.Size = size
	object.BackgroundTransparency = 1
	object.Font = font or Enum.Font.Gotham
	object.TextSize = fontSize
	object.TextColor3 = color
	object.TextXAlignment = Enum.TextXAlignment.Left
	object.TextYAlignment = Enum.TextYAlignment.Center
	object.Text = text
	object.Parent = parent
	return object
end

-- All icons are made from UI shapes, so they need no uploaded image assets.
local coinCard = frame(canvas, "Coins", UDim2.fromOffset(16, 14), UDim2.fromOffset(166, 78), colors.cream, 18)
outline(coinCard, colors.ink, 3)
local coinScale = Instance.new("UIScale")
coinScale.Parent = coinCard
local coinIcon = frame(coinCard, "CoinIcon", UDim2.fromOffset(12, 10), UDim2.fromOffset(38, 38), colors.gold, 38)
outline(coinIcon, colors.goldEdge, 2)
local coinRim = frame(coinIcon, "Rim", UDim2.fromOffset(6, 6), UDim2.fromOffset(26, 26), colors.gold, 26)
outline(coinRim, colors.cream, 2)
local currency = label(coinRim, "Symbol", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), "$", 20, colors.goldEdge, Enum.Font.GothamBlack)
currency.TextXAlignment = Enum.TextXAlignment.Center
label(coinCard, "Caption", UDim2.fromOffset(62, 7), UDim2.fromOffset(92, 15), "COINS", 10, colors.muted, Enum.Font.GothamBold)
local coinLabel = label(coinCard, "Amount", UDim2.fromOffset(62, 22), UDim2.fromOffset(92, 30), "--", 26, colors.ink, Enum.Font.GothamBlack)
coinLabel.TextScaled = true
local amountLimit = Instance.new("UITextSizeConstraint")
amountLimit.MinTextSize = 14
amountLimit.MaxTextSize = 26
amountLimit.Parent = coinLabel
local incomeLabel = label(coinCard, "Income", UDim2.fromOffset(12, 55), UDim2.fromOffset(142, 17), "+0/sec • Ready: 0", 11, colors.teal, Enum.Font.GothamBold)
incomeLabel.TextScaled = true
local incomeLimit = Instance.new("UITextSizeConstraint")
incomeLimit.MinTextSize = 9
incomeLimit.MaxTextSize = 11
incomeLimit.Parent = incomeLabel
local function refreshIncome()
	incomeLabel.Text = string.format("+%d/sec • Ready: %d", player:GetAttribute("EggIncomeRate") or 0, player:GetAttribute("EggIncomePending") or 0)
end
player:GetAttributeChangedSignal("EggIncomeRate"):Connect(refreshIncome)
player:GetAttributeChangedSignal("EggIncomePending"):Connect(refreshIncome)
refreshIncome()

local missionCard = frame(canvas, "Objective", UDim2.new(0.5, 0, 0, 14), UDim2.fromOffset(326, 58), colors.mint, 18)
missionCard.AnchorPoint = Vector2.new(0.5, 0)
outline(missionCard, colors.ink, 3)
local missionIcon = frame(missionCard, "RouteIcon", UDim2.fromOffset(12, 11), UDim2.fromOffset(36, 36), colors.teal, 36)
local direction = label(missionIcon, "Direction", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), ">", 25, colors.white, Enum.Font.GothamBlack)
direction.TextXAlignment = Enum.TextXAlignment.Center
local missionTitle = label(missionCard, "Title", UDim2.fromOffset(60, 8), UDim2.new(1, -72, 0, 22), "Explore Meadow", 18, colors.ink, Enum.Font.GothamBold)
local missionHint = label(missionCard, "Hint", UDim2.fromOffset(60, 31), UDim2.new(1, -72, 0, 17), "Enter the green Meadow portal", 12, colors.muted)
missionTitle.TextScaled = true
missionHint.TextScaled = true
for _, entry in ipairs({{missionTitle, 18}, {missionHint, 12}}) do
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 10
	limit.MaxTextSize = entry[2]
	limit.Parent = entry[1]
end

local cargoCard = frame(canvas, "Cargo", UDim2.new(0.5, 0, 1, -90), UDim2.fromOffset(268, 56), colors.amber, 18)
cargoCard.AnchorPoint = Vector2.new(0.5, 1)
cargoCard.Visible = false
outline(cargoCard, colors.ink, 3)
local cargoScale = Instance.new("UIScale")
cargoScale.Parent = cargoCard
local eggIcon = frame(cargoCard, "EggIcon", UDim2.fromOffset(18, 10), UDim2.fromOffset(26, 35), colors.cream, 26)
eggIcon.Rotation = -10
outline(eggIcon, colors.goldEdge, 2)
frame(eggIcon, "Spot1", UDim2.fromOffset(5, 12), UDim2.fromOffset(7, 8), colors.gold, 7)
frame(eggIcon, "Spot2", UDim2.fromOffset(15, 22), UDim2.fromOffset(6, 6), colors.gold, 6)
local cargoName = label(cargoCard, "EggName", UDim2.fromOffset(58, 7), UDim2.new(1, -70, 0, 24), "Common Egg", 17, colors.ink, Enum.Font.GothamBold)
local cargoValue = label(cargoCard, "Value", UDim2.fromOffset(58, 31), UDim2.new(1, -70, 0, 17), "+1 coin/sec when placed", 12, colors.goldEdge)

local windCard = frame(canvas, "WindWarning", UDim2.new(0.5, 0, 0, 84), UDim2.fromOffset(326, 42), colors.ink, 12)
windCard.AnchorPoint = Vector2.new(0.5, 0)
windCard.Visible = false
local windText = label(windCard, "Status", UDim2.fromOffset(12, 4), UDim2.new(1, -24, 1, -8), "", 14, colors.mint, Enum.Font.GothamBold)
windText.TextXAlignment = Enum.TextXAlignment.Center
windText.TextWrapped = true

local pickupNotice = label(canvas, "PickupNotice", UDim2.new(0.5, 0, 1, -192), UDim2.fromOffset(320, 32), "", 20, colors.mint, Enum.Font.GothamBold)
pickupNotice.AnchorPoint = Vector2.new(0.5, 0)
pickupNotice.TextXAlignment = Enum.TextXAlignment.Center
pickupNotice.TextStrokeTransparency = 0.25
pickupNotice.Visible = false
local pickupVersion = 0
local pickupTween = nil

local function showPickup(name)
	pickupVersion = pickupVersion + 1
	local version = pickupVersion
	if pickupTween then
		pickupTween:Cancel()
	end
	pickupNotice.Text = "Got " .. name .. "!"
	pickupNotice.TextTransparency = 0
	pickupNotice.TextStrokeTransparency = 0.25
	pickupNotice.Visible = true
	task.delay(1.1, function()
		if pickupVersion ~= version then return end
		pickupTween = TweenService:Create(pickupNotice, TweenInfo.new(0.35), {TextTransparency = 1, TextStrokeTransparency = 1})
		pickupTween:Play()
	end)
	task.delay(1.5, function()
		if pickupVersion == version then
			pickupNotice.Visible = false
		end
	end)
end

local function refreshWind()
	local combatMessage = player:GetAttribute("PvPMessage")
	if combatMessage and not player:GetAttribute("PortalTraveling") then
		windCard.Visible = true
		windText.Text = combatMessage
		windText.TextColor3 = colors.amber
		return
	end
	local state = player:GetAttribute("MeadowWindState")
	local guardianMessage = player:GetAttribute("GuardianMessage")
	local collectionMessage = player:GetAttribute("CollectionMessage")
	if collectionMessage and player:GetAttribute("CurrentBiome") == "Base Camp"
		and not player:GetAttribute("PortalTraveling") then
		windCard.Visible = true
		windText.Text = collectionMessage
		windText.TextColor3 = colors.mint
		return
	end
	if guardianMessage and guardianMessage ~= "" and not player:GetAttribute("PortalTraveling") then
		windCard.Visible = true
		windText.Text = guardianMessage
		windText.TextColor3 = colors.amber
		return
	end
	windCard.Visible = state ~= nil and state ~= "" and not player:GetAttribute("PortalTraveling")
	windText.Text = state == "Gust" and "CROSSWIND → steer against it or go around"
		or state == "Warning" and "Wind picking up — get ready to steer!"
		or "Wind is calm — a good time to cross"
	windText.TextColor3 = state == "Calm" and colors.mint or colors.amber
end
player:GetAttributeChangedSignal("MeadowWindState"):Connect(refreshWind)
player:GetAttributeChangedSignal("GuardianMessage"):Connect(refreshWind)
player:GetAttributeChangedSignal("PvPMessage"):Connect(refreshWind)
player:GetAttributeChangedSignal("PortalTraveling"):Connect(refreshWind)
player:GetAttributeChangedSignal("CollectionMessage"):Connect(refreshWind)
player:GetAttributeChangedSignal("CurrentBiome"):Connect(refreshWind)
refreshWind()

local rewardLabel = label(canvas, "CoinReward", UDim2.fromOffset(24, 80), UDim2.fromOffset(100, 35), "", 25, colors.gold, Enum.Font.GothamBlack)
rewardLabel.Visible = false
local rewardStroke = Instance.new("UIStroke")
rewardStroke.Color = colors.ink
rewardStroke.Thickness = 2
rewardStroke.Parent = rewardLabel

local function layout()
	local width = canvas.AbsoluteSize.X
	if width <= 0 then return end
	local compact = canvas.AbsoluteSize.Y < 540 and width >= 460
	-- Stack the banner below coins on narrow windows and phone screens.
	missionCard.AnchorPoint = Vector2.new(0.5, 0)
	windCard.AnchorPoint = Vector2.new(0.5, 0)
	missionCard.Position = UDim2.new(0.5, 0, 0, width < 760 and 104 or 14)
	missionCard.Size = UDim2.fromOffset(math.min(326, math.max(180, width - 32)), 58)
	windCard.Position = UDim2.new(0.5, 0, 0, width < 760 and 174 or 84)
	windCard.Size = UDim2.fromOffset(math.min(326, math.max(180, width - 32)), 42)
	cargoCard.Size = UDim2.fromOffset(math.min(268, math.max(180, width - 32)), 56)
	-- Leave a centered slot for the boost action above the default hotbar on touch/narrow screens.
	local centeredBoost = not compact and (width < 760 or UserInputService.TouchEnabled)
	cargoCard.Position = UDim2.new(0.5, 0, 1, centeredBoost and -158 or -90)
	pickupNotice.Position = UDim2.new(0.5, 0, 1, centeredBoost and -238 or -192)
	if compact then
		missionCard.AnchorPoint = Vector2.new(1, 0)
		missionCard.Position = UDim2.new(1, -16, 0, 14)
		missionCard.Size = UDim2.fromOffset(math.min(326, width - 214), 58)
		windCard.AnchorPoint = Vector2.zero
		windCard.Position = UDim2.fromOffset(16, 104)
		windCard.Size = UDim2.fromOffset(math.min(326, width - 228), 42)
		pickupNotice.Position = UDim2.new(0.5, 0, 1, -86)
	end
end
canvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
gui.Parent = playerGui
layout()

local rewardVersion = 0
local rewardTween = nil
local rewardStrokeTween = nil
local coinTween = nil
local cargoTween = nil

local function showReward(gain)
	rewardVersion = rewardVersion + 1
	local version = rewardVersion
	if rewardTween then
		rewardTween:Cancel()
	end
	if rewardStrokeTween then
		rewardStrokeTween:Cancel()
	end
	if coinTween then
		coinTween:Cancel()
	end
	local narrow = canvas.AbsoluteSize.X < 760
	local rewardX = narrow and math.min(196, canvas.AbsoluteSize.X - 112) or 24
	local rewardY = narrow and 25 or 108
	rewardLabel.Text = "+" .. tostring(gain)
	rewardLabel.Position = UDim2.fromOffset(rewardX, rewardY)
	rewardLabel.TextTransparency = 0
	rewardStroke.Transparency = 0
	rewardLabel.Visible = true
	coinScale.Scale = 1.08
	coinTween = TweenService:Create(coinScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
	coinTween:Play()
	task.delay(0.65, function()
		if version ~= rewardVersion then return end
		rewardTween = TweenService:Create(rewardLabel, TweenInfo.new(0.65), {
			Position = UDim2.fromOffset(rewardX, rewardY - 17), TextTransparency = 1,
		})
		rewardTween:Play()
		rewardStrokeTween = TweenService:Create(rewardStroke, TweenInfo.new(0.65), {Transparency = 1})
		rewardStrokeTween:Play()
	end)
	task.delay(1.35, function()
		if version == rewardVersion then
			rewardLabel.Visible = false
		end
	end)
end

local character = nil
local characterConnections = {}

local function refreshCargo()
	local inMeadow = player:GetAttribute("CurrentBiome") == "Meadow"
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local egg = character and character:FindFirstChild("CarriedEgg")
	local carrying = character and humanoid and humanoid.Health > 0
		and egg ~= nil
	local wasVisible = cargoCard.Visible
	cargoCard.Visible = carrying and true or false
	if carrying then
		local tier = egg:GetAttribute("EggTier")
		cargoName.Text = (egg:GetAttribute("EggName") or "Common Egg")
			.. (tier and tier ~= "Standard" and " • " .. tier or "")
		cargoValue.Text = "+" .. tostring(egg:GetAttribute("IncomeRate") or 1) .. " coins/sec when placed"
		local capacity = player:GetAttribute("EggDisplayCapacity") or 6
		local full = capacity > 0 and (player:GetAttribute("EggDisplayCount") or 0) >= capacity
		missionTitle.Text = inMeadow and "Fly back to camp!" or (full and "Pillows full!" or "Place your egg!")
		missionHint.Text = inMeadow and "Fly to the blue return portal" or (full and "At a pillow: hold E replace / F sell" or "Use E at your pillow or blue pad")
		missionCard.BackgroundColor3 = colors.amber
		missionIcon.BackgroundColor3 = colors.goldEdge
		if not wasVisible then
			showPickup(cargoName.Text)
			if cargoTween then
				cargoTween:Cancel()
			end
			cargoScale.Scale = 0.88
			cargoTween = TweenService:Create(cargoScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
			cargoTween:Play()
		end
	else
		local pending = player:GetAttribute("EggIncomePending") or 0
		missionTitle.Text = inMeadow and "Glide and find an egg" or (pending > 0 and "Income ready!" or "Explore Meadow")
		missionHint.Text = inMeadow and "Fly between the Meadow islands" or (pending > 0 and "Use E at your blue pad to collect" or "Enter the green Meadow portal")
		missionCard.BackgroundColor3 = colors.mint
		missionIcon.BackgroundColor3 = colors.teal
	end
	if not inMeadow and player:GetAttribute("EggDisplayCapacity") == 0 then
		missionTitle.Text = "Waiting for a camp"
		missionHint.Text = "All six gardens are occupied"
	end
end

player:GetAttributeChangedSignal("CurrentBiome"):Connect(refreshCargo)
player:GetAttributeChangedSignal("EggDisplayCapacity"):Connect(refreshCargo)
player:GetAttributeChangedSignal("EggDisplayCount"):Connect(refreshCargo)
player:GetAttributeChangedSignal("EggIncomePending"):Connect(refreshCargo)
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

player.CharacterAdded:Connect(bindCharacter)
player.CharacterRemoving:Connect(function(oldCharacter)
	if character == oldCharacter then
		disconnectCharacter()
		character = nil
		refreshCargo()
	end
end)
if player.Character then
	bindCharacter(player.Character)
end

-- Build the HUD first, then wait for the existing server coin counter.
task.spawn(function()
	local stats = player:WaitForChild("leaderstats", 15)
	local coins = stats and stats:WaitForChild("Coins", 15)
	if not coins or not coins:IsA("IntValue") then
		warn("FlightHUD: Coins not found. Check EggLoop in ServerScriptService.")
		return
	end
	local previous = coins.Value
	local function refreshCoins()
		local current = coins.Value
		if current >= 1000000 then
			coinLabel.Text = string.format("%.1fM", current / 1000000)
		elseif current >= 10000 then
			coinLabel.Text = string.format("%.1fK", current / 1000)
		else
			coinLabel.Text = tostring(current)
		end
		local gain = current - previous
		previous = current
		if gain > 0 then
			showReward(gain)
		end
	end
	coins:GetPropertyChangedSignal("Value"):Connect(refreshCoins)
	refreshCoins()
end)
