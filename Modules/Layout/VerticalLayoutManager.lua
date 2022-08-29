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

    -- single instance
    local instance

    -----------------------------------------------------------
    --                 Implementation method                 --
    -----------------------------------------------------------
    --- Refresh the layout of the target frame
    function RefreshLayout(self, frame, iter, padding)
        local _, minHeight      = self:GetMinResize()
        local totalHeight       = 0
        local prev
        local spacing           = padding and padding.top  or 0

        for i, child, margin in iter do
            local offsetx       = (padding and padding.left or 0) + (margin and margin.left or 0)
            local offsety       = spacing + (margin and margin.top  or 0)

            child:ClearAllPoints()

            if not prev then
                child:SetPoint("TOP", 0, - offsety)
            else
                child:SetPoint("TOP", prev, "BOTTOM", 0, - offsety)
            end

            child:SetPoint("LEFT", offsetx, 0)

            if margin and margin.right then
                child:SetPoint("RIGHT", - ((padding and padding.right or 0) + margin.right), 0)
            end

            totalHeight         = totalHeight + offsety + child:GetHeight()
            prev                = child
            spacing             = margin and margin.bottom or 0
        end

        totalHeight             = totalHeight + (padding and padding.bottom or 0)
        frame:SetHeight(math.max(totalHeight, minHeight or 0))
    end

    -----------------------------------------------------------
    --                      constructor                      --
    -----------------------------------------------------------
    function __ctor(self)
        instance                = instance
    end

    function __exist(_)
        return instance
    end
end)