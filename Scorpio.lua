--========================================================--
--                Scorpio Addon                           --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/12/14                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio"                         "1.0.0"
--========================================================--

-- Register the scorpio locale as the root localization to share the translation
Localization.Root           = _Locale

----------------------------------------------
--           Addon Event Handler            --
----------------------------------------------
function OnLoad(self)
    _SVData                 = SVManager( "Scorpio_DB" ,"Scorpio_DB_Char" )
    _Addon:SetSavedVariable("Scorpio_Setting"):UseConfigPanel()

    -- Bind the SetDefault log handler
    Logger.Default:AddHandler(errorhandler, Logger.LogLevel.Error)
    Logger.Default:AddHandler(print, Logger.LogLevel.Info)
end

----------------------------------------------
--                  Config                  --
----------------------------------------------
-- Enable the smoothing loading
__Config__(_Config, false)
function SmoothLoading(enable)
    Scorpio.SmoothLoading       = enable
end

-- The log level
__Config__(_Config, Logger.LogLevel, Logger.LogLevel.Info)
function LogLevel(level)
    Log.LogLevel                = level
end

-- Set the task threshold, the smaller the system more smooth
__Config__(_Config, RangeValue[{5, 50, 1}], 15)
function TaskThreshold(value)
    Scorpio.TaskThreshold       = value
end

-- Set the task factor, the smaller the system more smooth"
__Config__(_Config, RangeValue[{0.1, 1, 0.01}], 0.4)
function TaskFactor(value)
    Scorpio.TaskFactor          = value
end
