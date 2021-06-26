--========================================================--
--             Scorpio Secure EquipSet Handler            --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.EquipSetHandler"      "1.0.0"
--========================================================--

------------------------------------------------------
-- Action Handler
------------------------------------------------------
handler                         = ActionTypeHandler {
    Name                        = "equipmentset",

    InitSnippet                 = [[ _EquipSet = newtable() ]],

    PickupSnippet               = [[
        local target            = ...
        return "clear", "equipmentset", _EquipSet[target]
    ]],

    UpdateSnippet               = [[
        local target            = ...

        self:SetAttribute("*type*", "macro")
        self:SetAttribute("*macrotext*", "/equipset "..target)
    ]],

    ClearSnippet                = [[
        self:SetAttribute("*type*", nil)
        self:SetAttribute("*macrotext*", nil)
    ]],
}

------------------------------------------------------
-- Module Event Handler
------------------------------------------------------
_EquipSetTemplate               = "_EquipSet[%q] = %d\n"

_EquipSetMap                    = {}

GetEquipmentSetInfo             = C_EquipmentSet.GetEquipmentSetInfo

------------------------------------------------------
-- System Event Handler
------------------------------------------------------
__SystemEvent__()
function PLAYER_EQUIPMENT_CHANGED()
    return handler:RefreshActionButtons()
end

__SystemEvent__"PLAYER_ENTERING_WORLD" "EQUIPMENT_SETS_CHANGED"
function PLAYER_ENTERING_WORLD()
    return UpdateEquipmentSet()
end

function UpdateEquipmentSet()
    local str                   = "for i in pairs(_EquipSet) do _EquipSet[i] = nil end\n"

    wipe(_EquipSetMap)

    for _, id in pairs(C_EquipmentSet.GetEquipmentSetIDs()) do
        local name              = GetEquipmentSetInfo(id)
        str                     = str .. _EquipSetTemplate:format(name, id)
        _EquipSetMap[name]      = id
    end

    if str ~= "" then
        NoCombat(function ()
            handler:RunSnippet( str )

            return handler:RefreshActionButtons()
        end)
    end
end

------------------------------------------------------
-- Overwrite methods
------------------------------------------------------
function handler:PickupAction(target)
    return _EquipSetMap[target] and C_EquipmentSet.PickupEquipmentSet(_EquipSetMap[target])
end

function handler:GetActionText()
    return self.ActionTarget
end

function handler:GetActionTexture()
    local target = self.ActionTarget
    return _EquipSetMap[target] and select(2, GetEquipmentSetInfo(_EquipSetMap[target]))
end

function handler:IsEquippedItem()
    local target = self.ActionTarget
    return _EquipSetMap[target] and select(4, GetEquipmentSetInfo(_EquipSetMap[target]))
end

function handler:IsActivedAction()
    local target = self.ActionTarget
    return _EquipSetMap[target] and select(4, GetEquipmentSetInfo(_EquipSetMap[target]))
end

function handler:SetTooltip(tip)
    if _EquipSetMap[self.ActionTarget] then
        tip:SetEquipmentSet(_EquipSetMap[self.ActionTarget])
    end
end
