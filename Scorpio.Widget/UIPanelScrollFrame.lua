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

    local function refreshState(self)
        local value             = self:GetValue() or 0
        local min, max          = self:GetMinMaxValues()
        min                     = min or 0
        max                     = max or 0

        if math.abs(max - min) < 0.005 then
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

    __Template__{
        TopLeftTex              = Texture,
        TopRightTex             = Texture,
        TopTex                  = Texture,
        BottomLeftTex           = Texture,
        BottomRightTex          = Texture,
        BottomTex               = Texture,
        LeftTex                 = Texture,
        RightTex                = Texture,
        MiddleTex               = Texture,
        CharCount               = FontString,
        EditBox                 = EditBox,
        Instructions            = FontString,
    }
    function __ctor(self)
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
        TopLeftTex              = {
            file                = [[Interface\Common\Common-Input-Border-TL]],
            size                = Size(8, 8),
            location            = { Anchor("TOPLEFT", -5, 5) },
        },
        TopRightTex             = {
            file                = [[Interface\Common\Common-Input-Border-TR]],
            size                = Size(8, 8),
            location            = { Anchor("TOPRIGHT", 5, 5) },
        },
        TopTex                  = {
            file                = [[Interface\Common\Common-Input-Border-T]],
            size                = Size(8, 8),
            location            = {
                Anchor("TOPLEFT", 0, 0, "TopLeftTex", "TOPRIGHT"),
                Anchor("BOTTOMRIGHT", 0, 0, "TopRightTex", "BOTTOMLEFT")
            },
        },
        BottomLeftTex           = {
            file                = [[Interface\Common\Common-Input-Border-BL]],
            size                = Size(8, 8),
            location            = { Anchor("BOTTOMLEFT", -5, -5) },
        },
        BottomRightTex          = {
            file                = [[Interface\Common\Common-Input-Border-BR]],
            size                = Size(8, 8),
            location            = { Anchor("BOTTOMLEFT", 5, -5) },
        },
        BottomTex               = {
            file                = [[Interface\Common\Common-Input-Border-B]],
            size                = Size(8, 8),
            location            = {
                Anchor("TOPLEFT", 0, 0, "BottomLeftTex", "TOPRIGHT"),
                Anchor("BOTTOMRIGHT", 0, 0, "BottomRightTex", "BOTTOMLEFT")
            },
        },
        LeftTex           = {
            file                = [[Interface\Common\Common-Input-Border-L]],
            size                = Size(8, 8),
            location            = {
                Anchor("TOPLEFT", 0, 0, "TopLeftTex", "BOTTOMLEFT"),
                Anchor("BOTTOMRIGHT", 0, 0, "BottomLeftTex", "TOPRIGHT")
            },
        },
        RightTex          = {
            file                = [[Interface\Common\Common-Input-Border-R]],
            size                = Size(8, 8),
            location            = {
                Anchor("TOPLEFT", 0, 0, "TopRightTex", "BOTTOMLEFT"),
                Anchor("BOTTOMRIGHT", 0, 0, "BottomRightTex", "TOPRIGHT")
            },
        },
        MiddleTex               = {
            file                = [[Interface\Common\Common-Input-Border-M]],
            size                = Size(8, 8),
            location            = {
                Anchor("TOPLEFT", 0, 0, "LeftTex", "TOPRIGHT"),
                Anchor("BOTTOMRIGHT", 0, 0, "RightTex", "BOTTOMLEFT")
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
            size                = Size(1, 1),
            location            = { Anchor("TOPLEFT") },
        },
        Instructions            = {
            drawLayer           = "BORDER",
            fontObject          = GameFontNormalSmall,
            location            = { Anchor("TOPLEFT") },
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