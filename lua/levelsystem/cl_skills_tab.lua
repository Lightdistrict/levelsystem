-- Builds the Skills tab content. Called by the F4 menu (see the f4menu
-- addon's cl_parallax.lua, which calls LevelSystem.BuildSkillsTab(container)
-- if this addon is present) -- kept as a single exposed function so the two
-- addons stay loosely coupled.

local Config = LevelSystem.Config

-- Matches the F4 menu's own font family/sizing convention (see cl_parallax.lua's
-- "dev title"/"dev button"/"dev text" -- "Roboto Regular"/"Roboto Medium" with
-- ScreenScale sizes) so this tab looks cohesive with the rest of the menu.
surface.CreateFont("levelsystem.header", { font = "Roboto Regular", size = ScreenScale(20) })
surface.CreateFont("levelsystem.cardname", { font = "Roboto Medium", size = ScreenScale(7) })
surface.CreateFont("levelsystem.cardcount", { font = "Roboto Regular", size = ScreenScale(6) })
surface.CreateFont("levelsystem.button", { font = "Roboto Medium", size = ScreenScale(6.5) })
surface.CreateFont("levelsystem.xpbar", { font = "Roboto Medium", size = ScreenScale(5.5) })

local COLOR_BG = Color(24, 26, 32)
local COLOR_CARD = Color(35, 38, 46)
local COLOR_CARD_HOVER = Color(45, 49, 58)
local COLOR_CARD_MAXED = Color(45, 60, 45)
local COLOR_WHITE = Color(255, 255, 255)
local COLOR_ACCENT = Color(80, 200, 255)
local COLOR_XPBAR_BG = Color(15, 16, 20)

local function playClick()
	surface.PlaySound("buttons/button15.wav")
end

--------------------------------------------------------------------------------
-- Vector icons -- crisp at any size (unlike the low-res stock icon16/*.png
-- set), and drawn plain white per request.
--------------------------------------------------------------------------------

local function drawArrowUp(x, y, size, col)
	surface.SetDrawColor(col)
	draw.NoTexture()
	surface.DrawPoly({
		{ x = x + size * 0.5, y = y },
		{ x = x + size, y = y + size * 0.6 },
		{ x = x + size * 0.65, y = y + size * 0.6 },
		{ x = x + size * 0.65, y = y + size },
		{ x = x + size * 0.35, y = y + size },
		{ x = x + size * 0.35, y = y + size * 0.6 },
		{ x = x, y = y + size * 0.6 },
	})
end

local function drawArrowDown(x, y, size, col)
	surface.SetDrawColor(col)
	draw.NoTexture()
	surface.DrawPoly({
		{ x = x + size * 0.35, y = y },
		{ x = x + size * 0.65, y = y },
		{ x = x + size * 0.65, y = y + size * 0.4 },
		{ x = x + size, y = y + size * 0.4 },
		{ x = x + size * 0.5, y = y + size },
		{ x = x, y = y + size * 0.4 },
		{ x = x + size * 0.35, y = y + size * 0.4 },
	})
end

local function drawHeart(x, y, size, col)
	surface.SetDrawColor(col)
	draw.NoTexture()
	local cx = x + size / 2
	surface.DrawPoly({
		{ x = cx, y = y + size },
		{ x = x, y = y + size * 0.45 },
		{ x = x, y = y + size * 0.15 },
		{ x = x + size * 0.25, y = y },
		{ x = cx, y = y + size * 0.28 },
		{ x = x + size * 0.75, y = y },
		{ x = x + size, y = y + size * 0.15 },
		{ x = x + size, y = y + size * 0.45 },
	})
end

local function drawShield(x, y, size, col)
	surface.SetDrawColor(col)
	draw.NoTexture()
	surface.DrawPoly({
		{ x = x + size * 0.5, y = y },
		{ x = x + size, y = y + size * 0.22 },
		{ x = x + size, y = y + size * 0.5 },
		{ x = x + size * 0.5, y = y + size },
		{ x = x, y = y + size * 0.5 },
		{ x = x, y = y + size * 0.22 },
	})
end

local function drawChevrons(x, y, size, col)
	surface.SetDrawColor(col)
	draw.NoTexture()
	for _, offset in ipairs({ 0, size * 0.4 }) do
		surface.DrawPoly({
			{ x = x + offset, y = y },
			{ x = x + offset + size * 0.35, y = y + size * 0.5 },
			{ x = x + offset, y = y + size },
			{ x = x + offset - size * 0.15, y = y + size * 0.85 },
			{ x = x + offset + size * 0.12, y = y + size * 0.5 },
			{ x = x + offset - size * 0.15, y = y + size * 0.15 },
		})
	end
end

local function drawStar(x, y, size, col)
	surface.SetDrawColor(col)
	draw.NoTexture()
	local cx, cy = x + size / 2, y + size / 2
	local outer, inner = size / 2, size / 4.5
	local points = {}
	for i = 0, 9 do
		local radius = (i % 2 == 0) and outer or inner
		local angle = math.rad(-90 + i * 36)
		table.insert(points, { x = cx + math.cos(angle) * radius, y = cy + math.sin(angle) * radius })
	end
	surface.DrawPoly(points)
end

local function drawDollar(x, y, size, col)
	draw.SimpleText("$", "levelsystem.cardname", x + size / 2, y + size / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local SHAPES = {
	arrow_up = drawArrowUp,
	arrow_down = drawArrowDown,
	heart = drawHeart,
	shield = drawShield,
	chevrons = drawChevrons,
	star = drawStar,
	dollar = drawDollar,
}

local function drawSkillIcon(shape, x, y, size, col)
	local fn = SHAPES[shape]
	if fn then
		fn(x, y, size, col)
	end
end

--------------------------------------------------------------------------------

--[[
- Formats a skill's per-point effect for its hover tooltip, e.g.
- "+2% -- increases your jump height (0/20)".
]]
local function skillTooltip(key, def)
	local current = LevelSystem.MyData.skills[key] or 0
	local amountText

	if def.unit == "percent" then
		amountText = "+" .. (def.perPoint * 100) .. "%"
	elseif def.unit == "money" then
		amountText = "+$" .. def.perPoint
	else
		amountText = "+" .. def.perPoint
	end

	return amountText .. " per point -- " .. (def.desc or "") .. "\n(" .. current .. "/" .. def.max .. " spent)"
end

--[[
- Builds one skill card panel. Sized/positioned externally via the parent
- row's PerformLayout -- NOT via Dock/SetWide here, since the row hasn't
- been laid out by its own parent yet at creation time (GetWide() on a
- freshly created panel is unreliable until a real layout pass happens).
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
	card:SetTooltip(skillTooltip(key, def))

	card.Paint = function(self, w, h)
		local current = LevelSystem.MyData.skills[key] or 0
		local maxed = current >= def.max

		draw.RoundedBox(6, 0, 0, w, h, maxed and COLOR_CARD_MAXED or (self:IsHovered() and COLOR_CARD_HOVER or COLOR_CARD))

		drawSkillIcon(def.shape, 16, h / 2 - 16, 32, COLOR_WHITE)

		draw.SimpleText(def.name, "levelsystem.cardname", 60, h * 0.38, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(current .. "/" .. def.max, "levelsystem.cardcount", 60, h * 0.72, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		-- Keep the tooltip's spent-count in sync as points get spent
		self:SetTooltip(skillTooltip(key, def))
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

	-- "You have X points to spend"
	local header = vgui.Create("DPanel", container)
	header:SetTall(60)
	header.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, COLOR_CARD)
		local text = "You have " .. LevelSystem.MyData.points .. " point" .. (LevelSystem.MyData.points == 1 and "" or "s") .. " to spend"
		draw.SimpleText(text, "levelsystem.header", w / 2, h / 2, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	container:AddItem(header)

	-- Prestige / Level line -- the one place accent color (not white) is used
	local status = vgui.Create("DPanel", container)
	status:SetTall(26)
	status.Paint = function(self, w, h)
		local d = LevelSystem.MyData
		local text = "Level " .. d.level .. " / " .. Config.maxLevel
		if d.prestige > 0 then
			text = "Prestige " .. d.prestige .. "   " .. text
		end
		draw.SimpleText(text, "levelsystem.cardcount", w / 2, h / 2, COLOR_ACCENT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	container:AddItem(status)

	-- XP progress bar: thin blue fill, current/needed text centered over it
	local xpbar = vgui.Create("DPanel", container)
	xpbar:SetTall(22)
	xpbar.Paint = function(self, w, h)
		local d = LevelSystem.MyData

		draw.RoundedBox(4, 0, 0, w, h, COLOR_XPBAR_BG)

		if d.level >= Config.maxLevel then
			draw.RoundedBox(4, 0, 0, w, h, COLOR_ACCENT)
			draw.SimpleText("MAX LEVEL", "levelsystem.xpbar", w / 2, h / 2, Color(20, 20, 20), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			return
		end

		local frac = d.xpNeeded > 0 and math.Clamp(d.xp / d.xpNeeded, 0, 1) or 0
		if frac > 0 then
			draw.RoundedBox(4, 0, 0, w * frac, h, COLOR_ACCENT)
		end

		local text = string.Comma(d.xp) .. " / " .. string.Comma(d.xpNeeded) .. " XP"
		draw.SimpleText(text, "levelsystem.xpbar", w / 2, h / 2, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	container:AddItem(xpbar)

	-- Skill cards, 3 per row -- sized via the row's own PerformLayout so
	-- they always match the row's actual current width.
	local keys = {}
	for key in pairs(Config.skills) do
		table.insert(keys, key)
	end
	table.sort(keys)

	for i = 1, #keys, 3 do
		local row = vgui.Create("DPanel", container)
		row:SetTall(74)
		row.Paint = function() end

		local cards = {}
		for col = 0, 2 do
			local key = keys[i + col]
			if key then
				table.insert(cards, buildSkillCard(row, key, Config.skills[key]))
			end
		end

		row.PerformLayout = function(self, w, h)
			local gap = 8
			local cardWidth = (w - gap * (#cards - 1)) / #cards
			for idx, card in ipairs(cards) do
				card:SetPos((idx - 1) * (cardWidth + gap), 0)
				card:SetSize(cardWidth, h)
			end
		end

		container:AddItem(row)
	end

	-- Footer: reset + prestige, positioned via PerformLayout for the same
	-- reason as the skill card rows above.
	local footer = vgui.Create("DPanel", container)
	footer:SetTall(48)
	footer.Paint = function() end

	local resetButton = vgui.Create("DButton", footer)
	resetButton:SetText("")
	resetButton.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, COLOR_ACCENT)
		local label = Config.resetSkillsCost > 0 and ("Reset skills for $" .. string.Comma(Config.resetSkillsCost)) or "Reset skills"
		draw.SimpleText(label, "levelsystem.button", w / 2, h / 2, Color(20, 20, 20), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	resetButton.DoClick = function()
		playClick()
		LevelSystem.ResetAllSkills()
	end

	local prestigeButton = vgui.Create("DButton", footer)
	prestigeButton:SetText("")
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

		draw.SimpleText(label, "levelsystem.button", w / 2, h / 2, canPrestige and Color(20, 20, 20) or COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	prestigeButton.DoClick = function()
		local d = LevelSystem.MyData
		if d.level < Config.maxLevel or d.prestige >= Config.maxPrestige then return end

		playClick()
		LevelSystem.RequestPrestige()
	end

	footer.PerformLayout = function(self, w, h)
		local gap = 8
		local half = (w - gap) / 2
		resetButton:SetPos(0, 0)
		resetButton:SetSize(half, h)
		prestigeButton:SetPos(half + gap, 0)
		prestigeButton:SetSize(half, h)
	end

	container:AddItem(footer)

	LevelSystem.RequestData()
end
