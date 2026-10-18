-- Client-only modal ownership shared by all UI controllers.
local event = Instance.new("BindableEvent")
local Menus = {Current = nil}
function Menus.set(name)
	if Menus.Current == name then return end
	Menus.Current = name
	game:GetService("Players").LocalPlayer:SetAttribute("CampMenuOpen", name ~= nil)
	event:Fire(name)
end
function Menus.subscribe(callback) return event.Event:Connect(callback) end
return Menus
