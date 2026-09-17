local Config = LevelSystem.Config

LevelSystem.MyData = {
	level = 1,
	prestige = 0,
	points = 0,
	xp = 0,
	xpNeeded = 1,
	skills = {},
}

--[[
- Callbacks fired whenever fresh data arrives from the server (e.g. the
- Skills tab UI listens here to refresh itself).
]]
LevelSystem.OnDataUpdated = LevelSystem.OnDataUpdated or {}

net.Receive("levelsystem_data", function()
	local data = LevelSystem.MyData

	data.level = net.ReadUInt(8)
	data.prestige = net.ReadUInt(8)
	data.points = net.ReadUInt(8)
	data.xp = net.ReadUInt(32)
	data.xpNeeded = net.ReadUInt(32)

	data.skills = {}
	for key in pairs(Config.skills) do
		data.skills[key] = net.ReadUInt(8)
	end

	for _, callback in pairs(LevelSystem.OnDataUpdated) do
		callback(data)
	end
end)

net.Receive("levelsystem_notify", function()
	local ntype = net.ReadUInt(8)
	local message = net.ReadString()

	if DarkRP and DarkRP.notify then
		DarkRP.notify(LocalPlayer(), ntype, 5, message)
	else
		chat.AddText(message)
	end
end)

--[[
- Asks the server for a fresh copy of our data.
]]
function LevelSystem.RequestData()
	net.Start("levelsystem_requestdata")
	net.SendToServer()
end

--[[
- @param string key -- one of the Config.skills keys
]]
function LevelSystem.SpendPoint(key)
	net.Start("levelsystem_spend")
		net.WriteString(key)
	net.SendToServer()
end

function LevelSystem.ResetAllSkills()
	net.Start("levelsystem_resetall")
	net.SendToServer()
end

function LevelSystem.RequestPrestige()
	net.Start("levelsystem_prestige")
	net.SendToServer()
end
