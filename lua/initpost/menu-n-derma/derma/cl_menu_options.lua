hg.settings = hg.settings or {}
hg.settings.tbl = hg.settings.tbl or {}
hg.settings.order = hg.settings.order or {}     -- [category] = { convar, ... } in the order they were added
hg.settings.catorder = hg.settings.catorder or {} -- categories in the order they were added
hg.settings.CatOpen = hg.settings.CatOpen or {}   -- remembers which categories you collapsed this session

function hg.settings:AddOpt( strCategory, strConVar, strTitle, bDecimals, bString, category )
    self.tbl[strCategory] = self.tbl[strCategory] or {}
    self.order = self.order or {}
    self.catorder = self.catorder or {}

    if not self.tbl[strCategory][strConVar] then
        self.order[strCategory] = self.order[strCategory] or {}
        table.insert(self.order[strCategory], strConVar)
    end

    if not table.HasValue(self.catorder, strCategory) then
        table.insert(self.catorder, strCategory)
    end

    self.tbl[strCategory][strConVar] = { strCategory, strConVar, strTitle, bDecimals or false, bString or false, category }
end

local hg_firstperson_death = CreateClientConVar("hg_firstperson_death", "0", true, false, "Toggle first-person death camera view", 0, 1)
local hg_font = CreateClientConVar("hg_font", "Bahnschrift", true, false, "change every text font to selected because ui customization is cool")
local hg_attachment_draw_distance = CreateClientConVar("hg_attachment_draw_distance", 0, true, nil, "distance to draw attachments", 0, 4096)

xbars = 17
ybars = 30

gradient_l = Material("vgui/gradient-l")

local sw, sh = ScrW(), ScrH()

-- =====================================================================
-- Visual effects: set any of these to false to turn it off
-- =====================================================================
local SET_FX = {
    SmoothScroll = true, -- eased mouse-wheel scrolling
    Grid         = true, -- moving background grid
    CornerGlow   = true, -- pulsing red glow in the top-left corner
}

local ACCENT   = Color(192, 0, 0)
local ACCENT_B = Color(235, 40, 40)
local glow_mat = Material("sprites/light_glow02_add")

local font = function() -- hg_coolvetica:GetBool() and "Coolvetica" or "Bahnschrift"
    local usefont = "Bahnschrift"

    if hg_font:GetString() != "" then
        usefont = hg_font:GetString()
    end

    return usefont
end

surface.CreateFont("ZCity_setiings_tiny", {
	font = font(),
	size = ScreenScale(7),
	weight = 100
})

surface.CreateFont("ZCity_setiings_fine", {
	font = font(),
	size = ScreenScale(10),
	weight = 100
})

surface.CreateFont("ZCity_setiings_category", {
	font = font(),
	size = ScreenScale(15),
	weight = 100
})

surface.CreateFont("ZCity_setiings_title", {
	font = font(),
	size = ScreenScale(20),
	weight = 800,
	antialias = true
})


hg.settings:AddOpt("Gameplay","hg_old_notificate", "Old Notifications")
hg.settings:AddOpt("Gameplay","hg_cheats", "Enable Cheats")
hg.settings:AddOpt("Gameplay","hg_showthoughts", "Show thoughts")
hg.settings:AddOpt("Gameplay","hg_hints", "Show hints")
hg.settings:AddOpt("Gameplay","hg_gary", "Center weapon in fake")
hg.settings:AddOpt("Gameplay","hg_deathfadeout", "Death fade out")
--hg_gary
--hg_deathfadeout
if not game.IsDedicated() then
	hg.settings:AddOpt("Server-side settings","hg_toughnpcs", "Tough npcs")
	hg.settings:AddOpt("Server-side settings","hg_thirdperson", "Thirdperson (WIP)")
	hg.settings:AddOpt("Server-side settings","hg_legacycam", "Legacy camera")
	hg.settings:AddOpt("Server-side settings","hg_ragdollcombat", "Ragdoll combat mode")
	hg.settings:AddOpt("Server-side settings","hg_movement_stamina_debuff", "Movement stamina debuff")
	hg.settings:AddOpt("Server-side settings","hg_furcity", "Furcity")
	hg.settings:AddOpt("Server-side settings","hg_appearance_access_for_all", "Appearance full access for all", nil, nil, "bool")
	hg.settings:AddOpt("Server-side settings","hg_healanims", "Heal & food animations")
	hg.settings:AddOpt("Server-side settings","hg_aimtoshoot", "Toggle DarkRP-like shooting system (aim to shoot): 0 - disabled; 1 - hipfire only; 2 - aiming only", nil, nil, "int")
	hg.settings:AddOpt("Server-side settings","hg_slings", "Sling system")
	hg.settings:AddOpt("Server-side settings","hg_allow_gopro", "Allow GoPro-like first-person camera")
	hg.settings:AddOpt("Server-side settings","hg_allow_gopro_pos", "Allow editing GoPro camera position")
	hg.settings:AddOpt("Server-side settings","hg_giveammomul", "Multiply given ammo for weapon spawned from spawnmenu")
	hg.settings:AddOpt("Server-side settings","hg_ixanims", "Toggle Helix-like animations on NPC models for players. Experimental")
	hg.settings:AddOpt("Server-side settings","hg_coolhands", "Give cool hands instead of default hands on spawn")
	hg.settings:AddOpt("Server-side settings","hg_loadcontent", "Toggle loading content to clients using 'resource.AddWorkshop' (need server restart to apply)")
    hg.settings:AddOpt("Server-side settings","homicide_traitoramount", "Homicide: Traitor Amount", nil, nil, "int")
end
--hg_appearance_access_for_all
--hg_furcity
--hg_legacycam
--hg_toughnpcs

hg.settings:AddOpt("Debug","hg_show_hitposmuzzle", "Show weapon hitpos")
hg.settings:AddOpt("Debug","hg_setzoompos", "Edit weapon zoompos, check console for results")
hg.settings:AddOpt("Debug","hg_show_hitbox", "Show hitboxes")

hg.settings:AddOpt("Optimization","hg_potatopc", "Potato PC Mode")
hg.settings:AddOpt("Optimization","hg_anims_draw_distance", "Animations Draw Distance", true, nil, "int")
hg.settings:AddOpt("Optimization","hg_anim_fps", "Animations FPS", nil, nil, "int")
hg.settings:AddOpt("Optimization","hg_attachment_draw_distance", "Attachment Draw Distance", true, nil, "int")
hg.settings:AddOpt("Optimization","hg_maxsmoketrails", "Maximum Smoke Trails", nil, nil, "int")
hg.settings:AddOpt("Optimization","hg_tpik_distance", "TPIK Render Distance", true, nil, "int")

hg.settings:AddOpt("Blood","hg_blood_draw_distance", "Blood Draw Distance")
hg.settings:AddOpt("Blood","hg_blood_fps", "Blood FPS")
hg.settings:AddOpt("Blood","hg_blood_sprites", "Blood Sprites (DISABLED FOR EVERYONE)")
hg.settings:AddOpt("Blood","hg_old_blood", "Old blood")

hg.settings:AddOpt("UI","hg_font", "Set Custom Font", false, true)

hg.settings:AddOpt("Weapons","hg_weaponshotblur_enable", "Shooting Blur")
hg.settings:AddOpt("Weapons","hg_dynamic_mags", "Dynamic Ammo Inspect")
hg.settings:AddOpt("Weapons","hg_zoomsensitivity", "Scope sensitivity")
hg.settings:AddOpt("Weapons","hg_highpitchgunfire", "Toggle high pitched gunfire sounds inside buildings")

hg.settings:AddOpt("View","hg_firstperson_death", "First-Person Death")
hg.settings:AddOpt("View","hg_fov", "Field Of View")
hg.settings:AddOpt("View","hg_newspectate", "Smooth Spectator Camera")
hg.settings:AddOpt("View","hg_cshs_fake", "C'sHS Ragdoll Camera")
hg.settings:AddOpt("View","hg_gun_cam", "Gun Camera (ADMIN ONLY)")
hg.settings:AddOpt("View","hg_nofovzoom", "Disable/Enable FOV Zoom")
hg.settings:AddOpt("View","hg_realismcam", "Realism camera (shitty)")
hg.settings:AddOpt("View","hg_gopro", "GoPro camera")
hg.settings:AddOpt("View","hg_newfakecam", "New fake camera")
hg.settings:AddOpt("View","hg_leancam_mul", "Lean camera mul", true, nil, "int")
hg.settings:AddOpt("View","hg_gun_cam", "Gun camera (WIP Admin only)")
--hg_hints
--hg_leancam_mul
  --hg_newfakecam
hg.settings:AddOpt("Sound","hg_dmusic", "Dynamic Music")
hg.settings:AddOpt("Sound","hg_quietshots", "Enable/Disable Quietshoot Sounds")

-- =====================================================================
-- Helpers
-- =====================================================================

function hg.GetConVarType(convar)
    local stringv = convar:GetString()
    local floatVal = convar:GetFloat()
    local intVal = convar:GetInt()
    local boolVal = convar:GetBool()

    if (stringv == '0' and not boolVal) or (stringv == '1' and boolVal) then
        return 'bool'
    end

    if tonumber(stringv) and math.floor(stringv) == floatVal then
        if intVal == floatVal then
            return "int"
        end
    end

    return "string"
end

local function SetConVarValue(convar, value)
    if not convar then
        return
    end

    local name = convar.GetName and convar:GetName()
    if not name or name == "" then
        return
    end

    if isbool(value) then
        RunConsoleCommand(name, value and "1" or "0")
        return
    end

    RunConsoleCommand(name, tostring(value))
end

-- Reusable color so we don't allocate a new Color every frame
local _c = Color(255, 255, 255, 255)
local function SetC(r, g, b, a)
    _c.r, _c.g, _c.b, _c.a = r, g, b, a or 255
    return _c
end

local function Approach(cur, target, t)
    local n = Lerp(t, cur, target)
    if math.abs(n - target) < 0.004 then return target end
    return n
end

local function IntroEase(now, openTime, delay)
    local t = math.Clamp((now - openTime - delay) / 0.3, 0, 1)
    return 1 - (1 - t) ^ 3
end

local function IsModified(convar)
    local a, b = convar:GetString(), convar:GetDefault()
    if a == b then return false end

    local na, nb = tonumber(a), tonumber(b)
    if na and nb then
        return math.abs(na - nb) > 0.00001
    end

    return true
end

local function FormatVal(v, decimals)
    if decimals > 0 then
        return string.format("%." .. decimals .. "f", v)
    end
    return tostring(math.Round(v))
end

-- Shortens text with "..." so it fits in maxW pixels
local function FitText(text, fnt, maxW)
    surface.SetFont(fnt)
    if maxW <= 0 then return "" end
    if surface.GetTextSize(text) <= maxW then return text end

    local lo, hi = 0, #text
    while lo < hi do
        local mid = math.ceil((lo + hi) / 2)
        if surface.GetTextSize(string.sub(text, 1, mid) .. "...") <= maxW then
            lo = mid
        else
            hi = mid - 1
        end
    end

    return string.sub(text, 1, lo) .. "..."
end

-- Right-pointing triangle rotated by rot degrees (90 = pointing down)
local function DrawChevron(cx, cy, size, rot, col)
    local base = { {-0.5, -0.6}, {0.7, 0}, {-0.5, 0.6} }
    local rad = math.rad(rot)
    local c, s = math.cos(rad), math.sin(rad)
    local pts = {}

    for i, p in ipairs(base) do
        pts[i] = {
            x = cx + (p[1] * c - p[2] * s) * size,
            y = cy + (p[1] * s + p[2] * c) * size,
        }
    end

    draw.NoTexture()
    surface.SetDrawColor(col)
    surface.DrawPoly(pts)
end

local PreferredOrder = { "Gameplay", "View", "Weapons", "Sound", "Blood", "UI", "Optimization", "Server-side settings", "Debug" }
local DefaultCollapsed = { ["Debug"] = true, ["Server-side settings"] = true }

local function GetOrderedCategories()
    local list, seen = {}, {}

    for _, name in ipairs(PreferredOrder) do
        if hg.settings.tbl[name] and not seen[name] then
            list[#list + 1] = name
            seen[name] = true
        end
    end

    for _, name in ipairs(hg.settings.catorder or {}) do
        if hg.settings.tbl[name] and not seen[name] then
            list[#list + 1] = name
            seen[name] = true
        end
    end

    for name in SortedPairs(hg.settings.tbl) do
        if not seen[name] then
            list[#list + 1] = name
            seen[name] = true
        end
    end

    return list
end

local function GetOrderedConVars(cat)
    local list, seen = {}, {}
    local tbl = hg.settings.tbl[cat] or {}

    for _, cv in ipairs((hg.settings.order or {})[cat] or {}) do
        if tbl[cv] and not seen[cv] then
            list[#list + 1] = cv
            seen[cv] = true
        end
    end

    for cv in SortedPairs(tbl) do
        if not seen[cv] then
            list[#list + 1] = cv
            seen[cv] = true
        end
    end

    return list
end

-- =====================================================================
-- Controls
-- =====================================================================

local function MakeToggle(row, convar, fullH)
    local toggle = vgui.Create('DButton', row)
    toggle:SetText('')
    toggle:SetSize(ScreenScale(34), fullH * 0.46)
    toggle.Anim = convar:GetBool() and 1 or 0

    function toggle:State()
        if self.Opt and RealTime() - self.Opt.t < 0.35 then
            return self.Opt.val
        end
        return convar:GetBool()
    end

    function toggle:Paint(w, h)
        local on = self:State()
        self.Anim = Lerp(math.min(1, RealFrameTime() * 12), self.Anim, on and 1 or 0)
        local a = self.Anim

        -- track
        draw.RoundedBox(h / 2, 0, 0, w, h, SetC(Lerp(a, 70, 170), Lerp(a, 70, 25), Lerp(a, 70, 25), 255))
        draw.RoundedBox(math.max(0, h / 2 - 2), 2, 2, w - 4, h - 4, SetC(Lerp(a, 24, 100), Lerp(a, 24, 8), Lerp(a, 24, 8), 255))

        local ks = h - 8
        local kx = Lerp(a, 4, w - ks - 4)

        -- glow
        if a > 0.02 then
            local gs = ks * 3
            surface.SetMaterial(glow_mat)
            surface.SetDrawColor(255, 30, 30, 150 * a)
            surface.DrawTexturedRect(kx + ks / 2 - gs / 2, h / 2 - gs / 2, gs, gs)
        end

        -- knob
        draw.RoundedBox(ks / 2, kx, 4, ks, ks, SetC(Lerp(a, 140, 255), Lerp(a, 140, 70), Lerp(a, 140, 70), 255))

        -- label on the empty side of the track
        local lbl = a > 0.5 and "ON" or "OFF"
        local lx = a > 0.5 and (w * 0.3) or (w * 0.7)
        draw.SimpleText(lbl, "ZCity_setiings_tiny", lx, h / 2, SetC(255, 255, 255, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function toggle:DoClick()
        local newValue = not self:State()
        self.Opt = { val = newValue, t = RealTime() }
        SetConVarValue(convar, newValue)

        surface.PlaySound('glide/headlights_on.wav')
    end

    return toggle
end

local function MakeSlider(row, convar, buttonData, fullH)
    local decimals = buttonData[4] and 2 or 0
    local minv = convar:GetMin() or 0
    local maxv = convar:GetMax() or 100
    local cur = decimals > 0 and convar:GetFloat() or convar:GetInt()

    -- convars without a max: grow the range if the value is already past it
    if cur > maxv then maxv = cur * 2 end
    if maxv <= minv then maxv = minv + 1 end

    local slider = vgui.Create('DPanel', row)
    slider:SetSize(ScreenScale(170), fullH * 0.5)
    slider:SetCursor("hand")
    slider.Display = cur

    function slider:Track()
        return ScreenScale(30) + ScreenScale(6), self:GetWide() - ScreenScale(6)
    end

    function slider:Apply()
        local x0, x1 = self:Track()
        local x = self:CursorPos()
        local frac = math.Clamp((x - x0) / math.max(x1 - x0, 1), 0, 1)
        local val = math.Round(minv + frac * (maxv - minv), decimals)

        if val ~= self.LastSent then
            self.LastSent = val
            SetConVarValue(convar, val)
        end
    end

    function slider:OnMousePressed(code)
        if code ~= MOUSE_LEFT then return end
        self.Drag = true
        self:MouseCapture(true)
        self:Apply()
    end

    function slider:OnMouseReleased(code)
        self.Drag = false
        self:MouseCapture(false)
    end

    function slider:Think()
        if self.Drag then self:Apply() end

        local target = convar:GetFloat()
        if self.Drag and self.LastSent then target = self.LastSent end

        self.Display = Lerp(math.min(1, RealFrameTime() * 14), self.Display, target)
        self.KnobLerp = Lerp(math.min(1, RealFrameTime() * 12), self.KnobLerp or 0, (self.Drag or self:IsHovered()) and 1 or 0)
    end

    function slider:Paint(w, h)
        local x0, x1 = self:Track()
        local frac = math.Clamp((self.Display - minv) / math.max(maxv - minv, 0.0001), 0, 1)
        local fx = x0 + (x1 - x0) * frac
        local th = math.max(4, ScreenScale(1.6))
        local ty = h / 2
        local k = self.KnobLerp or 0

        -- track + fill
        surface.SetDrawColor(20, 20, 20, 255)
        surface.DrawRect(x0, ty - th / 2, x1 - x0, th)
        surface.SetDrawColor(ACCENT.r, ACCENT.g, ACCENT.b, 255)
        surface.DrawRect(x0, ty - th / 2, fx - x0, th)

        -- glow + knob
        local ks = h * (0.42 + 0.12 * k)
        local gs = ks * 3.2
        surface.SetMaterial(glow_mat)
        surface.SetDrawColor(255, 30, 30, 70 + 110 * k)
        surface.DrawTexturedRect(fx - gs / 2, ty - gs / 2, gs, gs)
        draw.RoundedBox(2, fx - ks / 2, ty - ks / 2, ks, ks, SetC(240, 240, 240, 255))

        -- value readout
        draw.SimpleText(FormatVal(self.Display, decimals), "ZCity_setiings_tiny", ScreenScale(30), h / 2, SetC(255, 255, 255, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    return slider
end

local function MakeTextEntry(row, convar, fullH)
    local textEntry = vgui.Create('DTextEntry', row)
    textEntry:SetSize(ScreenScale(120), fullH * 0.5)
    textEntry:SetText(convar:GetString())
    textEntry:SetUpdateOnType(true)
    textEntry:SetFont('ZCity_setiings_tiny')

    textEntry.Paint = function(self, w, h)
        surface.SetDrawColor(30, 30, 30, 255)
        surface.DrawRect(0, 0, w, h)

        if self:HasFocus() then
            surface.SetDrawColor(ACCENT.r, ACCENT.g, ACCENT.b, 255)
        else
            surface.SetDrawColor(60, 60, 60, 255)
        end
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        self:DrawTextEntryText(color_white, SetC(192, 0, 0, 160), color_white)
    end

    -- keep the box in sync when the value changes elsewhere (e.g. RESET)
    textEntry.Think = function(self)
        if not self:HasFocus() and self:GetText() ~= convar:GetString() then
            self:SetText(convar:GetString())
        end
    end

    function textEntry:OnValueChange(val)
        SetConVarValue(convar, val)
    end

    return textEntry
end

-- =====================================================================
-- Rows and category headers
-- =====================================================================

local function BuildRow(buttonData, convarName, parent, fullH)
    local convar = GetConVar(convarName)
    if not convar then return end

    local convarType = buttonData[6] or (buttonData[5] and "string") or hg.GetConVarType(convar)

    local row = vgui.Create('DPanel', parent)
    row.FullH = fullH
    row.Convar = convar
    row.RowTitle = buttonData[3] or convarName
    row.RowHelp = convar:GetHelpText() or ""
    row.CatName = buttonData[1] or ""
    row.SearchText = string.lower(row.RowTitle .. " " .. convarName .. " " .. row.RowHelp .. " " .. row.CatName)
    row.HoverLerp = 0
    row.ModLerp = 0
    row.Frac = 1
    row.Match = true
    row.TitleFit = row.RowTitle
    row.HelpFit = row.RowHelp

    surface.SetFont('ZCity_setiings_fine')
    local _, titleH = surface.GetTextSize(row.RowTitle)
    row.TitleH = titleH

    if row.RowHelp ~= "" then
        row:SetTooltip(row.RowHelp)
    end

    if convarType == 'bool' then
        row.Ctrl = MakeToggle(row, convar, fullH)
    elseif convarType == 'int' then
        row.Ctrl = MakeSlider(row, convar, buttonData, fullH)
    else
        row.Ctrl = MakeTextEntry(row, convar, fullH)
    end

    -- RESET button (only visible when the value differs from the default)
    surface.SetFont('ZCity_setiings_tiny')
    local rtw = surface.GetTextSize("RESET")
    local reset = vgui.Create('DButton', row)
    reset:SetText('')
    reset:SetSize(rtw + ScreenScale(8), ScreenScale(12))
    reset:SetVisible(false)
    reset.Hov = 0
    reset.Paint = function(self, w, h)
        self.Hov = Lerp(math.min(1, RealFrameTime() * 12), self.Hov, self:IsHovered() and 1 or 0)
        surface.SetDrawColor(ACCENT.r, ACCENT.g, ACCENT.b, 60 + 120 * self.Hov)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("RESET", "ZCity_setiings_tiny", w / 2, h / 2, SetC(255, 255, 255, 140 + 115 * self.Hov), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    reset.DoClick = function()
        RunConsoleCommand(convarName, convar:GetDefault())
        surface.PlaySound("shitty/tap_release.wav")
    end
    row.ResetBtn = reset

    function row:PerformLayout(w, h)
        local fh = self.FullH
        local textX = ScreenScale(12)
        local ctrlX = w - ScreenScale(12)

        if IsValid(self.Ctrl) then
            ctrlX = w - ScreenScale(12) - self.Ctrl:GetWide()
            self.Ctrl:SetPos(ctrlX, fh / 2 - self.Ctrl:GetTall() / 2)
        end

        local reserved = 0
        if IsValid(self.ResetBtn) then
            self.ResetBtn:SetPos(ctrlX - self.ResetBtn:GetWide() - ScreenScale(6), fh / 2 - self.ResetBtn:GetTall() / 2)
            reserved = self.ResetBtn:GetWide() + ScreenScale(6)
        end

        local avail = ctrlX - reserved - textX - ScreenScale(10)
        if self.FitW ~= avail then
            self.FitW = avail
            self.TitleFit = FitText(self.RowTitle, "ZCity_setiings_fine", avail)
            self.HelpFit = FitText(self.RowHelp, "ZCity_setiings_tiny", avail)
        end
    end

    function row:Think()
        local dt = math.min(1, RealFrameTime() * 12)
        local hovered = self:IsHovered() or self:IsChildHovered()
        self.HoverLerp = Lerp(dt, self.HoverLerp, hovered and 1 or 0)

        local mod = IsModified(self.Convar)
        self.ModLerp = Lerp(dt, self.ModLerp, mod and 1 or 0)

        if IsValid(self.ResetBtn) and self.ResetBtn:IsVisible() ~= mod then
            self.ResetBtn:SetVisible(mod)
        end
    end

    row.Paint = function(self, w, h)
        local hv, md, fh = self.HoverLerp, self.ModLerp, self.FullH

        surface.SetDrawColor(43 + 20 * hv, 43 + 6 * hv, 43 + 6 * hv, 145 + 55 * hv)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(47, 47, 47, 145)
        surface.DrawRect(0, h - 3, w, 3)

        -- red bar slides in on hover
        if hv > 0.01 then
            local barH = fh * 0.72 * hv
            surface.SetDrawColor(ACCENT.r, ACCENT.g, ACCENT.b, 255 * hv)
            surface.DrawRect(0, (fh - barH) / 2, math.max(2, ScreenScale(1.2)), barH)
        end

        -- dot = value differs from default
        if md > 0.01 then
            local ds = math.max(4, ScreenScale(2))
            surface.SetDrawColor(ACCENT_B.r, ACCENT_B.g, ACCENT_B.b, 255 * md)
            surface.DrawRect(ScreenScale(6), fh / 2 - ds / 2, ds, ds)
        end

        local tx = ScreenScale(12)
        local hasHelp = self.RowHelp ~= ""

        draw.SimpleText(self.TitleFit, 'ZCity_setiings_fine', tx, hasHelp and (fh / 2 - self.TitleH / 2.5) or (fh / 2), SetC(255, 255, 255, 150 + 105 * hv), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        if hasHelp then
            draw.SimpleText(self.HelpFit, 'ZCity_setiings_tiny', tx, fh / 2 + self.TitleH / 2, SetC(122 + 50 * hv, 122 + 50 * hv, 122 + 50 * hv, 104 + 90 * hv), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    return row
end

local function BuildCategory(name, parent, cat)
    local p = vgui.Create('DPanel', parent)
    p.Cat = cat
    p.HoverLerp = 0
    p:SetCursor("hand")
    p:SetMouseInputEnabled(true)

    function p:OnMousePressed(code)
        if code == MOUSE_LEFT and self.DoClick then
            self:DoClick()
        end
    end

    function p:Think()
        self.HoverLerp = Lerp(math.min(1, RealFrameTime() * 12), self.HoverLerp, self:IsHovered() and 1 or 0)
    end

    p.Paint = function(self, w, h)
        local hv, of = self.HoverLerp, self.Cat.OpenFrac

        surface.SetDrawColor(60 + 18 * hv, 60 + 4 * hv, 60 + 4 * hv, 145)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(42, 42, 42, 184)
        surface.DrawRect(0, h - 5, w, 5)

        -- red accent line grows when open / hovered
        surface.SetDrawColor(ACCENT.r, ACCENT.g, ACCENT.b, 255)
        surface.DrawRect(0, h - 5, w * (0.05 + 0.10 * of + 0.25 * hv), 5)

        DrawChevron(ScreenScale(12), h / 2, ScreenScale(3.5), 90 * of, SetC(255, 255, 255, 140 + 115 * hv))
        draw.SimpleText(name, 'ZCity_setiings_category', ScreenScale(22), h / 2, SetC(255, 255, 255, 200 + 55 * hv), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local mc = self.Cat.MatchCount or 0
        if mc > 0 then
            draw.SimpleText(mc .. (mc == 1 and " OPTION" or " OPTIONS"), 'ZCity_setiings_tiny', w - ScreenScale(8), h / 2, SetC(255, 255, 255, 90), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end

    return p
end

-- Kept for compatibility with anything that calls these directly
function hg.CreateCategory(ctgName, ParentPanel, yPos)
    local cat = { Name = ctgName, Open = true, OpenFrac = 1, MatchCount = 0, Rows = {} }
    local pnl = BuildCategory(ctgName, ParentPanel, cat)
    pnl:SetSize(ParentPanel:GetWide() / 1.05, ParentPanel:GetTall() * 0.07)
    pnl:SetPos(ParentPanel:GetWide() / 2 - pnl:GetWide() / 2, yPos)

    return pnl
end

function hg.CreateButton(buttonData, convarName, ParentPanel, yPos)
    local fullH = ParentPanel:GetTall() / 15
    local row = BuildRow(buttonData, convarName, ParentPanel, fullH)
    if not row then return end

    row:SetSize(ParentPanel:GetWide() / 1.05, fullH)
    row:SetPos(ParentPanel:GetWide() / 2 - row:GetWide() / 2, yPos)

    return row
end

-- =====================================================================
-- The settings page
-- =====================================================================

function hg.DrawSettings(ParentPanel)
    ParentPanel:SetAlpha(0)
    local openTime = RealTime()

    ParentPanel.Paint = function(self, w, h)
        local ct = RealTime()

        surface.SetDrawColor(28, 28, 28, 255)
        surface.DrawRect(0, 0, w, h)

        -- pulsing red glow in the corner
        if SET_FX.CornerGlow then
            local pulse = 0.7 + 0.3 * math.sin(ct * 1.5)
            local gs = math.max(w, h) * 0.9
            surface.SetMaterial(glow_mat)
            surface.SetDrawColor(180, 10, 10, 40 * pulse)
            surface.DrawTexturedRect(-gs / 2, -gs / 2, gs, gs)
        end

        draw.NoTexture()

        -- moving grid
        if SET_FX.Grid then
            surface.SetDrawColor(107, 107, 107, 22)

            for i = 1, (ybars + 1) do
                surface.DrawRect((sw / ybars) * i - (ct * 30 % (sw / ybars)), 0, ScreenScale(1), sh)
            end

            for i = 1, (xbars + 1) do
                surface.DrawRect(0, (sh / xbars) * (i - 1) + (ct * 30 % (sh / xbars)), sw, ScreenScale(1))
            end
        end

        local border_size = ScreenScale(2)
        surface.SetDrawColor(0, 0, 0)
        surface.SetMaterial(gradient_l)
        surface.DrawTexturedRect(0, 0, border_size, sh)
    end

    hg.DrawBlur(ParentPanel, 5)
    ParentPanel:AlphaTo(255, 0.15, 0)

    local pw, ph = ParentPanel:GetWide(), ParentPanel:GetTall()
    local sidePad = ScreenScale(6)
    local topPad = ScreenScale(4)
    local gap = ScreenScale(4)
    local headerH = math.max(ScreenScale(36), ph * 0.11)
    local fullH = ph / 15
    local catH = ph * 0.07

    local S = { Filter = "", Cats = {}, Matches = 0, Total = 0, LastY = 0 }

    -- ---------------- scroll area ----------------
    local scroll = vgui.Create('DScrollPanel', ParentPanel)
    scroll:SetPos(0, headerH)
    scroll:SetSize(pw, ph - headerH)
    scroll.Paint = function() end
    scroll.TargetScroll = 0

    local vbar = scroll:GetVBar()
    vbar:SetWide(ScreenScale(3))
    vbar:SetHideButtons(true)
    vbar.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 90)
        surface.DrawRect(0, 0, w, h)
    end
    vbar.btnGrip.Paint = function(self, w, h)
        surface.SetDrawColor(ACCENT.r, ACCENT.g, ACCENT.b, self:IsHovered() and 255 or 170)
        surface.DrawRect(0, 0, w, h)
    end

    local canvas = scroll:GetCanvas()

    -- ---------------- build rows + categories ----------------
    local n = 0
    for _, catName in ipairs(GetOrderedCategories()) do
        local open = hg.settings.CatOpen[catName]
        if open == nil then open = not DefaultCollapsed[catName] end

        local cat = { Name = catName, Rows = {}, Open = open, OpenFrac = open and 1 or 0, VisFrac = 1, MatchCount = 0 }

        for _, cv in ipairs(GetOrderedConVars(catName)) do
            local data = hg.settings.tbl[catName][cv]
            n = n + 1

            local row = BuildRow(data, cv, canvas, fullH)
            if row then
                row.IntroDelay = 0.05 + math.min(n * 0.02, 0.5)
                row.Frac = open and 1 or 0
                row:SetSize(math.max(pw - vbar:GetWide() - sidePad * 2, 1), fullH)
                cat.Rows[#cat.Rows + 1] = row
            end
        end

        if #cat.Rows > 0 then
            cat.Header = BuildCategory(catName, canvas, cat)
            cat.Header.IntroDelay = 0.03 * #S.Cats
            cat.Header:SetSize(math.max(pw - vbar:GetWide() - sidePad * 2, 1), catH)

            function cat.Header:DoClick()
                cat.Open = not cat.Open
                hg.settings.CatOpen[catName] = cat.Open
                surface.PlaySound("shitty/tap_depress.wav")
            end

            S.Cats[#S.Cats + 1] = cat
            S.Total = S.Total + #cat.Rows
        end
    end

    S.Spacer = vgui.Create('DPanel', canvas)
    S.Spacer:SetSize(1, 1)
    S.Spacer.Paint = function() end

    -- ---------------- search / filter ----------------
    local function Refilter()
        S.AppliedFilter = S.Filter

        local words = {}
        for wd in string.gmatch(S.Filter, "%S+") do
            words[#words + 1] = wd
        end

        local total = 0
        for _, cat in ipairs(S.Cats) do
            cat.MatchCount = 0

            for _, row in ipairs(cat.Rows) do
                local ok = true
                for _, wd in ipairs(words) do
                    if not string.find(row.SearchText, wd, 1, true) then
                        ok = false
                        break
                    end
                end

                row.Match = ok
                if ok then cat.MatchCount = cat.MatchCount + 1 end
            end

            total = total + cat.MatchCount
        end

        S.Matches = total
    end

    -- ---------------- layout (runs every frame) ----------------
    local function Layout()
        if not IsValid(scroll) then return end

        if S.AppliedFilter ~= S.Filter then Refilter() end

        local now = RealTime()
        local dt = math.min(1, RealFrameTime() * 12)
        local cw = math.max(scroll:GetWide() - vbar:GetWide() - sidePad * 2, 1)
        local filtering = S.Filter ~= ""
        local y = topPad

        for _, cat in ipairs(S.Cats) do
            local header = cat.Header
            local expanded = filtering or cat.Open

            cat.VisFrac = Approach(cat.VisFrac, cat.MatchCount > 0 and 1 or 0, dt)
            cat.OpenFrac = Approach(cat.OpenFrac, expanded and 1 or 0, dt)

            local vis = cat.VisFrac
            if vis > 0.001 then
                local intro = IntroEase(now, openTime, header.IntroDelay)
                local hh = math.max(1, math.Round(catH * vis))

                header:SetVisible(true)
                header:SetPos(sidePad + (1 - intro) * ScreenScale(14), y)
                if header:GetWide() ~= cw or header:GetTall() ~= hh then header:SetSize(cw, hh) end
                header:SetAlpha(255 * vis * intro)

                y = y + hh + math.Round(gap * vis)
            else
                header:SetVisible(false)
            end

            for _, row in ipairs(cat.Rows) do
                local want = (row.Match and expanded) and 1 or 0
                row.Frac = Approach(row.Frac, want, dt)

                local f = row.Frac
                if f > 0.001 then
                    local intro = IntroEase(now, openTime, row.IntroDelay)
                    local rh = math.max(1, math.Round(row.FullH * f))

                    row:SetVisible(true)
                    row:SetPos(sidePad + (1 - intro) * ScreenScale(14), y)
                    if row:GetWide() ~= cw or row:GetTall() ~= rh then row:SetSize(cw, rh) end
                    row:SetAlpha(255 * f * intro)

                    y = y + math.Round((row.FullH + gap) * f)
                else
                    row:SetVisible(false)
                end
            end
        end

        S.Spacer:SetPos(0, y + ScreenScale(10))

        if math.abs(y - S.LastY) > 0.5 then
            S.LastY = y
            scroll:InvalidateLayout()
        end
    end

    scroll.Think = function(self)
        Layout()

        if SET_FX.SmoothScroll then
            local vb = self:GetVBar()
            local maxS = math.max(0, self:GetCanvas():GetTall() - self:GetTall())

            if vb.btnGrip.Depressed then
                self.TargetScroll = vb:GetScroll()
            else
                self.TargetScroll = math.Clamp(self.TargetScroll, 0, maxS)

                local cur = vb:GetScroll()
                if math.abs(cur - self.TargetScroll) > 0.5 then
                    vb:SetScroll(Lerp(math.min(1, RealFrameTime() * 14), cur, self.TargetScroll))
                end
            end
        end
    end

    if SET_FX.SmoothScroll then
        function scroll:OnMouseWheeled(delta)
            local maxS = math.max(0, self:GetCanvas():GetTall() - self:GetTall())
            self.TargetScroll = math.Clamp(self.TargetScroll - delta * ScreenScale(36), 0, maxS)

            return true
        end
    end

    scroll.PaintOver = function(self, w, h)
        if S.Matches == 0 and S.Filter ~= "" then
            draw.SimpleText("NO SETTINGS MATCH", "ZCity_setiings_category", w / 2, h * 0.3, SetC(255, 255, 255, 160), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText('"' .. S.Filter .. '"', "ZCity_setiings_fine", w / 2, h * 0.3 + ScreenScale(18), SetC(ACCENT_B.r, ACCENT_B.g, ACCENT_B.b, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    -- ---------------- header bar ----------------
    local header = vgui.Create('DPanel', ParentPanel)
    header:SetPos(0, 0)
    header:SetSize(pw, headerH)
    header.Paint = function(self, w, h)
        surface.SetDrawColor(18, 18, 18, 200)
        surface.DrawRect(0, 0, w, h)

        local t = math.Clamp((RealTime() - openTime) / 0.7, 0, 1)
        local ease = 1 - (1 - t) ^ 3
        surface.SetDrawColor(ACCENT.r, ACCENT.g, ACCENT.b, 255)
        surface.DrawRect(0, h - math.max(2, ScreenScale(0.8)), w * ease, math.max(2, ScreenScale(0.8)))

        -- "S" in red, rest in white
        surface.SetFont("ZCity_setiings_title")
        local sW = surface.GetTextSize("S")
        draw.SimpleText("S", "ZCity_setiings_title", sidePad, h * 0.4, ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("ETTINGS", "ZCity_setiings_title", sidePad + sW, h * 0.4, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local sub
        if S.Filter ~= "" then
            sub = string.format("%d / %d MATCHING", S.Matches, S.Total)
        else
            sub = string.format("%d OPTIONS  |  %d CATEGORIES", S.Total, #S.Cats)
        end
        draw.SimpleText(sub, "ZCity_setiings_tiny", sidePad + 2, h * 0.78, SetC(255, 255, 255, 90), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local contentRight = pw - vbar:GetWide() - sidePad
    local ctlH = headerH * 0.34
    local ctlY = (headerH - ctlH) / 2
    local searchW = math.min(pw * 0.3, ScreenScale(170))

    local search = vgui.Create('DTextEntry', header)
    search:SetSize(searchW, ctlH)
    search:SetPos(contentRight - searchW, ctlY)
    search:SetFont('ZCity_setiings_tiny')
    search:SetUpdateOnType(true)
    search.Paint = function(self, w, h)
        surface.SetDrawColor(24, 24, 24, 255)
        surface.DrawRect(0, 0, w, h)

        if self:HasFocus() then
            surface.SetDrawColor(ACCENT.r, ACCENT.g, ACCENT.b, 255)
        else
            surface.SetDrawColor(60, 60, 60, 255)
        end
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        if self:GetText() == "" then
            draw.SimpleText("Search settings...", "ZCity_setiings_tiny", ScreenScale(4), h / 2, SetC(255, 255, 255, 70), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        self:DrawTextEntryText(color_white, SetC(192, 0, 0, 160), color_white)
    end
    function search:OnChange()
        S.Filter = string.lower(string.Trim(self:GetText()))
    end

    local function HeaderButton(text, right, onClick)
        surface.SetFont("ZCity_setiings_tiny")
        local tw = surface.GetTextSize(text)

        local b = vgui.Create('DButton', header)
        b:SetText('')
        b:SetSize(tw + ScreenScale(10), ctlH)
        b:SetPos(right - b:GetWide(), ctlY)
        b.Hov = 0
        b.Paint = function(self, w, h)
            self.Hov = Lerp(math.min(1, RealFrameTime() * 12), self.Hov, self:IsHovered() and 1 or 0)

            surface.SetDrawColor(24 + 20 * self.Hov, 24, 24, 255)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(60 + 132 * self.Hov, 60 - 60 * self.Hov, 60 - 60 * self.Hov, 255)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(text, "ZCity_setiings_tiny", w / 2, h / 2, SetC(255, 255, 255, 150 + 105 * self.Hov), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function()
            surface.PlaySound("shitty/tap_depress.wav")
            onClick()
        end

        return b
    end

    local function SetAllOpen(state)
        for _, cat in ipairs(S.Cats) do
            cat.Open = state
            hg.settings.CatOpen[cat.Name] = state
        end
    end

    local expandBtn = HeaderButton("EXPAND ALL", contentRight - searchW - ScreenScale(5), function() SetAllOpen(true) end)
    HeaderButton("COLLAPSE ALL", expandBtn:GetX() - ScreenScale(4), function() SetAllOpen(false) end)

    Refilter()
    Layout()
end
