-- init.client.lua
-- Client entry point: initializes the MathStreak UI

print("[MathStreak] Client script starting...")

local ok, err = pcall(function()
	local QuestionUI = require(script:WaitForChild("QuestionUI"))
	local LeaderboardUI = require(script:WaitForChild("LeaderboardUI"))

	QuestionUI.init()
	LeaderboardUI.init(QuestionUI.getScreenGui())
end)

if not ok then
	warn("[MathStreak] CLIENT FAILED TO START: " .. tostring(err))

	-- Show error on screen so the user can see what happened
	local Players = game:GetService("Players")
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local errorGui = Instance.new("ScreenGui")
	errorGui.Name = "MathStreakError"
	errorGui.ResetOnSpawn = false
	errorGui.Parent = playerGui

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
	bg.BorderSizePixel = 0
	bg.Parent = errorGui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.8, 0, 0, 200)
	label.Position = UDim2.new(0.5, 0, 0.5, 0)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 70, 80)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.TextWrapped = true
	label.Text = "MathStreak Error:\n\n" .. tostring(err) .. "\n\nCheck Output window (View > Output) for details."
	label.Parent = bg
end
