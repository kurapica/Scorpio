--========================================================--
--                Scorpio.ISavedVariableManager           --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/10/18                              --
--========================================================--

--========================================================--
Module            "Scorpio.ISavedVariableManager"    "1.0.0"
--========================================================--

__Doc__[[The saved variable manager]]
__Sealed__() interface "ISavedVariableManager" (function(_ENV)

    ----------------------------------------------
    ------------------- Helper -------------------
    ----------------------------------------------
    local _G = _G

    ----------------------------------------------
    ------------------- Event  -------------------
    ----------------------------------------------

    ----------------------------------------------
    ------------------- Method -------------------
    ----------------------------------------------
    __Doc__[[
        <desc>Get the saved variables, the operation should be done when the addon is loaded</desc>
        <param name="name" type="string">the saved variable's name</param>
        <param name="type" type="System.Serialization.SerializableType" optional="true">The saved variable's type</param>
        <return>The saved variable</return>
    ]]
    __Arguments__{ String, Argument(SerializableType, true) }
    function GetSavedVariable(self, name, type)
        local sv = _G[name] or {}

        return sv
    end

    ----------------------------------------------
    ------------------- Dispose ------------------
    ----------------------------------------------
end)