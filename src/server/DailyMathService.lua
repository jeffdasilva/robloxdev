-- DailyMathService.lua
-- Server-side service that manages the daily math question, attempts, and streaks

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MathStreak = ReplicatedStorage:WaitForChild("MathStreak")
local MathGenerator = require(MathStreak:WaitForChild("MathGenerator"))
local Config = require(MathStreak:WaitForChild("Config"))
local Remotes = require(MathStreak:WaitForChild("Remotes"))
local PlayerDataStore = require(script.Parent:WaitForChild("PlayerDataStore"))

local DailyMathService = {}

-- In-memory cache of player data (loaded on join, saved on leave and periodically)
local playerCache = {}

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------

local function getTodayDate()
	local now = os.date("!*t") -- UTC
	return now.year, now.month, now.day
end

local function getTodayId()
	local y, m, d = getTodayDate()
	return string.format("%04d-%02d-%02d", y, m, d)
end

local function getYesterdayId()
	local now = os.time()
	local yesterday = os.date("!*t", now - 86400)
	return string.format("%04d-%02d-%02d", yesterday.year, yesterday.month, yesterday.day)
end

--- Reset daily fields if the player hasn't played today yet
local function ensureTodayReset(data)
	local todayId = getTodayId()
	if data.todayQuestionId ~= todayId then
		data.attemptsUsed = 0
		data.todaySolved = false
		data.todayQuestionId = todayId

		-- Check streak continuity
		local yesterdayId = getYesterdayId()
		if data.lastCompletedDate ~= yesterdayId and data.lastCompletedDate ~= todayId then
			-- Streak broken
			data.currentStreak = 0
		end
	end
	return data
end

local function getClientData(data)
	return {
		currentStreak = data.currentStreak,
		bestStreak = data.bestStreak,
		attemptsUsed = data.attemptsUsed,
		todaySolved = data.todaySolved,
		maxAttempts = Config.MAX_ATTEMPTS,
	}
end

------------------------------------------------------------------------
-- Player lifecycle
------------------------------------------------------------------------

local function onPlayerAdded(player)
	print("[MathStreak] Loading data for " .. player.Name .. " (" .. player.UserId .. ")")

	-- Set default data immediately so remotes can respond while DataStore loads
	playerCache[player.UserId] = {
		currentStreak = 0,
		bestStreak = 0,
		lastCompletedDate = "",
		attemptsUsed = 0,
		todayQuestionId = "",
		todaySolved = false,
	}

	-- Attempt to load saved data from DataStore (may fail in Studio)
	local data = PlayerDataStore.load(player)
	data = ensureTodayReset(data)
	playerCache[player.UserId] = data

	print("[MathStreak] Data ready for " .. player.Name)

	PlayerDataStore.save(player, data)
end

local function onPlayerRemoving(player)
	local data = playerCache[player.UserId]
	if data then
		PlayerDataStore.save(player, data)
		playerCache[player.UserId] = nil
	end
end

------------------------------------------------------------------------
-- Remote handlers
------------------------------------------------------------------------

local function onGetDailyQuestion(player)
	-- Wait for player data to load (handles race with PlayerAdded)
	local data = playerCache[player.UserId]
	if not data then
		for _ = 1, 50 do -- wait up to 5 seconds
			task.wait(0.1)
			data = playerCache[player.UserId]
			if data then
				break
			end
		end
		if not data then
			return nil
		end
	end
	data = ensureTodayReset(data)

	local y, m, d = getTodayDate()
	local q = MathGenerator.getQuestion(y, m, d)

	return {
		question = q.question,
		category = q.category,
		hint = q.hint,
		questionId = q.questionId,
		playerData = getClientData(data),
	}
end

local function onSubmitAnswer(player, playerAnswer)
	local data = playerCache[player.UserId]
	if not data then
		return { success = false, message = "Data not loaded yet." }
	end

	data = ensureTodayReset(data)

	-- Validate
	if data.todaySolved then
		return {
			success = false,
			message = "You already solved today's question!",
			alreadySolved = true,
			playerData = getClientData(data),
		}
	end

	if data.attemptsUsed >= Config.MAX_ATTEMPTS then
		return {
			success = false,
			message = "No attempts remaining today.",
			noAttempts = true,
			playerData = getClientData(data),
		}
	end

	-- Validate input
	if type(playerAnswer) ~= "number" then
		playerAnswer = tonumber(playerAnswer)
		if not playerAnswer then
			return { success = false, message = "Please enter a valid number.", playerData = getClientData(data) }
		end
	end

	data.attemptsUsed = data.attemptsUsed + 1

	local y, m, d = getTodayDate()
	local correct = MathGenerator.checkAnswer(y, m, d, playerAnswer)

	if correct then
		data.todaySolved = true
		data.currentStreak = data.currentStreak + 1
		data.lastCompletedDate = getTodayId()
		if data.currentStreak > data.bestStreak then
			data.bestStreak = data.currentStreak
		end
		PlayerDataStore.save(player, data)
		PlayerDataStore.updateLeaderboard(player, data.bestStreak)

		-- Notify client of data update
		local updateRemote = Remotes.get("PlayerDataUpdated")
		if updateRemote then
			updateRemote:FireClient(player, getClientData(data))
		end

		return {
			success = true,
			correct = true,
			message = "🎉 Correct! Amazing job!",
			playerData = getClientData(data),
		}
	else
		local attemptsLeft = Config.MAX_ATTEMPTS - data.attemptsUsed
		PlayerDataStore.save(player, data)

		local msg
		if attemptsLeft > 0 then
			msg = string.format("Not quite! You have %d attempt%s left.", attemptsLeft, attemptsLeft == 1 and "" or "s")
		else
			msg = "Out of attempts for today. Try again tomorrow!"
			-- Streak broken
			data.currentStreak = 0
			PlayerDataStore.save(player, data)
		end

		return {
			success = true,
			correct = false,
			message = msg,
			attemptsLeft = attemptsLeft,
			playerData = getClientData(data),
		}
	end
end

local function onGetPlayerData(player)
	local data = playerCache[player.UserId]
	if not data then
		return nil
	end
	data = ensureTodayReset(data)
	return getClientData(data)
end

local function onGetLeaderboard(_player)
	local entries = PlayerDataStore.getLeaderboard()

	-- Resolve display names
	local results = {}
	for _, entry in ipairs(entries) do
		local displayName = "Player"
		local success, name = pcall(function()
			return Players:GetNameFromUserIdAsync(entry.userId)
		end)
		if success and name then
			displayName = name
		end
		table.insert(results, {
			rank = entry.rank,
			name = displayName,
			streak = entry.streak,
			userId = entry.userId,
		})
	end

	return results
end

------------------------------------------------------------------------
-- Initialization
------------------------------------------------------------------------

function DailyMathService.init()
	print("[MathStreak] Server v" .. Config.VERSION .. " (" .. Config.BUILD_TIME .. ") initializing...")

	-- Set up remotes
	Remotes.setup()
	print("[MathStreak] Remotes created")

	-- Bind remote handlers
	local getDailyQuestion = Remotes.get("GetDailyQuestion")
	getDailyQuestion.OnServerInvoke = onGetDailyQuestion

	local submitAnswer = Remotes.get("SubmitAnswer")
	submitAnswer.OnServerInvoke = onSubmitAnswer

	local getPlayerData = Remotes.get("GetPlayerData")
	getPlayerData.OnServerInvoke = onGetPlayerData

	local getLeaderboard = Remotes.get("GetLeaderboard")
	getLeaderboard.OnServerInvoke = onGetLeaderboard

	-- Player lifecycle
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Handle players who joined before the script loaded
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	-- Auto-save every 2 minutes
	task.spawn(function()
		while true do
			task.wait(120)
			for userId, data in pairs(playerCache) do
				local player = Players:GetPlayerByUserId(userId)
				if player then
					PlayerDataStore.save(player, data)
				end
			end
		end
	end)

	print("[MathStreak] Server initialized successfully!")
end

return DailyMathService
