return function()
	local ServerScriptService = game:GetService("ServerScriptService")

	local Server = ServerScriptService:WaitForChild("Server")
	local GridSystem = require(Server.Systems:WaitForChild("GridSystem"))
	local RoutingSystem = require(Server.Systems:WaitForChild("RoutingSystem"))
	local ThroughputSystem = require(Server.Systems:WaitForChild("ThroughputSystem"))

	local PLAYER = 1

	beforeEach(function()
		GridSystem.Init()
		RoutingSystem.Init(GridSystem)
		ThroughputSystem.Init(GridSystem, RoutingSystem)
	end)

	local function placeChain()
		GridSystem.PlaceMachine(PLAYER, "gen", 1, 1, 1) -- east
		GridSystem.PlaceMachine(PLAYER, "mult", 2, 1, 1) -- east
		GridSystem.PlaceMachine(PLAYER, "split", 3, 1, 0)
	end

	describe("processing", function()
		it("processes exactly one candy at a time", function()
			GridSystem.PlaceMachine(PLAYER, "gen", 2, 2, 1)
			ThroughputSystem.EnqueueToMachine(PLAYER, 2, 2, { value = 10 })
			ThroughputSystem.EnqueueToMachine(PLAYER, 2, 2, { value = 10 })

			ThroughputSystem.Step(PLAYER, 0.1)
			local state = ThroughputSystem.GetMachineState(PLAYER, 2, 2)
			expect(state.processingSlot ~= nil).to.equal(true)
			expect(#state.queue).to.equal(1)
		end)

		it("queue cap enforced", function()
			GridSystem.PlaceMachine(PLAYER, "gen", 2, 2, 1)
			for _ = 1, 5 do
				local ok = ThroughputSystem.EnqueueToMachine(PLAYER, 2, 2, { value = 1 })
				expect(ok).to.equal(true)
			end
			local ok, err = ThroughputSystem.EnqueueToMachine(PLAYER, 2, 2, { value = 1 })
			expect(ok).to.equal(false)
			expect(err).to.equal("queue_full")
		end)
	end)

	describe("belt and overflow", function()
		it("belt cap enforced and overflow triggers", function()
			GridSystem.PlaceMachine(PLAYER, "gen", 1, 1, 1)
			GridSystem.PlaceMachine(PLAYER, "mult", 2, 1, 0)

			-- Fill destination machine queue to cap
			for _ = 1, 5 do
				ThroughputSystem.EnqueueToMachine(PLAYER, 2, 1, { value = 1 })
			end

			-- Process 4 candies from source: 3 should go to belt, 1 overflow
			for _ = 1, 4 do
				ThroughputSystem.EnqueueToMachine(PLAYER, 1, 1, { value = 10 })
				ThroughputSystem.Step(PLAYER, 0.7)
			end

			local belt = ThroughputSystem.GetBeltState(PLAYER, 2, 1)
			expect(#belt.queue).to.equal(3)

			local events = ThroughputSystem.GetOverflowEvents(PLAYER)
			expect(#events).to.equal(1)
		end)
	end)

	describe("flow", function()
		it("moves candy across 3-machine chain", function()
			placeChain()
			ThroughputSystem.EnqueueToMachine(PLAYER, 1, 1, { value = 10 })

			ThroughputSystem.Step(PLAYER, 0.7) -- gen completes
			local m2 = ThroughputSystem.GetMachineState(PLAYER, 2, 1)
			expect(#m2.queue).to.equal(1)

			ThroughputSystem.Step(PLAYER, 1.2) -- mult completes
			local m3 = ThroughputSystem.GetMachineState(PLAYER, 3, 1)
			expect(#m3.queue).to.equal(1)
		end)

		it("delta stepping deterministic", function()
			placeChain()
			ThroughputSystem.EnqueueToMachine(PLAYER, 1, 1, { value = 10 })

			ThroughputSystem.Step(PLAYER, 0.35)
			ThroughputSystem.Step(PLAYER, 0.35)
			local m2 = ThroughputSystem.GetMachineState(PLAYER, 2, 1)
			expect(#m2.queue).to.equal(1)
		end)

		it("does not infinite loop", function()
			GridSystem.PlaceMachine(PLAYER, "a", 2, 2, 1)
			GridSystem.PlaceMachine(PLAYER, "b", 3, 2, 3)
			ThroughputSystem.EnqueueToMachine(PLAYER, 2, 2, { value = 10 })
			ThroughputSystem.Step(PLAYER, 0.7)
			expect(true).to.equal(true)
		end)
	end)
end
