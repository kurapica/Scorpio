--========================================================--
--                Scorpio Addon                           --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/12/14                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio"                         "1.0.0"
--========================================================--

----------------------------------------------
--           Addon Event Handler            --
----------------------------------------------
function OnLoad(self)
    _SVData                 = SVManager( "Scorpio_DB" ,"Scorpio_DB_Char" )

    _SVData:SetDefault {
        -- The log level
        LogLevel            = 3,

        -- The task schedule system settings
        TaskThreshold       = 15,
        TaskFactor          = 0.4,
    }

    -- Load log level
    Log.LogLevel            = _SVData.LogLevel

    Scorpio.TaskThreshold   = _SVData.TaskThreshold
    Scorpio.TaskFactor      = _SVData.TaskFactor

    -- Bind the SetDefault log handler
    Logger.Default:AddHandler(errorhandler, Logger.LogLevel.Error)
    Logger.Default:AddHandler(print, Logger.LogLevel.Info)
end

__Async__()
function OnEnable()
    local cache             = List()

    for _, name in ipairs{ "PLoop", "Scorpio.UI", "Scorpio.Widget", "Scorpio.Secure", "Scorpio.Unit", "Scorpio.Action" } do
        local _, title      = GetAddOnInfo(name)
        if title then
            cache:Insert(name)
        end
    end

    if #cache > 0 then
        Alert(_Locale["Please delete those addons:"] .. cache:Join(", "))
    end
end

----------------------------------------------
--                 SlashCmd                 --
----------------------------------------------
__SlashCmd__ "Scorpio" "log" "lvl - set the log level of the Scorpio"
function ToggleLogLevel(info)
    local lvl, msg = info:match("(%d+)%s*(.*)")
    lvl = tonumber(lvl)
    if lvl then
        if msg and msg ~= "" then
            Log(lvl, msg)
        elseif lvl and floor(lvl) == lvl and lvl >=1 and lvl <= 6 then
            Info("Scorpio's log level is turn to %d", lvl)
            Log.LogLevel = lvl
            _SVData.LogLevel = lvl
        end
    end
end

__SlashCmd__ "Scorpio" "taskthreshold" "[5-100] - set the task threshold, the smaller the system more smooth"
function SetTaskThreshold(info)
    local val = tonumber(info) or 15
    Scorpio.TaskThreshold = val
    _SVData.TaskThreshold = Scorpio.TaskThreshold
    Info("Scorpio's task threshold is set to %d", _SVData.TaskThreshold)
end

__SlashCmd__ "Scorpio" "taskfactor" "[0.1-1] - set the task factor, the smaller the system more smooth"
function SetTaskFactor(info)
    local val = tonumber(info) or 0.4
    Scorpio.TaskFactor = val
    _SVData.TaskFactor = Scorpio.TaskFactor
    Info("Scorpio's task factor is set to %.2f", _SVData.TaskFactor)
end

__SlashCmd__ "Scorpio" "suspend" " - suspend the task schedule system temporarily"
function SuspendSystem()
    Scorpio.SystemSuspended = true
end

__SlashCmd__ "Scorpio" "resume" " - resume the task schedule system"
function ResumeSystem()
    Scorpio.SystemSuspended = false
end

__SlashCmd__ "Scorpio" "info" "show the current system settings"
function GetInfo()
    Info("--====================--")
    Info("[log level] - %d", _SVData.LogLevel)
    Info("[task threshold] - %d", _SVData.TaskThreshold)
    Info("[task factor] - %.2f", _SVData.TaskFactor)
    Info("[system suspended] - %s", tostring(Scorpio.SystemSuspended))
    Info("--====================--")
end