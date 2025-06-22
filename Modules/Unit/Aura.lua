--========================================================--
--                Scorpio UnitFrame Aura                  --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2025/06/2                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Secure.UnitFrame.Aura"         ""
--========================================================--

------------------------------------------------------------
--                        Reactive                        --
------------------------------------------------------------
do
    _UnitAuraCache              = {}

    -- From 10.0
    if _G.C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID then


        __SystemEvent__()
        function UNIT_AURA(unit, updateInfo)
            local guid          = UnitGUID(unit)
            local map           = _GuidUnitMap[guid]
            if not map then return end -- no unit track

            if updateInfo and not updateInfo.isFullUpdate then
                if updateInfo.addedAuras ~= nil then
                    for _, aura in ipairs(updateInfo.addedAuras) do
                        PlayerAuras[aura.auraInstanceID] = aura
                        -- Perform any setup tasks for this aura here.
                    end
                end

                if updateInfo.updatedAuraInstanceIDs ~= nil then
                    for _, auraInstanceID in ipairs(updateInfo.updatedAuraInstanceIDs) do
                        PlayerAuras[auraInstanceID] = C_UnitAuras.GetAuraDataByAuraInstanceID("player", auraInstanceID)
                        -- Perform any update tasks for this aura here.
                    end
                end

                if updateInfo.removedAuraInstanceIDs ~= nil then
                    for _, auraInstanceID in ipairs(updateInfo.removedAuraInstanceIDs) do
                        PlayerAuras[auraInstanceID] = nil
                        -- Perform any cleanup tasks for this aura here.
                    end
                end
            else
                -- full update
                PlayerAuras = {}

                local function HandleAura(aura)
                    PlayerAuras[aura.auraInstanceID] = aura
                    -- Perform any setup or update tasks for this aura here.
                end

                local batchCount = nil
                local usePackedAura = true
                AuraUtil.ForEachAura("player", "HELPFUL", batchCount, HandleAura, usePackedAura)
                AuraUtil.ForEachAura("player", "HARMFUL", batchCount, HandleAura, usePackedAura)
            end
        end
    end
end

------------------------------------------------------------
--                       Indicator                        --
------------------------------------------------------------
_DISPELLABLE                    = {
    ["MAGE"]                    = { Curse   = Color.CURSE, },
    ["DRUID"]                   = { Poison  = Color.POISON, Curse   = Color.CURSE,   Magic = Color.MAGIC },
    ["PALADIN"]                 = { Poison  = Color.POISON, Disease = Color.DISEASE, Magic = Color.MAGIC },
    ["PRIEST"]                  = { Disease = Color.DISEASE,Magic   = Color.MAGIC },
    ["SHAMAN"]                  = { Curse   = Color.CURSE,  Magic   = Color.MAGIC },
    ["WARLOCK"]                 = { Magic   = Color.MAGIC, },
    ["MONK"]                    = { Poison  = Color.POISON, Disease = Color.DISEASE, Magic = Color.MAGIC },
    ["EVOKER"]                  = { Poison  = Color.POISON, Disease = Color.DISEASE, Curse = Color.Curse },
}[_PlayerClass] or false

__Sealed__() class "AuraPanelIcon"  (function(_ENV)
    inherit "Frame"

    local isObjectType          = Class.IsObjectType

    local function OnEnter(self)
        if self.ShowTooltip and self.AuraIndex then
            local parent        = self:GetParent()
            if not parent then return end

            GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT')
            GameTooltip:SetUnitAura(parent.Unit, self.AuraIndex, parent.AuraFilter)
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

__ChildProperty__(UnitFrame)
__ChildProperty__(InSecureUnitFrame)
__Sealed__() class "AuraPanel"      (function(_ENV)
    inherit "ElementPanel"

    import "System.Reactive"

    local tconcat               = table.concat
    local tinsert               = table.insert
    local wipe                  = wipe
    local strtrim               = Toolset.trim
    local validate              = Enum.ValidateValue
    local shareCooldown         = { start = 0, duration = 0 }
    local cache                 = {}
    local slotMap               = {}

    local refreshAura, refreshAuraByPriorty
    local hasUnitAuraSlots      = _G.UnitAuraSlots and true or false

    if hasUnitAuraSlots then
        function refreshAura(self, unit, filter, eleIdx, auraIdx, continuationToken, ...)
            local notPlayer         = not UnitIsUnit(unit, "player")
            for i = 1, select("#", ...) do
                local slot          = select(i, ...)

                local name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod, arg1, arg2, arg3 = UnitAuraBySlot(unit, slot)

                if not self.CustomFilter or self.CustomFilter(name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod, arg1, arg2, arg3) then
                    self.Elements[eleIdx]:Show()

                    shareCooldown.start             = expires - duration
                    shareCooldown.duration          = duration

                    self.AuraIndex[eleIdx]          = auraIdx
                    self.AuraName[eleIdx]           = name
                    self.AuraIcon[eleIdx]           = icon
                    self.AuraCount[eleIdx]          = count
                    self.AuraDebuff[eleIdx]         = dtype
                    self.AuraCooldown[eleIdx]       = shareCooldown
                    self.AuraStealable[eleIdx]      = isStealable and notPlayer
                    self.AuraSpellID[eleIdx]        = spellId
                    self.AuraBossDebuff[eleIdx]     = isBossDebuff
                    self.AuraCastByPlayer[eleIdx]   = castByPlayer

                    eleIdx          = eleIdx + 1

                    if eleIdx > self.MaxCount then return eleIdx end
                end
                auraIdx             = auraIdx + 1
            end

            if continuationToken then
                return refreshAura(self, unit, filter, eleIdx, auraIdx, UnitAuraSlots(unit, filter, self.MaxCount - eleIdx + 1, continuationToken))
            else
                return eleIdx
            end
        end

        function refreshAuraByPriorty(self, unit, filter, priority, auraIdx, continuationToken, ...)
            for i = 1, select("#", ...) do
                local slot          = select(i, ...)

                local name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod, arg1, arg2, arg3 = UnitAuraBySlot(unit, slot)

                if not self.CustomFilter or self.CustomFilter(name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod, arg1, arg2, arg3) then
                    local order     = priority[name] or priority[spellId]
                    if order then
                        cache[order]= slot
                    else
                        tinsert(cache, slot)
                    end

                    slotMap[slot]   = auraIdx
                end

                auraIdx             = auraIdx + 1
            end

            return continuationToken and refreshAuraByPriorty(self, unit, filter, priority, auraIdx, UnitAuraSlots(unit, filter, self.MaxCount, continuationToken))
        end
    else
        function refreshAura(self, unit, filter, eleIdx, auraIdx, name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, castByPlayer, ...)
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

        function refreshAuraByPriorty(self, unit, filter, priority, auraIdx, name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, castByPlayer, ...)
            if not name then return end

            if not self.CustomFilter or self.CustomFilter(name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, castByPlayer, ...) then
                local order         = priority[name] or priority[spellID]
                if order then
                    cache[order]    = auraIdx
                else
                    tinsert(cache, auraIdx)
                end
            end

            auraIdx                 = auraIdx + 1
            return refreshAuraByPriorty(self, unit, filter, priority, auraIdx, UnitAura(unit, auraIdx, filter))
        end
    end

    local function OnElementCreated(self, ele)
        return ele:InstantApplyStyle()
    end

    local function OnShow(self)
        self.Refresh            = self.Unit
    end

    --- The aura filters
    __Sealed__() enum "AuraFilter" { "HELPFUL", "HARMFUL", "PLAYER", "RAID", "CANCELABLE", "NOT_CANCELABLE", "INCLUDE_NAME_PLATE_ONLY", "MAW" }

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    --- The aura filter
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

    --- The custom filter
    property "CustomFilter"     { type = Function }

    --- The aura priority with order
    property "AuraPriority"      { type = struct { String + Number }, handler = function(self, val) self._AuraPriorityCache = {} if val then for i, v in ipairs(val) do self._AuraPriorityCache[v] = i end end end }

    --- The property to drive the refreshing
    property "Refresh"          {
        set                     = function(self, unit)
            self.Unit           = unit
            local filter        = self.AuraFilter
            if not (unit and filter and filter ~= "" and self:IsVisible()) then return end

            local auraPriority  = self.AuraPriority
            if not auraPriority or #auraPriority == 0 then
                if hasUnitAuraSlots then
                    self.Count  = refreshAura(self, unit, filter, 1, 1, UnitAuraSlots(unit, filter, self.MaxCount)) - 1
                else
                    self.Count  = refreshAura(self, unit, filter, 1, 1, UnitAura(unit, 1, filter)) - 1
                end
            else
                wipe(cache) for i = 1, #auraPriority do cache[i] = false end
                if hasUnitAuraSlots then
                    refreshAuraByPriorty(self, unit, filter, self._AuraPriorityCache, 1, UnitAuraSlots(unit, filter, self.MaxCount))
                else
                    refreshAuraByPriorty(self, unit, filter, self._AuraPriorityCache, 1, UnitAura(unit, 1, filter))
                end

                local eleIdx    = 1
                local name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, castByPlayer
                for i = 1, #cache do
                    local slot  = cache[i]
                    if slot then
                        if hasUnitAuraSlots then
                            name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, castByPlayer = UnitAuraBySlot(unit, slot)
                        else
                            name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, castByPlayer = UnitAura(unit, slot, filter)
                        end

                        self.Elements[eleIdx]:Show()

                        shareCooldown.start             = expires - duration
                        shareCooldown.duration          = duration

                        self.AuraIndex[eleIdx]          = slotMap[slot]
                        self.AuraName[eleIdx]           = name
                        self.AuraIcon[eleIdx]           = icon
                        self.AuraCount[eleIdx]          = count
                        self.AuraDebuff[eleIdx]         = dtype
                        self.AuraCooldown[eleIdx]       = shareCooldown
                        self.AuraStealable[eleIdx]      = isStealable and not UnitIsUnit(unit, "player")
                        self.AuraSpellID[eleIdx]        = spellID
                        self.AuraBossDebuff[eleIdx]     = isBossDebuff
                        self.AuraCastByPlayer[eleIdx]   = castByPlayer

                        eleIdx  = eleIdx + 1
                        if eleIdx > self.MaxCount then break end
                    end
                end

                self.Count      = eleIdx - 1
            end
        end
    }

    --- The unit of the current aura
    property "Unit"             { type = String }

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
        self.OnShow             = self.OnShow           + OnShow
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
    [AuraPanel]                 = {
        refresh                 = Unit.Aura,
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
})