-- EDIT-only temporary test staging. Not mapped by Rojo and never published.
-- Source access belongs here, not in the runtime server Script.
assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(), "Run in Edit only")
assert(game.GameId == 0, "Use an unassociated local fixture scene, never a cloud-associated save")
local scripts = game:GetService("ServerScriptService")
assert(not scripts:FindFirstChild("TemporaryResilienceModules"), "Remove old fixture before staging")
local folder = Instance.new("Folder")
folder.Name, folder.Parent = "TemporaryResilienceModules", scripts
for _, name in ipairs({"Schema", "Session"}) do
	scripts.DataModules[name]:Clone().Parent = folder
end
local backend = Instance.new("ModuleScript")
backend.Name = "Backend"
backend.Source = [==[
local Schema = require(script.Parent.Schema)
local api = {Values = {}, Policies = {}, Calls = {}}
local store = {}
function store:UpdateAsync(key, callback)
	api.Calls[key] = (api.Calls[key] or 0) + 1
	local policy = api.Policies[key]
	if policy and policy.Before > 0 then
		policy.Before -= 1
		error("fixture: request failed before write")
	end
	local result = callback(Schema.copy(api.Values[key]))
	if result ~= nil then api.Values[key] = Schema.copy(result) end
	if policy and policy.After > 0 then
		policy.After -= 1
		error("fixture: committed response was lost")
	end
	return Schema.copy(api.Values[key])
end
function api:GetDataStore() return store end
return api
]==]
backend.Parent = folder
local profiles = scripts.DataModules.Profiles:Clone()
local source, count = profiles.Source:gsub('local DataStoreService = game:GetService%("DataStoreService"%)',
	'local DataStoreService = require(script.Parent.Backend)')
assert(count == 1, "Expected one backend import")
source, count = source:gsub('local preview = RunService:IsStudio%(%) and game.GameId == 0', 'local preview = false')
assert(count == 1, "Expected one preview selector")
profiles.Source, profiles.Parent = source, folder
return {staged = folder:GetFullName(), modules = #folder:GetChildren()}
