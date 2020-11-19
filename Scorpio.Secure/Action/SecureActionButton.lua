--========================================================--
--             Scorpio Secure Action Button               --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/11/16                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.SecureActionButton"   "1.0.0"
--========================================================--

__Sealed__()
class "SecureActionButton" (function(_ENV)
    inherit "SecureCheckButton"

    _ManagerFrame               = SecureFrame("Scorpio_SecureActionButton_Manager", UIParent, "SecureHandlerStateTemplate")
    _ManagerFrame:Hide()

    _FlashInterval              = 0.4
    _UpdateRangeInterval        = 0.2

    _ActionTypeHandler          = {}

    _ActionTypeMap              = {}
    _ActionTargetMap            = {}
    _ActionTargetDetail         = {}
    _ReceiveMap                 = {}

    _AutoAttackButtons          = setmetatable({}, META_WEAKKEY)
    _AutoRepeatButtons          = setmetatable({}, META_WEAKKEY)
    _Spell4Buttons              = setmetatable({}, META_WEAKKEY)
    _RangeCheckButtons          = setmetatable({}, META_WEAKKEY)

    _IFActionTypeHandler        = {}

    _IFActionHandler_Buttons    = setmetatable({}, META_WEAKKEY)

    ------------------------------------------------------
    --               Action Type Handler                --
    ------------------------------------------------------
    __Sealed__()
    class "ActionTypeHandler" (function(_ENV)
        _RegisterSnippetTemplate= "%s[%q] = %q"

        __Sealed__() enum "HandleStyle" { "Keep", "Clear", "Block" }

        ------------------------------------------------------
        -- Event
        ------------------------------------------------------
        -- Fired when the handler is enabled or disabled
        event "OnEnableChanged"

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        -- Refresh all action buttons of the same action type
        function Refresh(self, button, mode)
            if type(button) ~= "table" then
                return _IFActionHandler_Buttons:EachK(self.Name, button or UpdateActionButton)
            else
                return (mode or UpdateActionButton)(button)
            end
        end

        -- Run the snippet in the global environment
        function RunSnippet(self, code)
            return NoCombat( SecureFrame.Execute, self.Manager, code )
        end

        ------------------------------------------------------
        -- Overridable Method
        ------------------------------------------------------
        -- Refresh the button
        function RefreshButton(self) end

        -- Get the actions's kind, target, detail
        function GetActionDetail(self)
            local name = self:GetAttribute("actiontype")
            return self:GetAttribute(_ActionTargetMap[name]), _ActionTargetDetail[name] and self:GetAttribute(_ActionTargetDetail[name])
        end

        -- Custom pick up action
        function PickupAction(self, target, detail)
        end

        -- Custom receive action
        function ReceiveAction(self, target, detail)
        end

        -- Whether the action button has an action
        function HasAction(self)
            return true
        end

        -- Get the action's text
        function GetActionText(self)
            return ""
        end

        -- Get the action's texture
        function GetActionTexture(self)
        end

        -- Get the action's charges
        function GetActionCharges(self)
        end

        -- Get the action's count
        function GetActionCount(self)
            return 0
        end

        -- Get the action's cooldown
        function GetActionCooldown(self)
            return 0, 0, 0
        end

        -- Whether the action is attackable
        function IsAttackAction(self)
            return false
        end

        -- Whether the action is an item and can be equipped
        function IsEquippedItem(self)
            return false
        end

        -- Whether the action is actived
        function IsActivedAction(self)
            return false
        end

        -- Whether the action is auto-repeat
        function IsAutoRepeatAction(self)
            return false
        end

        -- Whether the action is usable
        function IsUsableAction(self)
            return true
        end

        -- Whether the action is consumable
        function IsConsumableAction(self)
            return false
        end

        -- Whether the action is in range of the target
        function IsInRange(self)
            return
        end

        -- Whether the action is auto-castable
        function IsAutoCastAction(self)
            return false
        end

        -- Whether the action is auto-casting now
        function IsAutoCasting(self)
            return false
        end

        -- Show the tooltip for the action
        function SetTooltip(self, GameTooltip)
        end

        -- Get the spell id of the action<
        function GetSpellId(self)
        end

        -- Whether the action is a flyout spell
        function IsFlyout(self)
            return false
        end

        ------------------------------------------------------
        -- Property
        ------------------------------------------------------
        -- Whether the handler is enabled(has buttons)
        property "Enabled" { type = Boolean, Event = "OnEnableChanged" }

        -- The manager of the action system
        property "Manager" { default = _ManagerFrame, set = false }

        -- The action's name
        property "Name" { type = String }

        -- The action type's type
        property "Type" { type = String }

        -- The target attribute name
        property "Target" { type = String }

        -- The detail attribute name
        property "Detail" { type = String }

        -- Whether the action is player action
        property "IsPlayerAction" { type = Boolean, default = true }

        -- Whether the action is pet action
        property "IsPetAction" { type = Boolean, default = false }

        -- The drag style of the action type
        property "DragStyle" { type = HandleStyle, default = HandleStyle.Clear }

        -- The receive style of the action type
        property "ReceiveStyle" { type = HandleStyle, default = HandleStyle.Clear }

        -- The receive map
        property "ReceiveMap" { type = String }

        -- The pickup map
        property "PickupMap" { type = String }

        -- The snippet to setup environment for the action type
        property "InitSnippet" { type = String }

        -- The snippet used when pick up action
        property "PickupSnippet" { type = String }

        -- The snippet used to update for new action settings
        property "UpdateSnippet" { type = String }

        -- The snippet used to receive action
        property "ReceiveSnippet" { type = String }

        -- The snippet used to clear action
        property "ClearSnippet" { type = String }

        -- The snippet used for pre click
        property "PreClickSnippet" { type = String }

        -- The snippet used for post click
        property "PostClickSnippet" { type = String }

        ------------------------------------------------------
        -- Initialize
        ------------------------------------------------------
        function IFActionTypeHandler(self)
            -- No repeat definition for action types
            if _IFActionTypeHandler[self.Name] then return end

            -- Register the action type handler
            _IFActionTypeHandler[self.Name] = self

            -- Default map
            if self.Type == nil then self.Type = self.Name end
            if self.Target == nil then self.Target = self.Type end
            if self.ReceiveMap == nil and self.ReceiveStyle == "Clear" then self.ReceiveMap = self.Type end
            if self.PickupMap == nil then self.PickupMap = self.Type end

            -- Register action type map
            _ActionTypeMap[self.Name] = self.Type
            _ActionTargetMap[self.Name] = self.Target
            _ActionTargetDetail[self.Name]  = self.Detail
            self:RunSnippet( _RegisterSnippetTemplate:format("_ActionTypeMap", self.Name, self.Type) )
            self:RunSnippet( _RegisterSnippetTemplate:format("_ActionTargetMap", self.Name, self.Target) )
            if self.Detail then self:RunSnippet( _RegisterSnippetTemplate:format("_ActionTargetDetail", self.Name, self.Detail) ) end

            -- Init the environment
            if self.InitSnippet then self:RunSnippet( self.InitSnippet ) end

            -- Register PickupSnippet
            if self.PickupSnippet then self:RunSnippet( _RegisterSnippetTemplate:format("_PickupSnippet", self.Name, self.PickupSnippet) ) end

            -- Register UpdateSnippet
            if self.UpdateSnippet then self:RunSnippet( _RegisterSnippetTemplate:format("_UpdateSnippet", self.Name, self.UpdateSnippet) ) end

            -- Register ReceiveSnippet
            if self.ReceiveSnippet then self:RunSnippet( _RegisterSnippetTemplate:format("_ReceiveSnippet", self.Name, self.ReceiveSnippet) ) end

            -- Register ClearSnippet
            if self.ClearSnippet then self:RunSnippet( _RegisterSnippetTemplate:format("_ClearSnippet", self.Name, self.ClearSnippet) ) end

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
            if self.PickupMap then self:RunSnippet( _RegisterSnippetTemplate:format("_PickupMap", self.Name, self.PickupMap) ) end

            -- Register PreClickMap
            if self.PreClickSnippet then self:RunSnippet( _RegisterSnippetTemplate:format("_PreClickSnippet", self.Name, self.PreClickSnippet) ) end

            -- Register PostClickMap
            if self.PostClickSnippet then self:RunSnippet( _RegisterSnippetTemplate:format("_PostClickSnippet", self.Name, self.PostClickSnippet) ) end

            -- Clear
            self.InitSnippet = nil
            self.PickupSnippet = nil
            self.UpdateSnippet = nil
            self.ReceiveSnippet = nil
            self.ClearSnippet = nil
            self.PreClickSnippet = nil
            self.PostClickSnippet = nil
        end
    end)

    ------------------------------------------------------
    --              Action Button Manager               --
    ------------------------------------------------------
    -- Custom pick up handler
    __SecureMethod__()
    function _ManagerFrame:OnPickUp(kind, target, detail)
        return not InCombatLockdown() and PickupAny("clear", kind, target, detail)
    end

    __SecureMethod__()
    function _ManagerFrame:OnReceive(kind, target, detail)
        return not InCombatLockdown() and _IFActionTypeHandler[kind] and _IFActionTypeHandler[kind]:ReceiveAction(target, detail)
    end

    __SecureMethod__()
    function _ManagerFrame:UpdateActionButton(btnName)
        self                    = IGAS:GetWrapper(_G[btnName])

        local name              = self:GetAttribute("actiontype")
        local target, detail    = _IFActionTypeHandler[name].GetActionDetail(self)

        -- Some problem with battlepet
        -- target = tonumber(target) or target
        -- detail = tonumber(detail) or detail

        if self.__IFActionHandler_Kind ~= name
            or self.__IFActionHandler_Target ~= target
            or self.__IFActionHandler_Detail ~= detail then

            self.__IFActionHandler_Kind = name
            self.__IFActionHandler_Target = target
            self.__IFActionHandler_Detail = detail

            _IFActionHandler_Buttons[self] = name   -- keep button in kind's link list

            return UpdateActionButton(self)
        end
    end

    ------------------------------------------------------
    --                  Static Method                   --
    ------------------------------------------------------

    ------------------------------------------------------
    --                   Constructor                    --
    ------------------------------------------------------
    function __ctor(self, ...)

    end
end)