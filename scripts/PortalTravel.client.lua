-- Portal presentation and streaming checks. Only the server chooses destinations.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local uiModules = ReplicatedStorage:WaitForChild("UIModules")
local Theme = require(uiModules.Theme)
local Notices = require(uiModules.Notices)
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("PortalTravel")

local gui = Instance.new("ScreenGui")
gui.Name = "PortalTravelUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local curtain = Instance.new("Frame")
curtain.Name = "Curtain"
curtain.Size = UDim2.fromScale(1, 1)
curtain.BackgroundColor3 = Color3.fromRGB(13, 30, 47)
curtain.BackgroundTransparency = 1
curtain.BorderSizePixel = 0
curtain.Active = true
curtain.Visible = false
curtain.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "Destination"
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.46)
title.Size = UDim2.new(0.9, 0, 0, 55)
title.BackgroundTransparency = 1
title.TextColor3 = Theme.Sky
title.TextSize = 38
title.Font = Enum.Font.FredokaOne
title.TextStrokeColor3 = Theme.Ink
title.TextStrokeTransparency = 0
title.TextTransparency = 1
title.Text = ""
title.Parent = curtain

local hint = title:Clone()
hint.Name = "Hint"
hint.Position = UDim2.fromScale(0.5, 0.54)
hint.TextSize = 17
hint.Font = Enum.Font.Gotham
hint.TextColor3 = Theme.White
hint.TextStrokeTransparency = 1
hint.Text = "Getting your landing area ready…"
hint.Parent = curtain

gui.Parent = player:WaitForChild("PlayerGui")

local activeId = nil
local revision = 0
local tweens = {}

local function showNotice(message)
	Notices.show(message, 4)
end

local function fade(covered, version)
	for _, tween in ipairs(tweens) do
		tween:Cancel()
	end
	local transparency = covered and 0 or 1
	local duration = GuiService.ReducedMotionEnabled and 0.05 or 0.22
	tweens = {
		TweenService:Create(curtain, TweenInfo.new(duration), {BackgroundTransparency = transparency}),
		TweenService:Create(title, TweenInfo.new(duration), {TextTransparency = transparency}),
		TweenService:Create(hint, TweenInfo.new(duration), {TextTransparency = transparency}),
	}
	curtain.Visible = true
	for _, tween in ipairs(tweens) do
		tween:Play()
	end
	task.wait(0.24)
	if revision == version and not covered then
		curtain.Visible = false
	end
end

local function floorReady(biome, position)
	local floor
	if biome == "Base Camp" then
		floor = Workspace:FindFirstChild("HomeIsland")
	elseif biome == "Meadow" then
		local map = Workspace:FindFirstChild("Map")
		local meadow = map and map:FindFirstChild("Meadow")
		floor = meadow and meadow:FindFirstChild("MeadowEntrance")
	elseif biome == "Storm Isles" then
		local map = Workspace:FindFirstChild("Map")
		local storm = map and map:FindFirstChild("StormIsles")
		floor = storm and storm:FindFirstChild("StormEntrance")
	end
	if not floor or not floor:IsA("BasePart") or not floor.Anchored or not floor.CanCollide then return false end
	local localPoint = floor.CFrame:PointToObjectSpace(position)
	return math.abs(localPoint.X) < floor.Size.X / 2
		and math.abs(localPoint.Z) < floor.Size.Z / 2
		and math.abs(localPoint.Y - floor.Size.Y / 2) < 10
end

local function resetPresentation()
	revision = revision + 1
	activeId = nil
	for _, tween in ipairs(tweens) do
		tween:Cancel()
	end
	curtain.Visible = false
	curtain.BackgroundTransparency = 1
	title.TextTransparency = 1
	hint.TextTransparency = 1
end

remote.OnClientEvent:Connect(function(action, id, position, biome, recovery)
	if action == "Notice" then
		showNotice(id)
		return
	end
	if action == "Prepare" then
		revision = revision + 1
		local version = revision
		activeId = id
		Notices.clear()
		title.Text = recovery and ("Returning to " .. biome) or biome
		hint.Text = recovery and "Stay inside the biome and use its portals to travel." or "Getting your landing area ready…"
		-- The server has its own deadlines and unfreezes cancelled trips. This
		-- watchdog prevents an interrupted client callback leaving a black screen.
		task.delay(40, function()
			if activeId == id and revision == version then
				remote:FireServer("Cancel", id)
				resetPresentation()
				showNotice("Travel was interrupted. Please try again.")
			end
		end)
		fade(true, version)
		if activeId ~= id or revision ~= version then return end
		local deadline = os.clock() + 20
		-- The server prefetches and holds the destination in streaming range.
		-- Inspect replication immediately rather than waiting for a yielding
		-- request before checking an already-loaded floor.
		while activeId == id and revision == version and os.clock() < deadline do
			if floorReady(biome, position) then
				remote:FireServer("Ready", id)
				return
			end
			task.wait(0.1)
		end
		if activeId == id and revision == version then
			warn("PortalTravel: landing floor unavailable for " .. biome)
			remote:FireServer("Cancel", id)
		end
	elseif activeId == id and action == "Arrive" then
		local version = revision
		local deadline = os.clock() + 10
		while activeId == id and revision == version and os.clock() < deadline do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and (root.Position - position).Magnitude <= 14 and floorReady(biome, position) then
				remote:FireServer("Arrived", id)
				return
			end
			task.wait(0.1)
		end
		if activeId == id and revision == version then
			warn("PortalTravel: arrival was not confirmed for " .. biome)
			remote:FireServer("Cancel", id)
		end
	elseif activeId == id and (action == "Complete" or action == "Cancel") then
		activeId = nil
		revision = revision + 1
		local version = revision
		fade(false, version)
		if revision == version and action == "Cancel" then
			showNotice(position)
		end
	end
end)

player.CharacterRemoving:Connect(function()
	if activeId then
		remote:FireServer("Cancel", activeId)
	end
	resetPresentation()
	Notices.clear()
end)
remote:FireServer("ClientReady")
