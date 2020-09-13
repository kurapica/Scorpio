--========================================================--
--                Scorpio Core System                     --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/07/13                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.UI.Core"                  "1.0.0"
--========================================================--

import "System.Reactive"

--- Clear the property value of the target object
local NIL                       = Namespace.SaveNamespace("Scorpio.UI.NIL",   prototype { __tostring = function() return "nil"   end })

--- Clear the property value of the settings(so other settings may be used for the property)
local CLEAR                     = Namespace.SaveNamespace("Scorpio.UI.CLEAR", prototype { __tostring = function() return "clear" end })

local isObjectType              = Class.IsObjectType
local isTypeValidDisabled       = System.Platform.TYPE_VALIDATION_DISABLED
local isUIObject                = UI.IsUIObject
local isUIObjectType            = UI.IsUIObjectType
local clone                     = Toolset.clone
local yield                     = coroutine.yield
local tinsert                   = table.insert
local tremove                   = table.remove
local strlower                  = strlower
local isObservable              = function(val) return type(val) == "table" and isObjectType(val, IObservable) end
local gettable                  = function(self, key) local val = self[key] if not val or val == NIL or val == CLEAR then val = {} self[key] = val end return val end

local CHILD_SETTING             = 0   -- For children

----------------------------------------------
--            Helper - Property             --
----------------------------------------------
local _Property                 = {}

local _RecycleHolder            = CreateFrame("Frame") _RecycleHolder:Hide()
local _PropertyChildName        = setmetatable({}, META_WEAKKEY)
local _PropertyChildMap         = setmetatable({}, { __index = function(self, prop) local val = setmetatable({}, META_WEAKALL) rawset(self, prop, val) return val end })
local _PropertyChildRecycle     = setmetatable({}, {
    __index                     = function(self, type)
        local recycle           = Recycle(type, "__" .. Namespace.GetNamespaceName(type):gsub("%.", "_") .. "%d", _RecycleHolder)
        rawset(self, type, recycle)
        return recycle
    end,
    __call                      = function(self, obj)
        if obj.Disposed then return end

        local cls               = getmetatable(obj)
        local recycle           = cls and rawget(self, cls)

        if recycle then
            obj:SetParent(_RecycleHolder)
            if obj.ClearAllPoints then obj:ClearAllPoints() end
            recycle(obj)

            return true
        end
    end
})

-- The objservable map
local _ObservableProp           = setmetatable({}, META_WEAKKEY)

local function dispatchPropertySetting(cls, prop, setting, oldsetting, root)
    local settings              = _Property[cls]
    if not settings then return end -- So it doesn't finished the definition

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
            Trace("[Scorpio.UI]Init Property List for %q", tostring(cls))

            local super         = Class.GetSuperClass(cls)
            if super and _Property[super] then
                _Property[cls]  = clone(_Property[super])
            else
                _Property[cls]  = {}
            end
        end

        local _Prop             = System.Property

        -- Scan the class's property
        for name, feature in Class.GetFeatures(cls) do
            if _Prop.Validate(feature) and not _Prop.IsStatic(feature) and _Prop.IsWritable(feature) then
                Trace("[Scorpio.UI]Define Property %s for %s", name, tostring(cls))

                local ptype     = _Prop.GetType(feature)
                UI.Property     {
                    name        = name,
                    type        = ptype,
                    require     = cls,
                    set         = function(self, val) self[name] = val end,
                    get         = _Prop.IsReadable(feature) and function(self) return self[name] end or nil,
                    default     = _Prop.GetDefault(feature),
                    nilable     = not _Prop.IsValueRequired(feature),
                    childtype   = ptype and IsUIObjectType(ptype) and ptype or nil,
                }
            end
        end
    end
end

local applyStylesOnFrame

local function applyProperty(self, prop, value)
    --Trace("[Scorpio.UI]Apply Property:%s - %s", prop.name, tostring(value))

    -- Check the observable map
    local map                   = _ObservableProp[self]
    if map and map[prop] then
        map[prop]:Unsubscribe()
    end

    if value == nil then
        if prop.clear then return prop.clear(self) end
        if prop.default ~= nil then return prop.set(self, clone(prop.default, true)) end
        if prop.nilable then return prop.set(self, nil) end
    elseif isObservable(value) then
        map                     = _ObservableProp[self] or {}
        _ObservableProp[self]   = map
        map[prop]               = map[prop] or Observer(function(val)
            if val and prop.set then
                prop.set(self, val)
            end
        end)

        value:Subscribe(map[prop])
    elseif prop.set then
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
local _ClearQueue               = Queue()
local _ClassQueue               = Queue()
local _Recycle                  = Recycle()

local _DefaultStyle             = {}
local _CustomStyle              = setmetatable({}, META_WEAKKEY)
local _ClassFrames              = {}

local function collectPropertyChild(frame)
    if _ClearQueue[frame] then return end
    if _ClearQueue.Count == 0 then FireSystemEvent("SCORPIO_UI_COLLECT_PROPERTY_CHILD") end
    _ClearQueue[frame]          = true
    _ClearQueue:Enqueue(frame)
end

local function applyStyle(frame)
    if _StyleQueue[frame] then return end
    if _StyleQueue.Count == 0 then FireSystemEvent("SCORPIO_UI_APPLY_STYLE") end
    _StyleQueue[frame]          = true
    _StyleQueue:Enqueue(frame)
end

local function queueClassFrames(class)
    if not _ClassQueue[class] then
        if _ClassQueue.Count == 0 then FireSystemEvent("SCORPIO_UI_UPDATE_CLASS_SKIN") end
        _ClassQueue[class]      = true
        _ClassQueue:Enqueue(class)
    end

    for scls in Class.GetSubTypes(class) do
        queueClassFrames(scls)
    end
end

local function emptyDefaultStyle(settings)
    if settings and settings ~= NIL and settings ~= CLEAR then
        for k, v in pairs(settings) do
            if k == CHILD_SETTING then
                for child, csetting in pairs(v) do
                    emptyDefaultStyle(csetting)
                end
            else
                settings[k]     = CLEAR
            end
        end
    end

    return settings
end

local function setCustomStyle(target, pname, value, stack, nodirectapply)
    local custom                = gettable(_CustomStyle, target)
    local haschanges            = false
    local directapply           = not _StyleQueue[target] and not nodirectapply

    local props                 = _Property[getUIPrototype(target)]
    if not props then error("The target has no property definitions", stack + 1) end

    if pname then
        local prop              = props[pname]
        local cval

        if prop.childtype then
            cval                = true  -- So the system can track the child property
            directapply         = false

            if value == nil or value == CLEAR or value == NIL then
                cval            = value or CLEAR
            elseif type(value) == "table" and getmetatable(value) == nil then
                local child, new= prop.get(target)
                if child then
                    setCustomStyle(child, nil, value, stack + 1, new)
                else
                    error(strformat("The target has no child element from %q", pname), stack + 1)
                end
            else
                error(strformat("The %q is a child poperty, its setting should be a table", pname), stack + 1)
            end
        else
            if value == nil or value == NIL or value == CLEAR then
                directapply     = false
                cval            = value or CLEAR
            elseif isObservable(value) then
                cval            = value
            else
                if prop.validate then
                    local ret, msg  = prop.validate(prop.type, value)
                    if msg then error(Struct.GetErrorMessage(msg, prop.name), stack + 1) end
                    value       = ret
                end

                cval            = value
            end
        end

        if custom[pname] ~= cval then
            custom[pname]       = cval
            haschanges          = true

            if directapply then
                return applyProperty(target, prop, cval)
            end
        end
    else
        if type(value) ~= "table" then
            error("The style settings must be property key value pair or a table contains the key-value pairs", stack + 1)
        end

        directapply             = directapply and _Recycle()

        for pn, pv in pairs(value) do
            if type(pn) ~= "string" then
                error("The style property name must be string", stack + 1)
            end

            local child         = UIObject.GetChild(target, pn)

            if child then
                setCustomStyle(child, nil, pv, stack + 1)
            else
                local cval
                local ln        = strlower(pn)
                local prop      = props[ln]
                local isclear   = false

                if not prop then error(strformat("The %q isn't a valid property for the target", pn), stack + 1) end

                if prop.childtype then
                    cval        = true

                    if pv == CLEAR or pv == NIL then
                        cval    = pv
                        isclear = true
                    elseif type(pv) == "table" and getmetatable(pv) == nil then
                        local new
                        child, new = prop.get(target)
                        if child then
                            setCustomStyle(child, nil, pv, stack + 1, new)
                        else
                            error(strformat("The target has no child element from %q", pn), stack + 1)
                        end
                    else
                        error(strformat("The %q is a child poperty, its setting should be a table", pname), stack + 1)
                    end
                else
                    if pv == NIL or pv == CLEAR then
                        cval    = pv
                        isclear = true
                    elseif isObservable(pv) then
                        cval    = pv
                    else
                        if prop.validate then
                            local ret, msg = prop.validate(prop.type, pv)
                            if msg then error(Struct.GetErrorMessage(msg, prop.name), stack + 1) end
                            pv  = ret
                        end

                        cval    = pv
                    end
                end

                if custom[ln] ~= cval then
                    custom[ln]  = cval
                    haschanges  = true

                    if directapply then
                        if isclear then
                            _Recycle(wipe(directapply))
                            directapply = nil
                        else
                            directapply[ln] = cval
                        end
                    end
                end
            end
        end

        if directapply then
            -- Instant apply custon settings, no need queue it
            return applyStylesOnFrame(target, directapply)
        end
    end

    return haschanges and applyStyle(target)
end

local function registerFrame(cls, frame)
    local map                   = _ClassFrames[cls]
    if not map then
        map                     = setmetatable({}, META_WEAKKEY)
        _ClassFrames[cls]       = map
    end

    map[frame]                  = true

    applyStyle(frame)
end

local function unregisterFrame(frame)
    _ClassFrames[getmetatable(frame)][frame] = nil
end

----------------------------------------------
--              Helper - Skin               --
----------------------------------------------
local _Skins                    = {}
local _ActiveSkin               = {}

local function copyBaseSkinSettings(container, base)
    for k, v in pairs(base) do
        if k == CHILD_SETTING then
            for name, setting in pairs(v) do
                copyBaseSkinSettings(gettable(gettable(container, k), name), setting)
            end
        else
            container[k]        = v
        end
    end
end

local function saveSkinSettings(classes, paths, container, settings)
    if type(settings) ~= "table" then throw("The skin settings for " .. class ..  "must be table") end

    local pathIdx               = #classes
    local class                 = classes[pathIdx]
    local props                 = _Property[class]

    -- Check inherit
    for name, value in pairs(settings) do
        if type(name) ~= "string" then throw("The skin settings only accpet string values as key") end
        if strlower(name) == "inherit" then
            settings[name]      = nil

            if type(value) ~= "string" then throw("The inherit only accpet skin name as value") end
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
        local element

        paths[pathIdx]          = name

        for i = 1, pathIdx do
            element             = __Template__.GetElementType(classes[i], unpack(paths, i))
            if element then break end
        end

        paths[pathIdx]          = nil

        if element then
            tinsert(classes, element)
            tinsert(paths, name)
            saveSkinSettings(classes, paths, gettable(gettable(container, CHILD_SETTING), name), value)
            tremove(classes)
            tremove(paths)
        elseif props then
            name                = strlower(name)
            local prop          = props[name]

            if not prop then
                throw(strformat("The %q isn't a valid property for %s", name, tostring(class)))
            end

            if prop.childtype then
                container[name] = true -- So we can easily track the child property settings

                if value == NIL or value == CLEAR then
                    if container[CHILD_SETTING] then container[CHILD_SETTING][name] = nil end
                    container[name]     = value
                elseif type(value) == "table" and getmetatable(value) == nil then
                    saveSkinSettings({ prop.childtype }, {}, gettable(gettable(container, CHILD_SETTING), name), value)
                else
                    throw(strformat("The %q is a child generated from property, need table as settings", name))
                end
            else
                if value == NIL or value == CLEAR then
                    container[name]     = value
                elseif isObservable(value) then
                    container[name]     = value
                else
                    if prop.validate then
                        local ret, msg  = prop.validate(prop.type, value)
                        if msg then throw(Struct.GetErrorMessage(msg, prop.name)) end
                        value           = ret
                    end

                    container[name]     = value
                end
            end
        else
            throw("The " .. class .. " has no property definitions")
        end
    end
end

local function copyToDefault(settings, default)
    for name, value in pairs(settings) do
        if name == CHILD_SETTING then
            local childsettings = gettable(default, CHILD_SETTING)
            for element, setting in pairs(value) do
                copyToDefault(setting, gettable(childsettings, element))
            end
        else
            default[name]       = value
        end
    end
end

local function activeSkin(name, class, skin, force)
    if force and _ActiveSkin[class] and _ActiveSkin[class] ~= name then return end
    if not force and _ActiveSkin[class] == name then return end
    _ActiveSkin[class] = name

    local default               = emptyDefaultStyle(_DefaultStyle[class]) or {}
    _DefaultStyle[class]        = default

    copyToDefault(skin, default)
    queueClassFrames(class)
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
        local parent            = (_GetParent[getmetatable(self)] or self.GetParent)(self)
        return parent and GetProxyUI(parent)
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
        if name == 0 then return end

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
                throw(("Usage : %s(name, parent, ...) - the parent already has a child named '%s'."):format(Namespace.GetNamespaceName(cls), name))
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

    local function getTarget(owner, name)
        for s in name:gmatch("[^%.]+") do
            owner               = owner and getChild(owner, s)
        end
        return owner
    end

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

                for name, events in pairs(map) do
                    local child = type(name) == "number" and owner or getTarget(owner, name)

                    if not child then
                        error(("The child named %q doesn't existed in object of %s"):format(name, tostring(getmetatable(owner))))
                    end

                    for event in events:gmatch("%w+") do
                        if not child:HasScript(event) then
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
    local CHILDREN_MAP          = 1

    local isUIObjectType        = UI.IsUIObjectType
    local getSuperCTOR          = Class.GetSuperMetaMethod
    local yield                 = coroutine.yield
    local getSuperClass         = Class.GetSuperClass
    local tinsert               = table.insert
    local tremove               = table.remove
    local strformat             = string.format
    local tconcat               = table.concat

    local function getElementType(cls, ...)
        local pathCnt           = select("#", ...)
        local scls              = cls

        repeat
            local childtree     = _Template[scls]
            local i             = 1
            local name          = select(i, ...)

            while childtree and i < pathCnt do
                local child     = childtree[name]

                if child then
                    -- Check if it's created by the child
                    local type  = getElementType(child, select(i + 1, ...))
                    if type then return type, false end
                end

                childtree       = childtree[CHILDREN_MAP] and childtree[CHILDREN_MAP][name]
                i               = i + 1
                name            = select(i, ...)
            end

            local type          = childtree and i == pathCnt and childtree[name]
            if type then return type, scls == cls end

            scls                 = getSuperClass(scls)
        until not scls
    end

    local function parseChildTree(cls, path, elements, supercls, stack)
        local childtree         = {}
        local container         = _Template
        local pathCnt           = #path
        local pathIdx           = pathCnt + 1

        -- Save the tree
        if pathCnt == 0 then
            _Template[cls]      = childtree
        else
            container           = _Template[cls]

            for i = 1, #path - 1 do
                container       = container[CHILDREN_MAP][path[i]]
            end

            container[CHILDREN_MAP]             = container[CHILDREN_MAP] or {}
            container[CHILDREN_MAP][path[#path]]= childtree
        end

        -- Save settings to the tree
        local subtree

        for k, v in pairs(elements) do
            if type(k) == "string" and isUIObjectType(v) then
                path[pathIdx]   = k

                -- Check if already created by children or super class
                if getElementType(cls, unpack(path)) or (supercls and getElementType(supercls, unpack(path))) then
                    error(strformat("The the child element named %q is already defined", k), stack + 1)
                end

                path[pathIdx]   = nil

                childtree[k]    = v
            elseif type(k) == "number" and type(v) == "table" and getmetatable(v) == nil and not subtree then
                subtree         = v
            else
                error("The __Template__'s element type must be an ui object type", stack + 1)
            end
        end

        if subtree then
            childtree[CHILDREN_MAP] = {}

            for name, subelements in pairs(subtree) do
                if type(name) == "string" and type(subelements) == "table" and getmetatable(subelements) == nil then
                    path[pathIdx] = name

                    if getElementType(cls, unpack(path)) or (supercls and getElementType(supercls, unpack(path))) then
                        parseChildTree(cls, path, subelements, supercls, stack + 1)
                    else
                        error(strformat("The child with the path %q doesn't existed", tconcat(path, ".")), stack + 1)
                    end
                else
                    error("The __Template__'s element's children settings must be a table", stack + 1)
                end
            end

            path[pathIdx]       = nil
        end
    end

    local function generateChildren(self, childtree)
        for k, v in pairs(childtree) do
            if k ~= CHILDREN_MAP then
                v(k, self)
            end
        end

        if childtree[CHILDREN_MAP] then
            for name, tree in pairs(childtree[CHILDREN_MAP]) do
                generateChildren(self:GetChild(name), tree)
            end
        end
    end

    -----------------------------------------------------------
    --                     static method                     --
    -----------------------------------------------------------
    __Arguments__{ - UIObject, NEString * 1 }
    __Static__() GetElementType = getElementType

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
            if name ~= "__ctor" then error("The __Template__ can only be used on the constructor, not nomral method", stack + 1) end
            if type(self[1]) ~= "table" then error("The __Template__ lack the element settings", stack + 1) end

            parseChildTree(owner, {}, self[1], nil, stack + 1)

            return function(self, ...)
                local sctor = getSuperCTOR(owner, "__ctor")
                if sctor then sctor(self, ...) end

                generateChildren(self, _Template[owner])

                return definition(self, ...)
            end
        elseif targettype == AttributeTargets.Class then
            if type(definition) == "table" then
                local new       = { self[0] }
                local elements  = {}

                for k, v in pairs(definition) do
                    if type(k) == "string" and isUIObjectType(v) then
                        elements[k] = v
                    elseif type(k) == "number" and type(v) == "table" and elements[CHILDREN_MAP] == nil then
                        elements[CHILDREN_MAP] = v
                    else
                        new[k]  = v
                    end
                end

                parseChildTree(target, {}, elements, self[0], stack + 1)

                new.__ctor      = function(self, ...)
                    local sctor = getSuperCTOR(target, "__ctor")
                    if sctor then sctor(self, ...) end

                    generateChildren(self, _Template[target])
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
    depends                     = { type  = struct { NEString } },  -- Processed after other properties
    override                    = { type  = struct { NEString } },  -- override other properties

    __valid                     = function(self)
        if not self.childtype and not self.set then
            return "%s.set is required"
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

        if self.childtype then
            -- The child property type should be handled specially
            local name          = self.name
            local childtype     = self.childtype
            local set           = self.set
            local nilable       = self.nilable
            local childname     = strlower(self.name)

            setting.get         = function(self, try)
                local child     = _PropertyChildMap[setting][self]
                if child or try then return child, false end

                child           = _PropertyChildRecycle[childtype]()

                if child then
                    child:SetParent(self)
                    if set then set(self, child) end

                    _PropertyChildMap[setting][self]= child
                    _PropertyChildName[child]       = childname
                end

                return child, true
            end

            setting.clear       = function(self)
                local child     = _PropertyChildMap[setting][self]
                if not child then return end

                collectPropertyChild(child)

                _PropertyChildMap[setting][self]    = nil
                if nilable and set then set(self, nil) end
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

        if self.depends then
            setting.depends     = {}
            for i, v in ipairs(self.depends) do
                setting.depends[i] = strlower(v)
            end
        end

        if self.override then
            setting.override    = {}
            for i, v in ipairs(self.override) do
                setting.override[i] = strlower(v)
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
            setCustomStyle(key, nil, value, 2)
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
                if prop then
                    if prop.childtype then
                        _StyleOwner = prop.get(target)
                        if _StyleOwner then return _StyleAccessor end
                    elseif prop.get then
                        return prop.get(target)
                    else
                        error("The " .. key .. " property has no get method")
                    end
                end
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
                setCustomStyle(star, nil, value, 2)
                return
            else
                key             = strlower(key)
                local cls       = getUIPrototype(target)
                local prop      = cls and _Property[cls] and _Property[cls][key]
                if prop then
                    setCustomStyle(target, key, value, 2)
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
        if select("#", ...) > 0 then
            class               = __Template__.GetElementType(class, ...)
            if not class then return end

            for i = 1, select("#", ...) do
                local name      = select(i, ...)

                default         = default[CHILD_SETTING]
                default         = default and default[name]
                if not default then return end
            end
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

            saveSkinSettings({class}, {}, skin, setting)
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

        saveSkinSettings({class}, {}, skin, setting)
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

__Arguments__{ -UIObject } __Iterator__()
function Style.GetProperties(class)
    local props                 = _Property[class]
    if props then
        for name, prop in pairs(props) do
            yield(name, prop.childtype or prop.type)
        end
    end
end

__Arguments__{ - UIObject, String }
function Style.GetProperty(class, name)
    local props                 = _Property[class]
    local prop                  = props and props[strlower(name)]
    if prop then return prop.childtype or prop.type end
end

Style.RegisterSkin("Default")

export { Scorpio.UI.Property }

----------------------------------------------
--           Skin System Services           --
----------------------------------------------
local function genPriority(props, name, styles, priority, lvl)
    lvl                         = (lvl or 0) + 1
    local maxlvl                = lvl

    for _, dep in ipairs(props[name].depends) do
        local val               = styles[dep]
        if val ~= nil and val ~= NIL and val ~= CLEAR then
            priority[dep]       = max(priority[dep] or 0, lvl)

            if props[dep].depends then
                maxlvl          = max(maxlvl, genPriority(props, dep, styles, priority, lvl))
            end
        end
    end

    return maxlvl
end

function applyStylesOnFrame(frame, styles)
    local props                 = _Property[getUIPrototype(frame)]
    if not props then return _Recycle(wipe(styles)) end

    local priority              = _Recycle()
    local maxlvl                = 0

    -- Generate the priority to apply the styles based on the depends
    for name, value in pairs(styles) do
        if value == NIL or value == CLEAR then
            applyProperty(frame, props[name], nil)
            styles[name]        = nil
        elseif props[name].depends then
            maxlvl              = max(maxlvl, genPriority(props, name, styles, priority))
        end
    end

    -- Process with priority
    for i = maxlvl, 1, -1 do
        for name, lv in pairs(priority) do
            if lv == i and styles[name] ~= nil then
                applyProperty(frame, props[name], styles[name])
                styles[name]    = nil
            end
        end
    end

    -- Process the rest
    for name, value in pairs(styles) do
        applyProperty(frame, props[name], value)
    end

    _Recycle(wipe(priority))
    _Recycle(wipe(styles))
end

local function clearStylesOnFrame(frame, styles)
    local props                 = _Property[getUIPrototype(frame)]
    if not props then return _Recycle(wipe(styles)) end

    local priority              = _Recycle()
    local maxlvl                = 0

    -- Generate the priority to apply the styles based on the depends
    for name, value in pairs(styles) do
        if value == NIL or value == CLEAR then
            applyProperty(frame, props[name], nil)
            styles[name]        = nil
        elseif props[name].depends then
            maxlvl              = max(maxlvl, genPriority(props, name, styles, priority))
        end
    end

    -- Process with priority
    for i = maxlvl, 1, -1 do
        for name, lv in pairs(priority) do
            if lv == i and styles[name] ~= nil then
                applyProperty(frame, props[name], nil)
            end
        end
    end

    -- Process property with no priority
    for name, value in pairs(styles) do
        if not priority[name] then
            applyProperty(frame, props[name], nil)
        end
    end

    _Recycle(wipe(priority))
    _Recycle(wipe(styles))
end

local function buildTempStyle(frame)
    local styles                            = _Recycle()
    local paths                             = _Recycle()
    local children                          = _Recycle()
    local tempClass                         = _Recycle()

    local props                             = _Property[getUIPrototype(frame)]
    if not props then return styles, children end -- No properties can be found

    -- Prepare the style settings
    -- Custom -> Root Parent Class -> ... -> Parent Class -> Frame Class -> Super Class
    local name                              = _PropertyChildName[frame] or UIObject.GetName(frame)
    local parent                            = UIObject.GetParent(frame)

    while parent and name do
        local cls                           = getmetatable(parent)

        tinsert(paths, 1, name)

        if cls and isUIObjectType(cls) then
            wipe(tempClass)

            repeat
                tinsert(tempClass, cls)
                cls                         = Class.GetSuperClass(cls)
            until not cls

            for i = #tempClass, 1, -1 do
                cls                         = tempClass[i]

                local default               = _DefaultStyle[cls]
                local index                 = 1

                while default and paths[index] do
                    default                 = default[CHILD_SETTING]
                    default                 = default and default[paths[index]]
                    index                   = index + 1
                end

                if default then
                    -- The parent -> ... -> child style settings
                    for prop, value in pairs(default) do
                        if prop == CHILD_SETTING then
                            for name in pairs(value) do
                                children[name]      = true
                            end
                        else
                            if value ~= CLEAR or styles[prop] == nil then
                                styles[prop]        = value

                                -- Check override
                                if props[prop].override then
                                    if value ~= CLEAR then
                                        for _, op in ipairs(props[prop].override) do
                                            styles[op]      = nil  -- The overridden property won't be applied
                                        end
                                    else
                                        for _, op in ipairs(props[prop].override) do
                                            if styles[op]  ~= nil and styles[op] ~= CLEAR then
                                                styles[prop]= nil
                                                break
                                            else
                                                styles[op]  = nil
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        name                                = _PropertyChildName[parent] or UIObject.GetName(parent)
        parent                              = UIObject.GetParent(parent)
    end

    _Recycle(wipe(paths))
    _Recycle(wipe(tempClass))

    if _CustomStyle[frame] then
        for prop, value in pairs(_CustomStyle[frame]) do
            if value ~= CLEAR or styles[prop] == nil then
                styles[prop]                = value

                -- Check override
                if props[prop].override then
                    if value ~= CLEAR then
                        for _, op in ipairs(props[prop].override) do
                            styles[op]      = nil  -- The overridden property won't be applied
                        end
                    else
                        for _, op in ipairs(props[prop].override) do
                            if styles[op]  ~= nil and styles[op] ~= CLEAR then
                                styles[prop]= nil
                                break
                            else
                                styles[op]  = nil
                            end
                        end
                    end
                end
            end
        end
    end

    local cls                               = getmetatable(frame)

    if isUIObjectType(cls) then
        while cls do
            local default                   = _DefaultStyle[cls]

            if default then
                for prop, value in pairs(default) do
                    if prop == CHILD_SETTING then
                        for name in pairs(value) do
                            children[name]  = true
                        end
                    elseif styles[prop] == nil or styles[prop] == CLEAR then
                        local noOverride    = true

                        -- Check override
                        if props[prop].override then
                            for _, op in ipairs(props[prop].override) do
                                if styles[op] ~= nil and styles[op] ~= CLEAR then
                                    noOverride  = false
                                    break
                                else
                                    styles[op]  = nil  -- Clear the CLEAR value styles
                                end
                            end
                        end

                        if noOverride then
                            styles[prop]    = value
                        end
                    end
                end
            end

            cls                             = Class.GetSuperClass(cls)
        end
    end

    return styles, children
end

local function clearStyle(frame)
    local props                             = _Property[getUIPrototype(frame)]

    if props and not frame.Disposed then
        local debugname                     = frame:GetName(true) or frame:GetObjectType()
        local clearChilds                   = _Recycle()

        Trace("[Scorpio.UI]Clear Style: %s%s", debugname, _PropertyChildName[frame] and (" - " .. _PropertyChildName[frame]) or "")

        local styles, children              = buildTempStyle(frame)

        -- Clear the children
        for name in pairs(children) do
            local child                     = UIObject.GetChild(frame, name)

            if child then
                clearStyle(child)
            elseif props[name] and props[name].childtype then
                child                       = props[name].get(frame, true)
                styles[name]                = CLEAR
                if child then
                    clearChilds[child]      = true
                    _ClearQueue[child]      = true

                    clearStyle(child)
                end
            end
        end

        _Recycle(wipe(children))

        -- Apply the style settings
        local ok, err                       = pcall(clearStylesOnFrame, frame, styles)
        if not ok then Error("[Scorpio.UI]Clear Style: %s - Failed: %s", debugname, tostring(err)) end

        for child in pairs(clearChilds) do
            _ClearQueue[child]              = nil
        end

        _Recycle(wipe(clearChilds))
    end

    _CustomStyle[frame]                     = nil
    if _PropertyChildName[frame] then
        _PropertyChildName[frame]           = nil
        _PropertyChildRecycle(frame)
    end

    Continue() -- Smoothing the process
end

__Service__(true)
function ApplyStyleService()
    while true do
        local frame                         = _StyleQueue:Dequeue()

        while frame do
            if _StyleQueue[frame] then
                local props                 = _Property[getUIPrototype(frame)]

                if props and not frame.Disposed then
                    local debugname         = frame:GetName(true) or frame:GetObjectType()

                    Trace("[Scorpio.UI]Apply Style: %s%s", debugname, _PropertyChildName[frame] and (" - " .. _PropertyChildName[frame]) or "")

                    local styles, children  = buildTempStyle(frame)

                    -- Queue the children
                    for name in pairs(children) do
                        local child         = UIObject.GetChild(frame, name)

                        if child then
                            applyStyle(child)
                        elseif props[name] and props[name].childtype and styles[name] == true then
                            styles[name]    = nil
                            child           = props[name].get(frame)
                            if child then applyStyle(child) end
                        end
                    end

                    _Recycle(wipe(children))

                    _StyleQueue[frame]      = nil

                    -- Apply the style settings
                    local ok, err           = pcall(applyStylesOnFrame, frame, styles)
                    if not ok then Error("[Scorpio.UI]Apply Style: %s - Failed: %s", debugname, tostring(err)) end

                    Continue() -- Smoothing the process
                else
                    _StyleQueue[frame]      = nil
                end
            end

            frame                           = _StyleQueue:Dequeue()
        end

        NextEvent("SCORPIO_UI_APPLY_STYLE")
    end
end

__Service__(true)
function CollectPropertyChildService()
    while true do
        local frame                         = _ClearQueue:Dequeue()

        while frame do
            if _ClearQueue[frame] then
                _ClearQueue[frame]          = nil

                clearStyle(frame)
            end

            frame                           = _ClearQueue:Dequeue()

            Continue()
        end

        NextEvent("SCORPIO_UI_COLLECT_PROPERTY_CHILD")
    end
end

__Service__(true)
function QueueClassFramesService()
    while true do
        local class                 = _ClassQueue:Dequeue()

        while class do
            if _ClassQueue[class] then
                _ClassQueue[class]  = nil -- Allow queue again

                local count         = 1
                local frames        = _ClassFrames[class]

                if frames then
                    for frame in pairs(frames) do
                        applyStyle(frame)
                        count       = count + 1

                        if count > 30 then
                            count   = 1
                            Continue()
                        end
                    end
                end
            end

            Continue()

            class                   = _ClassQueue:Dequeue()
        end

        NextEvent("SCORPIO_UI_UPDATE_CLASS_SKIN")
    end
end

-- Apply the style on the frame instantly
function UIObject:InstantApplyStyle()
    _StyleQueue[self]       = nil

    local props             = _Property[getUIPrototype(self)]
    if not props then return end

    local debugname         = self:GetName(true) or self:GetObjectType()

    Trace("[Scorpio.UI]Instant Apply Style: %s%s", debugname, _PropertyChildName[frame] and (" - " .. _PropertyChildName[frame]) or "")

    local styles, children  = buildTempStyle(self)

    -- Queue the children
    for name in pairs(children) do
        local child         = UIObject.GetChild(self, name)
        children[name]      = false

        if child then
            children[name]  = child
        elseif props[name] and props[name].childtype and styles[name] == true then
            styles[name]    = nil
            child           = props[name].get(self)
            if child then children[name] = child end
        end
    end

    for name, child in pairs(children) do
        if child then UIObject.InstantApplyStyle(child) end
    end

    _Recycle(wipe(children))

    -- Apply the style settings
    local ok, err           = pcall(applyStylesOnFrame, self, styles)
    if not ok then Error("[Scorpio.UI]Apply Style: %s - Failed: %s", debugname, tostring(err)) end
end

-- Get the child property name of the frame if it's generated by the property
function UIObject:GetChildPropertyName()
    return _PropertyChildName[self]
end

-- Get the child generated from the given property name
__Arguments__{ String }
function UIObject:GetPropertyChild(name)
    self                        = GetProxyUI(self)

    local props                 = _Property[getUIPrototype(self)]
    local prop                  = props and props[strlower(name)]

    return prop and prop.childtype and prop.get(self, true)
end