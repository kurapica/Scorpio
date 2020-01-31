--========================================================--
--                Scorpio Core System                     --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/01/26                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.UI.Core"                  "1.0.0"
--========================================================--

local isTypeValidDisabled       = System.Platform.TYPE_VALIDATION_DISABLED
local isUIObject                = UI.IsUIObject
local isUIObjectType            = UI.IsUIObjectType
local clone                     = Toolset.clone
local yield                     = coroutine.yield
local tinsert                   = table.insert
local strlower                  = strlower
local gettable                  = function(self, key) local val = self[key] if not val then val = {} self[key] = val end return val end

----------------------------------------------
--                 NIL Value                --
----------------------------------------------
local NIL                       = Namespace.SaveNamespace("Scorpio.UI.NIL", prototype { __tostring = function() return "nil" end })

----------------------------------------------
--            Helper - UIObject             --
----------------------------------------------

----------------------------------------------
--            Helper - Property             --
----------------------------------------------
local _Property                 = {}

local function dispatchPropertySetting(cls, prop, setting, oldsetting, root)
    local settings              = _Property[cls]
    if not settings then
        settings                = {}
        _Property[cls]          = settings
    end

    if root then
        oldsetting              = settings[prop]
    elseif settings[prop] and oldsetting ~= settings[prop] then
        return
    end

    settings[prop]              = setting

    for scls in Class.GetSubTypes(cls) do
        dispatchPropertySetting(scls, prop, setting, oldsetting)
    end
end

Runtime.OnTypeDefined           = Runtime.OnTypeDefined + function(ptype, cls)
    if ptype == Class and IsUIObjectType(cls) then
        if _Property[cls] then return end

        local super             = Class.GetSuperClass(cls)
        if super and _Property[super] then
            _Property[cls]      = clone(_Property[super])
        end
    end
end

local function applyProperty(self, prop, value)
    if value == nil then
        if prop.clear then return prop.clear(self) end
        if prop.default then return prop.set(self, clone(prop.default, true)) end
        if prop.nilable then return prop.set(self, nil) end
    else
        prop.set(self, clone(value, true))
    end
end

----------------------------------------------
--              Helper - Style              --
----------------------------------------------
local _StyleMethods             = {}
local _StyleOwner               = {}
local _StyleAccessor
local _StyleQueue               = Queue()
local _ClassQueue               = Queue()
local _ClassQueueInfo           = {}
local _Recycle                  = Recycle()

_DefaultStyle             = {}
_CustomStyle              = setmetatable({}, META_WEAKKEY)
_TempStyle                = {}
_TempPath                 = {}
local _Inited                   = false

local _ClassMap                 = {}

local function applyDefaultStyle(frame)
    if frame.Disposed then return end

    local props                 = _Property[getmetatable(frame)]

    for name, value in pairs(_TempStyle) do
        if value == NIL then value = nil end
        Trace("[Scorpio.UI.Apply]%s", name)
        applyProperty(frame, props[name], value)
    end
end

local function buildTempStyle(frame)
    Trace("[Scorpio.UI.buildTempStyle]%s", frame:GetName(true))

    wipe(_TempStyle)
    wipe(_TempPath)

    -- Custom -> Root Parent Class -> ... -> Parent Class -> Frame Class -> Super Class
    local name                  = UIObject.GetName(frame)
    local parent                = UIObject.GetParent(frame)

    while parent do
        local cls               = getmetatable(parent)
        if cls and isUIObjectType(cls) then
            tinsert(_TempPath, 1, name)

            local default       = _DefaultStyle[cls]
            local index         = 1

            while default and _TempPath[index] do
                default         = default[0]
                default         = default and default[_TempPath[index]]
                index           = index + 1
            end

            if default then
                -- The parent -> ... -> child style settings
                for prop, value in pairs(default) do
                    if prop ~= 0 then
                        if value == NIL then
                            if _TempStyle[prop] == nil then
                                _TempStyle[prop] = NIL
                            end
                        else
                            _TempStyle[prop] = value
                        end
                    end
                end
            end

            name                = UIObject.GetName(parent)
            parent              = UIObject.GetParent(parent)
        else
            break
        end
    end

    if _CustomStyle[frame] then
        for prop, value in pairs(_CustomStyle[frame]) do
            if value == NIL then
                if _TempStyle[prop] == nil then
                    _TempStyle[prop] = NIL
                end
            else
                _TempStyle[prop] = value
            end
        end
    end

    local cls                   = getmetatable(frame)

    while cls do
        local default           = _DefaultStyle[cls]

        if default then
            for prop, value in pairs(default) do
                if prop ~= 0 then
                    local pval  = _TempStyle[prop]

                    if pval == nil or pval == NIL then
                        _TempStyle[prop] = value
                    end
                end
            end
        end

        cls                     = Class.GetSuperClass(cls)
    end
end

local function processStyleApply()
    _Inited                     = true

    while _StyleQueue.Count > 0 do
        local frame             = _StyleQueue:Peek()

        Trace("[Scorpio.UI]Apply Style To Frame: %s", frame:GetName(true))

        if not frame.Disposed then
            buildTempStyle(frame)
            _StyleQueue[frame]  = nil

            Continue()

            applyDefaultStyle(frame)

            Continue()
        else
            _StyleQueue[frame]  = nil
        end

        _StyleQueue:Dequeue()
    end
end

local function applyStyle(frame)
    if _StyleQueue[frame] then return end
    if _StyleQueue.Count == 0 then Next(processStyleApply) end
    _StyleQueue[frame]          = true
    _StyleQueue:Enqueue(frame)
    Trace("[Scorpio.UI]Queue %s", frame:GetName(true) or "nil")
end

local function processClassStyleApply()
    while _ClassQueue.Count > 0 do
        local class             = _ClassQueue:Peek()
        local info              = _ClassQueueInfo[class]
        _ClassQueueInfo[class]  = nil
        _ClassQueue[class]      = nil -- Allow queue again

        local count             = 1
        local frames            = _ClassMap[class]

        if frames then
            for frame in pairs(frames) do
                for path in pairs(info) do
                    local frm   = frame

                    if path == "" then
                        applyStyle(frame)
                        count   = count + 1
                    else
                        for p in path:gmatch("[^^]+") do
                            frm = UIObject.GetChild(frm, p)
                            if not frm then break end
                        end

                        if frm then
                            applyStyle(frm)
                            count = count + 1
                        end
                    end
                end

                if count > 10 then
                    count       = 0
                    Continue()
                end
            end
        end

        wipe(info)
        _Recycle(info)

        Continue()

        _ClassQueue:Dequeue()
    end
end

local function applyClassStyle(class, ...)
    if not _Inited then return end
    if _ClassQueue.Count == 0 then Next(processClassStyleApply) end

    if not _ClassQueue[class] then
        _ClassQueue:Enqueue(class)
        _ClassQueue[class]      = true
    end

    local info                  = _ClassQueueInfo[class] or _Recycle()
    _ClassQueueInfo[class]      = info

    local count                 = select("#", ...)
    if count == 0 then
        info[""]                = true
    else
        local s                 = select(1, ...)
        for i = 2, count do
            s                   = s .. "^" .. select(i, ...)
        end
        info[s]                 = true
    end
end

local function setTargetStyle(value, stack)
    local target                = _StyleOwner[1]
    local tarcls, default
    local pname

    if isUIObject(target) then
        for i = 2, #_StyleOwner do
            local name          = _StyleOwner[i]
            local child         = UIObject.GetChild(target, name)

            if not child then
                if i == #_StyleOwner then
                    tarcls      = getmetatable(target)
                    name        = strlower(name)

                    if _Property[tarcls] and _Property[tarcls][name] then
                        pname   = name
                    end
                end

                if not pname then
                    error("The target of the style settings doesn't existed", stack + 1)
                end
            else
                target          = child
            end
        end

        tarcls                  = getmetatable(target)
        default                 = gettable(_CustomStyle, target)
        applyStyle(target)
    elseif isUIObjectType(target) then
        default                 = gettable(_DefaultStyle, target)
        tarcls                  = target

        for i = 2, #_StyleOwner do
            local name          = _StyleOwner[i]
            local childtype     = __Template__.GetElementType(tarcls, name)
            if not childtype then
                if i == #_StyleOwner then
                    name        = strlower(name)

                    if _Property[tarcls] and _Property[tarcls][name] then
                        pname   = name
                    end
                end

                if not pname then
                    error("The target of the style settings doesn't existed", stack + 1)
                end
            else
                tarcls          = childtype
                default         = gettable(gettable(default, 0), name)
            end
        end

        applyClassStyle(unpack(_StyleOwner, 1, #_StyleOwner - (pname and 1 or 0)))
    else
        error("The target of the style settings isn't valid", stack + 1)
    end

    local props                 = _Property[tarcls]
    if not props then error("The target has no property definitions", stack + 1) end

    if pname then
        local prop              = props[pname]

        if value == nil or value == NIL then
            default[pname]      = NIL
        else
            if prop.validate then
                local ret, msg  = prop.validate(prop.type, value)
                if msg then error(Struct.GetErrorMessage(msg, prop.name), stack + 1) end
                value           = ret
            end

            default[pname]      = value
        end
    else
        if type(value) ~= "table" then
            error("The style settings must be property key value pair or a table contains the key-value pairs", stack + 1)
        end

        for pn, pv in pairs(value) do
            local ln            = strlower(pn)
            local prop          = props[ln]
            if not prop then error(strformat("The %q isn't a valid property for the target", pn), stack + 1) end

            if pv == NIL then
                default[ln]     = NIL
            else
                if prop.validate then
                    local ret, msg = prop.validate(prop.type, value)
                    if msg then error(Struct.GetErrorMessage(msg, prop.name), stack + 1) end
                    value       = ret
                end

                default[ln]     = value
            end
        end
    end
end

local function registerFrame(cls, frame)
    local map                   = _ClassMap[cls]
    if not map then
        map                     = setmetatable({}, META_WEAKKEY)
        _ClassMap[cls]          = map
    end

    map[frame]                  = true

    applyStyle(frame)
end

local function unregisterFrame(frame)
    _ClassMap[getmetatable(frame)][frame] = nil
end

----------------------------------------------
--                 UIObject                 --
----------------------------------------------
__Abstract__() __Sealed__() class "UIObject"(function(_ENV)

    ----------------------------------------------
    --                 Helpers                  --
    ----------------------------------------------
    local _NameMap              = setmetatable({}, META_WEAKKEY)
    local _ChildMap             = setmetatable({}, META_WEAKKEY)

    local _SetParent            = getRealMethodCache("SetParent")
    local _GetParent            = getRealMethodCache("GetParent")
    local _GetNew               = getRealMetaMethodCache("__new")

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
    __Iterator__() function GetChilds(self)
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
        return children and children[name]
    end

    ----------------------------------------------
    --                 Dispose                  --
    ----------------------------------------------
    function Dispose(self)
        local ui                = self[0]
        local name              = _NameMap[ui]

        unregisterFrame(self)

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
    __Final__() __Arguments__{ NEString, UI/UIParent, Any * 0 }
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

    __Final__() __Arguments__{ NEString, UI/UIParent, Any * 0 }
    function __new(cls, name, parent, ...)
        local self              = _GetNew[cls](cls, name, parent, ...)
        parent                  = parent[0]

        local children          = _ChildMap[parent]

        if not children then
            children            = {}
            _ChildMap[parent]   = children
        end

        children[name]          = self
        _NameMap[self[0]]       = name

        registerFrame(cls, self)

        return self
    end

    ----------------------------------------------
    --               Meta-Method                --
    ----------------------------------------------
    __index                     = GetChild
end)

----------------------------------------------
--                 Template                 --
----------------------------------------------
__Sealed__() class "__Template__" (function (_ENV)
    extend "IInitAttribute"

    local _Template             = {}

    local isUIObjectType        = UI.IsUIObjectType
    local getSuperCTOR          = Class.GetSuperMetaMethod
    local yield                 = coroutine.yield

    -----------------------------------------------------------
    --                     static method                     --
    -----------------------------------------------------------
    __Static__() __Iterator__()
    function GetElements(cls)
        local elements          = _Template[cls]
        if not elements then return end
        for k, v in pairs(elements) do yield(k, v) end
    end

    __Static__()
    function GetElementType(cls, name)
        local elements          = _Template[cls]
        return elements and elements[name]
    end

    -----------------------------------------------------------
    --                        method                         --
    -----------------------------------------------------------
    --- modify the target's definition
    -- @param   target                      the target
    -- @param   targettype                  the target type
    -- @param   definition                  the target's definition
    -- @param   owner                       the target's owner
    -- @param   name                        the target's name in the owner
    -- @param   stack                       the stack level
    -- @return  definition                  the new definition
    function InitDefinition(self, target, targettype, definition, owner, name, stack)
        if targettype == AttributeTargets.Method then
            if name ~= "__ctor" then
                error("The __Template__ can only be used on the constructor, not nomral method", stack + 1)
            end

            if type(self[1]) ~= "table" then
                error("The __Template__ lack the element settings", stack + 1)
            end

            local elements      = {}

            for k, v in pairs(self[1]) do
                if type(k) == "string" and isUIObjectType(v) then
                    elements[k] = v
                else
                    error("The __Template__'s element type must be an ui object type", stack + 1)
                end
            end

            _Template[owner]    = elements

            return function(self, ...)
                for k, v in pairs(elements) do
                    v(k, self)
                end

                return definition(self, ...)
            end
        elseif targettype == AttributeTargets.Class then
            if type(definition) == "table" then
                local new       = { self[0] }
                local elements  = {}

                for k, v in pairs(definition) do
                    if type(k) == "string" and isUIObjectType(v) then
                        elements[k] = v
                    else
                        new[k]  = v
                    end
                end

                _Template[target] = elements

                new.__ctor      = function(self, ...)
                    local sctor = getSuperCTOR(target, "__ctor")
                    if sctor then sctor(self, ...) end

                    for k, v in pairs(elements) do
                        v(k, self)
                    end
                end

                return new
            else
                error("The __Template__ require the class use table of element type settings as definition", stack + 1)
            end
        end
    end

    -----------------------------------------------------------
    --                       property                       --
    -----------------------------------------------------------
    property "AttributeTarget"  { type = AttributeTargets,  default = AttributeTargets.Method + AttributeTargets.Class }

    -----------------------------------------------------------
    --                      constructor                      --
    -----------------------------------------------------------
    __Arguments__{ ClassType/nil }
    function __new(_, cls) return { [0] = cls }, true end

    __Arguments__{ RawTable }
    function __new(_, setting) return { setting }, true  end
end)

----------------------------------------------
--              Style Property              --
----------------------------------------------
__Sealed__() struct "Scorpio.UI.Property" {
    name                        = { type  = NEString, require = true },
    type                        = { type  = AnyType },
    require                     = { type  = ClassType + struct { ClassType }, require = true },
    set                         = { type  = Function, require = true },
    get                         = { type  = Function },
    clear                       = { type  = Function },
    default                     = { type  = Any },
    nilable                     = { type  = Boolean },

    __init                      = function(self)
        local setting           = {
            name                = self.name,
            type                = self.type,
            set                 = self.set,
            get                 = self.get,
            clear               = self.clear,
            default             = clone(self.default, true),
            nilable             = self.nilable,
        }

        if self.type then
            if isTypeValidDisabled then
               if Struct.Validate(self.type) and not Struct.IsImmutable(self.type) then
                    setting.validate = Struct.ValidateValue
                end
            else
                if Enum.Validate(self.type) then
                    setting.validate = Enum.ValidateValue
                elseif Struct.Validate(self.type) then
                    setting.validate = Struct.ValidateValue
                elseif Class.Validate(self.type) then
                    setting.validate = Class.ValidateValue
                elseif Interface.Validate(self.type) then
                    setting.validate = Interface.ValidateValue
                end
            end

            if setting.default ~= nil and setting.validate then
                setting.default = setting.validate(setting.type, setting.default)
            end
        end

        local name              = strlower(self.name)

        if isUIObjectType(self.require) then
            dispatchPropertySetting(self.require, name, setting, nil, true)
        else
            for _, cls in ipairs(self.require) do
                dispatchPropertySetting(cls, name, setting, nil, true)
            end
        end
    end,
}

----------------------------------------------
--              Style Accessor              --
----------------------------------------------
-- Style[UnitFrame].HealthBar.Color = { r = 1, g = 0, b = 0 }
-- Style[frame].Alpha               = 0.5
-- Style[UnitFrame].HealthBar       = { color = { r = 1, g = 0, b = 1 }, alpha = 0.8 }
local Style                     = Namespace.SaveNamespace("Scorpio.UI.Style", prototype {
    __tostring                  = Namespace.GetNamespaceName,
    __index                     = function(self, key)
        if type(key) == "string" then
            return _StyleMethods[key]
        end

        if isUIObject(key) or isUIObjectType(key) then
            wipe(_StyleOwner)[1]= key
            return _StyleAccessor
        end
    end,
    __newindex                  = function(self, key, value)
        if type(key) == "string" and type(value) == "function" then
            if _StyleMethods[key] then
                error(("The method named %s already existed in Scorpio.UI.Style"):format(key), 2)
            end

            _StyleMethods[key]  = value
            return
        end

        if isUIObject(key) or isUIObjectType(key) then
            wipe(_StyleOwner)[1]= key
            setTargetStyle(value, 2)
        end

        error("The Scorpio.UI.Style access is denied", 2)
    end
})

_StyleAccessor                  = prototype {
    __metatable                 = Style,
    __index                     = function(self, key)
        local len               = #_StyleOwner
        if len > 0 and type(key) == "string" then
            _StyleOwner[len + 1]= key
            return _StyleAccessor
        else
            error("The sub key must be string", 2)
        end
    end,
    __newindex                  = function(self, key, value)
        local len               = #_StyleOwner
        if len > 0 and type(key) == "string" then
            _StyleOwner[len + 1]= key
            setTargetStyle(value, 2)
        else
            error("The sub key must be string", 2)
        end
    end
}
