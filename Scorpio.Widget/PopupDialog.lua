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
__Sealed__() class "DialogButton" { Button }

__Sealed__() class "AlertDialog" (function(_ENV)
    inherit "Frame"

    __Bubbling__{ OkayButton    = "OnClick" }
    event "OnOkay"

    __Template__{
        Message                 = FontString,
        OkayButton              = DialogButton,
    }
    function __ctor(self)
        self:GetChild("OkayButton"):SetText(_G.OKAY or "Okay")
    end
end)

__Sealed__() class "InputDialog" (function(_ENV)
    inherit "Frame"

    __Bubbling__{ ConfirmButton = "OnClick" }
    event "OnConfirm"

    __Bubbling__{ CancelButton  = "OnClick" }
    event "OnCancel"

    __Template__{
        Message                 = FontString,
        InputBox                = EditBox,
        ConfirmButton           = DialogButton,
        CancelButton            = DialogButton,
    }
    function __ctor(self)
        self:GetChild("ConfirmButton"):SetText(_G.OKAY or "Okay")
        self:GetChild("CancelButton"):SetText(_G.CANCEL or "Cancel")
    end
end)

__Sealed__() class "ConfirmDialog" (function(_ENV)
    inherit "Frame"

    __Bubbling__{ ConfirmButton = "OnClick" }
    event "OnConfirm"

    __Bubbling__{ CancelButton  = "OnClick" }
    event "OnCancel"

    __Template__{
        Message                 = FontString,
        ConfirmButton           = DialogButton,
        CancelButton            = DialogButton,
    }
    function __ctor(self)
        self:GetChild("ConfirmButton"):SetText(_G.OKAY or "Okay")
        self:GetChild("CancelButton"):SetText(_G.CANCEL or "Cancel")
    end
end)

-----------------------------------------------------------
--                Dialog Style - Default                 --
-----------------------------------------------------------
Style.UpdateSkin("Default", {
    [DialogButton]              = {
        NormalFontObject        = GameFontNormal,
        DisabledFontObject      = GameFontDisable,
        HighlightFontObject     = GameFontHighlight,

        NormalTexture           = {
            file                = [[Interface\Buttons\UI-Panel-Button-Up]],
            texcoord            = RectType(0, 0.625, 0, 0.6875),
        },
        PushedTexture           = {
            file                = [[Interface\Buttons\UI-Panel-Button-Down]],
            texcoord            = RectType(0, 0.625, 0, 0.6875),
        },
        DisabledTexture         = {
            file                = [[Interface\Buttons\UI-Panel-Button-Disabled]],
            texcoord            = RectType(0, 0.625, 0, 0.6875),
        },
        HighlightTexture        = {
            file                = [[Interface\Buttons\UI-Panel-Button-Highlight]],
            texcoord            = RectType(0, 0.625, 0, 0.6875),
        }
    },
    [AlertDialog]               = {
        Size                    = Size(320, 72),
        FrameStrata             = "FULLSCREEN_DIALOG",
        Toplevel                = true,
        Location                = { Anchor("CENTER") },
        Backdrop                = {
            bgFile              = [[Interface\DialogFrame\UI-DialogBox-Background]],
            edgeFile            = [[Interface\DialogFrame\UI-DialogBox-Border]],
            tile                = true, tileSize = 32, edgeSize = 32,
            insets              = { left = 11, right = 12, top = 12, bottom = 11 }
        },
        BackdropBorderColor     = ColorType(0, 0, 0),

        -- Childs
        Message                 = {
            Location            = { Anchor("TOP", 0, -16) },
            Width               = 290,
            DrawLayer           = "ARTWORK",
            FontObject          = GameFontHighlight,
        },
        OkayButton              = {
            Location            = { Anchor("BOTTOM", 0, 16) },
            Size                = Size(128, 20),
        }
    },
    [InputDialog]               = {

    },
    [ConfirmDialog]             = {
        Size                    = Size(320, 72),
        FrameStrata             = "FULLSCREEN_DIALOG",
        Toplevel                = true,
        Location                = { Anchor("CENTER") },
        Backdrop                = {
            bgFile              = [[Interface\DialogFrame\UI-DialogBox-Background]],
            edgeFile            = [[Interface\DialogFrame\UI-DialogBox-Border]],
            tile                = true, tileSize = 32, edgeSize = 32,
            insets              = { left = 11, right = 12, top = 12, bottom = 11 }
        },
        BackdropBorderColor     = ColorType(0, 0, 0),

        -- Childs
        Message                 = {
            Location            = { Anchor("TOP", 0, -16) },
            Width               = 290,
            DrawLayer           = "ARTWORK",
            FontObject          = GameFontHighlight,
        },
        ConfirmButton           = {
            Location            = { Anchor("BOTTOMRIGHT", -4, 16, nil, "BOTTOM") },
            Size                = Size(128, 20),
        },
        CancelButton            = {
            Location            = { Anchor("BOTTOMLEFT", 4, 16, nil, "BOTTOM") },
            Size                = Size(128, 20),
        }
    }
})

Style.ActiveSkin("Default", DialogButton)
Style.ActiveSkin("Default", AlertDialog)
Style.ActiveSkin("Default", InputDialog)
Style.ActiveSkin("Default", ConfirmDialog)

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