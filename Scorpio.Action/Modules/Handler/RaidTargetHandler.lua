--========================================================--
--             Scorpio Secure Raid Target Handler         --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.RaidTargetHandler"    "1.0.0"
--========================================================--

------------------------------------------------------
-- Action Handler
------------------------------------------------------
handler                         = ActionTypeHandler {
    Name                        = "raidtarget",
    DragStyle                   = "Block",
    ReceiveStyle                = "Block",
    PreClickSnippet             = [=[
        self:GetFrameRef("_Manager"):RunFor(self, [[ Manager:CallMethod("SetRaidTargetForTarget", self:GetAttribute("raidtarget")) ]])
    ]=]
}

------------------------------------------------------
-- Manager Init
------------------------------------------------------
_RaidTargetTextureMap = {
    [0] = [[Interface\Buttons\UI-GroupLoot-Pass-Up]],
    [1] = [[Interface\TargetingFrame\UI-RaidTargetingIcon_1]],
    [2] = [[Interface\TargetingFrame\UI-RaidTargetingIcon_2]],
    [3] = [[Interface\TargetingFrame\UI-RaidTargetingIcon_3]],
    [4] = [[Interface\TargetingFrame\UI-RaidTargetingIcon_4]],
    [5] = [[Interface\TargetingFrame\UI-RaidTargetingIcon_5]],
    [6] = [[Interface\TargetingFrame\UI-RaidTargetingIcon_6]],
    [7] = [[Interface\TargetingFrame\UI-RaidTargetingIcon_7]],
    [8] = [[Interface\TargetingFrame\UI-RaidTargetingIcon_8]],
}

__SecureMethod__()
function handler.Manager:SetRaidTargetForTarget(id)
    return SetRaidTarget("target", tonumber(id) or 0)
end

------------------------------------------------------
-- Overwrite methods
------------------------------------------------------
function handler:GetActionTexture()
    return _RaidTargetTextureMap[self.ActionTarget]
end

------------------------------------------------------
-- Extend Definitions
------------------------------------------------------
class "SecureActionButton" (function(_ENV)
    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    --- The raidtarget index
    property "RaidTarget" {
        type                    = Number,
        set                     = function(self, value) self:SetAction("raidtarget", value) end,
        get                     = function(self) return self:GetAttribute("actiontype") == "raidtarget" and self:GetAttribute("raidtarget") end,
    }
end)