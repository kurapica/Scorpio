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
    
    _UnitGUIDMap                = {}
    _UnitHealthMap              = {}
    _FixUnitMaxHealth           = {}
    
    _UnitHealthSubject          = Subject()
    _UnitMaxHealthSubject       = Subject()

    _UnitInstantHealthObservable= Observable(function(observer, subscription)
        local unitSub           = GetUnitFrameSubject()
        if not unitSub  then return _UnitHealthSubject:Subscribe(observer, subscription) end

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
    
    function RegisterFrequentHealthUnit(unit, guid, health)
        local oguid             = _UnitGUIDMap[unit]
        if oguid == guid then return end
    
        -- update ref count
        _UnitGUIDMap[unit]      = guid
        if guid then
            _UnitHealthMap[guid]= health
            _UnitGUIDMap[guid]  = (_UnitGUIDMap[guid] or 0) + 1
        end
    
        if oguid and _UnitGUIDMap[oguid] then
            _UnitGUIDMap[oguid] = _UnitGUIDMap[oguid] - 1
    
            -- clear
            if _UnitGUIDMap[oguid] <= 0 then
                _UnitGUIDMap[oguid] = nil
                _UnitHealthMap[oguid] = nil
            end
        end
    end
    
    __CombatEvent__ "SWING_DAMAGE" "RANGE_DAMAGE" "SPELL_DAMAGE" "SPELL_PERIODIC_DAMAGE" "DAMAGE_SPLIT" "DAMAGE_SHIELD" "ENVIRONMENTAL_DAMAGE" "SPELL_HEAL" "SPELL_PERIODIC_HEAL"
    function COMBAT_HEALTH_CHANGE(_, event, _, _, _, _, _, destGUID, _, _, _, arg12, arg13, arg14, arg15, arg16)
        local health            = _UnitHealthMap[destGUID]
        if not health then return end
    
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
            local unit          = GetUnitFromGUID(destGUID)
            if not unit then
                _UnitGUIDMap[destGUID]  = nil
                _UnitHealthMap[destGUID]= nil
                return
            end
    
            local max           = UnitHealthMax(unit)
            if health > max then health = max end
        end
        _UnitHealthMap[destGUID]= health
    
        -- Distribute the new health
        for unit in GetUnitsFromGUID(destGUID) do
            _UnitHealthSubject:OnNext(unit)
        end
    end
    
    __CombatEvent__ "UNIT_DIED" "UNIT_DESTROYED" "UNIT_DISSIPATES"
    function COMBAT_UNIT_DIED(_, _, _, _, _, _, _, destGUID)
        for unit in Scorpio.GetUnitsFromGUID(destGUID) do
            Delay(0.3, FireSystemEvent, "UNIT_HEALTH", unit)
        end
    end
    
    __SystemEvent__()
    function PLAYER_ENTERING_WORLD()
        -- Clear the Registered Units
        wipe(_UnitGUIDMap)
        wipe(_UnitHealthMap)
    end

    __SystemEvent__()
    function SCORPIO_UNIT_STOP_TRACKING_GUID(guid)
        _UnitHealthMap[guid]    = nil
    end
    
    __SystemEvent__("UNIT_HEALTH", "UNIT_HEALTH_FREQUENT")
    function UNIT_HEALTH(unit)
        local guid              = UnitGUID(unit)
        if _UnitHealthMap[guid] then
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
    Unit.Health                 = Unit:Watch(_UnitHealthSubject):Map(UnitHealth)
    
    --- Gets the unit lost health
    Unit.LostHealth             = Unit:Watch(_UnitHealthSubject):Map(function(unit)
        local max               = UnitHealthMax(unit)
        local health            = UnitHealth(unit)
        if max == 0 or max < health then
            RegisterFixUnitMaxHealth(unit)
            return 0
        end
        return max - health
    end)

    --- Gets the unit health with combat event fix
    Unit.InstantHealth          = Unit:Watch(_UnitHealthSubject):Map(function(unit)
        local guid          = UnitGUID(unit)
        local health        = _UnitHealthMap[guid]
        if health and _UnitGUIDMap[unit] == guid then return health end

        -- Register the unit
        health              = health or UnitHealth(unit)
        RegisterFrequentHealthUnit(unit, guid, health)
        return health
    end)
        
    __Static__() __AutoCache__()
    function Wow.UnitHealthLostFrequent()
        -- Based on the CLEU
        return Wow.FromNextUnitEvent(_UnitHealthSubject):Map(function(unit)
            local max           = UnitHealthMax(unit)
            local guid          = UnitGUID(unit)
            local health        = _UnitHealthMap[guid]
    
            if not (health and _UnitGUIDMap[unit] == guid) then
                -- Register the unit
                health          = health or UnitHealth(unit)
                RegisterFrequentHealthUnit(unit, guid, health)
            end
    
            if max == 0 or max < health then
                RegisterFixUnitMaxHealth(unit)
                return 0
            end
            return max - health
        end)
    end
    
    __Static__() __AutoCache__()
    function Wow.UnitHealthPercent()
        return Wow.FromNextUnitEvent(_UnitHealthSubject):Map(function(unit)
            local health        = UnitHealth(unit)
            local max           = UnitHealthMax(unit)
    
            if max == 0 or max < health then
                RegisterFixUnitMaxHealth(unit)
                return 100
            end
    
            return floor(0.5 + health / max * 100)
        end)
    end
    
    __Static__() __AutoCache__()
    function Wow.UnitHealthPercentFrequent()
        -- Based on the CLEU
        return Wow.FromNextUnitEvent(_UnitHealthSubject):Map(function(unit)
            local guid          = UnitGUID(unit)
            local health        = _UnitHealthMap[guid]
    
            if not (health and _UnitGUIDMap[unit] == guid) then
                -- Register the unit
                health          = health or UnitHealth(unit)
                RegisterFrequentHealthUnit(unit, guid, health)
            end
    
            local max           = UnitHealthMax(unit)
    
            if max == 0 or max < health then
                RegisterFixUnitMaxHealth(unit)
                return 100
            end
    
            return floor(0.5 + health / max * 100)
        end)
    end
    
    __Static__() __AutoCache__()
    function Wow.UnitHealthLostPercentFrequent()
        -- Based on the CLEU
        return Wow.FromNextUnitEvent(_UnitHealthSubject):Map(function(unit)
            local guid          = UnitGUID(unit)
            local health        = _UnitHealthMap[guid]
    
            if not (health and _UnitGUIDMap[unit] == guid) then
                -- Register the unit
                health          = health or UnitHealth(unit)
                RegisterFrequentHealthUnit(unit, guid, health)
            end
    
            local max           = UnitHealthMax(unit)
    
            if max == 0 or max < health then
                RegisterFixUnitMaxHealth(unit)
                return 0
            end
    
            return floor(0.5 + (max - health) / max * 100)
        end)
    end
    
    __Static__() __AutoCache__()
    function Wow.UnitHealthMax()
        local minMax            = { min = 0 }
        return Wow.FromUnitEvent(_UnitMaxHealthSubject):Map(function(unit)
            local health        = UnitHealth(unit)
            local max           = UnitHealthMax(unit)
    
            if max == 0 or max < health then
                RegisterFixUnitMaxHealth(unit)
                max             = health
            end
    
            minMax.max          = max
            return minMax
        end)
    end
    
    __Static__() __AutoCache__() -- Too complex to do it here, leave it to the indicators or map chains
    function Wow.UnitHealPrediction()
        return Wow.FromUnitEvent("UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_HEAL_PREDICTION", "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_HEAL_ABSORB_AMOUNT_CHANGED"):Next()
    end
    
    __Arguments__{ (ColorType + Boolean)/nil, ColorType/nil }
    __Static__()
    function Wow.UnitConditionColor(useClassColor, smoothEndColor)
        local defaultColor      = type(useClassColor) == "table" and useClassColor or Color.GREEN
        useClassColor           = useClassColor == true
    
        if smoothEndColor then
            local cache         = Color{ r = 1, g = 1, b = 1 }
            local br, bg, bb    = smoothEndColor.r, smoothEndColor.g, smoothEndColor.b
    
            if _DISPELLABLE then
                return Wow.FromUnitEvent("UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_AURA"):Next():Map(function(unit)
                    local index = 1
                    repeat
                        local n, _, _, d = UnitAura(unit, index, "HARMFUL")
                        local color = _DISPELLABLE[d]
                        if color then return color end
                        index   = index + 1
                    until not n
    
                    local health= UnitHealth(unit)
                    local maxHealth = UnitHealthMax(unit)
                    local pct   = health >= maxHealth and 1 or health / maxHealth
                    local dcolor= defaultColor
    
                    if useClassColor then
                        local _, cls= UnitClass(unit)
                        if cls then dcolor = Color[cls] end
                    end
    
                    cache.r     = br + (dcolor.r - br) * pct
                    cache.g     = bg + (dcolor.g - bg) * pct
                    cache.b     = bb + (dcolor.b - bb) * pct
    
                    return cache
                end)
            else
                return Wow.FromNextUnitEvent(_UnitHealthSubject):Map(function(unit)
                    local health= _UnitHealthMap[unit] or UnitHealth(unit)
                    local maxHealth = UnitHealthMax(unit)
                    local pct   = health >= maxHealth and 1 or health / maxHealth
                    local dcolor= defaultColor
    
                    if useClassColor then
                        local _, cls= UnitClass(unit)
                        if cls then dcolor = Color[cls] end
                    end
    
                    cache.r     = br + (dcolor.r - br) * pct
                    cache.g     = bg + (dcolor.g - bg) * pct
                    cache.b     = bb + (dcolor.b - bb) * pct
    
                    return cache
                end)
            end
        else
            if _DISPELLABLE then
                return Wow.FromUnitEvent("UNIT_AURA"):Next():Map(function(unit)
                    local index = 1
                    repeat
                        local n, _, _, d = UnitAura(unit, index, "HARMFUL")
                        local color = _DISPELLABLE[d]
                        if color then return color end
                        index   = index + 1
                    until not n
    
                    local dcolor= defaultColor
    
                    if useClassColor then
                        local _, cls= UnitClass(unit)
                        if cls then dcolor = Color[cls] end
                    end
                    return dcolor
                end)
            else
                return Wow.FromUnitEvent():Map(function(unit)
                    local dcolor= defaultColor
    
                    if useClassColor then
                        local _, cls= UnitClass(unit)
                        if cls then dcolor = Color[cls] end
                    end
                    return dcolor
                end)
            end
        end
    end    
end

------------------------------------------------------------
--                          Power                         --
------------------------------------------------------------
do

end

------------------------------------------------------------
--                          Cast                          --
------------------------------------------------------------
do
end