--========================================================--
--             Scorpio UIPanelLabel Widget                --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/04/06                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Widget.UIPanelLabel"      "1.0.0"
--========================================================--

-----------------------------------------------------------
--                  UIPanelLabel Widget                  --
-----------------------------------------------------------
__Sealed__()
class "UIPanelLabel" { FontString }

-----------------------------------------------------------
--                    Label Property                     --
-----------------------------------------------------------
--- Use the label as the style property
UI.Property                     {
    name                        = "Label",
    require                     = Frame,
    childtype                   = UIPanelLabel,
    nilable                     = true,
}

-----------------------------------------------------------
--                  UIPanelLabel Style                   --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [UIPanelLabel]              = {
        drawLayer               = "BACKGROUND",
        fontObject              = GameFontHighlight,
        location                = { Anchor("LEFT", -100, 0) },
    },
})