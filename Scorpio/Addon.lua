--========================================================--
--                Addon & Sub-Module System               --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/09/09                              --
--========================================================--

--========================================================--
Module            "Scorpio.Addon"                    "0.1.0"
--========================================================--

__Doc__[[The hook & secure hook provider]]
__Sealed__() interface "IModule" (function(_ENV)
    extend "ISystemEvent" "IHook" "ISlashCommand"

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    local function OnEventOrHook(self, event, ...)
        if type(self[event]) == "function" then
            return self[event](self, ...)
        end
    end

    ----------------------------------------------
    ------------------- Dispose ------------------
    ----------------------------------------------
    function Dispose(self)
        self.OnEvent = self.OnEvent - OnEventOrHook
        self.OnHook = self.OnHook - OnEventOrHook
    end

    ----------------------------------------------
    ----------------- Initializer ----------------
    ----------------------------------------------
    function IModule(self)
        -- Default event & hook handler
        self.OnEvent = self.OnEvent + OnEventOrHook
        self.OnHook = self.OnHook + OnEventOrHook
    end
end)