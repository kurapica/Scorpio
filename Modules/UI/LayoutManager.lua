--========================================================--
--             Scorpio Layout Frame Widget                --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2022/06/30                              --
--========================================================--

--========================================================--
Scorpio        "Scorpio.Layout"                      "1.0.0"
--========================================================--

--- The layout manager
__Sealed__()
interface "ILayoutManager" (function(_ENV)
    --- Refresh the layout of the frame by its children with IDs
    __Abstract__()
    function RefreshLayout(self, frame, iter, ...)
    end
end)

------------------------------------------------------
-- Helpers
------------------------------------------------------
frameManager                    = Toolset.newtable(true)
taskToken                       = Toolset.newtable(true)

function IsLayoutable(self)
    if not self:IsShown() then return end

    local getID                 = self.GetID
    local id                    = getID and getID(self)
    return id and id > 0
end

function CompareByID(a, b)
    return a:GetID() < b:GetID()
end

__Iterator__()
function GetLayoutChildren(self)
    local yield                 = coroutine.yield
    for i, child in XDictionary(self:GetChilds()).Values:Filter(IsLayoutable):ToList():Sort(CompareByID):GetIterator() do
        yield(i, child)
    end
end

__Async__()
function RefreshLayout(self)
    if not frameManager[self] then return end

    local token                 = (taskToken[self] or 0) + 1
    taskToken[self]             = token

    -- Wait for several cycle to avoid frequently refreshing
    for i = 1, 5 do Next() if token ~= taskToken[self] then return end end

    -- Refresh the layouts
    frameManager[self]:RefreshLayout(self, GetLayoutChildren(self))

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
    set                         = function(self, manager)
        frameManager[self]      = manager

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
