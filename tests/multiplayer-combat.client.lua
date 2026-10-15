if not game:GetService("RunService"):IsStudio() then return end
local RS=game:GetService("ReplicatedStorage")
local folder=RS:WaitForChild("TemporarySkyCombatTest",100)
if not folder then return end
local p=game.Players.LocalPlayer
local W=workspace
local report=folder:WaitForChild("Report")
local observePosition=folder:WaitForChild("ObservePosition")
local input
local lastPositionAck
local visiblePrompts={}
local promptService=game:GetService("ProximityPromptService")
promptService.PromptShown:Connect(function(prompt)
	visiblePrompts[prompt]=true
end)
promptService.PromptHidden:Connect(function(prompt)
	visiblePrompts[prompt]=nil
end)
local function await(fn,seconds)
	local deadline=os.clock()+seconds
	repeat
		if fn() then return end
		task.wait(0.05)
	until os.clock()>=deadline
	error("Client timeout at "..tostring(folder:GetAttribute("Stage")))
end
local role, remote
local function state(label)
	local stats=p:FindFirstChild("leaderstats")
	local coins=stats and stats:FindFirstChild("Coins")
	return {Step=label, Coins=coins and coins.Value, Bat=p:GetAttribute("OwnsBat"),
		Boost=p:GetAttribute("BoostLevel"), Shields=p:GetAttribute("EggShieldCharges"),
		Biome=p:GetAttribute("CurrentBiome"), Plot=p:GetAttribute("CampPlotId"), Loaded=p:GetAttribute("DataLoaded"),
		ServerPositionAck=lastPositionAck}
end
local function key(code,hold)
	input:SendKey(true,code,false)
	task.wait(hold or 0.1)
	input:SendKey(false,code,false)
end
local function move(position,look)
	p.Character:PivotTo(CFrame.lookAt(position,look or position+Vector3.new(0,0,-10)))
	W.CurrentCamera.CameraType=Enum.CameraType.Scriptable
	W.CurrentCamera.CFrame=CFrame.lookAt(position+Vector3.new(0,5,15),look or position+Vector3.new(0,0,-10))
	-- Scripted client positioning is not immediately authoritative. Wait until
	-- the server observes the settled/current client root before native input.
	local deadline=os.clock()+10
	repeat
		local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		lastPositionAck=root and observePosition:InvokeServer(root.Position) or nil
		if lastPositionAck and lastPositionAck.Distance <= 2 then return end
		task.wait(0.05)
	until os.clock()>=deadline
	error("Server did not acknowledge client position before input at "..tostring(folder:GetAttribute("Stage")))
end
local function use(prompt)
	local shown=visiblePrompts[prompt]==true
	local shownConnection=prompt.PromptShown:Connect(function()
		shown=true
	end)
	move(prompt.Parent.Position+Vector3.new(0,1,4),prompt.Parent.Position)
	local deadline=os.clock()+10
	repeat
		task.wait(0.05)
	until shown or os.clock()>=deadline
	shownConnection:Disconnect()
	assert(shown,"Native PromptShown was not observed: "..prompt:GetFullName())
	local before=state("BeforeUse")
	before.Prompt, before.Enabled = prompt:GetFullName(), prompt.Enabled
	before.PromptShown=true
	before.Distance = (p.Character.HumanoidRootPart.Position-prompt.Parent.Position).Magnitude
	assert(before.Distance <= prompt.MaxActivationDistance,
		"Client moved out of range after position acknowledgement: "..prompt:GetFullName())
	before.HoldDuration = prompt.HoldDuration
	local root = p.Character.HumanoidRootPart
	before.Anchored = root.Anchored
	before.Position = {root.Position.X, root.Position.Y, root.Position.Z}
	report:FireServer("BeforeUse",before)
	local triggered=false
	local triggeredConnection=prompt.Triggered:Connect(function()
		triggered=true
	end)
	local function entitlementChanged()
		if prompt.Parent.Name=="BatCounter" then
			return p:GetAttribute("OwnsBat")==true and before.Bat~=true
		elseif prompt.Parent.Name=="ShieldCounter" then
			return (p:GetAttribute("EggShieldCharges") or 0)>(before.Shields or 0)
		elseif prompt.Name=="UpgradePrompt" then
			return (p:GetAttribute("BoostLevel") or 0)>(before.Boost or 0)
		end
		return false
	end
	local started=os.clock()
	prompt:InputHoldBegin()
	repeat
		task.wait(0.05)
	until triggered or entitlementChanged() or os.clock()-started>=4
	prompt:InputHoldEnd()
	triggeredConnection:Disconnect()
	task.wait(0.5)
	local after=state("AfterUse")
	after.Prompt=prompt:GetFullName()
	after.NativeTriggered=triggered
	after.EntitlementChanged=entitlementChanged()
	after.HoldSeconds=os.clock()-started
	report:FireServer("AfterUse",after)
	assert(triggered or after.EntitlementChanged,"Native hold did not complete within four seconds: "..prompt:GetFullName())
end
local function flying()
	local glider=p.Character:FindFirstChild("Glider")
	return glider and glider:GetAttribute("IsGliding")
end
local function flight(enabled)
	if enabled and not p.Character:FindFirstChild("Glider") then
		p.Character.Humanoid:EquipTool(p.Backpack:WaitForChild("Glider"))
		task.wait(0.8)
	end
	if (flying()==true)~=enabled then
		key(Enum.KeyCode.Space,0.1)
	end
	await(function()
		return (flying()==true)==enabled
	end,4)
end
local function travel(biome)
	if p:GetAttribute("CurrentBiome")==biome then return end
	if flying() then
		flight(false)
	end
	local portals=W:WaitForChild("PortalLoopPrototype")
	local model=portals:WaitForChild(biome=="Meadow" and "MeadowPortal" or "CampReturnPortal")
	local field=model:WaitForChild("PortalField")
	move(field.Position+Vector3.new(role==1 and -2 or 2,-3,3),field.Position)
	assert((p.Character.HumanoidRootPart.Position-field.Position).Magnitude <= field.TravelPrompt.MaxActivationDistance,
		"Client portal position rolled back after server acknowledgement")
	task.wait(1.5)
	field.TravelPrompt:InputHoldBegin()
	task.wait(0.7)
	field.TravelPrompt:InputHoldEnd()
	await(function()
		return p:GetAttribute("CurrentBiome")==biome and not p:GetAttribute("PortalTraveling")
	end,25)
end
local function arena(reverse)
	local pos=Vector3.new(-180,235,role==1 and -1930 or -1937)
	move(pos,pos+Vector3.new(0,0,reverse and 10 or -10))
end
local function run()
	input=game:GetService("UserInputService"):CreateVirtualInput()
	await(function()
		local gui=p:FindFirstChild("PlayerGui")
		return game:IsLoaded() and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p:GetAttribute("TemporaryCombatRole")
			and p:GetAttribute("DataLoaded") and p:GetAttribute("CampPlotId") and p:GetAttribute("CurrentBiome")=="Base Camp"
			and p:GetAttribute("BoostLevel")~=nil and p:GetAttribute("OwnsBat")~=nil and p:GetAttribute("EggShieldCharges")~=nil
			and gui and gui:FindFirstChild("GlideAndGrabHUD") and gui:FindFirstChild("GliderBoostHUD")
			and gui:FindFirstChild("SkyCombatHUD") and gui:FindFirstChild("RebirthHUD")
	end,110)
	role=p:GetAttribute("TemporaryCombatRole")
	remote=RS:WaitForChild("SkyCombat")
	report:FireServer("Ready",state("Ready"))
	local completed={}
	while folder.Parent do
	local stage=folder:GetAttribute("Stage")
	if stage and not completed[stage] then
		completed[stage]=true
		report:FireServer("Step",state(stage))
		if stage=="Shop" then
			if role==1 then
				use(W.SkyGearShop.BatCounter.PurchasePrompt)
				report:FireServer("AfterBat",state("AfterBat"))
				use(W.BoostWorkshop.Counter.UpgradePrompt)
				report:FireServer("AfterBoost",state("AfterBoost"))
			else
				use(W.SkyGearShop.ShieldCounter.PurchasePrompt)
				report:FireServer("AfterShield",state("AfterShield"))
			end
		elseif stage=="SafeBase" then
			move(Vector3.new(0,107,role==1 and 60 or 53))
			if role==1 then
				remote:FireServer("Slap")
			end
		elseif stage=="Meadow" then
			travel("Meadow")
			if role==2 then
				move(Vector3.new(180,163,-2190))
				p:RequestStreamAroundAsync(Vector3.new(180,163,-2190),5)
				local egg=W.EggLoopPrototype:WaitForChild("Egg3",5)
				local part=egg:IsA("BasePart") and egg or egg:FindFirstChildWhichIsA("BasePart",true)
				move(part.Position+Vector3.new(0,1,3),part.Position)
				assert((p.Character.HumanoidRootPart.Position-part.Position).Magnitude <= 12,
					"Client pickup position rolled back after server acknowledgement")
				task.wait(0.6)
				key(Enum.KeyCode.E,0.1)
				await(function()
					return p.Character:FindFirstChild("CarriedEgg")
				end,2)
			end
			arena()
			flight(true)
			arena()
		elseif stage:match("^Pose") and stage~="PoseGround" then
			arena()
		elseif stage=="Slap" and role==1 then key(Enum.KeyCode.Q)
		elseif stage=="Shield" and role==2 then key(Enum.KeyCode.G)
		elseif (stage=="ShieldSteal" or stage=="GroundSteal" or stage=="Steal") and role==1 then
			key(Enum.KeyCode.F)
		elseif stage=="Bat" and role==1 then key(Enum.KeyCode.R)
		elseif stage=="Denied" and role==2 then
			p:SetAttribute("OwnsBat",true)
			remote:FireServer("Bat")
			task.wait(0.3)
			remote:FireServer("Bat",game.Players:GetPlayers()[1])
			task.wait(0.3)
			remote:FireServer({action="Bat"})
			task.wait(0.3)
			remote:FireServer("NotAnAction")
			p:SetAttribute("OwnsBat",false)
		elseif stage=="PoseGround" then
			move(Vector3.new(-5,role==1 and 133 or 128,-1930),Vector3.new(0,128,-1930))
		elseif stage=="BackSteal" and role==2 then
			arena(true)
			key(Enum.KeyCode.F)
		elseif stage=="Deposit" and role==1 then
			travel("Base Camp")
			local root=W.CampPlots[p:GetAttribute("CampPlotId")].Slots.Slot1.SlotRoot
			move(root.Position+Vector3.new(0,3,2),root.Position)
			assert((p.Character.HumanoidRootPart.Position-root.Position).Magnitude <= root.PlaceEgg.MaxActivationDistance,
				"Client pillow position rolled back after server acknowledgement")
			task.wait(1)
			root.PlaceEgg:InputHoldBegin()
			task.wait(0.7)
			root.PlaceEgg:InputHoldEnd()
		end
		report:FireServer("Completed",{Stage=stage})
	end
	task.wait(0.05)
	end
end
local ok, failure=xpcall(run,debug.traceback)
if not ok then
	report:FireServer("Error",failure)
end
