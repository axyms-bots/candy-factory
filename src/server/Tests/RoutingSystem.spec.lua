return function()
	local ServerScriptService = game:GetService("ServerScriptService")

	local Server = ServerScriptService:WaitForChild("Server")
	local GridSystem = require(Server.Systems:WaitForChild("GridSystem"))
	local RoutingSystem = require(Server.Systems:WaitForChild("RoutingSystem"))

	local PLAYER = 1

	beforeEach(function()
		GridSystem.Init()
	end)

	describe("rotation mapping", function()
		it("maps rotations to correct dx, dy", function()
			local dx, dy = RoutingSystem.GetOutputDirection(0)
			expect(dx).to.equal(0)
			expect(dy).to.equal(-1)

			dx, dy = RoutingSystem.GetOutputDirection(1)
			expect(dx).to.equal(1)
			expect(dy).to.equal(0)

			dx, dy = RoutingSystem.GetOutputDirection(2)
			expect(dx).to.equal(0)
			expect(dy).to.equal(1)

			dx, dy = RoutingSystem.GetOutputDirection(3)
			expect(dx).to.equal(-1)
			expect(dy).to.equal(0)
		end)
	end)

	describe("next node", function()
		it("connects to adjacent machine in output direction", function()
			GridSystem.PlaceMachine(PLAYER, "gen", 2, 2, 1) -- east
			GridSystem.PlaceMachine(PLAYER, "mult", 3, 2, 0)

			local nx, ny = RoutingSystem.GetNextNode(PLAYER, 2, 2)
			expect(nx).to.equal(3)
			expect(ny).to.equal(2)
		end)

		it("returns nil if next tile is empty", function()
			GridSystem.PlaceMachine(PLAYER, "gen", 2, 2, 1)
			local nx, ny = RoutingSystem.GetNextNode(PLAYER, 2, 2)
			expect(nx).to.equal(nil)
			expect(ny).to.equal(nil)
		end)
	end)

	describe("flow path", function()
		it("returns ordered list for 3-machine chain", function()
			GridSystem.PlaceMachine(PLAYER, "gen", 1, 1, 1) -- east
			GridSystem.PlaceMachine(PLAYER, "mult", 2, 1, 1) -- east
			GridSystem.PlaceMachine(PLAYER, "split", 3, 1, 0)

			local path = RoutingSystem.GetFlowPath(PLAYER, 1, 1)
			expect(#path).to.equal(3)
			expect(path[1].x).to.equal(1)
			expect(path[2].x).to.equal(2)
			expect(path[3].x).to.equal(3)
		end)

		it("stops on loop via safety cap", function()
			GridSystem.PlaceMachine(PLAYER, "a", 2, 2, 1) -- east
			GridSystem.PlaceMachine(PLAYER, "b", 3, 2, 3) -- west

			local path = RoutingSystem.GetFlowPath(PLAYER, 2, 2)
			expect(#path).to.be.greaterThan(0)
			expect(#path).to.be.lessThanOrEqual(100)
		end)
	end)
end
