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

--- The interface should be extended by all unit frame types(include secure and non-secure)
__Sealed__()
interface "IUnitFrame"          (function(_ENV)
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
class "InSecureUnitFrame"       { Frame, IUnitFrame }

--- The unit subject of the given unit frame
__Sealed__()
class "UnitFrameSubject"        (function(_ENV)
    inherit "Subject"

    export                      {
        _UnitFrameMap           = Toolset.newtable(true),
        _Recycle                = Recycle(),

        -- observables
        NAMEPLATE_SUBJECT       = Wow.FromEvent("NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED"),
        RAID_UNIT_SUBJECT       = Wow.FromEvent("UNIT_NAME_UPDATE", "GROUP_ROSTER_UPDATE"):Map(function() return "any" end):Next(), -- Force All

        -- helper
        subscribe               = Subject.Subscribe,
        FromEvent               = Wow.FromEvent,

        -- unit <-> guid
        _UnitGuidMap            = {},
        _GuidUnitMap            = {},
        refreshUnitGuidMap      = function (unit)
            local guid          = UnitGUID(unit)
            local oguid         = _UnitGuidMap[unit]

            if guid == oguid then return end
            _UnitGuidMap[unit]  = guid

            if guid then
                local map       = _GuidUnitMap[guid]
                if not map then
                    map         = _Recycle()
                    _GuidUnitMap[guid] = map
                end

                map[unit]       = true
            end

            if oguid then
                local map       = _GuidUnitMap[oguid]
                if map then
                    map[unit]   = nil

                    if not next(map) then
                        -- Clear
                        _GuidUnitMap[oguid] = nil
                        _Recycle(map)
                    end
                end
            end
        end
    }

    ----------------------------------------------------
    -- Extend Method To Scorpio
    ----------------------------------------------------
    --- Gets the unit based on the GUID
    __Static__()
    function Scorpio.GetUnitFromGUID(guid)
        local map               = _GuidUnitMap[guid]
        if not map then return end

        for unit in pairs(map) do
            if UnitGUID(unit) == guid then
                return unit
            else
                refreshUnitGuidMap(unit)
            end
        end
    end

    --- Gets all units based on the GUID
    __Static__() __Iterator__()
    function Scorpio.GetUnitsFromGUID(guid)
        local map               = _GuidUnitMap[guid]
        if not map then return end

        for unit in pairs(map) do
            if UnitGUID(unit) == guid then
                yield(unit)
            else
                refreshUnitGuidMap(unit)
            end
        end
    end

    ----------------------------------------------------
    -- Method
    ----------------------------------------------------
    function Subscribe(self, ...)
        local sub, observer     = subscribe(self, ...)
        if self.Unit then observer:OnNext(self.RealUnit or self.Unit, self.BlockEvent) end
        return sub, observer
    end

    -- Don't use __AsyncSingle__ here to reduce the memory garbage collect
    __Async__()
    function RefreshUnit(self, unit, oldunit)
        self.TaskId             = (self.TaskId or 0) + 1
        local task              = self.TaskId

        self.BlockEvent         = false
        self.RealUnit           = nil

        -- May clear the old unit's cache
        if oldunit then refreshUnitGuidMap(oldunit) end

        if not unit then
            -- need sepcial unit to be passed to clear the values
            self:OnNext("clear", true)
        elseif unit == "player" then
            refreshUnitGuidMap(unit)
            self:OnNext(unit)
        elseif unit == "target" then
            while task == self.TaskId do
                refreshUnitGuidMap(unit)
                self:OnNext(unit)
                NextEvent("PLAYER_TARGET_CHANGED")
            end
        elseif unit == "mouseover" then
            while task == self.TaskId do
                refreshUnitGuidMap(unit)
                self:OnNext(unit)
                NextEvent("UPDATE_MOUSEOVER_UNIT")
            end
        elseif unit == "focus" then
            while task == self.TaskId do
                refreshUnitGuidMap(unit)
                self:OnNext(unit)
                NextEvent("PLAYER_FOCUS_CHANGED")
            end
        elseif unit:match("pet%d*$") then
            local owner     = unit:match("^(%w+)pet")
            local index     = owner and unit:match("%d+")
            if not owner then
                owner       = "player"
            elseif index then
                owner       = owner .. index
            else
                -- Not valid
                return self:OnNext("none", true)
            end

            while task == self.TaskId do
                refreshUnitGuidMap(unit)
                self:OnNext(unit)
                Next(FromEvent("UNIT_PET"):MatchUnit(owner))
            end
        elseif unit:match("^nameplate%d+$") then
            while task == self.TaskId do
                refreshUnitGuidMap(unit)
                self:OnNext(unit)
                Next(NAMEPLATE_SUBJECT:MatchUnit(unit))
            end
        elseif unit:match("^party%d+$") or unit:match("^raid%d+$") then
            while task == self.TaskId do
                for i = 1, 4 do
                    -- The unit info may not be stable, try several times
                    refreshUnitGuidMap(unit)
                    self:OnNext(unit)

                    Delay(0.5)
                    if task ~= self.TaskId then break end
                end

                Next(RAID_UNIT_SUBJECT)
            end
        elseif unit == "vehicle" or unit:match("^arena%d+$") or unit:match("^boss%d+$") or unit:match("^spectated[ab]%d+$") or unit:match("^spectatedpet[ab]%d+$") then
            -- Other units: arenaN, bossN, vehicle, spectated<T><N>, spectatedpet<T><N>
            while task == self.TaskId do
                refreshUnitGuidMap(unit)
                self:OnNext(unit)
                Next(FromEvent("UNIT_NAME_UPDATE"):MatchUnit(unit))
            end
        else
            -- targettarget, xxxx-target-target, xxxxx and etc
            local frm           = self.UnitFrame
            local runit         -- the real unit for system event

            while task == self.TaskId do
                while frm:IsShown() and task == self.TaskId do
                    -- Check if the target is an existed unit, use that unit instead the *target
                    -- So the unit system event can work on it
                    local guid  = UnitGUID(unit)
                    local nunit = guid and GetUnitFromGUID(guid)

                    if not nunit or nunit ~= runit then
                        runit   = nunit
                        self:OnNext(runit or unit, not runit)

                        self.RealUnit   = runit
                        self.BlockEvent = not runit
                    end

                    Delay(self.Interval)
                end

                if task ~= self.TaskId then return end

                -- Wait the unit frame re-show
                Next(Observable.From(frm.OnShow))
            end
        end
    end

    ----------------------------------------------------
    -- Property
    ----------------------------------------------------
    --- the unit frame
    property "UnitFrame"    { type = IUnitFrame }

    --- The current unit
    property "Unit"         { type = String, handler = RefreshUnit }

    --- The real unit based on the GUID
    property "RealUnit"     { type = String }

    --- Whether block the unit event
    property "BlockEvent"   { type = Boolean, default = false }

    --- The current unit
    property "Interval"     { type = PositiveNumber, default = function(self) return self.UnitFrame.Interval or 1 end }

    ----------------------------------------------------
    -- Constructor
    ----------------------------------------------------
    __Arguments__{ IUnitFrame }
    function __ctor(self, unitfrm)
        super(self)

        self.UnitFrame          = unitfrm
        _UnitFrameMap[unitfrm]  = self

        unitfrm.OnUnitRefresh   = unitfrm.OnUnitRefresh + function (self, unit)
            self                = _UnitFrameMap[self]
            self.Unit           = unit
        end
        self.Unit               = unitfrm.Unit
    end

    function __exist(_, unitfrm)
        return _UnitFrameMap[unitfrm]
    end
end)

------------------------------------------------------------
--                        Wow API                         --
------------------------------------------------------------
export                          {
    getCurrentTarget            = UI.Style.GetCurrentTarget,
    isUIObject                  = UI.IsUIObject,
    isObjectType                = Class.IsObjectType,
    FromEvent                   = Wow.FromEvent,
    unitFrameObservable         = Toolset.newtable(true),
    nextUnitFrameObservable     = Toolset.newtable(true),
}

function getUnitFrameSubject()
    local indicator             = getCurrentTarget()

    if indicator and isUIObject(indicator) then
        local unitfrm           = indicator
        while unitfrm and not isObjectType(unitfrm, IUnitFrame) do
            unitfrm             = unitfrm:GetParent()
        end
        return unitfrm and UnitFrameSubject(unitfrm)
    end
end

function genUnitFrameObservable(unitEvent, useNext)
    local observable
    if useNext then
        observable              = nextUnitFrameObservable[unitEvent or 0]
    else
        observable              = unitFrameObservable[unitEvent or 0]
    end

    if not observable then
        observable              = Observable(function(observer, subscription)
            local unitSubject   = getUnitFrameSubject()

            if not unitSubject then return unitEvent and unitEvent:Subscribe(observer, subscription) end
            if not unitEvent   then return unitSubject:Subscribe(observer, subscription) end

            -- Unit event observer
            if unitEvent then
                local obsEvent  = Observer(function(...) return observer:OnNext(...) end)

                -- Unit change observer
                local obsUnit   = Observer(function(unit, noevent)
                    obsEvent.Subscription = Subscription(subscription)
                    if not noevent then unitEvent:MatchUnit(unit):Subscribe(obsEvent) end
                    return observer:OnNext(unit)
                end)

                -- Start the unit watching
                if useNext then
                    unitSubject:Next():Subscribe(obsUnit, subscription)
                else
                    unitSubject:Subscribe(obsUnit, subscription)
                end

            -- Unit observer
            else
                -- Start the unit watching
                if useNext then
                    unitSubject:Next():Subscribe(observer, subscription)
                else
                    unitSubject:Subscribe(observer, subscription)
                end
            end
        end)

        if useNext then
            nextUnitFrameObservable[unitEvent or 0] = observable
        else
            unitFrameObservable[unitEvent or 0] = observable
        end
    end

    return observable
end

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

--- The data sequences from the wow unit event binding to unit frames
-- The unit change event will be delayed for one phase
__Arguments__{ (NEString + IObservable)/nil, NEString * 0 }
__Static__()
function Wow.FromNextUnitEvent(observable, ...)
    if type(observable) == "string" then
        return genUnitFrameObservable(FromEvent(observable, ...), true)
    else
        return genUnitFrameObservable(observable, true)
    end
end
