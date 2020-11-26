-- Author      : Kurapica
-- Create Date : 2013/11/25
-- Change Log  :

-- Check Version
local version = 1
if not IGAS:NewAddon("IGAS.Widget.Action.EquipSetHandler", version) then
	return
end

import "System.Widget.Action.ActionRefreshMode"

_EquipSetTemplate = "_EquipSet[%q] = %d\n"

_EquipSetMap = {}

GetEquipmentSetInfo = C_EquipmentSet.GetEquipmentSetInfo

-- Event handler
function OnEnable(self)
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("EQUIPMENT_SETS_CHANGED")

	OnEnable = nil
end

function PLAYER_EQUIPMENT_CHANGED(self)
	return handler:Refresh()
end

function PLAYER_ENTERING_WORLD(self)
	return UpdateEquipmentSet()
end

function EQUIPMENT_SETS_CHANGED(self)
	return UpdateEquipmentSet()
end

function UpdateEquipmentSet()
	local str = "for i in pairs(_EquipSet) do _EquipSet[i] = nil end\n"

	wipe(_EquipSetMap)

	for _, id in pairs(C_EquipmentSet.GetEquipmentSetIDs()) do
		local name = GetEquipmentSetInfo(id)
		str = str.._EquipSetTemplate:format(name, id)
		_EquipSetMap[name] = id
	end

	if str ~= "" then
		Task.NoCombatCall(function ()
			handler:RunSnippet( str )

			return handler:Refresh()
		end)
	end
end

-- Equipset action type handler
handler = ActionTypeHandler {
	Name = "equipmentset",

	InitSnippet = [[
		_EquipSet = newtable()
	]],

	PickupSnippet = [[
		local target = ...
		return "clear", "equipmentset", _EquipSet[target]
	]],

	UpdateSnippet = [[
		local target = ...

		self:SetAttribute("*type*", "macro")
		self:SetAttribute("*macrotext*", "/equipset "..target)
	]],

	ClearSnippet = [[
		self:SetAttribute("*type*", nil)
		self:SetAttribute("*macrotext*", nil)
	]],
}

-- Overwrite methods
function handler:PickupAction(target)
	return _EquipSetMap[target] and C_EquipmentSet.PickupEquipmentSet(_EquipSetMap[target])
end

function handler:GetActionText()
	return self.ActionTarget
end

function handler:GetActionTexture()
	local target = self.ActionTarget
	return _EquipSetMap[target] and select(2, GetEquipmentSetInfo(_EquipSetMap[target]))
end

function handler:IsEquippedItem()
	local target = self.ActionTarget
	return _EquipSetMap[target] and select(4, GetEquipmentSetInfo(_EquipSetMap[target]))
end

function handler:IsActivedAction()
	local target = self.ActionTarget
	return _EquipSetMap[target] and select(4, GetEquipmentSetInfo(_EquipSetMap[target]))
end

function handler:SetTooltip(GameTooltip)
	if _EquipSetMap[self.ActionTarget] then
		GameTooltip:SetEquipmentSet(_EquipSetMap[self.ActionTarget])
	end
end

-- Expand IFActionHandler
interface "IFActionHandler"
	------------------------------------------------------
	-- Property
	------------------------------------------------------
	__Doc__[[The action button's content if its type is 'equipmentset']]
	property "EquipmentSet" {
		Get = function(self)
			return self:GetAttribute("actiontype") == "equipmentset" and self:GetAttribute("equipmentset") or nil
		end,
		Set = function(self, value)
			self:SetAction("equipmentset", value)
		end,
		Type = String,
	}
endinterface "IFActionHandler"