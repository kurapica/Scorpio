--========================================================--
--             Scorpio Secure Macro Text Handler          --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.MacroTextHandler"     "1.0.0"
--========================================================--

------------------------------------------------------
-- Action Handler
------------------------------------------------------
handler                         = ActionTypeHandler {
    Name                        = "macrotext",
    Type                        = "macro",
    Target                      = "macrotext",
    DragStyle                   = "Block",
    ReceiveStyle                = "Clear",

    ClearSnippet                = [[
        Manager:CallMethod("ClearCustom", self:GetName())
    ]],
}

------------------------------------------------------
-- Overwrite methods
------------------------------------------------------
function handler:GetActionText()
    return self.CustomText
end

function handler:GetActionTexture()
    return self.CustomTexture
end

function handler:SetTooltip(tip)
    if self.CustomTooltip then
        tip:SetText(self.CustomTooltip)
    end
end
