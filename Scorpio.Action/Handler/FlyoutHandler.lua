-- Author      : Kurapica
-- Create Date : 2013/11/25
-- Change Log  :

-- Check Version
local version = 1
if not IGAS:NewAddon("IGAS.Widget.Action.FlyoutHandler", version) then
	return
end

import "System.Widget.Action.ActionRefreshMode"

MAX_SKILLLINE_TABS = _G.MAX_SKILLLINE_TABS

enum "FlyoutDirection" {
	"UP",
	"DOWN",
	"LEFT",
	"RIGHT",
}

_FlyoutSlot = {}
_FlyoutTexture = {}

-- Event handler
function OnEnable(self)
	self:RegisterEvent("LEARNED_SPELL_IN_TAB")
	self:RegisterEvent("SPELLS_CHANGED")
	self:RegisterEvent("SKILL_LINES_CHANGED")
	self:RegisterEvent("PLAYER_GUILD_UPDATE")
	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

	OnEnable = nil
end

function LEARNED_SPELL_IN_TAB(self)
	return UpdateFlyoutSlotMap()
end

function SPELLS_CHANGED(self)
	return UpdateFlyoutSlotMap()
end

function SKILL_LINES_CHANGED(self)
	return UpdateFlyoutSlotMap()
end

function PLAYER_GUILD_UPDATE(self)
	return UpdateFlyoutSlotMap()
end

function PLAYER_SPECIALIZATION_CHANGED(self, unit)
	if unit == "player" then
		return UpdateFlyoutSlotMap()
	end
end

function UpdateFlyoutSlotMap()
	local type, id
	local name, texture, offset, numEntries, isGuild, offspecID

	wipe(_FlyoutSlot)
	wipe(_FlyoutTexture)

	for i = 1, MAX_SKILLLINE_TABS do
		name, texture, offset, numEntries, isGuild, offspecID = GetSpellTabInfo(i)

		if not name then
			break
		end

		if not isGuild and offspecID == 0 then
			for index = offset + 1, offset + numEntries do
				type, id = GetSpellBookItemInfo(index, "spell")

				if type == "FLYOUT" then
					if not _FlyoutSlot[id] then
						_FlyoutSlot[id] = index
						_FlyoutTexture[id] = GetSpellBookItemTexture(index, "spell")
					end
				end
			end
		end
	end

	return handler:Refresh()
end

-- Flyout action type handler
handler = ActionTypeHandler {
	Name = "flyout",

	Target = "spell",

	PickupSnippet = "Custom",
}

-- Overwrite methods
function handler:PickupAction(target)
	return PickupSpellBookItem(_FlyoutSlot[target], "spell")
end

function handler:GetActionTexture()
	return _FlyoutTexture[self.ActionTarget]
end

function handler:SetTooltip(GameTooltip)
	GameTooltip:SetSpellBookItem(_FlyoutSlot[self.ActionTarget], "spell")
end

function handler:IsFlyout()
	return true
end

-- Expand IFActionHandler
interface "IFActionHandler"
	------------------------------------------------------
	-- Property
	------------------------------------------------------
	__Doc__[[The action button's content if its type is 'flyout']]
	property "FlytoutID" {
		Get = function(self)
			return self:GetAttribute("actiontype") == "flyout" and tonumber(self:GetAttribute("spell")) or nil
		end,
		Set = function(self, value)
			self:SetAction("flyout", value)
		end,
		Type = NumberNil,
	}
endinterface "IFActionHandler"