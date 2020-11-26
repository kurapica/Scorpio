--========================================================--
--                Scorpio UnitFrame Indicator             --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/11/25                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Secure.Indicator"         "1.0.0"
--========================================================--

namespace "Scorpio.Secure.UnitFrame"

------------------------------------------------------------
--                       Indicator                        --
------------------------------------------------------------
__Sealed__() __ChildProperty__(UnitFrame, "NameLabel")
class "NameLabel"   { FontString }

__Sealed__() __ChildProperty__(UnitFrame, "LevelLabel")
class "LevelLabel"  { FontString }

__Sealed__() __ChildProperty__(UnitFrame, "HealthBar")
class "HealthBar"   { StatusBar }

__Sealed__() __ChildProperty__(UnitFrame, "PowerBar")
class "PowerBar"    { StatusBar }

------------------------------------------------------------
--                          APIS                          --
------------------------------------------------------------
interface "Scorpio.Wow" (function(_ENV)
    import "System.Reactive"

    export {
        -- Use Alias to avoid the name conclict
        GetUnitLevel            = UnitLevel,
        GetUnitHealth           = UnitHealth,
        GetUnitHealthMax        = UnitHealthMax,
    }

    __Static__() __AutoCache__()
    function UnitName(withServer)
        return FromUnitEvent("UNIT_NAME_UPDATE"):Map(withServer and function(unit) return GetUnitName(unit, true) end or GetUnitName)
    end

    __Static__() __AutoCache__()
    function UnitNameColor(useSelectionColor)
        if useSelectionColor then
            local shareColor            = { r = 1, g = 1, b = 1 }

            return FromUnitEvent("UNIT_NAME_UPDATE"):Map(function(unit)
                if not UnitIsPlayer(unit) then
                    if useSelectionColor then
                        if UnitIsTapDenied(unit) then return Color.RUNES end

                        local r, g, b   = UnitSelectionColor(unit, true)
                        shareColor.r    = r or 1
                        shareColor.g    = g or 1
                        shareColor.b    = b or 1
                        return shareColor
                    end
                else
                    return Color[select(2, UnitClass(unit))]
                end
                return Color.PALADIN
            end)
        else
            return FromUnitEvent("UNIT_NAME_UPDATE"):Map(function(unit)
                local _, cls               = UnitClass(unit)
                return cls and Color[cls] or Color.PALADIN
            end)
        end
    end

    __Static__()
    function UnitLevel(format)
        format                  = format or "%s"
        local unknownFormat     = format:gsub("%%%w+", "%%s")
        return FromUnitEvent(FromEvent("PLAYER_LEVEL_UP"):Map(function(level) return "player", level end))
            :Map(function(unit, level)
                level           = level or GetUnitLevel(unit)
                if level and level > 0 then
                    if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
                        level   = UnitBattlePetLevel(unit)
                    end
                    return strformat(format, level)
                else
                    return strformat(unknownFormat, "???")
                end
            end)
    end

    __Static__() __Arguments__{ ColorType/nil }
    function UnitLevelColor(default)
        return FromUnitEvent(FromEvent("PLAYER_LEVEL_UP"):Map(function(level) return "player", level end))
            :Map(function(unit, level)
                if not level and UnitCanAttack("player", unit) then
                    return GetQuestDifficultyColor(GetUnitLevel(unit) or 99)
                end
                return default or Color.NORMAL
            end)
    end

    __Static__() __AutoCache__()
    function UnitHealth()
        return FromUnitEvents("UNIT_HEALTH", "UNIT_MAXHEALTH"):Map(GetUnitHealth)
    end

    __Static__() __AutoCache__()
    function UnitHealthMax()
        local minMax            = { min = 0 }
        return FromUnitEvent("UNIT_MAXHEALTH"):Map(function(unit)
                minMax.max      = GetUnitHealthMax(unit) or 100
                return minMax
            end)
    end
end)

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
    [HealthBar]                 = {
        frameStrata             = "LOW",
        enableMouse             = false,
        statusBarTexture        = {
            file                = [[Interface\TargetingFrame\UI-StatusBar]],
        },
        middleBGTexture         = {
            drawLayer           = "BACKGROUND",
            setAllPoints        = true,
        },

        value                   = Wow.UnitHealth(),
        minMaxValues            = Wow.UnitHealthMax(),
        statusBarColor          = Color.GREEN,
    },
})