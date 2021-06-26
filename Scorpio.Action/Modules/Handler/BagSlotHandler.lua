--========================================================--
--             Scorpio Secure Bag Slot Handler            --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.BagSlotHandler"       "1.0.0"
--========================================================--

_Enabled                        = false

------------------------------------------------------
-- Action Handler
------------------------------------------------------
handler                         = ActionTypeHandler {
    Name                        = "bagslot",
    Target                      = "bag",
    Detail                      = "slot",

    DragStyle                   = "Keep",
    ReceiveStyle                = "Keep",

    UpdateSnippet               = [[
        self:SetAttribute("*type1", "macro")
        self:SetAttribute("*type2", "macro")
        self:SetAttribute("*macrotext1", "/click Scorpio_BagSlot_FakeItemButton LeftButton")
        self:SetAttribute("*macrotext2", "/click Scorpio_BagSlot_FakeItemButton RightButton")
        Manager:CallMethod("RegisterBagSlot", self:GetName())
    ]],
    ClearSnippet                = [[
        self:SetAttribute("*type1", nil)
        self:SetAttribute("*type2", nil)
        self:SetAttribute("*macrotext1", nil)
        self:SetAttribute("*macrotext2", nil)
        Manager:CallMethod("UnregisterBagSlot", self:GetName())
    ]],
    ReceiveSnippet              = "Custom",

    PreClickSnippet             = [[
        local bag               = self:GetAttribute("bag")
        local slot              = self:GetAttribute("slot")

        _BagSlot_FakeContainer:SetID(bag)
        _BagSlot_FakeItemButton:SetID(slot)

        _BagSlot_FakeItemButton:ClearAllPoints()
        _BagSlot_FakeItemButton:SetPoint("TOPRIGHT", self, "TOPRIGHT")
    ]],

    OnEnableChanged             = function(self, value) _Enabled = value end,
}


------------------------------------------------------
-- Module Event Handler
------------------------------------------------------
_BagCache                       = {}

LE_ITEM_QUALITY_POOR            = _G.LE_ITEM_QUALITY_POOR
REPAIR_COST                     = _G.REPAIR_COST

BACKPACK_CONTAINER              = _G.BACKPACK_CONTAINER
BANK_CONTAINER                  = _G.BANK_CONTAINER
REAGENTBANK_CONTAINER           = _G.REAGENTBANK_CONTAINER
NUM_BAG_SLOTS                   = _G.NUM_BAG_SLOTS
NUM_BANKBAGSLOTS                = _G.NUM_BANKBAGSLOTS
NUM_BANKGENERIC_SLOTS           = _G.NUM_BANKGENERIC_SLOTS

_ContainerBag                   = { BACKPACK_CONTAINER, 1, 2, 3, 4 }
_BankBag                        = { BANK_CONTAINER, 5, 6, 7, 8, 9, 10, 11 }

-- Event handler
function OnEnable()
    OnEnable                    = nil
    return handler:RefreshActionButtons()
end

------------------------------------------------------
-- System Event Handler
------------------------------------------------------
__SystemEvent__()
function QUEST_ACCEPTED()
    for _, bag in ipairs(_ContainerBag) do
        if _BagCache[bag] then
            for btn in pairs(_BagCache[bag]) do
                handler:RefreshActionButtons(btn)
            end
        end
    end
end

__SystemEvent__()
function UNIT_QUEST_LOG_CHANGED(unit)
    if unit ~= "player" then return end

    for _, bag in ipairs(_ContainerBag) do
        if _BagCache[bag] then
            for btn in pairs(_BagCache[bag]) do
                handler:RefreshActionButtons(btn)
            end
        end
    end
end

local bagUpdateCache            = {}

__SystemEvent__()
function BAG_UPDATE(bag)
    if _BagCache[bag] then
        bagUpdateCache[bag]     = true
    end
end

__SystemEvent__()
function BAG_UPDATE_DELAYED()
    for bag in pairs(bagUpdateCache) do
        for btn in pairs(_BagCache[bag]) do
            handler:RefreshActionButtons(btn)
        end
    end
    wipe(bagUpdateCache)
end

__SystemEvent__()
function ITEM_LOCK_CHANGED(bag, slot)
    if _BagCache[bag] and slot then
        local _, _, locked      = GetContainerItemInfo(bag, slot)

        for btn, bslot in pairs(_BagCache[bag]) do
            if bslot == slot then
                -- Do it directly
                btn.IconLocked  = locked
            end
        end
    end
end

__SystemEvent__()
function BAG_UPDATE_COOLDOWN()
    for _, bag in ipairs(_ContainerBag) do
        if _BagCache[bag] then
            for btn in pairs(_BagCache[bag]) do
                handler:RefreshCooldown(btn)
            end
        end
    end
end

__SystemEvent__()
function INVENTORY_SEARCH_UPDATE()
    for bag, cache in pairs(_BagCache) do
        for btn, slot in pairs(cache) do
            handler:RefreshShowSearchOverlay(btn)
        end
    end
end

__SystemEvent__()
function BAG_NEW_ITEMS_UPDATED()
    for _, bag in ipairs(_ContainerBag) do
        if _BagCache[bag] then
            for btn, slot in pairs(_BagCache[bag]) do
                if C_NewItems.IsNewItem(bag, slot) then
                    handler:RefreshActionButtons(btn)
                end
            end
        end
    end
end

__SystemEvent__()
function MERCHANT_SHOW()
    for _, bag in ipairs(_ContainerBag) do
        if _BagCache[bag] then
            for btn, slot in pairs(_BagCache[bag]) do
                local texture, itemCount, locked, quality, readable, _, _, isFiltered, noValue, itemID = GetContainerItemInfo(bag, slot)

                if itemID then
                    btn.IsJunk  = (quality == LE_ITEM_QUALITY_POOR and not noValue)
                else
                    btn.IsJunk  = false
                end
            end
        end
    end
end

__SystemEvent__()
function MERCHANT_CLOSED()
    for _, bag in ipairs(_ContainerBag) do
        if _BagCache[bag] then
            for btn, slot in pairs(_BagCache[bag]) do
                btn.IsJunk      = false
            end
        end
    end
end

__SystemEvent__()
function PLAYERBANKSLOTS_CHANGED(slot)
    if slot <= NUM_BANKGENERIC_SLOTS then
        if _BagCache[BANK_CONTAINER] then
            for btn, bslot in pairs(_BagCache[BANK_CONTAINER]) do
                if bslot == slot then
                    handler:RefreshActionButtons(btn)
                end
            end
        end
    end
end

__SystemEvent__()
function PLAYERREAGENTBANKSLOTS_CHANGED(slot)
    if _BagCache[REAGENTBANK_CONTAINER] then
        for btn, bslot in pairs(_BagCache[REAGENTBANK_CONTAINER]) do
            if bslot == slot then
                handler:RefreshActionButtons(btn)
            end
        end
    end
end

if _G.IsContainerItemAnUpgrade then
    function RefreshUpgradeItem(self, bag, slot)
        local itemIsUpgrade         = IsContainerItemAnUpgrade(bag, slot)

        if itemIsUpgrade == nil then
            print("Delay RefreshUpgradeItem", bag, slot)
            -- nil means not all the data was available to determine if this is an upgrade.
            self.IsUpgradeItem      = false
            Delay(0.5, RefreshUpgradeItem, self, bag, slot)
        else
            self.IsUpgradeItem      = itemIsUpgrade
        end
    end

    __SystemEvent__()
    function UNIT_INVENTORY_CHANGED(unit)
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

    __SystemEvent__()
    function PLAYER_SPECIALIZATION_CHANGED()
        for _, bag in ipairs(_ContainerBag) do
            if _BagCache[bag] then
                for btn, slot in pairs(_BagCache[bag]) do
                    RefreshUpgradeItem(btn, bag, slot)
                end
            end
        end
    end
else
    RefreshUpgradeItem          = Toolset.fakefunc
end

----------------------------------------
-- BagSlot Handler
----------------------------------------
-- Use fake container and item button to handle the click of item buttons
local fakeContainerFrame        = CreateFrame("Frame", "Scorpio_BagSlot_FakeContainer", _G.UIParent, "SecureFrameTemplate")
fakeContainerFrame:Hide()
local fakeItemButton            = CreateFrame("Button", "Scorpio_BagSlot_FakeItemButton", fakeContainerFrame, "ContainerFrameItemButtonTemplate, SecureFrameTemplate")
fakeItemButton:Hide()

handler.Manager:SetFrameRef("BagSlot_FakeContainer", fakeContainerFrame)
handler.Manager:SetFrameRef("BagSlot_FakeItemButton", fakeItemButton)
handler.Manager:Execute[[
    _BagSlot_FakeContainer      = Manager:GetFrameRef("BagSlot_FakeContainer")
    _BagSlot_FakeItemButton     = Manager:GetFrameRef("BagSlot_FakeItemButton")
]]

local function OnEnter(self)
    if self.IsNewItem then
        local bag, slot         = self.ActionTarget, self.ActionDetail
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
    local bag                   = self.ActionTarget
    if bag then
        _BagCache[bag]          = _BagCache[bag] or {}
        _BagCache[bag][self]    = self.ActionDetail
    end
    return handler:RefreshActionButtons(self)
end

local function OnHide(self)
    for k, v in pairs(_BagCache) do
        v[self]                 = nil
    end
end

__SecureMethod__()
function handler.Manager:RegisterBagSlot(btnName)
    self                        = UI.GetProxyUI(_G[btnName])

    if self:IsVisible() then
        local bag               = self:GetAttribute("bag")
        _BagCache[bag]          = _BagCache[bag] or {}
        _BagCache[bag][self]    = self:GetAttribute("slot")
    end

    self.OnEnter                = self.OnEnter + OnEnter
    self.OnLeave                = self.OnLeave + OnLeave
    self.OnShow                 = self.OnShow + OnShow
    self.OnHide                 = self.OnHide + OnHide
end

__SecureMethod__()
function handler.Manager:UnregisterBagSlot(btnName)
    self                        = UI.GetProxyUI(_G[btnName])

    for k, v in pairs(_BagCache) do
        v[self]                 = nil
    end

    self.ItemQuality            = nil
    self.ItemQuestStatus        = nil
    self.IsJunk                 = false
    self.IsBattlePayItem        = false
    self.IsNewItem              = false
    self.IsUpgradeItem          = false
    self.IsArtifactRelicItem    = false

    self.OnEnter                = self.OnEnter - OnEnter
    self.OnLeave                = self.OnLeave - OnLeave
    self.OnShow                 = self.OnShow - OnShow
    self.OnHide                 = self.OnHide - OnHide
end

-- Overwrite methods
function handler:Refresh()
    local bag, slot             = self.ActionTarget, self.ActionDetail
    if not bag or not slot then return end

    local texture, itemCount, locked, quality, readable, _, _, isFiltered, noValue, itemID = GetContainerItemInfo(bag, slot)
    local isQuestItem, questId, isActive = GetContainerItemQuestInfo(bag, slot)

    if itemID then
        self._BagSlot_ItemID    = itemID
        self._BagSlot_Readable  = readable

        self.ItemQuality        = quality
        self.IsArtifactRelicItem= IsArtifactRelicItem(itemID)

        if questId and not isActive then
            self.ItemQuestStatus= false
        elseif questId or isQuestItem then
            self.ItemQuestStatus= true
        else
            self.ItemQuestStatus= nil
        end

        if MerchantFrame:IsShown() then
            self.IsJunk         = (quality == LE_ITEM_QUALITY_POOR and not noValue)
        else
            self.IsJunk         = false
        end

        self.IsBattlePayItem    = IsBattlePayItem(bag, slot)
        self.IsNewItem          = C_NewItems.IsNewItem(bag, slot)

        RefreshUpgradeItem(self, bag, slot)
    else
        self._BagSlot_ItemID    = nil
        self._BagSlot_Readable  = nil
        self.ItemQuality        = nil
        self.IconLocked         = false
        self.IsSearching        = false
        self.ItemQuestStatus    = nil
        self.IsJunk             = false
        self.IsBattlePayItem    = false
        self.IsNewItem          = false
        self.IsUpgradeItem      = false
        self.IsArtifactRelicItem= false
    end
end

function handler:ReceiveAction(target, detail)
    return PickupContainerItem(target, detail)
end

function handler:HasAction()
    return GetContainerItemID(self.ActionTarget, self.ActionDetail) and true or false
end

function handler:GetActionTexture()
    return (GetContainerItemInfo(self.ActionTarget, self.ActionDetail))
end

function handler:GetActionCount()
    return (select(2, GetContainerItemInfo(self.ActionTarget, self.ActionDetail)))
end

function handler:GetActionCooldown()
    return GetContainerItemCooldown(self.ActionTarget, self.ActionDetail)
end

function handler:IsEquippedItem()
    return false
end

function handler:IsActivedAction()
    return false
end

function handler:IsUsableAction()
    local bag                   = self.ActionTarget

    if bag >= 0 and bag <= 4 then
        local item              = GetContainerItemID(bag, self.ActionDetail)
        return item and IsUsableItem(item)
    else
        return true
    end
end

function handler:IsConsumableAction()
    local item                  = GetContainerItemID(self.ActionTarget, self.ActionDetail)
    if not item then return false end

    local maxStack              = select(8, GetItemInfo(item)) or 0
    return maxStack > 1
end

function handler:IsInRange()
    local bag                   = self.ActionTarget
    if bag >= 0 and bag <= 4 then
        return IsItemInRange(GetContainerItemID(self.ActionTarget, self.ActionDetail), self:GetAttribute("unit"))
    end
end

function handler:IsSearchOverlayShow()
    return (select(8, GetContainerItemInfo(self.ActionTarget, self.ActionDetail)))
end

function handler:IsIconLocked()
    local _, _, locked          = GetContainerItemInfo(self.ActionTarget, self.ActionDetail)
    return locked
end

function handler:SetTooltip(GameTooltip)
    local bag                   = self.ActionTarget
    local slot                  = self.ActionDetail

    if bag == BANK_CONTAINER or bag == REAGENTBANK_CONTAINER then
        local invId

        if bag == BANK_CONTAINER then
            invId               = BankButtonIDToInvSlotID(slot)
        else
            invId               = ReagentBankButtonIDToInvSlotID(slot)
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

        local showSell          = nil
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
            showSell            = 1
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

__Sealed__()
class "ContainerFrameItemButton" (function(_ENV)
    inherit "SecureActionButton"

    import "System.Reactive"

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    --- The item's quality
    __Observable__()
    property "ItemQuality"      { type = Number }

    --- The item's quest status, true if actived quest, false if not actived quest, nil if not a quest item.
    __Observable__()
    property "ItemQuestStatus"  { type = Boolean }

    --- Whether the item is a new item
    __Observable__()
    property "IsNewItem"        { type = Boolean }

    --- Whether the item is a battle pay item
    __Observable__()
    property "IsBattlePayItem"  { type = Boolean }

    --- Whether show the item as junk
    __Observable__()
    property "IsJunk"           { type = Boolean }

    --- Whether the item is an upgrade item
    __Observable__()
    property "IsUpgradeItem"    { type = Boolean }

    --- Whether the item is an artifact relic item
    __Observable__()
    property "IsArtifactRelicItem" { type = Boolean }
end)

----------------------------------------
-- Client Patch
----------------------------------------
if Scorpio.IsRetail then return end

C_NewItems                      = _G.C_NewItems or {
    IsNewItem                   = Toolset.fakefunc,
    RemoveNewItem               = Toolset.fakefunc,
}

IsBattlePayItem                 = _G.IsBattlePayItem or Toolset.fakefunc
IsArtifactRelicItem             = _G.IsArtifactRelicItem or Toolset.fakefunc
GetContainerItemQuestInfo       = _G.GetContainerItemQuestInfo or Toolset.fakefunc