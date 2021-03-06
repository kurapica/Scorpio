-- Author      : Kurapica
-- Create Date : 2013/11/25
-- Change Log  :

-- Check Version
local version = 1
if not IGAS:NewAddon("IGAS.Widget.Action.BagSlotHandler", version) then
	return
end

import "System.Widget.Action.ActionRefreshMode"

_Enabled = false
_BagCache = {}

LE_ITEM_QUALITY_POOR = _G.LE_ITEM_QUALITY_POOR
REPAIR_COST = _G.REPAIR_COST

BACKPACK_CONTAINER = _G.BACKPACK_CONTAINER
BANK_CONTAINER = _G.BANK_CONTAINER
REAGENTBANK_CONTAINER = _G.REAGENTBANK_CONTAINER
NUM_BAG_SLOTS = _G.NUM_BAG_SLOTS
NUM_BANKBAGSLOTS = _G.NUM_BANKBAGSLOTS
NUM_BANKGENERIC_SLOTS = _G.NUM_BANKGENERIC_SLOTS

_ContainerBag = { BACKPACK_CONTAINER, 1, 2, 3, 4 }
_BankBag = { BANK_CONTAINER, 5, 6, 7, 8, 9, 10, 11 }

-- Event handler
function OnEnable(self)
	self:RegisterEvent("QUEST_ACCEPTED")
	self:RegisterEvent("UNIT_QUEST_LOG_CHANGED")

	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("BAG_UPDATE_DELAYED")
	self:RegisterEvent("ITEM_LOCK_CHANGED")
	self:RegisterEvent("BAG_UPDATE_COOLDOWN")
	self:RegisterEvent("INVENTORY_SEARCH_UPDATE")
	self:RegisterEvent("BAG_NEW_ITEMS_UPDATED")

	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_CLOSED")

	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")

	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

	OnEnable = nil

	return handler:Refresh()
end

function QUEST_ACCEPTED(self)
	for _, bag in ipairs(_ContainerBag) do
		if _BagCache[bag] then
			for btn in pairs(_BagCache[bag]) do
				handler:Refresh(btn)
			end
		end
	end
end

function UNIT_QUEST_LOG_CHANGED(self, unit)
	if unit ~= "player" then return end

	for _, bag in ipairs(_ContainerBag) do
		if _BagCache[bag] then
			for btn in pairs(_BagCache[bag]) do
				handler:Refresh(btn)
			end
		end
	end
end

local bagUpdateCache = {}

function BAG_UPDATE(self, bag)
	if _BagCache[bag] then
		bagUpdateCache[bag] = true
	end
end

function BAG_UPDATE_DELAYED(self)
	for bag in pairs(bagUpdateCache) do
		for btn in pairs(_BagCache[bag]) do
			handler:Refresh(btn)
		end
	end
	wipe(bagUpdateCache)
end

function ITEM_LOCK_CHANGED(self, bag, slot)
	if _BagCache[bag] and slot then
		local _, _, locked = GetContainerItemInfo(bag, slot)

		for btn, bslot in pairs(_BagCache[bag]) do
			if bslot == slot then
				btn.IconLocked = locked
			end
		end
	end
end

function BAG_UPDATE_COOLDOWN(self)
	for _, bag in ipairs(_ContainerBag) do
		if _BagCache[bag] then
			for btn in pairs(_BagCache[bag]) do
				RefreshCooldown(btn)
			end
		end
	end
end

function INVENTORY_SEARCH_UPDATE(self)
	for bag, cache in pairs(_BagCache) do
		for btn, slot in pairs(cache) do
			btn.ShowSearchOverlay = select(8, GetContainerItemInfo(bag, slot))
		end
	end
end

function BAG_NEW_ITEMS_UPDATED(self)
	for _, bag in ipairs(_ContainerBag) do
		if _BagCache[bag] then
			for btn, slot in pairs(_BagCache[bag]) do
				if C_NewItems.IsNewItem(bag, slot) then
					handler:Refresh(btn)
				end
			end
		end
	end
end

function MERCHANT_SHOW(self)
	for _, bag in ipairs(_ContainerBag) do
		if _BagCache[bag] then
			for btn, slot in pairs(_BagCache[bag]) do
				local texture, itemCount, locked, quality, readable, _, _, isFiltered, noValue, itemID = GetContainerItemInfo(bag, slot)

				if itemID then
					btn.ShowJunkIcon = (quality == LE_ITEM_QUALITY_POOR and not noValue)
				else
					btn.ShowJunkIcon = false
				end
			end
		end
	end
end

function MERCHANT_CLOSED(self)
	for _, bag in ipairs(_ContainerBag) do
		if _BagCache[bag] then
			for btn, slot in pairs(_BagCache[bag]) do
				btn.ShowJunkIcon = false
			end
		end
	end
end

function PLAYERBANKSLOTS_CHANGED(self, slot)
	if slot <= NUM_BANKGENERIC_SLOTS then
		if _BagCache[BANK_CONTAINER] then
			for btn, bslot in pairs(_BagCache[BANK_CONTAINER]) do
				if bslot == slot then
					handler:Refresh(btn)
				end
			end
		end
	end
end

function PLAYERREAGENTBANKSLOTS_CHANGED(self, slot)
	if _BagCache[REAGENTBANK_CONTAINER] then
		for btn, bslot in pairs(_BagCache[REAGENTBANK_CONTAINER]) do
			if bslot == slot then
				handler:Refresh(btn)
			end
		end
	end
end

local ITEM_UPGRADE_CHECK_TIME = 0.5
local function RefreshUpgradeItem(self, bag, slot)
	local itemIsUpgrade = IsContainerItemAnUpgrade(bag, slot)

	if itemIsUpgrade == nil then
		-- nil means not all the data was available to determine if this is an upgrade.
		self.IsUpgradeItem = false
		Task.DelayCall(ITEM_UPGRADE_CHECK_TIME, RefreshUpgradeItem, self, bag, slot)
	else
		self.IsUpgradeItem = itemIsUpgrade
	end
end

function UNIT_INVENTORY_CHANGED(self, unit)
	if not unit or unit == "player" then
		for _, bag in ipairs(_ContainerBag) do
			if _BagCache[bag] then
				for btn, slot in pairs(_BagCache[bag]) do
					RefreshUpgradeItem(btn, bag, slot)
				end
			end
		end
	end
end

function PLAYER_SPECIALIZATION_CHANGED(self)
	for _, bag in ipairs(_ContainerBag) do
		if _BagCache[bag] then
			for btn, slot in pairs(_BagCache[bag]) do
				RefreshUpgradeItem(btn, bag, slot)
			end
		end
	end
end

----------------------------------------
-- BagSlot Handler
----------------------------------------
handler = ActionTypeHandler {
	Name = "bagslot",
	Target = "bag",
	Detail = "slot",

	DragStyle = "Keep",
	ReceiveStyle = "Keep",

	UpdateSnippet = [[
		self:SetAttribute("*type1", "macro")
		self:SetAttribute("*type2", "macro")
		self:SetAttribute("*macrotext1", "/click IGAS_BagSlot_FakeItemButton LeftButton")
		self:SetAttribute("*macrotext2", "/click IGAS_BagSlot_FakeItemButton RightButton")
		Manager:CallMethod("RegisterBagSlot", self:GetName())
	]],
	ClearSnippet = [[
		self:SetAttribute("*type1", nil)
		self:SetAttribute("*type2", nil)
		self:SetAttribute("*macrotext1", nil)
		self:SetAttribute("*macrotext2", nil)
		Manager:CallMethod("UnregisterBagSlot", self:GetName())
	]],
	ReceiveSnippet = "Custom",

	PreClickSnippet = [[
		local bag = self:GetAttribute("bag")
		local slot = self:GetAttribute("slot")

		_BagSlot_FakeContainer:SetID(bag)
		_BagSlot_FakeItemButton:SetID(slot)

		_BagSlot_FakeItemButton:ClearAllPoints()
		_BagSlot_FakeItemButton:SetPoint("TOPRIGHT", self, "TOPRIGHT")
	]],

	OnEnableChanged = function(self) _Enabled = self.Enabled end,
}

-- Use fake container and item button to handle the click of item buttons
local fakeContainerFrame = CreateFrame("Frame", "IGAS_BagSlot_FakeContainer", _G.UIParent, "SecureFrameTemplate")
fakeContainerFrame:Hide()
local fakeItemButton = CreateFrame("Button", "IGAS_BagSlot_FakeItemButton", fakeContainerFrame, "ContainerFrameItemButtonTemplate, SecureFrameTemplate")
fakeItemButton:Hide()

handler.Manager:SetFrameRef("BagSlot_FakeContainer", fakeContainerFrame)
handler.Manager:SetFrameRef("BagSlot_FakeItemButton", fakeItemButton)
handler.Manager:Execute[[
	_BagSlot_FakeContainer = Manager:GetFrameRef("BagSlot_FakeContainer")
	_BagSlot_FakeItemButton = Manager:GetFrameRef("BagSlot_FakeItemButton")
]]

local function OnEnter(self)
	if self.IsNewItem then
		local bag, slot = self.ActionTarget, self.ActionDetail
		if bag and slot then
			C_NewItems.RemoveNewItem(bag, slot)

			for btn, bslot in pairs(_BagCache[bag]) do
				if bslot == slot then
					btn.IsNewItem = false
				end
			end
		end
	end

	if _G.ArtifactFrame and self._BagSlot_ItemID then
		_G.ArtifactFrame:OnInventoryItemMouseEnter(self.ActionTarget, self.ActionDetail)
	end
end

local function OnLeave(self)
	ResetCursor()

	if _G.ArtifactFrame then
		_G.ArtifactFrame:OnInventoryItemMouseLeave(self:GetParent():GetID(), self:GetID())
	end
end

local function OnShow(self)
	local bag = self.ItemBag
	if bag then
		_BagCache[bag] = _BagCache[bag] or {}
		_BagCache[bag][self] = self.ItemSlot
	end
	return handler:Refresh(self)
end

local function OnHide(self)
	for k, v in pairs(_BagCache) do
		if v[self] then v[self] = nil end
	end
end

IGAS:GetUI(handler.Manager).RegisterBagSlot = function (self, btnName)
	self = IGAS:GetWrapper(_G[btnName])

	if self:IsVisible() then
		local bag = self.ItemBag
		_BagCache[bag] = _BagCache[bag] or {}
		_BagCache[bag][self] = self.ItemSlot
	end

	self.OnEnter = self.OnEnter + OnEnter
	self.OnLeave = self.OnLeave + OnLeave
	self.OnShow = self.OnShow + OnShow
	self.OnHide = self.OnHide + OnHide
end

IGAS:GetUI(handler.Manager).UnregisterBagSlot = function (self, btnName)
	self = IGAS:GetWrapper(_G[btnName])

	for k, v in pairs(_BagCache) do
		if v[self] then v[self] = nil end
	end

	self.ItemQuality = nil
	self.IconLocked = false
	self.ShowSearchOverlay = false
	self.ItemQuestStatus = nil
	self.ShowJunkIcon = false
	self.IsBattlePayItem = false
	self.IsNewItem = false
	self.IsUpgradeItem = false

	self.OnEnter = self.OnEnter - OnEnter
	self.OnLeave = self.OnLeave - OnLeave
	self.OnShow = self.OnShow - OnShow
	self.OnHide = self.OnHide - OnHide
end

-- Overwrite methods
function handler:RefreshButton()
	local bag, slot = self.ActionTarget, self.ActionDetail

	if not bag or not slot then return end

	local texture, itemCount, locked, quality, readable, _, _, isFiltered, noValue, itemID = GetContainerItemInfo(bag, slot)
	local isQuestItem, questId, isActive = GetContainerItemQuestInfo(bag, slot)

	if itemID then
		self._BagSlot_ItemID = itemID
		self._BagSlot_Readable = readable
		self.ItemQuality = quality
		self.IconLocked = locked
		self.ShowSearchOverlay = isFiltered

		if questId and not isActive then
			self.ItemQuestStatus = false
		elseif questId or isQuestItem then
			self.ItemQuestStatus = true
		else
			self.ItemQuestStatus = nil
		end

		if MerchantFrame:IsShown() then
			self.ShowJunkIcon = (quality == LE_ITEM_QUALITY_POOR and not noValue)
		else
			self.ShowJunkIcon = false
		end

		self.IsBattlePayItem = IsBattlePayItem(bag, slot)
		self.IsNewItem = C_NewItems.IsNewItem(bag, slot)

		RefreshUpgradeItem(self, bag, slot)
	else
		self._BagSlot_ItemID = nil
		self._BagSlot_Readable = nil
		self.ItemQuality = nil
		self.IconLocked = false
		self.ShowSearchOverlay = false
		self.ItemQuestStatus = nil
		self.ShowJunkIcon = false
		self.IsBattlePayItem = false
		self.IsNewItem = false
		self.IsUpgradeItem = false
	end
end

function handler:ReceiveAction(target, detail)
	return PickupContainerItem(target, detail)
end

function handler:HasAction()
	return true
end

function handler:GetActionTexture()
	local bag = self.ActionTarget
	local slot = self.ActionDetail

	return (GetContainerItemInfo(bag, slot))
end

function handler:GetActionCount()
	local bag = self.ActionTarget
	local slot = self.ActionDetail

	return (select(2, GetContainerItemInfo(bag, slot)))
end

function handler:GetActionCooldown()
	local bag = self.ActionTarget
	local slot = self.ActionDetail

	return GetContainerItemCooldown(bag, slot)
end

function handler:IsEquippedItem()
	return false
end

function handler:IsActivedAction()
	return false
end

function handler:IsUsableAction()
	local bag = self.ActionTarget

	if bag >= 0 and bag <= 4 then
		local item = GetContainerItemID(self.ActionTarget, self.ActionDetail)

		return item and IsUsableItem(item)
	else
		return true
	end
end

function handler:IsConsumableAction()
	local item = GetContainerItemID(self.ActionTarget, self.ActionDetail)
	if not item then return false end

	local maxStack = select(8, GetItemInfo(item)) or 0
	return maxStack > 1
end

function handler:IsInRange()
	local bag = self.ActionTarget
	if bag >= 0 and bag <= 4 then
		return IsItemInRange(GetContainerItemID(self.ActionTarget, self.ActionDetail), self:GetAttribute("unit"))
	end
end

function handler:SetTooltip(GameTooltip)
	local bag = self.ActionTarget
	local slot = self.ActionDetail

	if bag == BANK_CONTAINER or bag == REAGENTBANK_CONTAINER then
		local invId

		if bag == BANK_CONTAINER then
			invId = BankButtonIDToInvSlotID(slot)
		else
			invId = ReagentBankButtonIDToInvSlotID(slot)
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

		local hasItem, hasCooldown, repairCost, speciesID, level, breedQuality, maxHealth, power, speed, name = GameTooltip:SetInventoryItem("player", invId)
		if(speciesID and speciesID > 0) then
			BattlePetToolTip_Show(speciesID, level, breedQuality, maxHealth, power, speed, name)
			CursorUpdate(self)
			return
		end

		if IsModifiedClick("DRESSUP") and self._BagSlot_ItemID then
			ShowInspectCursor()
		elseif self._BagSlot_Readable then
			ShowInspectCursor()
		else
			ResetCursor()
		end
	else
		--GameTooltip:SetOwner(self, "ANCHOR_NONE")

		local showSell = nil
		local hasCooldown, repairCost, speciesID, level, breedQuality, maxHealth, power, speed, name = GameTooltip:SetBagItem(bag, slot)

		GameTooltip:ClearAllPoints()
		if self:GetRight() < GetScreenWidth() / 2 then
			GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPRIGHT")
		else
			GameTooltip:SetPoint("BOTTOMRIGHT", self, "TOPLEFT")
		end

		if speciesID and speciesID > 0 then
			BattlePetToolTip_Show(speciesID, level, breedQuality, maxHealth, power, speed, name)
			return
		else
			if _G.BattlePetTooltip then
				_G.BattlePetTooltip:Hide()
			end
		end

		if InRepairMode() and (repairCost and repairCost > 0) then
			GameTooltip:AddLine(REPAIR_COST, nil, nil, nil, true)
			SetTooltipMoney(IGAS:GetUI(GameTooltip), repairCost)
		elseif _G.MerchantFrame:IsShown() and _G.MerchantFrame.selectedTab == 1 then
			showSell = 1
		end

		if IsModifiedClick("DRESSUP") and self._BagSlot_ItemID then
			ShowInspectCursor()
		elseif showSell then
			ShowContainerSellCursor(self.ActionTarget, self.ActionDetail)
		elseif self._BagSlot_Readable then
			ShowInspectCursor()
		else
			ResetCursor()
		end
	end
end

-- Expand IFActionHandler
interface "IFActionHandler"
	------------------------------------------------------
	-- Property
	------------------------------------------------------
	__Doc__[[The bag id]]
	property "ItemBag" {
		Get = function(self)
			return self:GetAttribute("actiontype") == "bagslot" and tonumber(self:GetAttribute("bag"))
		end,
		Set = function(self, value)
			self:SetAction("bag", value)
		end,
		Type = Number,
	}

	__Doc__[[The slot id]]
	property "ItemSlot" {
		Get = function(self)
			return self:GetAttribute("actiontype") == "bagslot" and tonumber(self:GetAttribute("slot"))
		end,
		Set = function(self, value)
			self:SetAction("slot", value)
		end,
		Type = Number,
	}

	__Doc__[[The item's quality]]
	property "ItemQuality" { Type = NumberNil }

	__Doc__[[The item's quest status, true if actived quest, false if not actived quest, nil if not a quest item.]]
	property "ItemQuestStatus" { Type = BooleanNil }

	__Doc__[[Whether the item is a new item]]
	property "IsNewItem" { Type = Boolean }

	__Doc__[[Whether the item is a battle pay item]]
	property "IsBattlePayItem" { Type = Boolean }

	__Doc__[[Whether show the item as junk]]
	property "ShowJunkIcon" { Type = Boolean }

	__Doc__[[Whether the item is an upgrade item]]
	property "IsUpgradeItem" { Type = Boolean }
endinterface "IFActionHandler"