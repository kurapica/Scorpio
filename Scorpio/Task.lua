--========================================================--
--                Task Management System                  --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/08/31                              --
--========================================================--

--========================================================--
Module                "Scorpio.Task"                 "1.0.0"
--========================================================--

------------------------------------------------------------
--                   Constant Settings                    --
------------------------------------------------------------
do
    PHASE_THRESHOLD = 50        -- The max task operation time per phase
    PHASE_TIME_FACTOR = 0.4     -- The factor used to calculate the task operation time per phase
    PHASE_BALANCE_FACTOR = 0.3  -- The factor used to balance tasks between the current and next phase
end

------------------------------------------------------------
--                       Task API                         --
------------------------------------------------------------
do
    CORE_PRIORITY = 0   -- For Task Job
    HIGH_PRIORITY = 1   -- For Direct, Continue, Thread
    NORMAL_PRIORITY = 2 -- For Event, Next
    LOW_PRIORITY = 3    -- For Delay

    DELAY_EVENT = -1

    g_Inited = false

    g_Phase = 0         -- The Nth phase based on GetTime()
    g_PhaseTime = 0
    g_Threshold = 0     -- The threshold based on GetFramerate(), in ms
    g_InPhase = false
    g_FinishedTask = 0
    g_TaskCount = {
        [HIGH_PRIORITY] = 0,
        [NORMAL_PRIORITY] = 0,
        [LOW_PRIORITY] = 0,
    }
    g_StartTime = 0
    g_EndTime = 0
    g_AverageTime = 20  -- A useless init value
    g_ReqAddTime = false

    -- For diagnosis
    g_DelayedTask = 0
    g_MaxPhaseTime = 0

    local r_Header = nil-- The core task header
    local r_Tail = nil  -- The core task tail
    local r_Count = 0   -- The core task count

    p_Header = {}       -- The header pointer
    p_Tail = {}         -- The tail pointer

    -- Cache for useless task objects
    c_Count = 0
    c_Task = {}
    c_Event = {}        -- Cache for registered events

    callThread = System.Threading.ThreadCall

    -- Phase API
    function StartPhase()
        if g_InPhase then return end

        g_InPhase = true

        -- One phase per one time
        local now = GetTime()
        if now ~= g_Phase then
            -- Init the phase
            g_Phase = now
            g_ReqAddTime = false

            -- For diagnosis
            g_DelayedTask = g_DelayedTask + r_Count

            -- Calculate the average time per task
            if g_FinishedTask > 0 then
                local phaseCost = g_EndTime - g_StartTime

                -- For diagnosis
                if phaseCost > g_MaxPhaseTime then g_MaxPhaseTime = phaseCost end

                g_AverageTime = (g_AverageTime + phaseCost / g_FinishedTask) / 2
                g_FinishedTask = 0
            end

            g_StartTime = debugprofilestop()

            -- Move task to core based on priority
            for i = HIGH_PRIORITY, LOW_PRIORITY do
                if p_Header[i] then
                    if r_Header and r_Tail then
                        r_Tail.Next = p_Header[i]
                        r_Tail = p_Tail[i]
                        r_Count = r_Count + g_TaskCount[i]
                    else
                        r_Header = p_Header[i]
                        r_Tail = p_Tail[i]
                        r_Count = g_TaskCount[i]
                    end

                    p_Header[i] = nil
                    p_Tail[i] = nil
                    g_TaskCount[i] = 0
                end
            end

            if g_Inited then
                g_PhaseTime = 1000 * PHASE_TIME_FACTOR / GetFramerate()
                if g_PhaseTime > PHASE_THRESHOLD then g_PhaseTime = PHASE_THRESHOLD end
            else
                -- just for safe
                g_PhaseTime = 1000000
            end

            g_Threshold = g_StartTime + g_PhaseTime
        elseif not r_Header and p_Header[HIGH_PRIORITY] then
            -- Only tasks of high priority can be executed with several generations in one phase
            r_Header = p_Header[HIGH_PRIORITY]
            r_Tail = p_Tail[HIGH_PRIORITY]
            r_Count = g_TaskCount[HIGH_PRIORITY]

            p_Header[HIGH_PRIORITY] = nil
            p_Tail[HIGH_PRIORITY] = nil
            g_TaskCount[HIGH_PRIORITY] = 0
        end

        -- It's time to execute tasks
        while r_Header do
            local task, args = r_Header, r_Header.Args or r_Header
            local ok, msg
            local stop = debugprofilestop()

            if g_Threshold <= stop and not g_ReqAddTime then
                -- One time per phase
                g_ReqAddTime = true

                -- Consider tasks in next phase to smooth the performance
                local cost = (r_Count + g_TaskCount[HIGH_PRIORITY] + g_TaskCount[NORMAL_PRIORITY] + g_TaskCount[LOW_PRIORITY]) * g_AverageTime * PHASE_BALANCE_FACTOR

                if cost + g_PhaseTime > PHASE_THRESHOLD then cost = PHASE_THRESHOLD - g_PhaseTime end

                g_Threshold = g_Threshold + cost

                if g_Threshold <= stop then break end

                task = r_Header
            end

            -- Execute task
            r_Header = r_Header.Next

            if not task.Cancel then
                local nargs = args.NArgs
                local method = task.Method
                if type(method) == "thread" then
                    if status(method) == "suspended" then
                        if nargs == 0 then
                            ok, msg = resume(method)
                        elseif nargs == 1 then
                            ok, msg = resume(method, args[1])
                        elseif nargs == 2 then
                            ok, msg = resume(method, args[1], args[2])
                        elseif nargs == 3 then
                            ok, msg = resume(method, args[1], args[2], args[3])
                        elseif nargs == 4 then
                            ok, msg = resume(method, args[1], args[2], args[3], args[4])
                        else
                            ok, msg = resume(method, unpack(args, 1, nargs))
                        end
                    else
                        ok = true
                    end
                elseif method then
                    if nargs == 0 then
                        ok, msg = pcall(method)
                    elseif nargs == 1 then
                        ok, msg = pcall(method, args[1])
                    elseif nargs == 2 then
                        ok, msg = pcall(method, args[1], args[2])
                    elseif nargs == 3 then
                        ok, msg = pcall(method, args[1], args[2], args[3])
                    elseif nargs == 4 then
                        ok, msg = pcall(method, args[1], args[2], args[3], args[4])
                    else
                        ok, msg = pcall(method, unpack(args, 1, nargs))
                    end
                else
                    ok = true
                end

                if not ok then pcall(geterrorhandler(), msg) end

                if task.Sibling then
                    local sib = task.Sibling
                    task.Sibling = nil

                    while sib do sib.Method, sib.Cancel, sib = nil, true, sib.Sibling end
                end

                g_FinishedTask = g_FinishedTask + 1
            end

            r_Count = r_Count - 1

            if args ~= task then
                args.Used = args.Used - 1
                if args.Used == 0 then
                    tinsert(c_Task, wipe(args))
                end
            end

            tinsert(c_Task, wipe(task))
        end

        g_EndTime = debugprofilestop()

        g_InPhase = false

        -- Try again if have time with high priority tasks
        return not r_Header and g_Threshold > g_EndTime and p_Header[HIGH_PRIORITY] and StartPhase()
    end

    -- Queue API
    function QueueTask(priority, task, noStart)
        local tail, ntail, count = task, task.Next, 1

        while ntail do tail, ntail, count = ntail, ntail.Next, count + 1 end

        if p_Tail[priority] then
            p_Tail[priority].Next = task
            p_Tail[priority] = tail

            g_TaskCount[priority] = g_TaskCount[priority] + count
        else
            p_Header[priority] = task
            p_Tail[priority] = tail

            g_TaskCount[priority] = count
        end

        return not noStart and priority == HIGH_PRIORITY and StartPhase()
    end

    function QueueDelayTask(time, task)
        task.Time = time

        local header = p_Header[DELAY_EVENT]
        local oHeader

        while header and header.Time <= time do
            oHeader = header
            header = header.Next
        end

        if oHeader then
            task.Next = header
            oHeader.Next = task
        else
            task.Next = header
            p_Header[DELAY_EVENT] = task
        end

        if not task.Next then p_Tail[DELAY_EVENT] = task end
    end

    function QueueEventTask(event, task)
        if not c_Event[event] then
            _EventManager:RegisterEvent(event)

            if not _EventManager:IsEventRegistered(event) then
                tinsert(c_Task, wipe(task))
                return false
            else
                c_Event[event] = true
            end
        end

        local tail = p_Tail[event]

        if tail then
            tail.Next = task
            p_Tail[event] = task
        else
            p_Header[event] = task
            p_Tail[event] = task
        end

        return true
    end
end

------------------------------------------------------------
--                     Task Manager                       --
------------------------------------------------------------
do
    _PhaseManager = CreateFrame("Frame")

    -- Delay Event Handler
    _PhaseManager:SetScript("OnUpdate", function(self, elapsed)
        local now = GetTime()

        g_Inited = true

        -- Make sure unexpected error won't stop the whole task system
        if now > g_Phase then g_InPhase = false end

        local header = p_Header[DELAY_EVENT]

        if header and header.Time <= now then
            local otail = header
            local tail = header.Next

            while tail and tail.Time <= now do
                otail = tail
                tail = tail.Next
            end

            p_Header[DELAY_EVENT] = tail
            otail.Next = nil

            QueueTask(NORMAL_PRIORITY, header, true)
        end

        return StartPhase()
    end)

    -- System Event Handler
    _EventManager = ISystemEvent()

    function _EventManager:OnEvent(event, ...)
        local header = p_Header[event]
        if not header then return end

        -- Clear
        p_Header[event] = nil
        p_Tail[event] = nil

        -- Fill args
        local task = header

        local args = tremove(c_Task) or {}

        args.NArgs = select('#', ...) + 1
        args.Used = 0
        args[1] = event
        for i = 1, args.NArgs do args[i + 1] = select(i, ...) end

        while task do
            if not task.NoEventArgs then
                task.Args = args
                args.Used = args.Used + 1
            else
                task.NoEventArgs = nil
            end

            task = task.Next
        end

        -- Attach to Queue
        return QueueTask(HIGH_PRIORITY, header)
    end
end

------------------------------------------------------------
--                     System.Task                        --
------------------------------------------------------------
__Doc__[[Task system used to improve performance for the whole system]]
__Sealed__() __Final__() __Abstract__() class "Task" (function(_ENV)

    ----------------------------------------------
    ---------------- Common Task -----------------
    ----------------------------------------------
    __Doc__[[
        <desc>Call method with high priority, the method should be called as soon as possible.</desc>
        <format>callable[, ...]</format>
        <param name="callable">Callable object like function, lambda, table</param>
        <param name="...">method parameter</param>
    ]]
    __Arguments__{ Callable, Argument{ Type = Any, Nilable = true, IsList = true } }
    __Static__() function DirectCall(callable, ...)
        local task = tremove(c_Task) or {}

        task.NArgs = select('#', ...)
        for i = 1, task.NArgs do task[i] = select(i, ...) end

        task.Method = callable

        return QueueTask(HIGH_PRIORITY, task)
    end

    __Doc__[[
        <desc>Call method with normal priority, the method should be called in the next phase.</desc>
        <format>callable[, ...]</format>
        <param name="callable">Callable object like function, lambda, table</param>
        <param name="...">method parameter</param>
    ]]
    __Arguments__{ Callable, Argument{ Type = Any, Nilable = true, IsList = true } }
    __Static__() function NextCall(callable, ...)
        local task = tremove(c_Task) or {}

        task.NArgs = select('#', ...)
        for i = 1, task.NArgs do task[i] = select(i, ...) end

        task.Method = callable

        return QueueTask(NORMAL_PRIORITY, task)
    end

    __Doc__[[
        <desc>Call method after several second</desc>
        <format>delay, callable[, ...]</format>
        <param name="delay">the time to delay</param>
        <param name="callable">Callable object like function, lambda, table</param>
        <param name="...">method parameter</param>
    ]]
    __Arguments__{ PositiveNumber, Callable, Argument{ Type = Any, Nilable = true, IsList = true } }
    __Static__() function DelayCall(delay, callable, ...)
        local task = tremove(c_Task) or {}

        task.NArgs = select('#', ...)
        for i = 1, task.NArgs do task[i] = select(i, ...) end

        task.Method = callable

        return QueueDelayTask((tonumber(delay) or 0) + GetTime(), task)
    end

    __Doc__[[
        <desc>Call method after special system event</desc>
        <format>event, callable[, ...]</format>
        <param name="event">the system event name</param>
        <param name="callable">Callable object like function, lambda, table</param>
        <return>true if the event is existed and task is registered</return>
    ]]
    __Arguments__{ String, Callable }
    __Static__() function EventCall(event, callable)
        local task = tremove(c_Task) or {}

        task.NArgs = 0
        task.Method = callable

        return QueueEventTask(tostring(event), task)
    end

    __Doc__[[
        <desc>Call methdo when not at combat</desc>
        <param name="func">function, the task function</param>
        <param name="...">the function's parameters</param>
    ]]
    __Arguments__{ Callable, Argument{ Type = Any, Nilable = true, IsList = true } }
    __Static__() function NoCombatCall(callable, ...)
        if not InCombatLockdown() then return callable(...) end

        local task = tremove(c_Task) or {}

        task.NArgs = select('#', ...)
        for i = 1, task.NArgs do task[i] = select(i, ...) end

        task.Method = callable
        task.NoEventArgs = true

        return QueueEventTask("PLAYER_REGEN_ENABLED", task)
    end

    __Doc__[[
        <desc>Call method with thread mode</desc>
        <format>callable[, ...]</format>
        <param name="callable">Callable object like function, lambda, table</param>
        <param name="...">method parameter</param>
    ]]
    __Arguments__{ Callable, Argument{ Type = Any, Nilable = true, IsList = true } }
    __Static__() function ThreadCall(...)
        local task = tremove(c_Task) or {}

        task.NArgs = select('#', ...)
        for i = 1, task.NArgs do task[i] = select(i, ...) end

        task.Method = callThread

        return QueueTask(HIGH_PRIORITY, task)
    end

    __Doc__[[
        <desc>Call method after special system events or time delay</desc>
        <format>callable, [delay, ][event, ...] </format>
        <param name="callable">Callable object like function, lambda, table</param>
        <param name="delay">the time to delay</param>
        <param name="event">the system event name</param>
        <return>true if the task is registered</return>
    ]]
    __Arguments__{ Callable, Argument{ Type = String + PositiveNumber, IsList = true } }
    __Static__() function WaitCall(callable, ...)
        local nargs = select('#', ...)

        local delayed = false
        local header = nil
        local tail = nil

        for i = 1, nargs do
            local v = select(i, ...)

            if type(v) == "number" and not delayed then
                delayed = true

                local task = tremove(c_Task) or {}
                task.NArgs = 0
                task.Method = callable

                QueueDelayTask((tonumber(delay) or 0) + GetTime(), task)

                if tail then
                    tail.Sibling = task
                    tail = task
                else
                    header, tail = task, task
                end
            elseif type(v) == "string" then
                local task = tremove(c_Task) or {}
                task.NArgs = 0
                task.Method = callable

                if QueueEventTask(v, task) then
                    if tail then
                        tail.Sibling = task
                        tail = task
                    else
                        header, tail = task, task
                    end
                else
                    tinsert(c_Task, wipe(task))
                end
            end
        end

        if not header then return false end

        tail.Sibling = header

        return true
    end

    ----------------------------------------------
    ---------------- Thread Task -----------------
    ----------------------------------------------
    __Doc__[[Check if the current thread should keep running or wait for next time slice]]
    __Arguments__{ }
    __Static__() function Continue()
        local thread = running()
        if not thread then error("Task.Continue() can only be used in a thread.", 2) end

        local task = tremove(c_Task) or {}
        task.NArgs = 0
        task.Method = thread

        QueueTask(HIGH_PRIORITY, task, true)

        return yield()
    end

    __Doc__[[Make the current thread wait for next phase]]
    __Arguments__{ }
    __Static__() function Next()
        local thread = running()
        if not thread then error("Task.Next() can only be used in a thread.", 2) end

        local task = tremove(c_Task) or {}
        task.NArgs = 0
        task.Method = thread

        QueueTask(NORMAL_PRIORITY, task, true)

        return yield()
    end

    __Doc__[[
        <desc>Delay the current thread for several second</desc>
        <param name="delay">the time to delay</param>
    ]]
    __Arguments__{ PositiveNumber }
    __Static__() function Delay(delay)
        local thread = running()
        if not thread then error("Task.Delay(delay) can only be used in a thread.", 2) end

        local task = tremove(c_Task) or {}

        task.NArgs = 0
        task.Method = thread

        QueueDelayTask((tonumber(delay) or 0) + GetTime(), task)

        return yield()
    end

    __Doc__[[
        <desc>Make the current thread wait for a system event</desc>
        <param name="event">the system event name</param>
        <return>true if the event is existed and task is registered</return>
    ]]
    __Arguments__{ String }
    __Static__() function Event(event)
        local thread = running()
        if not thread then error("Task.Event(event) can only be used in a thread.", 2) end

        local task = tremove(c_Task) or {}

        task.NArgs = 0
        task.Method = thread

        if QueueEventTask(tostring(event), task) then
            return yield()
        else
            error(("No '%s' event existed."):format(event), 2)
        end
    end

    __Doc__[[
        <desc>Call method after special system events or several times</desc>
        <format>[delay, ][event, ... ,] callable</format>
        <param name="delay">the time to delay</param>
        <param name="event">the system event name</param>
        <return>true if the task is registered</return>
    ]]
    __Arguments__{ Argument{ Type = String + PositiveNumber, IsList = true } }
    __Static__() function Wait(...)
        local thread = running()
        if not thread then error("Task.Wait(delay, event, ...) can only be used in a thread.", 2) end

        local delayed = false
        local header = nil
        local tail = nil

        for i = 1, select('#', ...) do
            local v = select(i, ...)

            if type(v) == "number" and not delayed then
                delayed = true

                local task = tremove(c_Task) or {}
                task.NArgs = 0
                task.Method = thread

                QueueDelayTask((tonumber(delay) or 0) + GetTime(), task)

                if tail then
                    tail.Sibling = task
                    tail = task
                else
                    header, tail = task, task
                end
            elseif type(v) == "string" then
                local task = tremove(c_Task) or {}
                task.NArgs = 0
                task.Method = thread

                if QueueEventTask(v, task) then
                    if tail then
                        tail.Sibling = task
                        tail = task
                    else
                        header, tail = task, task
                    end
                else
                    tinsert(c_Task, wipe(task))
                end
            end
        end

        if not header then error("No existed event or delay is specified.", 2) end

        tail.Sibling = header

        return yield()
    end
end)

------------------------------------------------------------
--                   Cancel Task Clear                    --
------------------------------------------------------------
do
    Task.ThreadCall(function()
        while true do
            for evt in pairs(p_Header) do
                if type(evt) == "string" then
                    local head = p_Header[evt]
                    local cnt = 0

                    while head and head.Cancel do
                        local nxt = head.Next
                        cnt = cnt + 1
                        tinsert(c_Task, wipe(head))
                        head = nxt
                    end

                    p_Header[evt] = head
                    p_Tail[evt] = nil

                    while head do
                        local nxt = head.Next

                        while nxt and nxt.Cancel do
                            local nnxt = nxt.Next
                            cnt = cnt + 1
                            tinsert(c_Task, wipe(nxt))
                            nxt = nnxt
                        end

                        head.Next = nxt

                        if nxt then
                            head = nxt
                        else
                            p_Tail[evt] = head
                            head = nil
                        end
                    end

                    if cnt > 0 then
                        Trace("[System.Task.Clear]%s : %d", evt, cnt)
                    end

                    Task.Continue()
                end
            end

            Task.Delay(10)
        end
    end)
end

------------------------------------------------------------
--                 Task System Diagnose                   --
------------------------------------------------------------
do
    function Diagnose()
        Trace("[System.Task]-----------------")

        Trace("[Delayed] %d", g_DelayedTask)
        Trace("[Average] %.2f ms", g_AverageTime)
        Trace("[Max Phase] %.2f ms", g_MaxPhaseTime)

        Trace("[System.Task]-----------------")

        g_DelayedTask = 0
        g_MaxPhaseTime = 0

        return Task.DelayCall(60, Diagnose)
    end

    Task.DelayCall(60, Diagnose)
end