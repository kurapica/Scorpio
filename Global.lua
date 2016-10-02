--========================================================--
--                Global Features                         --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/09/09                              --
--========================================================--

--========================================================--
Module                   "Scorpio"                   "0.0.0"
--========================================================--

import "System"

------------------------------------------------------------
--                       Constant                         --
------------------------------------------------------------
META_WEAKKEY = { __mode = "k" }
META_WEAKVAL = { __mode = "v" }
META_WEAKALL = { __mode = "kv"}

------------------------------------------------------------
--                        Logger                          --
------------------------------------------------------------
Log = System.Logger("Scorpio")

Log.TimeFormat = "%X"
Trace = Log:SetPrefix(1, "|cffa9a9a9[Scorpio]|r", true)
Debug = Log:SetPrefix(2, "|cff808080[Scorpio]|r", true)
Info = Log:SetPrefix(3, "|cffffffff[Scorpio]|r", true)
Warn = Log:SetPrefix(4, "|cffffff00[Scorpio]|r", true)
Error = Log:SetPrefix(5, "|cffff0000[Scorpio]|r", true)
Fatal = Log:SetPrefix(6, "|cff8b0000[Scorpio]|r", true)

Log.LogLevel = 3

Log:AddHandler(print)

------------------------------------------------------------
--                          APIS                          --
------------------------------------------------------------
strlen = string.len
strformat = string.format
strfind = string.find
strsub = string.sub
strbyte = string.byte
strchar = string.char
strrep = string.rep
strsub = string.gsub
strupper = string.upper
strtrim = strtrim or function(s)
  return (s:gsub("^%s*(.-)%s*$", "%1")) or ""
end
strmatch = string.match

wipe = wipe or function(t)
	for k in pairs(t) do
		t[k] = nil
	end
	return t
end

geterrorhandler = geterrorhandler or function()
	return print
end

errorhandler = errorhandler or function(err)
	return geterrorhandler()(err)
end

tblconcat = table.concat
tinsert = tinsert or table.insert
tremove = tremove or table.remove

floor = math.floor
ceil = math.ceil
log = math.log
pow = math.pow
min = math.min
max = math.max
random = math.random

date = date or (os and os.date)

create = coroutine.create
resume = coroutine.resume
running = coroutine.running
status = coroutine.status
wrap = coroutine.wrap
yield = coroutine.yield

loadstring = loadstring or load