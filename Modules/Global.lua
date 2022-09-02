--========================================================--
--                Scorpio Addon                           --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/12/14                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio"                              ""
--========================================================--

namespace          "Scorpio"

import "System.Serialization"

------------------------------------------------------------
--                        Prepare                         --
------------------------------------------------------------

GetSpecialization               = GetSpecialization or function() return 1 end
IsWarModeDesired                = C_PvP and C_PvP.IsWarModeDesired or function() return false end

-------------------- META --------------------
META_WEAKKEY                    = { __mode = "k" }
META_WEAKVAL                    = { __mode = "v" }
META_WEAKALL                    = { __mode = "kv"}

------------------- Logger ----------------T--
Log                             = System.Logger("Scorpio")

Log.TimeFormat                  = "%X"
Trace                           = Log:SetPrefix(Logger.LogLevel.Trace, "|cffa9a9a9[Scorpio]|r", true)
Debug                           = Log:SetPrefix(Logger.LogLevel.Debug, "|cff808080[Scorpio]|r", true)
Info                            = Log:SetPrefix(Logger.LogLevel.Info,  "|cffffffff[Scorpio]|r", true)
Warn                            = Log:SetPrefix(Logger.LogLevel.Warn,  "|cffffff00[Scorpio]|r", true)
Error                           = Log:SetPrefix(Logger.LogLevel.Error, "|cffff0000[Scorpio]|r", true)
Fatal                           = Log:SetPrefix(Logger.LogLevel.Fatal, "|cff8b0000[Scorpio]|r", true)

Log:AddHandler(print)

------------------- String -------------------
strformat                       = string.format
strfind                         = string.find
strsub                          = string.sub
strbyte                         = string.byte
strchar                         = string.char
strrep                          = string.rep
strgsub                         = string.gsub
strupper                        = string.upper
strlower                        = string.lower
strtrim                         = strtrim or Toolset.trim
strmatch                        = string.match

__Iterator__() __Arguments__{ String, String, Boolean/nil }
function strsplit(self, delimiter, plain)
    local i                     = 1
    local s, e                  = strfind(self, delimiter, i, plain)

    while s do
        if i <= s then yield(i, strsub(self, i, s - 1), strsub(self, s, e)) end
        i                       = e + 1
        s, e                    = strfind(self, delimiter, i, plain)
    end

    yield(i, strsub(self, i, -1), "")
end


------------------- Error --------------------
geterrorhandler                 = geterrorhandler or function() return print end
errorhandler                    = _G.errorhandler or function(err) return geterrorhandler()(err) end

------------------- Table --------------------
tblconcat                       = table.concat
tinsert                         = tinsert or table.insert
tremove                         = tremove or table.remove
wipe                            = wipe or function(t) for k in pairs(t) do t[k] = nil end return t end

------------------- Math ---------------------
floor                           = math.floor
ceil                            = math.ceil
log                             = math.log
pow                             = math.pow
min                             = math.min
max                             = math.max
mod                             = math.mod
random                          = math.random
abs                             = math.abs
clamp                           = function(value, min, max) return value > max and max or value < min and min or value end

------------------- Date ---------------------
date                            = date or (os and os.date)

------------------- Coroutine ----------------
create                          = coroutine.create
resume                          = coroutine.resume
running                         = coroutine.running
status                          = coroutine.status
wrap                            = coroutine.wrap
yield                           = coroutine.yield

------------------ Common --------------------
loadstring                      = loadstring or load
getRealMethodCache              = function (name) return setmetatable({}, { __index = function(self, cls) local real = Class.GetNormalMethod(cls, name)     rawset(self, cls, real) return real end }) end
getRealMetaMethodCache          = function (name) return setmetatable({}, { __index = function(self, cls) local real = Class.GetNormalMetaMethod(cls, name) rawset(self, cls, real) return real end }) end

------------------------------------------------------------
--                         Enums                          --
------------------------------------------------------------
__Sealed__()
enum "Classes"                  {
    "WARRIOR",
    "MAGE",
    "ROGUE",
    "DRUID",
    "HUNTER",
    "SHAMAN",
    "PRIEST",
    "WARLOCK",
    "PALADIN",
    "DEATHKNIGHT",
    "MONK",
    "DEMONHUNTER",
}

__Sealed__()
enum "ClassPower"   {
    MANA                        =  0,
    RAGE                        =  1,
    FOCUS                       =  2,
    ENERGY                      =  3,
    COMBO_POINTS                =  4,
    RUNES                       =  5,
    RUNIC_POWER                 =  6,
    SOUL_SHARDS                 =  7,
    LUNAR_POWER                 =  8,
    HOLY_POWER                  =  9,
    ALTERNATE                   = 10,
    MAELSTROM                   = 11,
    CHI                         = 12,
    INSANITY                    = 13,
    -- OBSOLETE                 = 14,
    -- OBSOLETE2                = 15,
    ARCANE_CHARGES              = 16,
    FURY                        = 17,
    PAIN                        = 18,
}

__Sealed__()
enum "WarMode"  {
    PVE                         = 1,
    PVP                         = 2,
}

------------------------------------------------------------
--                       Data Types                       --
------------------------------------------------------------
__Sealed__()
struct "LocaleString" { __base = String }

__Sealed__()
struct "ColorFloat" {
    __base = Number,
    function(val, onlyvalid) if (val < 0 or val > 1) then return onlyvalid or "the %s must between [0, 1]" end end
}

__Sealed__()
struct "HueValue" {
    __base = Number,
    function(val, onlyvalid) if (val < 0 or val > 360) then return onlyvalid or "the %s must between [0, 360]" end end
}

__Sealed__() __ObjectAllowed__()
struct "ColorType" {
    { name = "r",   type = ColorFloat, require = true },
    { name = "g",   type = ColorFloat, require = true },
    { name = "b",   type = ColorFloat, require = true },
    { name = "a",   type = ColorFloat, default = 1 },

    __init = function(val) return Color(val) end,
}

__Sealed__()
struct "HSVType" {
    { name = "h",   type = HueValue,    require = true },
    { name = "s",   type = ColorFloat,  require = true },
    { name = "v",   type = ColorFloat,  require = true },
}

__Sealed__()
struct "HSLType" {
    { name = "h",   type = HueValue,    require = true },
    { name = "s",   type = ColorFloat,  require = true },
    { name = "l",   type = ColorFloat,  require = true },
}

--- The color data, 'Color(r, g, b[, a])' - used to create a color data,
-- use obj.r, obj.g, obj.b, obj.a to access the color's part,
-- also 'obj .. "text"' can be used to concat values.
--
-- Some special color can be accessed like 'Color.Red', 'Color.Player', 'Color.Mage'
class "Color" (function(_ENV)
    extend "ICloneable"

    export { maxv = math.max, minv = math.min, floor = math.floor }

    local InnerColorType     = struct {
        { name = "r",   type = ColorFloat, require = true },
        { name = "g",   type = ColorFloat, require = true },
        { name = "b",   type = ColorFloat, require = true },
        { name = "a",   type = ColorFloat, default = 1 },
    }


    local function clamp(v) return minv(1, maxv(0, v)) end

    local function fromHSV(h, s, v)
        local r, g, b

        if s == 0 then
            r           = v
            g           = v
            b           = v
        else
            h           = h / 60.0
            local i     = floor(h)
            local f     = h - i
            local p     = v * (1 - s)
            local q     = v * (1 - s * f)
            local t     = v * (1 - s * (1 - f))

            if i == 0 then
                r       = v
                g       = t
                b       = p
            elseif i == 1 then
                r       = q
                g       = v
                b       = p
            elseif i == 2 then
                r       = p
                g       = v
                b       = t
            elseif i == 3 then
                r       = p
                g       = q
                b       = v
            elseif i == 4 then
                r       = t
                g       = p
                b       = v
            elseif i == 5 then
                r       = v
                g       = p
                b       = q
            end
        end

        return r, g, b
    end

    local function toHSV(r, g, b)
        local h, s, v

        local min       = minv(r, g, b)
        local max       = maxv(r, g, b)
        local delta     = max - min

        v               = max
        if max == 0 then
            s           = 0
            h           = 0
        else
            s           = delta / max

            if delta == 0 then
                h       = 0
            elseif max == r then
                h       = 60 * (g - b) / delta
                if h < 0 then h = h + 360 end
            elseif max == g then
                h       = 60 * (b - r) / delta + 120
            elseif max == b then
                h       = 60 * (r - g) / delta + 240
            end
        end

        return h, s, v
    end

    local function fromHSL(h, s, l)
        local r, g, b

        if s == 0 then
            r           = l
            g           = l
            b           = l
        else
            local q     = l < 1/2 and (l * (1 + s)) or (l + s - (l * s))
            local p     = 2 * l - q
            local hk    = h / 360.0
            local tr    = hk + 1/3
            local tg    = hk
            local tb    = hk - 1/3
            tr          = tr < 0 and tr + 1 or tr > 1 and tr - 1 or tr
            tg          = tg < 0 and tg + 1 or tg > 1 and tg - 1 or tg
            tb          = tb < 0 and tb + 1 or tb > 1 and tb - 1 or tb

            r           = tr < 1/6 and (p + ((q - p) * 6 * tr)) or tr < 1/2 and q or tr < 2/3 and (p + ((q - p) * 6 * (2/3 - tr))) or p
            g           = tg < 1/6 and (p + ((q - p) * 6 * tg)) or tg < 1/2 and q or tg < 2/3 and (p + ((q - p) * 6 * (2/3 - tg))) or p
            b           = tb < 1/6 and (p + ((q - p) * 6 * tb)) or tb < 1/2 and q or tb < 2/3 and (p + ((q - p) * 6 * (2/3 - tb))) or p
        end

        return r, g, b
    end

    local function toHSL(r, g, b)
        local h, s, l

        local min       = minv(r, g, b)
        local max       = maxv(r, g, b)
        local delta     = max - min

        l               = (max + min) / 2
        if l == 0 then
            s           = 0
            h           = 0
        else
            if l <= 1/2 then
                s       = delta / (2 * l)
            else
                s       = delta / (2 - 2 * l)
            end

            if delta == 0 then
                h       = 0
            elseif max == r then
                h       = 60 * (g - b) / delta
                if h < 0 then h = h + 360 end
            elseif max == g then
                h       = 60 * (b - r) / delta + 120
            elseif max == b then
                h       = 60 * (r - g) / delta + 240
            end
        end

        return h, s, l
    end

    ----------------------------------------------
    --              static method               --
    ----------------------------------------------
    --- Generate a color object from hsv
    __Arguments__{ HueValue, ColorFloat, ColorFloat }
    __Static__() function FromHSV(h, s, v)
        return Color(fromHSV(h, s, v))
    end

    __Arguments__{ HSVType }
    __Static__() function FromHSV(hsv)
        return Color(fromHSV(hsv.h, hsv.s, hsv.v))
    end

    --- generate a color object from hsl
    __Arguments__{ HueValue, ColorFloat, ColorFloat }
    __Static__() function FromHSL(h, s, l)
        return Color(fromHSL(h, s, l))
    end

    __Arguments__{ HSLType }
    __Static__() function FromHSL(hsl)
        return Color(fromHSL(hsl.h, hsl.s, hsl.l))
    end

    ----------------------------------------------
    --                  method                  --
    ----------------------------------------------
    --- return the clone of the object
    function Clone(self) return Color(self.r, self.g, self.b, self.a) end

    --- Set the hsv value to the color
    __Arguments__{ HueValue, ColorFloat, ColorFloat }
    function SetHSV(self, h, s, v)
        self.r, self.g, self.b = fromHSV(h, s, v)
    end

    --- return the hsv value from the color
    function ToHSV(self)
        return toHSV(self.r, self.g, self.b)
    end

    --- Set the hsl value to the color
    __Arguments__{ HueValue, ColorFloat, ColorFloat }
    function SetHSL(self, h, s, l)
        self.r, self.g, self.b = fromHSL(h, s, l)
    end

    --- return the hsl value from the color
    function ToHSL(self)
        return toHSL(self.r, self.g, self.b)
    end

    ----------------------------------------------
    --               Constructor                --
    ----------------------------------------------
    __Arguments__{ Color }
    function __exist(_, color)
        return color, true
    end

    __Arguments__{ Any * 0 }
    function __exist() end

    __Arguments__{ InnerColorType }
    function __new(_, color)
        return color, true
    end

    __Arguments__{
        Variable("r", ColorFloat),
        Variable("g", ColorFloat),
        Variable("b", ColorFloat),
        Variable("a", ColorFloat, true, 1),
    }
    function __new(_, r, g, b, a)
        return { r = r, g = g, b = b, a = a }, true
    end

    __Arguments__{ String }
    function __new(_, str)
        local r, g, b, a        = str:match("|c(%w%w)(%w%w)(%w%w)(%w%w)")
        if r and g and b and a then
            r                   = tonumber(r, 16)
            g                   = tonumber(g, 16)
            b                   = tonumber(b, 16)
            a                   = tonumber(a, 16)

            if r and g and b and a then
                return { r = r / 255, g = g / 255, b = b / 255, a = a / 255 }, true
            end
        end
        throw("The color string is not valid")
    end

    ----------------------------------------------
    ----------------- Meta-Method ----------------
    ----------------------------------------------
    function __tostring(self)
        return ("\124c%.2x%.2x%.2x%.2x"):format(self.a * 255, self.r * 255, self.g * 255, self.b * 255)
    end

    function __concat(self, val)
        return tostring(self) .. tostring(val)
    end

    function __eq(self, val)
        return self.r == val.r and self.g == val.g and self.b == val.b
    end
end)

------------------------------------------------------------
--                    Special Colors                      --
------------------------------------------------------------
__Sealed__() __Final__()
class "Color" (function(_ENV)
    ----------------------------------------------
    --             Static Property              --
    ----------------------------------------------
    --- The close tag to close color text
    __Static__() property "CLOSE"           { set = false, default = "|r" }

    --- The player's default color
    __Static__() property "PLAYER"          { type = Color }

    ------------------ Classes ------------------
    --- The Hunter class's default color
    __Static__() property "HUNTER"          { default = Color(0.67, 0.83, 0.45) }

    --- The Warlock class's default color
    __Static__() property "WARLOCK"         { default = Color(0.53, 0.53, 0.93) }

    --- The Priest class's default color
    __Static__() property "PRIEST"          { default = Color(1.00, 1.00, 1.00) }

    --- The Paladin class's default color
    __Static__() property "PALADIN"         { default = Color(0.96, 0.55, 0.73) }

    --- The Mage class's default color
    __Static__() property "MAGE"            { default = Color(0.25, 0.78, 0.92) }

    --- The Rogue class's default color
    __Static__() property "ROGUE"           { default = Color(1.00, 0.96, 0.41) }

    --- The Druid class's default color
    __Static__() property "DRUID"           { default = Color(1.00, 0.49, 0.04) }

    --- The Shaman class's default color
    __Static__() property "SHAMAN"          { default = Color(0.00, 0.44, 0.87) }

    --- The Warrior class's default color
    __Static__() property "WARRIOR"         { default = Color(0.78, 0.61, 0.43) }

    --- The Deathknight class's default color
    __Static__() property "DEATHKNIGHT"     { default = Color(0.77, 0.12, 0.23) }

    --- The Monk class's default color
    __Static__() property "MONK"            { default = Color(0.00, 1.00, 0.59) }

    --- The Demonhunter class's default color
    __Static__() property "DEMONHUNTER"     { default = Color(0.64, 0.19, 0.79) }

    ------------------ Powers -------------------
    --- The mana's default color
    __Static__() property "MANA"            { default = Color(0.00, 0.00, 1.00) }

    --- The rage's default color
    __Static__() property "RAGE"            { default = Color(1.00, 0.00, 0.00) }

    --- The focus's default color
    __Static__() property "FOCUS"           { default = Color(1.00, 0.50, 0.25) }

    --- The energy's default color
    __Static__() property "ENERGY"          { default = Color(1.00, 1.00, 0.00) }

    --- The combo_points's default color
    __Static__() property "COMBO_POINTS"    { default = Color(1.00, 0.96, 0.41) }

    --- The runes's default color
    __Static__() property "RUNES"           { default = Color(0.50, 0.50, 0.50) }

    --- The runic_power's default color
    __Static__() property "RUNIC_POWER"     { default = Color(0.00, 0.82, 1.00) }

    --- The soul_shards's default color
    __Static__() property "SOUL_SHARDS"     { default = Color(0.50, 0.32, 0.55) }

    --- The lunar_power's default color
    __Static__() property "LUNAR_POWER"     { default = Color(0.30, 0.52, 0.90) }

    --- The holy_power's default color
    __Static__() property "HOLY_POWER"      { default = Color(0.95, 0.90, 0.60) }

    --- The maelstrom's default color
    __Static__() property "MAELSTROM"       { default = Color(0.00, 0.50, 1.00) }

    --- The insanity's default color
    __Static__() property "INSANITY"        { default = Color(0.40, 0.00, 0.80) }

    --- The chi's default color
    __Static__() property "CHI"             { default = Color(0.71, 1.00, 0.92) }

    --- The arcane_charges's default color
    __Static__() property "ARCANE_CHARGES"  { default = Color(0.10, 0.10, 0.98) }

    --- The fury's default color
    __Static__() property "FURY"            { default = Color(0.79, 0.26, 0.99) }

    --- The pain's default color
    __Static__() property "PAIN"            { default = Color(1.00, 0.61, 0.00) }

    --- The stagger's default color
    __Static__() property "STAGGER"         { default = Color(0.52, 1.00, 0.52) }

    --- The stagger's warnning color
    __Static__() property "STAGGER_WARN"    { default = Color(1.00, 0.98, 0.72) }

    --- The stagger's dangerous color
    __Static__() property "STAGGER_DYING"   { default = Color(1.00, 0.42, 0.42) }

    ------------------ Vehicle ------------------
    --- The ammoslot's default color
    __Static__() property "AMMOSLOT"        { default = Color(0.80, 0.60, 0.00) }

    --- The fuel's default color
    __Static__() property "FUEL"            { default = Color(0.00, 0.55, 0.50) }

    --------------- Item quality ----------------
    --- The common quality's default color
    __Static__() property "COMMON"          { default = Color(0.65882, 0.65882, 0.65882) }

    --- The uncommon quality's default color
    __Static__() property "UNCOMMON"        { default = Color(0.08235, 0.70196, 0.0) }

    --- The rare quality's default color
    __Static__() property "RARE"            { default = Color(0.0, 0.56863, 0.94902) }

    --- The epic quality's default color
    __Static__() property "EPIC"            { default = Color(0.78431, 0.27059, 0.98039) }

    --- The legendary quality's default color
    __Static__() property "LEGENDARY"       { default = Color(1.0, 0.50196, 0.0) }

    --- The artifact quality's default color
    __Static__() property "ARTIFACT"        { default = Color(0.90196, 0.8, 0.50196) }

    --- The heirloom quality's default color
    __Static__() property "HEIRLOOM"        { default = Color(0.0, 0.8, 1) }

    --- The wow_token quality's default color
    __Static__() property "WOWTOKEN"        { default = Color(0.00, 0.80, 1.00) }

    --------------- Common Color ----------------
    --- The magic debuff's default color
    __Static__() property "MAGIC"           { default = Color(0.20, 0.60, 1.00) }

    --- The curse debuff's default color
    __Static__() property "CURSE"           { default = Color(0.60, 0.00, 1.00) }

    --- The disease debuff's default color
    __Static__() property "DISEASE"         { default = Color(0.60, 0.40, 0.00) }

    --- The poison debuff's default color
    __Static__() property "POISON"          { default = Color(0.00, 0.60, 0.00) }

    --------------- Common Color ----------------
    --- The normal font color
    __Static__() property "NORMAL"          { set = false, default = Color(1.0, 0.82, 0.0) }

    --- The transparent color
    __Static__() property "TRANSPARENT"     { set = false, default = Color(0.00, 0.00, 0.00, 0.00) }

    --- The high light font color
    __Static__() property "HIGHLIGHT"       { set = false, default = Color(1.0, 1.0, 1.0) }

    --- The passive spell color
    __Static__() property "PASSIVESPELL"    { set = false, default = Color(0.77, 0.64, 0.0) }

    --- The battle net font color
    __Static__() property "BATTLENET"       { set = false, default = Color(0.510, 0.773, 1.0) }

    --- The transmogrify font color
    __Static__() property "TRANSMOGRIFY"    { set = false, default = Color(1, 0.5, 1) }

    --- The disabled font color
    __Static__() property "DISABLED"        { set = false, default = Color(0.498, 0.498, 0.498) }

    --- The red color
    __Static__() property "RED"             { set = false, default = Color(1.00, 0.10, 0.10) }

    --- The dim red color
    __Static__() property "DIMRED"          { set = false, default = Color(0.8, 0.1, 0.1) }

    --- The green color
    __Static__() property "GREEN"           { set = false, default = Color(0.10, 1.00, 0.10) }

    --- The gray color
    __Static__() property "GRAY"            { set = false, default = Color(0.50, 0.50, 0.50) }

    --- The yellow color
    __Static__() property "YELLOW"          { set = false, default = Color(1.00, 1.00, 0.00) }

    --- The blue color
    __Static__() property "BLUE"            { set = false, default = Color(0, 0.749, 0.953) }

    --- The light yellow color
    __Static__() property "LIGHTYELLOW"     { set = false, default = Color(1.00, 1.00, 0.60) }

    --- The orange color
    __Static__() property "ORANGE"          { set = false, default = Color(1.00, 0.50, 0.25) }

    --- The light blue color
    __Static__() property "LIGHTBLUE"       { set = false, default = Color(0.53, 0.67, 1.0) }

    --- The white color
    __Static__() property "WHITE"           { set = false, default = Color(1.00, 1.00, 1.00) }

    --- The black color
    __Static__() property "BLACK"           { set = false, default = Color(0.00, 0.00, 0.00) }

    --- the aliceblue color
    __Static__() property "ALICEBLUE"       { set = false, default = Color("|cfff0f8ff") }

    --- the antiquewhite color
    __Static__() property "ANTIQUEWHITE"    { set = false, default = Color("|cfffaebd7") }

    --- the aqua color
    __Static__() property "AQUA"            { set = false, default = Color("|cff00ffff") }

    --- the aquamarine color
    __Static__() property "AQUAMARINE"      { set = false, default = Color("|cff7fffd4") }

    --- the azure color
    __Static__() property "AZURE"           { set = false, default = Color("|cfff0ffff") }

    --- the beige color
    __Static__() property "BEIGE"           { set = false, default = Color("|cfff5f5dc") }

    --- the bisque color
    __Static__() property "BISQUE"          { set = false, default = Color("|cffffe4c4") }

    --- the blanchedalmond color
    __Static__() property "BLANCHEDALMOND"  { set = false, default = Color("|cffffebcd") }

    --- the blueviolet color
    __Static__() property "BLUEVIOLET"      { set = false, default = Color("|cff8a2be2") }

    --- the brown color
    __Static__() property "BROWN"           { set = false, default = Color("|cffa52a2a") }

    --- the burlywood color
    __Static__() property "BURLYWOOD"       { set = false, default = Color("|cffdeb887") }

    --- the cadetblue color
    __Static__() property "CADETBLUE"       { set = false, default = Color("|cff5f9ea0") }

    --- the chartreuse color
    __Static__() property "CHARTREUSE"      { set = false, default = Color("|cff7fff00") }

    --- the chocolate color
    __Static__() property "CHOCOLATE"       { set = false, default = Color("|cffd2691e") }

    --- the coral color
    __Static__() property "CORAL"           { set = false, default = Color("|cffff7f50") }

    --- the cornflowerblue color
    __Static__() property "CORNFLOWERBLUE"  { set = false, default = Color("|cff6495ed") }

    --- the cornsilk color
    __Static__() property "CORNSILK"        { set = false, default = Color("|cfffff8dc") }

    --- the crimson color
    __Static__() property "CRIMSON"         { set = false, default = Color("|cffdc143c") }

    --- the cyan color
    __Static__() property "CYAN"            { set = false, default = Color("|cff00ffff") }

    --- the darkblue color
    __Static__() property "DARKBLUE"        { set = false, default = Color("|cff00008b") }

    --- the darkcyan color
    __Static__() property "DARKCYAN"        { set = false, default = Color("|cff008b8b") }

    --- the darkgoldenrod color
    __Static__() property "DARKGOLDENROD"   { set = false, default = Color("|cffb8860b") }

    --- the darkgray color
    __Static__() property "DARKGRAY"        { set = false, default = Color("|cffa9a9a9") }

    --- the darkgreen color
    __Static__() property "DARKGREEN"       { set = false, default = Color("|cff006400") }

    --- the darkkhaki color
    __Static__() property "DARKKHAKI"       { set = false, default = Color("|cffbdb76b") }

    --- the darkmagenta color
    __Static__() property "DARKMAGENTA"     { set = false, default = Color("|cff8b008b") }

    --- the darkolivegreen color
    __Static__() property "DARKOLIVEGREEN"  { set = false, default = Color("|cff556b2f") }

    --- the darkorange color
    __Static__() property "DARKORANGE"      { set = false, default = Color("|cffff8c00") }

    --- the darkorchid color
    __Static__() property "DARKORCHID"      { set = false, default = Color("|cff9932cc") }

    --- the darkred color
    __Static__() property "DARKRED"         { set = false, default = Color("|cff8b0000") }

    --- the darksalmon color
    __Static__() property "DARKSALMON"      { set = false, default = Color("|cffe9967a") }

    --- the darkseagreen color
    __Static__() property "DARKSEAGREEN"    { set = false, default = Color("|cff8fbc8f") }

    --- the darkslateblue color
    __Static__() property "DARKSLATEBLUE"   { set = false, default = Color("|cff483d8b") }

    --- the darkslategray color
    __Static__() property "DARKSLATEGRAY"   { set = false, default = Color("|cff2f4f4f") }

    --- the darkturquoise color
    __Static__() property "DARKTURQUOISE"   { set = false, default = Color("|cff00ced1") }

    --- the darkviolet color
    __Static__() property "DARKVIOLET"      { set = false, default = Color("|cff9400d3") }

    --- the deeppink color
    __Static__() property "DEEPPINK"        { set = false, default = Color("|cffff1493") }

    --- the deepskyblue color
    __Static__() property "DEEPSKYBLUE"     { set = false, default = Color("|cff00bfff") }

    --- the dimgray color
    __Static__() property "DIMGRAY"         { set = false, default = Color("|cff696969") }

    --- the dodgerblue color
    __Static__() property "DODGERBLUE"      { set = false, default = Color("|cff1e90ff") }

    --- the firebrick color
    __Static__() property "FIREBRICK"       { set = false, default = Color("|cffb22222") }

    --- the floralwhite color
    __Static__() property "FLORALWHITE"     { set = false, default = Color("|cfffffaf0") }

    --- the forestgreen color
    __Static__() property "FORESTGREEN"     { set = false, default = Color("|cff228b22") }

    --- the fuchsia color
    __Static__() property "FUCHSIA"         { set = false, default = Color("|cffff00ff") }

    --- the gainsboro color
    __Static__() property "GAINSBORO"       { set = false, default = Color("|cffdcdcdc") }

    --- the ghostwhite color
    __Static__() property "GHOSTWHITE"      { set = false, default = Color("|cfff8f8ff") }

    --- the gold color
    __Static__() property "GOLD"            { set = false, default = Color("|cffffd700") }

    --- the goldenrod color
    __Static__() property "GOLDENROD"       { set = false, default = Color("|cffdaa520") }

    --- the greenyellow color
    __Static__() property "GREENYELLOW"     { set = false, default = Color("|cffadff2f") }

    --- the honeydew color
    __Static__() property "HONEYDEW"        { set = false, default = Color("|cfff0fff0") }

    --- the hotpink color
    __Static__() property "HOTPINK"         { set = false, default = Color("|cffff69b4") }

    --- the indianred color
    __Static__() property "INDIANRED"       { set = false, default = Color("|cffcd5c5c") }

    --- the indigo color
    __Static__() property "INDIGO"          { set = false, default = Color("|cff4b0082") }

    --- the ivory color
    __Static__() property "IVORY"           { set = false, default = Color("|cfffffff0") }

    --- the khaki color
    __Static__() property "KHAKI"           { set = false, default = Color("|cfff0e68c") }

    --- the lavender color
    __Static__() property "LAVENDER"        { set = false, default = Color("|cffe6e6fa") }

    --- the lavenderblush color
    __Static__() property "LAVENDERBLUSH"   { set = false, default = Color("|cfffff0f5") }

    --- the lawngreen color
    __Static__() property "LAWNGREEN"       { set = false, default = Color("|cff7cfc00") }

    --- the lemonchiffon color
    __Static__() property "LEMONCHIFFON"    { set = false, default = Color("|cfffffacd") }

    --- the lightcoral color
    __Static__() property "LIGHTCORAL"      { set = false, default = Color("|cfff08080") }

    --- the lightcyan color
    __Static__() property "LIGHTCYAN"       { set = false, default = Color("|cffe0ffff") }

    --- the lightgoldenrodyellow color
    __Static__() property "LIGHTGOLDENRODYELLOW" { set = false, default = Color("|cfffafad2") }

    --- the lightgray color
    __Static__() property "LIGHTGRAY"       { set = false, default = Color("|cffd3d3d3") }

    --- the lightgreen color
    __Static__() property "LIGHTGREEN"      { set = false, default = Color("|cff90ee90") }

    --- the lightpink color
    __Static__() property "LIGHTPINK"       { set = false, default = Color("|cffffb6c1") }

    --- the lightsalmon color
    __Static__() property "LIGHTSALMON"     { set = false, default = Color("|cffffa07a") }

    --- the lightseagreen color
    __Static__() property "LIGHTSEAGREEN"   { set = false, default = Color("|cff20b2aa") }

    --- the lightskyblue color
    __Static__() property "LIGHTSKYBLUE"    { set = false, default = Color("|cff87cefa") }

    --- the lightslategray color
    __Static__() property "LIGHTSLATEGRAY"  { set = false, default = Color("|cff778899") }

    --- the lightsteelblue color
    __Static__() property "LIGHTSTEELBLUE"  { set = false, default = Color("|cffb0c4de") }

    --- the lime color
    __Static__() property "LIME"            { set = false, default = Color("|cff00ff00") }

    --- the limegreen color
    __Static__() property "LIMEGREEN"       { set = false, default = Color("|cff32cd32") }

    --- the linen color
    __Static__() property "LINEN"           { set = false, default = Color("|cfffaf0e6") }

    --- the magenta color
    __Static__() property "MAGENTA"         { set = false, default = Color("|cffff00ff") }

    --- the maroon color
    __Static__() property "MAROON"          { set = false, default = Color("|cff800000") }

    --- the mediumaquamarine color
    __Static__() property "MEDIUMAQUAMARINE" { set = false, default = Color("|cff66cdaa") }

    --- the mediumblue color
    __Static__() property "MEDIUMBLUE"      { set = false, default = Color("|cff0000cd") }

    --- the mediumorchid color
    __Static__() property "MEDIUMORCHID"    { set = false, default = Color("|cffba55d3") }

    --- the mediumpurple color
    __Static__() property "MEDIUMPURPLE"    { set = false, default = Color("|cff9370db") }

    --- the mediumseagreen color
    __Static__() property "MEDIUMSEAGREEN"  { set = false, default = Color("|cff3cb371") }

    --- the mediumslateblue color
    __Static__() property "MEDIUMSLATEBLUE" { set = false, default = Color("|cff7b68ee") }

    --- the mediumspringgreen color
    __Static__() property "MEDIUMSPRINGGREEN" { set = false, default = Color("|cff00fa9a") }

    --- the mediumturquoise color
    __Static__() property "MEDIUMTURQUOISE" { set = false, default = Color("|cff48d1cc") }

    --- the mediumvioletred color
    __Static__() property "MEDIUMVIOLETRED" { set = false, default = Color("|cffc71585") }

    --- the midnightblue color
    __Static__() property "MIDNIGHTBLUE"    { set = false, default = Color("|cff191970") }

    --- the mintcream color
    __Static__() property "MINTCREAM"       { set = false, default = Color("|cfff5fffa") }

    --- the mistyrose color
    __Static__() property "MISTYROSE"       { set = false, default = Color("|cffffe4e1") }

    --- the moccasin color
    __Static__() property "MOCCASIN"        { set = false, default = Color("|cffffe4b5") }

    --- the navajowhite color
    __Static__() property "NAVAJOWHITE"     { set = false, default = Color("|cffffdead") }

    --- the navy color
    __Static__() property "NAVY"            { set = false, default = Color("|cff000080") }

    --- the oldlace color
    __Static__() property "OLDLACE"         { set = false, default = Color("|cfffdf5e6") }

    --- the olive color
    __Static__() property "OLIVE"           { set = false, default = Color("|cff808000") }

    --- the olivedrab color
    __Static__() property "OLIVEDRAB"       { set = false, default = Color("|cff6b8e23") }

    --- the orangered color
    __Static__() property "ORANGERED"       { set = false, default = Color("|cffff4500") }

    --- the orchid color
    __Static__() property "ORCHID"          { set = false, default = Color("|cffda70d6") }

    --- the palegoldenrod color
    __Static__() property "PALEGOLDENROD"   { set = false, default = Color("|cffeee8aa") }

    --- the palegreen color
    __Static__() property "PALEGREEN"       { set = false, default = Color("|cff98fb98") }

    --- the paleturquoise color
    __Static__() property "PALETURQUOISE"   { set = false, default = Color("|cffafeeee") }

    --- the palevioletred color
    __Static__() property "PALEVIOLETRED"   { set = false, default = Color("|cffdb7093") }

    --- the papayawhip color
    __Static__() property "PAPAYAWHIP"      { set = false, default = Color("|cffffefd5") }

    --- the peachpuff color
    __Static__() property "PEACHPUFF"       { set = false, default = Color("|cffffdab9") }

    --- the peru color
    __Static__() property "PERU"            { set = false, default = Color("|cffcd853f") }

    --- the pink color
    __Static__() property "PINK"            { set = false, default = Color("|cffffc0cb") }

    --- the plum color
    __Static__() property "PLUM"            { set = false, default = Color("|cffdda0dd") }

    --- the powderblue color
    __Static__() property "POWDERBLUE"      { set = false, default = Color("|cffb0e0e6") }

    --- the purple color
    __Static__() property "PURPLE"          { set = false, default = Color("|cff800080") }

    --- the rosybrown color
    __Static__() property "ROSYBROWN"       { set = false, default = Color("|cffbc8f8f") }

    --- the royalblue color
    __Static__() property "ROYALBLUE"       { set = false, default = Color("|cff4169e1") }

    --- the saddlebrown color
    __Static__() property "SADDLEBROWN"     { set = false, default = Color("|cff8b4513") }

    --- the salmon color
    __Static__() property "SALMON"          { set = false, default = Color("|cfffa8072") }

    --- the sandybrown color
    __Static__() property "SANDYBROWN"      { set = false, default = Color("|cfff4a460") }

    --- the seagreen color
    __Static__() property "SEAGREEN"        { set = false, default = Color("|cff2e8b57") }

    --- the seashell color
    __Static__() property "SEASHELL"        { set = false, default = Color("|cfffff5ee") }

    --- the sienna color
    __Static__() property "SIENNA"          { set = false, default = Color("|cffa0522d") }

    --- the silver color
    __Static__() property "SILVER"          { set = false, default = Color("|cffc0c0c0") }

    --- the skyblue color
    __Static__() property "SKYBLUE"         { set = false, default = Color("|cff87ceeb") }

    --- the slateblue color
    __Static__() property "SLATEBLUE"       { set = false, default = Color("|cff6a5acd") }

    --- the slategray color
    __Static__() property "SLATEGRAY"       { set = false, default = Color("|cff708090") }

    --- the snow color
    __Static__() property "SNOW"            { set = false, default = Color("|cfffffafa") }

    --- the springgreen color
    __Static__() property "SPRINGGREEN"     { set = false, default = Color("|cff00ff7f") }

    --- the steelblue color
    __Static__() property "STEELBLUE"       { set = false, default = Color("|cff4682b4") }

    --- the tan color
    __Static__() property "TAN"             { set = false, default = Color("|cffd2b48c") }

    --- the teal color
    __Static__() property "TEAL"            { set = false, default = Color("|cff008080") }

    --- the thistle color
    __Static__() property "THISTLE"         { set = false, default = Color("|cffd8bfd8") }

    --- the tomato color
    __Static__() property "TOMATO"          { set = false, default = Color("|cffff6347") }

    --- the turquoise color
    __Static__() property "TURQUOISE"       { set = false, default = Color("|cff40e0d0") }

    --- the violet color
    __Static__() property "VIOLET"          { set = false, default = Color("|cffee82ee") }

    --- the wheat color
    __Static__() property "WHEAT"           { set = false, default = Color("|cfff5deb3") }

    --- the whitesmoke color
    __Static__() property "WHITESMOKE"      { set = false, default = Color("|cfff5f5f5") }

    --- the yellowgreen color
    __Static__() property "YELLOWGREEN"     { set = false, default = Color("|cff9acd32") }
end)

Color.PLAYER = Color[(select(2, UnitClass("player")))]


----------------------------------------------
--          Share Scan GameTooltip          --
----------------------------------------------
do
    ScanGameTooltip             = CreateFrame("GameTooltip", "Scorpio_Scan_GameTooltip", UIParent, "GameTooltipTemplate")
    SCAN_TIP_PREFIX_LEFT        = "Scorpio_Scan_GameTooltipTextLeft"
    SCAN_TIP_PREFIX_RIGHT       = "Scorpio_Scan_GameTooltipTextRight"

    local autoTipHiding         = false

    local function hideScanGameTooltip()
        autoTipHiding           = false
        ScanGameTooltip:Hide()
    end

    local function getTipLines(_, i)
        i                       = (i or 0) + 1
        if i > ScanGameTooltip:NumLines() then return ScanGameTooltip:Hide() end

        local left              = _G[SCAN_TIP_PREFIX_LEFT .. i]
        local right             = _G[SCAN_TIP_PREFIX_RIGHT .. i]

        if type(left) == "table" and left.GetText then
            left                = left:GetText()
        end

        if type(right) == "table" and right.GetText then
            right               = right:GetText()
        end

        return i, left, right
    end

    __Static__()
    function Scorpio.GetGameTooltipLines(type, ...)
        local method            = ScanGameTooltip["Set" .. type]
        if method then
            ScanGameTooltip:Hide()

            ScanGameTooltip:SetOwner(WorldFrame, 'ANCHOR_NONE')
            method(ScanGameTooltip, ...)

            -- Normally the iterator won't go down to the end, we need Hide the tip automatically
            if not autoTipHiding then
                autoTipHiding   = true
                Next(hideScanGameTooltip)
            end

            return getTipLines, ScanGameTooltip, 0
        else
            return Toolset.fakefunc, ScanGameTooltip, 0
        end
    end
end