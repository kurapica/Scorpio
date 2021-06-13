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
import "System.Toolset"

------------------------------------------------------------
--                    Simple Unit API                     --
------------------------------------------------------------
local _UnitNameSubject          = Subject()

__SystemEvent__()
function UNIT_NAME_UPDATE(unit)
    _UnitNameSubject:OnNext(unit)
end

__SystemEvent__()
function GROUP_ROSTER_UPDATE()
    _UnitNameSubject:OnNext("any")
end

__Static__()
function Wow.Unit()
    return Wow.FromUnitEvent()
end

__Static__() __AutoCache__()
function Wow.UnitName(withServer)
    return Wow.FromUnitEvent(_UnitNameSubject):Next():Map(withServer and function(unit) return GetUnitName(unit, true) end or GetUnitName)
end

__Static__() __AutoCache__()
function Wow.UnitColor()
    return Wow.FromUnitEvent(_UnitNameSubject):Next():Map(function(unit)
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
        :Map(Scorpio.IsRetail and function(unit, level)
            level               = level or UnitLevel(unit)
            if level and level > 0 then
                if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
                    level       = UnitBattlePetLevel(unit)
                end
                return strformat(format, level)
            else
                return strformat(unknownFormat, "???")
            end
        end or function(unit, level)
            level               = level or UnitLevel(unit)
            if level and level > 0 then
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
    return Wow.FromUnitEvent(_UnitNameSubject):Map(function(unit) return UnitIsUnit(unit, "player") end)
end

__Static__() __AutoCache__()
function Wow.UnitNotPlayer()
    return Wow.FromUnitEvent(_UnitNameSubject):Map(function(unit) return not UnitIsUnit(unit, "player") end)
end

__Static__() __AutoCache__()
function Wow.PlayerInCombat()
    local subject               = BehaviorSubject()
    Continue(function(subject)
        while true do
            local status        = UnitAffectingCombat("player") or false
            subject:OnNext(status)

            NextEvent(status and "PLAYER_REGEN_ENABLED" or "PLAYER_REGEN_DISABLED")
        end
    end, subject)
    return subject
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
    return Wow.FromUnitEvent(_UnitNameSubject):Map(function(unit)
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
    return Wow.FromUnitEvent(Wow.FromEvent("GROUP_ROSTER_UPDATE", "PLAYER_ROLES_ASSIGNED"):Map("=>'any'")):Map(UnitGroupRolesAssigned or Toolset.fakefunc)
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
--                      Wow Classic                       --
------------------------------------------------------------
if Scorpio.IsRetail then return end

UnitHasVehicleUI                = UnitHasVehicleUI or Toolset.fakefunc

function GetThreatStatusColor(index)
    if index == 3 then
        return 1, 0, 0
    elseif index == 2 then
        return 1, 0.6, 0
    elseif index == 1 then
        return 1, 1, 0.47
    else
        return 0.69, 0.69, 0.69
    end
end

if IsAddOnLoaded("LibClassicDurations") or (LibStub and LibStub("LibClassicDurations")) then
    LibClassicDurations         = LibStub("LibClassicDurations")
    LibClassicDurations:Register("Scorpio") -- tell library it's being used and should start working
    _Parent.UnitAura            = LibClassicDurations.UnitAuraWithBuffs

    LibClassicDurations.RegisterCallback("Scorpio", "UNIT_BUFF", function(event, unit)
        return FireSystemEvent("UNIT_AURA", unit)
    end)
end