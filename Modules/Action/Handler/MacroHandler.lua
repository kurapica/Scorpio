--========================================================--
--             Scorpio Secure Macro Handler               --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.MacroHandler"         "1.0.0"
--========================================================--

_Enabled                        = false

------------------------------------------------------
-- Action Handler
------------------------------------------------------
handler                         = ActionTypeHandler {
    Name                        = "macro",
    PickupSnippet               = [[ return "clear", "macro", ... ]],

    OnEnableChanged             = function(self, value) _Enabled = value end,
}


------------------------------------------------------
-- System Event Handler
------------------------------------------------------
__SystemEvent__()
function UPDATE_MACROS()
    return handler:RefreshActionButtons()
end


------------------------------------------------------
-- Overwrite methods
------------------------------------------------------
function handler:PickupAction(target)
    return PickupMacro(target)
end

function handler:GetActionText()
    return (GetMacroInfo(self.ActionTarget))
end

function handler:GetActionTexture()
    return (select(2, GetMacroInfo(self.ActionTarget)))
end
