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
local NIL                       = Namespace.SaveNamespace("Scorpio.UI.NIL", prototype { __tostring = function() return "nil" end })
local gettable                  = function(self, key) local val = self[key] if not val or val == NIL then val = {} self[key] = val end return val end

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
        if not _Property[cls] then
            local super         = Class.GetSuperClass(cls)
            if super and _Property[super] then
                _Property[cls]  = clone(_Property[super])
            end
        end

        local _Prop             = System.Property

        -- Scan the class's property
        for name, feature in Class.GetFeatures(cls) do
            if _Prop.Validate(feature) and not _Prop.IsStatic(feature) and _Prop.IsWritable(feature) then
                Trace("[Scorpio.UI.Core]Define Property %s for %s", name, tostring(cls))

                UI.Property     {
                    name        = name,
                    type        = _Prop.GetType(feature),
                    require     = cls,
                    set         = function(self, val) self[name] = val end,
                    get         = _Prop.IsReadable(feature) and function(self) return self[name] end or nil,
                    default     = _Prop.GetDefault(feature),
                    nilable     = not _Prop.IsValueRequired(feature),
                }
            end
        end
    end
end

local function applyProperty(self, prop, value)
    if value == nil then
        if prop.clear then return prop.clear(self) end
        if prop.default then return prop.set(self, clone(prop.default, true)) end
        if prop.nilable then return prop.set(self, nil) end
    elseif prop.childtype and type(value) == "table" and getmetatable(value) == nil then
        -- means settings to the child
        local child             = prop.get(self)
        if child then
            local props         = _Property[prop.childtype]

            for name, value in pairs(value) do
                if value == NIL then
                    applyProperty(child, props[name], nil)
                end
            end

            for name, value in pairs(value) do
                if value ~= NIL then
                    applyProperty(child, props[name], value)
                end
            end
        end
    else
        prop.set(self, clone(value, true))
    end
end

local function getUIPrototype(self)
    local cls                   = getmetatable(self)
    if isUIObjectType(cls) then return cls, true end
    if self.GetObjectType then return UI[self:GetObjectType()], false end
end

----------------------------------------------
--              Helper - Style              --
----------------------------------------------
local _StyleMethods             = {}
local _StyleOwner
local _StyleAccessor
local _StyleQueue               = Queue()
local _ClassQueue               = Queue()
local _ClassQueueInfo           = {}
local _Recycle                  = Recycle()

local _DefaultStyle             = {}
local _CustomStyle              = setmetatable({}, META_WEAKKEY)
local _TempStyle                = {}
local _TempPath                 = {}
local _TempClass                = {}
local _Inited                   = false

local _ClassMap                 = {}

local function applyDefaultStyle(frame)
    if frame.Disposed then return end

    local props                 = _Property[getmetatable(frame)]

    --- Apply the NIL value first to clear
    for name, value in pairs(_TempStyle) do
        if value == NIL then
            applyProperty(frame, props[name], nil)
        end
    end

    for name, value in pairs(_TempStyle) do
        if value ~= NIL then
            applyProperty(frame, props[name], value)
        end
    end
end

local function buildTempStyle(frame)
    wipe(_TempStyle)
    wipe(_TempPath)

    -- Custom -> Root Parent Class -> ... -> Parent Class -> Frame Class -> Super Class
    local name                  = UIObject.GetName(frame)
    local parent                = UIObject.GetParent(frame)

    while parent do
        local cls               = getmetatable(parent)
        wipe(_TempClass)

        if cls and isUIObjectType(cls) then
            tinsert(_TempPath, 1, name)

            repeat
                tinsert(_TempClass, cls)
                cls             = Class.GetSuperClass(cls)
            until not cls

            for i = #_TempClass, 1, -1 do
                cls                 = _TempClass[i]

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

        if not frame.Disposed then
            Trace("[Scorpio.UI.Core]Apply Style: %s", frame:GetName(true))

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

local function queueClassApply(class, ...)
    if not _ClassQueue[class] then
        _ClassQueue:Enqueue(class)
        _ClassQueue[class]      = true
    end

    local info                  = _ClassQueueInfo[class] or _Recycle()
    _ClassQueueInfo[class]      = info

    local count                 = select("#", ...)
    if count == 0 then
        if info[""] then return end
        info[""]                = true
    else
        local s                 = select(1, ...)
        for i = 2, count do
            s                   = s .. "^" .. select(i, ...)
        end
        if info[s] then return end
        info[s]                 = true
    end

    for scls in Class.GetSubTypes(class) do
        queueClassApply(scls, ...)
    end
end

local function applyClassStyle(class, ...)
    if not _Inited then return end
    if _ClassQueue.Count == 0 then Next(processClassStyleApply) end

    queueClassApply(class, ...)
end

local function setTargetStyle(target, pname, value, stack)
    local tarcls, isUICls       = getUIPrototype(target)
    local default               = isUICls and gettable(_CustomStyle, target)
    local hasnilset             = false

    local props                 = _Property[tarcls]
    if not props then error("The target has no property definitions", stack + 1) end

    if pname then
        local prop              = props[pname]

        if value == nil or value == NIL then
            hasnilset           = true
            if default then
                default[pname]  = NIL
            end

            applyProperty(target, prop, nil)
        elseif prop.childtype and type(value) == "table" and getmetatable(value) == nil then
            local child         = prop.get(target)
            if child then
                setTargetStyle(child, nil, value, stack + 1)
            else
                error(strformat("The target has no child element from %q", pname), stack + 1)
            end
        else
            if prop.validate then
                local ret, msg  = prop.validate(prop.type, value)
                if msg then error(Struct.GetErrorMessage(msg, prop.name), stack + 1) end
                value           = ret
            end

            if default then
                default[pname]  = value
            end

            applyProperty(target, prop, value)
        end
    else
        if type(value) ~= "table" then
            error("The style settings must be property key value pair or a table contains the key-value pairs", stack + 1)
        end

        for pn, pv in pairs(value) do
            if type(pn) ~= "string" then
                error("The style property name must be string", stack + 1)
            end

            local child         = UIObject.GetChild(target, pn)

            if child then
                setTargetStyle(child, nil, pv, stack + 1)
            else
                local ln        = strlower(pn)
                local prop      = props[ln]
                if not prop then error(strformat("The %q isn't a valid property for the target", pn), stack + 1) end

                if pv == NIL then
                    if default then default[ln] = NIL end
                    hasnilset   = true

                    applyProperty(target, prop, nil)
                elseif prop.childtype and type(pv) == "table" and getmetatable(pv) == nil then
                    child       = prop.get(target)
                    if child then
                        setTargetStyle(child, nil, pv, stack + 1)
                    else
                        error(strformat("The target has no child element from %q", pname), stack + 1)
                    end
                else
                    if prop.validate then
                        local ret, msg = prop.validate(prop.type, pv)
                        if msg then error(Struct.GetErrorMessage(msg, prop.name), stack + 1) end
                        pv      = ret
                    end

                    if default then default[ln] = pv end

                    applyProperty(target, prop, pv)
                end
            end
        end
    end

    if hasnilset and isUICls then
        return applyStyle(target)
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

local function emptyDefaultStyle(settings)
    if settings then
        for k, v in pairs(settings) do
            if k == 0 then
                for child, csetting in pairs(v) do
                    emptyDefaultStyle(csetting)
                end
            else
                settings[k]     = NIL
            end
        end
    end

    return settings
end

----------------------------------------------
--              Helper - Skin               --
----------------------------------------------
local _Skins                    = {}
local _ActiveSkin               = {}

local function copyBaseSkinSettings(container, base)
    for k, v in pairs(base) do
        if k == 0 then
            for name, setting in pairs(v) do
                copyBaseSkinSettings(gettable(gettable(container, 0), name), setting)
            end
        else
            container[k]        = v
        end
    end
end

local function saveSkinSettings(class, container, settings)
    if type(settings) ~= "table" then
        throw("The skin settings for " .. class ..  "must be table")
    end

    local props                 = _Property[class]

    -- Check inherit
    for name, value in pairs(settings) do
        if type(name) ~= "string" then
            throw("The skin settings only accpet string values as key")
        end
        if strlower(name) == "inherit" then
            settings[name]      = nil

            if type(value) ~= "string" then
                throw("The inherit only accpet skin name as value")
            end
            local base          = _Skins[strlower(value)]
            if not base then
                throw(strformat("The skin named %q doesn't existed", value))
            elseif not base[class] then
                throw(strformat("The skin named %q doesn't provide skin for %s", value, tostring(class)))
            end

            copyBaseSkinSettings(container, base[class])

            break
        end
    end

    for name, value in pairs(settings) do
        local element           = __Template__.GetElementType(class, name)
        if element then
            saveSkinSettings(element, gettable(gettable(container, 0), name), value)
        elseif props then
            name                = strlower(name)
            local prop          = props[name]

            if not prop then
                throw(strformat("The %q isn't a valid property for %s", name, tostring(class)))
            end

            if value == nil or value == NIL then
                container[name] = NIL
            elseif prop.childtype and type(value) == "table" and getmetatable(value) == nil then
                saveSkinSettings(prop.childtype, gettable(container, name), value)
            else
                if prop.validate then
                    local ret, msg  = prop.validate(prop.type, value)
                    if msg then throw(Struct.GetErrorMessage(msg, prop.name)) end
                    value           = ret
                end

                container[name]     = value
            end
        else
            throw("The " .. class .. " has no property definitions")
        end
    end
end

local function copyToDefault(settings, default, ...)
    local temp                  = { ... }
    local nxt                   = #temp + 1
    for name, value in pairs(settings) do
        if name == 0 then
            for element, setting in pairs(value) do
                temp[nxt]       = element
                copyToDefault(setting, gettable(gettable(default, 0), element), unpack(temp))
            end
        else
            default[name]       = value
        end
    end

    applyClassStyle(...)
end

local function activeSkin(name, class, skin, force)
    if force and _ActiveSkin[class] and _ActiveSkin[class] ~= name then return end
    if not force and _ActiveSkin[class] == name then return end
    _ActiveSkin[class] = name

    local default                   = emptyDefaultStyle(_DefaultStyle[class]) or {}
    _DefaultStyle[class]            = default

    copyToDefault(skin, default, class)
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
    local isClass               = Class.Validate

    ----------------------------------------------
    --                  event                   --
    ----------------------------------------------
    -- Fired when parent is changed
    event "OnParentChanged"

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

    __Final__() function GetDebugName(self)
        return self:GetName(true)
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

        OnParentChanged(self, parent, oparent)
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

    __Final__() __Arguments__{ UI }
    function __exist(cls, ui)
        local proxy             = UI.GetProxyUI(ui)
        if proxy and isClass(getmetatable(proxy)) then return proxy end
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

    __Final__() __Arguments__{ UI }
    function __new(cls, ui)
        local self              = { [0] = ui[0] }
        UI.RegisterProxyUI(self)
        UI.RegisterRawUI(ui)
        return self
    end

    ----------------------------------------------
    --               Meta-Method                --
    ----------------------------------------------
    __index                     = GetChild
end)

----------------------------------------------
--               __Bubbling__               --
----------------------------------------------
__Sealed__() class "__Bubbling__" (function(_ENV)
    extend "IApplyAttribute"

    local getChild              = UIObject.GetChild

    -----------------------------------------------------------
    --                       property                        --
    -----------------------------------------------------------
    property "AttributeTarget"  { set = false, default = AttributeTargets.Event }

    -----------------------------------------------------------
    --                        method                         --
    -----------------------------------------------------------
    --- apply changes on the target
    -- @param   target                      the target
    -- @param   targettype                  the target type
    -- @param   manager                     the definition manager of the target
    -- @param   owner                       the target's owner
    -- @param   name                        the target's name in the owner
    -- @param   stack                       the stack level
    function ApplyAttribute(self, target, targettype, manager, owner, name, stack)
        local map               = self[1]

        Event.SetEventChangeHandler(target, function(delegate, owner, eventname)
            if not delegate.PopupeBinded then
                delegate.PopupeBinded = true

                for name, event in pairs(map) do
                    local child = type(name) == "number" and owner or getChild(owner, name)

                    if not child then
                        error(("The child named %q doesn't existed in object of %s"):format(name, tostring(getmetatable(owner))))
                    elseif not child:HasScript(event) then
                        if child == owner then
                            error(("The object of %s doesn't have an event named %q"):format(tostring(getmetatable(owner)), event))
                        else
                            error(("The child named %q in object of %s doesn't have an event named %q"):format(name, tostring(getmetatable(owner)), event))
                        end
                    end

                    child:HookScript(event, function(self, ...)
                        return delegate(owner, ...)
                    end)
                end
            end
        end, stack + 1)
    end

    -----------------------------------------------------------
    --                      constructor                      --
    -----------------------------------------------------------
    __Arguments__{ struct { [NEString] = NEString } }
    function __new(_, map)
        return { map }, true
    end
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
    local getSuperClass         = Class.GetSuperClass

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
        repeat
            local elements      = _Template[cls]
            local type          = elements and elements[name]
            if type then return type end

            cls                 = getSuperClass(cls)
        until not cls
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
                local sctor = getSuperCTOR(owner, "__ctor")
                if sctor then sctor(self, ...) end

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
    __Arguments__{ - UIObject/nil }
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
    set                         = { type  = Function },
    get                         = { type  = Function },
    clear                       = { type  = Function },
    default                     = { type  = Any },
    nilable                     = { type  = Boolean },
    childtype                   = { type  = - UIObject },

    __valid                     = function(self)
        if self.childtype then
            if self.set and not self.get then
                return "%s.get is required if it represent a child element"
            end
        else
            if not self.set then
                return "%s.set is required"
            end
        end
    end,

    __init                      = function(self)
        local setting           = {
            name                = self.name,
            type                = self.type,
            set                 = self.set,
            get                 = self.get,
            clear               = self.clear,
            default             = clone(self.default, true),
            nilable             = self.nilable,
            childtype           = self.childtype,
        }

        if self.childtype and not self.get and not self.set then
            local childtype     = self.childtype
            local childname     = Namespace.GetNamespaceName(childtype):gsub("%.", "_")

            setting.get         = function(self)
                local child     = childtype(childname, self)
                child:Show()
                return child
            end

            if self.nilable then
                setting.type    = setting.type or self.childtype
                setting.set     = function(self, child)
                    if child then
                        child:SetParent(self)
                        child:SetName(childname)
                        child:Show()
                    elseif self:GetChild(childname) then
                        self:GetChild(childname):Hide()
                    end
                end
            end
        end

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

        if isUIObject(key) then
            _StyleOwner         = key
            return _StyleAccessor
        end
    end,
    __newindex                  = function(self, key, value)
        if type(key) == "string" and type(value) == "function" then
            if _StyleMethods[key] then
                error(("The method named %s already existed in Scorpio.UI.Style"):format(key), 2)
            end

            if Attribute.HaveRegisteredAttributes() then
                Attribute.SaveAttributes(value, AttributeTargets.Function, 2)
                local ret       = Attribute.InitDefinition(value, AttributeTargets.Function, value, self, key, 2)
                if ret ~= value then
                    Attribute.ToggleTarget(value, ret)
                    value        = ret
                end
                Attribute.ApplyAttributes (value, AttributeTargets.Function, nil, self, key, 2)
                Attribute.AttachAttributes(value, AttributeTargets.Function, self, key, 2)
            end

            _StyleMethods[key]  = value
            return
        end

        if isUIObject(key) then
            setTargetStyle(key, nil, value, 2)
            return
        end

        error("The Scorpio.UI.Style access is denied", 2)
    end
})

_StyleAccessor                  = prototype {
    __metatable                 = Style,
    __index                     = function(self, key)
        local target            = _StyleOwner
        if target and type(key) == "string" then
            local star          = UIObject.GetChild(target, key)
            if star then
                _StyleOwner     = star
                return _StyleAccessor
            else
                _StyleOwner     = nil

                local cls       = getUIPrototype(target)
                local prop      = cls and _Property[cls] and _Property[cls][strlower(key)]
                if prop then return prop.get and prop.get(target) end
            end
        end

        _StyleOwner             = nil
        error("The sub key must be child name or property name", 2)
    end,
    __newindex                  = function(self, key, value)
        local target            = _StyleOwner
        _StyleOwner             = nil

        if target and type(key) == "string" then
            local star          = UIObject.GetChild(target, key)
            if star then
                setTargetStyle(star, nil, value, 2)
                return
            else
                key             = strlower(key)
                local cls       = getUIPrototype(target)
                local prop      = cls and _Property[cls] and _Property[cls][key]
                if prop then
                    setTargetStyle(target, key, value, 2)
                    return
                end
            end
        end

        error("The sub key must be child name or property name", 2)
    end
}

__Iterator__() __Arguments__{ UI }
function Style.GetCustomStyles(frame)
    local custom                = _CustomStyle[frame]
    if custom then
        local props             = _Property[getmetatable(frame)]

        for name, value in pairs(custom) do
            yield(props[name].name, (clone(value)))
        end
    end
end

__Arguments__{ - UIObject, NEString * 0 } __Iterator__()
function Style.GetDefaultStyles(class, ...)
    local default               = _DefaultStyle[class]

    if default then
        for i = 1, select("#", ...) do
            local name          = select(i, ...)
            class               = __Template__.GetElementType(class, name)
            if not class then return end

            default             = default[0]
            default             = default and default[name]
            if not default then return end
        end

        local props             = _Property[class]

        for name, value in pairs(default) do
            if name ~= 0 then
                yield(props[name].name, (clone(value)))
            end
        end
    end
end

----------------------------------------------
--               Skin System                --
----------------------------------------------
local SkinSettings              = struct { [ - UIObject ] = Table }

__Arguments__{ NEString, SkinSettings/nil }:Throwable()
function Style.RegisterSkin(name, settings)
    name                        = strlower(name)

    if _Skins[name] then
        throw("Usage: Style.RegisterSkin(name, settings) - the name is already used")
    end

    local skins                 = {}
    _Skins[name]                = skins

    if settings then
        for class, setting in pairs(settings) do
            local skin          = {}
            skins[class]        = skin

            saveSkinSettings(class, skin, setting)
        end
    end
end

__Arguments__{ NEString, SkinSettings }:Throwable()
function Style.UpdateSkin(name, settings)
    name                        = strlower(name)
    local skins                 = _Skins[name]

    if not skins then
        throw("Usage: Style.UpdateSkin(name, settings) - the name doesn't existed")
    end

    for class, setting in pairs(settings) do
        local skin              = emptyDefaultStyle(skins[class]) or {}
        skins[class]            = skin

        saveSkinSettings(class, skin, setting)
        activeSkin(name, class, skin, true)
    end
end

__Arguments__{ NEString, - UIObject/nil }:Throwable()
function Style.ActiveSkin(name, class)
    name                        = strlower(name)
    local skins                 = _Skins[name]

    if not skins then
        throw("Usage: Style.ActiveSkin(name[, uitype]) - the name doesn't existed")
    end

    if class then
        local skin              = skins[class]
        if not skin then
            throw("Usage: Style.ActiveSkin(name[, uitype]) - the skin doesn't have settings for " .. class)
        end

        return activeSkin(name, class, skin)
    else
        for cls, skin in pairs(skins) do
            activeSkin(name, cls, skin)
        end
    end
end

__Arguments__{ - UIObject }
function Style.GetActiveSkin(class)
    return _ActiveSkin[class]
end

__Arguments__{ - UIObject } __Iterator__()
function Style.GetSkins(class)
    for name, skins in pairs(_Skins) do
        if skins[class] then
            yield(name)
        end
    end
end

Style.RegisterSkin("Default")

export { Scorpio.UI.Property }