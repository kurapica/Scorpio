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
------------ Addon Event Handler -------------
----------------------------------------------
function OnLoad(self)
    _SVData = SVManager( "Scorpio_DB" ,"Scorpio_DB_Char" )

    _SVData:SetDefault{ LogLevel = 3 }

    -- Load log level
    Log.LogLevel = _SVData.LogLevel
end

----------------------------------------------
------------------ SlashCmd ------------------
----------------------------------------------
__SlashCmd__ "Scorpio" "log"
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
