local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))

local GridSystem = {}
GridSystem.__index = GridSystem

-- Internal state: per-player grids
local grids = {}

local function getPlayerGrid(playerId)
	local grid = grids[playerId]
	if not grid then
		grid = {
			size = Constants.Grid.START_SIZE,
			cells = {}, -- key: "x,y" -> placement
		}
		grids[playerId] = grid
	end
	return grid
end

local function keyFor(x, y)
	return tostring(x) .. "," .. tostring(y)
end

local function isValidRotation(rotation)
	return rotation == 0 or rotation == 1 or rotation == 2 or rotation == 3
end

function GridSystem.Init()
	grids = {}
end

function GridSystem.IsInBounds(x, y)
	local size = Constants.Grid.START_SIZE
	return type(x) == "number" and type(y) == "number" and x >= 1 and y >= 1 and x <= size and y <= size
end

function GridSystem.IsOccupied(playerId, x, y)
	if not GridSystem.IsInBounds(x, y) then
		return false
	end
	local grid = getPlayerGrid(playerId)
	return grid.cells[keyFor(x, y)] ~= nil
end

function GridSystem.PlaceMachine(playerId, machineId, x, y, rotation)
	if playerId == nil then
		return false, "invalid_player"
	end
	if machineId == nil then
		return false, "invalid_machine"
	end
	if not GridSystem.IsInBounds(x, y) then
		return false, "out_of_bounds"
	end
	if not isValidRotation(rotation) then
		return false, "invalid_rotation"
	end

	local grid = getPlayerGrid(playerId)
	local key = keyFor(x, y)
	if grid.cells[key] ~= nil then
		return false, "occupied"
	end

	grid.cells[key] = {
		machineId = machineId,
		x = x,
		y = y,
		rotation = rotation,
	}

	return true
end

function GridSystem.RemoveMachine(playerId, x, y)
	if playerId == nil then
		return false, "invalid_player"
	end
	if not GridSystem.IsInBounds(x, y) then
		return false, "out_of_bounds"
	end

	local grid = getPlayerGrid(playerId)
	local key = keyFor(x, y)
	if grid.cells[key] == nil then
		return false, "not_found"
	end

	grid.cells[key] = nil
	return true
end

function GridSystem.RotateMachine(playerId, x, y, rotation)
	if playerId == nil then
		return false, "invalid_player"
	end
	if not GridSystem.IsInBounds(x, y) then
		return false, "out_of_bounds"
	end
	if not isValidRotation(rotation) then
		return false, "invalid_rotation"
	end

	local grid = getPlayerGrid(playerId)
	local key = keyFor(x, y)
	local placement = grid.cells[key]
	if placement == nil then
		return false, "not_found"
	end

	placement.rotation = rotation
	return true
end

function GridSystem.GetPlacedMachines(playerId)
	if playerId == nil then
		return {}
	end
	local grid = getPlayerGrid(playerId)
	local placements = {}
	for _, placement in pairs(grid.cells) do
		table.insert(placements, placement)
	end
	return placements
end

return GridSystem
