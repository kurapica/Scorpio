--========================================================--
--             Scorpio Secure Action InventoryHandler     --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/11/25                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.InventoryHandler"     "1.0.0"
--========================================================--

_Enabled                        = false

handler                         = SecureActionButton.ActionTypeHandler {
    Name                        = "inventory",

    InitSnippet                 = [[
    ]],

    PickupSnippet               = [[
    ]],

    UpdateSnippet               = [[
    ]],

    ReceiveSnippet              = [[
    ]],

    OnEnableChanged             = function(self) _Enabled = self.Enabled end,
}

-- Overwrite methods
function handler:PickupAction(target)
    return PickupInventoryItem(target)
end

function handler:HasAction()
end

function handler:GetActionText()
end

function handler:GetActionTexture()
end

function handler:GetActionCharges()
end

function handler:GetActionCount()
end

function handler:GetActionCooldown()
end

function handler:IsAttackAction()
end

function handler:IsEquippedItem()
end

function handler:IsActivedAction()
end

function handler:IsAutoRepeatAction()
end

function handler:IsUsableAction()
end

function handler:IsConsumableAction()
end

function handler:IsInRange()
end

function handler:IsAutoCastAction()
end

function handler:IsAutoCasting()
end

function handler:SetTooltip()
end

function handler:GetSpellId()
end

function handler:IsFlyout()
end