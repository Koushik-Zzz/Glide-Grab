-- Imported glider controller; Rojo owns this LocalScript after wind integration.
-- Wind adds sideways drift while normal steering stays in control.
Tool = script.Parent
Handle = Tool:WaitForChild("Handle")

Players = game:GetService("Players")
Debris = game:GetService("Debris")
RunService = game:GetService("RunService")

Camera = game:GetService("Workspace").CurrentCamera

Animations = {}
LocalObjects = {}

Speed = {
	CurrentSpeed = 5,
	MaxSpeed = 100
}

Jumping = {
	JumpTick = 0,
	Jumps = 0,
	JumpTime = 0.25,
	JumpsRequired = 1
}

Controls = {
	Forward = {Number = 0, Numbers = {On = -1, Off = 0}, Keys = {"W", 17}},
	Backward = {Number = 0, Numbers = { On = 1, Off = 0}, Keys = {"S", 18}},
	Left = {Number = 0, Numbers = {On = -1, Off = 0}, Keys = {"A", 20}},
	Right = {Number = 0, Numbers = {On = 1, Off = 0}, Keys = {"D", 19}}
}

UsableAnimations = {
	Pose = {Animation = Tool:WaitForChild("Pose"), FadeTime = nil, Weight = nil, Speed = nil},
}

Sounds = {
	Wind = Handle:WaitForChild("Wind"),
}

FlyRate = (1 / 60)

Debounce = false
Flying = false
ToolEquipped = false

ServerControl = Tool:WaitForChild("ServerControl")
ClientControl = Tool:WaitForChild("ClientControl")

function SetAnimation(Mode, Value)
	if Mode == "PlayAnimation" and Value and ToolEquipped and Humanoid then
		for i, v in pairs(Animations) do
			if v.Animation == Value.Animation then
				v.AnimationTrack:Stop()
				table.remove(Animations, i)
			end
		end
		local AnimationTrack = Humanoid:LoadAnimation(Value.Animation)
		table.insert(Animations, {Animation = Value.Animation, AnimationTrack = AnimationTrack})
		AnimationTrack:Play(Value.FadeTime, Value.Weight, Value.Speed)
	elseif Mode == "StopAnimation" and Value then
		for i, v in pairs(Animations) do
			if v.Animation == Value.Animation then
				v.AnimationTrack:Stop()
				table.remove(Animations, i)
			end
		end
	end
end

function DisableJump(Boolean)
	if PreventJump then
		PreventJump:disconnect()
	end
	if Boolean then
		PreventJump = Humanoid.Changed:connect(function(Property)
			if Property ==  "Jump" then
				Humanoid.Jump = false
			end
		end)
	end
end

function Clamp(Number, Min, Max)
	return math.max(math.min(Max, Number), Min)
end

function Fly()
	if Flying and Player and Torso and Humanoid and Humanoid.Health > 0 then
		Character:SetAttribute("GliderFlying", true)
		local Momentum = Vector3.new(0, 0, 0)
		local LastMomentum = Vector3.new(0, 0, 0)
		local LastTilt = 0
		local LastFlap = 0
		local WasKnockedBack = false
		local CurrentSpeed = Speed.MaxSpeed
		local Inertia = (1 - (Speed.CurrentSpeed / CurrentSpeed))
		
		Momentum = (Torso.Velocity + (Torso.CFrame.lookVector * 3) + Vector3.new(0, 10, 0))
		Momentum = Vector3.new(Clamp(Momentum.X, -15, 15), Clamp(Momentum.Y, -15, 15), Clamp(Momentum.Z, -15, 15))		
		
		BodyVelocity.maxForce = Vector3.new(1, 1, 1) * (10 ^ 6)	
		
		BodyGyro.maxTorque = Vector3.new(BodyGyro.P, BodyGyro.P, BodyGyro.P)
		BodyGyro.cframe = Torso.CFrame
		
		Spawn(function()
			InvokeServer("Flying", {Flying = true})
		end)
		
		--SetAnimation("PlayAnimation", UsableAnimations.Pose)
		
		Humanoid.AutoRotate = false
				
		while Flying and Torso and Humanoid and Humanoid.Health > 0 do
			local KnockbackUntil = math.max(Character:GetAttribute("GuardianKnockbackUntil") or 0,
				Character:GetAttribute("CombatKnockbackUntil") or 0)
			local KnockedBack = type(KnockbackUntil) == "number"
				and game:GetService("Workspace"):GetServerTimeNow() < KnockbackUntil
			if KnockedBack then
				-- The guardian's short LinearVelocity shove owns movement during impact.
				BodyVelocity.maxForce = Vector3.zero
				Momentum = Vector3.zero
			else
				if WasKnockedBack then
					Momentum = Torso.AssemblyLinearVelocity * 0.25
					LastMomentum = Momentum
				end
				BodyVelocity.maxForce = Vector3.new(1, 1, 1) * (10 ^ 6)
			end
			WasKnockedBack = KnockedBack
			
			if CurrentSpeed ~= Speed.MaxSpeed then
				CurrentSpeed = Speed.MaxSpeed
				Inertia = (1 - (Speed.CurrentSpeed / CurrentSpeed))
			end
			
			local Direction = Camera.CoordinateFrame:vectorToWorldSpace(Vector3.new(Controls.Left.Number + Controls.Right.Number, math.abs(Controls.Forward.Number) * 0.2, Controls.Forward.Number + Controls.Backward.Number))
			local Movement = Direction * Speed.CurrentSpeed
			
			Momentum = (Momentum * Inertia) + Movement
			
			local TotalMomentum = Momentum.magnitude
			
			if TotalMomentum > CurrentSpeed then
				TotalMomentum = CurrentSpeed
			end
			
			local Tilt = ((Momentum * Vector3.new(1, 0, 1)).unit:Cross(((LastMomentum * Vector3.new(1, 0, 1)).unit))).y
			local StringTilt = tostring(Tilt)
			
			if StringTilt == "-1.#IND" or StringTilt == "1.#IND" or Tilt == math.huge or Tilt == -math.huge or StringTilt == tostring(0 / 0) then
				Tilt = 0
			end
			
			local AbsoluteTilt = math.abs(Tilt)
			
			if AbsoluteTilt > 0.06 or AbsoluteTilt < 0.0001 then
				if math.abs(LastTilt) > 0.0001 then
					Tilt = (LastTilt * 0.9)
				else
					Tilt = 0
				end
			else
				Tilt = ((LastTilt * 0.77) + (Tilt * 0.25))
			end
			
			LastTilt = Tilt

			if TotalMomentum < 0.5 then
				Momentum = Vector3.new(0, 0, 0)
				TotalMomentum = 0
				BodyGyro.cframe = Camera.CoordinateFrame
			else
				BodyGyro.cframe = CFrame.new(Vector3.new(0, 0, 0), Momentum) * CFrame.Angles(0, 0, (Tilt * -20)) * CFrame.Angles((math.pi * -0.5 * (TotalMomentum / CurrentSpeed)), 0, 0)
			end
			
			local GravityDelta = ((((Momentum * Vector3.new(0, 1, 0)) - Vector3.new(0, -Speed.MaxSpeed, 0)).magnitude / Speed.MaxSpeed) * 0.5)
			if GravityDelta > 0.45 and tick() > LastFlap then
				LastFlap = (tick() + 0.5)
				Spawn(function()
					if not Flying then
						return
					end
					if not Sounds.Wind.IsPlaying then
						Sounds.Wind:Play()
					end
					Spawn(function()
						InvokeServer("SetWingSpan", {Angle = 0, MaxVelocity = 0.05})
					end)
					wait(0.25)
					if not Flying then
						return
					end
					Spawn(function()
						InvokeServer("SetWingSpan", {Angle = 0.5, MaxVelocity = 0.05})
					end)
					wait(0.25)
				end)
			elseif GravityDelta <= 0.45 then
				Sounds.Wind:Stop()
			end
			
			-- Meadow's server decides when this character is inside an active gust.
			-- Add wind to the existing flight target so controllers do not fight.
			local wind = Player:GetAttribute("MeadowWindVelocity")
			if Player:GetAttribute("PortalTraveling") or typeof(wind) ~= "Vector3" then
				wind = Vector3.zero
			end
			local boostUntil = Character:GetAttribute("GliderBoostUntil") or 0
			local boost = Vector3.zero
			if not KnockedBack and not Player:GetAttribute("PortalTraveling") and not Torso.Anchored
				and game:GetService("Workspace"):GetServerTimeNow() < boostUntil then
				local forward = Momentum.Magnitude > 5 and Momentum.Unit or Camera.CFrame.LookVector
				boost = forward * (Character:GetAttribute("GliderBoostSpeed") or 0)
			end
			-- Boost changes this controller's target rather than adding a competing force.
			BodyVelocity.velocity = KnockedBack and Vector3.zero or Momentum + wind + boost
			-- Visible wing bank follows the same wind that moves the glider.
			local crosswind = Camera.CFrame:VectorToObjectSpace(wind).X
			BodyGyro.cframe = BodyGyro.cframe * CFrame.Angles(0, 0, -math.clamp(crosswind / 64, -1, 1) * 0.22)
			LastMomentum = Momentum
			
			wait(FlyRate)
			
		end
		
		Sounds.Wind:Stop()
		Character:SetAttribute("GliderFlying", false)
		
		Spawn(function()
			InvokeServer("SetWingSpan", {Angle = 0, MaxVelocity = 0.01})
		end)
		
		Spawn(function()
			InvokeServer("Flying", {Flying = false})
		end)
		
		--SetAnimation("StopAnimation", UsableAnimations.Pose)		
		
		BodyVelocity.maxForce = Vector3.new(0, 0, 0)
		BodyGyro.maxTorque = Vector3.new(0, 0, 0)
		
		if CheckIfAlive() then
			Humanoid.AutoRotate = true
			Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		end
		
	end
end

function StopFlying()
	Flying = false
	if Character then Character:SetAttribute("GliderFlying", false) end
	BodyVelocity.maxForce = Vector3.new(0, 0, 0)
	BodyGyro.maxTorque = Vector3.new(0, 0, 0)
end

function CheckIfAlive()
	return (((Character and Character.Parent and Humanoid and Humanoid.Parent and Humanoid.Health > 0 and Torso and Torso.Parent and Player and Player.Parent) and true) or false)
end

function Equipped(Mouse)
	Character = Tool.Parent
	Humanoid = Character:FindFirstChild("Humanoid")
	Torso = Character:FindFirstChild("UpperTorso")
	Player = Players:GetPlayerFromCharacter(Character)
	if not CheckIfAlive() then
		return
	end
	PlayerMouse = Player:GetMouse()
	Mouse.Button1Down:connect(function()
		if Player and Player:GetAttribute("CampMenuOpen") then return end
		InvokeServer("MouseClick", {Down = true})
	end)
	Mouse.Button1Up:connect(function()
		InvokeServer("MouseClick", {Down = false})
	end)
	Mouse.KeyDown:connect(function(Key)
		if Player and Player:GetAttribute("CampMenuOpen") then return end
		local Key = string.lower(Key)
		local ByteKey = string.byte(Key)
		if ByteKey == string.byte(" ") and not Debounce
			and game:GetService("Workspace"):GetServerTimeNow() >= (Character:GetAttribute("CombatStunnedUntil") or 0) then
			if Flying then
				StopFlying()
			elseif not Flying then
				if (tick() - Jumping.JumpTick) <= Jumping.JumpTime or Jumping.JumpTick == 0 then
					Jumping.JumpTick = tick()
					Jumping.Jumps = Jumping.Jumps + 1
					if Jumping.Jumps >= Jumping.JumpsRequired then
						Debounce = true
						Jumping.JumpTick = 0
						Jumping.Jumps = 0
						Flying = true
						Spawn(Fly)
						Debounce = false
					end
				else
					Jumping.JumpTick = tick()
					Jumping.Jumps = 1
				end
			end
		end
		for i, v in pairs(Controls) do
			for ii, vv in pairs(v.Keys) do
				v.Number = ((((string.lower(type(vv)) == string.lower("String") and Key == string.lower(vv)) or (string.lower(type(vv)) == string.lower("Number") and ByteKey == vv)) and v.Numbers.On) or v.Number)
			end
		end
	end)
	Mouse.KeyUp:connect(function(Key)
		local Key = string.lower(Key)
		local ByteKey = string.byte(Key)
		for i, v in pairs(Controls) do
			for ii, vv in pairs(v.Keys) do
				v.Number = ((((string.lower(type(vv)) == string.lower("String") and Key == string.lower(vv)) or (string.lower(type(vv)) == string.lower("Number") and ByteKey == vv)) and v.Numbers.Off) or v.Number)
			end
		end
	end)
	ToolEquipped = true
	while not BodyVelocity or not BodyVelocity.Parent or not BodyGyro or not BodyGyro.Parent and CheckIfAlive() and ToolEquipped do
		BodyVelocity = Torso:FindFirstChild("BodyVelocity")
		BodyGyro = Torso:FindFirstChild("BodyGyro")
		RunService.Stepped:wait()
	end
end

function Unequipped()
	if Character then Character:SetAttribute("GliderFlying", false) end
	LocalObjects = {}
	for i, v in pairs(Animations) do
		if v and v.AnimationTrack then
			v.AnimationTrack:Stop()
		end
	end
	for i, v in pairs({PreventJump}) do
		if v then
			v:disconnect()
		end
	end
	Sounds.Wind:Stop()
	Animations = {}
	Flying = false
	ToolEquipped = false
end

function InvokeServer(Mode, Value)
	pcall(function()
		local ServerReturn = ServerControl:InvokeServer(Mode, Value)
		return ServerReturn
	end)
end

function OnClientInvoke(Mode, Value)
	if Mode == "PlayAnimation" and Value and ToolEquipped and Humanoid then
		SetAnimation("PlayAnimation", Value)
	elseif Mode == "StopAnimation" and Value then
		SetAnimation("StopAnimation", Value)
	elseif Mode == "PlaySound" and Value then
		Value:Play()
	elseif Mode == "StopSound" and Value then
		Value:Stop()
	elseif Mode == "MousePosition" then
		return PlayerMouse.Hit.p
	elseif Mode == "DisableJump" then
		DisableJump(Value)
	elseif Mode == "Fly" and not Flying then
		Flying = true
		Spawn(function()
			Fly()
		end)
	end
end

Tool.Equipped:connect(Equipped)
Tool.Unequipped:connect(Unequipped)
ClientControl.OnClientInvoke = OnClientInvoke
