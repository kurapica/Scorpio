--========================================================--
--                Scorpio UnitFrame Aura API              --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/09/07                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Secure.UnitFrame.AuraAPI" "1.0.0"
--========================================================--

namespace "Scorpio.Secure.UnitFrame"

import "System.Reactive"
import "System.Toolset"

if Scorpio.UseSecretValue then
    __Static__()
    function Wow.UnitAura()
        return Wow.FromUnitEvent("UNIT_AURA"):Next()
    end
    return
end


__Final__() interface "UnitAuraPredicate" (function(_ENV)
    local obUnitAura            = Wow.FromUnitEvent("UNIT_AURA"):Next()

    local scanResult            = setmetatable({}, { __index = function(self, key) local ret = {} rawset(self, key, ret) return ret end })
    local recycle               = Recycle()

    local singleSpellID         = setmetatable({}, getmetatable(scanResult))
    local singleSpellName       = setmetatable({}, getmetatable(scanResult))

    local auraFilter            = { HELPFUL = 1, HARMFUL = 2, PLAYER = 3, RAID = 4, CANCELABLE = 5, NOT_CANCELABLE = 6, INCLUDE_NAME_PLATE_ONLY = 7, MAW = 8 }

    local refreshAura, scanForUnit

    if _G.UnitAuraSlots then
        function refreshAura(cache, unit, filter, auraIdx, continuationToken, ...)
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

    local function getUnitCache(unit, filter)
        local guid              = UnitGUID(unit)
        local now               = GetTime()
        local fcache            = scanResult[filter]
        local cache             = fcache[guid]

        if not cache then
            cache               = recycle()
            fcache[guid]        = cache

            cache[0]            = now
            scanForUnit(cache, unit, filter)
        elseif cache[0] < now then
            wipe(cache)
            cache[0]            = now
            scanForUnit(cache, unit, filter)
        end

        return cache
    end

    local function passFilter(filter)
        return XList(filter:gmatch("[%w_]+")):ToList():Sort(function(a, b) return auraFilter[a] < auraFilter[b] end):Join("|")
    end

    -- Clear Caches
    Wow.FromEvent("PLAYER_REGEN_ENABLED"):Next():Subscribe(function()
        for filter, fcache in pairs(scanResult) do
            for guid, cache in pairs(fcache) do
                recycle(wipe(cache))
            end

            wipe(fcache)
        end
    end)

    -- Used for full scan
    __Static__() __Arguments__{}
    function PredicateUnitAura()
        return obUnitAura
    end

    -- Predicate for one spell id
    __Static__() __Arguments__{ String, Number } __Observable__()
    function PredicateUnitAura(filter, id)
        filter                  = passFilter(filter)
        singleSpellID[filter][id] = true

        return Operator(obUnitAura, function(observer, unit)
            local cache         = getUnitCache(unit, filter)

            local auraID        = cache[id]
            return auraID and observer:OnNext(unit, filter, auraID)
        end)
    end

    -- Predicate for one spell name
    __Static__() __Arguments__{ String } __Observable__()
    function PredicateUnitAura(filter, name)
        filter                  = passFilter(filter)
        singleSpellName[filter][name] = true

        return Operator(obUnitAura, function(observer, unit)
            local cache         = getUnitCache(unit, filter)

            local auraID        = cache[name]
            return auraID and observer:OnNext(unit, filter, auraID)
        end)
    end

    __Arguments__{ String, struct { Number }}
    __Static__() __Observable__()
    function PredicateUnitAura(filter, ids)
        filter                  = passFilter(filter)

        local clone             = recycle()
        local len               = #ids
        for i = 1, len do
            singleSpellID[filter][ids[i]] = true
            clone[i]            = ids[i]
        end

        return Operator(obUnitAura, function(observer, unit)
            local cache         = getUnitCache(unit, filter)

            local auraIDs       = recycle()
            local index         = 1

            for i = 1, len do
                local auraID    = cache[clone[i]]
                if auraID then
                    auraIDs[index] = auraID
                    index       = index + 1
                end
            end

            if index > 1 then
                observer:OnNext(unit, filter, unpack(auraIDs))
            end

            recycle(wipe(auraIDs))
        end)
    end

    __Arguments__{ String, struct { String }}
    __Static__() __Observable__()
    function PredicateUnitAura(filter, names)
        filter                  = passFilter(filter)

        local clone             = recycle()
        local len               = #names
        for i = 1, len do
            singleSpellName[filter][names[i]] = true
            clone[i]            = names[i]
        end

        return Operator(obUnitAura, function(observer, unit)
            local cache         = getUnitCache(unit, filter)

            local auraIDs       = recycle()
            local index         = 1

            for i = 1, len do
                local auraID    = cache[clone[i]]
                if auraID then
                    auraIDs[index] = auraID
                    index       = index + 1
                end
            end

            if index > 1 then
                observer:OnNext(unit, filter, unpack(auraIDs))
            end

            recycle(wipe(auraIDs))
        end)
    end
end)

__Static__()
Wow.UnitAura                    = UnitAuraPredicate.PredicateUnitAura

------------------------------------------------------------
--                      Wow Classic                       --
------------------------------------------------------------
if not Scorpio.IsClassic then return end

--- Try Get LibClassicDurations
pcall(LoadAddOn, "LibClassicDurations")

local ok, LibClassicDurations   = pcall(_G.LibStub, "LibClassicDurations")
if not (ok and LibClassicDurations) then return end

LibClassicDurations:Register("Scorpio") -- tell library it's being used and should start working
_Parent.UnitAura                = LibClassicDurations.UnitAuraWithBuffs

LibClassicDurations.RegisterCallback("Scorpio", "UNIT_BUFF", function(event, unit) return FireSystemEvent("UNIT_AURA", unit) end)