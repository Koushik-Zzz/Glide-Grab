if not game:GetService("RunService"):IsStudio() then return end
local RS = game:GetService("ReplicatedStorage")
local folder = RS:WaitForChild("TemporaryCampShopProof", 50)
if not folder then return end
local p = game.Players.LocalPlayer
local shop = RS:WaitForChild("CampShop")
local replies, serial, checks = {}, 0, 0
shop.OnClientEvent:Connect(function(id, ok, message, catalogue) replies[id] = {ok, message, catalogue} end)
local function check(value, message) assert(value, message) checks += 1 end
local function call(action, item, expected)
	task.wait(.6)
	serial += 1
	shop:FireServer(action, serial, item, expected)
	local untilTime = os.clock() + 8
	repeat task.wait(.05) until replies[serial] or os.clock() > untilTime
	check(replies[serial] ~= nil, "Missing reply")
	return table.unpack(replies[serial])
end
local function run(stage)
	local ok, err = pcall(function()
		if stage == "Inside" then
			local accepted, _, catalogue = call("Browse", "", false)
			check(accepted and catalogue.BatPrice == 5000 and catalogue.Levels["1"].Price == 500, "Catalogue prices")
			check(call("Buy", "Bat", false), "Bat buy")
			check(not call("Buy", "Bat", false), "Duplicate bat")
			check(call("Buy", "Shield", 0), "Shield buy")
			check(not call("Buy", "Shield", 0), "Stale shield")
			check(call("Buy", "Boost", 0), "Boost buy")
			check(not call("Buy", "Boost", 0), "Stale boost")
			check(not call("Buy", "Boost", "1"), "Wrong expected type")
			check(not call("Buy", "FreeMoney", 0), "Unknown SKU")
			shop:FireServer("Buy", 999, "Shield", 1, -3000)
			task.wait(.3)
			check(p.leaderstats.Coins.Value == 6500, "Malformed request / final balance")
			local gui = p.PlayerGui:WaitForChild("CampMenu")
			check(gui.SafeScreen.Overlay.Modal.Items.Bat.Action.Price.Text == "OWNED", "UI ownership")
		else
			check(not call("Buy", "Shield", 1), "Travel rejected")
			check(p.leaderstats.Coins.Value == 6500, "Travel balance")
		end
	end)
	folder.Report:FireServer({passed = ok, error = tostring(err), checks = checks})
end
folder:GetAttributeChangedSignal("Stage"):Connect(function() run(folder:GetAttribute("Stage")) end)
if folder:GetAttribute("Stage") then run(folder:GetAttribute("Stage")) end
