-- PlayerDataStore.lua
-- Wraps Roblox DataStore to persist player progress
-- Each player stores: currentStreak, bestStreak, lastCompletedDate, attemptsToday, todayQuestionId

local DataStoreService = game:GetService("DataStoreService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("BrainBlitz"):WaitForChild("Config"))

local PlayerDataStore = {}
PlayerDataStore.__index = PlayerDataStore

-- Lazy-initialized DataStore handles (avoid crashing at module load)
local dataStore = nil
local orderedStore = nil

local function getDataStore()
	if not dataStore then
		local ok, store = pcall(function()
			return DataStoreService:GetDataStore(Config.DATA_STORE_NAME)
		end)
		if ok then
			dataStore = store
		else
			warn("[BrainBlitz] Could not access DataStore: " .. tostring(store))
		end
	end
	return dataStore
end

local function getOrderedStore()
	if not orderedStore then
		local ok, store = pcall(function()
			return DataStoreService:GetOrderedDataStore(Config.ORDERED_STORE_NAME)
		end)
		if ok then
			orderedStore = store
		else
			warn("[BrainBlitz] Could not access OrderedDataStore: " .. tostring(store))
		end
	end
	return orderedStore
end

local DEFAULT_DATA = {
	currentStreak = 0,
	bestStreak = 0,
	lastCompletedDate = "",
	attemptsUsed = 0,
	todayQuestionId = "",
	todaySolved = false,
}

function PlayerDataStore.load(player)
	local store = getDataStore()
	if not store then
		warn("[BrainBlitz] DataStore unavailable, returning defaults for " .. player.Name)
		return {
			currentStreak = 0,
			bestStreak = 0,
			lastCompletedDate = "",
			attemptsUsed = 0,
			todayQuestionId = "",
			todaySolved = false,
		}
	end
	local key = "player_" .. player.UserId
	local success, data = pcall(function()
		return store:GetAsync(key)
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
	local store = getDataStore()
	if not store then
		warn("[BrainBlitz] DataStore unavailable, cannot save for " .. player.Name)
		return false
	end
	local key = "player_" .. player.UserId
	local success, err = pcall(function()
		store:SetAsync(key, data)
	end)
	if not success then
		warn("[BrainBlitz] Failed to save data for " .. player.Name .. ": " .. tostring(err))
	end
	return success
end

function PlayerDataStore.updateLeaderboard(player, streak)
	local store = getOrderedStore()
	if not store then
		warn("[BrainBlitz] OrderedDataStore unavailable, cannot update leaderboard")
		return
	end
	local success, err = pcall(function()
		store:SetAsync("player_" .. player.UserId, streak)
	end)
	if not success then
		warn("[BrainBlitz] Failed to update leaderboard: " .. tostring(err))
	end
end

function PlayerDataStore.getLeaderboard(count)
	count = count or Config.LEADERBOARD_SIZE
	local store = getOrderedStore()
	if not store then
		warn("[BrainBlitz] OrderedDataStore unavailable, returning empty leaderboard")
		return {}
	end
	local success, pages = pcall(function()
		return store:GetSortedAsync(false, count)
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
