--========================================================--
--             Scorpio InputBox Widget                    --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/02/05                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Widget.InputBox"          "1.0.0"
--========================================================--

-----------------------------------------------------------
--                 UIPanelButton Widget                  --
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

    __Template__{
        LeftBG                  = Texture,
        RightBG                 = Texture,
        MiddleBG                = Texture,
    }
    function __ctor(self)
        self.OnEscapePressed    = self.OnEscapePressed + OnEscapePressed
        self.OnEditFocusGained  = self.OnEditFocusGained + OnEditFocusGained
        self.OnEditFocusLost    = self.OnEditFocusLost + OnEditFocusLost
    end
end)

-----------------------------------------------------------
--             UIPanelButton Style - Default             --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [InputBox]                  = {
        FontObject              = ChatFontNormal,
        LeftBG                  = {
            Atlas               = {
                atlas           = [[common-search-border-left]],
                useAtlasSize    = false,
            },
            Location            = {
                Anchor("TOPLEFT", -5, 0),
                Anchor("BOTTOMLEFT", -5, 0),
            },
            Width = 8,
        },
        RightBG                 = {
            Atlas               = {
                atlas           = [[common-search-border-right]],
                useAtlasSize    = false,
            },
            Location            = {
                Anchor("TOPRIGHT", 0, 0),
                Anchor("BOTTOMRIGHT", 0, 0),
            },
            Width = 8,
        },
        MiddleBG                = {
            Atlas               = {
                atlas           = [[common-search-border-middle]],
                useAtlasSize    = false,
            },
            Location            = {
                Anchor("TOPLEFT", 0, 0, "LeftBG", "TOPRIGHT"),
                Anchor("BOTTOMRIGHT", 0, 0, "RightBG", "BOTTOMLEFT"),
            }
        },
    },
})