-- Level/prestige for every player, not just yourself (LevelSystem.MyData
-- below is private, net.Send(ply)-only) -- for anything that needs to show
-- someone else's level, e.g. the scoreboard. Keyed by player entity.

LevelSystem.PublicData = LevelSystem.PublicData or {}

net.Receive("levelsystem_public_data", function()
	local ply = net.ReadEntity()
	local level = net.ReadUInt(8)
	local prestige = net.ReadUInt(8)

	if not IsValid(ply) then return end
	LevelSystem.PublicData[ply] = { level = level, prestige = prestige }
end)

hook.Add("EntityRemoved", "levelsystem_public_data_cleanup", function(ent)
	LevelSystem.PublicData[ent] = nil
end)
