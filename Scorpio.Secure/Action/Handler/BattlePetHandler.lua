-- Author      : Kurapica
-- Create Date : 2013/11/25
-- Change Log  :

-- Check Version
local version = 2
if not IGAS:NewAddon("IGAS.Widget.Action.BattlePetHandler", version) then
	return
end

_Enabled = false
SUMMON_RANDOM_FAVORITE_PET_SPELL = 243819
SUMMON_RANDOM_ID = 0

-- Event handler
function OnEnable(self)
	self:RegisterEvent("PET_JOURNAL_LIST_UPDATE")

	OnEnable = nil
	C_PetJournal.PickupSummonRandomPet()
	local ty, pick = GetCursorInfo()
	ClearCursor()
	SUMMON_RANDOM_ID = pick

	return handler:Refresh()
end

function PET_JOURNAL_LIST_UPDATE(self)
	return handler:Refresh()
end

local _ForceUpdated = false
function ForceUpdate()
	_ForceUpdated = false
	return handler:Refresh(RefreshIcon)
end

-- Battlepet action type handler
handler = ActionTypeHandler {
	Name = "battlepet",

	PickupSnippet = "Custom",

	UpdateSnippet = [[
		local target = ...

		self:SetAttribute("*type*", "macro")
		self:SetAttribute("*macrotext*", "/summonpet "..target)
	]],

	ClearSnippet = [[
		self:SetAttribute("*type*", nil)
		self:SetAttribute("*macrotext*", nil)
	]],

	OnEnableChanged = function(self) _Enabled = self.Enabled end,
}

-- Overwrite methods
function handler:PickupAction(target)
	if target == SUMMON_RANDOM_ID then
		return C_PetJournal.PickupSummonRandomPet()
	else
		return C_PetJournal.PickupPet(target)
	end
end

function handler:GetActionTexture()
	local target, icon = self.ActionTarget
	if target == SUMMON_RANDOM_ID then
		icon = GetSpellTexture(SUMMON_RANDOM_FAVORITE_PET_SPELL)
	else
		icon = select(9, C_PetJournal.GetPetInfoByPetID(target))
	end
	if not icon and not _ForceUpdated then _ForceUpdated = true Task.DelayCall(1, ForceUpdate) end
	return icon
end

function handler:SetTooltip(GameTooltip)
	local target = self.ActionTarget
	if target == SUMMON_RANDOM_ID then
		return GameTooltip:SetSpellByID(SUMMON_RANDOM_FAVORITE_PET_SPELL)
	else
		local speciesID, _, _, _, _, _, _, name, _, _, _, sourceText, description, _, _, tradable, unique = C_PetJournal.GetPetInfoByPetID(target)

		if speciesID then
			GameTooltip:SetText(name, 1, 1, 1)

			if sourceText and sourceText ~= "" then
				GameTooltip:AddLine(sourceText, 1, 1, 1, true)
			end

			if description and description ~= "" then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(description, nil, nil, nil, true)
			end
			GameTooltip:Show()
		end
	end
end

-- Expand IFActionHandler
interface "IFActionHandler"
	------------------------------------------------------
	-- Property
	------------------------------------------------------
	__Doc__[[The action button's content if its type is 'battlepet']]
	property "BattlePet" {
		Get = function(self)
			return self:GetAttribute("actiontype") == "battlepet" and self:GetAttribute("battlepet") or nil
		end,
		Set = function(self, value)
			self:SetAction("battlepet", value)
		end,
		Type = String,
	}
endinterface "IFActionHandler"