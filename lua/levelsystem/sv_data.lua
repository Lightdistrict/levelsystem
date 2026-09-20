-- Self-contained JSON-file persistence, one file per player -- no external
-- database dependency required.

local Config = LevelSystem.Config
local DATA_DIR = "levelsystem/players"

file.CreateDir("levelsystem")
file.CreateDir(DATA_DIR)

LevelSystem.PlayerData = LevelSystem.PlayerData or {} -- [steamid64] = data table

util.AddNetworkString("levelsystem_data")
util.AddNetworkString("levelsystem_requestdata")
util.AddNetworkString("levelsystem_spend")
util.AddNetworkString("levelsystem_resetall")
util.AddNetworkString("levelsystem_prestige")
util.AddNetworkString("levelsystem_notify")
util.AddNetworkString("levelsystem_public_data")

local function emptySkills()
	local skills = {}
	for key in pairs(Config.skills) do
		skills[key] = 0
	end
	return skills
end

local function defaultData()
	return {
		level = 1,
		xp = 0,
		prestige = 0,
		points = 0,
		skills = emptySkills(),
	}
end

--[[
- Loads (or creates) a player's data into the in-memory cache.
- @param player ply
]]
function LevelSystem.LoadData(ply)
	local sid = ply:SteamID64()
	local path = DATA_DIR .. "/" .. sid .. ".txt"

	if file.Exists(path, "DATA") then
		local ok, decoded = pcall(util.JSONToTable, file.Read(path, "DATA") or "")
		if ok and decoded and decoded.level then
			-- Backfill any skill keys added to the config since this file was last saved
			decoded.skills = decoded.skills or {}
			for key in pairs(Config.skills) do
				decoded.skills[key] = decoded.skills[key] or 0
			end
			LevelSystem.PlayerData[sid] = decoded
			return
		end
	end

	LevelSystem.PlayerData[sid] = defaultData()
end

--[[
- Saves a player's current data to disk.
- @param player ply
]]
function LevelSystem.SaveData(ply)
	local sid = ply:SteamID64()
	local data = LevelSystem.PlayerData[sid]
	if not data then return end

	file.Write(DATA_DIR .. "/" .. sid .. ".txt", util.TableToJSON(data))
end

--[[
- @param player ply
- @return table -- the player's data (creates a default entry if missing)
]]
function LevelSystem.GetData(ply)
	local sid = ply:SteamID64()
	if not LevelSystem.PlayerData[sid] then
		LevelSystem.LoadData(ply)
	end
	return LevelSystem.PlayerData[sid]
end

--[[
- Broadcasts a player's level/prestige to clients -- to everyone by
- default, or just `target` when catching one client up on someone
- they've already missed broadcasts for (see PlayerInitialSpawn below).
-
- Deliberately a real net broadcast rather than SetNWInt: NWVars are only
- guaranteed to reach clients for whom the entity is currently PVS-
- relevant (roughly: visible/nearby), which silently breaks exactly this
- use case -- a scoreboard needs to show every player's level regardless
- of whether you can currently see them in the world.
-
- @param player ply
- @param player|nil target
]]
local function broadcastPublicData(ply, target)
	local data = LevelSystem.GetData(ply)

	net.Start("levelsystem_public_data")
		net.WriteEntity(ply)
		net.WriteUInt(data.level, 8)
		net.WriteUInt(data.prestige, 8)
	if target then
		net.Send(target)
	else
		net.Broadcast()
	end
end

--[[
- Sends a player's current full data (level, xp, skills, etc) to their
- own client, and their level/prestige to everyone (see
- broadcastPublicData above).
-
- @param player ply
]]
function LevelSystem.SyncToClient(ply)
	local data = LevelSystem.GetData(ply)

	broadcastPublicData(ply)

	net.Start("levelsystem_data")
		net.WriteUInt(data.level, 8)
		net.WriteUInt(data.prestige, 8)
		net.WriteUInt(math.min(data.points, 255), 8)
		net.WriteUInt(math.min(data.xp, 4294967295), 32)
		net.WriteUInt(math.min(Config.xpForLevel(data.level), 4294967295), 32)

		for key in pairs(Config.skills) do
			net.WriteUInt(data.skills[key] or 0, 8)
		end
	net.Send(ply)
end

hook.Add("PlayerInitialSpawn", "levelsystem_load", function(ply)
	LevelSystem.LoadData(ply)
	timer.Simple(1, function()
		if not IsValid(ply) then return end

		LevelSystem.SyncToClient(ply)

		-- Catches the new player up on everyone else's level/prestige --
		-- they've missed every broadcastPublicData call that happened
		-- before they connected.
		for _, other in ipairs(player.GetAll()) do
			if other ~= ply and LevelSystem.PlayerData[other:SteamID64()] then
				broadcastPublicData(other, ply)
			end
		end
	end)
end)

hook.Add("PlayerDisconnected", "levelsystem_save", function(ply)
	LevelSystem.SaveData(ply)
	LevelSystem.PlayerData[ply:SteamID64()] = nil
end)

-- Periodic autosave so a crash doesn't lose progress
timer.Create("levelsystem_autosave", 300, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		LevelSystem.SaveData(ply)
	end
end)

net.Receive("levelsystem_requestdata", function(len, ply)
	LevelSystem.SyncToClient(ply)
end)

--[[
- @param player ply
- @param number level
- @param number type -- NOTIFY_ constant
- @param string message
]]
function LevelSystem.Notify(ply, ntype, message)
	net.Start("levelsystem_notify")
		net.WriteUInt(ntype, 8)
		net.WriteString(message)
	net.Send(ply)
end
