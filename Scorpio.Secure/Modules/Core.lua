--========================================================--
--             Scorpio Secure UI Framework                --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/06/04                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Secure"                   "1.0.0"
--========================================================--

__Sealed__() __Final__() interface "Scorpio.Secure" {}

Environment.RegisterGlobalNamespace("Scorpio.Secure")

namespace "Scorpio.Secure"

import "Scorpio.UI"

-- We can't directly change the secure widgets to the Scorpio UI widget,
-- we can only use the wrapper/origin model, so to define the functions that
-- can be called in the secure snippets, we should use __SecureMethod__ attribute
-- to bind the class object method or the obect method to the secure ui objects
-- so the system can keep those functions defined in the wrapper/origin at the same time
_SecureCallMap                          = {}

--- The interface that provide the basic features for secure widgets
__Sealed__()__ObjFuncAttr__{ Inheritable= true }
interface "ISecureHandler" (function(_ENV)

    local GetRawUI                      = Scorpio.UI.GetRawUI
    local GetProxyUI                    = Scorpio.UI.GetProxyUI
    local GetSuperClass                 = Class.GetSuperClass

    local _RegisterAttributeDriver      = RegisterAttributeDriver
    local _UnregisterAttributeDriver    = UnregisterAttributeDriver
    local _RegisterStateDriver          = RegisterStateDriver
    local _UnregisterStateDriver        = UnregisterStateDriver
    local _RegisterUnitWatch            = RegisterUnitWatch
    local _UnregisterUnitWatch          = UnregisterUnitWatch
    local _UnitWatchRegistered          = UnitWatchRegistered

    ------------------------------------------------------
    -- Method
    ------------------------------------------------------
    --- Execute a snippet against a header frame
    __Arguments__{ String }
    function Execute(self, body)
        return SecureHandlerExecute(GetRawUI(self), body)
    end

    --- Wrap the script on a frame to invoke snippets against a header
    __Arguments__{ UI, ScriptsType, String/nil, String/nil }
    function WrapScript(self, frame, script, preBody, postBody)
        return SecureHandlerWrapScript(GetRawUI(frame), script, GetRawUI(self), preBody, postBody)
    end

    --- Remove previously applied wrapping, returning its details
    __Arguments__{ UI, ScriptsType }
    function UnwrapScript(self, frame, script)
        return SecureHandlerUnwrapScript(GetRawUI(frame), script)
    end

    --- Create a frame handle reference and store it against a frame
    __Arguments__{ String, UI }
    function SetFrameRef(self, label, refFrame)
        return SecureHandlerSetFrameRef(GetRawUI(self), label, GetRawUI(refFrame))
    end

    --- Register a frame attribute to be set automatically with changes in game state
    __Arguments__{ String, Any }
    function RegisterAttributeDriver(self, attribute, values)
        return _RegisterAttributeDriver(GetRawUI(self), attribute, values)
    end

    --- Unregister a frame from the state driver manager
    __Arguments__{ String }
    function UnregisterAttributeDriver(self, attribute)
        return _UnregisterAttributeDriver(GetRawUI(self), attribute)
    end

    --- Register a frame state to be set automatically with changes in game state
    __Arguments__{ String, Any }
    function RegisterStateDriver(self, state, values)
        return _RegisterStateDriver(GetRawUI(self), state, values)
    end

    --- Unregister a frame from the state driver manager
    __Arguments__{ String }
    function UnregisterStateDriver(self, state)
        return _UnregisterStateDriver(GetRawUI(self), state)
    end

    --- Register a frame to be notified when a unit's existence changes
    __Arguments__{ Boolean/nil }
    function RegisterUnitWatch(self, asState)
        return _RegisterUnitWatch(GetRawUI(self), asState)
    end

    --- Unregister a frame from the unit existence monitor
    function UnregisterUnitWatch(self)
        return _UnregisterUnitWatch(GetRawUI(self))
    end

    --- Check to see if a frame is registered
    function IsUnitWatchRegistered(self)
        return _UnitWatchRegistered(GetRawUI(self))
    end

    function __init(self)
        local cls               = getmetatable(self)
        self                    = GetRawUI(self)
        while cls do
            local map           = _SecureCallMap[cls]
            if map then

                for name, func in pairs(map) do
                    self[name]  = self[name] or func
                end
            end
            cls                 = GetSuperClass(cls)
        end
    end
end)

--- The attribute used to bind functions that be be called by the secure environment
__Sealed__() __Final__()
class "__SecureMethod__" (function(_ENV)
    extend "IAttachAttribute"

    local GetRawUI              = Scorpio.UI.GetRawUI
    local GetProxyUI            = Scorpio.UI.GetProxyUI

    -----------------------------------------------------------
    --                        method                         --
    -----------------------------------------------------------
    function AttachAttribute(self, target, targettype, owner, name, stack)
        if targettype == AttributeTargets.Method then
            if Class.IsSubType(owner, ISecureHandler) then
                local map               = _SecureCallMap[owner] or {}
                _SecureCallMap[owner]   = map

                map[name]               = function(self, ...)
                    return target(GetProxyUI(self), ...)
                end
            end
        else
            if Class.IsObjectType(owner, ISecureHandler) then
                GetRawUI(owner)[name]   = function(self, ...)
                    return target(owner, ...)
                end
            end
        end
    end

    -----------------------------------------------------------
    --                       property                        --
    -----------------------------------------------------------
    --- the attribute target
    property "AttributeTarget"  { type = AttributeTargets,  default = AttributeTargets.Method + AttributeTargets.Function }

    --- the attribute's priority
    property "Priority"         { type = AttributePriority, default = AttributePriority.Lowest }
end)

--- The attribute used to bind secure template for the class objects
__Sealed__() __Final__()
class "__SecureTemplate__" (function(_ENV)
    extend "IAttachAttribute"

    local _SecureTemplateMap    = {}
    local _TempList             = List()

    function _TempList:Distinct()
        self:Sort()

        for i = #self, 1, -1 do
            if self[i] == self[i - 1] then
                self:RemoveByIndex(i)
            end
        end

        return self
    end

    -----------------------------------------------------------
    --                        method                         --
    -----------------------------------------------------------
    function AttachAttribute(self, target, targettype, owner, name, stack)
        if Class.IsSubType(target, ISecureHandler) then
            _SecureTemplateMap[target] = self.template
        end
    end

    __Static__() function GetTemplate(cls, template)
        local default           = _SecureTemplateMap[cls]
        while cls and default == nil do
            cls                 = Class.GetSuperClass(cls)
            default             = cls and _SecureTemplateMap[cls]
        end

        if default then
            _TempList:Clear()

            _TempList:Extend(default:gmatch("[%w_]+"))
            if type(template) == "string" then
                _TempList:Extend(template:gmatch("[%w_]+"))
            end

            return _TempList:Distinct():Join(",")
        elseif type(template) == "string" then
            return template
        end
    end

    -----------------------------------------------------------
    --                       property                        --
    -----------------------------------------------------------
    --- the attribute target
    property "AttributeTarget"  { type = AttributeTargets,  default = AttributeTargets.Class }

    -----------------------------------------------------------
    --                      constructor                      --
    -----------------------------------------------------------
    __Arguments__{ String/nil }
    function __ctor(self, template)
        self.template           = template or false
    end
end)

--- SecureFrame is a root widget class for secure frames
__Sealed__() __SecureTemplate__"SecureFrameTemplate"
class "SecureFrame" {
    Frame, ISecureHandler,

    __new                       = function(cls, name, parent, inherits)
        local ui                = CreateFrame("Frame", name, parent, __SecureTemplate__.GetTemplate(cls, inherits))
        local self              = { [0] = ui[0] }
        UI.RegisterProxyUI(self)
        UI.RegisterRawUI(ui)
        return self
    end
}

--- SecureButton is used as the root widget class for secure buttons
__Sealed__() __SecureTemplate__"SecureActionButtonTemplate"
class "SecureButton"  {
    Button, ISecureHandler,

    __new                       = function(cls, name, parent, inherits)
        local ui                = CreateFrame("Button", name, parent, __SecureTemplate__.GetTemplate(cls, inherits))
        local self              = { [0] = ui[0] }
        UI.RegisterProxyUI(self)
        UI.RegisterRawUI(ui)
        return self
    end
}

--- SecureCheckButton is used as the root widget class for secure check buttons
__Sealed__()  __SecureTemplate__"SecureActionButtonTemplate"
class "SecureCheckButton" {
    CheckButton, ISecureHandler,

    __new                       = function(cls, name, parent, inherits)
        local ui                = CreateFrame("CheckButton", name, parent, __SecureTemplate__.GetTemplate(cls, inherits))
        local self              = { [0] = ui[0] }
        UI.RegisterProxyUI(self)
        UI.RegisterRawUI(ui)
        return self
    end
}