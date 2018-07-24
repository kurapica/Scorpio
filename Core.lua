--========================================================--
--                Scorpio Addon FrameWork                 --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/12/12                              --
--========================================================--

PLoop(function(_ENV)
    ------------------------------------------------------------
    --                Scorpio - Addon Class                   --
    ------------------------------------------------------------
    __Final__() __Sealed__()
    _G.Scorpio = class "Scorpio" (function (_ENV)
        inherit "Module"

        ----------------------------------------------
        --                  Prepare                 --
        ----------------------------------------------

        -------------------- META --------------------
        META_WEAKKEY            = { __mode = "k" }
        META_WEAKVAL            = { __mode = "v" }

        ------------------- Logger -------------------
        Log                     = Logger("Scorpio")
        Log.LogLevel            = 3

        export {
            ------------------- String -------------------
            strtrim             = strtrim or function(s) return (s:gsub("^%s*(.-)%s*$", "%1")) or "" end,

            ------------------- Error --------------------
            geterrorhandler     = geterrorhandler or function() return print end,
            errorhandler        = errorhandler or function(err) return geterrorhandler()(err) end,

            ------------------- Table --------------------
            tblconcat           = table.concat,
            tinsert             = tinsert or table.insert,
            tremove             = tremove or table.remove,
            wipe                = wipe or function(t) for k in pairs(t) do t[k] = nil end return t end,

            ------------------- Coroutine ----------------
            create              = coroutine.create,
            resume              = coroutine.resume,
            running             = coroutine.running,
            status              = coroutine.status,
            wrap                = coroutine.wrap,
            yield               = coroutine.yield,

            DefaultPool         = Threading.ThreadPool.Default,
        }

        ThreadCall              = function(...) return DefaultPool:ThreadCall(...) end

        ----------------------------------------------
        --            Task System Helper            --
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
        --                  Helper                  --
        ----------------------------------------------
        _EventDistribution      = {}
        _HookDistribution       = setmetatable({}, META_WEAKKEY)
        _SecureHookDistribution = setmetatable({}, META_WEAKKEY)

        _SlashCmdList           = _G.SlashCmdList
        _SlashCmdCount          = 0
        _SlashCmdHandler        = {}

        -- Whether the player is already logined
        _Logined                = false
        _PlayerSpec             = -1

        -- Cache for module properties
        _RootAddon              = setmetatable({}, META_WEAKVAL)
        _NotLoaded              = setmetatable({}, META_WEAKKEY)
        _DisabledModule         = setmetatable({}, META_WEAKKEY)

        local function callHandlers(map, ...)
            if not map then return end
            for obj, handler in pairs(map) do
                if obj ~= 0 and not _DisabledModule[obj] then
                    local ok, err = pcall(handler, ...)
                    if not ok then errorhandler(err) end
                end
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
                    if map[option](info, input) == false then
                        print("--======================--")
                        print(("%s %s %s"):format(slashCmd:lower(), option:lower(), map[option .. "-desc"] or ""))
                        print("--======================--")
                    end
                elseif map[0] and map[0](msg, input) ~= false then
                    -- pass
                else
                    -- Default handler
                    if next(map) then
                        print("--======================--")
                        for opt, m in pairs(map) do
                            if type(m) == "function" then
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

                if _Logined then
                    queueTask(HIGH_PRIORITY, thread, true)
                    yield()
                end
            end

            wipe(cache)
            tinsert(t_Cache, cache)
        end

        local function getHookMap(target, targetFunc)
            local map = _HookDistribution[target]

            if not map then
                map   = setmetatable({}, META_WEAKKEY)
                _HookDistribution[target] = map
            end

            map = map[targetFunc]

            if not map then
                if type(target[targetFunc]) ~= "function" then
                    error(("No method named '%s' can be found."):format(targetFunc))
                elseif issecurevariable(target, targetFunc) then
                    error(("'%s' is secure method, use SecureHook instead."):format(targetFunc))
                end

                map   = setmetatable({}, META_WEAKKEY)
                _HookDistribution[target][targetFunc]  = map

                local _orig = target[targetFunc]
                target[targetFunc] = function(...)
                    local cache = map[0]
                    if cache then
                        map[0] = false
                        if _Logined then
                            queueTask(HIGH_PRIORITY, ThreadCall(taskCallWithArgs, handleEventTask, cache, ...))
                        else
                            handleEventTask(cache, ...)
                        end
                    end

                    callHandlers(map, ...)
                    return _orig(...)
                end
            end

            return map
        end

        local function getSecureHookMap(target, targetFunc)
            local map = _SecureHookDistribution[target]

            if not map then
                map   = setmetatable({}, META_WEAKKEY)
                _SecureHookDistribution[target] = map
            end

            map = map[targetFunc]

            if not map then
                if type(target[targetFunc]) ~= "function" then
                    error(("No method named '%s' can be found."):format(targetFunc))
                end

                map   = setmetatable({}, META_WEAKKEY)
                _SecureHookDistribution[target][targetFunc] = map

                hooksecurefunc(target, targetFunc, function(...)
                    local cache = map[0]
                    if cache then
                        map[0] = false
                        if _Logined then
                            queueTask(HIGH_PRIORITY, ThreadCall(taskCallWithArgs, handleEventTask, cache, ...))
                        else
                            handleEventTask(cache, ...)
                        end
                    end

                    return callHandlers(map, ...)
                end)
            end

            return map
        end

        local function queueNextCall(target, targetFunc, task)
            local map = getHookMap(target, targetFunc)

            local cache = map[0]
            if not cache then
                cache  = tremove(t_Cache) or {}
                map[0] = cache
            end
            tinsert(cache, task)
        end

        local function queueNextSecureCall(target, targetFunc, task)
            local map = getSecureHookMap(target, targetFunc)

            local cache = map[0]
            if not cache then
                cache  = tremove(t_Cache) or {}
                map[0] = cache
            end
            tinsert(cache, task)
        end

        ----------------------------------------------
        --             Scorpio Manager              --
        ----------------------------------------------
        ScorpioManager = CreateFrame("Frame")

        function ScorpioManager:OnEvent(evt, ...)
            local cache = t_EventTasks[evt]
            if cache then
                t_EventTasks[evt] = nil
                if _Logined then
                    queueTask(HIGH_PRIORITY, ThreadCall(taskCallWithArgs, handleEventTask, cache, ...))
                else
                    handleEventTask(cache, ...)
                end
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
                if _Logined then
                    queueTask(HIGH_PRIORITY, ThreadCall(taskCallWithArgs, handleEventTask, wcache, evt, ...))
                else
                    handleEventTask(wcache, evt, ...)
                end
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
            local addon = _RootAddon[name]
            if addon then return tryloading(addon) end

            name = name:match("%P+")
            addon = name and _RootAddon[name]
            if addon then return tryloading(addon) end
        end

        function ScorpioManager.PLAYER_LOGIN()
            _PlayerSpec = GetSpecialization() or 1
            _Logined = true

            for _, addon in pairs(_RootAddon) do
                enabling(addon)
                specChanged(addon, _PlayerSpec)
            end
        end

        function ScorpioManager.PLAYER_LOGOUT()
            for _, addon in pairs(_RootAddon) do
                exiting(addon)
            end
        end

        function ScorpioManager.PLAYER_SPECIALIZATION_CHANGED(unit)
            if not unit or UnitIsUnit(unit, "player") then
                local spec = GetSpecialization() or 1
                if _PlayerSpec ~= spec then
                    _PlayerSpec = spec
                    for _, addon in pairs(_RootAddon) do
                        specChanged(addon, spec)
                    end
                end
            end
        end

        function ScorpioManager.PLAYER_ENTERING_WORLD()
            return ScorpioManager.PLAYER_SPECIALIZATION_CHANGED()
        end

        ----------------------------------------------
        --            System Event Method           --
        ----------------------------------------------
        --- Register system event or custom event
        -- @param event         string, the system|custom event name
        -- @param handler       string|function, the event handler or its name
        __Arguments__{ NEString, Variable.Optional(NEString + Function) }:Throwable()
        function RegisterEvent(self, evt, handler)
            local map = _EventDistribution[evt]
            if not map then
                pcall(ScorpioManager.RegisterEvent, ScorpioManager, evt)
                map = setmetatable({}, META_WEAKKEY)
                _EventDistribution[evt] = map
            end

            handler = handler or evt
            if type(handler) == "string" then handler = self[handler] end
            if type(handler) ~= "function" then throw("Scorpio:RegisterEvent(event[, handler]) -- handler not existed.") end

            map[self] = handler
        end

        --- Whether the system event or custom event is registered
        --@param  event          string, the system|custom event name
        --@return boolean       true if the event is registered
        __Arguments__{ NEString }
        function IsEventRegistered(self, evt)
            local map = _EventDistribution[evt]
            return map and map[self] and true or false
        end

        --- Get the registered handler of an event
        --@param  event         string, the system|custom event name
        --@return boolean       true if the event is registered
        __Arguments__{ NEString }
        function GetRegisteredEventHandler(self, evt)
            local map = _EventDistribution[evt]
            return map and map[self]
        end

        --- Unregister system event or custom event
        --@param event          string, the system|custom event name
        __Arguments__{ NEString }
        function UnregisterEvent(self, evt)
            local map = _EventDistribution[evt]
            if map and map[self] then
                map[self] = nil
            end
        end

        --- Unregister all the events
        function UnregisterAllEvents(self)
            for evt, map in pairs(_EventDistribution) do
                if map[self] then
                    map[self] = nil
                end
            end
        end

        --- Fire the system event
        --@param event          string, the event's name
        --@param ...            the other arguments
        function FireSystemEvent(self, ...)
            if type(self) == "string" then
                return ScorpioManager:OnEvent(self, ...)
            elseif type(self) == "table" and type(select(1, ...)) == "string" then
                return ScorpioManager:OnEvent(...)
            end
        end

        ----------------------------------------------
        --            Hook System Method            --
        ----------------------------------------------
        --- Hook a table's function
        --@format [target, ]targetFunction[, handler]
        --@param target         table, the target table, default _G
        --@param targetFunction string, the hook function name
        --@param handler        string, the hook handler, default the targetFunction
        __Arguments__{ Table, NEString, Variable.Optional(NEString + Function) }:Throwable()
        function Hook(self, target, targetFunc, handler)
            handler = handler or targetFunc
            if type(handler) == "string" then handler = self[handler] end
            if type(handler) ~= "function" then throw("Scorpio:Hook([target, ]targetFunc[, handler]) -- handler not existed.") end

            getHookMap(target, targetFunc)[self] = handler
        end

        __Arguments__{ NEString, Variable.Optional(NEString + Function) }:Throwable()
        function Hook(self, targetFunc, handler)
            handler = handler or targetFunc
            if type(handler) == "string" then handler = self[handler] end
            if type(handler) ~= "function" then throw("Scorpio:Hook([target, ]targetFunc[, handler]) -- handler not existed.") end

            getHookMap(target, targetFunc)[self] = handler
        end

        --- Un-hook a table's function
        --@format [target, ]targetFunction
        --@param target         table, the target table, default _G
        --@param targetFunction string, the hook function name
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

        --- Un-hook all functions
        function UnHookAll(self)
            for _, target in pairs(_HookDistribution) do for _, map in pairs(target) do map[self] = nil end end
        end

        --- Get the hook handler
        __Arguments__{ Table, NEString }
        function GetHookHandler(self, target, targetFunc)
            local map = _HookDistribution[target] and _HookDistribution[target][targetFunc]
            return map and map[self] or nil
        end

        __Arguments__{ NEString }
        function GetHookHandler(self, targetFunc)
            local map = _HookDistribution[_G] and _HookDistribution[_G][targetFunc]
            return map and map[self] or nil
        end

        --- Secure hook a table's function
        --@format [target, ]targetFunction[, handler]
        --@param target         table, the target table, default _G
        --@param targetFunction string, the hook function name
        --@param handler        string, the hook handler
        __Arguments__{ Table, NEString, Variable.Optional(NEString + Function) }:Throwable()
        function SecureHook(self, target, targetFunc, handler)
            handler = handler or targetFunc
            if type(handler) == "string" then handler = self[handler] end
            if type(handler) ~= "function" then throw("Scorpio:SecureHook([target, ]targetFunc[, handler]) -- handler not existed.") end

            getSecureHookMap(target, targetFunc)[self] = handler
        end

        __Arguments__{ NEString, Variable.Optional(NEString + Function) }:Throwable()
        function SecureHook(self, targetFunc, handler)
            if type(_G[targetFunc]) ~= "function" then
                throw(("No method named '%s' can be found."):format(targetFunc))
            end
            handler = handler or targetFunc
            if type(handler) == "string" then handler = self[handler] end
            if type(handler) ~= "function" then throw("Scorpio:SecureHook([target, ]targetFunc[, handler]) -- handler not existed.") end

            getSecureHookMap(_G, targetFunc)[self] = handler
        end

        --- Un-hook a table's function
        --@format [target, ]targetFunction
        --@param target         table, the target table, default _G
        --@param targetFunction string, the hook function name
        __Arguments__{ Table, NEString }
        function SecureUnHook(self, target, targetFunc)
            if _SecureHookDistribution[target] and _SecureHookDistribution[target][targetFunc] then
                _SecureHookDistribution[target][targetFunc][self] = nil
            end
        end

        __Arguments__{ NEString }
        function SecureUnHook(self, targetFunc) return SecureUnHook(self, _G, targetFunc) end

        --- Un-hook all functions
        function SecureUnHookAll(self) for _, target in pairs(_SecureHookDistribution) do for _, map in pairs(target) do map[self] = nil end end end

        --- Get the secure hook handler
        __Arguments__{ Table, NEString }
        function GetSecureHookHandler(self, target, targetFunc)
            local map = _SecureHookDistribution[target] and _SecureHookDistribution[target][targetFunc]
            return map and map[self] or nil
        end

        __Arguments__{ NEString }
        function GetSecureHookHandler(self, targetFunc)
            local map = _SecureHookDistribution[_G] and _SecureHookDistribution[_G][targetFunc]
            return map and map[self] or nil
        end

        ----------------------------------------------
        --           Slash Command Method           --
        ----------------------------------------------
        --- Register a slash command with handler
        --@param slashCmd       string, the slash command, case ignored
        --@param handler        string|function, handler
        __Arguments__{ NEString, NEString + Function }:Throwable()
        function RegisterSlashCommand(self, slashCmd, handler)
            slashCmd = slashCmd:upper():match("^/?(%w+)")
            if slashCmd == "" then throw("The slash command can only be letters and numbers.") end
            slashCmd = "/" .. slashCmd

            local map = _SlashCmdHandler[slashCmd]

            if not map then
                map = {}
                _SlashCmdHandler[slashCmd] = map
                newSlashCmd(slashCmd, map)
            end

            if type(handler) == "string" then handler = self[handler] end
            if type(handler) ~= "function" then throw("Scorpio:RegisterSlashCommand(slashCmd, handler) -- handler not existed.") end

            map[0] = handler
        end

        --- Register a slash command with handler
        --@param slashCmd       string, the slash command, case ignored
        --@param option         string, the slash command option, case ignored
        --@param handler        string|function, handler
        __Arguments__{ NEString, NEString, NEString + Function, Variable.Optional(NEString) }:Throwable()
        function RegisterSlashCmdOption(self, slashCmd, option, handler, desc)
            slashCmd = slashCmd:upper():match("^/?(%w+)")
            if slashCmd == "" then throw("The slash command can only be letters and numbers.") end
            slashCmd = "/" .. slashCmd

            option = option:upper():match("^%w+")
            if not option or option == "" then throw("The slash command option can only be letters and numbers.") end

            local map = _SlashCmdHandler[slashCmd]

            if not map then
                map = {}
                _SlashCmdHandler[slashCmd] = map
                newSlashCmd(slashCmd, map)
            end

            if type(handler) == "string" then handler = self[handler] end
            if type(handler) ~= "function" then throw("Scorpio:RegisterSlashCmdOption(slashCmd, option, handler[, description]) -- handler not existed.") end

            map[option] = handler
            map[option .. "-desc"] = desc
        end

        ----------------------------------------------
        --            Task System Method            --
        ----------------------------------------------
        ---Call method or continue thread with high priority, the method(thread) should be called(resumed) as soon as possible.
        --@format [func[, ...]]
        --@param func           The function
        --@param ...            method parameter
        __Arguments__{ Function, Variable.Rest() }
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

        ---Call method or resume thread with normal priority, the method(thread) should be called(resumed) in the next phase.
        --@format [func[, ...]]
        --@param func           The function
        --@param ...            method parameter
        __Arguments__{ Function, Variable.Rest() }
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

        --- Call method|yield current thread and resume it after several seconds
        --@format delay[, func[, ...]]
        --@param delay          the time to delay
        --@param func           The function
        --@param ...            method parameter
        __Arguments__{ Number, Function, Variable.Rest() }
        __Static__() function Delay(delay, func, ...)
            return queueDelayTask(delay, ThreadCall(taskCallWithArgs, func, ...))
        end

        __Arguments__{ Number }
        __Static__() function Delay(delay)
            local thread = running()
            if not thread then error("Scorpio.Delay(delay) can only be used in a thread.", 2) end

            queueDelayTask(delay, thread)

            return yield()
        end

        --- Call method|yield current thread and resume it after special system event
        --@format event[, func[, ...]]
        --@param event          the system event name
        --@param func           The function
        --@param ...            method parameter
        __Arguments__{ NEString, Function, Variable.Rest() }
        __Static__() function NextEvent(event, func, ...)
            if select("#", ...) > 0 then
                return queueEventTask(event, ThreadCall(taskCallWithArgs, func, ...))
            else
                return queueEventTask(event, func)
            end
        end

        __Arguments__{ NEString }
        __Static__() function NextEvent(event)
            local thread = running()
            if not thread then error("Scorpio.NextEvent(event) can only be used in a thread.", 2) end

            queueEventTask(event, thread)

            return yield()
        end

        --- Call method|contine thread when not in combat
        --@format [func[, ...]]
        --@param func           The function
        --@param ...            the arguments
        __Arguments__{ Function, Variable.Rest() }
        __Static__() function NoCombat(func, ...)
            if not InCombatLockdown() then return ThreadCall(func, ...) end

            return NextEvent("PLAYER_REGEN_ENABLED", noCombatCall, func, ...)
        end

        __Arguments__{ }
        __Static__() function NoCombat()
            if not InCombatLockdown() then return end
            if not running() then error("Scorpio.NoCombat() can only be used in a thread.", 2) end

            NextEvent("PLAYER_REGEN_ENABLED")

            while InCombatLockdown() do Next() end
        end

        --- Call method|yield current thread and resume it after special system events or time delay
        --@format [func, ][waitTime, ][event, ...]
        --@param func           The function
        --@param waitTime       the time to wait
        --@param event          the system event name
        __Arguments__{ Function, Number, Variable.Rest(NEString) }
        __Static__() function Wait(func, delay, ...)
            local token = w_Token_INDEX
            w_Token_INDEX = w_Token_INDEX + 1

            queueDelayTask(delay, token)

            for i = 1, select("#", ...) do
                queueWaitEventTask(select(i, ...), token)
            end

            w_Token[token] = func
        end

        __Arguments__{ Function, NEString * 1 }
        __Static__() function Wait(func, ...)
            local token = w_Token_INDEX
            w_Token_INDEX = w_Token_INDEX + 1

            for i = 1, select("#", ...) do
                queueWaitEventTask(select(i, ...), token)
            end

            w_Token[token] = func
        end

        __Arguments__{ Number, Variable.Rest(NEString) }
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

        __Arguments__{ NEString * 1 }
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

        --- Call method|yield current thread and resume it with un-secure object-method call
        --@format [func, ][target, ]targetFunction[, ...]
        --@param func           The function
        --@param target         table, the target table, default _G
        --@param targetFunction string, the target table's method name
        --@param ...            custom params if you don't need real params of the method-call
        __Arguments__{ Function, Table, NEString, Variable.Rest()}
        __Static__() function NextCall(func, target, targetFunc, ...)
            if select("#", ...) > 0 then
                queueNextCall(target, targetFunc, ThreadCall(taskCallWithArgs, func, ...))
            else
                queueNextCall(target, targetFunc, func)
            end
        end

        __Arguments__{ Function, NEString, Variable.Rest()}
        __Static__() function NextCall(func, targetFunc, ...)
            if select("#", ...) > 0 then
                queueNextCall(_G, targetFunc, ThreadCall(taskCallWithArgs, func, ...))
            else
                queueNextCall(_G, targetFunc, func)
            end
        end

        __Arguments__{ Table, NEString }
        __Static__() function NextCall(target, targetFunc)
            local thread = running()
            if not thread then error("Scorpio.NextCall([target, ]targetFunc) can only be used in a thread.", 2) end

            queueNextCall(target, targetFunc, thread)

            return yield()
        end

        __Arguments__{ NEString }
        __Static__() function NextCall(targetFunc)
            local thread = running()
            if not thread then error("Scorpio.NextCall([target, ]targetFunc) can only be used in a thread.", 2) end

            queueNextCall(_G, targetFunc, thread)

            return yield()
        end

        --- Call method|yield current thread and resume it after secure object-method call
        --@format [func, ][target, ]targetFunction[, ...]
        --@param func           The function
        --@param target         table, the target table, default _G
        --@param targetFunction string, the target table's method name
        --@param ...            custom params if you don't need real params of the method-call
        __Arguments__{ Function, Table, NEString, Variable.Rest()}
        __Static__() function NextSecureCall(func, target, targetFunc, ...)
            if select("#", ...) > 0 then
                queueNextSecureCall(target, targetFunc, ThreadCall(taskCallWithArgs, func, ...))
            else
                queueNextSecureCall(target, targetFunc, func)
            end
        end

        __Arguments__{ Function, NEString, Variable.Rest()}
        __Static__() function NextSecureCall(func, targetFunc, ...)
            if select("#", ...) > 0 then
                queueNextSecureCall(_G, targetFunc, ThreadCall(taskCallWithArgs, func, ...))
            else
                queueNextSecureCall(_G, targetFunc, func)
            end
        end

        __Arguments__{ Table, NEString }
        __Static__() function NextSecureCall(target, targetFunc)
            local thread = running()
            if not thread then error("Scorpio.NextSecureCall([target, ]targetFunc) can only be used in a thread.", 2) end

            queueNextSecureCall(target, targetFunc, thread)

            return yield()
        end

        __Arguments__{ NEString }
        __Static__() function NextSecureCall(targetFunc)
            local thread = running()
            if not thread then error("Scorpio.NextSecureCall([target, ]targetFunc) can only be used in a thread.", 2) end

            queueNextSecureCall(_G, targetFunc, thread)

            return yield()
        end

        ----------------------------------------------
        --                  Event                   --
        ----------------------------------------------
        --- Fired when the addon(module) and it's saved variables is loaded
        event "OnLoad"

        --- Fired when player specialization changed
        event "OnSpecChanged"

        --- Fired when the addon(module) is enabled
        event "OnEnable"

        --- Fired when the addon(module) is disabled
        event "OnDisable"

        --- Fired when the player log out
        event "OnQuit"

        ----------------------------------------------
        --                 Property                 --
        ----------------------------------------------
        --- Whether the module is enabled
        property "_Enabled" { type = Boolean, default = true, handler = function(self, val) if val then return tryEnable(self) else return disabling(self) end end }

        --- Whether the module is disabled by itself or it's parent
        property "_Disabled" { get = function (self) return _DisabledModule[self] or false end }

        --- The addon of the module
        property "_Addon" { get = function(self) while self._Parent do self = self._Parent end return self end }

        ----------------------------------------------
        --                  Dispose                 --
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
        --                Constructor               --
        ----------------------------------------------
        function Scorpio(self, ...)
            super(self, ...)

            _NotLoaded[self] = true

            if not self._Parent then
                -- Means this is an addon
                _RootAddon[self._Name] = self
            elseif _DisabledModule[self._Parent] then
                -- Register disabled modules
                _DisabledModule[self] = true
            end
        end

        ----------------------------------------------
        --                Attributes                --
        ----------------------------------------------
        --- Register a system event with a handler, the handler's name is the event name
        -- @usage
        --      Scorpio "MyAddon" "v1.0.1"
        --
        --      __SystemEvent__()
        --      function ADDON_LOADED(name)
        --          print("Addon " .. name .. " is loaded.")
        --      end
        --
        --      __SystemEvent__ "PLAYER_LOGIN" "PLAYER_LOGOUT"
        --      function PLAYER_LOGIN(...)
        --         -- The event's name won't be passed to it
        --      end
        __Sealed__()
        class "__SystemEvent__" (function(_ENV)
            extend "IAttachAttribute"

            function AttachAttribute(self, target, targettype, owner, name, stack)
                if Class.IsObjectType(owner, Scorpio) then
                    if #self > 0 then
                        for _, evt in ipairs(self) do
                            owner:RegisterEvent(evt, target)
                        end
                    else
                        owner:RegisterEvent(name, target)
                    end
                else
                    error("__SystemEvent__ can only be applyed to objects of Scorpio.", stack + 1)
                end
            end

            ----------------------------------------------
            --                 Property                 --
            ----------------------------------------------
            property "AttributeTarget"  { default = AttributeTargets.Function }

            ----------------------------------------------
            --                Constructor               --
            ----------------------------------------------
            __Arguments__{ Variable.Rest(NEString) }
            function __new(cls, ...)
                return { ... }, true
            end

            ----------------------------------------------
            --                Meta-Method               --
            ----------------------------------------------
            __Arguments__{ NEString }
            function __call(self, other)
                tinsert(self, other)
                return self
            end
        end)

        --- Mark the method as a hook
        -- @usage
        --      Scorpio "MyAddon" "v1.0.1"
        --
        --      -- Calc how many times the print is called, hook the "print" function
        --      __Hook__ "print"
        --      function hook_print(...)
        --          _printCnt = (_printCnt or 0) + 1
        --      end
        --
        --      -- also can be simple like if you don't use the print function in your addon.
        --      __Hook__()
        --      function print(...)
        --          _printCnt = (_printCnt or 0) + 1
        --      end
        --
        --      -- If you want specific the table, do it like :
        --      __Hook__(math)
        --      function random(...)
        --      end
        --
        --      -- or
        --      __Hook__(math, "random")
        --      function math_random(...)
        --      end
        __Sealed__()
        class "__Hook__" (function(_ENV)
            extend "IAttachAttribute"

            function AttachAttribute(self, target, targettype, owner, name, stack)
                if Class.IsObjectType(owner, Scorpio) then
                    owner:Hook(self.Target, self.TargetFunc or name, target)
                else
                    error("__Hook__ can only be applyed to objects of Scorpio.", stack + 1)
                end
            end

            ----------------------------------------------
            --                 Property                 --
            ----------------------------------------------
            property "AttributeTarget"  { default = AttributeTargets.Function }

            ----------------------------------------------
            --                Constructor               --
            ----------------------------------------------
            __Arguments__{ Table, Variable.Optional(NEString) }
            function __Hook__(self, target, targetFunc)
                self.Target = target
                self.TargetFunc = targetFunc
            end

            __Arguments__{ Variable.Optional(NEString) }
            function __Hook__(self, targetFunc)
                self.Target = _G
                self.TargetFunc = targetFunc
            end
        end)

        --- Mark the method as a hook
        -- @usage
        --      Scorpio "MyAddon" "v1.0.1"
        --
        --      -- Modify each buff button's texture when they are created
        --      __SecureHook__()
        --      function BuffButton_OnLoad(self)
        --
        --          -- We should secure hook the texture's SetTexture to do modifiy
        --          -- Normally, these should be done like
        --          -- _M:SecureHook(_G[self:GetName() .. "Icon"], "SetTexture", HookSetTexture)
        --          -- Just for an example
        --          __SecureHook__(_G[self:GetName() .. "Icon"])
        --          function SetTexture(self, path)
        --              if path then
        --                  self:SetTexCoord(0.06, 0.94, 0.06, 0.94)
        --              end
        --          end
        --      end
        __Sealed__()
        class "__SecureHook__" (function(_ENV)
            extend "IAttachAttribute"

            function AttachAttribute(self, target, targettype, owner, name, stack)
                if Class.IsObjectType(owner, Scorpio) then
                    owner:SecureHook(self.Target, self.TargetFunc or name, target)
                else
                    error("__SecureHook__ can only be applyed to objects of Scorpio.", stack + 1)
                end
            end

            ----------------------------------------------
            --                 Property                 --
            ----------------------------------------------
            property "AttributeTarget"  { default = AttributeTargets.Function }

            ----------------------------------------------
            --                Constructor               --
            ----------------------------------------------
            __Arguments__{ Table, Variable.Optional(NEString) }
            function __SecureHook__(self, target, targetFunc)
                self.Target = target
                self.TargetFunc = targetFunc
            end

            __Arguments__{ Variable.Optional(NEString) }
            function __SecureHook__(self, targetFunc)
                self.Target = _G
                self.TargetFunc = targetFunc
            end
        end)

        --- Register a slash cmd with handler
        -- @usage>
        --      Scorpio "MyAddon" "v1.0.1"
        --
        --      Log = Logger("MyAddon")
        --
        --      -- "/myaddon log 1" used to change the addon's log level
        --      __SlashCmd__ "/myaddon" "log"
        --      function TurnLog(lvl)
        --          Log.LogLevel = tonumber(lvl) or 2
        --      end
        --
        --      -- "/myaddon" default slash command handler, used to display the detail
        --      __SlashCmd__ "/myaddon"
        --      function SlashCmd(msg)
        --          print("/myaddon log N - change the log level")
        --      end
        __Sealed__()
        class "__SlashCmd__" (function(_ENV)
            extend "IAttachAttribute"

            function AttachAttribute(self, target, targettype, owner, name, stack)
                if Class.IsObjectType(owner, Scorpio) then
                    if not self.SlashOpt then
                        owner:RegisterSlashCommand(self.SlashCmd, target)
                    else
                        owner:RegisterSlashCmdOption(self.SlashCmd, self.SlashOpt, target, self.SlashDesc)
                    end
                else
                    error("__SlashCmd__ can only be applyed to objects of Scorpio.", stack + 1)
                end
            end

            ----------------------------------------------
            --                 Property                 --
            ----------------------------------------------
            property "AttributeTarget"  { default = AttributeTargets.Function }
            property "SlashCmd"         { type = NEString }
            property "SlashOpt"         { type = NEString }
            property "SlashDesc"        { type = NEString}

            ----------------------------------------------
            --                Constructor               --
            ----------------------------------------------
            __Arguments__{ NEString, Variable.Optional(NEString), Variable.Optional(NEString) }
            function __SlashCmd__(self, slashCmd, slashOpt, slashDesc)
                self.SlashCmd = slashCmd
                self.SlashOpt = slashOpt
                self.SlashDesc = slashDesc
            end

            ----------------------------------------------
            --                Meta-Method               --
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

        --- Mark the method so it only be called when the player is not in combat
        __Sealed__()
        class "__NoCombat__" (function(_ENV)
            function __NoCombat__(self)
                local del = __Delegate__(NoCombat)
                del.Priorty = AttributePriority.Lower
                del.SubLevel = -999
            end
        end)

        --- Mark the method as a hook when the target's addon is loaded
        -- @usage
        --      Scorpio "MyAddon" "v1.0.1"
        --
        --      __AddonHook__ "AnotherAddon"
        --      function dosomeJob(...)
        --          -- Wait "AnotherAddon" loaded and hook the "dosomeJob" function
        --      end
        __Sealed__()
        class "__AddonHook__" (function(_ENV)
            extend "IAttachAttribute"

            function AttachAttribute(self, target, targettype, owner, name, stack)
                if Class.IsObjectType(owner, Scorpio) then
                    local addon = self.Addon
                    if IsAddOnLoaded(addon) then
                        owner:Hook(self.Target, self.TargetFunc or name, target)
                    else
                        local targetTbl = self.Target
                        local targetFunc = self.TargetFunc or name

                        ThreadCall(function()
                            while NextEvent("ADDON_LOADED") ~= addon do end
                            owner:Hook(targetTbl, targetFunc, target)
                        end)
                    end
                else
                    error("__AddonHook__ can only be applyed to objects of Scorpio.", stack + 1)
                end
            end

            ----------------------------------------------
            --                 Property                 --
            ----------------------------------------------
            property "AttributeTarget"  { default = AttributeTargets.Function }

            ----------------------------------------------
            --                Constructor               --
            ----------------------------------------------
            __Arguments__{ NEString, Variable.Optional(NEString) }
            function __AddonHook__(self, addon, targetFunc)
                self.Addon = addon
                self.Target = _G
                self.TargetFunc = targetFunc
            end
        end)

        --- Mark the method as a secure hook when the target's addon is loaded
        -- @usage
        --      Scorpio "MyAddon" "v1.0.1"
        --
        --      -- Secure hook 'AuctionFrameTab_OnClick' when Blizzard_AuctionUI loaded
        --      __AddonSecureHook__ "Blizzard_AuctionUI"
        --      function AuctionFrameTab_OnClick(self, button, down, index)
        --      end
        --
        --      __AddonSecureHook__ "Blizzard_AuctionUI" "AuctionFrameTab_OnClick"
        --      function Hook_Blizzard_AuctionUI(self, button, down, index)
        --      end
        __Sealed__()
        class "__AddonSecureHook__" (function(_ENV)
            extend "IAttachAttribute"

            function AttachAttribute(self, target, targettype, owner, name, stack)
                if Class.IsObjectType(owner, Scorpio) then
                    local addon = self.Addon
                    if IsAddOnLoaded(addon) then
                        owner:SecureHook(self.Target, self.TargetFunc or name, target)
                    else
                        local targetTbl = self.Target
                        local targetFunc = self.TargetFunc or name

                        ThreadCall(function()
                            while NextEvent("ADDON_LOADED") ~= addon do end
                            owner:SecureHook(targetTbl, targetFunc, target)
                        end)
                    end
                else
                    error("__AddonSecureHook__ can only be applyed to objects of Scorpio.", stack + 1)
                end
            end

            ----------------------------------------------
            --                 Property                 --
            ----------------------------------------------
            property "AttributeTarget"  { default = AttributeTargets.Function }

            ----------------------------------------------
            --                Constructor               --
            ----------------------------------------------
            __Arguments__{ NEString, Variable.Optional(NEString) }
            function __AddonSecureHook__(self, addon, targetFunc)
                self.Addon = addon
                self.Target = _G
                self.TargetFunc = targetFunc
            end
        end)

        ----------------------------------------------
        --              System Prepare              --
        ----------------------------------------------
        Environment.RegisterGlobalNamespace("Scorpio")

        RegisterEvent(ScorpioManager, "ADDON_LOADED")
        RegisterEvent(ScorpioManager, "PLAYER_LOGIN")
        RegisterEvent(ScorpioManager, "PLAYER_LOGOUT")
        RegisterEvent(ScorpioManager, "PLAYER_SPECIALIZATION_CHANGED")
        RegisterEvent(ScorpioManager, "PLAYER_ENTERING_WORLD")

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

        ----------------------------------------------
        --                  Locale                  --
        ----------------------------------------------
        __Sealed__()
        class "Localization" (function(_ENV)
            _Localizations = {}

            enum "Locale" {
                "deDE",             -- German
                --"enGB",             -- British English
                "enUS",             -- American English
                "esES",             -- Spanish (European)
                "esMX",             -- Spanish (Latin American)
                "frFR",             -- French
                "koKR",             -- Korean
                "ruRU",             -- Russian
                "zhCN",             -- Chinese (simplified; mainland China)
                "zhTW",             -- Chinese (traditional; Taiwan)
            }

            ----------------------------------------------
            ----------------- Constructor ----------------
            ----------------------------------------------
            __Arguments__{ NEString }
            function Localization(self, name)
                _Localizations[name] = self
            end

            ----------------------------------------------
            ----------------- Meta-Method ----------------
            ----------------------------------------------
            __Arguments__{ NEString }
            function __exist(_, name)
                return _Localizations[name]
            end

            __Arguments__{ NEString }
            function __index(self, key)
                rawset(self, key, key)
                return key
            end

            __Arguments__{ NEString + Number, NEString }
            function __newindex(self, key, value)
                rawset(self, key, value)
            end

            __Arguments__{ NEString, Boolean }
            function __newindex(self, key, value)
                rawset(self, key, key)
            end

            __Arguments__ { Variable("language", Locale), Variable("asDefault", Boolean, true) }
            function __call(self, language, asDefault)
                if not asDefault then
                    local locale = GetLocale()
                    if locale == "enGB" then locale = "enUS" end
                    if locale ~= language then return end
                end
                return self
            end
        end)

        ------------------------------------------------------------
        --               [Property]Scorpio._Locale                --
        ------------------------------------------------------------
        property "_Locale" { set = false, default = function(self) return Localization(self._Addon._Name) end }
    end)
end)