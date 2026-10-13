-- Server entry point. Guardian behavior, tuning, flight and slap physics are modules.
local modules = script.Parent:WaitForChild("GuardianModules")
local Controller = require(modules:WaitForChild("Controller"))
Controller.start(script)
