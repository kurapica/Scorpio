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

    POPUP_TYPE_ALERT            = 1,
    POPUP_TYPE_INPUT            = 2,
    POPUP_TYPE_CONFIRM          = 3,

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
    function __ctor(self)
        self:GetChild("OkayButton"):SetText(_G.OKAY or "Okay")
    end
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
    function __ctor(self)
        self:GetChild("ConfirmButton"):SetText(_G.OKAY or "Okay")
        self:GetChild("CancelButton"):SetText(_G.CANCEL or "Cancel")
    end
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
    function __ctor(self)
        self:GetChild("ConfirmButton"):SetText(_G.OKAY or "Okay")
        self:GetChild("CancelButton"):SetText(_G.CANCEL or "Cancel")
    end
end)

-----------------------------------------------------------
--                Dialog Style - Default                 --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [AlertDialog]               = {
        Size                    = Size(320, 100),
        Resizable               = false,
        FrameStrata             = "FULLSCREEN_DIALOG",
        Location                = { Anchor("CENTER") },

        -- Childs
        Message                 = {
            Location            = { Anchor("TOP", 0, -16) },
            Width               = 290,
            DrawLayer           = "ARTWORK",
            FontObject          = GameFontHighlight,
        },
        OkayButton              = {
            Location            = { Anchor("BOTTOM", 0, 16) },
            Size                = Size(90, 20),
        }
    },
    [InputDialog]               = {
        Size                    = Size(360, 130),
        Resizable               = false,
        FrameStrata             = "FULLSCREEN_DIALOG",
        Location                = { Anchor("CENTER") },

        -- Childs
        Message                 = {
            Location            = { Anchor("TOP", 0, -16) },
            Width               = 290,
            DrawLayer           = "ARTWORK",
            FontObject          = GameFontHighlight,
        },
        InputBox                = {
            Location            = { Anchor("TOP", 0, -50) },
            Size                = Size(240, 32),
            AutoFocus           = true,
        },
        ConfirmButton           = {
            Location            = { Anchor("BOTTOMRIGHT", -4, 16, nil, "BOTTOM") },
            Size                = Size(90, 20),
        },
        CancelButton            = {
            Location            = { Anchor("BOTTOMLEFT", 4, 16, nil, "BOTTOM") },
            Size                = Size(90, 20),
        }
    },
    [ConfirmDialog]             = {
        Size                    = Size(360, 100),
        Resizable               = false,
        FrameStrata             = "FULLSCREEN_DIALOG",
        Location                = { Anchor("CENTER") },

        -- Childs
        Message                 = {
            Location            = { Anchor("TOP", 0, -16) },
            Width               = 290,
            DrawLayer           = "ARTWORK",
            FontObject          = GameFontHighlight,
        },
        ConfirmButton           = {
            Location            = { Anchor("BOTTOMRIGHT", -4, 16, nil, "BOTTOM") },
            Size                = Size(90, 20),
        },
        CancelButton            = {
            Location            = { Anchor("BOTTOMLEFT", 4, 16, nil, "BOTTOM") },
            Size                = Size(90, 20),
        }
    }
})

-----------------------------------------------------------
--                       Popup API                       --
-----------------------------------------------------------
local _CurrentPopup

function showPopup()
    if _CurrentPopup then return end

    local qtype, message, thread = _PopupQueue:Dequeue(3)
    if not qtype then return end

    if qtype == POPUP_TYPE_ALERT then
        _CurrentPopup           = AlertDialog("Scorpio_AlertDialog")
        _CurrentPopup.OnOkay    = function(self)
            self:Hide()
            Next(showPopup) _CurrentPopup = nil
            return resume(thread)
        end
    elseif qtype == POPUP_TYPE_INPUT then
        _CurrentPopup           = InputDialog("Scorpio_InputDialog")
        _CurrentPopup:GetChild("InputBox"):SetText("")
        _CurrentPopup.OnConfirm = function(self)
            local text          = self:GetChild("InputBox"):GetText() or ""
            self:Hide()
            Next(showPopup) _CurrentPopup = nil
            return resume(thread, text)
        end

        _CurrentPopup.OnCancel  = function(self)
            self:Hide()
            Next(showPopup) _CurrentPopup = nil
            return resume(thread)
        end
    elseif qtype == POPUP_TYPE_CONFIRM then
        _CurrentPopup           = ConfirmDialog("Scorpio_ConfirmDialog")
        _CurrentPopup.OnConfirm = function(self)
            self:Hide()
            Next(showPopup) _CurrentPopup = nil
            return resume(thread, true)
        end

        _CurrentPopup.OnCancel  = function(self)
            self:Hide()
            Next(showPopup) _CurrentPopup = nil
            return resume(thread, false)
        end
    end

    _CurrentPopup:GetChild("Message"):SetText(message)
    _CurrentPopup:Show()
end

function queuePopup(qtype, message)
    local current               = running()

    if not current then
        if qtype == POPUP_TYPE_ALERT then
            error("The Alert(message) must be used in a coroutine", 3)
        elseif qtype == POPUP_TYPE_INPUT then
            error("The Input(message) must be used in a coroutine", 3)
        elseif qtype == POPUP_TYPE_CONFIRM then
            error("The Confirm(message) must be used in a coroutine", 3)
        end
    end

    if type(message) ~= "string" then
        if qtype == POPUP_TYPE_ALERT then
            error("The Alert(message) - the message must be string", 3)
        elseif qtype == POPUP_TYPE_INPUT then
            error("The Input(message) - the message must be string", 3)
        elseif qtype == POPUP_TYPE_CONFIRM then
            error("The Confirm(message) - the message must be string", 3)
        end
    end

    _PopupQueue:Enqueue(qtype, message, current)
    showPopup()

    return yield()
end

function Widget.Alert(message)
    local value                 = queuePopup(POPUP_TYPE_ALERT, message)
    return value
end

function Widget.Input(message)
    local value                 = queuePopup(POPUP_TYPE_INPUT, message)
    return value
end

function Widget.Confirm(message)
    local value                 = queuePopup(POPUP_TYPE_CONFIRM, message)
    return value
end