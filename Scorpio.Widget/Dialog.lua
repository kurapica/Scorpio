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
    Resizer                     = Resizer,
    CloseButton                 = UIPanelCloseButton,
}

__Sealed__() __Template__(Mover)
class "DialogHeader" {
    LeftBG                      = Texture,
    RightBG                     = Texture,
    MiddleBG                    = Texture,
    HeaderText                  = FontString,

    --- The text of the header
    Text                        = {
        type                    = String,
        get                     = function(self)
            return self:GetChild("HeaderText"):GetText()
        end,
        set                     = function(self, text)
            local headerText    = self:GetChild("HeaderText")
            headerText:SetText(text or "")

            Next(function()
                local minwidth  = self:GetMinResize() or 0
                local maxwidth  = self:GetMaxResize() or math.huge
                if maxwidth == 0 then maxwidth = math.huge end
                maxwidth        = math.min(maxwidth, self:GetParent() and self:GetParent():GetWidth() or math.huge)
                local textwidth = headerText:GetStringWidth() + self.TextPadding

                Style[self].Width = math.min( math.max(minwidth, textwidth), maxwidth)
            end)
        end,
    },

    --- The text padding of the header(the sum of the spacing on the left & right)
    TextPadding                 = { type = Number, default = 64, handler = function(self) self.Text = self.Text end }
}

-----------------------------------------------------------
--                   Dialog Property                     --
-----------------------------------------------------------
--- The header of the dialog
UI.Property                     {
    name                        = "Header",
    require                     = Dialog,
    childtype                   = DialogHeader,
    nilable                     = true,
}

-----------------------------------------------------------
--                     Dialog Style                      --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
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
        LeftBG                  = {
            atlas               = {
                atlas           = [[UI-Frame-DiamondMetal-Header-CornerLeft]],
                useAtlasSize    = false,
            },
            texelSnappingBias   = 0,
            snapToPixelGrid     = false,
            size                = Size(32, 39),
            location            = { Anchor("LEFT") },
        },
        RightBG                 = {
            atlas               = {
                atlas           = [[UI-Frame-DiamondMetal-Header-CornerRight]],
                useAtlasSize    = false,
            },
            texelSnappingBias   = 0,
            snapToPixelGrid     = false,
            size                = Size(32, 39),
            location            = { Anchor("RIGHT") },
        },
        MiddleBG                = {
            atlas               = {
                atlas           = [[_UI-Frame-DiamondMetal-Header-Tile]],
                useAtlasSize    = false,
            },
            horizTile           = true,
            texelSnappingBias   = 0,
            snapToPixelGrid     = false,
            location            = {
                Anchor("TOPLEFT", 0, 0, "LeftBG", "TOPRIGHT"),
                Anchor("BOTTOMRIGHT", 0, 0, "RightBG", "BOTTOMLEFT"),
            }
        },
    },
})