-- QuestionUI.lua
-- Builds and manages the daily math question panel

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainBlitz = ReplicatedStorage:WaitForChild("BrainBlitz")
local Config = require(BrainBlitz:WaitForChild("Config"))
local Remotes = require(BrainBlitz:WaitForChild("Remotes"))
local UIComponents = require(script.Parent:WaitForChild("UIComponents"))

local QuestionUI = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui
local mainFrame
local questionLabel
local answerBox
local submitButton
local feedbackLabel
local attemptsLabel
local streakLabel
local hintLabel
local categoryLabel
local hintButton

local currentData = nil
local showingHint = false

------------------------------------------------------------------------
-- Animations
------------------------------------------------------------------------

local function tweenIn(guiObject, duration)
	guiObject.Position = guiObject.Position + UDim2.new(0, 0, 0.05, 0)
	guiObject.BackgroundTransparency = 1
	local tween = TweenService:Create(
		guiObject,
		TweenInfo.new(duration or 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Position = guiObject.Position - UDim2.new(0, 0, 0.05, 0),
			BackgroundTransparency = 0,
		}
	)
	tween:Play()
end

local function pulseElement(guiObject)
	local orig = guiObject.Size
	local tween1 =
		TweenService:Create(guiObject, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(orig.X.Scale * 1.05, orig.X.Offset, orig.Y.Scale * 1.05, orig.Y.Offset),
		})
	tween1:Play()
	tween1.Completed:Wait()
	local tween2 = TweenService:Create(guiObject, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = orig,
	})
	tween2:Play()
end

local function shakeElement(guiObject)
	local origPos = guiObject.Position
	for i = 1, 4 do
		local offset = (i % 2 == 0) and 6 or -6
		local tween = TweenService:Create(guiObject, TweenInfo.new(0.05), {
			Position = origPos + UDim2.new(0, offset, 0, 0),
		})
		tween:Play()
		tween.Completed:Wait()
	end
	local resetTween = TweenService:Create(guiObject, TweenInfo.new(0.05), { Position = origPos })
	resetTween:Play()
end

------------------------------------------------------------------------
-- Build UI
------------------------------------------------------------------------

local function buildUI()
	-- ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BrainBlitzUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Full-screen background overlay
	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Config.Colors.Background
	bg.BorderSizePixel = 0
	bg.Parent = screenGui

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 60)
	title.Position = UDim2.new(0, 0, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "⚡ BRAIN BLITZ ⚡"
	title.TextColor3 = Config.Colors.AccentGlow
	title.Font = Config.Fonts.Title
	title.TextSize = 42
	title.Parent = bg

	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, 0, 0, 25)
	subtitle.Position = UDim2.new(0, 0, 0, 78)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Daily Brain Challenge"
	subtitle.TextColor3 = Config.Colors.TextSecondary
	subtitle.Font = Config.Fonts.BodyLight
	subtitle.TextSize = 16
	subtitle.Parent = bg

	-- Version label (bottom right)
	local versionLabel = Instance.new("TextLabel")
	versionLabel.Name = "Version"
	versionLabel.Size = UDim2.new(0, 250, 0, 20)
	versionLabel.Position = UDim2.new(1, -260, 1, -25)
	versionLabel.BackgroundTransparency = 1
	versionLabel.Text = "v" .. Config.VERSION .. " | " .. Config.BUILD_TIME
	versionLabel.TextColor3 = Color3.fromRGB(80, 80, 100)
	versionLabel.Font = Config.Fonts.BodyLight
	versionLabel.TextSize = 11
	versionLabel.TextXAlignment = Enum.TextXAlignment.Right
	versionLabel.Parent = bg

	-- Streak display (top right)
	local streakFrame = UIComponents.makePanel(bg, {
		Name = "StreakFrame",
		Size = UDim2.new(0, 180, 0, 70),
		Position = UDim2.new(1, -200, 0, 20),
		Color = Config.Colors.Panel,
		Stroke = true,
		StrokeColor = Config.Colors.Streak,
	})

	streakLabel = Instance.new("TextLabel")
	streakLabel.Name = "StreakLabel"
	streakLabel.Size = UDim2.new(1, 0, 1, 0)
	streakLabel.BackgroundTransparency = 1
	streakLabel.Text = "🔥 Streak: 0"
	streakLabel.TextColor3 = Config.Colors.Streak
	streakLabel.Font = Config.Fonts.Body
	streakLabel.TextSize = 22
	streakLabel.Parent = streakFrame

	-- Main question card
	mainFrame = UIComponents.makePanel(bg, {
		Name = "QuestionCard",
		Size = UDim2.new(0, 520, 0, 420),
		Position = UDim2.new(0.5, 0, 0.5, -20),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Color = Config.Colors.Panel,
		Stroke = true,
		StrokeColor = Config.Colors.Accent,
		StrokeThickness = 2,
	})
	UIComponents.makeShadow(mainFrame)

	-- Category badge
	categoryLabel = Instance.new("TextLabel")
	categoryLabel.Name = "Category"
	categoryLabel.Size = UDim2.new(0, 160, 0, 30)
	categoryLabel.Position = UDim2.new(0.5, 0, 0, 20)
	categoryLabel.AnchorPoint = Vector2.new(0.5, 0)
	categoryLabel.BackgroundColor3 = Config.Colors.Accent
	categoryLabel.TextColor3 = Config.Colors.TextPrimary
	categoryLabel.Font = Config.Fonts.Body
	categoryLabel.TextSize = 14
	categoryLabel.Text = "CATEGORY"
	categoryLabel.Parent = mainFrame
	UIComponents.makeCorner(categoryLabel, 15)

	-- Question text
	questionLabel = Instance.new("TextLabel")
	questionLabel.Name = "Question"
	questionLabel.Size = UDim2.new(0.85, 0, 0, 80)
	questionLabel.Position = UDim2.new(0.5, 0, 0, 70)
	questionLabel.AnchorPoint = Vector2.new(0.5, 0)
	questionLabel.BackgroundTransparency = 1
	questionLabel.TextColor3 = Config.Colors.TextPrimary
	questionLabel.Font = Config.Fonts.Body
	questionLabel.TextSize = 24
	questionLabel.TextWrapped = true
	questionLabel.Text = "Loading..."
	questionLabel.Parent = mainFrame

	-- Answer input
	answerBox = Instance.new("TextBox")
	answerBox.Name = "AnswerBox"
	answerBox.Size = UDim2.new(0.7, 0, 0, 50)
	answerBox.Position = UDim2.new(0.5, 0, 0, 180)
	answerBox.AnchorPoint = Vector2.new(0.5, 0)
	answerBox.BackgroundColor3 = Config.Colors.PanelLight
	answerBox.TextColor3 = Config.Colors.TextPrimary
	answerBox.PlaceholderText = "Type your answer here..."
	answerBox.PlaceholderColor3 = Config.Colors.TextSecondary
	answerBox.Font = Config.Fonts.Mono
	answerBox.TextSize = 22
	answerBox.ClearTextOnFocus = true
	answerBox.BorderSizePixel = 0
	answerBox.Parent = mainFrame
	UIComponents.makeCorner(answerBox, 10)
	UIComponents.makeStroke(answerBox, Config.Colors.Accent, 1)

	-- Submit button
	submitButton = UIComponents.makeButton(mainFrame, {
		Name = "SubmitButton",
		Size = UDim2.new(0.5, 0, 0, 48),
		Position = UDim2.new(0.5, 0, 0, 248),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = Config.Colors.Accent,
		Text = "🚀 SUBMIT",
		TextSize = 20,
		CornerRadius = 24,
	})

	-- Feedback label
	feedbackLabel = Instance.new("TextLabel")
	feedbackLabel.Name = "Feedback"
	feedbackLabel.Size = UDim2.new(0.85, 0, 0, 35)
	feedbackLabel.Position = UDim2.new(0.5, 0, 0, 310)
	feedbackLabel.AnchorPoint = Vector2.new(0.5, 0)
	feedbackLabel.BackgroundTransparency = 1
	feedbackLabel.TextColor3 = Config.Colors.TextPrimary
	feedbackLabel.Font = Config.Fonts.Body
	feedbackLabel.TextSize = 16
	feedbackLabel.TextWrapped = true
	feedbackLabel.Text = ""
	feedbackLabel.Parent = mainFrame

	-- Attempts label
	attemptsLabel = Instance.new("TextLabel")
	attemptsLabel.Name = "Attempts"
	attemptsLabel.Size = UDim2.new(0.5, 0, 0, 25)
	attemptsLabel.Position = UDim2.new(0.5, 0, 0, 350)
	attemptsLabel.AnchorPoint = Vector2.new(0.5, 0)
	attemptsLabel.BackgroundTransparency = 1
	attemptsLabel.TextColor3 = Config.Colors.TextSecondary
	attemptsLabel.Font = Config.Fonts.BodyLight
	attemptsLabel.TextSize = 14
	attemptsLabel.Text = ""
	attemptsLabel.Parent = mainFrame

	-- Hint button
	hintButton = UIComponents.makeButton(mainFrame, {
		Name = "HintButton",
		Size = UDim2.new(0.3, 0, 0, 32),
		Position = UDim2.new(0.5, 0, 0, 382),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = Config.Colors.Warning,
		Text = "💡 Hint",
		TextColor = Color3.fromRGB(30, 30, 50),
		TextSize = 14,
		CornerRadius = 16,
	})

	-- Hint label (hidden by default)
	hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "HintLabel"
	hintLabel.Size = UDim2.new(0.85, 0, 0, 30)
	hintLabel.Position = UDim2.new(0.5, 0, 1, -35)
	hintLabel.AnchorPoint = Vector2.new(0.5, 0)
	hintLabel.BackgroundTransparency = 1
	hintLabel.TextColor3 = Config.Colors.Warning
	hintLabel.Font = Config.Fonts.BodyLight
	hintLabel.TextSize = 13
	hintLabel.TextWrapped = true
	hintLabel.Text = ""
	hintLabel.Visible = false
	hintLabel.Parent = mainFrame

	return screenGui
end

------------------------------------------------------------------------
-- Logic
------------------------------------------------------------------------

local function updateAttempts(playerData)
	if playerData then
		local remaining = playerData.maxAttempts - playerData.attemptsUsed
		local dots = ""
		for i = 1, playerData.maxAttempts do
			if i <= remaining then
				dots = dots .. "● "
			else
				dots = dots .. "○ "
			end
		end
		attemptsLabel.Text = "Attempts: " .. dots
	end
end

local function updateStreak(playerData)
	if playerData then
		streakLabel.Text = "🔥 Streak: " .. tostring(playerData.currentStreak)
	end
end

local function setLockedState()
	answerBox.TextEditable = false
	answerBox.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	submitButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	submitButton.Text = "✅ COMPLETED"
end

local function loadQuestion()
	print("[BrainBlitz] Client: loading daily question...")
	local getDailyQuestion = Remotes.get("GetDailyQuestion")
	if not getDailyQuestion then
		warn("[BrainBlitz] Client: GetDailyQuestion remote not found")
		questionLabel.Text = "Could not connect to server.\nPlease rejoin!"
		questionLabel.TextColor3 = Config.Colors.Error
		return
	end

	local result = nil

	-- Retry up to 5 times in case the server hasn't loaded our data yet
	for i = 1, 5 do
		print("[BrainBlitz] Client: requesting question (attempt " .. i .. "/5)")
		local ok, response = pcall(function()
			return getDailyQuestion:InvokeServer()
		end)
		if ok and response then
			result = response
			break
		elseif not ok then
			warn("[BrainBlitz] Client: InvokeServer error: " .. tostring(response))
		end
		task.wait(2)
	end

	if result then
		questionLabel.Text = result.question
		categoryLabel.Text = string.upper(result.category or "MATH")
		currentData = result

		updateAttempts(result.playerData)
		updateStreak(result.playerData)

		if result.playerData.todaySolved then
			feedbackLabel.Text = "✅ You already solved today's challenge!"
			feedbackLabel.TextColor3 = Config.Colors.Success
			setLockedState()
		elseif result.playerData.attemptsUsed >= result.playerData.maxAttempts then
			feedbackLabel.Text = "No attempts remaining. Come back tomorrow!"
			feedbackLabel.TextColor3 = Config.Colors.Error
			setLockedState()
		end

		tweenIn(mainFrame, 0.5)
		print("[BrainBlitz] Client: question loaded successfully")
	else
		warn("[BrainBlitz] Client: failed to load question after all retries")
		questionLabel.Text = "Could not load today's question.\nPlease rejoin!"
		questionLabel.TextColor3 = Config.Colors.Error
	end
end

local function submitAnswer()
	if not currentData then
		return
	end

	local answer = tonumber(answerBox.Text)
	if not answer then
		feedbackLabel.Text = "Please enter a valid number!"
		feedbackLabel.TextColor3 = Config.Colors.Error
		shakeElement(answerBox)
		return
	end

	submitButton.Text = "..."
	submitButton.BackgroundColor3 = Config.Colors.PanelLight

	local submitRemote = Remotes.get("SubmitAnswer")
	local result = submitRemote:InvokeServer(answer)

	if result and result.success then
		if result.correct then
			feedbackLabel.Text = result.message
			feedbackLabel.TextColor3 = Config.Colors.Success
			pulseElement(mainFrame)
			setLockedState()

			-- confetti-like effect: change title color briefly
			task.spawn(function()
				local colors = { Config.Colors.Success, Config.Colors.Gold, Config.Colors.Accent }
				for i = 1, 6 do
					streakLabel.TextColor3 = colors[(i % #colors) + 1]
					task.wait(0.2)
				end
				streakLabel.TextColor3 = Config.Colors.Streak
			end)
		else
			feedbackLabel.Text = result.message
			feedbackLabel.TextColor3 = Config.Colors.Error
			shakeElement(answerBox)

			if result.attemptsLeft and result.attemptsLeft <= 0 then
				setLockedState()
				submitButton.Text = "❌ OUT OF ATTEMPTS"
			else
				submitButton.Text = "🚀 SUBMIT"
				submitButton.BackgroundColor3 = Config.Colors.Accent
			end
		end

		if result.playerData then
			updateAttempts(result.playerData)
			updateStreak(result.playerData)
		end
	else
		feedbackLabel.Text = (result and result.message) or "Something went wrong!"
		feedbackLabel.TextColor3 = Config.Colors.Error
		submitButton.Text = "🚀 SUBMIT"
		submitButton.BackgroundColor3 = Config.Colors.Accent
	end

	answerBox.Text = ""
end

------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------

function QuestionUI.init()
	print("[BrainBlitz] Client v" .. Config.VERSION .. " (" .. Config.BUILD_TIME .. ") initializing...")
	buildUI()

	submitButton.MouseButton1Click:Connect(submitAnswer)

	-- Also submit on Enter key
	answerBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			submitAnswer()
		end
	end)

	-- Hint toggle
	hintButton.MouseButton1Click:Connect(function()
		showingHint = not showingHint
		if showingHint and currentData then
			hintLabel.Text = "💡 " .. (currentData.hint or "")
			hintLabel.Visible = true
		else
			hintLabel.Visible = false
		end
	end)

	-- Listen for data updates from server
	local updateRemote = Remotes.get("PlayerDataUpdated")
	if updateRemote then
		updateRemote.OnClientEvent:Connect(function(playerData)
			updateAttempts(playerData)
			updateStreak(playerData)
		end)
	else
		warn("[BrainBlitz] Client: PlayerDataUpdated remote not found")
	end

	-- Load the question in a protected call so errors don't silently kill the UI
	local ok, err = pcall(loadQuestion)
	if not ok then
		warn("[BrainBlitz] Client: loadQuestion error: " .. tostring(err))
		questionLabel.Text = "Error loading question.\nCheck Output for details."
		questionLabel.TextColor3 = Config.Colors.Error
	end
end

function QuestionUI.getScreenGui()
	return screenGui
end

return QuestionUI
