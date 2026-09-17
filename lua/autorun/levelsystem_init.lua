LevelSystem = LevelSystem or {}
LevelSystem.Config = LevelSystem.Config or {}

local function include_shared(file)
	if SERVER then
		AddCSLuaFile(file)
	end
	include(file)
end

local function include_server(file)
	if SERVER then
		include(file)
	end
end

local function include_client(file)
	if SERVER then
		AddCSLuaFile(file)
	elseif CLIENT then
		include(file)
	end
end

include_shared("levelsystem/sh_config.lua")

include_server("levelsystem/sv_data.lua")
include_server("levelsystem/sv_xp.lua")
include_server("levelsystem/sv_skills.lua")
include_server("levelsystem/sv_jobs.lua")
include_server("levelsystem/sv_admin.lua")

include_client("levelsystem/cl_data.lua")
include_client("levelsystem/cl_skills_tab.lua")
