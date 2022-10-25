--========================================================--
--             Scorpio Shared UI Panel Templates          --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/04/17                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Widget.SharedUIPanel"     "1.0.0"
--========================================================--

local _M                        = _M    -- to be used inside the class
local START_MOVE_RESIZE_DELAY   = 0.05  -- A delay to start moving/resizing to reduce the cost

-----------------------------------------------------------
--                   Draggable Widget                    --
-----------------------------------------------------------
--- The widget used as a handler to move other frames
__Sealed__() __ChildProperty__(Frame, "Mover")
class "Mover"                   (function(_ENV)
    inherit "Frame"

    local _Moving               = setmetatable({}, META_WEAKKEY)

    -- Fired when start moving
    event "OnStartMoving"

    -- Fired when stop moving
    event "OnStopMoving"

    local function checkMoving(self)
        local start             = GetTime()

        repeat Next() until _Moving[self] == nil or (GetTime() - start) >= START_MOVE_RESIZE_DELAY

        if _Moving[self] == nil then return end
        local parent            = self.MoveTarget

        _Moving[self]           = LayoutFrame.GetLocation(parent)
        parent:StartMoving()
        return OnStartMoving(self)
    end

    local function onMouseDown(self)
        if self.MoveTarget:IsMovable() then
            _Moving[self]       = false
            return Scorpio.Continue(checkMoving, self)
        end
    end

    local function onMouseUp(self)
        local loc               = _Moving[self]
        _Moving[self]           = nil
        if loc then
            local parent        = self.MoveTarget
            parent:StopMovingOrSizing()

            LayoutFrame.SetLocation(parent, LayoutFrame.GetLocation(parent, loc))

            return OnStopMoving(self)
        end
    end

    local function setMoveTarget(self, ui)
        self.__Mover_Target     = ui
    end

    local function getMoveTarget(self)
        return self.__Mover_Target or self:GetParent()
    end

    --- The Move target
    property "MoveTarget"       { type = UI, set = setMoveTarget, get = getMoveTarget }

    -- Whether the mover is moving
    function IsMoving(self)
        return _Moving[self] and true or false
    end

    function __ctor(self)
        self.OnMouseDown        = onMouseDown
        self.OnMouseUp          = onMouseUp
    end
end)

--- The widget used as handler to resize other frames
__Sealed__() __ChildProperty__(Frame, "Resizer")
class "Resizer"                 (function(_ENV)
    inherit "Button"

    local _ResizingHook         = setmetatable({}, META_WEAKKEY)
    local _Resizing             = {}

    -- Fired when start resizing
    event "OnStartResizing"

    -- Fired when stop resizing
    event "OnStopResizing"

    local function addHook(frame, resizer)
        if not _ResizingHook[frame] then
            _ResizingHook[frame] = _ResizingHook[frame] or {}

            _M:SecureHook(frame, "SetResizable", function(par, flag)
                for hooker in pairs(_ResizingHook[frame]) do
                    hooker:SetShown(flag or false)
                end
            end)
        end

        _ResizingHook[frame][resizer] = true
        resizer:SetShown(frame:IsResizable())
    end

    local function removeHook(frame, resizer)
        if _ResizingHook[frame] then
            _ResizingHook[frame][resizer] = nil
        end
        resizer:SetShown(false)
    end

    local function checkResizing(self)
        local start             = GetTime()

        repeat Next() until _Resizing[self] == nil or (GetTime() - start) >= START_MOVE_RESIZE_DELAY

        if _Resizing[self] == nil then return end
        local parent            = self.ResizeTarget

        _Resizing[self]         = LayoutFrame.GetLocation(parent)
        parent:StartSizing(self.Direction)
        return OnStartResizing(self)
    end

    local function onParentChanged(self, parent, oldparent)
        self.ResizeTarget       = parent
    end

    local function onMouseDown(self)
        if self.ResizeTarget:IsResizable() then
            _Resizing[self]     = false
            return Scorpio.Continue(checkResizing, self)
        end
    end

    local function onMouseUp(self)
        local loc               = _Resizing[self]
        _Resizing[self]         = nil
        if loc then
            local parent        = self.ResizeTarget
            parent:StopMovingOrSizing()

            LayoutFrame.SetLocation(parent, LayoutFrame.GetLocation(parent, loc))

            return OnStopResizing(self)
        end
    end

    local function setResizeTarget(self, ui)
        local old               = self.__Resizer_Target
        if old and ui and UI.IsSameUI(old, ui) then return end

        if old then
            removeHook(old, self)
        end

        if ui then
            addHook(ui, self)
        end

        self.__Resizer_Target   = ui
    end

    local function getResizeTarget(self)
        return self.__Resizer_Target
    end

    --- Whether the resizer is resizing
    function IsResizing(self)
        return _Resizing[self] and true or false
    end

    --- The Resize target
    property "ResizeTarget"     { type = UI, set = setResizeTarget, get = getResizeTarget }

    -- The resizer direction
    property "Direction"        { type = FramePoint, default = "BOTTOMRIGHT" }

    function __ctor(self)
        self.OnMouseDown        = self.OnMouseDown + onMouseDown
        self.OnMouseUp          = self.OnMouseUp + onMouseUp
        self.OnParentChanged    = self.OnParentChanged + onParentChanged

        local parent            = self:GetParent()
        addHook(parent, self)

        self.__Resizer_Target   = parent
    end
end)

--- The widget used as mask to move, resize, toggle, key binding for the target widget
__Sealed__()  __ChildProperty__(Frame, "Mask")
class "Mask"                    (function(_ENV)
    inherit "Button"

    ---------------------------------------------------
    --                     Event                     --
    ---------------------------------------------------
    --- Fired when the mask start resizing
    __Bubbling__{ Resizer = "OnStartResizing" }
    event "OnStartResizing"

    --- Fired when the mask stop resizing
    __Bubbling__{ Resizer = "OnStopResizing" }
    event "OnStopResizing"

    -- Fired when start moving
    event "OnStartMoving"

    -- Fired when stop moving
    event "OnStopMoving"

    --- Fired when set the binding key on the mask
    event "OnKeySet"

    --- Fired when clear the binding key on the mask
    event "OnKeyClear"

    --- Fired when use right click to toggle
    event "OnToggle"

    ---------------------------------------------------
    --                 Event Handler                 --
    ---------------------------------------------------
    local _Moving               = setmetatable({}, META_WEAKKEY)

    local _BlockKey             = {
        UNKNOWN                 = true,
        LSHIFT                  = true,
        RSHIFT                  = true,
        LCTRL                   = true,
        RCTRL                   = true,
        LALT                    = true,
        RALT                    = true,
        PRINTSCREEN             = true,
    }

    local _ReplaceKey           = {
        ['ALT']                 = 'A',
        ['CTRL']                = 'C',
        ['SHIFT']               = 'S',
        ['NUMPAD']              = 'N',
        ['PLUS']                = '+',
        ['MINUS']               = '-',
        ['MULTIPLY']            = '*',
        ['DIVIDE']              = '/',
        ['BACKSPACE']           = 'BAK',
        ['BUTTON']              = 'B',
        ['CAPSLOCK']            = 'CAPS',
        ['CLEAR']               = 'CLR',
        ['DELETE']              = 'DEL',
        ['END']                 = 'END',
        ['HOME']                = 'HME',
        ['INSERT']              = 'INS',
        ['MOUSEWHEELDOWN']      = 'WD',
        ['MOUSEWHEELUP']        = 'WU',
        ['NUMLOCK']             = 'NL',
        ['PAGEDOWN']            = 'PD',
        ['PAGEUP']              = 'PU',
        ['SCROLLLOCK']          = 'SL',
        ['SPACEBAR']            = 'SP',
        ['SPACE']               = 'SP',
        ['TAB']                 = '↦',
        ['DOWNARROW']           = '↓',
        ['LEFTARROW']           = '←',
        ['RIGHTARROW']          = '→',
        ['UPARROW']             = '↑',
    }

    local function refreshToggleState(self)
        self:SetAlpha((not self.EnableToggle or self.ToggleState) and 1 or 0.5)
    end

    local function refreshBindKey(self, key)
        self:GetChild("KeyBindText"):SetText(self.EnableKeyBinding and self.BindingKey and self.BindingKey:upper():gsub(' ', ''):gsub("%a+", _ReplaceKey) or " ")
    end

    local function updateBindKey(self, key)
        key                     = key:upper()

        if _BlockKey[key] then return end

        if key == GetBindingKey("SCREENSHOT") then
            return Screenshot()
        end

        if key == GetBindingKey("OPENCHAT") then
            if _G.ChatFrameEditBox then
                _G.ChatFrameEditBox:Show()
            end
            return
        end

        local oldKey            = self.BindingKey

        if key == "ESCAPE" then
            if oldKey then
                self.BindingKey = nil
                return OnKeyClear(self, oldKey)
            end
        end

        -- Remap mouse key
        if key == "LEFTBUTTON" then
            key                 = "BUTTON1"
        elseif key == "RIGHTBUTTON" then
            key                 = "BUTTON2"
        elseif key == "MIDDLEBUTTON" then
            key                 = "BUTTON3"
        end

        if IsShiftKeyDown() then
            key                 = "SHIFT-" .. key
        end
        if IsControlKeyDown() then
            key                 = "CTRL-" .. key
        end
        if IsAltKeyDown() then
            key                 = "ALT-" .. key
        end

        self.BindingKey         = key

        OnKeySet(self, key, oldKey)
    end

    local function OnShow(self)
        local parent            = self:GetParent()
        if not parent then self:SetShown(false) end

        self:SetSize(parent:GetSize())
    end

    local function checkMoving(self)
        local start             = GetTime()

        repeat Next() until _Moving[self] == nil or (GetTime() - start) >= START_MOVE_RESIZE_DELAY

        if _Moving[self] == nil then return end
        local parent            = self:GetParent()

        _Moving[self]           = LayoutFrame.GetLocation(parent)
        parent:StartMoving()
        return OnStartMoving(self)
    end

    local function OnMouseDown(self)
        local parent            = self:GetParent()
        if parent:IsMovable() then
            _Moving[self]       = false
            return Continue(checkMoving, self)
        end
    end

    local function OnMouseUp(self)
        local loc               = _Moving[self]
        _Moving[self]           = nil
        if loc then
            local parent        = self:GetParent()
            parent:StopMovingOrSizing()

            LayoutFrame.SetLocation(parent, LayoutFrame.GetLocation(parent, loc))

            return OnStopMoving(self)
        end
    end

    local function OnClick(self, button)
        if self.EnableToggle and button == "RightButton" then
            self.ToggleState = not self.ToggleState
            return OnToggle(self, self.ToggleState)
        elseif self.EnableKeyBinding then
            return updateBindKey(self, button)
        end
    end

    local function OnMouseWheel(self, wheel)
        if self.EnableKeyBinding then
            return updateBindKey(self, wheel > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN")
        end
    end

    local function OnKeyDown(self, key)
        if self.EnableKeyBinding then
            return updateBindKey(self, key)
        end
    end

    local function OnEnter(self)
        self:EnableKeyboard(self.EnableKeyBinding)
    end

    local function OnLeave(self)
        self:EnableKeyboard(false)
    end

    local function OnParentChanged(self, parent)
        if parent then
            self:ClearAllPoints()
            self:SetAllPoints(parent)

            self:GetChild("Resizer").ResizeTarget = self:GetParent()
        else
            self:ClearAllPoints()
            self:Hide()
        end
    end

    ---------------------------------------------------
    --                    Method                     --
    ---------------------------------------------------
    --- Whether the mask is resizing
    function IsResizing(self)
        return self:GetChild("Resizer"):IsResizing()
    end

    --- Whether the mask is moving
    function IsMoving(self)
        return _Moving[self] and true or false
    end

    --- Enable the key binding
    function SetKeyBindingEnabled(self, flag)
        self.EnableKeyBinding   = flag
    end

    --- Whether the key binding is enabled
    function IsKeyBindingEnabled(self)
        return self.EnableKeyBinding
    end

    --- Sets the binding key
    function SetBindingKey(self, key)
        self.BindingKey         = key
    end

    --- Gets the binding key
    function GetBindingKey(self)
        return self.BindingKey
    end

    --- Enable the right-click toggle functionality
    function SetToggleEnabled(self, flag)
        self.EnableToggle       = flag
    end

    --- Whether the right-click toggle functionality is enabled
    function IsToggleEnabled(self)
        return self.EnableToggle
    end

    --- Sets the toggle state
    function SetToggleState(self, flag)
        self.ToggleState        = flag
    end

    --- Gets the toggle state
    function GetToggleState(self)
        return self.ToggleState
    end

    ---------------------------------------------------
    --                   Property                    --
    ---------------------------------------------------
    --- Whether the key binding is enabled
    property "EnableKeyBinding" { type = Boolean, handler = refreshBindKey }

    --- The binding key
    property "BindingKey"       { type = String,  handler = refreshBindKey }

    --- Whether the right-click toggle functionality is enabled
    property "EnableToggle"     { type = Boolean, handler = refreshToggleState }

    --- The toggle state
    property "ToggleState"      { type = Boolean, handler = refreshToggleState }

    ---------------------------------------------------
    --                  Constructor                  --
    ---------------------------------------------------
    __Template__{
        Resizer                 = Resizer,
        KeyBindText             = FontString,
    }
    function __ctor(self)
        self.OnShow             = self.OnShow           + OnShow
        self.OnMouseDown        = self.OnMouseDown      + OnMouseDown
        self.OnMouseUp          = self.OnMouseUp        + OnMouseUp
        self.OnClick            = self.OnClick          + OnClick
        self.OnMouseWheel       = self.OnMouseWheel     + OnMouseWheel
        self.OnKeyDown          = self.OnKeyDown        + OnKeyDown
        self.OnEnter            = self.OnEnter          + OnEnter
        self.OnLeave            = self.OnLeave          + OnLeave
        self.OnParentChanged    = self.OnParentChanged  + OnParentChanged

        self:RegisterForClicks("AnyUp")

        self:GetChild("Resizer").ResizeTarget = self:GetParent()

        -- For Key Bindings
        self:EnableMouse(true)
        self:EnableMouseWheel(true)
        self:EnableKeyboard(false)

        self:SetShown(false)
    end
end)

-----------------------------------------------------------
--                 UIPanelButton Widget                  --
-----------------------------------------------------------
__Sealed__()
class "UIPanelButton"           { Button }

__Sealed__()
class "UIPanelCloseButton"      { Button, function(self) self.OnClick = function(self) self:GetParent():Hide() end end }

__Sealed__()
class "UIToggleButton"          { Button, ToggleTexture = { type = Texture, set = function(self, texture) return texture and texture:SetShown(self.ToggleState) end }, ToggleState = { type = Boolean, default = false, handler = function(self, val) self:GetPropertyChild("ToggleTexture"):SetShown(val) self:GetPropertyChild("NormalTexture"):SetShown(not val) end }}

-----------------------------------------------------------
--                    InputBox Widget                    --
-----------------------------------------------------------
__Sealed__() __ConfigDataType__(Number, String)
class "InputBox"                (function(_ENV)
    inherit "EditBox"

    local function OnEscapePressed(self)
        self:ClearFocus()
    end

    local function OnEditFocusGained(self)
        self:HighlightText()
    end

    local function OnEditFocusLost(self)
        self:HighlightText(0, 0)
    end

    local function OnTextChangedFix(self)
        return true
    end

    local function OnTextChanged(self)
        if self.__CheckNumber then
            local text          = self:GetText()
            local value         = tonumber(text)
            if value and tostring(value) == text then
                self:SetConfigSubjectValue(value)
            end
        else
            self:SetConfigSubjectValue(self:GetText())
        end
    end

    local function FixInputDisplay(self)
        -- Already in the progress
        if self.OnTextChanged[0] then
            Delay(0.1)
            if self.OnTextChanged[0] then return end
        end

        -- Only continue when it's visible
        if not self:IsVisible() then
            Next(Observable.From(self.OnShow))
        end

        self.OnTextChanged:SetInitFunction(OnTextChangedFix)

        if self:IsNumeric() then
            local orgVal    = self:GetText()
            local rval      = (tonumber(orgVal or 0) or 0) + 111111
            self:SetNumber(rval)
            rval            = self:GetNumber()

            Next()

            if self:IsNumeric() and self:GetNumber() == rval then
                self:SetNumber(orgVal or "")
            end
        else
            local orgText   = self:GetText() or ""
            local rtext     = Guid.New()
            self:SetText(rtext)
            rtext           = self:GetText()

            for i = 1, 4 do
                Next()

                if self:GetText() ~= rtext then
                    orgText     = self:GetText()
                end

                rtext           = Guid.New()
                self:SetText(rtext)
                rtext           = self:GetText()
            end

            Next()

            if self:GetText() == rtext then
                self:SetText(orgText)
            end
        end

        self.OnTextChanged:SetInitFunction(nil)
    end

    local function OnStyleApplied(self)
        return Next(FixInputDisplay, self)
    end

    --- Sets the config node field
    function SetConfigSubject(self, configSubject)
        self.OnTextChanged      = self.OnTextChanged + OnTextChanged
        self.__CheckNumber      = Struct.IsSubType(configSubject.Type, Number)

        -- subscribe the config subject
        return configSubject:Subscribe(function(value)
            local hasFocus      = self:HasFocus()
            local text          = value ~= nil and tostring(value) or ""
            if text == self:GetText() then return end
            self:SetText(text)
            if hasFocus then
                self:SetFocus()
                self:SetCursorPosition(#text)
            end
        end)
    end

    __InstantApplyStyle__()
    function __ctor(self)
        self.OnStyleApplied     = self.OnStyleApplied + OnStyleApplied
        self.OnEscapePressed    = self.OnEscapePressed + OnEscapePressed
        self.OnEditFocusGained  = self.OnEditFocusGained + OnEditFocusGained
        self.OnEditFocusLost    = self.OnEditFocusLost + OnEditFocusLost
    end
end)

-----------------------------------------------------------
--                   Track Bar Widget                    --
-----------------------------------------------------------
__Sealed__() __ConfigDataType__(RangeValue)
class "TrackBar"                (function(_ENV)
    inherit "Slider"

    local floor                 = math.floor
    local getValue              = Slider.GetValue
    local setValue              = Slider.SetValue
    local setValueStep          = Slider.SetValueStep
    local getValueStep          = Slider.GetValueStep

    local function OnValueChanged(self)
        local value             = self:GetValue()
        self:GetChild("Text"):SetText(value or "")
        self:SetConfigSubjectValue(value)
    end

    --- Sets the value
    function SetValue(self, value)
        if type(value) ~= "number" then return end
        setValue(self, value)
        self:GetChild("Text"):SetText(self:GetValue())
    end

    --- Gets the value
    function GetValue(self)
        local value             = getValue(self)
        local step              = self:GetValueStep()

        if value and step then
            local count         = tostring(step):match("%.%d+")
            count               = count and 10 ^ (#count - 1) or 1
            return floor(count * value + 0.5) / count
        end

        return value
    end

    --- Sets the value step
    function SetValueStep(self, step)
        self.__RealValueStep    = step
        setValueStep(self, step)
    end

    --- Gets the value step
    function GetValueStep(self)
        return self.__RealValueStep or getValueStep(self)
    end

    --- Sets the config node field
    function SetConfigSubject(self, configSubject)
        local min, max, step    = Struct.GetTemplateParameters(configSubject.Type)
        self:SetMinMaxValues(min, max)
        self:SetValueStep(step or (max - min) / 100)

        -- subscribe the config subject
        return configSubject:Subscribe(function(value) self:SetValue(value) end)
    end

    __Template__{
        Text                    = FontString,
        MinText                 = FontString,
        MaxText                 = FontString,
    }
    __InstantApplyStyle__()
    function __ctor(self)
        self.OnValueChanged     = self.OnValueChanged + OnValueChanged
    end
end)

-----------------------------------------------------------
--                     Dialog Widget                     --
-----------------------------------------------------------
__Sealed__() __Template__(Frame)
class "Dialog"                  {
    Resizer                     = Resizer,
    CloseButton                 = UIPanelCloseButton,
}

__Sealed__() __Template__(Mover)
__ChildProperty__(Dialog, "Header")
class "DialogHeader"            {
    HeaderText                  = FontString,

    --- The text of the header
    Text                        = {
        type                    = String,
        set                     = function(self, text)
            local headerText    = self:GetChild("HeaderText")
            headerText:SetText(text or "")

            Next(function()
                local minResize = Style[self].minResize
                local maxResize = Style[self].maxResize
                local minwidth  = minResize and minResize.width or 0
                local maxwidth  = maxResize and maxResize.width or math.huge
                if maxwidth == 0 then maxwidth = math.huge end
                maxwidth        = math.min(maxwidth, self:GetParent() and self:GetParent():GetWidth() or math.huge)
                local textwidth = headerText:GetStringWidth() + self.TextPadding

                self:SetWidth(math.min( math.max(minwidth, textwidth), maxwidth))
            end)
        end,
        get                     = function(self)
            return self:GetChild("HeaderText"):GetText()
        end
    },

    --- The text padding of the header(the sum of the spacing on the left & right)
    TextPadding                 = { type = Number, default = 64, handler = function(self) self.Text = self.Text end }
}

-----------------------------------------------------------
--                    GroupBox Widget                    --
-----------------------------------------------------------
__Sealed__() __Template__(Frame)
class "GroupBox"                { }

-----------------------------------------------------------
--                 UICheckButton Widget                  --
-----------------------------------------------------------
__Sealed__() __ConfigDataType__(Boolean)
class "UICheckButton"           (function(_ENV)
    inherit "CheckButton"

    local function OnValueChanged(self)
        self:SetConfigSubjectValue(self:GetChecked())
    end

    --- Sets the text
    __Async__()
    function SetText(self, text)
        local nameText          = self:GetChild("NameText")
        nameText:SetText(text)

        local trycnt            = 10
        while trycnt > 0 and not (self:GetRight() and nameText:GetLeft()) do
            Next() trycnt       = trycnt - 1
        end
        if trycnt == 0 then return end

        if self:GetRight() > nameText:GetLeft() then
            self:SetHitRectInsets(0, self:GetRight() - nameText:GetLeft() - nameText:GetStringWidth(), 0, 0)
        else
            self:SetHitRectInsets(0, 0, 0, 0)
        end
    end

    --- Gets the text
    function GetText(self)
        return self:GetChild("NameText"):GetText()
    end

    --- Sets the config node field
    function SetConfigSubject(self, configSubject)
        -- subscribe the config subject
        return configSubject:Subscribe(function(value) self:SetChecked(value) end)
    end

    __Template__{
        NameText                = FontString
    }
    function __ctor(self)
        self.PostClick          = self.PostClick + OnValueChanged
    end
end)

__Sealed__()
class "UIRadioButton"           (function(_ENV)
    inherit "CheckButton"

    local IsObjectType          = Class.IsObjectType

    local function OnClick(self)
        return self:SetChecked(true)
    end

    function SetChecked(self, flag)
        if flag then
            local parent        = self:GetParent()
            if parent then
                for name, child in UIObject.GetChilds(parent) do
                    if child ~= self and IsObjectType(child, UIRadioButton) then
                        child:SetChecked(false)
                    end
                end
            end
        end

        return CheckButton.SetChecked(self, flag)
    end

    --- Sets the text
    SetText                     = UICheckButton.SetText

    --- Gets the text
    GetText                     = UICheckButton.GetText

    __Template__{
        NameText                = FontString
    }
    function __ctor(self)
        self.OnClick            = self.OnClick + OnClick
    end
end)

-----------------------------------------------------------
--                 UIColorPicker Widget                  --
-----------------------------------------------------------
--- The color picker
__Sealed__() __ConfigDataType__(ColorType)
class "UIColorPicker"           (function(_ENV)
    inherit "Button"

    --- Fired when color picked
    event "OnColorPicked"

    -- Helpers
    local function chooseColor(self)
        local color             = Scorpio.PickColor(self.Color)
        if color then
            self.Color          = color
            OnColorPicked(self, color)

            self:SetConfigSubjectValue(color)
        end
    end

    local function OnClick(self)
        Next(chooseColor, self)
    end

    --- The color property
    property "Color"            {
        type                    = ColorType,
        handler                 = function(self, color)
            if color then
                self:GetChild("ColorSwatch"):SetColorTexture(color.r, color.g, color.b)
            else
                self:GetChild("ColorSwatch"):SetColorTexture(1, 1, 1)
            end
        end
    }

    --- Sets the config node field
    function SetConfigSubject(self, configSubject)
        -- subscribe the config subject and return the observer for tracking
        return configSubject:Subscribe(function(value) self.Color = value end)
    end

    -- Constructor
    __Template__{
        ColorSwatchBG           = Texture,
        ColorSwatch             = Texture,
    }
    function __ctor(self)
        self.OnClick            = self.OnClick + OnClick
    end
end)

-----------------------------------------------------------
--                     Default Style                     --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [Mover]                     = {
        location                = { Anchor("TOPLEFT"), Anchor("TOPRIGHT") },
        height                  = 26,
        enableMouse             = true,
    },
    [Resizer]                   = {
        location                = { Anchor("BOTTOMRIGHT") },
        size                    = Size(16, 16),

        NormalTexture           = {
            file                = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]],
            setAllPoints        = true,
        },
        PushedTexture           = {
            file                = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Down]],
            setAllPoints        = true,
        },
        HighlightTexture        = {
            file                = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Highlight]],
            setAllPoints        = true,
        }
    },
    [Mask]                      = {
        toplevel                = true,
        frameStrata             = "FULLSCREEN",
        setAllPoints            = true,
        backdrop                = {
            bgFile              = [[Interface\Tooltips\UI-Tooltip-Background]],
            edgeFile            = [[Interface\Tooltips\UI-Tooltip-Border]],
            tile                = true, tileSize = 16, edgeSize = 8,
            insets              = { left = 3, right = 3, top = 3, bottom = 3 }
        },
        backdropColor           = Color(0, 1, 0, 0.4),

        KeyBindText             = {
            location            = { Anchor("CENTER") },
            fontObject          = GameFontNormal,
        }
    },
    [UIPanelButton]             = {
        size                    = Size(80, 22),
        normalFont              = GameFontNormal,
        disabledFont            = GameFontDisable,
        highlightFont           = GameFontHighlight,

        LeftBGTexture           = {
            drawLayer           = "ARTWORK",
            file                = [[Interface\Buttons\UI-Panel-Button-Up]],
            texCoords           = RectType(0, 0.09375, 0, 0.6875),
            location            = {
                Anchor("TOPLEFT", 0, 0),
                Anchor("BOTTOMLEFT", 0, 0),
            },
            width               = 12,
        },
        RightBGTexture          = {
            file                = [[Interface\Buttons\UI-Panel-Button-Up]],
            texCoords           = RectType(0.53125, 0.625, 0, 0.6875),
            location            = {
                Anchor("TOPRIGHT", 0, 0),
                Anchor("BOTTOMRIGHT", 0, 0),
            },
            width               = 12,
        },
        MiddleBGTexture         = {
            file                = [[Interface\Buttons\UI-Panel-Button-Up]],
            texCoords           = RectType(0.09375, 0.53125, 0, 0.6875),
            location            = {
                Anchor("TOPLEFT", 0, 0, "LeftBGTexture", "TOPRIGHT"),
                Anchor("BOTTOMRIGHT", 0, 0, "RightBGTexture", "BOTTOMLEFT"),
            }
        },
    },
    [UIPanelCloseButton]        = {
        size                    = Size(32, 32),
        location                = { Anchor("TOPRIGHT", -4, 4) },

        NormalTexture           = {
            file                = [[Interface\Buttons\UI-Panel-MinimizeButton-Up]],
            setAllPoints        = true,
        },
        PushedTexture           = {
            file                = [[Interface\Buttons\UI-Panel-MinimizeButton-Down]],
            setAllPoints        = true,
        },
        HighlightTexture        = {
            file                = [[Interface\Buttons\UI-Panel-MinimizeButton-Highlight]],
            setAllPoints        = true,
            alphamode           = "ADD",
        },
    },
    [UIToggleButton]            = {
            size                = Size(14, 14),

            NormalTexture       = {
                file            = [[Interface\Buttons\UI-PlusButton-UP]],
                setAllPoints    = true,
            },
            ToggleTexture       = {
                file            = [[Interface\Buttons\UI-MinusButton-Up]],
                setAllPoints    = true,
            },
            HighlightTexture    = {
                file            = [[Interface\Buttons\UI-PlusButton-Hilight]],
                setAllPoints    = true,
                alphaMode       = "ADD",
            },
    },
    [InputBox]                  = {
        fontObject              = ChatFontNormal,
        autoFocus               = false,
        size                    = Size(150, 24),

        LeftBGTexture           = {
            atlas               = {
                atlas           = [[common-search-border-left]],
                useAtlasSize    = false,
            },
            location            = {
                Anchor("TOPLEFT", -5, 0),
                Anchor("BOTTOMLEFT", -5, 0),
            },
            width = 8,
        },
        RightBGTexture          = {
            atlas               = {
                atlas           = [[common-search-border-right]],
                useAtlasSize    = false,
            },
            location            = {
                Anchor("TOPRIGHT", 0, 0),
                Anchor("BOTTOMRIGHT", 0, 0),
            },
            width = 8,
        },
        MiddleBGTexture         = {
            atlas               = {
                atlas           = [[common-search-border-middle]],
                useAtlasSize    = false,
            },
            location            = {
                Anchor("TOPLEFT", 0, 0, "LeftBGTexture", "TOPRIGHT"),
                Anchor("BOTTOMRIGHT", 0, 0, "RightBGTexture", "BOTTOMLEFT"),
            }
        },
    },
    [TrackBar]                  = {
        orientation             = "HORIZONTAL",
        enableMouse             = true,
        obeyStepOnDrag          = true,
        size                    = Size(200, 24),
        hitRectInsets           = Inset(0, 0, -10, -10),
        backdrop                = {
            bgFile              = [[Interface\Buttons\UI-SliderBar-Background]],
            edgeFile            = [[Interface\Buttons\UI-SliderBar-Border]],
            tile                = true, tileSize = 8, edgeSize = 8,
            insets              = { left = 3, right = 3, top = 6, bottom = 6 }
        },

        ThumbTexture            = {
            file                = [[Interface\Buttons\UI-SliderBar-Button-Horizontal]],
            size                = Size(32, 32),
        },

        Text                    = {
            fontObject          = GameFontNormalSmall,
            location            = { Anchor("TOP", 0, 0, nil, "BOTTOM") },
        },

        MinText                 = {
            fontObject          = GameFontNormalHuge,
            location            = { Anchor("TOPLEFT", 0, 0, nil, "BOTTOMLEFT") },
            text                = "-",
        },

        MaxText                 = {
            fontObject          = GameFontNormalHuge,
            location            = { Anchor("TOPRIGHT", 0, 0, nil, "BOTTOMRIGHT") },
            text                = "+",
        }
    },
    [Dialog]                    = {
        frameStrata             = "DIALOG",
        size                    = Size(300, 200),
        location                = { Anchor("CENTER") },
        minResize               = Size(100, 100),
        toplevel                = true,
        movable                 = true,
        resizable               = true,
        backdrop                = {
            bgFile              = [[Interface\DialogFrame\UI-DialogBox-Background]],
            edgeFile            = [[Interface\DialogFrame\UI-DialogBox-Border]],
            tile                = true, tileSize = 32, edgeSize = 32,
            insets              = { left = 11, right = 12, top = 12, bottom = 11 }
        },
        backdropBorderColor     = Color(1, 1, 1),

        CloseButton             = {
            location            = { Anchor("TOPRIGHT", -4, -4)},
        },

        Resizer                 = {
            location            = { Anchor("BOTTOMRIGHT", -8, 8)}
        }
    },
    [DialogHeader]              = {
        height                  = 39,
        width                   = 200,
        location                = { Anchor("TOP", 0, 11) },

        HeaderText              = {
            fontObject          = GameFontNormal,
            location            = { Anchor("TOP", 0, -13) },
        },
        LeftBGTexture           = {
            atlas               = {
                atlas           = [[UI-Frame-DiamondMetal-Header-CornerLeft]],
                useAtlasSize    = false,
            },
            texelSnappingBias   = 0,
            snapToPixelGrid     = false,
            size                = Size(32, 39),
            location            = { Anchor("LEFT") },
        },
        RightBGTexture          = {
            atlas               = {
                atlas           = [[UI-Frame-DiamondMetal-Header-CornerRight]],
                useAtlasSize    = false,
            },
            texelSnappingBias   = 0,
            snapToPixelGrid     = false,
            size                = Size(32, 39),
            location            = { Anchor("RIGHT") },
        },
        MiddleBGTexture         = {
            atlas               = {
                atlas           = [[_UI-Frame-DiamondMetal-Header-Tile]],
                useAtlasSize    = false,
            },
            horizTile           = true,
            texelSnappingBias   = 0,
            snapToPixelGrid     = false,
            location            = {
                Anchor("TOPLEFT", 0, 0, "LeftBGTexture", "TOPRIGHT"),
                Anchor("BOTTOMRIGHT", 0, 0, "RightBGTexture", "BOTTOMLEFT"),
            }
        },
    },
    [GroupBox]                  = {
        backdrop                = {
            edgeFile            = [[Interface\Tooltips\UI-Tooltip-Border]],
            tile                = true, tileSize = 16, edgeSize = 16,
            insets              = { left = 5, right = 5, top = 5, bottom = 5 }
        },
        backdropBorderColor     = Color(0.6, 0.6, 0.6),
    },
    [UIRadioButton]             = {
        size                    = Size(16, 16),

        NormalTexture           = {
            file                = [[Interface\Buttons\UI-RadioButton]],
            texCoords           = RectType(0, 0.25, 0, 1),
            setAllPoints        = true,
        },
        CheckedTexture           = {
            file                = [[Interface\Buttons\UI-RadioButton]],
            texCoords           = RectType(0.25, 0.5, 0, 1),
            setAllPoints        = true,
        },
        HighlightTexture        = {
            file                = [[Interface\Buttons\UI-RadioButton]],
            texCoords           = RectType(0.5, 0.5, 0, 1),
            setAllPoints        = true,
            alphaMode           = "ADD",
        },

        NameText                = {
            fontObject          = GameFontNormalSmall,
            location            = { Anchor("LEFT", 5, 0, nil, "RIGHT") }
        },
    },
    [UICheckButton]             = {
        size                    = Size(32, 32),

        NormalTexture           = {
            file                = [[Interface\Buttons\UI-CheckBox-Up]],
            setAllPoints        = true,
        },
        PushedTexture           = {
            file                = [[Interface\Buttons\UI-CheckBox-Down]],
            setAllPoints        = true,
        },
        HighlightTexture        = {
            file                = [[Interface\Buttons\UI-CheckBox-Highlight]],
            setAllPoints        = true,
            alphamode           = "ADD",
        },
        CheckedTexture          = {
            file                = [[Interface\Buttons\UI-CheckBox-Check]],
            setAllPoints        = true,
        },
        DisabledCheckedTexture  = {
            file                = [[Interface\Buttons\UI-CheckBox-Check-Disabled]],
            setAllPoints        = true,
        },
        NameText                = {
            fontObject          = GameFontNormalSmall,
            location            = { Anchor("LEFT", -2, 0, nil, "RIGHT") },
        },
    },
    [UIColorPicker]             = {
        size                    = Size(32, 32),

        ColorSwatchBG           = {
            drawLayer           = "ARTWORK",
            setAllPoints        = true,
            file                = [[Interface\ChatFrame\ChatFrameColorSwatch]],
        },
        ColorSwatch             = {
            drawLayer           = "OVERLAY",
            location            = { Anchor("TOPLEFT", 2, -2), Anchor("BOTTOMRIGHT", -2, 2) },
        },
    },
})

if Scorpio.IsRetail then return end

-- The skin for the classic game
Style.UpdateSkin("Default", {
    [InputBox]                  = {
        fontObject              = ChatFontNormal,

        LeftBGTexture           = {
            file                = [[Interface\Common\Common-Input-Border]],
            texCoords           = RectType(0, 0.0625, 0, 0.625),
            location            = {
                Anchor("TOPLEFT", -5, 0),
                Anchor("BOTTOMLEFT", -5, 0),
            },
            width = 8,
        },
        RightBGTexture          = {
            file                = [[Interface\Common\Common-Input-Border]],
            texCoords           = RectType(0.9375, 1.0, 0, 0.625),
            location            = {
                Anchor("TOPRIGHT", 0, 0),
                Anchor("BOTTOMRIGHT", 0, 0),
            },
            width = 8,
        },
        MiddleBGTexture         = {
            file                = [[Interface\Common\Common-Input-Border]],
            texCoords           = RectType(0.0625, 0.9375, 0, 0.625),
            location            = {
                Anchor("TOPLEFT", 0, 0, "LeftBGTexture", "TOPRIGHT"),
                Anchor("BOTTOMRIGHT", 0, 0, "RightBGTexture", "BOTTOMLEFT"),
            }
        },
    },
    [DialogHeader]              = {
        height                  = 39,
        width                   = 200,
        location                = { Anchor("TOP", 0, 11) },

        HeaderText              = {
            fontObject          = GameFontNormal,
            location            = { Anchor("TOP", 0, -13) },
        },
        LeftBGTexture           = {
            file                = [[Interface\DialogFrame\UI-DialogBox-Header]],
            size                = Size(32, 41),
            location            = { Anchor("LEFT") },
            texCoords           = RectType(0.22265625, 0.34375, 0, 0.640625),
        },
        RightBGTexture          = {
            file                = [[Interface\DialogFrame\UI-DialogBox-Header]],
            size                = Size(32, 41),
            location            = { Anchor("RIGHT") },
            texCoords           = RectType(0.65234375, 0.77734375, 0, 0.640625),
        },
        MiddleBGTexture         = {
            file                = [[Interface\DialogFrame\UI-DialogBox-Header]],
            texCoords           = RectType(0.34375, 0.65234375, 0, 0.640625),
            location            = {
                Anchor("TOPLEFT", 0, 0, "LeftBGTexture", "TOPRIGHT"),
                Anchor("BOTTOMRIGHT", 0, 0, "RightBGTexture", "BOTTOMLEFT"),
            }
        },
    },
})