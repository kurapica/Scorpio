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
__Sealed__() __ChildProperty__(UnitFrame, "NameLabel")
class "NameLabel"       { FontString }

__Sealed__() __ChildProperty__(UnitFrame, "LevelLabel")
class "LevelLabel"      { FontString }

__Sealed__() __ChildProperty__(UnitFrame, "HealthLabel")
class "HealthLabel"     { FontString }

__Sealed__() __ChildProperty__(UnitFrame, "PowerLabel")
class "PowerLabel"      { FontString }

__Sealed__() __ChildProperty__(UnitFrame, "HealthBar")
class "HealthBar"       { StatusBar }

__Sealed__() __ChildProperty__(UnitFrame, "PowerBar")
class "PowerBar"        { StatusBar }

__Sealed__() __ChildProperty__(UnitFrame, "ClassPowerBar")
class "ClassPowerBar"   { StatusBar }

__Sealed__() __ChildProperty__(UnitFrame, "HiddenManaBar")
class "HiddenManaBar"   { StatusBar }

__Sealed__() __ChildProperty__(UnitFrame, "BuffPanel")
class "BuffPanel"       { ElementPanel }

__Sealed__() __ChildProperty__(UnitFrame, "DebuffPanel")
class "DebuffPanel"     { ElementPanel }

__Sealed__() __ChildProperty__(UnitFrame, "ClassBuffPanel")
class "ClassBuffPanel"  { ElementPanel }

__Sealed__() __ChildProperty__(UnitFrame, "DisconnectIcon")
class "DisconnectIcon"  { Texture }

__Sealed__() __ChildProperty__(UnitFrame, "CombatIcon")
class "CombatIcon"      { Texture }

__Sealed__() __ChildProperty__(UnitFrame, "ResurrectIcon")
class "ResurrectIcon"   { Texture }

__Sealed__() __ChildProperty__(UnitFrame, "CastBar")
class "CastBar"         { CooldownStatusBar }

------------------------------------------------------------
--                     Default Style                      --
------------------------------------------------------------
Style.UpdateSkin("Default",     {
    [NameLabel]                 = {
        drawLayer               = "BORDER",
        fontObject              = GameFontNormalSmall,
        text                    = Wow.UnitName(true),
        textColor               = Wow.UnitNameColor(true),
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
        cooldown                = Wow.
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
})