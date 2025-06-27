--========================================================--
--                Scorpio UnitFrame Reactive              --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2025/04/01                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Secure.UnitFrame.Reactive"     ""
--========================================================--

------------------------------------------------------------
--                         Helper                         --
------------------------------------------------------------
do
    export                      {
        getCurrentTarget        = UI.Style.GetCurrentTarget,
        isUIObject              = UI.IsUIObject,
        isObjectType            = Class.IsObjectType,
        unitFrameObservable     = Toolset.newtable(true),
    }

    --- Gets the unit frame's unit observable
    function GetUnitFrameSubject()
        -- Gets the current unit frame
        local indicator         = getCurrentTarget()
        while indicator and not isObjectType(indicator, IUnitFrame) do
            indicator           = indicator:GetParent()
        end
    
        -- gets the unit subject
        return indicator and indicator.Subject
    end

    --- Combine unit observable and unit event observable
    function GenUnitFrameObservable(unitEvent)
        local observable        = unitFrameObservable[unitEvent]

        if not observable then
            observable          = Observable(function(observer, subscription)
                local unitSub   = GetUnitFrameSubject()
                if not unitSub  then return unitEvent and unitEvent:Subscribe(observer, subscription) end

                -- Start the unit watching
                local eventSub
                unitSub:Subscribe(Observer(function(unit)
                    if eventSub then eventSub:Dispose() end
                    eventSub    = Subscription(subscription)

                    -- Check trackable unit
                    local runit = unit and GetUnitFromGUID(UnitGUID(unit)) or unit
                    if runit then unitEvent:MatchUnit(runit):Subscribe(observer, eventSub) end

                    -- Push the unit
                    return observer:OnNext(unit)
                end), subscription)
            end)

            unitFrameObservable[unitEvent] = observable
        end

        return observable
    end
end

------------------------------------------------------------
--                 Scorpio Wow Extension                  --
------------------------------------------------------------
--- The data sequences from the wow unit event binding to unit frames
-- @deprecated
__Arguments__{ NEString + IObservable, NEString * 0 }
function Wow.FromUnitEvent(observable, ...)
    if type(observable) == "string" then
        return GenUnitFrameObservable(FromEvent(observable, ...))
    else
        return GenUnitFrameObservable(observable)
    end
end

------------------------------------------------------------
--                    Scorpio Wow Unit                    --
------------------------------------------------------------
--- Gets the unit observable and the unit data container
Scorpio.Wow.Unit                = reactive {
    --- No deep subscription for Unit, override the default subscription
    Subscribe                   = function (self, ...)
        local subject           = GetUnitFrameSubject()
        if not subject then return end
        return subject:Subscribe(...)
    end,

    --- Combine with unit event observables
    Watch                       = function(self, arg, ...) return self == Unit and Wow.FromUnitEvent(arg, ...) or Wow.FromUnitEvent(self, arg, ...) end
}

------------------------------------------------------------
--                          Unit                          --
------------------------------------------------------------
do
    Unit                        = Scorpio.Wow.Unit
    
    --- Gets a timer to refresh
    Unit.Timer                  = Unit:Watch(Observable.Interval(0.5):Map("=>'any'"))

    --- Gets the unit's name
    Unit.Name                   = Unit:Map(GetUnitName)

    --- Gets the unit's name with server
    Unit.Name.Server            = Unit:Map(function(unit)
        local name, server      = GetUnitName(unit, true)
        return name and server and (name .. "-" .. server) or name
    end)

    --- Gets the unit class color
    local tColor                = {}
    Unit.Color                  = Unit:Watch("UNIT_FACTION", "UNIT_THREAT_SITUATION_UPDATE"):Map(function(unit)
        if not UnitIsPlayer(unit) then
            if UnitIsTapDenied(unit) then return Color.RUNES end

            if withThreat and UnitCanAttack("player", unit) then
                local threat    = UnitThreatSituation("player", unit)
                if threat and threat > 0 then
                    local color = tColor[threat]
                    if not color then
                        local r, g, b = GetThreatStatusColor(threat)
                        color   = { r = r, g = g, b = b }
                        tColor[threat] = color
                    end
                    return color
                end
            end

            local r, g, b       = UnitSelectionColor(unit, true)
            local rgb           = ("%.2x%.2x%.2x"):format(r * 255, g * 255, b * 255)
            local color         = tColor[rgb]
            if not color then
                color           = { r = r, g = g, b = b }
                tColor[rgb]     = color
            end

            return color
        end
        local _, cls            = UnitClass(unit)
        return Color[cls or "PALADIN"]
    end)

    --- Gets the unit level
    Unit.Level                  = Unit:Watch(Wow.PLAYER_LEVEL_UP:Map(function(level) return "player", level end))
        :Map(_G.UnitBattlePetLevel and function(unit, level)
            level               = level or UnitLevel(unit)
            if level and level > 0 then
                if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
                    level       = UnitBattlePetLevel(unit)
                end
                return strformat("%s", level)
            else
                return "???"
            end
        end or function(unit, level)
            level               = level or UnitLevel(unit)
            if level and level > 0 then
                return strformat("%s", level)
            else
                return "???"
            end
        end)

    --- Gets the unit's level color
    Unit.Level.Color            = Unit:Map(function(unit) return UnitCanAttack("player", unit) and GetQuestDifficultyColor(UnitLevel(unit) or 99) or Color.NORMAL end)

    --- Gets the unit's classification
    Unit.Classification         = Unit:Watch("UNIT_CLASSIFICATION_CHANGED"):Map(UnitClassification)

    --- Gets the unit's classification color
    Unit.Classification.Color   = Unit:Watch("UNIT_CLASSIFICATION_CHANGED"):Map(function(unit)
        local c                 = UnitClassification(unit)
        return c == "elite"     and Color.YELLOW
            or c == "rare"      and Color.WHITE
            or c == "rareelite" and Color.CYAN
            or c == "worldboss" and Color.RAGE
            or Color.NORMAL
    end)

    --- Gets the unit's disconnected
    Unit.Disconnected           = Unit:Watch("UNIT_CONNECTION"):Map(function(unit) return not UnitIsConnected(unit) end)

    --- Gets the unit is target
    Unit.IsTarget               = Unit:Watch(Wow.PLAYER_TARGET_CHANGED:Map("=>'any'")):Map(function(unit) return UnitIsUnit(unit, "target") end)

    --- Gets the unit is player
    Unit.IsPlayer               = Unit:Map(function(unit) return UnitIsUnit(unit, "player") end)

    --- Whether the player is in combat
    Unit.InCombat               = Wow.FromEvent("PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED"):Map(function() return UnitAffectingCombat("player") or false end):ToSubject(BehaviorSubject)

    --- Gets whether the unit is in range of the player
    Unit.InRange                = Unit.Timer:Map(function(unit) return UnitExists(unit) and (UnitIsUnit(unit, "player") or not (UnitInParty(unit) or UnitInRaid(unit)) or UnitInRange(unit)) end)

    --- Whether the unit is resurrect
    resurrectSubject            = Subject()
    Wow.INCOMING_RESURRECT_CHANGED:Next():Subscribe(function(unit)
        resurrectSubject:OnNext(unit)

        if UnitHasIncomingResurrection(unit) then
            Next(function()
                -- Avoid the event not fired when the unit is already resurrected
                while UnitHasIncomigResurrectinon(unit) do Delay(1) end
                resurrectSubject:OnNext(unit)
            end)
        end
    end)
    Unit.IsResurrect            = Unit:Watch(resurrectSubject):Map(UnitHasIncomingResurrection)

    --- Gets the unit's raid target index
    Unit.RaidTargetIndex        = Unit:Watch(Wow.RAID_TARGET_UPDATE:Map("=>'any'")):Map(GetRaidTargetIndex)

    --- Gets the unit's threat level
    Unit.ThreatLevel            = Unit:Watch("UNIT_THREAT_SITUATION_UPDATE"):Map(function(unit) return UnitIsPlayer(unit) and UnitThreatSituation(unit) or 0 end)

    --- Whether the unit is targeted by enemy
    Unit.HasThreat              = Unit:Watch("UNIT_THREAT_SITUATION_UPDATE"):Map(function(unit) return UnitIsPlayer(unit) and (UnitThreatSituation(unit) or 0) >= 2 end)

    --- Gets the unit's party assignment
    roleSubject                 = Wow.FromEvent("GROUP_ROSTER_UPDATE", "PLAYER_ROLES_ASSIGNED", "PARTY_LEADER_CHANGED"):Map("=>'any'"):Debounce(0.5):ToSubject()
    Unit.Assignment             = Unit:Watch(roleSubject):Map(function(unit)
        if IsInRaid() and not UnitHasVehicleUI(unit) then
            if GetPartyAssignment('MAINTANK', unit) then
                return "MAINTANK"
            elseif GetPartyAssignment('MAINASSIST', unit) then
                return "MAINASSIST"
            end
        end
        return "NONE"
    end)

    --- Whether the unit is main tank
    Unit.Assignment.MainTank    = Unit:Watch(roleSubject):Map(function(unit) return IsInRaid() and not UnitHasVehicleUI(unit) and GetPartyAssignment('MAINTANK', unit) end)

    --- Whether the unit is main assist
    Unit.Assignment.MainAssist  = Unit:Watch(roleSubject):Map(function(unit) return IsInRaid() and not UnitHasVehicleUI(unit) and GetPartyAssignment('MAINASSIST', unit) end)

    --- Gets the unit's party assignment visibility
    Unit.Assignment.Visible     = Unit.Assignment:Map(function(assign) return assign ~= "NONE" end)

    --- Gets the unit's role
    Unit.Role                   = _G.UnitGroupRolesAssigned and Unit:Watch(roleSubject):Map(UnitGroupRolesAssigned) or BehaviorSubject("NONE")

    --- Gets the unit role's visibility
    Unit.Role.Visible           = _G.UnitGroupRolesAssigned and Unit:Watch(roleSubject):Map(function(unit) return (UnitGroupRolesAssigned(unit) or "NONE") ~= "NONE" end) or BehaviorSubject(false)

    --- Gets whether the unit is leader
    Unit.Role.IsLeader          = Unit:Watch(roleSubject):Map(function(unit) return (UnitInParty(unit) or UnitInRaid(unit)) and UnitIsGroupLeader(unit) or false end)

    --- Gets the unit totem update
    Unit.Totem                  = Unit:Watch(Wow.PLAYER_TOTEM_UPDATE:Map("=>'player'"))
end

------------------------------------------------------------
--                       Unit Owner                       --
------------------------------------------------------------
do
    --- Gets the unit owner
    function GetUnitOwner(unit)
        return unit and (unit:match("^[pP][eE][tT]$") and "player" or unit:gsub("[pP][eE][tT]", "")) or nil
    end

    --- Gets the unit's owner
    Unit.Owner                  = Unit:Map(GetUnitOwner)

    --- Gets the unit's owner name
    Unit.Owner.Name             = Unit:Map(function(unit) return GetUnitName(GetUnitOwner(unit)) end)

    --- Gets the unit's owner name with server
    Unit.Owner.Name.Server      = Unit:Map(function(unit)
        local name, server      = GetUnitName(GetUnitOwner(unit), true)
        return name and server and (name .. "-" .. server) or name
    end)

    --- Gets the unit's owner class color
    Unit.Owner.Color            = Unit:Map(function(unit)
        local _, cls            = UnitClass(GetUnitOwner(unit))
        return Color[cls or "PALADIN"]
    end)

    --- Gets whether the unit's owner is in range or the player
    Unit.Owner.InRange          = Unit.Timer:Map(function(unit) unit = GetUnitOwner(unit) return UnitExists(unit) and (UnitIsUnit(unit, "player") or not (UnitInParty(unit) or UnitInRaid(unit)) or UnitInRange(unit)) end)
end

------------------------------------------------------------
--                      Ready Check                       --
------------------------------------------------------------
do
    _ReadyChecking              = 0
    _ReadyCheckVisibleSubject   = Subject()
    _ReadyCheckConfirmSubject   = Subject()
    _ReadyCheckCache            = {}

    __SystemEvent__() __Async__()
    function READY_CHECK()
        wipe(_ReadyCheckCache)

        _ReadyChecking          = 1
        _ReadyCheckVisibleSubject:OnNext("any")
        _ReadyCheckConfirmSubject:OnNext("any")

        if "READY_CHECK_FINISHED" == Wait("READY_CHECK_FINISHED", "PLAYER_REGEN_DISABLED") then
            _ReadyChecking      = 2
            _ReadyCheckConfirmSubject:OnNext("any")

            Wait(10, "PLAYER_REGEN_DISABLED")
        end

        _ReadyChecking          = 0
        return _ReadyCheckVisibleSubject:OnNext("any")
    end

    __SystemEvent__()
    function READY_CHECK_CONFIRM()
        return _ReadyCheckConfirmSubject:OnNext("any")
    end

    --- Gets the unit's ready check status
    Unit.ReadyCheck             = Unit:Watch(_ReadyCheckConfirmSubject):Map(function(unit)
        if _ReadyChecking == 0 then return end

        local guid              = UnitGUID(unit)
        if not guid then return "notready" end

        local state             = GetReadyCheckStatus(unit) or _ReadyCheckCache[guid]
        _ReadyCheckCache[guid]  = state
        return _ReadyChecking == 2 and state == "waiting" and "notready" or state
    end)

    --- Gets the unit's ready check visibility
    Unit.ReadyCheck.Visible     = Unit:Watch(_ReadyCheckVisibleSubject):Map(function(unit) return _ReadyChecking > 0 and UnitGUID(unit) ~= nil end)
end

------------------------------------------------------------
--                         Health                         --
------------------------------------------------------------
do
    --------------------------------------------------------
    --                       Helper                       --
    --------------------------------------------------------
    _UnitHealthMap              = {}
    _FixUnitMaxHealth           = {}
    
    _UnitHealthSubject          = Subject()
    _UnitMaxHealthSubject       = Subject()
    
    -- clear
    Wow.PLAYER_ENTERING_WORLD:Subscribe(function() wipe(_UnitHealthMap) end)
    Wow.SCORPIO_UNIT_STOP_TRACKING_GUID:Subscribe(function(guid) _UnitHealthMap[guid] = nil end)

    -- events
    __CombatEvent__ "SWING_DAMAGE" "RANGE_DAMAGE" "SPELL_DAMAGE" "SPELL_PERIODIC_DAMAGE" "DAMAGE_SPLIT" "DAMAGE_SHIELD" "ENVIRONMENTAL_DAMAGE" "SPELL_HEAL" "SPELL_PERIODIC_HEAL"
    function COMBAT_HEALTH_CHANGE(_, event, _, _, _, _, _, destGUID, _, _, _, arg12, arg13, arg14, arg15, arg16)
        local health            = _UnitHealthMap[destGUID]
        local map               = _GuidUnitMap[destGUID]
        if not (health and map) then return end
    
        local change            = 0
    
        if event == "SWING_DAMAGE" then
            -- amount   : arg12
            -- overkill : arg13
            change              = (arg13 > 0 and arg13 or 0) - arg12
        elseif event == "RANGE_DAMAGE" or event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" or event == "DAMAGE_SPLIT" or event == "DAMAGE_SHIELD" then
            -- amount   : arg15
            -- overkill : arg16
            change              = (arg16 > 0 and arg16 or 0) - arg15
        elseif event == "ENVIRONMENTAL_DAMAGE" then
            -- amount   : arg13
            -- overkill : arg14
            change              = (arg14 > 0 and arg14 or 0) - arg13
        elseif event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" then
            -- amount       : arg15
            -- overhealing  : arg16
            change              = arg15 - arg16
        end
    
        if change == 0 then return end
    
        health                  = health + change
        if change < 0 then
            if health < 0 then health = 0 end
        elseif change > 0 then
            local unit          = next(map)
            if not unit then
                _UnitHealthMap[destGUID]= nil
                return
            end
    
            local max           = UnitHealthMax(unit)
            if health > max then health = max end
        end
        _UnitHealthMap[destGUID]= health
    
        -- Distribute the new health
        for unit in pairs(map) do
            _UnitHealthSubject:OnNext(unit)
        end
    end
    
    __CombatEvent__ "UNIT_DIED" "UNIT_DESTROYED" "UNIT_DISSIPATES"
    function COMBAT_UNIT_DIED(_, _, _, _, _, _, _, destGUID)
        local map               = _GuidUnitMap[destGUID]
        if not map then return end
        for unit in pairs(map) do
            Delay(0.3, FireSystemEvent, "UNIT_HEALTH", unit)
        end
    end
    
    __SystemEvent__("UNIT_HEALTH", "UNIT_HEALTH_FREQUENT")
    function UNIT_HEALTH(unit)
        local guid              = UnitGUID(unit)
        -- Update the guid health
        if _GuidUnitMap[guid] then
            _UnitHealthMap[guid]= UnitHealth(unit)
        end
        return _UnitHealthSubject:OnNext(unit)
    end
    
    __SystemEvent__()
    function UNIT_MAXHEALTH(unit)
        _UnitMaxHealthSubject:OnNext(unit)
        _UnitHealthSubject:OnNext(unit)
    end
    
    __Service__(true)
    function FixUnitMaxHealth()
        while true do
            local hasUnit       = false
    
            for unit in pairs(_FixUnitMaxHealth) do
                local health    = UnitHealth(unit)
                local max       = UnitHealthMax(unit)
                hasUnit         = true
    
                if health > 0 and max > 0 then
                    if max >= health then
                        _FixUnitMaxHealth[unit] = nil
                        FireSystemEvent("UNIT_MAXHEALTH", unit)
                    end
                elseif not UnitExists(unit) then
                    _FixUnitMaxHealth[unit] = nil
                end
            end
    
            if not hasUnit then
                NextEvent("SCORPIO_UNIT_FIX_MAX_HEALTH")
            else
                Next()
            end
        end
    end
    
    function RegisterFixUnitMaxHealth(unit)
        if UnitExists(unit) then
            if not next(_FixUnitMaxHealth) then FireSystemEvent("SCORPIO_UNIT_FIX_MAX_HEALTH") end
            _FixUnitMaxHealth[unit] = true
        end
    end
    
    --------------------------------------------------------
    --                     Observable                     --
    --------------------------------------------------------
    --- Gets the unit health
    Unit.Health                 = Unit:Watch(_UnitHealthSubject):Map(function(unit)
        return _UnitHealthMap[UnitGUID(unit)] or UnitHealth(unit)
    end)
    
    --- Gets the unit lost health
    Unit.Health.Loss            = Unit:Watch(_UnitHealthSubject):Map(function(unit)
        local max               = UnitHealthMax(unit)
        local health            = _UnitHealthMap[UnitGUID(unit)] or UnitHealth(unit)
        if max == 0 or max < health then
            RegisterFixUnitMaxHealth(unit)
            return 0
        end
        return max - health
    end)

    --- Gets the unit health percent
    Unit.Health.Percent         = Unit:Watch(_UnitHealthSubject):Map(function(unit)
        local max               = UnitHealthMax(unit)
        local health            = _UnitHealthMap[UnitGUID(unit)] or UnitHealth(unit)
        if max == 0 or max < health then
            RegisterFixUnitMaxHealth(unit)
            return 100
        end
        return floor(0.5 + health / max * 100)
    end)

    --- Gets the unit health loss percent
    Unit.Health.LossPercent     = Unit:Watch(_UnitHealthSubject):Map(function(unit)
        local max               = UnitHealthMax(unit)
        local health            = _UnitHealthMap[UnitGUID(unit)] or UnitHealth(unit)
        if max == 0 or max < health then
            RegisterFixUnitMaxHealth(unit)
            return 100
        end
        return floor(0.5 + (max - health) / max * 100)
    end)

    --- Gets the unit max health
    Unit.Health.Max             = Unit:Watch(_UnitMaxHealthSubject):Map(function(unit)
        local max               = UnitHealthMax(unit)
        if max == 0 then
            RegisterFixUnitMaxHealth(unit)
            max                 = _UnitHealthMap[UnitGUID(unit)] or UnitHealth(unit)
        end
        return max
    end)
    
    --- Gets the player incoming heals
    Unit.Health.PlayerIncoming  = Unit:Watch("UNIT_HEAL_PREDICTION"):Map(_G.UnitGetIncomingHeals and function(unit) return UnitGetIncomingHeals(unit, "player") end or Toolset.fakefunc)

    --- Gets the total incoming heals
    Unit.Health.TotalIncoming   = Unit:Watch("UNIT_HEAL_PREDICTION"):Map(_G.UnitGetIncomingHeals or Toolset.fakefunc)

    --- Gets the total absorbs
    Unit.Health.TotalAbsorb     = Unit:Watch("UNIT_ABSORB_AMOUNT_CHANGED"):Map(_G.UnitGetTotalAbsorbs or Toolset.fakefunc)

    --- Gets the total heal absorbs
    Unit.Health.TotalHealAbsorb = Unit:Watch("UNIT_HEAL_ABSORB_AMOUNT_CHANGED"):Map(_G.UnitGetTotalHealAbsorbs or Toolset.fakefunc)
end

------------------------------------------------------------
--                          Power                         --
------------------------------------------------------------
do
    --------------------------------------------------------
    --                       Helper                       --
    --------------------------------------------------------
    local _ClassPowerType, _ClassPowerToken, _PrevClassPowerType
    local SPEC_DEMONHUNTER_VENGENCE = 2
    local SOULFRAGMENT          = 203981
    local SOULFRAGMENTNAME    
    local STAGGER               = 100 -- DIFF to other class type    
    local FindAuraByName        = _G.AuraUtil.FindAuraByName
    local PowerType             = _G.Enum.PowerType
    
    _ClassPowerRefresh          = Subject()
    _ClassPowerSubject          = Subject()
    _ClassPowerMaxSubject       = Subject()

    _UnitPowerObservable        = Wow.FromEvent("UNIT_POWER_FREQUENT", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_POWER_BAR_SHOW", "UNIT_POWER_BAR_HIDE"):Next()
    _UnitMaxPowerObservable     = Wow.FromEvent("UNIT_CONNECTION", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_POWER_BAR_SHOW", "UNIT_POWER_BAR_HIDE"):Next()
    
    -- Power Type Scan Service
    NextEvent("PLAYER_LOGIN", function()
        -- Use the custom unit event to provide the API
        if _PlayerClass == "WARRIOR" then
    
        elseif _PlayerClass == "DEATHKNIGHT" then
            _ClassPowerToken    = "RUNES"
            _ClassPowerType     = PowerType.Runes
    
            while true do
                Continue(RefreshClassPower)
                NextEvent("PLAYER_SPECIALIZATION_CHANGED")
            end
    
        elseif _PlayerClass == "PALADIN" and PowerType.HolyPower then
            _ClassPowerToken    = "HOLY_POWER"
            _ClassPowerType     = PowerType.HolyPower
    
        elseif _PlayerClass == "MONK" then
            _ClassPowerToken    = "CHI"
    
            while true do
                local spec      = GetSpecialization()
                _ClassPowerType = spec == SPEC_MONK_WINDWALKER and PowerType.Chi or spec == SPEC_MONK_BREWMASTER and STAGGER or nil
                Continue(RefreshClassPower)
                NextEvent("PLAYER_SPECIALIZATION_CHANGED")
            end
    
        elseif _PlayerClass == "PRIEST" then
            _ClassPowerToken    = "MANA"
    
            while true do
                _ClassPowerType = GetSpecialization() == SPEC_PRIEST_SHADOW and PowerType.Mana or nil
                Continue(RefreshClassPower)
                NextEvent("PLAYER_SPECIALIZATION_CHANGED")
            end
    
        elseif _PlayerClass == "SHAMAN" then
            _ClassPowerToken    = "MANA"
    
            while true do
                _ClassPowerType = GetSpecialization() ~= SPEC_SHAMAN_RESTORATION and PowerType.Mana or nil
                Continue(RefreshClassPower)
                NextEvent("PLAYER_SPECIALIZATION_CHANGED")
            end
    
        elseif _PlayerClass == "DRUID" then
            _ClassPowerToken    = "COMBO_POINTS"
    
            while true do
                _ClassPowerType = GetShapeshiftFormID() == DRUID_CAT_FORM and PowerType.ComboPoints or nil
                Continue(RefreshClassPower)
                NextEvent("UPDATE_SHAPESHIFT_FORM")
            end
    
        elseif _PlayerClass == "ROGUE" then
            _ClassPowerToken    = "COMBO_POINTS"
            _ClassPowerType     = PowerType.ComboPoints
    
        elseif _PlayerClass == "MAGE" and Scorpio.IsRetail then
            _ClassPowerToken    = "ARCANE_CHARGES"
    
            while true do
                _ClassPowerType = GetSpecialization() == SPEC_MAGE_ARCANE and PowerType.ArcaneCharges or nil
                Continue(RefreshClassPower)
                NextEvent("PLAYER_SPECIALIZATION_CHANGED")
            end
    
        elseif _PlayerClass == "WARLOCK" and PowerType.SoulShards then
            _ClassPowerToken    = "SOUL_SHARDS"
            _ClassPowerType     = PowerType.SoulShards
    
        elseif _PlayerClass == "HUNTER" then
    
        elseif _PlayerClass == "DEMONHUNTER" then
            SOULFRAGMENTNAME    = GetSpellInfo(SOULFRAGMENT)
            _ClassPowerToken    = "DEMONHUNTER"
    
            while true do
                _ClassPowerType = GetSpecialization() == SPEC_DEMONHUNTER_VENGENCE and SOULFRAGMENT or nil
                Continue(RefreshClassPower)
                NextEvent("PLAYER_SPECIALIZATION_CHANGED")
            end
    
        elseif _PlayerClass == "EVOKER" then
            _ClassPowerToken    = "ESSENCE"
            _ClassPowerType     = PowerType.Essence
        end
    
        return RefreshClassPower()
    end)
    
    -- Refresh the class power
    function RefreshClassPower()
        if _ClassPowerType then
            if _PrevClassPowerType ~= _ClassPowerType then
                if _PrevClassPowerType then
                    _ClassPowerSubject.Subscription     = nil
                    _ClassPowerMaxSubject.Subscription  = nil
                end
    
                _PrevClassPowerType = _ClassPowerType
    
                if _ClassPowerType == SOULFRAGMENT then
                    Wow.FromEvent("UNIT_AURA"):MatchUnit("player"):Subscribe(_ClassPowerSubject)

                elseif _ClassPowerType == STAGGER then
                    Wow.FromEvent("UNIT_HEALTH"):MatchUnit("player"):Subscribe(_ClassPowerSubject)
                    Wow.FromEvent("UNIT_MAXHEALTH"):MatchUnit("player"):Subscribe(_ClassPowerMaxSubject)

                elseif _ClassPowerType == PowerType.Runes then
                    Wow.FromEvent("RUNE_POWER_UPDATE"):Map("=>'player'"):Subscribe(_ClassPowerSubject)

                else
                    Wow.FromEvent("UNIT_POWER_FREQUENT", "UNIT_POWER_POINT_CHARGE"):MatchUnit("player"):Subscribe(_ClassPowerSubject)
                    Wow.FromEvent("UNIT_MAXPOWER"):MatchUnit("player"):Subscribe(_ClassPowerMaxSubject)
                end
            end
        else
            _PrevClassPowerType = false
            _ClassPowerSubject.Subscription     = nil
            _ClassPowerMaxSubject.Subscription  = nil
        end
    
        -- Publish the changes
        _ClassPowerRefresh:OnNext("any")        -- For all, but other unit's indicator will be disabled and hide
        _ClassPowerSubject:OnNext("player")     -- For player only
        _ClassPowerMaxSubject:OnNext("player")
    end
    
    --------------------------------------------------------
    --                     Observable                     --
    --------------------------------------------------------
    --- Gets the unit class power, works for player only
    Unit.ClassPower             =  _PlayerClass == "DEATHKNIGHT" and Unit:Watch(_ClassPowerSubject):Map(function(unit) local count = 0 for i = 1, 6 do local _, _, ready = GetRuneCooldown(i) if ready then count = count + 1 end end return count end)
                                or _PlayerClass == "DEMONHUNTER" and Unit:Watch(_ClassPowerSubject):Map(function(unit) return _ClassPowerType and min((select(3, FindAuraByName(SOULFRAGMENTNAME, "player", "PLAYER|HELPFUL"))) or 0, 5) or 0 end)
                                or _PlayerClass == "MONK"        and Unit:Watch(_ClassPowerSubject):Map(function(unit) return (_ClassPowerType == STAGGER and UnitStagger(unit) or _ClassPowerType and UnitPower(unit, _ClassPowerType)) or 0 end)
                                or                                   Unit:Watch(_ClassPowerSubject):Map(function(unit) return _ClassPowerType and UnitPower(unit, _ClassPowerType) or 0 end)
    
    --- Gets the unit max class power, works for player only
    Unit.ClassPower.Max         =  _PlayerClass == "DEATHKNIGHT" and BehaviorSubject(6)
                                or _PlayerClass == "DEMONHUNTER" and BehaviorSubject(5)
                                or _PlayerClass == "MONK"        and Unit:Watch(_ClassPowerMaxSubject):Map(function(unit) return _ClassPowerType == STAGGER and UnitHealthMax(unit) or _ClassPowerType and UnitPowerMax(unit, _ClassPowerType) or 100 end)
                                or                                   Unit:Watch(_ClassPowerMaxSubject):Map(function(unit) return _ClassPowerType and UnitPowerMax(unit, _ClassPowerType) or 100 end)

    --- Gets the unit class power color
    Unit.ClassPower.Color       = _PlayerClass == "MONK" and Unit:Watch(_ClassPowerSubject):Map(function(unit)
                                    if _ClassPowerType and UnitIsUnit(unit, "player") then
                                        if _ClassPowerType == STAGGER then
                                            local curr          = UnitStagger(unit)
                                            local maxs          = UnitHealthMax(unit)
                                            if curr and maxs then
                                                local pct       = curr / max
                        
                                                if (pct >= STAGGER_RED_TRANSITION) then
                                                    return Color.RED
                                                elseif (pct >= STAGGER_YELLOW_TRANSITION) then
                                                    return Color.YELLOW
                                                else
                                                    return Color.GREEN
                                                end
                                            end
                                        else
                                            return Color[_ClassPowerToken]
                                        end
                                    end
                        
                                    return Color.DISABLED
                                end)
                                or Unit:Watch(_ClassPowerRefresh):Map(function(unit) return UnitIsUnit(unit, "player") and _ClassPowerType and Color[_ClassPowerToken] or Color.DISABLED end)
    
    --- Gets the unit class power visible
    Unit.ClassPower.Visible     = Unit:Watch(_ClassPowerRefresh):Map(function(unit) return UnitIsUnit(unit, "player") and _ClassPowerType and true or false end)
    
    --- Gets the unit power
    Unit.Power                  = Unit:Watch(_UnitPowerObservable):Map(function(unit) return UnitPower(unit, (UnitPowerType(unit))) end)

    --- Gets the unit max powr
    Unit.Power.Max              = Unit:Watch(_UnitMaxPowerObservable):Map(function(unit) return UnitPowerMax(unit, (UnitPowerType(unit))) end)

    --- Gets the unit power color
    local tColor                = {}
    Unit.Power.Color            = Unit:Watch(_UnitMaxPowerObservable):Map(function(unit)
                                    if not UnitIsConnected(unit) then
                                        return Color.RUNES
                                    else
                                        local ptype, ptoken, r, g, b = UnitPowerType(unit)
                                        local color     = ptoken and Color[ptoken]
                                        if color then return color end
                        
                                        if r then
                                            local rgb   = ("%.2x%.2x%.2x"):format(r * 255, g * 255, b * 255)
                                            color       = tColor[rgb]
                                            if not color then
                                                color   = { r = r, g = g, b = b }
                                                tColor[rgb] = color
                                            end

                                            return color
                                        end
                                    end
                                    return Color.MANA
                                end)
    
    --- Gets the unit mana
    Unit.Mana                   = Unit:Watch(_UnitPowerObservable):Map(function(unit) return UnitPower(unit, PowerType.MANA) end)
    
    --- Gets the unit max mana
    Unit.Mana.Max               = Unit:Watch(_UnitMaxPowerObservable):Map(function(unit) return UnitPowerMax(unit, PowerType.MANA) end)

    --- Gets the unit mana visible
    Unit.Mana.Visible           = Unit:Watch(_UnitMaxPowerObservable):Map(function(unit) return UnitPowerType(unit) ~= PowerType.MANA and (UnitPowerMax(unit, PowerType.MANA) or 0) > 0 end)
end

------------------------------------------------------------
--                          Cast                          --
------------------------------------------------------------
do
    --------------------------------------------------------
    --                       Helper                       --
    --------------------------------------------------------
    _CurrentCastID              = {}
    _CurrentCastEndTime         = {}

    _UnitCastSubject            = Subject()
    _UnitCastDelay              = Subject()
    _UnitCastInterruptible      = Subject()
    _UnitCastChannel            = Subject()

    __SystemEvent__()
    function UNIT_SPELLCAST_START(unit, castID)
        local n, _, t, s, e, _, _, i= UnitCastingInfo(unit)
        if not n then return end
        s, e                        = s / 1000, e / 1000

        _CurrentCastID[unit]        = castID
        _CurrentCastEndTime[unit]   = e

        _UnitCastChannel:OnNext(unit, false)
        _UnitCastSubject:OnNext(unit, n, t, s, e - s)
        _UnitCastDelay:OnNext(unit, 0)
        _UnitCastInterruptible:OnNext(unit, not i)
    end

    __SystemEvent__ "UNIT_SPELLCAST_FAILED" "UNIT_SPELLCAST_STOP" "UNIT_SPELLCAST_INTERRUPTED"
    function UNIT_SPELLCAST_FAILED(unit, castID)
        if _CurrentCastID[unit] and (not castID or castID == _CurrentCastID[unit]) then
            _UnitCastSubject:OnNext(unit, nil, nil, 0, 0)
            _UnitCastDelay:OnNext(unit, 0)
        end
    end

    __SystemEvent__()
    function UNIT_SPELLCAST_INTERRUPTIBLE(unit)
        if not _CurrentCastID[unit] then return end
        _UnitCastInterruptible:OnNext(unit, true)
    end

    __SystemEvent__()
    function UNIT_SPELLCAST_NOT_INTERRUPTIBLE(unit)
        if not _CurrentCastID[unit] then return end
        _UnitCastInterruptible:OnNext(unit, false)
    end

    __SystemEvent__()
    function UNIT_SPELLCAST_DELAYED(unit, castID)
        if _CurrentCastID[unit] and (not castID or castID == _CurrentCastID[unit]) then
            local n, _, t, s, e, _, _, i= UnitCastingInfo(unit)
            if not n then return end
            s, e                        = s / 1000, e / 1000

            _UnitCastSubject:OnNext(unit, n, t, s, e - s)
            if _CurrentCastEndTime[unit] then
                _UnitCastDelay:OnNext(unit, e - _CurrentCastEndTime[unit])
            end
        end
    end

    __SystemEvent__()
    function UNIT_SPELLCAST_CHANNEL_START(unit)
        local n, _, t, s, e, _, i   = UnitChannelInfo(unit)
        if not n then return end
        s, e                        = s / 1000, e / 1000

        _CurrentCastID[unit]        = nil
        _CurrentCastEndTime[unit]   = e

        _UnitCastChannel:OnNext(unit, true)
        _UnitCastSubject:OnNext(unit, n, t, s, e - s)
        _UnitCastDelay:OnNext(unit, 0)
        _UnitCastInterruptible:OnNext(unit, not i)
    end

    __SystemEvent__()
    function UNIT_SPELLCAST_CHANNEL_UPDATE(unit)
        local n, _, t, s, e         = UnitChannelInfo(unit)
        if not n then return end
        s, e                        = s / 1000, e / 1000

        _UnitCastSubject:OnNext(unit, n, t, s, e - s)
        if _CurrentCastEndTime[unit] then
            _UnitCastDelay:OnNext(unit, e - _CurrentCastEndTime[unit])
        end
    end

    __SystemEvent__()
    function UNIT_SPELLCAST_CHANNEL_STOP(unit)
        _UnitCastSubject:OnNext(unit, nil, nil, 0, 0)
        _UnitCastDelay:OnNext(unit, 0)
    end

    ------------------------------------------------------------
    --                    Classic Support                     --
    ------------------------------------------------------------
    if not Scorpio.IsRetail then
        local oUnitCastingInfo  = _G.UnitCastingInfo
        local oUnitChannelInfo  = _G.UnitChannelInfo

        function UnitCastingInfo(unit)
            local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, spellId = oUnitCastingInfo(unit)
            if type(spellId) == "boolean" then
                -- rollback
                _ENV.UnitCastingInfo = oUnitCastingInfo
                return oUnitCastingInfo(unit)
            end
            return name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, false, spellId
        end

        function UnitChannelInfo(unit)
            local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, spellId = oUnitChannelInfo(unit)
            if type(spellId) == "boolean" then
                -- rollback
                _ENV.UnitChannelInfo = oUnitChannelInfo
                return oUnitChannelInfo(unit)
            end
            return name, text, texture, startTimeMS, endTimeMS, isTradeSkill, false, spellId
        end
    end

    --------------------------------------------------------
    --                     Observable                     --
    --------------------------------------------------------
    --- Gets the unit cast event
    Unit.Cast                   = Unit:Watch(_UnitCastSubject)

    --- Gets the unit cast cooldown
    local shareCooldown         = { start = 0, duration = 0 }
    Unit.Cast.Cooldown          = Unit.Cast:Map(function(unit, name, icon, start, duration)
                                    if name then
                                        shareCooldown.start     = start
                                        shareCooldown.duration  = duration
                                    else
                                        -- Register the Unit Here
                                        _CurrentCastID[unit]    = 0
                                        shareCooldown.start     = 0
                                        shareCooldown.duration  = 0
                                    end
                                    return shareCooldown
                                end)

    --- Gets the unit cast name
    Unit.Cast.Name              = Unit.Cast:Map(function(unit, name) return name end)

    --- Gets the unit cast  icon
    Unit.Cast.Icon              = Unit.Cast:Map(function(unit, name, icon) return icon end)

    --- Gets whether the unit is casting channel spell
    Unit.Cast.Channel           = Unit:Watch(_UnitCastChannel):Map(function(unit, val) return val or false end)

    -- Gets whether the unit's casting is interruptible
    Unit.Cast.Interruptible     = Unit:Watch(_UnitCastInterruptible):Map(function(unit, val) return val or false end)

    --- Gets the unit cast delay
    Unit.Cast.Delay             = Unit:Watch(_UnitCastDelay):Map(function(unit, delay) return delay end)
end

------------------------------------------------------------
--                          Aura                          --
------------------------------------------------------------
do
    _AuraCache                  = {}
    _AuraFilter                 = { HELPFUL = 1, HARMFUL = 2, PLAYER = 3, RAID = 4, CANCELABLE = 5, NOT_CANCELABLE = 6, INCLUDE_NAME_PLATE_ONLY = 7, MAW = 8 }
    _UnitAuraSubject            = Subject()
    _UnitAuraDelaySubject       = Subject:Next():ToSubject()

    -- clear
    Wow.SCORPIO_UNIT_STOP_TRACKING_GUID:Subscribe(function(guid) _AuraCache[guid] = nil end)

    -- event handler
    if _G.C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID then
        __SystemEvent__()
        function UNIT_AURA(unit, updateInfo)
            local guid          = UnitGUID(unit)
            local map           = _GuidUnitMap[guid]
            if not map then return end -- no unit track

            if updateInfo and not updateInfo.isFullUpdate then
                local auras     = _AuraCache[guid]
                if not auras then return end -- wait for full scan

                if updateInfo.addedAuras ~= nil then
                    for _, aura in ipairs(updateInfo.addedAuras) do
                        auras[aura.auraInstanceID] = aura
                        -- Perform any setup tasks for this aura here.
                    end
                end

                if updateInfo.updatedAuraInstanceIDs ~= nil then
                    for _, auraInstanceID in ipairs(updateInfo.updatedAuraInstanceIDs) do
                        auras[auraInstanceID] = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
                        -- Perform any update tasks for this aura here.
                    end
                end

                if updateInfo.removedAuraInstanceIDs ~= nil then
                    for _, auraInstanceID in ipairs(updateInfo.removedAuraInstanceIDs) do
                        auras[auraInstanceID] = nil
                        -- Perform any cleanup tasks for this aura here.
                    end
                end
            else
                -- full update, wait for next
                _AuraCache[guid]= nil
            end

            return _UnitAuraSubject:OnNext(unit)
        end

        function scanForUnit(unit)
            local guid          = UnitGUID(unit)
            local auras         = _AuraCache[guid]
            if auras then return auras end

            auras               = {}
            _AuraCache[guid]    = auras

            local function HandleAura(aura)
                auras[aura.auraInstanceID] = aura
            end

            AuraUtil.ForEachAura("player", "HELPFUL", 16, HandleAura, true)
            AuraUtil.ForEachAura("player", "HARMFUL", 16, HandleAura, true)
        end
    else
        __SystemEvent__()
        function UNIT_AURA(unit)
            _AuraCache[UnitGUID(unit)] = nil
            return _UnitAuraSubject:OnNext(unit)
        end

        if _G.UnitAuraSlots then
            local function refreshAura(cache, unit, filter, auraIdx, continuationToken, ...)
                local singleSpellIDMap  = singleSpellID[filter]
                local singleSpellNameMap= singleSpellName[filter]

                for i = 1, select("#", ...) do
                    local slot          = select(i, ...)
                    local name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellId = UnitAuraBySlot(unit, slot)

                    if singleSpellIDMap[spellId] then
                        cache[spellId]  = auraIdx
                    end

                    if singleSpellNameMap[name] then
                        cache[name]     = auraIdx
                    end

                    auraIdx             = auraIdx + 1
                end

                return continuationToken and refreshAura(cache, unit, filter, auraIdx, UnitAuraSlots(unit, filter, 16, continuationToken))
            end

            function scanForUnit(cache, unit, filter)
                return refreshAura(cache, unit, filter, 1, UnitAuraSlots(unit, filter, 16))
            end

        else
            function scanForUnit(cache, unit, filter)
                local singleSpellIDMap  = singleSpellID[filter]
                local singleSpellNameMap= singleSpellName[filter]

                local auraIdx           = 1
                local name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellId = UnitAura(unit, auraIdx, filter)

                while name do
                    if singleSpellIDMap[spellId] then
                        cache[spellId]  = auraIdx
                    end

                    if singleSpellNameMap[name] then
                        cache[name]     = auraIdx
                    end

                    auraIdx             = auraIdx + 1
                    name, icon, count, dtype, duration, expires, caster, isStealable, nameplateShowPersonal, spellId = UnitAura(unit, auraIdx, filter)
                end
            end
        end
    end


    function passFilter(filter) return XList(filter:gmatch("[%w_]+")):Filter(function(a) return _AuraFilter[a] end):ToList():Sort(function(a, b) return auraFilter[a] < auraFilter[b] end):Join("|") end
end