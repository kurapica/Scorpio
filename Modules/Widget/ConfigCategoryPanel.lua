--========================================================--
--             Scorpio Config Category Panel              --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/02/04                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Widget.ConfigCategoryPanel"  "1.0.0"
--========================================================--

--- The category panel to hold the config panel with scroll frame
__Sealed__()
class "ConfigCategoryPanel"     (function(_ENV)
    inherit "FauxScrollFrame"

    ----------------------------------------------
    --                  Method                  --
    ----------------------------------------------
    --- This method will run when the player clicks "okay" in the Interface Options.
    function okay(self)
        self:GetChild("ScrollChild"):Commit()
    end

    --- This method will run when the player clicks "cancel" in the Interface Options.
    function cancel(self)
        self:GetChild("ScrollChild"):Rollback()
    end

    --- This method will run when the player clicks "defaults".
    function default(self)
        self:GetChild("ScrollChild"):Reset()
    end

    --- This method will run when the Interface Options frame calls its OnShow function and after defaults
    __AsyncSingle__()
    function refresh(self)
        -- Only continue when it's visible
        if not self:IsVisible() then
            Next(Observable.From(self.OnShow))
        end

        -- Rendering and record current value
        return self:GetChild("ScrollChild"):Begin()
    end

    ----------------------------------------------
    --               Constructor                --
    ----------------------------------------------
    __Template__{
        ScrollChild 			= ConfigPanel
    }
    function __ctor(self, name, parent, node, cateName, cateParent, showAllSubNodes)
        self.name               = cateName
        self.parent             = cateParent

        local panel             = self:GetChild("ScrollChild")
        panel.ConfigNode        = node
        panel.ShowAllSubNodes   = showAllSubNodes

        return InterfaceOptions_AddCategory(self)
    end

    __Arguments__{ NEString, UI, ConfigNode, NEString, NEString/nil, Boolean/nil }
    function __new(_, name, parent, node, cateName, cateParent, showAllSubNodes)
        return CreateFrame("Frame", nil, parent)
    end
end)

------------------------------------------------------
-- Default Style
------------------------------------------------------
Style.UpdateSkin("Default",     {
    [ConfigCategoryPanel]       = {
        location            	= {
            Anchor("TOPLEFT", 0, -8),
            Anchor("BOTTOMRIGHT", -32, 8)
        },
        scrollBarHideable   	= true,
    }
})
