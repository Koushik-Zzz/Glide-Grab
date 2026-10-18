-- Native prompt eligibility, keys, hold duration and server transactions stay intact.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Menus = require(RS:WaitForChild("UIModules"):WaitForChild("Menus"))
local template = RS:WaitForChild("UIAssets"):WaitForChild("WorldPrompt")
local gui = Players.LocalPlayer:WaitForChild("PlayerGui")
local active, original = {}, {}
local connections = {}
local enabledBefore = PPS.Enabled
local function managed(prompt)
	if not prompt:IsA("ProximityPrompt") then return false end
	-- Only game-owned prompts. Other imported tools retain their presentation.
	local name = prompt.Name
	return name == "TravelPrompt" or name == "RebirthPrompt" or name == "PurchasePrompt"
		or name == "UpgradePrompt" or name == "DepositPrompt" or name == "GrabPrompt"
		or name == "PlaceEgg" or name == "SellEgg" or name == "CollectPrompt"
end
local function style(prompt)
	if not managed(prompt) then return end
	if original[prompt] == nil then original[prompt] = prompt.Style end
	prompt.Style = Enum.ProximityPromptStyle.Custom
end
local function hide(prompt)
	local state = active[prompt]
	if not state then return end
	active[prompt] = nil
	if state.Pressed and prompt.Parent then prompt:InputHoldEnd() end
	if state.Tween then state.Tween:Cancel() end
	for _, connection in state.Connections do connection:Disconnect() end
	state.Gui:Destroy()
end
local function show(prompt, inputType)
	if not managed(prompt) or Menus.Current then return end
	style(prompt)
	hide(prompt)
	local display = template:Clone()
	display.Name = "Styled" .. prompt.Name
	display.Adornee = prompt.Parent
	display.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	display.Parent = gui
	local state = {Gui = display, Connections = {}, Pressed = false}
	active[prompt] = state
	local body = display.Body
	local function watch(signal, fn) table.insert(state.Connections, signal:Connect(fn)) end
	local function refresh()
		body.Action.Text = prompt.ActionText
		body.Detail.Text = (prompt.HoldDuration > 0 and "Hold • " or "") .. prompt.ObjectText
		body.Key.Glyph.Text = inputType == Enum.ProximityPromptInputType.Touch and "Tap"
			or inputType == Enum.ProximityPromptInputType.Gamepad and prompt.GamepadKeyCode.Name:gsub("Button", "")
			or UIS:GetStringForKeyCode(prompt.KeyboardKeyCode)
		body.Position = UDim2.fromOffset(3 + prompt.UIOffset.X, 3 + prompt.UIOffset.Y)
	end
	local function endHold()
		if state.Pressed then state.Pressed = false prompt:InputHoldEnd() end
	end
	watch(body.InputBegan, function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if Menus.Current or (input.UserInputType ~= Enum.UserInputType.Touch and not prompt.ClickablePrompt) then return end
		state.Pressed = true
		prompt:InputHoldBegin()
	end)
	watch(UIS.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then endHold() end
	end)
	watch(prompt.PromptButtonHoldBegan, function()
		if state.Tween then state.Tween:Cancel() end
		body.Progress.Size = UDim2.fromOffset(0, 3)
		state.Tween = TweenService:Create(body.Progress, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), {Size = UDim2.new(1, -12, 0, 3)})
		state.Tween:Play()
	end)
	watch(prompt.PromptButtonHoldEnded, function()
		if state.Tween then state.Tween:Cancel() end
		body.Progress.Size = UDim2.fromOffset(0, 3)
	end)
	for _, property in {"ActionText", "ObjectText", "UIOffset", "HoldDuration", "KeyboardKeyCode", "GamepadKeyCode"} do watch(prompt:GetPropertyChangedSignal(property), refresh) end
	watch(prompt.Destroying, function() hide(prompt) end)
	refresh()
end
table.insert(connections, PPS.PromptShown:Connect(show))
table.insert(connections, PPS.PromptHidden:Connect(hide))
table.insert(connections, workspace.DescendantAdded:Connect(style))
table.insert(connections, workspace.DescendantRemoving:Connect(function(object)
	hide(object)
	if original[object] ~= nil then
		object.Style = original[object]
		original[object] = nil
	end
end))
table.insert(connections, Menus.subscribe(function(name)
	PPS.Enabled = name == nil and enabledBefore
end))
for _, object in workspace:GetDescendants() do style(object) end
script.Destroying:Connect(function()
	for _, connection in connections do connection:Disconnect() end
	for prompt in active do hide(prompt) end
	for prompt, value in original do if prompt.Parent then prompt.Style = value end end
	PPS.Enabled = enabledBefore
end)
