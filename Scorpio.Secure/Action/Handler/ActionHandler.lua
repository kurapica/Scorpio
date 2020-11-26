-- Author      : Kurapica
-- Create Date : 2013/11/25
-- Change Log  :

-- Check Version
local version = 2
if not IGAS:NewAddon("IGAS.Widget.Action.ActionHandler", version) then
	return
end

import "System.Widget.Action.ActionRefreshMode"

_Enabled = false

-- Event handler
function OnEnable(self)
	self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	self:RegisterEvent("ACTIONBAR_UPDATE_STATE")
	self:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
	self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	self:RegisterEvent("UPDATE_SUMMONPETS_ACTION")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
	self:RegisterEvent("UNIT_AURA")

	OnEnable = nil

	return handler:Refresh()
end

function ACTIONBAR_SLOT_CHANGED(self, slot)
	if slot == 0 then
		return handler:Refresh()
	else
		for _, button in handler() do
			if slot == button.ActionTarget then
				handler:Refresh(button)
			end
		end
	end
end

function ACTIONBAR_UPDATE_STATE(self)
	handler:Refresh(RefreshButtonState)
end

function ACTIONBAR_UPDATE_USABLE(self)
	handler:Refresh(RefreshUsable)
end

function ACTIONBAR_UPDATE_COOLDOWN(self)
	handler:Refresh(RefreshCooldown)

	RefreshTooltip()
end

function UPDATE_SUMMONPETS_ACTION(self)
	for _, btn in handler() do
		if GetActionInfo(btn.ActionTarget) == "summonpet" then
			btn.Icon = GetActionTexture(btn.ActionTarget)
		end
	end
end

function UPDATE_SHAPESHIFT_FORM(self)
	return handler:Refresh()
end

function UPDATE_SHAPESHIFT_FORMS(self)
	return handler:Refresh()
end

function UNIT_AURA(self, unit)
	if unit == "player" then
		handler:Refresh()
	end
end

-- Action type handler
handler = ActionTypeHandler {
	Name = "action",

	DragStyle = "Keep",

	ReceiveStyle = "Keep",

	InitSnippet = [[
		NUM_ACTIONBAR_BUTTONS = 12

		_MainPage = newtable()

		MainPage = newtable()

		UpdateMainActionBar = [=[
			local page = ...
			if not page then page = GetActionBarPage() end
			if type(page) ~= "number" then
				if HasVehicleActionBar() then
					page = GetVehicleBarIndex()
				elseif HasOverrideActionBar() then
					page = GetOverrideBarIndex()
				elseif HasTempShapeshiftActionBar() then
					page = GetTempShapeshiftBarIndex()
				elseif HasBonusActionBar() then
					page = GetBonusBarIndex()
				else
					page = GetActionBarPage()
				end
			end
			MainPage[0] = page
			for btn in pairs(_MainPage) do
				btn:SetAttribute("actionpage", MainPage[0])
				Manager:RunFor(btn, UpdateAction)
			end
		]=]
	]],

	PickupSnippet = [[
		local target = ...

		if self:GetAttribute("actionpage") and self:GetID() > 0 then
			target = self:GetID() + (tonumber(self:GetAttribute("actionpage"))-1) * NUM_ACTIONBAR_BUTTONS
		end

		return "action", target
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

do
	-- ActionBar swap register
	local state = {}

	-- special using
	tinsert(state, "[possessbar]possess")
	tinsert(state, "[shapeshift]tempshapeshift")
	tinsert(state, "[overridebar]override")
	tinsert(state, "[vehicleui]vehicle")

	-- action bar swap
	for i = 2, 6 do
		tinsert(state, ("[bar:%d]%d"):format(i, i))
	end

	-- stance
	local _, playerclass = UnitClass("player")

	if playerclass == "DRUID" then
		-- prowl first
		tinsert(state, "[bonusbar:1,stealth]8")
	elseif playerclass == "WARRIOR" then
		tinsert(state, "[stance:2]7")
		tinsert(state, "[stance:3]8")
	end

	-- bonusbar map
	for i = 1, 4 do
		tinsert(state, ("[bonusbar:%d]%d"):format(i, i+6))
	end

	-- Fix for temp shape shift bar
	-- tinsert(state, "[shapeshift]tempshapeshift")

	tinsert(state, "1")

	state = table.concat(state, ";")

	local now = SecureCmdOptionParse(state)

	handler:RunSnippet(("MainPage[0] = %s"):format(now))

	handler.Manager:RegisterStateDriver("page", state)

	handler.Manager:SetAttribute("_onstate-page", [=[
		Manager:Run(UpdateMainActionBar, newstate)
	]=])
end

-- Overwrite methods
function handler:GetActionDetail()
	local target = self:CalculateAction()
	local desc

	if target then
		local type, id = GetActionInfo(target)

		if type and id then
			desc = ""..type.."_"..id
		end
	end

	return target, desc
end

function handler:PickupAction(target)
	return PickupAction(target)
end

function handler:HasAction()
	return HasAction(self.ActionTarget)
end

function handler:GetActionText()
	return GetActionText(self.ActionTarget)
end

function handler:GetActionTexture()
	return GetActionTexture(self.ActionTarget)
end

function handler:GetActionCharges()
	return GetActionCharges(self.ActionTarget)
end

function handler:GetActionCount()
	return GetActionCount(self.ActionTarget)
end

function handler:GetActionCooldown()
	return GetActionCooldown(self.ActionTarget)
end

function handler:IsAttackAction()
	return IsAttackAction(self.ActionTarget)
end

function handler:IsEquippedItem()
	return IsEquippedAction(self.ActionTarget)
end

function handler:IsActivedAction()
	return IsCurrentAction(self.ActionTarget)
end

function handler:IsAutoRepeatAction()
	return IsAutoRepeatAction(self.ActionTarget)
end

function handler:IsUsableAction()
	return IsUsableAction(self.ActionTarget)
end

function handler:IsConsumableAction()
	local target = self.ActionTarget
	return IsConsumableAction(target) or IsStackableAction(target) or (not IsItemAction(target) and GetActionCount(target) > 0)
end

function handler:IsInRange()
	return IsActionInRange(self.ActionTarget, self:GetAttribute("unit"))
end

function handler:SetTooltip(GameTooltip)
	GameTooltip:SetAction(self.ActionTarget)
end

function handler:GetSpellId()
	local type, id = GetActionInfo(self.ActionTarget)
	if type == "spell" then
		return id
	elseif type == "macro" then
		return GetMacroSpell(id)
	end
end

-- Expand IFActionHandler
interface "IFActionHandler"

	------------------------------------------------------
	-- Event
	------------------------------------------------------

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	CalculateAction = SecureActionButtonMixin.CalculateAction

	__Doc__[[
		<desc>Set Action Page for actionbutton</desc>
		<param name="page">number|nil, the action page for the action button</param>
	]]
	function SetActionPage(self, page)
		page = tonumber(page) or 0
		page = page and floor(page)
		if page and page <= 0 then page = nil end

		if self.ID == nil then page = nil end

		if GetActionPage(self) ~= page then
			Task.NoCombatCall(
				function (self, page)
					self:SetAttribute("actionpage", page)
					if page then
						self:SetAction("action", tonumber(self:GetAttribute("action")) or self.ID or 1)
					else
						self:SetAction(nil)
					end
				end,
				self, page
			)
		end
	end

	__Doc__[[
		<desc>Get Action Page of action button</desc>
		<return type="number">the action button's action page if set, or nil</return>
	]]
	function GetActionPage(self)
		return tonumber(self:GetAttribute("actionpage"))
	end

	__Doc__[[
		<desc>Set if this action button belongs to main page</desc>
		<param name="isMain">boolean, true if the action button belongs to main page, so its content will be automatically changed under several conditions.</param>
	]]
	function SetMainPage(self, isMain)
		isMain = isMain and true or nil
		if self.__IFActionHandler_IsMainPage ~= isMain then
			self.__IFActionHandler_IsMainPage = isMain

			if isMain then
				Task.NoCombatCall(
					function (self)
						handler.Manager:SetFrameRef("MainPageButton", self)
						handler.Manager:Execute([[
							local btn = Manager:GetFrameRef("MainPageButton")
							if btn then
								_MainPage[btn] = true
								btn:SetAttribute("actionpage", MainPage[0] or 1)
							end
						]])
						self:SetAction("action", tonumber(self:GetAttribute("action")) or self.ID or 1)
					end, self
				)
			else
				Task.NoCombatCall(
					function (self)
						handler.Manager:SetFrameRef("MainPageButton", self)
						handler.Manager:Execute([[
							local btn = Manager:GetFrameRef("MainPageButton")
							if btn then
								_MainPage[btn] = nil
								btn:SetAttribute("actionpage", nil)
							end
						]])
						self:SetAction(nil)
					end, self
				)
			end
		end
	end

	__Doc__[[
		<desc>Whether if the action button is belong to main page</desc>
		<return type="boolean">true if the action button is belong to main page</return>
	]]
	function IsMainPage(self)
		return self.__IFActionHandler_IsMainPage or false
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------
	__Doc__[[The action button's content if its type is 'action']]
	property "Action" {
		Get = function(self)
			return self:GetAttribute("actiontype") == "action" and tonumber(self:GetAttribute("action")) or nil
		end,
		Set = function(self, value)
			self:SetAction("action", value)
		end,
		Type = NumberNil,
	}

	__Doc__[[The action page of the action button if type is 'action']]
	property "ActionPage" { Type = NumberNil }

	__Doc__[[Whether the action button is used in the main page]]
	property "MainPage" { Type = Boolean }

endinterface "IFActionHandler"