--========================================================--
--                Scorpio SavedVariable Config UI System  --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2022/06/25                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio.Config.UI"               "1.0.0"
--========================================================--

------------------------------------------------------
-- Config UI Panel
------------------------------------------------------
__Sealed__()
class "AddonConfigPanel"        (function(_ENV)
    inherit "Frame"

    local _AddonConfigNode      = {}

    ----------------------------------------------
    --                 Property                 --
    ----------------------------------------------
    --- The panel name
    property "name"             { get = function(self) return _AddonConfigNode[self]._Addon._Name end }

    --- The parent panel name
    property "parent"           { get = function() end }

    ----------------------------------------------
    --                  Method                  --
    ----------------------------------------------
    --- This method will run when the player clicks "okay" in the Interface Options.
    function okay(self)
        print("okay")
    end

    --- This method will run when the player clicks "cancel" in the Interface Options.
    function cancel(self)
        print("cancel")
    end

    --- This method will run when the player clicks "defaults".
    function default(self)
        print("default")
    end

    --- This method will run when the Interface Options frame calls its OnShow function and after defaults
    function refresh(self)
        print("refresh")
    end

    ----------------------------------------------
    --               Constructor                --
    ----------------------------------------------
    __Template__{
        ScrollFrame             = FauxScrollFrame
    }
    function __ctor(self)
        return InterfaceOptions_AddCategory(self)
    end

    __Arguments__{ NEString, UI, AddonConfigNode }
    function __new(_, name, parent, node)
        local frame             = CreateFrame("Frame", nil, parent)
        _AddonConfigNode[frame] = node
        return frame
    end
end)

------------------------------------------------------
-- Scorpio Extension
------------------------------------------------------
--- Show the config UI panel for the addon
function Scorpio:ShowConfigUI()
    InterfaceOptionsFrame_OpenToCategory(self._Name)
end

------------------------------------------------------
-- Config Style
------------------------------------------------------
Style.UpdateSkin("Default",     {
    [AddonConfigPanel]          = {
        ScrollFrame             = {
            location            = {
                Anchor("TOPLEFT", 0, -8),
                Anchor("BOTTOMRIGHT", - 32, 8)
            },
            scrollBarHideable   = true
        }
    }
})