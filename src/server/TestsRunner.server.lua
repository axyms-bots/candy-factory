-- TestEZ runner for Studio
local ServerScriptService = game:GetService("ServerScriptService")
local ServerRoot = ServerScriptService:WaitForChild("Server")

local TestEZ = require(ServerRoot.ThirdParty.TestEZ)
local Tests = ServerRoot:WaitForChild("Tests")

local results = TestEZ.TestBootstrap:run({ Tests }, TestEZ.Reporters.TextReporter)

-- TestEZ returns a boolean success OR a results table depending on version
local success = results
if type(results) == "table" then
	success = results.success
end

if not success then
	error("TestEZ: one or more tests failed")
end
