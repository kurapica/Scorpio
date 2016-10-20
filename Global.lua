--========================================================--
--                Global Features                         --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/09/09                              --
--========================================================--

--========================================================--
Module            "Scorpio"                               ""
--========================================================--

namespace "Scorpio"

import "System"
import "System.Serialization"
import "System.Collections"

------------------------------------------------------------
--                       Constant                         --
------------------------------------------------------------
META_WEAKKEY   = { __mode = "k" }
META_WEAKVAL   = { __mode = "v" }
META_WEAKALL   = { __mode = "kv"}

------------------------------------------------------------
--                        Logger                          --
------------------------------------------------------------
Log            = System.Logger("Scorpio")

Log.TimeFormat = "%X"
Trace          = Log:SetPrefix(1, "|cffa9a9a9[Scorpio]|r", true)
Debug          = Log:SetPrefix(2, "|cff808080[Scorpio]|r", true)
Info           = Log:SetPrefix(3, "|cffffffff[Scorpio]|r", true)
Warn           = Log:SetPrefix(4, "|cffffff00[Scorpio]|r", true)
Error          = Log:SetPrefix(5, "|cffff0000[Scorpio]|r", true)
Fatal          = Log:SetPrefix(6, "|cff8b0000[Scorpio]|r", true)

Log.LogLevel   = 3

Log:AddHandler(print)

------------------------------------------------------------
--                          APIS                          --
------------------------------------------------------------

------------------- String -------------------
strlen         = string.len
strformat      = string.format
strfind        = string.find
strsub         = string.sub
strbyte        = string.byte
strchar        = string.char
strrep         = string.rep
strsub         = string.gsub
strupper       = string.upper
strtrim        = strtrim or function(s) return (s:gsub("^%s*(.-)%s*$", "%1")) or "" end
strmatch       = string.match

------------------- Error --------------------
geterrorhandler= geterrorhandler or function() return print end
errorhandler   = errorhandler or function(err) return geterrorhandler()(err) end

------------------- Table --------------------
tblconcat      = table.concat
tinsert        = tinsert or table.insert
tremove        = tremove or table.remove
wipe           = wipe or function(t) for k in pairs(t) do t[k] = nil end return t end

------------------- Math ---------------------
floor          = math.floor
ceil           = math.ceil
log            = math.log
pow            = math.pow
min            = math.min
max            = math.max
random         = math.random

------------------- Date ---------------------
date           = date or (os and os.date)

------------------- Coroutine ----------------
create         = coroutine.create
resume         = coroutine.resume
running        = coroutine.running
status         = coroutine.status
wrap           = coroutine.wrap
yield          = coroutine.yield

------------------- Load ---------------------
loadstring     = loadstring or load
