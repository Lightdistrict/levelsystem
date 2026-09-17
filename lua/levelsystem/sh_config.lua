local Config = LevelSystem.Config

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

-- `shape` picks one of the hand-drawn vector icons in cl_skills_tab.lua
-- (crisp at any size, unlike the low-res stock icon16/*.png set).
-- `unit` controls how the per-point tooltip number is formatted:
-- "percent" shows e.g. "+2%", "money" shows "+$3", "flat" shows "+5".
Config.skills = {
	jumpheight = { name = "Jump Height", shape = "arrow_up",   unit = "percent", max = 20, perPoint = 0.02, desc = "increases your jump height" },
	health     = { name = "Health",      shape = "heart",      unit = "flat",    max = 20, perPoint = 5,    desc = "increases your max health" },
	armor      = { name = "Armor",       shape = "shield",     unit = "flat",    max = 20, perPoint = 5,    desc = "increases your starting armor" },
	salary     = { name = "Salary",      shape = "dollar",     unit = "money",   max = 20, perPoint = 3,    desc = "increases your salary per paycheck" },
	runspeed   = { name = "Run Speed",   shape = "chevrons",   unit = "flat",    max = 20, perPoint = 5,    desc = "increases your run and walk speed" },
	falldamage = { name = "Fall Damage", shape = "arrow_down", unit = "percent", max = 20, perPoint = 0.03, desc = "reduces fall damage taken" },
	xp         = { name = "XP",          shape = "star",       unit = "percent", max = 20, perPoint = 0.02, desc = "increases all XP gained" },
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
