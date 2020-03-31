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
__Sealed__()
class "UIPanelScrollUpButton" { Button }

__Sealed__()
class "UIPanelScrollDownButton" { Button }

__Sealed__()
class "UIPanelScrollBar" (function(_ENV)
    inherit "Slider"


    __Template__{
        ScrollUpButton          = UIPanelScrollUpButton,
        ScrollDownButton        = UIPanelScrollDownButton,
    }
    function __ctor(self)
    end
end)

__Sealed__()
class "UIPanelScrollFrame" { ScrollFrame }

-----------------------------------------------------------
--          UIPanelScrollFrame Style - Default           --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [UIPanelScrollUpButton]     = {
        size                    = Size(18, 16),

        NormalTexture           = {
            file                = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Up]],
            texCoords           = RectType(0.20, 0.80, 0.25, 0.75),
        },
        PushedTexture           = {
            file                = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Down]],
            texCoords           = RectType(0.20, 0.80, 0.25, 0.75),
        },
        DisabledTexture         = {
            file                = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Disabled]],
            texCoords           = RectType(0.20, 0.80, 0.25, 0.75),
        },
        HighlightTexture        = {
            file                = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Highlight]],
            texCoords           = RectType(0.20, 0.80, 0.25, 0.75),
            alphamode           = "ADD",
        }
    },
    [UIPanelScrollDownButton]   = {
        size                    = Size(18, 16),

        NormalTexture           = {
            file                = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Up]],
            texCoords           = RectType(0.20, 0.80, 0.25, 0.75),
        },
        PushedTexture           = {
            file                = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Down]],
            texCoords           = RectType(0.20, 0.80, 0.25, 0.75),
        },
        DisabledTexture         = {
            file                = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Disabled]],
            texCoords           = RectType(0.20, 0.80, 0.25, 0.75),
        },
        HighlightTexture        = {
            file                = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Highlight]],
            texCoords           = RectType(0.20, 0.80, 0.25, 0.75),
            alphamode           = "ADD",
        }
    },
    [UIPanelScrollBar]          = {
        width                   = 16,

        ThumbTexture            = {
            file                = [[Interface\Buttons\UI-ScrollBar-Knob]],
            texCoords           = RectType(0.20, 0.80, 0.125, 0.875),
            alphamode           = "ADD",
        },

        -- Childs
        ScrollUpButton          = {
            location            = { Anchor("BOTTOM", 0, 0, nil, "TOP") },
        },
        ScrollDownButton        = {
            location            = { Anchor("TOP", 0, 0, nil, "BOTTOM") },
        },
    }
})