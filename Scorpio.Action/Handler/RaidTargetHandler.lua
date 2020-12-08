-- Author      : Kurapica
-- Create Date : 2017/11/29
-- Change Log  :

-- Check Version
local version = 1
if not IGAS:NewAddon("IGAS.Widget.Action.RaidTargetHandler", version) then
	return
end

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

handler = ActionTypeHandler {
	Name = "raidtarget",

	DragStyle = "Block",

	ReceiveStyle = "Block",

	PreClickSnippet = [=[
		self:GetFrameRef("IFActionHandler_Manager"):RunFor(self, [[ Manager:CallMethod("SetRaidTargetForTarget", self:GetAttribute("raidtarget")) ]])
	]=]
}

IGAS:GetUI(handler.Manager).SetRaidTargetForTarget = function (self, id)
	SetRaidTarget("target", tonumber(id) or 0)
end

-- Overwrite methods
function handler:GetActionTexture()
	return _RaidTargetTextureMap[self.ActionTarget]
end

-- Part-interface definition
interface "IFActionHandler"
	__Doc__[[The raidtarget index]]
	property "RaidTarget" {
		Get = function(self)
			return self:GetAttribute("actiontype") == "raidtarget" and self:GetAttribute("raidtarget")
		end,
		Set = function(self, value)
			self:SetAction("raidtarget", value)
		end,
		Type = Number,
	}
endinterface "IFActionHandler"