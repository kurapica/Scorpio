--========================================================--
--                Scorpio Secure Frames                   --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2017/01/20                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.UI.SecureFrame"           "1.0.0"
--========================================================--

--- IFSecureHandler contains several secure methods for secure frames
__Sealed__()
interface "IFSecureHandler" (function(_ENV)
    export {
        _SecureHandlerExecute       = _G.SecureHandlerExecute,
        _SecureHandlerWrapScript    = _G.SecureHandlerWrapScript,
        _SecureHandlerUnwrapScript  = _G.SecureHandlerUnwrapScript,
        _SecureHandlerSetFrameRef   = _G.SecureHandlerSetFrameRef,

        _RegisterAttributeDriver    = _G.RegisterAttributeDriver,
        _UnregisterAttributeDriver  = _G.UnregisterAttributeDriver,
        _RegisterStateDriver        = _G.RegisterStateDriver,
        _UnregisterStateDriver      = _G.UnregisterStateDriver,
        _RegisterUnitWatch          = _G.RegisterUnitWatch,
        _UnregisterUnitWatch        = _G.UnregisterUnitWatch,
        _UnitWatchRegistered        = _G.UnitWatchRegistered,
    }

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    --- Execute a snippet against a header frame
    -- @param  body              string, the snippet to be executed for the frame
    -- @usage  object:Execute("print(1, 2, 3)")
    function Execute(self, body)
        return _SecureHandlerExecute(self.UIElement, body)
    end

    --- Wrap the script on a frame to invoke snippets against a header
    -- @param  frame            System.Widget.Frame, the frame which's script is to be wrapped
    -- @param  script           string, the script handle name
    -- @param  preBody          string, the snippet to be executed before the original script handler
    -- @param  postBody         string, the snippet to be executed after the original script handler
    -- @usage  object:WrapScript(button, "OnEnter", "")
    function WrapScript(self, frame, script, preBody, postBody)
        return _SecureHandlerWrapScript(frame.UIElement, script, self.UIElement, preBody, postBody)
    end

    --- Remove previously applied wrapping, returning its details
    -- @param  frame            System.Widget.Frame, the frame which's script is to be wrapped
    -- @param  script           name, the script handle name
    -- @return header           System.Widget.Frame, self's handler</return>
    -- @return preBody          string, the snippet to be executed before the original script handler</return>
    -- @return postBody         string, the snippet to be executed after the original script handler</return>
    -- @usage  object:UnwrapScript(button, "OnEnter")
    function UnwrapScript(self, frame, script)
        return _SecureHandlerUnwrapScript(frame.UIElement, script)
    end

    --- Create a frame handle reference and store it against a frame
    -- @param  label            string, the frame handle's reference name
    -- @param  refFrame         System.Widget.Frame, the frame
    -- @usage  object:SetFrameRef("MyButton", button)
    function SetFrameRef(self, label, refFrame)
        return _SecureHandlerSetFrameRef(self.UIElement, label, refFrame.UIElement)
    end

    --- Register a frame attribute to be set automatically with changes in game state
    -- @param  attribute        string
    -- @param  values           string
    -- @usage  object:RegisterAttributeDriver("hasunit", "[@mouseover, exists] true; false")
    function RegisterAttributeDriver(self, attribute, values)
        return _RegisterAttributeDriver(self.UIElement, attribute, values)
    end

    --- Unregister a frame from the state driver manager
    -- @param  attribute        string
    -- @param  values           string
    -- @usage  object:UnregisterAttributeDriver("hasunit")
    function UnregisterAttributeDriver(self, attribute, values)
        return _UnregisterAttributeDriver(self.UIElement, attribute, values)
    end

    --- Register a frame state to be set automatically with changes in game state
    -- @param  state
    -- @param  values
    -- @usage  object:RegisterStateDriver("hasunit", "[@mouseover, exists] true; false")
    function RegisterStateDriver(self, state, values)
        return _RegisterStateDriver(self.UIElement, state, values)
    end

    --- Unregister a frame from the state driver manager
    -- @param  state
    -- @param  values
    -- @usage  object:UnregisterStateDriver("hasunit")
    function UnregisterStateDriver(self, state)
        return _UnregisterStateDriver(self.UIElement, state)
    end

    --- Register a frame to be notified when a unit's existence changes
    -- @format [asState]
    -- @usage  object:RegisterUnitWatch()
    function RegisterUnitWatch(self, asState)
        return _RegisterUnitWatch(self.UIElement, asState)
    end

    --- Unregister a frame from the unit existence monitor
    function UnregisterUnitWatch(self)
        return _UnregisterUnitWatch(self.UIElement)
    end

    --- Check to see if a frame is registered
    -- @return boolean
    function UnitWatchRegistered(self)
        return _UnitWatchRegistered(self.UIElement)
    end
end)

--- SecureFrame is a root widget class for secure frames
__Sealed__()
class "SecureFrame" (function(_ENV)
    inherit "Frame"
    extend "IFSecureHandler"

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    function CreateUIElement(self, name, parent, ...)
        if select('#', ...) > 0 then
            return CreateFrame("Frame", name, parent, ...)
        else
            return CreateFrame("Frame", name, parent, "SecureFrameTemplate")
        end
    end
end)

--- SecureButton is used as the root widget class for secure buttons
__Sealed__()
class "SecureButton" (function(_ENV)
    inherit "Button"
    extend "IFSecureHandler"

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    function CreateUIElement(self, name, parent, ...)
        if type(template) ~= "string" or strtrim(template) == "" then
            return CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
        else
            if not template:find("SecureActionButtonTemplate") then
                template = "SecureActionButtonTemplate,"..template
            end
            return CreateFrame("Button", name, parent, template)
        end
    end
end)

--- SecureCheckButton is used as the root widget class for secure check buttons
__Sealed__()
class "SecureCheckButton" (function(_ENV)
    inherit "CheckButton"
    extend "IFSecureHandler"

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    function CreateUIElement(self, name, parent, ...)
        if type(template) ~= "string" or strtrim(template) == "" then
            return CreateFrame("CheckButton", name, parent, "SecureActionButtonTemplate")
        else
            if not template:find("SecureActionButtonTemplate") then
                template = "SecureActionButtonTemplate,"..template
            end
            return CreateFrame("CheckButton", name, parent, template)
        end
    end
end)