--[[
    Fake ragdoll realism (server-side)

    Install: garrysmod/lua/autorun/server/sv_fake_realism.lua
    That folder is always loaded (singleplayer and multiplayer), no matter how Z-City loads
    its own modules. It only uses hooks and touches `hg` at runtime, so load order doesn't matter.
    You should see "[FakeRealism] loaded" in the console when the map starts.

    What it does
      1. Joint friction: every limb is resisted relative to its parent joint (forearm vs
         upper arm, calf vs thigh, head vs chest...), like real joints and muscle tone.
         It scales with consciousness: neck/limbs tense when awake, go limp when out cold.
         Whole-body spin in the air is left alone (angular momentum is conserved IRL).
      2. Brace reflex: a conscious player who is falling puts their hands out toward the
         ground right before impact.
      3. Smooth flailing: replaces the per-tick random-angle jitter at high speed
         (needs the small patch in sv_control.lua that calls hg.FakeFlail).
      4. Limb impacts: per-bone body thuds scaled by impact speed, a view punch for the
         owner, and a short daze on hard head/torso hits.

    Console variables (all replicated + saved; change them from the SERVER console,
    or from the host console on a listen server)
      hg_fake_realism           1    master switch
      hg_fake_realism_damping   1    joint friction multiplier (0 = off, 3 = very stiff)
      hg_fake_realism_brace     1    hands-out reflex when falling
      hg_fake_realism_flail     1    flail strength (0 = no flailing at all)
      hg_fake_realism_impacts   1    limb impact sounds + view punch
      hg_fake_realism_daze      1    stun on hard head/torso impacts

    Diagnostics
      hg_fake_realism_debug     prints module state for every active fake ragdoll
]]

hg = hg or {}

local FLAGS = FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED

local cv_enable  = CreateConVar("hg_fake_realism", "1", FLAGS, "Master switch for the realistic ragdoll tweaks", 0, 1)
local cv_damping = CreateConVar("hg_fake_realism_damping", "1", FLAGS, "Joint friction multiplier (0 = off, 1 = default, 3 = very stiff)", 0, 3)
local cv_brace   = CreateConVar("hg_fake_realism_brace", "1", FLAGS, "Conscious players put their hands out when falling", 0, 1)
local cv_flail   = CreateConVar("hg_fake_realism_flail", "1", FLAGS, "Limb flailing strength at high speed (0 = none)", 0, 3)
local cv_impacts = CreateConVar("hg_fake_realism_impacts", "1", FLAGS, "Per-limb impact sounds and view punch", 0, 1)
local cv_daze    = CreateConVar("hg_fake_realism_daze", "1", FLAGS, "Short stun on hard head/torso impacts", 0, 1)

-- If anything throws, switch the module off once instead of spamming the console every tick.
local failed = false
local function Fail(err)
    if failed then return end
    failed = true
    ErrorNoHalt("[FakeRealism] disabled after an error: " .. tostring(err) .. "\n")
end

local function Enabled()
    return cv_enable:GetBool() and not failed
end

-- ---------------------------------------------------------------------
-- Joint table
--   base   = friction that is always there (skin, tendons, joint friction), per second
--   tone   = extra friction from muscle tone (scaled by consciousness), per second
--   flail  = how much this joint thrashes when flailing
--   role   = used for sounds / arm logic
--   parent = the joint it is attached to (friction is applied relative to it)
-- ---------------------------------------------------------------------
local P = "ValveBiped.Bip01_"
local JOINTS = {
    [P .. "Pelvis"]     = { base = 0.5, tone = 1.0, flail = 0.0,  role = "torso" },
    [P .. "Spine2"]     = { base = 0.7, tone = 1.5, flail = 0.1,  role = "torso", parent = P .. "Pelvis" },
    [P .. "Head1"]      = { base = 0.9, tone = 3.5, flail = 0.25, role = "head",  parent = P .. "Spine2" },
    [P .. "R_UpperArm"] = { base = 0.6, tone = 1.4, flail = 1.0,  role = "arm",   parent = P .. "Spine2" },
    [P .. "L_UpperArm"] = { base = 0.6, tone = 1.4, flail = 1.0,  role = "arm",   parent = P .. "Spine2" },
    [P .. "R_Forearm"]  = { base = 0.6, tone = 1.2, flail = 1.3,  role = "arm",   parent = P .. "R_UpperArm" },
    [P .. "L_Forearm"]  = { base = 0.6, tone = 1.2, flail = 1.3,  role = "arm",   parent = P .. "L_UpperArm" },
    [P .. "R_Hand"]     = { base = 0.4, tone = 0.8, flail = 1.6,  role = "arm",   parent = P .. "R_Forearm" },
    [P .. "L_Hand"]     = { base = 0.4, tone = 0.8, flail = 1.6,  role = "arm",   parent = P .. "L_Forearm" },
    [P .. "R_Thigh"]    = { base = 0.9, tone = 1.8, flail = 0.5,  role = "leg",   parent = P .. "Pelvis" },
    [P .. "L_Thigh"]    = { base = 0.9, tone = 1.8, flail = 0.5,  role = "leg",   parent = P .. "Pelvis" },
    [P .. "R_Calf"]     = { base = 0.8, tone = 1.5, flail = 0.7,  role = "leg",   parent = P .. "R_Thigh" },
    [P .. "L_Calf"]     = { base = 0.8, tone = 1.5, flail = 0.7,  role = "leg",   parent = P .. "L_Thigh" },
    [P .. "R_Foot"]     = { base = 0.6, tone = 1.0, flail = 0.9,  role = "leg",   parent = P .. "R_Calf" },
    [P .. "L_Foot"]     = { base = 0.6, tone = 1.0, flail = 0.9,  role = "leg",   parent = P .. "L_Calf" },
}

-- Strength of joint friction: friction per second = (base + tone * toneAmount) * damping * FRICTION_SCALE
local FRICTION_SCALE = 2.5

-- ---------------------------------------------------------------------
-- Per-ragdoll state
-- ---------------------------------------------------------------------
local NO_ORG = {} -- used if a player has no organism table

local function InitState(rag)
    local st = {
        joints = {},   -- [physIndex] = joint config
        links = {},    -- { child = physIndex, parent = physIndex, j = joint config }
        flail = {},    -- [physIndex] = flail gain
        nextSnd = {},  -- [physIndex] = next time this limb may make an impact sound
        seed = math.Rand(0, 100),
        tone = 0,
        updates = 0,
        lastK = 0,
    }

    local byName = {}

    for i = 0, rag:GetPhysicsObjectCount() - 1 do
        local phys = rag:GetPhysicsObjectNum(i)
        local bone = rag:TranslatePhysBoneToBone(i)

        if IsValid(phys) and bone and bone >= 0 then
            local name = rag:GetBoneName(bone)
            local j = JOINTS[name]

            if j then
                st.joints[i] = j
                byName[name] = i

                if j.flail > 0 then st.flail[i] = j.flail end

                if name == P .. "Pelvis" then st.pelvis = i end
                if name == P .. "L_Hand" then st.lhand = i end
                if name == P .. "R_Hand" then st.rhand = i end
            end
        end
    end

    for name, idx in pairs(byName) do
        local j = JOINTS[name]
        local parentIdx = j.parent and byName[j.parent]

        if parentIdx then
            st.links[#st.links + 1] = { child = idx, parent = parentIdx, j = j }
        end
    end

    rag.hgReal = st
    return st
end

-- 0 = limp, 1 = fully tense
local function GetTone(org, now)
    if org.otrub then return 0 end

    local tone = math.Clamp(tonumber(org.consciousness) or 1, 0, 1)

    if (tonumber(org.stun) or 0) > now or (tonumber(org.lightstun) or 0) > now then
        tone = tone * 0.3
    end

    return tone
end

-- ---------------------------------------------------------------------
-- Joint friction.
-- Damps the relative velocity between each limb and its parent, splitting the
-- change by mass so total momentum is conserved. This resists limbs swinging
-- around their joints without slowing the body's overall motion or spin.
-- ---------------------------------------------------------------------
local function JointFriction(rag, st, tone, armsBusy, dt)
    local mult = cv_damping:GetFloat()
    if mult <= 0 then return end

    -- when thrashing at high speed, ease off so the flailing stays visible
    local flailEase = 1
    local pelvis = st.pelvis and rag:GetPhysicsObjectNum(st.pelvis)
    if IsValid(pelvis) and tone > 0.5 and pelvis:GetVelocity():Length() > 350 then
        flailEase = 0.5
    end

    local lastK = 0

    for _, link in ipairs(st.links) do
        local child = rag:GetPhysicsObjectNum(link.child)
        local parent = rag:GetPhysicsObjectNum(link.parent)

        if IsValid(child) and IsValid(parent) then
            local j = link.j
            local t = tone

            -- don't fight the player's own arm controls
            if armsBusy and j.role == "arm" then t = t * 0.3 end

            local k = (j.base + j.tone * t) * mult * FRICTION_SCALE * flailEase
            local f = math.min(k * dt, 0.35)
            lastK = math.max(lastK, k)

            local mc, mp = child:GetMass(), parent:GetMass()
            local total = mc + mp

            if total > 0 and f > 0 then
                local dv = (child:GetVelocity() - parent:GetVelocity()) * f

                child:AddVelocity(-dv * (mp / total))
                parent:AddVelocity(dv * (mc / total))
            end
        end
    end

    st.lastK = lastK
end

-- ---------------------------------------------------------------------
-- Brace reflex: hands go toward the surface you're about to hit
-- ---------------------------------------------------------------------
local function BraceReflex(ply, rag, org, st, tone)
    if not hg.ShadowControl then return end

    local pelvis = st.pelvis and rag:GetPhysicsObjectNum(st.pelvis)
    local lhand = st.lhand and rag:GetPhysicsObjectNum(st.lhand)
    local rhand = st.rhand and rag:GetPhysicsObjectNum(st.rhand)
    if not (IsValid(pelvis) and IsValid(lhand) and IsValid(rhand)) then return end

    local vel = pelvis:GetVelocity()
    local speed = vel:Length()
    if speed < 180 or vel.z > -80 then return end -- only when actually falling

    local dir = vel / speed
    local pos = pelvis:GetPos()
    local reach = math.Clamp(speed * 0.28, 45, 180)

    local tr = util.TraceLine({
        start = pos,
        endpos = pos + dir * reach,
        filter = { rag, ply },
        mask = MASK_SOLID,
    })

    if not tr.Hit or tr.HitSky then return end

    -- keep the current left/right hand spread, flattened onto the surface
    local normal = tr.HitNormal
    local sep = lhand:GetPos() - rhand:GetPos()
    sep = sep - normal * sep:Dot(normal)

    if sep:LengthSqr() < 1 then
        sep = normal:Cross(vector_up)
        if sep:LengthSqr() < 0.01 then sep = Vector(1, 0, 0) end
    end
    sep:Normalize()

    local base = tr.HitPos + normal * 3

    local lForce = org.larmamputated and 0 or math.max(1 - (tonumber(org.larm) or 0) / 1.3, 0)
    local rForce = org.rarmamputated and 0 or math.max(1 - (tonumber(org.rarm) or 0) / 1.3, 0)

    -- (ragdoll, physNumber, secondsToArrive, ang, maxang, maxangdamp, pos, maxspeed, maxspeeddamp)
    if lForce > 0 and not IsValid(rag.ConsLH) then
        hg.ShadowControl(rag, 5, 0.1, nil, nil, nil, base + sep * 9, 450 * lForce * tone, 40)
    end

    if rForce > 0 and not IsValid(rag.ConsRH) then
        hg.ShadowControl(rag, 7, 0.1, nil, nil, nil, base - sep * 9, 450 * rForce * tone, 40)
    end
end

-- ---------------------------------------------------------------------
-- Main update
-- ---------------------------------------------------------------------
local function Update(ply, rag, now, dt)
    local org = ply.organism
    if type(org) ~= "table" then org = NO_ORG end

    local st = rag.hgReal or InitState(rag)
    local tone = GetTone(org, now)

    st.tone = tone
    st.updates = st.updates + 1

    local armsBusy = ply:KeyDown(IN_ATTACK) or ply:KeyDown(IN_ATTACK2) or ply:KeyDown(IN_USE)
    JointFriction(rag, st, tone, armsBusy, dt)

    if cv_brace:GetBool() and tone > 0.25 then
        BraceReflex(ply, rag, org, st, tone)
    end
end

-- Corpses keep joint friction too (dead weight, zero muscle tone)
local corpses = setmetatable({}, { __mode = "k" })

local function CorpseUpdate(rag, dt)
    local st = rag.hgReal
    if not st then return end

    local pelvis = st.pelvis and rag:GetPhysicsObjectNum(st.pelvis)
    if not IsValid(pelvis) or pelvis:IsAsleep() then return end

    JointFriction(rag, st, 0, false, dt)
end

hook.Add("Think", "hg_fake_realism", function()
    if not Enabled() then return end

    local now = CurTime()
    local dt = math.Clamp(FrameTime(), 0.001, 0.05)

    if hg.ragdollFake then
        for ply, rag in pairs(hg.ragdollFake) do
            if IsValid(ply) and IsValid(rag) and ply:Alive() then
                local ok, err = pcall(Update, ply, rag, now, dt)

                if not ok then
                    Fail(err)
                    return
                end
            end
        end
    end

    for rag in pairs(corpses) do
        if not IsValid(rag) then
            corpses[rag] = nil
        else
            local ok, err = pcall(CorpseUpdate, rag, dt)

            if not ok then
                Fail(err)
                return
            end
        end
    end
end)

-- Build the joint state as soon as a ragdoll exists
hook.Add("Ragdoll_Create", "hg_fake_realism", function(ply, rag)
    if not Enabled() or not IsValid(rag) then return end

    local ok, err = pcall(function()
        InitState(rag)

        if not (IsValid(ply) and ply:Alive()) then
            corpses[rag] = true
        end
    end)

    if not ok then Fail(err) end
end)

-- ---------------------------------------------------------------------
-- Smooth flailing. Called from sv_control.lua in place of the old
-- AngleRand() jitter. Returns true when it handled the flailing.
-- ---------------------------------------------------------------------
function hg.FakeFlail(rag, org, vellen)
    if not Enabled() then return false end

    local strength = cv_flail:GetFloat()
    if strength <= 0 then return true end

    local ok, err = pcall(function()
        local st = rag.hgReal or InitState(rag)

        local speedMul = math.Clamp((vellen - 350) / 750, 0, 1)
        local cons = math.Clamp(tonumber(org.consciousness) or 1, 0, 1)
        local amp = 700 * strength * speedMul * cons * (rag.dtime or 0.015)
        local t = CurTime() + st.seed

        for i, gain in pairs(st.flail) do
            local phys = rag:GetPhysicsObjectNum(i)

            if IsValid(phys) then
                local ph = i * 1.93

                phys:AddAngleVelocity(Vector(
                    math.sin(t * 5.1 + ph),
                    math.sin(t * 4.3 + ph * 1.7),
                    math.sin(t * 6.2 + ph * 0.6)
                ) * (amp * gain))
            end
        end
    end)

    if not ok then
        Fail(err)
        return false
    end

    return true
end

-- ---------------------------------------------------------------------
-- Limb impacts. The collision callback itself only reads data; everything
-- that touches the world is deferred a tick (physics callbacks are not
-- a safe place to change entities).
-- ---------------------------------------------------------------------
hook.Add("Ragdoll Collide", "hg_fake_realism_impacts", function(rag, data)
    if not Enabled() or not cv_impacts:GetBool() then return end
    if not IsValid(rag) then return end

    local he = data.HitEntity
    if not (IsValid(he) or he == game.GetWorld()) then return end

    local st = rag.hgReal
    if not st then return end

    local impact = math.abs((data.OurOldVelocity - data.TheirOldVelocity):Dot(data.HitNormal))
    if impact < 120 then return end

    local idx
    for i = 0, rag:GetPhysicsObjectCount() - 1 do
        if rag:GetPhysicsObjectNum(i) == data.PhysObject then
            idx = i
            break
        end
    end

    local j = idx and st.joints[idx]
    if not j then return end

    local now = CurTime()
    if (st.nextSnd[idx] or 0) > now then return end
    st.nextSnd[idx] = now + 0.15

    local pos = Vector(data.HitPos)
    local role = j.role

    timer.Simple(0, function()
        if not IsValid(rag) then return end

        local ok, err = pcall(function()
            -- thud: harder/deeper for head and torso, softer for limbs
            local vol = math.Clamp(impact / 500, 0.2, 1)
            local snd

            if role == "head" or role == "torso" then
                snd = string.format("physics/body/body_medium_impact_hard%d.wav", math.random(1, 6))
            else
                snd = string.format("physics/body/body_medium_impact_soft%d.wav", math.random(1, 7))
            end

            local pitch = (role == "torso" and 92) or (role == "head" and 105) or (role == "leg" and 100) or 110
            sound.Play(snd, pos, 55 + 25 * vol, pitch + math.random(-5, 5), vol)

            -- owner reactions
            local ply = rag:GetNWEntity("ply")
            if not (IsValid(ply) and ply:IsPlayer() and ply:Alive()) then return end

            local org = ply.organism
            if type(org) ~= "table" or org.otrub then return end

            local t = CurTime()

            if impact > 250 and (ply.hgRealNextPunch or 0) < t then
                ply.hgRealNextPunch = t + 0.3

                local k = math.Clamp(impact / 60, 2, 14)
                ply:ViewPunch(Angle(math.Rand(-1, 1) * k, math.Rand(-1, 1) * k, math.Rand(-1, 1) * k))
            end

            local hardHit = (role == "head" and impact > 500) or (role == "torso" and impact > 650)

            if cv_daze:GetBool() and hardHit and hg.LightStunPlayer and (ply.hgRealNextDaze or 0) < t then
                ply.hgRealNextDaze = t + 2.5
                hg.LightStunPlayer(ply, math.Clamp(impact / 500, 0.8, 3))
            end
        end)

        if not ok then Fail(err) end
    end)
end)

-- ---------------------------------------------------------------------
-- Diagnostics: run `hg_fake_realism_debug` (server console, or as superadmin)
-- while a player is in fake/ragdoll mode.
-- ---------------------------------------------------------------------
concommand.Add("hg_fake_realism_debug", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local function out(s)
        if IsValid(ply) then
            ply:PrintMessage(HUD_PRINTCONSOLE, s .. "\n")
        else
            print(s)
        end
    end

    out(string.format("[FakeRealism] enabled=%s failed=%s damping=%.2f brace=%s flail=%.2f",
        tostring(cv_enable:GetBool()), tostring(failed), cv_damping:GetFloat(),
        tostring(cv_brace:GetBool()), cv_flail:GetFloat()))

    local n = 0
    for p, rag in pairs(hg.ragdollFake or {}) do
        if IsValid(p) then
            n = n + 1
            local st = IsValid(rag) and rag.hgReal

            out(string.format("  %s: ragdoll=%s state=%s links=%d tone=%.2f updates=%d peakFrictionPerSec=%.2f",
                p:Nick(), tostring(IsValid(rag)), tostring(st ~= nil and st ~= false),
                st and #st.links or 0, st and st.tone or -1, st and st.updates or 0, st and st.lastK or 0))
        end
    end

    if n == 0 then
        out("  no active fake ragdolls (go into fake mode with the 'fake' command first)")
    end
end)

-- ---------------------------------------------------------------------
-- Z-City may rebuild the `hg` table after autorun files have loaded, which would drop
-- hg.FakeFlail. Keep the hook point alive (sv_control.lua falls back to the old jitter
-- if it is missing, so this is just insurance).
-- ---------------------------------------------------------------------
local flailFn = hg.FakeFlail

hook.Add("Think", "hg_fake_realism_reassert", function()
    if hg.FakeFlail ~= flailFn then
        hg.FakeFlail = flailFn
    end
end)

print("[FakeRealism] loaded")
