local Config = LevelSystem.Config

--------------------------------------------------------------------------------
-- Notification types -- own copies of GMod's NOTIFY_ constants (0-4),
-- defined explicitly rather than relying on the globals NOTIFY_GENERIC/
-- NOTIFY_ERROR/etc existing server-side. They don't always (server-side
-- Lua doesn't guarantee every client-oriented enum is registered), which
-- is what was crashing LevelSystem.Notify with a nil passed to
-- net.WriteUInt. These values match DarkRP's own notify()/AddNotify
-- convention exactly, so the client-side display is unaffected.
--------------------------------------------------------------------------------

LevelSystem.NOTIFY_GENERIC = 0
LevelSystem.NOTIFY_ERROR = 1
LevelSystem.NOTIFY_UNDO = 2
LevelSystem.NOTIFY_HINT = 3
LevelSystem.NOTIFY_CLEANUP = 4

--------------------------------------------------------------------------------
-- Core progression
--------------------------------------------------------------------------------

Config.maxLevel = 100
Config.maxPrestige = 10

-- XP required to go from `level` to `level + 1`.
-- At these numbers: level 2 needs 283 xp, level 50 needs ~35,355 xp,
-- level 99 needs ~98,505 xp. Tune the multiplier/exponent to taste.
Config.xpForLevel = function(level)
	return math.floor(100 * level ^ 1.5)
end

Config.skillPointsPerLevel = 1

-- Whether prestiging wipes spent skill points back to 0 (a fresh respec)
-- or lets the player keep everything they've allocated so far.
Config.resetSkillsOnPrestige = true

--------------------------------------------------------------------------------
-- XP sources
--------------------------------------------------------------------------------

Config.xpRewards = {
	killPlayer = 25,      -- PvP kill (not suicide/world damage)
	killNPC = 15,         -- Any NPC kill credited to a player
	passiveTick = 5,      -- Granted to every connected player every passiveInterval seconds
	passiveInterval = 120,
}

--------------------------------------------------------------------------------
-- Skill point categories
--
-- `perPoint` is applied per point spent, up to `max` points in that category.
-- See sv_skills.lua for exactly how each one is used.
--------------------------------------------------------------------------------

-- `unit` controls how the per-point amount is formatted in `desc`:
-- "percent" shows e.g. "2%", "money" shows "$3", "flat" shows "5".
-- `desc` is a format string with one %s for that formatted amount --
-- shown in place of the card's normal text while it's hovered.
Config.skills = {
	jumpheight = { name = "Jump Height", unit = "percent", max = 20, perPoint = 0.02, desc = "Increases your jump height by %s per point" },
	health     = { name = "Health",      unit = "flat",    max = 20, perPoint = 5,    desc = "Increases your max health by %s per point" },
	armor      = { name = "Armor",       unit = "flat",    max = 20, perPoint = 5,    desc = "Increases your spawn armor by %s per point" },
	salary     = { name = "Salary",      unit = "money",   max = 20, perPoint = 3,    desc = "Increases your salary by %s per paycheck" },
	runspeed   = { name = "Run Speed",   unit = "flat",    max = 20, perPoint = 5,    desc = "Increases your run and walk speed by %s per point" },
	falldamage = { name = "Fall Damage", unit = "percent", max = 20, perPoint = 0.03, desc = "Reduces fall damage taken by %s per point" },
	xp         = { name = "XP",          unit = "percent", max = 20, perPoint = 0.02, desc = "Increases all XP gained by %s per point" },
}

-- Cost in DarkRP money to reset all spent skill points back to unspent
-- points. Set to 0 to make resets free.
Config.resetSkillsCost = 10000

--------------------------------------------------------------------------------
-- Job level requirements
--
-- Keyed by job NAME (exactly as it appears in your jobs.lua / DarkRP.createJob),
-- not by team index -- team indices can shift depending on load order.
-- `prestige` is optional; omit it to only require a level.
--------------------------------------------------------------------------------

Config.jobRequirements = {
	-- ["Police Officer"] = { level = 10 },
	-- ["SWAT"] = { level = 25, prestige = 1 },
}
