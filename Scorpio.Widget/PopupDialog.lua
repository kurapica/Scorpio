--========================================================--
--             Scorpio PopupDialog Widget                 --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/02/04                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Widget.PopupDialog"       "1.0.0"
--========================================================--

export {
    running                     = coroutine.running,
    yield                       = coroutine.yield,
    resume                      = coroutine.resume,
    OpenColorPicker             = OpenColorPicker,

    POPUP_TYPE_ALERT            = 1,
    POPUP_TYPE_INPUT            = 2,
    POPUP_TYPE_CONFIRM          = 3,
    POPUP_TYPE_COLORPICKER      = 4,
    POPUP_TYPE_OPACITYPICKER    = 5,

    _PopupQueue                 = Queue(),
}

-----------------------------------------------------------
--                     Popup Widget                      --
-----------------------------------------------------------
__Sealed__() class "AlertDialog" (function(_ENV)
    inherit "Dialog"

    __Bubbling__{ OkayButton    = "OnClick", CloseButton = "OnClick" }
    event "OnOkay"

    __Template__{
        Message                 = FontString,
        OkayButton              = UIPanelButton,
    }
    function __ctor(self) end
end)

__Sealed__() class "InputDialog" (function(_ENV)
    inherit "Dialog"

    __Bubbling__{ ConfirmButton = "OnClick", InputBox = "OnEnterPressed" }
    event "OnConfirm"

    __Bubbling__{ CancelButton  = "OnClick", InputBox = "OnEscapePressed", CloseButton = "OnClick" }
    event "OnCancel"

    __Template__{
        Message                 = FontString,
        InputBox                = InputBox,
        ConfirmButton           = UIPanelButton,
        CancelButton            = UIPanelButton,
    }
    function __ctor(self) end
end)

__Sealed__() class "ConfirmDialog" (function(_ENV)
    inherit "Dialog"

    __Bubbling__{ ConfirmButton = "OnClick" }
    event "OnConfirm"

    __Bubbling__{ CancelButton  = "OnClick", CloseButton = "OnClick" }
    event "OnCancel"

    __Template__{
        Message                 = FontString,
        ConfirmButton           = UIPanelButton,
        CancelButton            = UIPanelButton,
    }
    function __ctor(self) end
end)

-----------------------------------------------------------
--                Dialog Style - Default                 --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [AlertDialog]               = {
        size                    = Size(320, 100),
        resizable               = false,
        frameStrata             = "FULLSCREEN_DIALOG",
        location                = { Anchor("CENTER") },

        -- Childs
        Message                 = {
            location            = { Anchor("TOP", 0, -16) },
            width               = 290,
            drawLayer           = "ARTWORK",
            fontObject          = GameFontHighlight,
        },
        OkayButton              = {
            text                = _G.OKAY or "Okay",
            location            = { Anchor("BOTTOM", 0, 16) },
        }
    },
    [InputDialog]               = {
        size                    = Size(360, 130),
        resizable               = false,
        frameStrata             = "FULLSCREEN_DIALOG",
        location                = { Anchor("CENTER") },

        -- Childs
        Message                 = {
            location            = { Anchor("TOP", 0, -16) },
            width               = 290,
            drawLayer           = "ARTWORK",
            fontObject          = GameFontHighlight,
        },
        InputBox                = {
            location            = { Anchor("TOP", 0, -50) },
            size                = Size(240, 32),
            autoFocus           = true,
        },
        ConfirmButton           = {
            text                = _G.OKAY or "Okay",
            location            = { Anchor("BOTTOMRIGHT", -4, 16, nil, "BOTTOM") },
        },
        CancelButton            = {
            text                = _G.CANCEL or "Cancel",
            location            = { Anchor("BOTTOMLEFT", 4, 16, nil, "BOTTOM") },
        }
    },
    [ConfirmDialog]             = {
        size                    = Size(360, 100),
        resizable               = false,
        frameStrata             = "FULLSCREEN_DIALOG",
        location                = { Anchor("CENTER") },

        -- Childs
        Message                 = {
            location            = { Anchor("TOP", 0, -16) },
            width               = 290,
            drawLayer           = "ARTWORK",
            fontObject          = GameFontHighlight,
        },
        ConfirmButton           = {
            text                = _G.OKAY or "Okay",
            location            = { Anchor("BOTTOMRIGHT", -4, 16, nil, "BOTTOM") },
        },
        CancelButton            = {
            text                = _G.CANCEL or "Cancel",
            location            = { Anchor("BOTTOMLEFT", 4, 16, nil, "BOTTOM") },
        }
    }
})

-----------------------------------------------------------
--                       Popup API                       --
-----------------------------------------------------------
local _CurrentPopup

OpacityFrame:HookScript("OnHide", function(self)
    if _CurrentPopup == self then
        if OpacityFrame.saveOpacityFunc then
            OpacityFrame.saveOpacityFunc()
        end
    end
end)

function showPopup()
    if _CurrentPopup then return end

    local qtype, message, thread = _PopupQueue:Dequeue(3)
    if not qtype then return end

    local isthread              = type(thread) == "thread"

    if qtype == POPUP_TYPE_ALERT then
        _CurrentPopup           = AlertDialog("Scorpio_AlertDialog")
        _CurrentPopup.OnOkay    = function(self)
            self:Hide()
            Next(showPopup) _CurrentPopup = nil
            if isthread then
                return resume(thread)
            elseif thread then
                return thread()
            end
        end

        _CurrentPopup:GetChild("Message"):SetText(message)
        _CurrentPopup:Show()
    elseif qtype == POPUP_TYPE_INPUT then
        _CurrentPopup           = InputDialog("Scorpio_InputDialog")
        _CurrentPopup:GetChild("InputBox"):SetText("")
        _CurrentPopup.OnConfirm = function(self)
            local text          = self:GetChild("InputBox"):GetText()
            if text and strtrim(text) == "" then text = nil end
            self:Hide()
            Next(showPopup) _CurrentPopup = nil
            if isthread then
                return resume(thread, text)
            else
                return thread(text)
            end
        end

        _CurrentPopup.OnCancel  = function(self)
            self:Hide()
            Next(showPopup) _CurrentPopup = nil
            if isthread then
                return resume(thread)
            else
                return thread()
            end
        end

        _CurrentPopup:GetChild("Message"):SetText(message)
        _CurrentPopup:Show()
    elseif qtype == POPUP_TYPE_CONFIRM then
        _CurrentPopup           = ConfirmDialog("Scorpio_ConfirmDialog")
        _CurrentPopup.OnConfirm = function(self)
            self:Hide()
            Next(showPopup) _CurrentPopup = nil
            if isthread then
                return resume(thread, true)
            else
                return thread(true)
            end
        end

        _CurrentPopup.OnCancel  = function(self)
            self:Hide()
            Next(showPopup) _CurrentPopup = nil
            if isthread then
                return resume(thread, false)
            else
                return thread(false)
            end
        end

        _CurrentPopup:GetChild("Message"):SetText(message)
        _CurrentPopup:Show()
    elseif qtype == POPUP_TYPE_COLORPICKER then
        _CurrentPopup           = ColorPickerFrame
        local color             = Color(message)

        while ColorPickerFrame:IsShown() or InCombatLockdown() do
            Next()
        end

        if isthread then
            local firstopen     = true

            OpenColorPicker     {
                hasOpacity      = true,
                r               = color.r,
                g               = color.g,
                b               = color.b,
                opacity         = 1 - color.a,
                swatchFunc      = function()
                    if firstopen or ColorPickerFrame:IsShown() then firstopen = false return end
                    Next(showPopup) _CurrentPopup = nil

                    local r,g,b = ColorPickerFrame:GetColorRGB()
                    local a     = 1 - OpacitySliderFrame:GetValue()

                    return resume(thread, Color(r, g, b, a))
                end,
                cancelFunc      = function()
                    Next(showPopup) _CurrentPopup = nil

                    return resume(thread, color)
                end,
            }
        else
            OpenColorPicker     {
                hasOpacity      = true,
                r               = color.r,
                g               = color.g,
                b               = color.b,
                opacity         = 1 - color.a,
                swatchFunc      = function()
                    if not ColorPickerFrame:IsShown() then
                        Next(showPopup) _CurrentPopup = nil
                    end

                    local r,g,b = ColorPickerFrame:GetColorRGB()
                    local a     = 1 - OpacitySliderFrame:GetValue()

                    return thread(Color(r, g, b, a))
                end,
                opacityFunc     = function()
                    local r,g,b = ColorPickerFrame:GetColorRGB()
                    local a     = 1 - OpacitySliderFrame:GetValue()

                    return thread(Color(r, g, b, a))
                end,
                cancelFunc      = function()
                    Next(showPopup) _CurrentPopup = nil

                    return thread(color)
                end,
            }
        end
    elseif qtype == POPUP_TYPE_OPACITYPICKER then
        _CurrentPopup           = OpacityFrame
        local opacity           = message

        while OpacityFrame:IsShown() or InCombatLockdown() do
            Next()
        end

        OpacityFrame:ClearAllPoints()
        OpacityFrame:SetPoint("BOTTOMLEFT", GetCursorPosition())
        OpacityFrameSlider:SetValue(1 - opacity)

        if isthread then
            OpacityFrame.opacityFunc        = nil
            OpacityFrame.saveOpacityFunc    = function()
                if not _CurrentPopup then return end
                Next(showPopup) _CurrentPopup = nil
                return resume(thread, 1- OpacityFrameSlider:GetValue())
            end
        else
            OpacityFrame.opacityFunc        = function()
                return thread(1 - OpacityFrameSlider:GetValue())
            end
            OpacityFrame.saveOpacityFunc    = function()
                if not _CurrentPopup then return end
                Next(showPopup) _CurrentPopup = nil
            end
        end

        OpacityFrame:Show()
    end
end

function queuePopup(qtype, message, func)
    local current               = func or running()

    if not current then
       if qtype == POPUP_TYPE_INPUT then
            error("The Input(message[, callback]) must be used in a coroutine or with a callback", 3)
        elseif qtype == POPUP_TYPE_CONFIRM then
            error("The Confirm(message[, callback]) must be used in a coroutine or with a callback", 3)
        elseif qtype == POPUP_TYPE_COLORPICKER then
            error("The PickColor([callback]) must be used in a coroutine or with a callback", 3)
        elseif qtype == POPUP_TYPE_OPACITYPICKER then
            error("The PickOpacity([callback]) must be used in a coroutine or with a callback", 3)
        end
    end

    _PopupQueue:Enqueue(qtype, message, current or false)
    Next(showPopup)

    return not func and current and yield()
end

__Static__() __Arguments__{ String, Function/nil }
function Scorpio.Alert(message, func)
    local value                 = queuePopup(POPUP_TYPE_ALERT, message, func)
    return value
end

__Static__() __Arguments__{ String, Function/nil }
function Scorpio.Input(message, func)
    local value                 = queuePopup(POPUP_TYPE_INPUT, message, func)
    return value
end

__Static__() __Arguments__{ String, Function/nil }
function Scorpio.Confirm(message, func)
    local value                 = queuePopup(POPUP_TYPE_CONFIRM, message, func)
    return value
end

__Static__() __Arguments__{ ColorType/ColorType(1, 1, 1, 1), Function/nil }
function Scorpio.PickColor(color, func)
    local value                 = queuePopup(POPUP_TYPE_COLORPICKER, color, func)
    return value
end

__Static__() __Arguments__{ ColorFloat/1, Function/nil }
function Scorpio.PickOpacity(opacity, func)
    local value                 = queuePopup(POPUP_TYPE_OPACITYPICKER, opacity, func)
    return value
end