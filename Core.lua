--========================================================--
--                Scorpio Addon FrameWork                 --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/12/12                              --
--========================================================--

--========================================================--
Module            "ScorpioCore"                      "1.1.0"
--========================================================--

namespace         "Scorpio"

import "System"
import "System.Threading"

------------------------------------------------------------
--                Scorpio - Addon Class                   --
------------------------------------------------------------
__ObjMethodAttr__() __Final__() __Sealed__()
_G.Scorpio = class (Scorpio) (function (_ENV)
    inherit "Module"

    ----------------------------------------------
    ------------------- Prepare ------------------
    ----------------------------------------------

    -------------------- META --------------------
    META_WEAKKEY            = { __mode = "k" }
    META_WEAKVAL            = { __mode = "v" }

    ------------------- Logger -------------------
    Log                     = Logger("Scorpio")
    Log.LogLevel            = 3

    ------------------- String -------------------
    local strtrim           = strtrim or function(s) return (s:gsub("^%s*(.-)%s*$", "%1")) or "" end

    ------------------- Error --------------------
    local geterrorhandler   = geterrorhandler or function() return print end
    local errorhandler      = errorhandler or function(err) return geterrorhandler()(err) end

    ------------------- Table --------------------
    local tblconcat         = table.concat
    local tinsert           = tinsert or table.insert
    local tremove           = tremove or table.remove
    local wipe              = wipe or function(t) for k in pairs(t) do t[k] = nil end return t end

    ------------------- Coroutine ----------------
    local create            = coroutine.create
    local resume            = coroutine.resume
    local running           = coroutine.running
    local status            = coroutine.status
    local wrap              = coroutine.wrap
    local yield             = coroutine.yield

    -------------------- Types -------------------
    __Sealed__() __Base__(String)
    struct "NEString" {
        __init = function(val) return strtrim(val) end,
        function(val) assert(strtrim(val) ~= "", "%s can't be empty.") end,
    }

    ----------------------------------------------
    -------------- Task System Helper ------------
    ----------------------------------------------
    -- Settings
    PHASE_THRESHOLD         = 50    -- The max task operation time per phase
    PHASE_TIME_FACTOR       = 0.4   -- The factor used to calculate the task operation time per phase
    PHASE_BALANCE_FACTOR    = 0.3   -- The factor used to balance tasks between the current and next phase
    EVENT_CLEAR_INTERVAL    = 100   -- The interval for event task clear
    EVENT_CLEAR_DELAY       = 10
    DIAGNOSE_DELAY          = 60

    -- Const
    HIGH_PRIORITY           = 1     -- For Continue
    NORMAL_PRIORITY         = 2     -- For Event, Next, Wait
    LOW_PRIORITY            = 3     -- For Delay

    -- Global variables
    g_Phase                 = 0     -- The Nth phase based on GetTime()
    g_PhaseTime             = 0
    g_Threshold             = 0     -- The threshold based on GetFramerate(), in ms
    g_InPhase               = false
    g_FinishedTask          = 0
    g_StartTime             = 0
    g_EndTime               = 0
    g_AverageTime           = 20    -- An useless init value
    g_ReqAddTime            = false

    -- For diagnosis
    g_DelayedTask           = 0
    g_MaxPhaseTime          = 0

    -- Wait thread token
    w_Token                 = {}
    w_Token_INDEX           = 1

    -- Task List
    t_Cache                 = {}    -- Cache Manager
    t_Tasks                 = {}    -- Core task list
    local t_DelayTasks      = nil   -- Delayed task
    t_EventTasks            = {}    -- Event Task
    t_WaitEventTasks        = {}    -- Wait Event Task

    -- Runtime task
    r_Tasks                 = {}
    r_Count                 = 0

    -- Phase API
    local function startPhase()
        if g_InPhase then return end
        g_InPhase = true

        -- Prepare the task list
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
            -- High priority means it should be processed as soon as possible
            -- Normal priority means it should be processed in the next phase as high priority
            -- Lower priority means it should be processed when there is enough time
            local r_Tail = r_Tasks[0]

            for i = HIGH_PRIORITY, NORMAL_PRIORITY do
                local cache = t_Tasks[i]

                if cache then
                    t_Tasks[i] = nil

                    if r_Tail then
                        r_Tail[0] = cache
                        r_Tail = cache
                    else
                        -- Init
                        r_Tasks[1] = cache
                        r_Tail = cache
                    end

                    r_Count = r_Count + #cache - (cache[-1] or 1) + 1
                end
            end

            r_Tasks[0] = r_Tail

            -- LOW_PRIORITY
            if not r_Tasks[LOW_PRIORITY] and t_Tasks[LOW_PRIORITY] then
                r_Tasks[LOW_PRIORITY] = t_Tasks[LOW_PRIORITY]
                t_Tasks[LOW_PRIORITY] = nil
            end

            local fps = GetFramerate() or 60
            if fps <= 1 then fps = 60 end

            g_PhaseTime = 1000 * PHASE_TIME_FACTOR / fps
            if g_PhaseTime > PHASE_THRESHOLD then g_PhaseTime = PHASE_THRESHOLD end

            g_Threshold = g_StartTime + g_PhaseTime
        elseif not r_Tasks[1] then
            -- Only tasks of high priority can be executed again and again in a phase
            local cache = t_Tasks[HIGH_PRIORITY]
            if cache then
                t_Tasks[HIGH_PRIORITY] = nil

                r_Tasks[1] = cache
                r_Tasks[0] = cache

                r_Count = #cache
            end
        end

        -- It's time to process tasks' execution
        -- Process the high priority tasks
        local r_Header = r_Tasks[1]
        local runoutIdx = nil

        while r_Header do
            for i = r_Header[-1] or 1, #r_Header do
                local now = debugprofilestop()

                -- The time is runout, check if can get some more time for the phase
                if g_Threshold <= now then
                    if not g_ReqAddTime then
                        g_ReqAddTime = true

                        -- Calc the tasks in the next phase
                        local remainTask = r_Count
                        for j = HIGH_PRIORITY, NORMAL_PRIORITY do
                            local cache = t_Tasks[j]
                            if cache then remainTask = remainTask + #cache end
                        end

                        local cost = remainTask * g_AverageTime * PHASE_BALANCE_FACTOR

                        if cost + g_PhaseTime > PHASE_THRESHOLD then cost = PHASE_THRESHOLD - g_PhaseTime end

                        g_Threshold = g_Threshold + cost

                        if g_Threshold <= now then
                            runoutIdx = i
                            break
                        end
                    else
                        runoutIdx = i
                        break
                    end
                end

                -- Process the task
                local ok, msg = resume(r_Header[i])
                if not ok then pcall(geterrorhandler(), msg) end
                g_FinishedTask = g_FinishedTask + 1
                r_Count = r_Count - 1
            end

            if runoutIdx and r_Header then
                r_Header[-1] = runoutIdx
                break
            end

            local nxt = r_Header[0]
            wipe(r_Header)
            tinsert(t_Cache, r_Header)
            r_Header = nxt
        end

        r_Tasks[1] = r_Header
        if not r_Header then r_Tasks[0] = nil end

        -- Process the low priority tasks
        if not runoutIdx and r_Tasks[LOW_PRIORITY] then
            r_Header = r_Tasks[LOW_PRIORITY]

            for i = r_Header[-1] or 1, #r_Header do
                if g_Threshold <= debugprofilestop() then
                    runoutIdx = i
                    break
                end

                -- Process the task
                local ok, msg = resume(r_Header[i])
                if not ok then pcall(geterrorhandler(), msg) end
                g_FinishedTask = g_FinishedTask + 1
            end

            if runoutIdx then
                r_Header[-1] = runoutIdx
            else
                r_Tasks[LOW_PRIORITY] = nil
            end
        end

        g_EndTime = debugprofilestop()

        g_InPhase = false

        -- Try again if have time with high priority tasks
        return g_Threshold > g_EndTime and t_Tasks[HIGH_PRIORITY] and startPhase()
    end

    -- Queue API
    local function queueTask(priority, task, noStart)
        local cache = t_Tasks[priority]
        if not cache then
            cache = tremove(t_Cache) or {}
            t_Tasks[priority] = cache
        end
        tinsert(cache, task)
        return not noStart and priority == HIGH_PRIORITY and startPhase()
    end

    local function queueDelayTask(time, task)
        -- Fix the time
        time = floor((GetTime() + time) * 10) / 10

        if not t_DelayTasks then
            t_DelayTasks = tremove(t_Cache) or {}
            t_DelayTasks[0] = time
            t_DelayTasks[1] = task
        else
            local header = t_DelayTasks
            local oHeader
            while header and header[0] < time do
                oHeader = header
                header = header[-1]
            end
            if header and header[0] == time then
                tinsert(header, task)
            else
                local dcache = tremove(t_Cache) or {}
                dcache[0] = time
                dcache[1] = task
                dcache[-1] = header

                if oHeader then
                    oHeader[-1] = dcache
                else
                    t_DelayTasks = dcache
                end
            end
        end
    end

    local function queueEventTask(event, task)
        if not _EventDistribution[event] then
            _EventDistribution[event] = setmetatable({}, META_WEAKKEY)
            pcall(ScorpioManager.RegisterEvent, ScorpioManager, event)
        end

        local cache = t_EventTasks[event]
        if not cache then
            cache = tremove(t_Cache) or {}
            t_EventTasks[event] = cache
        end

        tinsert(cache, task)
    end

    local function queueWaitEventTask(event, task)
        if not _EventDistribution[event] then
            _EventDistribution[event] = setmetatable({}, META_WEAKKEY)
            pcall(ScorpioManager.RegisterEvent, ScorpioManager, event)
        end

        local cache = t_WaitEventTasks[event]
        if not cache then
            cache = tremove(t_Cache) or {}
            cache[0] = GetTime() + EVENT_CLEAR_INTERVAL
            t_WaitEventTasks[event] = cache
        end

        tinsert(cache, task)
    end

    local function taskCallWithArgs(callable, ...)
        yield( running() )
        return callable(...)
    end

    local function noCombatCall(callable, ...)
        while InCombatLockdown() do Next() end
        return callable(...)
    end

    ----------------------------------------------
    ------------------ Helper --------------------
    ----------------------------------------------
    _EventDistribution      = {}
    _HookDistribution       = setmetatable({}, META_WEAKKEY)
    _SecureHookDistribution = setmetatable({}, META_WEAKKEY)

    _SlashCmdList           = _G.SlashCmdList
    _SlashCmdCount          = 0
    _SlashCmdHandler        = {}

    -- Whether the player is already logined
    _Logined                = false

    -- Cache for module properties
    _RootAddon              = setmetatable({}, META_WEAKVAL)
    _NotLoaded              = setmetatable({}, META_WEAKKEY)
    _DisabledModule         = setmetatable({}, META_WEAKKEY)

    local function callHandlers(map, ...)
        if not map then return end
        for obj, handler in pairs(map) do
            if not _DisabledModule[obj] then
                local ok, err = pcall(handler, ...)
                if not ok then errorhandler(err) end
            end
        end
    end

    local function directCallHandlers(map, ...)
        if not map then return end
        for obj, handler in pairs(map) do
            local ok, err = pcall(handler, ...)
            if not ok then errorhandler(err) end
        end
    end

    -- SlashCmd Operation
    local function newSlashCmd(slashCmd, map)
        -- New Slash Command
        _SlashCmdCount = _SlashCmdCount + 1

        -- Register it to the system
        _G["SLASH_SCORPIOCMD_".._SlashCmdCount.."_1"] = slashCmd
        _SlashCmdList["SCORPIOCMD_".._SlashCmdCount.."_"] = function(msg, input)
            local option, info

            if type(msg) == "string" then
                msg = strtrim(msg)

                if msg:sub(1, 1) == "\"" and msg:find("\"", 2) then
                    option, info = msg:match("\"([^\"]+)\"%s*(.*)")
                else
                    option, info = msg:match("(%S+)%s*(.*)")
                end

                if option then option = option:upper() end
            end

            if option and map[option] then
                return directCallHandlers(map[option], info, input)
            elseif map[0] then
                return directCallHandlers(map[0], msg, input)
            else
                -- Default handler
                if next(map) then
                    print("--======================--")
                    for opt, m in pairs(map) do
                        if type(m) == "table" then
                            print(("%s %s %s"):format(slashCmd:lower(), opt:lower(), map[opt .. "-desc"] or ""))
                        end
                    end
                    print("--======================--")
                end
            end
        end
    end

    local function loadingWithoutClear(self)
        if _NotLoaded[self] then
            OnLoad(self)
        end

        for _, mdl in self:GetModules() do loadingWithoutClear(mdl) end
    end

    local function loading(self)
        if _NotLoaded[self] then
            _NotLoaded[self] = nil
            OnLoad(self)
        end

        for _, mdl in self:GetModules() do loading(mdl) end
    end

    local function enablingWithCheck(self)
        if not _DisabledModule[self] then
            if _NotLoaded[self] then
                OnEnable(self)
            end

            for _, mdl in self:GetModules() do enablingWithCheck(mdl) end
        end
    end

    local function enabling(self)
        if _NotLoaded[self] then loading(self) end

        if not _DisabledModule[self] then
            OnEnable(self)

            for _, mdl in self:GetModules() do enabling(mdl) end
        end
    end

    local function disabling(self)
        if not _DisabledModule[self] then
            _DisabledModule[self] = true

            if _Logined then OnDisable(self) end

            for _, mdl in self:GetModules() do disabling(mdl) end
        end
    end

    local function tryEnable(self)
        if _DisabledModule[self] and self._Enabled then
            if not self._Parent or (not _DisabledModule[self._Parent]) then
                _DisabledModule[self] = nil

                OnEnable(self)

                for _, mdl in self:GetModules() do
                    if mdl._Enabled then
                        tryEnable(mdl)
                    end
                end
            end
        end
    end

    local function exiting(self)
        OnQuit(self)

        for _, mdl in self:GetModules() do exiting(mdl) end
    end

    local function specChangedWithCheck(self, spec)
        if _NotLoaded[self] then
            OnSpecChanged(self, spec)
        end

        for _, mdl in self:GetModules() do specChangedWithCheck(mdl, spec) end
    end

    local function specChanged(self, spec)
        if not _Logined then return end

        OnSpecChanged(self, spec)

        for _, mdl in self:GetModules() do specChanged(mdl, spec) end
    end

    local function clearNotLoaded(self)
        _NotLoaded[self] = nil
        for _, mdl in self:GetModules() do clearNotLoaded(mdl) end
    end

    local function tryloading(self)
        if not self then return end

        if _Logined then
            loadingWithoutClear(self)
            enablingWithCheck(self)
            specChangedWithCheck(self, GetSpecialization() or 1)
            clearNotLoaded(self)
        else
            return loading(self)
        end
    end

    local function handleEventTask(cache, ...)
        local thread = running()
        local ok, msg

        for _, task in ipairs(cache) do
            if task then
                if type(task) ~= "thread" then
                    task = ThreadCall(taskCallWithArgs, task, ...)
                end
                ok, msg = resume(task, ...)
                if not ok then pcall(geterrorhandler(), msg) end
            end

            queueTask(HIGH_PRIORITY, thread, true)
            yield()
        end

        wipe(cache)
        tinsert(t_Cache, cache)
    end

    ----------------------------------------------
    -------------- Scorpio Manager ---------------
    ----------------------------------------------
    ScorpioManager = CreateFrame("Frame")

    function ScorpioManager:OnEvent(evt, ...)
        local cache = t_EventTasks[evt]
        if cache then
            t_EventTasks[evt] = nil
            queueTask(HIGH_PRIORITY, ThreadCall(taskCallWithArgs, handleEventTask, cache, ...))
        end

        local wcache = t_WaitEventTasks[evt]
        if wcache then
            t_WaitEventTasks[evt] = nil
            for i, v in ipairs(wcache) do
                local task = w_Token[v]
                if task then
                    w_Token[v] = nil
                    wcache[i] = task
                else
                    wcache[i] = false
                end
            end
            queueTask(HIGH_PRIORITY, ThreadCall(taskCallWithArgs, handleEventTask, wcache, evt, ...))
        end

        -- The System event handler may register event task
        -- So I should keep it won't bother the previous tasks
        -- Just call it at the last
        return callHandlers(_EventDistribution[evt], ...)
    end

    function ScorpioManager:OnUpdate()
        local now = GetTime()

        -- Make sure unexpected error won't stop the whole task system
        if now > g_Phase then g_InPhase = false end

        local cache = t_DelayTasks

        while cache and cache[0] <= now do
            for _, task in ipairs(cache) do
                local ty = type(task)

                if ty == "number" then
                    local rtask = w_Token[task]
                    if rtask then
                        w_Token[task] = nil
                        ty = type(rtask)
                    end
                    task = rtask
                end

                if task then
                    if ty ~= "thread" then
                        task = ThreadCall(taskCallWithArgs, task)
                    end

                    queueTask(LOW_PRIORITY, task)
                end
            end

            local ncache = cache[-1]
            wipe(cache)
            tinsert(t_Cache, cache)

            cache = ncache
        end

        t_DelayTasks = cache

        return startPhase()
    end

    ScorpioManager:SetScript("OnEvent", ScorpioManager.OnEvent)
    ScorpioManager:SetScript("OnUpdate", ScorpioManager.OnUpdate)

    function ScorpioManager.ADDON_LOADED(name)
        name = name:match("^[^%._]+")
        return name and tryloading(_RootAddon[name])
    end

    function ScorpioManager.PLAYER_LOGIN()
        local spec = GetSpecialization() or 1
        _Logined = true

        for _, addon in pairs(_RootAddon) do
            enabling(addon)
            specChanged(addon, spec)
        end
    end

    function ScorpioManager.PLAYER_LOGOUT()
        for _, addon in pairs(_RootAddon) do
            exiting(addon)
        end
    end

    function ScorpioManager.PLAYER_SPECIALIZATION_CHANGED()
        local spec = GetSpecialization() or 1
        for _, addon in pairs(_RootAddon) do
            specChanged(addon, spec)
        end
    end

    ----------------------------------------------
    ------------- System Event Method ------------
    ----------------------------------------------
    __Doc__[[
        <desc>Register system event or custom event</desc>
        <param name="event" type="string">the system|custom event name</param>
        <param name="handler" type="string|function">the event handler or its name</param>
    ]]
    __Arguments__{ NEString, Argument(NEString + Function, true) }
    function RegisterEvent(self, evt, handler)
        local map = _EventDistribution[evt]
        if not map then
            pcall(ScorpioManager.RegisterEvent, ScorpioManager, evt)
            map = setmetatable({}, META_WEAKKEY)
            _EventDistribution[evt] = map
        end

        handler = handler or evt
        if type(handler) == "string" then handler = self[handler] end
        if type(handler) ~= "function" then error("Scorpio:RegisterEvent(event[, handler]) -- handler not existed.", 2) end

        map[self] = handler
    end

    __Doc__[[
        <desc>Whether the system event or custom event is registered</desc>
        <param name="event" type="string">the system|custom event name</param>
        <return>true if the event is registered</return>
    ]]
    __Arguments__{ NEString }
    function IsEventRegistered(self, evt)
        local map = _EventDistribution[evt]
        return map and map[self] and true or false
    end

    __Doc__[[
        <desc>Unregister system event or custom event</desc>
        <param name="event" type="string">the system|custom event name</param>
    ]]
    __Arguments__{ NEString }
    function UnregisterEvent(self, evt)
        local map = _EventDistribution[evt]
        if map and map[self] then
            map[self] = nil
        end
    end

    __Doc__[[Unregister all the events]]
    function UnregisterAllEvents(self)
        for evt, map in pairs(_EventDistribution) do
            if map[self] then
                map[self] = nil
            end
        end
    end

    __Doc__[[
        <desc>Fire the system event</desc>
        <param name="event" type="string">the event's name</param>
        <param name="...">the other arguments</param>
    ]]
    function FireSystemEvent(self, ...)
        if type(self) == "string" then
            return ScorpioManager:OnEvent(self, ...)
        elseif type(self) == "table" and type(select(1, ...)) == "string" then
            return ScorpioManager:OnEvent(...)
        end
    end

    ----------------------------------------------
    ------------- Hook System Method -------------
    ----------------------------------------------
    __Doc__[[
        <desc>Hook a table's function</desc>
        <format>[target, ]targetFunction[, handler]</format>
        <param name="target" type="table">the target table, default _G</param>
        <param name="targetFunction" type="string">the hook function name</param>
        <param name="handler" type="string">the hook handler, default the targetFunction</param>
    ]]
    __Arguments__{ Table, NEString, Argument(NEString + Function, true) }
    function Hook(self, target, targetFunc, handler)
        if type(target[targetFunc]) ~= "function" then
            error(("No method named '%s' can be found."):format(targetFunc), 2)
        elseif issecurevariable(target, targetFunc) then
            error(("'%s' is secure method, use SecureHook instead."):format(targetFunc), 2)
        end

        _HookDistribution[target] = _HookDistribution[target] or setmetatable({}, META_WEAKKEY)

        local map = _HookDistribution[target][targetFunc]

        if not map then
            map = setmetatable({}, META_WEAKKEY)
            _HookDistribution[target][targetFunc]  = map

            local _orig = target[targetFunc]
            target[targetFunc] = function(...) callHandlers(map, ...) return _orig(...) end
        end

        handler = handler or targetFunc
        if type(handler) == "string" then handler = self[handler] end
        if type(handler) ~= "function" then error("Scorpio:Hook([target, ]targetFunc[, handler]) -- handler not existed.", 2) end

        map[self] = handler
    end

    __Arguments__{ NEString, Argument(NEString + Function, true) }
    function Hook(self, targetFunc, handler) return Hook(self, _G, targetFunc, handler) end

    __Doc__[[
        <desc>Un-hook a table's function</desc>
        <format>[target, ]targetFunction</format>
        <param name="target" type="table">the target table, default _G</param>
        <param name="targetFunction" type="string">the hook function name</param>
    ]]
    __Arguments__{ Table, NEString }
    function UnHook(self, target, targetFunc)
        if _HookDistribution[target] and _HookDistribution[target][targetFunc] then
            _HookDistribution[target][targetFunc][self] = nil
        end
    end

    __Arguments__{ NEString }
    function UnHook(self, targetFunc)
        return UnHook(self, _G, targetFunc)
    end

    __Doc__[[Un-hook all functions]]
    function UnHookAll(self)
        for _, target in pairs(_HookDistribution) do for _, map in pairs(target) do map[self] = nil end end
    end

    __Doc__[[
        <desc>Secure hook a table's function</desc>
        <format>[target, ]targetFunction[, handler]</format>
        <param name="target" type="table">the target table, default _G</param>
        <param name="targetFunction" type="string">the hook function name</param>
        <param name="handler" type="string">the hook handler</param>
    ]]
    __Arguments__{ Table, NEString, Argument(NEString + Function, true) }
    function SecureHook(self, target, targetFunc, handler)
        if type(target[targetFunc]) ~= "function" then
            error(("No method named '%s' can be found."):format(targetFunc), 2)
        end
        _SecureHookDistribution[target] = _SecureHookDistribution[target] or setmetatable({}, META_WEAKKEY)

        local map = _SecureHookDistribution[target][targetFunc]

        if not map then
            map = setmetatable({}, META_WEAKKEY)
            _SecureHookDistribution[target][targetFunc] = map

            hooksecurefunc(target, targetFunc, function(...) return callHandlers(map, ...) end)
        end

        handler = handler or targetFunc
        if type(handler) == "string" then handler = self[handler] end
        if type(handler) ~= "function" then error("Scorpio:SecureHook([target, ]targetFunc[, handler]) -- handler not existed.", 2) end

        map[self] = handler
    end

    __Arguments__{ NEString, Argument(NEString + Function, true) }
    function SecureHook(self, targetFunc, handler) return SecureHook(self, _G, targetFunc, handler) end

    __Doc__[[
        <desc>Un-hook a table's function</desc>
        <format>[target, ]targetFunction</format>
        <param name="target" type="table">the target table, default _G</param>
        <param name="targetFunction" type="string">the hook function name</param>
    ]]
    __Arguments__{ Table, NEString }
    function SecureUnHook(self, target, targetFunc)
        if _SecureHookDistribution[target] and _SecureHookDistribution[target][targetFunc] then
            _SecureHookDistribution[target][targetFunc][self] = nil
        end
    end

    __Arguments__{ NEString }
    function SecureUnHook(self, targetFunc) return SecureUnHook(self, _G, targetFunc) end

    __Doc__[[Un-hook all functions]]
    function SecureUnHookAll(self) for _, target in pairs(_SecureHookDistribution) do for _, map in pairs(target) do map[self] = nil end end end

    ----------------------------------------------
    ------------ Slash Command Method ------------
    ----------------------------------------------
    __Doc__[[
        <desc>Register a slash command with handler</desc>
        <param name="slashCmd" type="string">the slash command, case ignored</param>
        <param name="handler" type="string|function">handler</param>
    ]]
    __Arguments__{ NEString, NEString + Function }
    function RegisterSlashCommand(self, slashCmd, handler)
        slashCmd = slashCmd:upper():match("^/?(%w+)")
        if slashCmd == "" then error("The slash command can only be letters and numbers.", 2) end
        slashCmd = "/" .. slashCmd

        local map = _SlashCmdHandler[slashCmd]

        if not map then
            map = {}
            _SlashCmdHandler[slashCmd] = map
            newSlashCmd(slashCmd, map)
        end

        if type(handler) == "string" then handler = self[handler] end
        if type(handler) ~= "function" then error("Scorpio:RegisterSlashCommand(slashCmd, handler) -- handler not existed.", 2) end

        map[0] = { [self] = handler }
    end

    __Doc__[[
        <desc>Register a slash command with handler</desc>
        <param name="slashCmd" type="string">the slash command, case ignored</param>
        <param name="option" type="string">the slash command option, case ignored</param>
        <param name="handler" type="string|function">handler</param>
    ]]
    __Arguments__{ NEString, NEString, NEString + Function, Argument(NEString, true) }
    function RegisterSlashCmdOption(self, slashCmd, option, handler, desc)
        slashCmd = slashCmd:upper():match("^/?(%w+)")
        if slashCmd == "" then error("The slash command can only be letters and numbers.", 2) end
        slashCmd = "/" .. slashCmd

        option = option:upper():match("^%w+")
        if not option or option == "" then error("The slash command option can only be letters and numbers.", 2) end

        local map = _SlashCmdHandler[slashCmd]

        if not map then
            map = {}
            _SlashCmdHandler[slashCmd] = map
            newSlashCmd(slashCmd, map)
        end

        if type(handler) == "string" then handler = self[handler] end
        if type(handler) ~= "function" then error("Scorpio:RegisterSlashCmdOption(slashCmd, option, handler[, description]) -- handler not existed.", 2) end

        map[option] = { [self] = handler }
        map[option .. "-desc"] = desc
    end

    ----------------------------------------------
    ------------- Task System Method -------------
    ----------------------------------------------
    __Doc__[=[
        <desc>Call method or continue thread with high priority, the method(thread) should be called(resumed) as soon as possible.</desc>
        <format>[func[, ...]]</format>
        <param name="func">The function</param>
        <param name="...">method parameter</param>
    ]=]
    __Arguments__{ Function, { Nilable = true, IsList = true } }
    __Static__() function Continue(func, ...)
        return queueTask(HIGH_PRIORITY, ThreadCall(taskCallWithArgs, func, ...))
    end

    __Arguments__{ }
    __Static__() function Continue()
        local thread = running()
        if not thread then error("Scorpio.Continue() can only be used in a thread.", 2) end

        queueTask(HIGH_PRIORITY, thread, true)

        return yield()
    end

    __Doc__[=[
        <desc>Call method or resume thread with normal priority, the method(thread) should be called(resumed) in the next phase.</desc>
        <format>[func[, ...]]</format>
        <param name="func">The function</param>
        <param name="...">method parameter</param>
    ]=]
    __Arguments__{ Function, { Nilable = true, IsList = true } }
    __Static__() function Next(func, ...)
        return queueTask(NORMAL_PRIORITY, ThreadCall(taskCallWithArgs, func, ...))
    end

    __Arguments__{ }
    __Static__() function Next()
        local thread = running()
        if not thread then error("Scorpio.Next() can only be used in a thread.", 2) end

        queueTask(NORMAL_PRIORITY, thread, true)

        return yield()
    end

    __Doc__[=[
        <desc>Call method|yield current thread and resume it after several seconds</desc>
        <format>delay[, func[, ...]]</format>
        <param name="delay">the time to delay</param>
        <param name="func">The function</param>
        <param name="...">method parameter</param>
    ]=]
    __Arguments__{ PositiveNumber, Function, { Nilable = true, IsList = true } }
    __Static__() function Delay(delay, func, ...)
        return queueDelayTask(delay, ThreadCall(taskCallWithArgs, func, ...))
    end

    __Arguments__{ PositiveNumber }
    __Static__() function Delay(delay)
        local thread = running()
        if not thread then error("Scorpio.Delay(delay) can only be used in a thread.", 2) end

        queueDelayTask(delay, thread)

        return yield()
    end

    __Doc__[=[
        <desc>Call method|yield current thread and resume it after special system event</desc>
        <format>event[, func[, ...]]</format>
        <param name="event">the system event name</param>
        <param name="func">The function</param>
        <param name="...">method parameter</param>
    ]=]
    __Arguments__{ NEString, Function, { Nilable = true, IsList = true } }
    __Static__() function Event(event, func, ...)
        if select("#", ...) > 0 then
            return queueEventTask(event, ThreadCall(taskCallWithArgs, func, ...))
        else
            return queueEventTask(event, func)
        end
    end

    __Arguments__{ NEString }
    __Static__() function Event(event)
        local thread = running()
        if not thread then error("Scorpio.Event(event) can only be used in a thread.", 2) end

        queueEventTask(event, thread)

        return yield()
    end

    __Doc__[=[
        <desc>Call method|contine thread when not in combat</desc>
        <format>[func[, ...]]</format>
        <param name="func">The function</param>
        <param name="...">the arguments</param>
    ]=]
    __Arguments__{ Function, { Nilable = true, IsList = true } }
    __Static__() function NoCombat(func, ...)
        if not InCombatLockdown() then return ThreadCall(func, ...) end

        return Event("PLAYER_REGEN_ENABLED", noCombatCall, func, ...)
    end

    __Arguments__{ }
    __Static__() function NoCombat()
        if not InCombatLockdown() then return end
        if not running() then error("Scorpio.NoCombat() can only be used in a thread.", 2) end

        Event("PLAYER_REGEN_ENABLED")

        while InCombatLockdown() do Next() end
    end

    __Doc__[[
        <desc>Call method|yield current thread and resume it after special system events or time delay</desc>
        <format>[func, ][waitTime, ][event, ...]</format>
        <param name="func">The function</param>
        <param name="waitTime">the time to wait</param>
        <param name="event">the system event name</param>
    ]]
    __Arguments__{ Function, PositiveNumber, Argument{ Type = NEString, IsList = true, Nilable = true } }
    __Static__() function Wait(func, delay, ...)
        local token = w_Token_INDEX
        w_Token_INDEX = w_Token_INDEX + 1

        queueDelayTask(delay, token)

        for i = 1, select("#", ...) do
            queueWaitEventTask(select(i, ...), token)
        end

        w_Token[token] = func
    end

    __Arguments__{ Function, Argument{ Type = NEString, IsList = true } }
    __Static__() function Wait(func, ...)
        local token = w_Token_INDEX
        w_Token_INDEX = w_Token_INDEX + 1

        for i = 1, select("#", ...) do
            queueWaitEventTask(select(i, ...), token)
        end

        w_Token[token] = func
    end

    __Arguments__{ PositiveNumber, Argument{ Type = NEString, IsList = true, Nilable = true } }
    __Static__() function Wait(delay, ...)
        local thread = running()
        if not thread then error("Scorpio.Wait([waitTime, ][event, ...]) can only be used in a thread.", 2) end

        local token = w_Token_INDEX
        w_Token_INDEX = w_Token_INDEX + 1

        queueDelayTask(delay, token)

        for i = 1, select("#", ...) do
            queueWaitEventTask(select(i, ...), token)
        end

        w_Token[token] = thread

        return yield()
    end

    __Arguments__{ Argument{ Type = NEString, IsList = true } }
    __Static__() function Wait(...)
        local thread = running()
        if not thread then error("Scorpio.Wait([waitTime, ][event, ...]) can only be used in a thread.", 2) end

        local token = w_Token_INDEX
        w_Token_INDEX = w_Token_INDEX + 1

        for i = 1, select("#", ...) do
            queueWaitEventTask(select(i, ...), token)
        end

        w_Token[token] = thread

        return yield()
    end

    ----------------------------------------------
    ------------------- Event --------------------
    ----------------------------------------------
    __Doc__[[Fired when the addon(module) and it's saved variables is loaded]]
    event "OnLoad"

    __Doc__[[Fired when player specialization changed]]
    event "OnSpecChanged"

    __Doc__[[Fired when the addon(module) is enabled]]
    event "OnEnable"

    __Doc__[[Fired when the addon(module) is disabled]]
    event "OnDisable"

    __Doc__[[Fired when the player log out]]
    event "OnQuit"

    ----------------------------------------------
    ------------------ Property ------------------
    ----------------------------------------------
    __Doc__[[Whether the module is enabled]]
    __Handler__(function(self, val) if val then return tryEnable(self) else return disabling(self) end end)
    property "_Enabled" { Type = Boolean, Default = true }

    __Doc__[[Whether the module is disabled by itself or it's parent]]
    property "_Disabled" { Get = function (self) return _DisabledModule[self] or false end }

    __Doc__[[The addon of the module]]
    property "_Addon" { Get = function(self) while self._Parent do self = self._Parent end return self end }

    ----------------------------------------------
    ------------------- Dispose ------------------
    ----------------------------------------------
    function Dispose(self)
        self:UnregisterAllEvents()

        self:UnHookAll()
        self:SecureUnHookAll()

        for _, map in pairs(_SlashCmdHandler) do
            for k, smap in pairs(map) do
                if smap[self] then
                    map[k] = nil
                end
            end
        end

        _RootAddon[self._Name] = nil
        _NotLoaded[self] = nil
        _DisabledModule[self] = nil
    end

    ----------------------------------------------
    ----------------- Constructor ----------------
    ----------------------------------------------
    function Scorpio(self, ...)
        Super(self, ...)

        _NotLoaded[self] = true

        if not self._Parent then
            -- Means this is an addon
            _RootAddon[self._Name] = self

            -- Common namespaces should be imported as default
            self.import "Scorpio"
            self.import "System"
            self.import "System.Threading"
            self.import "System.Collections"
        elseif _DisabledModule[self._Parent] then
            -- Register disabled modules
            _DisabledModule[self] = true
        end
    end

    ----------------------------------------------
    ----------------- Attributes -----------------
    ----------------------------------------------
    __Doc__[[
        <desc>Register a system event with a handler, the handler's name is the event name</desc>
        <usage>
            Scorpio "MyAddon" "v1.0.1"

            __SystemEvent__()
            function ADDON_LOADED(name)
                print("Addon " .. name .. " is loaded.")
            end

            __SystemEvent__ "PLAYER_LOGIN" "PLAYER_LOGOUT"
            function PLAYER_LOGIN(...)
                -- The event's name won't be passed to it
            end
        </usage>
    ]]
    __AttributeUsage__{AttributeTarget = AttributeTargets.ObjectMethod, RunOnce = true, AllowMultiple = true}
    __Sealed__()
    class "__SystemEvent__" (function(_ENV)
        extend "IAttribute"

        function ApplyAttribute(self, target, targetType, owner, name)
            if getmetatable(owner) == Scorpio then
                if #self > 0 then
                    for _, evt in ipairs(self) do
                        owner:RegisterEvent(evt, target)
                    end
                else
                    owner:RegisterEvent(name, target)
                end
            else
                error("__SystemEvent__ can only be applyed to objects of Scorpio.")
            end
        end

        ----------------------------------------------
        ------------------ Property ------------------
        ----------------------------------------------
        property "Priorty" { Type = AttributePriorty, Default = AttributePriorty.Lowest }

        ----------------------------------------------
        ----------------- Constructor ----------------
        ----------------------------------------------
        __Arguments__{ Argument(NEString, true, nil, nil, true) }
        function __SystemEvent__(self, ...)
            for i = 1, select('#', ...) do
                tinsert(self, select(i, ...))
            end
        end

        ----------------------------------------------
        ----------------- Meta-Method ----------------
        ----------------------------------------------
        __Arguments__{ NEString }
        function __call(self, other)
            tinsert(self, other)
            return self
        end

        -- Make sure multi can be appled
        function __eq(self, other) return false end
    end)

    __Doc__[[
        <desc>Mark the method as a hook</desc>
        <usage>
            Scorpio "MyAddon" "v1.0.1"

            -- Calc how many times the print is called, hook the "print" function
            __Hook__ "print"
            function hook_print(...)
                _printCnt = (_printCnt or 0) + 1
            end

            -- also can be simple like if you don't use the print function in your addon.
            __Hook__()
            function print(...)
                _printCnt = (_printCnt or 0) + 1
            end

            -- If you want specific the table, do it like :
            __Hook__(math)
            function random(...)
            end

            -- or
            __Hook__(math, "random")
            function math_random(...)
            end
        </usage>
    ]]
    __AttributeUsage__{AttributeTarget = AttributeTargets.ObjectMethod, RunOnce = true}
    __Sealed__()
    class "__Hook__" (function(_ENV)
        extend "IAttribute"

        function ApplyAttribute(self, target, targetType, owner, name)
            if getmetatable(owner) == Scorpio then
                owner:Hook(self.Target, self.TargetFunc or name, target)
            else
                error("__Hook__ can only be applyed to objects of Scorpio.")
            end
        end

        ----------------------------------------------
        ------------------ Property ------------------
        ----------------------------------------------
        property "Priorty" { Type = AttributePriorty, Default = AttributePriorty.Lowest }

        ----------------------------------------------
        ----------------- Constructor ----------------
        ----------------------------------------------
        __Arguments__{ Table, Argument(NEString, true) }
        function __Hook__(self, target, targetFunc)
            self.Target = target
            self.TargetFunc = targetFunc
        end

        __Arguments__{ Argument(NEString, true) }
        function __Hook__(self, targetFunc)
            self.Target = _G
            self.TargetFunc = targetFunc
        end
    end)

    __Doc__[[
        <desc>Mark the method as a hook</desc>
        <usage>
            Scorpio "MyAddon" "v1.0.1"

            -- Modify each buff button's texture when they are created
            __SecureHook__()
            function BuffButton_OnLoad(self)

                -- We should secure hook the texture's SetTexture to do modifiy
                -- Normally, these should be done like
                -- _M:SecureHook(_G[self:GetName() .. "Icon"], "SetTexture", HookSetTexture)
                -- Just for an example
                __SecureHook__(_G[self:GetName() .. "Icon"])
                function SetTexture(self, path)
                    if path then
                        self:SetTexCoord(0.06, 0.94, 0.06, 0.94)
                    end
                end
            end
        </usage>
    ]]
    __AttributeUsage__{AttributeTarget = AttributeTargets.ObjectMethod, RunOnce = true}
    __Sealed__()
    class "__SecureHook__" (function(_ENV)
        extend "IAttribute"

        function ApplyAttribute(self, target, targetType, owner, name)
            if getmetatable(owner) == Scorpio then
                owner:SecureHook(self.Target, self.TargetFunc or name, target)
            else
                error("__SecureHook__ can only be applyed to objects of Scorpio.")
            end
        end

        ----------------------------------------------
        ------------------ Property ------------------
        ----------------------------------------------
        property "Priorty" { Type = AttributePriorty, Default = AttributePriorty.Lowest }

        ----------------------------------------------
        ----------------- Constructor ----------------
        ----------------------------------------------
        __Arguments__{ Table, Argument(NEString, true) }
        function __SecureHook__(self, target, targetFunc)
            self.Target = target
            self.TargetFunc = targetFunc
        end

        __Arguments__{ Argument(NEString, true) }
        function __SecureHook__(self, targetFunc)
            self.Target = _G
            self.TargetFunc = targetFunc
        end
    end)

    __Doc__[[
        <desc>Register a slash cmd with handler</desc>
        <usage>
            Scorpio "MyAddon" "v1.0.1"

            Log = Logger("MyAddon")

            -- "/myaddon log 1" used to change the addon's log level
            __SlashCmd__ "/myaddon" "log"
            function TurnLog(lvl)
                Log.LogLevel = tonumber(lvl) or 2
            end

            -- "/myaddon" default slash command handler, used to display the detail
            __SlashCmd__ "/myaddon"
            function SlashCmd(msg)
                print("/myaddon log N - change the log level")
            end
        </usage>
    ]]
    __AttributeUsage__{AttributeTarget = AttributeTargets.ObjectMethod, RunOnce = true, AllowMultiple = true}
    __Sealed__()
    class "__SlashCmd__" (function(_ENV)
        extend "IAttribute"

        function ApplyAttribute(self, target, targetType, owner, name)
            if getmetatable(owner) == Scorpio then
                if not self.SlashOpt then
                    owner:RegisterSlashCommand(self.SlashCmd, target)
                else
                    owner:RegisterSlashCmdOption(self.SlashCmd, self.SlashOpt, target, self.SlashDesc)
                end
            else
                error("__SlashCmd__ can only be applyed to objects of Scorpio.")
            end
        end

        ----------------------------------------------
        ------------------ Property ------------------
        ----------------------------------------------
        property "Priorty" { Type = AttributePriorty, Default = AttributePriorty.Lowest }
        property "SlashCmd" { Type = NEString }
        property "SlashOpt" { Type = NEString }
        property "SlashDesc" { Type = NEString}

        ----------------------------------------------
        ----------------- Constructor ----------------
        ----------------------------------------------
        __Arguments__{ NEString, Argument(NEString, true), Argument(NEString, true) }
        function __SlashCmd__(self, slashCmd, slashOpt, slashDesc)
            self.SlashCmd = slashCmd
            self.SlashOpt = slashOpt
            self.SlashDesc = slashDesc
        end

        ----------------------------------------------
        ----------------- Meta-Method ----------------
        ----------------------------------------------
        __Arguments__{ NEString }
        function __call(self, str)
            if not self.SlashOpt then
                self.SlashOpt = str
                return self
            elseif not self.SlashDesc then
                self.SlashDesc = str
            end
        end
    end)

    __Doc__[[Mark the method so it only be called when the player is not in combat]]
    __AttributeUsage__{AttributeTarget = AttributeTargets.ObjectMethod, RunOnce = true}
    __Sealed__()
    class "__NoCombat__" (function(_ENV)
        extend "IAttribute"

        function __NoCombat__(self)
            local del = __Delegate__(NoCombat)
            del.Priorty = AttributePriorty.Lower
            del.SubLevel = -999
        end
    end)

    __Doc__[[
        <desc>Mark the method as a hook when the target's addon is loaded</desc>
        <usage>
            Scorpio "MyAddon" "v1.0.1"

            __AddonHook__ "AnotherAddon"
            function dosomeJob(...)
                -- Wait "AnotherAddon" loaded and hook the "dosomeJob" function
            end
        </usage>
    ]]
    __AttributeUsage__{AttributeTarget = AttributeTargets.ObjectMethod, RunOnce = true}
    __Sealed__()
    class "__AddonHook__" (function(_ENV)
        extend "IAttribute"

        function ApplyAttribute(self, target, targetType, owner, name)
            if getmetatable(owner) == Scorpio then
                local addon = self.Addon
                if IsAddOnLoaded(addon) then
                    owner:Hook(self.Target, self.TargetFunc or name, target)
                else
                    local targetTbl = self.Target
                    local targetFunc = self.TargetFunc or name

                    ThreadCall(function()
                        while Event("ADDON_LOADED") ~= addon do end
                        owner:Hook(targetTbl, targetFunc, target)
                    end)
                end
            else
                error("__AddonHook__ can only be applyed to objects of Scorpio.")
            end
        end

        ----------------------------------------------
        ------------------ Property ------------------
        ----------------------------------------------
        property "Priorty" { Type = AttributePriorty, Default = AttributePriorty.Lowest }

        ----------------------------------------------
        ----------------- Constructor ----------------
        ----------------------------------------------
        __Arguments__{ NEString, Argument(NEString, true) }
        function __AddonHook__(self, addon, targetFunc)
            self.Addon = addon
            self.Target = _G
            self.TargetFunc = targetFunc
        end
    end)

    __Doc__[[
        <desc>Mark the method as a secure hook when the target's addon is loaded</desc>
        <usage>
            Scorpio "MyAddon" "v1.0.1"

            -- Secure hook 'AuctionFrameTab_OnClick' when Blizzard_AuctionUI loaded
            __AddonSecureHook__ "Blizzard_AuctionUI"
            function AuctionFrameTab_OnClick(self, button, down, index)
            end

            __AddonSecureHook__ "Blizzard_AuctionUI" "AuctionFrameTab_OnClick"
            function Hook_Blizzard_AuctionUI(self, button, down, index)
            end
        </usage>
    ]]
    __AttributeUsage__{AttributeTarget = AttributeTargets.ObjectMethod, RunOnce = true}
    __Sealed__()
    class "__AddonSecureHook__" (function(_ENV)
        extend "IAttribute"

        function ApplyAttribute(self, target, targetType, owner, name)
            if getmetatable(owner) == Scorpio then
                local addon = self.Addon
                if IsAddOnLoaded(addon) then
                    owner:SecureHook(self.Target, self.TargetFunc or name, target)
                else
                    local targetTbl = self.Target
                    local targetFunc = self.TargetFunc or name

                    ThreadCall(function()
                        while Event("ADDON_LOADED") ~= addon do end
                        owner:SecureHook(targetTbl, targetFunc, target)
                    end)
                end
            else
                error("__AddonSecureHook__ can only be applyed to objects of Scorpio.")
            end
        end

        ----------------------------------------------
        ------------------ Property ------------------
        ----------------------------------------------
        property "Priorty" { Type = AttributePriorty, Default = AttributePriorty.Lowest }

        ----------------------------------------------
        ----------------- Constructor ----------------
        ----------------------------------------------
        __Arguments__{ NEString, Argument(NEString, true) }
        function __AddonSecureHook__(self, addon, targetFunc)
            self.Addon = addon
            self.Target = _G
            self.TargetFunc = targetFunc
        end
    end)

    ----------------------------------------------
    --------------- System Prepare ---------------
    ----------------------------------------------
    RegisterEvent(ScorpioManager, "ADDON_LOADED")
    RegisterEvent(ScorpioManager, "PLAYER_LOGIN")
    RegisterEvent(ScorpioManager, "PLAYER_LOGOUT")
    RegisterEvent(ScorpioManager, "PLAYER_SPECIALIZATION_CHANGED")

    -- Clear canceld event tasks
    ThreadCall(function()
        while true do
            local now = GetTime()

            for evt, cache in pairs(t_WaitEventTasks) do
                if cache[0] >= now then
                    local cnt = 0

                    for i = #cache, 1, -1 do
                        if not w_Token[cache[i]] then
                            cnt = cnt + 1
                            tremove(cache, i)
                        end
                    end

                    if cnt > 0 then Log(1, "Clear %d tasks for %s", cnt, evt) end

                    if #cache == 0 then
                        -- Only clear one cache at one time to avoid un-valid key error
                        t_WaitEventTasks[evt] = nil
                        wipe(cache)
                        tinsert(t_Cache, cache)

                        Log(1, "Recycle %s task cache", evt)
                        break
                    else
                        -- Wait to next cycle
                        cache[0] = now + EVENT_CLEAR_INTERVAL
                    end

                    -- Check if need contine
                    Continue()
                end
            end

            Delay(EVENT_CLEAR_DELAY)
        end
    end)

    -- Task System Diagnose
    ThreadCall(function()
        while true do
            Log(1, "--======================--")

            Log(1, "[Delayed] %d", g_DelayedTask)
            Log(1, "[Average] %.2f ms", g_AverageTime)
            Log(1, "[Max Phase] %.2f ms", g_MaxPhaseTime)

            Log(1, "--======================--")

            g_DelayedTask = 0
            g_MaxPhaseTime = 0

            Delay(DIAGNOSE_DELAY)
        end
    end)
end)