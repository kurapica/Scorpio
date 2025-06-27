--========================================================--
--                Scorpio UnitFrame Indicator             --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/11/25                              --
-- Update Date :  2025/04/27                              --
--========================================================--

--========================================================--
Scorpio         "Scorpio.Secure.UnitFrame.Indicator" "1.0.0"
--========================================================--

namespace "Scorpio.Secure.UnitFrame"

------------------------------------------------------------
--                       Indicator                        --
------------------------------------------------------------
__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "NameLabel"       { FontString }

__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "LevelLabel"      { FontString }

__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "HealthLabel"     { FontString }

__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "PowerLabel"      { FontString }

__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "HealthBar"       { StatusBar }

__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "PowerBar"        { StatusBar }

__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "ClassPowerBar"   { StatusBar }

__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "HiddenManaBar"   { StatusBar }

__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "DisconnectIcon"  { Texture }

__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "CombatIcon"      { Texture }

__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "ResurrectIcon"   { Texture }

__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "RaidTargetIcon"  { Texture }

__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "ReadyCheckIcon"  { Texture }

__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "RaidRosterIcon"  { Texture }

__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "RoleIcon"        { Texture }

__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "LeaderIcon"      { Texture }

__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "CastBar"         { CooldownStatusBar }

__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "TotemPanel"     (function(_ENV)
    inherit "ElementPanel"

    local MAX_TOTEMS            = _G.MAX_TOTEMS
    local SLOT_MAP              = {}

    for slot, index in ipairs(select(2, UnitClass("player")) == "SHAMAN" and _G.SHAMAN_TOTEM_PRIORITIES or _G.STANDARD_TOTEM_PRIORITIES) do
        SLOT_MAP[index]         = slot
    end

    local shareCooldown         = { start = 0, duration = 0 }

    local function OnElementCreated(self, ele)
        return ele:InstantApplyStyle()
    end

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    property "Refresh"          {
        set                     = function(self, unit)
            local eleIdx        = 1
            for i = 1, MAX_TOTEMS do
                local haveTotem, name, startTime, duration, icon = GetTotemInfo(SLOT_MAP[i])
                if haveTotem then
                    local ele   = self.Elements[eleIdx]
                    if not ele then return end
                    ele:Show()
                    ele.Slot    = SLOT_MAP[i]

                    shareCooldown.start         = startTime
                    shareCooldown.duration      = duration

                    self.TotemName[eleIdx]      = name
                    self.TotemIcon[eleIdx]      = icon
                    self.TotemCooldown[eleIdx]  = shareCooldown

                    eleIdx      = eleIdx + 1
                end
            end

            self.Count          = eleIdx - 1
        end
    }

    ------------------------------------------------------
    -- Observable Property
    ------------------------------------------------------
    __Indexer__() __Observable__()
    property "TotemName"        { set = Toolset.fakefunc }

    __Indexer__() __Observable__()
    property "TotemIcon"        { set = Toolset.fakefunc }

    __Indexer__() __Observable__()
    property "TotemCooldown"    { set = Toolset.fakefunc }

    ------------------------------------------------------
    -- Constructor
    ------------------------------------------------------
    function __ctor(self)
        self.OnElementCreated   = self.OnElementCreated + OnElementCreated
    end
end)

__Sealed__() class "TotemPanelIcon"  (function(_ENV)
    inherit "Frame"

    local function OnEnter(self)
        if self.ShowTooltip then
            GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT')
            GameTooltip:SetTotem(self.Slot)
        end
    end

    local function OnLeave(self)
        GameTooltip:Hide()
    end

    property "Slot"             { type = Number }
    property "ShowTooltip"      { type = Boolean, default = true }

    function __ctor(self)
        self.OnEnter            = self.OnEnter + OnEnter
        self.OnLeave            = self.OnLeave + OnLeave
    end
end)

-- A health bar with prediction elements
__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "PredictionHealthBar" (function(_ENV)
    inherit "StatusBar"

    local  function updateFillBar(self, previousTexture, bar, amount, barOffsetXPercent)
        local tWidth, tHeight   = self:GetSize()
        local isVertical        = self:GetOrientation() == "VERTICAL"

        local total             = isVertical and tHeight or tWidth

        if ( total == 0 or amount == 0 ) then
            bar:Hide()
            if ( bar.overlay ) then
                bar.overlay:Hide()
            end
            return previousTexture
        end

        local barOffsetX        = 0
        if ( barOffsetXPercent ) then
            barOffsetX          = total * barOffsetXPercent
        end

        local _, totalMax       = self:GetMinMaxValues()
        local barSize           = (amount / totalMax) * total

        bar:ClearAllPoints()
        if isVertical then
            bar:SetPoint("BOTTOMLEFT", previousTexture, "TOPLEFT", 0, barOffsetX)
            bar:SetPoint("BOTTOMRIGHT", previousTexture, "TOPRIGHT", 0, barOffsetX)

            bar:SetHeight(barSize)
            bar:Show()
            if ( bar.overlay ) then
                bar.overlay:SetTexCoord(0, Clamp(barSize / bar.overlay.tileSize, 0, 1), 0, Clamp(tHeight / bar.overlay.tileSize, 0, 1))
                Style[bar.overlay].rotateDegree = 270
                bar.overlay:Show()
            end
        else
            bar:SetPoint("TOPLEFT", previousTexture, "TOPRIGHT", barOffsetX, 0)
            bar:SetPoint("BOTTOMLEFT", previousTexture, "BOTTOMRIGHT", barOffsetX, 0)

            bar:SetWidth(barSize)
            bar:Show()
            if ( bar.overlay ) then
                bar.overlay:SetTexCoord(0, Clamp(barSize / bar.overlay.tileSize, 0, 1), 0, Clamp(tHeight / bar.overlay.tileSize, 0, 1))
                Style[bar.overlay].rotateDegree = 0
                bar.overlay:Show()
            end
        end

        return bar
    end

    property "HealPrediction"   {
        set                     = function(self, unit)
            local maxHealth     = unit and UnitHealthMax(unit) or 0

            if maxHealth <= 0 then
                self.myHealPrediction:Hide()
                self.otherHealPrediction:Hide()
                self.totalAbsorb:Hide()
                self.totalAbsorbOverlay:Hide()
                self.myHealAbsorb:Hide()
                -- self.myHealAbsorbLeftShadow:Hide()
                self.overAbsorbGlow:Hide()
                self.overHealAbsorbGlow:Hide()
                return
            end

            local health        = unit and UnitHealth(unit)
            if health > maxHealth then maxHealth = health end -- Just avoid some bugs

            local myIncomingHeal            = UnitGetIncomingHeals(unit, "player") or 0
            local allIncomingHeal           = UnitGetIncomingHeals(unit) or 0
            local totalAbsorb               = UnitGetTotalAbsorbs(unit) or 0
            local totalHealAbsorb           = UnitGetTotalHealAbsorbs(unit) or 0
            local otherIncomingHeal         = 0
            local overHealAbsorb            = false
            local overAbsorb                = false

            if health < totalHealAbsorb then
                totalHealAbsorb             = health
                overHealAbsorb              = true
            end

            if health - totalHealAbsorb + allIncomingHeal > maxHealth * self.MaxHealOverflowRatio then
                allIncomingHeal             = maxHealth * self.MaxHealOverflowRatio - health + totalHealAbsorb
            end

            --Split up incoming heals.
            if allIncomingHeal >= myIncomingHeal then
                otherIncomingHeal           = allIncomingHeal - myIncomingHeal
            else
                myIncomingHeal              = allIncomingHeal
            end

            if health - totalHealAbsorb + allIncomingHeal + totalAbsorb >= maxHealth or health + totalAbsorb >= maxHealth then
                overAbsorb                  = totalAbsorb > 0

                if allIncomingHeal > totalHealAbsorb then
                    totalAbsorb             = max(0, maxHealth - (health - totalHealAbsorb + allIncomingHeal))
                else
                    totalAbsorb             = max(0, maxHealth - health)
                end
            end

            self.overHealAbsorbGlow:SetShown(overHealAbsorb)
            self.overAbsorbGlow:SetShown(overAbsorb)

            local healthTexture             = self:GetStatusBarTexture()
            local totalHealAbsorbPct        = totalHealAbsorb / maxHealth

            local healAbsorbTexture         = nil

            if totalHealAbsorb > allIncomingHeal then
                local shownHealAbsorb       = totalHealAbsorb - allIncomingHeal
                local shownHealAbsorbPercent= shownHealAbsorb / maxHealth
                healAbsorbTexture           = updateFillBar(self, healthTexture, self.myHealAbsorb, shownHealAbsorb, -shownHealAbsorbPercent)

                --If there are incoming heals the left shadow would be overlayed by the incoming heals
                --so it isn't shown.
                -- if ( allIncomingHeal > 0 ) then
                --     self.myHealAbsorbLeftShadow:Hide()
                -- else
                --     self.myHealAbsorbLeftShadow:ClearAllPoints()
                --     if self:GetOrientation() == "HORIZONTAL" then
                --         self.myHealAbsorbLeftShadow:SetPoint("TOPLEFT", healAbsorbTexture, "TOPLEFT", 0, 0)
                --         self.myHealAbsorbLeftShadow:SetPoint("BOTTOMLEFT", healAbsorbTexture, "BOTTOMLEFT", 0, 0)
                --     else
                --         self.myHealAbsorbLeftShadow:SetPoint("BOTTOMLEFT", healAbsorbTexture, "BOTTOMLEFT", 0, 0)
                --         self.myHealAbsorbLeftShadow:SetPoint("BOTTOMRIGHT", healAbsorbTexture, "BOTTOMRIGHT", 0, 0)
                --     end
                --     self.myHealAbsorbLeftShadow:Show()
                -- end

                -- The right shadow is only shown if there are absorbs on the health bar.
                -- if ( totalAbsorb > 0 ) then
                --     self.myHealAbsorbRightShadow:ClearAllPoints()
                --     if self:GetOrientation() == "HORIZONTAL" then
                --         self.myHealAbsorbRightShadow:SetPoint("TOPLEFT", healAbsorbTexture, "TOPRIGHT", -8, 0)
                --         self.myHealAbsorbRightShadow:SetPoint("BOTTOMLEFT", healAbsorbTexture, "BOTTOMRIGHT", -8, 0)
                --     else
                --         self.myHealAbsorbRightShadow:SetPoint("BOTTOMLEFT", healAbsorbTexture, "TOPLEFT", 0, -8)
                --         self.myHealAbsorbRightShadow:SetPoint("BOTTOMRIGHT", healAbsorbTexture, "TOPRIGHT", 0, -8)
                --     end
                --     self.myHealAbsorbRightShadow:Show()
                -- else
                --     self.myHealAbsorbRightShadow:Hide()
                -- end
            else
                self.myHealAbsorb:Hide()
                -- self.myHealAbsorbRightShadow:Hide()
                -- self.myHealAbsorbLeftShadow:Hide()
            end

            --Show myIncomingHeal on the health bar.
            local incomingHealsTexture = updateFillBar(self, healthTexture, self.myHealPrediction, myIncomingHeal, -totalHealAbsorbPct)
            --Append otherIncomingHeal on the health bar.
            incomingHealsTexture = updateFillBar(self, incomingHealsTexture, self.otherHealPrediction, otherIncomingHeal)

            --Appen absorbs to the correct section of the health bar.
            local appendTexture = nil
            if ( healAbsorbTexture ) then
                --If there is a healAbsorb part shown, append the absorb to the end of that.
                appendTexture = healAbsorbTexture
            else
                --Otherwise, append the absorb to the end of the the incomingHeals part
                appendTexture = incomingHealsTexture
            end
            updateFillBar(self, appendTexture, self.totalAbsorb, totalAbsorb)
        end
    }

    property "MaxHealOverflowRatio" { type = Number, default = 1.00 }

    __Observable__()
    property "Orientation"      { type = Orientation, set = StatusBar.SetOrientation, get = StatusBar.GetOrientation }

    function SetOrientation(self, orientation)
        super.SetOrientation(self, orientation)
        self.Orientation        = self:GetOrientation()
    end

    __Template__{
        MyHealPrediction        = Texture,
        OtherHealPrediction     = Texture,
        TotalAbsorb             = Texture,
        TotalAbsorbOverlay      = Texture,

        MyHealAbsorb            = Texture,
        -- MyHealAbsorbLeftShadow  = Texture,
        -- MyHealAbsorbRightShadow = Texture,

        OverAbsorbGlow          = Texture,
        OverHealAbsorbGlow      = Texture,
    }
    function __ctor(self)
        self.myHealPrediction   = self:GetChild("MyHealPrediction")
        self.otherHealPrediction= self:GetChild("OtherHealPrediction")
        self.totalAbsorb        = self:GetChild("TotalAbsorb")
        self.totalAbsorbOverlay = self:GetChild("TotalAbsorbOverlay")
        self.myHealAbsorb       = self:GetChild("MyHealAbsorb")
        -- self.myHealAbsorbLeftShadow = self:GetChild("MyHealAbsorbLeftShadow")
        -- self.myHealAbsorbRightShadow= self:GetChild("MyHealAbsorbRightShadow")
        self.overAbsorbGlow     = self:GetChild("OverAbsorbGlow")
        self.overHealAbsorbGlow = self:GetChild("OverHealAbsorbGlow")

        self.totalAbsorb.overlay= self.totalAbsorbOverlay
        self.totalAbsorbOverlay.tileSize = 32
    end
end)

------------------------------------------------------------
--                         Helper                         --
------------------------------------------------------------
GetTexCoordsForRoleSmallCircle  = _G.GetTexCoordsForRoleSmallCircle or function(role)
    if ( role == "TANK" ) then
        return 0, 19/64, 22/64, 41/64
    elseif ( role == "HEALER" ) then
        return 20/64, 39/64, 1/64, 20/64
    elseif ( role == "DAMAGER" ) then
        return 20/64, 39/64, 22/64, 41/64
    else
        error("Unknown role: "..tostring(role))
    end
end

shareRect                       = RectType()

shareMyHealPreGraH              = GradientType("VERTICAL", Color(8/255, 93/255, 72/255), Color(11/255, 136/255, 105/255))
shareOtherHealPreGraH           = GradientType("VERTICAL", Color(11/255, 53/255, 43/255), Color(21/255, 89/255, 72/255))

shareMyHealPreGraV              = GradientType("HORIZONTAL", Color(8/255, 93/255, 72/255), Color(11/255, 136/255, 105/255))
shareOtherHealPreGraV           = GradientType("HORIZONTAL", Color(11/255, 53/255, 43/255), Color(21/255, 89/255, 72/255))

shareOverAbsorbGlowH            = { Anchor("BOTTOMLEFT", -7, 0, nil, "BOTTOMRIGHT"), Anchor("TOPLEFT", -7, 0, nil, "TOPRIGHT") }
shareOverHealAbsorbGlowH        = { Anchor("BOTTOMRIGHT", 7, 0, nil, "BOTTOMLEFT"), Anchor("TOPRIGHT", 7, 0, nil, "TOPLEFT") }

shareOverAbsorbGlowV            = { Anchor("BOTTOMLEFT", 0, -7, nil, "TOPLEFT"), Anchor("BOTTOMRIGHT", 0, -7, nil, "TOPRIGHT") }
shareOverHealAbsorbGlowV        = { Anchor("TOPRIGHT", 0, 7, nil, "BOTTOMRIGHT"), Anchor("TOPLEFT", 0, 7, nil, "BOTTOMLEFT") }

shareOrientationSubject         = Wow.FromUIProperty("Orientation"):Next()
shareSizeSubject                = shareOrientationSubject:Map("=>16")

------------------------------------------------------------
--                     Default Style                      --
------------------------------------------------------------
Style.UpdateSkin("Default",     {
    [NameLabel]                 = {
        drawLayer               = "BORDER",
        fontObject              = GameFontNormalSmall,
        text                    = Unit.Name,
        textColor               = Unit.Color,
    },
    [LevelLabel]                = {
        drawLayer               = "BORDER",
        fontObject              = GameFontNormalSmall,
        text                    = Unit.Level,
        vertexColor             = Unit.Level.Color,
    },
    [HealthLabel]               = {
        drawLayer               = "BORDER",
        fontObject              = GameFontNormalSmall,
        text                    = Unit.Health,
    },
    [PowerLabel]                = {
        drawLayer               = "BORDER",
        fontObject              = GameFontNormalSmall,
        text                    = Unit.Power,
    },
    [HealthBar]                 = {
        frameStrata             = "LOW",
        enableMouse             = false,
        statusBarTexture        = {
            file                = [[Interface\TargetingFrame\UI-StatusBar]],
        },
        value                   = Unit.Health,
        MaxValue                = Unit.Health.Max,
        statusBarColor          = Color.GREEN,
    },
    [PowerBar]                  = {
        frameStrata             = "LOW",
        enableMouse             = false,
        statusBarTexture        = {
            file                = [[Interface\TargetingFrame\UI-StatusBar]],
        },
        value                   = Unit.Power,
        MaxValue                = Unit.Power.Max,
        statusBarColor          = Unit.Power.Color,
    },
    [HiddenManaBar]             = {
        frameStrata             = "LOW",
        enableMouse             = false,
        statusBarTexture        = {
            file                = [[Interface\TargetingFrame\UI-StatusBar]],
        },
        value                   = Unit.Mana,
        MaxValue                = Unit.Mana.Max,
        visible                 = Unit.Mana.Visible,
        statusBarColor          = Color.MANA,
    },
    [ClassPowerBar]             = {
        frameStrata             = "LOW",
        enableMouse             = false,
        statusBarTexture        = {
            file                = [[Interface\TargetingFrame\UI-StatusBar]],
        },
        value                   = Unit.ClassPower,
        MaxValue                = Unit.ClassPower.Max,
        statusBarColor          = Unit.ClassPower.Color,
        visible                 = Unit.ClassPower.Visible,
    },
    [DisconnectIcon]            = {
        file                    = [[Interface\CharacterFrame\Disconnect-Icon]],
        size                    = Size(16, 16),
        visible                 = Unit.IsDisconnected,
    },
    [CombatIcon]                = {
        file                    = [[Interface\CharacterFrame\UI-StateIcon]],
        texCoords               = RectType(.5, 1, 0, .49),
        size                    = Size(24, 24),
        visible                 = Unit.InCombat,
    },
    [ResurrectIcon]             = {
        file                    = [[Interface\RaidFrame\Raid-Icon-Rez]],
        size                    = Size(16, 16),
        visible                 = Unit.IsResurrect,
    },
    [RaidTargetIcon]            = {
        file                    = [[Interface\TargetingFrame\UI-RaidTargetingIcons]],
        size                    = Size(16, 16),
        texCoords               = Unit.RaidTargetIndex:Map(function(index)
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
        visible                 = Unit.RaidTargetIndex:Map(function(val) return val and true or false end),
    },
    [ReadyCheckIcon]            = {
        file                    = Unit.ReadyCheck:Map(function(state)
            return state == "ready"    and READY_CHECK_READY_TEXTURE
                or state == "notready" and READY_CHECK_NOT_READY_TEXTURE
                or state == "waiting"  and READY_CHECK_WAITING_TEXTURE
                or nil
        end),
        visible                 = Unit.ReadyCheck.Visible,
        size                    = Size(16, 16),
    },
    [RaidRosterIcon]            = {
        file                    = Unit.Assignment:Map(function(assign)
            return assign == "MAINTANK"   and [[Interface\GROUPFRAME\UI-GROUP-MAINTANKICON]]
                or assign == "MAINASSIST" and [[Interface\GROUPFRAME\UI-GROUP-MAINASSISTICON]]
                or nil
        end),
        size                    = Size(16, 16),
    },
    [RoleIcon]                  = {
        file                    = [[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]],
        texCoords               = Unit.Role:Map(function(role)
            if role and role ~= "NONE" then
                local left, right, top, bottom = GetTexCoordsForRoleSmallCircle(role)

                shareRect.left  = left
                shareRect.right = right
                shareRect.top   = top
                shareRect.bottom= bottom
            else
                shareRect.left  = 0
                shareRect.right = 0
                shareRect.top   = 0
                shareRect.bottom= 0
            end
            return shareRect
        end),
        size                    = Size(16, 16),
        visible                 = Unit.Role.Visible,
    },
    [LeaderIcon]                = {
        file                    = [[Interface\GroupFrame\UI-Group-LeaderIcon]],
        size                    = Size(16, 16),
        visible                 = Unit.Role.IsLeader,
    },
    [CastBar]                   = {
        cooldown                = Unit.Cast.Cooldown,
        reverse                 = Unit.Cast.Channel,
        showSafeZone            = Unit.IsPlayer,
    },
    [TotemPanel]                = {
        refresh                 = Unit.Totem,
        visible                 = Unit.IsPlayer,
        elementType             = TotemPanelIcon,

        frameStrata             = "MEDIUM",
        columnCount             = _G.MAX_TOTEMS,
        rowCount                = 1,
        elementWidth            = 16,
        elementHeight           = 16,
        hSpacing                = 2,
        vSpacing                = 2,
        enableMouse             = false,
    },
    [TotemPanelIcon]            = {
        enableMouse             = true,
    },
    [PredictionHealthBar]       = {
        frameStrata             = "LOW",
        enableMouse             = false,
        statusBarColor          = Unit.ConditionColor(true, Color.RED),
        statusBarTexture        = {
            file                = [[Interface\TargetingFrame\UI-StatusBar]],
        },

        value                   = Unit.Health,
        minMaxValues            = Unit.HealthMinMax,
        healPrediction          = Unit.HealthPrediction,

        MyHealPrediction        = {
            drawLayer           = "BORDER",
            subLevel            = 5,
            color               = Color.WHITE,
            gradient            = shareOrientationSubject:Map(function(val) return val == "HORIZONTAL" and shareMyHealPreGraH or shareMyHealPreGraV end),
        },
        OtherHealPrediction     = {
            drawLayer           = "BORDER",
            subLevel            = 5,
            color               = Color.WHITE,
            gradient            = shareOrientationSubject:Map(function(val) return val == "HORIZONTAL" and shareOtherHealPreGraH or shareOtherHealPreGraV end),
        },
        TotalAbsorb             = {
            file                = [[Interface\RaidFrame\Shield-Fill]],
            drawLayer           = "BORDER",
            subLevel            = 5,
            rotateDegree        = shareOrientationSubject:Map(function(val) return val == "HORIZONTAL" and 0 or 270 end),
        },
        TotalAbsorbOverlay      = {
            file                = [[Interface\RaidFrame\Shield-Overlay]],
            hWrapMode           = "REPEAT",
            vWrapMode           = "REPEAT",
            drawLayer           = "BORDER",
            subLevel            = 6,
            location            = { Anchor("TOPLEFT", 0, 0, "TotalAbsorb"), Anchor("BOTTOMRIGHT", 0, 0, "TotalAbsorb") },
            rotateDegree        = shareOrientationSubject:Map(function(val) return val == "HORIZONTAL" and 0 or 270 end),
        },
        MyHealAbsorb            = {
            file                = [[Interface\RaidFrame\Absorb-Fill]],
            hWrapMode           = "REPEAT",
            vWrapMode           = "REPEAT",
            drawLayer           = "ARTWORK",
            subLevel            = 1,
            rotateDegree        = shareOrientationSubject:Map(function(val) return val == "HORIZONTAL" and 0 or 270 end),
        },
        -- MyHealAbsorbLeftShadow  = {
        --     file                = [[Interface\RaidFrame\Absorb-Edge]],
        --     drawLayer           = "ARTWORK",
        --     subLevel            = 1,
        --     setAllPoints        = true,
        --     rotateDegree        = shareOrientationSubject:Map(function(val) return val == "HORIZONTAL" and 0 or 270 end),
        -- },
        -- MyHealAbsorbRightShadow = {
        --     file                = [[Interface\RaidFrame\Absorb-Edge]],
        --     drawLayer           = "ARTWORK",
        --     subLevel            = 1,
        --     setAllPoints        = true,
        --     rotateDegree        = shareOrientationSubject:Map(function(val) return val == "HORIZONTAL" and 180 or 90 end),
        -- },
        OverAbsorbGlow          = {
            file                = [[Interface\RaidFrame\Shield-Overshield]],
            alphaMode           = "ADD",
            drawLayer           = "ARTWORK",
            subLevel            = 2,
            location            = shareOrientationSubject:Map(function(val) return val == "HORIZONTAL" and shareOverAbsorbGlowH or shareOverAbsorbGlowV end),
            width               = shareSizeSubject,
            height              = shareSizeSubject,
            rotateDegree        = shareOrientationSubject:Map(function(val) return val == "HORIZONTAL" and 0 or 270 end),
        },
        OverHealAbsorbGlow      = {
            file                = [[Interface\RaidFrame\Absorb-Overabsorb]],
            alphaMode           = "ADD",
            drawLayer           = "ARTWORK",
            subLevel            = 2,
            location            = shareOrientationSubject:Map(function(val) return val == "HORIZONTAL" and shareOverHealAbsorbGlowH or shareOverHealAbsorbGlowV end),
            width               = shareSizeSubject,
            height              = shareSizeSubject,
            rotateDegree        = shareOrientationSubject:Map(function(val) return val == "HORIZONTAL" and 0 or 270 end),
        },
    },
})