--========================================================--
--             Scorpio UI Style FrameWork                 --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2019/01/09                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.UI.Style"                 "1.0.0"
--========================================================--

local clone                     = Toolset.clone
local ACTION_APP_CLASS          = 1
local ACTION_DEL_CLASS          = 2

local _PropertyOwner
local _PropertyAccessor

local _Property                 = {}
local _StyleClass               = {}
local _StyleClassObjects        = setmetatable({}, { __index = function(self, key) local val = setmetatable({}, META_WEAKKEY) rawset(self, key, val) return val end })
local _FrameStyleClasses        = setmetatable({}, META_WEAKALL)

local _ApplyStyleTask           = setmetatable({}, META_WEAKALL)
local _ApplyStyleTaskStart      = 0
local _ApplyStyleTaskEnd        = 0

local META_TYPE_PROP_CACHE      = {
    __index                     = function(self, key)
        local prop              = _Property[key]
        if not prop then return nil end
        local require           = prop.require
        if require then
            if getmetatable(require) == nil then
                local match     = false
                for _, req in ipairs(require) do
                    if Class.IsSubType(self[1], req) then match = true break end
                end
                if not match then prop = false end
            else
                if not Class.IsSubType(self[1], require) then prop = false end
            end
        end
        rawset(self, key, prop)
        return prop
    end
}

local _Property4Type            = setmetatable({}, {
    __index = function(self, key)
        if Class.Validate(key) then
            local cache         = setmetatable({ [1] = key }, META_TYPE_PROP_CACHE)
            rawset(self, key, cache)
            return cache
        end
    end
})

function OnEnable(self)
    OnEnable                    = nil
    RunAsService(ProcessApplyStyleTask, true)
end

function ProcessApplyStyleTask()
    while true do
        while _ApplyStyleTaskEnd > _ApplyStyleTaskStart and GetTime() > _ApplyStyleTask[_ApplyStyleTaskStart + 1] do
            local action        = _ApplyStyleTask[_ApplyStyleTaskStart + 2]
            local frame         = _ApplyStyleTask[_ApplyStyleTaskStart + 3]

            if frame and _ApplyStyleTask[frame] <= _ApplyStyleTaskStart then
                _ApplyStyleTask[frame] = nil
            end

            _ApplyStyleTask[_ApplyStyleTaskStart + 1] = nil
            _ApplyStyleTask[_ApplyStyleTaskStart + 2] = nil
            _ApplyStyleTask[_ApplyStyleTaskStart + 3] = nil

            if action == ACTION_DEL_CLASS then
                local settings  = _ApplyStyleTask[_ApplyStyleTaskStart + 4]
                _ApplyStyleTask[_ApplyStyleTaskStart + 4] = nil
                _ApplyStyleTaskStart= _ApplyStyleTaskStart + 4

                if frame and not rawget(frame, "Disposed") then
                    RemoveClassStyle(frame, settings)
                    QueueApplyStyleTask(frame)
                end
            else
                _ApplyStyleTaskStart= _ApplyStyleTaskStart + 3

                if frame and not rawget(frame, "Disposed") then
                    ApplyClassStyle(frame, _StyleClass[getmetatable(frame)])
                    ApplyClassStyle(frame, _StyleClass[_FrameStyleClasses[frame]])
                end
            end

            Continue()
        end

        Next()
    end
end

function QueueApplyStyleTask(self)
    if _ApplyStyleTask[self] then return end
    _ApplyStyleTask[self]                   = _ApplyStyleTaskEnd

    _ApplyStyleTask[_ApplyStyleTaskEnd + 1] = GetTime()
    _ApplyStyleTask[_ApplyStyleTaskEnd + 2] = ACTION_APP_CLASS
    _ApplyStyleTask[_ApplyStyleTaskEnd + 3] = self
    _ApplyStyleTaskEnd                      = _ApplyStyleTaskEnd + 3
end

function QueueRemoveStyleTask(self, settings)
    local previous              = _ApplyStyleTask[self]
    if previous then
        if _ApplyStyleTask[previous + 2] == ACTION_APP_CLASS then
            _ApplyStyleTask[previous + 3]   = false
        elseif _ApplyStyleTask[_ApplyStyleTaskEnd + 4] == settings then
            return
        end
    end

    _ApplyStyleTask[self]                   = _ApplyStyleTaskEnd

    _ApplyStyleTask[_ApplyStyleTaskEnd + 1] = GetTime()
    _ApplyStyleTask[_ApplyStyleTaskEnd + 2] = ACTION_DEL_CLASS
    _ApplyStyleTask[_ApplyStyleTaskEnd + 3] = self
    _ApplyStyleTask[_ApplyStyleTaskEnd + 4] = settings
    _ApplyStyleTaskEnd                      = _ApplyStyleTaskEnd + 4
end

function QueueStyleUpdate(scls, old)
    if old then
        for frame in pairs(_StyleClassObjects[scls]) do
            QueueRemoveStyleTask(frame, old)
        end
    else
        for frame in pairs(_StyleClassObjects[scls]) do
            QueueApplyStyleTask(frame)
        end
    end
end

function GetPropertyCache(self)
    local cls                   = getmetatable(self)
    local ptype                 = _Property4Type[cls]

    if not ptype then
        -- Means the raw bliz ui
        ptype                   = _Property4Type[UI[self:GetObjectType()]]
        rawset(_Property4Type, cls, ptype)
    end

    return ptype
end

function ApplyClassStyle(self, settings)
    if not settings then return end
    local ptype                 = GetPropertyCache(self)
    if not ptype then return end
    for n, v in pairs(settings) do
        local prop              = ptype[n]
        if prop then prop.set(self, clone(v, true), 2) end
    end
end

function RemoveClassStyle(self, settings)
    if not settings then return end
    local ptype                 = GetPropertyCache(self)
    if not ptype then return end
    for n in pairs(settings) do
        local prop              = ptype[n]
        if prop then
            if prop.clear   then prop.clear(self, 2) end
            if prop.default then prop.set(self, clone(prop.default, true), 2) end
            if prop.nilable then prop.set(self, nil, 2) end
        end
    end
end

----------------------------------------------
--          Scorpio UI Style Core           --
----------------------------------------------
Namespace.SaveNamespace("Scorpio.UI.Style", prototype {
    __tostring                  = Namespace.GetNamespaceName,
    __index                     = function(self, key)
        -- Style[frm].Alpha = 1
        local tkey              = type(key)
        if tkey == "string" then
            return Namespace.GetNamespace(self, key)
        elseif tkey == "table" and key[0] then -- no more check, keep simple
            _PropertyOwner      = key
            return _PropertyAccessor
        end
    end,
    __newindex                  = function(self, key, value)
        if type(value) ~= "table" then error("Usage: Style[class] = { ... } - the style settings must be a table", 2) end

        local settings          = {}

        for n, v in pairs(value) do
            if type(n) == "string" then
                n               = strlower(n)
                local prop      = _Property[n]
                if not prop then error(strformat("Usage: Style[class] = { ... } - the %q isn't a valid property", n), 2) end

                if prop.validate then
                    local ret, msg  = prop.validate(prop.type, v)
                    if msg then error(Struct.GetErrorMessage(msg, n), 2) end
                    v           = ret
                end

                settings[n]     = v
            end
        end

        local tkey              = type(key)

        if (tkey == "string" and key:match("^[%w_-]+$")) or Class.IsSubType(key, IStyle) then
            -- Style["My_Style"]= { Alpha = 1 }
            key                 = tkey == "string" and strlower(key) or key

            local old           = _StyleClass[key]
            _StyleClass[key]    = settings
            QueueStyleUpdate(key, old)
        else
            error("Usage: Style[class] = { ... } - the style target should be widget class or style class(string)", 2)
        end
    end,
})

----------------------------------------------
--         Scorpio UI Property Core         --
----------------------------------------------
if System.Platform.TYPE_VALIDATION_DISABLED then
    _PropertyAccessor           = prototype {
        __metatable             = Scorpio.UI.Style,
        __index                 = function(self, key)
            local get           = _Property[strlower(key)].get
            return get and get(_PropertyOwner)
        end,
        __newindex              = function(self, key, value)
            local prop          = _Property[strlower(key)]
            if value == nil then
                if prop.clear   then prop.clear(_PropertyOwner, 2) return end
                if prop.default then prop.set(_PropertyOwner, clone(prop.default, true), 2) return end
                if prop.nilable then prop.set(_PropertyOwner, nil, 2) return end
            elseif prop.validate then
                prop.set(_PropertyOwner, prop.validate(prop.type, value))
            else
                prop.set(_PropertyOwner, value)
            end
        end,
    }
else
    _PropertyAccessor           = prototype {
        __metatable             = Scorpio.UI.Style,
        __index                 = function(self, key)
            if type(key) ~= "string" then error("the widget property name must be string", 2) end

            local ptype         = GetPropertyCache(_PropertyOwner)
            local prop          = ptype and ptype[strlower(key)]
            if not prop then error(strformat("the object has no widget property named %q", key), 2) end

            prop                = prop.get(_PropertyOwner, 2)
            return prop
        end,
        __newindex              = function(self, key, value)
            if type(key) ~= "string" then error("the widget property name must be string", 2) end

            local ptype         = GetPropertyCache(_PropertyOwner)
            local prop          = ptype and ptype[strlower(key)]
            if not prop then error(strformat("the object has no widget property named %q", key), 2) end

            if value == nil then
                if prop.clear   then prop.clear(_PropertyOwner, 2) return end
                if prop.default then prop.set(_PropertyOwner, clone(prop.default, true), 2) return end
                if prop.nilable then prop.set(_PropertyOwner, nil, 2) return end
                error(strformat("the %q widget property require non-nil value", key), 2)
            elseif prop.validate then
                local ret, msg  = prop.validate(prop.type, value)
                if msg then error(Struct.GetErrorMessage(msg, prop.name), 2) end
                prop.set(_PropertyOwner, ret, 2)
            else
                prop.set(_PropertyOwner, value, 2)
            end
        end,
    }
end

__Sealed__() struct "Scorpio.UI.Style.Property" (function(_ENV)
    __Static__() __Iterator__()
    function GetProperties(cls)
        if cls then
            for _, prop in pairs(_Property) do
                local match     = false
                if not prop.require then
                    match       = true
                elseif getmetatable(prop.require) then
                    if Class.IsSubType(cls, prop.require) then
                        match   = true
                    end
                else
                    for _, req in ipairs(prop.require) do
                        if Class.IsSubType(cls, req) then
                            match = true
                            break
                        end
                    end
                end
                if match then
                    yield(prop.name, prop.type, prop.set, prop.get, prop.clear, clone(prop.default, true), prop.nilable)
                end
            end
        else
            for _, prop in pairs(_Property) do
                yield(prop.name, prop.type, prop.set, prop.get, prop.clear, clone(prop.default, true), prop.nilable)
            end
        end
    end

    __Static__()
    function GetProperty(name, cls)
        local prop              = _Property[strlower(name)]
        if prop then
            local match         = false
            if not (cls and prop.require) then
                match           = true
            elseif getmetatable(prop.require) then
                if Class.IsSubType(cls, prop.require) then
                    match       = true
                end
            else
                for _, req in ipairs(prop.require) do
                    if Class.IsSubType(cls, req) then
                        match   = true
                        break
                    end
                end
            end
            if match then
                return prop.name, prop.type, prop.set, prop.get, prop.clear, clone(prop.default, true), prop.nilable
            end
        end
    end

    member "name"       { type  = NEString, require = true }
    member "type"       { type  = AnyType }
    member "require"    { type  = not System.Platform.TYPE_VALIDATION_DISABLED and (AnyType + struct { AnyType }) or nil }
    member "set"        { type  = Function, require = true }
    member "get"        { type  = Function }
    member "clear"      { type  = Function }
    member "default"    { type  = Any }
    member "nilable"    { type  = Boolean }

    __valid                     = function (self)
        local name              = strlower(self.name)
        if _Property[name] then
            return strformat("the %q widget property is already existed", name)
        end
    end

    __init                      = System.Platform.TYPE_VALIDATION_DISABLED and function(self)
        self                    = Toolset.clone(self)

        self.require            = nil

        if self.type then
           if Struct.Validate(self.type) then
                if not Struct.IsImmutable(self.type) then
                    self.validate  = Struct.ValidateValue
                end
                if Struct.GetStructCategory(self.type) ~= StructCategory.CUSTOM then
                    self.depthcomp = true
                end
            end

            if self.default then
                self.default    = Struct.ValidateValue(self.type, self.default)
            end
        end

        _Property[strlower(self.name)] = self
    end or function(self)
        self                    = Toolset.clone(self)

        if self.type then
            if Enum.Validate(self.type) then
                self.validate   = Enum.ValidateValue
            elseif Struct.Validate(self.type) then
                self.validate   = Struct.ValidateValue
                if Struct.GetStructCategory(self.type) ~= StructCategory.CUSTOM then
                    self.depthcomp = true
                end
            elseif Class.Validate(self.type) then
                self.validate   = Class.ValidateValue
            elseif Interface.Validate(self.type) then
                self.validate   = Interface.ValidateValue
            end
        end

        _Property[strlower(self.name)] = self
    end
end)

----------------------------------------------
--               Style Class                --
----------------------------------------------
Style.Property  {
    name                        = "Class",
    type                        = NEString,
    nilable                     = true,
    get                         = function(self) return _FrameStyleClasses[self] or nil end,
    set                         = function(self, scls)
        scls                    = scls and strlower(scls)

        local old               = _FrameStyleClasses[self]
        if old == scls then return end
        if old then
            _FrameStyleClasses[self]        = nil
            _StyleClassObjects[old][self]   = nil
            QueueRemoveStyleTask(self, _StyleClass[old])
        end

        if scls then
            _FrameStyleClasses[self]        = scls
            _StyleClassObjects[scls][self]  = true
            QueueApplyStyleTask(self)
        end
    end,
}

----------------------------------------------
--             Style Interface              --
----------------------------------------------
__Sealed__()
IStyle                          = interface ("Scorpio.UI.Style.IStyle", {
    function (self)
        _StyleClassObjects[getmetatable(self)][self] = true
        QueueApplyStyleTask(self)
    end
})