return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Server = ServerScriptService:WaitForChild("Server")
	local Shared = ReplicatedStorage:WaitForChild("Shared")

	local GridSystem = require(Server.Systems:WaitForChild("GridSystem"))
	local Constants = require(Shared:WaitForChild("Constants"))

	local PLAYER_A = 1
	local PLAYER_B = 2

	beforeEach(function()
		GridSystem.Init()
	end)

	describe("bounds checks", function()
		it("valid in-bounds coordinates", function()
			local size = Constants.Grid.START_SIZE
			expect(GridSystem.IsInBounds(1, 1)).to.equal(true)
			expect(GridSystem.IsInBounds(size, size)).to.equal(true)
		end)

		it("invalid out-of-bounds coordinates", function()
			local size = Constants.Grid.START_SIZE
			expect(GridSystem.IsInBounds(0, 1)).to.equal(false)
			expect(GridSystem.IsInBounds(1, 0)).to.equal(false)
			expect(GridSystem.IsInBounds(size + 1, 1)).to.equal(false)
			expect(GridSystem.IsInBounds(1, size + 1)).to.equal(false)
		end)
	end)

	describe("placement rules", function()
		it("cannot place out of bounds", function()
			local size = Constants.Grid.START_SIZE
			local ok, err = GridSystem.PlaceMachine(PLAYER_A, "gen", size + 1, 1, 0)
			expect(ok).to.equal(false)
			expect(err).to.equal("out_of_bounds")
		end)

		it("cannot place on occupied tile", function()
			local ok1 = GridSystem.PlaceMachine(PLAYER_A, "gen", 2, 2, 0)
			local ok2, err = GridSystem.PlaceMachine(PLAYER_A, "mult", 2, 2, 1)
			expect(ok1).to.equal(true)
			expect(ok2).to.equal(false)
			expect(err).to.equal("occupied")
		end)

		it("can remove then place again", function()
			local ok1 = GridSystem.PlaceMachine(PLAYER_A, "gen", 3, 3, 0)
			local okRemove = GridSystem.RemoveMachine(PLAYER_A, 3, 3)
			local ok2 = GridSystem.PlaceMachine(PLAYER_A, "mult", 3, 3, 2)
			expect(ok1).to.equal(true)
			expect(okRemove).to.equal(true)
			expect(ok2).to.equal(true)
		end)
	end)

	describe("rotation", function()
		it("rejects invalid rotations", function()
			GridSystem.PlaceMachine(PLAYER_A, "gen", 1, 1, 0)
			local ok, err = GridSystem.RotateMachine(PLAYER_A, 1, 1, 4)
			expect(ok).to.equal(false)
			expect(err).to.equal("invalid_rotation")
		end)

		it("updates rotation", function()
			GridSystem.PlaceMachine(PLAYER_A, "gen", 1, 1, 0)
			local ok = GridSystem.RotateMachine(PLAYER_A, 1, 1, 3)
			expect(ok).to.equal(true)
			local placements = GridSystem.GetPlacedMachines(PLAYER_A)
			expect(#placements).to.equal(1)
			expect(placements[1].rotation).to.equal(3)
		end)
	end)

	describe("per-player separation", function()
		it("isolates grids per playerId", function()
			GridSystem.PlaceMachine(PLAYER_A, "gen", 2, 2, 0)
			local occupiedA = GridSystem.IsOccupied(PLAYER_A, 2, 2)
			local occupiedB = GridSystem.IsOccupied(PLAYER_B, 2, 2)
			expect(occupiedA).to.equal(true)
			expect(occupiedB).to.equal(false)
		end)
	end)
end
