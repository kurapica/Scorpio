--========================================================--
--                Scorpio UnitFrame Cast API              --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/06                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Secure.UnitFrame.HealthAPI" "1.0.0"
--========================================================--

namespace "Scorpio.Secure.UnitFrame"

import "System.Reactive"
import "System.Toolset"

------------------------------------------------------------
--                      UNIT HEALTH                       --
------------------------------------------------------------
local _DISPELLABLE              = ({
    ["MAGE"]                    = { Curse   = Color.CURSE, },
    ["DRUID"]                   = { Poison  = Color.POISON, Curse   = Color.CURSE,   Magic = Color.MAGIC },
    ["PALADIN"]                 = { Poison  = Color.POISON, Disease = Color.DISEASE, Magic = Color.MAGIC },
    ["PRIEST"]                  = { Disease = Color.DISEASE,Magic   = Color.MAGIC },
    ["SHAMAN"]                  = { Curse   = Color.CURSE,  Magic   = Color.MAGIC },
    ["WARLOCK"]                 = { Magic   = Color.MAGIC, },
    ["MONK"]                    = { Poison  = Color.POISON, Disease = Color.DISEASE, Magic = Color.MAGIC },
})[_PlayerClass] or false

local _UnitGUIDMap              = {}
local _UnitHealthMap            = {}

local _UnitHealthSubject        = Subject()
local _UnitMaxHealthSubject     = Subject()

function RegisterFrequentHealthUnit(unit, guid, health)
    _UnitHealthMap[guid]        = health

    local oguid                 = _UnitGUIDMap[unit]
    if oguid == guid then return end

    _UnitGUIDMap[unit]          = guid
    _UnitGUIDMap[guid]          = (_UnitGUIDMap[guid] or 0) + 1

    if oguid then
        _UnitGUIDMap[oguid]     = _UnitGUIDMap[oguid] - 1

        if _UnitGUIDMap[oguid] <= 0 then
            _UnitGUIDMap[oguid] = nil
            _UnitHealthMap[oguid] = nil
        end
    end
end

__CombatEvent__ "SWING_DAMAGE" "RANGE_DAMAGE" "SPELL_DAMAGE" "SPELL_PERIODIC_DAMAGE" "DAMAGE_SPLIT" "DAMAGE_SHIELD" "ENVIRONMENTAL_DAMAGE" "SPELL_HEAL" "SPELL_PERIODIC_HEAL"
function COMBAT_HEALTH_CHANGE(_, event, _, _, _, _, _, destGUID, _, _, _, arg12, arg13, arg14, arg15, arg16)
    local health                = _UnitHealthMap[destGUID]
    if not health then return end

    local change                = 0

    if event == "SWING_DAMAGE" then
        -- amount   : arg12
        -- overkill : arg13
        change                  = (arg13 > 0 and arg13 or 0) - arg12
    elseif event == "RANGE_DAMAGE" or event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" or event == "DAMAGE_SPLIT" or event == "DAMAGE_SHIELD" then
        -- amount   : arg15
        -- overkill : arg16
        change                  = (arg16 > 0 and arg16 or 0) - arg15
    elseif event == "ENVIRONMENTAL_DAMAGE" then
        -- amount   : arg13
        -- overkill : arg14
        change                  = (arg14 > 0 and arg14 or 0) - arg13
    elseif event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" then
        -- amount       : arg15
        -- overhealing  : arg16
        change                  = arg15 - arg16
    end

    if change == 0 then return end

    health                      = health + change
    if change < 0 then
        if health < 0 then health = 0 end
    elseif change > 0 then
        local unit              = GetUnitFromGUID(destGUID)
        if not unit then
            _UnitGUIDMap[destGUID]  = nil
            _UnitHealthMap[destGUID]= nil
            return
        end

        local max               = UnitHealthMax(unit)
        if health > max then health = max end
    end
    _UnitHealthMap[destGUID]    = health

    -- Distribute the new health
    for unit in GetUnitsFromGUID(destGUID) do
        _UnitHealthSubject:OnNext(unit)
    end
end

__SystemEvent__()
function PLAYER_ENTERING_WORLD()
    -- Clear the Registered Units
    wipe(_UnitGUIDMap)
    wipe(_UnitHealthMap)
end

__SystemEvent__(Scorpio.IsRetail and "UNIT_HEALTH" or "UNIT_HEALTH_FREQUENT")
function UNIT_HEALTH(unit)
    local guid                  = UnitGUID(unit)
    if _UnitHealthMap[guid] then
        _UnitHealthMap[guid]    = UnitHealth(unit)
    end

    _UnitHealthSubject:OnNext(unit)
end

__SystemEvent__()
function UNIT_MAXHEALTH(unit)
    _UnitMaxHealthSubject:OnNext(unit)
    _UnitHealthSubject:OnNext(unit)
end

__Static__() __AutoCache__()
function Wow.UnitHealth()
    -- Use the Next for a tiny delay after the UnitHealthMax
    return Wow.FromUnitEvent(_UnitHealthSubject):Next():Map(UnitHealth)
end

__Static__() __AutoCache__()
function Wow.UnitHealthFrequent()
    -- Based on the CLEU
    return Wow.FromUnitEvent(_UnitHealthSubject):Next():Map(function(unit)
        local guid              = UnitGUID(unit)
        local health            = _UnitHealthMap[guid]
        if health and _UnitGUIDMap[unit] == guid then return health end

        -- Register the unit
        health                  = health or UnitHealth(unit)
        RegisterFrequentHealthUnit(unit, guid, health)
        return health
    end)
end

__Static__() __AutoCache__()
function Wow.UnitHealthPercent()
    return Wow.FromUnitEvent(_UnitHealthSubject):Next():Map(function(unit)
        local health            = UnitHealth(unit)
        local max               = UnitHealthMax(unit)

        return floor(0.5 + (health and max and health / max * 100) or 0)
    end)
end

__Static__() __AutoCache__()
function Wow.UnitHealthPercentFrequent()
    -- Based on the CLEU
    return Wow.FromUnitEvent(_UnitHealthSubject):Next():Map(function(unit)
        local guid              = UnitGUID(unit)
        local health            = _UnitHealthMap[guid]

        if not (health and _UnitGUIDMap[unit] == guid) then
        -- Register the unit
            health              = health or UnitHealth(unit)
            RegisterFrequentHealthUnit(unit, guid, health)
        end

        local max               = UnitHealthMax(unit)
        return floor(0.5 + (health and max and health / max * 100) or 0)
    end)
end

__Static__() __AutoCache__()
function Wow.UnitHealthMax()
    local minMax                = { min = 0 }
    return Wow.FromUnitEvent(_UnitMaxHealthSubject):Map(function(unit)
        minMax.max              = UnitHealthMax(unit) or 100
        return minMax
    end)
end

__Static__() __AutoCache__() -- Too complex to do it here, leave it to the indicators or map chains
function Wow.UnitHealPrediction()
    return Wow.FromUnitEvent("UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_HEAL_PREDICTION", "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_HEAL_ABSORB_AMOUNT_CHANGED"):Next()
end

__Arguments__{ (ColorType + Boolean)/nil, ColorType/nil }
__Static__()
function Wow.UnitConditionColor(useClassColor, smoothEndColor)
    local defaultColor          = type(useClassColor) == "table" and useClassColor or Color.GREEN
    useClassColor               = useClassColor == true

    if smoothEndColor then
        local cache             = Color{ r = 1, g = 1, b = 1 }
        local br, bg, bb        = smoothEndColor.r, smoothEndColor.g, smoothEndColor.b

        if _DISPELLABLE then
            return Wow.FromUnitEvent("UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_AURA"):Next():Map(function(unit)
                local index     = 1
                repeat
                    local n, _, _, d = UnitAura(unit, index, "HARMFUL")
                    local color = _DISPELLABLE[d]
                    if color then return color end
                    index       = index + 1
                until not n

                local health    = UnitHealth(unit)
                local maxHealth = UnitHealthMax(unit)
                local pct       = health / maxHealth
                local dcolor    = defaultColor

                if useClassColor then
                    local _, cls= UnitClass(unit)
                    if cls then dcolor = Color[cls] end
                end

                cache.r         = br + (dcolor.r - br) * pct
                cache.g         = bg + (dcolor.g - bg) * pct
                cache.b         = bb + (dcolor.b - bb) * pct

                return cache
            end)
        else
            return Wow.FromUnitEvent(_UnitHealthSubject):Next():Map(function(unit)
                local health    = _UnitHealthMap[unit] or UnitHealth(unit)
                local maxHealth = UnitHealthMax(unit)
                local pct       = health / maxHealth
                local dcolor    = defaultColor

                if useClassColor then
                    local _, cls= UnitClass(unit)
                    if cls then dcolor = Color[cls] end
                end

                cache.r         = br + (dcolor.r - br) * pct
                cache.g         = bg + (dcolor.g - bg) * pct
                cache.b         = bb + (dcolor.b - bb) * pct

                return cache
            end)
        end
    else
        if _DISPELLABLE then
            return Wow.FromUnitEvent("UNIT_AURA"):Next():Map(function(unit)
                local index     = 1
                repeat
                    local n, _, _, d = UnitAura(unit, index, "HARMFUL")
                    local color = _DISPELLABLE[d]
                    if color then return color end
                    index       = index + 1
                until not n

                local dcolor    = defaultColor

                if useClassColor then
                    local _, cls= UnitClass(unit)
                    if cls then dcolor = Color[cls] end
                end
                return dcolor
            end)
        else
            return Wow.FromUnitEvent():Map(function(unit)
                local dcolor    = defaultColor

                if useClassColor then
                    local _, cls= UnitClass(unit)
                    if cls then dcolor = Color[cls] end
                end
                return dcolor
            end)
        end
    end
end