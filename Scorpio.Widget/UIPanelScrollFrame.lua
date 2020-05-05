--========================================================--
--             Scorpio UIPanelScrollFrame Widget          --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/02/05                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Widget.UIPanelScrollFrame"   "1.0.0"
--========================================================--

-----------------------------------------------------------
--               UIPanelScrollFrame Widget               --
-----------------------------------------------------------
__Sealed__() class "UIPanelScrollBar" (function(_ENV)
    inherit "Slider"

    local abs                   = math.abs

    local function refreshState(self)
        local value             = self:GetValue() or 0
        local min, max          = self:GetMinMaxValues()
        min                     = min or 0
        max                     = max or 0

        if abs(max - min) < 0.005 then
            self:GetChild("ScrollUpButton"):SetEnabled(false)
            self:GetChild("ScrollDownButton"):SetEnabled(false)

            if self.AutoHide then self:Hide() end
        else
            self:GetChild("ScrollUpButton"):SetEnabled(true)

            -- The 0.005 is to account for precision errors
            if ( max - value > 0.005 ) then
                self:GetChild("ScrollDownButton"):SetEnabled(true)
            else
                self:GetChild("ScrollDownButton"):SetEnabled(false)
            end

            self:Show()
        end
    end

    local function scrollUpButton_OnClick(self)
        local parent            = self:GetParent()
        local scrollStep        = self:GetParent().ScrollStep or (parent:GetHeight() / 2)
        parent:SetValue(parent:GetValue() - scrollStep)
        PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
    end

    local function scrollDownButton_OnClick(self)
        local parent            = self:GetParent()
        local scrollStep        = self:GetParent().ScrollStep or (parent:GetHeight() / 2)
        parent:SetValue(parent:GetValue() + scrollStep)
        PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
    end

    local function scrollBar_OnValueChanged(self, value)
        refreshState(self)
        return self:GetParent():SetVerticalScroll(value)
    end

    local function scrollBar_OnMouseWheel(self, value)
        local scrollStep        = self.ScrollStep or self:GetHeight() / 2
        if ( value > 0 ) then
            self:SetValue(self:GetValue() - scrollStep)
        else
            self:SetValue(self:GetValue() + scrollStep)
        end
    end

    --- The scroll Step
    property "ScrollStep"       { type = Number }

    --- Whether the scroll bar should be hidden if no need to be used
    property "AutoHide"         { type = Boolean, handler = refreshState }

    --- @Override
    function SetMinMaxValues(self, min, max)
        Slider.SetMinMaxValues(self, min, max)
        return refreshState(self)
    end

    __Template__{
        ScrollUpButton          = Button,
        ScrollDownButton        = Button,
    }
    function __ctor(self)
        local scrollUpButton    = self:GetChild("ScrollUpButton")
        local scrollDownButton  = self:GetChild("ScrollDownButton")

        scrollUpButton.OnClick  = scrollUpButton.OnClick + scrollUpButton_OnClick
        scrollDownButton.OnClick= scrollDownButton.OnClick + scrollDownButton_OnClick

        self.OnValueChanged     = self.OnValueChanged + scrollBar_OnValueChanged
        self.OnMouseWheel       = self.OnMouseWheel + scrollBar_OnMouseWheel
    end
end)

__Sealed__() class "UIPanelScrollFrame" (function(_ENV)
    inherit "ScrollFrame"

    local function OnScrollRangeChanged(self, xrange, yrange)
        if self.NoAutoAdjustScrollRange then return end

        yrange                  = math.floor(yrange or self:GetVerticalScrollRange())
        local scrollbar         = self:GetChild("ScrollBar")

        scrollbar:SetMinMaxValues(0, yrange)
        scrollbar:SetValue(math.min(scrollbar:GetValue(), yrange))
    end

    local function OnVerticalScroll(self, offset)
        self:GetChild("ScrollBar"):SetValue(offset)
    end

    local function OnMouseWheel(self, value)
        return self:GetChild("ScrollBar"):OnMouseWheel(value)
    end

    --- Whether auto hide the scroll bar if no use
    property "ScrollBarHideable"{ type = Boolean, handler = function(self, val) self:GetChild("ScrollBar").AutoHide = val end }

    --- Whether don't show the thumb texture on the scroll bar
    property "NoScrollThumb"    { type = Boolean, handler = function(self, val) Style[self:GetChild("ScrollBar")].ThumbTexture = val and NIL or nil end }

    --- Whether don't automatically adjust the scroll range
    property "NoAutoAdjustScrollRange" { type = Boolean }

    __Template__{
        ScrollBar               = UIPanelScrollBar
    }
    function __ctor(self)
        self.OnScrollRangeChanged = self.OnScrollRangeChanged + OnScrollRangeChanged
        self.OnVerticalScroll   = self.OnVerticalScroll + OnVerticalScroll
        self.OnMouseWheel       = self.OnMouseWheel + OnMouseWheel

        local scrollbar         = self:GetChild("ScrollBar")
        scrollbar:SetMinMaxValues(0, 0)
        scrollbar:SetValue(0)
    end
end)

__Sealed__() class "FauxScrollFrame" (function(_ENV)
    inherit "UIPanelScrollFrame"

    __Template__{
        ScrollChild             = Frame
    }
    function __ctor(self)
        local child             = self:GetChild("ScrollChild")
        self:SetScrollChild(child)
        child:SetPoint("TOPLEFT")
        child:SetSize(1, 1)
    end
end)

__Sealed__() class "InputScrollFrame" (function(_ENV)
    inherit "FauxScrollFrame"

    local Next                  = Scorpio.Next

    local function OnMouseDown(self)
        self:GetScrollChild():GetChild("EditBox"):SetFocus()
    end

    local function handleCursorChange(self)
        local height, range, scroll, size, cursorOffset
        local scrollChild       = self:GetParent()
        local scrollFrame       = scrollChild:GetParent()

        scrollFrame:UpdateScrollChildRect()
        Next()

        local charCount         = scrollFrame:GetChild("CharCount")

        if self:GetMaxLetters() then
            charCount:SetText(self:GetNumLetters() .. "/" .. self:GetMaxLetters())
        else
            charCount:SetText("")
        end

        charCount:ClearAllPoints()

        if scrollFrame:GetChild("ScrollBar"):IsShown() then
            charCount:SetPoint("BOTTOMRIGHT", -17, 0)
        else
            charCount:SetPoint("BOTTOMRIGHT", 0, 0)
        end

        height                  = scrollFrame:GetHeight()
        range                   = scrollFrame:GetVerticalScrollRange()
        scroll                  = scrollFrame:GetVerticalScroll()
        size                    = height + range
        cursorOffset            = -(self.cursorOffset or 0)

        if ( math.floor(height) <= 0 or math.floor(range) <= 0 ) then
            --Frame has no area, nothing to calculate.
            return
        end

        while ( cursorOffset < scroll ) do
            scroll              = (scroll - (height / 2))
            if ( scroll < 0 ) then
                scroll          = 0
            end
            scrollFrame:SetVerticalScroll(scroll)
        end

        while ( (cursorOffset + self.cursorHeight) > (scroll + height) and scroll < range ) do
            scroll              = (scroll + (height / 2))
            if ( scroll > range ) then
                scroll          = range
            end
            scrollFrame:SetVerticalScroll(scroll)
        end
    end

    local function OnCursorChanged(self, x, y, w, h)
        self.cursorOffset       = y
        self.cursorHeight       = h
        Next(handleCursorChange, self)
    end

    local function OnTextChanged(self)
        Continue(handleCursorChange, self)
    end

    local function OnEscapePressed(self)
        self:ClearFocus()
    end

    --- The max letters of the input scroll frame
    property "MaxLetters" {
        type                    = Number,
        set                     = function(self, value)
            self:GetScrollChild():GetChild("EditBox"):SetMaxLetters(value)
        end,
        get                     = function(self)
            return self:GetScrollChild():GetChild("EditBox"):GetMaxLetters()
        end,
    }

    --- Whether show the char count
    property "HideCharCount"    {
        type                    = Boolean,
        set                     = function(self, value)
            self:GetScrollChild():GetChild("CharCount"):SetShown(not value)
        end,
        get                     = function(self)
            return not self:GetScrollChild():GetChild("CharCount"):IsShown()
        end,
    }

    --- The font object of the input text
    property "FontObject"       {
        type                    = FontObject,
        set                     = function(self, value)
            return self:GetScrollChild():GetChild("EditBox"):SetFontObject(value)
        end,
        get                     = function(self)
            return self:GetScrollChild():GetChild("EditBox"):GetFontObject()
        end,
    }

    --- Whether count the invisible letters
    property "CountInvisibleLetters" {
        type                    = Boolean,
        set                     = function(self, value)
            return self:GetScrollChild():GetChild("EditBox"):SetCountInvisibleLetters(value)
        end,
        get                     = function(self)
            return self:GetScrollChild():GetChild("EditBox"):IsCountInvisibleLetters()
        end,
    }

    --- Sets the text to the input scroll frame
    function SetText(self, text)
        local editbox           = self:GetScrollChild():GetChild("EditBox")
        editbox:SetText(text)
        Next(handleCursorChange, editbox)
    end

    --- Gets the text from the input scroll frame
    function GetText(self)
        return self:GetScrollChild():GetChild("EditBox"):GetText()
    end

    __Template__{
        CharCount               = FontString,

        {
            ScrollChild         = {
                EditBox         = EditBox,
            }
        }
    }
    function __ctor(self)
        local child             = self:GetScrollChild()

        local editbox           = child:GetChild("EditBox")
        editbox:SetPoint("TOPLEFT")
        editbox:SetPoint("RIGHT", self:GetChild("ScrollBar"), "LEFT", -4, 0)
        editbox:SetMultiLine(true)
        editbox:SetAutoFocus(false)

        editbox:SetCountInvisibleLetters(true)

        self.OnMouseDown        = self.OnMouseDown          + OnMouseDown

        editbox.OnTextChanged   = editbox.OnTextChanged     + OnTextChanged
        editbox.OnCursorChanged = editbox.OnCursorChanged   + OnCursorChanged
        editbox.OnEscapePressed = editbox.OnEscapePressed   + OnEscapePressed
    end
end)

__Sealed__() class "ListFrameItemButton" (function(_ENV)
    inherit "Button"

    local function refreshIcon(self)
        local icon              = self:GetChild("DisplayIcon")

        if self.Icon then
            icon:SetTexture(self.Icon)
            icon:Show()
        else
            icon:Hide()
        end
    end

    -- The event handlers
    local function OnEnter(self)
        if self.TooltipTitle then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip_SetTitle(GameTooltip, self.TooltipTitle)
            if self.TooltipText then
                GameTooltip_AddNormalLine(GameTooltip, self.TooltipText, true)
            end
            GameTooltip:Show()
        end
    end

    local function OnLeave(self)
        GameTooltip:Hide()
    end

    --- The icon
    property "Icon"             { type = String + Number, handler = refreshIcon }

    --- The tooltip title
    property "TooltipTitle"     { type = String }

    --- The tooltip text
    property "TooltipText"      { type = String }

    __Template__{
        DisplayIcon             = Texture,
    }
    function __ctor(self)
        refreshIcon(self)

        self.OnEnter            = self.OnEnter + OnEnter
        self.OnLeave            = self.OnLeave + OnLeave
    end
end)

__Sealed__() class "ListFrame" (function(_ENV)
    inherit "FauxScrollFrame"

    __Sealed__() struct "ListItem" {
        { name = "text",        type = String, require = true },
        { name = "icon",        type = String + Number },
        { name = "tiptitle",    type = String },
        { name = "tiptext",     type = String },
    }

    local tinsert               = table.insert
    local tremove               = table.remove
    local Next                  = Scorpio.Next

    local function ItemButton_OnClick(self)
        local list              = self:GetParent():GetParent()
        list.SelectedValue      = self.checkvalue
        return OnItemClick(list, self.checkvalue)
    end

    local function ItemButton_OnDoubleClick(self)
        local list              = self:GetParent():GetParent()
        list.SelectedValue      = self.checkvalue
        return OnItemDoubleClick(list, self.checkvalue)
    end

    local function refreshItems(self)
        local offset            = self.__ListOffset or 0
        local items             = self.__ListItems
        local scrollChild       = self:GetChild("ScrollChild")

        if not scrollChild then return end

        GameTooltip:Hide()

        for i = 1, self.DisplayCount do
            local item          = items and items[offset + i]
            local btn           = scrollChild:GetChild("ItemButton" .. i)
            if not btn then return end

            if item then
                btn:SetText(item.text)
                btn.Icon        = item.icon
                btn.TooltipTitle= item.tiptitle
                btn.TooltipText = item.tiptext
                btn.checkvalue  = item.checkvalue
                btn:SetEnabled(true)

                if item.tiptitle and item:IsMouseOver() then
                    btn:OnEnter()
                end

                if self.SelectedValue == item.checkvalue then
                    local color = self.SelectHightlightColor
                    btn:LockHighlight()
                    btn:GetPropertyChild("HighlightTexture"):SetVertexColor(color.r, color.g, color.b)
                else
                    local color = self.UnselectHightlightColor
                    btn:UnlockHighlight()
                    btn:GetPropertyChild("HighlightTexture"):SetVertexColor(color.r, color.g, color.b)
                end
            else
                btn:SetText("")
                btn.Icon        = nil
                btn.TooltipTitle= nil
                btn.TooltipText = nil
                btn.checkvalue  = nil
                btn:SetEnabled(false)
            end
        end
    end

    local function processRefreshList(self)
        self.__InRefresh        = false

        local scrollBar         = self:GetChild("ScrollBar")
        local scrollChild       = self:GetChild("ScrollChild")
        local count             = self.__ListItems and #self.__ListItems or 0
        local totalheight       = 0
        local init              = false

        for i = 1, self.DisplayCount do
            local btn           = scrollChild:GetChild("ItemButton" .. i)
            if not btn then
                btn             = ListFrameItemButton("ItemButton" .. i, scrollChild)
                btn:InstantApplyStyle()
                init            = true

                btn:ClearAllPoints()
                if i == 1 then
                    btn:SetPoint("TOPLEFT")
                else
                    btn:SetPoint("TOPLEFT", scrollChild:GetChild("ItemButton" .. (i-1)), "BOTTOMLEFT")
                end
                btn:SetPoint("RIGHT")
                btn:Show()

                btn.OnClick     = btn.OnClick + ItemButton_OnClick
                btn.OnDoubleClick = btn.OnDoubleClick + ItemButton_OnDoubleClick
            end

            totalheight         = totalheight + btn:GetHeight()
        end

        local disidx            = self.DisplayCount + 1
        while scrollChild:GetChild("ItemButton" .. disidx) do
            scrollChild:GetChild("ItemButton" .. disidx):Hide()
            disidx              = disidx + 1
        end

        if init then
            local diff          = self:GetHeight() - scrollChild:GetHeight()
            self:SetHeight(totalheight + diff)
        end

        local yrange            = count - self.DisplayCount

        if yrange > 0 then
            scrollBar:SetMinMaxValues(0, yrange)
            scrollBar:SetValue(math.min(scrollBar:GetValue(), yrange))
        else
            scrollBar:SetMinMaxValues(0, 0)
            scrollBar:SetValue(0)
        end

        return refreshItems(self)
    end

    local function refreshList(self)
        if self.__InRefresh then return end
        self.__InRefresh        = true
        Next(processRefreshList, self)
    end

    --- Fired when click on the item
    event "OnItemClick"

    --- Fired when double click on the item
    event "OnItemDoubleClick"

    --- The select node highlight color
    property "SelectHightlightColor"    { type = Color, default = Color(1, 1, 0) }

    --- The un-select node highlight color
    property "UnselectHightlightColor"  { type = Color, default = Color(.196, .388, .8) }

    --- The selected value of the list frame
    property "SelectedValue"    { handler = refreshItems }

    --- The items to be selected
    __Indexer__()
    property "Items"            {
        type                    = String + ListItem,
        set                     = function(self, value, text)
            local items         = self.__ListItems or {}
            local itemidx

            for i, item in ipairs(items) do
                if item.checkvalue == value then
                    itemidx     = i
                    break
                end
            end

            if text == nil then
                if itemidx then tremove(items, itemidx) end
            elseif type(text) == "string" then
                if itemidx then
                    local item      = items[itemidx]

                    item.checkvalue = value
                    item.text       = text
                    item.icon       = nil
                    item.tiptitle   = nil
                    item.tiptext    = nil
                else
                    tinsert(items, {
                        -- So we share the same struct for dropdown menu item and combobox
                        -- Just for simple
                        checkvalue  = value,
                        text        = text,
                    })
                end
            else
                if itemidx then
                    local item      = items[itemidx]

                    item.checkvalue = value
                    item.text       = text.text
                    item.icon       = text.icon
                    item.tiptitle   = text.tiptitle
                    item.tiptext    = text.tiptext
                else
                    tinsert(items, {
                        checkvalue  = value,
                        text        = text.text,
                        icon        = text.icon,
                        tiptitle    = text.tiptitle,
                        tiptext     = text.tiptext,
                    })
                end
            end

            self.__ListItems    = items

            return refreshList(self)
        end,
    }

    --- The raw items to be set, normally only be used by the ComboBox
    -- or you know what you are doing
    property "RawItems"         {
        type                    = Table,
        set                     = function(self, items)
            self.__ListItems    = items
            return refreshList(self)
        end
    }

    --- The display item count
    property "DisplayCount"     { type = Number, default = 5, handler = refreshList }

    --- Whether don't automatically adjust the scroll range
    property "NoAutoAdjustScrollRange" { default = true, set = false }

    --- The methods used to clear all items
    function ClearItems(self)
        if self.__ListItems then wipe(self.__ListItems) end
    end

    function SetVerticalScroll(self, value)
        self.__ListOffset       = math.floor(value)
        return refreshItems(self)
    end

    function __ctor(self)
        super(self)

        self:InstantApplyStyle()
        return refreshList(self)
    end
end)

__Sealed__() class "TreeView" (function(_ENV)
    inherit "FauxScrollFrame"

    local tinsert               = table.insert
    local tremove               = table.remove

    local TreeNodeCount         = 0
    local TreeNodeLevelClasses  = {}
    local TreeNodeHolder        = CreateFrame("Frame")
    TreeNodeHolder:Hide()

    local _TempPath             = {}
    local _TempCount            = 0
    local _TempOffset           = 0

    local refreshTreeView

    local function TreeNode_OnEnter(self)
        if self:GetFontString():IsTruncated() then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self:GetText(), Color.NORMAL.r, Color.NORMAL.g, Color.NORMAL.b, 1, true)
        end
    end

    local function TreeNode_OnLeave(self)
        GameTooltip:Hide()
    end

    local function TreeNode_OnClick(self)
        local node              = self.node
        local tree              = self:GetParent():GetParent()

        if not self:GetChild("Toggle"):IsShown() and #self.node > 0 then
            -- Click to toggle
            self.node.unfold    = not self.node.unfold
            refreshTreeView(tree)
        end

        wipe(_TempPath)

        while node and node.text do
            tinsert(_TempPath, 1, node.text)
            node                = node.parent
        end

        if tree.__SelectedNode then
            local selected      = tree.__SelectedNode.button
            if selected then
                local color     = tree.UnselectHightlightColor
                selected:UnlockHighlight()
                selected:GetPropertyChild("HighlightTexture"):SetVertexColor(color.r, color.g, color.b)
            end
        end

        tree.__SelectedNode     = self.node
        local color             = tree.SelectHightlightColor
        self:LockHighlight()
        self:GetPropertyChild("HighlightTexture"):SetVertexColor(color.r, color.g, color.b)

        OnNodeClick(tree, unpack(_TempPath))
    end

    local function TreeNodeToggle_OnClick(self)
        local button            = self:GetParent()
        if #button.node > 0 then
            button.node.unfold  = not button.node.unfold

            return refreshTreeView(button:GetParent():GetParent())
        end
    end
    local function getButtonLevel(button)
        local level             = button:GetName():match("TreeNode(%d+)")
        return level and tonumber(level)
    end

    local function getTreeNode(level)
        local recycle           = TreeNodeHolder[level]
        local node              = recycle and tremove(recycle)

        if not node then
            TreeNodeCount       = TreeNodeCount + 1
            node                = TreeView.TreeNodeClasses[level]("TreeNode" .. level .. "_" .. TreeNodeCount, TreeNodeHolder)
            node:InstantApplyStyle()

            node.OnEnter        = node.OnEnter + TreeNode_OnEnter
            node.OnLeave        = node.OnLeave + TreeNode_OnLeave
            node.OnClick        = node.OnClick + TreeNode_OnClick

            local toggle        = node:GetChild("Toggle")
            toggle.OnClick      = toggle.OnClick + TreeNodeToggle_OnClick
        end

        return node
    end

    local function removeTreeButton(button)
        button.node             = nil

        local level             = getButtonLevel(button)
        if level then
            button:ClearAllPoints()
            button:SetParent(TreeNodeHolder)

            local recycle       = TreeNodeHolder[level] or {}
            tinsert(recycle, button)
            TreeNodeHolder[level] = recycle
        end
    end

    local function parseNodeSettings(self, node, level)
        if not node then return end

        self.__TreeButtons      = self.__TreeButtons or {}
        local buttons           = self.__TreeButtons

        local container         = self:GetChild("ScrollChild")

        if #node > 0 then
            if node.unfold and #node > 0 then
                if _TempCount > 0 then
                    local toggle= buttons[_TempCount]:GetChild("Toggle")
                    toggle:Show()

                    toggle:GetPropertyChild("UnfoldTexture"):Show()
                    toggle:GetPropertyChild("NormalTexture"):Hide()
                end

                for i = 1, #node do
                    local cnode = node[i]

                    _TempCount  = _TempCount + 1
                    local button= buttons[_TempCount]
                    local btnlvl= button and getButtonLevel(button)

                    while button and btnlvl > level do
                        removeTreeButton(button)
                        tremove(buttons, _TempCount)
                        button  = buttons[_TempCount]
                        btnlvl  = button and getButtonLevel(button)
                    end

                    if not button or btnlvl < level then
                        button  = getTreeNode(level)
                        tinsert(buttons, _TempCount, button)

                        button:SetParent(container)
                    end

                    button.node = cnode
                    cnode.button= button
                    button:SetText(cnode.text)

                    button:ClearAllPoints()
                    button:SetPoint("TOP", 0,  -_TempOffset)
                    button:SetPoint("LEFT")
                    button:SetPoint("RIGHT", self:GetChild("ScrollBar"), "LEFT")

                    _TempOffset = _TempOffset + button:GetHeight()

                    if self.__SelectedNode == cnode then
                        local color = self.SelectHightlightColor
                        button:LockHighlight()
                        button:GetPropertyChild("HighlightTexture"):SetVertexColor(color.r, color.g, color.b)
                    else
                        local color = self.UnselectHightlightColor
                        button:UnlockHighlight()
                        button:GetPropertyChild("HighlightTexture"):SetVertexColor(color.r, color.g, color.b)
                    end

                    parseNodeSettings(self, cnode, level + 1)
                end
            else
                if _TempCount > 0 then
                    local toggle= buttons[_TempCount]:GetChild("Toggle")
                    toggle:Show()

                    toggle:GetPropertyChild("UnfoldTexture"):Hide()
                    toggle:GetPropertyChild("NormalTexture"):Show()
                end
            end
        else
            if _TempCount > 0 then
                buttons[_TempCount]:GetChild("Toggle"):Hide()
            end
        end

        if level == 1 then
            for i = #buttons, _TempCount + 1, -1 do
                removeTreeButton(buttons[i])
                tremove(buttons, i)
            end

            container:SetHeight(_TempOffset)
        end
    end

    local function processRefreshTreeView(self)
        self.__InRefresh        = false

        _TempCount              = 0
        _TempOffset             = 0
        return parseNodeSettings(self, self.__TreeNodes, 1)
    end

    function refreshTreeView(self)
        if self.__InRefresh then return end
        self.__InRefresh        = true
        Next(processRefreshTreeView, self)
    end


    --- The toggle button on the tree node
    __Sealed__()
    class "TreeNodeToggle"      { Button }

    --- The unfold texture of the toggle button
    UI.Property         {
        name            = "UnfoldTexture",
        require         = TreeNodeToggle,
        childtype       = Texture,
    }

    __Sealed__() __Template__(Button)
    class "TreeNode"            { Toggle   = TreeNodeToggle }

    --- Fired when click on the tree node, the path of the tree node will be send out
    event "OnNodeClick"

    -- Auto-generate the tree node classes based on the level
    __Static__() __Indexer__(Integer)
    property "TreeNodeClasses" {
        get                     = function(self, index)
            local treenode      = TreeNodeLevelClasses[index]
            if not treenode then
                Attribute.IndependentCall(function()
                    treenode    = class ("TreeNodeLevel" .. index) { TreeNode }
                end)

                TreeNodeLevelClasses[index] = treenode
            end
            return treenode
        end,
    }

    --- The select node highlight color
    property "SelectHightlightColor" { type = Color, default = Color(1, 1, 0) }

    --- The un-select node highlight color
    property "UnselectHightlightColor" { type = Color, default = Color(.196, .388, .8) }

    --- Add tree node by the path
    __Arguments__{ NEString * 1 }
    function AddTreeNode(self, ...)
        local treeNodes         = self.__TreeNodes or { unfold = true }
        self.__TreeNodes        = treeNodes

        for i = 1, select("#", ...) do
            local name          = select(i, ...)
            local item

            for j = 1, #treeNodes do
                if treeNodes[j].text == name then
                    item        = treeNodes[j]
                    break
                end
            end

            if not item then
                item            = { text = name, parent = treeNodes }
                tinsert(treeNodes, item)
            end

            treeNodes           = item
        end

        return refreshTreeView(self)
    end

    --- Remove the tree node by the path
    __Arguments__{ NEString * 1 }
    function RemoveTreeNode(self, ...)
        local treeNodes         = self.__TreeNodes
        if not treeNodes then return end
        local count             = select("#", ...)

        for i = 1, count do
            local name          = select(i, ...)
            local item

            for j = 1, #treeNodes do
                if treeNodes[j].text == name then
                    item        = treeNodes[j]
                    break
                end
            end

            if not item then return end
            if count == i then
                for j = 1, #treeNodes do
                    if treeNodes[j] == item then
                        tremove(treeNodes, j)
                        break
                    end
                end
            end

            treeNodes           = item
        end

        return refreshTreeView(self)
    end
end)

-----------------------------------------------------------
--          UIPanelScrollFrame Style - Default           --
-----------------------------------------------------------
Style.UpdateSkin("Default",     {
    [UIPanelScrollBar]          = {
        width                   = 16,

        ThumbTexture            = {
            file                = [[Interface\Buttons\UI-ScrollBar-Knob]],
            texCoords           = RectType(0.20, 0.80, 0.125, 0.875),
            size                = Size(18, 24),
        },

        -- Childs
        ScrollUpButton          = {
            location            = { Anchor("BOTTOM", 0, 0, nil, "TOP") },
            size                = Size(18, 16),

            NormalTexture       = {
                file            = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Up]],
                texCoords       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints    = true,
            },
            PushedTexture       = {
                file            = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Down]],
                texCoords       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints    = true,
            },
            DisabledTexture     = {
                file            = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Disabled]],
                texCoords       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints    = true,
            },
            HighlightTexture    = {
                file            = [[Interface\Buttons\UI-ScrollBar-ScrollUpButton-Highlight]],
                texCoords       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints    = true,
                alphamode       = "ADD",
            }
        },
        ScrollDownButton        = {
            location            = { Anchor("TOP", 0, 0, nil, "BOTTOM") },
            size                = Size(18, 16),

            NormalTexture       = {
                file            = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Up]],
                texCoords       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints    = true,
            },
            PushedTexture       = {
                file            = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Down]],
                texCoords       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints    = true,
            },
            DisabledTexture     = {
                file            = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Disabled]],
                texCoords       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints    = true,
            },
            HighlightTexture    = {
                file            = [[Interface\Buttons\UI-ScrollBar-ScrollDownButton-Highlight]],
                texCoords       = RectType(0.20, 0.80, 0.25, 0.75),
                setAllPoints    = true,
                alphamode       = "ADD",
            }
        },
    },
    [UIPanelScrollFrame]        = {
        ScrollBar               = {
            location            = {
                Anchor("TOPLEFT", 6, -16, nil, "TOPRIGHT"),
                Anchor("BOTTOMLEFT", 6, 16, nil, "BOTTOMRIGHT")
            },
        },
    },
    [InputScrollFrame]          = {
        fontObject              = GameFontHighlightSmall,
        countInvisibleLetters   = true,
        scrollBarHideable       = true,
        maxLetters              = 255,

        ScrollBar               = {
            location            = {
                Anchor("TOPLEFT", -13, -11, nil, "TOPRIGHT"),
                Anchor("BOTTOMLEFT", -13, 9, nil, "BOTTOMRIGHT")
            },

            ScrollUpButton      = {
                location        = { Anchor("BOTTOM", 0, -4, nil, "TOP") },
            },
            ScrollDownButton    = {
                location        = { Anchor("TOP", 0, 4, nil, "BOTTOM") },
            },
        },
        TopLeftBGTexture        = {
            file                = [[Interface\Common\Common-Input-Border-TL]],
            size                = Size(8, 8),
            location            = { Anchor("TOPLEFT", -5, 5) },
        },
        TopRightBGTexture       = {
            file                = [[Interface\Common\Common-Input-Border-TR]],
            size                = Size(8, 8),
            location            = { Anchor("TOPRIGHT", 5, 5) },
        },
        TopBGTexture            = {
            file                = [[Interface\Common\Common-Input-Border-T]],
            size                = Size(8, 8),
            location            = {
                Anchor("TOPLEFT", 0, 0, "TopLeftBGTexture", "TOPRIGHT"),
                Anchor("BOTTOMRIGHT", 0, 0, "TopRightBGTexture", "BOTTOMLEFT")
            },
        },
        BottomLeftBGTexture     = {
            file                = [[Interface\Common\Common-Input-Border-BL]],
            size                = Size(8, 8),
            location            = { Anchor("BOTTOMLEFT", -5, -5) },
        },
        BottomRightBGTexture    = {
            file                = [[Interface\Common\Common-Input-Border-BR]],
            size                = Size(8, 8),
            location            = { Anchor("BOTTOMRIGHT", 5, -5) },
        },
        BottomBGTexture         = {
            file                = [[Interface\Common\Common-Input-Border-B]],
            size                = Size(8, 8),
            location            = {
                Anchor("TOPLEFT", 0, 0, "BottomLeftBGTexture", "TOPRIGHT"),
                Anchor("BOTTOMRIGHT", 0, 0, "BottomRightBGTexture", "BOTTOMLEFT")
            },
        },
        LeftBGTexture           = {
            file                = [[Interface\Common\Common-Input-Border-L]],
            size                = Size(8, 8),
            location            = {
                Anchor("TOPLEFT", 0, 0, "TopLeftBGTexture", "BOTTOMLEFT"),
                Anchor("BOTTOMRIGHT", 0, 0, "BottomLeftBGTexture", "TOPRIGHT")
            },
        },
        RightBGTexture          = {
            file                = [[Interface\Common\Common-Input-Border-R]],
            size                = Size(8, 8),
            location            = {
                Anchor("TOPLEFT", 0, 0, "TopRightBGTexture", "BOTTOMLEFT"),
                Anchor("BOTTOMRIGHT", 0, 0, "BottomRightBGTexture", "TOPRIGHT")
            },
        },
        MiddleBGTexture         = {
            file                = [[Interface\Common\Common-Input-Border-M]],
            size                = Size(8, 8),
            location            = {
                Anchor("TOPLEFT", 0, 0, "LeftBGTexture", "TOPRIGHT"),
                Anchor("BOTTOMRIGHT", 0, 0, "RightBGTexture", "BOTTOMLEFT")
            },
        },
        CharCount               = {
            drawLayer           = "OVERLAY",
            fontObject          = GameFontDisableLarge,
            location            = { Anchor("BOTTOMRIGHT", -6, 0) },
        },
    },
    [ListFrameItemButton]       = {
        height                  = 32,

        normalFont              = GameFontNormal,
        disabledFont            = GameFontDisable,
        highlightFont           = GameFontHighlight,

        HighlightTexture        = {
            file                = [[Interface\BUTTONS\UI-Common-MouseHilight]],
            setAllPoints        = true,
            alphamode           = "ADD",
        },

        ButtonText              = {
            fontObject          = GameFontNormal,
        },

        DisplayIcon             = {
            drawLayer           = "ARTWORK",
            size                = Size(16, 16),
            location            = { Anchor("RIGHT") },
        },
    },
    [ListFrame]                 = {
        backdrop                = {
            edgeFile            = [[Interface\Tooltips\UI-Tooltip-Border]],
            bgFile              = [[Interface\DialogFrame\UI-DialogBox-Background]],
            tile                = true, tileSize = 16, edgeSize = 16,
            insets              = { left = 5, right = 5, top = 5, bottom = 5 }
        },
        backdropBorderColor     = ColorType(0.6, 0.6, 0.6),

        ScrollBar               = {
            scrollStep          = 1,

            location            = { Anchor("TOPRIGHT", -6, -22), Anchor("BOTTOMRIGHT", -6, 22) },
            TopBGTexture        = {
                drawLayer       = "BORDER",
                file            = [[Interface\PaperDollInfoFrame\UI-Character-ScrollBar]],
                texCoords       = RectType(0, 0.484375, 0, 0.09),
                location        = { Anchor("TOPLEFT", -4, 4, "ScrollUpButton"),  Anchor("BOTTOMRIGHT", 4, -4, "ScrollUpButton") },
            },
            MiddleBGTexture     = {
                drawLayer       = "BORDER",
                file            = [[Interface\PaperDollInfoFrame\UI-Character-ScrollBar]],
                texCoords       = RectType(0, 0.484375, 0.1640625, 1),
                location        = { Anchor("TOPLEFT", 0, 0, "TopBGTexture", "BOTTOMLEFT"), Anchor("BOTTOMRIGHT", 0, 0, "BottomBGTexture", "TOPRIGHT") },
            },
            BottomBGTexture     = {
                drawLayer       = "BORDER",
                file            = [[Interface\PaperDollInfoFrame\UI-Character-ScrollBar]],
                texCoords       = RectType(0.515625, 1.0, 0.328, 0.4140625),
                location        = { Anchor("TOPLEFT", -4, 4, "ScrollDownButton"),  Anchor("BOTTOMRIGHT", 4, -3, "ScrollDownButton") },
            },
        },

        ScrollChild             = {
            location            = { Anchor("TOPLEFT", 4, -4), Anchor("BOTTOMRIGHT", -4, 4, "ScrollBar", "BOTTOMLEFT") }
        },
    },
    [TreeView]                  = {
        scrollBarHideable       = true,
        backdrop                = {
            edgeFile            = [[Interface\Tooltips\UI-Tooltip-Border]],
            bgFile              = [[Interface\DialogFrame\UI-DialogBox-Background]],
            tile                = true, tileSize = 16, edgeSize = 16,
            insets              = { left = 5, right = 5, top = 5, bottom = 5 }
        },
        backdropBorderColor     = ColorType(0.6, 0.6, 0.6),

        ScrollBar               = {
            scrollStep          = 1,

            location            = { Anchor("TOPRIGHT", -6, -22), Anchor("BOTTOMRIGHT", -6, 22) },
            TopBGTexture        = {
                drawLayer       = "BORDER",
                file            = [[Interface\PaperDollInfoFrame\UI-Character-ScrollBar]],
                texCoords       = RectType(0, 0.484375, 0, 0.09),
                location        = { Anchor("TOPLEFT", -4, 4, "ScrollUpButton"),  Anchor("BOTTOMRIGHT", 4, -4, "ScrollUpButton") },
            },
            MiddleBGTexture     = {
                drawLayer       = "BORDER",
                file            = [[Interface\PaperDollInfoFrame\UI-Character-ScrollBar]],
                texCoords       = RectType(0, 0.484375, 0.1640625, 1),
                location        = { Anchor("TOPLEFT", 0, 0, "TopBGTexture", "BOTTOMLEFT"), Anchor("BOTTOMRIGHT", 0, 0, "BottomBGTexture", "TOPRIGHT") },
            },
            BottomBGTexture     = {
                drawLayer       = "BORDER",
                file            = [[Interface\PaperDollInfoFrame\UI-Character-ScrollBar]],
                texCoords       = RectType(0.515625, 1.0, 0.328, 0.4140625),
                location        = { Anchor("TOPLEFT", -4, 4, "ScrollDownButton"),  Anchor("BOTTOMRIGHT", 4, -3, "ScrollDownButton") },
            },
        },

        ScrollChild             = {
            location            = { Anchor("TOPLEFT", 8, -8), Anchor("BOTTOMRIGHT", -4, 4, "ScrollBar", "BOTTOMLEFT") }
        },
    },
    -- Level 1 Tree Node
    [TreeView.TreeNodeClasses[1]] = {
        size                    = Size(175, 18),
        normalFont              = GameFontNormal,
        highlightFont           = GameFontHighlight,

        Toggle                  = {
            size                = Size(14, 14),
            location            = { Anchor("TOPRIGHT", -6, -1) },

            NormalTexture       = {
                file            = [[Interface\Buttons\UI-PlusButton-UP]],
                setAllPoints    = true,
            },
            UnfoldTexture       = {
                file            = [[Interface\Buttons\UI-MinusButton-Up]],
                setAllPoints    = true,
            },
            HighlightTexture    = {
                file            = [[Interface\Buttons\UI-PlusButton-Hilight]],
                setAllPoints    = true,
                alphaMode       = "ADD",
            },
        },

        ButtonText              = {
            justifyH            = "LEFT",
            location            = { Anchor("LEFT") },
            wordwrap            = false,
        },

        HighlightTexture        = {
            file                = [[Interface\QuestFrame\UI-QuestLogTitleHighlight]],
            location            = { Anchor("TOPLEFT", 0, 1), Anchor("BOTTOMRIGHT", 0, 1) },
            alphaMode           = "ADD",
        },
    },
    -- Level 2 Tree Node
    [TreeView.TreeNodeClasses[2]] = {
        size                    = Size(175, 18),
        normalFont              = GameFontNormal,
        highlightFont           = GameFontHighlight,

        Toggle                  = {
            size                = Size(14, 14),
            location            = { Anchor("TOPRIGHT", -6, -1) },

            NormalTexture       = {
                file            = [[Interface\Buttons\UI-PlusButton-UP]],
                setAllPoints    = true,
            },
            UnfoldTexture       = {
                file            = [[Interface\Buttons\UI-MinusButton-Up]],
                setAllPoints    = true,
            },
            HighlightTexture    = {
                file            = [[Interface\Buttons\UI-PlusButton-Hilight]],
                setAllPoints    = true,
                alphaMode       = "ADD",
            },
        },

        ButtonText              = {
            justifyH            = "LEFT",
            location            = { Anchor("LEFT", 24, 0) },
            wordwrap            = false,
            textColor           = Color(1, 1, 1),
        },

        HighlightTexture        = {
            file                = [[Interface\QuestFrame\UI-QuestLogTitleHighlight]],
            location            = { Anchor("TOPLEFT", 0, 1), Anchor("BOTTOMRIGHT", 0, 1) },
            alphaMode           = "ADD",
        },
    },
    -- Level 3 Tree Node(No more for now)
    [TreeView.TreeNodeClasses[3]] = {
        size                    = Size(175, 18),
        normalFont              = GameFontNormal,
        highlightFont           = GameFontHighlight,

        Toggle                  = {
            size                = Size(14, 14),
            location            = { Anchor("TOPRIGHT", -6, -1) },

            NormalTexture       = {
                file            = [[Interface\Buttons\UI-PlusButton-UP]],
                setAllPoints    = true,
            },
            UnfoldTexture       = {
                file            = [[Interface\Buttons\UI-MinusButton-Up]],
                setAllPoints    = true,
            },
            HighlightTexture    = {
                file            = [[Interface\Buttons\UI-PlusButton-Hilight]],
                setAllPoints    = true,
                alphaMode       = "ADD",
            },
        },

        ButtonText              = {
            justifyH            = "LEFT",
            location            = { Anchor("LEFT", 48, 0) },
            wordwrap            = false,
            textColor           = Color(1, 1, 1),
        },

        HighlightTexture        = {
            file                = [[Interface\QuestFrame\UI-QuestLogTitleHighlight]],
            location            = { Anchor("TOPLEFT", 0, 1), Anchor("BOTTOMRIGHT", 0, 1) },
            alphaMode           = "ADD",
        },
    },
})