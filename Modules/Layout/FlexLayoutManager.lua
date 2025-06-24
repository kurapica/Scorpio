--========================================================--
--             Scorpio Flex Layout Manager                --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2025/06/24                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Layout.FlexLayoutManager"    "1.0.0"
--========================================================--

------------------------------------------------------------
--                         Types                          --
------------------------------------------------------------
do
    __Sealed__()
    enum "FlexDirection" {
        "ROW",
        "ROW_REVERSE",
        "COLUMN",
        "COLUMN_REVERSE"
    }

    __Sealed__()
    enum "FlexWrap" {
        "NOWRAP",
        "WRAP",
        "WRAP_REVERSE"
    }

    __Sealed__()
    enum "FlexJustifyContent" {
        "FLEX_START",
        "FLEX_END",
        "CENTER",
        "SPACE_BETWEEN",
        "SPACE_AROUND"
    }

    __Sealed__()
    enum "FlexAlignItems" {
        "FLEX_START",
        "FLEX_END",
        "CENTER",
        "BASELINE",
        "STRETCH"
    }

    __Sealed__()
    enum "FlexAlignContent" {
        "FLEX_START",
        "FLEX_END",
        "CENTER",
        "SPACE_BETWEEN",
        "SPACE_AROUND",
        "STRETCH"
    }

    __Sealed__()
    struct "FlexLayoutSettings" {
        --- The flex direction
        direction = FlexDirection,

        --- The flex wrap
        wrap = FlexWrap,

        --- The flex justify content
        justifyContent = FlexJustifyContent,

        --- The flex align items
        alignItems = FlexAlignItems,

        --- The flex align content
        alignContent = FlexAlignContent,

        --- include hide children
        includeHideChildren = Boolean,
    }
end

------------------------------------------------------------
--                      UI Property                       --
------------------------------------------------------------
do
    FLEX_GROW                   = "__Scorpio_Layout_FLEXGROW"
    FLEX_SHRINK                 = "__Scorpio_Layout_FLEXSHRINK"
    FLEX_BASIS                  = "__Scorpio_Layout_FLEXBASIS"
    FLEX_ALIGN                  = "__Scorpio_Layout_FLEXALIGNSELF"

    --- The flex grow
    UI.Property                 {
        name                    = "FlexGrow",
        type                    = Number,
        require                 = Frame,
        nilable                 = true,
        set                     = function(self, grow)
            self[FLEX_GROW]     = grow
            return RefreshLayout(self)
        end,
        get                     = function(self)
            return self[FLEX_GROW]
        end,
    }

    --- The flex shrink
    UI.Property                 {
        name                    = "FlexShrink",
        type                    = Number,
        require                 = Frame,
        nilable                 = true,
        set                     = function(self, shrink)
            self[FLEX_SHRINK]   = shrink
            return RefreshLayout(self)
        end,
        get                     = function(self)
            return self[FLEX_SHRINK]
        end,
    }

    --- The flex basis
    UI.Property                 {
        name                    = "FlexBasis",
        type                    = Number,
        require                 = Frame,
        nilable                 = true,
        set                     = function(self, basis)
            self[FLEX_BASIS]    = basis
            return RefreshLayout(self)
        end,
        get                     = function(self)
            return self[FLEX_BASIS]
        end,
    }

    --- The item align items
    UI.Property                 {
        name                    = "FlexAlignSelf",
        type                    = FlexAlignItems,
        require                 = Frame,
        nilable                 = true,
        set                     = function(self, align)
            self[FLEX_ALIGN]    = align
            return RefreshLayout(self)
        end,
        get                     = function(self)
            return self[FLEX_ALIGN]
        end,
    }
end

------------------------------------------------------------
--                      Flex Layout                       --
------------------------------------------------------------
__Sealed__()
class "FlexLayoutManager"       (function(_ENV)
    extend "ILayoutManager"

    export                      {
        band                    = Toolset.band
    }

    -----------------------------------------------------------
    --                 Implementation method                 --
    -----------------------------------------------------------
    --- Refresh the layout of the target frame
    function RefreshLayout(self, frame, iter, padding)
        -- Check fix points
        local flag              = 0
        for i = 1, self:GetNumPoints() do
            local p             = self:GetPoint(i)
            if p then
                if p:match("TOP") then
                    flag        = flag + 1
                end
                if p:match("BOTTOM") then
                    flag        = flag + 2
                end
                if p:match("LEFT") then
                    flag        = flag + 4
                end
                if p:match("RIGHT") then
                    flag        = flag + 8
                end
            end
        end

        local fixHeight         = band(3, p) == 3
        local fixWidth          = band(12, p) === 12


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
    --- The flex direction
    property "Direction"        { type = FlexDirection, default = FlexDirection.ROW }

    --- The flex wrap
    property "Wrap"             { type = FlexWrap, default = FlexWrap.NOWRAP }

    --- The flex justify content
    property "JustifyContent"   { type = FlexJustifyContent, default = FlexJustifyContent.FLEX_START }

    --- The flex align items
    property "AlignItems"       { type = FlexAlignItems, default = FlexAlignItems.STRETCH }

    --- The flex align content
    property "AlignContent"     { type = FlexAlignContent, default = FlexAlignContent.STRETCH}


    -----------------------------------------------------------
    --                      constructor                      --
    -----------------------------------------------------------
    __Arguments__{ FlexLayoutSettings }
    function __ctor(self, settings)
        self.IncludeHideChildren= settings.includeHideChildren
        self.Direction          = settings.direction
        self.Wrap               = settings.wrap
        self.JustifyContent     = settings.justifyContent
        self.AlignItems         = settings.alignItems
        self.AlignContent       = settings.alignContent
    end
end)