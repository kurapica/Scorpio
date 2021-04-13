--========================================================--
--             Scorpio Secure Battle Pet Handler          --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.BattlePetHandler"     "1.0.0"
--========================================================--

_Enabled                        = false

------------------------------------------------------
-- Action Handler
------------------------------------------------------
handler                         = ActionTypeHandler {
    Name                        = "battlepet",

    PickupSnippet               = "Custom",

    UpdateSnippet               = [[
        local target            = ...

        self:SetAttribute("*type*", "macro")
        self:SetAttribute("*macrotext*", "/summonpet "..target)
    ]],

    ClearSnippet                = [[
        self:SetAttribute("*type*", nil)
        self:SetAttribute("*macrotext*", nil)
    ]],

    OnEnableChanged             = function(self, value) _Enabled = value end,
}

------------------------------------------------------
-- Module Event Handler
------------------------------------------------------
SUMMON_RANDOM_FAVORITE_PET_SPELL= 243819
SUMMON_RANDOM_ID                = 0

-- Event handler
function OnEnable(self)
    OnEnable                    = nil

    C_PetJournal.PickupSummonRandomPet()

    local ty, pick              = GetCursorInfo()
    ClearCursor()
    SUMMON_RANDOM_ID            = pick

    return handler:RefreshAll()
end

------------------------------------------------------
-- System Event Handler
------------------------------------------------------
__SystemEvent__()
function PET_JOURNAL_LIST_UPDATE()
    return handler:RefreshAll()
end


------------------------------------------------------
-- Overwrite methods
------------------------------------------------------
function DelayRefreshIcon(self)
    if self.ActionType == "battlepet" then
        local target, icon      = self.ActionTarget
        if target == SUMMON_RANDOM_ID then
            icon                = GetSpellTexture(SUMMON_RANDOM_FAVORITE_PET_SPELL)
        else
            icon                = select(9, C_PetJournal.GetPetInfoByPetID(target))
        end

        self.Icon               = icon
    end
end

function handler:PickupAction(target)
    if target == SUMMON_RANDOM_ID then
        return C_PetJournal.PickupSummonRandomPet()
    else
        return C_PetJournal.PickupPet(target)
    end
end

function handler:GetActionTexture()
    local target, icon          = self.ActionTarget
    if target == SUMMON_RANDOM_ID then
        icon                    = GetSpellTexture(SUMMON_RANDOM_FAVORITE_PET_SPELL)
    else
        icon                    = select(9, C_PetJournal.GetPetInfoByPetID(target))
    end

    if not icon then Delay(1, DelayRefreshIcon, self) end
    return icon
end

function handler:SetTooltip(GameTooltip)
    local target                = self.ActionTarget
    if target == SUMMON_RANDOM_ID then
        return GameTooltip:SetSpellByID(SUMMON_RANDOM_FAVORITE_PET_SPELL)
    else
        local speciesID, _, _, _, _, _, _, name, _, _, _, sourceText, description, _, _, tradable, unique = C_PetJournal.GetPetInfoByPetID(target)

        if speciesID then
            GameTooltip:SetText(name, 1, 1, 1)

            if sourceText and sourceText ~= "" then
                GameTooltip:AddLine(sourceText, 1, 1, 1, true)
            end

            if description and description ~= "" then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(description, nil, nil, nil, true)
            end
            GameTooltip:Show()
        end
    end
end

------------------------------------------------------
-- Extend Definitions
------------------------------------------------------
class "SecureActionButton" (function(_ENV)
    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    --- The action button's content if its type is 'battlepet'
    property "BattlePet" {
        type                    = String,
        set                     = function(self, value) self:SetAction("battlepet", value) end,
        get                     = function(self) return self:GetAttribute("actiontype") == "battlepet" and self:GetAttribute("battlepet") or nil end,
    }
end)