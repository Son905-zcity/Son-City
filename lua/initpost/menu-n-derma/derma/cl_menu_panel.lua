local PANEL = {}
local curent_panel
local red_select = Color(192,0,0)

DISCORD_URL = "https://discord.gg/475EmEdTgH"

-- =====================================================================
-- Visual effects: set any of these to false (or 0) to turn it off
-- =====================================================================
local FX = {
    Embers      = 70,   -- floating embers (0 = off)
    MouseGlow   = true, -- red light that trails your cursor
    Scanlines   = true, -- CRT lines over the background
    ScanBeam    = true, -- slow light beam sweeping down the screen
    Vignette    = true, -- dark edges
    TitleGlitch = true, -- Z-City title glitches every few seconds
    StatusBar   = true, -- clock / ping / fps / players, top-left
    SideLine    = true, -- glowing divider with a traveling pulse
}

local glow_mat   = Material("sprites/light_glow02_add")
local gradient_d = surface.GetTextureID("vgui/gradient-d")
local gradient_l = surface.GetTextureID("vgui/gradient-l")

local Selects = {
    {Title = "Disconnect", Func = function(luaMenu) RunConsoleCommand("disconnect") end},
    {Title = "Main Menu", Func = function(luaMenu) gui.ActivateGameUI() luaMenu:Close() end},
    {Title = "Discord", Func = function(luaMenu) luaMenu:Close() gui.OpenURL(DISCORD_URL)  end},
    {Title = "Traitor Role",
    GamemodeOnly = true,
    CreatedFunc = function(self, parent, luaMenu)
        local btn = vgui.Create( "DLabel", self )
        btn:SetText( "SOE" )
        btn:SetMouseInputEnabled( true )
        btn:SizeToContents()
        btn:SetFont( "ZCity_Small" )
        btn:SetTall( ScreenScale( 15 ) )
        btn:Dock(BOTTOM)
        btn:DockMargin(ScreenScale(20),ScreenScale(10),0,0)
        btn:SetTextColor(Color(255,255,255))
        btn:InvalidateParent()
        btn.RColor = Color(225, 225, 225, 0)
        btn.WColor = Color(225, 225, 225, 255)
        btn.x = btn:GetX()

        function btn:DoClick()
            luaMenu:Close()
            hg.SelectPlayerRole(nil, "soe")
        end

        local selfa = self
        function btn:Think()
            self.HoverLerp = selfa.HoverLerp
            self.HoverLerp2 = LerpFT(0.2, self.HoverLerp2 or 0, self:IsHovered() and 1 or 0)

            self:SetTextColor(self.RColor:Lerp(self.WColor:Lerp(red_select, self.HoverLerp2), self.HoverLerp))
            self:SetX(self.x + ScreenScaleH(40) + self.HoverLerp * ScreenScaleH(50))
        end

        local btn = vgui.Create( "DLabel", btn )
        btn:SetText( "STD" )
        btn:SetMouseInputEnabled( true )
        btn:SizeToContents()
        btn:SetFont( "ZCity_Small" )
        btn:SetTall( ScreenScale( 15 ) )
        btn:Dock(BOTTOM)
        btn:DockMargin(0,ScreenScale(2),0,0)
        btn:SetTextColor(Color(255,255,255))
        btn:InvalidateParent()
        btn.RColor = Color(225, 225, 225, 0)
        btn.WColor = Color(225, 225, 225, 255)
        btn.x = btn:GetX()

        function btn:DoClick()
            luaMenu:Close()
            hg.SelectPlayerRole(nil, "standard")
        end

        function btn:Think()
            self.HoverLerp = selfa.HoverLerp
            self.HoverLerp2 = LerpFT(0.2, self.HoverLerp2 or 0, self:IsHovered() and 1 or 0)

            self:SetTextColor(self.RColor:Lerp(self.WColor:Lerp(red_select, self.HoverLerp2), self.HoverLerp))
            self:SetX(self.x + ScreenScaleH(35))
        end
    end,
    Func = function(luaMenu)

    end,
    },
    {Title = "Achievements", Func = function(luaMenu,pp)
        hg.DrawAchievmentsMenu(pp)
    end},
    {Title = "Settings", Func = function(luaMenu,pp)
        hg.DrawSettings(pp)
    end},
    {Title = "Appearance", Func = function(luaMenu,pp) hg.CreateApperanceMenu(pp) end},
    {Title = "Return", Func = function(luaMenu) luaMenu:Close() end},
}

local splasheh = {
    'LIKE HOMICIDED',
    'PLUV PLUV PLUVISKI',
    'LULU IS NOT DEAD | !PLUV',
    'THE TRAITOR WAS KILLED',
    'NAB HOMICIDE SERVER',
    'ALSO TRY MODDED HOMICIDE 2',
    'HOP ON Z-CITY',
    'JOHN Z-CITY',
    ':pluvrare:',
    'SAW51 IS REAL',
    'MORE SMALLTOWN',
    'MORE CLUE2022',
    'BACKROOMS == CLUE',
    'HELL IS NEAR',
    'I WISH YOU GOOD HEALTH, JASON STATHAM'
}

surface.CreateFont("ZC_MM_Title", {
    font = "Bahnschrift",
    size = ScreenScale(40),
    weight = 800,
    antialias = true
})

local Pluv = Material("pluv/pluvkid.jpg")

local color_red    = Color(255,25,25,45)
local clr_gray     = Color(255,255,255,25)
local clr_verygray = Color(10,10,19,235)
local clr_1        = Color(102,0,0,35)
local clr_status   = Color(255,255,255,75)

-- =====================================================================
-- Helpers
-- =====================================================================

local function NewEmber(randomY)
    local sc = ScrH() / 1080
    return {
        x = math.random(0, ScrW()),
        y = randomY and math.random(0, ScrH()) or (ScrH() + 20 * sc),
        speed = math.Rand(25, 95) * sc,
        size = math.Rand(8, 26) * sc,
        drift = math.Rand(-14, 14) * sc,
        alpha = math.Rand(40, 150),
        phase = math.Rand(0, math.pi * 2),
    }
end

-- Fades the current right-hand panel out, builds a fresh empty one,
-- fades it in, then calls after(newPanel).
local function RebuildRightPanel(luaMenu, after)
    local old = luaMenu.panelparrent
    if not IsValid(old) then return end

    local x, w, h = old:GetX(), old:GetWide(), old:GetTall()

    old:AlphaTo(0, 0.2, 0, function()
        if not IsValid(luaMenu) then return end
        if IsValid(old) then old:Remove() end

        local pnl = vgui.Create("DPanel", luaMenu)
        pnl:SetPos(x, 0)
        pnl:SetSize(w, h)
        pnl.Paint = function(this, pw, ph) end
        pnl:SetAlpha(0)
        pnl:AlphaTo(255, 0.25, 0)
        luaMenu.panelparrent = pnl

        if after then after(pnl) end
    end)
end

local function DrawStatus(self, ct, sc)
    local ply = LocalPlayer()
    local ping = IsValid(ply) and ply:Ping() or 0
    local x, y = ScreenScale(15), ScreenScale(10)

    surface.SetFont("ZCity_Tiny")
    local _, th = surface.GetTextSize("A")
    th = th + 2

    local dot = math.max(5, 6 * sc)
    local blink = (math.sin(ct * 4) + 1) * 0.5
    draw.NoTexture()
    surface.SetDrawColor(192, 0, 0, 80 + 175 * blink)
    surface.DrawRect(x, y + (th - dot) / 2, dot, dot)

    local tx = x + dot + 10 * sc
    draw.SimpleText(os.date("%H:%M:%S"), "ZCity_Tiny", tx, y, clr_status, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(string.format("PING %d   FPS %d", ping, math.floor(self.SmoothFPS)), "ZCity_Tiny", tx, y + th, clr_status, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(string.format("PLAYERS %d/%d", #player.GetAll(), game.MaxPlayers()), "ZCity_Tiny", tx, y + th * 2, clr_status, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

-- =====================================================================
-- Panel
-- =====================================================================

function PANEL:InitializeMarkup()
	local mapname = game.GetMap()
	local prefix = string.find(mapname, "_")
	if prefix then
		mapname = string.sub(mapname, prefix + 1)
	end
	local gm = splasheh[math.random(#splasheh)] .. " | " .. string.NiceName(mapname)

    if hg.PluvTown.Active then
        local text = "<font=ZC_MM_Title><colour=199,2,2>    </colour>City</font>\n<font=ZCity_Tiny><colour=105,105,105>" .. gm .. "</colour></font>"

        self.SelectedPluv = table.Random(hg.PluvTown.PluvMats)

        return markup.Parse(text)
    end

    local text = "<font=ZC_MM_Title><colour=199,2,2,255>Z</colour>-City</font>\n<font=ZCity_Tiny><colour=105,105,105>" .. gm .. "</colour></font>"
    return markup.Parse(text)
end

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("")
    self:SetDraggable(false)
    self:SetBorder(false)
    self:SetColorBG(clr_verygray)
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    curent_panel = nil
    self.Title, self.TitleShadow = self:InitializeMarkup()

    -- RealTime is used everywhere (not CurTime) so the animations keep
    -- running while the game is paused in singleplayer.
    self.OpenTime = RealTime()
    self.SmoothFPS = 60

    self.Embers = {}
    for i = 1, FX.Embers do
        self.Embers[i] = NewEmber(true)
    end

    timer.Simple(0, function()
        if IsValid(self) and self.First then
            self:First()
        end
    end)

    self.lDock = vgui.Create("DPanel", self)
    local lDock = self.lDock
    lDock:Dock(LEFT)
    lDock:SetSize(ScrW() / 4, ScrH())
    lDock:DockMargin(ScreenScale(0), ScreenScaleH(90), ScreenScale(10), ScreenScaleH(90))
    lDock.Paint = function(this, w, h)
        local ct = RealTime()
        local sc = ScrH() / 1080

        -- Button indicators (bar + hover wash), drawn behind the labels
        draw.NoTexture()
        for _, b in ipairs(self.Buttons) do
            if IsValid(b) then
                local bx, by = b:GetPos()
                local bw, bh = b:GetSize()
                local v = b.HoverLerp or 0
                local active = (b.TitleKey == curent_panel) and 0.85 or 0
                local a = math.max(v, active) * (b:GetAlpha() / 255)

                if a > 0.01 then
                    local barH = bh * 0.8 * a
                    local off = ScreenScale(8)

                    surface.SetDrawColor(192, 0, 0, 30 * a)
                    surface.DrawRect(bx - off, by, bw + off * 2 + v * ScreenScale(24), bh)

                    surface.SetDrawColor(220, 20, 20, 255 * a)
                    surface.DrawRect(bx - off, by + (bh - barH) / 2, math.max(2, ScreenScale(1.5)), barH)
                end
            end
        end

        if hg.PluvTown.Active then
            surface.SetDrawColor(color_white)
            surface.SetMaterial(self.SelectedPluv or Pluv)
            surface.DrawTexturedRect(0, ScreenScale(27), ScreenScale(35), ScreenScale(27))
        end

        local tx, ty = ScreenScale(15), ScreenScale(50)

        -- Title glitch
        if FX.TitleGlitch then
            self.NextGlitch = self.NextGlitch or (ct + math.Rand(2, 4))

            if ct >= self.NextGlitch then
                self.GlitchUntil = ct + math.Rand(0.08, 0.22)
                self.NextGlitch = ct + math.Rand(3, 7)
            end

            if self.GlitchUntil and ct < self.GlitchUntil then
                local ox = math.random(-8, 8) * math.max(sc, 0.6)
                self.Title:Draw(tx + ox, ty + math.random(-3, 3), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 110, TEXT_ALIGN_LEFT)
                self.Title:Draw(tx - ox, ty + math.random(-3, 3), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 110, TEXT_ALIGN_LEFT)
            end
        end

        self.Title:Draw(tx, ty, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 255, TEXT_ALIGN_LEFT)

        -- Red underline that grows in when the menu opens
        local t = math.Clamp((ct - self.OpenTime) / 0.9, 0, 1)
        local ease = 1 - (1 - t) ^ 3
        local ly = ty + self.Title:GetHeight() / 2 + ScreenScale(2)
        draw.NoTexture()
        surface.SetDrawColor(192, 0, 0, 255)
        surface.DrawRect(tx, ly, self.Title:GetWidth() * ease, math.max(2, 2 * sc))
    end

    self.Buttons = {}
    for k, v in ipairs(Selects) do
        if v.GamemodeOnly and engine.ActiveGamemode() != "soncity" then continue end
        self:AddSelect(lDock, v.Title, v)
    end


    local bottomDock = vgui.Create("DPanel", self)
    bottomDock:SetPos(ScreenScale(1), ScrH() - ScrH()/10)
    bottomDock:SetSize(ScreenScale(190), ScreenScaleH(40))
    bottomDock.Paint = function(this, w, h) end
    self.panelparrent = vgui.Create("DPanel", self)
    self.panelparrent:SetPos(bottomDock:GetWide()+bottomDock:GetX(), 0)
    self.panelparrent:SetSize(ScrW() - bottomDock:GetWide()*1, ScrH())
    self.panelparrent.Paint = function(this, w, h) end

    local git = vgui.Create("DLabel", bottomDock)
    git:Dock(BOTTOM)
    git:DockMargin(ScreenScale(10), 0, 0, 0)
    git:SetFont("ZCity_Tiny")
    git:SetTextColor(clr_gray)
    git:SetText("GitHub: github.com/" .. hg.GitHub_ReposOwner .. "/" .. hg.GitHub_ReposName)
    git:SetContentAlignment(4)
    git:SetMouseInputEnabled(true)
    git:SizeToContents()

    function git:DoClick()
        gui.OpenURL("https://github.com/" .. hg.GitHub_ReposOwner .. "/" .. hg.GitHub_ReposName)
    end

    local version = vgui.Create("DLabel", bottomDock)
    version:Dock(BOTTOM)
    version:DockMargin(ScreenScale(10), 0, 0, 0)
    version:SetFont("ZCity_Tiny")
    version:SetTextColor(clr_gray)
    version:SetText(hg.Version)
    version:SetContentAlignment(4)
    version:SizeToContents()

    local zteam = vgui.Create("DLabel", bottomDock)
    zteam:Dock(BOTTOM)
    zteam:DockMargin(ScreenScale(10), 0, 0, 0)
    zteam:SetFont("ZCity_Tiny")
    zteam:SetTextColor(clr_gray)
    zteam:SetText("Authors: uzelezz, Sadsalat, \nMr.Point, Zac90, Deka, Mannytko")
    zteam:SetContentAlignment(4)
    zteam:SizeToContents()
end

function PANEL:First( ply )
    self:AlphaTo( 255, 0.1, 0, nil )
end

function PANEL:Paint(w,h)
    local ct = RealTime()
    local dt = RealFrameTime()
    local sc = h / 1080

    -- Original background
    draw.RoundedBox( 0, 0, 0, w, h, self.ColorBG )
    hg.DrawBlur(self, 5)
    surface.SetDrawColor( self.ColorBG )
    surface.SetTexture( gradient_l )
    surface.DrawTexturedRect(0,0,w,h)
    surface.SetDrawColor( clr_1 )
    surface.SetTexture( gradient_d )
    surface.DrawTexturedRect(0,0,w,h)

    self.SmoothFPS = Lerp(math.min(1, dt * 4), self.SmoothFPS, 1 / math.max(dt, 0.0001))

    -- Floating embers
    if self.Embers and #self.Embers > 0 then
        surface.SetMaterial(glow_mat)
        for _, e in ipairs(self.Embers) do
            e.y = e.y - e.speed * dt
            e.x = e.x + (e.drift + math.sin(ct + e.phase) * 12 * sc) * dt

            if e.y < -e.size then
                for k, v in pairs(NewEmber(false)) do e[k] = v end
            end

            local fade = math.Clamp(e.y / (h * 0.3), 0, 1)
            local flicker = 0.7 + 0.3 * math.sin(ct * 3 + e.phase)
            surface.SetDrawColor(230, 30, 20, e.alpha * fade * flicker)
            surface.DrawTexturedRect(e.x - e.size / 2, e.y - e.size / 2, e.size, e.size)
        end
    end

    -- Cursor glow (trails slightly behind the mouse)
    if FX.MouseGlow then
        local mx, my = self:CursorPos()
        self.GlowX = Lerp(math.min(1, dt * 8), self.GlowX or mx, mx)
        self.GlowY = Lerp(math.min(1, dt * 8), self.GlowY or my, my)

        local s = 520 * sc
        surface.SetMaterial(glow_mat)
        surface.SetDrawColor(200, 10, 10, 38)
        surface.DrawTexturedRect(self.GlowX - s / 2, self.GlowY - s / 2, s, s)
    end

    draw.NoTexture()

    -- Scanlines
    if FX.Scanlines then
        surface.SetDrawColor(0, 0, 0, 38)
        local step = math.max(3, math.floor(4 * sc))
        for y = 0, h, step do
            surface.DrawRect(0, y, w, 1)
        end
    end

    -- Sweeping scan beam
    if FX.ScanBeam then
        local by = ((ct * 0.12) % 1.2 - 0.1) * h
        for i = 0, 11 do
            surface.SetDrawColor(255, 40, 40, 10 * (1 - i / 12))
            surface.DrawRect(0, by + i * 3 * sc, w, math.max(2, 3 * sc))
            surface.DrawRect(0, by - i * 3 * sc, w, math.max(2, 3 * sc))
        end
    end

    -- Glowing divider with a traveling pulse
    if FX.SideLine then
        local lx = ScreenScale(190) - ScreenScale(4)
        local top, bot = ScreenScaleH(90), h - ScreenScaleH(90)
        local lw = math.max(1, 2 * sc)

        surface.SetDrawColor(192, 0, 0, 45)
        surface.DrawRect(lx, top, lw, bot - top)

        local seg = 220 * sc
        local py = top + ((ct * 0.25) % 1) * (bot - top - seg)
        for i = 0, 15 do
            local f = math.sin((i / 15) * math.pi)
            surface.SetDrawColor(255, 40, 40, 200 * f)
            surface.DrawRect(lx, py + i * seg / 16, lw, seg / 16 + 1)
        end
    end

    -- Vignette
    if FX.Vignette then
        local steps, thick = 14, math.max(4, 8 * sc)
        for i = 0, steps - 1 do
            surface.SetDrawColor(0, 0, 0, 120 * (1 - i / steps) ^ 2)
            surface.DrawOutlinedRect(i * thick, i * thick, w - i * thick * 2, h - i * thick * 2, thick)
        end
    end

    if FX.StatusBar then
        DrawStatus(self, ct, sc)
    end
end

function PANEL:AddSelect( pParent, strTitle, tbl )
    local id = #self.Buttons + 1
    self.Buttons[id] = vgui.Create( "DLabel", pParent )
    local btn = self.Buttons[id]
    btn:SetText( strTitle )
    btn:SetMouseInputEnabled( true )
    btn:SizeToContents()
    btn:SetFont( "ZCity_Small" )
    btn:SetTall( ScreenScale( 15 ) )
    btn:Dock(BOTTOM)
    btn:DockMargin(ScreenScale(15),ScreenScale(1.5),0,0)
    btn.Func = tbl.Func
    btn.HoveredFunc = tbl.HoveredFunc
    btn.TitleKey = string.lower(strTitle)
    local luaMenu = self
    if tbl.CreatedFunc then tbl.CreatedFunc(btn, self, luaMenu) end
    btn.RColor = Color(225,225,225)

    -- Staggered fade-in: top button first, then down the list
    btn:SetAlpha(0)
    btn:AlphaTo(255, 0.3, 0.05 * math.max(0, #Selects - id), nil)

    function btn:DoClick()
        if curent_panel == self.TitleKey then
            RebuildRightPanel(luaMenu, function()
                curent_panel = nil
            end)
			for i = 1, 3 do
				surface.PlaySound("shitty/tap_release.wav")
			end
            return
        end

        RebuildRightPanel(luaMenu, function(pnl)
            btn.Func(luaMenu, pnl)
            curent_panel = btn.TitleKey
        end)
		for i = 1, 3 do
			surface.PlaySound("shitty/tap_depress.wav")
		end
    end

    function btn:Think()
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, (self:IsHovered() or (IsValid(self:GetChild(0)) and self:GetChild(0):IsHovered()) or (IsValid(self:GetChild(0)) and IsValid(self:GetChild(0):GetChild(0)) and self:GetChild(0):GetChild(0):IsHovered())) and 1 or 0)

        local v = self.HoverLerp
        self:SetTextColor(self.RColor:Lerp(red_select, v))

        local targetText = (self:IsHovered()) and string.upper(strTitle) or strTitle
        local crw = self:GetText()

        if (crw ~= targetText) or (curent_panel == self.TitleKey) then
            local ntxt = ""
            -- (fixed) was `not strTitle == 'Traitor Role'`, which is always false
            local will_text = (curent_panel == self.TitleKey and strTitle ~= 'Traitor Role') and '[ '..string.upper(strTitle)..' ]' or strTitle
            for i = 1, #will_text do
                local char = will_text:sub(i, i)
                if i <= math.ceil(#will_text * v) then
                    ntxt = ntxt .. string.upper(char)
                else
                    ntxt = ntxt .. char
                end
            end
			if self:GetText() ~= ntxt then
				surface.PlaySound("shitty/tap-resonant.wav")
			end
            self:SetText(ntxt)
        end
        self:SizeToContents()
    end
end

function PANEL:Close()
    if self.Closing then return end
    self.Closing = true
    self:AlphaTo( 0, 0.1, 0, function() if IsValid(self) then self:Remove() end end)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register( "ZMainMenu", PANEL, "ZFrame")

hook.Add("OnPauseMenuShow","OpenMainMenu",function()
    local run = hook.Run("OnShowZCityPause")
    if run != nil then
        return run
    end

    if MainMenu and IsValid(MainMenu) then
        MainMenu:Close()
        MainMenu = nil
        return false
    end

    MainMenu = vgui.Create("ZMainMenu")
    MainMenu:MakePopup()
    return false
end)
