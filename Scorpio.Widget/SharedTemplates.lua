--========================================================--
--             Scorpio Shared UI Panel Templates          --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/04/17                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Widget.SharedUIPanel"     "1.0.0"
--========================================================--

local _M                        = _M -- to be used inside the class
local IS_CLASSIC                = select(4, GetBuildInfo()) < 20000

-----------------------------------------------------------
--                   Draggable Widget                    --
-----------------------------------------------------------
__Sealed__()
class "Mover" (function(_ENV)
    inherit "Frame"

    -- Fired when stop moving
    event "OnMoved"

    local function onMouseDown(self)
        local parent            = self:GetParent()
        if parent:IsMovable() then
            self.IsMoving       = true
            parent:StartMoving()
        end
    end

    local function onMouseUp(self)
        if self.IsMoving then
            self.IsMoving       = false
            self:GetParent():StopMovingOrSizing()
            OnMoved(self)
        end
    end

    function __ctor(self)
        self.OnMouseDown        = onMouseDown
        self.OnMouseUp          = onMouseUp
    end
end)

__Sealed__()
class "Resizer" (function(_ENV)
    inherit "Button"

    -- Fired when stop resizing
    event "OnResized"

    local function onMouseDown(self)
        local parent            = self:GetParent()
        if parent:IsResizable() then
            self.IsResizing     = true
            parent:StartSizing("BOTTOMRIGHT")
        end
    end

    local function onMouseUp(self)
        if self.IsResizing then
            self.IsResizing     = false
            self:GetParent():StopMovingOrSizing()
            OnResized(self)
        end
    end

    function __ctor(self)
        self.OnMouseDown        = onMouseDown
        self.OnMouseUp          = onMouseUp

        local parent            = self:GetParent()
        if parent:IsResizable() then
            self:Show()
        else
            self:Hide()
        end

         _M:SecureHook(parent, "SetResizable", function(par, flag)
            if flag then
                self:Show()
            else
                self:Hide()
            end
        end)
    end
end)

-----------------------------------------------------------
--                     Label Widget                      --
-----------------------------------------------------------
__Sealed__() __ChildProperty__(Frame, "Label")
class "UIPanelLabel" { FontString }

-----------------------------------------------------------
--                 UIPanelButton Widget                  --
-----------------------------------------------------------
__Sealed__()
class "UIPanelButton" { Button }

__Sealed__()
class "UIPanelCloseButton" { Button, function(self) self.OnClick = function(self) self:GetParent():Hide() end end }

-----------------------------------------------------------
--                    InputBox Widget                    --
-----------------------------------------------------------
__Sealed__() class "InputBox" (function(_ENV)
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

    function __ctor(self)
        self.OnEscapePressed    = self.OnEscapePressed + OnEscapePressed
        self.OnEditFocusGained  = self.OnEditFocusGained + OnEditFocusGained
        self.OnEditFocusLost    = self.OnEditFocusLost + OnEditFocusLost
    end
end)

-----------------------------------------------------------
--                   Track Bar Widget                    --
-----------------------------------------------------------
__Sealed__() class "TrackBar" (function(_ENV)
    inherit "Slider"

    local floor                 = math.floor
    local getValue              = Slider.GetValue
    local setValue              = Slider.SetValue
    local setValueStep          = Slider.SetValueStep
    local getValueStep          = Slider.GetValueStep

    local function OnValueChanged(self)
        self:GetChild("Text"):SetText(self:GetValue() or "")
    end

    function SetValue(self, value)
        setValue(self, value)
        OnValueChanged(self)
    end

    function GetValue(self)
        local value             = getValue(self)
        local step              = self:GetValueStep()

        if value and step then
            local count         = tostring(step):match("%.%d+")
            count               = count and 10 ^ (#count - 1) or 1
            return floor(count * value) / count
        end

        return value
    end

    function SetValueStep(self, step)
        self.__RealValueStep    = step
        setValueStep(self, step)
    end

    function GetValueStep(self)
        return self.__RealValueStep or getValueStep(self)
    end

    __Template__{
        Text                    = FontString,
        MinText                 = FontString,
        MaxText                 = FontString,
    }
    function __ctor(self)
        self.OnValueChanged     = self.OnValueChanged + OnValueChanged
    end
end)

-----------------------------------------------------------
--                     Dialog Widget                     --
-----------------------------------------------------------
__Sealed__() __Template__(Frame)
class "Dialog"  {
    Resizer                     = Resizer,
    CloseButton                 = UIPanelCloseButton,
}

__Sealed__() __Template__(Mover)
__ChildProperty__(Dialog, "Header")
class "DialogHeader" {
    HeaderText                  = FontString,

    --- The text of the header
    Text                        = {
        type                    = String,
        set                     = function(self, text)
            local headerText    = self:GetChild("HeaderText")
            headerText:SetText(text or "")

            Next(function()
                local minwidth  = self:GetMinResize() or 0
                local maxwidth  = self:GetMaxResize() or math.huge
                if maxwidth == 0 then maxwidth = math.huge end
                maxwidth        = math.min(maxwidth, self:GetParent() and self:GetParent():GetWidth() or math.huge)
                local textwidth = headerText:GetStringWidth() + self.TextPadding

                self:SetWidth(math.min( math.max(minwidth, textwidth), maxwidth))
            end)
        end,
    },

    --- The text padding of the header(the sum of the spacing on the left & right)
    TextPadding                 = { type = Number, default = 64, handler = function(self) self.Text = self.Text end }
}

-----------------------------------------------------------
--                    GroupBox Widget                    --
-----------------------------------------------------------
__Sealed__() __Template__(Frame)
class "GroupBox" { }

__Sealed__() __Template__(Frame)
__ChildProperty__(GroupBox, "Header")
class "GroupBoxHeader" {
    HeaderText                  = FontString,
    UnderLine                   = Texture,

    --- The text of the header
    Text                        = {
        type                    = String,
        get                     = function(self)
            return self:GetChild("HeaderText"):GetText()
        end,
        set                     = function(self, text)
            self:GetChild("HeaderText"):SetText(text or "")
        end,
    },
}

-----------------------------------------------------------
--                 UICheckButton Widget                  --
-----------------------------------------------------------
__Sealed__()
class "UICheckButton" {CheckButton }

__Sealed__()
class "UIRadioButton" (function(_ENV)
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

    function __ctor(self)
        self.OnClick            = self.OnClick + OnClick
    end
end)

__Sealed__() __ChildProperty__(CheckButton, "Label")
class "UICheckButtonLabel" { FontString,
    SetText                     = function(self, text)
        FontString.SetText(self, text)

        Next(function()
            local parent        = self:GetParent()
            local trycnt        = 10

            if parent then
                while trycnt > 0 and not (parent:GetRight() and self:GetLeft()) do
                    Next() trycnt = trycnt - 1
                end

                parent:SetHitRectInsets(0, parent:GetRight() - self:GetLeft() - self:GetStringWidth(), 0, 0)
            end
        end)
    end,
}

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
    [UIPanelLabel]              = {
        drawLayer               = "BACKGROUND",
        fontObject              = GameFontHighlight,
        location                = { Anchor("RIGHT", -24, 0, nil, "LEFT") },
        justifyH                = "RIGHT",
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
    [InputBox]                  = {
        fontObject              = ChatFontNormal,

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
        toplevel                = true,
        movable                 = true,
        resizable               = true,
        backdrop                = {
            bgFile              = [[Interface\DialogFrame\UI-DialogBox-Background]],
            edgeFile            = [[Interface\DialogFrame\UI-DialogBox-Border]],
            tile                = true, tileSize = 32, edgeSize = 32,
            insets              = { left = 11, right = 12, top = 12, bottom = 11 }
        },
        backdropBorderColor     = ColorType(1, 1, 1),

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
        backdropBorderColor     = ColorType(0.6, 0.6, 0.6),
    },
    [GroupBoxHeader]            = {
        location                = { Anchor("TOPLEFT"), Anchor("TOPRIGHT") },
        height                  = 48,

        HeaderText              = {
            fontObject          = OptionsFontHighlight,
            location            = { Anchor("TOPLEFT", 16, -16) },
        },

        UnderLine               = {
            height              = 1,
            color               = ColorType(1, 1, 1, 0.2),
            location            = { Anchor("TOPLEFT", 0, -3, "HeaderText", "BOTTOMLEFT"), Anchor("RIGHT", -16, 0) },
        },
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

        Label                   = {
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
        Label                   = {
            fontObject          = GameFontNormalSmall,
            location            = { Anchor("LEFT", -2, 0, nil, "RIGHT") },
        },
    },
})

if not IS_CLASSIC then return end
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