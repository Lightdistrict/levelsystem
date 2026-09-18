local Config = LevelSystem.Config

--[[
- Grants XP to a player, applying their XP-skill bonus, and processes any
- resulting level-ups (a single big grant can cross multiple levels).
-
- @param player ply
- @param number amount -- base amount, before the XP skill bonus
- @param string reason -- shown in the level-up notification, optional
]]
function LevelSystem.GrantXP(ply, amount, reason)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local data = LevelSystem.GetData(ply)
	if data.level >= Config.maxLevel then return end

	local skillDef = Config.skills.xp
	local bonus = 1 + ((data.skills.xp or 0) * skillDef.perPoint)
	amount = math.floor(amount * bonus)

	data.xp = data.xp + amount

	local leveledUp = false
	while data.level < Config.maxLevel and data.xp >= Config.xpForLevel(data.level) do
		data.xp = data.xp - Config.xpForLevel(data.level)
		data.level = data.level + 1
		data.points = data.points + Config.skillPointsPerLevel
		leveledUp = true
	end

	if data.level >= Config.maxLevel then
		data.xp = 0
	end

	if leveledUp then
		LevelSystem.Notify(ply, LevelSystem.NOTIFY_GENERIC, "You reached level " .. data.level .. "! (+" .. Config.skillPointsPerLevel .. " skill point" .. (Config.skillPointsPerLevel == 1 and "" or "s") .. ")")
		LevelSystem.ApplySkillEffects(ply)
	end

	LevelSystem.SyncToClient(ply)
end

--[[
- Attempts to prestige a player. Requires being at max level.
-
- @param player ply
- @return bool success
]]
function LevelSystem.TryPrestige(ply)
	local data = LevelSystem.GetData(ply)

	if data.level < Config.maxLevel then
		return false, "You must reach level " .. Config.maxLevel .. " to prestige."
	end

	if data.prestige >= Config.maxPrestige then
		return false, "You're already at max prestige (" .. Config.maxPrestige .. ")."
	end

	data.prestige = data.prestige + 1
	data.level = 1
	data.xp = 0

	if Config.resetSkillsOnPrestige then
		data.points = 0
		for key in pairs(Config.skills) do
			data.skills[key] = 0
		end
		LevelSystem.ApplySkillEffects(ply)
	end

	LevelSystem.Notify(ply, LevelSystem.NOTIFY_GENERIC, "You prestiged! You are now Prestige " .. data.prestige .. ".")
	LevelSystem.SyncToClient(ply)
	LevelSystem.SaveData(ply)

	return true
end

net.Receive("levelsystem_prestige", function(len, ply)
	-- Was silently swallowing failures -- a click that didn't meet the
	-- requirements looked exactly like a click that did nothing at all.
	local success, reason = LevelSystem.TryPrestige(ply)
	if not success and reason then
		LevelSystem.Notify(ply, LevelSystem.NOTIFY_ERROR, reason)
	end
end)

--------------------------------------------------------------------------------
-- Admin setters -- used by sv_admin.lua's commands. Unlike GrantXP, these
-- don't apply the XP skill bonus (an admin grant should be the exact amount
-- given) and TakeXP doesn't trigger a delevel, it just floors at 0 XP.
--------------------------------------------------------------------------------

--[[
- @param player ply
- @param number level -- clamped to [1, Config.maxLevel]
]]
function LevelSystem.AdminSetLevel(ply, level)
	local data = LevelSystem.GetData(ply)
	data.level = math.Clamp(math.floor(level), 1, Config.maxLevel)
	data.xp = 0

	LevelSystem.SyncToClient(ply)
	LevelSystem.SaveData(ply)
end

--[[
- @param player ply
- @param number amount -- raw XP, no XP-skill bonus applied
]]
function LevelSystem.AdminGiveXP(ply, amount)
	local data = LevelSystem.GetData(ply)
	if data.level >= Config.maxLevel then return end

	amount = math.floor(amount)
	if amount <= 0 then return end

	data.xp = data.xp + amount

	local leveledUp = false
	while data.level < Config.maxLevel and data.xp >= Config.xpForLevel(data.level) do
		data.xp = data.xp - Config.xpForLevel(data.level)
		data.level = data.level + 1
		data.points = data.points + Config.skillPointsPerLevel
		leveledUp = true
	end

	if data.level >= Config.maxLevel then
		data.xp = 0
	end

	if leveledUp then
		LevelSystem.Notify(ply, LevelSystem.NOTIFY_GENERIC, "You reached level " .. data.level .. "! (+" .. Config.skillPointsPerLevel .. " skill point" .. (Config.skillPointsPerLevel == 1 and "" or "s") .. ")")
		LevelSystem.ApplySkillEffects(ply)
	end

	LevelSystem.SyncToClient(ply)
	LevelSystem.SaveData(ply)
end

--[[
- @param player ply
- @param number amount -- floors at 0 XP, doesn't delevel
]]
function LevelSystem.AdminTakeXP(ply, amount)
	local data = LevelSystem.GetData(ply)

	amount = math.floor(amount)
	if amount <= 0 then return end

	data.xp = math.max(0, data.xp - amount)

	LevelSystem.SyncToClient(ply)
	LevelSystem.SaveData(ply)
end

--[[
- @param player ply
- @param number prestige -- clamped to [0, Config.maxPrestige]
]]
function LevelSystem.AdminSetPrestige(ply, prestige)
	local data = LevelSystem.GetData(ply)
	data.prestige = math.Clamp(math.floor(prestige), 0, Config.maxPrestige)

	LevelSystem.SyncToClient(ply)
	LevelSystem.SaveData(ply)
end

--------------------------------------------------------------------------------
-- XP sources
--------------------------------------------------------------------------------

hook.Add("PlayerDeath", "levelsystem_pvp_xp", function(victim, inflictor, attacker)
	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	if attacker == victim then return end

	LevelSystem.GrantXP(attacker, Config.xpRewards.killPlayer, "Killed " .. victim:Nick())
end)

hook.Add("OnNPCKilled", "levelsystem_npc_xp", function(npc, attacker, inflictor)
	if not IsValid(attacker) or not attacker:IsPlayer() then return end

	LevelSystem.GrantXP(attacker, Config.xpRewards.killNPC, "Killed an NPC")
end)

timer.Create("levelsystem_passive_xp", Config.xpRewards.passiveInterval, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		LevelSystem.GrantXP(ply, Config.xpRewards.passiveTick, "Playtime bonus")
	end
end)
