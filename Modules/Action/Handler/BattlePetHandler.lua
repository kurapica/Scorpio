--========================================================--
--             Scorpio Secure Battle Pet Handler          --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

if not _G.C_PetJournal then return end

--========================================================--
Scorpio        "Scorpio.Secure.BattlePetHandler"     "1.0.0"
--========================================================--

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
}

------------------------------------------------------
-- Module Event Handler
------------------------------------------------------
SUMMON_RANDOM_FAVORITE_PET_SPELL= 243819
SUMMON_RANDOM_ID                = 0

-- Event handler
function OnEnable(self)
    OnEnable                    = nil

    if C_PetJournal.PickupSummonRandomPet then
        C_PetJournal.PickupSummonRandomPet()

        local ty, pick              = GetCursorInfo()
        ClearCursor()
        SUMMON_RANDOM_ID            = pick
    end

    return handler:RefreshActionButtons()
end

------------------------------------------------------
-- System Event Handler
------------------------------------------------------
__SystemEvent__()
function PET_JOURNAL_LIST_UPDATE()
    return handler:RefreshActionButtons()
end


------------------------------------------------------
-- Overwrite methods
------------------------------------------------------
function DelayRefreshIcon(self)
    if self.ActionType == "battlepet" then
        local target, icon      = self.ActionTarget
        if target == SUMMON_RANDOM_ID then
            icon                = C_Spell.GetSpellTexture(SUMMON_RANDOM_FAVORITE_PET_SPELL)
        else
            icon                = select(9, C_PetJournal.GetPetInfoByPetID(target))
        end

        self.Icon               = icon
    end
end

function handler:PickupAction(target)
    if target == SUMMON_RANDOM_ID then
        return C_PetJournal.PickupSummonRandomPet and C_PetJournal.PickupSummonRandomPet()
    else
        return C_PetJournal.PickupPet(target)
    end
end

function handler:GetActionTexture()
    local target, icon          = self.ActionTarget
    if target == SUMMON_RANDOM_ID then
        icon                    = C_Spell.GetSpellTexture(SUMMON_RANDOM_FAVORITE_PET_SPELL)
    else
        icon                    = select(9, C_PetJournal.GetPetInfoByPetID(target))
    end

    if not icon then Delay(1, DelayRefreshIcon, self) end
    return icon
end

function handler:SetTooltip(tip)
    local target                = self.ActionTarget
    if target == SUMMON_RANDOM_ID then
        return tip:SetSpellByID(SUMMON_RANDOM_FAVORITE_PET_SPELL)
    else
        local speciesID, _, _, _, _, _, _, name, _, _, _, sourceText, description, _, _, tradable, unique = C_PetJournal.GetPetInfoByPetID(target)

        if speciesID then
            tip:SetText(name, 1, 1, 1)

            if sourceText and sourceText ~= "" then
                tip:AddLine(sourceText, 1, 1, 1, true)
            end

            if description and description ~= "" then
                tip:AddLine(" ")
                tip:AddLine(description, nil, nil, nil, true)
            end
            tip:Show()
        end
    end
end
