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
META_WEAKKEY   = { __mode = "k" }
META_WEAKVAL   = { __mode = "v" }
META_WEAKALL   = { __mode = "kv"}

------------------- Logger ----------------T--
Log            = System.Logger("Scorpio")

Log.TimeFormat = "%X"
Trace          = Log:SetPrefix(1, "|cffa9a9a9[Scorpio]|r", true)
Debug          = Log:SetPrefix(2, "|cff808080[Scorpio]|r", true)
Info           = Log:SetPrefix(3, "|cffffffff[Scorpio]|r", true)
Warn           = Log:SetPrefix(4, "|cffffff00[Scorpio]|r", true)
Error          = Log:SetPrefix(5, "|cffff0000[Scorpio]|r", true)
Fatal          = Log:SetPrefix(6, "|cff8b0000[Scorpio]|r", true)

Log.LogLevel   = 1

Log:AddHandler(print)

------------------- String -------------------
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
abs            = math.abs

------------------- Date ---------------------
date           = date or (os and os.date)

------------------- Coroutine ----------------
create         = coroutine.create
resume         = coroutine.resume
running        = coroutine.running
status         = coroutine.status
wrap           = coroutine.wrap
yield          = coroutine.yield

------------------ Common --------------------
loadstring     = loadstring or load


------------------------------------------------------------
--                         Enums                          --
------------------------------------------------------------
__Sealed__()
enum "Classes" {
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
enum "ClassPower" {
    MANA            = 0,
    RAGE            = 1,
    FOCUS           = 2,
    ENERGY          = 3,
    COMBO_POINTS    = 4,
    RUNES           = 5,
    RUNIC_POWER     = 6,
    SOUL_SHARDS     = 7,
    LUNAR_POWER     = 8,
    HOLY_POWER      = 9,
    ALTERNATE_POWER = 10,
    MAELSTROM       = 11,
    CHI             = 12,
    INSANITY        = 13,
    -- OBSOLETE     = 14,
    -- OBSOLETE2    = 15,
    ARCANE_CHARGES  = 16,
    FURY            = 17,
    PAIN            = 18,
}

------------------------------------------------------------
--                       Data Types                       --
------------------------------------------------------------
__Sealed__() __Base__(String)
struct "LocaleString" { }

__Sealed__() __Base__(Number)
struct "ColorFloat" {
    function (val) assert(val >= 0 and val <= 1, "%s must between 0.0 and 1.0.") end
}

__Doc__[[
    The color data, 'Color(r, g, b[, a])' - used to create a color data,
    use obj.r, obj.g, obj.b, obj.a to access the color's part,
    also 'obj .. "text"' can be used to concat values.

    Some special color can be accessed like 'Color.Red', 'Color.Player', 'Color.Mage'
]]
class "Color" (function(_ENV)

    ----------------------------------------------
    ----------------- Sub-Types ------------------
    ----------------------------------------------
    __Sealed__()
    struct "ColorType" {
        { Name = "r",   Type = ColorFloat, Require = true },
        { Name = "g",   Type = ColorFloat, Require = true },
        { Name = "b",   Type = ColorFloat, Require = true },
        { Name = "a",   Type = ColorFloat, Default = 1 },
    }

    ----------------------------------------------
    ---------------- Constructor -----------------
    ----------------------------------------------
    __Arguments__{ ColorType }
    function Color(self, color)
        self.r = color.r
        self.g = color.g
        self.b = color.b
        self.a = color.a
    end

    __Arguments__{
        { Type = ColorFloat, Name = "r"},
        { Type = ColorFloat, Name = "g"},
        { Type = ColorFloat, Name = "b"},
        { Type = ColorFloat, Name = "a", Nilable = true, Default = 1}
    }
    function Color(self, r, g, b, a)
        self.r = r
        self.g = g
        self.b = b
        self.a = a
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
end)

------------------------------------------------------------
--                    Special Colors                      --
------------------------------------------------------------
__Sealed__()
class "Color" (function(_ENV)
    ----------------------------------------------
    -------------- Static Property ---------------
    ----------------------------------------------
    __Doc__[[The close tag to close color text]]
    __Static__() property "CLOSE"           { Set = false, Default = "|r" }

    ------------------ Classes ------------------
    __Doc__[[The Hunter class's default color]]
    __Static__() property "HUNTER"          { Set = false, Default = Color(0.67, 0.83, 0.45) }

    __Doc__[[The Warlock class's default color]]
    __Static__() property "WARLOCK"         { Set = false, Default = Color(0.53, 0.53, 0.93) }

    __Doc__[[The Priest class's default color]]
    __Static__() property "PRIEST"          { Set = false, Default = Color(1.00, 1.00, 1.00) }

    __Doc__[[The Paladin class's default color]]
    __Static__() property "PALADIN"         { Set = false, Default = Color(0.96, 0.55, 0.73) }

    __Doc__[[The Mage class's default color]]
    __Static__() property "MAGE"            { Set = false, Default = Color(0.25, 0.78, 0.92) }

    __Doc__[[The Rogue class's default color]]
    __Static__() property "ROGUE"           { Set = false, Default = Color(1.00, 0.96, 0.41) }

    __Doc__[[The Druid class's default color]]
    __Static__() property "DRUID"           { Set = false, Default = Color(1.00, 0.49, 0.04) }

    __Doc__[[The Shaman class's default color]]
    __Static__() property "SHAMAN"          { Set = false, Default = Color(0.00, 0.44, 0.87) }

    __Doc__[[The Warrior class's default color]]
    __Static__() property "WARRIOR"         { Set = false, Default = Color(0.78, 0.61, 0.43) }

    __Doc__[[The Deathknight class's default color]]
    __Static__() property "DEATHKNIGHT"     { Set = false, Default = Color(0.77, 0.12, 0.23) }

    __Doc__[[The Monk class's default color]]
    __Static__() property "MONK"            { Set = false, Default = Color(0.00, 1.00, 0.59) }

    __Doc__[[The Demonhunter class's default color]]
    __Static__() property "DEMONHUNTER"     { Set = false, Default = Color(0.64, 0.19, 0.79) }

    ------------------ Powers -------------------
    __Doc__[[The mana's default color]]
    __Static__() property "MANA"            { Set = false, Default = Color(0.00, 0.00, 1.00) }

    __Doc__[[The rage's default color]]
    __Static__() property "RAGE"            { Set = false, Default = Color(1.00, 0.00, 0.00) }

    __Doc__[[The focus's default color]]
    __Static__() property "FOCUS"           { Set = false, Default = Color(1.00, 0.50, 0.25) }

    __Doc__[[The energy's default color]]
    __Static__() property "ENERGY"          { Set = false, Default = Color(1.00, 1.00, 0.00) }

    __Doc__[[The combo_points's default color]]
    __Static__() property "COMBO_POINTS"    { Set = false, Default = Color(1.00, 0.96, 0.41) }

    __Doc__[[The runes's default color]]
    __Static__() property "RUNES"           { Set = false, Default = Color(0.50, 0.50, 0.50) }

    __Doc__[[The runic_power's default color]]
    __Static__() property "RUNIC_POWER"     { Set = false, Default = Color(0.00, 0.82, 1.00) }

    __Doc__[[The soul_shards's default color]]
    __Static__() property "SOUL_SHARDS"     { Set = false, Default = Color(0.50, 0.32, 0.55) }

    __Doc__[[The lunar_power's default color]]
    __Static__() property "LUNAR_POWER"     { Set = false, Default = Color(0.30, 0.52, 0.90) }

    __Doc__[[The holy_power's default color]]
    __Static__() property "HOLY_POWER"      { Set = false, Default = Color(0.95, 0.90, 0.60) }

    __Doc__[[The maelstrom's default color]]
    __Static__() property "MAELSTROM"       { Set = false, Default = Color(0.00, 0.50, 1.00) }

    __Doc__[[The insanity's default color]]
    __Static__() property "INSANITY"        { Set = false, Default = Color(0.40, 0.00, 0.80) }

    __Doc__[[The chi's default color]]
    __Static__() property "CHI"             { Set = false, Default = Color(0.71, 1.00, 0.92) }

    __Doc__[[The arcane_charges's default color]]
    __Static__() property "ARCANE_CHARGES"  { Set = false, Default = Color(0.10, 0.10, 0.98) }

    __Doc__[[The fury's default color]]
    __Static__() property "FURY"            { Set = false, Default = Color(0.79, 0.26, 0.99) }

    __Doc__[[The pain's default color]]
    __Static__() property "PAIN"            { Set = false, Default = Color(1.00, 0.61, 0.00) }

    __Doc__[[The stagger's default color]]
    __Static__() property "STAGGER"         { Set = false, Default = Color(0.52, 1.00, 0.52) }

    __Doc__[[The stagger's warnning color]]
    __Static__() property "STAGGER_WARN"    { Set = false, Default = Color(1.00, 0.98, 0.72) }

    __Doc__[[The stagger's dangerous color]]
    __Static__() property "STAGGER_DYING"   { Set = false, Default = Color(1.00, 0.42, 0.42) }

    ------------------ Vehicle ------------------
    __Doc__[[The ammoslot's default color]]
    __Static__() property "AMMOSLOT"        { Set = false, Default = Color(0.80, 0.60, 0.00) }

    __Doc__[[The fuel's default color]]
    __Static__() property "FUEL"            { Set = false, Default = Color(0.00, 0.55, 0.50) }

    --------------- Item quality ----------------
    __Doc__[[The common quality's default color]]
    __Static__() property "COMMON"          { Set = false, Default = Color(0.66, 0.66, 0.66) }

    __Doc__[[The uncommon quality's default color]]
    __Static__() property "UNCOMMON"        { Set = false, Default = Color(0.08, 0.70, 0.00) }

    __Doc__[[The rare quality's default color]]
    __Static__() property "RARE"            { Set = false, Default = Color(0.00, 0.57, 0.95) }

    __Doc__[[The epic quality's default color]]
    __Static__() property "EPIC"            { Set = false, Default = Color(0.78, 0.27, 0.98) }

    __Doc__[[The legendary quality's default color]]
    __Static__() property "LEGENDARY"       { Set = false, Default = Color(1.00, 0.50, 0.00) }

    __Doc__[[The artifact quality's default color]]
    __Static__() property "ARTIFACT"        { Set = false, Default = Color(0.90, 0.80, 0.50) }

    __Doc__[[The heirloom quality's default color]]
    __Static__() property "HEIRLOOM"        { Set = false, Default = Color(0.00, 0.80, 1.00) }

    __Doc__[[The wow_token quality's default color]]
    __Static__() property "WOWTOKEN"        { Set = false, Default = Color(0.00, 0.80, 1.00) }

    --------------- Common Color ----------------
    __Doc__[[The magic debuff's default color]]
    __Static__() property "MAGIC"           { Set = false, Default = Color(0.20, 0.60, 1.00) }

    __Doc__[[The curse debuff's default color]]
    __Static__() property "CURSE"           { Set = false, Default = Color(0.60, 0.00, 1.00) }

    __Doc__[[The disease debuff's default color]]
    __Static__() property "DISEASE"         { Set = false, Default = Color(0.60, 0.40, 0.00) }

    __Doc__[[The poison debuff's default color]]
    __Static__() property "POISON"          { Set = false, Default = Color(0.00, 0.60, 0.00) }


    --------------- Common Color ----------------
    __Doc__[[The red color]]
    __Static__() property "RED"             { Set = false, Default = Color(1.00, 0.10, 0.10) }

    __Doc__[[The green color]]
    __Static__() property "GREEN"           { Set = false, Default = Color(0.10, 1.00, 0.10) }

    __Doc__[[The gray color]]
    __Static__() property "GRAY"            { Set = false, Default = Color(0.50, 0.50, 0.50) }

    __Doc__[[The yellow color]]
    __Static__() property "YELLOW"          { Set = false, Default = Color(1.00, 1.00, 0.00) }

    __Doc__[[The light yellow color]]
    __Static__() property "LIGHTYELLOW"     { Set = false, Default = Color(1.00, 1.00, 0.60) }

    __Doc__[[The orange color]]
    __Static__() property "ORANGE"          { Set = false, Default = Color(1.00, 0.50, 0.25) }
end)

-- Add PLAYER Class Color
__Doc__[[The player's default color]]
Color.PLAYER = { Set = false, Default = Color[(select(2, UnitClass("player")))], Static = true }
