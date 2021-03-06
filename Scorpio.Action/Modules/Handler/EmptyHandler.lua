-- Author      : Kurapica
-- Create Date : 2013/11/25
-- Change Log  :

-- Check Version
local version = 1
if not IGAS:NewAddon("IGAS.Widget.Action.EmptyHandler", version) then
	return
end

handler = ActionTypeHandler {
	Name = "empty",
	DragStyle = "Block",
	ReceiveStyle = "Clear",
}

function handler:HasAction()
	return false
end
