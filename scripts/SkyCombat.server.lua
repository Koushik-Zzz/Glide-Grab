-- All purchases, hits and mid-air theft are decided by this server controller.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local modules = script.Parent:WaitForChild("CombatModules")
local Config, Rules, Impact = require(modules.Config), require(modules.Rules), require(modules.Impact)
local HeldBat = require(modules:WaitForChild("HeldBat"))
local eggLoop = script.Parent:WaitForChild("EggLoop")
local steal = eggLoop:WaitForChild("TryAirSteal")
local hasCargo = eggLoop:WaitForChild("HasCargo")
local shield = eggLoop:WaitForChild("ProtectCargo")
assert(not ReplicatedStorage:FindFirstChild("SkyCombat"), "Keep one SkyCombat controller")
local remote = Instance.new("RemoteEvent")
remote.Name = "SkyCombat"
remote.Parent = ReplicatedStorage
local profiles, noticeVersions = {}, {}
local function notice(p, text)
	if p.Parent ~= Players then return end
	local n = (noticeVersions[p] or 0) + 1
	noticeVersions[p] = n
	p:SetAttribute("PvPMessage", text)
	task.delay(4, function()
		if p.Parent == Players and noticeVersions[p] == n then
			p:SetAttribute("PvPMessage", nil)
		end
	end)
end
local function bind(p)
	profiles[p] = {Bat = false, Charges = 0, Ready = {}, LastRequest = 0, LastBuy = 0, HitReady = 0}
	profiles[p].Presentation = HeldBat.bind(p, function()
		return profiles[p] ~= nil and profiles[p].Bat
	end)
	p:SetAttribute("OwnsBat", false)
	p:SetAttribute("EggShieldCharges", 0)
	p.CharacterRemoving:Connect(function()
		Impact.clear(p)
	end)
end
Players.PlayerAdded:Connect(bind)
for _, p in ipairs(Players:GetPlayers()) do
	bind(p)
end
Players.PlayerRemoving:Connect(function(p)
	Impact.clear(p)
	if profiles[p] then
		profiles[p].Presentation:destroy()
	end
	profiles[p], noticeVersions[p] = nil, nil
end)
local function effect(p, action)
	local c = p.Character
	local root = c and c:FindFirstChild("HumanoidRootPart")
	if not root then return end
	for _, viewer in ipairs(Players:GetPlayers()) do
		local vc = viewer.Character
		local vr = vc and vc:FindFirstChild("HumanoidRootPart")
		if vr and (vr.Position - root.Position).Magnitude < 160 then
			remote:FireClient(viewer, "Swing", p, action)
		end
	end
end
remote.OnServerEvent:Connect(function(p, ...)
	local state, now = profiles[p], Workspace:GetServerTimeNow()
	if not state or now - state.LastRequest < Config.RequestInterval then return end
	state.LastRequest = now
	if select("#", ...) ~= 1 then return end
	local action = ...
	if type(action) ~= "string" or not Config.Cooldowns[action] then return end
	if now < (state.Ready[action] or 0) then return end
	local character = Rules.allowed(p, false)
	if not character then
		notice(p, "Base camp and the Meadow landing are safe. Fly farther out to use gear.")
		return
	end
	if action == "Bat" and not state.Bat then
		notice(p, "Buy the bat at the camp gear shop — 5,000 coins.")
		return
	end
	state.Ready[action] = now + Config.Cooldowns[action]
	p:SetAttribute(action .. "ReadyAt", state.Ready[action])
	if action == "Shield" then
		if state.Charges <= 0 then
			notice(p, "Buy egg shields at camp — 3,000 coins each.")
			return
		end
		if shield:Invoke(p) then
			state.Charges -= 1
			p:SetAttribute("EggShieldCharges", state.Charges)
			notice(p, "Egg shield active for 12 seconds. The bird can still catch you!")
		else
			notice(p, "Carry an egg first; an active shield cannot be stacked.")
		end
		return
	elseif action == "Steal" then
		if hasCargo:Invoke(p, false) then
			notice(p, "Place your egg first — stealing needs empty hands.")
			return
		end
		local target = Rules.target(p, Config.StealRange, true, function(other)
			return hasCargo:Invoke(other, true)
		end)
		if not target then
			notice(p, "Fly close behind an airborne egg carrier. Protected eggs cannot be stolen.")
			return
		end
		local ok, name = steal:Invoke(p, target)
		if ok then
			effect(p, "Slap")
			notice(p, "Stole " .. name .. " from " .. target.DisplayName .. "! Fly home!")
			notice(target, p.DisplayName .. " stole your " .. name .. "! Chase them!")
		end
		return
	end
	local weapon = Config.Weapons[action]
	if action == "Bat" then
		character:SetAttribute("BatSwingStartedAt", now)
	end
	effect(p, action)
	local originalCharacter = character
	task.delay(weapon.Windup, function()
		if p.Character ~= originalCharacter or not Rules.allowed(p, false) then return end
		local victim = Rules.target(p, weapon.Range, false, function(other)
			return profiles[other] and Workspace:GetServerTimeNow() >= profiles[other].HitReady
		end)
		if not victim then return end
		local origin = p.Character.HumanoidRootPart.Position
		if Impact.apply(victim, origin, weapon) then
			profiles[victim].HitReady = Workspace:GetServerTimeNow() + weapon.Stun + Config.HitRecovery
			notice(p, action .. " hit " .. victim.DisplayName .. "!")
			notice(victim, "Stunned! Your controls return in a moment.")
		end
	end)
end)

local shop = Workspace:WaitForChild("SkyGearShop", 10)
assert(shop, "Author SkyGearShop in Edit mode")
local function purchase(p, kind, prompt)
	local state, now = profiles[p], Workspace:GetServerTimeNow()
	if not state or now - state.LastBuy < 0.5 then return end
	state.LastBuy = now
	local c, _, root = Rules.living(p)
	if not c or not prompt.Enabled or p:GetAttribute("CurrentBiome") ~= "Base Camp"
		or not ((root.Position - prompt.Parent.Position).Magnitude <= prompt.MaxActivationDistance) then return end
	local stats = p:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if not coins or not coins:IsA("IntValue") then return end
	if kind == "Bat" and state.Bat then
		notice(p, "You already own the bat. R to swing in Meadow.")
		return
	end
	if kind == "Shield" and state.Charges >= Config.ShieldMaxCharges then
		notice(p, "You can carry at most three shield charges.")
		return
	end
	local price = kind == "Bat" and Config.BatPrice or Config.ShieldPrice
	if coins.Value < price then
		notice(p, "Need " .. (price - coins.Value) .. " more coins.")
		return
	end
	-- No yield between payment, entitlement and publication.
	coins.Value -= price
	if kind == "Bat" then
		state.Bat = true
		p:SetAttribute("OwnsBat", true)
		state.Presentation:refresh()
		notice(p, "Bat purchased! R to swing; your glider stays equipped.")
	else
		state.Charges += 1
		p:SetAttribute("EggShieldCharges", state.Charges)
		notice(p, "Shield charge purchased! G while carrying an egg in Meadow.")
	end
end
for _, kind in ipairs({"Bat", "Shield"}) do
	local prompt = shop[kind .. "Counter"].PurchasePrompt
	prompt.Triggered:Connect(function(p)
		purchase(p, kind, prompt)
	end)
end
