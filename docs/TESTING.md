# Testing

## Unit Tests (TestEZ)

### Where tests live
- `src/server/Tests/` (ServerScriptService/Server/Tests in Studio)

### How to run in Roblox Studio
1. Start Rojo (`rojo serve`) and connect the Rojo plugin.
2. In Studio, click **Play** (or **F5**).
3. Output should show TestEZ results.
   - If any tests fail, Studio will error: `TestEZ: one or more tests failed`.

### Test Runner
- `src/server/TestsRunner.server.lua`
- Loads TestEZ from `src/server/ThirdParty/TestEZ/` and runs all tests under `Tests`.
