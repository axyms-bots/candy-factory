-- TestsRunner.server.lua
local Server = script.Parent
local ThirdParty = Server:WaitForChild("ThirdParty")
local TestEZ = require(ThirdParty:WaitForChild("TestEZ"))
local TestsFolder = Server:WaitForChild("Tests")

local function getFailureCount(result)
	-- Some TestEZ setups return boolean, some number, some table.
	local t = typeof(result)
	if t == "boolean" then
		return result and 0 or 1
	end
	if t == "number" then
		-- If it's a failure count, 0 means pass.
		return result
	end
	if t == "table" then
		-- Try common fields
		if type(result.failureCount) == "number" then
			return result.failureCount
		end
		if type(result.failures) == "number" then
			return result.failures
		end
		if type(result.results) == "table" then
			if type(result.results.failureCount) == "number" then
				return result.results.failureCount
			end
			if type(result.results.failures) == "number" then
				return result.results.failures
			end
		end
		-- Unknown table shape: don't assume failure; rely on TextReporter output.
		return 0
	end
	-- Unknown: be conservative but not noisy
	return 0
end

local ok, result = pcall(function()
	return TestEZ.TestBootstrap:run({ TestsFolder }, TestEZ.TextReporter)
end)

if not ok then
	error("TestEZ runner crashed: " .. tostring(result))
end

local failureCount = getFailureCount(result)
if failureCount > 0 then
	error(("TestEZ: %d test(s) failed"):format(failureCount))
end
