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

    local function onNextProcess(observer, cache)
        local index             = 1

        while true do
            local count         = cache[index]
            if not count then break end

            observer:OnNext(unpack(cache, index + 1, index + count))

            index               = index + count + 1
        end

        _Recyle(wipe(cache))
    end

    local function distinctCache(cache, ...)
        local ncnt              = select("#", ...)
        local index             = 1

        while true do
            local count         = cache[index]
            if not count then break end

            if count == ncnt then
                local match     = true
                for i = 1, ncnt do
                    if cache[index + i] ~= select(i, ...) then
                        match   = false
                        break
                    end
                end
                if match then return end
            end

            index               = index + count + 1
        end

        cache[index]            = ncnt

        for i = 1, ncnt do
            cache[index + i]    = select(i, ...)
        end
    end

    __Observable__()
    function IObservable:Next()
        local cache
        local currTime          = 0

        return Operator(self, function(observer, ...)
            local now           = GetTime()
            if now ~= currTime then
                cache           = _Recyle()
                currTime        = now
                Next(onNextProcess, observer, cache)
            end
            distinctCache(cache, ...)
        end)
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
