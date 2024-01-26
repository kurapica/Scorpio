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
    OpenColorPicker             = _G.OpenColorPicker or function(info) return ColorPickerFrame:SetupColorPickerAndShow(info) end,

    POPUP_TYPE_ALERT            = 1,
    POPUP_TYPE_INPUT            = 2,
    POPUP_TYPE_CONFIRM          = 3,
    POPUP_TYPE_COLORPICKER      = 4,
    POPUP_TYPE_OPACITYPICKER    = 5,
    POPUP_TYPE_RANGEPICKER      = 6,
    POPUP_TYPE_MACROCONDITION   = 7,

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

__Sealed__() class "MacroConditionDialog" (function(_ENV)
    inherit "Dialog"
    import "System.Text"

    __Bubbling__{ ConfirmButton = "OnClick", InputBox = "OnEnterPressed" }
    event "OnConfirm"

    __Bubbling__{ CancelButton  = "OnClick", InputBox = "OnEscapePressed", CloseButton = "OnClick" }
    event "OnCancel"

    local L                     = Scorpio("Scorpio")._Locale

    local targetData            = { "target", "pet", "vehicle", "focus", "mouseover", "targettarget", "focustarget", "boss1", "arena1", "party1", "raid1" }

    local conditionData         = {
        {
            Condition           = "canexitvehicle",
            Text                = L["Player is in a vehicle and can exit it at will."],
        },
        {
            Condition           = "combat",
            Text                = L["Player is in combat."],
        },
        {
            Condition           = "dead",
            Text                = L["Conditional target exists and is dead."],
        },
        {
            Condition           = "exists",
            Text                = L["Conditional target exists."],
        },
        {
            Condition           = "flyable",
            Text                = L["The player can use a flying mount in this zone (though incorrect in Wintergrasp during a battle)."],
        },
        {
            Condition           = "flying",
            Text                = L["Mounted or in flight form AND in the air."],
        },
        {
            Condition           = "form",
            Text                = L["The player is in any form."],
        },
        {
            Condition           = "form:0",
            Text                = L["The player is not in any form."],
        },
        {
            Condition           = "form:1",
            Text                = L["The player is in form 1." .. (GetShapeshiftFormInfo(1) and GetSpellLink(select(4, GetShapeshiftFormInfo(1))) or "")],
        },
        {
            Condition           = "form:2",
            Text                = L["The player is in form 2." .. (GetShapeshiftFormInfo(2) and GetSpellLink(select(4, GetShapeshiftFormInfo(2))) or "")],
        },
        {
            Condition           = "form:3",
            Text                = L["The player is in form 3." .. (GetShapeshiftFormInfo(3) and GetSpellLink(select(4, GetShapeshiftFormInfo(3))) or "")],
        },
        {
            Condition           = "form:4",
            Text                = L["The player is in form 4." .. (GetShapeshiftFormInfo(4) and GetSpellLink(select(4, GetShapeshiftFormInfo(4))) or "")],
        },
        {
            Condition           = "group",
            Text                = L["Player is in a party."],
        },
        {
            Condition           = "group:raid",
            Text                = L["Player is in a raid."],
        },
        {
            Condition           = "harm",
            Text                = L["Conditional target exists and can be targeted by harmful spells (e.g.  [Fireball])."],
        },
        {
            Condition           = "help",
            Text                = L["Conditional target exists and can be targeted by helpful spells (e.g.  [Heal])."],
        },
        {
            Condition           = "indoors",
            Text                = L["Player is indoors."],
        },
        {
            Condition           = "mounted",
            Text                = L["Player is mounted."],
        },
        {
            Condition           = "outdoors",
            Text                = L["Player is outdoors."],
        },
        {
            Condition           = "party",
            Text                = L["Conditional target exists and is in your party."],
        },
        {
            Condition           = "pet",
            Text                = L["The player has a pet."],
        },
        {
            Condition           = "petbattle",
            Text                = L["Currently participating in a pet battle."],
        },
        {
            Condition           = "raid",
            Text                = L["Conditional target exists and is in your raid/party."],
        },
        {
            Condition           = "resting",
            Text                = L["Player is currently resting."],
        },
        {
            Condition           = "spec:1",
            Text                = L["Player's active the first specialization group (spec, talents and glyphs)."],
        },
        {
            Condition           = "spec:2",
            Text                = L["Player's active the second specialization group (spec, talents and glyphs)."],
        },
        {
            Condition           = "stealth",
            Text                = L["Player is stealthed."],
        },
        {
            Condition           = "swimming",
            Text                = L["Player is swimming."],
        },
        {
            Condition           = "vehicleui",
            Text                = L["Player has vehicle UI."],
        },
        {
            Condition           = "extrabar",
            Text                = L["Player currently has an extra action bar/button."],
        },
        {
            Condition           = "overridebar",
            Text                = L["Player's main action bar is currently replaced by the override action bar."],
        },
        {
            Condition           = "possessbar",
            Text                = L["Player's main action bar is currently replaced by the possess action bar."],
        },
        {
            Condition           = "shapeshift",
            Text                = L["Player's main action bar is currently replaced by a temporary shapeshift action bar."],
        },
        {
            Condition           = "mod:shift",
            Text                = L["Player's holding the shift key"],
        },
        {
            Condition           = "mod:ctrl",
            Text                = L["Player's holding the ctrl key"],
        },
        {
            Condition           = "mod:alt",
            Text                = L["Player's holding the alt key"],
        },
        {
            Condition           = "cursor",
            Text                = L["Player's mouse cursor is currently holding an item/ability/macro/etc"],
        },
    }

    TEMPLATE_CHOOSER            = TemplateString[[ [@condition] ]]

    TEMPLATE_VIEWER             = TemplateString[[
        <html>
            <body>
                <p><cyan>@L["The conditional target :"]</cyan></p>
                <p>
                @for _, tar in ipairs(targetData) do
                    <a href="@@@tar">[@tar]</a>
                @end
                </p>
                <br/>
                <p><cyan>@L["The macro conditions :"]</cyan></p>
                @for _, cond in ipairs(conditionData) do
                    <p>
                        <a href="no@cond.Condition">[no]</a>
                        <a href="@cond.Condition">[@cond.Condition]</a>
                        - @cond.Text
                    </p>
                @end
            </body>
        </html>
    ]]

    local function OnShow(self)
        self.Selection          = { "@player" }
        self:GetChild("InputBox"):SetText("")
    end

    local function OnViewerHyperlinkClick(self, data)
        self                    = self:GetParent()
        local selection         = self.Selection

        if data:match("^@") then
            -- conditional target
            if data == selection[1] then
                selection[1]    = "@player"
            else
                selection[1]    = data
            end
        else
            local negData
            local matched       = false
            if data:match("^no") then
                negData         = data:sub(3, -1)
            else
                negData         = "no" .. data
            end

            if data:match("form") then
                for i, v in ipairs(selection) do
                    if v:match("form") then
                        matched = true

                        if(v == data) then
                            tremove(selection, i)
                        elseif data == "form" or data == "noform" then
                            selection[i] = data
                        else
                            local forms
                            if v == "noform" then
                                forms = {[0] = true, false, false, false, false}
                            elseif v == "form" then
                                forms = {[0] = false, true, true, true, true}
                            elseif v:match("^no") then
                                forms = {[0] = true, true, true, true, true}
                                v:gsub("%d+", function(num) forms[tonumber(num)] = false end)
                            else
                                forms = {[0] = false, false, false, false, false}
                                v:gsub("%d+", function(num) forms[tonumber(num)] = true end)
                            end
                            if data:match("^no") then
                                data:gsub("%d+", function(num) forms[tonumber(num)] = false end)
                            else
                                data:gsub("%d+", function(num) forms[tonumber(num)] = true end)
                            end
                            local cnt = 0
                            for j = 1, #forms do if forms[j] then cnt = cnt + 1 end end
                            if cnt == 0 then
                                selection[i] = "noform"
                            elseif cnt == #forms then
                                selection[i] = "form"
                            elseif cnt <= 2 then
                                data = ""
                                for j = 0, #forms do
                                    if forms[j] then
                                        if data ~= "" then
                                            data = data .. "/" .. j
                                        else
                                            data = data .. j
                                        end
                                    end
                                end
                                selection[i] = "form:" .. data
                            else
                                data = ""
                                for j = 0, #forms do
                                    if not forms[j] then
                                        if data ~= "" then
                                            data = data .. "/" .. j
                                        else
                                            data = data .. j
                                        end
                                    end
                                end
                                selection[i] = "noform:" .. data
                            end
                        end
                        break
                    end
                end
            else
                for i, v in ipairs(selection) do
                    if v == data then
                        matched = true
                        tremove(selection, i)
                        break
                    elseif v == negData then
                        matched = true
                        selection[i] = data
                    end
                end
            end
            if not matched then
                tinsert(selection, data)
            end
        end

        local text = ""
        for i, v in ipairs(selection) do
            if i == 1 then
                if v ~= "@player" then
                    text        = v
                end
            else
                text            = text .. (text ~= "" and ", " or "") .. v
            end
        end

        self:GetChild("InputBox"):SetText("[" .. text .. "]")
    end

    __Template__{
        Message                 = FontString,
        InputBox                = InputBox,
        Viewer                  = HtmlViewer,
        ConfirmButton           = UIPanelButton,
        CancelButton            = UIPanelButton,
    }
    function __ctor(self)
        self:Hide()

        local viewer            = self:GetChild("Viewer")
        viewer.OnHyperlinkClick = viewer.OnHyperlinkClick + OnViewerHyperlinkClick

        self.OnShow             = self.OnShow + OnShow

        viewer:SetText(TEMPLATE_VIEWER{
            L                   = L,
            targetData          = targetData,
            conditionData       = conditionData
        })
    end
end)

-----------------------------------------------------------
--                Dialog Style - Default                 --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [AlertDialog]               = {
        size                    = Size(320, 120),
        resizable               = false,
        frameStrata             = "FULLSCREEN_DIALOG",
        location                = { Anchor("TOP", 0, -120) },

        -- Childs
        Message                 = {
            location            = { Anchor("TOP", 0, -28) },
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
        location                = { Anchor("TOP", 0, -120) },

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
        location                = { Anchor("TOP", 0, -120) },

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
        location                = { Anchor("TOP", 0, -120) },

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
    },
    [MacroConditionDialog]      = {
        size                    = Size(560, 430),
        resizable               = false,
        frameStrata             = "FULLSCREEN_DIALOG",
        location                = { Anchor("TOP", 0, -120) },

        -- Childs
        Message                 = {
            location            = { Anchor("TOP", 0, -16) },
            width               = 490,
            drawLayer           = "ARTWORK",
            fontObject          = GameFontHighlight,
        },
        InputBox                = {
            location            = { Anchor("TOP", 0, -40) },
            size                = Size(500, 32),
            autoFocus           = true,
        },
        Viewer                = {
            location            = { Anchor("TOP", 0, -4, "InputBox", "BOTTOM") },
            size                = Size(500, 300),
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
        local color             = ColorType(message)
        local useColorAlpha     = ColorPickerFrame.GetColorAlpha and true or false

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
                opacity         = useColorAlpha and color.a or (1 - color.a),
                swatchFunc      = function()
                    Next(function()
                        if firstopen or ColorPickerFrame:IsShown() then firstopen = false return end
                        Next(showPopup) _CurrentPopup = nil

                        local r,g,b = ColorPickerFrame:GetColorRGB()
                        local a     = useColorAlpha and ColorPickerFrame:GetColorAlpha() or (1 - OpacitySliderFrame:GetValue())

                        return resume(thread, Color(r, g, b, a))
                    end)
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
                    local a     = useColorAlpha and ColorPickerFrame:GetColorAlpha() or (1 - OpacitySliderFrame:GetValue())

                    return thread(Color(r, g, b, a))
                end,
                opacityFunc     = function()
                    local r,g,b = ColorPickerFrame:GetColorRGB()
                    local a     = useColorAlpha and ColorPickerFrame:GetColorAlpha() or (1 - OpacitySliderFrame:GetValue())

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
    elseif qtype == POPUP_TYPE_MACROCONDITION then
        _CurrentPopup           = MacroConditionDialog("Scorpio_MacroConditionDialog")
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
        elseif qtype == POPUP_TYPE_MACROCONDITION then
            error("Usage: PickMacroCondition(message[, callback]) - the api must be used in a coroutine or with a callback")
        end
    end

    _PopupQueue:Enqueue(qtype, message, current)
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

__Static__() __Arguments__{ ColorType/Color(1, 1, 1, 1), Function/nil }
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

__Static__() __Arguments__{ String, Function/nil }
function Scorpio.PickMacroCondition(message, func)
    local value                 = queuePopup(POPUP_TYPE_MACROCONDITION, message, func)
    return value
end