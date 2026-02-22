-- TestEZ runner for Studio
local ServerScriptService = game:GetService("ServerScriptService")
local ServerRoot = ServerScriptService:WaitForChild("Server")

local TestEZ = require(ServerRoot.ThirdParty.TestEZ)
local Tests = ServerRoot:WaitForChild("Tests")

local results = TestEZ.TestBootstrap:run({ Tests }, TestEZ.Reporters.TextReporter)

if not results.success then
	error("TestEZ: one or more tests failed")
end
