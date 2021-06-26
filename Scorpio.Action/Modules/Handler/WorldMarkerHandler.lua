--========================================================--
--             Scorpio Secure World Marker Handler        --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.WorldMarkerHandler"   "1.0.0"
--========================================================--

_Enabled                        = false

__Sealed__() enum "WorldMarkerActionType" { "set", "clear", "toggle" }

------------------------------------------------------
-- Action Handler
------------------------------------------------------
handler                         = ActionTypeHandler {
    Name                        = "worldmarker",
    Target                      = "marker",
    Detail                      = "action",
    DragStyle                   = "Block",
    ReceiveStyle                = "Block",

    OnEnableChanged             = function(self, value) _Enabled = value end,
}

------------------------------------------------------
-- Module Event Handler
------------------------------------------------------
_WorldMarker                    = {}
for i = 1, _G.NUM_WORLD_RAID_MARKERS do
    _WorldMarker[i]             = _G["WORLD_MARKER"..i]:match("Interface[^:]+")
end

__Async__()
function OnEnable()
    while _Enabled do
        handler:RefreshButtonState()
        Delay(0.1)
    end
end

------------------------------------------------------
-- Overwrite methods
------------------------------------------------------
function handler:GetActionTexture()
    return _WorldMarker[self.ActionTarget]
end

function handler:IsActivedAction()
    local target                = self.ActionTarget
    return target and target >= 1 and target <= NUM_WORLD_RAID_MARKERS and IsRaidMarkerActive(target)
end
