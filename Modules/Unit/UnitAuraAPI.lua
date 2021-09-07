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

--- The observable for the aura panel to refresh all
__Static__() __AutoCache__()
function Wow.UnitAura()
    return Wow.FromUnitEvent("UNIT_AURA"):Next()
end


------------------------------------------------------------
--                      Wow Classic                       --
------------------------------------------------------------
if Scorpio.IsRetail or Scorpio.IsBCC then return end

--- Try Get LibClassicDurations
pcall(LoadAddOn, "LibClassicDurations")

local ok, LibClassicDurations   = pcall(_G.LibStub, "LibClassicDurations")
if not (ok and LibClassicDurations) then return end

LibClassicDurations:Register("Scorpio") -- tell library it's being used and should start working
_Parent.UnitAura                = LibClassicDurations.UnitAuraWithBuffs

LibClassicDurations.RegisterCallback("Scorpio", "UNIT_BUFF", function(event, unit) return FireSystemEvent("UNIT_AURA", unit) end)