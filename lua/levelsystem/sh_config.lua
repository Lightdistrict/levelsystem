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

Config.skills = {
	jumpheight = { name = "Jump Height", icon = "icon16/arrow_up.png",      max = 20, perPoint = 0.02 }, -- +2% jump power per point
	health     = { name = "Health",      icon = "icon16/heart.png",        max = 20, perPoint = 5 },    -- +5 max health per point
	armor      = { name = "Armor",       icon = "icon16/shield.png",       max = 20, perPoint = 5 },    -- +5 starting armor per point
	salary     = { name = "Salary",      icon = "icon16/money.png",        max = 20, perPoint = 3 },    -- +$3 per paycheck per point
	runspeed   = { name = "Run Speed",   icon = "icon16/lightning.png",    max = 20, perPoint = 5 },    -- +5 units/sec per point
	falldamage = { name = "Fall Damage", icon = "icon16/arrow_down.png",   max = 20, perPoint = 0.03 }, -- -3% fall damage taken per point
	xp         = { name = "XP",          icon = "icon16/star.png",         max = 20, perPoint = 0.02 }, -- +2% XP gained per point
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
