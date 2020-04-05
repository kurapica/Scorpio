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
    POPUP_TYPE_RANGEPICKER      = 6,

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

__Sealed__() class "RangeDialog" (function(_ENV)
    inherit "Dialog"

    __Bubbling__{ ConfirmButton = "OnClick" }
    event "OnConfirm"

    __Bubbling__{ CancelButton  = "OnClick", CloseButton = "OnClick" }
    event "OnCancel"

    __Template__{
        Message                 = FontString,
        RangeBar                = TrackBar,
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
    },
    [RangeDialog]               = {
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
        RangeBar                = {
            location            = { Anchor("TOP", 0, -50) },
            size                = Size(240, 16),
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
    elseif qtype == POPUP_TYPE_RANGEPICKER then
        local min, max, step, v = _PopupQueue:Dequeue(4)

        _CurrentPopup           = RangeDialog("Scorpio_RangeDialog")
        _CurrentPopup:GetChild("RangeBar"):SetMinMaxValues(min, max)
        _CurrentPopup:GetChild("RangeBar"):SetValueStep(step)
        _CurrentPopup:GetChild("RangeBar"):SetValue(v)

        _CurrentPopup.OnConfirm = function(self)
            local value         = self:GetChild("RangeBar"):GetValue()
            self:Hide()
            Next(showPopup) _CurrentPopup = nil
            if isthread then
                return resume(thread, value)
            else
                return thread(value)
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

function queuePopup(qtype, message, func, min, max, step, value)
    local current               = func or running()

    if not current then
       if qtype == POPUP_TYPE_INPUT then
            error("Usage: Input(message[, callback]) - the api must be used in a coroutine or with a callback", 4)
        elseif qtype == POPUP_TYPE_CONFIRM then
            error("Usage: Confirm(message[, callback]) - the api must be used in a coroutine or with a callback", 4)
        elseif qtype == POPUP_TYPE_COLORPICKER then
            error("Usage: PickColor([callback]) - the api must be used in a coroutine or with a callback", 4)
        elseif qtype == POPUP_TYPE_OPACITYPICKER then
            error("Usage: PickOpacity([callback]) - the api must be used in a coroutine or with a callback", 4)
        elseif qtype == POPUP_TYPE_RANGEPICKER then
            error("Usage: PickRange(message, min, max, step[, value[, callback]]) - the api must be used in a coroutine or with a callback", 4)
        end
    end

    _PopupQueue:Enqueue(qtype, message, current or false)
    if qtype == POPUP_TYPE_RANGEPICKER then _PopupQueue:Enqueue(min, max, step, value or min) end
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

__Static__() __Arguments__{ String, Number, Number, Number, Number/nil, Function/nil }
function Scorpio.PickRange(message, min, max, step, value, func)
    if min >= max then error("Usage: PickRange(message, min, max, step[, value[, callback]]) - the min value must be smaller than the max value", 3) end
    local value                 = queuePopup(POPUP_TYPE_RANGEPICKER, message, func, min, max, step, value)
    return value
end