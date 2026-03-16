-- init.server.lua
-- Server entry point: initializes all MathStreak services

print("[MathStreak] Server script starting...")

local ok, err = pcall(function()
	local DailyMathService = require(script:WaitForChild("DailyMathService"))
	DailyMathService.init()
end)

if not ok then
	warn("[MathStreak] SERVER FAILED TO START: " .. tostring(err))
end
