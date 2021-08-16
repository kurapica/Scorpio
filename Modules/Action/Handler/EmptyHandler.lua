--========================================================--
--             Scorpio Secure Empty Handler              --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/03/29                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Secure.EmptyHandler"         "1.0.0"
--========================================================--

_Enabled                        = false

------------------------------------------------------
-- Action Handler
-----------------------------------------------------
handler 						= ActionTypeHandler {
	Name 						= "empty",
	DragStyle 					= "Block",
	ReceiveStyle 				= "Clear",
}

------------------------------------------------------
-- Overwrite methods
------------------------------------------------------
function handler:HasAction()
	return false
end
