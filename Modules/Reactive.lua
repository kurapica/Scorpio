--========================================================--
--                Scorpio Reactive Extension              --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2019/12/03                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio.Reactive"                     ""
--========================================================--

local _M                        = _M

import "System.Reactive"

------------------------------------------------------------
--                     Time Operation                     --
------------------------------------------------------------
do
    --- Create an Observable that emits a sequence of integers spaced by a given time interval
    __Static__() __Arguments__{ Number, Number/nil }
    function Observable.Interval(interval, max)
        return Observable(function(observer)
            return Continue(
                function (observer, interval, max)
                    local i     = 0
                    max         = max or math.huge

                    while not observer.IsUnsubscribed and i <= max do
                        observer:OnNext(i)
                        Delay(interval)
                        i       = i + 1
                    end

                    observer:OnCompleted()
                end,
                observer, interval, max
            )
        end)
    end

    --- Creates an Observable that emits a particular item after a given delay
    __Static__() __Arguments__{ Number }
    function Observable.Timer(delay)
        return Observable(function(observer)
            return Delay(delay,
                function (observer)
                    observer:OnNext(0)
                    observer:OnCompleted()
                end,
                observer
            )
        end)
    end

    --- The Delay extension method is a purely a way to time-shift an entire sequence
    __Observable__()
    __Arguments__{ Number }
    function IObservable:Delay(delay)
        return Operator(self, function(observer, ...)
            return Delay(delay,
                function (observer, ...)
                    observer:OnNext(...)
                end,
                observer, ...
            )
        end, nil, function(observer)
            return Delay(delay,
                function (observer)
                    observer:OnCompleted()
                end,
                observer
            )
        end)
    end

    --- The Timeout extension method allows us terminate the sequence with an error if
    -- we do not receive any notifications for a given period
    --
    -- Usage: Observable.Range(1, 10):Delay(2):Timeout(1):Dump()
    __Observable__()
    __Arguments__{ Number }
    function IObservable:Timeout(dueTime)
        return Observable(function(observer)
            local count         = 0
            local check         = function(chkcnt)
                return chkcnt == count and observer:OnError("The operation is time out")
            end

            Delay(dueTime, check, count)

            self:Subscribe(function(...)
                count           = count + 1
                observer:OnNext(...)
                Delay(dueTime, check, count)
            end, function(ex)
                observer:OnError(ex)
            end, function()
                observer:OnCompleted()
            end)
        end)
    end

    --- Block the sequence for a frame phase, useful for some events that trigger
    -- multiple-times in one phase(the same value will be blocked until the next phase)
    local _Recyle               = Recycle()

    local function onNextSingleProcess(observer, cache, idxmap)
        for i = 1, #cache do
            local single        = cache[i]
            if idxmap[single] == i then
                observer:OnNext(single)
            end
        end

        _Recyle(wipe(cache))
        _Recyle(wipe(idxmap))
    end

    local function onNextProcess(observer, cache, idxmap)
        for i = 1, #cache do
            local item          = cache[i]
            if idxmap[item[0]] == i then
                observer:OnNext(unpack(item, 1))
                wipe(item)
            end
        end

        _Recyle(wipe(cache))
        _Recyle(wipe(idxmap))
    end

    local function distinctCache(cache, idxmap, ...)
        local item              = _Recyle()
        local ncnt              = select("#", ...)
        local index             = 1

        for i = 1, ncnt do
            item[i]             = tostring((select(i, ...)))
        end

        local token             = tblconcat(item, "|")
        local index             = #cache + 1

        if idxmap[token] then
            cache[index]        = cache[idxmap[token]]
            _Recyle(wipe(item))
        else
            item[0]             = token
            for i = 1, ncnt do
                item[i]         = select(i, ...)
            end

            cache[index]        = item
        end
        idxmap[token]           = index
    end

    __Observable__()
    function IObservable:Next(multi)
        local cache, idxmap
        local currTime          = 0

        if multi then
            return Operator(self, function(observer, ...)
                local now           = GetTime()
                if now ~= currTime then
                    cache           = _Recyle()
                    idxmap          = _Recyle()
                    currTime        = now
                    Next(onNextProcess, observer, cache, idxmap)
                end
                distinctCache(cache, idxmap, ...)
            end)
        else
            return Operator(self, function(observer, single)
                local now           = GetTime()
                if now ~= currTime then
                    cache           = _Recyle()
                    idxmap          = _Recyle()
                    currTime        = now
                    Next(onNextSingleProcess, observer, cache, idxmap)
                end
                if single ~= nil then
                    local idx       = #cache + 1
                    cache[idx]      = single
                    idxmap[single]  = idx
                end
            end)
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

    if not IObservable.Throttle then
        __Observable__()
        __Arguments__{ Number }
        function IObservable:Throttle(dueTime)
            local lasttime      = 0

            return Operator(self, function(observer, ...)
                local curr      = GetTime()
                if curr - lasttime > dueTime then
                    lasttime    = curr
                    observer:OnNext(...)
                end
            end)
        end

        IObservable.Debounce    = IObservable.Throttle
    end

    function IObservable:ColorString()
        return self:Map(function(color)
            if type(color) == "table" then
                return strformat("\124c%.2x%.2x%.2x%.2x", (color.a or 1) * 255, (color.r or 1) * 255, (color.g or 1) * 255, (color.b or 1) * 255)
            else
                return ""
            end
        end):ToSubject(LiteralSubject)
    end
end

------------------------------------------------------------
--                     Wow Observable                     --
------------------------------------------------------------
__Final__() __Sealed__()
interface "Scorpio.Wow" (function(_ENV)
    local _EventMap             = setmetatable({}, {
        __index                 = function(self, event)
            local subject       = Subject()
            rawset(self, event, subject)

            -- Keep register since if the event is used, it should be used frequently
            _M:RegisterEvent(event, function(...) subject:OnNext(...) end)

            return subject
        end
    })

    local _MultiEventMap        = {}

    --- The data sequences from the wow event
    __Static__() __Arguments__{ NEString * 1 }
    function FromEvent(...)
        if select("#", ...) == 1 then
            return _EventMap[(...)]
        else
            local token         = List{ ... }:Join("|")
            local ob            = _MultiEventMap[token]
            if not ob then
                ob              = Observable(function(observer) for i = 1, #ob do _EventMap[ob[i]]:Subscribe(observer) end end)
                for i = 1, select("#", ...) do ob[i] = select(i, ...) end
                _MultiEventMap[token] = ob
            end

            return ob
        end
    end
end)
