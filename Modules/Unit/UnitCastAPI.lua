--========================================================--
--                Scorpio UnitFrame Cast API              --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/06                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Secure.UnitFrame.CastAPI" "1.0.0"
--========================================================--

namespace "Scorpio.Secure.UnitFrame"

import "System.Reactive"
import "System.Toolset"

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
function UNIT_SPELLCAST_START(unit, castID)
    local n, _, t, s, e, _, _, i= UnitCastingInfo(unit)
    if not n then return end
    s, e                        = s / 1000, e / 1000

    _CurrentCastID[unit]        = castID
    _CurrentCastEndTime[unit]   = e

    _UnitCastChannel:OnNext(unit, false)
    _UnitCastSubject:OnNext(unit, n, t, s, e - s)
    _UnitCastDelay:OnNext(unit, 0)
    _UnitCastInterruptible:OnNext(unit, not i)
end

__SystemEvent__ "UNIT_SPELLCAST_FAILED" "UNIT_SPELLCAST_STOP" "UNIT_SPELLCAST_INTERRUPTED"
function UNIT_SPELLCAST_FAILED(unit, castID)
    if _CurrentCastID[unit] and (not castID or castID == _CurrentCastID[unit]) then
        _UnitCastSubject:OnNext(unit, nil, nil, 0, 0)
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
function UNIT_SPELLCAST_DELAYED(unit, castID)
    if _CurrentCastID[unit] and (not castID or castID == _CurrentCastID[unit]) then
        local n, _, t, s, e, _, _, i= UnitCastingInfo(unit)
        if not n then return end
        s, e                        = s / 1000, e / 1000

        _UnitCastSubject:OnNext(unit, n, t, s, e - s)
        _UnitCastDelay:OnNext(unit, e - _CurrentCastEndTime[unit])
    end
end

__SystemEvent__()
function UNIT_SPELLCAST_CHANNEL_START(unit)
    local n, _, t, s, e, _, i   = UnitChannelInfo(unit)
    if not n then return end
    s, e                        = s / 1000, e / 1000

    _CurrentCastID[unit]        = nil
    _CurrentCastEndTime[unit]   = e

    _UnitCastChannel:OnNext(unit, true)
    _UnitCastSubject:OnNext(unit, n, t, s, e - s)
    _UnitCastDelay:OnNext(unit, 0)
    _UnitCastInterruptible:OnNext(unit, not i)
end

__SystemEvent__()
function UNIT_SPELLCAST_CHANNEL_UPDATE(unit)
    local n, _, t, s, e         = UnitChannelInfo(unit)
    if not n then return end
    s, e                        = s / 1000, e / 1000

    _UnitCastSubject:OnNext(unit, n, t, s, e - s)
    _UnitCastDelay:OnNext(unit, e - _CurrentCastEndTime[unit])
end

__SystemEvent__()
function UNIT_SPELLCAST_CHANNEL_STOP(unit)
    _UnitCastSubject:OnNext(unit, nil, nil, 0, 0)
    _UnitCastDelay:OnNext(unit, 0)
end

__Static__() __AutoCache__()
function Wow.UnitCastCooldown()
    local status                = { start = 0, duration = 0 }
    return Wow.FromUnitEvent(_UnitCastSubject):Map(function(unit, name, icon, start, duration)
        if name then
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
    return Wow.FromUnitEvent(_UnitCastSubject):Map(function(unit, name) return name end)
end

__Static__() __AutoCache__()
function Wow.UnitCastIcon()
    return Wow.FromUnitEvent(_UnitCastSubject):Map(function(unit, name, icon) return icon end)
end

__Static__() __AutoCache__()
function Wow.UnitCastDelay()
    return Wow.FromUnitEvent(_UnitCastDelay):Map(function(unit, delay) return delay end)
end

------------------------------------------------------------
--                    Classic Support                     --
------------------------------------------------------------
if Scorpio.IsRetail then return end

if Scorpio.IsBCC then
    local oUnitCastingInfo      = _G.UnitCastingInfo
    local oUnitChannelInfo      = _G.UnitChannelInfo

    function UnitCastingInfo(unit)
        local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, spellId = oUnitCastingInfo(unit)
        return name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, false, spellId
    end

    function UnitChannelInfo(unit)
        local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, spellId = oUnitChannelInfo(unit)
        return name, text, texture, startTimeMS, endTimeMS, isTradeSkill, false, spellId
    end

    return
end

local HUNTER_AUTO               = 75
local HUNTER_AIM                = 19434

local _Cache                    = {}
local recycle                   = function(tbl) if tbl then tinsert(_Cache, wipe(tbl)) else return tremove(_Cache) or {} end end
local _CastingInfo              = {}
local _PlayerGUID
local _CASTLINE                 = 0
local average                   = function(prev, now) if prev then return (prev + now) / 2 else return now end end
local scanTime                  = 0

local _IsAutoShot               = false
local _IsCastAutoShot           = false
local _AutoStart
local _AutoEnd
local _AutoLine

local function getUnmodifiedSpeed()
    for _, left, right in GetGameTooltipLines("InventoryItem", "player", 18) do
        if right then
            local _, _, spd     = strfind(right, "([%,%.%d]+)")
            if spd then
                spd             = strgsub(spd, "%,", "%.")
                return tonumber(spd)
            end
        end
    end
end

function OnLoad()
    _SVData:SetDefault {
        CAST_INFO_DB            = {
            PLAYER              = {},
            NPC                 = {},
        }
    }

    CAST_INFO_DB                = _SVData.CAST_INFO_DB

    _PlayerGUID                 = UnitGUID("player")
end

__Service__(true)
function RecycleCastInfo()
    while true do
        local limit             = (GetTime() - 60) * 1000

        for k, v in pairs(_CastingInfo) do
            if v.start < limit then
                _CastingInfo[k] = nil
                recycle(v)
            end
        end

        Delay(10)
    end
end

function UpdatePlayerCondition()
    local name, _, _, _, _, _, castID, notInterruptible = UnitCastingInfo("player")

    if name then return UNIT_SPELLCAST_START("player", castID) end
    if ChannelInfo() then return UNIT_SPELLCAST_CHANNEL_START("player") end

    UNIT_SPELLCAST_CHANNEL_STOP("player")
end

__CombatEvent__"SPELL_CAST_START" "SPELL_CAST_SUCCESS" "SPELL_MISSED" "SPELL_CAST_FAILED" "SPELL_INTERRUPT"
function COMBAT_LOG_CAST_EVENT(timestamp, eventType, hideCaster, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, spellID, spellName, spellSchool, auraType, amount)
    if not srcGUID then return end

    if eventType == "SPELL_CAST_START" then
        _CASTLINE               = _CASTLINE + 1

        local info              = recycle()
        info.spellName          = spellName
        info.timestamp          = timestamp
        info.isplayer           = band(srcFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0
        info.LineID             = _CASTLINE
        info.start              = GetTime() * 1000

        local duration          = CAST_INFO_DB[info.isplayer and "PLAYER" or "NPC"][spellName]
        if duration then
            info.endtime        = info.start + duration
        end

        _CastingInfo[srcGUID]   = info

        if not srcGUID == _PlayerGUID then
            for unit in GetUnitsFromGUID(srcGUID) do
                UNIT_SPELLCAST_START(unit, info.LineID)
            end
        end
    elseif eventType == "SPELL_CAST_SUCCESS" or eventType == "SPELL_MISSED" then
        local info              = _CastingInfo[srcGUID]
        if info and info.spellName == spellName then
            _CastingInfo[srcGUID] = nil

            local duration      = (timestamp - info.timestamp) * 1000

            if info.isplayer then
                CAST_INFO_DB.PLAYER[spellName] = average(CAST_INFO_DB.PLAYER[spellName], duration)
            else
                CAST_INFO_DB.NPC[spellName] = average(CAST_INFO_DB.NPC[spellName], duration)
            end

            if not srcGUID == _PlayerGUID then
                for unit in GetUnitsFromGUID(srcGUID) do
                    UNIT_SPELLCAST_FAILED(unit, info.LineID)
                end
            end

            recycle(info)
        end
    elseif eventType == "SPELL_CAST_FAILED" or eventType == "SPELL_INTERRUPT" then
        local info              = _CastingInfo[srcGUID]
        if info and info.spellName == spellName then
            _CastingInfo[srcGUID] = nil

            if not srcGUID == _PlayerGUID then
                for unit in GetUnitsFromGUID(srcGUID) do
                    UNIT_SPELLCAST_FAILED(unit, info.LineID)
                end
            end

            recycle(info)
        end
    end
end

__SystemEvent__()
function START_AUTOREPEAT_SPELL()
    _IsAutoShot                 = true
end

__SystemEvent__()
function STOP_AUTOREPEAT_SPELL()
    _IsAutoShot                 = false
    if _IsCastAutoShot then
        _IsCastAutoShot         = false
        UpdatePlayerCondition()
    end
end

__SystemEvent__()
function UNIT_SPELLCAST_SUCCEEDED(unit, line, spell)
    if unit == "player" then
        if spell == HUNTER_AUTO or spell == HUNTER_AIM then
            if _IsAutoShot then
                local spd, min, max = UnitRangedDamage("player")
                if spell == HUNTER_AIM then
                    spd         = getUnmodifiedSpeed() or spd
                end
                _CASTLINE       = _CASTLINE + 1

                _AutoStart      = GetTime() * 1000
                _AutoEnd        = _AutoStart + spd * 1000
                _AutoLine       = _CASTLINE

                _IsCastAutoShot = true

                UpdatePlayerCondition()
            end
        end
    end
end

function UnitCastingInfo(unit)
    local guid                  = UnitGUID(unit)

    if guid == _PlayerGUID then
        if _IsCastAutoShot then
            if CastingInfo() then return CastingInfo() end
            local name, _, texture = GetSpellInfo(HUNTER_AUTO)
            return name, _, texture, _AutoStart, _AutoEnd, nil, _AutoLine
        end
        return CastingInfo()
    end

    local info                  = _CastingInfo[guid]
    if info and info.endtime then
        return info.spellName, "", select(3, GetSpellInfo(info.spellName)), info.start, info.endtime, nil, info.LineID
    end
end

function UnitChannelInfo(unit)
    local guid                  = UnitGUID(unit)
    if guid == _PlayerGUID then return ChannelInfo() end
end
