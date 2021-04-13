--========================================================--
--             Scorpio Secure Macro Text Handler          --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.MacroTextHandler"     "1.0.0"
--========================================================--

_Enabled                        = false

------------------------------------------------------
-- Action Handler
------------------------------------------------------
handler                         = ActionTypeHandler {
    Name                        = "macrotext",
    Type                        = "macro",
    Target                      = "macrotext",
    DragStyle                   = "Block",
    ReceiveStyle                = "Block",

    OnEnableChanged             = function(self, value) _Enabled = value end,
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

function handler:SetTooltip(GameTooltip)
    if self.CustomTooltip then
        GameTooltip:SetText(self.CustomTooltip)
    end
end

------------------------------------------------------
-- Extend Definitions
------------------------------------------------------
class "SecureActionButton" (function(_ENV)
    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    --- The action button's content if its type is 'macrotext'
    property "MacroText"        {
        type                    = String,
        set                     = function(self, value) self:SetAction("macrotext", value) end,
        get                     = function(self) return self:GetAttribute("actiontype") == "macrotext" and self:GetAttribute("macrotext") or nil end,
    }

    --- The custom text
    property "CustomText"       { Type = String }

    --- The custom texture path
    __Handler__("Refresh")
    property "CustomTexture"    { Type = String + Number, handler = function(self) handler:RefreshAll(self) end }

    --- The custom tooltip
    property "CustomTooltip"    { Type = String }
end)