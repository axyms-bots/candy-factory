local ServerScriptService = game:GetService("ServerScriptService")

local Server = ServerScriptService:WaitForChild("Server")
local DefaultGridSystem = require(Server.Systems:WaitForChild("GridSystem"))
local DefaultRoutingSystem = require(Server.Systems:WaitForChild("RoutingSystem"))

local ThroughputSystem = {}

local SPEED = {
	FAST = 0.7,
	SLOW = 1.2,
}

local SPEED_BY_MACHINE = {
	gen = SPEED.FAST,
	split = SPEED.FAST,
	mult = SPEED.SLOW,
}

local MAX_MACHINE_QUEUE = 5
local MAX_BELT_QUEUE = 3

local gridSystem = DefaultGridSystem
local routingSystem = DefaultRoutingSystem

local playerState = {}

local function keyFor(x, y)
	return tostring(x) .. "," .. tostring(y)
end

local function getPlayerState(playerId)
	local state = playerState[playerId]
	if not state then
		state = {
			machines = {}, -- key -> {processingSlot, queue, processTimer, machineId}
			belts = {}, -- key -> {queue}
			overflowEvents = {},
		}
		playerState[playerId] = state
	end
	return state
end

local function getMachineState(state, x, y)
	local key = keyFor(x, y)
	local machine = state.machines[key]
	if not machine then
		machine = {
			processingSlot = nil,
			queue = {},
			processTimer = 0,
			machineId = nil,
		}
		state.machines[key] = machine
	end
	return machine
end

local function getBeltState(state, x, y)
	local key = keyFor(x, y)
	local belt = state.belts[key]
	if not belt then
		belt = { queue = {} }
		state.belts[key] = belt
	end
	return belt
end

local function getMachineIdAt(playerId, x, y)
	local placements = gridSystem.GetPlacedMachines(playerId)
	for _, placement in ipairs(placements) do
		if placement.x == x and placement.y == y then
			return placement.machineId
		end
	end
	return nil
end

function ThroughputSystem.Init(injectedGridSystem, injectedRoutingSystem)
	if injectedGridSystem ~= nil then
		gridSystem = injectedGridSystem
	else
		gridSystem = DefaultGridSystem
	end

	if injectedRoutingSystem ~= nil then
		routingSystem = injectedRoutingSystem
	else
		routingSystem = DefaultRoutingSystem
	end

	playerState = {}
end

function ThroughputSystem.EnqueueToMachine(playerId, x, y, candy)
	if playerId == nil then
		return false, "invalid_player"
	end
	if candy == nil or type(candy) ~= "table" then
		return false, "invalid_candy"
	end
	if not gridSystem.IsInBounds(x, y) then
		return false, "out_of_bounds"
	end
	if not gridSystem.IsOccupied(playerId, x, y) then
		return false, "no_machine"
	end

	local state = getPlayerState(playerId)
	local machine = getMachineState(state, x, y)
	if #machine.queue >= MAX_MACHINE_QUEUE then
		return false, "queue_full"
	end

	-- Cache machineId for speed lookup
	machine.machineId = getMachineIdAt(playerId, x, y)
	table.insert(machine.queue, candy)
	return true
end

function ThroughputSystem.Step(playerId, deltaTime)
	local state = getPlayerState(playerId)
	local placements = gridSystem.GetPlacedMachines(playerId)
	-- Deterministic ordering for tests
	table.sort(placements, function(a, b)
		if a.x == b.x then
			return a.y < b.y
		end
		return a.x < b.x
	end)

	-- Phase 0: load processing slots from queue (no time decrement this step)
	for _, placement in ipairs(placements) do
		local machine = getMachineState(state, placement.x, placement.y)
		machine.machineId = placement.machineId
		if machine.processingSlot == nil and #machine.queue > 0 then
			machine.processingSlot = table.remove(machine.queue, 1)
			local speed = SPEED_BY_MACHINE[machine.machineId] or SPEED.FAST
			machine.processTimer = speed
		end
	end

	-- Phase 1: tick existing processing slots and emit outputs
	for _, placement in ipairs(placements) do
		local machine = getMachineState(state, placement.x, placement.y)

		if machine.processingSlot ~= nil then
			local nx, ny = routingSystem.GetNextNode(playerId, placement.x, placement.y)
			-- If no next node, treat as blocked: do not process this tick
			if nx ~= nil and ny ~= nil then
				machine.processTimer = machine.processTimer - deltaTime
				if machine.processTimer <= 0 then
					local candy = machine.processingSlot
					machine.processingSlot = nil
					machine.processTimer = 0

					local targetMachine = getMachineState(state, nx, ny)
					local effectiveSize = #targetMachine.queue + (targetMachine.processingSlot and 1 or 0)
					-- If destination is already full, route to belt/overflow immediately
					if effectiveSize >= MAX_MACHINE_QUEUE then
						local belt = getBeltState(state, placement.x, placement.y)
						if #belt.queue < MAX_BELT_QUEUE then
							table.insert(belt.queue, candy)
						else
							table.insert(state.overflowEvents, {
								type = "overflow",
								value = candy.value or 0,
								xp = (candy.value or 0) * 0.75,
							})
						end
					else
						table.insert(targetMachine.queue, candy)
					end
				end
			end
		end
	end

	-- Phase 2: move belt queues into next machine queues when possible (if space exists)
	for key, belt in pairs(state.belts) do
		if #belt.queue > 0 then
			local parts = string.split(key, ",")
			local x = tonumber(parts[1])
			local y = tonumber(parts[2])
			if x and y and gridSystem.IsOccupied(playerId, x, y) then
				local nx, ny = routingSystem.GetNextNode(playerId, x, y)
				if nx ~= nil and ny ~= nil and gridSystem.IsOccupied(playerId, nx, ny) then
					local machine = getMachineState(state, nx, ny)
					local effectiveSize = #machine.queue + (machine.processingSlot and 1 or 0)
					if effectiveSize < MAX_MACHINE_QUEUE then
						while #belt.queue > 0 and effectiveSize < MAX_MACHINE_QUEUE do
							table.insert(machine.queue, table.remove(belt.queue, 1))
							effectiveSize += 1
						end
					end
				end
			end
		end
	end
end

function ThroughputSystem.GetMachineState(playerId, x, y)
	local state = getPlayerState(playerId)
	local machine = getMachineState(state, x, y)
	return machine
end

function ThroughputSystem.GetBeltState(playerId, x, y)
	local state = getPlayerState(playerId)
	local belt = getBeltState(state, x, y)
	return belt
end

function ThroughputSystem.GetOverflowEvents(playerId)
	local state = getPlayerState(playerId)
	return state.overflowEvents
end

return ThroughputSystem
