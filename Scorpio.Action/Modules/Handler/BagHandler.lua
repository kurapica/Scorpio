--========================================================--
--             Scorpio Secure Bag Handler                 --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.BagHandler"           "1.0.0"
--========================================================--

_Enabled                        = false

__Sealed__() enum "BagSlotCountStyle" { "Hidden", "Empty", "Total", "AllEmpty", "All" }

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
        local target = ...
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

        Manager:CallMethod("UpdateForPushItemAnim", self:GetName(), target)
    ]],

    ClearSnippet                = [[
        self:SetAttribute("*type*", nil)
        self:SetAttribute("*macrotext*", nil)
        Manager:CallMethod("UnregisterBankBag", self:GetName())
        Manager:CallMethod("UpdateForPushItemAnim", self:GetName(), false)
    ]],

    OnEnableChanged             = function(self, value) _Enabled = value end,
}

------------------------------------------------------
-- Module Event Handler
------------------------------------------------------
_BagSlotMapTemplate             = "_BagSlotMap[%d] = %d"

_, _EmptyTexture                = GetInventorySlotInfo("Bag0Slot")
NUM_BANKGENERIC_SLOTS           = _G.NUM_BANKGENERIC_SLOTS
_BagSlotMap                     = {}
_ContainerMap                   = {}

function OnEnable(self)
    OnEnable                    = nil

    local cache                 = {}

    -- Container
    _BagSlotMap[0]              = GetInventorySlotInfo("BackSlot")

    for i = 1, 11 do
        _BagSlotMap[i]          = ContainerIDToInventoryID(i)
        tinsert(cache, _BagSlotMapTemplate:format(i, _BagSlotMap[i]))
    end

    if next(cache) then
        NoCombat(function ()
            handler:RunSnippet( tblconcat(cache, ";") )

            for _, btn in handler:GetIterator() do
                local target    = tonumber(btn.ActionTarget)

                if target == 0 then
                    btn:SetAttribute("*type*", "macro")
                    btn:SetAttribute("*macrotext*", "/click MainMenuBarBackpackButton")
                elseif target and target <= 4 then
                    btn:SetAttribute("*type*", "macro")
                    btn:SetAttribute("*macrotext*", "/click CharacterBag".. tostring(target-1) .."Slot")
                elseif target and target <= 11 then
                    btn:SetAttribute("*type*", "openbank")
                    btn:SetAttribute("_openbank", [=[ self:GetFrameRef("_Manager"):RunFor(self, [[ Manager:CallMethod("OpenBankBag", self:GetName()) ]]) ]=])
                else
                    btn:SetAttribute("*type*", nil)
                    btn:SetAttribute("*macrotext*", nil)
                    btn:SetAttribute("_openbank", nil)
                end
                if target <= 4 then
                    local id    = target ~= 0 and _BagSlotMap[target] or target or false
                    IFPushItemAnim.AttachBag(btn, id)
                end
            end

            handler:RefreshAll()
        end)
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
                local flag = IsInventoryItemLocked(bag)
                for _, btn in handler() do
                    if btn.ActionTarget == i then btn.IconLocked = flag end
                end
                break
            end
        end
    end
end

function CURSOR_UPDATE()
    for _, btn in handler() do
        local target = _BagSlotMap[btn.ActionTarget]
        if target then
            btn.HighlightLocked = CursorCanGoInSlot(target)
        else
            btn.HighlightLocked = false
        end
    end
end

function BAG_UPDATE_DELAYED()
    for _, btn in handler() do
        handler:Refresh(btn)
        local target = _BagSlotMap[btn.ActionTarget]
        if target then
            btn.IconLocked = IsInventoryItemLocked(target)
        else
            btn.IconLocked = false
        end
    end
end

function PLAYERBANKBAGSLOTS_CHANGED()
    for _, btn in handler() do
        handler:Refresh(btn)
        local target = _BagSlotMap[btn.ActionTarget]
        if target then
            btn.IconLocked = IsInventoryItemLocked(target)
        else
            btn.IconLocked = false
        end
    end
end

function PLAYERBANKSLOTS_CHANGED(self, slot)
    if slot > NUM_BANKGENERIC_SLOTS then
        slot = slot - NUM_BANKGENERIC_SLOTS + NUM_BAG_FRAMES

        for _, btn in handler() do
            if btn.ActionTarget == slot then
                handler:Refresh(btn)
            end
        end
    end
end

function INVENTORY_SEARCH_UPDATE()
    for _, btn in handler() do
        btn.ShowSearchOverlay = IsContainerFiltered(btn.ActionTarget)
    end
end

-- Use Manager to control the IFPushItemAnim
IGAS:GetUI(handler.Manager).UpdateForPushItemAnim = function (self, name, target)
    local id = target ~= 0 and _BagSlotMap[target] or target or false
    return IFPushItemAnim.AttachBag(IGAS:GetWrapper(_G[name]), id)
end

IGAS:GetUI(handler.Manager).RegisterBankBag = function (self, btnName)
    Task.NoCombatCall(function()
        _G[btnName]:SetAttribute("_openbank", [=[ self:GetFrameRef("_Manager"):RunFor(self, [[ Manager:CallMethod("OpenBankBag", self:GetName()) ]]) ]=])
    end)
end

IGAS:GetUI(handler.Manager).UnregisterBankBag = function (self, btnName)
    Task.NoCombatCall(function()
        _G[btnName]:SetAttribute("_openbank",  nil)
    end)
end

IGAS:GetUI(handler.Manager).OpenBankBag = function (self, btnName)
    local bankID = IGAS:GetWrapper(_G[btnName]).BagSlot

    if bankID and not InCombatLockdown() then
        local inventoryID = BankButtonIDToInvSlotID(bankID-4, 1)
        local hadItem = PutItemInBag(inventoryID)
        if ( not hadItem ) then
            -- open bag
            ToggleBag(bankID)
        end
    end
end

IGAS:GetUI(handler.Manager).CloseContainerForSafe = function (self, id)
    if id and not InCombatLockdown() then
        CloseBag(id)
    end
end

-- Overwrite methods
function handler:RefreshButton()
    local bag = self.ActionTarget

    if bag > 4 then
        -- Check if buyed
        if bag - 4 <= GetNumBankSlots() then
            self.BagUsable = true
        else
            self.BagUsable = false
        end
    else
        self.BagUsable = true
    end
end


function handler:ReceiveAction(target, detail)
    if target == 0 then
        return PutItemInBackpack()
    elseif target and target <= 11 then
        return PutItemInBag(_BagSlotMap[target])
    end
end

function handler:HasAction()
    return _BagSlotMap[self.ActionTarget] and true or false
end

function handler:GetActionTexture()
    if self.ActionTarget == 0 then return MainMenuBarBackpackButtonIconTexture:GetTexture() end
    local target = _BagSlotMap[self.ActionTarget]
    return target and GetInventoryItemTexture("player", target) or _EmptyTexture
end

function handler:GetActionCharges()
    local style = self.BagSlotCountStyle
    if style == "Hidden" then
        return nil
    elseif style == "Empty" or style == "Total" then
        local free, total = GetContainerNumFreeSlots(self.ActionTarget), GetContainerNumSlots(self.ActionTarget)
        if style == "Empty" then
            return free, total
        else
            return total, total
        end
    elseif style == "AllEmpty" or style == "All" then
        if self.ActionTarget <= 4 then
            local sFree, sTotal, free, total, bagFamily = 0, 0
            local _, tarFamily = GetContainerNumFreeSlots(self.ActionTarget)
            if not tarFamily then return nil end
            for i = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
                free, bagFamily = GetContainerNumFreeSlots(i)
                total = GetContainerNumSlots(i)
                if bagFamily == tarFamily then
                    sFree = sFree + free
                    sTotal = sTotal + total
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
    local id = self.ActionTarget
    local containers = _ContainerMap[id]
    local flag = containers and containers[1] and containers[1].Visible
    if not flag and _ContainerMap[100] then
        for _, container in ipairs(_ContainerMap[100]) do
            if container.ID == id and container.Visible then
                return true
            end
        end
    end
    return flag
end

function handler:SetTooltip(GameTooltip)
    local target = self.ActionTarget
    if target == 0 then
        GameTooltip:SetText(BACKPACK_TOOLTIP, 1.0, 1.0, 1.0)
        local keyBinding = GetBindingKey("TOGGLEBACKPACK")
        if ( keyBinding ) then
            GameTooltip:AppendText(" "..NORMAL_FONT_COLOR_CODE.."("..keyBinding..")"..FONT_COLOR_CODE_CLOSE)
        end
        GameTooltip:AddLine(string.format(NUM_FREE_SLOTS, (self.__BagHandler_FreeSlots or 0)))
        GameTooltip:Show()
    elseif _BagSlotMap[target] then
        local id = _BagSlotMap[target]
        if ( GameTooltip:SetInventoryItem("player", id) ) then
            if id <= 4 then
                local bindingKey = GetBindingKey("TOGGLEBAG"..(5 -  target))
                if ( bindingKey ) then
                    GameTooltip:AppendText(" "..NORMAL_FONT_COLOR_CODE.."("..bindingKey..")"..FONT_COLOR_CODE_CLOSE)
                end
            end
            if (not IsInventoryItemProfessionBag("player", ContainerIDToInventoryID(target))) then
                for i = LE_BAG_FILTER_FLAG_EQUIPMENT, NUM_LE_BAG_FILTER_FLAGS do
                    if ( GetBagSlotFlag(target, i) ) then
                        GameTooltip:AddLine(BAG_FILTER_ASSIGNED_TO:format(BAG_FILTER_LABELS[i]))
                        break
                    end
                end
            end
            GameTooltip:Show()
        else
            GameTooltip:SetText(EQUIP_CONTAINER, 1.0, 1.0, 1.0)
        end
    else

    end
end

-- Expand IFActionHandler
interface "IFActionHandler"
    local function OnShowOrHide(self)
        return handler:Refresh(RefreshButtonState)
    end

    ------------------------------------------------------
    -- Static Method
    ------------------------------------------------------
    __Doc__[[
        <desc>Register container to control the bag slot button's button state</desc>
        <param name="container">the container frame</param>
        <param name="id" optional="true">the container index, un-register if false, use container's id if true</param>
    ]]
    __Static__()  __Arguments__{ Region, Argument(Number) }
    function RegisterContainer(container, id)
        container.OnShow = container.OnShow - OnShowOrHide
        container.OnHide = container.OnHide - OnShowOrHide
        for k, v in pairs(_ContainerMap) do
            for i, c in ipairs(v) do
                if c == container then
                    tremove(c, i)
                    break
                end
            end
        end

        _ContainerMap[id] = _ContainerMap[id] or {}
        tinsert(_ContainerMap[id], 1, container)

        container.OnShow = container.OnShow + OnShowOrHide
        container.OnHide = container.OnHide + OnShowOrHide
    end

    __Static__()  __Arguments__{ Region, Argument(Boolean, true, true) }
    function RegisterContainer(container, id)
        container.OnShow = container.OnShow - OnShowOrHide
        container.OnHide = container.OnHide - OnShowOrHide
        for k, v in pairs(_ContainerMap) do
            for i, c in ipairs(v) do
                if c == container then
                    tremove(c, i)
                    break
                end
            end
        end
        if id ~= false then
            id = 100

            _ContainerMap[id] = _ContainerMap[id] or {}
            tinsert(_ContainerMap[id], container)

            container.OnShow = container.OnShow + OnShowOrHide
            container.OnHide = container.OnHide + OnShowOrHide
        end
    end

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    __Doc__[[The action button's content if its type is 'bag']]
    property "BagSlot" {
        Get = function(self)
            return self:GetAttribute("actiontype") == "bag" and tonumber(self:GetAttribute("bag"))
        end,
        Set = function(self, value)
            self:SetAction("bag", value)
        end,
        Type = struct { 0,
            function (value)
                assert(type(value) == "number", "%s must be number.")
                assert(value >= 0 and value <= 11, "%s must between [0-11]")
                return math.floor(value)
            end
        },
    }

    __Doc__[[Whether the bag is usable]]
    property "BagUsable" { Type = Boolean, Default = true }

    __Doc__[[What to be shown as the count]]
    __Handler__(RefreshCount)
    property "BagSlotCountStyle" { Type = BagSlotCountStyle, Default = "Hidden" }
endinterface "IFActionHandler"

-- Init the _ContainerMap
for i=1, NUM_CONTAINER_FRAMES do IFActionHandler.RegisterContainer(IGAS["ContainerFrame"..i]) end