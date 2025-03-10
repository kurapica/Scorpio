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

------------------------------------------------------------
--                     Time Operation                     --
------------------------------------------------------------
do
    --- Create an Observable that emits a sequence of integers spaced by a given time interval
    __Static__() __Arguments__{ Number, Number/nil }
    function Observable.Interval(interval, max)
        return Observable(function(observer, subscription)
            return Continue(
                function (observer, interval, max, subscription)
                    local i     = 0
                    max         = max or math.huge

                    while not subscription.IsUnsubscribed and i <= max do
                        observer:OnNext(i)
                        Delay(interval)
                        i       = i + 1
                    end

                    if not subscription.IsUnsubscribed then
                        observer:OnCompleted()
                    end
                end,
                observer, interval, max, subscription
            )
        end)
    end

    --- Creates an Observable that emits a particular item after a given delay
    __Static__() __Arguments__{ Number }
    function Observable.Timer(delay)
        return Observable(function(observer, subscription)
            return Delay(delay,
                function (observer, subscription)
                    if subscription.IsUnsubscribed then return end

                    observer:OnNext(0)
                    observer:OnCompleted()
                end,
                observer, subscription
            )
        end)
    end

    --- The Delay extension method is a purely a way to time-shift an entire sequence
    __Observable__()
    __Arguments__{ Number }
    function IObservable:Delay(delay)
        return Operator(self, function(observer, ...)
            return Delay(delay,
                function (observer, ...) observer:OnNext(...) end,
                observer, ...
            )
        end, nil, function(observer)
            return Delay(delay,
                function (observer) observer:OnCompleted() end,
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
        return Observable(function(observer, subscription)
            local count         = 0
            local check         = function(chkcnt)
                return chkcnt == count and observer:OnError("The operation is time out")
            end

            self:Subscribe(function(...)
                count           = count + 1
                observer:OnNext(...)
                Delay(dueTime, check, count)
            end, function(ex)
                observer:OnError(ex)
            end, function()
                observer:OnCompleted()
            end, subscription)

            Delay(dueTime, check, count)
        end)
    end

    --- Distinct the sequence by the first value until the next phase
    local _Recyle               = Recycle()
    local _RecycleQueue         = Recycle(Queue)
    local fakefunc              = Toolset.fakefunc

    local function processNextQueue(subscription, observer, queue, idxmap)
        if not subscription.IsUnsubscribed then
            local index         = 0

            local key, count    = queue:Dequeue(2)
            while key ~= nil do
                index           = index + 1

                if idxmap[key] == index then
                    if key == fakefunc then key = nil end

                    if count > 0 then
                        observer:OnNext(key, queue:Dequeue(count))
                    else
                        observer:OnNext(key)
                    end
                elseif count > 0 then
                    queue:Dequeue(count)
                end

                key, count          = queue:Dequeue(2)
            end

            Next()
        end

        queue:Clear()
        _RecycleQueue(queue)
        _Recyle(wipe(idxmap))
    end

    __Observable__()
    function IObservable:Next()
        local queue, idxmap, index
        local currTime          = 0

        local subscription
        local oper              = Operator(self, function(observer, key, ...)
            local now           = GetTime()

            -- Init the queue for this phase
            if now ~= currTime then
                queue           = _RecycleQueue()
                idxmap          = _Recyle()
                currTime        = now
                index           = 0

                Next(processNextQueue, subscription, observer, queue, idxmap)
            end

            -- Use fakefunc to represent nil
            if key == nil then key = fakefunc end

            index               = index + 1
            queue:Enqueue(key, select("#", ...), ...)
            idxmap[key]         = index
        end)

        -- get the subscription
        oper.HandleSubscription = function(self, ...)
            subscription        = ...
        end

        return oper
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
    end

    local DebounceTask              = Toolset.newtable(true)
    local DebounceCache             = Recycle()

    __Service__(true)
    function DebounceService()
        while true do
            local hasTasks          = false
            local curr              = GetTime()

            for ob, task in pairs(DebounceTask) do
                hasTasks            = true

                if task.lasttime <= curr then
                    DebounceTask[ob] = nil
                    ob:OnNext(unpack(task))

                    DebounceCache(wipe(task))
                end
            end

            if not hasTasks then NextEvent("SCORPIO_DEBOUNCE_SERVICE_START") end

            Delay(0.1)
        end
    end

    __Observable__()
    __Arguments__{ Number }
    function IObservable:Debounce(dueTime)
        if dueTime <= 0 then dueTime = 1 end

        return Operator(self, function(observer, ...)
            local cache             = DebounceTask[observer] or DebounceCache()
            cache.lasttime          = GetTime() + dueTime
            local n                 = select("#", ...)
            local cn                = #cache

            if n <= 5 and cn <= 5 then
                cache[1], cache[2], cache[3], cache[4], cache[5] = ...
            else
                for i = 1, n > cn and n or cn do
                    cache[i]        = select(i, ...)
                end
            end

            if not next(DebounceTask) then FireSystemEvent("SCORPIO_DEBOUNCE_SERVICE_START") end
            DebounceTask[observer]  = cache
        end)
    end

    function IObservable:ColorString()
        return self:Map(function(color)
            if type(color) == "table" then
                return strformat("\124c%.2x%.2x%.2x%.2x", (color.a or 1) * 255, (color.r or 1) * 255, (color.g or 1) * 255, (color.b or 1) * 255)
            else
                return ""
            end
        end):ToSubject(BehaviorSubject)
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
                ob              = Observable(function(...) for i = 1, #ob do _EventMap[ob[i]]:Subscribe(...) end end)
                for i = 1, select("#", ...) do ob[i] = select(i, ...) end
                _MultiEventMap[token] = ob
            end

            return ob
        end
    end
end)
