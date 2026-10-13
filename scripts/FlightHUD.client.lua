-- Rojo manages FlightHUD in StarterPlayer > StarterPlayerScripts.
-- Reads EggLoop cargo and PortalLoop's CurrentBiome player attribute.
-- Reads Coins and the server-created CarriedEgg. Rewards stay on the server.
-- Compact HUD: coins, objective banner, carried egg badge, animated reward.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
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
local coinCard = frame(canvas, "Coins", UDim2.fromOffset(16, 14), UDim2.fromOffset(166, 58), colors.cream, 18)
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
local cargoValue = label(cargoCard, "Value", UDim2.fromOffset(58, 31), UDim2.new(1, -70, 0, 17), "+10 coins when banked", 12, colors.goldEdge)

local rewardLabel = label(canvas, "CoinReward", UDim2.fromOffset(24, 80), UDim2.fromOffset(100, 35), "", 25, colors.gold, Enum.Font.GothamBlack)
rewardLabel.Visible = false
local rewardStroke = Instance.new("UIStroke")
rewardStroke.Color = colors.ink
rewardStroke.Thickness = 2
rewardStroke.Parent = rewardLabel

local function layout()
	local width = canvas.AbsoluteSize.X
	if width <= 0 then return end
	-- Stack the banner below coins on narrow windows and phone screens.
	missionCard.Position = UDim2.new(0.5, 0, 0, width < 760 and 86 or 14)
	missionCard.Size = UDim2.fromOffset(math.min(326, math.max(180, width - 32)), 58)
	cargoCard.Size = UDim2.fromOffset(math.min(268, math.max(180, width - 32)), 56)
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
	local rewardY = narrow and 25 or 80
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
		cargoName.Text = egg:GetAttribute("EggName") or "Common Egg"
		cargoValue.Text = "+" .. tostring(egg:GetAttribute("BankValue") or 10) .. " coins when banked"
		missionTitle.Text = inMeadow and "Fly back to camp!" or "Bank your egg!"
		missionHint.Text = inMeadow and "Fly to the blue return portal" or "Bank your egg at the blue pad"
		missionCard.BackgroundColor3 = colors.amber
		missionIcon.BackgroundColor3 = colors.goldEdge
		if not wasVisible then
			if cargoTween then
				cargoTween:Cancel()
			end
			cargoScale.Scale = 0.88
			cargoTween = TweenService:Create(cargoScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
			cargoTween:Play()
		end
	else
		missionTitle.Text = inMeadow and "Glide and find an egg" or "Explore Meadow"
		missionHint.Text = inMeadow and "Fly between the Meadow islands" or "Enter the green Meadow portal"
		missionCard.BackgroundColor3 = colors.mint
		missionIcon.BackgroundColor3 = colors.teal
	end
end

player:GetAttributeChangedSignal("CurrentBiome"):Connect(refreshCargo)
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
