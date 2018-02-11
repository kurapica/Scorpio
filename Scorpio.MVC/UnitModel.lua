--========================================================--
--                Scorpio MVC FrameWork                   --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2017/02/08                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.MVC.UnitModel"            "1.0.0"
--========================================================--

namespace "Scorpio.MVC"


------------------------------------------------------------
--                      Constants                         --
------------------------------------------------------------
do
    ------------------- Player Class ------------------
    PLAYER_CLASS                = select(2, UnitClass("player"))

    ----------------- Class Power Map -----------------
    CLASS_POWER_MAP             = Dictionary(Iterator(function() for n, v in Reflector.GetEnums(ClassPower) do coroutine.yield(v, n) end end))

    ----------------- SPEC Class Power ----------------
    SPEC_ALL                    = 0

    SPEC_SHAMAN_ELEMENTAL       = 1
    SPEC_SHAMAN_ENHANCEMENT     = 2

    SPEC_CLASS_POWERMAP = ({
        ROGUE = {
            [SPEC_ALL] = {
                PowerType = "COMBO_POINTS",
            },
        },
        PALADIN = {
            [_G.SPEC_PALADIN_RETRIBUTION] = {
                ShowLevel = _G.PALADINPOWERBAR_SHOW_LEVEL,
                PowerType = "HOLY_POWER",
            },
        },
        MAGE = {
            [_G.SPEC_MAGE_ARCANE] = {
                PowerType = "ARCANE_CHARGES",
            },
        },
        DRUID = {
            [SPEC_ALL] = {
                CheckShapeshift = true,
                [_G.CAT_FORM] = "COMBO_POINTS",
            },
        },
        PRIEST = {
            [_G.SPEC_PRIEST_SHADOW] = {
                PowerType = "MANA",
            },
        },
        MONK = {
            [_G.SPEC_MONK_WINDWALKER] = {
                PowerType = "CHI",
            },
        },
        WARLOCK = {
            [SPEC_ALL] = {
                PowerType = "SOUL_SHARDS",
            },
        },
        SHAMAN = {
            [SPEC_SHAMAN_ELEMENTAL] = {
                PowerType = "MANA",
            },
            [SPEC_SHAMAN_ENHANCEMENT] = {
                PowerType = "MANA",
            },
        },
    })[PLAYER_CLASS] or false

    SPEC_CLASS_POWER            = false
    SPEC_CLASS_POWERID          = 0

    ---------------------- Totem ----------------------
    FIRE_TOTEM_SLOT             = 1
    EARTH_TOTEM_SLOT            = 2
    WATER_TOTEM_SLOT            = 3
    AIR_TOTEM_SLOT              = 4

    STANDARD_TOTEM_PRIORITIES   = { 1, 2, 3, 4 }

    SHAMAN_TOTEM_PRIORITIES     = { EARTH_TOTEM_SLOT, FIRE_TOTEM_SLOT, WATER_TOTEM_SLOT, AIR_TOTEM_SLOT }

    ---------------------- Other ----------------------
    SPELL_POWER_MANA            = _G.SPELL_POWER_MANA
end

------------------------------------------------------------
--                  Module Event Handler                  --
------------------------------------------------------------
__Thread__()
function OnEnable(self)

end

__Thread__()
function OnSpecChanged(self, spec)
    -- Update the class power
    SPEC_CLASS_POWER = false

    if SPEC_CLASS_POWERMAP then
        local info = SPEC_CLASS_POWERMAP[spec] or SPEC_CLASS_POWERMAP[SPEC_ALL]

        if info then
            if info.CheckShapeshift then
                OnSpecChanged = nil -- No need to check the spec

                while true do
                    SPEC_CLASS_POWER = info[GetShapeshiftFormID()] or false
                    if SPEC_CLASS_POWER then SPEC_CLASS_POWERID = ClassPower[SPEC_CLASS_POWER] end
                    UNIT_POWER_FREQUENT("player", SPEC_CLASS_POWER)

                    Event("UPDATE_SHAPESHIFT_FORM")
                end
            elseif info.ShowLevel and info.ShowLevel > UnitLevel("player") then
                UNIT_POWER_FREQUENT("player", SPEC_CLASS_POWER)

                while true do
                    local evt, lvl = Wait("PLAYER_LEVEL_UP", "PLAYER_SPECIALIZATION_CHANGED")

                    if evt == "PLAYER_SPECIALIZATION_CHANGED" then return end

                    if info.ShowLevel <= lvl then
                        SPEC_CLASS_POWER = info.PowerType
                        if SPEC_CLASS_POWER then SPEC_CLASS_POWERID = ClassPower[SPEC_CLASS_POWER] end
                        break
                    end
                end
            else
                SPEC_CLASS_POWER = info.PowerType
                if SPEC_CLASS_POWER then SPEC_CLASS_POWERID = ClassPower[SPEC_CLASS_POWER] end
            end
        end
    end

    return UNIT_POWER_FREQUENT("player", SPEC_CLASS_POWER)
end

------------------------------------------------------------
--                      MVC Helper                        --
------------------------------------------------------------
FireObjectEvent             = Reflector.FireObjectEvent

UnitHealthModelMap          = Dictionary()
UnitHealthFrequentModelMap  = Dictionary()
UnitPowerModelMap           = Dictionary()
UnitPowerFrequentModelMap   = Dictionary()
UnitManaModelMap            = Dictionary()
UnitManaFrequentModelMap    = Dictionary()
UnitClassPowerModelMap      = Dictionary()

__SystemEvent__()
function UNIT_HEALTH(unit)
    local obj = UnitHealthModelMap[unit]
    if obj then
        obj[1] = UnitHealth(unit)
        obj[2] = UnitHealthMax(unit)

        return obj:RefreshViews()
    end
end

__SystemEvent__()
function UNIT_HEALTH_FREQUENT(unit)
    local obj = UnitHealthFrequentModelMap[unit]
    if obj then
        obj[1] = UnitHealth(unit)
        obj[2] = UnitHealthMax(unit)

        return obj:RefreshViews()
    end
end

__SystemEvent__()
function UNIT_MAXHEALTH(unit)
    UNIT_HEALTH(unit)
    UNIT_HEALTH_FREQUENT(unit)
end

__SystemEvent__()
function UNIT_POWER(unit, ptype)
    -- Mana
    if not ptype or ptype == "MANA" then
        local obj = UnitManaModelMap[unit]
        if obj then
            obj[1] = UnitPower(unit, SPELL_POWER_MANA)
            obj[2] = UnitPowerMax(unit, SPELL_POWER_MANA)

            obj:RefreshViews()
        end
    end

    -- Power
    local obj = UnitPowerModelMap[unit]
    if obj then
        local powerType = UnitPowerType(unit)
        local powerName = CLASS_POWER_MAP[powerType]
        if not ptype or powerName == ptype then
            obj[1] = UnitPower(unit, powerType)
            obj[2] = UnitPowerMax(unit, powerType)
            obj[3] = powerName

            obj:RefreshViews()
        end
    end
end

__SystemEvent__()
function UNIT_POWER_FREQUENT(unit, ptype)
    local obj

    -- Mana
    if ptype == nil or ptype == "MANA" then
        obj = UnitManaFrequentModelMap[unit]
        if obj then
            obj[1] = UnitPower(unit, SPELL_POWER_MANA)
            obj[2] = UnitPowerMax(unit, SPELL_POWER_MANA)

            obj:RefreshViews()
        end
    end

    -- Power
    obj = UnitPowerFrequentModelMap[unit]
    if obj then
        local powerType = UnitPowerType(unit)
        local powerName = CLASS_POWER_MAP[powerType]
        if not ptype or powerName == ptype then
            obj[1] = UnitPower(unit, powerType)
            obj[2] = UnitPowerMax(unit, powerType)
            obj[3] = powerName

            obj:RefreshViews()
        end
    end

    -- Class Power
    if unit == "player" and (not ptype or ptype == SPEC_CLASS_POWER) then
        obj = UnitClassPowerModelMap[unit]
        if obj then
            if SPEC_CLASS_POWER then
                obj[1] = UnitPower(unit, SPEC_CLASS_POWERID)
                obj[2] = UnitPowerMax(unit, SPEC_CLASS_POWERID)
                obj[3] = powerName
            else
                obj[1] = 0
                obj[2] = 0
                obj[3] = nil
            end

            obj:RefreshViews()
        end
    end
end

__SystemEvent__ "UNIT_MAXPOWER" "UNIT_POWER_BAR_SHOW" "UNIT_POWER_BAR_HIDE" "UNIT_DISPLAYPOWER"
function UNIT_POWER_OTHER(unit)
    UNIT_POWER(unit)
    UNIT_POWER_FREQUENT(unit)
end


------------------------------------------------------------
--                        Unit MVC                        --
------------------------------------------------------------
__Doc__[[The unit health model]]
class "UnitHealthModel" { Model,
    -- Constructor
    function(self, unit)
        UnitHealthModelMap[unit] = self
        self[1] = 0     -- Value
        self[2] = 100   -- Max
    end,

    -- Meta-method
    __exist = function(unit) return UnitHealthModelMap[unit] end,
}

__Doc__[[The unit frequent health model]]
class "UnitHealthFrequentModel" { Model,
    -- Constructor
    function(self, unit)
        UnitHealthFrequentModelMap[unit] = self
        self[1] = 0     -- Value
        self[2] = 100   -- Max
    end,

    -- Meta-method
    __exist = function(unit) return UnitHealthFrequentModelMap[unit] end,
}

__Doc__[[The unit power model]]
class "UnitPowerModel" { Model,
    -- Constructor
    function(self, unit)
        UnitPowerModelMap[unit] = self
        self[1] = 0     -- Value
        self[2] = 100   -- Max
        self[3] = "MANA"-- Type
    end,

    -- Meta-method
    __exist = function(unit) return UnitPowerModelMap[unit] end,
}

__Doc__[[The unit frequent power model]]
class "UnitPowerFrequentModel" { Model,
    -- Constructor
    function(self, unit)
        UnitPowerFrequentModelMap[unit] = self
        self[1] = 0     -- Value
        self[2] = 100   -- Max
        self[3] = "MANA"-- Type
    end,

    -- Meta-method
    __exist = function(unit) return UnitPowerFrequentModelMap[unit] end,
}

__Doc__[[The unit mana model]]
class "UnitManaModel" { Model,
    -- Constructor
    function(self, unit)
        UnitManaModelMap[unit] = self
        self[1] = 0     -- Value
        self[2] = 100   -- Max
    end,

    -- Meta-method
    __exist = function(unit) return UnitManaModelMap[unit] end,
}

__Doc__[[The unit frequent mana model]]
class "UnitManaFrequentModel" { Model,
    -- Constructor
    function(self, unit)
        UnitManaFrequentModelMap[unit] = self
        self[1] = 0     -- Value
        self[2] = 100   -- Max
    end,

    -- Meta-method
    __exist = function(unit) return UnitManaFrequentModelMap[unit] end,
}

__Doc__[[The unit class power model]]
class "UnitClassPowerModel" { Model,
    -- Constructor
    function(self, unit)
        UnitClassPowerModelMap[unit] = self
        self[1] = 0     -- Value
        self[2] = 100   -- Max
        self[3] = nil   -- Type
    end,

    -- Meta-method
    __exist = function(unit) return UnitClassPowerModelMap[unit] end,
}