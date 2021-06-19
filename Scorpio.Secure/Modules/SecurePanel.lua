--========================================================--
--             Scorpio Secure Element Panel               --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/11/12                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.Secure.SecurePanel"       "1.0.0"
--========================================================--

-----------------------------------------------------------
--              Secure Element Panel Widget              --
-----------------------------------------------------------
__Sealed__()
class "SecurePanel" (function(_ENV)
    inherit "SecureFrame" extend "ICountable"

    -------------------------------------
    -- Secure Manager
    -------------------------------------
    -- Manager Frame
    _ManagerFrame               = SecureFrame("Scorpio_SecurePanel_LayoutMananger", UIParent, "SecureHandlerStateTemplate")
    _ManagerFrame:Hide()

    _ManagerFrame:Execute[[
        Manager = self

        _Panels = newtable()
        _Cache  = newtable()
        _Map    = newtable()

        _Queue  = newtable()

        QueueUpdatePanel = [=[
            local panel     = _Map[self] or self
            local noForce= ...

            if not noForce then
                _Queue[panel] = false
            elseif _Queue[panel] == nil then
                _Queue[panel] = true
            end

            -- Reset the timer
            Manager:SetAttribute("state-timer", "reset")
        ]=]

        UnQueueUpdatePanel = [=[
            local panel     = _Map[self] or self
            _Queue[panel]   = nil
        ]=]

        UpdatePanelSize = [=[
            local noForce   = ...
            local panel     = _Map[self] or self
            local elements  = _Panels[panel]
            local count     = 0

            local row
            local column
            local columnCount   = panel:GetAttribute("IFSecurePanel_ColumnCount") or 5
            local rowCount      = panel:GetAttribute("IFSecurePanel_RowCount") or 5
            local elementWidth  = panel:GetAttribute("IFSecurePanel_ElementWidth") or 16
            local elementHeight = panel:GetAttribute("IFSecurePanel_ElementHeight") or 16
            local hSpacing      = panel:GetAttribute("IFSecurePanel_HSpacing") or 0
            local vSpacing      = panel:GetAttribute("IFSecurePanel_VSpacing") or 0
            local marginTop     = panel:GetAttribute("IFSecurePanel_MarginTop") or 0
            local marginBottom  = panel:GetAttribute("IFSecurePanel_MarginBottom") or 0
            local marginLeft    = panel:GetAttribute("IFSecurePanel_MarginLeft") or 0
            local marginRight   = panel:GetAttribute("IFSecurePanel_MarginRight") or 0
            local orientation   = panel:GetAttribute("IFSecurePanel_Orientation") or "HORIZONTAL"
            local leftToRight   = panel:GetAttribute("IFSecurePanel_LeftToRight")
            local topToBottom   = panel:GetAttribute("IFSecurePanel_TopToBottom")
            local autoPos       = panel:GetAttribute("IFSecurePanel_AutoPosition")

            if leftToRight == nil then leftToRight = true end
            if topToBottom == nil then topToBottom = true end

            if elements then
                for i = 1, #elements do
                    local frm = elements[i]

                    frm:SetWidth(elementWidth)
                    frm:SetHeight(elementHeight)

                    if not autoPos or frm:IsShown() then
                        local posX = (orientation == "HORIZONTAL" and count % columnCount or floor(count / rowCount)) * (elementWidth + hSpacing)
                        local posY = (orientation == "HORIZONTAL" and floor(count / columnCount) or count % rowCount) * (elementHeight + vSpacing)

                        frm:ClearAllPoints()

                        if topToBottom then
                            frm:SetPoint("TOP", panel, "TOP", 0, - posY - marginTop)
                        else
                            frm:SetPoint("BOTTOM", panel, "BOTTOM", 0, posY + marginBottom)
                        end

                        if leftToRight then
                            frm:SetPoint("LEFT", panel, "LEFT", posX + marginLeft, 0)
                        else
                            frm:SetPoint("RIGHT", panel, "RIGHT", - posX - marginRight, 0)
                        end

                        count = count + 1
                    end
                end
            end

            if not panel:GetAttribute("IFSecurePanel_KeepMaxSize") then
                if not noForce or panel:GetAttribute("IFSecurePanel_AutoSize") then
                    if count ~= _Cache[panel] then
                        _Cache[panel] = count

                        if orientation == "HORIZONTAL" then
                            row = ceil(count / columnCount)
                            column = row == 1 and count or columnCount
                        else
                            column = ceil(count / rowCount)
                            row = column == 1 and count or rowCount
                        end

                        if panel:GetAttribute("IFSecurePanel_KeepColumnSize") then
                            column = columnCount
                            if row == 0 then row = 1 end
                        end
                        if panel:GetAttribute("IFSecurePanel_KeepRowSize") then
                            row = rowCount
                            if column == 0 then column = 1 end
                        end

                        if row > 0 and column > 0 then
                            panel:SetWidth(column * elementWidth + (column - 1) * hSpacing + marginLeft + marginRight)
                            panel:SetHeight(row * elementHeight + (row - 1) * vSpacing + marginTop + marginBottom)
                        else
                            panel:SetWidth(1)
                            panel:SetHeight(1)
                        end
                    end
                end
            else
                panel:SetWidth(columnCount * elementWidth + (columnCount - 1) * hSpacing + marginLeft + marginRight)
                panel:SetHeight(rowCount * elementHeight + (rowCount - 1) * vSpacing + marginTop + marginBottom)
            end
        ]=]
    ]]

    -- The condition has no real use, just a timer ticker
    _ManagerFrame:SetAttribute("_onstate-timer", [=[
        if newstate ~= "reset" then
            for obj, noForce in pairs(_Queue) do
                Manager:RunFor(obj, UpdatePanelSize, noForce)
            end

            wipe(_Queue)
        end
    ]=])
    _ManagerFrame:RegisterStateDriver("timer", "[pet]pet;nopet;")

    _RegisterPanel              = [=[
        local panel = Manager:GetFrameRef("SecurePanel")

        if panel and not _Panels[panel] then
            _Panels[panel] = newtable()
        end
    ]=]

    _UnregisterPanel            = [=[
        local panel = Manager:GetFrameRef("SecurePanel")

        if panel then
            _Panels[panel] = nil
            _Cache[panel] = nil
        end
    ]=]

    _RegisterFrame              = [=[
        local panel = Manager:GetFrameRef("SecurePanel")
        local frame = Manager:GetFrameRef("SecureElement")

        if panel and frame then
            _Panels[panel] = _Panels[panel] or newtable()
            tinsert(_Panels[panel], frame)

            _Map[frame] = panel
        end
    ]=]

    _UnregisterFrame            = [=[
        local panel = Manager:GetFrameRef("SecurePanel")
        local frame = Manager:GetFrameRef("SecureElement")

        _Map[frame] = nil

        if panel and frame and _Panels[panel] then
            for k, v in ipairs(_Panels[panel]) do
                if v == frame then
                    return tremove(_Panels[panel], k)
                end
            end
        end
    ]=]

    _WrapShow                   = [[
        Manager:RunFor(self, QueueUpdatePanel, true)
    ]]

    _WrapHide                   = [[
        Manager:RunFor(self, QueueUpdatePanel, true)
    ]]

    _UpdatePanelSize            = [=[
        local panel = Manager:GetFrameRef("SecurePanel")

        _Cache[panel] = nil
        Manager:RunFor(panel, QueueUpdatePanel)
    ]=]

    _ForceUpdatePanel           = [=[
        local panel = Manager:GetFrameRef("SecurePanel")

        _Cache[panel] = nil
        Manager:RunFor(panel, UnQueueUpdatePanel)
        Manager:RunFor(panel, UpdatePanelSize)
    ]=]

    local function registerPanel(self)
        _ManagerFrame:SetFrameRef("SecurePanel", self)
        _ManagerFrame:Execute(_RegisterPanel)
    end

    local function unregisterPanel(self)
        _ManagerFrame:SetFrameRef("SecurePanel", self)
        _ManagerFrame:Execute(_UnregisterPanel)
    end

    local function registerFrame(self, frame)
        _ManagerFrame:SetFrameRef("SecurePanel", self)
        _ManagerFrame:SetFrameRef("SecureElement", frame)
        _ManagerFrame:Execute(_RegisterFrame)

        _ManagerFrame:WrapScript(frame, "OnShow", _WrapShow)
        _ManagerFrame:WrapScript(frame, "OnHide", _WrapHide)
    end

    local function unregisterFrame(self, frame)
        _ManagerFrame:UnwrapScript(frame, "OnShow")
        _ManagerFrame:UnwrapScript(frame, "OnHide")

        _ManagerFrame:SetFrameRef("SecurePanel", self)
        _ManagerFrame:SetFrameRef("SecureElement", frame)
        _ManagerFrame:Execute(_UnregisterFrame)
    end

    local function secureUpdatePanelSize(self)
        _ManagerFrame:SetFrameRef("SecurePanel", self)
        _ManagerFrame:Execute(_UpdatePanelSize)
    end

    local function nextItem(self, index)
        index                   = index + 1
        local ele               = self:GetChild(self.ElementPrefix .. index)
        if ele then return index, ele end
    end

    local function reduce(self, index)
        index                   = index or self.RowCount * self.ColumnCount

        if index < self.Count then
            for i = self.Count, index + 1, -1 do
                local ele       = self:GetChild(self.ElementPrefix .. i)
                ele:Hide()
                OnElementRemove(self, ele)

                self.ElementPool(ele)
                self:SetAttribute("IFSecurePanel_Count", i - 1)
            end

            return secureUpdatePanelSize(self)
        end
    end

    local function generate(self, index)
        if self.ElementType and index > self.Count then
            for i = self.Count + 1, index do
                local ele       = self.ElementPool()
                ele.ID          = i

                ele:Show()
                OnElementAdd(self, ele)

                self:SetAttribute("IFSecurePanel_Count", i)
            end

            return secureUpdatePanelSize(self)
        end
    end

    local function handlePropertyChange(self, prop, value)
        self:SetAttribute("IFSecurePanel_" .. prop, value)

        if prop == "RowCount" or prop == "ColumnCount" then reduce(self) end
        return secureUpdatePanelSize(self)
    end

    local function onPropertyChanged(self, value, old, prop)
        return NoCombat(handlePropertyChange, self, prop, value)
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

    __NoCombat__()
    RefreshLayout               = secureUpdatePanelSize

    function ForceRefreshLayout(self)
        if not InCombatLockdown() then
            _ManagerFrame:SetFrameRef("SecurePanel", self)
            _ManagerFrame:Execute(_ForceUpdatePanel)
        end
    end

    ------------------------------------------------------
    -- Property
    ------------------------------------------------------
    --- The Element Pool
    property "ElementPool"      { type = Recycle, default = function(self) return Recycle(self.ElementType, self.ElementPrefix .. "%d", self) end }

    -- The element's type
    property "ElementType"      { type = ClassType }

    -- The Element accessor, used like obj.Elements[i].
    __Indexer__(NaturalNumber)
    property "Elements"         {
        get                     = function(self, index)
            if index >= 1 and index <= self.ColumnCount * self.RowCount then
                if self:GetChild(self.ElementPrefix .. index) then return self:GetChild(self.ElementPrefix .. index) end

                if self.ElementType and not InCombatLockdown() then
                    generate(self, index)

                    return self:GetChild(self.ElementPrefix .. index)
                else
                    return nil
                end
            end
        end,
    }

    -- The columns's count
    property "ColumnCount"      { type = PositiveNumber, default = 5, handler = onPropertyChanged }

    -- The row's count
    property "RowCount"         { type = PositiveNumber, default = 5, handler = onPropertyChanged }

    -- The elements's max count
    property "MaxCount"         { Get = function(self) return self.ColumnCount * self.RowCount end }

    -- The element's width
    property "ElementWidth"     { type = PositiveNumber, default = 16, handler = onPropertyChanged }

    -- The element's height
    property "ElementHeight"    { type = PositiveNumber, default = 16, handler = onPropertyChanged }

    -- The element's count
    property "Count"            {
        get                     = function(self)
            return self:GetAttribute("IFSecurePanel_Count") or 0
        end,
        set                     = function(self, cnt)
            if cnt > self.RowCount * self.ColumnCount then
                error("Count can't be more than "..self.RowCount * self.ColumnCount, 2)
            end

            if cnt > self.Count then
                if self.ElementType then
                    NoCombat(generate, self, cnt)
                else
                    error("ElementType not set.", 2)
                end
            elseif cnt < self.Count then
                NoCombat(reduce, self, cnt)
            end
        end,
        type = NaturalNumber,
    }

    -- The orientation for elements
    property "Orientation"      { type = Orientation, default = Orientation.HORIZONTAL, handler = onPropertyChanged }

    -- Whether the elements start from left to right
    property "LeftToRight"      { type = Boolean, default = true, handler = onPropertyChanged }

    -- Whether the elements start from top to bottom
    property "TopToBottom"      { type = Boolean, default = true, handler = onPropertyChanged }

    -- The horizontal spacing
    property "HSpacing"         { type = Number, handler = onPropertyChanged }

    -- The vertical spacing
    property "VSpacing"         { type = Number, handler = onPropertyChanged }

    -- Whether the elementPanel is autosize
    property "AutoSize"         { type = Boolean, handler = onPropertyChanged }

    -- The top margin
    property "MarginTop"        { type = Number, handler = onPropertyChanged }

    -- The bottom margin
    property "MarginBottom"     { type = Number, handler = onPropertyChanged }

    -- The left margin
    property "MarginLeft"       { type = Number, handler = onPropertyChanged }

    -- The right margin
    property "MarginRight"      { type = Number, handler = onPropertyChanged }

    -- The prefix for the element's name
    property "ElementPrefix"    { type = String, default = "Element" }

    -- Whether the elementPanel should keep it's max size
    property "KeepMaxSize"      { type = Boolean, handler = onPropertyChanged }

    -- Whether adjust the elements position automatically
    property "AutoPosition"     { type = Boolean, handler = onPropertyChanged }

    -- Whether keep the max size for columns
    property "KeepColumnSize"   { type = Boolean, handler = onPropertyChanged }

    -- Whether keep the max size for rows
    property "KeepRowSize"      { type = Boolean, handler = onPropertyChanged }


    ------------------------------------------------------
    -- Constructor
    ------------------------------------------------------
    function __ctor(self)
        self.OnElementAdd       = self.OnElementAdd + registerFrame
        self.OnElementRemove    = self.OnElementRemove + unregisterFrame

        registerPanel(self)
    end
end)

-----------------------------------------------------------
--                     Default Style                     --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [SecurePanel]               = {
        autoPosition            = true,
        autoSize                = true,
    }
})