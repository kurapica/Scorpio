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
    function getUnitFrameSubject()
        -- Gets the current unit frame
        local indicator         = getCurrentTarget()
        if not (indicator and isUIObject(indicator)) then return end
        while indicator and not isObjectType(indicator, IUnitFrame) do
            indicator           = indicator:GetParent()
        end
    
        -- gets the unit subject
        return indicator and indicator.Subject
    end

    --- Combine unit observable and unit event observable
    function genUnitFrameObservable(unitEvent)
        local observable        = unitFrameObservable[unitEvent]

        if not observable then
            observable          = Observable(function(observer, subscription)
                local unitSubject = getUnitFrameSubject()
                if not unitSubject then return unitEvent and unitEvent:Subscribe(observer, subscription) end

                -- Unit event observer
                local obsEvent  = Observer(function(...) return observer:OnNext(...) end)

                -- Unit change observer
                local obsUnit   = Observer(function(unit)
                    obsEvent.Subscription = Subscription(subscription)

                    -- Check trackable unit
                    local runit = unit and GetUnitFromGUID(UnitGUID(unit))
                    if runit then unitEvent:MatchUnit(runit):Subscribe(obsEvent) end

                    -- Push the unit
                    return observer:OnNext(unit)
                end)

                -- Start the unit watching
                unitSubject:Subscribe(obsUnit, subscription)
            end)

            unitFrameObservable[unitEvent] = observable
        end

        return observable
    end

    --- Gets the unit owner
    function getUnitOwner(unit)
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
        return genUnitFrameObservable(FromEvent(observable, ...))
    else
        return genUnitFrameObservable(observable)
    end
end

------------------------------------------------------------
--                    Scorpio Wow Unit                    --
------------------------------------------------------------
--- Gets the unit observable and the unit data container
Scorpio.Wow.Unit                = reactive {
    --- No deep subscription for Unit, override the default subscription
    Subscribe                   = function (self, ...)
        local subject           = getUnitFrameSubject()
        if not subject then return end
        return subject:Subscribe(...)
    end,
}

------------------------------------------------------------
--              Scorpio Wow Unit Observable               --
------------------------------------------------------------
do
    Unit                        = Scorpio.Wow.Unit
    
    --- Gets a timer to refresh
    Unit.Timer                  = Wow.FromUnitEvent(Observable.Interval(0.5):Map("=>'any'"))

    --- Gets the unit's name
    Unit.Name                   = Unit:Map(GetUnitName)

    --- Gets the unit's owner
    Unit.Owner                  = Unit:Map(getUnitOwner)

    --- Gets the unit's name with server
    Unit.NameWithServer         = Unit:Map(function(unit)
        local name, server      = GetUnitName(unit, true)
        return name and server and (name .. "-" .. server) or name
    end)

    --- Gets the unit's owner name
    Unit.OwnerName              = Unit:Map(function(unit)
        local owner             = getUnitOwner(unit)
        return owner and GetUnitName(owner) or nil
    end)

    --- Gets the unit's owner name with server
    Unit.OwnerNameWithServer    = Unit:Map(function(unit)
        local name, server      = GetUnitName(getUnitOwner(unit), true)
        return name and server and (name .. "-" .. server) or name
    end)

    --- Gets the unit class color
    Unit.Color                  = Unit:Map(function(unit)
        local _, cls            = UnitClass(unit)
        return Color[cls or "PALADIN"]
    end)

    --- Gets the unit's owner class color
    Unit.OwnerColor             = Unit:Map(function(unit)
        local _, cls            = UnitClass(getUnitOwner(unit))
        return Color[cls or "PALADIN"]
    end)

    --- Gets the npc unit color with faction and threat status
    local scolor                = Color(1, 1, 1) -- share since lua is single thread
    Unit.ExtendColor            = Wow.FromUnitEvent("UNIT_FACTION", "UNIT_THREAT_SITUATION_UPDATE"):Map(function(unit)
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
    Unit.Level                  = Wow.FromUnitEvent(Wow.FromEvent("PLAYER_LEVEL_UP"):Map(function(level) return "player", level end))
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
    Unit.Classification         = Wow.FromUnitEvent("UNIT_CLASSIFICATION_CHANGED"):Map(UnitClassification)

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
    Unit.Disconnected           = Wow.FromUnitEvent("UNIT_HEALTH", "UNIT_CONNECTION"):Next()
        :Map(function(unit) return not UnitIsConnected(unit) end)

    --- Gets the unit is target
    Unit.IsTarget               = Wow.FromUnitEvent(Wow.FromEvent("PLAYER_TARGET_CHANGED"):Map("=>'any'")):Map(function(unit) return UnitIsUnit(unit, "target") end)

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
                while UnitHasIncomingResurrection(unit) do Delay(1) end
                resurrectSubject:OnNext(unit)
            end)
        end
    end)
    Unit.IsResurrect            = Wow.FromUnitEvent(resurrectSubject):Map(UnitHasIncomingResurrection)

    --- Gets the unit's raid target index
    Unit.RaidTargetIndex        = Wow.FromUnitEvent(Wow.FromEvent("RAID_TARGET_UPDATE"):Map("=>'any'")):Map(GetRaidTargetIndex)

    --- Gets the unit's threat level
    Unit.ThreatLevel             = Wow.FromUnitEvent("UNIT_THREAT_SITUATION_UPDATE"):Map(function(unit)
        return UnitIsPlayer(unit) and UnitThreatSituation(unit) or 0
    end)

    --- Gets the unit's group roster
    roleSubject                 = Wow.FromEvent("GROUP_ROSTER_UPDATE", "PLAYER_ROLES_ASSIGNED", "PARTY_LEADER_CHANGED"):Map("=>'any'"):Debounce(0.5)
    Unit.GroupRoster            = Wow.FromUnitEvent(roleSubject):Map(function(unit)
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
    Unit.Role                   = Wow.FromUnitEvent(roleSubject):Map(UnitGroupRolesAssigned or Toolset.fakefunc)

    --- Gets the unit owner's role
    Unit.OwnerRole              = Wow.FromUnitEvent(roleSubject):Map(getUnitOwner):Map(UnitGroupRolesAssigned or Toolset.fakefunc)

    --- Gets the unit role's visibility
    Unit.RoleVisible            = Unit.Role:Map(function(role) return role and role ~= "NONE" or false end)

    --- Gets whether the unit is leader
    Unit.IsLeader               = Wow.FromUnitEvent(roleSubject):Map(function(unit) return (UnitInParty(unit) or UnitInRaid(unit)) and UnitIsGroupLeader(unit) or false end)

    --- Gets whether the unit is in range of the player
    Unit.InRange                = Unit.Timer:Map(function(unit) return UnitExists(unit) and (UnitIsUnit(unit, "player") or not (UnitInParty(unit) or UnitInRaid(unit)) or UnitInRange(unit)) end)

    --- Gets whether the unit's owner is in range or the player
    Unit.OwnerInRange           = Unit.Timer:Map(function(unit) unit = getUnitOwner(unit) return UnitExists(unit) and (UnitIsUnit(unit, "player") or not (UnitInParty(unit) or UnitInRaid(unit)) or UnitInRange(getUnitOwner(unit))) end)
end

------------------------------------------------------------
--                 Ready Check Observable                 --
------------------------------------------------------------
do
    _ReadyChecking              = 0
    _ReadyCheckSubject          = Subject()
    _ReadyCheckConfirmSubject   = Subject()
    _ReadyCheckingCache         = {}

    __SystemEvent__() __Async__()
    function READY_CHECK()
        wipe(_ReadyCheckingCache)

        _ReadyChecking              = 1
        _ReadyCheckSubject:OnNext("any")
        _ReadyCheckConfirmSubject:OnNext("any")

        if "READY_CHECK_FINISHED" == Wait("READY_CHECK_FINISHED", "PLAYER_REGEN_DISABLED") then
            _ReadyChecking          = 2
            _ReadyCheckConfirmSubject:OnNext("any")

            Wait(10, "PLAYER_REGEN_DISABLED")
        end

        _ReadyChecking              = 0
        return _ReadyCheckSubject:OnNext("any")
    end

    __SystemEvent__()
    function READY_CHECK_CONFIRM()
        return _ReadyCheckConfirmSubject:OnNext("any")
    end

    --- Gets the unit's ready check visibility
    Unit.ReadyCheckVisible      = Wow.FromUnitEvent(_ReadyCheckSubject):Map(function(unit) return _ReadyChecking > 0 and UnitGUID(unit) ~= nil end)

    --- Gets the unit's ready check status
    Unit.ReadyCheck             = Wow.FromUnitEvent(_ReadyCheckConfirmSubject):Map(function(unit)
        if _ReadyChecking == 0 then return end

        local guid              = UnitGUID(unit)
        if not guid then return "notready" end

        local state             = GetReadyCheckStatus(unit) or _ReadyCheckingCache[guid]
        _ReadyCheckingCache[guid]= state
        return _ReadyChecking == 2 and state == "waiting" and "notready" or state
    end)
end