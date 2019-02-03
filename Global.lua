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

-------------------- META --------------------
META_WEAKKEY                    = { __mode = "k" }
META_WEAKVAL                    = { __mode = "v" }
META_WEAKALL                    = { __mode = "kv"}

------------------- Logger ----------------T--
Log                             = System.Logger("Scorpio")

Log.TimeFormat                  = "%X"
Trace                           = Log:SetPrefix(1, "|cffa9a9a9[Scorpio]|r", true)
Debug                           = Log:SetPrefix(2, "|cff808080[Scorpio]|r", true)
Info                            = Log:SetPrefix(3, "|cffffffff[Scorpio]|r", true)
Warn                            = Log:SetPrefix(4, "|cffffff00[Scorpio]|r", true)
Error                           = Log:SetPrefix(5, "|cffff0000[Scorpio]|r", true)
Fatal                           = Log:SetPrefix(6, "|cff8b0000[Scorpio]|r", true)

Log.LogLevel                    = 1

Log:AddHandler(print)

------------------- String -------------------
strformat                       = string.format
strfind                         = string.find
strsub                          = string.sub
strbyte                         = string.byte
strchar                         = string.char
strrep                          = string.rep
strsub                          = string.gsub
strupper                        = string.upper
strlower                        = string.lower
strtrim                         = strtrim or function(s) return (s:gsub("^%s*(.-)%s*$", "%1")) or "" end
strmatch                        = string.match

------------------- Error --------------------
geterrorhandler                 = geterrorhandler or function() return print end
errorhandler                    = errorhandler or function(err) return geterrorhandler()(err) end

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
getRealMethodCache              = function (name) return setmetatable({}, { __index = function(self, cls) local real = Class.GetNormalMethod(cls, name) rawset(self, cls, real) return real end }) end

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
    __init = function(val) return clamp(val, 0, 1) end
}

__Sealed__()
struct "HueValue" {
    __base = Number,
    __init = function(val) return clamp(val, 0, 360) end
}

__Sealed__()
struct "ColorType" {
    { name = "r",   type = ColorFloat, require = true },
    { name = "g",   type = ColorFloat, require = true },
    { name = "b",   type = ColorFloat, require = true },
    { name = "a",   type = ColorFloat, default = 1 },
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
    export { maxv = math.max, minv = math.min, floor = math.floor }

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
    __Arguments__{ ColorType }
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
        return { r = r, g = g, b = b, a = a}, true
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
__Sealed__()
class "Color" (function(_ENV)
    ----------------------------------------------
    --             Static Property              --
    ----------------------------------------------
    --- The close tag to close color text
    __Static__() property "CLOSE"           { set = false, default = "|r" }

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
    __Static__() property "COMMON"          { default = Color(0.66, 0.66, 0.66) }

    --- The uncommon quality's default color
    __Static__() property "UNCOMMON"        { default = Color(0.08, 0.70, 0.00) }

    --- The rare quality's default color
    __Static__() property "RARE"            { default = Color(0.00, 0.57, 0.95) }

    --- The epic quality's default color
    __Static__() property "EPIC"            { default = Color(0.78, 0.27, 0.98) }

    --- The legendary quality's default color
    __Static__() property "LEGENDARY"       { default = Color(1.00, 0.50, 0.00) }

    --- The artifact quality's default color
    __Static__() property "ARTIFACT"        { default = Color(0.90, 0.80, 0.50) }

    --- The heirloom quality's default color
    __Static__() property "HEIRLOOM"        { default = Color(0.00, 0.80, 1.00) }

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
    --- The red color
    __Static__() property "RED"             { set = false, default = Color(1.00, 0.10, 0.10) }

    --- The green color
    __Static__() property "GREEN"           { set = false, default = Color(0.10, 1.00, 0.10) }

    --- The gray color
    __Static__() property "GRAY"            { set = false, default = Color(0.50, 0.50, 0.50) }

    --- The yellow color
    __Static__() property "YELLOW"          { set = false, default = Color(1.00, 1.00, 0.00) }

    --- The light yellow color
    __Static__() property "LIGHTYELLOW"     { set = false, default = Color(1.00, 1.00, 0.60) }

    --- The orange color
    __Static__() property "ORANGE"          { set = false, default = Color(1.00, 0.50, 0.25) }

    --- The player's default color
    __Static__() property "PLAYER"          { type = Color }
end)

Color.PLAYER = Color[(select(2, UnitClass("player")))]
