--========================================================--
--                Scorpio UnitFrame FrameWork             --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/06/09                              --
--========================================================--

--========================================================--
Scorpio         "Scorpio.Secure.UnitReactive"        "1.0.0"
--========================================================--

import "System.Reactive"

local getCurrentTarget          = Scorpio.UI.Style.GetCurrentTarget
local isUIObject                = UI.IsUIObject
local isObjectType              = Class.IsObjectType
local FromEvent                 = Scorpio.Wow.FromEvent

--- The interface should be extended by all unit frame types(include secure and non-secure)
__Sealed__()
interface "IUnitFrame" (function(_ENV)
    ------------------------------------------------------
    --                      Event                       --
    ------------------------------------------------------
    --- Fired when the unit frame need refreshing
    __Abstract__()
    event "OnUnitRefresh"

    --- The current unit
    __Abstract__()
    property "Unit"             { type = String, event = OnUnitRefresh }
end)

--- The unsecure unit frame that'd be used as nameplates
__Sealed__()
class "InSecureUnitFrame" { Frame, IUnitFrame }

__Sealed__()
class "UnitFrameSubject" (function(_ENV)
    inherit "Subject"

    local _UnitFrameMap         = Toolset.newtable(true)

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

    -- Don't use __AsyncSingle__ here to reduce the memory garbage collect
    __Async__()
    function RefreshUnit(self, unit)
        self.TaskId             = (self.TaskId or 0) + 1
        local task              = self.TaskId

        if unit == "target" then
            while task == self.TaskId do
                self:OnNext(unit)
                NextEvent("PLAYER_TARGET_CHANGED")
            end
        elseif unit == "mouseover" then
            while task == self.TaskId do
                self:OnNext(unit)
                NextEvent("UPDATE_MOUSEOVER_UNIT")
            end
        elseif unit == "focus" then
            while task == self.TaskId do
                self:OnNext(unit)
                NextEvent("PLAYER_FOCUS_CHANGED")
            end
        elseif unit then
            if unit:match("^party%d") or unit:match("^raid%d") then
                while task == self.TaskId do
                    self:OnNext(unit)
                    Next(FromEvent("UNIT_NAME_UPDATE"):MatchUnit(unit))
                end
            elseif unit:match("pet") then
                local owner     = unit:match("^(%w*)pet")
                if not owner or owner:match("^%s*$") then owner = "player" end

                while task == self.TaskId do
                    self:OnNext(unit)
                    Next(FromEvent("UNIT_PET"):MatchUnit(owner))
                end
            elseif unit:match("%w+target") then
                local frm       = self.UnitFrame
                while task == self.TaskId do
                    while frm:IsShown() and task == self.TaskId do
                        self:OnNext(unit, true)
                        Delay(self.Interval)
                    end

                    -- Wait the unit frame re-show
                    if task == self.TaskId then
                        Next(Observable.From(frm.OnShow))
                    end
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
    property "UnitFrame"    { type = IUnitFrame }

    --- The current unit
    property "Unit"         { type = String, handler = RefreshUnit }

    --- The current unit
    property "Interval"     { type = PositiveNumber, default = function(self) return self.UnitFrame.Interval or 0.5 end }

    ----------------------------------------------------
    -- Constructor
    ----------------------------------------------------
    __Arguments__{ IUnitFrame }
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
        while unitfrm and not isObjectType(unitfrm, IUnitFrame) do
            unitfrm             = unitfrm:GetParent()
        end

        return unitfrm and UnitFrameSubject(unitfrm)
    end
end

local unitFrameObservable       = Toolset.newtable(true)

local function genUnitFrameObservable(unitEvent)
    local observable            = unitFrameObservable[unitEvent or 0]
    if not observable then
        observable              = Observable(function(observer)
            local unitSubject   = getUnitFrameSubject()

            if not unitSubject then return unitEvent and unitEvent:Subscribe(observer) end
            if not unitEvent   then return unitSubject:Subscribe(observer) end

            local currUnit

            -- Unit event observer
            local obsEvent      = Observer(function(...) return observer:OnNext(...) end)

            -- Unit change observer
            local obsUnit       = Observer(function(unit, noevent)
                if noevent or currUnit ~= unit then
                    obsEvent:Unsubscribe() -- Clear the previous observable
                    obsEvent:Resubscribe()

                    currUnit    = unit

                    if not noevent then
                        unitEvent:MatchUnit(unit):Subscribe(obsEvent)
                    end
                end

                observer:OnNext(unit)
            end)

            local onUnsubscribe
            onUnsubscribe       = function()
                observer.OnUnsubscribe = observer.OnUnsubscribe - onUnsubscribe

                obsEvent:Unsubscribe()
                obsUnit:Unsubscribe()
            end
            observer.OnUnsubscribe = observer.OnUnsubscribe + onUnsubscribe

            -- Start the unit watching
            unitSubject:Subscribe(obsUnit)
        end)

        unitFrameObservable[unitEvent or 0] = observable
    end

    return observable
end

------------------------------------------------------------
--                        Wow API                         --
------------------------------------------------------------
--- The data sequences from the wow unit event binding to unit frames
__Arguments__{ (NEString + IObservable)/nil, NEString * 0 }
__Static__()
function Wow.FromUnitEvent(observable, ...)
    if type(observable) == "string" then
        return genUnitFrameObservable(FromEvent(observable, ...))
    else
        return genUnitFrameObservable(observable)
    end
end

--- Filter the unit event with unit, this should be re-usable
__Arguments__{ String }
function IObservable:MatchUnit(unit)
    local matchUnits            = self.__MatchUnits
    if not matchUnits then
        matchUnits              = {}
        self.__MatchUnits       = matchUnits

        self:Subscribe(function(unit, ...)
            if unit == "any" then
                for nunit, subject in pairs(matchUnits) do
                    subject:OnNext(nunit, ...)
                end
            else
                local subject   = matchUnits[unit]
                return subject and subject:OnNext(unit, ...)
            end
        end)
    end

    local subject               = matchUnits[unit]
    if not subject then
        subject                 = Subject()
        matchUnits[unit]        = subject
    end

    return subject
end