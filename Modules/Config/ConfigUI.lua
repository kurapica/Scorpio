--========================================================--
--                Scorpio SavedVariable Config UI System  --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2022/06/25                              --
--========================================================--

--========================================================--
Scorpio            "Scorpio.Config.UI"               "1.0.0"
--========================================================--

local _PanelCount               = 0
local _AddonMap                 = {}
local _PanelMap                 = {}
local _ConfigNode               = {}

------------------------------------------------------
-- Config UI Panel
------------------------------------------------------
__Sealed__()
class "ConfigPanel"             (function(_ENV)
    inherit "Frame"

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
        local node              = _ConfigNode[self]

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

    __Arguments__{ NEString, UI, Scorpio, ConfigNode, NEString/nil, NEString/nil }
    function __new(_, name, parent, addon, node, cateName, cateParent)
        if _PanelMap[node] then
            throw("The node already has a config panel binded")
        end

        local frame             = CreateFrame("Frame", nil, parent)
        _AddonMap[frame]        = addon
        _ConfigNode[frame]      = node
        _PanelMap[node]         = frame
        frame.name              = cateName
        frame.parent            = cateParent
        return frame
    end
end)

------------------------------------------------------
-- Scorpio Extension
------------------------------------------------------
class "Scorpio" (function(_ENV)
    --- Start using the category panel for the adon
    function UseCategoryPanel(self)
        _PanelCount             = _PanelCount + 1
        ConfigPanel("Scorpio_Config_Node_Panel_" .. _PanelCount, InterfaceOptionsFrame, self._Addon, self._Config, self._Addon._Name)
        return self
    end

    --- Bind the config to a sub category panel
    __Arguments__{ NEString, ConfigNode }:Throwable()
    function UseSubCategoryPanel(self, name, node)
        if not _PanelMap[self._Addon._Config] then
            throw("Usage: Scorpio:UseSubCategoryPanel(name, configNode) - The Scorpio:UseCategoryPanel() must be called first")
        end

        _PanelCount             = _PanelCount + 1
        ConfigPanel("Scorpio_Config_Node_Panel_" .. _PanelCount, InterfaceOptionsFrame, self._Addon, node, name, self._Addon._Name)
        return self
    end

    --- Show the config UI panel for the addon
    __Async__()
    function ShowConfigUI(self)
        if InCombatLockdown() then return end

        InterfaceOptionsFrame_OpenToCategory(self._Name)
        Next() -- Make sure open to the category
        InterfaceOptionsFrame_OpenToCategory(self._Name)
    end
end)

------------------------------------------------------
-- Config Style
------------------------------------------------------
Style.UpdateSkin("Default",     {
    [ConfigPanel]               = {
        ScrollFrame             = {
            location            = {
                Anchor("TOPLEFT", 0, -8),
                Anchor("BOTTOMRIGHT", - 32, 8)
            },
            scrollBarHideable   = true,

            ScrollChild         = {
                layoutManager   = ConfigLayoutManager()
            },
        }
    }
})
