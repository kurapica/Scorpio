--========================================================--
--                Scorpio UnitFrame FrameWork             --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/06/09                              --
--========================================================--

--========================================================--
Scorpio         "Scorpio.Secure.UnitFrame.UnitEvent" "1.0.0"
--========================================================--

namespace "Scorpio.Secure.UnitFrame"

import "System.Reactive"


local getCurrentTarget          = Scorpio.UI.Style.GetCurrentTarget
local isUIObject                = UI.IsUIObject
local isObjectType              = Class.IsObjectType
local FromEvent                 = Scorpio.Wow.FromEvent
local FromEvents                = Scorpio.Wow.FromEvents

__Sealed__()
class "UnitFrameSubject" (function(_ENV)
    inherit "Subject"

    local _UnitFrameMap         = setmetatable({}, META_WEAKKEY)

    local function OnUnitRefresh(self, unit)
        self                    = _UnitFrameMap[self]
        self.Unit               = unit
    end

    ----------------------------------------------------
    -- Method
    ----------------------------------------------------
    function Subscribe(self, ...)
        local observer          = super.Subscribe(self, ...)
        if self.Unit then observer:OnNext(self.Unit) end
    end

    __AsyncSingle__(true)
    function RefreshUnit(self, unit)
        if unit == "target" then
            while true do
                self:OnNext(unit)
                NextEvent("PLAYER_TARGET_CHANGED")
            end
        elseif unit == "mouseover" then
            while true do
                self:OnNext(unit)
                NextEvent("UPDATE_MOUSEOVER_UNIT")
            end
        elseif unit == "focus" then
            while true do
                self:OnNext(unit)
                NextEvent("PLAYER_FOCUS_CHANGED")
            end
        elseif unit then
            if unit:match("^party%d") or unit:match("^raid%d") then
                while true do
                    self:OnNext(unit)
                    Next(FromEvent("UNIT_NAME_UPDATE"):MatchUnit(unit))
                end
            elseif unit:match("pet") then
                local owner     = unit:match("^(%w*)pet")
                if not owner or owner:match("^%s*$") then owner = "player" end

                while true do
                    self:OnNext(unit)
                    Next(FromEvent("UNIT_PET"):MatchUnit(owner))
                end
            elseif unit:match("%w+target") then
                local frm       = self.UnitFrame
                while true do
                    while frm:IsShown() do
                        self:OnNext(unit, true)
                        Delay(self.Interval)
                    end

                    -- Wait the unit frame re-show
                    Next(Observable.From(frm.OnShow))
                end
            else
                self:OnNext(unit)
            end
        else
            -- need sepcial unit to be passed to clear the values
            self:OnNext("clear", true)
        end
    end

    ----------------------------------------------------
    -- Property
    ----------------------------------------------------
    --- the unit frame
    property "UnitFrame"    { type = UnitFrame }

    --- The current unit
    property "Unit"         { type = String, handler = RefreshUnit }

    --- The current unit
    property "Interval"     { type = PositiveNumber, default = function(self) return self.UnitFrame.Interval or 0.5 end }

    ----------------------------------------------------
    -- Constructor
    ----------------------------------------------------
    __Arguments__{ UnitFrame }
    function __ctor(self, unitfrm)
        self.UnitFrame          = unitfrm
        _UnitFrameMap[unitfrm]  = self

        unitfrm.OnUnitRefresh   = unitfrm.OnUnitRefresh + OnUnitRefresh
        self.Unit               = unitfrm.Unit
    end

    function __exist(_, unitfrm)
        return _UnitFrameMap[unitfrm]
    end
end)

local function getUnitFrameSubject()
    local indicator             = getCurrentTarget()

    if indicator and isUIObject(indicator) then
        local unitfrm           = indicator
        while unitfrm and not isObjectType(unitfrm, UnitFrame) do
            unitfrm             = unitfrm:GetParent()
        end

        return unitfrm and UnitFrameSubject(unitfrm)
    end
end

local function genUnitFrameObservable(unitEvent)
    return Observable(function(observer)
        local unitSubject       = getUnitFrameSubject()

        if not unitSubject then return unitEvent:Subscribe(observer) end

        local currUnit

        -- Unit event observer
        local obsEvent          = Observer(function(...) observer:OnNext(...) end)

        -- Unit change observer
        local obsUnit           = Observer(function(unit, noevent)
            if noevent or currUnit ~= unit then
                obsEvent:Unsubscribe() -- Clear the previous observable
                obsEvent:Resubscribe()

                currUnit        = unit

                if not noevent then
                    unitEvent:MatchUnit(unit):Subscribe(obsEvent)
                end
            end

            observer:OnNext(unit)
        end)

        local onUnsubscribe
        onUnsubscribe           = function()
            observer.OnUnsubscribe = observer.OnUnsubscribe - onUnsubscribe

            obsEvent:Unsubscribe()
            obsUnit:Unsubscribe()
        end
        observer.OnUnsubscribe  = observer.OnUnsubscribe + onUnsubscribe

        -- Start the unit watching
        unitSubject:Subscribe(obsUnit)
    end)
end

------------------------------------------------------------
--                        Wow API                         --
------------------------------------------------------------
--- The data sequences from the wow unit event binding to unit frames
__Arguments__{ NEString + IObservable }
__Static__()  __AutoCache__()
function Wow.FromUnitEvent(event)
    if type(event) == "string" then
        return genUnitFrameObservable(FromEvent(event))
    else
        return genUnitFrameObservable(event)
    end
end

__Static__() __Arguments__{ NEString * 2 } __AutoCache__()
function Wow.FromUnitEvents(...)
    return genUnitFrameObservable(FromEvents(...))
end

--- Filter the unit event with unit, this should be re-usable
__AutoCache__() __Arguments__{ String }
function IObservable:MatchUnit(unit)
    return Operator(self, function(observer, nunit, ...)
        if nunit == unit or nunit == "any" then
            return observer:OnNext(unit, ...)
        end
    end):Publish():Connect()
end