-- Rojo manages this script. The map and imported glider remain Studio-managed.
-- Map contract: anchored Workspace.HomeIsland is the camp floor; anchored
-- Workspace.Map.Meadow.MeadowEntrance is the Meadow landing floor.
-- These portals move the existing character in this place, preserving carried eggs.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Profiles = require(script.Parent:WaitForChild("DataModules"):WaitForChild("Profiles"))
local Progression = require(script.Parent:WaitForChild("ProgressionModules"):WaitForChild("Progression"))
local campAnchor = Workspace:WaitForChild("SharedCamp"):WaitForChild("Anchors"):WaitForChild("MeadowPortal")
local stormAnchor = Workspace.SharedCamp.Anchors:WaitForChild("StormPortal")

local function floorPart(parent, name)
	local part = parent:WaitForChild(name, 10)
	assert(part and part:IsA("BasePart") and part.Anchored,
		"PortalLoop: Create an anchored Part named " .. name .. " under " .. parent:GetFullName())
	return part
end

local home = floorPart(Workspace, "HomeIsland")
local map = Workspace:WaitForChild("Map", 10)
local meadow = map and map:WaitForChild("Meadow", 10)
assert(meadow, "PortalLoop: Create Workspace/Map/Meadow")
local entrance = floorPart(meadow, "MeadowEntrance")
local stormEntrance = floorPart(map:WaitForChild("StormIsles"), "StormEntrance")
assert(not Workspace:FindFirstChild("PortalLoopPrototype"), "Keep only one PortalLoop script")

local objects = Instance.new("Folder")
objects.Name = "PortalLoopPrototype"
objects.Parent = Workspace

local function part(parent, name, size, transform, color, material)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = transform
	object.Color = color
	object.Material = material or Enum.Material.SmoothPlastic
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.Parent = parent
	return object
end

local function makePortal(name, floor, x, z, color, title, action, description)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = objects
	local center = name == "MeadowPortal" and campAnchor.CFrame or name == "StormPortal" and stormAnchor.CFrame
		or floor.CFrame * CFrame.new(x, floor.Size.Y / 2 + 6, z)
	part(model, "LeftPost", Vector3.new(1.5, 12, 1.5), center * CFrame.new(-5, 0, 0), color, Enum.Material.Neon)
	part(model, "RightPost", Vector3.new(1.5, 12, 1.5), center * CFrame.new(5, 0, 0), color, Enum.Material.Neon)
	part(model, "Top", Vector3.new(11.5, 1.5, 1.5), center * CFrame.new(0, 6, 0), color, Enum.Material.Neon)
	part(model, "Step", Vector3.new(11.5, 0.4, 4), center * CFrame.new(0, -5.8, 0), color, Enum.Material.Neon)
	local field = part(model, "PortalField", Vector3.new(8.5, 10, 0.25), center, color, Enum.Material.Neon)
	field.Transparency = 0.72
	field.CanQuery = false

	local sign = Instance.new("BillboardGui")
	sign.Name = "PortalSign"
	sign.Size = UDim2.fromOffset(250, 55)
	sign.StudsOffset = Vector3.new(0, 8, 0)
	sign.AlwaysOnTop = true
	sign.MaxDistance = 150
	sign.Parent = field
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundColor3 = Color3.fromRGB(28, 43, 54)
	text.BackgroundTransparency = 0.15
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.Font = Enum.Font.GothamBold
	text.TextSize = 19
	text.Text = title
	text.Parent = sign
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = text

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TravelPrompt"
	prompt.ActionText = action
	prompt.ObjectText = description
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = field
	return field, prompt
end

local entryField, entryPrompt = makePortal("MeadowPortal", home, -22, -18,
	Color3.fromRGB(100, 255, 154), "MEADOW", "Enter Meadow", "Glide between islands and find eggs")
entryField:SetAttribute("RequiredRebirths", campAnchor:GetAttribute("RequiredRebirths"))
entryPrompt.ObjectText = "Meadow • " .. tostring(campAnchor:GetAttribute("RequiredRebirths")) .. "+ rebirths"
local exitField, exitPrompt = makePortal("CampReturnPortal", entrance, -12, 0,
	Color3.fromRGB(80, 200, 255), "BASE CAMP", "Return to camp", "Bring your egg home to display it")
local stormField, stormPrompt = makePortal("StormPortal", home, 0, 0,
	Color3.fromRGB(190, 137, 244), "STORM ISLES • 1 REBIRTH", "Enter Storm Isles", "1+ rebirths • stronger crosswinds")
stormField:SetAttribute("RequiredRebirths", 1)
local stormExitField, stormExitPrompt = makePortal("StormReturnPortal", stormEntrance, -12, 0,
	Color3.fromRGB(80, 200, 255), "BASE CAMP", "Return to camp", "Bring your Storm egg home")

-- Region membership is owned by the server. Crossing the gap cannot unlock a
-- biome, and the client never supplies a destination or a biome name to travel.
local regions = {
	["Base Camp"] = {Floor = home, Center = home.Position + Vector3.new(0, 80, 0), HalfSize = Vector3.new(330, 260, 330)},
	Meadow = {Floor = entrance, Center = entrance.Position + Vector3.new(90, 75, -245), HalfSize = Vector3.new(500, 330, 560)},
	["Storm Isles"] = {Floor = stormEntrance, Center = stormEntrance.Position + Vector3.new(70, 85, -235), HalfSize = Vector3.new(450, 330, 500)},
}
assert(not ReplicatedStorage:FindFirstChild("PortalTravel"), "Keep only one PortalLoop script")
local remote = Instance.new("RemoteEvent")
remote.Name = "PortalTravel"
remote.Parent = ReplicatedStorage
local states = {}
local nextId = 0
local LOAD_TIMEOUT = 24
local ARRIVAL_TIMEOUT = 12

local function landing(biome)
	local floor = regions[biome].Floor
	return floor.CFrame * CFrame.new(0, floor.Size.Y / 2 + 4, 10)
end

local function livingCharacter(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return character, root
	end
	return nil, nil
end

local function edgeDistance(region, position)
	local offset = position - region.Center
	return math.min(region.HalfSize.X - math.abs(offset.X),
		region.HalfSize.Y - math.abs(offset.Y), region.HalfSize.Z - math.abs(offset.Z))
end

local function stopVelocity(root)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

local function finish(player, state, record, success, message)
	if state.Pending ~= record then return end
	state.Pending = nil
	-- Hold the destination through arrival; release it on every exit path.
	if record.Focus then
		if record.FocusAdded and player.Parent == Players then
			local ok, err = pcall(function()
				player:RemoveReplicationFocus(record.Focus)
			end)
			if not ok then
				warn("PortalTravel focus cleanup: " .. tostring(err))
			end
		end
		record.Focus:Destroy()
		record.Focus = nil
	end
	local character, root = livingCharacter(player)
	if character == record.Character then
		if success then
			state.Biome = record.Destination
			state.LastSafe = landing(state.Biome)
		else
			-- A failed load stays at the departure point. Boundary recovery uses
			-- the last safe in-region position instead of leaving players outside.
			character:PivotTo(record.ReturnCFrame)
		end
		stopVelocity(root)
	end
	if record.Root.Parent then
		record.Root.Anchored = record.WasAnchored
	end
	state.Cooldown = os.clock() + 2
	state.Warned = false
	player:SetAttribute("CurrentBiome", state.Biome)
	player:SetAttribute("PortalTraveling", false)
	if player.Parent == Players then
		remote:FireClient(player, success and "Complete" or "Cancel", record.Id, message)
	end
end

local function beginTravel(player, state, destination, recovery, field, prompt)
	local character, root = livingCharacter(player)
	if not state.Ready or state.Pending or not character or root.Anchored then return end
	nextId = nextId + 1
	local record = {
		Id = nextId, Character = character, Root = root, WasAnchored = root.Anchored,
		ReturnCFrame = recovery and state.LastSafe or character:GetPivot(),
		Destination = destination, Target = landing(destination), Phase = "Loading",
		Field = field, Prompt = prompt,
	}
	state.Pending = record
	root.Anchored = true
	stopVelocity(root)
	player:SetAttribute("PortalTraveling", true)
	if Workspace.StreamingEnabled then
		local focus = part(objects, "TravelFocus_" .. record.Id, Vector3.one,
			record.Target, Color3.new())
		focus.Transparency = 1
		focus.CanQuery = false
		record.Focus = focus
		local ok, err = pcall(function()
			player:AddReplicationFocus(focus)
		end)
		record.FocusAdded = ok
		if not ok then
			warn("PortalTravel destination focus: " .. tostring(err))
		end
		-- Server prefetch runs independently of the client handshake. The API
		-- is best effort; the client must still see the actual landing floor.
		task.spawn(function()
			local streamed, streamError = pcall(function()
				player:RequestStreamAroundAsync(record.Target.Position, 20)
			end)
			if not streamed and states[player] == state and state.Pending == record then
				warn("PortalTravel prefetch: " .. tostring(streamError))
			end
		end)
	end
	remote:FireClient(player, "Prepare", record.Id, record.Target.Position, destination, recovery == true)
	task.delay(LOAD_TIMEOUT, function()
		if states[player] == state and state.Pending == record and record.Phase == "Loading" then
			warn("PortalTravel loading deadline: " .. destination .. " for " .. player.UserId)
			finish(player, state, record, false, "The area couldn't load. Please try again.")
		end
	end)
end

local function usePortal(player, field, prompt, fromBiome, toBiome, allowCargo)
	if not Profiles.get(player) then return end
	local state = states[player]
	local character, root = livingCharacter(player)
	if not state or not character or state.Pending or not prompt.Enabled then return end
	if state.Biome ~= fromBiome or os.clock() < state.Cooldown then return end
	if not ((root.Position - field.Position).Magnitude <= prompt.MaxActivationDistance) then return end
	if not allowCargo and character:FindFirstChild("CarriedEgg") then
		remote:FireClient(player, "Notice", "Place your carried egg on a pillow or the blue pad first.")
		return
	end
	if toBiome ~= "Base Camp" and not Progression.canEnter(player, field:GetAttribute("RequiredRebirths")) then
		remote:FireClient(player, "Notice", "This portal requires " .. tostring(field:GetAttribute("RequiredRebirths"))
			.. "+ rebirths. You have " .. tostring(Progression.getRebirths(player)) .. ".")
		return
	end
	beginTravel(player, state, toBiome, false, field, prompt)
end

entryPrompt.Triggered:Connect(function(player)
	usePortal(player, entryField, entryPrompt, "Base Camp", "Meadow", false)
end)
exitPrompt.Triggered:Connect(function(player)
	usePortal(player, exitField, exitPrompt, "Meadow", "Base Camp", true)
end)
stormPrompt.Triggered:Connect(function(player)
	usePortal(player, stormField, stormPrompt, "Base Camp", "Storm Isles", false)
end)
stormExitPrompt.Triggered:Connect(function(player)
	usePortal(player, stormExitField, stormExitPrompt, "Storm Isles", "Base Camp", true)
end)

remote.OnServerEvent:Connect(function(player, action, id)
	local state = states[player]
	if not state then return end
	if action == "ClientReady" then
		state.Ready = true
		return
	end
	local record = state.Pending
	if not record or record.Id ~= id then return end
	local character, root = livingCharacter(player)
	if character ~= record.Character then
		finish(player, state, record, false)
		return
	end
	if action == "Ready" and record.Phase == "Loading" then
		if record.Field and (not record.Prompt.Enabled
			or not ((root.Position - record.Field.Position).Magnitude <= record.Prompt.MaxActivationDistance)) then
			finish(player, state, record, false, "Move closer to the portal and try again.")
			return
		end
		if record.Field and record.Destination ~= "Base Camp"
			and not Progression.canEnter(player, record.Field:GetAttribute("RequiredRebirths")) then
			finish(player, state, record, false, "You no longer meet this portal's rebirth requirement.")
			return
		end
		record.Phase = "Arriving"
		character:PivotTo(record.Target)
		stopVelocity(root)
		remote:FireClient(player, "Arrive", record.Id, record.Target.Position, record.Destination)
		task.delay(ARRIVAL_TIMEOUT, function()
			if states[player] == state and state.Pending == record then
				finish(player, state, record, false, "Travel was interrupted. Please try again.")
			end
		end)
	elseif action == "Arrived" and record.Phase == "Arriving" then
		if (root.Position - record.Target.Position).Magnitude <= 14 then
			finish(player, state, record, true)
		end
	elseif action == "Cancel" then
		finish(player, state, record, false, "The area couldn't load. Please try again.")
	end
end)

local function setupPlayer(player)
	local state = {Biome = "Base Camp", Cooldown = 0, LastSafe = landing("Base Camp"), Ready = false}
	states[player] = state
	local function cancelTravel()
		if state.Pending then
			finish(player, state, state.Pending, false)
		end
	end
	local function onCharacter(character)
		cancelTravel()
		state.Biome = "Base Camp"
		state.LastSafe = landing("Base Camp")
		state.Cooldown = 0
		state.Warned = false
		player:SetAttribute("CurrentBiome", state.Biome)
		player:SetAttribute("PortalTraveling", false)
		task.spawn(function()
			local humanoid = character:WaitForChild("Humanoid", 5)
			if humanoid and character == player.Character then
				humanoid.Died:Connect(cancelTravel)
			end
		end)
	end
	player.CharacterAdded:Connect(onCharacter)
	player.CharacterRemoving:Connect(cancelTravel)
	player:SetAttribute("CurrentBiome", state.Biome)
	player:SetAttribute("PortalTraveling", false)
	if player.Character then
		onCharacter(player.Character)
	end
end
Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end
Players.PlayerRemoving:Connect(function(player)
	local state = states[player]
	if state and state.Pending then
		finish(player, state, state.Pending, false)
	end
	states[player] = nil
end)

-- Generous flight volumes leave room to explore. The check runs on the server
-- even if a client hides the warning or attempts to fly directly to another biome.
task.spawn(function()
	while objects.Parent do
		for player, state in pairs(states) do
			local character, root = livingCharacter(player)
			if character and not state.Pending then
				local distance = edgeDistance(regions[state.Biome], root.Position)
				if distance < 0 then
					if state.Ready and os.clock() >= state.Cooldown then
						beginTravel(player, state, state.Biome, true)
					else
						character:PivotTo(state.LastSafe)
						stopVelocity(root)
					end
				elseif distance < 75 then
					if not state.Warned then
						state.Warned = true
						remote:FireClient(player, "Notice", "Edge of " .. state.Biome .. " — turn back! Use portals to travel.")
					end
				elseif distance > 95 then
					state.Warned = false
					state.LastSafe = character:GetPivot()
				end
			end
		end
		task.wait(0.25)
	end
end)

print("Meadow portals ready: streaming, travel fades, and server biome boundaries enabled.")
