-- Unmapped two-client regression. Local preview only; never touches cloud saves.
local Test = game:GetService("StudioTestService")
if not game:GetService("RunService"):IsStudio() or Test:GetTestArgs() ~= "CampShopProof" then return end
if game.GameId ~= 0 then Test:EndTest({passed = false, error = "Use an unassociated preview"}) return end
local Players = game:GetService("Players")
local folder = Instance.new("Folder")
folder.Name, folder.Parent = "TemporaryCampShopProof", game.ReplicatedStorage
local report = Instance.new("RemoteEvent")
report.Name, report.Parent = "Report", folder
local reports = {}
report.OnServerEvent:Connect(function(p, value) reports[p] = value end)
local ended = false
local function finish(value)
	if ended then return end
	ended = true
	Test:EndTest(value)
end
task.delay(110, function() finish({passed = false, error = "Timeout"}) end)
local ok, result = pcall(function()
	local deadline = os.clock() + 45
	repeat task.wait(.1) until #Players:GetPlayers() == 2 or os.clock() > deadline
	assert(#Players:GetPlayers() == 2, "Need two clients")
	for _, p in Players:GetPlayers() do
		repeat task.wait(.1) until (p:GetAttribute("DataLoaded") and p:GetAttribute("BoostLevel") ~= nil and p:GetAttribute("OwnsBat") ~= nil and p.Character) or os.clock() > deadline
		assert(p:GetAttribute("DataLoaded"), "Profile load")
		p.leaderstats.Coins.Value = 15000
	end
	folder:SetAttribute("Stage", "Inside")
	repeat task.wait(.1) until reports[Players:GetPlayers()[1]] and reports[Players:GetPlayers()[2]] or os.clock() > deadline + 35
	for _, p in Players:GetPlayers() do
		assert(reports[p] and reports[p].passed, p.Name .. ": " .. tostring(reports[p] and reports[p].error))
		assert(p.leaderstats.Coins.Value == 6500, "Authoritative total")
		assert(p:GetAttribute("OwnsBat") == true and p:GetAttribute("EggShieldCharges") == 1 and p:GetAttribute("BoostLevel") == 1, "Separate entitlements")
		reports[p] = nil
		p:SetAttribute("PortalTraveling", true)
	end
	folder:SetAttribute("Stage", "Travel")
	repeat task.wait(.1) until reports[Players:GetPlayers()[1]] and reports[Players:GetPlayers()[2]] or os.clock() > deadline + 55
	local clients = {}
	for _, p in Players:GetPlayers() do
		assert(reports[p] and reports[p].passed, p.Name .. ": travel rejection failed")
		assert(p.leaderstats.Coins.Value == 6500, "Travel request charged coins")
		table.insert(clients, {player = p.Name, coins = 6500, checks = reports[p].checks})
		p:SetAttribute("PortalTraveling", false)
	end
	return {passed = true, clients = clients, isolatedTransactions = true, staleRejected = true, malformedRejected = true, travelRejected = true}
end)
finish(ok and result or {passed = false, error = tostring(result)})
