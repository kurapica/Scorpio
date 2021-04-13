--========================================================--
--             Scorpio Secure Custom Handler              --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.CustomHandler"        "1.0.0"
--========================================================--

_Enabled                        = false

------------------------------------------------------
-- Action Handler
------------------------------------------------------
handler                         = ActionTypeHandler {
    Name                        = "custom",
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

function handler:Map(target, detail)
    -- Convert to spell id
    self:SetAttribute("_custom", target)
    target                      = "_"

    return target, detail
end

------------------------------------------------------
-- Extend Definitions
------------------------------------------------------
class "SecureActionButton" (function(_ENV)

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    --- The custom action
    property "Custom" {
        set                     = function(self, value) return self:SetAction("custom", value) end
        get                     = function(self) return self:GetAttribute("actiontype") == "custom" and self:GetAttribute("_custom") or nil end
        end,
    }

    --- The custom text
    property "CustomText"       { Type = String }

    --- The custom texture path
    __Handler__("Refresh")
    property "CustomTexture"    { Type = String + Number, handler = function(self) handler:RefreshAll(self) end }

    --- The custom tooltip
    property "CustomTooltip"    { Type = String }
end)