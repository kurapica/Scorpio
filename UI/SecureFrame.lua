--========================================================--
--                Scorpio Secure Frames                   --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2017/01/20                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.UI.SecureFrame"           "1.0.0"
--========================================================--

__Doc__[[IFSecureHandler contains several secure methods for secure frames]]
__Sealed__()
interface "IFSecureHandler" (function(_ENV)

	local _SecureHandlerExecute 	= _G.SecureHandlerExecute
	local _SecureHandlerWrapScript 	= _G.SecureHandlerWrapScript
	local _SecureHandlerUnwrapScript= _G.SecureHandlerUnwrapScript
	local _SecureHandlerSetFrameRef = _G.SecureHandlerSetFrameRef

	local _RegisterAttributeDriver 	= _G.RegisterAttributeDriver
	local _UnregisterAttributeDriver= _G.UnregisterAttributeDriver
	local _RegisterStateDriver 		= _G.RegisterStateDriver
	local _UnregisterStateDriver 	= _G.UnregisterStateDriver
	local _RegisterUnitWatch 		= _G.RegisterUnitWatch
	local _UnregisterUnitWatch 		= _G.UnregisterUnitWatch
	local _UnitWatchRegistered 		= _G.UnitWatchRegistered

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    __Doc__[[
		<desc>Execute a snippet against a header frame</desc>
		<param name="body">string, the snippet to be executed for the frame</param>
		<usage>object:Execute("print(1, 2, 3)"</usage>
	]]
	function Execute(self, body)
		return _SecureHandlerExecute(self.UIElement, body)
	end

	__Doc__[[
		<desc>Wrap the script on a frame to invoke snippets against a header</desc>
		<param name="frame">System.Widget.Frame, the frame which's script is to be wrapped</param>
		<param name="script">string, the script handle name</param>
		<param name="preBody">string, the snippet to be executed before the original script handler</param>
		<param name="postBody">string, the snippet to be executed after the original script handler</param>
		<usage>object:WrapScript(button, "OnEnter", "")</usage>
	]]
	function WrapScript(self, frame, script, preBody, postBody)
		return _SecureHandlerWrapScript(frame.UIElement, script, self.UIElement, preBody, postBody)
	end

	__Doc__[[
		<desc>Remove previously applied wrapping, returning its details</desc>
		<param name="frame">System.Widget.Frame, the frame which's script is to be wrapped</param>
		<param name="script">name, the script handle name</param>
		<return type="header">System.Widget.Frame, self's handler</return>
		<return type="preBody">string, the snippet to be executed before the original script handler</return>
		<return type="postBody">string, the snippet to be executed after the original script handler</return>
		<usage>object:UnwrapScript(button, "OnEnter")</usage>
	]]
	function UnwrapScript(self, frame, script)
		return _SecureHandlerUnwrapScript(frame.UIElement, script)
	end

	__Doc__[[
		<desc>Create a frame handle reference and store it against a frame</desc>
		<param name="label">string, the frame handle's reference name</param>
		<param name="refFrame">System.Widget.Frame, the frame</param>
		<usage>object:SetFrameRef("MyButton", button)</usage>
	]]
	function SetFrameRef(self, label, refFrame)
		return _SecureHandlerSetFrameRef(self.UIElement, label, refFrame.UIElement)
	end

	__Doc__[[
		<desc>Register a frame attribute to be set automatically with changes in game state</desc>
		<param name="attribute">string</param>
		<param name="values">string</param>
		<usage>object:RegisterAttributeDriver("hasunit", "[@mouseover, exists] true; false")</usage>
	]]
	function RegisterAttributeDriver(self, attribute, values)
		return _RegisterAttributeDriver(self.UIElement, attribute, values)
	end

	__Doc__[[
		<desc>Unregister a frame from the state driver manager</desc>
		<param name="attribute">string</param>
		<param name="values">string</param>
		<usage>object:UnregisterAttributeDriver("hasunit")</usage>
	]]
	function UnregisterAttributeDriver(self, attribute, values)
		return _UnregisterAttributeDriver(self.UIElement, attribute, values)
	end

	__Doc__[[
		<desc>Register a frame state to be set automatically with changes in game state</desc>
		<param name="state"></param>
		<param name="values"></param>
		<usage>object:RegisterStateDriver("hasunit", "[@mouseover, exists] true; false")</usage>
	]]
	function RegisterStateDriver(self, state, values)
		return _RegisterStateDriver(self.UIElement, state, values)
	end

	__Doc__[[
		<desc>Unregister a frame from the state driver manager</desc>
		<param name="state"></param>
		<param name="values"></param>
		<usage>object:UnregisterStateDriver("hasunit")</usage>
	]]
	function UnregisterStateDriver(self, state)
		return _UnregisterStateDriver(self.UIElement, state)
	end

	__Doc__[[
		<desc>Register a frame to be notified when a unit's existence changes</desc>
		<format>[asState]</format>
		<usage>object:RegisterUnitWatch()</usage>
	]]
	function RegisterUnitWatch(self, asState)
		return _RegisterUnitWatch(self.UIElement, asState)
	end

	__Doc__[[Unregister a frame from the unit existence monitor]]
	function UnregisterUnitWatch(self)
		return _UnregisterUnitWatch(self.UIElement)
	end

	__Doc__[[
		<desc>Check to see if a frame is registered</desc>
		<return type="boolean"></return>
	]]
	function UnitWatchRegistered(self)
		return _UnitWatchRegistered(self.UIElement)
	end
end)

__Doc__[[SecureFrame is a root widget class for secure frames]]
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

__Doc__[[SecureButton is used as the root widget class for secure buttons]]
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

__Doc__[[SecureCheckButton is used as the root widget class for secure check buttons]]
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