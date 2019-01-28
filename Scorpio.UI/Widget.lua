--========================================================--
--             Scorpio UI Basic Widgets                   --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2019/01/09                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.UI.Widget"                "1.0.0"
--========================================================--

----------------------------------------------
--                UI Helpers                --
----------------------------------------------
do
    function getRealMethodCache(name)
        return setmetatable({}, {
            __index             = function(self, cls)
                local real      = Class.GetNormalMethod(cls, name)
                rawset(self, cls, real)
                return real
            end,
        })
    end
end

--- The basic type for all ui ojbect provide the name and parent-children support
__Sealed__() __Abstract__()
class "UIObject" (function(_ENV)
    ----------------------------------------------
    --                 Helpers                  --
    ----------------------------------------------
    local _NameMap              = setmetatable({}, META_WEAKKEY)
    local _ChildMap             = setmetatable({}, META_WEAKKEY)

    local _SetParent            = getRealMethodCache("SetParent")
    local _GetParent            = getRealMethodCache("GetParent")

    local validate              = Struct.ValidateValue

    ----------------------------------------------
    --              Static Methods              --
    ----------------------------------------------
    --- Gets the ui object with the full name
    __Static__() __Arguments__{ NEString }
    function FromName(name)
        local obj

        for str in name:gmatch("[^%.]+") do
            if not obj then
                obj             = validate(UI, _G[str], true)
            else
                local children  = _ChildMap[obj[0]]
                obj             = children and children[str]
            end
            if not obj then return end
        end

        return obj
    end

    ----------------------------------------------
    --                 Methods                  --
    ----------------------------------------------
    --- Gets the ui object's name or full name
    __Final__() function GetName(self, full)
        local name              = _NameMap[self[0]]
        if full then
            local globalUI      = _G[name]
            if globalUI and (globalUI == self or IsSameUI(self, globalUI)) then
                return name
            else
                local parent    = self:GetParent()
                local pname     = parent and parent:GetName(true)
                if pname then return pname .. "." .. name end
            end
        else
            return name
        end
    end

    --- Gets the parent of ui object
    __Final__() function GetParent(self)
        return GetProxyUI(_GetParent[getmetatable(self)](self))
    end

    --- Sets the ui object's name
    __Final__() __Arguments__{ NEString }
    function SetName(self, name)
        local oname             = _NameMap[self[0]]
        if oname == name then return end

        local globalUI          = _G[oname]
        if globalUI and (globalUI == self or IsSameUI(self, globalUI)) then
            error("Usage: UI:SetName(name) - UI with global name can't change its name", 2)
        end

        local parent            = self:GetParent()
        if parent then
            local pui           = parent[0]
            local children      = _ChildMap[pui]

            if children and children[name] then
                error("Usage: UI:SetName(name) - the name is used by another child", 2)
            end

            if not children then
                children        = {}
                _ChildMap[pui]  = children
            end

            children[oname]     = nil
            children[name]      = self
        end

        _NameMap[self[0]]       = name
    end

    --- Sets the ui object's parent
    __Final__() __Arguments__{ UI/nil }
    function SetParent(self, parent)
        local oparent           = self:GetParent()
        if oparent == parent or IsSameUI(oparent, parent) then return end

        local name              = _NameMap[self[0]]
        local setParent         = _SetParent[getmetatable(self)]

        if oparent then
            local pui           = oparent[0]
            if _ChildMap[pui] and _ChildMap[pui][name] == self then
                _ChildMap[pui][name] = nil
            end
        end

        if parent == nil then return setParent(self, nil) end

        local pui               = parent[0]
        local children          = _ChildMap[pui]

        if children and children[name] and children[name] ~= self then
            error("Usage : UI:SetParent([parent]) : parent has another child with the same name.", 2)
        end

        setParent(self, GetRawUI(parent))

        if not children then
            children            = {}
            _ChildMap[pui]      = children
        end

        children[name]          = self
    end

    --- Gets the children of the frame
    __Iterator__() function GetChildren(self)
        local children          = _ChildMap[self[0]]
        if children then
            for name, child in pairs(children) do
                yield(name, child)
            end
        end
    end

    --- Gets the child with the given name
    function GetChild(self, name)
        local children          = _ChildMap[self[0]]
        return children and children[child]
    end

    ----------------------------------------------
    --                 Dispose                  --
    ----------------------------------------------
    function Dispose(self)
        local ui                = self[0]
        local name              = _NameMap[ui]

        self:SetParent(nil)

        -- Dispose the children
        local children          = _ChildMap[ui]
        if children then
            for _, obj in pairs(children) do obj:Dispose() end
        end

        -- Clear it from the _G
        local globalUI          = _G[name]
        if globalUI and (globalUI == self or IsSameUI(self, globalUI)) then
            _G[name]            = nil
        end

        -- Clear register datas
        _NameMap[ui]            = nil
        _ChildMap[ui]           = nil
    end

    ----------------------------------------------
    --               Constructor                --
    ----------------------------------------------
    __Arguments__{ NEString, UI/UIParent, Any * 0 }
    function __ctor(self, name, parent, ...)
        parent                  = parent[0]

        local children          = _ChildMap[parent]

        if not children then
            children            = {}
            _ChildMap[parent]   = children
        end

        children[name]          = self
        _NameMap[self[0]]       = name
    end

    __Arguments__{ NEString, UI/UIParent, Any * 0 }
    function __exist(cls, name, parent, ...)
        local children          = _ChildMap[parent[0]]
        local object            = children and children[name]

        if object then
            if getmetatable(object) == cls then
                return object
            else
                throw(("Usage : %s(name, parent, ...) - the parent already has a child named '%s'."):format(GetNamespaceName(cls), name))
            end
        end
    end

    ----------------------------------------------
    --               Meta-Method                --
    ----------------------------------------------
    __index                     = GetChild
end)

--- Region is the basic type for anything that can occupy an area of the screen
__Sealed__() __Abstract__()
class "Region" (function(_ENV)
    inherit "UIObject"

    local _GetPoint             = getRealMethodCache("GetPoint")

    ----------------------------------------------
    --                 Helpers                  --
    ----------------------------------------------
    local function GetPos(self, point, e)
        local x, y              = self:GetCenter()

        if strfind(point, "TOP") then
            y                   = self:GetTop()
        elseif strfind(point, "BOTTOM") then
            y                   = self:GetBottom()
        end

        if strfind(point, "LEFT") then
            x                   = self:GetLeft()
        elseif strfind(point, "RIGHT") then
            x                   = self:GetRight()
        end

        return x * e, y * e
    end

    ----------------------------------------------
    --                 Methods                  --
    ----------------------------------------------
    --- Gets the anchor point of the given index
    __Final__() function GetPoint(self, index)
        local p, f, r, x, y     = _GetPoint[getmetatable(self)](self, index)
        return p, GetProxyUI(f), r, x, y
    end

    --- Get the region object's location(Type: Anchors), the data is serializable, can be saved directly.
    -- You can also apply a data of Anchors to get a location based on the data's point, relativeTo and relativePoint settings.
    __Arguments__{}:Throwable()
    function GetLocation(self)
        local loc               = {}
        local parent            = self:GetParent()

        for i = 1, self:GetNumPoints() do
            local p, f, r, x, y = self:GetPoint(i)

            f                   = f or parent
            if IsSameUI(f, parent) then
                -- Don't save parent
                f               = nil
            elseif parent and IsSameUI(f:GetParent(), parent) then
                -- Save the brother's name
                f               = f:GetName()
            else
                local uname     = f:GetName(true)
                if not uname then throw("Usage: Region:GetLocation() - The System can't identify the relativeTo frame.") end
                f               = uname
            end

            if r == p then r    = nil end
            if x == 0 then x    = nil end
            if y == 0 then y    = nil end

            loc[i]              = Anchor(p, x, y, f, r)
        end

        return loc
    end

    __Arguments__{ Anchors }:Throwable()
    function GetLocation(self, oLoc)
        local loc               = {}
        local parent            = self:GetParent()

        for i, anchor in ipairs(oLoc) do
            local relativeTo    = anchor.relativeTo
            local relativeFrame

            if relativeTo then
                relativeFrame   = parent and parent.Children[relativeTo] or UI.GetUniqueObject(relativeTo)

                if not relativeFrame then
                    throw("Usage: Region:GetLocation(accordingLoc) - The System can't identify the relativeTo frame.")
                end
            else
                relativeFrame   = parent
            end

            if relativeFrame then
                local e         = self:GetEffectiveScale()/UIParent:GetScale()
                local x, y      = GetPos(self, anchor.point, e)
                local rx, ry    = GetPos(relativeFrame, anchor.relativePoint or anchor.point, e)

                tinsert(loc, Anchor(anchor.point, (x-rx)/e, (y-ry)/e, relativeTo, anchor.relativePoint or anchor.point))
            end
        end

        return loc
    end

    --- Set the region object's location
    function SetLocation(self, loc)
        if #loc > 0 then
            local parent = self:GetParent()

            self:ClearAllPoints()
            for _, anchor in ipairs(loc) do
                local relativeTo = anchor.relativeTo

                if relativeTo then
                    relativeTo = parent and parent.Children[relativeTo] or UI.GetUniqueObject(relativeTo)

                    if not relativeTo then
                        error("Usage: Region:SetLocation(loc) - The System can't identify the relativeTo frame.", 2)
                    end
                else
                    relativeTo = parent
                end

                if relativeTo then
                    self:SetPoint(anchor.point, relativeTo, anchor.relativePoint or anchor.point, anchor.x or 0, anchor.y or 0)
                end
            end
        end
    end

    ----------------------------------------------
    --                 Dispose                  --
    ----------------------------------------------
    function Dispose(self)
        self:SetUserPlaced(false)
        self:ClearAllPoints()
        self:Hide()
    end
end)