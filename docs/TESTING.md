# Testing

## Unit Tests (TestEZ)

### Where tests live
- `src/server/Tests/` (ServerScriptService/Server/Tests in Studio)

### How to run in Roblox Studio
1. Start Rojo (`rojo serve`) and connect the Rojo plugin.
2. In Studio, click **Play** (or **F5**).
3. Output should show TestEZ results.
   - If any tests fail, Studio will error: `TestEZ: <n> test(s) failed`.

### Manual Validation (M1 - GridSystem)
1. Start Rojo and connect.
2. Press Play.
3. Confirm Output shows TestEZ summary and **no** TestsRunner error lines.

### Manual Validation (M1 - RoutingSystem)
1. Start Rojo and connect.
2. Press Play.
3. Confirm TestEZ summary includes RoutingSystem tests and no errors.

### Test Runner
- `src/server/TestsRunner.server.lua`
- Loads TestEZ from `src/server/ThirdParty/TestEZ/` and runs all tests under `Tests`.
