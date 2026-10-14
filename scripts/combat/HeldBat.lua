-- Replicated cosmetic prop. The private purchase entitlement owns its lifetime.
-- This is a Model, so the glider remains the equipped Tool and keeps its grip.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HeldBat = {}

function HeldBat.bind(player, ownsBat)
	local character, model
	local connections, characterConnections = {}, {}
	local api = {}
	local function clearModel()
		if model then
			model:Destroy()
		end
		model = nil
	end
	local function clearCharacter()
		clearModel()
		for _, connection in ipairs(characterConnections) do
			connection:Disconnect()
		end
		table.clear(characterConnections)
		character = nil
	end
	function api:refresh()
		local c = character
		local humanoid = c and c:FindFirstChildOfClass("Humanoid")
		local hand = c and (c:FindFirstChild("LeftHand") or c:FindFirstChild("Left Arm"))
		if c ~= player.Character or not c or not c.Parent or not ownsBat()
			or not humanoid or humanoid.Health <= 0 or not hand then
			clearModel()
			return
		end
		if model and model.Parent == c then return end
		clearModel()
		local assets = ReplicatedStorage:FindFirstChild("CombatAssets")
		local source = assets and assets:FindFirstChild("Bat")
		if not source or not source.PrimaryPart then return end
		model = source:Clone()
		model.Name = "HeldBat"
		local primary = model.PrimaryPart
		local attachment = hand:FindFirstChild("LeftGripAttachment")
		local handGrip = attachment and attachment.CFrame
			or CFrame.new(0, -hand.Size.Y / 2, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
		-- Original imported Bat-to-Handle joint was 1.3 studs from centre on
		-- a 4-stud bat. Preserve that handle location after the template's scale.
		local batGrip = CFrame.new(0, 0, -primary.Size.Z * 0.325)
		model:PivotTo(hand.CFrame * handGrip * batGrip:Inverse())
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.Massless = true
				part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
				if part ~= primary then
					local weld = Instance.new("WeldConstraint")
					weld.Part0, weld.Part1 = primary, part
					weld.Parent = part
				end
			end
		end
		local grip = Instance.new("Motor6D")
		grip.Name = "BatGrip"
		grip.Part0, grip.Part1 = hand, primary
		grip.C0, grip.C1 = handGrip, batGrip
		grip.Parent = primary
		model.Parent = c
	end
	local function bindCharacter(c)
		if player.Character ~= c then return end
		clearCharacter()
		character = c
		table.insert(characterConnections, c.ChildAdded:Connect(function(child)
			if child:IsA("Humanoid") then
				table.insert(characterConnections, child.Died:Connect(clearModel))
			end
			if child:IsA("BasePart") or child:IsA("Humanoid") then
				api:refresh()
			end
		end))
		local humanoid = c:FindFirstChildOfClass("Humanoid")
		if humanoid then
			table.insert(characterConnections, humanoid.Died:Connect(clearModel))
		end
		api:refresh()
	end
	table.insert(connections, player.CharacterAdded:Connect(bindCharacter))
	table.insert(connections, player.CharacterRemoving:Connect(function(c)
		if character == c then
			clearCharacter()
		end
	end))
	if player.Character then
		bindCharacter(player.Character)
	end
	function api:destroy()
		clearCharacter()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		table.clear(connections)
	end
	return api
end
return HeldBat
