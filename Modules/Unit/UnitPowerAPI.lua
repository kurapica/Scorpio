--========================================================--
--                Scorpio UnitFrame Power API             --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/06                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Secure.UnitFrame.PowerAPI""1.0.0"
--========================================================--

namespace "Scorpio.Secure.UnitFrame"

import "System.Reactive"
import "System.Toolset"

------------------------------------------------------------
--                     Unit Power API                     --
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
OnEnable                        = OnEnable + function ()
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

    elseif _PlayerClass == "PALADIN" and Scorpio.IsRetail then
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

    elseif _PlayerClass == "PRIEST" and Scorpio.IsRetail then
        _ClassPowerToken        = "MANA"

        while true do
            _ClassPowerType     = GetSpecialization() == SPEC_PRIEST_SHADOW and PowerType.Mana or nil
            Continue(RefreshClassPower)
            NextEvent("PLAYER_SPECIALIZATION_CHANGED")
        end

    elseif _PlayerClass == "SHAMAN" and Scorpio.IsRetail then
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

    elseif _PlayerClass == "MAGE" and Scorpio.IsRetail then
        _ClassPowerToken        = "ARCANE_CHARGES"

        while true do
            _ClassPowerType     = GetSpecialization() == SPEC_MAGE_ARCANE and PowerType.ArcaneCharges or nil
            Continue(RefreshClassPower)
            NextEvent("PLAYER_SPECIALIZATION_CHANGED")
        end

    elseif _PlayerClass == "WARLOCK" and Scorpio.IsRetail then
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
                Wow.FromEvent("UNIT_AURA"):MatchUnit("player"):Subscribe(_ClassPowerSubject)
            elseif _ClassPowerType == STAGGER then
                Wow.FromEvent("UNIT_HEALTH"):MatchUnit("player"):Subscribe(_ClassPowerSubject)
                Wow.FromEvent("UNIT_MAXHEALTH"):MatchUnit("player"):Subscribe(_ClassPowerMaxSubject)
            elseif _ClassPowerType == PowerType.Runes then
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
        return Wow.FromUnitEvent(_ClassPowerSubject):Next():Map(function(unit) local count = 0 for i = 1, 6 do local _, _, ready = GetRuneCooldown(i) if ready then count = count + 1 end end return count end)
    elseif _PlayerClass == "DEMONHUNTER" then
        return Wow.FromUnitEvent(_ClassPowerSubject):Next():Map(function(unit) return _ClassPowerType and min((select(3, FindAuraByName(SOULFRAGMENTNAME, "player", "PLAYER|HELPFUL"))) or 0, 5) or 0 end)
    elseif _PlayerClass == "MONK" then
        return Wow.FromUnitEvent(_ClassPowerSubject):Next():Map(function(unit) return (_ClassPowerType == STAGGER and UnitStagger(unit) or _ClassPowerType and UnitPower(unit, _ClassPowerType)) or 0 end)
    else
        return Wow.FromUnitEvent(_ClassPowerSubject):Next():Map(function(unit) return _ClassPowerType and UnitPower(unit, _ClassPowerType) or 0 end)
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

__Static__() __AutoCache__()
function Wow.UnitPower(frequent)
    return Wow.FromUnitEvent(frequent and "UNIT_POWER_FREQUENT" or "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_POWER_BAR_SHOW", "UNIT_POWER_BAR_HIDE")
        :Next():Map(function(unit) return UnitPower(unit, (UnitPowerType(unit))) end)
end

__Static__() __AutoCache__()
function Wow.UnitPowerMax()
    local minMax                = { min = 0 }
    return Wow.FromUnitEvent("UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_POWER_BAR_SHOW", "UNIT_POWER_BAR_HIDE")
        :Map(function(unit) minMax.max =  UnitPowerMax(unit, (UnitPowerType(unit))) return minMax end)
end

__Static__() __AutoCache__()
function Wow.UnitPowerColor()
    local scolor                = Color(1, 1, 1)
    return Wow.FromUnitEvent("UNIT_CONNECTION", "UNIT_DISPLAYPOWER", "UNIT_POWER_BAR_SHOW", "UNIT_POWER_BAR_HIDE")
        :Map(function(unit)
            if not UnitIsConnected(unit) then
                scolor.r        = 0.5
                scolor.g        = 0.5
                scolor.b        = 0.5
            else
                local ptype, ptoken, r, g, b = UnitPowerType(unit)
                local color     = ptoken and Color[ptoken]
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
    local MANA                  = _G.Enum.PowerType.Mana
    return Wow.FromUnitEvent("UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_POWER_BAR_SHOW", "UNIT_POWER_BAR_HIDE")
        :Map(function(unit) return UnitPower(unit, MANA) end)
end

__Static__() __AutoCache__()
function Wow.UnitManaMax()
    local MANA                  = _G.Enum.PowerType.Mana
    local minMax                = { min = 0 }
    return Wow.FromUnitEvent("UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_POWER_BAR_SHOW", "UNIT_POWER_BAR_HIDE")
        :Map(function(unit) minMax.max =  UnitPowerMax(unit, MANA) return minMax end)
end

__Static__() __AutoCache__()
function Wow.UnitManaVisible()
    local MANA                  = _G.Enum.PowerType.Mana
    return Wow.FromUnitEvent("UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_POWER_BAR_SHOW", "UNIT_POWER_BAR_HIDE")
        :Map(function(unit) return UnitPowerType(unit) ~= MANA and (UnitPowerMax(unit, MANA) or 0) > 0 end)
end
