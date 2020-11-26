-- Author      : Kurapica
-- Create Date : 2013/11/25
-- Change Log  :
--               2014/10/17 Use the spell id as the action content, not index

-- Check Version
local version = 3
if not IGAS:NewAddon("IGAS.Widget.Action.MountHandler", version) then
	return
end

import "System.Widget.Action.ActionRefreshMode"

GetMountInfoByID = C_MountJournal.GetMountInfoByID
GetDisplayedMountInfo = C_MountJournal.GetDisplayedMountInfo
SUMMON_RANDOM_FAVORITE_MOUNT_SPELL = 150544
SUMMON_RANDOM_ID = 0

-- Event handler
function OnEnable(self)
	IGAS_DB.MountHandler_Data = nil

	self:RegisterEvent("COMPANION_UPDATE")
	self:RegisterEvent("SPELL_UPDATE_USABLE")
	self:RegisterEvent("UNIT_AURA")

	C_MountJournal.Pickup(0)
	local ty, pick = GetCursorInfo()
	ClearCursor()

	SUMMON_RANDOM_ID = pick

	OnEnable = nil
end

local firstUpdate = true

function COMPANION_UPDATE(self, companionType)
	if not companionType or companionType == "MOUNT" then
		if firstUpdate then
			firstUpdate = true
			return handler:Refresh()
		else
			return handler:Refresh(RefreshUsable)
		end
	end
end

function SPELL_UPDATE_USABLE(self)
	return handler:Refresh(RefreshUsable)
end

function UNIT_AURA(self, unit)
	if unit == "player" then
		return handler:Refresh(RefreshButtonState)
	end
end

local _ForceUpdated = false
function ForceUpdate()
	_ForceUpdated = false
	return handler:Refresh(RefreshIcon)
end

-- Companion action type handler
handler = ActionTypeHandler {
	Name = "mount",

	PickupSnippet = "Custom",

	UpdateSnippet = [[
		local target = ...

		if target then
			self:SetAttribute("*type*", "macro")
			self:SetAttribute("*macrotext*", "/CANCELFORM")
		else
			self:SetAttribute("*type*", nil)
			self:SetAttribute("*macrotext*", nil)
		end
	]],

	ClearSnippet = [[
		self:SetAttribute("*type*", nil)
		self:SetAttribute("*macrotext*", nil)
	]],

	PreClickSnippet = [=[
		self:GetFrameRef("IFActionHandler_Manager"):RunFor(self, [[ Manager:CallMethod("SummonMount", self:GetName()) ]])
	]=],
}

IGAS:GetUI(handler.Manager).SummonMount = function (self, btnName)
	local mountID = IGAS:GetWrapper(_G[btnName]).Mount

	if mountID then
		if select(4, C_MountJournal.GetMountInfoByID(mountID)) then
			C_MountJournal.Dismiss()
		else
			Task.NextCall(C_MountJournal.SummonByID, mountID)
		end
	end
end

-- Overwrite methods
function handler:PickupAction(target)
	-- Try pickup
	if target == SUMMON_RANDOM_ID then
		return C_MountJournal.Pickup(0)
	else
		local i = 1
		while GetDisplayedMountInfo(i) do
			if target == select(12, GetDisplayedMountInfo(i)) then
				return C_MountJournal.Pickup(i)
			end
			i = i + 1
		end
	end
end

function handler:GetActionTexture()
	local target, icon = self.ActionTarget
	if target == SUMMON_RANDOM_ID then
		icon = GetSpellTexture(SUMMON_RANDOM_FAVORITE_MOUNT_SPELL)
	else
		icon = (select(3, GetMountInfoByID(target)))
	end
	if not icon and not _ForceUpdated then _ForceUpdated = true Task.DelayCall(1, ForceUpdate) end
	return icon
end

function handler:IsActivedAction()
	local target = self.ActionTarget
	if target == SUMMON_RANDOM_ID then
		return IsMounted()
	else
		return (select(4, GetMountInfoByID(target)))
	end
end

function handler:IsUsableAction()
	local target = self.ActionTarget
	local canSummon = not InCombatLockdown() and IsUsableSpell(SUMMON_RANDOM_FAVORITE_MOUNT_SPELL)
	if target == SUMMON_RANDOM_ID then
		return canSummon
	else
		return canSummon and (select(5, GetMountInfoByID(target)))
	end
end

function handler:SetTooltip(GameTooltip)
	local target = self.ActionTarget
	if target == SUMMON_RANDOM_ID then
		return GameTooltip:SetSpellByID(SUMMON_RANDOM_FAVORITE_MOUNT_SPELL)
	else
		local _, spell = C_MountJournal.GetMountInfoByID(target)
		return GameTooltip:SetMountBySpellID(spell)
	end
end

-- Expand IFActionHandler
interface "IFActionHandler"
	------------------------------------------------------
	-- Property
	------------------------------------------------------
	__Doc__[[The action button's content if its type is 'mount']]
	property "Mount" {
		Get = function(self)
			return self:GetAttribute("actiontype") == "mount" and tonumber(self:GetAttribute("mount"))
		end,
		Set = function(self, value)
			self:SetAction("mount", value)
		end,
		Type = NumberNil,
	}
endinterface "IFActionHandler"