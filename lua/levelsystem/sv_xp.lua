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
		LevelSystem.Notify(ply, NOTIFY_GENERIC, "You reached level " .. data.level .. "! (+" .. Config.skillPointsPerLevel .. " skill point" .. (Config.skillPointsPerLevel == 1 and "" or "s") .. ")")
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

	LevelSystem.Notify(ply, NOTIFY_GENERIC, "You prestiged! You are now Prestige " .. data.prestige .. ".")
	LevelSystem.SyncToClient(ply)
	LevelSystem.SaveData(ply)

	return true
end

net.Receive("levelsystem_prestige", function(len, ply)
	LevelSystem.TryPrestige(ply)
end)

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
