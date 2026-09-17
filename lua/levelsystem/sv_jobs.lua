local Config = LevelSystem.Config

hook.Add("playerCanChangeTeam", "levelsystem_job_gate", function(ply, targetTeam, force)
	if force then return end -- admin-forced team changes bypass the gate

	local jobName = team.GetName(targetTeam)
	local requirement = Config.jobRequirements[jobName]
	if not requirement then return end

	local data = LevelSystem.GetData(ply)

	if data.level < requirement.level then
		return false, "You need to be level " .. requirement.level .. " to become " .. jobName .. " (you are level " .. data.level .. ")."
	end

	if requirement.prestige and data.prestige < requirement.prestige then
		return false, "You need Prestige " .. requirement.prestige .. " to become " .. jobName .. "."
	end
end)
