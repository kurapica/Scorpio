--========================================================--
--             Scorpio UIPanelButton Widget               --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/02/05                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Widget.UIPanelButton"     "1.0.0"
--========================================================--


-----------------------------------------------------------
--                 UIPanelButton Widget                  --
-----------------------------------------------------------
__Sealed__() __Template__(Button)
class "UIPanelButton" {
    LeftBG                      = Texture,
    RightBG                     = Texture,
    MiddleBG                    = Texture,
}

__Sealed__()
class "UIPanelCloseButton" { Button, function(self) self.OnClick = function(self) self:GetParent():Hide() end end }

-----------------------------------------------------------
--             UIPanelButton Style - Default             --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [UIPanelButton]             = {
        size                    = Size(80, 22),
        normalFont             = GameFontNormal,
        disabledFont           = GameFontDisable,
        highlightFont          = GameFontHighlight,

        LeftBG                  = {
            drawLayer           = "ARTWORK",
            file                = [[Interface\Buttons\UI-Panel-Button-Up]],
            texCoords           = RectType(0, 0.09375, 0, 0.6875),
            location            = {
                Anchor("TOPLEFT", 0, 0),
                Anchor("BOTTOMLEFT", 0, 0),
            },
            width               = 12,
        },
        RightBG                 = {
            file                = [[Interface\Buttons\UI-Panel-Button-Up]],
            texCoords           = RectType(0.53125, 0.625, 0, 0.6875),
            location            = {
                Anchor("TOPRIGHT", 0, 0),
                Anchor("BOTTOMRIGHT", 0, 0),
            },
            width               = 12,
        },
        MiddleBG                = {
            file                = [[Interface\Buttons\UI-Panel-Button-Up]],
            texCoords           = RectType(0.09375, 0.53125, 0, 0.6875),
            location            = {
                Anchor("TOPLEFT", 0, 0, "LeftBG", "TOPRIGHT"),
                Anchor("BOTTOMRIGHT", 0, 0, "RightBG", "BOTTOMLEFT"),
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
})