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

    _IFActionTypeHandler        = {}

    _ActionTypeMap              = {}
    _ActionTargetMap            = {}
    _ActionTargetDetail         = {}
    _ReceiveMap                 = {}

    ------------------------------------------------------
    --               Action Type Handler                --
    ------------------------------------------------------
    -- The handler for action types
    __Sealed__() __AnonymousClass__()
    interface "ActionTypeHandler" (function(_ENV)
        extend "IList"

        _RegisterSnippetTemplate= "%s[%q] = %q"

        _ActionButtonMap        = setmetatable({}, META_WEAKALL)

        __Sealed__() enum "HandleStyle" { "Keep", "Clear", "Block" }

        ------------------------------------------------------
        -- Event
        ------------------------------------------------------
        -- Fired when the handler is enabled or disabled
        event "OnEnableChanged"

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        GetIterator             = ipairs

        function Insert(self, button)
            local oldHandler    = _ActionButtonMap[button]

            if oldHandler and oldHandler == self then return end
            if oldHandler then oldHandler:Remove(button) end

            _ActionButtonMap[button] = self
            tinsert(self, button)

            self.Enabled        = true
        end

        function Remove(self, button)
            if _ActionButtonMap[button] ~= self then return end
            _ActionButtonMap[button] = nil

            for i, v in ipairs(self) do if v == button then tremove(self, i) break end end

            if not self[1] then
                self.Enabled    = false
            end
        end

        -- Refresh all action buttons of the same action type
        __AsyncSingle__(true)
        function Refresh(self, button, mode)
            if type(button) ~= "table" then
                local func      = SecureActionButton[button or "UpdateActionButton"]

                for i = 1, #self do
                    func(self[i])
                    Continue()  -- smoothing the operation
                end
            else
                return SecureActionButton[mode or "UpdateActionButton"](button)
            end
        end

        -- Run the snippet in the global environment
        __NoCombat__()
        function RunSnippet(self, code)
            return self.Manager:Execute(code)
        end

        ------------------------------------------------------
        -- Overridable Method For Buttons
        ------------------------------------------------------
        -- Set the action, return new result to replacd the oldest
        __Abstract__() function SetAction(self, ...) return ... end

        -- Refresh the button
        __Abstract__() function RefreshButton(self) end

        -- Get the actions's kind, target, detail
        __Abstract__() function GetActionDetail(self)
            local name = self:GetAttribute("actiontype")
            return self:GetAttribute(_ActionTargetMap[name]), _ActionTargetDetail[name] and self:GetAttribute(_ActionTargetDetail[name])
        end

        -- Custom pick up action
        __Abstract__() function PickupAction(self, target, detail) end

        -- Custom receive action
        __Abstract__() function ReceiveAction(self, target, detail) end

        -- Whether the action button has an action
        __Abstract__() function HasAction(self) return true end

        -- Get the action's text
        __Abstract__() function GetActionText(self) return "" end

        -- Get the action's texture
        __Abstract__() function GetActionTexture(self) end

        -- Get the action's charges
        __Abstract__() function GetActionCharges(self) end

        -- Get the action's count
        __Abstract__() function GetActionCount(self) return 0 end

        -- Get the action's cooldown
        __Abstract__() function GetActionCooldown(self) return 0, 0, 0 end

        -- Whether the action is attackable
        __Abstract__() function IsAttackAction(self) return false end

        -- Whether the action is an item and can be equipped
        __Abstract__() function IsEquippedItem(self) return false end

        -- Whether the action is actived
        __Abstract__() function IsActivedAction(self) return false end

        -- Whether the action is auto-repeat
        __Abstract__() function IsAutoRepeatAction(self) return false end

        -- Whether the action is usable
        __Abstract__() function IsUsableAction(self) return true end

        -- Whether the action is consumable
        __Abstract__() function IsConsumableAction(self) return false end

        -- Whether the action is in range of the target
        __Abstract__() function IsInRange(self) return end

        -- Whether the action is auto-castable
        __Abstract__() function IsAutoCastAction(self) return false end

        -- Whether the action is auto-casting now
        __Abstract__() function IsAutoCasting(self) return false end

        -- Show the tooltip for the action
        __Abstract__() function SetTooltip(self, GameTooltip) end

        -- Get the spell id of the action
        __Abstract__() function GetSpellId(self) end

        -- Whether the action is a flyout spell
        __Abstract__() function IsFlyout(self) return false end

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
        property "DragStyle"        { type = HandleStyle, default = HandleStyle.Clear }

        -- The receive style of the action type
        property "ReceiveStyle"     { type = HandleStyle, default = HandleStyle.Clear }

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
            if self.Type == nil         then self.Type      = self.Name end
            if self.Target == nil       then self.Target    = self.Type end
            if self.PickupMap == nil    then self.PickupMap = self.Type end
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

    ------------------------------------------------------
    --                  Static Method                   --
    ------------------------------------------------------

    ------------------------------------------------------
    --                   Constructor                    --
    ------------------------------------------------------
    function __ctor(self, ...)

    end
end)