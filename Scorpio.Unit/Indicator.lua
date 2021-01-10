--========================================================--
--                Scorpio UnitFrame Indicator             --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/11/25                              --
--========================================================--

--========================================================--
Scorpio         "Scorpio.Secure.UnitFrame.Indicator" "1.0.0"
--========================================================--

namespace "Scorpio.Secure.UnitFrame"

------------------------------------------------------------
--                       Indicator                        --
------------------------------------------------------------
__ChildProperty__(UnitFrame,         "NameLabel")
__ChildProperty__(InSecureUnitFrame, "NameLabel")
__Sealed__() class "NameLabel"       { FontString }

__ChildProperty__(UnitFrame,         "LevelLabel")
__ChildProperty__(InSecureUnitFrame, "LevelLabel")
__Sealed__() class "LevelLabel"      { FontString }

__ChildProperty__(UnitFrame,         "HealthLabel")
__ChildProperty__(InSecureUnitFrame, "HealthLabel")
__Sealed__() class "HealthLabel"     { FontString }

__ChildProperty__(UnitFrame,         "PowerLabel")
__ChildProperty__(InSecureUnitFrame, "PowerLabel")
__Sealed__() class "PowerLabel"      { FontString }

__ChildProperty__(UnitFrame,         "HealthBar")
__ChildProperty__(InSecureUnitFrame, "HealthBar")
__Sealed__() class "HealthBar"       { StatusBar }

__ChildProperty__(UnitFrame,         "PowerBar")
__ChildProperty__(InSecureUnitFrame, "PowerBar")
__Sealed__() class "PowerBar"        { StatusBar }

__ChildProperty__(UnitFrame,         "ClassPowerBar")
__ChildProperty__(InSecureUnitFrame, "ClassPowerBar")
__Sealed__() class "ClassPowerBar"   { StatusBar }

__ChildProperty__(UnitFrame,         "HiddenManaBar")
__ChildProperty__(InSecureUnitFrame, "HiddenManaBar")
__Sealed__() class "HiddenManaBar"   { StatusBar }

__ChildProperty__(UnitFrame,         "DisconnectIcon")
__ChildProperty__(InSecureUnitFrame, "DisconnectIcon")
__Sealed__() class "DisconnectIcon"  { Texture }

__ChildProperty__(UnitFrame,         "CombatIcon")
__ChildProperty__(InSecureUnitFrame, "CombatIcon")
__Sealed__() class "CombatIcon"      { Texture }

__ChildProperty__(UnitFrame,         "ResurrectIcon")
__ChildProperty__(InSecureUnitFrame, "ResurrectIcon")
__Sealed__() class "ResurrectIcon"   { Texture }

__ChildProperty__(UnitFrame,         "RaidTargetIcon")
__ChildProperty__(InSecureUnitFrame, "RaidTargetIcon")
__Sealed__() class "RaidTargetIcon"  { Texture }

__ChildProperty__(UnitFrame,         "CastBar")
__ChildProperty__(InSecureUnitFrame, "CastBar")
__Sealed__() class "CastBar"         { CooldownStatusBar }

__ChildProperty__(UnitFrame,        "AuraPanel")
__ChildProperty__(InSecureUnitFrame,"AuraPanel")
__Sealed__() class "AuraPanel"      (function(_ENV)
    inherit "ElementPanel"

    import "System.Reactive"

    local tconcat               = table.concat
    local strtrim               = Toolset.trim
    local validate              = Enum.ValidateValue
    local shareCooldown         = { start = 0, duration = 0 }

    local function refreshAura(self, filter, eleIdx, auraIdx, name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, castByPlayer, ...)
        if not name or eleIdx > self.MaxCount then return eleIdx end

        if not self.CustomFilter or self.CustomFilter(name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, castByPlayer, ...) then
            self.Elements[eleIdx]:Show()

            shareCooldown.start             = expires - duration
            shareCooldown.duration          = duration

            self.AuraName[eleIdx]           = name
            self.AuraIcon[eleIdx]           = icon
            self.AuraCount[eleIdx]          = count
            self.AuraDebuff[eleIdx]         = dtype
            self.AuraCooldown[eleIdx]       = shareCooldown
            self.AuraStealable[eleIdx]      = isStealable
            self.AuraSpellID[eleIdx]        = spellID
            self.AuraBossDebuff[eleIdx]     = isBossDebuff
            self.AuraCastByPlayer[eleIdx]   = castByPlayer

            eleIdx              = eleIdx + 1
        end

        auraIdx                 = auraIdx + 1
        return refreshAura(self, filter, eleIdx, auraIdx, UnitAura(unit, auraIdx, filter))
    end

    local function OnElementCreated(self, ele)
        return ele:InstantApplyStyle()
    end

    --- The aura filters
    __Sealed__() enum "AuraFilter" { "HELPFUL", "HARMFUL", "PLAYER", "RAID", "CANCELABLE", "NOT_CANCELABLE", "INCLUDE_NAME_PLATE_ONLY" }

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    property "Filter"           {
        type                    = struct{ AuraFilter } + String,
        field                   = "__AuraPanel_Filter",
        set                     = function(self, filter)
            -- No more check, just keep it simple
            if type(filter) == "table" then
                filter          = tconcat(filter, "|")
            else
                filter          = filter and strtrim(filter) or ""
            end

            if filter == "" then
                for i = self.Count, 1, -1 do
                    self.Elements[i]:Hide()
                end
            end
        end,
    }

    property "CustomFilter"     { type = Function }

    property "Refresh"          {
        set                     = function(self, unit)
            local filter        = self.Filter
            if not filter or filter == "" then return end

            for i = self.Count, refreshAura(self, filter, 1, 1, UnitAura(unit, 1, filter)), -1 do
                self.Elements[i]:Hide()
            end
        end
    }

    ------------------------------------------------------
    -- Observable Property
    ------------------------------------------------------
    __Indexer__() __Observable__()
    property "AuraName"         { set = Toolset.fakefunc }

    __Indexer__() __Observable__()
    property "AuraIcon"         { set = Toolset.fakefunc }

    __Indexer__() __Observable__()
    property "AuraCount"        { set = Toolset.fakefunc }

    __Indexer__() __Observable__()
    property "AuraDebuff"       { set = Toolset.fakefunc }

    __Indexer__() __Observable__()
    property "AuraCooldown"     { set = Toolset.fakefunc }

    __Indexer__() __Observable__()
    property "AuraStealable"    { set = Toolset.fakefunc }

    __Indexer__() __Observable__()
    property "AuraSpellID"      { set = Toolset.fakefunc }

    __Indexer__() __Observable__()
    property "AuraBossDebuff"   { set = Toolset.fakefunc }

    __Indexer__() __Observable__()
    property "AuraCastByPlayer" { set = Toolset.fakefunc }


    ------------------------------------------------------
    -- Constructor
    ------------------------------------------------------
    function __ctor(self)
        self.OnElementCreated   = self.OnElementCreated + OnElementCreated
    end
end)

__ChildProperty__(UnitFrame,         "BuffPanel")
__ChildProperty__(InSecureUnitFrame, "BuffPanel")
__Sealed__() class "BuffPanel"       { AuraPanel }

__ChildProperty__(UnitFrame,         "DebuffPanel")
__ChildProperty__(InSecureUnitFrame, "DebuffPanel")
__Sealed__() class "DebuffPanel"     { AuraPanel }

__ChildProperty__(UnitFrame,         "ClassBuffPanel")
__ChildProperty__(InSecureUnitFrame, "ClassBuffPanel")
__Sealed__() class "ClassBuffPanel"  { AuraPanel }

------------------------------------------------------------
--                     Default Style                      --
------------------------------------------------------------
local shareRect                 = RectType()

Style.UpdateSkin("Default",     {
    [NameLabel]                 = {
        drawLayer               = "BORDER",
        fontObject              = GameFontNormalSmall,
        text                    = Wow.UnitName(true),
        textColor               = Wow.UnitColor(),
    },
    [LevelLabel]                = {
        drawLayer               = "BORDER",
        fontObject              = GameFontNormalSmall,
        text                    = Wow.UnitLevel(),
        vertexColor             = Wow.UnitLevelColor(),
    },
    [HealthLabel]               = {
        drawLayer               = "BORDER",
        fontObject              = GameFontNormalSmall,
        text                    = Wow.UnitHealth(),
    },
    [PowerLabel]                = {
        drawLayer               = "BORDER",
        fontObject              = GameFontNormalSmall,
        text                    = Wow.UnitPower(),
    },
    [HealthBar]                 = {
        frameStrata             = "LOW",
        enableMouse             = false,
        statusBarTexture        = {
            file                = [[Interface\TargetingFrame\UI-StatusBar]],
        },

        value                   = Wow.UnitHealth(),
        minMaxValues            = Wow.UnitHealthMax(),
        statusBarColor          = Color.GREEN,
    },
    [PowerBar]                  = {
        frameStrata             = "LOW",
        enableMouse             = false,
        statusBarTexture        = {
            file                = [[Interface\TargetingFrame\UI-StatusBar]],
        },

        value                   = Wow.UnitPower(),
        minMaxValues            = Wow.UnitPowerMax(),
        statusBarColor          = Wow.UnitPowerColor(),
    },
    [HiddenManaBar]             = {
        frameStrata             = "LOW",
        enableMouse             = false,
        statusBarTexture        = {
            file                = [[Interface\TargetingFrame\UI-StatusBar]],
        },

        value                   = Wow.UnitMana(),
        minMaxValues            = Wow.UnitManaMax(),
        visible                 = Wow.UnitManaVisible(),
        statusBarColor          = Color.MANA,
    },
    [ClassPowerBar]             = {
        frameStrata             = "LOW",
        enableMouse             = false,
        statusBarTexture        = {
            file                = [[Interface\TargetingFrame\UI-StatusBar]],
        },

        value                   = Wow.ClassPower(),
        minMaxValues            = Wow.ClassPowerMax(),
        statusBarColor          = Wow.ClassPowerColor(),
        visible                 = Wow.ClassPowerUsable(),
    },
    [DisconnectIcon]            = {
        file                    = [[Interface\CharacterFrame\Disconnect-Icon]],
        size                    = Size(16, 16),
        visible                 = Wow.UnitIsDisconnected(),
    },
    [CombatIcon]                = {
        file                    = [[Interface\CharacterFrame\UI-StateIcon]],
        texCoords               = RectType(.5, 1, 0, .49),
        size                    = Size(24, 24),
        visible                 = Wow.PlayerInCombat(),
    },
    [ResurrectIcon]             = {
        file                    = [[Interface\RaidFrame\Raid-Icon-Rez]],
        size                    = Size(16, 16),
        visible                 = Wow.UnitIsResurrect(),
    },
    [RaidTargetIcon]            = {
        file                    = [[Interface\TargetingFrame\UI-RaidTargetingIcons]],
        size                    = Size(16, 16),
        texCoords               = Wow.UnitRaidTargetIndex():Map(function(index)
            if index then
                index           = index - 1
                local left, right, top, bottom
                local cIncr     = RAID_TARGET_ICON_DIMENSION / RAID_TARGET_TEXTURE_DIMENSION
                left            = mod(index , RAID_TARGET_TEXTURE_COLUMNS) * cIncr
                right           = left + cIncr
                top             = floor(index / RAID_TARGET_TEXTURE_ROWS) * cIncr
                bottom          = top + cIncr
                shareRect.left  = left
                shareRect.right = right
                shareRect.top   = top
                shareRect.bottom= bottom
            end
            return shareRect
        end),
        visible                 = Wow.UnitRaidTargetIndex():Map(function(val) return val and true or false end),
    },
    [CastBar]                   = {
        cooldown                = Wow.UnitCastCooldown(),
        reverse                 = Wow.UnitCastChannel(),
        showSafeZone            = Wow.UnitIsPlayer(),
    },
    [AuraPanel]                 = {
        refresh                 = Wow.UnitAura(),
    },
    [BuffPanel]                 = {
        filter                  = "HELPFUL",
    },
    [DebuffPanel]               = {
        filter                  = "HARMFUL",
    },
    [ClassBuffPanel]            = {
        filter                  = "PLAYER",
    },
})