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
        local width             = frame:GetWidth()

        for i, child, margin in iter do
            local left          = margin and margin.left or 0
            if left > 0 and left < 1 then -- as percent
                left            = width * left
            end

            local offsetx       = (padding and padding.left or 0) + left
            local offsety       = spacing + (margin and margin.top  or 0)

            child:ClearAllPoints()

            if not prev then
                child:SetPoint("TOP", 0, - offsety)
            else
                child:SetPoint("TOP", prev, "BOTTOM", 0, - offsety)
            end

            child:SetPoint("LEFT", offsetx, 0)

            if margin and margin.right then
                local right     = margin.right
                if right > 0 and right < 1 then
                    right       = width * right
                end
                child:SetPoint("RIGHT", - ((padding and padding.right or 0) + right), 0)
            end
            if showHide and not child:IsShown() then
                showHide        = showHide == true and {} or showHide
                showHide[#showHide + 1] = child
            end

            totalHeight         = totalHeight + offsety + child:GetHeight()
            prev                = child
            spacing             = margin and margin.bottom or 0
        end

        totalHeight             = math.max(totalHeight + spacing + (padding and padding.bottom or 0), minHeight or 0)
        if math.abs(frame:GetHeight() - totalHeight) > 10 then
            frame:SetHeight(math.max(totalHeight, minHeight or 0))
        end

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

    -----------------------------------------------------------
    --                      constructor                      --
    -----------------------------------------------------------
    __Arguments__{ Boolean/nil, Boolean/nil }
    function __ctor(self, includeHideChildren, showHideChildren)
        self.IncludeHideChildren= includeHideChildren
        self.ShowHideChildren   = showHideChildren
    end
end)