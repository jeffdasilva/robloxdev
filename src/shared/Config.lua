-- Config.lua
-- Game-wide configuration constants for BrainBlitz

local Config = {}

-- Version identifier (updated by Makefile at build time)
Config.VERSION = "c1f5486-dirty"
Config.BUILD_TIME = "2026-03-16 05:34 UTC"

-- How many attempts the player gets per daily question
Config.MAX_ATTEMPTS = 5

-- DataStore keys
Config.DATA_STORE_NAME = "BrainBlitzPlayerData_v1"
Config.LEADERBOARD_KEY = "GlobalLeaderboard_v1"
Config.ORDERED_STORE_NAME = "BrainBlitzLeaderboard_v1"

-- Leaderboard settings
Config.LEADERBOARD_SIZE = 50

-- UI Colors (modern, vibrant palette for kids)
Config.Colors = {
	Background = Color3.fromRGB(18, 18, 30),
	Panel = Color3.fromRGB(30, 30, 50),
	PanelLight = Color3.fromRGB(45, 45, 70),
	Accent = Color3.fromRGB(110, 75, 255),
	AccentGlow = Color3.fromRGB(140, 110, 255),
	Success = Color3.fromRGB(50, 205, 100),
	Error = Color3.fromRGB(255, 70, 80),
	Warning = Color3.fromRGB(255, 200, 50),
	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 200),
	Gold = Color3.fromRGB(255, 215, 0),
	Silver = Color3.fromRGB(192, 192, 210),
	Bronze = Color3.fromRGB(205, 127, 50),
	Streak = Color3.fromRGB(255, 140, 50),
}

-- UI Fonts
Config.Fonts = {
	Title = Enum.Font.FredokaOne,
	Body = Enum.Font.GothamBold,
	BodyLight = Enum.Font.Gotham,
	Mono = Enum.Font.Code,
}

-- Remote event/function names
Config.Remotes = {
	GetDailyQuestion = "BrainBlitz_GetDailyQuestion",
	SubmitAnswer = "BrainBlitz_SubmitAnswer",
	GetPlayerData = "BrainBlitz_GetPlayerData",
	GetLeaderboard = "BrainBlitz_GetLeaderboard",
	PlayerDataUpdated = "BrainBlitz_PlayerDataUpdated",
}

return Config
