-- Author      : Kurapica
-- Create Date : 2013/11/25
-- Change Log  :

-- Check Version
local version = 1
if not IGAS:NewAddon("IGAS.Widget.Action.WorldMarkerHandler", version) then
	return
end

import "System.Widget.Action.ActionRefreshMode"

_Enabled = false

enum "WorldMarkerActionType" {
	"set",
	"clear",
	"toggle",
}

_WorldMarker = {}
for i = 1, _G.NUM_WORLD_RAID_MARKERS do
	_WorldMarker[i] = _G["WORLD_MARKER"..i]:match("Interface[^:]+")
end

handler = ActionTypeHandler {
	Name = "worldmarker",

	Target = "marker",

	Detail = "action",

	DragStyle = "Block",

	ReceiveStyle = "Block",

	OnEnableChanged = function(self)
		_Enabled = self.Enabled
		if _Enabled then
			RefreshForWorldMark()
		end
	end,
}

System.Threading.__Thread__()
function RefreshForWorldMark()
	while _Enabled do
		handler:Refresh(RefreshButtonState)

		Task.Delay(0.1)
	end
end

-- Overwrite methods
function handler:GetActionTexture()
	return _WorldMarker[tonumber(self.ActionTarget)]
end

function handler:IsActivedAction()
	local target = tonumber(self.ActionTarget)
	-- No event for world marker, disable it now
	return target and target >= 1 and target <= NUM_WORLD_RAID_MARKERS and IsRaidMarkerActive(target)
end

-- Expand IFActionHandler
interface "IFActionHandler"
	------------------------------------------------------
	-- Property
	------------------------------------------------------
	__Doc__[[The action button's content if its type is 'worldmarker']]
	property "WorldMarker" {
		Get = function(self)
			return self:GetAttribute("actiontype") == "worldmarker" and tonumber(self:GetAttribute("marker")) or nil
		end,
		Set = function(self, value)
			self:SetAction("worldmarker", value, self.WorldMarkerActionType)
		end,
		Type = NumberNil,
	}

	__Doc__[[The world marker action type]]
	property "WorldMarkerActionType" {
		Get = function (self)
			return self:GetAttribute("actiontype") == "worldmarker" and self:GetAttribute("action") or "toggle"
		end,
		Set = function (self, type)
			self:SetAction("worldmarker", self.WorldMarker, type)
		end,
		Type = WorldMarkerActionType,
	}
endinterface "IFActionHandler"