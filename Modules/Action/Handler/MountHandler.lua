--========================================================--
--             Scorpio Secure Mount Handler               --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

if not Scorpio.IsRetail then return end

--========================================================--
Scorpio        "Scorpio.Secure.MountHandler"         "1.0.0"
--========================================================--

export { GetProxyUI             = UI.GetProxyUI }

------------------------------------------------------
-- Action Handler
------------------------------------------------------
handler                         = ActionTypeHandler {
    Name                        = "mount",
    PickupSnippet               = "Custom",

    UpdateSnippet               = [[
        local target            = ...

        if target then
            self:SetAttribute("*type*", "macro")
            self:SetAttribute("*macrotext*", "/CANCELFORM")
        else
            self:SetAttribute("*type*", nil)
            self:SetAttribute("*macrotext*", nil)
        end
    ]],

    ClearSnippet                = [[
        self:SetAttribute("*type*", nil)
        self:SetAttribute("*macrotext*", nil)
    ]],

    PreClickSnippet             = [=[
        self:GetFrameRef("_Manager"):RunFor(self, [[ Manager:CallMethod("SummonMount", self:GetName()) ]])
    ]=],
}


------------------------------------------------------
-- Module Event Handler
------------------------------------------------------
GetMountInfoByID                = C_MountJournal.GetMountInfoByID
GetDisplayedMountInfo           = C_MountJournal.GetDisplayedMountInfo
SUMMON_RANDOM_FAVORITE_MOUNT_SPELL = 150544
SUMMON_RANDOM_ID                = 0

function OnEnable()
    OnEnable                    = nil

    C_MountJournal.Pickup(0)
    local ty, pick              = GetCursorInfo()
    ClearCursor()

    SUMMON_RANDOM_ID            = pick

    Wow.FromEvent("UNIT_AURA"):MatchUnit("player"):Next():Subscribe(function()
        return handler:RefreshButtonState()
    end)
end

------------------------------------------------------
-- System Event Handler
------------------------------------------------------
local firstUpdate = true

__SystemEvent__()
function COMPANION_UPDATE(companionType)
    if not companionType or companionType == "MOUNT" then
        if firstUpdate then
            firstUpdate         = true
            return handler:RefreshActionButtons()
        else
            return handler:RefreshUsable()
        end
    end
end

__SystemEvent__()
function SPELL_UPDATE_USABLE(self)
    return handler:RefreshUsable()
end

------------------------------------------------------
-- Secure Enviornment Init
------------------------------------------------------
__SecureMethod__()
function handler.Manager:SummonMount(btnName)
    local mountID               = GetProxyUI(_G[btnName]).ActionTarget

    if mountID then
        if select(4, C_MountJournal.GetMountInfoByID(mountID)) then
            C_MountJournal.Dismiss()
        else
            Next(C_MountJournal.SummonByID, mountID)
        end
    end
end

------------------------------------------------------
-- Overwrite methods
------------------------------------------------------
function DelayRefreshIcon(self)
    if self.ActionType == "mount" then
        local target, icon      = self.ActionTarget
        if target == SUMMON_RANDOM_ID then
            icon                = GetSpellTexture(SUMMON_RANDOM_FAVORITE_MOUNT_SPELL)
        else
            icon                = (select(3, GetMountInfoByID(target)))
        end

        self.Icon               = icon
    end
end

function handler:PickupAction(target)
    -- Try pickup
    if target == SUMMON_RANDOM_ID then
        return C_MountJournal.Pickup(0)
    else
        local i                 = 1
        while GetDisplayedMountInfo(i) do
            if target == select(12, GetDisplayedMountInfo(i)) then
                return C_MountJournal.Pickup(i)
            end
            i                   = i + 1
        end
    end
end

function handler:GetActionTexture()
    local target, icon          = self.ActionTarget
    if target == SUMMON_RANDOM_ID then
        icon                    = GetSpellTexture(SUMMON_RANDOM_FAVORITE_MOUNT_SPELL)
    else
        icon                    = (select(3, GetMountInfoByID(target)))
    end

    if not icon then Delay(1, DelayRefreshIcon, self) end

    return icon
end

function handler:IsActivedAction()
    local target                = self.ActionTarget
    if target == SUMMON_RANDOM_ID then
        return IsMounted()
    else
        return (select(4, GetMountInfoByID(target)))
    end
end

function handler:IsUsableAction()
    local target                = self.ActionTarget
    local canSummon             = not InCombatLockdown() and IsUsableSpell(SUMMON_RANDOM_FAVORITE_MOUNT_SPELL)
    if target == SUMMON_RANDOM_ID then
        return canSummon
    else
        return canSummon and (select(5, GetMountInfoByID(target)))
    end
end

function handler:SetTooltip(tip)
    local target                = self.ActionTarget
    if target == SUMMON_RANDOM_ID then
        return tip:SetSpellByID(SUMMON_RANDOM_FAVORITE_MOUNT_SPELL)
    else
        local _, spell = C_MountJournal.GetMountInfoByID(target)
        return tip:SetMountBySpellID(spell)
    end
end
