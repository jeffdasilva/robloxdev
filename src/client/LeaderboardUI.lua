-- LeaderboardUI.lua
-- Builds and manages the leaderboard panel

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainBlitz = ReplicatedStorage:WaitForChild("BrainBlitz")
local Config = require(BrainBlitz:WaitForChild("Config"))
local Remotes = require(BrainBlitz:WaitForChild("Remotes"))
local UIComponents = require(script.Parent:WaitForChild("UIComponents"))

local LeaderboardUI = {}

local player = Players.LocalPlayer
local screenGui
local leaderboardFrame
local listFrame
local isVisible = false

------------------------------------------------------------------------
-- Build UI
------------------------------------------------------------------------

local function buildToggleButton(parent)
	local btn = UIComponents.makeButton(parent, {
		Name = "LeaderboardToggle",
		Size = UDim2.new(0, 160, 0, 44),
		Position = UDim2.new(0, 20, 0, 20),
		Color = Config.Colors.Accent,
		Text = "🏆 Leaderboard",
		TextSize = 15,
		CornerRadius = 22,
	})
	return btn
end

local function buildLeaderboard(parent)
	leaderboardFrame = UIComponents.makePanel(parent, {
		Name = "LeaderboardPanel",
		Size = UDim2.new(0, 300, 0, 460),
		Position = UDim2.new(0, 20, 0, 80),
		Color = Config.Colors.Panel,
		Stroke = true,
		StrokeColor = Config.Colors.Gold,
		StrokeThickness = 2,
	})
	leaderboardFrame.Visible = false
	UIComponents.makeShadow(leaderboardFrame)

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "LBTitle"
	title.Size = UDim2.new(1, 0, 0, 45)
	title.BackgroundTransparency = 1
	title.Text = "🏆 TOP STREAKS"
	title.TextColor3 = Config.Colors.Gold
	title.Font = Config.Fonts.Title
	title.TextSize = 24
	title.Parent = leaderboardFrame

	-- Scrolling list
	listFrame = Instance.new("ScrollingFrame")
	listFrame.Name = "List"
	listFrame.Size = UDim2.new(1, -20, 1, -55)
	listFrame.Position = UDim2.new(0, 10, 0, 50)
	listFrame.BackgroundTransparency = 1
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 4
	listFrame.ScrollBarImageColor3 = Config.Colors.Accent
	listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	listFrame.Parent = leaderboardFrame

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = listFrame

	return leaderboardFrame
end

local function makeEntry(rank, name, streak, isLocal)
	local entry = Instance.new("Frame")
	entry.Name = "Entry_" .. rank
	entry.Size = UDim2.new(1, 0, 0, 38)
	entry.BackgroundColor3 = isLocal and Config.Colors.Accent or Config.Colors.PanelLight
	entry.BackgroundTransparency = isLocal and 0.3 or 0
	entry.BorderSizePixel = 0
	entry.LayoutOrder = rank
	UIComponents.makeCorner(entry, 8)

	-- Rank medal
	local rankLabel = Instance.new("TextLabel")
	rankLabel.Size = UDim2.new(0, 36, 1, 0)
	rankLabel.Position = UDim2.new(0, 6, 0, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Font = Config.Fonts.Body
	rankLabel.TextSize = 16
	if rank == 1 then
		rankLabel.Text = "🥇"
		rankLabel.TextSize = 20
	elseif rank == 2 then
		rankLabel.Text = "🥈"
		rankLabel.TextSize = 20
	elseif rank == 3 then
		rankLabel.Text = "🥉"
		rankLabel.TextSize = 20
	else
		rankLabel.Text = "#" .. rank
		rankLabel.TextColor3 = Config.Colors.TextSecondary
	end
	rankLabel.Parent = entry

	-- Player name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -110, 1, 0)
	nameLabel.Position = UDim2.new(0, 44, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = Config.Colors.TextPrimary
	nameLabel.Font = Config.Fonts.Body
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = entry

	-- Streak count
	local streakLabel = Instance.new("TextLabel")
	streakLabel.Size = UDim2.new(0, 60, 1, 0)
	streakLabel.Position = UDim2.new(1, -66, 0, 0)
	streakLabel.BackgroundTransparency = 1
	streakLabel.Text = "🔥" .. streak
	streakLabel.TextColor3 = Config.Colors.Streak
	streakLabel.Font = Config.Fonts.Body
	streakLabel.TextSize = 15
	streakLabel.TextXAlignment = Enum.TextXAlignment.Right
	streakLabel.Parent = entry

	return entry
end

------------------------------------------------------------------------
-- Logic
------------------------------------------------------------------------

local function refreshLeaderboard()
	-- Clear existing entries
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local getLeaderboard = Remotes.get("GetLeaderboard")
	local entries = getLeaderboard:InvokeServer()

	if entries and #entries > 0 then
		for _, entry in ipairs(entries) do
			local isLocal = (entry.userId == player.UserId)
			local e = makeEntry(entry.rank, entry.name, entry.streak, isLocal)
			e.Parent = listFrame
		end
		listFrame.CanvasSize = UDim2.new(0, 0, 0, #entries * 42)
	else
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 60)
		empty.BackgroundTransparency = 1
		empty.Text = "No entries yet!\nBe the first to start a streak!"
		empty.TextColor3 = Config.Colors.TextSecondary
		empty.Font = Config.Fonts.BodyLight
		empty.TextSize = 14
		empty.TextWrapped = true
		empty.Parent = listFrame
	end
end

local function toggleLeaderboard()
	isVisible = not isVisible
	leaderboardFrame.Visible = isVisible
	if isVisible then
		refreshLeaderboard()
	end
end

------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------

function LeaderboardUI.init(parentGui)
	screenGui = parentGui

	local bg = screenGui:FindFirstChild("Background")
	if not bg then
		bg = screenGui
	end

	local toggleBtn = buildToggleButton(bg)
	buildLeaderboard(bg)

	toggleBtn.MouseButton1Click:Connect(toggleLeaderboard)
end

return LeaderboardUI
