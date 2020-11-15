--========================================================--
--             Scorpio Element Panel                      --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/11/12                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Widget.ElementPanel"      "1.0.0"
--========================================================--

-----------------------------------------------------------
--                 Element Panel Widget                  --
-----------------------------------------------------------
__Sealed__() class "ElementPanel" (function(_ENV)
    inherit "Frame" extend "ICountable"

    local function adjustElement(element, self)
        local id                = element.ID
        if not id then return end

        element:SetSize(self.ElementWidth, self.ElementHeight)

        local posX              = (self.Orientation == Orientation.HORIZONTAL and (id - 1) % self.ColumnCount or floor((id - 1) / self.RowCount)) * (self.ElementWidth + self.HSpacing)
        local posY              = (self.Orientation == Orientation.HORIZONTAL and floor((id - 1) / self.ColumnCount) or (id - 1) % self.RowCount) * (self.ElementHeight + self.VSpacing)

        element:ClearAllPoints()

        if self.TopToBottom then
            element:SetPoint("TOP", 0, - posY - self.MarginTop)
        else
            element:SetPoint("BOTTOM", 0, posY + self.MarginBottom)
        end

        if self.LeftToRight then
            element:SetPoint("LEFT", posX + self.MarginLeft, 0)
        else
            element:SetPoint("RIGHT", - posX - self.MarginRight, 0)
        end
    end

    local function adjustPanel(self)
        if self.KeepMaxSize then
            self:SetSize(
                self.ColumnCount * self.ElementWidth  + (self.ColumnCount - 1) * self.HSpacing + self.MarginLeft + self.MarginRight,
                self.RowCount    * self.ElementHeight + (self.RowCount    - 1) * self.VSpacing + self.MarginTop  + self.MarginBottom
            )
        elseif self.AutoSize then
            local i             = self.Count

            while i > 0 do
                if self:GetChild(self.ElementPrefix .. i):IsShown() then
                    break
                end
                i               = i - 1
            end

            local row
            local column

            if self.Orientation == Orientation.HORIZONTAL then
                row             = ceil(i / self.ColumnCount)
                column          = row == 1 and i or self.ColumnCount
            else
                column          = ceil(i / self.RowCount)
                row             = column == 1 and i or self.RowCount
            end

            if self.KeepColumnSize then
                column          = self.ColumnCount
                if row == 0 then row = 1 end
            end
            if self.KeepRowSize then
                row             = self.RowCount
                if column == 0 then column = 1 end
            end

            if row > 0 and column > 0 then
                self:SetSize(
                    column * self.ElementWidth + (column - 1) * self.HSpacing + self.MarginLeft + self.MarginRight,
                    row * self.ElementHeight + (row - 1) * self.VSpacing + self.MarginTop + self.MarginBottom
                )
            else
                self:SetSize(1, 1)
            end
        end
    end

    local function reduce(self, index)
        index                   = index or self.RowCount * self.ColumnCount

        if index < self.Count then
            for i = self.Count, index + 1, -1 do
                local ele       = self:GetChild(self.ElementPrefix .. i)

                -- still keep them to be re-use
                ele:ClearAllPoints()
                ele:Hide()

                OnElementRemove(self, ele)

                self.__ElementPanel_Count = i - 1
            end

            return adjustPanel(self)
        end
    end

    local function generate(self, index)
        if self.ElementType and index > self.Count then
            local ele

            for i = self.Count + 1, index do
                local ele       = self:GetChild(self.ElementPrefix .. i) or self.ElementType(self.ElementPrefix .. i, self)
                ele.ID          = i
                ele:Show()

                adjustElement(ele, self)
                OnElementAdd(self, ele)

                self.__ElementPanel_Count = i
            end

            return adjustPanel(self)
        end
    end

    local function nextItem(self, index)
        index                   = index + 1
        local ele               = self:GetChild(self.ElementPrefix .. index)
        if ele then return index, ele end
    end

    ------------------------------------------------------
    -- Event
    ------------------------------------------------------
    -- Fired when an element is added
    event "OnElementAdd"

    -- Fired when an element is removed
    event "OnElementRemove"

    ------------------------------------------------------
    -- Method
    ------------------------------------------------------
    function GetIterator(self, key)
        return nextItem, self, tonumber(key) or 0
    end

    __AsyncSingle__()
    function Refresh(self)
        Next()
        reduce(self)
        self:Each(adjustElement, self)

        local autoSize          = self.AutoSize
        self.AutoSize           = true
        adjustPanel(self)
        self.AutoSize           = autoSize
    end

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    -- The Element accessor, used like obj.Element[i].
    __Indexer__(NaturalNumber)
    property "Elements"         {
        get                     = function(self, index)
            if index >= 1 and index <= self.ColumnCount * self.RowCount then

                if self:GetChild(self.ElementPrefix .. index) then return self:GetChild(self.ElementPrefix .. index) end

                if self.ElementType then
                    generate(self, index)

                    return self:GetChild(self.ElementPrefix .. index)
                else
                    return nil
                end
            end
        end,
    }

    -- The columns's count
    property "ColumnCount"      { type = PositiveNumber, default = 8, handler = Refresh }

    -- The row's count
    property "RowCount"         { type = PositiveNumber, default = 8, handler = Refresh }

    -- The elements's max count
    property "MaxCount"         { Get = function(self) return self.ColumnCount * self.RowCount end }

    -- The element's width
    property "ElementWidth"     { type = PositiveNumber, default = 16, handler = Refresh }

    -- The element's height
    property "ElementHeight"    { type = PositiveNumber, default = 16, handler = Refresh }

    -- The element's count
    property "Count"            {
        type                    = NaturalNumber,
        field                   = "__ElementPanel_Count",
        set                     = function(self, cnt)
            if cnt > self.RowCount * self.ColumnCount then
                error("Count can't be more than "..self.RowCount * self.ColumnCount, 2)
            end

            if cnt > self.Count then
                if self.ElementType then
                    generate(self, cnt)
                else
                    error("ElementType not set.", 2)
                end
            elseif cnt < self.Count then
                reduce(self, cnt)
            end
        end,
    }

    -- The orientation for elements
    property "Orientation"      { type = Orientation, default = Orientation.HORIZONTAL, handler = Refresh }

    -- Whether the elements start from left to right
    property "LeftToRight"      { type = Boolean, default = true, handler = Refresh }

    -- Whether the elements start from top to bottom
    property "TopToBottom"      { type = Boolean, default = true, handler = Refresh }

    -- The element's type
    property "ElementType"      { type = Class }

    -- The horizontal spacing
    property "HSpacing"         { type = Number, handler = Refresh }

    -- The vertical spacing
    property "VSpacing"         { type = Number, handler = Refresh }

    -- Whether the elementPanel is autosize
    property "AutoSize"         { type = Boolean }

    -- The top margin
    property "MarginTop"        { type = Number, handler = Refresh }

    -- The bottom margin
    property "MarginBottom"     { type = Number, handler = Refresh }

    -- The left margin
    property "MarginLeft"       { type = Number, handler = Refresh }

    -- The right margin
    property "MarginRight"      { type = Number, handler = Refresh }

    -- The prefix for the element's name
    property "ElementPrefix"    { type = String, default = "Element" }

    -- Whether the elementPanel should keep it's max size
    property "KeepMaxSize"      { type = Boolean, handler = Refresh }

    -- Whether keep the max size for columns
    property "KeepColumnSize"   { type = Boolean, handler = Refresh }

    -- Whether keep the max size for rows
    property "KeepRowSize"      { type = Boolean, handler = Refresh }
end)