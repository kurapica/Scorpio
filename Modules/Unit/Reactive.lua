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

                -- Unit event observer
                local obsEvent  = Observer(function(...) return observer:OnNext(...) end)

                -- Unit change observer
                local obsUnit   = Observer(function(unit)
                    obsEvent.Subscription = Subscription(subscription)

                    -- Check trackable unit
                    local runit = unit and GetUnitFromGUID(UnitGUID(unit)) or unit
                    if runit then unitEvent:MatchUnit(runit):Subscribe(obsEvent) end

                    -- Push the unit
                    return observer:OnNext(unit)
                end)

                -- Start the unit watching
                unitSub:Subscribe(obsUnit, subscription)
            end)

            unitFrameObservable[unitEvent] = observable
        end

        return observable
    end

    --- Gets the unit owner
    function GetUnitOwner(unit)
        return unit and (unit:match("^[pP][eE][tT]$") and "player" or unit:gsub("[pP][eE][tT]", "")) or nil
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
    Unit.NameWithServer         = Unit:Map(function(unit)
        local name, server      = GetUnitName(unit, true)
        return name and server and (name .. "-" .. server) or name
    end)

    --- Gets the unit class color
    Unit.Color                  = Unit:Map(function(unit)
        local _, cls            = UnitClass(unit)
        return Color[cls or "PALADIN"]
    end)

    --- Gets the npc unit color with faction and threat status
    local scolor                = Color(1, 1, 1) -- share since lua is single thread
    Unit.ExtendColor            = Unit:Watch("UNIT_FACTION", "UNIT_THREAT_SITUATION_UPDATE"):Map(function(unit)
        if not UnitIsPlayer(unit) then
            if UnitIsTapDenied(unit) then return Color.RUNES end

            if withThreat and UnitCanAttack("player", unit) then
                local threat    = UnitThreatSituation("player", unit)
                if threat and threat > 0 then
                    scolor.r, scolor.g, scolor.b = GetThreatStatusColor(threat)
                    return scolor
                end
            end

            scolor.r, scolor.g, scolor.b = UnitSelectionColor(unit, true)
            return scolor
        end
        local _, cls            = UnitClass(unit)
        return Color[cls or "PALADIN"]
    end)

    --- Gets the unit level
    Unit.Level                  = Unit:Watch(Wow.FromEvent("PLAYER_LEVEL_UP"):Map(function(level) return "player", level end))
        :Map(UnitBattlePetLevel and function(unit, level)
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
    Unit.LevelColor             = Unit:Map(function(unit) return UnitCanAttack("player", unit) and GetQuestDifficultyColor(UnitLevel(unit) or 99) or Color.NORMAL end)

    --- Gets the unit's classification
    Unit.Classification         = Unit:Watch("UNIT_CLASSIFICATION_CHANGED"):Map(UnitClassification)

    --- Gets the unit's classification color
    Unit.ClassificationColor    = Unit.Classification:Map(function(class)
        if class == "elite" then
            return Color.YELLOW
        elseif class == "rare" then
            return Color.WHITE
        elseif class == "rareelite" then
            return Color.CYAN
        elseif class == "worldboss" then
            return Color.RAGE
        else
            return Color.NORMAL
        end
    end)

    --- Gets the unit's disconnected
    Unit.Disconnected           = Unit:Watch("UNIT_HEALTH", "UNIT_CONNECTION"):Map(function(unit) return not UnitIsConnected(unit) end)

    --- Gets the unit is target
    Unit.IsTarget               = Unit:Watch(Wow.FromEvent("PLAYER_TARGET_CHANGED"):Map("=>'any'")):Map(function(unit) return UnitIsUnit(unit, "target") end)

    --- Gets the unit is player
    Unit.IsPlayer               = Unit:Map(function(unit) return UnitIsUnit(unit, "player") end)

    --- Whether the player is in combat
    Unit.InCombat               = Wow.FromEvent("PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED"):Map(function() return UnitAffectingCombat("player") or false end):ToSubject(BehaviorSubject)

    --- Whether the unit is resurrect
    resurrectSubject            = Subject()
    Wow.FromEvent("INCOMING_RESURRECT_CHANGED"):Next():Subscribe(function(unit)
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
    Unit.RaidTargetIndex        = Unit:Watch(Wow.FromEvent("RAID_TARGET_UPDATE"):Map("=>'any'")):Map(GetRaidTargetIndex)

    --- Gets the unit's threat level
    Unit.ThreatLevel             = Unit:Watch("UNIT_THREAT_SITUATION_UPDATE"):Map(function(unit)
        return UnitIsPlayer(unit) and UnitThreatSituation(unit) or 0
    end)

    --- Gets the unit's group roster
    roleSubject                 = Wow.FromEvent("GROUP_ROSTER_UPDATE", "PLAYER_ROLES_ASSIGNED", "PARTY_LEADER_CHANGED"):Map("=>'any'"):Debounce(0.5):ToSubject()
    Unit.GroupRoster            = Unit:Watch(roleSubject):Map(function(unit)
        if IsInRaid() and not UnitHasVehicleUI(unit) then
            if GetPartyAssignment('MAINTANK', unit) then
                return "MAINTANK"
            elseif GetPartyAssignment('MAINASSIST', unit) then
                return "MAINASSIST"
            else
                return "NONE"
            end
        else
            return "NONE"
        end
    end)

    --- Gets the unit's group roster visibility
    Unit.GroupRosterVisible     = Unit.GroupRoster:Map(function(assign) return assign and assign ~= "NONE" or false end)

    --- Gets the unit's role
    Unit.Role                   = Unit:Watch(roleSubject):Map(UnitGroupRolesAssigned or Toolset.fakefunc)

    --- Gets the unit role's visibility
    Unit.RoleVisible            = Unit.Role:Map(function(role) return role and role ~= "NONE" or false end)

    --- Gets whether the unit is leader
    Unit.IsLeader               = Unit:Watch(roleSubject):Map(function(unit) return (UnitInParty(unit) or UnitInRaid(unit)) and UnitIsGroupLeader(unit) or false end)

    --- Gets whether the unit is in range of the player
    Unit.InRange                = Unit.Timer:Map(function(unit) return UnitExists(unit) and (UnitIsUnit(unit, "player") or not (UnitInParty(unit) or UnitInRaid(unit)) or UnitInRange(unit)) end)
end

------------------------------------------------------------
--                       Unit Owner                       --
------------------------------------------------------------
do
    --- Gets the unit's owner
    Unit.Owner                  = Unit:Map(GetUnitOwner)

    --- Gets the unit's owner name
    Unit.OwnerName              = Unit:Map(function(unit)
        local owner             = GetUnitOwner(unit)
        return owner and GetUnitName(owner) or nil
    end)

    --- Gets the unit's owner name with server
    Unit.OwnerNameWithServer    = Unit:Map(function(unit)
        local name, server      = GetUnitName(GetUnitOwner(unit), true)
        return name and server and (name .. "-" .. server) or name
    end)

    --- Gets the unit's owner class color
    Unit.OwnerColor             = Unit:Map(function(unit)
        local _, cls            = UnitClass(GetUnitOwner(unit))
        return Color[cls or "PALADIN"]
    end)

    --- Gets the unit owner's role
    Unit.OwnerRole              = Unit:Watch(roleSubject):Map(GetUnitOwner):Map(UnitGroupRolesAssigned or Toolset.fakefunc)

    --- Gets whether the unit's owner is in range or the player
    Unit.OwnerInRange           = Unit.Timer:Map(function(unit) unit = GetUnitOwner(unit) return UnitExists(unit) and (UnitIsUnit(unit, "player") or not (UnitInParty(unit) or UnitInRaid(unit)) or UnitInRange(GetUnitOwner(unit))) end)
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

    --- Gets the unit's ready check visibility
    Unit.ReadyCheckVisible      = Unit:Watch(_ReadyCheckVisibleSubject):Map(function(unit) return _ReadyChecking > 0 and UnitGUID(unit) ~= nil end)

    --- Gets the unit's ready check status
    Unit.ReadyCheck             = Unit:Watch(_ReadyCheckConfirmSubject):Map(function(unit)
        if _ReadyChecking == 0 then return end

        local guid              = UnitGUID(unit)
        if not guid then return "notready" end

        local state             = GetReadyCheckStatus(unit) or _ReadyCheckCache[guid]
        _ReadyCheckCache[guid]  = state
        return _ReadyChecking == 2 and state == "waiting" and "notready" or state
    end)
end

------------------------------------------------------------
--                         Health                         --
------------------------------------------------------------
do
    --------------------------------------------------------
    --                       Helper                       --
    --------------------------------------------------------
    _PlayerClass                = select(2, UnitClass("player"))
    _DISPELLABLE                = ({
        ["MAGE"]                = { Curse   = Color.CURSE, },
        ["DRUID"]               = { Poison  = Color.POISON, Curse   = Color.CURSE,   Magic = Color.MAGIC },
        ["PALADIN"]             = { Poison  = Color.POISON, Disease = Color.DISEASE, Magic = Color.MAGIC },
        ["PRIEST"]              = { Disease = Color.DISEASE,Magic   = Color.MAGIC },
        ["SHAMAN"]              = { Curse   = Color.CURSE,  Magic   = Color.MAGIC },
        ["WARLOCK"]             = { Magic   = Color.MAGIC, },
        ["MONK"]                = { Poison  = Color.POISON, Disease = Color.DISEASE, Magic = Color.MAGIC },
        ["EVOKER"]              = { Poison  = Color.POISON, Disease = Color.DISEASE, Curse = Color.Curse },
    })[_PlayerClass] or false
    
    _UnitHealthMap              = {}
    _FixUnitMaxHealth           = {}
    
    _UnitHealthSubject          = Subject()
    _UnitMaxHealthSubject       = Subject()
    
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
    
    __SystemEvent__()
    function PLAYER_ENTERING_WORLD()
        wipe(_UnitHealthMap)
    end

    __SystemEvent__()
    function SCORPIO_UNIT_STOP_TRACKING_GUID(guid)
        _UnitHealthMap[guid]    = nil
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
    Unit.HealthLost             = Unit:Watch(_UnitHealthSubject):Map(function(unit)
        local max               = UnitHealthMax(unit)
        local health            = _UnitHealthMap[UnitGUID(unit)] or UnitHealth(unit)
        if max == 0 or max < health then
            RegisterFixUnitMaxHealth(unit)
            return 0
        end
        return max - health
    end)
        
    --- Gets the unit health percent
    Unit.HealthPercent          = Unit:Watch(_UnitHealthSubject):Map(function(unit)
        local health            = UnitHealth(unit)
        local max               = _UnitHealthMap[UnitGUID(unit)] or UnitHealth(unit)
        if max == 0 or max < health then
            RegisterFixUnitMaxHealth(unit)
            return 100
        end
        return floor(0.5 + health / max * 100)
    end)

    --- Gets the unit max health
    Unit.HealthMax              = Unit:Watch(_UnitMaxHealthSubject):Map(function(unit)
        local max               = UnitHealthMax(unit)
        if max == 0 then
            RegisterFixUnitMaxHealth(unit)
            max                 = _UnitHealthMap[UnitGUID(unit)] or UnitHealth(unit)
        end
        return max
    end)

    --- Gets the unit min-max health
    local healthMinMax          = { min = 0 }
    Unit.HealthMinMax           = Unit:Watch(_UnitMaxHealthSubject):Map(function (unit)
        local max               = UnitHealthMax(unit)
        if max == 0 then
            RegisterFixUnitMaxHealth(unit)
            max                 = _UnitHealthMap[UnitGUID(unit)] or UnitHealth(unit)
        end
        healthMinMax.max        = max
        return healthMinMax
    end)
    
    --- Gets the health prediction
    Unit.HealthPrediction        = Unit:Watch(Wow.FromEvent("UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_HEAL_PREDICTION", "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_HEAL_ABSORB_AMOUNT_CHANGED"):Next())
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
    
        elseif _PlayerClass == "PRIEST" and Scorpio.IsRetail then
            _ClassPowerToken    = "MANA"
    
            while true do
                _ClassPowerType = GetSpecialization() == SPEC_PRIEST_SHADOW and PowerType.Mana or nil
                Continue(RefreshClassPower)
                NextEvent("PLAYER_SPECIALIZATION_CHANGED")
            end
    
        elseif _PlayerClass == "SHAMAN" and Scorpio.IsRetail then
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
    
        elseif _PlayerClass == "WARLOCK" and Scorpio.IsRetail then
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
                                or _PlayerClass == "MONK" and Unit:Watch(_ClassPowerSubject):Map(function(unit) return (_ClassPowerType == STAGGER and UnitStagger(unit) or _ClassPowerType and UnitPower(unit, _ClassPowerType)) or 0 end)
                                or Unit:Watch(_ClassPowerSubject):Map(function(unit) return _ClassPowerType and UnitPower(unit, _ClassPowerType) or 0 end)
    
    --- Gets the unit max class power, works for player only
    Unit.ClassPowerMax          = _PlayerClass == "DEATHKNIGHT" and Unit:Watch(_ClassPowerMaxSubject):Map(function() return 6 end)
                                or _PlayerClass == "DEMONHUNTER" and Unit:Watch(_ClassPowerMaxSubject):Map(function(unit) return 5 end)
                                or _PlayerClass == "MONK" and Unit:Watch(_ClassPowerMaxSubject):Map(function(unit) return _ClassPowerType == STAGGER and UnitHealthMax(unit) or _ClassPowerType and UnitPowerMax(unit, _ClassPowerType) or 100 end)
                                or Unit:Watch(_ClassPowerMaxSubject):Map(function(unit) return _ClassPowerType and UnitPowerMax(unit, _ClassPowerType) or 100 end)
    
    --- Gets the unit min max class power, works for player only
    local classPowerMinMax      = { min = 0, max = _PlayerClass == "DEATHKNIGHT" and 6 or _PlayerClass == "DEMONHUNTER" and 5 or 100 }
    Unit.ClassPowerMinMax       = (_PlayerClass == "DEATHKNIGHT" or _PlayerClass == "DEMONHUNTER") and Unit:Watch(_ClassPowerMaxSubject):Map(function() return minMax end)
                                or _PlayerClass == "MONK" and Unit:Watch(_ClassPowerMaxSubject):Map(function(unit)
                                    classPowerMinMax.max  = _ClassPowerType == STAGGER and UnitHealthMax(unit) or _ClassPowerType and UnitPowerMax(unit, _ClassPowerType) or 100
                                    return classPowerMinMax
                                end)
                                or Unit:Watch(_ClassPowerMaxSubject):Map(function(unit)
                                    classPowerMinMax.max  = _ClassPowerType and UnitPowerMax(unit, _ClassPowerType) or 100
                                    return classPowerMinMax
                                end)
    
    --- Gets the unit class power color
    Unit.ClassPowerColor        = _PlayerClass == "MONK" and Unit:Watch(_ClassPowerSubject):Map(function(unit)
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
    Unit.ClassPowerVisible    = Unit:Watch(_ClassPowerRefresh):Map(function(unit) return UnitIsUnit(unit, "player") and _ClassPowerType and true or false end)
    
    --- Gets the unit power
    Unit.Power                  = Unit:Watch(_UnitPowerObservable):Map(function(unit) return UnitPower(unit, (UnitPowerType(unit))) end)

    --- Gets the unit max powr
    Unit.PowerMax               = Unit:Watch(_UnitMaxPowerObservable):Map(function(unit) return UnitPowerMax(unit, (UnitPowerType(unit))) end)

    --- Gets the unit min max power
    local powerMinMax           = { min = 0 }
    Unit.PowerMinMax            = Unit.PowerMax:Map(function(max) powerMinMax.max = max return powerMinMax end)
    
    --- Gets the unit power color
    local powerColor            = Color(1, 1, 1)
    Unit.PowerColor             = Unit:Watch(_UnitMaxPowerObservable):Map(function(unit)
                                    if not UnitIsConnected(unit) then
                                        powerColor.r    = 0.5
                                        powerColor.g    = 0.5
                                        powerColor.b    = 0.5
                                    else
                                        local ptype, ptoken, r, g, b = UnitPowerType(unit)
                                        local color     = ptoken and Color[ptoken]
                                        if color then return color end
                        
                                        if r then
                                            powerColor.r= r
                                            powerColor.g= g
                                            powerColor.b= b
                                        else
                                            return Color.MANA
                                        end
                                    end
                        
                                    return powerColor
                                end)
    
    --- Gets the unit mana
    Unit.Mana                   = Unit:Watch(_UnitPowerObservable):Map(function(unit) return UnitPower(unit, PowerType.MANA) end)
    
    --- Gets the unit max mana
    Unit.ManaMax                = Unit:Watch(_UnitMaxPowerObservable):Map(function(unit) return UnitPowerMax(unit, PowerType.MANA) end)

    --- Gets the unit min max mana
    Unit.ManaMinMax             = Unit.ManaMax:Map(function(max) powerMinMax.max = max return powerMinMax end)
                                
    --- Gets the unit mana visible
    Unit.ManaVisible            = Unit:Watch(_UnitMaxPowerObservable):Map(function(unit) return UnitPowerType(unit) ~= PowerType.MANA and (UnitPowerMax(unit, PowerType.MANA) or 0) > 0 end)
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
    --- Gets the unit cast cooldown
    local shareCooldown         = { start = 0, duration = 0 }
    Unit.CastCooldown           = Unit:Watch(_UnitCastSubject):Map(function(unit, name, icon, start, duration)
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

    --- Gets whether the unit is casting channel spell
    Unit.CastChannel            = Unit:Watch(_UnitCastChannel):Map(function(unit, val) return val or false end)

    -- Gets whether the unit's casting is interruptible
    Unit.CastInterruptible      = Unit:Watch(_UnitCastInterruptible):Map(function(unit, val) return val or false end)

    --- Gets the unit cast name
    Unit.CastName               = Unit:Watch(_UnitCastSubject):Map(function(unit, name) return name end)

    --- Gets the unit cast  icon
    Unit.CastIcon               = Unit:Watch(_UnitCastSubject):Map(function(unit, name, icon) return icon end)

    --- Gets the unit cast delay
    Unit.CastDelay              = Unit:Watch(_UnitCastDelay):Map(function(unit, delay) return delay end)
end

------------------------------------------------------------
--                          Aura                          --
------------------------------------------------------------
do
    

    __SystemEvent__()
    function UNIT_AURA(unit, updateInfo)
        if updateInfo and not updateInfo.isFullUpdate then
            local guid              = UnitGUID(unit)

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

        end
    end
end