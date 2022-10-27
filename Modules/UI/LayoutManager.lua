--========================================================--
--             Scorpio Layout Frame Widget                --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2022/06/30                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Layout"                      "1.0.0"
--========================================================--

namespace "Scorpio.UI.Layout"

export { clone                  = Toolset.clone }

--- The layout manager
__Sealed__()
interface "ILayoutManager"      (function(_ENV)

    --- Refresh the layout of the frame by its children with IDs
    __Abstract__()
    function RefreshLayout(self, frame, iter) end

    --- Whether include the hide childrens
    __Abstract__()
    property "IncludeHideChildren"  { type = Boolean, default = false }
end)

------------------------------------------------------
-- Helpers
------------------------------------------------------
FRAME_MANAGER                   = "__Scorpio_Layout_Frame_Manager"
PADDING                         = "__Scorpio_Layout_Padding"
MARGIN                          = "__Scorpio_Layout_Margin"

taskToken                       = Toolset.newtable(true)

function IsLayoutable(self)
    if not self:IsShown() then return end

    local getID                 = self.GetID
    local id                    = getID and getID(self)
    return id and id > 0
end

function IsLayoutableWithHidden(self)
    local getID                 = self.GetID
    local id                    = getID and getID(self)
    return id and id > 0
end

function CompareByID(a, b)
    return a:GetID() < b:GetID()
end

__Iterator__()
function GetLayoutChildren(self, incHide)
    local yield                 = coroutine.yield
    for i, child in XDictionary(self:GetChilds()).Values:Filter(incHide and IsLayoutableWithHidden or IsLayoutable):ToList():Sort(CompareByID):GetIterator() do
        yield(i, child, child[MARGIN])
    end
end

__Async__()
function RefreshLayout(self)
    if not self then return end
    if not self[FRAME_MANAGER] then return end

    local token                 = (taskToken[self] or 0) + 1
    taskToken[self]             = token

    -- Wait for several cycle to avoid frequently refreshing
    for i = 1, 3 do Next() if token ~= taskToken[self] then return end end

    -- Refresh the layouts
    self[FRAME_MANAGER]:RefreshLayout(self, GetLayoutChildren(self, self[FRAME_MANAGER].IncludeHideChildren), self[PADDING])

    -- Release the token
    taskToken[self]             = nil
end

function OnStateChanged(self)
    return RefreshLayout(self:GetParent())
end

function OnChildChanged(self, child, isAdd, norefresh)
    if not child.GetID then return end

    if isAdd then
        child.OnSizeChanged     = child.OnSizeChanged + OnStateChanged
        child.OnShow            = child.OnShow + OnStateChanged
        child.OnHide            = child.OnHide + OnStateChanged
        _M:SecureHook(child, "SetID", OnStateChanged)
    else
        child.OnSizeChanged     = child.OnSizeChanged - OnStateChanged
        child.OnShow            = child.OnShow - OnStateChanged
        child.OnHide            = child.OnHide - OnStateChanged
        _M:SecureUnHook(child, "SetID")
    end

    return not norefresh and RefreshLayout(self)
end

------------------------------------------------------
-- UI Property
------------------------------------------------------
--- the frame's layout manager
UI.Property                     {
    name                        = "LayoutManager",
    type                        = ILayoutManager,
    require                     = Frame,
    nilable                     = true,
    set                         = function(self, manager)
        if self[FRAME_MANAGER] == manager then return end
        self[FRAME_MANAGER]     = manager

        if manager then
            self.OnChildChanged = self.OnChildChanged + OnChildChanged

            for name, child in self:GetChilds() do
                OnChildChanged(self, child, true, true)
            end

            return RefreshLayout(self)
        else
            self.OnChildChanged = self.OnChildChanged - OnChildChanged

            for name, child in self:GetChilds() do
                OnChildChanged(self, child, false)
            end
        end
    end,
}

--- The padding for layout panel
UI.Property                     {
    name                        = "Padding",
    type                        = Inset,
    require                     = Frame,
    nilable                     = true,
    set                         = function(self, padding)
        self[PADDING]           = padding
        return RefreshLayout(self)
    end,
    get                         = function(self)
        return clone(self[PADDING])
    end,
    override                    = { "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" }
}
UI.Property                     {
    name                        = "PaddingLeft",
    type                        = Number,
    require                     = Frame,
    nilable                     = true,
    set                         = function(self, val)
        self[PADDING]           = self[PADDING] or {}
        self[PADDING].left      = val
        return RefreshLayout(self)
    end,
    get                         = function(self)
        return self[PADDING] and self[PADDING].left
    end,
    override                    = { "Padding" }
}
UI.Property                     {
    name                        = "PaddingRight",
    type                        = Number,
    require                     = Frame,
    nilable                     = true,
    set                         = function(self, val)
        self[PADDING]           = self[PADDING] or {}
        self[PADDING].right     = val
        return RefreshLayout(self)
    end,
    get                         = function(self)
        return self[PADDING] and self[PADDING].right
    end,
    override                    = { "Padding" }
}
UI.Property                     {
    name                        = "PaddingTop",
    type                        = Number,
    require                     = Frame,
    nilable                     = true,
    set                         = function(self, val)
        self[PADDING]           = self[PADDING] or {}
        self[PADDING].top       = val
        return RefreshLayout(self)
    end,
    get                         = function(self)
        return self[PADDING] and self[PADDING].top
    end,
    override                    = { "Padding" }
}
UI.Property                     {
    name                        = "PaddingBottom",
    type                        = Number,
    require                     = Frame,
    nilable                     = true,
    set                         = function(self, val)
        self[PADDING]           = self[PADDING] or {}
        self[PADDING].bottom    = val
        return RefreshLayout(self)
    end,
    get                         = function(self)
        return self[PADDING] and self[PADDING].bottom
    end,
    override                    = { "Padding" }
}

--- The margin for layout element
UI.Property                     {
    name                        = "Margin",
    type                        = Inset,
    require                     = Frame,
    nilable                     = true,
    set                         = function(self, margin)
        self[MARGIN]            = margin
        return OnStateChanged(self)
    end,
    get                         = function(self)
        return clone(self[MARGIN])
    end,
    override                    = { "MarginLeft", "MarginRight", "MarginTop", "MarginBottom" }
}
UI.Property                     {
    name                        = "MarginLeft",
    type                        = Number,
    require                     = Frame,
    nilable                     = true,
    set                         = function(self, val)
        self[MARGIN]            = self[MARGIN] or {}
        self[MARGIN].left       = val
        return OnStateChanged(self)
    end,
    get                         = function(self)
        return self[MARGIN] and self[MARGIN].left
    end,
    override                    = { "Margin" }
}
UI.Property                     {
    name                        = "MarginRight",
    type                        = Number,
    require                     = Frame,
    nilable                     = true,
    set                         = function(self, val)
        self[MARGIN]            = self[MARGIN] or {}
        self[MARGIN].right      = val
        return OnStateChanged(self)
    end,
    get                         = function(self)
        return self[MARGIN] and self[MARGIN].right
    end,
    override                    = { "Margin" }
}
UI.Property                     {
    name                        = "MarginTop",
    type                        = Number,
    require                     = Frame,
    nilable                     = true,
    set                         = function(self, val)
        self[MARGIN]            = self[MARGIN] or {}
        self[MARGIN].top        = val
        return OnStateChanged(self)
    end,
    get                         = function(self)
        return self[MARGIN] and self[MARGIN].top
    end,
    override                    = { "Margin" }
}
UI.Property                     {
    name                        = "MarginBottom",
    type                        = Number,
    require                     = Frame,
    nilable                     = true,
    set                         = function(self, val)
        self[MARGIN]            = self[MARGIN] or {}
        self[MARGIN].bottom     = val
        return OnStateChanged(self)
    end,
    get                         = function(self)
        return self[MARGIN] and self[MARGIN].bottom
    end,
    override                    = { "Margin" }
}
