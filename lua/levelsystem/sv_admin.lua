-- Admin commands for adjusting a player's level/xp/prestige. Registered
-- through SAM (sam.command.new) when it's present so permissions/ACL and
-- the !command UI all work normally; concommands are always registered too
-- as a console/RCON fallback that doesn't depend on SAM being installed.

local Config = LevelSystem.Config

--[[
- Finds a player by (in order) exact SteamID64, SteamID ("STEAM_0:..."),
- userid, or a case-insensitive partial nick match.
-
- @param string str
- @return player|nil
]]
local function resolveTarget(str)
	if not str or str == "" then return nil end

	if string.match(str, "^%d+$") and #str >= 15 then
		local bySid64 = player.GetBySteamID64(str)
		if IsValid(bySid64) then return bySid64 end
	end

	local bySteamId = player.GetBySteamID(str)
	if IsValid(bySteamId) then return bySteamId end

	local userid = tonumber(str)
	if userid then
		local byId = player.GetByID(userid)
		if IsValid(byId) then return byId end
	end

	local needle = string.lower(str)
	for _, candidate in ipairs(player.GetAll()) do
		if string.find(string.lower(candidate:Nick()), needle, 1, true) then
			return candidate
		end
	end

	return nil
end

--[[
- Replies to whoever ran the console command -- the dedicated server
- console (ply invalid) via print(), or the calling client via their own
- console/chat, since print() from a server-side concommand never reaches
- a client's console.
-
- @param player|nil ply
- @param string message
]]
local function reply(ply, message)
	if IsValid(ply) then
		ply:PrintMessage(HUD_PRINTCONSOLE, message)
		ply:ChatPrint(message)
	else
		print(message)
	end
end

-- Deferred to the next tick, not run inline at file-load time: addon load
-- order between "levelsystem" and "sam" isn't guaranteed, so `sam` may not
-- exist yet while this file is being included. By the start of the next
-- tick every addon's initial files have finished loading either way.
--
-- Real SAM command-builder API (verified against actual published SAM
-- modules, not guessed): the "player" arg type resolves to a `targets`
-- TABLE (even with single_target = true, it's a 1-length table), the
-- execute callback is :OnExecute(function(ply, targets, ...)), the chain
-- ends with :End() (not :Register()), and player feedback goes through
-- ply:sam_send_message("{A} did X to {T}", {A = ply, T = targets, ...})
-- rather than a return value.
timer.Simple(0, function()
	if not sam then
		print("[LevelSystem] SAM not detected -- skipping SAM chat commands (console fallback commands still work).")
		return
	end

	sam.command.new("setlevel")
		:SetPermission("levelsystem_setlevel", "moderator")
		:AddArg("player", { single_target = true })
		:AddArg("number", { hint = "level", min = 1, max = Config.maxLevel, default = 1 })
		:Help("Sets a player's level.")
		:OnExecute(function(ply, targets, level)
			local target = targets[1]
			if not IsValid(target) then return end

			LevelSystem.AdminSetLevel(target, level)
			ply:sam_send_message("{A} set {T}'s level to " .. math.Clamp(math.floor(level), 1, Config.maxLevel) .. ".", { A = ply, T = targets })
		end)
		:End()

	sam.command.new("givexp")
		:SetPermission("levelsystem_givexp", "moderator")
		:AddArg("player", { single_target = true })
		:AddArg("number", { hint = "amount", min = 1, default = 100 })
		:Help("Gives a player XP.")
		:OnExecute(function(ply, targets, amount)
			local target = targets[1]
			if not IsValid(target) then return end

			LevelSystem.AdminGiveXP(target, amount)
			ply:sam_send_message("{A} gave {T} " .. math.floor(amount) .. " XP.", { A = ply, T = targets })
		end)
		:End()

	sam.command.new("takexp")
		:SetPermission("levelsystem_takexp", "moderator")
		:AddArg("player", { single_target = true })
		:AddArg("number", { hint = "amount", min = 1, default = 100 })
		:Help("Takes XP away from a player.")
		:OnExecute(function(ply, targets, amount)
			local target = targets[1]
			if not IsValid(target) then return end

			LevelSystem.AdminTakeXP(target, amount)
			ply:sam_send_message("{A} took " .. math.floor(amount) .. " XP from {T}.", { A = ply, T = targets })
		end)
		:End()

	sam.command.new("setprestige")
		:SetPermission("levelsystem_setprestige", "moderator")
		:AddArg("player", { single_target = true })
		:AddArg("number", { hint = "prestige", min = 0, max = Config.maxPrestige, default = 0 })
		:Help("Sets a player's prestige rank.")
		:OnExecute(function(ply, targets, prestige)
			local target = targets[1]
			if not IsValid(target) then return end

			LevelSystem.AdminSetPrestige(target, prestige)
			ply:sam_send_message("{A} set {T}'s prestige to " .. math.Clamp(math.floor(prestige), 0, Config.maxPrestige) .. ".", { A = ply, T = targets })
		end)
		:End()

	print("[LevelSystem] Registered SAM commands: setlevel, givexp, takexp, setprestige.")
end)

--------------------------------------------------------------------------------
-- Console/chat-console fallback -- works even without SAM installed. Only
-- the dedicated server console (ply == NULL) or a superadmin may run these.
-- Target can be a SteamID64, SteamID, userid, or a partial player name.
--------------------------------------------------------------------------------

local function canUseConsoleCommand(ply)
	return not IsValid(ply) or ply:IsSuperAdmin()
end

concommand.Add("levelsystem_setlevel", function(ply, cmd, args)
	if not canUseConsoleCommand(ply) then return end

	local target = resolveTarget(args[1])
	local level = tonumber(args[2])
	if not IsValid(target) or not level then
		reply(ply, "Usage: levelsystem_setlevel <name|steamid|userid> <level>")
		return
	end

	LevelSystem.AdminSetLevel(target, level)
	reply(ply, "Set " .. target:Nick() .. "'s level to " .. math.Clamp(math.floor(level), 1, Config.maxLevel) .. ".")
end)

concommand.Add("levelsystem_givexp", function(ply, cmd, args)
	if not canUseConsoleCommand(ply) then return end

	local target = resolveTarget(args[1])
	local amount = tonumber(args[2])
	if not IsValid(target) or not amount then
		reply(ply, "Usage: levelsystem_givexp <name|steamid|userid> <amount>")
		return
	end

	LevelSystem.AdminGiveXP(target, amount)
	reply(ply, "Gave " .. target:Nick() .. " " .. math.floor(amount) .. " XP.")
end)

concommand.Add("levelsystem_takexp", function(ply, cmd, args)
	if not canUseConsoleCommand(ply) then return end

	local target = resolveTarget(args[1])
	local amount = tonumber(args[2])
	if not IsValid(target) or not amount then
		reply(ply, "Usage: levelsystem_takexp <name|steamid|userid> <amount>")
		return
	end

	LevelSystem.AdminTakeXP(target, amount)
	reply(ply, "Took " .. math.floor(amount) .. " XP from " .. target:Nick() .. ".")
end)

concommand.Add("levelsystem_setprestige", function(ply, cmd, args)
	if not canUseConsoleCommand(ply) then return end

	local target = resolveTarget(args[1])
	local prestige = tonumber(args[2])
	if not IsValid(target) or not prestige then
		reply(ply, "Usage: levelsystem_setprestige <name|steamid|userid> <prestige>")
		return
	end

	LevelSystem.AdminSetPrestige(target, prestige)
	reply(ply, "Set " .. target:Nick() .. "'s prestige to " .. math.Clamp(math.floor(prestige), 0, Config.maxPrestige) .. ".")
end)
