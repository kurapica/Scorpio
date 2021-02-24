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

------------------------------------------------------------
--                    Simple Unit API                     --
------------------------------------------------------------
__Static__()
function Wow.Unit()
    return Wow.FromUnitEvent()
end

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
    local scolor                = Color(1, 1, 1)
    return Wow.FromUnitEvent("UNIT_FACTION", "UNIT_THREAT_SITUATION_UPDATE"):Map(function(unit)
        if not UnitIsPlayer(unit) then
            if UnitIsTapDenied(unit) then return Color.RUNES end

            if withThreat and UnitCanAttack("player", unit) then
                local threat    = UnitThreatSituation("player", unit)
                if threat and threat > 0 then
                    scolor.r, scolor.g, scolor.b = GetThreatStatusColor(threat)
                    return scolor
                end
            end

            scolor.r, scolor.g, scolor.b = UnitSelectionColor(unit, true)
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

__Static__() __AutoCache__()
function Wow.UnitClassification()
    return Wow.FromUnitEvent("UNIT_CLASSIFICATION_CHANGED"):Map(UnitClassification)
end

__Static__() __AutoCache__()
function Wow.UnitClassificationColor()
    return Wow.UnitClassification():Map(function(class)
        if class == "elite" then
            return Color.YELLOW
        elseif class == "rare" then
            return Color.WHITE
        elseif class == "rareelite" then
            return Color.CYAN
        elseif class == "worldboss" then
            return Color.RAGE
        else
            return Color.NORMAL
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

-- The Aura API
__Static__() __AutoCache__()
function Wow.UnitAura()
    return Wow.FromUnitEvent("UNIT_AURA"):Next()
end

__Static__() __AutoCache__()
function Wow.UnitTotem()
    return Wow.FromUnitEvent(Wow.FromEvent("PLAYER_TOTEM_UPDATE"):Map("=>'player'"))
end

-- Unit State API
__Static__() __AutoCache__()
function Wow.UnitIsDisconnected()
    return Wow.FromUnitEvent("UNIT_HEALTH", "UNIT_CONNECTION"):Next():Map(function(unit) return not UnitIsConnected(unit) end)
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
function Wow.UnitNotPlayer()
    return Wow.FromUnitEvent("UNIT_NAME_UPDATE"):Map(function(unit) return not UnitIsUnit(unit, "player") end)
end

__Static__() __AutoCache__()
function Wow.PlayerInCombat()
    return Wow.FromUnitEvent(Wow.FromEvent("PLAYER_ENTER_COMBAT", "PLAYER_LEAVE_COMBAT"):Map("=>'player'")):Map(function(unit) return UnitAffectingCombat("player") end)
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

__Static__() __AutoCache__()
function Wow.UnitRaidTargetIndex()
    return Wow.FromUnitEvent(Wow.FromEvent("RAID_TARGET_UPDATE"):Map("=>'any'")):Map(GetRaidTargetIndex)
end

__Static__() __AutoCache__()
function Wow.UnitThreatLevel()
    return Wow.FromUnitEvent("UNIT_THREAT_SITUATION_UPDATE"):Map(function(unit)
        return UnitIsPlayer(unit) and UnitThreatSituation(unit) or 0
    end)
end

__Static__() __AutoCache__()
function Wow.UnitGroupRoster()
    return Wow.FromUnitEvent(Wow.FromEvent("GROUP_ROSTER_UPDATE"):Map("=>'any'")):Map(function(unit)
        if IsInRaid() and not UnitHasVehicleUI(unit) then
            if GetPartyAssignment('MAINTANK', unit) then
                return "MAINTANK"
            elseif GetPartyAssignment('MAINASSIST', unit) then
                return "MAINASSIST"
            else
                return "NONE"
            end
        else
            return "NONE"
        end
    end)
end

__Static__() __AutoCache__()
function Wow.UnitGroupRosterVisible()
    return Wow.UnitGroupRoster():Map(function(assign) return assign and assign ~= "NONE" or false end)
end

__Static__() __AutoCache__()
function Wow.UnitRole()
    return Wow.FromUnitEvent(Wow.FromEvent("GROUP_ROSTER_UPDATE", "PLAYER_ROLES_ASSIGNED"):Map("=>'any'")):Map(UnitGroupRolesAssigned)
end

__Static__() __AutoCache__()
function Wow.UnitRoleVisible()
    return Wow.UnitRole():Map(function(role) return role and role ~= "NONE" or false end)
end

__Static__() __AutoCache__()
function Wow.UnitIsLeader()
    return Wow.FromUnitEvent(Wow.FromEvent("GROUP_ROSTER_UPDATE", "PARTY_LEADER_CHANGED"):Map("=>'any'")):Map(function(unit)
        return (UnitInParty(unit) or UnitInRaid(unit)) and UnitIsGroupLeader(unit) or false
    end)
end

__Static__() __AutoCache__()
function Wow.UnitInRange()
    return Wow.FromUnitEvent(Observable.Interval(0.5):Map("=>'any'")):Map(function(unit)
        return UnitIsUnit(unit, "player") or not (UnitInParty(unit) or UnitInRaid(unit)) or UnitInRange(unit)
    end)
end


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


------------------------------------------------------------
--                     Unit Cast API                      --
------------------------------------------------------------
local _CurrentCastID            = {}
local _CurrentCastEndTime       = {}

local _UnitCastSubject          = Subject()
local _UnitCastDelay            = Subject()
local _UnitCastInterruptible    = Subject()
local _UnitCastChannel          = Subject()

__SystemEvent__()
function UNIT_SPELLCAST_START(unit, castID, spellID)
    local n, _, t, s, e, _, _, i= UnitCastingInfo(unit)
    s, e                        = s / 1000, e / 1000

    _CurrentCastID[unit]        = castID
    _CurrentCastEndTime[unit]   = e

    _UnitCastChannel:OnNext(unit, false)
    _UnitCastSubject:OnNext(unit, spellID, n, t, s, e - s)
    _UnitCastDelay:OnNext(unit, 0)
    _UnitCastInterruptible:OnNext(unit, not i)
end

__SystemEvent__ "UNIT_SPELLCAST_FAILED" "UNIT_SPELLCAST_STOP" "UNIT_SPELLCAST_INTERRUPTED"
function UNIT_SPELLCAST_FAILED(unit, castID, spellID)
    if _CurrentCastID[unit] and (not castID or castID == _CurrentCastID[unit]) then
        _UnitCastSubject:OnNext(unit, spellID, nil, nil, 0, 0)
        _UnitCastDelay:OnNext(unit, 0)
    end
end

__SystemEvent__()
function UNIT_SPELLCAST_INTERRUPTIBLE(unit)
    if not _CurrentCastID[unit] then return end
    _UnitCastInterruptible:OnNext(unit, true)
end

__SystemEvent__()
function UNIT_SPELLCAST_NOT_INTERRUPTIBLE(unit)
    if not _CurrentCastID[unit] then return end
    _UnitCastInterruptible:OnNext(unit, false)
end

__SystemEvent__()
function UNIT_SPELLCAST_DELAYED(unit, castID, spellID)
    if _CurrentCastID[unit] and (not castID or castID == _CurrentCastID[unit]) then
        local n, _, t, s, e, _, _, i= UnitCastingInfo(unit)
        s, e                        = s / 1000, e / 1000

        _UnitCastSubject:OnNext(unit, spellID, n, t, s, e - s)
        _UnitCastDelay:OnNext(unit, e - _CurrentCastEndTime[unit])
    end
end

__SystemEvent__()
function UNIT_SPELLCAST_CHANNEL_START(unit, castID, spellID)
    local n, _, t, s, e, _, i   = UnitChannelInfo(unit)
    s, e                        = s / 1000, e / 1000

    _CurrentCastID[unit]        = nil
    _CurrentCastEndTime[unit]   = e

    _UnitCastChannel:OnNext(unit, true)
    _UnitCastSubject:OnNext(unit, spellID, n, t, s, e - s)
    _UnitCastDelay:OnNext(unit, 0)
    _UnitCastInterruptible:OnNext(unit, i)
end

__SystemEvent__()
function UNIT_SPELLCAST_CHANNEL_UPDATE(unit, castID, spellID)
    local n, _, t, s, e         = UnitChannelInfo(unit)
    s, e                        = s / 1000, e / 1000

    _UnitCastSubject:OnNext(unit, spellID, n, t, s, e - s)
    _UnitCastDelay:OnNext(unit, e - _CurrentCastEndTime[unit])
end

__SystemEvent__()
function UNIT_SPELLCAST_CHANNEL_STOP(unit, castID, spellID)
    _UnitCastSubject:OnNext(unit, spellID, nil, nil, 0, 0)
    _UnitCastDelay:OnNext(unit, 0)
end

__Static__() __AutoCache__()
function Wow.UnitCastCooldown()
    local status                = { start = 0, duration = 0 }
    return Wow.FromUnitEvent(_UnitCastSubject):Map(function(unit, spellID, name, icon, start, duration)
        if spellID then
            status.start        = start
            status.duration     = duration
        else
            -- Register the Unit Here
            _CurrentCastID[unit]= 0
            status.start        = 0
            status.duration     = 0
        end
        return status
    end)
end

__Static__() __AutoCache__()
function Wow.UnitCastChannel()
    return Wow.FromUnitEvent(_UnitCastChannel):Map(function(unit, val) return val or false end)
end

__Static__() __AutoCache__()
function Wow.UnitCastInterruptible()
    return Wow.FromUnitEvent(_UnitCastInterruptible):Map(function(unit, val) return val or false end)
end

__Static__() __AutoCache__()
function Wow.UnitCastName()
    return Wow.FromUnitEvent(_UnitCastSubject):Map(function(unit, spellID, name) return name end)
end

__Static__() __AutoCache__()
function Wow.UnitCastIcon()
    return Wow.FromUnitEvent(_UnitCastSubject):Map(function(unit, spellID, name, icon) return icon end)
end

__Static__() __AutoCache__()
function Wow.UnitCastDelay()
    return Wow.FromUnitEvent(_UnitCastDelay):Map(function(unit, delay) return delay end)
end


------------------------------------------------------------
--                      READY CHECK                       --
------------------------------------------------------------
local _ReadyChecking            = 0
local _ReadyCheckSubject        = Subject()
local _ReadyCheckConfirmSubject = Subject()

__SystemEvent__() __Async__()
function READY_CHECK()
    _ReadyChecking              = 1
    _ReadyCheckSubject:OnNext("any")

    if "READY_CHECK_FINISHED" == Wait("READY_CHECK_FINISHED", "PLAYER_REGEN_DISABLED") then
        _ReadyChecking          = 2
        _ReadyCheckConfirmSubject:OnNext("any")

        Wait(8, "PLAYER_REGEN_DISABLED")
    end

    _ReadyChecking              = 0
    _ReadyCheckSubject:OnNext("any")
end

__SystemEvent__()
function READY_CHECK_CONFIRM()
    _ReadyCheckConfirmSubject:OnNext("any")
end

__Static__() __AutoCache__()
function Wow.UnitReadyCheckVisible()
    return Wow.FromUnitEvent(_ReadyCheckSubject):Map(function() return _ReadyChecking > 0 end)
end

__Static__() __AutoCache__()
function Wow.UnitReadyCheck()
    return Wow.FromUnitEvent(_ReadyCheckConfirmSubject):Map(function(unit)
        if _ReadyChecking == 0 then return end

        local state             = GetReadyCheckStatus(unit)
        return _ReadyChecking == 2 and state == "waiting" and "notready" or state
    end)
end


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

__Static__() __AutoCache__()
function Wow.UnitHealth()
    -- Use the Next for a tiny delay after the UnitHealthMax
    return Wow.FromUnitEvent("UNIT_HEALTH", "UNIT_MAXHEALTH"):Next():Map(UnitHealth)
end

__Static__() __AutoCache__()
function Wow.UnitHealthMax()
    local minMax                = { min = 0 }
    return Wow.FromUnitEvent("UNIT_MAXHEALTH"):Map(function(unit)
        minMax.max              = UnitHealthMax(unit) or 100
        return minMax
    end)
end

__Static__() __AutoCache__()
function Wow.UnitHealthPercent()
    return Wow.FromUnitEvent("UNIT_HEALTH", "UNIT_MAXHEALTH"):Next():Map(function(unit)
        local health            = UnitHealth(unit)
        local max               = UnitHealthMax(unit)

        return floor(0.5 + (health and max and health / max * 100) or 0)
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
                until not name

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
            return Wow.FromUnitEvent("UNIT_HEALTH", "UNIT_MAXHEALTH"):Next():Map(function(unit)
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
                until not name

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