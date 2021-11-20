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
_WorldMarkerCount               = 0
_WorldMarker                    = {}

while type(_G["WORLD_MARKER"..(_WorldMarkerCount+1)]) == "string" do
    _WorldMarkerCount           = _WorldMarkerCount + 1
    _WorldMarker[_WorldMarkerCount] = _G["WORLD_MARKER".._WorldMarkerCount]:match("Interface[^:]+")
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
    return target and target >= 1 and target <= _WorldMarkerCount and IsRaidMarkerActive(target)
end
