-- Assign gardens on join and retain them through character respawns.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Plot = require(script.Parent.Plot)
local Profiles = require(script.Parent.Parent:WaitForChild("DataModules"):WaitForChild("Profiles"))
local Controller = {}
local started = false
function Controller.start(callbacks)
	assert(not started, "Start camp collection only once")
	started = true
	local folder = Workspace:WaitForChild("CampPlots", 10)
	assert(folder, "Run the SharedCamp Edit-mode setup first")
	local plots, assignments, waiting, versions = {}, {}, {}, {}
	function Controller.rebirth(player, data)
		local plot = assignments[player]
		if plot then
			plot:rebirth(data)
		end
	end
	local function notice(player, message)
		if player.Parent ~= Players then return end
		local version = (versions[player] or 0) + 1
		versions[player] = version
		player:SetAttribute("CollectionMessage", message)
		task.delay(4, function()
			if player.Parent == Players and versions[player] == version then
				player:SetAttribute("CollectionMessage", nil)
			end
		end)
	end
	local models = folder:GetChildren()
	table.sort(models, function(a, b)
		return (a:GetAttribute("PlotIndex") or 0) < (b:GetAttribute("PlotIndex") or 0)
	end)
	for _, model in ipairs(models) do
		if model:IsA("Model") then
			table.insert(plots, Plot.new(model, callbacks, notice))
		end
	end
	assert(#plots == 6, "The shared camp needs six authored plots")
	local function assign(player)
		local profile = Profiles.await(player)
		if not profile then return end
		if assignments[player] or player.Parent ~= Players then return end
		for _, plot in ipairs(plots) do
			if plot:isAvailable() and plot:claim(player) then
				assignments[player] = plot
				waiting[player] = nil
				player:SetAttribute("CampPlotId", plot.Model.Name)
				notice(player, "Your egg garden: " .. plot.Model.Name .. ". Look for your name above its gate.")
				return
			end
		end
		waiting[player] = true
		player:SetAttribute("CampPlotId", nil)
		player:SetAttribute("EggDisplayCapacity", 0)
		player:SetAttribute("EggDisplayCount", 0)
		player:SetAttribute("EggIncomeRate", 0)
		player:SetAttribute("EggIncomePending", 0)
		notice(player, "All six camps are occupied. A garden will be assigned when one becomes available.")
	end
	Players.PlayerAdded:Connect(assign)
	Players.PlayerRemoving:Connect(function(player)
		local plot = assignments[player]
		assignments[player], waiting[player], versions[player] = nil, nil, nil
		if plot then
			plot:release(player)
			for _, nextPlayer in ipairs(Players:GetPlayers()) do
				if waiting[nextPlayer] then
					assign(nextPlayer)
					break
				end
			end
		end
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(assign, player)
	end
	task.spawn(function()
		while folder.Parent do
			for _, plot in ipairs(plots) do
				plot:publish()
			end
			task.wait(1)
		end
	end)
	Profiles.capture(function(player, data)
		local plot = assignments[player]
		if plot then
			plot:snapshot(data)
		end
	end)
end
return Controller
