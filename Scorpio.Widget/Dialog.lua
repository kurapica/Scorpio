--========================================================--
--             Scorpio Dialog Widget                      --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/03/05                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Widget.Dialog"            "1.0.0"
--========================================================--

-----------------------------------------------------------
--                     Dialog Widget                     --
-----------------------------------------------------------
__Sealed__() __Template__(Frame)
class "Dialog"  {
    Mover                   	= Mover,
    Resizer                     = Resizer,
    CloseButton         		= UIPanelCloseButton,
}

-----------------------------------------------------------
--                     Dialog Style                      --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [Dialog]                    = {
        FrameStrata             = "DIALOG",
        Toplevel                = true,
        Movable                 = true,
        Resizable               = true,
        Backdrop                = {
            bgFile              = [[Interface\DialogFrame\UI-DialogBox-Background]],
            edgeFile            = [[Interface\DialogFrame\UI-DialogBox-Border]],
            tile                = true, tileSize = 32, edgeSize = 32,
            insets              = { left = 11, right = 12, top = 12, bottom = 11 }
        },
        BackdropBorderColor     = ColorType(1, 1, 1),

        CloseButton             = {
            Location            = { Anchor("TOPRIGHT", -4, -4)},
        },

        Mover                   = {
            Location            = { Anchor("TOPLEFT"), Anchor("RIGHT", -4, 0, "CloseButton", "LEFT")}
        },

        Resizer                 = {
            Location            = { Anchor("BOTTOMRIGHT", -8, 8)}
        }
    },
})

Style.ActiveSkin("Default",     Dialog)