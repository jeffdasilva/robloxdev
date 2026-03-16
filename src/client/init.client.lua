-- init.client.lua
-- Client entry point: initializes the MathStreak UI

local QuestionUI = require(script:WaitForChild("QuestionUI"))
local LeaderboardUI = require(script:WaitForChild("LeaderboardUI"))

QuestionUI.init()
LeaderboardUI.init(QuestionUI.getScreenGui())
