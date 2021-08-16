--========================================================--
--             Scorpio Secure Custom Handler              --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.CustomHandler"        "1.0.0"
--========================================================--

------------------------------------------------------
-- Action Handler
------------------------------------------------------
handler                         = ActionTypeHandler {
    Name                        = "custom",
    DragStyle                   = "Block",
    ReceiveStyle                = "Clear",

    ClearSnippet                = [[
        Manager:CallMethod("ClearCustom", self:GetName())
    ]],
}

__SecureMethod__()
function handler.Manager:ClearCustom(btnName)
    self                        = UI.GetProxyUI(_G[btnName])
    self:SetAttribute("_custom", nil)
    self.CustomText             = nil
    self.CustomTexture          = nil
end

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
    --- The custom text
    property "CustomText"       { Type = String, handler = function(self, val) self.Text = val end  }

    --- The custom texture path
    property "CustomTexture"    { Type = String + Number, handler = function(self, val) self.Icon = val end }

    --- The custom tooltip
    property "CustomTooltip"    { Type = String }
end)