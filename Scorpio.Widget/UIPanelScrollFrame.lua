--========================================================--
--             Scorpio UIPanelScrollFrame Widget          --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/02/05                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Widget.UIPanelScrollFrame"   "1.0.0"
--========================================================--

-----------------------------------------------------------
--               UIPanelScrollFrame Widget               --
-----------------------------------------------------------
__Sealed__() class "UIPanelScrollBar" (function(_ENV)
    inherit "Slider"

    local abs                   = math.abs

    local function refreshState(self)
        local value             = self:GetValue() or 0
        local min, max          = self:GetMinMaxValues()
        min                     = min or 0
        max                     = max or 0

        if abs(max - min) < 0.005 then
            self:GetChild("ScrollUpButton"):SetEnabled(false)
            self:GetChild("ScrollDownButton"):SetEnabled(false)

            if self.AutoHide then self:Hide() end
        else
            self:GetChild("ScrollUpButton"):SetEnabled(true)

            -- The 0.005 is to account for precision errors
            if ( max - value > 0.005 ) then
                self:GetChild("ScrollDownButton"):SetEnabled(true)
            else
                self:GetChild("ScrollDownButton"):SetEnabled(false)
            end

            self:Show()
        end
    end

    local function scrollUpButton_OnClick(self)
        local parent            = self:GetParent()
        local scrollStep        = self:GetParent().ScrollStep or (parent:GetHeight() / 2)
        parent:SetValue(parent:GetValue() - scrollStep)
        PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
    end

    local function scrollDownButton_OnClick(self)
        local parent            = self:GetParent()
        local scrollStep        = self:GetParent().ScrollStep or (parent:GetHeight() / 2)
        parent:SetValue(parent:GetValue() + scrollStep)
        PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
    end

    local function scrollBar_OnValueChanged(self, value)
        refreshState(self)
        return self:GetParent():SetVerticalScroll(value)
    end

    --- The scroll Step
    property "ScrollStep"       { type = Number }

    --- Whether the scroll bar should be hidden if no need to be used
    property "AutoHide"         { type = Boolean, handler = refreshState }

    --- @Override
    function SetMinMaxValues(self, min, max)
        Slider.SetMinMaxValues(self, min, max)
        return refreshState(self)
    end

    __Template__{
        ScrollUpButton          = Button,
        ScrollDownButton        = Button,
    }
    function __ctor(self)
        local scrollUpButton    = self:GetChild("ScrollUpButton")
        local scrollDownButton  = self:GetChild("ScrollDownButton")

        scrollUpButton.OnClick  = scrollUpButton.OnClick + scrollUpButton_OnClick
        scrollDownButton.OnClick= scrollDownButton.OnClick + scrollDownButton_OnClick

        self.OnValueChanged     = self.OnValueChanged + scrollBar_OnValueChanged
    end
end)

__Sealed__() class "UIPanelScrollFrame" (function(_ENV)
    inherit "ScrollFrame"

    local function OnScrollRangeChanged(self, xrange, yrange)
        yrange                  = math.floor(yrange or self:GetVerticalScrollRange())
        local scrollbar         = self:GetChild("ScrollBar")

        scrollbar:SetMinMaxValues(0, yrange)
        scrollbar:SetValue(math.min(scrollbar:GetValue(), yrange))
    end

    local function OnVerticalScroll(self, offset)
        self:GetChild("ScrollBar"):SetValue(offset)
    end

    local function OnMouseWheel(self, value, scrollBar)
        local scrollBar         = self:GetChild("ScrollBar")
        local scrollStep        = scrollBar.ScrollStep or scrollBar:GetHeight() / 2
        if ( value > 0 ) then
            scrollBar:SetValue(scrollBar:GetValue() - scrollStep)
        else
            scrollBar:SetValue(scrollBar:GetValue() + scrollStep)
        end
    end

    --- Whether auto hide the scroll bar if no use
    property "ScrollBarHideable"{ type = Boolean, handler = function(self, val) self:GetChild("ScrollBar").AutoHide = val end }

    --- Whether don't show the thumb texture on the scroll bar
    property "NoScrollThumb"    { type = Boolean, handler = function(self, val) Style[self:GetChild("ScrollBar")].ThumbTexture = val and NIL or nil end }

    __Template__{
        ScrollBar               = UIPanelScrollBar
    }
    function __ctor(self)
        self.OnScrollRangeChanged = self.OnScrollRangeChanged + OnScrollRangeChanged
        self.OnVerticalScroll   = self.OnVerticalScroll + OnVerticalScroll
        self.OnMouseWheel       = self.OnMouseWheel + OnMouseWheel

        local scrollbar         = self:GetChild("ScrollBar")
        scrollbar:SetMinMaxValues(0, 0)
        scrollbar:SetValue(0)
    end
end)

__Sealed__() class "InputScrollFrame" (function(_ENV)
    inherit "UIPanelScrollFrame"

    local Next                  = Scorpio.Next

    local function OnMouseDown(self)
        self:GetChild("EditBox"):SetFocus()
    end

    local function handleCursorChange(self)
        local height, range, scroll, size, cursorOffset
        local scrollFrame       = self:GetParent()

        height                  = scrollFrame:GetHeight()
        range                   = scrollFrame:GetVerticalScrollRange()
        scroll                  = scrollFrame:GetVerticalScroll()
        size                    = height + range
        cursorOffset            = -self.cursorOffset or 0

        if ( math.floor(height) <= 0 or math.floor(range) <= 0 ) then
            --Frame has no area, nothing to calculate.
            return
        end

        while ( cursorOffset < scroll ) do
            scroll              = (scroll - (height / 2))
            if ( scroll < 0 ) then
                scroll          = 0
            end
            scrollFrame:SetVerticalScroll(scroll)
        end

        while ( (cursorOffset + self.cursorHeight) > (scroll + height) and scroll < range ) do
            scroll              = (scroll + (height / 2))
            if ( scroll > range ) then
                scroll          = range
            end
            scrollFrame:SetVerticalScroll(scroll)
        end
    end

    local function OnCursorChanged(self, x, y, w, h)
        self.cursorOffset       = y
        self.cursorHeight       = h
        Next(handleCursorChange, self)
    end

    local function OnTextChanged(self)
        local scrollFrame       = self:GetParent()

        handleCursorChange(self)

        if self:GetText() ~= "" then
            scrollFrame:GetChild("InstructionLabel"):Hide()
        else
            scrollFrame:GetChild("InstructionLabel"):Show()
        end

        local charCount         = scrollFrame:GetChild("CharCount")

        if self:GetMaxLetters() then
            charCount:SetText(self:GetNumLetters() .. "/" .. self:GetMaxLetters())
        else
            charCount:SetText("")
        end

        charCount:ClearAllPoints()

        if scrollFrame:GetChild("ScrollBar"):IsShown() then
            charCount:SetPoint("BOTTOMRIGHT", -17, 0)
        else
            charCount:SetPoint("BOTTOMRIGHT", 0, 0)
        end
    end

    local function OnEscapePressed(self)
        self:ClearFocus()
    end

    --- The max letters of the input scroll frame
    property "MaxLetters" {
        type                    = Number,
        set                     = function(self, value)
            self:GetChild("EditBox"):SetMaxLetters(value)
        end,
        get                     = function(self)
            return self:GetChild("EditBox"):GetMaxLetters()
        end,
    }

    --- The instructions of the input scroll frame
    property "Instructions"     {
        type                    = String,
        set                     = function(self, value)
            self:GetChild("InstructionLabel"):SetText(value)
        end,
        get                     = function(self)
            return self:GetChild("InstructionLabel"):GetText()
        end,
    }

    --- Whether show the char count
    property "HideCharCount"    {
        type                    = Boolean,
        set                     = function(self, value)
            self:GetChild("CharCount"):SetShown(not value)
        end,
        get                     = function(self)
            return not self:GetChild("CharCount"):IsShown()
        end,
    }

    --- Sets the text to the input scroll frame
    function SetText(self, text)
        self:GetChild("EditBox"):SetText(text)
    end

    --- Gets the text from the input scroll frame
    function GetText(self)
        return self:GetChild("EditBox"):GetText()
    end

    __Template__{
        CharCount               = FontString,
        EditBox                 = EditBox,
        InstructionLabel        = FontString,
    }
    function __ctor(self)
        local editBox           = self:GetChild("EditBox")
        editBox:SetHeight(32)
        self:SetScrollChild(editBox)

        self.OnMouseDown        = self.OnMouseDown          + OnMouseDown

        editBox.OnTextChanged   = editBox.OnTextChanged     + OnTextChanged
        editBox.OnCursorChanged = editBox.OnCursorChanged   + OnCursorChanged
        editBox.OnEscapePressed = editBox.OnEscapePressed   + OnEscapePressed
    end
end)

__Sealed__() class "FauxScrollFrame" (function(_ENV)
    inherit "UIPanelScrollFrame"

    __Template__{
        ScrollChildFrame        = Frame
    }
    function __ctor(self)
    end
end)

__Sealed__() class "ListScrollFrame" (function(_ENV)
    inherit "FauxScrollFrame"

    local function OnScrollRangeChanged(self, xrange, yrange)
        -- Hide/show scrollframe borders
        local top               = self:GetChild("ScrollBarTop")
        local bottom            = self:GetChild("ScrollBarBottom")
        local middle            = self:GetChild("ScrollBarMiddle")

        if ( top and bottom and self.ScrollBarHideable ) then
            if ( self:GetVerticalScrollRange() == 0 ) then
                top:Hide()
                bottom:Hide()
            else
                top:Show()
                bottom:Show()
            end
        end

        if ( middle and self.ScrollBarHideable ) then
            if ( self:GetVerticalScrollRange() == 0 ) then
                middle:Hide()
            else
                middle:Show()
            end
        end
    end

    __Template__{
        ScrollBarTop            = Texture,
        ScrollBarBottom         = Texture,
        ScrollBarMiddle         = Texture,
    }
    function __ctor(self)
        self.OnScrollRangeChanged = self.OnScrollRangeChanged + OnScrollRangeChanged
    end
end)

-----------------------------------------------------------
--          UIPanelScrollFrame Style - Default           --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [UIPanelScrollBar]          = {
        width                   = 16,

        ThumbTexture            = {
            file                = [[Interface\Buttons\UI-ScrollBar-Knob]],
            texCoords           = RectType(0.20, 0.80, 0.125, 0.875),
            size                = Size(18, 24),
        },

        -- Childs
        ScrollUpButton          = {
            location            = { Anchor("BOTTOM", 0, 0, nil, "TOP") },
            size                = Size(18, 16),

            NormalTexture       = {
                file            = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Up]],
                texCoords       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints    = true,
            },
            PushedTexture       = {
                file            = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Down]],
                texCoords       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints    = true,
            },
            DisabledTexture     = {
                file            = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Disabled]],
                texCoords       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints    = true,
            },
            HighlightTexture    = {
                file            = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Highlight]],
                texCoords       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints    = true,
                alphamode       = "ADD",
            }
        },
        ScrollDownButton        = {
            location            = { Anchor("TOP", 0, 0, nil, "BOTTOM") },
            size                = Size(18, 16),

            NormalTexture       = {
                file            = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Up]],
                texCoords       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints    = true,
            },
            PushedTexture       = {
                file            = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Down]],
                texCoords       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints    = true,
            },
            DisabledTexture     = {
                file            = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Disabled]],
                texCoords       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints    = true,
            },
            HighlightTexture    = {
                file            = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Highlight]],
                texCoords       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints    = true,
                alphamode       = "ADD",
            }
        },
    },
    [UIPanelScrollFrame]        = {
        ScrollBar               = {
            location            = {
                Anchor("TOPLEFT", 6, -16, nil, "TOPRIGHT"),
                Anchor("BOTTOMLEFT", 6, 16, nil, "BOTTOMRIGHT")
            },
        },
    },
    [InputScrollFrame]          = {
        scrollBarHideable       = true,

        ScrollBar               = {
            location            = {
                Anchor("TOPLEFT", -13, -11, nil, "TOPRIGHT"),
                Anchor("BOTTOMLEFT", -13, 9, nil, "BOTTOMRIGHT")
            },

            ScrollUpButton      = {
                location        = { Anchor("BOTTOM", 0, -4, nil, "TOP") },
            },
            ScrollDownButton    = {
                location        = { Anchor("BOTTOM", 0, 4, nil, "TOP") },
            },
        },
        TopLeftBGTexture        = {
            file                = [[Interface\Common\Common-Input-Border-TL]],
            size                = Size(8, 8),
            location            = { Anchor("TOPLEFT", -5, 5) },
        },
        TopRightBGTexture       = {
            file                = [[Interface\Common\Common-Input-Border-TR]],
            size                = Size(8, 8),
            location            = { Anchor("TOPRIGHT", 5, 5) },
        },
        TopBGTexture            = {
            file                = [[Interface\Common\Common-Input-Border-T]],
            size                = Size(8, 8),
            location            = {
                Anchor("TOPLEFT", 0, 0, "TopLeftBGTexture", "TOPRIGHT"),
                Anchor("BOTTOMRIGHT", 0, 0, "TopRightBGTexture", "BOTTOMLEFT")
            },
        },
        BottomLeftBGTexture     = {
            file                = [[Interface\Common\Common-Input-Border-BL]],
            size                = Size(8, 8),
            location            = { Anchor("BOTTOMLEFT", -5, -5) },
        },
        BottomRightBGTexture    = {
            file                = [[Interface\Common\Common-Input-Border-BR]],
            size                = Size(8, 8),
            location            = { Anchor("BOTTOMRIGHT", 5, -5) },
        },
        BottomBGTexture         = {
            file                = [[Interface\Common\Common-Input-Border-B]],
            size                = Size(8, 8),
            location            = {
                Anchor("TOPLEFT", 0, 0, "BottomLeftBGTexture", "TOPRIGHT"),
                Anchor("BOTTOMRIGHT", 0, 0, "BottomRightBGTexture", "BOTTOMLEFT")
            },
        },
        LeftBGTexture           = {
            file                = [[Interface\Common\Common-Input-Border-L]],
            size                = Size(8, 8),
            location            = {
                Anchor("TOPLEFT", 0, 0, "TopLeftBGTexture", "BOTTOMLEFT"),
                Anchor("BOTTOMRIGHT", 0, 0, "BottomLeftBGTexture", "TOPRIGHT")
            },
        },
        RightBGTexture          = {
            file                = [[Interface\Common\Common-Input-Border-R]],
            size                = Size(8, 8),
            location            = {
                Anchor("TOPLEFT", 0, 0, "TopRightBGTexture", "BOTTOMLEFT"),
                Anchor("BOTTOMRIGHT", 0, 0, "BottomRightBGTexture", "TOPRIGHT")
            },
        },
        MiddleBGTexture         = {
            file                = [[Interface\Common\Common-Input-Border-M]],
            size                = Size(8, 8),
            location            = {
                Anchor("TOPLEFT", 0, 0, "LeftBGTexture", "TOPRIGHT"),
                Anchor("BOTTOMRIGHT", 0, 0, "RightBGTexture", "BOTTOMLEFT")
            },
        },
        CharCount               = {
            drawLayer           = "OVERLAY",
            fontObject          = GameFontDisableLarge,
            location            = { Anchor("BOTTOMRIGHT", -6, 0) },
        },
        EditBox                 = {
            fontObject          = GameFontHighlightSmall,
            multiLine           = true,
            countInvisibleLetters = true,
            autoFocus           = false,
            location            = { Anchor("TOPLEFT"), Anchor("RIGHT", -18, 0) },
        },
        InstructionLabel        = {
            drawLayer           = "BORDER",
            fontObject          = GameFontNormalSmall,
            justifyH            = "LEFT",
            justifyV            = "TOP",
            location            = { Anchor("TOPLEFT", 0, 0, "EditBox"), Anchor("RIGHT") },
            textColor           = Color(0.35, 0.35, 0.35),
        },
    },
    [ListScrollFrame]           = {
        ScrollBarTop            = {
            atlas               = {
                atlas           = [[macropopup-scrollbar-top]],
                useAtlasSize    = true,
            },
            location            = { Anchor("TOPLEFT", -2, 5, nil, "TOPRIGHT") },
        },
        ScrollBarBottom         = {
            atlas               = {
                atlas           = [[macropopup-scrollbar-bottom]],
                useAtlasSize    = true,
            },
            location            = { Anchor("BOTTOMLEFT", -2, -2, nil, "BOTTOMRIGHT") },
        },
        ScrollBarMiddle         = {
            atlas               = {
                atlas           = [[!macropopup-scrollbar-middle]],
                useAtlasSize    = true,
            },
            vertTile            = true,
            location            = { Anchor("TOP", 0, 0, "ScrollBarTop", "BOTTOM"), Anchor("BOTTOM", 0, 0, "ScrollBarBottom", "TOP") },
        },
    },
})