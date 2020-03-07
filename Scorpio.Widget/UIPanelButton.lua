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
__Sealed__()
class "UIPanelButton" { Button }

__Sealed__()
class "UIPanelCloseButton" { Button, function(self) self.OnClick = function(self) self:GetParent():Hide() end end }

-----------------------------------------------------------
--             UIPanelButton Style - Default             --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [UIPanelButton]             = {
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
    [UIPanelCloseButton]        = {
        Size                    = Size(32, 32),
        Location                = { Anchor("TOPRIGHT", -4, 4) },
        NormalTexture           = {
            file                = [[Interface\Buttons\UI-Panel-MinimizeButton-Up]],
        },
        PushedTexture           = {
            file                = [[Interface\Buttons\UI-Panel-MinimizeButton-Down]],
        },
        HighlightTexture        = {
            file                = [[Interface\Buttons\UI-Panel-MinimizeButton-Highlight]],
            alphamode           = "ADD",
        },
    },
})