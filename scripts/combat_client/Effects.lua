-- Local swing visuals follow the hand; they do not affect collision or hits.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BatPose = require(script.Parent:WaitForChild("BatPose"))
local Effects = {}
function Effects.new()
	local assets = ReplicatedStorage:WaitForChild("CombatAssets")
	local active = {}
	local api = {}
	local batPose = BatPose.new()
	function api:play(player, kind)
		-- Owned bats are persistent hand-gripped models with a left-arm pose.
		if kind ~= "Slap" then return end
		local c = player.Character
		local hand = c and (c:FindFirstChild("RightHand") or c:FindFirstChild("Right Arm"))
		local source = assets:FindFirstChild(kind)
		if not hand or not source then return end
		local model = source:Clone()
		model.Name = "Local" .. kind .. "Swing"
		model.Parent = workspace
		local start = os.clock()
		local record = {Model = model}
		active[record] = true
		record.Connection = RunService.RenderStepped:Connect(function()
			local t = (os.clock() - start) / 0.38
			if t >= 1 or player.Character ~= c or not hand.Parent then
				record.Connection:Disconnect()
				model:Destroy()
				active[record] = nil
				return
			end
			local angle = math.rad(-60 + 120 * math.sin(t * math.pi))
			model:PivotTo(hand.CFrame * CFrame.new(0, -0.2, -1.2) * CFrame.Angles(math.rad(60), angle, 0))
		end)
	end
	function api:destroy()
		batPose:destroy()
		for record in pairs(active) do
			record.Connection:Disconnect()
			record.Model:Destroy()
		end
		table.clear(active)
	end
	return api
end
return Effects
