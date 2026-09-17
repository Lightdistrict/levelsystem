-- Builds the Skills tab content. Called by the F4 menu (see the f4menu
-- addon's cl_parallax.lua, which calls LevelSystem.BuildSkillsTab(container)
-- if this addon is present) -- kept as a single exposed function so the two
-- addons stay loosely coupled.

local Config = LevelSystem.Config

surface.CreateFont("levelsystem.header", { font = "Roboto", size = 28, weight = 700 })
surface.CreateFont("levelsystem.cardname", { font = "Roboto", size = 18, weight = 600 })
surface.CreateFont("levelsystem.cardcount", { font = "Roboto", size = 15, weight = 400 })
surface.CreateFont("levelsystem.button", { font = "Roboto", size = 16, weight = 600 })

local COLOR_BG = Color(24, 26, 32)
local COLOR_CARD = Color(35, 38, 46)
local COLOR_CARD_HOVER = Color(45, 49, 58)
local COLOR_CARD_MAXED = Color(45, 60, 45)
local COLOR_TEXT = Color(235, 235, 235)
local COLOR_SUBTEXT = Color(160, 160, 165)
local COLOR_ACCENT = Color(80, 200, 255)

local function playClick()
	surface.PlaySound("buttons/button15.wav")
end

--[[
- Builds one skill card panel.
-
- @param panel parent
- @param string key
- @param table def -- Config.skills[key]
-
- @return panel
]]
local function buildSkillCard(parent, key, def)
	local card = vgui.Create("DButton", parent)
	card:SetText("")
	card:SetSize(1, 74)

	local icon = vgui.Create("DImage", card)
	icon:SetImage(def.icon or "icon16/star.png")
	icon:SetSize(32, 32)

	card.Paint = function(self, w, h)
		local current = LevelSystem.MyData.skills[key] or 0
		local maxed = current >= def.max

		draw.RoundedBox(6, 0, 0, w, h, maxed and COLOR_CARD_MAXED or (self:IsHovered() and COLOR_CARD_HOVER or COLOR_CARD))

		draw.SimpleText(def.name, "levelsystem.cardname", 60, h * 0.38, COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(current .. "/" .. def.max, "levelsystem.cardcount", 60, h * 0.72, COLOR_SUBTEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	card.PerformLayout = function(self, w, h)
		icon:SetPos(16, h / 2 - 16)
	end

	card.DoClick = function()
		local current = LevelSystem.MyData.skills[key] or 0
		if LevelSystem.MyData.points <= 0 then return end
		if current >= def.max then return end

		playClick()
		LevelSystem.SpendPoint(key)
	end

	return card
end

--[[
- @param panel container -- the DPanelList passed in by the F4 menu tab system
]]
function LevelSystem.BuildSkillsTab(container)
	container.Paint = function(self, w, h)
		surface.SetDrawColor(COLOR_BG)
		surface.DrawRect(0, 0, w, h)
	end

	local header = vgui.Create("DPanel", container)
	header:SetTall(60)
	header.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, COLOR_CARD)
		local text = "You have " .. LevelSystem.MyData.points .. " point" .. (LevelSystem.MyData.points == 1 and "" or "s") .. " to spend"
		draw.SimpleText(text, "levelsystem.header", w / 2, h / 2, COLOR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	container:AddItem(header)

	local status = vgui.Create("DPanel", container)
	status:SetTall(30)
	status.Paint = function(self, w, h)
		local d = LevelSystem.MyData
		local text = "Level " .. d.level .. " / " .. Config.maxLevel
		if d.prestige > 0 then
			text = text .. "   -   Prestige " .. d.prestige .. " / " .. Config.maxPrestige
		end
		draw.SimpleText(text, "levelsystem.cardcount", w / 2, h / 2, COLOR_ACCENT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	container:AddItem(status)

	-- Skill cards, 3 per row
	local keys = {}
	for key in pairs(Config.skills) do
		table.insert(keys, key)
	end
	table.sort(keys)

	for i = 1, #keys, 3 do
		local row = vgui.Create("DPanel", container)
		row:SetTall(74)
		row.Paint = function() end

		for col = 0, 2 do
			local key = keys[i + col]
			if key then
				local card = buildSkillCard(row, key, Config.skills[key])
				card:SetWide(row:GetWide() / 3 - 6)
				card:Dock(LEFT)
				card:DockMargin(col == 0 and 0 or 4, 0, 4, 0)
			end
		end

		container:AddItem(row)
	end

	-- Footer: reset + prestige
	local footer = vgui.Create("DPanel", container)
	footer:SetTall(48)
	footer.Paint = function() end

	local resetButton = vgui.Create("DButton", footer)
	resetButton:SetText("")
	resetButton:Dock(LEFT)
	resetButton:SetWide(footer:GetWide() / 2 - 4)
	resetButton.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, COLOR_ACCENT)
		local label = Config.resetSkillsCost > 0 and ("Reset All ($" .. Config.resetSkillsCost .. ")") or "Reset All"
		draw.SimpleText(label, "levelsystem.button", w / 2, h / 2, Color(20, 20, 20), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	resetButton.DoClick = function()
		playClick()
		LevelSystem.ResetAllSkills()
	end

	local prestigeButton = vgui.Create("DButton", footer)
	prestigeButton:SetText("")
	prestigeButton:Dock(RIGHT)
	prestigeButton:SetWide(footer:GetWide() / 2 - 4)
	prestigeButton.Paint = function(self, w, h)
		local d = LevelSystem.MyData
		local canPrestige = d.level >= Config.maxLevel and d.prestige < Config.maxPrestige

		draw.RoundedBox(6, 0, 0, w, h, canPrestige and COLOR_ACCENT or COLOR_CARD)

		local label
		if d.prestige >= Config.maxPrestige then
			label = "Max Prestige"
		elseif canPrestige then
			label = "Prestige"
		else
			label = "Prestige (Lvl " .. Config.maxLevel .. " required)"
		end

		draw.SimpleText(label, "levelsystem.button", w / 2, h / 2, canPrestige and Color(20, 20, 20) or COLOR_SUBTEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	prestigeButton.DoClick = function()
		local d = LevelSystem.MyData
		if d.level < Config.maxLevel or d.prestige >= Config.maxPrestige then return end

		playClick()
		LevelSystem.RequestPrestige()
	end

	container:AddItem(footer)

	LevelSystem.RequestData()
end
