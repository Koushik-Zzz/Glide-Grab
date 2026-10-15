-- Unmapped regression fixture. Author this and multiplayer-combat.client.lua in
-- Edit for ExecuteMultiplayerTestAsync(2, "SkyCombatProof"); remove after Stop.
if not game:GetService("RunService"):IsStudio() then return end
local Test = game:GetService("StudioTestService")
if Test:GetTestArgs() ~= "SkyCombatProof" then return end
if game.GameId ~= 0 then
	Test:EndTest({passed = false, error = "Use an unassociated local preview; fixture coins must not reach cloud saves"})
	return
end
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local W = game:GetService("Workspace")
local Profiles = require(game.ServerScriptService.DataModules.Profiles)
local folder = Instance.new("Folder")
folder.Name = "TemporarySkyCombatTest"
folder.Parent = RS
local report = Instance.new("RemoteEvent")
report.Name, report.Parent = "Report", folder
local observePosition = Instance.new("RemoteFunction")
observePosition.Name, observePosition.Parent = "ObservePosition", folder
observePosition.OnServerInvoke = function(player, clientPosition)
	if typeof(clientPosition) ~= "Vector3" or clientPosition.X ~= clientPosition.X
		or clientPosition.Y ~= clientPosition.Y or clientPosition.Z ~= clientPosition.Z
		or clientPosition.Magnitude > 1e6 then return nil end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root and {Distance = (root.Position - clientPosition).Magnitude,
		Position = {root.Position.X, root.Position.Y, root.Position.Z}, Anchored = root.Anchored} or nil
end
local reports, promptEvents = {}, {}
report.OnServerEvent:Connect(function(player, tag, payload)
	if type(tag) ~= "string" or #tag > 40 or (type(payload) ~= "table" and type(payload) ~= "string") then return end
	reports[player.Name] = reports[player.Name] or {}
	reports[player.Name][tag] = payload
	if tag == "Completed" and type(payload) == "table" and type(payload.Stage) == "string" then
		reports[player.Name].CompletedStages = reports[player.Name].CompletedStages or {}
		reports[player.Name].CompletedStages[payload.Stage] = true
	end
	if (tag == "BeforeUse" or tag == "AfterUse") and type(payload) == "table" and type(payload.Prompt) == "string" then
		local entry = reports[player.Name]
		entry.Prompts = entry.Prompts or {}
		entry.Prompts[payload.Prompt] = entry.Prompts[payload.Prompt] or {}
		entry.Prompts[payload.Prompt][tag] = payload
	end
end)
local function observePrompt(prompt)
	local function record(kind, player)
		local c = player.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		local saved = Profiles.get(player)
		local values = promptEvents[player.Name] or {}
		promptEvents[player.Name] = values
		table.insert(values, {Kind = kind, Prompt = prompt:GetFullName(), Time = W:GetServerTimeNow(),
			Distance = root and (root.Position - prompt.Parent.Position).Magnitude,
			Anchored = root and root.Anchored, ProfileAvailable = saved ~= nil,
			Coins = saved and saved.Coins, Bat = saved and saved.Bat, Shields = saved and saved.Shields,
			Enabled = prompt.Enabled, MaxDistance = prompt.MaxActivationDistance, Hold = prompt.HoldDuration,
			Biome = player:GetAttribute("CurrentBiome"), Traveling = player:GetAttribute("PortalTraveling")})
	end
	prompt.PromptButtonHoldBegan:Connect(function(player)
		record("HoldBegan", player)
	end)
	prompt.PromptButtonHoldEnded:Connect(function(player)
		record("HoldEnded", player)
	end)
	prompt.Triggered:Connect(function(player)
		record("Triggered", player)
	end)
end
observePrompt(W.SkyGearShop.BatCounter.PurchasePrompt)
observePrompt(W.SkyGearShop.ShieldCounter.PurchasePrompt)
observePrompt(W.BoostWorkshop.Counter.UpgradePrompt)
local function diagnostics()
	local states = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local c = player.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		local root = c and c:FindFirstChild("HumanoidRootPart")
		local stats = player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins")
		local state = {Coins = coins and coins.Value, Bat = player:GetAttribute("OwnsBat"),
			Boost = player:GetAttribute("BoostLevel"), Shields = player:GetAttribute("EggShieldCharges"),
			Loaded = player:GetAttribute("DataLoaded"), Biome = player:GetAttribute("CurrentBiome"),
			Plot = player:GetAttribute("CampPlotId"), Traveling = player:GetAttribute("PortalTraveling"),
			Alive = h and h.Health > 0, PvPMessage = player:GetAttribute("PvPMessage")}
		if root then
			state.Position = {root.Position.X, root.Position.Y, root.Position.Z}
			state.BatDistance = (root.Position - W.SkyGearShop.BatCounter.Position).Magnitude
			state.ShieldDistance = (root.Position - W.SkyGearShop.ShieldCounter.Position).Magnitude
			state.BoostDistance = (root.Position - W.BoostWorkshop.Counter.Position).Magnitude
		end
		states[player.Name] = state
	end
	return {players = states, clients = reports, promptEvents = promptEvents}
end
local ended, results = false, {}
local function finish(value)
	if ended then return end
	ended = true
	value.diagnostics = diagnostics()
	Test:EndTest(value)
end
task.delay(330, function()
	finish({passed=false,stage=folder:GetAttribute("Stage"),error="Overall timeout"})
end)
local function await(fn, seconds)
	local deadline = os.clock() + seconds
	repeat
		for name, values in pairs(reports) do
			if values.Error then
				error(name .. ": " .. tostring(values.Error))
			end
		end
		if fn() then return end
		task.wait(0.05)
	until os.clock() >= deadline
	error("Timed out at " .. tostring(folder:GetAttribute("Stage")))
end
local function stage(name)
	folder:SetAttribute("Stage", name)
end
local function completed(name)
	await(function()
		for _, player in ipairs(Players:GetPlayers()) do
			local values = reports[player.Name]
			if not values or not values.CompletedStages or not values.CompletedStages[name] then return false end
		end
		return true
	end,15)
end
local function pose(name)
	stage(name)
	completed(name)
end
local ok, failure = xpcall(function()
	await(function()
		return #Players:GetPlayers()==2
	end, 100)
	local people=Players:GetPlayers()
	table.sort(people,function(a,b)
		return a.Name<b.Name
	end)
	local a,b=people[1],people[2]
	stage("Ready")
	for role,p in ipairs(people) do
		p:SetAttribute("TemporaryCombatRole",role)
		await(function()
			return p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p:FindFirstChild("leaderstats")
				and p:GetAttribute("DataLoaded") and p:GetAttribute("BoostLevel") ~= nil
				and p:GetAttribute("OwnsBat") ~= nil and p:GetAttribute("EggShieldCharges") ~= nil
				and p:GetAttribute("CampPlotId") and p:GetAttribute("CurrentBiome") == "Base Camp"
		end,45)
		p.leaderstats.Coins.Value=9000
	end
	await(function()
		return reports[a.Name] and reports[a.Name].Ready and reports[b.Name] and reports[b.Name].Ready
	end,45)
	stage("Shop")
	await(function()
		return a:GetAttribute("OwnsBat") and a:GetAttribute("BoostLevel")==1 and b:GetAttribute("EggShieldCharges")==1
	end,25)
	assert(a.leaderstats.Coins.Value==3500 and b.leaderstats.Coins.Value==6000, "private shop balances")
	results.purchases={bat=5000,shield=3000,boost=500}
	stage("SafeBase")
	completed("SafeBase")
	assert(not b.Character:GetAttribute("CombatStunnedUntil") and b.Character.Humanoid.Health==100, "base rejects hits")
	results.baseSafe=true
	stage("Meadow")
	await(function()
		local ac,bc=a.Character,b.Character
		return a:GetAttribute("CurrentBiome")=="Meadow" and b:GetAttribute("CurrentBiome")=="Meadow"
			and ac:FindFirstChild("Glider") and bc:FindFirstChild("Glider")
			and ac.Glider:GetAttribute("IsGliding") and bc.Glider:GetAttribute("IsGliding") and bc:FindFirstChild("CarriedEgg")
	end,45)
	task.wait(6)
	local offer=b.Character.CarriedEgg:GetAttributes()
	assert(offer.Rarity=="Rare", "native guarded Rare pickup")
	pose("PoseSlap")
	stage("Slap")
	await(function()
		return (b.Character:GetAttribute("CombatStunnedUntil") or 0)>W:GetServerTimeNow()
	end,4)
	assert(b.Character.Humanoid.WalkSpeed==0 and b.Character.Humanoid.Health==100, "slap stuns without health damage")
	assert(b.Character:FindFirstChild("CarriedEgg"))
	results.slapStunAndCargoPreserved=true
	task.wait(3.1)
	assert(not b.Character:GetAttribute("CombatStunnedUntil") and b.Character.Humanoid.WalkSpeed==16, "stun movement restored")
	assert(not b.Character.HumanoidRootPart:FindFirstChild("CombatImpactVelocity"), "stun force removed")
	results.stunCleanup=true
	pose("PoseShield")
	stage("Shield")
	await(function()
		return b:GetAttribute("EggShieldCharges")==0 and (b.Character.CarriedEgg:GetAttribute("EggShieldUntil") or 0)>W:GetServerTimeNow()
	end,4)
	local expires=b.Character.CarriedEgg:GetAttribute("EggShieldUntil")
	stage("ShieldSteal")
	completed("ShieldSteal")
	assert(b.Character:FindFirstChild("CarriedEgg") and not a.Character:FindFirstChild("CarriedEgg"), "shield rejects theft")
	results.shieldRejectedSteal=true
	stage("Bat")
	await(function()
		return (b.Character:GetAttribute("CombatStunnedUntil") or 0)>W:GetServerTimeNow()
	end,4)
	assert(b.Character.Humanoid.Health==100, "bat does not remove health")
	results.purchasedBatStuns=true
	task.wait(3.1)
	pose("PoseDenied")
	stage("Denied")
	completed("Denied")
	assert(not a.Character:GetAttribute("CombatStunnedUntil"), "spoofed bat has no impact")
	assert(b:GetAttribute("BatReadyAt")==nil, "unowned bat never accepted")
	results.unownedSpoofAndMalformedRejected=true
	await(function()
		return W:GetServerTimeNow()>=expires
	end,14)
	pose("PoseGround")
	stage("GroundSteal")
	completed("GroundSteal")
	assert(b.Character:FindFirstChild("CarriedEgg") and not a.Character:FindFirstChild("CarriedEgg"), "grounded theft rejected")
	results.groundedTheftRejected=true
	task.wait(3.2)
	pose("PoseSteal")
	stage("Steal")
	await(function()
		return a.Character:FindFirstChild("CarriedEgg") and not b.Character:FindFirstChild("CarriedEgg")
	end,5)
	local cargo=a.Character.CarriedEgg
	assert(cargo:GetAttribute("EggId")==offer.EggId and cargo:GetAttribute("IncomeRate")==offer.IncomeRate, "air theft preserves offer")
	assert(not W.EggLoopPrototype:FindFirstChild("Egg3"), "exclusive source remains reserved")
	results.airStealPreservedOffer={id=offer.EggId,income=offer.IncomeRate,tier=offer.EggTier,scale=offer.EggScale}
	stage("BackSteal")
	completed("BackSteal")
	assert(a.Character:FindFirstChild("CarriedEgg") and not b.Character:FindFirstChild("CarriedEgg"), "transfer grace rejects take-back")
	results.transferGraceRejectedImmediateTakeBack=true
	stage("FormerOwnerReset")
	b:LoadCharacterAsync()
	task.wait(2)
	assert(a.Character:FindFirstChild("CarriedEgg") and not W.EggLoopPrototype:FindFirstChild("Egg3"), "former owner respawn preserves transfer")
	results.formerOwnerRespawnDidNotReleaseStolenEgg=true
	stage("Deposit")
	await(function()
		return a:GetAttribute("EggDisplayCount")==1
	end,40)
	assert(a:GetAttribute("EggIncomeRate")==offer.IncomeRate and b:GetAttribute("EggIncomeRate")==0, "only new owner receives income")
	local display=W.CampPlots[a:GetAttribute("CampPlotId")].Slots.Slot1.DisplayedEgg
	assert(display:GetAttribute("EggId")==offer.EggId and display:GetAttribute("OwnerUserId")==a.UserId, "new owner display retains offer")
	results.newOwnerDisplayAndIncome=true
	results.clients=2
end,debug.traceback)
results.passed=ok
if not ok then
	results.error=failure
	results.stage=folder:GetAttribute("Stage")
end
finish(results)
