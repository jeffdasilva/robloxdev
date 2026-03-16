-- Remotes.lua
-- Creates and provides access to RemoteEvents and RemoteFunctions
-- Used by both server and client

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent.Config)

local Remotes = {}

function Remotes.setup()
	local folder = Instance.new("Folder")
	folder.Name = "MathStreakRemotes"
	folder.Parent = ReplicatedStorage

	for name, remoteName in pairs(Config.Remotes) do
		if name == "PlayerDataUpdated" then
			local event = Instance.new("RemoteEvent")
			event.Name = remoteName
			event.Parent = folder
		else
			local func = Instance.new("RemoteFunction")
			func.Name = remoteName
			func.Parent = folder
		end
	end
end

function Remotes.get(name)
	local remoteName = Config.Remotes[name]
	if not remoteName then
		warn("[MathStreak] Unknown remote: " .. tostring(name))
		return nil
	end
	local folder = ReplicatedStorage:WaitForChild("MathStreakRemotes", 30)
	if not folder then
		warn("[MathStreak] MathStreakRemotes folder not found — server may not have started yet")
		return nil
	end
	local remote = folder:WaitForChild(remoteName, 30)
	if not remote then
		warn("[MathStreak] Remote not found: " .. remoteName)
	end
	return remote
end

return Remotes
