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
    --- Refresh the layout of the frame
    __Abstract__()
    function RefreshLayout(self, iter)
    end
end)

------------------------------------------------------
-- Helpers
------------------------------------------------------
HANDLER                         = 1
MANAGER                         = 2
TOKEN                           = 3
CHILDS                          = 4
DISABLE                         = 5

local frameMap                  = Toolset.newtable(true)

local function GetChilds(childs)
    local yield                 = coroutine.yield
    for i, childs in ipairs(childs) do
        yield(i, childs)
    end
end

local function GetChildIter(map)
    return RunIterator(GetChilds, map[CHILDS])
end

local function OnStyleApplied(self, child, taskid)
    local map                   = frameMap[self]
    if map[DISABLE] or #map[CHILDS] == 0 then return end

    -- Wait for several cycle to avoid frequently refreshing
    for i = 1, 5 do if taskid ~= smap[TOKEN] then return end Next() end

    -- Refresh the layouts
    return map[MANAGER]:RefreshLayout(frame, GetChildIter(map))
end

local function OnChildChanged(self, child, isAdd)
    if isAdd then
        child.OnStyleApplied    = child.OnStyleApplied + frameMap[self][HANDLER]
    else
        child.OnStyleApplied    = child.OnStyleApplied - frameMap[self][HANDLER]
    end
end

------------------------------------------------------
-- UI Property
------------------------------------------------------
--- the frame's layout manager
UI.Property         {
    name            = "LayoutManager",
    type            = ILayoutManager,
    require         = Frame,
    set             = function(self, manager)
        if manager then
            local map               = frameMap[self]
            if not map then
                map                 = {
                    [TOKEN]         = 0,
                    [HANDLER]       = function(child)
                        map[TOKEN]  = map[TOKEN] + 1
                        return Next(OnStyleApplied, self, child, map[TOKEN])
                    end,
                    [CHILDS]        = {}
                }
                frameMap[self]      = map
            end
            map[MANAGER]            = manager
            map[DISABLE]            = false

            -- Bind the child changed
            self.OnChildChanged     = self.OnChildChanged + OnChildChanged

            return #map[CHILDS] > 0 and Next(manager.RefreshLayout, manager, self, GetChildIter(map))
        else
            local map               = frameMap[self]
            if not map then return end
            map[DISABLE]            = true
        end
    end,
}
