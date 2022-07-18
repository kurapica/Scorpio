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
class "VerticalLayoutManager"	(function(_ENV)
	extend "ILayoutManager"

    -----------------------------------------------------------
    --                       Property                        --
    -----------------------------------------------------------
    -- The vertical spacing
    property "VSpacing"         { type = Number, default = 0 }

    -- The top margin
    property "MarginTop"        { type = Number, default = 0 }

    -- The bottom margin
    property "MarginBottom"     { type = Number, default = 0 }

    -- The left margin
    property "MarginLeft"       { type = Number, default = 0 }

    -----------------------------------------------------------
    --                 Implementation method                 --
    -----------------------------------------------------------
    --- Refresh the layout of the target frame
    function RefreshLayout(self, frame, iter)
    	local totalHeight 		= self.MarginTop

    	for i, child in iter do
    		child:ClearAllPoints()
    		child:SetPoint("LEFT", self.MarginLeft)
    		child:SetPoint("TOP", - totalHeight)
    		totalHeight 		= totalHeight + child:GetHeight() + self.VSpacing
    	end

    	totalHeight 			= totalHeight + self.MarginBottom
    	frame:SetHeight(totalHeight)
    end
end)