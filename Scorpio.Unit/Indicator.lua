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

__ChildProperty__(UnitFrame,         "ReadyCheckIcon")
__ChildProperty__(InSecureUnitFrame, "ReadyCheckIcon")
__Sealed__() class "ReadyCheckIcon"  { Texture }

__ChildProperty__(UnitFrame,         "RaidRosterIcon")
__ChildProperty__(InSecureUnitFrame, "RaidRosterIcon")
__Sealed__() class "RaidRosterIcon"  { Texture }

__ChildProperty__(UnitFrame,         "RoleIcon")
__ChildProperty__(InSecureUnitFrame, "RoleIcon")
__Sealed__() class "RoleIcon"        { Texture }

__ChildProperty__(UnitFrame,         "LeaderIcon")
__ChildProperty__(InSecureUnitFrame, "LeaderIcon")
__Sealed__() class "LeaderIcon"      { Texture }

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

    local function refreshAura(self, unit, filter, eleIdx, auraIdx, name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, castByPlayer, ...)
        if not name or eleIdx > self.MaxCount then return eleIdx end

        if not self.CustomFilter or self.CustomFilter(name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, castByPlayer, ...) then
            self.Elements[eleIdx]:Show()

            shareCooldown.start             = expires - duration
            shareCooldown.duration          = duration

            self.AuraIndex[eleIdx]          = auraIdx
            self.AuraName[eleIdx]           = name
            self.AuraIcon[eleIdx]           = icon
            self.AuraCount[eleIdx]          = count
            self.AuraDebuff[eleIdx]         = dtype
            self.AuraCooldown[eleIdx]       = shareCooldown
            self.AuraStealable[eleIdx]      = isStealable and not UnitIsUnit(unit, "player")
            self.AuraSpellID[eleIdx]        = spellID
            self.AuraBossDebuff[eleIdx]     = isBossDebuff
            self.AuraCastByPlayer[eleIdx]   = castByPlayer

            eleIdx              = eleIdx + 1
        end

        auraIdx                 = auraIdx + 1
        return refreshAura(self, unit, filter, eleIdx, auraIdx, UnitAura(unit, auraIdx, filter))
    end

    local function OnElementCreated(self, ele)
        return ele:InstantApplyStyle()
    end

    --- The aura filters
    __Sealed__() enum "AuraFilter" { "HELPFUL", "HARMFUL", "PLAYER", "RAID", "CANCELABLE", "NOT_CANCELABLE", "INCLUDE_NAME_PLATE_ONLY" }

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    property "AuraFilter"       {
        type                    = struct{ AuraFilter } + String,
        field                   = "__AuraPanel_AuraFilter",
        set                     = function(self, filter)
            -- No more check, just keep it simple
            if type(filter) == "table" then
                filter          = tconcat(filter, "|")
            else
                filter          = filter and strtrim(filter) or ""
            end

            if filter == "" then
                self.Count      = 0
            end

            self.__AuraPanel_AuraFilter = filter
        end,
    }

    property "CustomFilter"     { type = Function }

    property "Refresh"          {
        set                     = function(self, unit)
            local filter        = self.AuraFilter
            if not filter or filter == "" then return end

            self.Count          = refreshAura(self, unit, filter, 1, 1, UnitAura(unit, 1, filter)) - 1
        end
    }

    ------------------------------------------------------
    -- Observable Property
    ------------------------------------------------------
    __Indexer__() __Observable__()
    property "AuraIndex"        { set = Toolset.fakefunc }

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

__Sealed__() class "AuraPanelIcon"  (function(_ENV)
    inherit "Frame"

    local isObjectType          = Class.IsObjectType

    local function OnEnter(self)
        if self.ShowTooltip and self.AuraIndex then
            local parent        = self:GetParent()
            while parent and not isObjectType(parent, IUnitFrame) do
                parent          = parent:GetParent()
            end

            if not parent then return end

            GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT')
            GameTooltip:SetUnitAura(parent.Unit, self.AuraIndex, self:GetParent().AuraFilter)
        end
    end

    local function OnLeave(self)
        GameTooltip:Hide()
    end

    property "ShowTooltip"      { type = Boolean, default = true }

    property "AuraIndex"        { type = Number }

    function __ctor(self)
        self.OnEnter            = self.OnEnter + OnEnter
        self.OnLeave            = self.OnLeave + OnLeave
    end
end)

__ChildProperty__(UnitFrame,        "TotemPanel")
__ChildProperty__(InSecureUnitFrame,"TotemPanel")
__Sealed__() class "TotemPanel"     (function(_ENV)
    inherit "ElementPanel"

    import "System.Reactive"

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
                    self.Elements[eleIdx]:Show()
                    self.Elements[eleIdx].Slot  = SLOT_MAP[i]

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
__ChildProperty__(UnitFrame,        "PredictionHealthBar")
__ChildProperty__(InSecureUnitFrame,"PredictionHealthBar")
__Sealed__() class "PredictionHealthBar" (function(_ENV)
    inherit "StatusBar"

    property "HealPrediction"   {
        type                    = HealPrediction,
        handler                 = function(self, prediction)
            local myIncomingHeal    = prediction.myIncomingHeal
            local allIncomingHeal   = prediction.allIncomingHeal
            local otherIncomingHeal = prediction.otherIncomingHeal
            local totalAbsorb       = prediction.totalAbsorb
            local totalHealAbsorb   = prediction.totalHealAbsorb

            self:GetChild("OverHealAbsorbGlow"):SetShown(prediction.overHealAbsorb)
            self:GetChild("OverAbsorbGlow"):SetShown(prediction.overAbsorb)

            local healthTexture = frame.healthBar:GetStatusBarTexture();

            local totalHealAbsorbPercent = totalHealAbsorb / maxHealth;

            local healAbsorbTexture = nil;

            --If allIncomingHeal is greater than totalHealAbsorb, then the current
            --heal absorb will be completely overlayed by the incoming heals so we don't show it.
            if ( totalHealAbsorb > allIncomingHeal ) then
                local shownHealAbsorb = totalHealAbsorb - allIncomingHeal;
                local shownHealAbsorbPercent = shownHealAbsorb / maxHealth;
                healAbsorbTexture = CompactUnitFrameUtil_UpdateFillBar(frame, healthTexture, frame.myHealAbsorb, shownHealAbsorb, -shownHealAbsorbPercent);

                --If there are incoming heals the left shadow would be overlayed by the incoming heals
                --so it isn't shown.
                if ( allIncomingHeal > 0 ) then
                    frame.myHealAbsorbLeftShadow:Hide();
                else
                    frame.myHealAbsorbLeftShadow:SetPoint("TOPLEFT", healAbsorbTexture, "TOPLEFT", 0, 0);
                    frame.myHealAbsorbLeftShadow:SetPoint("BOTTOMLEFT", healAbsorbTexture, "BOTTOMLEFT", 0, 0);
                    frame.myHealAbsorbLeftShadow:Show();
                end

                -- The right shadow is only shown if there are absorbs on the health bar.
                if ( totalAbsorb > 0 ) then
                    frame.myHealAbsorbRightShadow:SetPoint("TOPLEFT", healAbsorbTexture, "TOPRIGHT", -8, 0);
                    frame.myHealAbsorbRightShadow:SetPoint("BOTTOMLEFT", healAbsorbTexture, "BOTTOMRIGHT", -8, 0);
                    frame.myHealAbsorbRightShadow:Show();
                else
                    frame.myHealAbsorbRightShadow:Hide();
                end
            else
                frame.myHealAbsorb:Hide();
                frame.myHealAbsorbRightShadow:Hide();
                frame.myHealAbsorbLeftShadow:Hide();
            end

            --Show myIncomingHeal on the health bar.
            local incomingHealsTexture = CompactUnitFrameUtil_UpdateFillBar(frame, healthTexture, frame.myHealPrediction, myIncomingHeal, -totalHealAbsorbPercent);
            --Append otherIncomingHeal on the health bar.
            incomingHealsTexture = CompactUnitFrameUtil_UpdateFillBar(frame, incomingHealsTexture, frame.otherHealPrediction, otherIncomingHeal);

            --Appen absorbs to the correct section of the health bar.
            local appendTexture = nil;
            if ( healAbsorbTexture ) then
                --If there is a healAbsorb part shown, append the absorb to the end of that.
                appendTexture = healAbsorbTexture;
            else
                --Otherwise, append the absorb to the end of the the incomingHeals part;
                appendTexture = incomingHealsTexture;
            end
            CompactUnitFrameUtil_UpdateFillBar(frame, appendTexture, frame.totalAbsorb, totalAbsorb)
        end
    }


    __Template__{
        MyHealPrediction        = Texture,
        OtherHealPrediction     = Texture,
        TotalAbsorb             = Texture,
        TotalAbsorbOverlay      = Texture,

        MyHealAbsorb            = Texture,
        MyHealAbsorbLeftShadow  = Texture,
        MyHealAbsorbRightShadow = Texture,

        OverAbsorbGlow          = Texture,
        OverHealAbsorbGlow      = Texture,
    }
    function __ctor(self) end
end)

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
    [ReadyCheckIcon]            = {
        file                    = Wow.UnitReadyCheck():Map(function(state)
            return state == "ready"    and READY_CHECK_READY_TEXTURE
                or state == "notready" and READY_CHECK_NOT_READY_TEXTURE
                or state == "waiting"  and READY_CHECK_WAITING_TEXTURE
                or nil
        end),
        visible                 = Wow.UnitReadyCheckVisible(),
        size                    = Size(16, 16),
    },
    [RaidRosterIcon]            = {
        file                    = Wow.UnitGroupRoster():Map(function(assign)
            return assign == "MAINTANK"   and [[Interface\GROUPFRAME\UI-GROUP-MAINTANKICON]]
                or assign == "MAINASSIST" and [[Interface\GROUPFRAME\UI-GROUP-MAINASSISTICON]]
                or nil
        end),
        size                    = Size(16, 16),
    },
    [RoleIcon]                  = {
        file                    = Wow.UnitRole():Map(function(role)
            return role and role ~= "NONE" and GetTexCoordsForRoleSmallCircle(role) or nil
        end),
        size                    = Size(16, 16),
    },
    [LeaderIcon]                = {
        file                    = [[Interface\GroupFrame\UI-Group-LeaderIcon]],
        size                    = Size(16, 16),
        visible                 = Wow.UnitIsLeader(),
    },
    [CastBar]                   = {
        cooldown                = Wow.UnitCastCooldown(),
        reverse                 = Wow.UnitCastChannel(),
        showSafeZone            = Wow.UnitIsPlayer(),
    },
    [AuraPanel]                 = {
        refresh                 = Wow.UnitAura(),
        elementType             = AuraPanelIcon,

        frameStrata             = "MEDIUM",
        columnCount             = 6,
        rowCount                = 6,
        elementWidth            = 16,
        elementHeight           = 16,
        hSpacing                = 2,
        vSpacing                = 2,
        enableMouse             = false,
    },
    [BuffPanel]                 = {
        auraFilter              = "HELPFUL",
    },
    [DebuffPanel]               = {
        auraFilter              = "HARMFUL",
    },
    [ClassBuffPanel]            = {
        auraFilter              = "PLAYER",
    },
    [AuraPanelIcon]             = {
        enableMouse             = true,
        auraIndex               = Wow.FromPanelProperty("AuraIndex"),
    },
    [TotemPanel]                = {
        refresh                 = Wow.UnitTotem(),
        visible                 = Wow.UnitIsPlayer(),
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
        statusBarColor          = Color.GREEN,
        statusBarTexture        = {
            file                = [[Interface\TargetingFrame\UI-StatusBar]],
        },

        value                   = Wow.UnitHealth(),
        minMaxValues            = Wow.UnitHealthMax(),
        healPrediction          = Wow.UnitHealPrediction(),

        MyHealPrediction        = {
            drawLayer           = "BORDER",
            subLevel            = 5,
        },
        OtherHealPrediction     = {
            drawLayer           = "BORDER",
            subLevel            = 5,
        },
        TotalAbsorb             = {
            drawLayer           = "BORDER",
            subLevel            = 5,
        },
        TotalAbsorbOverlay      = {
            drawLayer           = "BORDER",
            subLevel            = 6,
        },
        MyHealAbsorb            = {
            drawLayer           = "ARTWORK",
            subLevel            = 1,
        },
        MyHealAbsorbLeftShadow  = {
            file                = [[Interface\RaidFrame\Absorb-Edge]],
            drawLayer           = "ARTWORK",
            subLevel            = 1,
        },
        MyHealAbsorbRightShadow = {
            file                = [[Interface\RaidFrame\Absorb-Edge]],
            drawLayer           = "ARTWORK",
            subLevel            = 1,
            texCoords           = RectType(1, 0, 0, 1),
        },
        OverAbsorbGlow          = {
            drawLayer           = "ARTWORK",
            subLevel            = 2,
        },
        OverHealAbsorbGlow      = {
            drawLayer           = "ARTWORK",
            subLevel            = 2,
        },
    },
})