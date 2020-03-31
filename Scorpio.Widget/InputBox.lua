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
        fontObject              = ChatFontNormal,

        LeftBG                  = {
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
        RightBG                 = {
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
        MiddleBG                = {
            atlas               = {
                atlas           = [[common-search-border-middle]],
                useAtlasSize    = false,
            },
            location            = {
                Anchor("TOPLEFT", 0, 0, "LeftBG", "TOPRIGHT"),
                Anchor("BOTTOMRIGHT", 0, 0, "RightBG", "BOTTOMLEFT"),
            }
        },
    },
})