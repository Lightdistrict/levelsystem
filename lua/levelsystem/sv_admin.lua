-- Admin commands for adjusting a player's level/xp/prestige. Registered
-- through SAM (sam.command.new) when it's present so permissions/ACL and
-- the !command UI all work normally; concommands are always registered too
-- as a console/RCON fallback that doesn't depend on SAM being installed.

local Config = LevelSystem.Config

local function levelName(ply)
	return IsValid(ply) and ply:Nick() or "console"
end

if sam then
	sam.command.new("setlevel")
		:SetPermission("levelsystem_setlevel", "moderator")
		:AddArg("player")
		:AddArg("number", { hint = "level", min = 1, max = Config.maxLevel, default = 1 })
		:Help("Sets a player's level.")
		:OnRun(function(caller, cmdArg, target, level)
			LevelSystem.AdminSetLevel(target, level)
			return "Set " .. target:Nick() .. "'s level to " .. math.Clamp(math.floor(level), 1, Config.maxLevel) .. "."
		end)
		:Register()

	sam.command.new("givexp")
		:SetPermission("levelsystem_givexp", "moderator")
		:AddArg("player")
		:AddArg("number", { hint = "amount", min = 1, default = 100 })
		:Help("Gives a player XP.")
		:OnRun(function(caller, cmdArg, target, amount)
			LevelSystem.AdminGiveXP(target, amount)
			return "Gave " .. target:Nick() .. " " .. math.floor(amount) .. " XP."
		end)
		:Register()

	sam.command.new("takexp")
		:SetPermission("levelsystem_takexp", "moderator")
		:AddArg("player")
		:AddArg("number", { hint = "amount", min = 1, default = 100 })
		:Help("Takes XP away from a player.")
		:OnRun(function(caller, cmdArg, target, amount)
			LevelSystem.AdminTakeXP(target, amount)
			return "Took " .. math.floor(amount) .. " XP from " .. target:Nick() .. "."
		end)
		:Register()

	sam.command.new("setprestige")
		:SetPermission("levelsystem_setprestige", "moderator")
		:AddArg("player")
		:AddArg("number", { hint = "prestige", min = 0, max = Config.maxPrestige, default = 0 })
		:Help("Sets a player's prestige rank.")
		:OnRun(function(caller, cmdArg, target, prestige)
			LevelSystem.AdminSetPrestige(target, prestige)
			return "Set " .. target:Nick() .. "'s prestige to " .. math.Clamp(math.floor(prestige), 0, Config.maxPrestige) .. "."
		end)
		:Register()
end

--------------------------------------------------------------------------------
-- Console/RCON fallback -- works even without SAM installed. Only the
-- dedicated server console (ply == NULL) or a superadmin may run these.
--------------------------------------------------------------------------------

local function canUseConsoleCommand(ply)
	return not IsValid(ply) or ply:IsSuperAdmin()
end

concommand.Add("levelsystem_setlevel", function(ply, cmd, args)
	if not canUseConsoleCommand(ply) then return end

	local target = player.GetBySteamID(args[1]) or player.GetByID(tonumber(args[1]) or -1)
	local level = tonumber(args[2])
	if not IsValid(target) or not level then
		print("Usage: levelsystem_setlevel <steamid|userid> <level>")
		return
	end

	LevelSystem.AdminSetLevel(target, level)
	print("Set " .. levelName(target) .. "'s level to " .. math.Clamp(math.floor(level), 1, Config.maxLevel) .. ".")
end)

concommand.Add("levelsystem_givexp", function(ply, cmd, args)
	if not canUseConsoleCommand(ply) then return end

	local target = player.GetBySteamID(args[1]) or player.GetByID(tonumber(args[1]) or -1)
	local amount = tonumber(args[2])
	if not IsValid(target) or not amount then
		print("Usage: levelsystem_givexp <steamid|userid> <amount>")
		return
	end

	LevelSystem.AdminGiveXP(target, amount)
	print("Gave " .. levelName(target) .. " " .. math.floor(amount) .. " XP.")
end)

concommand.Add("levelsystem_takexp", function(ply, cmd, args)
	if not canUseConsoleCommand(ply) then return end

	local target = player.GetBySteamID(args[1]) or player.GetByID(tonumber(args[1]) or -1)
	local amount = tonumber(args[2])
	if not IsValid(target) or not amount then
		print("Usage: levelsystem_takexp <steamid|userid> <amount>")
		return
	end

	LevelSystem.AdminTakeXP(target, amount)
	print("Took " .. math.floor(amount) .. " XP from " .. levelName(target) .. ".")
end)

concommand.Add("levelsystem_setprestige", function(ply, cmd, args)
	if not canUseConsoleCommand(ply) then return end

	local target = player.GetBySteamID(args[1]) or player.GetByID(tonumber(args[1]) or -1)
	local prestige = tonumber(args[2])
	if not IsValid(target) or not prestige then
		print("Usage: levelsystem_setprestige <steamid|userid> <prestige>")
		return
	end

	LevelSystem.AdminSetPrestige(target, prestige)
	print("Set " .. levelName(target) .. "'s prestige to " .. math.Clamp(math.floor(prestige), 0, Config.maxPrestige) .. ".")
end)
