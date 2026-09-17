local Config = LevelSystem.Config

--------------------------------------------------------------------------------
-- Spending / resetting points
--------------------------------------------------------------------------------

net.Receive("levelsystem_spend", function(len, ply)
	local key = net.ReadString()
	local skillDef = Config.skills[key]
	if not skillDef then return end

	local data = LevelSystem.GetData(ply)
	if data.points <= 0 then return end
	if (data.skills[key] or 0) >= skillDef.max then return end

	data.points = data.points - 1
	data.skills[key] = (data.skills[key] or 0) + 1

	LevelSystem.ApplySkillEffects(ply)
	LevelSystem.SyncToClient(ply)
	LevelSystem.SaveData(ply)
end)

net.Receive("levelsystem_resetall", function(len, ply)
	local data = LevelSystem.GetData(ply)

	local spent = 0
	for key in pairs(Config.skills) do
		spent = spent + (data.skills[key] or 0)
	end
	if spent == 0 then return end

	if Config.resetSkillsCost > 0 then
		if not ply.getDarkRPVar or (ply:getDarkRPVar("money") or 0) < Config.resetSkillsCost then
			LevelSystem.Notify(ply, NOTIFY_ERROR, "You need $" .. Config.resetSkillsCost .. " to reset your skills.")
			return
		end
		ply:addMoney(-Config.resetSkillsCost)
	end

	data.points = data.points + spent
	for key in pairs(Config.skills) do
		data.skills[key] = 0
	end

	LevelSystem.ApplySkillEffects(ply)
	LevelSystem.SyncToClient(ply)
	LevelSystem.SaveData(ply)

	LevelSystem.Notify(ply, NOTIFY_GENERIC, "Skills reset -- you have " .. data.points .. " points to spend.")
end)

--------------------------------------------------------------------------------
-- Applying effects
--
-- These are re-applied on every spawn (and immediately after any point is
-- spent/reset) rather than tracked incrementally, so there's never a risk
-- of stacking bonuses across respawns.
--------------------------------------------------------------------------------

local BASE_JUMP_POWER = 200
local BASE_RUN_SPEED = 400
local BASE_WALK_SPEED = 200
local BASE_MAX_HEALTH = 100
local BASE_ARMOR = 0

--[[
- @param player ply
]]
function LevelSystem.ApplySkillEffects(ply)
	if not IsValid(ply) then return end

	local data = LevelSystem.GetData(ply)
	local skills = data.skills

	local jumpPoints = skills.jumpheight or 0
	ply:SetJumpPower(BASE_JUMP_POWER * (1 + jumpPoints * Config.skills.jumpheight.perPoint))

	local healthPoints = skills.health or 0
	local maxHealth = BASE_MAX_HEALTH + (healthPoints * Config.skills.health.perPoint)
	ply:SetMaxHealth(maxHealth)
	if ply:Health() > maxHealth then
		ply:SetHealth(maxHealth)
	end

	local armorPoints = skills.armor or 0
	local maxArmor = BASE_ARMOR + (armorPoints * Config.skills.armor.perPoint)
	if ply:Armor() < maxArmor then
		ply:SetArmor(maxArmor)
	end

	local speedPoints = skills.runspeed or 0
	local speedBonus = speedPoints * Config.skills.runspeed.perPoint
	ply:SetRunSpeed(BASE_RUN_SPEED + speedBonus)
	ply:SetWalkSpeed(BASE_WALK_SPEED + speedBonus / 2)
end

hook.Add("PlayerSpawn", "levelsystem_apply_effects", function(ply)
	timer.Simple(0, function()
		if IsValid(ply) then
			LevelSystem.ApplySkillEffects(ply)
		end
	end)
end)

--------------------------------------------------------------------------------
-- Salary bonus
--------------------------------------------------------------------------------

hook.Add("playerGetSalary", "levelsystem_salary_bonus", function(ply, amount)
	local data = LevelSystem.GetData(ply)
	local points = data.skills.salary or 0
	if points <= 0 then return end

	local bonus = points * Config.skills.salary.perPoint
	return nil, nil, amount + bonus
end)

--------------------------------------------------------------------------------
-- Fall damage reduction
--------------------------------------------------------------------------------

hook.Add("GetFallDamage", "levelsystem_falldamage_reduction", function(ply, speed)
	local data = LevelSystem.GetData(ply)
	local points = data.skills.falldamage or 0
	if points <= 0 then return end

	-- Returning a number from this hook fully replaces DarkRP's own
	-- GM:GetFallDamage, so mirror its actual calculation here first
	-- (mp_falldamage/realisticfalldamage flips between a speed-based
	-- formula and a flat amount) rather than inventing a different curve.
	local baseDamage
	if GetConVar("mp_falldamage"):GetBool() or GAMEMODE.Config.realisticfalldamage then
		baseDamage = speed / (GAMEMODE.Config.falldamagedamper or 15)
	else
		baseDamage = GAMEMODE.Config.falldamageamount or 10
	end

	local reduction = 1 - math.min(points * Config.skills.falldamage.perPoint, 0.9)

	return baseDamage * reduction
end)
