-- Author      : Kurapica
-- Create Date : 2013/11/25
-- Change Log  :

-- Check Version
local version = 1
if not IGAS:NewAddon("IGAS.Widget.Action.CustomHandler", version) then
	return
end

_Enabled = false

handler = ActionTypeHandler {
	Name = "custom",

	DragStyle = "Block",

	ReceiveStyle = "Block",

	OnEnableChanged = function(self) _Enabled = self.Enabled end,
}

-- Overwrite methods
function handler:GetActionText()
	return self.CustomText
end

function handler:GetActionTexture()
	return self.CustomTexture
end

function handler:SetTooltip(GameTooltip)
	if self.CustomTooltip then
		GameTooltip:SetText(self.CustomTooltip)
	end
end

-- Part-interface definition
interface "IFActionHandler"
	local old_SetAction = IFActionHandler.SetAction

	function SetAction(self, kind, target, ...)
		if kind == "custom" then
			self:SetAttribute("_custom", target)
			target = "_"
		end

		return old_SetAction(self, kind, target, ...)
	end

	__Doc__[[The custom action]]
	property "Custom" {
		Get = function(self)
			return self:GetAttribute("actiontype") == "custom" and self.custom or self:GetAttribute("custom") or nil
		end,
		Set = function(self, value)
			self:SetAction("custom", value)
		end,
		--Type = StringFunction,
	}

	__Doc__[[The custom text]]
	property "CustomText" { Type = String }

	__Doc__[[The custom texture path]]
	__Handler__("Refresh")
	property "CustomTexture" { Type = String + Number }

	__Doc__[[The custom tooltip]]
	property "CustomTooltip" { Type = String }
endinterface "IFActionHandler"