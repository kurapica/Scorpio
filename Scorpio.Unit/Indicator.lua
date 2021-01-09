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

__ChildProperty__(UnitFrame,         "BuffPanel")
__ChildProperty__(InSecureUnitFrame, "BuffPanel")
__Sealed__() class "BuffPanel"       { ElementPanel }

__ChildProperty__(UnitFrame,         "DebuffPanel")
__ChildProperty__(InSecureUnitFrame, "DebuffPanel")
__Sealed__() class "DebuffPanel"     { ElementPanel }

__ChildProperty__(UnitFrame,         "ClassBuffPanel")
__ChildProperty__(InSecureUnitFrame, "ClassBuffPanel")
__Sealed__() class "ClassBuffPanel"  { ElementPanel }

__ChildProperty__(UnitFrame,         "DisconnectIcon")
__ChildProperty__(InSecureUnitFrame, "DisconnectIcon")
__Sealed__() class "DisconnectIcon"  { Texture }

__ChildProperty__(UnitFrame,         "CombatIcon")
__ChildProperty__(InSecureUnitFrame, "CombatIcon")
__Sealed__() class "CombatIcon"      { Texture }

__ChildProperty__(UnitFrame,         "ResurrectIcon")
__ChildProperty__(InSecureUnitFrame, "ResurrectIcon")
__Sealed__() class "ResurrectIcon"   { Texture }

__ChildProperty__(UnitFrame,         "CastBar")
__ChildProperty__(InSecureUnitFrame, "CastBar")
__Sealed__() class "CastBar"         { CooldownStatusBar }


------------------------------------------------------------
--                     Default Style                      --
------------------------------------------------------------
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
        text                    = Wow.UnitLevel("Lv. %s"),
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
    [CastBar]                   = {
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
    [CastBar]                   = {
        cooldown                = Wow.UnitCastCooldown(),
        reverse                 = Wow.UnitCastChannel(),
        showSafeZone            = Wow.UnitIsPlayer(),
    },
})