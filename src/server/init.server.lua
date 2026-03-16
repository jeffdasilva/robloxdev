-- init.server.lua
-- Server entry point: initializes all MathStreak services

local DailyMathService = require(script:WaitForChild("DailyMathService"))
DailyMathService.init()
