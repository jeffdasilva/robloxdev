-- init.server.lua
-- Server entry point: initializes all BrainBlitz services

print("[BrainBlitz] Server script starting...")

local ok, err = pcall(function()
	local DailyMathService = require(script:WaitForChild("DailyMathService"))
	DailyMathService.init()
end)

if not ok then
	warn("[BrainBlitz] SERVER FAILED TO START: " .. tostring(err))
end
