--========================================================--
--             Scorpio Secure Action Button               --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/11/16                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.SecureActionButton"   "1.0.0"
--========================================================--

export { GetProxyUI             = UI.GetProxyUI }

_ManagerFrame                   = SecureFrame("Scorpio_SecureActionButton_Manager", UIParent, "SecureHandlerStateTemplate")
_ManagerFrame:Hide()

_IFActionTypeHandler            = {}

_ActionTypeMap                  = {}
_ActionTargetMap                = {}
_ActionTargetDetail             = {}
_ReceiveMap                     = {}

_ActionButtonGroupList          = {}

_AutoAttackButtons              = {}
_AutoRepeatButtons              = {}
_RangeCheckButtons              = {}
_Spell4Buttons                  = {}

local _GridCounter              = 0
local _PetGridCounter           = 0
local _OnTooltipButton
local _KeyBindingMap            = {}
local _Locale                   = _Locale

IsSpellOverlayed                = _G.IsSpellOverlayed or Toolset.fakefunc

------------------------------------------------------
--               Module Event Handler               --
------------------------------------------------------
function OnLoad()
    _SVData.Char:SetDefault {
        SecureActionButtonNoDragGroup   = {},
        SecureActionButtonMouseDownGroup= {},
    }

    _NoDragGroup                = _SVData.Char.SecureActionButtonNoDragGroup
    _MouseDownGroup             = _SVData.Char.SecureActionButtonMouseDownGroup

    for group, val in pairs(_NoDragGroup) do
        if val then DisableDrag(group) end
    end
end

__Service__(true)
function RangeCheckerService()
    while true do
        for i = 1, 99999 do
            local button        = _RangeCheckButtons[i]
            if not button then
                if i == 1 then NextEvent("SCORPIO_SAB_RANGE_CHECK") end
                break
            end

            _IFActionTypeHandler[button.ActionType]:RefreshRange(button)
            if i % 20 == 0 then Continue() end
        end

        Wait(0.2, "PLAYER_TARGET_CHANGED")
    end
end

__SystemEvent__()
function ACTIONBAR_SHOWGRID()
    _GridCounter                = _GridCounter + 1
    if _GridCounter == 1 then
        for kind, handler in pairs(_IFActionTypeHandler) do
            if handler.IsPlayerAction and handler.ReceiveStyle ~= "Block" then
                handler:RefershGrid()
            end
        end
    end
end

__SystemEvent__()
function ACTIONBAR_HIDEGRID()
    if _GridCounter > 0 then
        _GridCounter            = _GridCounter - 1
        if _GridCounter == 0 then
            for kind, handler in pairs(_IFActionTypeHandler) do
                if handler.IsPlayerAction and handler.ReceiveStyle ~= "Block" then
                    handler:RefershGrid()
                end
            end
        end
    end
end

__SystemEvent__()
function PET_BAR_SHOWGRID()
    _PetGridCounter             = _PetGridCounter + 1
    if _PetGridCounter == 1 then
        for kind, handler in pairs(_IFActionTypeHandler) do
            if handler.IsPetAction and handler.ReceiveStyle ~= "Block" then
                handler:RefershGrid()
            end
        end
    end
end

__SystemEvent__()
function PET_BAR_HIDEGRID()
    if _PetGridCounter > 0 then
        _PetGridCounter         = _PetGridCounter - 1
        if _PetGridCounter == 0 then
            for kind, handler in pairs(_IFActionTypeHandler) do
                if handler.IsPetAction and handler.ReceiveStyle ~= "Block" then
                    handler:RefershGrid()
                end
            end
        end
    end
end

__SystemEvent__()
function PLAYER_ENTER_COMBAT()
    for button in pairs(_AutoAttackButtons) do
        button.IsAutoAttacking = true
    end
end

__SystemEvent__()
function PLAYER_LEAVE_COMBAT()
    for button in pairs(_AutoAttackButtons) do
        button.IsAutoAttacking = false
    end
end

__SystemEvent__()
function SPELL_ACTIVATION_OVERLAY_GLOW_SHOW(spellId)
    local buttons               = _Spell4Buttons[spellId]
    if not buttons then return end

    if getmetatable(buttons) then
        buttons.OverlayGlow     = true
    else
        for button in pairs(buttons) do
            button.OverlayGlow  = true
        end
    end
end

__SystemEvent__()
function SPELL_ACTIVATION_OVERLAY_GLOW_HIDE(spellId)
    local buttons               = _Spell4Buttons[spellId]
    if not buttons then return end

    if getmetatable(buttons) then
        buttons.OverlayGlow     = false
    else
        for button in pairs(buttons) do
            button.OverlayGlow  = false
        end
    end
end

__SystemEvent__()
function SPELL_UPDATE_CHARGES()
    for kind, handler in pairs(_IFActionTypeHandler) do
        handler:RefreshCount()
    end
end

__SystemEvent__()
function START_AUTOREPEAT_SPELL()
    for button in pairs(_AutoRepeatButtons) do
        if not _AutoAttackButtons[button] then
            button.IsAutoAttacking = true
        end
    end
end

__SystemEvent__()
function STOP_AUTOREPEAT_SPELL()
    for button in pairs(_AutoRepeatButtons) do
        if button.IsAutoAttacking and not _AutoAttackButtons[button] then
            button.IsAutoAttacking = false
        end
    end
end

__SystemEvent__ "ARCHAEOLOGY_CLOSED" "TRADE_SKILL_SHOW" "TRADE_SKILL_CLOSE"
function TRADE_SKILL_SHOW()
    for kind, handler in pairs(_IFActionTypeHandler) do
        handler:RefreshButtonState()
    end
end

__SystemEvent__"UNIT_ENTERED_VEHICLE" "UNIT_EXITED_VEHICLE"
function UNIT_ENTERED_VEHICLE(unit)
    if unit == "player" then
        for kind, handler in pairs(_IFActionTypeHandler) do
            handler:RefreshButtonState()
        end
    end
end

__SystemEvent__"UNIT_INVENTORY_CHANGED" "LEARNED_SPELL_IN_TAB" "ACTIONBAR_UPDATE_COOLDOWN"
function UNIT_INVENTORY_CHANGED(unit)
    return (not unit or unit == "player") and _OnTooltipButton and _OnTooltipButton:UpdateTooltip()
end

__SystemEvent__() __Async__()
function PET_BATTLE_OPENING_START()
    for i = 1, 6 do
        local key               = tostring(i)
        local button            = _KeyBindingMap[key]
        if button then ClearOverrideBindings(GetRawUI(button)) end
    end

    NextEvent("PET_BATTLE_CLOSE") NoCombat()

    for i = 1, 6 do
        local key               = tostring(i)
        local button            = _KeyBindingMap[key]
        if button then SetOverrideBindingClick(GetRawUI(button), false, key, button:GetName(), "LeftButton") end
    end
end

------------------------------------------------------
--               Action Type Handler                --
------------------------------------------------------
__Sealed__()
enum "ActionTypeHandleStyle" { "Keep", "Clear", "Block" }

-- The handler for action types
__Sealed__() __AnonymousClass__()
interface "ActionTypeHandler" (function(_ENV)
    extend "IList"

    _RegisterSnippetTemplate    = "%s[%q] = %q"

    _ActionButtonMap            = Toolset.newtable(true, true)

    local function refreshButton(self, button)
        _AutoAttackButtons[button] = self.IsAttackAction(button) or nil
        _AutoRepeatButtons[button] = self.IsAutoRepeatAction(button) or nil

        button.HasAction        = self.HasAction(button)
        button.IsAutoAttack     = _AutoAttackButtons[button] or _AutoRepeatButtons[button]

        local spell             = self.GetSpellId(button)
        local ospell            = _Spell4Buttons[button]

        if ospell ~= spell then
            if ospell then
                local buttons   = _Spell4Buttons[ospell]
                if getmetatable(buttons) == nil then
                    buttons[button] = nil
                elseif buttons == button then
                    _Spell4Buttons[ospell] = nil
                end
            end

            if spell then
                local buttons   = _Spell4Buttons[spell]
                if buttons == nil then
                    _Spell4Buttons[spell] = button
                elseif getmetatable(buttons) == nil then
                    buttons[button] = true
                else
                    buttons     = { [buttons] = true }
                    buttons[button] = true

                    _Spell4Buttons[spell] = buttons
                end
            end

            _Spell4Buttons[button] = spell
        end

        if self.IsRangeSpell(button) then
            if not _RangeCheckButtons[button] then
                local index     = #_RangeCheckButtons + 1
                _RangeCheckButtons[button] = true
                _RangeCheckButtons[index]  = button

                if index == 1 then FireSystemEvent("SCORPIO_SAB_RANGE_CHECK") end
            end
        else
            if _RangeCheckButtons[button] then
                for i = 1, #_RangeCheckButtons do
                    if _RangeCheckButtons[i] == button then
                        tremove(_RangeCheckButtons, i)
                        break
                    end
                end
                _RangeCheckButtons[button] = nil
            end
        end

        if self.ReceiveStyle ~= "Block" then
            self:RefershGrid(button)
        end

        self:RefreshButtonState(button)
        self:RefreshUsable(button)
        self:RefreshCooldown(button)
        self:RefreshFlyout(button)
        self:RefreshAutoCastable(button)
        self:RefreshAutoCasting(button)
        self:RefreshEquipItem(button)
        self:RefreshText(button)
        self:RefreshIcon(button)
        self:RefreshCount(button)
        self:RefreshOverlayGlow(button)
        self:Refresh(button)

        if _OnTooltipButton == button then
            return button:UpdateTooltip()
        end
    end

    ------------------------------------------------------
    -- Event
    ------------------------------------------------------
    -- Fired when the handler is enabled or disabled
    event "OnEnableChanged"

    ------------------------------------------------------
    -- Refresh Method
    ------------------------------------------------------
    function RefershGrid(self, button)
        local force             = (self.IsPlayerAction and _GridCounter or _PetGridCounter) > 0
        local HasAction         = self.HasAction

        if button then
            button.GridVisible  = force or HasAction(button)
        else
            for _, button in self:GetIterator() do
                button.GridVisible = force or HasAction(button)
            end
        end
    end

    function RefreshButtonState(self, button)
        local IsActivedAction   = self.IsActivedAction
        local IsAutoRepeatAction= self.IsAutoRepeatAction

        if button then
            button:SetChecked(IsActivedAction(button) or IsAutoRepeatAction(button))
        else
            for _, button in self:GetIterator() do
                button:SetChecked(IsActivedAction(button) or IsAutoRepeatAction(button))
            end
        end
    end

    function RefreshUsable(self, button)
        local IsUsableAction   = self.IsUsableAction

        if button then
            button.IsUsable    = IsUsableAction(button)
        else
            for _, button in self:GetIterator() do
                button.IsUsable= IsUsableAction(button)
            end
        end
    end

    function RefreshCount(self, button)
        local IsConsumableAction= self.IsConsumableAction
        local GetActionCount    = self.GetActionCount
        local GetActionCharges  = self.GetActionCharges

        if button then
            if IsConsumableAction(button) then
                button.Count    = GetActionCount(button)
            else
                local cha, max  = GetActionCharges(button)
                if max and max > 1 then
                    button.Count= cha
                else
                    button.Count= nil
                end
            end
        else
            for _, button in self:GetIterator() do
                if IsConsumableAction(button) then
                    button.Count    = GetActionCount(button)
                else
                    local cha, max  = GetActionCharges(button)
                    if max and max > 1 then
                        button.Count= cha
                    else
                        button.Count= nil
                    end
                end
            end
        end
    end

    local shareCooldown         = { start = 0, duration = 0 }
    function RefreshCooldown(self, button)
        local GetActionCooldown = self.GetActionCooldown

        if button then
            shareCooldown.start, shareCooldown.duration = GetActionCooldown(button)
            button.Cooldown     = shareCooldown
        else
            for _, button in self:GetIterator() do
                shareCooldown.start, shareCooldown.duration = GetActionCooldown(button)
                button.Cooldown = shareCooldown
            end
        end
    end

    function RefreshFlash(self, button)
        local IsAttackAction    = self.IsAttackAction
        local IsActivedAction   = self.IsActivedAction
        local IsAutoRepeatAction= self.IsAutoRepeatAction

        if button then
            button.IsAutoAttacking = (IsAttackAction(button) and IsActivedAction(button)) or IsAutoRepeatAction(button)
        else
            for _, button in self:GetIterator() do
                button.IsAutoAttacking = (IsAttackAction(button) and IsActivedAction(button)) or IsAutoRepeatAction(button)
            end
        end
    end

    function RefreshOverlayGlow(self, button)
        local GetSpellId        = self.GetSpellId

        if button then
            local spellId       = GetSpellId(button)
            self.OverlayGlow    = spellId and IsSpellOverlayed(spellId)
        else
            for _, button in self:GetIterator() do
                local spellId   = GetSpellId(button)
                self.OverlayGlow= spellId and IsSpellOverlayed(spellId)
            end
        end
    end

    function RefreshRange(self, button)
        local IsInRange         = self.IsInRange

        if button then
            button.InRange      = IsInRange(button)
        else
            for _, button in self:GetIterator() do
                button.InRange  = IsInRange(button)
            end
        end
    end

    function RefreshFlyout(self, button)
        local IsFlyout          = self.IsFlyout

        if button then
            if button.IsCustomFlyout then return end
            button.IsFlyout     = IsFlyout(button)
        else
            for _, button in self:GetIterator() do
                if not button.IsCustomFlyout then
                    button.IsFlyout = IsFlyout(button)
                end
            end
        end
    end

    function RefreshAutoCastable(self, button)
        local IsAutoCastAction  = self.IsAutoCastAction

        if button then
            button.IsAutoCastable= IsAutoCastAction(button)
        else
            for _, button in self:GetIterator() do
                button.IsAutoCastable = IsAutoCastAction(button)
            end
        end
    end

    function RefreshAutoCasting(self, button)
        local IsAutoCasting     = self.IsAutoCasting

        if button then
            button.IsAutoCasting= IsAutoCasting(button)
        else
            for _, button in self:GetIterator() do
                button.IsAutoCasting = IsAutoCasting(button)
            end
        end
    end

    function RefreshIcon(self, button)
        local GetActionTexture  = self.GetActionTexture

        if button then
            button.Icon         = GetActionTexture(button)
        else
            for _, button in self:GetIterator() do
                button.Icon     = GetActionTexture(button)
            end
        end
    end

    function RefreshEquipItem(self, button)
        local IsEquippedItem    = self.IsEquippedItem

        if button then
            button.IsEquippedItem       = IsEquippedItem(button)
        else
            for _, button in self:GetIterator() do
                button.IsEquippedItem   = IsEquippedItem(button)
            end
        end
    end

    function RefreshText(self, button)
        local IsConsumableAction= self.IsConsumableAction
        local GetActionText     = self.GetActionText

        if button then
            button.Text         = IsConsumableAction(button) and "" or GetActionText(button)
        else
            for _, button in self:GetIterator() do
                button.Text     = IsConsumableAction(button) and "" or GetActionText(button)
            end
        end
    end

    __Delegate__(Continue)
    function RefreshActionButtons(self, button)
        local refresh           = refreshButton

        if button then
            -- The button may change its action type when waiting
            return button.ActionType == self.Type and refresh(self, button)
        else
            for _, button in self:GetIterator() do
                refresh(self, button)
                Continue()
            end
        end
    end

    ------------------------------------------------------
    -- Method
    ------------------------------------------------------
    GetIterator                 = ipairs

    function Insert(self, button)
        local oldHandler        = _ActionButtonMap[button]

        if oldHandler then
            if oldHandler == self then return end
            oldHandler:Remove(button)
        end

        _ActionButtonMap[button]= self
        tinsert(self, button)

        self.Enabled            = true
    end

    function Remove(self, button)
        if _ActionButtonMap[button] ~= self then return end
        _ActionButtonMap[button]= nil

        for i, v in ipairs(self) do if v == button then tremove(self, i) break end end

        self.Enabled            = self[1] and true or false
    end

    -- Run the snippet in the global environment
    __NoCombat__()
    function RunSnippet(self, code)
        return self.Manager:Execute(code)
    end

    ------------------------------------------------------
    -- Overridable Method For Action Buttons
    ------------------------------------------------------
    -- Get the actions's kind, target, detail
    function GetActionDetail(self)
        local name              = self:GetAttribute("actiontype")
        return self:GetAttribute(_ActionTargetMap[name]), _ActionTargetDetail[name] and self:GetAttribute(_ActionTargetDetail[name])
    end

    -- Map the action
    function Map(self, ...) return ... end

    -- The refresh logic
    function Refresh(self) end

    -- Custom pick up action
    function PickupAction(self, target, detail)  end

    -- Custom receive action
    function ReceiveAction(self, target, detail) end

    -- Whether the action button has an action
    function HasAction(self) return true end

    -- Get the action's text
    function GetActionText(self) return "" end

    -- Get the action's texture
    function GetActionTexture(self) end

    -- Get the action's charges
    function GetActionCharges(self) end

    -- Get the action's count
    function GetActionCount(self) return 0 end

    -- Get the action's cooldown
    function GetActionCooldown(self) return 0, 0, 0 end

    -- Whether the action is attackable
    function IsAttackAction(self) return false end

    -- Whether the action is an item and can be equipped
    function IsEquippedItem(self) return false end

    -- Whether the action is actived
    function IsActivedAction(self) return false end

    -- Whether the action is auto-repeat
    function IsAutoRepeatAction(self) return false end

    -- Whether the action is usable
    function IsUsableAction(self) return true end

    -- Whether the action is consumable
    function IsConsumableAction(self) return false end

    -- Whether the action is in range of the target
    function IsInRange(self) return end

    -- Whether the action is auto-castable
    function IsAutoCastAction(self) return false end

    -- Whether the action is auto-casting now
    function IsAutoCasting(self) return false end

    -- Show the tooltip for the action
    function SetTooltip(self, tip) end

    -- Get the spell id of the action
    function GetSpellId(self) end

    -- Whether the action is a flyout spell
    function IsFlyout(self) return false end

    -- Whether the action has range spell
    function IsRangeSpell(self) return false end

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    -- The manager of the action system
    property "Manager"          { default = _ManagerFrame, set = false }

    -- Whether the handler is enabled(has buttons)
    property "Enabled"          { type = Boolean, event = "OnEnableChanged" }

    -- The action's name
    property "Name"             { type = String }

    -- The action type's type
    property "Type"             { type = String }

    -- The target attribute name
    property "Target"           { type = String }

    -- The detail attribute name
    property "Detail"           { type = String }

    -- Whether the action is player action
    property "IsPlayerAction"   { type = Boolean, default = true }

    -- Whether the action is pet action
    property "IsPetAction"      { type = Boolean, default = false }

    -- The drag style of the action type
    property "DragStyle"        { type = ActionTypeHandleStyle, default = ActionTypeHandleStyle.Clear }

    -- The receive style of the action type
    property "ReceiveStyle"     { type = ActionTypeHandleStyle, default = ActionTypeHandleStyle.Clear }

    -- The receive map
    property "ReceiveMap"       { type = String }

    -- The pickup map
    property "PickupMap"        { type = String }

    -- The snippet to setup environment for the action type
    property "InitSnippet"      { type = String }

    -- The snippet used when pick up action
    property "PickupSnippet"    { type = String }

    -- The snippet used to update for new action settings
    property "UpdateSnippet"    { type = String }

    -- The snippet used to receive action
    property "ReceiveSnippet"   { type = String }

    -- The snippet used to clear action
    property "ClearSnippet"     { type = String }

    -- The snippet used for pre click
    property "PreClickSnippet"  { type = String }

    -- The snippet used for post click
    property "PostClickSnippet" { type = String }

    ------------------------------------------------------
    -- Initialize
    ------------------------------------------------------
    function __init(self)
        -- No repeat definition for action types
        if _IFActionTypeHandler[self.Name] then return end

        -- Register the action type handler
        _IFActionTypeHandler[self.Name] = self

        -- Default map
        if self.Type       == nil then self.Type        = self.Name end
        if self.Target     == nil then self.Target      = self.Type end
        if self.PickupMap  == nil then self.PickupMap   = self.Type end
        if self.ReceiveMap == nil and self.ReceiveStyle == "Clear" then self.ReceiveMap = self.Type end

        -- Register action type map
        _ActionTypeMap[self.Name]       = self.Type
        _ActionTargetMap[self.Name]     = self.Target
        _ActionTargetDetail[self.Name]  = self.Detail

        self:RunSnippet( _RegisterSnippetTemplate:format("_ActionTypeMap", self.Name, self.Type) )
        self:RunSnippet( _RegisterSnippetTemplate:format("_ActionTargetMap", self.Name, self.Target) )
        if self.Detail              then self:RunSnippet( _RegisterSnippetTemplate:format("_ActionTargetDetail", self.Name, self.Detail) ) end

        -- Init the environment
        if self.InitSnippet         then self:RunSnippet( self.InitSnippet ) end

        -- Register PickupSnippet
        if self.PickupSnippet       then self:RunSnippet( _RegisterSnippetTemplate:format("_PickupSnippet", self.Name, self.PickupSnippet) ) end

        -- Register UpdateSnippet
        if self.UpdateSnippet       then self:RunSnippet( _RegisterSnippetTemplate:format("_UpdateSnippet", self.Name, self.UpdateSnippet) ) end

        -- Register ReceiveSnippet
        if self.ReceiveSnippet      then self:RunSnippet( _RegisterSnippetTemplate:format("_ReceiveSnippet", self.Name, self.ReceiveSnippet) ) end

        -- Register ClearSnippet
        if self.ClearSnippet        then self:RunSnippet( _RegisterSnippetTemplate:format("_ClearSnippet", self.Name, self.ClearSnippet) ) end

        -- Register DragStyle
        self:RunSnippet( _RegisterSnippetTemplate:format("_DragStyle", self.Name, self.DragStyle) )

        -- Register ReceiveStyle
        self:RunSnippet( _RegisterSnippetTemplate:format("_ReceiveStyle", self.Name, self.ReceiveStyle) )

        -- Register ReceiveMap
        if self.ReceiveMap then
            self:RunSnippet( _RegisterSnippetTemplate:format("_ReceiveMap", self.ReceiveMap, self.Name) )
            _ReceiveMap[self.ReceiveMap] = self
        end

        -- Register PickupMap
        if self.PickupMap           then self:RunSnippet( _RegisterSnippetTemplate:format("_PickupMap", self.Name, self.PickupMap) ) end

        -- Register PreClickMap
        if self.PreClickSnippet     then self:RunSnippet( _RegisterSnippetTemplate:format("_PreClickSnippet", self.Name, self.PreClickSnippet) ) end

        -- Register PostClickMap
        if self.PostClickSnippet    then self:RunSnippet( _RegisterSnippetTemplate:format("_PostClickSnippet", self.Name, self.PostClickSnippet) ) end

        -- Clear
        self.InitSnippet            = nil
        self.PickupSnippet          = nil
        self.UpdateSnippet          = nil
        self.ReceiveSnippet         = nil
        self.ClearSnippet           = nil
        self.PreClickSnippet        = nil
        self.PostClickSnippet       = nil
    end
end)

------------------------------------------------------
--              Action Button Manager               --
------------------------------------------------------
__SecureMethod__()
function _ManagerFrame:OnPickUp(kind, target, detail)
    return not InCombatLockdown() and PickupAny("clear", kind, target, detail)
end

__SecureMethod__()
function _ManagerFrame:OnReceive(kind, target, detail)
    return not InCombatLockdown() and _IFActionTypeHandler[kind] and _IFActionTypeHandler[kind]:ReceiveAction(target, detail)
end

__SecureMethod__()
function _ManagerFrame:UpdateActionButton(name)
    self                        = GetProxyUI(_G[name])

    local name                  = self:GetAttribute("actiontype")
    local handler               = _IFActionTypeHandler[name]
    local target, detail        = handler.GetActionDetail(self)

    if self.__IFActionHandler_Kind ~= name
        or self.__IFActionHandler_Target ~= target
        or self.__IFActionHandler_Detail ~= detail then

        if self.__IFActionHandler_Kind and self.__IFActionHandler_Kind ~= name then
            _IFActionTypeHandler[self.__IFActionHandler_Kind]:Remove(self)
        end

        self.__IFActionHandler_Kind     = name
        self.__IFActionHandler_Target   = target
        self.__IFActionHandler_Detail   = detail

        handler:Insert(self)
        return handler:RefreshActionButtons(self)
    end
end

------------------------------------------------------
--                  Secure Snippet                  --
------------------------------------------------------
do
    -- Init manger frame's enviroment
    _ManagerFrame:Execute[[
        -- to fix blz error, use Manager not control
        Manager                 = self

        _NoDraggable            = newtable()

        _ActionTypeMap          = newtable()
        _ActionTargetMap        = newtable()
        _ActionTargetDetail     = newtable()

        _ReceiveMap             = newtable()
        _PickupMap              = newtable()

        _ClearSnippet           = newtable()
        _UpdateSnippet          = newtable()
        _PickupSnippet          = newtable()
        _ReceiveSnippet         = newtable()
        _PreClickSnippet        = newtable()
        _PostClickSnippet       = newtable()

        _DragStyle              = newtable()
        _ReceiveStyle           = newtable()

        UpdateAction            = [=[
            local name          = self:GetAttribute("actiontype")

            -- Custom update
            if _UpdateSnippet[name] then
                Manager:RunFor(
                    self, _UpdateSnippet[name],
                    self:GetAttribute(_ActionTargetMap[name]),
                    _ActionTargetDetail[name] and self:GetAttribute(_ActionTargetDetail[name])
                )
            end

            return Manager:CallMethod("UpdateActionButton", self:GetName())
        ]=]

        ClearAction             = [=[
            local name          = self:GetAttribute("actiontype")

            if name and name ~= "empty" then
                self:SetAttribute("actiontype", "empty")

                self:SetAttribute("type", nil)
                self:SetAttribute(_ActionTargetMap[name], nil)
                if _ActionTargetDetail[name] then
                    self:SetAttribute(_ActionTargetDetail[name], nil)
                end

                -- Custom clear
                if _ClearSnippet[name] then
                    Manager:RunFor(self, _ClearSnippet[name])
                end
            end
        ]=]

        GetAction               = [=[
            return self:GetAttribute("actiontype"), self:GetAttribute(_ActionTargetMap[name]), _ActionTargetDetail[name] and self:GetAttribute(_ActionTargetDetail[name])
        ]=]

        SetAction               = [=[
            local name, target, detail = ...

            Manager:RunFor(self, ClearAction)

            if name and _ActionTypeMap[name] and target then
                self:SetAttribute("actiontype", name)

                self:SetAttribute("type", _ActionTypeMap[name])
                self:SetAttribute(_ActionTargetMap[name], target)

                if detail ~= nil and _ActionTargetDetail[name] then
                    self:SetAttribute(_ActionTargetDetail[name], detail)
                end
            end

            return Manager:RunFor(self, UpdateAction)
        ]=]

        DragStart               = [=[
            local name          = self:GetAttribute("actiontype")

            if _DragStyle[name] == "Block" then return false end

            local target        = self:GetAttribute(_ActionTargetMap[name])
            local detail        = _ActionTargetDetail[name] and self:GetAttribute(_ActionTargetDetail[name])

            -- Clear and refresh
            if _DragStyle[name] == "Clear" then
                Manager:RunFor(self, ClearAction)
                Manager:RunFor(self, UpdateAction)
            end

            -- Pickup the target
            if _PickupSnippet[name] == "Custom" then
                Manager:CallMethod("OnPickUp", name, target, detail)
                return false
            elseif _PickupSnippet[name] then
                return Manager:RunFor(self, _PickupSnippet[name], target, detail)
            else
                return "clear", _PickupMap[name], target, detail
            end
        ]=]

        ReceiveDrag             = [=[
            local kind, value, extra, extra2 = ...
            if not kind or not value then return false end

            local oldName       = self:GetAttribute("actiontype")
            if _ReceiveStyle[oldName] == "Block" then return false end

            local oldTarget     = oldName and self:GetAttribute(_ActionTargetMap[oldName])
            local oldDetail     = oldName and _ActionTargetDetail[oldName] and self:GetAttribute(_ActionTargetDetail[oldName])

            if _ReceiveStyle[oldName] == "Clear" then
                Manager:RunFor(self, ClearAction)

                local name, target, detail = _ReceiveMap[kind]

                if name then
                    if _ReceiveSnippet[name] and _ReceiveSnippet[name] ~= "Custom" then
                        target, detail = Manager:RunFor(self, _ReceiveSnippet[name], value, extra, extra2)
                    else
                        target, detail = value, extra
                    end

                    if target then
                        self:SetAttribute("actiontype", name)

                        self:SetAttribute("type", _ActionTypeMap[name])
                        self:SetAttribute(_ActionTargetMap[name], target)

                        if detail ~= nil and _ActionTargetDetail[name] then
                            self:SetAttribute(_ActionTargetDetail[name], detail)
                        end
                    end
                end

                Manager:RunFor(self, UpdateAction)
            end

            if _ReceiveStyle[oldName] == "Keep" and _ReceiveSnippet[oldName] == "Custom" then
                Manager:CallMethod("OnReceive", oldName, oldTarget, oldDetail)
                return Manager:RunFor(self, UpdateAction) or false
            end

            -- Pickup the target
            if _PickupSnippet[oldName] == "Custom" then
                Manager:CallMethod("OnPickUp", oldName, oldTarget, oldDetail)
                return false
            elseif _PickupSnippet[oldName] then
                return Manager:RunFor(self, _PickupSnippet[oldName], oldTarget, oldDetail)
            else
                return "clear", _PickupMap[oldName], oldTarget, oldDetail
            end
        ]=]
    ]]

    _OnDragStartSnippet         = [[
        if (IsModifierKeyDown() or _NoDraggable[self:GetAttribute("IFActionHandlerGroup")]) and not IsModifiedClick("PICKUPACTION") then return false end
        return Manager:RunFor(self, DragStart)
    ]]

    _OnReceiveDragSnippet       = [[
        return Manager:RunFor(self, ReceiveDrag, kind, value, ...)
    ]]

    _PostReceiveSnippet         = [[
        return Manager:RunFor(Manager:GetFrameRef("UpdatingButton"), ReceiveDrag, %s, %s, %s, %s)
    ]]

    _SetActionSnippet        = [[
        return Manager:RunFor(Manager:GetFrameRef("UpdatingButton"), SetAction, %s, %s, %s)
    ]]

    _WrapClickPrev              = [[
        local name              = self:GetAttribute("actiontype")

        if _PreClickSnippet[name] then
            return Manager:RunFor(self, _PreClickSnippet[name], button, down)
        end
    ]]

    _WrapClickPost              = [[
        local name              = self:GetAttribute("actiontype")

        if _PostClickSnippet[name] then
            return Manager:RunFor(self, _PostClickSnippet[name], message, button, down)
        end
    ]]

    _WrapDragPrev               = [[ return "message", "update" ]]

    _WrapDragPost               = [[ Manager:RunFor(self, UpdateAction) ]]

    _OnShowSnippet              = [[ if self:GetAttribute("autoKeyBinding") and self:GetAttribute("hotKey") then self:SetBindingClick(true, self:GetAttribute("hotKey"), self:GetName(), "LeftButton") end ]]

    _OnHideSnippet              = [[ if self:GetAttribute("autoKeyBinding") then self:ClearBindings() end ]]
end

------------------------------------------------------
--              Action Script Hanlder               --
------------------------------------------------------
do
    _GlobalGroup                = "GLOBAL"

    function GetGroup(group)
        group                   = type(group) == "string" and strtrim(group)
        return group and group ~= "" and group:upper() or _GlobalGroup
    end

    function GetFormatString(param)
        return type(param) == "string" and ("%q"):format(param) or tostring(param)
    end

    function PickupAny(kind, target, detail, ...)
        if (kind == "clear") then
            ClearCursor()
            kind, target, detail= target, detail, ...
        end

        local handler           = _IFActionTypeHandler[kind]
        return handler and handler.PickupAction(target, detail)
    end

    function PreClick(self)
        local oldKind           = self:GetAttribute("actiontype")
        if InCombatLockdown() or (oldKind and _IFActionTypeHandler[oldKind].ReceiveStyle ~= "Clear") then return end

        local kind, value       = GetCursorInfo()
        if not (kind and value) then return end

        self.__IFActionHandler_PreType  = self:GetAttribute("type")
        self.__IFActionHandler_PreMsg   = true

        -- Make sure no action used
        self:SetAttribute("type", nil)
    end

    function PostClick(self)
        _IFActionTypeHandler[self.ActionType]:RefreshButtonState(self)

        -- Restore the action
        if self.__IFActionHandler_PreMsg then
            if not InCombatLockdown() then
                if self.__IFActionHandler_PreType then
                    self:SetAttribute("type", self.__IFActionHandler_PreType)
                end

                local kind, value, subtype, detail = GetCursorInfo()

                if kind and value and _ReceiveMap[kind] then
                    local oldName   = self.__IFActionHandler_Kind
                    local oldTarget = self.__IFActionHandler_Target
                    local oldDetail = self.__IFActionHandler_Detail

                    _ManagerFrame:SetFrameRef("UpdatingButton", self)
                    _ManagerFrame:Execute(_PostReceiveSnippet:format(GetFormatString(kind), GetFormatString(value), GetFormatString(subtype), GetFormatString(detail)))

                    PickupAny("clear", oldName, oldTarget, oldDetail)
                end
            elseif self.__IFActionHandler_PreType then
                -- Keep safe
                NoCombat(self.SetAttribute, self, "type", self.__IFActionHandler_PreType)
            end

            self.__IFActionHandler_PreType  = false
            self.__IFActionHandler_PreMsg   = false
        end
    end

    function OnEnter(self)
        _OnTooltipButton        = self
        return self:UpdateTooltip()
    end

    function OnLeave(self)
        _OnTooltipButton        = nil
        GameTooltip:Hide()
    end

    function OnShow(self)
        _IFActionTypeHandler[self.ActionType]:RefershGrid(self)
    end

    __NoCombat__()
    function DisableDrag(group, value)
        group                   = GetGroup(group)

        _NoDragGroup[group]     = value or nil
        _ManagerFrame:Execute( ("_NoDraggable[%q] = %s"):format(group, tostring(value or nil)) )
    end

    function IsDragEnabled(group)
        return not _NoDragGroup[GetGroup(group)]
    end

    __NoCombat__()
    function EnableButtonDown(group, value)
        group                   = GetGroup(group)

        if not _MouseDownGroup[group] then
            _MouseDownGroup[group] = value or nil

            if _ActionButtonGroupList[group] then
                local reg       = value and "AnyDown" or "AnyUp"

                for btn in pairs(_ActionButtonGroupList[group]) do
                    btn:RegisterForClicks(reg)
                end
            end
        end
    end

    function IsButtonDownEnabled(group)
        return _MouseDownGroup[GetGroup(group)]
    end

    function SetActionButtonGroup(self, group, old)
        group                   = GetGroup(group)
        old                     = old and GetGroup(old)

        if old and _ActionButtonGroupList[old] then
            _ActionButtonGroupList[old][self]   = nil
        end
        _ActionButtonGroupList[group]           = _ActionButtonGroupList[group] or {}
        _ActionButtonGroupList[group][self]     = true

        self:SetAttribute("IFActionHandlerGroup", group)
        self:RegisterForClicks(_MouseDownGroup[group] and "AnyDown" or "AnyUp")
    end

    function SetupActionButton(self)
        SetActionButtonGroup(self, self.ActionButtonGroup)

        self:RegisterForDrag("LeftButton", "RightButton")


        _ManagerFrame:WrapScript(self, "OnShow",   _OnShowSnippet)
        _ManagerFrame:WrapScript(self, "OnHide",   _OnHideSnippet)

        _ManagerFrame:WrapScript(self, "OnDragStart",   _OnDragStartSnippet)
        _ManagerFrame:WrapScript(self, "OnReceiveDrag", _OnReceiveDragSnippet)

        _ManagerFrame:WrapScript(self, "OnClick",       _WrapClickPrev, _WrapClickPost)
        _ManagerFrame:WrapScript(self, "OnDragStart",   _WrapDragPrev, _WrapDragPost)
        _ManagerFrame:WrapScript(self, "OnReceiveDrag", _WrapDragPrev, _WrapDragPost)

        -- Register useful attribute snippets to be used in other addons
        self:SetFrameRef("_Manager",    _ManagerFrame)
        self:SetAttribute("SetAction",  [[ return self:GetFrameRef("_Manager"):RunFor(self, "Manager:RunFor(self, SetAction, ...)", ...) ]])
        self:SetAttribute("ClearAction",[[ return self:GetFrameRef("_Manager"):RunFor(self, "Manager:RunFor(self, ClearAction)") ]])
        self:SetAttribute("GetAction",  [[ return self:GetFrameRef("_Manager"):RunFor(self, "return Manager:RunFor(self, GetAction)") ]])

        if not self:GetAttribute("actiontype") then
            self:SetAttribute("actiontype", "empty")
        end

        self.PreClick           = self.PreClick + PreClick
        self.PostClick          = self.PostClick+ PostClick
        self.OnShow             = self.OnShow   + OnShow
        self.OnEnter            = self.OnEnter  + OnEnter
        self.OnLeave            = self.OnLeave  + OnLeave
    end

    function SaveAction(self, kind, target, detail)
        _ManagerFrame:SetFrameRef("UpdatingButton", self)
        _ManagerFrame:Execute(_SetActionSnippet:format(GetFormatString(kind), GetFormatString(target), GetFormatString(detail)))
    end
end

class "SecureActionButton" (function(_ENV)
    inherit "SecureCheckButton"

    import "System.Reactive"

    export {
        GetRawUI                = UI.GetRawUI,
        IsObjectType            = Class.IsObjectType,
    }

    local _KeyBindingMask       = Mask("Scorpio_SecureActionButton_KeyBindingMask")
    local _KeyBindingMode       = false

    _KeyBindingMask:Hide()
    _KeyBindingMask.EnableKeyBinding = true

    function _KeyBindingMask:OnKeySet(key, old)
        local parent            = self:GetParent()
        if IsObjectType(parent, SecureActionButton) then
            parent.HotKey       = key
        end
    end

    function _KeyBindingMask:OnKeyClear()
        local parent            = self:GetParent()
        if IsObjectType(parent, SecureActionButton) then
            parent.HotKey       = nil
        end
    end

    local function handleKeyBinding(self)
        if self.HotKey and (not self.AutoKeyBinding or self:IsVisible()) then
            SetOverrideBindingClick(GetRawUI(self), self.AutoKeyBinding, self.HotKey, self:GetName(), "LeftButton")
        else
            ClearOverrideBindings(GetRawUI(self))
        end
    end

    ------------------------------------------------------
    --                 Static Property                  --
    ------------------------------------------------------
    --- Whether the action button group is draggable
    __Static__() __Indexer__(String)
    property "Draggable"        {
        type                    = Boolean,
        get                     = function(self, group) return IsDragEnabled(group) end,
        set                     = function(self, group, value) DisableDrag(group, not value) end,
    }

    --- Whether the action button group use mouse down to trigger
    __Static__() __Indexer__(String)
    property "UseMouseDown"     {
        type                    = Boolean,
        get                     = function(self, group) return IsButtonDownEnabled(group) end,
        set                     = function(self, group, value) EnableButtonDown(group, value) end,
    }

    ------------------------------------------------------
    --                     Property                     --
    ------------------------------------------------------
    --- The action button group
    property "ActionButtonGroup"{ default = _GlobalGroup, handler = SetActionButtonGroup }

    --- The action type
    property "ActionType"       { set = false, field = "__IFActionHandler_Kind", default = "empty" }

    --- the action content
    property "ActionTarget"     { set = false, field = "__IFActionHandler_Target" }

    --- The action detail
    property "ActionDetail"     { set = false, field = "__IFActionHandler_Detail" }

    --- The gametool tip anchor
    property "GameTooltipAnchor"{ type = AnchorType }

    --- Whether use custom flyout logic
    property "IsCustomFlyout"   { type = Boolean }

    ------------------------------------------------------
    --               Observable Property                --
    ------------------------------------------------------
    --- Whether show the button grid
    __Observable__()
    property "GridVisible"      { type = Boolean }

    --- Whether always show the button grid
    __Observable__()
    property "GridAlwaysShow"   { type = Boolean }

    --- Whether the button is usable
    __Observable__()
    property "IsUsable"         { type = Boolean }

    --- Whether the button has action
    __Observable__()
    property "HasAction"        { type = Boolean }

    --- The count/charge of the action
    __Observable__()
    property "Count"            { type = Number }

    --- The cooldown of the action
    __Observable__()
    property "Cooldown"         { type = CooldownStatus, set = Toolset.fakefunc }

    --- Whether the action is auto attack or auto repeat
    __Observable__()
    property "IsAutoAttack"     { type = Boolean }

    --- Whether show the IsAutoAttacking
    __Observable__()
    property "IsAutoAttacking"  { type = Boolean }

    --- Whether show the overlay glow
    __Observable__()
    property "OverlayGlow"      { type = Boolean }

    --- Whether the target is in range
    __Observable__()
    property "InRange"          { type = Any }

    --- The action button's flyout direction: TOP, RIGHT, BOTTOM, LEFT
    __Observable__()
    property "FlyoutDirection"  { type = FlyoutDirection, default = "TOP" }

    --- Whether the action is flyout
    __Observable__()
    property "IsFlyout"         { type = Boolean }

    --- whether the flyout action bar is shown
    __Observable__()
    property "Flyouting"        { type = Boolean }

    --- Whether the action is auto castable
    __Observable__()
    property "IsAutoCastable"   { type = Boolean }

    --- Whether the action is auto casting
    __Observable__()
    property "IsAutoCasting"    { type = Boolean }

    --- The icon of the action
    __Observable__()
    property "Icon"             { type = Any }

    --- Whether the action is an equipped item
    __Observable__()
    property "IsEquippedItem"   { type = Boolean }

    --- The action text
    __Observable__()
    property "Text"             { type = String }

    --- Whether the icon should be locked
    __Observable__()
    property "IconLocked"       { type = Boolean }

    --- The short key of the action
    __Observable__()
    property "HotKey"           { type = String, handler = function(self, key, old)
            if old and _KeyBindingMap[old] == self then
                _KeyBindingMap[old] = nil
            end

            if key and key:upper() ~= key then
                self.HotKey     = key:upper()
                return
            end

            self:SetAttribute("hotKey", key)

            if key and not self.AutoKeyBinding and _KeyBindingMap[key] ~= self then
                if _KeyBindingMap[key] then _KeyBindingMap[key].HotKey = nil end
                _KeyBindingMap[key] = self
            end

            return handleKeyBinding(self)
        end
    }

    ------------------------------------------------------
    --                     Property                     --
    ------------------------------------------------------
    --- Whether only bind keys when the button is shown
    property "AutoKeyBinding"   { type = Boolean, handler = function(self, flag)
            self:SetAttribute("autoKeyBinding", flag and true or nil)

            if self.HotKey then
                if flag then
                    if _KeyBindingMap[self.HotKey] == self then
                        _KeyBindingMap[self.HotKey] = nil
                    end
                elseif _KeyBindingMap[self.HotKey] and _KeyBindingMap[self.HotKey] ~= self then
                    self.HotKey = nil
                    return
                end
            end

            return handleKeyBinding(self)
        end
    }


    ------------------------------------------------------
    --                  Static Method                   --
    ------------------------------------------------------
    --- Start the key binding for all secure action buttons
    __Static__() __Async__()
    function StartKeyBinding()
        _KeyBindingMode         = true

        Alert(_Locale["Confirm when you finished the key binding"])
        _KeyBindingMode         = false

        _KeyBindingMask:Hide()
        _KeyBindingMask:SetParent(nil)
    end


    ------------------------------------------------------
    --                      Method                      --
    ------------------------------------------------------
    --- Set action for the actionbutton
    function SetAction(self, kind, target, detail)
        if kind and not _IFActionTypeHandler[kind] then
            error("SecureActionButton:SetAction(kind, target, detail) - no such action kind", 2)
        end

        if not kind or not target then
            kind, target, detail= nil, nil, nil
        else
            target, detail      = _IFActionTypeHandler[kind].Map(self, target, detail)
        end

        NoCombat(SaveAction, self, kind, target, detail)
    end

    --- Get action for the actionbutton
    function GetAction(self)
        return self.ActionType, self.ActionTarget, self.ActionDetail
    end

    function UpdateTooltip(self)
        if not self.ActionType then return end

        local anchor            = self.GameTooltipAnchor

        if anchor then
            GameTooltip:SetOwner(self, anchor)
        else
            if (GetCVar("UberTooltips") == "1") then
                GameTooltip_SetDefaultAnchor(GameTooltip, self)
            else
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            end
        end

        _IFActionTypeHandler[self.ActionType].SetTooltip(self, GameTooltip)
        GameTooltip:Show()
    end

    ------------------------------------------------------
    --                   Initializer                    --
    ------------------------------------------------------
    local function OnEnter(self)
        if not _KeyBindingMode then return end

        _KeyBindingMask:SetParent(self)
        _KeyBindingMask:SetBindingKey(self.HotKey)
        _KeyBindingMask:Show()

        return true
    end

    local function OnLeave(self)
        if not _KeyBindingMode then return end

        if _KeyBindingMask:GetParent() == self then
            _KeyBindingMask:Hide()
            _KeyBindingMask:SetParent(nil)
        end
    end

    __Sealed__()
    ISecureActionButton         = interface {
        __init                  = function(self)
            self.OnEnter        = self.OnEnter + OnEnter
            self.OnLeave        = self.OnLeave + OnLeave

            SetupActionButton(self)
        end
    }

    extend(ISecureActionButton)
end)