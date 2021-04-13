--========================================================--
--             Scorpio Secure Pet Action Handler          --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.PetActionHandler"     "1.0.0"
--========================================================--

_Enabled                        = false

------------------------------------------------------
-- Action Handler
------------------------------------------------------
handler                         = ActionTypeHandler {
    Name                        = "pet",
    Target                      = "action",
    DragStyle                   = "Keep",
    ReceiveStyle                = "Keep",
    IsPlayerAction              = false,
    IsPetAction                 = true,
    PickupSnippet               = [[ return "petaction", ... ]],
    UpdateSnippet               = [[
        local target            = ...

        if tonumber(target) then
            -- Use macro to toggle auto cast
            self:SetAttribute("type2", "macro")
            self:SetAttribute("macrotext2", "/click PetActionButton".. target .. " RightButton")
        end
    ]],

    ClearSnippet                = [[
        self:SetAttribute("type2", nil)
        self:SetAttribute("macrotext2", nil)
    ]],

    PreClickSnippet             = [[
        local type, action      = GetActionInfo(self:GetAttribute("action"))
        return nil, format("%s|%s", tostring(type), tostring(action))
    ]],

    PostClickSnippet            = [[
        local message           = ...
        local type, action      = GetActionInfo(self:GetAttribute("action"))
        if message ~= format("%s|%s", tostring(type), tostring(action)) then
            return Manager:RunFor(self, UpdateAction)
        end
    ]],

    OnEnableChanged             = function(self, value) _Enabled = value end,
}


------------------------------------------------------
-- Addon Event Handler
------------------------------------------------------
function OnEnable()
    OnEnable                    = nil

    Wow.FromEvent("UNIT_AURA"):MatchUnit("pet"):Next(function()
        return handler:RefreshButtonState()
    end)
end

------------------------------------------------------
-- System Event Handler
------------------------------------------------------
__SystemEvent__"PET_STABLE_UPDATE" "PET_STABLE_SHOW" "PLAYER_CONTROL_LOST"
                "PLAYER_CONTROL_GAINED" "PLAYER_FARSIGHT_FOCUS_CHANGED"
                "PET_BAR_UPDATE" "PET_UI_UPDATE" "UPDATE_VEHICLE_ACTIONBAR"
function PET_STABLE_UPDATE()
    return handler:RefreshAll()
end

__SystemEvent__()
function UNIT_PET(unit)
    if unit == "player" then
        return handler:RefreshAll()
    end
end

__SystemEvent__()
function UNIT_FLAGS(unit)
    if unit == "pet" then
        return handler:RefreshAll()
    end
end

__SystemEvent__()
function PET_BAR_UPDATE_COOLDOWN()
    return handler:RefreshCooldown()
end

__SystemEvent__()
function PET_BAR_UPDATE_USABLE()
    return handler:RefreshUsable()
end


------------------------------------------------------
-- Overwrite methods
------------------------------------------------------
function handler:PickupAction(target)
    return PickupPetAction(target)
end

function handler:HasAction()
    return GetPetActionInfo(self.ActionTarget) and true
end

function handler:GetActionTexture()
    local name, texture, isToken = GetPetActionInfo(self.ActionTarget)
    if name then
        return isToken and _G[texture] or texture
    end
end

function handler:GetActionCooldown()
    return GetPetActionCooldown(self.ActionTarget)
end

function handler:IsUsableAction()
    return GetPetActionSlotUsable(self.ActionTarget)
end

function handler:IsActivedAction()
    return select(4, GetPetActionInfo(self.ActionTarget))
end

function handler:IsAutoCastAction()
    return select(5, GetPetActionInfo(self.ActionTarget))
end

function handler:IsAutoCasting()
    return select(6, GetPetActionInfo(self.ActionTarget))
end

function handler:SetTooltip(GameTooltip)
    return GameTooltip:SetPetAction(self.ActionTarget)
end

function handler:IsRangeSpell()
    return true
end

------------------------------------------------------
-- Extend Definitions
------------------------------------------------------
class "SecureActionButton" (function(_ENV)
    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    --- The action button's content if its type is 'pet'
    property "PetAction" {
        type                    = NumberNil,
        set                     = function(self, value) self:SetAction("pet", value) end,
        get                     = function(self) return self:GetAttribute("actiontype") == "pet" and tonumber(self:GetAttribute("action")) or nil end,
    }
end)