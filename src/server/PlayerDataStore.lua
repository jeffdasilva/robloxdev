-- PlayerDataStore.lua
-- Wraps Roblox DataStore to persist player progress
-- Each player stores: currentStreak, bestStreak, lastCompletedDate, attemptsToday, todayQuestionId

local DataStoreService = game:GetService("DataStoreService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("MathStreak"):WaitForChild("Config"))

local PlayerDataStore = {}
PlayerDataStore.__index = PlayerDataStore

local dataStore = DataStoreService:GetDataStore(Config.DATA_STORE_NAME)
local orderedStore = DataStoreService:GetOrderedDataStore(Config.ORDERED_STORE_NAME)

local DEFAULT_DATA = {
	currentStreak = 0,
	bestStreak = 0,
	lastCompletedDate = "",
	attemptsUsed = 0,
	todayQuestionId = "",
	todaySolved = false,
}

function PlayerDataStore.load(player)
	local key = "player_" .. player.UserId
	local success, data = pcall(function()
		return dataStore:GetAsync(key)
	end)

	if success and data then
		-- merge with defaults in case of schema evolution
		for k, v in pairs(DEFAULT_DATA) do
			if data[k] == nil then
				data[k] = v
			end
		end
		return data
	end

	return {
		currentStreak = 0,
		bestStreak = 0,
		lastCompletedDate = "",
		attemptsUsed = 0,
		todayQuestionId = "",
		todaySolved = false,
	}
end

function PlayerDataStore.save(player, data)
	local key = "player_" .. player.UserId
	local success, err = pcall(function()
		dataStore:SetAsync(key, data)
	end)
	if not success then
		warn("[MathStreak] Failed to save data for " .. player.Name .. ": " .. tostring(err))
	end
	return success
end

function PlayerDataStore.updateLeaderboard(player, streak)
	local success, err = pcall(function()
		orderedStore:SetAsync("player_" .. player.UserId, streak)
	end)
	if not success then
		warn("[MathStreak] Failed to update leaderboard: " .. tostring(err))
	end
end

function PlayerDataStore.getLeaderboard(count)
	count = count or Config.LEADERBOARD_SIZE
	local success, pages = pcall(function()
		return orderedStore:GetSortedAsync(false, count)
	end)

	if not success or not pages then
		return {}
	end

	local entries = {}
	local page = pages:GetCurrentPage()
	for rank, entry in ipairs(page) do
		table.insert(entries, {
			rank = rank,
			userId = tonumber(string.gsub(entry.key, "player_", "")),
			streak = entry.value,
		})
	end

	return entries
end

return PlayerDataStore
