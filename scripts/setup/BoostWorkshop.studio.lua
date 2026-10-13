-- One-time Edit-mode camp fixture. Not a runtime/Rojo script; safe to rerun.
local Workspace = game:GetService("Workspace")
local home = Workspace:WaitForChild("HomeIsland")
local station = Workspace:FindFirstChild("BoostWorkshop")
if station then return station:GetFullName() end
station = Instance.new("Model")
station.Name = "BoostWorkshop"
station.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
local top = home.Size.Y / 2
local function part(name, offset, size, color, collide)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = home.CFrame * CFrame.new(offset)
	object.Color = color
	object.Material = Enum.Material.Wood
	object.Anchored = true
	object.CanCollide = collide
	object.CanTouch = false
	object.Parent = station
	return object
end
local wood = Color3.fromRGB(187, 144, 95)
local teal = Color3.fromRGB(28, 130, 110)
part("WorkshopPad", Vector3.new(-22, top + 0.15, 18), Vector3.new(12, 0.3, 10), teal, true)
part("LeftSupport", Vector3.new(-25, top + 1.5, 18), Vector3.new(1, 3, 3), wood, true)
part("RightSupport", Vector3.new(-19, top + 1.5, 18), Vector3.new(1, 3, 3), wood, true)
local counter = part("Counter", Vector3.new(-22, top + 3.25, 18), Vector3.new(9, 0.5, 4), wood, true)
part("SignPost", Vector3.new(-22, top + 5, 21), Vector3.new(0.5, 10, 0.5), wood, false)
local sign = part("WorkshopSign", Vector3.new(-22, top + 10, 21), Vector3.new(8, 2, 0.5), teal, false)
local wing = part("DisplayGlider", Vector3.new(-22, top + 4.3, 18), Vector3.new(5.5, 0.25, 2), Color3.fromRGB(255, 235, 179), false)
wing.CFrame *= CFrame.Angles(0, 0, 0.15)
local board = Instance.new("BillboardGui")
board.Name = "WorkshopLabel"
board.Size = UDim2.fromOffset(260, 72)
board.StudsOffset = Vector3.new(0, 2, 0)
board.MaxDistance = 80
board.AlwaysOnTop = false
local caption = Instance.new("TextLabel")
caption.Size = UDim2.fromScale(1, 1)
caption.BackgroundTransparency = 1
caption.Text = "BOOST WORKSHOP\nLonger bursts • Faster recharge"
caption.Font = Enum.Font.GothamBold
caption.TextSize = 20
caption.TextColor3 = Color3.fromRGB(221, 255, 240)
caption.TextStrokeTransparency = 0.25
caption.Parent = board
board.Parent = sign
local prompt = Instance.new("ProximityPrompt")
prompt.Name = "UpgradePrompt"
prompt.ActionText = "Upgrade boost — 50 coins"
prompt.ObjectText = "Boost workshop"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
prompt.HoldDuration = 0.5
prompt.MaxActivationDistance = 12
prompt.RequiresLineOfSight = false
prompt.Parent = counter
station.Parent = Workspace
game:GetService("ChangeHistoryService"):SetWaypoint("Add camp boost workshop")
return station:GetFullName()
