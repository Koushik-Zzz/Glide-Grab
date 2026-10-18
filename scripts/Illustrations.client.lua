-- Keep editable symbols visible until Roblox has actually loaded the artwork.
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local gui = Players.LocalPlayer:WaitForChild("PlayerGui")
local bound, alive = {}, true
local function bind(image)
	if not image:IsA("ImageLabel") or image.Name ~= "Illustration" or bound[image] then return end
	local fallback = image.Parent:FindFirstChild("VectorFallback")
	if not fallback then return end
	local connections = {}
	bound[image] = connections
	local version = 0
	local function load()
		version += 1
		local expected, source = version, image.Image
		-- Hidden ImageLabels may report IsLoaded=false even after a successful
		-- fetch. Render the transparent layer and gate the fallback on fetch status.
		image.Visible, fallback.Visible = true, true
		task.spawn(function()
			local fetched = false
			pcall(function()
				ContentProvider:PreloadAsync({image}, function(_, status)
					fetched = status == Enum.AssetFetchStatus.Success
				end)
			end)
			if alive and bound[image] and version == expected and image.Image == source then
				fallback.Visible = not fetched
			end
		end)
	end
	table.insert(connections, image:GetPropertyChangedSignal("Image"):Connect(load))
	table.insert(connections, image.Destroying:Connect(function()
		for _, connection in connections do connection:Disconnect() end
		bound[image] = nil
	end))
	load()
end
local added = gui.DescendantAdded:Connect(bind)
for _, object in gui:GetDescendants() do bind(object) end
script.Destroying:Connect(function()
	alive = false
	added:Disconnect()
	for image, connections in bound do
		for _, connection in connections do connection:Disconnect() end
		if image.Parent then
			image.Visible = false
			local fallback = image.Parent:FindFirstChild("VectorFallback")
			if fallback then fallback.Visible = true end
		end
	end
	table.clear(bound)
end)
