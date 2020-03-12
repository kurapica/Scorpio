--========================================================--
--             Scorpio GroupBox Widget                    --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/03/05                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Widget.GroupBox"         "1.0.0"
--========================================================--

-----------------------------------------------------------
--                    GroupBox Widget                    --
-----------------------------------------------------------
__Sealed__() __Template__(Frame)
class "GroupBox" { }

__Sealed__() __Template__(Frame)
class "GroupBoxHeader" {
	HeaderText 					= FontString,
	UnderLine 					= Texture,

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
--                   GroupBox Property                   --
-----------------------------------------------------------
--- The headerw of the dialog
UI.Property                     {
    name                        = "Header",
    require                     = GroupBox,
    childtype                   = GroupBoxHeader,
    nilable                     = true,
}

-----------------------------------------------------------
--                    GroupBox Style                     --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [GroupBox]              	= {
        Backdrop                = {
            edgeFile            = [[Interface\Tooltips\UI-Tooltip-Border]],
            tile                = true, tileSize = 16, edgeSize = 16,
            insets              = { left = 5, right = 5, top = 5, bottom = 5 }
        },
        BackdropBorderColor     = ColorType(0.6, 0.6, 0.6),
    },
    [GroupBoxHeader]			= {
        Location                = { Anchor("TOPLEFT"), Anchor("TOPRIGHT") },
        Height 					= 48,
    	HeaderText 				= {
    		FontObject 			= OptionsFontHighlight,
    		Location 			= { Anchor("TOPLEFT", 16, -16) },
    	},
    	UnderLine 				= {
    		Height 				= 1,
    		Color 				= ColorType(1, 1, 1, 0.2),
    		Location 			= { Anchor("TOPLEFT", 0, -3, "HeaderText", "BOTTOMLEFT"), Anchor("RIGHT", -16, 0) },
    	},
    },
})