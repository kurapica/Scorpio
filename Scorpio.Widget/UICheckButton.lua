--========================================================--
--             Scorpio UICheckButton Widget               --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/02/05                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Widget.UICheckButton"     "1.0.0"
--========================================================--

-----------------------------------------------------------
--                 UICheckButton Widget                  --
-----------------------------------------------------------
__Sealed__()
class "UICheckButtonLabel" { FontString,
    SetText                     = function(self, text)
        FontString.SetText(self, text)

        Next(function()
            local textwidth     = self:GetStringWidth()
            local parent        = self:GetParent()

            if parent then
                Style[parent].HitRectInsets = Inset(0, parent:GetRight() - self:GetLeft() - textwidth, 0, 0)
            end
        end)
    end,
}

__Sealed__() __Template__(CheckButton)
class "UIRadioButton" {
    Label                       = UICheckButtonLabel,
}

__Sealed__() __Template__(CheckButton)
class "UICheckButton" {
    Label                       = UICheckButtonLabel,
}

-----------------------------------------------------------
--             UICheckButton Style - Default             --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
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