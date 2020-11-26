-- Author      : Kurapica
-- Create Date : 2013/11/25
-- Change Log  :

-- Check Version
local version = 1
if not IGAS:NewAddon("IGAS.Widget.Action.PetActionHandler", version) then
	return
end

import "System.Widget.Action.ActionRefreshMode"

_Enabled = false

-- Event handler
function OnEnable(self)
	self:RegisterEvent("PET_STABLE_UPDATE")
	self:RegisterEvent("PET_STABLE_SHOW")
	self:RegisterEvent("PET_BAR_SHOWGRID")
	self:RegisterEvent("PET_BAR_HIDEGRID")
	self:RegisterEvent("PLAYER_CONTROL_LOST")
	self:RegisterEvent("PLAYER_CONTROL_GAINED")
	self:RegisterEvent("PLAYER_FARSIGHT_FOCUS_CHANGED")
	self:RegisterEvent("UNIT_PET")
	self:RegisterEvent("UNIT_FLAGS")
	self:RegisterEvent("PET_BAR_UPDATE")
	self:RegisterEvent("PET_UI_UPDATE")
	self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
	self:RegisterEvent("UNIT_AURA")
	self:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
	self:RegisterEvent("PET_BAR_UPDATE_USABLE")

	OnEnable = nil

	return handler:Refresh()
end

function PET_STABLE_UPDATE(self)
	return handler:Refresh()
end

function PET_STABLE_SHOW(self)
	return handler:Refresh()
end


function PLAYER_CONTROL_LOST(self)
	return handler:Refresh()
end

function PLAYER_CONTROL_GAINED(self)
	return handler:Refresh()
end

function PLAYER_FARSIGHT_FOCUS_CHANGED(self)
	return handler:Refresh()
end

function UNIT_PET(self, unit)
	if unit == "player" then
		return handler:Refresh()
	end
end

function UNIT_FLAGS(self, unit)
	if unit == "pet" then
		return handler:Refresh()
	end
end

function PET_BAR_UPDATE(self)
	return handler:Refresh()
end

function PET_UI_UPDATE(self)
	return handler:Refresh()
end

function UPDATE_VEHICLE_ACTIONBAR(self)
	return handler:Refresh()
end

function UNIT_AURA(self, unit)
	if unit == "pet" then
		return handler:Refresh()
	end
end

function PET_BAR_UPDATE_COOLDOWN(self)
	return handler:Refresh(RefreshCooldown)
end

function PET_BAR_UPDATE_USABLE(self)
	return handler:Refresh(RefreshUsable)
end

-- Pet action type handler
handler = ActionTypeHandler {
	Name = "pet",

	Target = "action",

	DragStyle = "Keep",

	ReceiveStyle = "Keep",

	IsPlayerAction = false,

	IsPetAction = true,

	PickupSnippet = [[ return "petaction", ... ]],

	UpdateSnippet = [[
		local target = ...

		if tonumber(target) then
			-- Use macro to toggle auto cast
			self:SetAttribute("type2", "macro")
			self:SetAttribute("macrotext2", "/click PetActionButton".. target .. " RightButton")
		end
	]],

	ClearSnippet = [[
		self:SetAttribute("type2", nil)
		self:SetAttribute("macrotext2", nil)
	]],

	PreClickSnippet = [[
		local type, action = GetActionInfo(self:GetAttribute("action"))
		return nil, format("%s|%s", tostring(type), tostring(action))
	]],

	PostClickSnippet = [[
		local message = ...
		local type, action = GetActionInfo(self:GetAttribute("action"))
		if message ~= format("%s|%s", tostring(type), tostring(action)) then
			return Manager:RunFor(self, UpdateAction)
		end
	]],

	OnEnableChanged = function(self) _Enabled = self.Enabled end,
}

-- Overwritde methods
function handler:PickupAction(target)
	return PickupPetAction(target)
end

function handler:HasAction()
	return GetPetActionInfo(self.ActionTarget) and true
end

function handler:GetActionTexture()
	local name, texture, isToken = GetPetActionInfo(self.ActionTarget)
	if name then
		return isToken and _G[texture] or texture
	end
end

function handler:GetActionCooldown()
	return GetPetActionCooldown(self.ActionTarget)
end

function handler:IsUsableAction()
	return GetPetActionSlotUsable(self.ActionTarget)
end

function handler:IsActivedAction()
	return select(4, GetPetActionInfo(self.ActionTarget))
end

function handler:IsAutoCastAction()
	return select(5, GetPetActionInfo(self.ActionTarget))
end

function handler:IsAutoCasting()
	return select(6, GetPetActionInfo(self.ActionTarget))
end

function handler:SetTooltip(GameTooltip)
	GameTooltip:SetPetAction(self.ActionTarget)
end

-- Expand IFActionHandler
interface "IFActionHandler"
	------------------------------------------------------
	-- Property
	------------------------------------------------------
	__Doc__[[The action button's content if its type is 'pet']]
	property "PetAction" {
		Get = function(self)
			return self:GetAttribute("actiontype") == "pet" and tonumber(self:GetAttribute("action")) or nil
		end,
		Set = function(self, value)
			self:SetAction("pet", value)
		end,
		Type = NumberNil,
	}

endinterface "IFActionHandler"