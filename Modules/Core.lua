--========================================================--
--                Scorpio Addon FrameWork                 --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/12/12                              --
-- Update Date :  2022/08/30                              --
--========================================================--

PLoop(function(_ENV)
    ------------------------------------------------------------
    --                Scorpio - Addon Class                   --
    ------------------------------------------------------------
    __Sealed__()
    _G.Scorpio = class "Scorpio" (function (_ENV)
        inherit "Module"

        import "System.Reactive"

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
            ------------------- Math ---------------------
            min                 = math.min,
            max                 = math.max,

            ------------------- String -------------------
            strtrim             = strtrim or function(s) return (s:gsub("^%s*(.-)%s*$", "%1")) or "" end,

            ------------------- Error --------------------
            geterrorhandler     = _G.geterrorhandler or function() return print end,
            errorhandler        = _G.errorhandler or function(err) return geterrorhandler()(err) end,

            ------------------- Table --------------------
            tblconcat           = table.concat,
            tinsert             = table.insert,
            tremove             = table.remove,
            wipe                = wipe or function(t) for k in pairs(t) do t[k] = nil end return t end,

            ------------------- Coroutine ----------------
            create              = coroutine.create,
            resume              = coroutine.resume,
            running             = coroutine.running,
            status              = coroutine.status,
            wrap                = coroutine.wrap,
            yield               = coroutine.yield,

            DefaultPool         = Threading.ThreadPool.Default,

            debugprofilestop    = debugprofilestop,
            GetSpecialization   = _G.GetSpecialization and pcall(_G.GetSpecialization) and _G.GetSpecialization or _G.GetActiveTalentGroup or function() return 1 end,
            IsWarModeDesired    = C_PvP and C_PvP.IsWarModeDesired or function() return false end,
        }

        ThreadCall              = function(...) return DefaultPool:ThreadCall(...) end

        ----------------------------------------------
        --               Addon Cache                --
        ----------------------------------------------
        _RootAddon              = setmetatable({}, META_WEAKVAL)
        _NotLoaded              = setmetatable({}, META_WEAKKEY)
        _DisabledModule         = setmetatable({}, META_WEAKKEY)

        local function callAddonHandlers(map, ...)
            if not map then return end
            for obj, handler in pairs(map) do
                if not _DisabledModule[obj] then
                    local ok, err = pcall(handler, ...)
                    if not ok then errorhandler(err) end
                end
            end
        end

        ----------------------------------------------
        --               Cache System               --
        ----------------------------------------------
        local t_Cache           = {}    -- Cache Manager

        local _RegisterService  = {}
        local _ResidentService  = setmetatable({}, META_WEAKKEY)

        local _ObjectGuidMap    = setmetatable({}, META_WEAKKEY)
        local _SingleAsync      = setmetatable({}, META_WEAKVAL)
        local _RunSingleAsync   = setmetatable({}, META_WEAKKEY)
        local _CancelSingleAsync= setmetatable({}, META_WEAKKEY)

        -- For diagnosis
        g_CacheGenerated        = 0
        g_CacheRamain           = 1

        local function recycleCache(cache)
            if cache then
                wipe(cache)
                if t_Cache then
                    cache[0]    = t_Cache
                end
                t_Cache         = cache
                g_CacheRamain   = g_CacheRamain + 1
                return
            end

            if t_Cache then
                cache           = t_Cache
                t_Cache         = cache[0]
                cache[0]        = nil
                g_CacheRamain   = g_CacheRamain - 1
                return cache
            else
                g_CacheGenerated= g_CacheGenerated + 1
                return {}
            end
        end

        ----------------------------------------------
        --               Task System                --
        ----------------------------------------------
        -- Phase Settings
        PHASE_THRESHOLD         = 15    -- The max task operation time per phase
        PHASE_TIME_FACTOR       = 0.4   -- The factor used to calculate the task operation time per phase
        SMOOTH_LOADING          = true

        -- System Task Settings
        EVENT_CLEAR_INTERVAL    = 100   -- The interval for event task clear
        EVENT_CLEAR_DELAY       = 10
        DIAGNOSE_DELAY          = 60

        -- Const
        HIGH_PRIORITY           = 1     -- For Continue
        NORMAL_PRIORITY         = 2     -- For Event, Next, Wait
        LOW_PRIORITY            = 3     -- For Delay

        MAX_LOW_DELAY_TURN      = 5     -- The max phase to delay the low priority tasks

        -- Global variables
        g_Phase                 = 0     -- The Nth phase based on GetTime()
        g_PhaseTime             = 0
        g_Threshold             = 0     -- The threshold based on GetFramerate(), in ms
        g_InPhase               = false
        g_FinishedTask          = 0
        g_StartTime             = 0
        g_EndTime               = 0
        g_AverageTime           = 20    -- An useless init value

        g_PhaseStartTime        = 0     -- Recored the start phase time
        g_PhaseStartProfile     = 0     -- The start profile time of current phase

        g_DynamicThreshold      = 15    -- The dynamic threshold
        g_PreTaskCount          = 0

        -- For diagnosis
        g_DelayedTask           = 0
        g_LowLevelup            = 0
        g_MaxPhaseTime          = 0

        -- Task List
        t_Tasks                 = {}    -- Core task list

        -- Runtime task
        r_Tasks                 = {}
        r_Count                 = 0
        r_LowDelayed            = 0

        -- In Loading Screen
        r_InLoadingScreen       = true
        r_InBattleField         = false
        r_DelayResumeForBF      = 1

        -- Queue API
        local function queueTask(priority, task)
            local cache         = t_Tasks[priority]
            if not cache then
                cache           = recycleCache()
                t_Tasks[priority] = cache
            end
            tinsert(cache, task)
        end

        local function queueTaskList(priority, tasklist)
            local cache         = t_Tasks[priority]
            if not cache then
                t_Tasks[priority] = tasklist
            else
                while cache[0] do cache = cache[0] end
                cache[0]        = tasklist
            end
        end

        -- Phase API
        local function processPhase()
            if g_InPhase or r_InLoadingScreen then return end
            g_InPhase                       = true

            -- Prepare the task list
            local now                       = GetTime()
            if now ~= g_Phase then
                -- Init the phase
                g_Phase                     = now

                -- For diagnosis
                g_DelayedTask               = g_DelayedTask + r_Count

                -- Calculate the average time per task
                if g_FinishedTask > 0 then
                    local cost              = g_EndTime - g_StartTime

                    -- For diagnosis
                    if cost > g_MaxPhaseTime then g_MaxPhaseTime = cost end

                    g_AverageTime           = (g_AverageTime + cost / g_FinishedTask) / 2
                    g_FinishedTask          = 0
                end

                -- Record the start time
                g_StartTime                 = g_PhaseStartProfile   -- debugprofilestop()

                -- Move task to core based on priority
                -- High priority means it must be processed as soon as possible
                -- Normal priority means it could be processed in the next phase as high priority
                -- Lower priority means it will be processed when there is enough time
                local r_Tail                = r_Tasks[0]

                for i = HIGH_PRIORITY, NORMAL_PRIORITY do
                    local cache             = t_Tasks[i]

                    if cache then
                        t_Tasks[i]          = nil

                        if r_Tail then
                            r_Tail[0]       = cache
                        else
                            -- Init
                            r_Tasks[1]      = cache
                        end

                        while cache do
                            r_Tail          = cache
                            r_Count         = r_Count + #cache
                            cache           = cache[0]
                        end
                    end
                end

                r_Tasks[0]                  = r_Tail

                -- LOW_PRIORITY
                if  not r_Tasks[LOW_PRIORITY] then
                    r_Tasks[LOW_PRIORITY]   = t_Tasks[LOW_PRIORITY]
                    t_Tasks[LOW_PRIORITY]   = nil

                    -- reset the counter
                    r_LowDelayed            = 0
                else
                    r_LowDelayed            = r_LowDelayed + 1

                    if r_LowDelayed > MAX_LOW_DELAY_TURN then
                        g_LowLevelup        = g_LowLevelup + 1

                        -- Queue to the normal priority list
                        queueTaskList(NORMAL_PRIORITY, r_Tasks[LOW_PRIORITY])
                        r_Tasks[LOW_PRIORITY] = nil
                    end
                end

                -- Calc the phase time
                local fpslimit              = min(PHASE_THRESHOLD, 1000 * PHASE_TIME_FACTOR / max(10, GetFramerate() or 60))
                local taskreq               = r_Count * g_AverageTime

                if taskreq <= fpslimit * 2 then
                    g_PhaseTime             = fpslimit
                elseif not SMOOTH_LOADING and taskreq > PHASE_THRESHOLD * 50 then
                    -- Reduce the waiting time when entering the game
                    g_PhaseTime             = taskreq / 2
                else
                    if g_DynamicThreshold < PHASE_THRESHOLD then
                        g_PhaseTime         = PHASE_THRESHOLD
                    else
                        -- use dynamic phase time to avoid too many task remained
                        if r_Count > g_PreTaskCount then
                            g_PhaseTime     = g_DynamicThreshold + 1
                        elseif r_Count < g_PreTaskCount then
                            g_PhaseTime     = g_DynamicThreshold - 1
                        else
                            g_PhaseTime     = g_DynamicThreshold
                        end
                    end
                end

                g_DynamicThreshold          = g_PhaseTime
                g_PreTaskCount              = r_Count

                g_Threshold                 = g_StartTime + g_PhaseTime

                -- Check if too much time cost by events(with low cpu), we still need some time to process the high priority tasks
                local currStop              = debugprofilestop()
                if g_Threshold <= currStop then g_Threshold = currStop + g_PhaseTime end
            elseif not r_Tasks[1] then
                -- Only tasks of high priority can be executed again and again in a phase
                local cache                 = t_Tasks[HIGH_PRIORITY]
                if cache then
                    t_Tasks[HIGH_PRIORITY]  = nil

                    r_Tasks[1]              = cache

                    while cache do
                        r_Tasks[0]          = cache
                        r_Count             = r_Count + #cache
                        cache               = cache[0]
                    end
                end
            end

            -- It's time to process the task execution
            -- Process the high priority tasks
            local r_Header                  = r_Tasks[1]
            local runoutIdx                 = nil

            while r_Header do
                for i = r_Header[-1] or 1, #r_Header do
                    -- The phase is out of time, keep the index for next phase
                    if g_Threshold <= debugprofilestop() then
                        runoutIdx           = i
                        break
                    end

                    local task              = r_Header[i]
                    r_Header[-1]            = i + 1

                    if task then
                        if _CancelSingleAsync[task] then
                            _CancelSingleAsync[task] = nil
                        else
                            -- Process the task
                            local ok, msg   = resume(task)
                            if not ok then
                                if msg ~= "cannot resume dead coroutine" then
                                    pcall(geterrorhandler(), msg)
                                end
                                if _RunSingleAsync[task] then
                                    if type(_RunSingleAsync[task]) == "string" then
                                        _SingleAsync[_RunSingleAsync[task]] = false
                                    else
                                        _RunSingleAsync[task][1] = false
                                    end
                                    _RunSingleAsync[task] = nil
                                end
                                if _ResidentService[task] then
                                    ThreadCall(_ResidentService[task], msg)
                                    _ResidentService[task] = nil
                                end
                            end
                            g_FinishedTask  = g_FinishedTask + 1
                        end
                    end
                    r_Count                 = r_Count - 1
                end

                if runoutIdx and r_Header then
                    r_Header[-1]            = runoutIdx
                    break
                end

                local nxt                   = r_Header[0]
                recycleCache(r_Header)
                r_Header                    = nxt
            end

            r_Tasks[1] = r_Header
            if not r_Header then r_Tasks[0] = nil end

            -- Process the low priority tasks
            if not runoutIdx and r_Tasks[LOW_PRIORITY] then
                r_Header                    = r_Tasks[LOW_PRIORITY]

                for i = r_Header[-1] or 1, #r_Header do
                    if g_Threshold <= debugprofilestop() then
                        runoutIdx           = i
                        break
                    end

                    local task              = r_Header[i]
                    r_Header[-1]            = i + 1

                    if task then
                        if _CancelSingleAsync[task] then
                            _CancelSingleAsync[task] = nil
                        else
                            -- Process the task
                            local ok, msg   = resume(task)
                            if not ok then
                                if msg ~= "cannot resume dead coroutine" then
                                    pcall(geterrorhandler(), msg)
                                end
                                if _RunSingleAsync[task] then
                                    if type(_RunSingleAsync[task]) == "string" then
                                        _SingleAsync[_RunSingleAsync[task]] = false
                                    else
                                        _RunSingleAsync[task][1] = false
                                    end
                                    _RunSingleAsync[task] = nil
                                end
                                if _ResidentService[task] then
                                    ThreadCall(_ResidentService[task])
                                    _ResidentService[task] = nil
                                end
                            end
                            g_FinishedTask  = g_FinishedTask + 1
                        end
                    end
                end

                if runoutIdx then
                    r_Header[-1]            = runoutIdx
                else
                    recycleCache(r_Header)
                    r_Tasks[LOW_PRIORITY]   = nil
                end
            end

            g_EndTime                       = debugprofilestop()
            g_InPhase                       = false

            -- Try again if have time with high priority tasks
            return g_Threshold > g_EndTime and t_Tasks[HIGH_PRIORITY] and processPhase()
        end

        ----------------------------------------------
        --            System Task Driver            --
        ----------------------------------------------
        ScorpioManager          = CreateFrame("Frame")

        _EventDistribution      = {}                                -- System Event
        _CombatEventDistribution= {}                                -- Combat Event
        _SecureHookDistribution = setmetatable({}, META_WEAKKEY)    -- Secure Hook

        t_EventTasks            = {}                                -- Event Task
        t_WaitEventTasks        = {}                                -- Wait Event Task
        t_SecureHookTasks       = setmetatable({}, META_WEAKKEY)    -- Secure Hook Task

        -- Wait thread token
        w_Token                 = {}
        w_Token_INDEX           = 1

        local t_DelayTasks      = nil   -- Delayed task

        local function queueDelayTask(task, time)
            time                = floor((GetTime() + time) * 100)

            local node, header  = t_DelayTasks

            while node and node[1] < time do
                header          = node
                node            = header[0]
            end

            if node and node[1] == time then
                tinsert(node, task)
            else
                node            = recycleCache()
                node[1]         = time
                node[2]         = task

                if header then
                    node[0]     = header[0]
                    header[0]   = node
                else
                    node[0]     = t_DelayTasks
                    t_DelayTasks= node
                end
            end
        end

        local function queueEventTask(task, event)
            if not _EventDistribution[event] then
                _EventDistribution[event] = setmetatable({}, META_WEAKKEY)
                pcall(ScorpioManager.RegisterEvent, ScorpioManager, event)
            end

            local cache         = t_EventTasks[event]
            if not cache then
                cache           = recycleCache()
                t_EventTasks[event] = cache
            end

            tinsert(cache, task)
        end

        local function queueWaitTask(task, delay, ...)
            local token         = w_Token_INDEX

            w_Token_INDEX       = w_Token_INDEX + 1
            if w_Token_INDEX > 2147483647 then w_Token_INDEX = 1 end

            w_Token[token]      = task

            if delay then queueDelayTask(token, delay) end

            for i = 1, select("#", ...) do
                local event     = select(i, ...)

                if not _EventDistribution[event] then
                    _EventDistribution[event] = setmetatable({}, META_WEAKKEY)
                    pcall(ScorpioManager.RegisterEvent, ScorpioManager, event)
                end

                local cache     = t_WaitEventTasks[event]
                if not cache then
                    cache       = recycleCache()
                    cache[0]    = GetTime() + EVENT_CLEAR_INTERVAL
                    t_WaitEventTasks[event] = cache
                end

                tinsert(cache, token)
            end
        end

        local function yieldReturn(...)
            yield()
            return ...
        end

        local function newSystemTask(func, ...)
            if select("#", ...) > 0 then
                yieldReturn(yield( running() ))
                return func(...)
            else
                return func(yieldReturn(yield( running() )))
            end
        end

        local function wrapAsSystemTask(func, ...)
            return ThreadCall(newSystemTask, func, ...)
        end

        local function newSimpleTask(func, ...)
            yield( running() )
            return func(...)
        end

        local function wrapAsSimpleTask(func, ...)
            return ThreadCall(newSimpleTask, func, ...)
        end

        local function processQueue(priority, queue, ...)
            yield( running() )

            for _, task in ipairs(queue) do
                if task then resume(task, ...) end
            end

            queueTaskList(priority, queue)
        end

        local function getSecureHookMap(target, targetFunc)
            local map           = _SecureHookDistribution[target]

            if not map then
                map             = setmetatable({}, META_WEAKKEY)
                _SecureHookDistribution[target] = map
            end

            map                 = map[targetFunc]

            if not map then
                if type(target[targetFunc]) ~= "function" then
                    error(("No method named '%s' can be found."):format(targetFunc))
                end

                map             = setmetatable({}, META_WEAKKEY)
                _SecureHookDistribution[target][targetFunc] = map

                hooksecurefunc(target, targetFunc, function(...)
                    local cache = t_SecureHookTasks[target]
                    local queue = cache and cache[targetFunc]

                    if queue then
                        cache[targetFunc] = nil
                        queueTask(NORMAL_PRIORITY, ThreadCall(processQueue, HIGH_PRIORITY, queue, ...))
                    end

                    return callAddonHandlers(map, ...)
                end)
            end

            return map
        end

        local function queueNextSecureCall(task, target, targetFunc)
            if not getSecureHookMap(target, targetFunc) then return end

            local cache         = t_SecureHookTasks[target]
            if not cache then
                cache           = setmetatable({}, META_WEAKKEY)
                t_SecureHookTasks[target] = cache
            end

            local queue         = cache[targetFunc]
            if not queue then
                queue           = recycleCache()
                cache[targetFunc] = queue
            end

            tinsert(queue, task)
        end

        local function noCombatCall(callable, ...)
            while InCombatLockdown() do Next() end
            return callable(...)
        end

        local function registerService(func, resident)
            local wrap
            wrap                = resident and function()
                _ResidentService[running()] = wrap
                Next() func()
            end or function()
                Next() func()
            end
            tinsert(_RegisterService, wrap)
        end

        local function processService()
            if _RegisterService[1] then
                local task      = _RegisterService
                _RegisterService= {}
                for i = 1, #task do ThreadCall(task[i]) end
            end
        end

        local function retSingleAsync(...)
            local curr              = running()
            local guid              = _RunSingleAsync[curr]

            _RunSingleAsync[curr]   = nil
            _CancelSingleAsync[curr]= nil

            if guid then
                if type(guid) == "string" then
                    _SingleAsync[guid] = false
                else
                    guid[1]         = false
                end
            end

            return ...
        end

        local function registerSingleAsync(func, override, owner, name)
            if owner then
                -- For method, the guid should be binded to class
                -- But we need check if the method is static
                local staticguid

                local getGuid                       = function(self)
                    if staticguid then
                        -- For static method
                        return staticguid
                    elseif staticguid == nil then
                        -- Check whether is static method
                        if Interface.IsStaticMethod(owner, name) then
                            local guid              = Guid.New()
                            while _SingleAsync[guid] ~= nil do guid = Guid.New() end
                            _SingleAsync[guid]      = false
                            staticguid              = guid

                            return guid
                        else
                            staticguid              = false
                        end
                    else
                        -- For object method
                        local map                   = _ObjectGuidMap[self]
                        if not map then
                            map                     = {}
                            _ObjectGuidMap[self]    = map
                        end

                        local guid                  = map[name]
                        if not guid then
                            guid                    = Guid.New()
                            while map[guid] ~= nil do guid = Guid.New() end
                            map[name]               = guid
                            map[guid]               = { [0]= guid, [1] = false }
                        end
                        return guid, map[guid]
                    end
                end

                local wrapper                       = function(self, ...)
                    local guid, obmap               = getGuid(self)

                    local curr                      = running()

                    if obmap then
                        _RunSingleAsync[curr]       = obmap
                        _CancelSingleAsync[curr]    = nil
                        obmap[1]                    = curr
                    else
                        _RunSingleAsync[curr]       = guid
                        _CancelSingleAsync[curr]    = nil
                        _SingleAsync[guid]          = curr
                    end

                    return retSingleAsync(func(self, ...))
                end

                if override then
                    return function(self, ...)
                        local guid, obmap           = getGuid(self)

                        if obmap then
                            local curr              = obmap[1]
                            if curr then
                                obmap[1]                = false
                                _RunSingleAsync[curr]   = nil
                                _CancelSingleAsync[curr]= true
                            end
                        else
                            local curr              = _SingleAsync[guid]
                            if curr then
                                _SingleAsync[guid]      = false
                                _RunSingleAsync[curr]   = nil
                                _CancelSingleAsync[curr]= true
                            end
                        end

                        return ThreadCall(wrapper, self, ...)
                    end
                else
                    return function(self, ...)
                        local guid, obmap           = getGuid(self)

                        if obmap then
                            if obmap[1] then return end
                        else
                            if _SingleAsync[guid] then return end
                        end

                        return ThreadCall(wrapper, self, ...)
                    end
                end
            else
                -- For function the guid is binded to function
                local guid                          = Guid.New()
                while _SingleAsync[guid] ~= nil do guid = Guid.New() end
                _SingleAsync[guid]                  = false

                local wrapper                       = function(...)
                    local curr                      = running()
                    _RunSingleAsync[curr]           = guid
                    _SingleAsync[guid]              = curr

                    return retSingleAsync(func(...))
                end

                if override then
                    return function(...)
                        local curr                  = _SingleAsync[guid]
                        if curr then
                            _SingleAsync[guid]      = false
                            _RunSingleAsync[curr]   = nil
                            _CancelSingleAsync[curr]= true
                        end

                        return ThreadCall(wrapper, ...)
                    end
                else
                    return function(...)
                        if _SingleAsync[guid] then return end
                        return ThreadCall(wrapper, ...)
                    end
                end
            end
        end

        local function callCombatHandlers(timestamp, eventType, ...)
            local map           = _CombatEventDistribution[eventType]
            if map then return callAddonHandlers(map, timestamp, eventType, ...) end
        end

        local function safeCall(...)
            local ok, err       = pcall(...)
            if not ok then errorhandler(err) end
        end

        ----------------------------------------------
        --             Next Observable              --
        ----------------------------------------------
        local rycNextObserver   = Recycle(Observer)

        function rycNextObserver:OnInit(ob)
            ob.OnNext           = function(...)
                ob.Subscription = nil

                local thread    = ob.NextThread

                ob.NextThread   = nil
                rycNextObserver(ob)

                if thread then
                    resume(thread, ...)
                    queueTask(HIGH_PRIORITY, thread)
                end
            end
        end

        ----------------------------------------------
        --               Addon Helper               --
        ----------------------------------------------
        _SlashCmdList           = _G.SlashCmdList
        _SlashCmdCount          = 0
        _SlashCmdHandler        = {}

        -- Whether the player is already logined
        _Logined                = false
        _PlayerSpec             = -1
        _PlayerWarMode          = -1

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
                safeCall(OnLoad, self)
            end

            for _, mdl in self:GetModules() do loadingWithoutClear(mdl) end
        end

        local function loading(self)
            if _NotLoaded[self] then
                _NotLoaded[self] = nil
                safeCall(OnLoad, self)
            end

            for _, mdl in self:GetModules() do loading(mdl) end
        end

        local function enablingWithCheck(self)
            if not _DisabledModule[self] then
                if _NotLoaded[self] then
                    safeCall(OnEnable, self)
                end

                for _, mdl in self:GetModules() do enablingWithCheck(mdl) end
            end
        end

        local function enabling(self)
            if _NotLoaded[self] then loading(self) end

            if not _DisabledModule[self] then
                safeCall(OnEnable, self)

                for _, mdl in self:GetModules() do enabling(mdl) end
            end
        end

        local function disabling(self)
            if not _DisabledModule[self] then
                _DisabledModule[self] = true

                if _Logined then safeCall(OnDisable, self) end

                for _, mdl in self:GetModules() do disabling(mdl) end
            end
        end

        local function tryEnable(self)
            if _DisabledModule[self] and self._Enabled then
                if not self._Parent or (not _DisabledModule[self._Parent]) then
                    _DisabledModule[self] = nil

                    safeCall(OnEnable, self)

                    for _, mdl in self:GetModules() do
                        if mdl._Enabled then
                            tryEnable(mdl)
                        end
                    end
                end
            end
        end

        local function exiting(self)
            safeCall(OnQuit, self)

            for _, mdl in self:GetModules() do exiting(mdl) end
        end

        local function specChangedWithCheck(self, spec)
            if _NotLoaded[self] then
                safeCall(OnSpecChanged, self, spec)
            end

            for _, mdl in self:GetModules() do specChangedWithCheck(mdl, spec) end
        end

        local function specChanged(self, spec)
            if not _Logined then return end

            safeCall(OnSpecChanged, self, spec)

            for _, mdl in self:GetModules() do specChanged(mdl, spec) end
        end

        local function warmodeChangedWithCheck(self, mode)
            if _NotLoaded[self] then
                safeCall(OnWarModeChanged, self, mode)
            end

            for _, mdl in self:GetModules() do warmodeChangedWithCheck(mdl, mode) end
        end

        local function warmodeChanged(self, mode)
            if not _Logined then return end

            safeCall(OnWarModeChanged, self, mode)

            for _, mdl in self:GetModules() do warmodeChanged(mdl, mode) end
        end

        local function clearNotLoaded(self)
            _NotLoaded[self] = nil
            for _, mdl in self:GetModules() do clearNotLoaded(mdl) end
        end

        local function tryloading(self)
            if _Logined then
                loadingWithoutClear(self)
                enablingWithCheck(self)
                specChangedWithCheck(self, _PlayerSpec)
                warmodeChangedWithCheck(self, _PlayerWarMode)
                clearNotLoaded(self)
            else
                return loading(self)
            end
        end

        ----------------------------------------------
        --             Scorpio Manager              --
        ----------------------------------------------
        function ScorpioManager:OnEvent(evt, ...)
            if evt == "COMBAT_LOG_EVENT_UNFILTERED" then
                callCombatHandlers( CombatLogGetCurrentEventInfo() )
            end

            local now           = GetTime()
            if now > g_PhaseStartTime then
                g_PhaseStartTime = now
                g_PhaseStartProfile = debugprofilestop()
            end

            local cache         = t_EventTasks[evt]
            local wcache        = t_WaitEventTasks[evt]

            -- event tasks
            if cache then
                t_EventTasks[evt] = nil

                queueTask(NORMAL_PRIORITY, ThreadCall(processQueue, HIGH_PRIORITY, cache, ...))
            end

            -- wait event tasks
            if wcache then
                t_WaitEventTasks[evt] = nil
                wcache[0]       = nil

                for i, v in ipairs(wcache) do
                    local task  = w_Token[v]
                    if task then
                        w_Token[v] = nil
                        wcache[i] = task
                    else
                        wcache[i] = false
                    end
                end

                queueTask(NORMAL_PRIORITY, ThreadCall(processQueue, HIGH_PRIORITY, wcache, evt, ...))
            end

            -- Call direct handlers
            return callAddonHandlers(_EventDistribution[evt], ...)
        end

        function ScorpioManager:OnUpdate()
            local now           = GetTime()

            if now > g_PhaseStartTime then
                g_PhaseStartTime = now
                g_PhaseStartProfile = debugprofilestop()
            end

            -- Make sure unexpected error won't stop the whole task system
            if now > g_Phase then g_InPhase = false end

            local cache         = t_DelayTasks
            now                 = floor(now * 100)

            while cache do
                local t         = cache[1]
                if t and t > now then break end

                if t then
                    local i     = 2
                    local task  = cache[i]
                    repeat
                        if type(task) == "number" then
                            local rtask = w_Token[task]
                            if rtask then
                                w_Token[task] = nil
                            end
                            task= rtask
                        end

                        if task then
                            resume(task, now)
                            queueTask(LOW_PRIORITY, task)
                        end

                        i       = i + 1
                        task    = cache[i]
                    until not task
                end

                local ncache    = cache[0]
                recycleCache(cache)

                cache           = ncache
            end
            t_DelayTasks        = cache

            return processPhase()
        end

        function ScorpioManager.ADDON_LOADED(name)
            local addon         = _RootAddon[name]
            if addon then
                tryloading(addon)
            else
                name            = name:match("%P+")
                addon           = name and _RootAddon[name]
                if addon then tryloading(addon) end
            end

            processService()
        end

        function ScorpioManager.PLAYER_LOGIN()
            if _Logined then return end

            --Log(2, "[START TASK MANAGER]")
            --r_InLoadingScreen = false

            _PlayerSpec         = GetSpecialization() or 1
            _PlayerWarMode      = IsWarModeDesired() and WarMode.PVP or WarMode.PVE
            _Logined            = true

            for _, addon in pairs(_RootAddon) do
                enabling(addon)
            end

            for _, addon in pairs(_RootAddon) do
                specChanged(addon, _PlayerSpec)
                warmodeChanged(addon, _PlayerWarMode)
            end

            processService()
        end

        function ScorpioManager.PLAYER_LOGOUT()
            Log(2, "[STOP TASK MANAGER]")

            r_InLoadingScreen   = true

            for _, addon in pairs(_RootAddon) do
                exiting(addon)
            end
        end

        function ScorpioManager.PLAYER_SPECIALIZATION_CHANGED(unit)
            if not _Logined then return end

            if not unit or type(unit) == "number" or UnitIsUnit(unit, "player") then
                local spec      = GetSpecialization() or 1
                if _PlayerSpec ~= spec then
                    _PlayerSpec = spec
                    for _, addon in pairs(_RootAddon) do
                        specChanged(addon, spec)
                    end
                end
            end
        end

        function ScorpioManager.PLAYER_ENTERING_WORLD()
            Log(2, "[RESUME TASK MANAGER]")

            if r_InBattleField then
                C_Timer.After(r_DelayResumeForBF, function() r_InLoadingScreen = false r_InBattleField = false end)
            else
                r_InLoadingScreen   = false
            end
            ScorpioManager.PLAYER_SPECIALIZATION_CHANGED()
        end

        function ScorpioManager.PLAYER_FLAGS_CHANGED()
            if not _Logined then return end

            local mode          = IsWarModeDesired() and WarMode.PVP or WarMode.PVE
            if _PlayerWarMode  ~= mode then
                _PlayerWarMode  = mode
                for _, addon in pairs(_RootAddon) do
                    warmodeChanged(addon, mode)
                end
            end
        end

        -- Stop the task system when loading screen
        function ScorpioManager.LOADING_SCREEN_ENABLED()
            Log(2, "[SUSPEND TASK MANAGER]")

            r_InLoadingScreen   = true
        end

        function ScorpioManager.LOADING_SCREEN_DISABLED()
            Log(2, "[RESUME TASK MANAGER]")

            if r_InBattleField then
                C_Timer.After(r_DelayResumeForBF, function() r_InLoadingScreen = false r_InBattleField = false end)
            else
                r_InLoadingScreen   = false
            end
        end

        hooksecurefunc(_G, "AcceptBattlefieldPort", function(data, accepted)
            if accepted then
                Log(2, "[SUSPEND TASK MANAGER]")

                r_InBattleField     = true
                r_InLoadingScreen   = true
            end
        end)

        ----------------------------------------------
        --                  Locale                  --
        ----------------------------------------------
        __Sealed__()
        class "Localization"    (function(_ENV)
            _Localizations      = {}
            _RootLocale         = {}

            enum "Locale"       {
                "deDE",         -- German
                --"enGB",       -- British English
                "enUS",         -- American English
                "esES",         -- Spanish (European)
                "esMX",         -- Spanish (Latin American)
                "itIT",         -- Italian (Italy)
                "frFR",         -- French
                "koKR",         -- Korean
                "ptBR",         -- Portuguese (Brazil)
                "ruRU",         -- Russian
                "zhCN",         -- Chinese (simplified; mainland China)
                "zhTW",         -- Chinese (traditional; Taiwan)
            }

            ----------------------------------------------
            --              Static Feature              --
            ----------------------------------------------
            __Static__()
            property "Root"     { type = Localization }

            ----------------------------------------------
            --                Constructor               --
            ----------------------------------------------
            __Arguments__{ NEString, Localization/nil }
            function Localization(self, name, root)
                _Localizations[name]= self
                _RootLocale[self]   = root or Localization.Root
            end

            ----------------------------------------------
            --                Meta-Method               --
            ----------------------------------------------
            __Arguments__{ NEString }
            function __exist(_, name)
                return _Localizations[name]
            end

            __Arguments__{ String }
            function __index(self, key)
                local root      = _RootLocale[self]
                local value     = root and rawget(root, key)

                if not value then
                    local lkey  = strlower(key)
                    value       = rawget(self, lkey) or root and rawget(root, lkey) or key
                end

                rawset(self, key, value)
                return value
            end

            __Arguments__{ String + Number, String }
            function __newindex(self, key, value)
                rawset(self, key, value)
            end

            __Arguments__{ String, Boolean }
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

        ----------------------------------------------
        --  SavedVariable Config Node Declaration   --
        ----------------------------------------------
        class "Scorpio.Config.ConfigNode"       {}
        class "Scorpio.Config.AddonConfigNode"  {}
        class "Scorpio.Config.CharConfigNode"   {}
        class "Scorpio.Config.SpecConfigNode"   {}
        class "Scorpio.Config.WarModeConfigNode"{}

        ----------------------------------------------
        --            System Event Method           --
        ----------------------------------------------
        --- Register system event or custom event
        -- @param event         string, the system|custom event name
        -- @param handler       string|function, the event handler or its name
        __Arguments__{ NEString, (NEString + Function)/nil }:Throwable()
        function RegisterEvent(self, evt, handler)
            local map           = _EventDistribution[evt]
            if not map then
                pcall(ScorpioManager.RegisterEvent, ScorpioManager, evt)
                map             = setmetatable({}, META_WEAKKEY)
                _EventDistribution[evt] = map
            end

            handler             = handler or evt
            if type(handler) == "string" then handler = self[handler] end
            if type(handler) ~= "function" then throw("Scorpio:RegisterEvent(event[, handler]) -- handler not existed.") end

            map[self]           = handler
        end

        --- Whether the system event or custom event is registered
        --@param  event          string, the system|custom event name
        --@return boolean       true if the event is registered
        __Arguments__{ NEString }
        function IsEventRegistered(self, evt)
            local map           = _EventDistribution[evt]
            return map and map[self] and true or false
        end

        --- Get the registered handler of an event
        --@param  event         string, the system|custom event name
        --@return boolean       true if the event is registered
        __Arguments__{ NEString }
        function GetRegisteredEventHandler(self, evt)
            local map           = _EventDistribution[evt]
            return map and map[self]
        end

        --- Unregister system event or custom event
        --@param event          string, the system|custom event name
        __Arguments__{ NEString }
        function UnregisterEvent(self, evt)
            local map           = _EventDistribution[evt]
            if map and map[self] then
                map[self]       = nil
            end
        end

        --- Unregister all the events
        function UnregisterAllEvents(self)
            for evt, map in pairs(_EventDistribution) do
                if map[self] then
                    map[self]   = nil
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
        --           System Combat Method           --
        ----------------------------------------------
        --- Register combat event or custom event
        -- @param event         string, the combat|custom event name
        -- @param handler       string|function, the event handler or its name
        __Arguments__{ NEString, (NEString + Function)/nil }:Throwable()
        function RegisterCombatEvent(self, evt, handler)
            local map           = _CombatEventDistribution[evt]
            if not map then
                map             = setmetatable({}, META_WEAKKEY)
                _CombatEventDistribution[evt] = map
            end

            handler             = handler or evt
            if type(handler) == "string" then handler = self[handler] end
            if type(handler) ~= "function" then throw("Scorpio:RegisterCombatEvent(event[, handler]) -- handler not existed.") end

            map[self]           = handler
        end

        --- Whether the combat event or custom event is registered
        --@param  event          string, the combat|custom event name
        --@return boolean       true if the event is registered
        __Arguments__{ NEString }
        function IsCombatEventRegistered(self, evt)
            local map           = _CombatEventDistribution[evt]
            return map and map[self] and true or false
        end

        --- Get the registered handler of an event
        --@param  event         string, the combat|custom event name
        --@return boolean       true if the event is registered
        __Arguments__{ NEString }
        function GetRegisteredCombatEventHandler(self, evt)
            local map           = _CombatEventDistribution[evt]
            return map and map[self]
        end

        --- Unregister combat event or custom event
        --@param event          string, the combat|custom event name
        __Arguments__{ NEString }
        function UnregisterCombatEvent(self, evt)
            local map           = _CombatEventDistribution[evt]
            if map and map[self] then
                map[self]       = nil
            end
        end

        --- Unregister all the events
        function UnregisterAllCombatEvents(self)
            for evt, map in pairs(_CombatEventDistribution) do
                if map[self] then
                    map[self]   = nil
                end
            end
        end

        --- Fire the combat event
        --@param event          string, the event's name
        --@param ...            the other arguments
        function FireCombatEvent(self, arg1, ...)
            if type(self) == "string" then
                return ScorpioManager:OnEvent("COMBAT_LOG_EVENT_UNFILTERED", time(), self, arg1, ...)
            elseif type(arg1) == "string" then
                return ScorpioManager:OnEvent("COMBAT_LOG_EVENT_UNFILTERED", time(), arg1, ...)
            end
        end

        ----------------------------------------------
        --        Secure Hook System Method         --
        ----------------------------------------------
        --- Secure hook a table's function
        --@format [target, ]targetFunction[, handler]
        --@param target         table, the target table, default _G
        --@param targetFunction string, the hook function name
        --@param handler        string, the hook handler
        __Arguments__{ Table, NEString, (NEString + Function)/nil }:Throwable()
        function SecureHook(self, target, targetFunc, handler)
            handler             = handler or targetFunc
            if type(handler) == "string" then handler = self[handler] end
            if type(handler) ~= "function" then throw("Scorpio:SecureHook([target, ]targetFunc[, handler]) -- handler not existed.") end

            getSecureHookMap(target, targetFunc)[self] = handler
        end

        __Arguments__{ NEString, (NEString + Function)/nil }:Throwable()
        function SecureHook(self, targetFunc, handler)
            if type(_G[targetFunc]) ~= "function" then
                throw(("No method named '%s' can be found."):format(targetFunc))
            end
            handler             = handler or targetFunc
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
            local map           = _SecureHookDistribution[target] and _SecureHookDistribution[target][targetFunc]
            return map and map[self] or nil
        end

        __Arguments__{ NEString }
        function GetSecureHookHandler(self, targetFunc)
            local map           = _SecureHookDistribution[_G] and _SecureHookDistribution[_G][targetFunc]
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
            slashCmd            = slashCmd:upper():match("^/?(%w+)")
            if slashCmd == "" then throw("The slash command can only be letters and numbers.") end
            slashCmd = "/" .. slashCmd

            local map           = _SlashCmdHandler[slashCmd]

            if not map then
                map             = {}
                _SlashCmdHandler[slashCmd] = map
                newSlashCmd(slashCmd, map)
            end

            if type(handler) == "string" then handler = self[handler] end
            if type(handler) ~= "function" then throw("Scorpio:RegisterSlashCommand(slashCmd, handler) -- handler not existed.") end

            map[0]              = handler
        end

        --- Register a slash command with handler
        --@param slashCmd       string, the slash command, case ignored
        --@param option         string, the slash command option, case ignored
        --@param handler        string|function, handler
        __Arguments__{ NEString, NEString, NEString + Function, NEString/nil }:Throwable()
        function RegisterSlashCmdOption(self, slashCmd, option, handler, desc)
            slashCmd            = slashCmd:upper():match("^/?(%w+)")
            if slashCmd == "" then throw("The slash command can only be letters and numbers.") end
            slashCmd = "/" .. slashCmd

            option = option:upper():match("^%w+")
            if not option or option == "" then throw("The slash command option can only be letters and numbers.") end

            local map           = _SlashCmdHandler[slashCmd]

            if not map then
                map = {}
                _SlashCmdHandler[slashCmd] = map
                newSlashCmd(slashCmd, map)
            end

            if type(handler) == "string" then handler = self[handler] end
            if type(handler) ~= "function" then throw("Scorpio:RegisterSlashCmdOption(slashCmd, option, handler[, description]) -- handler not existed.") end

            map[option]         = handler
            map[option .. "-desc"] = desc
        end

        ----------------------------------------------
        --            Task System Method            --
        ----------------------------------------------
        ---Call method or continue thread with high priority, the method(thread) should be called(resumed) as soon as possible.
        --@format [func[, ...]]
        --@param func           The function
        --@param ...            method parameter
        __Arguments__{ Function, Any * 0 }
        __Static__() function Continue(func, ...)
            return queueTask(HIGH_PRIORITY, wrapAsSimpleTask(func, ...))
        end

        __Arguments__{ }
        __Static__() function Continue()
            local thread        = running()
            if not thread then error("Scorpio.Continue() can only be used in a thread.", 2) end

            queueTask(HIGH_PRIORITY, thread)

            return yield()
        end

        ---Call method or resume thread with normal priority, the method(thread) should be called(resumed) in the next phase.
        --@format [func[, ...]]
        --@param func           The function
        --@param ...            method parameter
        __Arguments__{ Function, Any * 0 }
        __Static__() function Next(func, ...)
            return queueTask(NORMAL_PRIORITY, wrapAsSimpleTask(func, ...))
        end

        __Arguments__{ IObservable }
        __Static__() function Next(observable)
            local thread        = running()
            if not thread then error("Scorpio.Next(observable) can only be used in a thread.", 2) end

            local obNext        = rycNextObserver()
            obNext.NextThread   = thread
            observable:Subscribe(obNext)

            return yieldReturn(yield())
        end

        __Arguments__{ }
        __Static__() function Next()
            local thread        = running()
            if not thread then error("Scorpio.Next() can only be used in a thread.", 2) end

            queueTask(NORMAL_PRIORITY, thread)

            return yield()
        end

        --- Call method|yield current thread and resume it after several seconds
        --@format delay[, func[, ...]]
        --@param delay          the time to delay
        --@param func           The function
        --@param ...            method parameter
        __Arguments__{ Number, Function, Any * 0 }
        __Static__() function Delay(delay, func, ...)
            return queueDelayTask(wrapAsSystemTask(func, ...), delay)
        end

        __Arguments__{ Number }
        __Static__() function Delay(delay)
            local thread = running()
            if not thread then error("Scorpio.Delay(delay) can only be used in a thread.", 2) end

            queueDelayTask(thread, delay)

            return yieldReturn(yield())
        end

        --- Call method|yield current thread and resume it after special system event
        --@format event[, func[, ...]]
        --@param event          the system event name
        --@param func           The function
        --@param ...            method parameter
        __Arguments__{ NEString, Function, Any * 0 }
        __Static__() function NextEvent(event, func, ...)
            return queueEventTask(wrapAsSystemTask(func, ...), event)
        end

        __Arguments__{ NEString }
        __Static__() function NextEvent(event)
            local thread = running()
            if not thread then error("Scorpio.NextEvent(event) can only be used in a thread.", 2) end

            queueEventTask(thread, event)

            return yieldReturn(yield())
        end

        --- Call method|yield current thread when not in combat
        --@format [func[, ...]]
        --@param func           The function
        --@param ...            the arguments
        __Arguments__{ Function, Any * 0 }
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
        __Arguments__{ Function, Number, NEString * 0 }
        __Static__() function Wait(func, delay, ...)
            return queueWaitTask(wrapAsSystemTask(func), delay, ...)
        end

        __Arguments__{ Function, NEString * 1 }
        __Static__() function Wait(func, ...)
            return queueWaitTask(wrapAsSystemTask(func), nil, ...)
        end

        __Arguments__{ Number, NEString * 0 }
        __Static__() function Wait(delay, ...)
            local thread = running()
            if not thread then error("Scorpio.Wait([waitTime, ][event, ...]) can only be used in a thread.", 2) end

            queueWaitTask(thread, delay, ...)

            return yieldReturn(yield())
        end

        __Arguments__{ NEString * 1 }
        __Static__() function Wait(...)
            local thread = running()
            if not thread then error("Scorpio.Wait([waitTime, ][event, ...]) can only be used in a thread.", 2) end

            queueWaitTask(thread, nil, ...)

            return yieldReturn(yield())
        end

        --- Call method|yield current thread and resume it after secure object-method call
        --@format [func, ][target, ]targetFunction[, ...]
        --@param func           The function
        --@param target         table, the target table, default _G
        --@param targetFunction string, the target table's method name
        --@param ...            custom params if you don't need real params of the method-call
        __Arguments__{ Function, Table, NEString, Any * 0}
        __Static__() function NextSecureCall(func, target, targetFunc, ...)
            return queueNextSecureCall(wrapAsSystemTask(func, ...), target, targetFunc)
        end

        __Arguments__{ Function, NEString, Any * 0}
        __Static__() function NextSecureCall(func, targetFunc, ...)
            return queueNextSecureCall(wrapAsSystemTask(func, ...), _G, targetFunc)
        end

        __Arguments__{ Table, NEString }
        __Static__() function NextSecureCall(target, targetFunc)
            local thread = running()
            if not thread then error("Scorpio.NextSecureCall([target, ]targetFunc) can only be used in a thread.", 2) end

            queueNextSecureCall(thread, target, targetFunc)

            return yieldReturn(yield())
        end

        __Arguments__{ NEString }
        __Static__() function NextSecureCall(targetFunc)
            local thread = running()
            if not thread then error("Scorpio.NextSecureCall([target, ]targetFunc) can only be used in a thread.", 2) end

            queueNextSecureCall(thread, _G, targetFunc)

            return yieldReturn(yield())
        end

        --- Run a method as service
        __Arguments__{ Function, Boolean/nil }
        __Static__() function RunAsService(func, resident)
            registerService(func, resident)
            processService()
        end

        ----------------------------------------------
        --                  Event                   --
        ----------------------------------------------
        --- Fired when the addon(module) and it's saved variables is loaded
        event "OnLoad"

        --- Fired when player specialization changed
        event "OnSpecChanged"

        --- Fired when player toggle the war mode
        event "OnWarModeChanged"

        --- Fired when the addon(module) is enabled
        event "OnEnable"

        --- Fired when the addon(module) is disabled
        event "OnDisable"

        --- Fired when the player log out
        event "OnQuit"

        ----------------------------------------------
        --             Static  Property             --
        ----------------------------------------------
        --- Enable smoothing loading to minimal the loading screen
        __Static__() property "SmoothLoading"   { type = Boolean, get = function() return SMOOTH_LOADING end, set = function(self, val) SMOOTH_LOADING = val or false end }

        --- The max task operation time per phase(ms)
        __Static__() property "TaskThreshold"   { type = Integer, get = function() return PHASE_THRESHOLD end, set = function(self, val) PHASE_THRESHOLD = Clamp(val or 0, 5, 100) end }

        --- The factor used to calculate the task operation time per phase
        __Static__() property "TaskFactor"      { type = Number, get = function() return PHASE_TIME_FACTOR end, set = function(self, val) PHASE_TIME_FACTOR = Clamp(val or 0, 0.1, 1) end }

        --- Whether the task schedule system is suspended
        __Static__() property "SystemSuspended" { type = Boolean, get = function() return r_InLoadingScreen end, set = function(self, val) r_InLoadingScreen = val end }

        --- Whether the game is retail version
        __Static__() property "IsRetail"        { type = Boolean, default = function() return _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE end }

        --- Whether the game is classic version
        __Static__() property "IsClassic"       { type = Boolean, default = function() return _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC end }

        --- Whether the game is classic burning crusade
        __Static__() property "IsBCC"           { type = Boolean, default = function() return _G.WOW_PROJECT_ID == _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC end }

        --- Whether the game is WLK
        __Static__() property "IsWLK"           { type = Boolean, default = function() return _G.WOW_PROJECT_ID == _G.WOW_PROJECT_WRATH_CLASSIC end }

        --- Whether the game is Cataclysm
        __Static__() property "IsCataclysm"     { type = Boolean, default = function() return _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CATACLYSM_CLASSIC end }

        ----------------------------------------------
        --                 Property                 --
        ----------------------------------------------
        --- Whether the module is enabled
        property "_Enabled"         { type = Boolean, default = true, handler = function(self, val) if val then return tryEnable(self) else return disabling(self) end end }

        --- Whether the module is disabled by itself or it's parent
        property "_Disabled"        { get = function (self) return _DisabledModule[self] or false end }

        --- Whether the module is already loaded with saved variables
        property "_Loaded"          { get = function(self) return not _NotLoaded[self] end }

        --- The addon of the module
        property "_Addon"           { get = function(self) while self._Parent do self = self._Parent end return self end }

        --- The localiaztion
        property "_Locale"          { type = Localization, default = function(self) return Localization(self._Addon._Name) end }

        --- The saved variable config node, don't make it readonly, so sub-addon can have its own config node with its own saved variables
        property "_Config"          { type = AddonConfigNode, default = function(self) return self._Parent and self._Parent._Config or AddonConfigNode(self) end }

        --- The saved variable per character config node
        property "_CharConfig"      { set = false, default = function(self) return CharConfigNode(self._Config, "__char") end }

        --- The saved variable spec config node
        property "_SpecConfig"      { set = false, default = function(self) return SpecConfigNode(self._CharConfig, "__spec") end }

        --- The saved variable war mode config node
        property "_WarModeConfig"   { set = false, default = function(self) return WarModeConfigNode(self._SpecConfig, "__warmode") end }

        ----------------------------------------------
        --                  Dispose                 --
        ----------------------------------------------
        function Dispose(self)
            self:UnregisterAllEvents()

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
            __Arguments__{ NEString * 0 }
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

        --- Register a combat event with a handler, the handler's name is the event name
        -- @usage
        --      Scorpio "MyAddon" "v1.0.1"
        --
        --      __CombatEvent__()
        --      function SPELL_CAST_START(...)
        --      end
        --
        --      __CombatEvent__ "SPELL_CAST_SUCCESS" "SPELL_MISSED"
        --      function SPELL_CAST(...)
        --      end
        class "__CombatEvent__" (function(_ENV)
            extend "IAttachAttribute"

            function AttachAttribute(self, target, targettype, owner, name, stack)
                if Class.IsObjectType(owner, Scorpio) then
                    if #self > 0 then
                        for _, evt in ipairs(self) do
                            owner:RegisterCombatEvent(evt, target)
                        end
                    else
                        owner:RegisterCombatEvent(name, target)
                    end
                else
                    error("__CombatEvent__ can only be applyed to objects of Scorpio.", stack + 1)
                end
            end

            ----------------------------------------------
            --                 Property                 --
            ----------------------------------------------
            property "AttributeTarget"  { default = AttributeTargets.Function }

            ----------------------------------------------
            --                Constructor               --
            ----------------------------------------------
            __Arguments__{ NEString * 0 }
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
            __Arguments__{ Table, NEString/nil }
            function __SecureHook__(self, target, targetFunc)
                self.Target = target
                self.TargetFunc = targetFunc
            end

            __Arguments__{ NEString/nil }
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
            __Arguments__{ NEString, NEString/nil, NEString/nil }
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
            __Arguments__{ NEString, NEString/nil }
            function __AddonSecureHook__(self, addon, targetFunc)
                self.Addon = addon
                self.Target = _G
                self.TargetFunc = targetFunc
            end
        end)

        --- Mark the method as an async service so it'd be automatically processed
        -- when the addon is loaded, and the system will try to re-process it if the
        -- process is dead as required
        -- @usage
        --      Scorpio "MyAddon" "v1.0.1"
        --
        --      __Service__(true) -- auto restarted
        --      function MyService()
        --          while Wait("PLAYER_FLAGS_CHANGED") do
        --              print("The pvp mode is " .. (C_PvP.IsWarModeDesired() and "active" or "deactive"))
        --          end
        --      end
        __Sealed__()
        class "__Service__" (function(_ENV)
            extend "IAttachAttribute"

            -----------------------------------------------------------
            --                        method                         --
            -----------------------------------------------------------
            function AttachAttribute(self, target, targettype, owner, name, stack)
                registerService(target, self[1])
            end

            -----------------------------------------------------------
            --                       property                        --
            -----------------------------------------------------------
            --- the attribute target
            property "AttributeTarget"  { type = AttributeTargets,  default = AttributeTargets.Method + AttributeTargets.Function }

            -----------------------------------------------------------
            --                      constructor                      --
            -----------------------------------------------------------
            __Arguments__{ Boolean/nil }
            function __Service__(self, flag)
                self[1]         = flag
            end
        end)

        --- Mark the async method that can only be run one copy in the same time.
        -- So if the method is still running, another call will be cancelled.
        -- We can also change the behavior by set the override flag to true, so
        -- when call the method again, the previous call will be cancelled.
        __Sealed__()
        class "__AsyncSingle__" (function(_ENV)
            extend "IInitAttribute"

            -----------------------------------------------------------
            --                        method                         --
            -----------------------------------------------------------
            --- modify the target's definition
            -- @param   target                      the target
            -- @param   targettype                  the target type
            -- @param   definition                  the target's definition
            -- @param   owner                       the target's owner
            -- @param   name                        the target's name in the owner
            -- @param   stack                       the stack level
            -- @return  definition                  the new definition
            function InitDefinition(self, target, targettype, definition, owner, name, stack)
                if targettype == AttributeTargets.Method and (Class.Validate(owner) or Interface.Validate(owner))  then
                    return registerSingleAsync(definition, self[1], owner, name)
                else
                    return registerSingleAsync(definition, self[1])
                end
            end

            -----------------------------------------------------------
            --                       property                        --
            -----------------------------------------------------------
            --- the attribute target
            property "AttributeTarget"  { type = AttributeTargets,  default = AttributeTargets.Method + AttributeTargets.Function }

            --- the attribute's priority
            property "Priority"         { type = AttributePriority, default = AttributePriority.Lower }

            -----------------------------------------------------------
            --                      constructor                      --
            -----------------------------------------------------------
            function __new(_, override) return { override }, true end
        end)

        ----------------------------------------------
        --              System Prepare              --
        ----------------------------------------------
        Environment.RegisterGlobalNamespace("Scorpio")

        ScorpioManager:SetScript("OnEvent", ScorpioManager.OnEvent)
        ScorpioManager:SetScript("OnUpdate", ScorpioManager.OnUpdate)
        ScorpioManager:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

        RegisterEvent(ScorpioManager, "ADDON_LOADED")
        RegisterEvent(ScorpioManager, "PLAYER_LOGIN")
        RegisterEvent(ScorpioManager, "PLAYER_LOGOUT")
        RegisterEvent(ScorpioManager, _G.GetSpecialization and "PLAYER_SPECIALIZATION_CHANGED" or "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_SPECIALIZATION_CHANGED")
        RegisterEvent(ScorpioManager, "PLAYER_ENTERING_WORLD")
        RegisterEvent(ScorpioManager, "PLAYER_FLAGS_CHANGED")
        RegisterEvent(ScorpioManager, "LOADING_SCREEN_DISABLED")
        RegisterEvent(ScorpioManager, "LOADING_SCREEN_ENABLED")

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
                            recycleCache(cache)

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
                Log(2, "--======================--")

                Log(2, "[Delayed] %d", g_DelayedTask)
                Log(2, "[Low Task Levelup] %d", g_LowLevelup)
                Log(2, "[Average] %.2f ms", g_AverageTime)
                Log(2, "[Max Phase] %.2f ms", g_MaxPhaseTime)
                Log(2, "[Cache][Generated] %d", g_CacheGenerated)
                Log(2, "[Cache][Remain] %d", g_CacheRamain)

                Log(2, "--======================--")

                g_DelayedTask       = 0
                g_LowLevelup        = 0
                g_MaxPhaseTime      = 0
                g_CacheGenerated    = 0

                Delay(DIAGNOSE_DELAY)
            end
        end)
    end)
end)