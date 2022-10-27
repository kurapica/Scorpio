--========================================================--
--             Scorpio Vertical Layout Manager            --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2022/07/18                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Layout.VerticalLayoutManager""1.0.0"
--========================================================--

__Sealed__()
class "VerticalLayoutManager"   (function(_ENV)
    extend "ILayoutManager"

    -----------------------------------------------------------
    --                 Implementation method                 --
    -----------------------------------------------------------
    --- Refresh the layout of the target frame
    function RefreshLayout(self, frame, iter, padding)
        local minResize         = Style[frame].minResize
        local minHeight         = minResize and minResize.height or 0
        local totalHeight       = 0
        local prev
        local spacing           = padding and padding.top  or 0
        local showHide          = self.ShowHideChildren
        local fromTop           = self.BaseLineY ~= JustifyVType.BOTTOM -- From top to bottom
        local fromLeft          = self.BaseLineX == JustifyHType.LEFT   -- From left to right
        local fromRight         = self.BaseLineX == JustifyHType.RIGHT  -- From right to left

        for i, child, margin in iter do
            local offsetx       =  fromLeft  and ( (padding and padding.left  or 0) + (margin and margin.left  or 0) )
                                or fromRight and ( (padding and padding.right or 0) + (margin and margin.right or 0) )
                                or ( margin  and ( margin.left and - margin.left or margin.right) or 0  )
            local offsety       =  fromTop   and ( spacing + (margin and margin.top  or 0) ) or ( spacing + (margin and margin.bottom or 0) )

            child:ClearAllPoints()

            -- Y-axis
            if fromTop then
                if not prev then
                    child:SetPoint("TOP", 0, - offsety)
                else
                    child:SetPoint("TOP", prev, "BOTTOM", 0, - offsety)
                end
            else
                if not prev then
                    child:SetPoint("BOTTOM", 0, offsety)
                else
                    child:SetPoint("BOTTOM", prev, "TOP", 0, offsety)
                end
            end

            -- X-axis
            if fromLeft then
                child:SetPoint("LEFT", offsetx, 0)
            elseif fromRight then
                child:SetPoint("RIGHT", - offsetx, 0)
            else
                child:SetPoint("CENTER", offsetx, 0)
            end

            -- Stretching
            if not fromRight and margin and margin.right then
                child:SetPoint("RIGHT", - ((padding and padding.right or 0) + margin.right), 0)
            end
            if not fromLeft and margin and margin.left then
                child:SetPoint("LEFT", ((padding and padding.left or 0) + margin.left), 0)
            end

            if showHide and not child:IsShown() then
                showHide        = showHide == true and {} or showHide
                showHide[#showHide + 1] = child
            end

            totalHeight         = totalHeight + offsety + child:GetHeight()
            prev                = child
            spacing             = margin and margin[fromTop and "bottom" or "top"] or 0
        end

        totalHeight             = totalHeight + spacing + (padding and padding[fromTop and "bottom" or "top"] or 0)
        frame:SetHeight(math.max(totalHeight, minHeight))

        if type(showHide) == "table" then
            for i = 1, #showHide do
                showHide[i]:SetShown(true)
            end
        end
    end

    -----------------------------------------------------------
    --                       property                        --
    -----------------------------------------------------------
    --- Whether show the hidden children when re-layouted
    property "ShowHideChildren" { type = Boolean, default = false }

    --- The base axis of the axis-x
    property "BaseLineX"        { type = JustifyHType, default = JustifyHType.LEFT }

    --- The base line of the axis-y, MIDDLE is not supported
    property "BaseLineY"        { type = JustifyVType, default = JustifyVType.TOP }

    -----------------------------------------------------------
    --                      constructor                      --
    -----------------------------------------------------------
    __Arguments__{ Boolean/nil, Boolean/nil, JustifyHType/nil, JustifyVType/nil }
    function __ctor(self, includeHideChildren, showHideChildren, baselineX, baselineY)
        self.IncludeHideChildren= includeHideChildren
        self.ShowHideChildren   = showHideChildren
        self.BaseLineX          = baselineX
        self.BaseLineY          = baselineY
    end
end)