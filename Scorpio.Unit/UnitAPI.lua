--========================================================--
--                Scorpio UnitFrame API                   --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/11/25                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Secure.UnitFrame.API"     "1.0.0"
--========================================================--

namespace "Scorpio.Secure.UnitFrame"

import "System.Reactive"

--- The aura filters
__Sealed__() enum "AuraFilter" { "HELPFUL", "HARMFUL", "PLAYER", "RAID", "CANCELABLE", "NOT_CANCELABLE", "INCLUDE_NAME_PLATE_ONLY" }

------------------------------------------------------------
--                    Simple Unit API                     --
------------------------------------------------------------
local MANA                      = _G.Enum.PowerType.Mana

__Static__() __AutoCache__()
function Wow.UnitName(withServer)
    return Wow.FromUnitEvent("UNIT_NAME_UPDATE"):Map(withServer and function(unit) return GetUnitName(unit, true) end or GetUnitName)
end

__Static__() __AutoCache__()
function Wow.UnitColor()
    return Wow.FromUnitEvent("UNIT_NAME_UPDATE"):Map(function(unit)
        local _, cls            = UnitClass(unit)
        return Color[cls or "PALADIN"]
    end)
end

__Static__() __AutoCache__()
function Wow.UnitExtendColor(withThreat)
    local scolor                = { r = 1, g = 1, b = 1 }
    return Wow.FromUnitEvents("UNIT_FACTION", "UNIT_THREAT_SITUATION_UPDATE"):Map(function(unit)
        if not UnitIsPlayer(unit) then
            if UnitIsTapDenied(unit) then return Color.RUNES end

            if withThreat and UnitCanAttack("player", unit) then
                local threat    = UnitThreatSituation("player", unit)
                if threat and threat > 0 then
                    return GetThreatStatusColor(threat)
                end
            end

            local r,g,b         = UnitSelectionColor(unit, true)
            scolor.r            = r or 1
            scolor.g            = g or 1
            scolor.b            = b or 1
            return scolor
        end
        local _, cls            = UnitClass(unit)
        return Color[cls or "PALADIN"]
    end)
end

-- Unit Level API
__Static__()
function Wow.UnitLevel(format)
    format                      = format or "%s"
    local unknownFormat         = format:gsub("%%%w+", "%%s")
    return Wow.FromUnitEvent(Wow.FromEvent("PLAYER_LEVEL_UP"):Map(function(level) return "player", level end))
        :Map(function(unit, level)
            level               = level or UnitLevel(unit)
            if level and level > 0 then
                if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
                    level       = UnitBattlePetLevel(unit)
                end
                return strformat(format, level)
            else
                return strformat(unknownFormat, "???")
            end
        end)
end

__Static__() __Arguments__{ ColorType/nil }
function Wow.UnitLevelColor(default)
    return Wow.FromUnitEvent(Wow.FromEvent("PLAYER_LEVEL_UP"):Map(function(level) return "player", level end))
        :Map(function(unit, level)
            if not level and UnitCanAttack("player", unit) then
                return GetQuestDifficultyColor(UnitLevel(unit) or 99)
            end
            return default or Color.NORMAL
        end)
end

-- Unit Health API
__Static__() __AutoCache__()
function Wow.UnitHealth()
    return Wow.FromUnitEvents("UNIT_HEALTH", "UNIT_MAXHEALTH"):Map(UnitHealth)
end

__Static__() __AutoCache__()
function Wow.UnitHealthMax()
    local minMax                = { min = 0 }
    return Wow.FromUnitEvent("UNIT_MAXHEALTH"):Map(function(unit)
            minMax.max          = UnitHealthMax(unit) or 100
            return minMax
        end)
end

__Static__() __AutoCache__()
function Wow.UnitHealthPercent()
    return Wow.FromUnitEvents("UNIT_HEALTH", "UNIT_MAXHEALTH"):Map(function(unit)
            local health        = UnitHealth(unit)
            local max           = UnitHealthMax(unit)

            return floor(0.5 + (health and max and health / max * 100) or 0)
        end)
end

-- Unit Power API
__Static__() __AutoCache__()
function Wow.UnitPower(frequent)
    return Wow.FromUnitEvents(frequent and "UNIT_POWER_FREQUENT" or "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_POWER_BAR_SHOW", "UNIT_POWER_BAR_HIDE")
        :Map(function(unit) return UnitPower(unit, (UnitPowerType(unit))) end)
end

__Static__() __AutoCache__()
function Wow.UnitPowerMax()
    local minMax                = { min = 0 }
    return Wow.FromUnitEvents("UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_POWER_BAR_SHOW", "UNIT_POWER_BAR_HIDE")
        :Map(function(unit) minMax.max =  UnitPowerMax(unit, (UnitPowerType(unit))) return minMax end)
end

__Static__() __AutoCache__()
function Wow.UnitPowerColor()
    local scolor                = { r = 1, g = 1, b = 1, a = 1 }
    return Wow.FromUnitEvents("UNIT_CONNECTION", "UNIT_DISPLAYPOWER", "UNIT_POWER_BAR_SHOW", "UNIT_POWER_BAR_HIDE")
        :Map(function(unit)
            if not UnitIsConnected(unit) then
                scolor.r        = 0.5
                scolor.g        = 0.5
                scolor.b        = 0.5
            else
                local ptype, ptoken, r, g, b = UnitPowerType(unit)
                local color     = Color[ptoken]
                if color then return color end

                if r then
                    scolor.r    = r
                    scolor.g    = g
                    scolor.b    = b
                else
                    return Color.MANA
                end
            end

            return scolor
        end)
end

__Static__() __AutoCache__()
function Wow.UnitMana()
    return Wow.FromUnitEvents("UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_POWER_BAR_SHOW", "UNIT_POWER_BAR_HIDE")
        :Map(function(unit) return UnitPower(unit, MANA) end)
end

__Static__() __AutoCache__()
function Wow.UnitManaMax()
    local minMax                = { min = 0 }
    return Wow.FromUnitEvents("UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_POWER_BAR_SHOW", "UNIT_POWER_BAR_HIDE")
        :Map(function(unit) minMax.max =  UnitPowerMax(unit, MANA) return minMax end)
end

__Static__() __AutoCache__()
function Wow.UnitManaVisible()
    return Wow.FromUnitEvents("UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_POWER_BAR_SHOW", "UNIT_POWER_BAR_HIDE")
        :Map(function(unit) return UnitPowerType(unit) ~= MANA and (UnitPowerMax(unit, MANA) or 0) > 0 end)
end

-- The Aura API
__Static__() __Arguments__{ AuraFilter * 0 }
function Wow.UnitAura(...)
    local filter            = select("#", ...) > 0 and List{ ... }:Join("|") or "HELPFUL"
    return Wow.FromUnitEvents("UNIT_AURA"):Map(function(unit)

    end)
end

-- Unit State API
__Static__() __AutoCache__()
function Wow.UnitIsDisconnected()
    return Wow.FromUnitEvents("UNIT_HEALTH", "UNIT_CONNECTION"):Map(function(unit) return not UnitIsConnected(unit) end)
end

__Static__() __AutoCache__()
function Wow.UnitIsTarget()
    return Wow.FromUnitEvent(Wow.FromEvent("PLAYER_TARGET_CHANGED"):Map("=>'any'")):Map(function(unit) return UnitIsUnit(unit, "target") end)
end

__Static__() __AutoCache__()
function Wow.UnitIsPlayer()
    return Wow.FromUnitEvent("UNIT_NAME_UPDATE"):Map(function(unit) return UnitIsUnit(unit, "player") end)
end

__Static__() __AutoCache__()
function Wow.PlayerInCombat()
    return Wow.FromUnitEvent(Wow.FromEvents("PLAYER_ENTER_COMBAT", "PLAYER_LEAVE_COMBAT"):Map("=>'player'")):Map(function(unit) return UnitAffectingCombat("player") end)
end

__Static__() __AutoCache__()
function Wow.UnitIsResurrect()
    local subject               = Subject()

    Wow.FromEvent("INCOMING_RESURRECT_CHANGED"):Subscribe(function(unit)
        subject:OnNext(unit)

        if UnitHasIncomingResurrection(unit) then
            Next(function()
                -- Avoid the event not fired when the unit is already resurrected
                while UnitHasIncomingResurrection(unit) do Delay(1) end
                subject:OnNext(unit)
            end)
        end
    end)

    return Wow.FromUnitEvent(subject):Map(function(unit) return UnitHasIncomingResurrection(unit) end)
end


------------------------------------------------------------
--                    Class Power API                     --
------------------------------------------------------------
local _PlayerClass              = select(2, UnitClass("player"))
local _ClassPowerType, _ClassPowerToken, _PrevClassPowerType

local _ClassPowerRefresh        = Subject()
local _ClassPowerSubject        = Subject()
local _ClassPowerMaxSubject     = Subject()

local SPEC_DEMONHUNTER_VENGENCE = 2
local SOULFRAGMENT              = 203981
local SOULFRAGMENTNAME

local STAGGER                   = 100 -- DIFF to other class type

local FindAuraByName            = _G.AuraUtil.FindAuraByName
local PowerType                 = _G.Enum.PowerType

__Async__()
function OnEnable()
    -- Use the custom unit event to provide the API
    if _PlayerClass == "WARRIOR" then

    elseif _PlayerClass == "DEATHKNIGHT" then
        _ClassPowerToken        = "RUNES"
        _ClassPowerType         = PowerType.Runes

        while true do
            local spec          = GetSpecialization()
            Continue(RefreshClassPower)
            NextEvent("PLAYER_SPECIALIZATION_CHANGED")
        end

    elseif _PlayerClass == "PALADIN" then
        _ClassPowerToken        = "HOLY_POWER"

        local level             = UnitLevel("player")
        while level < PALADINPOWERBAR_SHOW_LEVEL do
            level               = NextEvent("PLAYER_LEVEL_UP")
        end
        _ClassPowerType         = PowerType.HolyPower

    elseif _PlayerClass == "MONK" then
        _ClassPowerToken        = "CHI"

        while true do
            local spec          = GetSpecialization()
            _ClassPowerType     = spec == SPEC_MONK_WINDWALKER and PowerType.Chi or spec == SPEC_MONK_BREWMASTER and STAGGER or nil
            Continue(RefreshClassPower)
            NextEvent("PLAYER_SPECIALIZATION_CHANGED")
        end

    elseif _PlayerClass == "PRIEST" then
        _ClassPowerToken        = "MANA"

        while true do
            _ClassPowerType     = GetSpecialization() == SPEC_PRIEST_SHADOW and PowerType.Mana or nil
            Continue(RefreshClassPower)
            NextEvent("PLAYER_SPECIALIZATION_CHANGED")
        end

    elseif _PlayerClass == "SHAMAN" then
        _ClassPowerToken        = "MANA"

        while true do
            _ClassPowerType     = GetSpecialization() ~= SPEC_SHAMAN_RESTORATION and PowerType.Mana or nil
            Continue(RefreshClassPower)
            NextEvent("PLAYER_SPECIALIZATION_CHANGED")
        end

    elseif _PlayerClass == "DRUID" then
        _ClassPowerToken        = "COMBO_POINTS"

        while true do
            _ClassPowerType     = GetShapeshiftFormID() == CAT_FORM and PowerType.ComboPoints or nil
            Continue(RefreshClassPower)
            NextEvent("UPDATE_SHAPESHIFT_FORM")
        end

    elseif _PlayerClass == "ROGUE" then
        _ClassPowerToken        = "COMBO_POINTS"
        _ClassPowerType         = PowerType.ComboPoints

    elseif _PlayerClass == "MAGE" then
        _ClassPowerToken        = "ARCANE_CHARGES"

        while true do
            _ClassPowerType     = GetSpecialization() == SPEC_MAGE_ARCANE and PowerType.ArcaneCharges or nil
            Continue(RefreshClassPower)
            NextEvent("PLAYER_SPECIALIZATION_CHANGED")
        end

    elseif _PlayerClass == "WARLOCK" then
        _ClassPowerToken        = "SOUL_SHARDS"
        _ClassPowerType         = PowerType.SoulShards

    elseif _PlayerClass == "HUNTER" then

    elseif _PlayerClass == "DEMONHUNTER" then
        SOULFRAGMENTNAME        = GetSpellInfo(SOULFRAGMENT)
        _ClassPowerToken        = "DEMONHUNTER"

        while true do
            _ClassPowerType     = GetSpecialization() == SPEC_DEMONHUNTER_VENGENCE and SOULFRAGMENT or nil
            Continue(RefreshClassPower)
            NextEvent("PLAYER_SPECIALIZATION_CHANGED")
        end

    end

    return RefreshClassPower()
end

function RefreshClassPower()
    if _ClassPowerType then
        if _PrevClassPowerType ~= _ClassPowerType then
            if _PrevClassPowerType then
                _ClassPowerSubject:Unsubscribe()
                _ClassPowerMaxSubject:Unsubscribe()
            end

            _PrevClassPowerType = _ClassPowerType

            -- Binding the real event source
            _ClassPowerSubject:Resubscribe()
            _ClassPowerMaxSubject:Resubscribe()

            if _ClassPowerType == SOULFRAGMENT then
                -- Use aura to track, keep using Next() for throttling
                Wow.FromEvent("UNIT_AURA"):MatchUnit("player"):Next():Subscribe(_ClassPowerSubject)
            elseif _ClassPowerType == STAGGER then
                Wow.FromEvent("UNIT_HEALTH"):MatchUnit("player"):Subscribe(_ClassPowerSubject)
                Wow.FromEvent("UNIT_MAXHEALTH"):MatchUnit("player"):Subscribe(_ClassPowerMaxSubject)
            elseif _ClassPowerType == PowerType.RUNES then
                Wow.FromEvent("RUNE_POWER_UPDATE"):Map("=>'player'"):Subscribe(_ClassPowerSubject)
            else
                Wow.FromEvent("UNIT_POWER_FREQUENT"):MatchUnit("player"):Subscribe(_ClassPowerSubject)
                Wow.FromEvent("UNIT_MAXPOWER"):MatchUnit("player"):Subscribe(_ClassPowerMaxSubject)
            end
        end
    else
        _PrevClassPowerType     = false
        _ClassPowerSubject:Unsubscribe()
        _ClassPowerMaxSubject:Unsubscribe()
    end

    -- Publish the changes
    _ClassPowerRefresh:OnNext("any")        -- For all, but other unit's indicator will be disabled and hide
    _ClassPowerSubject:OnNext("player")     -- For player only
    _ClassPowerMaxSubject:OnNext("player")
end

__Static__() __AutoCache__()
function Wow.ClassPower()
    if _PlayerClass == "DEATHKNIGHT" then
        -- A simple total rune as basic features
        return Wow.FromUnitEvent(_ClassPowerSubject):Map(function(unit) local count = 0 for i = 1, 6 do local _, _, ready = GetRuneCooldown(i) if ready then count = count + 1 end end return count end)
    elseif _PlayerClass == "DEMONHUNTER" then
        return Wow.FromUnitEvent(_ClassPowerSubject):Map(function(unit) return _ClassPowerType and min((select(3, FindAuraByName(SOULFRAGMENTNAME, "player", "PLAYER|HELPFUL"))) or 0, 5) or 0 end)
    elseif _PlayerClass == "MONK" then
        return Wow.FromUnitEvent(_ClassPowerSubject):Map(function(unit) return (_ClassPowerType == STAGGER and UnitStagger(unit) or _ClassPowerType and UnitPower(unit, _ClassPowerType)) or 0 end)
    else
        return Wow.FromUnitEvent(_ClassPowerSubject):Map(function(unit) return _ClassPowerType and UnitPower(unit, _ClassPowerType) or 0 end)
    end
end

__Static__() __AutoCache__()
function Wow.ClassPowerMax()
    local minMax                = { min = 0 }
    if _PlayerClass == "DEATHKNIGHT" then
        minMax.max              = 6
        return Wow.FromUnitEvent(_ClassPowerMaxSubject):Map(function(unit)
            return minMax
        end)
    elseif _PlayerClass == "DEMONHUNTER" then
        minMax.max              = 5
        -- Only track max 5 soul fragment
        return Wow.FromUnitEvent(_ClassPowerMaxSubject):Map(function(unit)
            return minMax
        end)
    elseif _PlayerClass == "MONK" then
        return Wow.FromUnitEvent(_ClassPowerMaxSubject):Map(function(unit)
            minMax.max          = _ClassPowerType == STAGGER and UnitHealthMax(unit) or _ClassPowerType and UnitPowerMax(unit, _ClassPowerType) or 100
            return minMax
        end)
    else
        return Wow.FromUnitEvent(_ClassPowerMaxSubject):Map(function(unit)
            minMax.max          = _ClassPowerType and UnitPowerMax(unit, _ClassPowerType) or 100
            return minMax
        end)
    end
end

__Static__() __AutoCache__()
function Wow.ClassPowerColor()
    if _PlayerClass == "MONK" then
        local STAGGER_YELLOW_TRANSITION = _G.STAGGER_YELLOW_TRANSITION
        local STAGGER_RED_TRANSITION    = _G.STAGGER_RED_TRANSITION

        return Wow.FromUnitEvent(_ClassPowerSubject):Map(function(unit)
            if _ClassPowerType and UnitIsUnit(unit, "player") then
                if _ClassPowerType == STAGGER then
                    local curr          = UnitStagger(unit)
                    local maxs          = UnitHealthMax(unit)
                    if curr and maxs then
                        local pct       = curr / max

                        if (pct >= STAGGER_RED_TRANSITION) then
                            return Color.RED
                        elseif (pct >= STAGGER_YELLOW_TRANSITION) then
                            return Color.YELLOW
                        else
                            return Color.GREEN
                        end
                    end
                else
                    return Color[_ClassPowerToken]
                end
            end

            return Color.DISABLED
        end)
    else
        return Wow.FromUnitEvent(_ClassPowerRefresh):Map(function(unit)
            return UnitIsUnit(unit, "player") and _ClassPowerType and Color[_ClassPowerToken] or Color.DISABLED
        end)
    end
end

__Static__() __AutoCache__()
function Wow.ClassPowerUsable()
    return Wow.FromUnitEvent(_ClassPowerRefresh):Map(function(unit) return UnitIsUnit(unit, "player") and _ClassPowerType and true or false end)
end


------------------------------------------------------------
--                     Unit Cast API                      --
------------------------------------------------------------
local _CurrentCastID            = {}
local _CurrentCastEndTime       = {}
local _CurrentCastDelay         = {}
local _UnitCastSubject          = Subject()
local _UnitCastDelay            = Subject()
local _UnitCastInterruptible    = Subject()
local _UnitCastChannel          = Subject()

__SystemEvent__()
function UNIT_SPELLCAST_START(unit, castID, spellID)
    local _, _, _, s, e, _, _, i= UnitCastingInfo(unit)
    _CurrentCastID[unit]        = castID
    _CurrentCastDelay[unit]     = 0
    _CurrentCastEndTime[unit]   = e

    s, e                        = s / 1000, e / 1000


    _UnitCastSubject:OnNext(unit, spellID, s, e - s)
    _UnitCastDelay:OnNext(unit, 0)
    _UnitCastInterruptible:OnNext(unit, i)
    _UnitCastChannel:OnNext(unit, false)
end

__SystemEvent__ "UNIT_SPELLCAST_FAILED" "UNIT_SPELLCAST_STOP" "UNIT_SPELLCAST_INTERRUPTED"
function UNIT_SPELLCAST_FAILED(unit, castID, spellID)
    if not castID or castID == _CurrentCastID[unit] then
        _UnitCastSubject:OnNext(unit, spellID, 0, 0)
        _UnitCastDelay:Only(unit, 0)
        _UnitCastInterruptible:OnNext(unit, nil)
    end
end

__SystemEvent__()
function UNIT_SPELLCAST_INTERRUPTIBLE(unit)
    _UnitCastInterruptible:OnNext(unit, true)
end

__SystemEvent__()
function UNIT_SPELLCAST_NOT_INTERRUPTIBLE(unit)
    _UnitCastInterruptible:OnNext(unit, false)
end

__SystemEvent__()
function UNIT_SPELLCAST_DELAYED(unit, castID, spellID)
    local _, _, _, s, e, _, _, i= UnitCastingInfo(unit)
    s, e                        = s / 1000, e / 1000

    local delay                 = e - _CurrentCastEndTime[unit]
    _CurrentCastEndTime[unit]   = e

    _UnitCastSubject:OnNext(unit, spellID, s, e - s)

    if delay > 0 then
        _CurrentCastDelay[unit] = _CurrentCastDelay[unit] + delay
        _UnitCastDelay:OnNext(unit, _CurrentCastDelay[unit])
    end
end

__SystemEvent__()
function UNIT_SPELLCAST_CHANNEL_START(unit, castID, spellID)
    local _, _, _, s, e, _, i   = UnitChannelInfo(unit)
    _CurrentCastID[unit]        = castID
    _CurrentCastDelay[unit]     = 0
    _CurrentCastEndTime[unit]   = e

    s, e                        = s / 1000, e / 1000


    _UnitCastSubject:OnNext(unit, spellID, s, e - s)
    _UnitCastDelay:OnNext(unit, 0)
    _UnitCastInterruptible:OnNext(unit, i)
    _UnitCastChannel:OnNext(unit, true)
end

__SystemEvent__()
function UNIT_SPELLCAST_CHANNEL_UPDATE(unit, castID, spellID)
    local _, _, _, s, e         = UnitChannelInfo(unit)
    s, e                        = s / 1000, e / 1000

    local delay                 = e - _CurrentCastEndTime[unit]
    _CurrentCastEndTime[unit]   = e

    _UnitCastSubject:OnNext(unit, spellID, s, e - s)

    if delay > 0 then
        _CurrentCastDelay[unit] = _CurrentCastDelay[unit] + delay
        _UnitCastDelay:OnNext(unit, _CurrentCastDelay[unit])
    end
end

__SystemEvent__()
function UNIT_SPELLCAST_CHANNEL_STOP(unit, castID, spellID)
    _UnitCastSubject:OnNext(unit, spellID, 0, 0)
    _UnitCastDelay:Only(unit, 0)
    _UnitCastInterruptible:OnNext(unit, nil)
end

__Static__() __AutoCache__()
function Wow.UnitCastCooldown()
    local status                = { start = 0, duration = 0 }
    return FromUnitEvent(_UnitCastSubject):Map(function(unit, spellID, start, stop)
        status.start            = start
        status.stop             = stop
        return status
    end)
end

