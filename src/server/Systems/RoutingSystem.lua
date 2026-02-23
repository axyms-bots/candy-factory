local ServerScriptService = game:GetService("ServerScriptService")

local Server = ServerScriptService:WaitForChild("Server")
local GridSystem = require(Server.Systems:WaitForChild("GridSystem"))

local RoutingSystem = {}

local MAX_PATH = 100

function RoutingSystem.GetOutputDirection(rotation)
	if rotation == 0 then
		return 0, -1
	elseif rotation == 1 then
		return 1, 0
	elseif rotation == 2 then
		return 0, 1
	elseif rotation == 3 then
		return -1, 0
	end
	return 0, 0
end

function RoutingSystem.GetNextNode(playerId, x, y)
	local placements = GridSystem.GetPlacedMachines(playerId)
	local rotation
	for _, placement in ipairs(placements) do
		if placement.x == x and placement.y == y then
			rotation = placement.rotation
			break
		end
	end
	if rotation == nil then
		return nil, nil
	end

	local dx, dy = RoutingSystem.GetOutputDirection(rotation)
	local nx, ny = x + dx, y + dy

	if not GridSystem.IsInBounds(nx, ny) then
		return nil, nil
	end

	if not GridSystem.IsOccupied(playerId, nx, ny) then
		return nil, nil
	end

	return nx, ny
end

function RoutingSystem.GetFlowPath(playerId, startX, startY)
	local path = {}
	local currentX, currentY = startX, startY
	local visited = {}

	for _ = 1, MAX_PATH do
		local key = tostring(currentX) .. "," .. tostring(currentY)
		if visited[key] then
			break
		end
		visited[key] = true

		table.insert(path, { x = currentX, y = currentY })

		local nx, ny = RoutingSystem.GetNextNode(playerId, currentX, currentY)
		if nx == nil or ny == nil then
			break
		end

		currentX, currentY = nx, ny
	end

	return path
end

return RoutingSystem
