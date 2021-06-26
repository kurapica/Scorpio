--========================================================--
--             Scorpio Secure Bag Handler                 --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.BagHandler"           "1.0.0"
--========================================================--

__Sealed__() enum "BagSlotCountStyle" { "Hidden", "Empty", "Total", "AllEmpty", "All" }

_Enabled                        = false

------------------------------------------------------
-- Action Handler
------------------------------------------------------
handler                         = ActionTypeHandler {
    Name                        = "bag",
    DragStyle                   = "Keep",
    ReceiveStyle                = "Keep",

    InitSnippet                 = [[ _BagSlotMap = newtable() ]],

    PickupSnippet               = [[
        local id                = ...
        if id ~= 0 then
            Manager:CallMethod("CloseContainerForSafe", id)
            return "clear", "bag", _BagSlotMap[id]
        end
    ]],

    ReceiveSnippet              = "Custom",

    UpdateSnippet               = [[
        local target            = ...
        target                  = tonumber(target)

        if target == 0 then
            self:SetAttribute("*type*", "macro")
            self:SetAttribute("*macrotext*", "/click MainMenuBarBackpackButton")
        elseif target and target <= 4 then
            self:SetAttribute("*type*", "macro")
            self:SetAttribute("*macrotext*", "/click CharacterBag".. tostring(target-1) .."Slot")
        elseif target and target <= 11 then
            self:SetAttribute("*type*", "openbank")
            Manager:CallMethod("RegisterBankBag", self:GetName())
        else
            self:SetAttribute("*type*", nil)
            self:SetAttribute("*macrotext*", nil)
            Manager:CallMethod("UnregisterBankBag", self:GetName())
        end
    ]],

    ClearSnippet                = [[
        self:SetAttribute("*type*", nil)
        self:SetAttribute("*macrotext*", nil)
        Manager:CallMethod("UnregisterBankBag", self:GetName())
    ]],

    OnEnableChanged             = function(self, value) _Enabled = value end,
}

------------------------------------------------------
-- Module Event Handler
------------------------------------------------------
_BagSlotMapTemplate             = "_BagSlotMap[%d] = %d"

_, _EmptyTexture                = GetInventorySlotInfo("Bag0Slot")
_BagSlotMap                     = {}
_ContainerMap                   = {}

_IconLocked                     = {}

function OnEnable(self)
    OnEnable                    = nil

    local cache                 = {}

    -- Container
    _BagSlotMap[0]              = GetInventorySlotInfo("BackSlot")

    for i = 1, 11 do
        _BagSlotMap[i]          = ContainerIDToInventoryID(i)
        tinsert(cache, _BagSlotMapTemplate:format(i, _BagSlotMap[i]))
    end

    handler:RunSnippet( tblconcat(cache, ";") )
    handler:RefreshActionButtons()

    for i = 1, NUM_CONTAINER_FRAMES do
        SecureActionButton.RegisterContainer(_G["ContainerFrame"..i])
    end
end

------------------------------------------------------
-- System Event Handler
------------------------------------------------------
__SystemEvent__()
function ITEM_LOCK_CHANGED(bag, slot)
    if not slot then
        for i, map in pairs(_BagSlotMap) do
            if map == bag then
                _IconLocked[i]  = IsInventoryItemLocked(bag)

                return handler:RefreshIconLocked()
            end
        end
    end
end

__SystemEvent__"BAG_UPDATE_DELAYED" "PLAYERBANKBAGSLOTS_CHANGED"
function BAG_UPDATE_DELAYED()
    return handler:RefreshActionButtons()
end

__SystemEvent__()
function PLAYERBANKSLOTS_CHANGED(slot)
    if slot > NUM_BANKGENERIC_SLOTS then
        slot = slot - NUM_BANKGENERIC_SLOTS + NUM_BAG_FRAMES

        for _, btn in handler:GetIterator() do
            if btn.ActionTarget == slot then
                handler:RefreshActionButtons(btn)
            end
        end
    end
end

__SystemEvent__()
function INVENTORY_SEARCH_UPDATE()
    return handler:RefreshShowSearchOverlay()
end

__SecureMethod__() __NoCombat__()
function handler.Manager:RegisterBankBag(btnName)
    _G[btnName]:SetAttribute("_openbank", [=[ self:GetFrameRef("_Manager"):RunFor(self, [[ Manager:CallMethod("OpenBankBag", self:GetName()) ]]) ]=])
end

__SecureMethod__() __NoCombat__()
function handler.Manager:UnregisterBankBag(btnName)
    _G[btnName]:SetAttribute("_openbank",  nil)
end

__SecureMethod__()
function handler.Manager:OpenBankBag(btnName)
    local button                = UI.GetProxyUI(_G[btnName])
    local bankID                = button.BagSlot

    if bankID and not InCombatLockdown() then
        local inventoryID       = BankButtonIDToInvSlotID(bankID - 4, 1)
        if not PutItemInBag(inventoryID) then
            -- open bag
            ToggleBag(bankID)
        end
    end
end

__SecureMethod__()
function handler.Manager:CloseContainerForSafe(id)
    if id and not InCombatLockdown() then
        CloseBag(id)
    end
end

-- Overridable Methods
function handler:IsUsableAction()
    return self.ActionTarget - 4 <= GetNumBankSlots()
end

function handler:ReceiveAction(target, detail)
    if target == 0 then
        return PutItemInBackpack()
    elseif _BagSlotMap[target] then
        return PutItemInBag(_BagSlotMap[target])
    end
end

function handler:HasAction()
    return _BagSlotMap[self.ActionTarget] and true or false
end

function handler:IsSearchOverlayShow()
    return IsContainerFiltered(self.ActionTarget)
end

function handler:IsIconLocked()
    return _IconLocked[self.ActionTarget] or false
end

function handler:GetActionTexture()
    if self.ActionTarget == 0 then return MainMenuBarBackpackButtonIconTexture:GetTexture() end
    local target                = _BagSlotMap[self.ActionTarget]
    return target and GetInventoryItemTexture("player", target) or _EmptyTexture
end

function handler:GetActionCharges()
    local style                 = self.BagSlotCountStyle

    if style == "Hidden" then
        return nil
    elseif style == "Empty" or style == "Total" then
        local free, total       = GetContainerNumFreeSlots(self.ActionTarget), GetContainerNumSlots(self.ActionTarget)
        if style == "Empty" then
            return free, total
        else
            return total, total
        end
    elseif style == "AllEmpty" or style == "All" then
        if self.ActionTarget <= 4 then
            local sFree, sTotal, free, total, bagFamily = 0, 0
            local _, tarFamily  = GetContainerNumFreeSlots(self.ActionTarget)
            if not tarFamily then return nil end

            for i = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
                free, bagFamily = GetContainerNumFreeSlots(i)
                total           = GetContainerNumSlots(i)
                if bagFamily == tarFamily then
                    sFree       = sFree + free
                    sTotal      = sTotal + total
                end
            end
            if self.ActionTarget == 0 then
                self.__BagHandler_FreeSlots = sFree
            end
            if style == "AllEmpty" then
                return sFree, sTotal
            else
                return sTotal, sTotal
            end
        else
            return nil
        end
    end
end

function handler:IsActivedAction()
    local id                    = self.ActionTarget
    for container in pairs(_ContainerMap) do
        if container:GetID() == id and container:IsVisible() then
            return true
        end
    end
    return false
end

function handler:SetTooltip(tip)
    local target                = self.ActionTarget
    if target == 0 then
        tip:SetText(BACKPACK_TOOLTIP, 1.0, 1.0, 1.0)
        local keyBinding        = GetBindingKey("TOGGLEBACKPACK")
        if ( keyBinding ) then
            tip:AppendText(" "..NORMAL_FONT_COLOR_CODE.."("..keyBinding..")"..FONT_COLOR_CODE_CLOSE)
        end
        tip:AddLine(string.format(NUM_FREE_SLOTS, (self.__BagHandler_FreeSlots or 0)))
        tip:Show()
    elseif _BagSlotMap[target] then
        local id                = _BagSlotMap[target]
        if ( tip:SetInventoryItem("player", id) ) then
            if id <= 4 then
                local bindingKey = GetBindingKey("TOGGLEBAG"..(5 -  target))
                if ( bindingKey ) then
                    tip:AppendText(" "..NORMAL_FONT_COLOR_CODE.."("..bindingKey..")"..FONT_COLOR_CODE_CLOSE)
                end
            end
            if (not IsInventoryItemProfessionBag("player", ContainerIDToInventoryID(target))) then
                for i = LE_BAG_FILTER_FLAG_EQUIPMENT, NUM_LE_BAG_FILTER_FLAGS do
                    if ( GetBagSlotFlag(target, i) ) then
                        tip:AddLine(BAG_FILTER_ASSIGNED_TO:format(BAG_FILTER_LABELS[i]))
                        break
                    end
                end
            end
            tip:Show()
        else
            tip:SetText(EQUIP_CONTAINER, 1.0, 1.0, 1.0)
        end
    else

    end
end

-- Expand IFActionHandler
class "SecureActionButton" (function(_ENV)
    local function OnShowOrHide(self)
        return handler:RefreshButtonState()
    end

    ------------------------------------------------------
    -- Static Method
    ------------------------------------------------------
    __Static__() __Arguments__{ UI }
    function RegisterContainer(container)
        if _ContainerMap[container] then return end
        _ContainerMap[container]= true

        container:HookScript("OnShow", OnShowOrHide)
        container:HookScript("OnHide", OnShowOrHide)
    end

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    --- What to be shown as the count
    property "BagSlotCountStyle" { type = BagSlotCountStyle, default = "Hidden", handler = function(self) return handler:RefreshCount(self) end }
end)
